local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local MoneyStack = require(script.Parent.Parent.components.MoneyStack)

local e = React.createElement

export type Props = {
	coinsText: string,
	deltaText: string?,
	deltaColor: Color3?,
	viewportSize: Vector2?,
}

local function MoneyHUDView(props: Props)
	local viewportSize = props.viewportSize or Vector2.new(1920, 1080)
	local minAxis = math.min(viewportSize.X, viewportSize.Y)
	local hudScale = math.clamp(minAxis / 1080, 0.72, 1.08)

	local children = {
		Scale = e("UIScale", {
			Scale = hudScale,
		}),
		Money = e(MoneyStack, {
			coinsText = props.coinsText,
			deltaText = props.deltaText,
			deltaColor = props.deltaColor,
		}),
	}

	return e("Frame", {
		Name = "Root",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, children)
end

return MoneyHUDView
