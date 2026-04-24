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
local FOOD_FISH_SPEED = 8.5
local FOOD_MOVE_MIN = 0.18
local FOOD_MOVE_MAX = 0.8
local INITIALIZE_RETRIES = 20
local INITIALIZE_RETRY_DELAY = 1
local BUBBLE_SOUND_ID = "rbxassetid://76388110801091"
local BUBBLE_INTERVAL = 5
local BUBBLE_VOLUME = 2.4
local BUBBLE_MAX_DISTANCE = 200

type FishController = {
	activeTween: Tween?,
	boundary: Instance,
	cancelled: boolean,
	fish: Instance,
	mode: string,
	targetPosition: Vector3?,
	tweenChangedConnection: RBXScriptConnection?,
	tweenProxy: CFrameValue?,
}

export type MovementServiceServer = typeof(setmetatable(
	{} :: {
		bubbleLoops: { [Instance]: boolean },
		controllers: { FishController },
		foodTargets: { [Instance]: { Vector3 } },
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

local function getSoundHost(instance: Instance): Instance?
	if instance:IsA("BasePart") then
		return instance
	end

	if instance:IsA("Model") then
		return getInstancePrimaryPart(instance)
	end

	return nil
end

local function computeRandomTargetPosition(boundary: Instance, fishPart: BasePart): Vector3?
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

	return boundaryCFrame.Position
		+ boundaryCFrame.RightVector * offset.X
		+ boundaryCFrame.UpVector * offset.Y
		+ boundaryCFrame.LookVector * offset.Z
end

local function getRandomTarget(boundary: Instance, fishPart: BasePart, worldPosition: Vector3?): CFrame?
	local targetPosition = worldPosition or computeRandomTargetPosition(boundary, fishPart)
	if not targetPosition then
		return nil
	end

	local currentPosition = fishPart.Position
	local facingDirection = Vector3.new(targetPosition.X - currentPosition.X, 0, targetPosition.Z - currentPosition.Z)
	local lookTarget = if facingDirection.Magnitude > 0.05
		then targetPosition + facingDirection.Unit
		else currentPosition + Vector3.new(0, 0, 1)

	return CFrame.lookAt(targetPosition, lookTarget)
end

local function prepareFishInstance(fish: Instance)
	for _, descendant in fish:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Anchored = true
		end
	end

	if fish:IsA("BasePart") then
		fish.CanCollide = false
		fish.CanTouch = false
		fish.CanQuery = false
		fish.Anchored = true
	end
end

local function clearLegacyFishState(fish: Instance)
	fish:SetAttribute("Hunger", nil)
	fish:SetAttribute("HungerMax", nil)
	fish:SetAttribute("HungerState", nil)
	fish:SetAttribute("IsDead", nil)

	local fishPart = getInstancePrimaryPart(fish)
	if not fishPart then
		return
	end

	local existingGui = fishPart:FindFirstChild("HungerGui")
	if existingGui then
		existingGui:Destroy()
	end
end

local function clearLegacyFishDisplay(controller: FishController)
	local fishPart = getInstancePrimaryPart(controller.fish)
	if not fishPart then
		return
	end

	local existingGui = fishPart:FindFirstChild("HungerGui")
	if existingGui then
		existingGui:Destroy()
	end
end

local function getOtherTargetPositions(controllers: { FishController }, boundary: Instance, currentController: FishController): { Vector3 }
	local positions = {}

	for _, controller in controllers do
		if controller ~= currentController and not controller.cancelled and controller.boundary == boundary and controller.targetPosition then
			table.insert(positions, controller.targetPosition)
		end
	end

	return positions
end

local function chooseSpacedTarget(boundary: Instance, fishPart: BasePart, occupiedPositions: { Vector3 }): Vector3?
	local bestCandidate = nil
	local bestDistanceScore = -math.huge
	local desiredSpacing = math.max(fishPart.Size.Magnitude * 2.2, 4)

	for _ = 1, 12 do
		local candidate = computeRandomTargetPosition(boundary, fishPart)
		if not candidate then
			return nil
		end

		local nearestDistance = math.huge
		for _, occupied in occupiedPositions do
			local distance = (candidate - occupied).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
			end
		end

		if #occupiedPositions == 0 then
			return candidate
		end

		if nearestDistance >= desiredSpacing then
			return candidate
		end

		if nearestDistance > bestDistanceScore then
			bestDistanceScore = nearestDistance
			bestCandidate = candidate
		end
	end

	return bestCandidate
end

local function moveFishIntoBoundary(controller: FishController, occupiedPositions: { Vector3 })
	local fishPart = getInstancePrimaryPart(controller.fish)
	if not fishPart then
		return
	end

	prepareFishInstance(controller.fish)

	local targetPosition = chooseSpacedTarget(controller.boundary, fishPart, occupiedPositions)
	if targetPosition then
		controller.targetPosition = targetPosition
		local target = getRandomTarget(controller.boundary, fishPart, targetPosition)
		if target then
			pivotInstanceTo(controller.fish, target)
		end
	end
end

local function stopControllerTween(controller: FishController)
	if controller.activeTween then
		controller.activeTween:Cancel()
		controller.activeTween = nil
	end

	if controller.tweenChangedConnection then
		controller.tweenChangedConnection:Disconnect()
		controller.tweenChangedConnection = nil
	end

	if controller.tweenProxy then
		controller.tweenProxy:Destroy()
		controller.tweenProxy = nil
	end
end

local function getTraitSpeedMultiplier(controller: FishController): number
	local trait = controller.fish:GetAttribute("FishTrait")

	if trait == "Fast" then
		return 1.2
	end

	if trait == "Aggressive" or trait == "Alpha" then
		return 1.15
	end

	if trait == "Lazy" then
		return 0.82
	end

	return 1
end

local function getClosestFoodTarget(foodTargets: { Vector3 }?, fishPart: BasePart): Vector3?
	if not foodTargets or #foodTargets == 0 then
		return nil
	end

	local bestTarget = nil
	local bestDistance = math.huge

	for _, targetPosition in foodTargets do
		local distance = (targetPosition - fishPart.Position).Magnitude
		if distance < bestDistance then
			bestDistance = distance
			bestTarget = targetPosition
		end
	end

	return bestTarget
end

local function animateFish(self: MovementServiceServer, controller: FishController, controllers: { FishController })
	local fishPart = getInstancePrimaryPart(controller.fish)
	if not fishPart then
		return
	end

	moveFishIntoBoundary(controller, getOtherTargetPositions(controllers, controller.boundary, controller))
	clearLegacyFishDisplay(controller)

	task.spawn(function()
		while not controller.cancelled and controller.fish.Parent and controller.boundary.Parent do
			local foodTargetPosition = getClosestFoodTarget(self.foodTargets[controller.boundary], fishPart)
			local targetPosition = nil
			local isFoodTarget = false

			if foodTargetPosition then
				targetPosition = foodTargetPosition
				isFoodTarget = true
			else
				targetPosition = chooseSpacedTarget(
					controller.boundary,
					fishPart,
					getOtherTargetPositions(controllers, controller.boundary, controller)
				)
			end

			if not targetPosition then
				task.wait(1)
				continue
			end

			controller.targetPosition = targetPosition
			local target = getRandomTarget(controller.boundary, fishPart, targetPosition)
			if not target then
				task.wait(1)
				continue
			end

			local currentPivot = getInstancePivot(controller.fish)
			if not currentPivot then
				break
			end

			local distance = (target.Position - currentPivot.Position).Magnitude
			local traitMultiplier = getTraitSpeedMultiplier(controller)
			local speed = if isFoodTarget
				then FOOD_FISH_SPEED * traitMultiplier
				else FISH_SPEED * traitMultiplier
			local minDuration = if isFoodTarget then FOOD_MOVE_MIN else FISH_MOVE_MIN
			local maxDuration = if isFoodTarget then FOOD_MOVE_MAX else FISH_MOVE_MAX
			local duration = math.clamp(distance / speed, minDuration, maxDuration)
			local proxy = Instance.new("CFrameValue")
			proxy.Value = currentPivot

			local tween = TweenService:Create(
				proxy,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Value = target }
			)

			stopControllerTween(controller)

			controller.mode = if isFoodTarget then "Food" else "Swim"
			controller.activeTween = tween
			controller.tweenProxy = proxy
			controller.tweenChangedConnection = proxy:GetPropertyChangedSignal("Value"):Connect(function()
				pivotInstanceTo(controller.fish, proxy.Value)
			end)

			tween:Play()
			tween.Completed:Wait()
			stopControllerTween(controller)

			if not isFoodTarget then
				task.wait(math.random(FISH_IDLE_MIN * 100, FISH_IDLE_MAX * 100) / 100)
			else
				task.wait(0.05)
			end
		end

		stopControllerTween(controller)
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

local function getFishInstancesFromContainer(container: Instance): { Instance }
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

function MovementServiceServer.new(): MovementServiceServer
	local self = setmetatable({
		bubbleLoops = {},
		controllers = {},
		foodTargets = {},
	}, MovementServiceServer)

	task.spawn(function()
		self:initialize()
	end)

	return self
end

function MovementServiceServer:startBubbleLoop(boundary: Instance)
	if self.bubbleLoops[boundary] then
		return
	end

	self.bubbleLoops[boundary] = true

	local soundHost = getSoundHost(boundary)
	if not soundHost then
		return
	end

	task.spawn(function()
		while self.bubbleLoops[boundary] and boundary.Parent do
			local sound = Instance.new("Sound")
			sound.Name = "AquariumBubble"
			sound.SoundId = BUBBLE_SOUND_ID
			sound.RollOffMaxDistance = BUBBLE_MAX_DISTANCE
			sound.RollOffMode = Enum.RollOffMode.InverseTapered
			sound.Volume = BUBBLE_VOLUME
			sound.Parent = soundHost
			sound:Play()

			sound.Ended:Connect(function()
				sound:Destroy()
			end)

			task.wait(BUBBLE_INTERVAL)
		end
	end)
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
			local fishContainer = findNamedDescendant(plotModel, "Fish")
			if not tankBoundary or not fishContainer then
				continue
			end

			local boundaryCFrame, boundarySize = getBoundaryBox(tankBoundary)
			if not boundaryCFrame or not boundarySize then
				warn(("[MovementService] `%s` has Fish/Tank but they are not movable yet"):format(plotModel.Name))
				continue
			end

			for _, fish in getFishInstancesFromContainer(fishContainer) do
				local fishPart = getInstancePrimaryPart(fish)
				if fishPart then
					clearLegacyFishState(fish)

					local controller = {
						activeTween = nil,
						boundary = tankBoundary,
						cancelled = false,
						fish = fish,
						mode = "Swim",
						targetPosition = nil,
						tweenChangedConnection = nil,
						tweenProxy = nil,
					}

					table.insert(self.controllers, controller)
					foundControllers += 1
				end
			end
		end

		if foundControllers > 0 then
			for boundary in self.bubbleLoops do
				self.bubbleLoops[boundary] = nil
			end

			for _, controller in self.controllers do
				if not controller.cancelled then
					self:startBubbleLoop(controller.boundary)
					animateFish(self, controller, self.controllers)
				end
			end

			return
		end

		if attempt < INITIALIZE_RETRIES then
			task.wait(INITIALIZE_RETRY_DELAY)
		else
			warn("[MovementService] No Fish/Tank pairs were found inside Workspace.Map.Tanks")
		end
	end
end

function MovementServiceServer:setFoodTargets(boundary: Instance, positions: { Vector3 })
	self.foodTargets[boundary] = positions

	for _, controller in self.controllers do
		if not controller.cancelled and controller.boundary == boundary then
			stopControllerTween(controller)
		end
	end
end

function MovementServiceServer:clearFoodTarget(boundary: Instance)
	self.foodTargets[boundary] = {}
end

function MovementServiceServer:getClosestFishDistance(boundary: Instance, position: Vector3): number?
	local closestDistance = nil

	for _, controller in self.controllers do
		if not controller.cancelled and controller.boundary == boundary then
			local fishPart = getInstancePrimaryPart(controller.fish)
			if fishPart then
				local distance = (fishPart.Position - position).Magnitude
				if closestDistance == nil or distance < closestDistance then
					closestDistance = distance
				end
			end
		end
	end

	return closestDistance
end

function MovementServiceServer:getFishAtFood(boundary: Instance, position: Vector3, maxDistance: number): Instance?
	local closestController = nil
	local closestDistance = maxDistance

	for _, controller in self.controllers do
		if not controller.cancelled and controller.boundary == boundary then
			local fishPart = getInstancePrimaryPart(controller.fish)
			if fishPart then
				local distance = (fishPart.Position - position).Magnitude
				if distance <= closestDistance then
					closestDistance = distance
					closestController = controller
				end
			end
		end
	end

	if closestController then
		return closestController.fish
	end

	return nil
end

function MovementServiceServer:feedFish(fish: Instance, _amount: number?): boolean
	for _, controller in self.controllers do
		if controller.fish == fish and not controller.cancelled then
			controller.fish:SetAttribute("LastFedAt", os.time())
			return true
		end
	end

	return false
end

function MovementServiceServer:destroy()
	for _, controller in self.controllers do
		controller.cancelled = true
		stopControllerTween(controller)
		clearLegacyFishDisplay(controller)
	end

	for boundary in self.bubbleLoops do
		self.bubbleLoops[boundary] = nil
	end

	self.controllers = {}
	self.foodTargets = {}
end

return MovementServiceServer
