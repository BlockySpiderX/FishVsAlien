local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).server
local FishServiceServer = require(ServerScriptService.Server.features.fish.FishServiceServer)
local InventoryServiceServer = require(ServerScriptService.Server.features.inventory.InventoryServiceServer)
local MovementServiceServer = require(ServerScriptService.Server.features.movement.MovementServiceServer)
local MoneyServiceServer = require(ServerScriptService.Server.features.money.MoneyServiceServer)
local PlotServiceServer = require(ServerScriptService.Server.features.plot.PlotServiceServer)
local ShopServiceServer = require(ServerScriptService.Server.features.shop.ShopServiceServer)
local WorldTimeServiceServer = require(ServerScriptService.Server.features.world.WorldTimeServiceServer)
local DataTemplate = require(ServerScriptService.Server.game.DataTemplate)

DataService:init({
	template = DataTemplate,
	profileStoreIndex = "FishVsAlien",
	useMock = true,
})

local inventoryService = InventoryServiceServer.new()
local movementService = MovementServiceServer.new()
local moneyService = MoneyServiceServer.new()
local plotService = PlotServiceServer.new()
local fishService = FishServiceServer.new(plotService, moneyService)
local shopService = ShopServiceServer.new(moneyService, inventoryService)
local worldTimeService = WorldTimeServiceServer.new()

return {
	inventoryService = inventoryService,
	fishService = fishService,
	movementService = movementService,
	moneyService = moneyService,
	plotService = plotService,
	shopService = shopService,
	worldTimeService = worldTimeService,
}
