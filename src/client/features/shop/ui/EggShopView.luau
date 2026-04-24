local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Create = require(script.Parent.Create)
local EggCard = require(script.Parent.Components.EggCard)
local formatNumber = require(script.Parent.FormatNumber)
local ShopButton = require(script.Parent.Components.ShopButton)
local Theme = require(script.Parent.Theme)

local localPlayer = Players.LocalPlayer

local EggShopView = {}
EggShopView.__index = EggShopView

local BASE_LAYOUT_SIZE = Vector2.new(560, 620)

type EggShopViewProps = {
	onBuy: (string) -> (),
	onClose: () -> (),
}

local function createShadow(parent: Instance, zIndex: number)
	local shadow = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(4, 10, 19),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 20, 1, 20),
		ZIndex = zIndex,
		Parent = parent,
	})

	Create("UICorner", {
		CornerRadius = Theme.cornerRadius,
		Parent = shadow,
	})
end

function EggShopView.new(props: EggShopViewProps)
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local self = setmetatable({
		busyEggId = nil,
		cardViews = {},
		currentSnapshot = nil,
		onBuy = props.onBuy,
		onClose = props.onClose,
		visible = false,
	}, EggShopView)

	self.screenGui = Create("ScreenGui", {
		DisplayOrder = 25,
		IgnoreGuiInset = true,
		Name = "EggShopGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})

	self.backdropButton = Create("TextButton", {
		Active = true,
		AutoButtonColor = false,
		BackgroundColor3 = Theme.colors.backdrop,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Modal = true,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Visible = false,
		ZIndex = 1,
		Parent = self.screenGui,
	})

	self.modalShadow = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.new(0.94, 0, 0.86, 0),
		Visible = false,
		ZIndex = 1,
		Parent = self.screenGui,
	})

	createShadow(self.modalShadow, 1)

	self.modal = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.colors.panel,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.94, 0, 0.86, 0),
		Visible = false,
		ZIndex = 2,
		Parent = self.screenGui,
	})

	Create("UISizeConstraint", {
		MaxSize = Vector2.new(640, 800),
		MinSize = Vector2.new(340, 460),
		Parent = self.modal,
	})

	Create("UICorner", {
		CornerRadius = Theme.cornerRadius,
		Parent = self.modal,
	})

	self.modalStroke = Create("UIStroke", {
		Color = Theme.colors.stroke,
		Thickness = 8,
		Parent = self.modal,
	})

	self.header = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -40),
		Size = UDim2.new(1, 0, 0, 120),
		ZIndex = 10,
		Parent = self.modal,
	})

	self.titleLabel = Create("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Font = Theme.fonts.heading,
		Position = UDim2.fromScale(0.05, 0.4),
		Size = UDim2.new(0.6, 0, 0, 80),
		Text = "EGGS",
		TextColor3 = Theme.colors.text,
		TextSize = 82, -- Huge stylized title
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
		Parent = self.header,
	})

	Create("UIStroke", {
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 6,
		Parent = self.titleLabel,
	})

	self.restockFrame = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 60, 20),
		Position = UDim2.new(0.95, -60, 0.2, 0),
		Size = UDim2.fromOffset(160, 56),
		ZIndex = 11,
		Parent = self.header,
	})

	Create("UICorner", {
		CornerRadius = UDim.new(0, 12),
		Parent = self.restockFrame,
	})

	Create("UIStroke", {
		Color = Color3.fromRGB(0, 100, 40),
		Thickness = 4,
		Parent = self.restockFrame,
	})

	self.restockTitle = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.fonts.body,
		Size = UDim2.new(1, 0, 1.2, 0), -- Slightly offset up
		Position = UDim2.fromScale(0, -0.4),
		Text = "Restocking in:",
		TextColor3 = Color3.fromRGB(200, 255, 220),
		TextSize = 18,
		ZIndex = 12,
		Parent = self.restockFrame,
	})

	self.restockTime = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.fonts.heading,
		Size = UDim2.fromScale(1, 1),
		Text = "3:09",
		TextColor3 = Theme.colors.text,
		TextSize = 28,
		ZIndex = 12,
		Parent = self.restockFrame,
	})

	self.closeButtonFrame = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Color3.fromRGB(220, 40, 40),
		Position = UDim2.new(1.05, 0, -0.05, 0),
		Size = UDim2.fromOffset(64, 64),
		Text = "X",
		TextColor3 = Theme.colors.text,
		Font = Theme.fonts.heading,
		TextSize = 36,
		ZIndex = 15,
		Parent = self.modal,
	})

	Create("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = self.closeButtonFrame,
	})

	Create("UIStroke", {
		Color = Theme.colors.stroke,
		Thickness = 4,
		Parent = self.closeButtonFrame,
	})

	self.balanceChip = Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.colors.surfaceMuted,
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(240, 42),
		Text = "Balance: 0",
		TextColor3 = Theme.colors.textDark,
		Font = Theme.fonts.heading,
		TextSize = 20,
		ZIndex = 3,
		Parent = self.modal,
	})

	Create("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = self.balanceChip,
	})

	self.noticeLabel = Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		Font = Theme.fonts.body,
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -40, 0, 20),
		Text = "",
		TextColor3 = Theme.colors.subtext,
		TextSize = 14,
		ZIndex = 3,
		Parent = self.modal,
	})

	self.listFrame = Create("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.fromOffset(28, 120),
		ScrollBarImageColor3 = Theme.colors.panelTop,
		ScrollBarThickness = 8,
		Size = UDim2.new(1, -56, 1, -140),
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		ZIndex = 3,
		Parent = self.modal,
	})

	self.listLayout = Create("UIListLayout", {
		Padding = UDim.new(0, 20),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.listFrame,
	})

	self.listPadding = Create("UIPadding", {
		PaddingBottom = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
		Parent = self.listFrame,
	})

	self.backdropButton.Activated:Connect(function()
		self.onClose()
	end)

	self.closeButtonFrame.Activated:Connect(function()
		self.onClose()
	end)

	self.modal:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		-- Removed updateResponsiveScale call
	end)

	-- Removed updateResponsiveScale call


	return self
