local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).server

local MoneyServiceServer = {}
MoneyServiceServer.__index = MoneyServiceServer

local COINS_PATH = { "coins" }

export type MoneyServiceServer = typeof(setmetatable({} :: {}, MoneyServiceServer))

local function assertWholeNumber(value: number, label: string)
	assert(type(value) == "number", (`{label} must be a number`))
	assert(value == math.floor(value), (`{label} must be a whole number`))
end

function MoneyServiceServer.new(): MoneyServiceServer
	return setmetatable({}, MoneyServiceServer)
end

function MoneyServiceServer:getCoins(player: Player): number
	return DataService:get(player, COINS_PATH)
end

function MoneyServiceServer:getBalance(player: Player): number
	return self:getCoins(player)
end

function MoneyServiceServer:set(player: Player, amount: number): number
	assertWholeNumber(amount, "amount")

	local nextAmount = math.max(0, amount)
	DataService:set(player, COINS_PATH, nextAmount)
	return nextAmount
end

function MoneyServiceServer:add(player: Player, amount: number): number
	assertWholeNumber(amount, "amount")
	assert(amount >= 0, "amount must be positive")

	return DataService:update(player, COINS_PATH, function(currentCoins)
		return currentCoins + amount
	end)
end

function MoneyServiceServer:remove(player: Player, amount: number): boolean
	assertWholeNumber(amount, "amount")
	assert(amount >= 0, "amount must be positive")

	if not self:canAfford(player, amount) then
		return false
	end

	DataService:update(player, COINS_PATH, function(currentCoins)
		return currentCoins - amount
	end)

	return true
end

function MoneyServiceServer:canAfford(player: Player, amount: number): boolean
	assertWholeNumber(amount, "amount")
	assert(amount >= 0, "amount must be positive")

	return self:getCoins(player) >= amount
end

function MoneyServiceServer:destroy() end

return MoneyServiceServer
