local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Create = require(script.Parent.Parent.shop.ui.Create)
local formatCompactNumber = require(script.Parent.FormatCompactNumber)

local localPlayer = Players.LocalPlayer

local MoneyHudView = {}
MoneyHudView.__index = MoneyHudView

function MoneyHudView.new()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local self = setmetatable({
		activeTween = nil,
		cameraConnection = nil,
		currentAmount = nil,
		viewportConnection = nil,
	}, MoneyHudView)

	self.screenGui = Create("ScreenGui", {
		DisplayOrder = 30,
		IgnoreGuiInset = true,
		Name = "MoneyHudGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})

	self.root = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.015, 0, 0.955, 0),
		Size = UDim2.new(0, 360, 0, 72),
		ZIndex = 20,
		Parent = self.screenGui,
	})

	Create("UISizeConstraint", {
		MaxSize = Vector2.new(380, 80),
		MinSize = Vector2.new(200, 48),
		Parent = self.root,
	})

	Create("UIPadding", {
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 4),
		Parent = self.root,
	})

	self.scale = Create("UIScale", {
		Scale = 0.92,
		Parent = self.root,
	})

	self.amountLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		Text = "$0",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 21,
		Parent = self.root,
	})

	Create("UIStroke", {
		Color = Color3.fromRGB(85, 85, 255),
		Thickness = 4.5,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = self.amountLabel,
	})

	Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 245, 255)),
		}),
		Rotation = 90,
		Parent = self.amountLabel,
	})

	self:updateScale()
	self:bindViewport()

	return self
end

function MoneyHudView:updateScale()
	local camera = Workspace.CurrentCamera
	local viewportSize = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
	local minAxis = math.min(viewportSize.X, viewportSize.Y)
	self.scale.Scale = math.clamp((minAxis / 1080) * 0.92, 0.64, 0.96)
end

function MoneyHudView:bindViewport()
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

function MoneyHudView:setAmount(amount: number)
	local roundedAmount = math.max(0, math.floor(amount))
	if self.currentAmount == roundedAmount then
		return
	end

	self.currentAmount = roundedAmount

	local displayText = "$" .. formatCompactNumber(roundedAmount)
	self.amountLabel.Text = displayText

	if self.activeTween then
		self.activeTween:Cancel()
	end

	self.scale.Scale = math.min(self.scale.Scale + 0.05, 1.01)
	local tween = TweenService:Create(self.scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = math.clamp((math.min((if Workspace.CurrentCamera then math.min(Workspace.CurrentCamera.ViewportSize.X, Workspace.CurrentCamera.ViewportSize.Y) else 1080) / 1080, 1)) * 0.92, 0.64, 0.96),
	})
	self.activeTween = tween
	tween.Completed:Connect(function()
		if self.activeTween == tween then
			self.activeTween = nil
		end
	end)
	tween:Play()
end

function MoneyHudView:Destroy()
	if self.activeTween then
		self.activeTween:Cancel()
		self.activeTween = nil
	end

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

return MoneyHudView
