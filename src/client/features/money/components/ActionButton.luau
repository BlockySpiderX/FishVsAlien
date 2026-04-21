local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type Props = {
	label: string,
	size: UDim2,
	position: UDim2,
	anchorPoint: Vector2?,
	backgroundTop: Color3,
	backgroundBottom: Color3,
	strokeColor: Color3,
	labelColor: Color3?,
	labelSize: number?,
	iconImage: string?,
	iconText: string?,
	iconRotation: number?,
	iconTextColor: Color3?,
	iconPosition: UDim2?,
	iconSize: UDim2?,
	cornerRadius: UDim?,
	shadowTransparency: number?,
	hideLabel: boolean?,
	badgeText: string?,
	onActivated: (() -> ())?,
}

local function ActionButton(props: Props)
	local iconElement

	if props.iconImage then
		iconElement = e("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.iconImage,
			Position = props.iconPosition or UDim2.fromScale(0.5, 0.38),
			Rotation = props.iconRotation or 0,
			Size = props.iconSize or UDim2.fromScale(0.56, 0.56),
		})
	else
		iconElement = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			Position = props.iconPosition or UDim2.fromScale(0.5, 0.38),
			Rotation = props.iconRotation or 0,
			Size = props.iconSize or UDim2.fromScale(0.52, 0.52),
			Text = props.iconText or "?",
			TextColor3 = props.iconTextColor or Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			TextStrokeTransparency = 0,
		})
	end

	return e("ImageButton", {
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		AutoButtonColor = true,
		BackgroundColor3 = props.backgroundTop,
		BorderSizePixel = 0,
		Position = props.position,
		Size = props.size,
		[React.Event.Activated] = props.onActivated,
	}, {
		Corner = e("UICorner", {
			CornerRadius = props.cornerRadius or UDim.new(0, 28),
		}),
		BaseStroke = e("UIStroke", {
			Color = props.strokeColor,
			Thickness = 4,
		}),
		Gradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, props.backgroundTop),
				ColorSequenceKeypoint.new(1, props.backgroundBottom),
			}),
			Rotation = 90,
		}),
		Shadow = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = props.strokeColor,
			BackgroundTransparency = props.shadowTransparency or 0.72,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.56),
			Size = UDim2.fromScale(1, 1),
			ZIndex = -1,
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(0, 32),
			}),
		}),
		Shine = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.84,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.1, 0.08),
			Rotation = -8,
			Size = UDim2.fromScale(0.8, 0.18),
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
		Icon = iconElement,
		Label = not props.hideLabel and e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			Position = UDim2.fromScale(0.5, 0.96),
			Size = UDim2.fromScale(0.92, 0.2),
			Text = props.label,
			TextColor3 = props.labelColor or Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = props.labelSize or 18,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			TextStrokeTransparency = 0,
		}) or nil,
		Badge = props.badgeText and e("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(243, 72, 106),
			BorderSizePixel = 0,
			Position = UDim2.new(1, -6, 0, 6),
			Size = UDim2.fromOffset(34, 34),
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			Stroke = e("UIStroke", {
				Color = Color3.fromRGB(0, 0, 0),
				Thickness = 3,
			}),
			Value = e("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Size = UDim2.fromScale(1, 1),
				Text = props.badgeText,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				TextStrokeTransparency = 0,
			}),
		}) or nil,
	})
end

return ActionButton
