local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggCatalog = require(ReplicatedStorage.Shared.features.shop.Eggs)
local EggShopRemotes = require(ReplicatedStorage.Shared.features.shop.EggShopRemotes)

local PURCHASE_COOLDOWN = 0.2
local SHOP_TITLE = "Fish Egg Shop"

type EggDefinition = typeof(EggCatalog[1])
type ShopSnapshot = {
	title: string,
	items: { [number]: { [string]: any } },
	balance: number?,
	updatedAt: number,
}

local ShopServiceServer = {}
ShopServiceServer.__index = ShopServiceServer

export type ShopServiceServer = typeof(setmetatable(
	{} :: {
		catalogById: { [string]: EggDefinition },
		getStateRemote: RemoteFunction,
		inventoryService: any,
		lastPurchaseAt: { [Player]: number },
		moneyService: any,
		purchaseRemote: RemoteFunction,
		stateEvent: RemoteEvent,
		stockByEggId: { [string]: number },
	},
	ShopServiceServer
))

local function createOrGetFolder(name: string): Folder
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = ReplicatedStorage
	return folder
end

local function createOrGetRemoteFunction(parent: Instance, name: string): RemoteFunction
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing
	end

	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local function createOrGetRemoteEvent(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local function sanitizeEgg(egg: EggDefinition, stockCount: number): { [string]: any }
	return {
		id = egg.id,
		name = egg.name,
		fishId = egg.fishId,
		fishName = egg.fishName,
		rarity = egg.rarity,
		price = egg.price,
		stock = stockCount,
		color = egg.color,
		accentColor = egg.accentColor,
		description = egg.description,
	}
end

function ShopServiceServer.new(moneyService, inventoryService): ShopServiceServer
	local remoteFolder = createOrGetFolder(EggShopRemotes.folderName)

	local self = setmetatable({
		catalogById = {},
		getStateRemote = createOrGetRemoteFunction(remoteFolder, EggShopRemotes.getStateFunction),
		inventoryService = inventoryService,
		lastPurchaseAt = {},
		moneyService = moneyService,
		purchaseRemote = createOrGetRemoteFunction(remoteFolder, EggShopRemotes.purchaseFunction),
		stateEvent = createOrGetRemoteEvent(remoteFolder, EggShopRemotes.stateEvent),
		stockByEggId = {},
	}, ShopServiceServer)

	for _, egg in EggCatalog do
		self.catalogById[egg.id] = egg
		self.stockByEggId[egg.id] = egg.stock
	end

	self.getStateRemote.OnServerInvoke = function(player)
		return self:getSnapshotForPlayer(player)
	end

	self.purchaseRemote.OnServerInvoke = function(player, eggId)
		return self:purchaseEgg(player, eggId)
	end

	Players.PlayerRemoving:Connect(function(player)
		self.lastPurchaseAt[player] = nil
	end)

	return self
end

function ShopServiceServer:getPublicItems(): { [number]: { [string]: any } }
	local items = {}

	for _, egg in EggCatalog do
		table.insert(items, sanitizeEgg(egg, self.stockByEggId[egg.id] or 0))
	end

	return items
end

function ShopServiceServer:getPublicSnapshot(): ShopSnapshot
	return {
		title = SHOP_TITLE,
		items = self:getPublicItems(),
		updatedAt = os.time(),
	}
end

function ShopServiceServer:getSnapshotForPlayer(player: Player): ShopSnapshot
	local snapshot = self:getPublicSnapshot()
	snapshot.balance = self.moneyService:getBalance(player)
	return snapshot
end

function ShopServiceServer:broadcastPublicSnapshot(excludedPlayer: Player?)
	local snapshot = self:getPublicSnapshot()

	for _, player in Players:GetPlayers() do
		if player ~= excludedPlayer then
			self.stateEvent:FireClient(player, snapshot)
		end
	end
end

function ShopServiceServer:purchaseEgg(player: Player, eggId: string)
	if type(eggId) ~= "string" or eggId == "" then
		return {
			success = false,
			message = "Invalid egg selected.",
			snapshot = self:getSnapshotForPlayer(player),
		}
	end

	local lastPurchaseAt = self.lastPurchaseAt[player]
	local now = os.clock()
	if lastPurchaseAt and now - lastPurchaseAt < PURCHASE_COOLDOWN then
		return {
			success = false,
			message = "Please wait a moment before buying again.",
			snapshot = self:getSnapshotForPlayer(player),
		}
	end

	self.lastPurchaseAt[player] = now

	local egg = self.catalogById[eggId]
	if not egg then
		return {
			success = false,
			message = "That egg is no longer available.",
			snapshot = self:getSnapshotForPlayer(player),
		}
	end

	local stockCount = self.stockByEggId[eggId] or 0
	if stockCount <= 0 then
		return {
			success = false,
			message = "This egg is sold out.",
			snapshot = self:getSnapshotForPlayer(player),
		}
	end

	if not self.moneyService:canAfford(player, egg.price) then
		return {
			success = false,
			message = "You do not have enough coins.",
			snapshot = self:getSnapshotForPlayer(player),
		}
	end

	local charged = self.moneyService:remove(player, egg.price)
	if not charged then
		return {
			success = false,
			message = "Your balance changed. Try again.",
			snapshot = self:getSnapshotForPlayer(player),
		}
	end

	local inventoryOk, inventoryResult = pcall(function()
		return self.inventoryService:addEgg(player, egg.id, 1)
	end)

	if not inventoryOk then
		self.moneyService:add(player, egg.price)
		warn(("[ShopService] Failed to add egg `%s` for %s: %s"):format(egg.id, player.Name, tostring(inventoryResult)))
		return {
			success = false,
			message = "Purchase could not be completed.",
			snapshot = self:getSnapshotForPlayer(player),
		}
	end

	self.stockByEggId[eggId] = stockCount - 1

	local buyerSnapshot = self:getSnapshotForPlayer(player)
	self.stateEvent:FireClient(player, buyerSnapshot)
	self:broadcastPublicSnapshot(player)

	return {
		success = true,
		message = (`Purchased {egg.name}.`),
		snapshot = buyerSnapshot,
	}
end

function ShopServiceServer:destroy()
	self.getStateRemote.OnServerInvoke = nil
	self.purchaseRemote.OnServerInvoke = nil
	table.clear(self.lastPurchaseAt)
	table.clear(self.stockByEggId)
	table.clear(self.catalogById)
end

return ShopServiceServer
