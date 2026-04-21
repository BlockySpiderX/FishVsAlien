local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)

local ShopServiceClient = {}
ShopServiceClient.__index = ShopServiceClient

export type ShopServiceClient = typeof(setmetatable(
	{} :: {
		networker: Networker.Client,
		eggs: { any },
	},
	ShopServiceClient
))

function ShopServiceClient.new(): ShopServiceClient
	local self = setmetatable({
		eggs = {},
	}, ShopServiceClient)

	self.networker = Networker.client.new("ShopService", self)

	local ok, result = pcall(function()
		return self.networker:fetch("getEggCatalog")
	end)

	if ok and type(result) == "table" then
		self.eggs = result
	end

	return self
end

function ShopServiceClient:getEggCatalog()
	return self.eggs
end

function ShopServiceClient:buyEgg(eggId: string)
	return self.networker:fetch("buyEgg", eggId)
end

function ShopServiceClient:destroy()
	self.networker:destroy()
end

return ShopServiceClient
