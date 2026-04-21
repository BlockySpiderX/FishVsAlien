local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type Props = {
	index: number,
	name: string,
	count: number,
}

local function HotbarSlot(props: Props)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(39, 42, 55),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(126, 68),
	}, {
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
		Stroke = e("UIStroke", {
			Color = Color3.fromRGB(14, 15, 20),
			Thickness = 3,
		}),
		Accent = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(95, 210, 255),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 5),
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
		}),
		Index = e("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			Position = UDim2.fromOffset(10, 8),
			Size = UDim2.fromOffset(18, 14),
			Text = tostring(props.index),
			TextColor3 = Color3.fromRGB(174, 179, 201),
			TextScaled = true,
			TextStrokeTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Name = e("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(10, 22),
			Size = UDim2.fromOffset(104, 24),
			Text = props.name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}),
		Count = e("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 97, 97),
			BorderSizePixel = 0,
			Position = UDim2.new(1, -8, 1, -8),
			Size = UDim2.fromOffset(38, 22),
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			Stroke = e("UIStroke", {
				Color = Color3.fromRGB(0, 0, 0),
				Thickness = 2,
			}),
			Value = e("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Size = UDim2.fromScale(1, 1),
				Text = "x" .. tostring(props.count),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
			}),
		}),
	})
end

return HotbarSlot
