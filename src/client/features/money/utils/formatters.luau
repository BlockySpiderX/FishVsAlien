local formatters = {}

local SUFFIXES = {
	{ value = 1_000_000_000, suffix = "B" },
	{ value = 1_000_000, suffix = "M" },
	{ value = 1_000, suffix = "K" },
}

function formatters.formatCompact(value: number): string
	local absolute = math.abs(value)

	for _, suffixEntry in SUFFIXES do
		if absolute >= suffixEntry.value then
			local scaled = value / suffixEntry.value
			local rounded = math.floor(scaled * 100 + 0.5) / 100
			local whole = math.floor(rounded)

			if math.abs(rounded - whole) < 0.01 then
				return tostring(whole) .. suffixEntry.suffix
			end

			return string.format("%.2f%s", rounded, suffixEntry.suffix)
		end
	end

	return tostring(math.floor(value + 0.5))
end

function formatters.formatMoney(value: number): string
	return "$" .. formatters.formatCompact(value)
end

function formatters.formatDelta(value: number): string
	local prefix = if value >= 0 then "+" else "-"
	return prefix .. formatters.formatMoney(math.abs(value))
end

return formatters
