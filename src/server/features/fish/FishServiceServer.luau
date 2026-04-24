local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Fishes = require(ReplicatedStorage.Shared.features.fish.FishConfig)

local FishServiceServer = {}
FishServiceServer.__index = FishServiceServer

local TANKS_FOLDER_PATH = { "Map", "Tanks" }
local UPDATE_INTERVAL = 1

type FishDefinition = {
	id: string,
	name: string,
	rarity: string,
	trait: string,
	moveStyle: string,
	baseIncome: number,
	incomeInterval: number,
	baseSellValue: number,
	growthPerFeed: number,
	image: string,
}

type FishRuntime = {
	definition: FishDefinition,
	fedCount: number,
	fish: Instance,
	incomeDeadline: number,
	lastFedAt: number,
	lifetimeCoins: number,
	originalSize: Vector3?,
	plot: any,
	stageIndex: number,
}

export type FishServiceServer = typeof(setmetatable(
	{} :: {
		fishRuntimes: { FishRuntime },
		moneyService: any,
		plotService: any,
		running: boolean,
	},
	FishServiceServer
))

local function findFolder(pathSegments: { string }): Instance?
	local current: Instance = Workspace

	for _, segment in pathSegments do
		local nextInstance = current:FindFirstChild(segment)
		if not nextInstance then
			return nil
		end

		current = nextInstance
	end

	return current
end

local function findNamedDescendant(root: Instance, name: string): Instance?
	local direct = root:FindFirstChild(name)
	if direct then
		return direct
	end

	return root:FindFirstChild(name, true)
end

local function getPrimaryPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end

	if instance:IsA("Model") then
		if instance.PrimaryPart then
			return instance.PrimaryPart
		end

		local part = instance:FindFirstChildWhichIsA("BasePart", true)
		if part then
			instance.PrimaryPart = part
			return part
		end
	end

	return nil
end

local function getFishInstances(container: Instance): { Instance }
	local fishInstances = {}

	if container:IsA("Folder") then
		for _, child in container:GetChildren() do
			if child:IsA("Model") or child:IsA("BasePart") then
				table.insert(fishInstances, child)
			end
		end
	elseif container:IsA("Model") or container:IsA("BasePart") then
		table.insert(fishInstances, container)
	end

	return fishInstances
end

local function getPlotByInstance(plotService, plotInstance: Instance)
	for _, plot in plotService.plots do
		if plot.instance == plotInstance then
			return plot
		end
	end

	return nil
end

local function getFishDefinition(fish: Instance): FishDefinition
	local fishId = fish:GetAttribute("FishId")
	if type(fishId) ~= "string" or fishId == "" then
		fishId = string.lower(fish.Name)
	end

	local definition = Fishes.species[fishId]
	if definition then
		return definition
	end

	return Fishes.species.salmon
end

local function getStageForFedCount(fedCount: number): (number, any)
	local currentIndex = 1
	local currentStage = Fishes.stages[1]

	for index, stage in Fishes.stages do
		if fedCount >= stage.fedRequired then
			currentIndex = index
			currentStage = stage
		end
	end

	return currentIndex, currentStage
end

local function getCurrentIncome(runtime: FishRuntime): number
	local stage = Fishes.stages[runtime.stageIndex]
	local rarity = Fishes.rarities[runtime.definition.rarity]
	local baseIncome = runtime.definition.baseIncome
	local rarityMultiplier = if rarity then rarity.incomeMultiplier else 1
	local stageMultiplier = if stage then stage.incomeMultiplier else 1

	return math.floor(baseIncome * rarityMultiplier * stageMultiplier)
end

local function getHungerIncomeMultiplier(hungerState: string?): number
	if hungerState == "Hungry" then
		return 0.82
	end

	if hungerState == "Danger" then
		return 0.55
	end

	if hungerState == "Starving" or hungerState == "Dead" then
		return 0
	end

	return 1
end

local function getCurrentSellValue(runtime: FishRuntime): number
	local stage = Fishes.stages[runtime.stageIndex]
	local rarity = Fishes.rarities[runtime.definition.rarity]
	local rarityMultiplier = if rarity then rarity.incomeMultiplier else 1
	local stageMultiplier = if stage then stage.incomeMultiplier else 1

	return math.floor(runtime.definition.baseSellValue * rarityMultiplier * stageMultiplier)
end

local function applyFishScale(runtime: FishRuntime)
	local stage = Fishes.stages[runtime.stageIndex]
	local fish = runtime.fish
	local scale = if stage then stage.scale else 1

	if fish:IsA("Model") then
		fish:ScaleTo(scale)
		return
	end

	local fishPart = getPrimaryPart(fish)
	if fishPart and runtime.originalSize then
		fishPart.Size = runtime.originalSize * scale
	end
end

