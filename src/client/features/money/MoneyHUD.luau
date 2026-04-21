local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Eggs = require(ReplicatedStorage.Shared.features.shop.Eggs)

local formatters = require(script.Parent.utils.formatters)
local MoneyHUDView = require(script.Parent.views.MoneyHUDView)

local e = React.createElement

local HOTBAR_SIZE = 8

local MoneyHUD = {}
MoneyHUD.__index = MoneyHUD

local function cloneArray(source)
	local copy = {}
	for index, value in source do
		copy[index] = value
	end
	return copy
end

local function buildEggLookup()
	local lookup = {}
	for _, egg in Eggs do
		lookup[egg.id] = egg
	end
	return lookup
end

local function getViewportSize(): Vector2
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1920, 1080)
end

local function isEggShopPrompt(prompt: ProximityPrompt): boolean
	if prompt.Name == "EggShop" then
		return true
	end

	if prompt.Parent and prompt.Parent.Name == "EggShop" then
		return true
	end

	if prompt:GetAttribute("ShopType") == "EggShop" then
		return true
	end

	return false
end

function MoneyHUD.new(moneyService, inventoryService, shopService)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existingGui = playerGui:FindFirstChild("MoneyHUD")
	if existingGui then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MoneyHUD"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local self = setmetatable({
		activePanel = nil,
		backpackEntries = {},
		connections = {},
		coins = moneyService:getCoins(),
		currentCameraConnection = nil,
		delta = nil,
		eggById = buildEggLookup(),
		eggs = shopService:getEggCatalog(),
		hotbarEntries = {},
		inventoryService = inventoryService,
		moneyService = moneyService,
		gui = screenGui,
		root = ReactRoblox.createRoot(screenGui),
		shopService = shopService,
		statusText = nil,
		statusToken = 0,
		viewportSize = getViewportSize(),
	}, MoneyHUD)

	self:rebuildInventory(inventoryService:getInventory())
	self:render()

	table.insert(self.connections, moneyService.changed:Connect(function(coins)
		self:updateCoins(coins)
	end))

	table.insert(self.connections, inventoryService.changed:Connect(function(inventory)
		self:rebuildInventory(inventory)
		self:render()
	end))

	table.insert(self.connections, ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if not isEggShopPrompt(prompt) then
			return
		end

		self.activePanel = "shop"
		self:render()
	end))

	local function bindCamera(camera: Camera?)
		if self.currentCameraConnection then
			self.currentCameraConnection:Disconnect()
			self.currentCameraConnection = nil
		end

		if not camera then
			return
		end

		self.viewportSize = camera.ViewportSize
		self:render()

		self.currentCameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self.viewportSize = camera.ViewportSize
			self:render()
		end)
	end

	table.insert(self.connections, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local camera = Workspace.CurrentCamera
		bindCamera(camera)
	end))

	bindCamera(Workspace.CurrentCamera)

	return self
end

function MoneyHUD:getEggName(eggId: string): string
	local egg = self.eggById[eggId]
	return if egg then egg.name else eggId
end

function MoneyHUD:rebuildInventory(inventory)
	local backpackEntries = {}
	local backpack = inventory.backpack or {}
	local order = inventory.order or {}

	for _, eggId in order do
		local count = backpack[eggId]
		if count and count > 0 then
			table.insert(backpackEntries, {
				id = eggId,
				name = self:getEggName(eggId),
				count = count,
			})
		end
	end

	self.backpackEntries = backpackEntries
	self.hotbarEntries = {}

	for index = 1, math.min(HOTBAR_SIZE, #backpackEntries) do
		self.hotbarEntries[index] = backpackEntries[index]
	end
end

function MoneyHUD:updateCoins(coins: number)
	if self.coins ~= nil and coins ~= self.coins then
		self.delta = {
			amount = coins - self.coins,
			token = os.clock(),
		}

		local token = self.delta.token
		task.delay(1.6, function()
			if self.delta and self.delta.token == token then
				self.delta = nil
				self:render()
			end
		end)
	end

	self.coins = coins
	self:render()
end

function MoneyHUD:togglePanel(panelName: string)
	if self.activePanel == panelName then
		self.activePanel = nil
	else
		self.activePanel = panelName
	end

	self:render()
end

function MoneyHUD:setStatus(text: string)
	self.statusToken += 1
	local token = self.statusToken
	self.statusText = text
	self:render()

	task.delay(2.5, function()
		if self.statusToken == token then
			self.statusText = nil
			self:render()
		end
	end)
end

function MoneyHUD:buyEgg(eggId: string)
	local ok, result = pcall(function()
		return self.shopService:buyEgg(eggId)
	end)

	if not ok then
		self:setStatus("Purchase failed")
		return
	end

	if result and result.success then
		self:setStatus(result.message or "Bought egg")
	else
		self:setStatus((result and result.message) or "Could not buy egg")
	end
end

function MoneyHUD:render()
	local deltaText = nil
	local deltaColor = nil

	if self.delta and self.delta.amount ~= 0 then
		deltaText = formatters.formatDelta(self.delta.amount)
		deltaColor = if self.delta.amount > 0
			then Color3.fromRGB(127, 255, 88)
			else Color3.fromRGB(255, 88, 88)
	end

	self.root:render(e(MoneyHUDView, {
		activePanel = self.activePanel,
		backpackEntries = cloneArray(self.backpackEntries),
		coinsText = formatters.formatMoney(self.coins or 0),
		deltaColor = deltaColor,
		deltaText = deltaText,
		eggs = cloneArray(self.eggs),
		hotbarEntries = cloneArray(self.hotbarEntries),
		onBuyEgg = function(eggId)
			self:buyEgg(eggId)
		end,
		onClosePanel = function()
			self.activePanel = nil
			self:render()
		end,
		onTogglePanel = function(panelName)
			self:togglePanel(panelName)
		end,
		statusText = self.statusText,
		viewportSize = self.viewportSize,
	}))
end

function MoneyHUD:destroy()
	for _, connection in self.connections do
		connection:Disconnect()
	end

	if self.root then
		self.root:unmount()
	end

	if self.currentCameraConnection then
		self.currentCameraConnection:Disconnect()
	end

	if self.gui then
		self.gui:Destroy()
	end
end

return MoneyHUD
