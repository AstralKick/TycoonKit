-- Constants
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage = game:GetService("ServerStorage");
local Packages = ReplicatedStorage.Packages;

-- Modules
local Knit = require(Packages.Knit);
local ProfileService = require(Packages.ProfileService);
local Promise = require(Knit.Util.Promise);
local Trove = require(Packages.Trove);
local ReplicaService = require(ServerStorage.src.Modules.ReplicaService);

-- Data
local ProfileTemplate = require(ServerStorage.src.Modules.ProfileTemplate);
local Products = require(ServerStorage.src.Modules.Products);
local PlayerProfileClassToken = ReplicaService.NewClassToken("PlayerProfile")

-- Setup Profile
local ProfileStore = ProfileService.GetProfileStore(
    "PlayerData",
    ProfileTemplate
)

local DataService = Knit.CreateService{
    Name = "DataService",
    Client = {},
    Profiles = {},
    Callbacks = {},
}

function DataService:KnitStart()
    for _,Player in ipairs (Players:GetPlayers()) do
        self:LoadData(Player)
    end

    Players.PlayerAdded:Connect(function(Player: Player)
        self:LoadData(Player)
    end)

    Players.PlayerRemoving:Connect(function(Player: Player)
        local Profile = self.Profiles[Player]
        if Profile then
            Profile.Profile:Release()
        end
        self.Callbacks[Player] = nil
    end)
end

function DataService:LoadData(Player: Player)
    local Profile = ProfileStore:LoadProfileAsync("Player_"..Player.UserId)
    if Profile then
        Profile:AddUserId(Player.UserId)
        Profile:Reconcile()
        Profile:ListenToRelease(function()
            self.Profiles[Player].Replica:Destroy()
            self.Profiles[Player] = nil
            Player:Kick("Your data has been loaded elsewhere.")
        end)

        if Player:IsDescendantOf(Players) then
            local PlayerProfile = {
                Profile = Profile,
                Replica = ReplicaService.NewReplica{
                    ClassToken = PlayerProfileClassToken,
                    Tags = {Player = Player},
                    Data = Profile.Data,
                    Replication = "All"
                }
            }
            self.Profiles[Player] = PlayerProfile
            warn("Data loaded for user "..Player.Name)
        else
            Profile:Release()
        end
    end
end

function DataService:SetKey(Player: Player, Key: string, Value: any)
    return Promise.new(function(Resolve, Reject)
        local Profile = self:GetProfile(Player)
        Profile.Profile.Data[Key] = Value
        Profile.Replica:SetValue({Key}, Value)
        if self.Callbacks[Player] then
            if self.Callbacks[Player][Key] then
                for _,Func in pairs (self.Callbacks[Player][Key]) do
                    Func(Value)
                end
            end
        end
        Resolve()
    end)
end

function DataService:AttachFunction(Player: Player, Key: string, Callback: ()->())
    if not self.Callbacks[Player] then
        self.Callbacks[Player] = {}
    end
    if not self.Callbacks[Player][Key] then
        self.Callbacks[Player][Key] = {}
    end
    table.insert(self.Callbacks[Player][Key], Callback)
end


function DataService:GetKey(Player: Player, Key: string)
    return Promise.new(function(Resolve, Reject)
        local Profile = self:GetProfile(Player)
        if not Profile.Profile.Data[Key] then
            Reject()
        else
            Resolve(Profile.Profile.Data[Key])
        end
    end)
end

function DataService:GetProfile(Player: Player)
    local Profile = self.Profiles[Player]
    while Profile == nil and Player:IsDescendantOf(Players) do
        task.wait()
        Profile = self.Profiles[Player]
    end
    return Profile
end

local function PurchaseCheck(Profile, PurchaseId: number, callback: ()->())
    if Profile:IsActive() then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    else
        local MetaData = Profile.MetaData
        
        local  LocalPurchaseIds = MetaData.MetaTags.ProfilePurchaseIds
        
        if not LocalPurchaseIds then
            LocalPurchaseIds = {}
            MetaData.MetaTags.ProfilePurchaseIds = LocalPurchaseIds
        end

        if not table.find(LocalPurchaseIds, PurchaseId) then
            while #LocalPurchaseIds >= Products.PurchaseIdLog do
                table.remove(LocalPurchaseIds, 1)
            end
            table.insert(LocalPurchaseIds, PurchaseId)
            task.spawn(callback)
        end

        local Result = nil

        local function checkMetaTags()
            local savedPurchaseIds = MetaData.MetaTagsLatest.ProfilePurchaseIds
            if savedPurchaseIds and table.find(savedPurchaseIds, PurchaseId) then
                Result = Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end
        checkMetaTags()

        local metaTagsConnection = Profile.MetaTagsUpdated:Connect(function()
            checkMetaTags()
            if not Profile:IsActive() and not Result then
                Result = Enum.ProductPurchaseDecision.NotProcessedYet
            end
        end)

        while not Result do
            task.wait()
        end

        metaTagsConnection:Disconnect()

        return Result

    end
end

local function GrantProduct(Player: Player, ProductId: number)
    local Profile = DataService:GetProfile(Player).Profile
    local ProductFunction = Products.Products[ProductId]
    if ProductFunction then
        ProductFunction(Player, Profile)
    else
        warn("Product Id ", tostring(ProductId), " is not defined.")
    end
end

local function ProcessReceipt(ReceiptInfo)
    local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
    if not Player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local Profile = DataService:GetProfile(Player).Profile

    if Profile then
        return PurchaseCheck(
            Profile,
            ReceiptInfo.PurchaseId,
            function()
                GrantProduct(Player, ReceiptInfo.ProductId)
            end
        )
    else
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

MarketplaceService.ProcessReceipt = ProcessReceipt

return DataService