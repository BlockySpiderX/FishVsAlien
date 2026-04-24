local FriendBoostHudView = require(script.Parent.FriendBoostHudView)

local FriendBoostHudController = {}
FriendBoostHudController.__index = FriendBoostHudController

local activeController = nil

function FriendBoostHudController.new()
	local self = setmetatable({
		view = FriendBoostHudView.new(),
	}, FriendBoostHudController)

	self.view:setBoostPercent(0)
	return self
end

function FriendBoostHudController.start()
	if activeController then
		return activeController
	end

	activeController = FriendBoostHudController.new()
	return activeController
end

function FriendBoostHudController:Destroy()
	if self.view then
		self.view:Destroy()
		self.view = nil
	end

	if activeController == self then
		activeController = nil
	end

	setmetatable(self, nil)
end

return FriendBoostHudController
