local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)

local PlotServiceServer = {}


function PlotServiceServer.init(self: PlotServiceServer)   
     self.networker = Networker.server.new("PlotService", self, {})
end

type PlotServiceServer = typeof(PlotServiceServer) & {
    networker: Networker.Server,

}


return PlotServiceServer