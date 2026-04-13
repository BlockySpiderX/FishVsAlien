-- Files
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotTypesc= require(ReplicatedStorage.Source.Features.Plots.PlotTypes)
local PlotModel = ReplicatedStorage.Assets.Misc.Plot


local CHAR_SPAWN_OFFSET =  CFrame.new(0,20,0)

local PlotServer = {}
PlotServer.__index = PlotServer


type PlotSpawn = PlotTypes.PlotSpawn
export type Plot = typeof(setmetatable(
    {} :: {
        cf:CFrame,
        index:number,
        player:Player,
        plotModel:Model 
    },
    
    PlotServer
))


function PlotServer.new(plotSpawn: PlotSpawn, player:Player): PlotSpawn
    local self = setmetatable({player = player}, PlotServer)
    return self
end



function PlotServer.charInit(self:Plot)
    local startingChar = self.player. or self.player.CharacterAdded:Wait()
    self.player.CharacterAdded:Connect(function)

end




function PlotServer.destroy(self: Plot)
    self.plotModel:Destroy()
    self.janitor:Destroy()
end


return PlotServer 