local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type Props = {
	coinsText: string,
	deltaText: string?,
	deltaColor: Color3?,
}

local function MoneyStack(props: Props)
	return e("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.012, 0, 1, -12),
		Size = UDim2.new(0, 300, 0, 126),
	}, {
		Constraint = e("UISizeConstraint", {
			MaxSize = Vector2.new(340, 150),
			MinSize = Vector2.new(190, 92),
		}),
		Delta = props.deltaText and e("Frame", {
			BackgroundColor3 = Color3.fromRGB(28, 28, 28),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.new(0.52, 0, 0, 34),
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
				Text = props.deltaText,
				TextColor3 = props.deltaColor or Color3.fromRGB(255, 88, 88),
				TextScaled = true,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				TextStrokeTransparency = 0,
			}),
		}) or nil,
		Money = e("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			Position = UDim2.fromScale(0, 0.18),
			Size = UDim2.new(0.98, 0, 0.4, 0),
			Text = props.coinsText,
			TextColor3 = Color3.fromRGB(140, 255, 76),
			TextScaled = true,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Glow = e("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			Position = UDim2.new(0.014, 0, 0.205, 0),
			Size = UDim2.new(0.98, 0, 0.4, 0),
			Text = props.coinsText,
			TextColor3 = Color3.fromRGB(236, 255, 97),
			TextScaled = true,
			TextTransparency = 0.78,
			TextStrokeTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 0,
		}),
		Boost = e("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			Position = UDim2.fromScale(0, 0.74),
			Size = UDim2.new(0.82, 0, 0.18, 0),
			Text = "Friend Boost: +0%",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return MoneyStack
