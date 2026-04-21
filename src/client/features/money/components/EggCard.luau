local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local formatters = require(script.Parent.Parent.utils.formatters)

local e = React.createElement

export type Props = {
	egg: any,
	onBuy: ((string) -> ())?,
}

local function EggCard(props: Props)
	local egg = props.egg
	local accentColor = egg.color or Color3.fromRGB(255, 255, 255)

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(188, 232),
	}, {
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 24),
		}),
		Stroke = e("UIStroke", {
			Color = Color3.fromRGB(24, 34, 54),
			Thickness = 3,
		}),
		Header = e("Frame", {
			BackgroundColor3 = accentColor,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 90),
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(0, 24),
			}),
			Fix = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = accentColor,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.new(1, 0, 0, 24),
			}),
			Preview = e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Position = UDim2.fromScale(0.5, 0.58),
				Size = UDim2.fromOffset(92, 56),
				Text = "EGG",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				TextStrokeTransparency = 0,
			}),
		}),
		Name = e("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			Position = UDim2.fromOffset(16, 102),
			Size = UDim2.fromOffset(156, 32),
			Text = egg.name,
			TextColor3 = Color3.fromRGB(29, 35, 49),
			TextScaled = true,
			TextWrapped = true,
		}),
		Rarity = e("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(16, 136),
			Size = UDim2.fromOffset(156, 18),
			Text = egg.rarity,
			TextColor3 = accentColor:Lerp(Color3.fromRGB(0, 0, 0), 0.35),
			TextScaled = true,
		}),
		Desc = e("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Position = UDim2.fromOffset(16, 160),
			Size = UDim2.fromOffset(156, 28),
			Text = "Adds this egg to your permanent inventory.",
			TextColor3 = Color3.fromRGB(110, 120, 144),
			TextScaled = true,
			TextWrapped = true,
		}),
		Buy = e("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.fromRGB(28, 34, 48),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.94),
			Size = UDim2.fromOffset(148, 40),
			Text = formatters.formatMoney(egg.price),
			TextColor3 = Color3.fromRGB(255, 224, 112),
			Font = Enum.Font.FredokaOne,
			TextScaled = true,
			[React.Event.Activated] = function()
				if props.onBuy then
					props.onBuy(egg.id)
				end
			end,
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			Stroke = e("UIStroke", {
				Color = Color3.fromRGB(0, 0, 0),
				Thickness = 3,
			}),
		}),
	})
end

return EggCard
