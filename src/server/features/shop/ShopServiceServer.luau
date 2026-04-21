local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Eggs = require(ReplicatedStorage.Shared.features.shop.Eggs)

local ShopServiceServer = {}
ShopServiceServer.__index = ShopServiceServer

export type ShopServiceServer = typeof(setmetatable(
	{} :: {
		networker: Networker.Server,
		moneyService: any,
		inventoryService: any,
		eggById: { [string]: any },
	},
	ShopServiceServer
))

local function buildEggLookup()
	local lookup = {}
	for _, egg in Eggs do
		lookup[egg.id] = egg
	end

	return lookup
end

function ShopServiceServer.new(
	moneyService: any,
	inventoryService: any
): ShopServiceServer
	local self = setmetatable({
		moneyService = moneyService,
		inventoryService = inventoryService,
		eggById = buildEggLookup(),
	}, ShopServiceServer)

	self.networker = Networker.server.new("ShopService", self, {
		self.getEggCatalog,
		self.buyEgg,
	})

	return self
end

function ShopServiceServer:getEggCatalog(_player: Player)
	return Eggs
end

function ShopServiceServer:buyEgg(player: Player, eggId: string)
	local egg = self.eggById[eggId]
	if not egg then
		return {
			success = false,
			message = "Egg not found",
		}
	end

	if not self.moneyService:remove(player, egg.price) then
		return {
			success = false,
			message = "Not enough money",
		}
	end

	local inventory = self.inventoryService:addEgg(player, eggId, 1)

	return {
		success = true,
		message = ("Bought %s"):format(egg.name),
		eggId = eggId,
		inventory = inventory,
		coins = self.moneyService:getCoins(player),
	}
end

function ShopServiceServer:destroy()
	if self.networker then
		self.networker:destroy()
	end
end

return ShopServiceServer
