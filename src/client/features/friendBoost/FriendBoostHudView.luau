local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Create = require(script.Parent.Parent.shop.ui.Create)

local localPlayer = Players.LocalPlayer

local FriendBoostHudView = {}
FriendBoostHudView.__index = FriendBoostHudView

function FriendBoostHudView.new()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local self = setmetatable({
		cameraConnection = nil,
		currentBoostText = nil,
		viewportConnection = nil,
	}, FriendBoostHudView)

	self.screenGui = Create("ScreenGui", {
		DisplayOrder = 30,
		IgnoreGuiInset = true,
		Name = "FriendBoostHudGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})

	self.root = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.02, 0, 0.995, 0),
		Size = UDim2.new(0, 260, 0, 34),
		ZIndex = 20,
		Parent = self.screenGui,
	})

	Create("UISizeConstraint", {
		MaxSize = Vector2.new(300, 40),
		MinSize = Vector2.new(180, 26),
		Parent = self.root,
	})

	self.scale = Create("UIScale", {
		Scale = 0.92,
		Parent = self.root,
	})

	self.boostLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		Size = UDim2.fromScale(0.8, 0.8),
		Text = "Friend Boost: +0%",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 21,
		Parent = self.root,
	})

	Create("UIStroke", {
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 3,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = self.boostLabel,
	})

	self:updateScale()
	self:bindViewport()

	return self
end

function FriendBoostHudView:updateScale()
	local camera = Workspace.CurrentCamera
	local viewportSize = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
	local minAxis = math.min(viewportSize.X, viewportSize.Y)
	self.scale.Scale = math.clamp((minAxis / 1080) * 0.92, 0.64, 0.96)
end

function FriendBoostHudView:bindViewport()
	local function attachToCamera(camera: Camera?)
		if self.viewportConnection then
			self.viewportConnection:Disconnect()
			self.viewportConnection = nil
		end

		if not camera then
			self:updateScale()
			return
		end

		self:updateScale()
		self.viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self:updateScale()
		end)
	end

	self.cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		attachToCamera(Workspace.CurrentCamera)
	end)

	attachToCamera(Workspace.CurrentCamera)
end

function FriendBoostHudView:setBoostPercent(boostPercent: number)
	local roundedBoost = math.max(0, math.floor(boostPercent + 0.5))
	local displayText = `Friend Boost: +{roundedBoost}%`

	if self.currentBoostText == displayText then
		return
	end

	self.currentBoostText = displayText
	self.boostLabel.Text = displayText
end

function FriendBoostHudView:Destroy()
	if self.viewportConnection then
		self.viewportConnection:Disconnect()
		self.viewportConnection = nil
	end

	if self.cameraConnection then
		self.cameraConnection:Disconnect()
		self.cameraConnection = nil
	end

	if self.screenGui then
		self.screenGui:Destroy()
		self.screenGui = nil
	end

	setmetatable(self, nil)
end

return FriendBoostHudView
