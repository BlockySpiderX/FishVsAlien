local Create = require(script.Parent.Parent.Create)
local Theme = require(script.Parent.Parent.Theme)

local ShopButton = {}
ShopButton.__index = ShopButton

type ButtonProps = {
	parent: Instance,
	position: UDim2?,
	size: UDim2?,
	text: string?,
	zIndex: number?,
	onActivated: (() -> ())?,
}

function ShopButton.new(props: ButtonProps)
	local self = setmetatable({}, ShopButton)
	local zIndex = props.zIndex or 1

	self.instance = Create("TextButton", {
		AnchorPoint = Vector2.new(0, 0),
		AutoButtonColor = true,
		BackgroundColor3 = Theme.colors.surfaceMuted,
		BorderSizePixel = 0,
		Font = Theme.fonts.button,
		Position = props.position or UDim2.new(),
		Size = props.size or UDim2.fromOffset(140, 42),
		Text = props.text or "Action",
		TextColor3 = Theme.colors.text,
		TextSize = 18,
		ZIndex = zIndex,
		Parent = props.parent,
	})

	Create("UICorner", {
		CornerRadius = Theme.buttonCornerRadius,
		Parent = self.instance,
	})

	self.stroke = Create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 4,
		Parent = self.instance,
	})

	self.textStroke = Create("UIStroke", {
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 3,
		Parent = self.instance,
	})

	self.gradient = Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(0.6, 0.6, 0.6)),
		}),
		Rotation = 90,
		Parent = self.instance,
	})

	if props.onActivated then
		self.instance.Activated:Connect(props.onActivated)
	end

	return self
end

function ShopButton:update(text: string, enabled: boolean, accentColor: Color3?)
	local baseColor = accentColor or Theme.colors.cardHighlight
	local darkerColor = baseColor:Lerp(Color3.new(0, 0, 0), 0.4)
	local lighterColor = baseColor:Lerp(Color3.new(1, 1, 1), 0.3)

	self.instance.Text = text
	self.instance.Active = enabled
	self.instance.Selectable = enabled
	self.instance.TextTransparency = if enabled then 0 else 0.4

	if enabled then
		self.instance.BackgroundColor3 = baseColor
		self.stroke.Color = darkerColor
		self.gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, lighterColor),
			ColorSequenceKeypoint.new(1, baseColor),
		})
	else
		self.instance.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
		self.stroke.Color = Color3.fromRGB(60, 60, 60)
		self.gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 150, 150)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100)),
		})
	end
end

return ShopButton
