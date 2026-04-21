local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type Props = {
	title: string,
	subtitle: string?,
	size: UDim2,
	position: UDim2,
	onClose: (() -> ())?,
	children: any,
}

local function Panel(props: Props)
	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(242, 248, 255),
		BorderSizePixel = 0,
		Position = props.position,
		Size = props.size,
	}, {
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 28),
		}),
		Stroke = e("UIStroke", {
			Color = Color3.fromRGB(24, 34, 54),
			Thickness = 4,
		}),
		Header = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(65, 163, 255),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 82),
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(0, 28),
			}),
			Fix = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromRGB(65, 163, 255),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.new(1, 0, 0, 32),
			}),
			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Position = UDim2.fromOffset(22, 10),
				Size = UDim2.new(1, -90, 0, 28),
				Text = props.title,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				TextStrokeTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = e("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Position = UDim2.fromOffset(24, 42),
				Size = UDim2.new(1, -120, 0, 18),
				Text = props.subtitle or "",
				TextColor3 = Color3.fromRGB(226, 243, 255),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Close = e("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 97, 97),
				BorderSizePixel = 0,
				Position = UDim2.new(1, -18, 0.5, 0),
				Size = UDim2.fromOffset(40, 40),
				Text = "X",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.FredokaOne,
				TextScaled = true,
				[React.Event.Activated] = props.onClose,
			}, {
				Corner = e("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				Stroke = e("UIStroke", {
					Color = Color3.fromRGB(0, 0, 0),
					Thickness = 3,
				}),
			}),
		}),
		Body = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 94),
			Size = UDim2.new(1, -36, 1, -112),
		}, props.children),
	})
end

return Panel
