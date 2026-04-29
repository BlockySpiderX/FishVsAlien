local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).client

local COINS_PATH = { "coins" }
local localPlayer = Players.LocalPlayer

local SUFFIXES = {
	{ value = 1e15, suffix = "Qa" },
	{ value = 1e12, suffix = "T" },
	{ value = 1e9, suffix = "B" },
	{ value = 1e6, suffix = "M" },
	{ value = 1e3, suffix = "K" },
}

local MoneyServiceClient = {}
MoneyServiceClient.__index = MoneyServiceClient

export type MoneyServiceClient = typeof(setmetatable(
	{} :: {
		changedConnection: RBXScriptConnection?,
		moneyLabel: TextLabel,
	},
	MoneyServiceClient
))

local activeService: MoneyServiceClient? = nil

local function trimTrailingZeroes(value: string): string
	return string.gsub(value, "%.?0+$", "")
end

local function formatCompactNumber(amount: number): string
	local absoluteAmount = math.abs(amount)

	for _, entry in SUFFIXES do
		if absoluteAmount >= entry.value then
			local scaled = amount / entry.value
			return `{trimTrailingZeroes(string.format("%.2f", scaled))}{entry.suffix}`
		end
	end

	return tostring(math.floor(amount + 0.00001))
end

local function makeVisible(instance: Instance)
	if instance:IsA("ScreenGui") then
		instance.Enabled = true
	elseif instance:IsA("GuiObject") then
		instance.Visible = true
	end
end

local function getMoneyLabel(): TextLabel
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local root = playerGui:WaitForChild("Root")
	local screenFrame = root:FindFirstChild("ScreenFrame") or root
	local rightBottomBar = screenFrame:WaitForChild("RightBottomBar")
	local money = rightBottomBar:WaitForChild("Money", 5) or rightBottomBar:FindFirstChild("Money", true)

	assert(money and money:IsA("TextLabel"), "MoneyServiceClient could not find a TextLabel named Money inside RightBottomBar")

	makeVisible(root)
	makeVisible(screenFrame)
	makeVisible(rightBottomBar)
	makeVisible(money)

	return money :: TextLabel
end

local function setMoneyText(moneyLabel: TextLabel, coins: number?)
	moneyLabel.Text = "$" .. formatCompactNumber(coins or 0)
end

function MoneyServiceClient.new(): MoneyServiceClient
	local self = setmetatable({
		changedConnection = nil,
		moneyLabel = getMoneyLabel(),
	}, MoneyServiceClient)

	setMoneyText(self.moneyLabel, DataService:get(COINS_PATH))

	self.changedConnection = DataService:getChangedSignal(COINS_PATH):Connect(function(coins)
		setMoneyText(self.moneyLabel, coins)
	end)

	return self
end

function MoneyServiceClient.start(): MoneyServiceClient
	if activeService then
		return activeService
	end

	activeService = MoneyServiceClient.new()
	return activeService
end

function MoneyServiceClient:destroy()
	if self.changedConnection then
		self.changedConnection:Disconnect()
		self.changedConnection = nil
	end

	if activeService == self then
		activeService = nil
	end

	setmetatable(self, nil)
end

return MoneyServiceClient
