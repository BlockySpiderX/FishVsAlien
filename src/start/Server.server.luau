local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService)
local DataTemplate = require(ReplicatedStorage.Source.Game.Items.DataTemplate)


-- Services
local PlotServiceServer = require(ServerScriptService.Features.Plots.)

DataService:init({

    template = DataTemplate,
    profileStoreIndex = "PRE",
    useMock = false,
    resetData = false,
    dontSave = false,
})


PlotServiceServer:init()