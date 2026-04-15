local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(ReplicatedStorage.Packages.DataService).server
local BaseServiceServer = require(ServerScriptService.Features.Base.BaseServiceServer)
local InitializePartsServer = require(ServerScriptService.Game.Parts.InitializePartsServer)
local DataTemplate = require(ReplicatedStorage.Source.Game.Items.DataTemplate)

DataService:init({
	template = DataTemplate,
	profileStoreIndex = "PRE",
	useMock = false,
	resetData = false,
	dontSave = false,
})

InitializePartsServer()
BaseServiceServer:init()
