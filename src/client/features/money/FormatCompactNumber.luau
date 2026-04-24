local SUFFIXES = {
	{ value = 1e15, suffix = "Qa" },
	{ value = 1e12, suffix = "T" },
	{ value = 1e9, suffix = "B" },
	{ value = 1e6, suffix = "M" },
	{ value = 1e3, suffix = "K" },
}

local function trimTrailingZeroes(value: string): string
	value = string.gsub(value, "%.?0+$", "")
	return value
end

local function formatCompactNumber(amount: number): string
	local absoluteAmount = math.abs(amount)

	for _, entry in SUFFIXES do
		if absoluteAmount >= entry.value then
			local scaled = amount / entry.value
			return `{trimTrailingZeroes(string.format("%.2f", scaled))}{entry.suffix}`
		end
	end

	return tostring(math.floor(amount + 0.00001))
end

return formatCompactNumber
