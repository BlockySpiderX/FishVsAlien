local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).server
local PlotServiceServer = require(ServerScriptService.Server.features.plot.PlotServiceServer)
local DataTemplate = require(ServerScriptService.Server.game.DataTemplate)

DataService:init({
	template = DataTemplate,
	profileStoreIndex = "FishVsAlien",
	useMock = true,
})

local plotService = PlotServiceServer.new()

return {
	plotService = plotService,
}
