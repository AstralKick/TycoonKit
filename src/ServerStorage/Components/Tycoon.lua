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
            local Success, Current = DataService:GetKey(self.owner, "TycoonData"):await()
            Current.Bank += 50
            DataService:SetKey(self.owner, "TycoonData", Current):await()
            self.interactables.Collect.SurfaceGui.TextLabel.Text = "£"..Current.Bank
            warn("Player awarded +50 in the bank")
        end
    end), function()
        Counter = 0
    end)

    self._trove:Add(self.interactables.Collect.Touched:Connect(function()
        local Success, Current = DataService:GetKey(self.owner, "TycoonData"):await()
        DataService:SetKey(self.owner, "Currency", Current.Bank):await()
        Current.Bank = 0
        DataService:SetKey(self.owner, "TycoonData", Current):await()
        self.interactables.Collect.SurfaceGui.TextLabel.Text = "£"..Current.Bank
    end), function() 
        self.interactables.Collect.SurfaceGui.TextLabel.Text = ""
    end)
end

function TycoonTemplate:LoadData()
    return Promise.new(function(Resolve, Reject)
        local Success, Unlocks = DataService:GetKey(self.owner, "Unlocks"):await()

        if Success then
            if #Unlocks > 0 then
                warn("Data exists")
                Resolve(Unlocks)
            else
                warn("Data doesnt exist")
                Reject("Data doesn't exist")
            end
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