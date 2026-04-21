local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local MovementServiceServer = {}
MovementServiceServer.__index = MovementServiceServer

local TANKS_FOLDER_PATH = { "Map", "Tanks" }
local FISH_HEIGHT_PADDING = 1.5
local FISH_SIDE_PADDING = 1
local FISH_SPEED = 3.25
local FISH_MOVE_MIN = 2
local FISH_MOVE_MAX = 4.8
local FISH_IDLE_MIN = 0.2
local FISH_IDLE_MAX = 0.7
local INITIALIZE_RETRIES = 20
local INITIALIZE_RETRY_DELAY = 1

type FishController = {
	fish: Instance,
	boundary: Instance,
	cancelled: boolean,
}

export type MovementServiceServer = typeof(setmetatable(
	{} :: {
		controllers: { FishController },
	},
	MovementServiceServer
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

local function getInstancePrimaryPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end

	if instance:IsA("Model") then
		if instance.PrimaryPart then
			return instance.PrimaryPart
		end

		local firstPart = instance:FindFirstChildWhichIsA("BasePart", true)
		if firstPart then
			instance.PrimaryPart = firstPart
			return firstPart
		end
	end

	return nil
end

local function getInstancePivot(instance: Instance): CFrame?
	if instance:IsA("Model") then
		return instance:GetPivot()
	end

	if instance:IsA("BasePart") then
		return instance.CFrame
	end

	return nil
end

local function pivotInstanceTo(instance: Instance, targetCFrame: CFrame)
	if instance:IsA("Model") then
		instance:PivotTo(targetCFrame)
	elseif instance:IsA("BasePart") then
		instance.CFrame = targetCFrame
	end
end

local function getBoundaryBox(instance: Instance)
	if instance:IsA("Model") then
		return instance:GetBoundingBox()
	end

	if instance:IsA("BasePart") then
		return instance.CFrame, instance.Size
	end

	return nil
end

local function getRandomTarget(boundary: Instance, fishPart: BasePart): CFrame?
	local boundaryCFrame, boundarySize = getBoundaryBox(boundary)
	if not boundaryCFrame or not boundarySize then
		return nil
	end

	local fishSize = fishPart.Size
	local halfX = math.max(0.5, (boundarySize.X - fishSize.X) * 0.5 - FISH_SIDE_PADDING)
	local halfY = math.max(0.5, (boundarySize.Y - fishSize.Y) * 0.5 - FISH_HEIGHT_PADDING)
	local halfZ = math.max(0.5, (boundarySize.Z - fishSize.Z) * 0.5 - FISH_SIDE_PADDING)

	local offset = Vector3.new(
		(math.random() * 2 - 1) * halfX,
		(math.random() * 2 - 1) * halfY,
		(math.random() * 2 - 1) * halfZ
	)

	local worldPosition = boundaryCFrame.Position
		+ boundaryCFrame.RightVector * offset.X
		+ boundaryCFrame.UpVector * offset.Y
		+ boundaryCFrame.LookVector * offset.Z

	local currentPosition = fishPart.Position
	local facingDirection = Vector3.new(worldPosition.X - currentPosition.X, 0, worldPosition.Z - currentPosition.Z)
	local lookTarget = if facingDirection.Magnitude > 0.05
		then worldPosition + facingDirection.Unit
		else worldPosition + boundaryCFrame.LookVector

	return CFrame.lookAt(worldPosition, lookTarget)
end

local function moveFishIntoBoundary(fish: Instance, boundary: Instance)
	if fish.Parent ~= boundary then
		fish.Parent = boundary
	end

	local fishPart = getInstancePrimaryPart(fish)
	if not fishPart then
		return
	end

	local target = getRandomTarget(boundary, fishPart)
	if target then
		pivotInstanceTo(fish, target)
	end
end

local function animateFish(controller: FishController)
	local fishPart = getInstancePrimaryPart(controller.fish)
	if not fishPart then
		return
	end

	moveFishIntoBoundary(controller.fish, controller.boundary)

	task.spawn(function()
		while not controller.cancelled and controller.fish.Parent and controller.boundary.Parent do
			local target = getRandomTarget(controller.boundary, fishPart)
			if not target then
				task.wait(1)
				continue
			end

			local currentPivot = getInstancePivot(controller.fish)
			if not currentPivot then
				break
			end

			local distance = (target.Position - currentPivot.Position).Magnitude
			local duration = math.clamp(distance / FISH_SPEED, FISH_MOVE_MIN, FISH_MOVE_MAX)
			local proxy = Instance.new("CFrameValue")
			proxy.Value = currentPivot

			local tween = TweenService:Create(
				proxy,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Value = target }
			)

			local changedConnection = proxy:GetPropertyChangedSignal("Value"):Connect(function()
				pivotInstanceTo(controller.fish, proxy.Value)
			end)

			tween:Play()
			tween.Completed:Wait()
			changedConnection:Disconnect()
			proxy:Destroy()

			task.wait(math.random(FISH_IDLE_MIN * 100, FISH_IDLE_MAX * 100) / 100)
		end
	end)
end

local function isPlotContainer(instance: Instance): boolean
	return instance:IsA("Model")
end

local function findNamedDescendant(root: Instance, name: string): Instance?
	local direct = root:FindFirstChild(name)
	if direct then
		return direct
	end

	return root:FindFirstChild(name, true)
end

function MovementServiceServer.new(): MovementServiceServer
	local self = setmetatable({
		controllers = {},
	}, MovementServiceServer)

	task.spawn(function()
		self:initialize()
	end)

	return self
end

function MovementServiceServer:initialize()
	for attempt = 1, INITIALIZE_RETRIES do
		local tanksFolder = findFolder(TANKS_FOLDER_PATH)
		if not tanksFolder then
			if attempt == INITIALIZE_RETRIES then
				warn("[MovementService] Could not find Workspace.Map.Tanks")
			else
				task.wait(INITIALIZE_RETRY_DELAY)
			end
			continue
		end

		local foundControllers = 0

		for _, plotModel in tanksFolder:GetChildren() do
			if not isPlotContainer(plotModel) then
				continue
			end

			local tankBoundary = findNamedDescendant(plotModel, "Tank")
			local fish = findNamedDescendant(plotModel, "Fish")
			if not tankBoundary or not fish then
				continue
			end

			local fishPart = getInstancePrimaryPart(fish)
			local boundaryCFrame, boundarySize = getBoundaryBox(tankBoundary)
			if not fishPart or not boundaryCFrame or not boundarySize then
				warn(("[MovementService] `%s` has Fish/Tank but they are not movable yet"):format(plotModel.Name))
				continue
			end

			local controller = {
				boundary = tankBoundary,
				cancelled = false,
				fish = fish,
			}

			table.insert(self.controllers, controller)
			animateFish(controller)
			foundControllers += 1
		end

		if foundControllers > 0 then
			return
		end

		if attempt < INITIALIZE_RETRIES then
			task.wait(INITIALIZE_RETRY_DELAY)
		else
			warn("[MovementService] No Fish/Tank pairs were found inside Workspace.Map.Tanks")
		end
	end
end

function MovementServiceServer:destroy()
	for _, controller in self.controllers do
		controller.cancelled = true
	end

	self.controllers = {}
end

return MovementServiceServer
