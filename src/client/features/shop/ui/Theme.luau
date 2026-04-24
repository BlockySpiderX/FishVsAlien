local Theme = {
	cornerRadius = UDim.new(0, 24),
	cardCornerRadius = UDim.new(0, 12),
	buttonCornerRadius = UDim.new(0, 10),

	fonts = {
		title = Enum.Font.FredokaOne,
		heading = Enum.Font.LuckiestGuy,
		body = Enum.Font.FredokaOne,
		button = Enum.Font.FredokaOne,
	},

	colors = {
		backdrop = Color3.fromRGB(0, 0, 0),
		panel = Color3.fromRGB(74, 18, 18), -- Dark Maroon
		panelTop = Color3.fromRGB(114, 30, 30),
		panelBottom = Color3.fromRGB(54, 12, 12),
		surface = Color3.fromRGB(245, 209, 164), -- Tan/Wood
		surfaceMuted = Color3.fromRGB(215, 179, 134),
		card = Color3.fromRGB(255, 230, 190), -- Light Tan
		cardHighlight = Color3.fromRGB(152, 60, 34), -- Darker Orange/Brown for emphasis
		stroke = Color3.fromRGB(255, 255, 255), -- White outline
		text = Color3.fromRGB(255, 255, 255),
		textDark = Color3.fromRGB(74, 18, 18),
		subtext = Color3.fromRGB(134, 44, 44),
		success = Color3.fromRGB(85, 255, 127), -- Green for price
		error = Color3.fromRGB(255, 85, 85),
		warning = Color3.fromRGB(255, 170, 0),
		
		rarityCommon = Color3.fromRGB(100, 130, 210),
		rarityUncommon = Color3.fromRGB(100, 210, 130),
	},
}

return Theme
