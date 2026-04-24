local Create = require(script.Parent.Parent.Create)
local formatNumber = require(script.Parent.Parent.FormatNumber)
local Theme = require(script.Parent.Parent.Theme)
local ShopButton = require(script.Parent.ShopButton)

local EggCard = {}
EggCard.__index = EggCard

local function getFishInitials(name: string): string
	local words = string.split(name, " ")
	local initials = ""

	for _, word in words do
		if #word > 0 then
			initials ..= string.upper(string.sub(word, 1, 1))
		end

		if #initials >= 2 then
			break
		end
	end

	if initials == "" then
		return "EG"
	end

	return initials
end

local function setChipColor(label: TextLabel, color: Color3)
	label.BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.22)
	label.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.6)
end

type EggCardProps = {
	parent: Instance,
	layoutOrder: number?,
	onBuy: (string) -> (),
}

function EggCard.new(props: EggCardProps)
	local self = setmetatable({
		eggId = nil,
		onBuy = props.onBuy,
	}, EggCard)

	self.instance = Create("Frame", {
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundColor3 = Theme.colors.surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = props.layoutOrder or 1,
		Size = UDim2.new(1, 0, 0, 160),
		Parent = props.parent,
	})

	Create("UICorner", {
		CornerRadius = Theme.cardCornerRadius,
		Parent = self.instance,
	})

	self.whiteStroke = Create("UIStroke", {
		Color = Theme.colors.stroke,
		Thickness = 4,
		Parent = self.instance,
	})

	self.iconFrame = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(34, 12, 12),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(20, 80),
		Size = UDim2.fromOffset(120, 120),
		ZIndex = 2,
		Parent = self.instance,
	})

	Create("UIStroke", {
		Color = Color3.fromRGB(74, 18, 18),
		Thickness = 4,
		Parent = self.iconFrame,
	})

	self.iconLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.fonts.heading,
		Size = UDim2.fromScale(1, 1),
		Text = "EG",
		TextColor3 = Theme.colors.text,
		TextSize = 42,
		ZIndex = 3,
		Parent = self.iconFrame,
	})

	self.eggNameLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.fonts.heading,
		Position = UDim2.fromOffset(150, 15),
		Size = UDim2.new(1, -170, 0, 36),
		Text = "Egg Name",
		TextColor3 = Theme.colors.textDark,
		TextSize = 32,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
		Parent = self.instance,
	})

	self.starContainer = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(150, 52),
		Size = UDim2.fromOffset(100, 24),
		ZIndex = 2,
		Parent = self.instance,
	})

	self.starLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.fonts.body,
		Size = UDim2.fromScale(1, 1),
		Text = "⭐⭐",
		TextColor3 = Theme.colors.warning,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
		Parent = self.starContainer,
	})

	self.stockLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.fonts.body,
		Position = UDim2.fromOffset(150, 78),
		Size = UDim2.new(0, 100, 0, 24),
		Text = "17x",
		TextColor3 = Theme.colors.textDark,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
		Parent = self.instance,
	})

	self.priceLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.fonts.heading,
		Position = UDim2.fromOffset(150, 108),
		Size = UDim2.fromOffset(150, 42),
		Text = "$20",
		TextColor3 = Theme.colors.success,
		TextSize = 38,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
		Parent = self.instance,
	})

	Create("UIStroke", {
		Color = Color3.fromRGB(0, 44, 18),
		Thickness = 4,
		Parent = self.priceLabel,
	})

	self.buyButton = ShopButton.new({
		parent = self.instance,
		position = UDim2.new(1, -160, 1, -60),
		size = UDim2.fromOffset(140, 44),
		text = "COMMON",
		zIndex = 3,
		onActivated = function()
			if self.eggId then
				self.onBuy(self.eggId)
			end
		end,
	})

	return self
end

function EggCard:update(item: { [string]: any }, balance: number, isBusy: boolean)
	self.eggId = item.id

	self.eggNameLabel.Text = item.name
	self.stockLabel.Text = (`{formatNumber(item.stock)}x`)
	self.priceLabel.Text = (`${formatNumber(item.price)}`)

	-- Style stars based on rarity or name for now
	local stars = ""
	if item.rarity == "Common" then stars = "⭐"
	elseif item.rarity == "Uncommon" then stars = "⭐⭐"
	elseif item.rarity == "Rare" then stars = "⭐⭐⭐"
	elseif item.rarity == "Legendary" then stars = "⭐⭐⭐⭐"
	else stars = "⭐" end
	self.starLabel.Text = stars

	local accentColor = item.accentColor or item.color or Theme.colors.rarityCommon
	if item.rarity == "Uncommon" then accentColor = Theme.colors.rarityUncommon end

	local inStock = (item.stock or 0) > 0
	local canAfford = balance >= (item.price or 0)
	local canBuy = inStock and canAfford and not isBusy
	
	local buttonText = string.upper(item.rarity or "Common")

	if isBusy then
		buttonText = "PENDING..."
	elseif not inStock then
		buttonText = "SOLD OUT"
	elseif not canAfford then
		buttonText = "NO COINS"
	end

	self.buyButton:update(buttonText, canBuy, accentColor)
end

return EggCard
