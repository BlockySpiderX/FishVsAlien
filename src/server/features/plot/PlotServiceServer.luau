local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Networker = require(ReplicatedStorage.Packages.Networker)
local ServicePlayerData = require(ReplicatedStorage.Packages.ServicePlayerData)

local PlotServer = require(ServerScriptService.Server.features.plot.classes.PlotServer)

type PlotTypes = typeof(require(ReplicatedStorage.Shared.features.plot.PlotTypes))
type Plot = PlotServer.Plot
type PlotSnapshot = PlotTypes.PlotSnapshot

type PlotPlayerData = {
	plotIndex: number?,
}

local PLOT_FOLDER_PATHS = {
	{ "Map", "Tanks" },
	{ "Map", "Plots" },
	{ "Plots" },
	{ "PlotSpawns" },
}

local PlotServiceServer = {}
PlotServiceServer.__index = PlotServiceServer

local PLAYER_DATA_TEMPLATE: PlotPlayerData = {
	plotIndex = nil,
}

export type PlotServiceServer = typeof(setmetatable(
	{} :: {
		networker: Networker.Server,
		playerData: ServicePlayerData.ServicePlayerData<PlotPlayerData>,
		plots: { Plot },
		playerPlots: { [Player]: Plot },
	},
	PlotServiceServer
))

local function findPlotFolder(): Instance?
	for _, path in PLOT_FOLDER_PATHS do
		local current: Instance = Workspace
		local foundPath = true

		for _, segment in path do
			local nextInstance = current:FindFirstChild(segment)
			if not nextInstance then
				foundPath = false
				break
			end

			current = nextInstance
		end

		if foundPath then
			return current
		end
	end

	return nil
end

local function getInstancePivot(instance: PlotTypes.PlotInstance): CFrame
	if instance:IsA("Model") then
		return instance:GetPivot()
	end

	return instance.CFrame
end

local function getPlotSpawnCFrame(instance: PlotTypes.PlotInstance): CFrame
	if instance:IsA("Model") then
		local spawnPart = instance:FindFirstChild("Spawn")
		if spawnPart and spawnPart:IsA("BasePart") then
			return spawnPart.CFrame
		end

		warn(("[PlotService] Plot `%s` is missing a BasePart named `Spawn`"):format(instance.Name))
	end

	return getInstancePivot(instance)
end

local function isPlotInstance(instance: Instance): boolean
	return instance:IsA("Model") or instance:IsA("BasePart")
end

local function tryGetPlayerData(self: PlotServiceServer, player: Player): PlotPlayerData?
	local ok, playerData = pcall(function()
		return self.playerData:get(player)
	end)

	if ok then
		return playerData
	end

	return nil
end

local function sortPlotInstances(a: PlotTypes.PlotInstance, b: PlotTypes.PlotInstance): boolean
	local aIndex = a:GetAttribute("PlotIndex")
	local bIndex = b:GetAttribute("PlotIndex")
	if type(aIndex) == "number" and type(bIndex) == "number" and aIndex ~= bIndex then
		return aIndex < bIndex
	end

	return a.Name < b.Name
end

function PlotServiceServer.new(): PlotServiceServer
	local self = setmetatable({
		plots = {},
		playerPlots = {},
	}, PlotServiceServer)

	self.networker = Networker.server.new("PlotService", self, {
		self.getLocalPlot,
		self.getPlots,
	})

	self.plots = self:_createPlots()
	self.playerData = ServicePlayerData.new(PLAYER_DATA_TEMPLATE, self)

	for _, player in Players:GetPlayers() do
		self:playerAdded(player)
	end

	return self
end

function PlotServiceServer:_createPlots(): { Plot }
	local plotFolder = findPlotFolder()
	if not plotFolder then
		warn("[PlotService] Could not find plots at Workspace.Map.Tanks")
		return {}
	end

	local plotInstances = {}
	for _, child in plotFolder:GetChildren() do
		if isPlotInstance(child) then
			table.insert(plotInstances, child :: PlotTypes.PlotInstance)
		end
	end

	table.sort(plotInstances, sortPlotInstances)

	local plots = {}
	for index, instance in plotInstances do
		table.insert(plots, PlotServer.new({
			index = index,
			instance = instance,
			spawnCFrame = getPlotSpawnCFrame(instance),
		}))
	end

	return plots
end

function PlotServiceServer:_getUnclaimedPlot(): Plot?
	for _, plot in self.plots do
		if not plot.owner then
			return plot
		end
	end

	return nil
end

function PlotServiceServer:_assignPlot(player: Player): Plot?
	local existingPlot = self.playerPlots[player]
	if existingPlot then
		return existingPlot
	end

	local openPlot = self:_getUnclaimedPlot()
	if not openPlot then
		warn(("[PlotService] No open plot available for %s"):format(player.Name))
		return nil
	end

	openPlot:claim(player)
	self.playerPlots[player] = openPlot
	local playerData = tryGetPlayerData(self, player)
	if playerData then
		playerData.plotIndex = openPlot.index
	end
	return openPlot
end

function PlotServiceServer:_releasePlot(player: Player)
	local plot = self.playerPlots[player]
	if not plot then
		return
	end

	plot:release()
	self.playerPlots[player] = nil

	local playerData = tryGetPlayerData(self, player)
	if playerData then
		playerData.plotIndex = nil
	end
end

function PlotServiceServer:playerAdded(player: Player)
	local plot = self:_assignPlot(player)
	if plot then
		self.networker:set(player, "localPlotIndex", plot.index)
	end
end

function PlotServiceServer:playerRemoving(player: Player, playerData: PlotPlayerData?)
	self:_releasePlot(player)

	if playerData then
		playerData.plotIndex = nil
	end
end

function PlotServiceServer.getLocalPlot(self: PlotServiceServer, player: Player): PlotSnapshot?
	local plot = self.playerPlots[player]
	if not plot then
		return nil
	end

	return plot:getSnapshot()
end

function PlotServiceServer.getPlots(self: PlotServiceServer, _player: Player): { PlotSnapshot }
	local snapshots = {}
	for _, plot in self.plots do
		table.insert(snapshots, plot:getSnapshot())
	end

	return snapshots
end

function PlotServiceServer.destroy(self: PlotServiceServer)
	if self.playerData then
		self.playerData:destroy()
	end

	for _, plot in self.plots do
		plot:destroy()
	end

	self.playerPlots = {}
	self.plots = {}
	self.networker:destroy()
end

return PlotServiceServer