local function updateIdentityDisplay(runtime: FishRuntime)
	local stage = Fishes.stages[runtime.stageIndex]
	local fish = runtime.fish
	local fishPart = getPrimaryPart(fish)
	if fishPart then
		local existingGui = fishPart:FindFirstChild("FishIdentityGui")
		if existingGui then
			existingGui:Destroy()
		end
	end

	local income = getCurrentIncome(runtime)

	fish:SetAttribute("FishId", runtime.definition.id)
	fish:SetAttribute("FishName", runtime.definition.name)
	fish:SetAttribute("FishRarity", runtime.definition.rarity)
	fish:SetAttribute("FishTrait", runtime.definition.trait)
	fish:SetAttribute("FishMoveStyle", runtime.definition.moveStyle)
	fish:SetAttribute("GrowthStage", stage.id)
	fish:SetAttribute("GrowthFeeds", runtime.fedCount)
	fish:SetAttribute("CoinRate", income)
	fish:SetAttribute("SellValue", getCurrentSellValue(runtime))
	fish:SetAttribute("LifetimeCoins", runtime.lifetimeCoins)
end

local function advanceGrowthIfNeeded(runtime: FishRuntime)
	local stageIndex = getStageForFedCount(runtime.fedCount)
	local nextStageIndex = stageIndex
	if runtime.stageIndex ~= nextStageIndex then
		runtime.stageIndex = nextStageIndex
		applyFishScale(runtime)
		updateIdentityDisplay(runtime)
	end
end

function FishServiceServer.new(plotService, moneyService): FishServiceServer
	local self = setmetatable({
		fishRuntimes = {},
		moneyService = moneyService,
		plotService = plotService,
		running = true,
	}, FishServiceServer)

	self:initialize()
	task.spawn(function()
		self:runLoop()
	end)

	return self
end

function FishServiceServer:initialize()
	local tanksFolder = findFolder(TANKS_FOLDER_PATH)
	if not tanksFolder then
		warn("[FishService] Could not find Workspace.Map.Tanks")
		return
	end

	for _, plotModel in tanksFolder:GetChildren() do
		if not plotModel:IsA("Model") then
			continue
		end

		local plot = getPlotByInstance(self.plotService, plotModel)
		local fishContainer = findNamedDescendant(plotModel, "Fish")
		if not plot or not fishContainer then
			continue
		end

		for _, fish in getFishInstances(fishContainer) do
			local fishPart = getPrimaryPart(fish)
			if fishPart then
				local definition = getFishDefinition(fish)
				local runtime = {
					definition = definition,
					fedCount = 0,
					fish = fish,
					incomeDeadline = os.clock() + definition.incomeInterval,
					lastFedAt = 0,
					lifetimeCoins = 0,
					originalSize = if fishPart:IsA("BasePart") then fishPart.Size else nil,
					plot = plot,
					stageIndex = 1,
				}

				applyFishScale(runtime)
				updateIdentityDisplay(runtime)
				table.insert(self.fishRuntimes, runtime)
			end
		end
	end
end

function FishServiceServer:processGrowth(runtime: FishRuntime)
	local fish = runtime.fish
	local lastFedAt = fish:GetAttribute("LastFedAt")
	if type(lastFedAt) ~= "number" or lastFedAt <= runtime.lastFedAt then
		return
	end

	runtime.lastFedAt = lastFedAt
	runtime.fedCount += runtime.definition.growthPerFeed
	advanceGrowthIfNeeded(runtime)
	updateIdentityDisplay(runtime)
end

function FishServiceServer:processIncome(runtime: FishRuntime)
	local fish = runtime.fish
	local owner = runtime.plot.owner
	if not owner then
		return
	end

	local isDead = fish:GetAttribute("IsDead") == true
	if isDead then
		return
	end

	local hungerState = fish:GetAttribute("HungerState")
	local hungerMultiplier = getHungerIncomeMultiplier(hungerState)
	if hungerMultiplier <= 0 then
		return
	end

	if os.clock() < runtime.incomeDeadline then
		return
	end

	local income = math.max(1, math.floor(getCurrentIncome(runtime) * hungerMultiplier))
	runtime.incomeDeadline = os.clock() + runtime.definition.incomeInterval
	runtime.lifetimeCoins += income
	self.moneyService:add(owner, income)
	updateIdentityDisplay(runtime)
	fish:SetAttribute("LastIncomeAt", os.time())
end

function FishServiceServer:runLoop()
	while self.running do
		for _, runtime in self.fishRuntimes do
			if runtime.fish.Parent then
				self:processGrowth(runtime)
				self:processIncome(runtime)
			end
		end

		task.wait(UPDATE_INTERVAL)
	end
end

function FishServiceServer:destroy()
	self.running = false

	for _, runtime in self.fishRuntimes do
		local fishPart = getPrimaryPart(runtime.fish)
		if fishPart then
			local existingGui = fishPart:FindFirstChild("FishIdentityGui")
			if existingGui then
				existingGui:Destroy()
			end
		end
	end

	self.fishRuntimes = {}
end

return FishServiceServer
