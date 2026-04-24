local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local EggShopRemotes = require(ReplicatedStorage.Shared.features.shop.EggShopRemotes)
local EggShopView = require(script.Parent.ui.EggShopView)

local localPlayer = Players.LocalPlayer

type ShopSnapshot = {
	title: string?,
	items: { [number]: { [string]: any } }?,
	balance: number?,
	updatedAt: number?,
}

local EggShopController = {}
EggShopController.__index = EggShopController

local activeController = nil

local function isEggShopPrompt(prompt: ProximityPrompt): boolean
	if prompt.Name == "EggShop" then
		return true
	end

	local shopId = prompt:GetAttribute("ShopId")
	if type(shopId) == "string" and shopId == "EggShop" then
		return true
	end

	return prompt.ActionText == "EggShop" or prompt.ObjectText == "EggShop"
end

function EggShopController.new()
	local remoteFolder = ReplicatedStorage:WaitForChild(EggShopRemotes.folderName)

	local self = setmetatable({
		busyEggId = nil,
		getStateRemote = remoteFolder:WaitForChild(EggShopRemotes.getStateFunction) :: RemoteFunction,
		purchaseRemote = remoteFolder:WaitForChild(EggShopRemotes.purchaseFunction) :: RemoteFunction,
		snapshot = {
			title = "Fish Egg Shop",
			items = {},
			balance = 0,
			updatedAt = 0,
		},
		stateEvent = remoteFolder:WaitForChild(EggShopRemotes.stateEvent) :: RemoteEvent,
	}, EggShopController)

	self.view = EggShopView.new({
		onBuy = function(eggId)
			self:buyEgg(eggId)
		end,
		onClose = function()
			self.view:setVisible(false)
		end,
	})

	self:bind()
	self.view:render(self.snapshot, self.busyEggId)

	return self
end

function EggShopController:bind()
	self.stateEvent.OnClientEvent:Connect(function(payload)
		self:applySnapshot(payload)
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if isEggShopPrompt(prompt) then
			self:toggleFromPrompt()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not self.view:isVisible() then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			self.view:setVisible(false)
		end
	end)
end

function EggShopController:applySnapshot(payload: ShopSnapshot)
	if type(payload) ~= "table" then
		return
	end

	self.snapshot = {
		title = if type(payload.title) == "string" and payload.title ~= "" then payload.title else self.snapshot.title,
		items = if type(payload.items) == "table" then payload.items else self.snapshot.items,
		balance = if type(payload.balance) == "number" then payload.balance else self.snapshot.balance,
		updatedAt = if type(payload.updatedAt) == "number" then payload.updatedAt else self.snapshot.updatedAt,
	}

	self.view:render(self.snapshot, self.busyEggId)
end

function EggShopController:refreshSnapshot(): boolean
	self.view:setNotice("Loading egg shop...", false)

	local ok, result = pcall(function()
		return self.getStateRemote:InvokeServer()
	end)

	if not ok then
		self.view:setNotice("The egg shop is unavailable right now.", true)
		return false
	end

	self:applySnapshot(result)
	self.view:setNotice("Browse the latest fish eggs in stock.", false)
	return true
end

function EggShopController:toggleFromPrompt()
	if self.view:isVisible() then
		self.view:setVisible(false)
		return
	end

	self.view:setVisible(true)
	self:refreshSnapshot()
end

function EggShopController:buyEgg(eggId: string)
	if self.busyEggId then
		return
	end

	self.busyEggId = eggId
	self.view:setBusyEggId(eggId)
	self.view:setNotice("Processing purchase...", false)

	local ok, result = pcall(function()
		return self.purchaseRemote:InvokeServer(eggId)
	end)

	self.busyEggId = nil
	self.view:setBusyEggId(nil)

	if not ok then
		self.view:setNotice("Purchase failed. Please try again.", true)
		return
	end

	if type(result) ~= "table" then
		self.view:setNotice("The shop returned an invalid response.", true)
		return
	end

	if type(result.snapshot) == "table" then
		self:applySnapshot(result.snapshot)
	else
		self:refreshSnapshot()
	end

	local success = result.success == true
	local message = if type(result.message) == "string" and result.message ~= "" then
		result.message
	else
		(if success then "Purchase complete." else "Purchase failed.")

	self.view:setNotice(message, not success)
end

function EggShopController.start()
	if activeController then
		return activeController
	end

	if not localPlayer then
		return nil
	end

	activeController = EggShopController.new()
	return activeController
end

return EggShopController
