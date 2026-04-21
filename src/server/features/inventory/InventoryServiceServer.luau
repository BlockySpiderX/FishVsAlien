local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).server

local InventoryServiceServer = {}
InventoryServiceServer.__index = InventoryServiceServer

local INVENTORY_PATH = { "inventory" }
local BACKPACK_PATH = { "inventory", "backpack" }
local ORDER_PATH = { "inventory", "order" }

type InventorySnapshot = {
	backpack: { [string]: number },
	order: { string },
}

export type InventoryServiceServer = typeof(setmetatable({} :: {}, InventoryServiceServer))

local function cloneDictionary(source: { [string]: number }): { [string]: number }
	local copy = {}
	for key, value in source do
		copy[key] = value
	end
	return copy
end

local function cloneArray(source: { string }): { string }
	local copy = table.clone(source)
	return copy
end

function InventoryServiceServer.new(): InventoryServiceServer
	return setmetatable({}, InventoryServiceServer)
end

function InventoryServiceServer:getSnapshot(player: Player): InventorySnapshot
	local inventory = DataService:get(player, INVENTORY_PATH)
	return {
		backpack = cloneDictionary(inventory.backpack),
		order = cloneArray(inventory.order),
	}
end

function InventoryServiceServer:getBackpack(player: Player): { [string]: number }
	return cloneDictionary(DataService:get(player, BACKPACK_PATH))
end

function InventoryServiceServer:getOrder(player: Player): { string }
	return cloneArray(DataService:get(player, ORDER_PATH))
end

function InventoryServiceServer:addEgg(player: Player, eggId: string, amount: number?): InventorySnapshot
	local addAmount = amount or 1
	assert(type(eggId) == "string" and eggId ~= "", "eggId must be a non-empty string")
	assert(type(addAmount) == "number" and addAmount >= 1, "amount must be at least 1")

	local currentCount = DataService:get(player, { "inventory", "backpack", eggId })
	if currentCount == nil then
		DataService:set(player, { "inventory", "backpack", eggId }, addAmount)
		DataService:arrayInsert(player, ORDER_PATH, eggId)
	else
		DataService:update(player, { "inventory", "backpack", eggId }, function(value)
			return value + addAmount
		end)
	end

	return self:getSnapshot(player)
end

function InventoryServiceServer:destroy() end

return InventoryServiceServer
