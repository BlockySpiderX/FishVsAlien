local function formatNumber(value: number): string
	local formatted = tostring(math.floor(value))

	while true do
		local nextValue, substitutions = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		formatted = nextValue

		if substitutions == 0 then
			break
		end
	end

	return formatted
end

return formatNumber
