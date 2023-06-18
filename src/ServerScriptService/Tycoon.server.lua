-- This script will intiialise the tycoon creation, and serve as the connector.

-- Constants
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage");
local Src = ServerStorage.src
local Components = Src.Components

-- Components
local TycoonComponent = require(Components.Tycoon);

Players.PlayerRemoving:Connect(function(Player: Player)
    local Comps = TycoonComponent:GetAll()

    for _,Component in ipairs (Comps) do
        if not Component.owner then continue end
        if Component.owner ~= Player then continue end
        Component:PlayerLeave()
    end
end)