local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).client
local InventoryServiceClient = require(script.Parent.features.inventory.InventoryServiceClient)
local MoneyHUD = require(script.Parent.features.money.MoneyHUD)
local MoneyServiceClient = require(script.Parent.features.money.MoneyServiceClient)
local ShopServiceClient = require(script.Parent.features.shop.ShopServiceClient)

DataService:init()
local inventoryService = InventoryServiceClient.new()
local moneyService = MoneyServiceClient.new()
local shopService = ShopServiceClient.new()
local moneyHUD = MoneyHUD.new(moneyService, inventoryService, shopService)

return {
	inventoryService = inventoryService,
	moneyService = moneyService,
	moneyHUD = moneyHUD,
	shopService = shopService,
}
