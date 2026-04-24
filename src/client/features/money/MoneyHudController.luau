local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).client
local MoneyHudView = require(script.Parent.MoneyHudView)

local COINS_PATH = { "coins" }

local MoneyHudController = {}
MoneyHudController.__index = MoneyHudController

local activeController = nil

function MoneyHudController.new()
	local self = setmetatable({
		view = MoneyHudView.new(),
	}, MoneyHudController)

	self.view:setAmount(DataService:get(COINS_PATH) or 0)
	self.changedConnection = DataService:getChangedSignal(COINS_PATH):Connect(function(value)
		self.view:setAmount(value or 0)
	end)

	return self
end

function MoneyHudController.start()
	if activeController then
		return activeController
	end

	activeController = MoneyHudController.new()
	return activeController
end

function MoneyHudController:Destroy()
	if self.changedConnection then
		self.changedConnection:Disconnect()
		self.changedConnection = nil
	end

	if self.view then
		self.view:Destroy()
		self.view = nil
	end

	if activeController == self then
		activeController = nil
	end

	setmetatable(self, nil)
end

return MoneyHudController
