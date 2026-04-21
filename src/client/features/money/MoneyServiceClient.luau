local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).client
local Signal = require(ReplicatedStorage.Packages.Signal)

local MoneyServiceClient = {}
MoneyServiceClient.__index = MoneyServiceClient

local COINS_PATH = { "coins" }

export type MoneyServiceClient = typeof(setmetatable(
	{} :: {
		coins: number,
		changed: Signal.Signal<number>,
		connection: RBXScriptConnection?,
	},
	MoneyServiceClient
))

function MoneyServiceClient.new(): MoneyServiceClient
	local self = setmetatable({
		coins = DataService:get(COINS_PATH),
		changed = Signal.new(),
	}, MoneyServiceClient)

	self.connection = DataService:getChangedSignal(COINS_PATH):Connect(function(coins: number)
		self.coins = coins
		self.changed:Fire(coins)
	end)

	task.defer(function()
		self.changed:Fire(self.coins)
	end)

	return self
end

function MoneyServiceClient:getCoins(): number
	return self.coins
end

function MoneyServiceClient:destroy()
	if self.connection then
		self.connection:Disconnect()
	end
	self.changed:Destroy()
end

return MoneyServiceClient
