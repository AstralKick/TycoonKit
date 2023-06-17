-- Constants
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage = game:GetService("ServerStorage");
local Packages = ReplicatedStorage.Packages;

-- Modules
local Knit = require(Packages.Knit);

-- Add Services

Knit.AddServices(ServerStorage.src.Services)

Knit.Start():andThen():catch(warn)