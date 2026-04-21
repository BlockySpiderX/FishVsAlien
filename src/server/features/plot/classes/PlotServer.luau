local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.Janitor)

type PlotTypes = typeof(require(ReplicatedStorage.Shared.features.plot.PlotTypes))
type PlotSpawn = PlotTypes.PlotSpawn
type PlotSnapshot = PlotTypes.PlotSnapshot

local PlotServer = {}
PlotServer.__index = PlotServer

export type Plot = typeof(setmetatable(
	{} :: {
		index: number,
		instance: PlotTypes.PlotInstance,
		spawnCFrame: CFrame,
		owner: Player?,
		janitor: Janitor.Janitor,
	},
	PlotServer
))

local function applyStateAttributes(self: Plot)
	local owner = self.owner
	self.instance:SetAttribute("PlotIndex", self.index)
	self.instance:SetAttribute("PlotClaimed", owner ~= nil)
	self.instance:SetAttribute("PlotOwnerUserId", if owner then owner.UserId else nil)
	self.instance:SetAttribute("PlotOwnerName", if owner then owner.Name else nil)
end

local function setTextOnInstance(target: Instance, text: string): boolean
	if target:IsA("TextLabel") or target:IsA("TextButton") or target:IsA("TextBox") then
		target.Text = text
		return true
	end

	if target:IsA("StringValue") then
		target.Value = text
		return true
	end

	for _, descendant in target:GetDescendants() do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			descendant.Text = text
			return true
		end

		if descendant:IsA("StringValue") then
			descendant.Value = text
			return true
		end
	end

	return false
end

local function updateTankNameTag(self: Plot)
	if not self.instance:IsA("Model") then
		return
	end

	local tagModel = self.instance:FindFirstChild("Tag")
	if not tagModel then
		return
	end

	local nameTarget = tagModel:FindFirstChild("Name")
	if not nameTarget then
		return
	end

	local owner = self.owner
	local text = if owner then (`{owner.Name}'s tank`) else "Empty tank"
	setTextOnInstance(nameTarget, text)
end

local function waitForCharacterReady(model: Model)
	if model.PrimaryPart then
		return
	end

	model:WaitForChild("HumanoidRootPart", 5)
end

function PlotServer.new(plotSpawn: PlotSpawn): Plot
	local self = setmetatable({
		index = plotSpawn.index,
		instance = plotSpawn.instance,
		spawnCFrame = plotSpawn.spawnCFrame,
		owner = nil,
		janitor = Janitor.new(),
	}, PlotServer)

	applyStateAttributes(self)
	updateTankNameTag(self)

	return self
end

function PlotServer.claim(self: Plot, player: Player)
	assert(self.owner == nil, ("Plot %d is already claimed"):format(self.index))
	self.owner = player
	applyStateAttributes(self)
	updateTankNameTag(self)
	self:bindCharacter(player)
	self:teleportCharacter(player)
end

function PlotServer.release(self: Plot)
	self.owner = nil
	self.janitor:Cleanup()
	applyStateAttributes(self)
	updateTankNameTag(self)
end

function PlotServer.bindCharacter(self: Plot, player: Player)
	self.janitor:Cleanup()
	self.janitor:Add(player.CharacterAdded:Connect(function(character)
		task.defer(function()
			if self.owner ~= player then
				return
			end

			self:teleportModel(character)
		end)
	end))
end

function PlotServer.teleportCharacter(self: Plot, player: Player)
	local character = player.Character
	if not character then
		return
	end

	self:teleportModel(character)
end

function PlotServer.teleportModel(self: Plot, model: Model)
	if not model.Parent then
		return
	end

	waitForCharacterReady(model)

	if not model.PrimaryPart and not model:FindFirstChild("HumanoidRootPart") then
		return
	end

	model:PivotTo(self.spawnCFrame)
end

function PlotServer.getSnapshot(self: Plot): PlotSnapshot
	local owner = self.owner
	return {
		index = self.index,
		ownerUserId = if owner then owner.UserId else nil,
		ownerName = if owner then owner.Name else nil,
		isClaimed = owner ~= nil,
	}
end

function PlotServer.destroy(self: Plot)
	self:release()
	self.janitor:Destroy()
end

return PlotServer
