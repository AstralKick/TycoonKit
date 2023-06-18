local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Packages = ReplicatedStorage.Packages

-- Heartbeat
local Counter = 0
local CashUpdate = 3

local Knit = require(Packages.Knit);
Knit.OnStart():await()

local Promise = require(Knit.Util.Promise);
local Component = require(Packages.Component);
local Trove = require(Packages.Trove);
local DataService = Knit.GetService("DataService");
local RunService = game:GetService('RunService')

local TycoonTemplate = Component.new{ Tag = "Tycoon" }

function TycoonTemplate:Construct()
    -- Cleanup
    self._trove = Trove.new()

    -- Definitions
    self.tycoon = self.Instance
    self.interactables = self.tycoon.Interactables

    -- Proximity Prompt Setup
    self.proximityPrompt = Instance.new("ProximityPrompt")
    self.proximityPrompt.ActionText = "Claim"
    self.proximityPrompt.RequiresLineOfSight = false
    self.proximityPrompt.Parent = self.interactables.Claim

    -- Add to trove
    self._trove:Add(self.proximityPrompt)

    -- Ownership
    self.owner = nil
    self.purchasingEnabled = false
end

function TycoonTemplate:Start()
    self.proximityPrompt.Triggered:Connect(function(Player: Player)
        self:Claim(Player)
    end)
end

function TycoonTemplate:Claim(Player: Player)
    self.proximityPrompt.Enabled = false
    self.owner = Player

    -- TEST
    warn("Player ", Player.Name, " has claimed the Tycoon!")

    self:LoadData():andThen(function(Data)
        warn("AT THIS POINT THE EXISTING TYCOON WOULD LOAD")
        self.purchasingEnabled = true
    end):catch(warn)

    self._trove:Add(RunService.Heartbeat:Connect(function(dt)
        Counter += dt
        if Counter >= CashUpdate then
            Counter = Counter - CashUpdate

            local Profile = DataService:GetProfile(Player)
            Profile.Data.TycoonData.Bank += 50
            self.interactables.Claim.SurfaceGui.TextLabel.Text = "£"..Profile.Data.TycoonData.Bank
            warn("Player awarded +50 in the bank")
        end
    end), function()
        Counter = 0
    end)

    self._trove:Add(self.interactables.Claim.Touched:Connect(function()
        local Profile = DataService:GetProfile(Player)
        Profile.Data.Currency += Profile.Data.TycoonData.Bank
        Profile.Data.TycoonData.Bank = 0
        self.interactables.Claim.SurfaceGui.TextLabel.Text = "£"..Profile.Data.TycoonData.Bank
    end), function() 
        self.interactables.Claim.SurfaceGui.TextLabel.Text = ""
    end)
end

function TycoonTemplate:LoadData()
    return Promise.new(function(Resolve, Reject)
        local Profile = DataService:GetProfile(self.owner)
        local Data = Profile.Data

        if #Data.Unlocks then
            warn("Data exists")
            Resolve(Data.Unlocks)
        else
            warn("Data doesnt exist")
            Reject("Data doesn't exist")
        end
    end)
end

function TycoonTemplate:PlayerLeave()
    warn("Player has left --- running functions to fix...")
    self._trove:Destroy()

    
    -- Cleanup
    self._trove = Trove.new()

    -- Definitions
    self.tycoon = self.Instance
    self.interactables = self.tycoon.Interactables

    -- Proximity Prompt Setup
    self.proximityPrompt = Instance.new("ProximityPrompt")
    self.proximityPrompt.ActionText = "Claim"
    self.proximityPrompt.RequiresLineOfSight = false
    self.proximityPrompt.Parent = self.interactables.Claim

    -- Add to trove
    self._trove:Add(self.proximityPrompt)

    -- Ownership
    self.owner = nil
    self.purchasingEnabled = false
end


function TycoonTemplate:Stop()
    
end


return TycoonTemplate