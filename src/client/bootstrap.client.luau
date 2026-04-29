local PlayerScripts = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).client
local MoneyServiceClient = require(PlayerScripts.features.money.MoneyServiceClient)

DataService:init()
MoneyServiceClient.start()
