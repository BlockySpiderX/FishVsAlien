local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type Props = {
	index: number,
	name: string,
	count: number,
}

local function InventoryCard(props: Props)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 88),
	}, {
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 18),
		}),
		Stroke = e("UIStroke", {
			Color = Color3.fromRGB(24, 34, 54),
			Thickness = 3,
		}),
		Index = e("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(88, 176, 255),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(14, 44),
			Size = UDim2.fromOffset(52, 52),
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(0, 16),
			}),
			Number = e("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Size = UDim2.fromScale(1, 1),
				Text = tostring(props.index),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				TextStrokeTransparency = 0,
			}),
		}),
		Name = e("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			Position = UDim2.fromOffset(78, 16),
			Size = UDim2.new(1, -170, 0, 30),
			Text = props.name,
			TextColor3 = Color3.fromRGB(29, 35, 49),
			TextScaled = true,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Subtitle = e("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(78, 48),
			Size = UDim2.new(1, -170, 0, 18),
			Text = "Stored in backpack",
			TextColor3 = Color3.fromRGB(101, 113, 137),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Count = e("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 206, 92),
			BorderSizePixel = 0,
			Position = UDim2.new(1, -18, 0.5, 0),
			Size = UDim2.fromOffset(78, 42),
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
				TextColor3 = Color3.fromRGB(43, 43, 43),
				TextScaled = true,
			}),
		}),
	})
end

return InventoryCard
