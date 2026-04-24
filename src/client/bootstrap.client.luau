local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).client

local features = script.Parent:WaitForChild("features")
local friendBoost = features:WaitForChild("friendBoost")
local money = features:WaitForChild("money")
local shop = features:WaitForChild("shop")

local FriendBoostHudController = require(friendBoost:WaitForChild("FriendBoostHudController"))
local MoneyHudController = require(money:WaitForChild("MoneyHudController"))
local EggShopController = require(shop:WaitForChild("EggShopController"))

DataService:init()
FriendBoostHudController.start()
MoneyHudController.start()
EggShopController.start()
