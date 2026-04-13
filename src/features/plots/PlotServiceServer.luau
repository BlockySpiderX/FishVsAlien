-- Folders
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("ServerScriptService")

-- Packages
local Networker = require(ReplicatedStorage.Packages.Networker)
local ServicePlayerData = require(ReplicatedStorage.Packages.ServicePlayerData)

-- Classes
local PlotServer = require(ServerScriptService.Features.Plots.Classes.PlotServer )
local PlotTypes = require(ReplicatedStorage.Source.Features.Plots.PlotTypes)


type Plot = PlotServer.Plot 
type PlotSpawn = PlotTypes.PlotSpawn


local PlotServiceServer = {}


local PLAYER_DATA_TEMPLATE = {
    plot = nil,
}

local 



type PlayerData = {
    plot:Plot,
}


function PlotServiceServer.init(self: PlotServiceServer)   
     self.networker = Networker.server.new("PlotService", self, {} )
     self.PlayerData = ServicePlayerData.new(PLAYER_DATA_TEMPLATE :: Player,self )
     self.plotSpawns = {}

     for _,plotSpawns: BasePart in CollectionService:GetTagged("PlotSpawn") destroy


end





function PlotServiceServer.playerAdded(_self:PlotServiceServer,player:Player, playerData:PlayerData)
    playerData.plot = PlotServer.new(player)
end    


function PlotServiceServer.playerRemoving(_self:PlotServiceServer,_player:Player, playerData:PlayerData)
    local plot = playerData.plot

    if plot then
        plot:destroy()
    end
end    


type PlotServiceServer = typeof(PlotServiceServer) & {
    plotSpawns: {BasePart},
    networker: Networker.Server,
    PlayerData: ServicePlayerData.ServicePlayerData<PlayerData>,

}

return PlotServiceServer :: PlotServiceServer


