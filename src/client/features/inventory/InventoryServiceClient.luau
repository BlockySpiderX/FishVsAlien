local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).client
local Signal = require(ReplicatedStorage.Packages.Signal)

local InventoryServiceClient = {}
InventoryServiceClient.__index = InventoryServiceClient

local INVENTORY_PATH = { "inventory" }

type InventorySnapshot = {
	backpack: { [string]: number },
	order: { string },
}

local function cloneDictionary(source: { [string]: number }): { [string]: number }
	local copy = {}
	for key, value in source do
		copy[key] = value
	end
	return copy
end

local function cloneArray(source: { string }): { string }
	return table.clone(source)
end

local function cloneInventory(inventory: any): InventorySnapshot
	return {
		backpack = cloneDictionary(inventory.backpack or {}),
		order = cloneArray(inventory.order or {}),
	}
end

export type InventoryServiceClient = typeof(setmetatable(
	{} :: {
		inventory: InventorySnapshot,
		changed: Signal.Signal<InventorySnapshot>,
		connection: RBXScriptConnection?,
	},
	InventoryServiceClient
))

function InventoryServiceClient.new(): InventoryServiceClient
	local self = setmetatable({
		inventory = cloneInventory(DataService:get(INVENTORY_PATH)),
		changed = Signal.new(),
	}, InventoryServiceClient)

	self.connection = DataService:getChangedSignal(INVENTORY_PATH):Connect(function(inventory)
		self.inventory = cloneInventory(inventory)
		self.changed:Fire(cloneInventory(self.inventory))
	end)

	task.defer(function()
		self.changed:Fire(cloneInventory(self.inventory))
	end)

	return self
end

function InventoryServiceClient:getInventory(): InventorySnapshot
	return cloneInventory(self.inventory)
end

function InventoryServiceClient:getEggInventory(): { [string]: number }
	return cloneDictionary(self.inventory.backpack)
end

function InventoryServiceClient:destroy()
	if self.connection then
		self.connection:Disconnect()
	end
	self.changed:Destroy()
end

return InventoryServiceClient