end

function EggShopView:updateResponsiveScale()
	local absoluteSize = self.modal.AbsoluteSize
	if absoluteSize.X <= 0 or absoluteSize.Y <= 0 then
		return
	end

	local widthScale = absoluteSize.X / BASE_LAYOUT_SIZE.X
	local heightScale = absoluteSize.Y / BASE_LAYOUT_SIZE.Y
	self.modalScale.Scale = math.min(widthScale, heightScale, 1)
end

function EggShopView:setNotice(message: string, isError: boolean)
	self.noticeLabel.Text = message
	self.noticeLabel.TextColor3 = if isError then Theme.colors.error else Theme.colors.subtext
end

function EggShopView:setBusyEggId(eggId: string?)
	self.busyEggId = eggId

	if self.currentSnapshot then
		self:render(self.currentSnapshot, eggId)
	end
end

function EggShopView:isVisible(): boolean
	return self.visible
end

function EggShopView:setVisible(isVisible: boolean)
	if self.visible == isVisible then
		return
	end

	self.visible = isVisible

	if isVisible then
		self.backdropButton.Visible = true
		self.modal.Visible = true
		self.modalShadow.Visible = true
		self.modal.Position = UDim2.fromScale(0.5, 0.5)
		self.modalShadow.Position = UDim2.fromScale(0.5, 0.5)

		TweenService:Create(self.backdropButton, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.32,
		}):Play()

		TweenService:Create(self.modalShadow, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.5),
		}):Play()
	else
		TweenService:Create(self.backdropButton, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()

		local modalTween = TweenService:Create(self.modal, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromScale(0.5, 0.56),
		})
		local shadowTween = TweenService:Create(self.modalShadow, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromScale(0.5, 0.54),
		})

		modalTween:Play()
		shadowTween:Play()

		task.delay(0.18, function()
			if self.visible then
				return
			end

			self.backdropButton.Visible = false
			self.modal.Visible = false
			self.modalShadow.Visible = false
		end)
	end
end

function EggShopView:ensureCardCount(count: number)
	for index = #self.cardViews + 1, count do
		self.cardViews[index] = EggCard.new({
			parent = self.listFrame,
			layoutOrder = index,
			onBuy = function(eggId)
				self.onBuy(eggId)
			end,
		})
	end

	for index = count + 1, #self.cardViews do
		local card = self.cardViews[index]
		card.instance:Destroy()
		self.cardViews[index] = nil
	end
end

function EggShopView:render(snapshot, busyEggId: string?)
	self.currentSnapshot = snapshot

	self.titleLabel.Text = snapshot.title or "Fish Egg Shop"
	self.balanceChip.Text = (`Balance: {formatNumber(snapshot.balance or 0)} Coins`)

	local items = snapshot.items or {}
	self:ensureCardCount(#items)

	for index, item in items do
		local card = self.cardViews[index]
		card.instance.LayoutOrder = index
		card:update(item, snapshot.balance or 0, busyEggId == item.id)
	end
end

return EggShopView
