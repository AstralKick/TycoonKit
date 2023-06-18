-- This script will intiialise the tycoon creation, and serve as the connector.

-- Constants
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage");
local Src = ServerStorage.src
local Components = Src.Components
local ReplicaService = require(ServerStorage.src.Modules.ReplicaService);

local Knit = require(ReplicatedStorage.Packages.Knit);
Knit.OnStart():await()

local DataService = Knit.GetService("DataService");

-- Components
local TycoonComponent = require(Components.Tycoon);

Players.PlayerAdded:Connect(function(Player: Player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    
    local number = Instance.new("NumberValue")
    number.Parent = leaderstats
    number.Name = "Cash"

    DataService:AttachFunction(Player, "Currency", function(newValue)
        number.Value = newValue
    end)
    
end)

Players.PlayerRemoving:Connect(function(Player: Player)
    local Comps = TycoonComponent:GetAll()

    for _,Component in ipairs (Comps) do
        if not Component.owner then continue end
        if Component.owner ~= Player then continue end
        Component:PlayerLeave()
    end
end)