local wait, spawn = task.wait, task.spawn
repeat wait() until game:IsLoaded()
getgenv().TeleportEnabled = false

local GameName = "Fabled Legacy"
-- Clone each service once
local ClonedPlayers = cloneref(game:GetService("Players"))
local ClonedUserInputService = cloneref(game:GetService("UserInputService"))
local ClonedTweenService = cloneref(game:GetService("TweenService"))
local ClonedReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local ClonedRunService = cloneref(game:GetService("RunService"))
local ClonedCoreGui = cloneref(game:GetService("CoreGui"))
local ClonedHttpService = cloneref(game:GetService("HttpService"))

local Settings = {}
local Vars = {
    -- Services
    Workspace = game:GetService("Workspace"),
    Players = ClonedPlayers,
    UserInputService = ClonedUserInputService,
    TweenService = ClonedTweenService,
    ReplicatedStorage = ClonedReplicatedStorage,
    RunService = ClonedRunService,
    CoreGui = ClonedCoreGui,
    HttpService = ClonedHttpService,

    -- Player & Character
    Client = ClonedPlayers.LocalPlayer,
    Character = ClonedPlayers.LocalPlayer.Character,
    HumanoidRootPart = ClonedPlayers.LocalPlayer.Character:WaitForChild("HumanoidRootPart"),
    Mouse = ClonedPlayers.LocalPlayer:GetMouse(),

    -- Utility
    Match = string.match,
    SetHidden = sethiddenproperty or set_hidden_property or set_hidden_prop,
    GetHidden = gethiddenproperty or get_hidden_property or get_hidden_prop,
    QueueTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport),
    HttpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request,
    Clipboard = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set),
    PlaceId = game.PlaceId,
    JobId = game.JobId
}

-- Game Specific
Vars.UseSpell = Vars.ReplicatedStorage:WaitForChild("useSpell")
Vars.Swing = Vars.ReplicatedStorage:WaitForChild("Swing")
Vars.Enemies = Vars.Workspace:WaitForChild("Enemies")
Vars.SpellGui = Vars.Client:WaitForChild("PlayerGui"):WaitForChild("Spell")

Vars.cooldownQ = Vars.Client.cooldownQ
Vars.cooldownE = Vars.Client.cooldownE
Vars.cooldownR = Vars.Client.cooldownR

Vars.Client.CharacterAdded:Connect(function(char)
	Vars.Character = char
	Vars.HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)


--local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/VeronicVR/UI-Libraries/refs/heads/master/Luna-Interface-Suite", true))()
--local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/VeronicVR/UI-Libraries/924d9aff3cbdb2cb1a67c85e4e12bf3556648b41/Luna-Interface-Suite", true))()
local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/main/source.lua", true))()

local Window = Luna:CreateWindow({
	Name = "Fabled Legacy 🐾 Akora Hub",
	Subtitle = "Welcome, " .. Vars.Client.Name,
	LogoID = "98726723415305", -- 82795327169782 | 127994320313471 
	LoadingEnabled = false,
	LoadingTitle = "Luna Interface Suite",
	LoadingSubtitle = "by Nebula Softworks",

	ConfigSettings = {
		RootFolder = "Akora Hub/Games", -- The Root Folder Is Only If You Have A Hub With Multiple Game Scripts and u may remove it. DO NOT ADD A SLASH
		ConfigFolder = GameName .. "/" .. Vars.Client.DisplayName .. " [ @" .. Vars.Client.Name .. " - " .. Vars.Client.UserId .. " ]" -- The Name Of The Folder Where Luna Will Store Configs For This Script. DO NOT ADD A SLASH
	},

	KeySystem = false, -- As Of Beta 6, Luna Has officially Implemented A Key System!
	KeySettings = {
		Title = "Luna Example Key",
		Subtitle = "Key System",
		Note = "Best Key System Ever! Also, Please Use A HWID Keysystem like Pelican, Luarmor etc. that provide key strings based on your HWID since putting a simple string is very easy to bypass",
		SaveInRoot = false, -- Enabling will save the key in your RootFolder (YOU MUST HAVE ONE BEFORE ENABLING THIS OPTION)
		SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
		Key = {"Example Key"}, -- List of keys that will be accepted by the system, please use a system like Pelican or Luarmor that provide key strings based on your HWID since putting a simple string is very easy to bypass
		SecondAction = {
			Enabled = true, -- Set to false if you do not want a second action,
			Type = "Link", -- Link / Discord.
			Parameter = "" -- If Type is Discord, then put your invite link (DO NOT PUT DISCORD.GG/). Else, put the full link of your key system here.
		}
	}
})

DestroyUI = function()
    Luna:Destroy()
end

local Tabs = {
    Home = Window:CreateHomeTab({
	    SupportedExecutors = {"AWP"},
	    DiscordInvite = "furry",
	    Icon = 2,
    }),
    Main = Window:CreateTab({
    	Name = "Main",
    	Icon = "91755688447120",
    	ImageSource = "Custom",
    	ShowTitle = false
    }),
    Combat = Window:CreateTab({
    	Name = "Combat",
    	Icon = "14193513163",
    	ImageSource = "Custom",
    	ShowTitle = false
    }),
    Inventory = Window:CreateTab({
    	Name = "Inventory",
    	Icon = "6966623635",
    	ImageSource = "Custom",
    	ShowTitle = false
    }),
    Webhook = Window:CreateTab({
    	Name = "Webhook",
    	Icon = "112706694874589",
    	ImageSource = "Custom",
    	ShowTitle = false
    }),
    Settings = Window:CreateTab({
    	Name = "Settings",
    	Icon = "127751182541191",
    	ImageSource = "Custom",
    	ShowTitle = false
    }),
}

local UIElements = {
    Sections = {
        -- Main Tab
        Autofarm,
        AutofarmSettings,
        
        -- Combat Tab
        KillAura,
        KillAuraSettings,

        -- Inventory Tab
        AutoSell,
    },
    Toggles = {
        AOESpell,
        AOESwing,
        Autofarm,
        AutoRetry,
        AutoLeave,

        AutoSell
    },
    Dropdowns = {
        AutofarmMode,
        AutoSellRarity,
        AutoSellTypes,
    },
    Sliders = {
        SpellDistance,
        SigilDistance,
        SwingDistance,
        TeleportHeight,
        TeleportDistance,
        AutoSellLevel,
    },
    Buttons = {
        Destroy_UI,
    },
    Labels = {

    },
}

-- Get the inventory remote function from Vars.ReplicatedStorage.
local getInventory = Vars.ReplicatedStorage:FindFirstChild("getInventory")
if not getInventory then
    warn("getInventory function not found in ReplicatedStorage!")
    return
end

-- Retrieve the initial inventory at startup.
local initialInventory = getInventory:InvokeServer(Vars.Client.UserId)

-- A helper function to recursively print tables.
local function printTable(t, indent)
    indent = indent or ""
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(indent .. tostring(k) .. ":")
            printTable(v, indent .. "  ")
        else
            print(indent .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

local function checkForNewItems()
    local currentInventory = getInventory:InvokeServer(Vars.Client.UserId)
    
    -- Build the sell structure
    local SellTable = {{
        armors = {},
        rings = {},
        spells = {},
        legs = {},
        weapons = {},
        sigils = {},
        helmets = {}
    }}

    for category, catData in pairs(currentInventory) do
        if type(catData) == "table" then
            for guid, itemData in pairs(catData) do
                local alreadyProcessed = false
                if initialInventory[category] and type(initialInventory[category]) == "table" then
                    if initialInventory[category][guid] then
                        alreadyProcessed = true
                    end
                end

                if not alreadyProcessed then
                    local rarity = tostring(itemData.itemRarity or "")
                    local levelReq = tonumber(itemData.levelReq or 0)
                    local itemType = tostring(itemData.itemType or "")
                    local guidValue = tostring(itemData.GUID or guid)

                    local shouldSell = false
                    if Settings.AutoSell_Tog then
                        if Settings.AutoSell_Rarity and type(Settings.AutoSell_Rarity) == "table" then
                            for _, r in ipairs(Settings.AutoSell_Rarity) do
                                if rarity:lower() == r:lower() then
                                    shouldSell = true
                                    break
                                end
                            end
                        end

                        if shouldSell and Settings.AutoSell_Types and type(Settings.AutoSell_Types) == "table" then
                            local typeMatch = false
                            for _, t in ipairs(Settings.AutoSell_Types) do
                                if itemType:lower() == t:lower() then
                                    typeMatch = true
                                    break
                                end
                            end
                            shouldSell = shouldSell and typeMatch
                        end

                        if shouldSell and Settings.AutoSell_MaxLevel then
                            if levelReq > Settings.AutoSell_MaxLevel then
                                shouldSell = false
                            end
                        end
                    end

                    if shouldSell then
                        --print("Auto-selling:", guidValue, "from category:", itemType)
                        if SellTable[1][itemType] then
                            table.insert(SellTable[1][itemType], guidValue)
                        else
                            warn("Unknown item type found: " .. itemType)
                        end
                    else
                        --print("Item does not meet auto-sell criteria.")
                    end

                    -- Mark as processed
                    initialInventory[category] = initialInventory[category] or {}
                    initialInventory[category][guid] = itemData
                end
            end
        end
    end

    -- Fire sellItems if there is at least one item to sell
    local hasItemsToSell = false
    for _, itemList in pairs(SellTable[1]) do
        if #itemList > 0 then
            hasItemsToSell = true
            break
        end
    end

    if hasItemsToSell then
        Vars.ReplicatedStorage.sellItems:InvokeServer(unpack(SellTable))
        --print("Invoked sellItems with table:", SellTable)
    end
end

function Vars.sellAllEligibleItems()
    local currentInventory = getInventory:InvokeServer(Vars.Client.UserId)

    local SellTable = {{
        armors = {},
        rings = {},
        spells = {},
        legs = {},
        weapons = {},
        sigils = {},
        helmets = {}
    }}

    for category, catData in pairs(currentInventory) do
        if type(catData) == "table" then
            for guid, itemData in pairs(catData) do
                local rarity = tostring(itemData.itemRarity or "")
                local levelReq = tonumber(itemData.levelReq or 0)
                local itemType = tostring(itemData.itemType or "")
                local guidValue = tostring(itemData.GUID or guid)
                local isLocked = itemData.itemLocked == true

                local shouldSell = false
                if not isLocked then
                    if Settings.AutoSell_Rarity and type(Settings.AutoSell_Rarity) == "table" then
                        for _, r in ipairs(Settings.AutoSell_Rarity) do
                            if rarity:lower() == r:lower() then
                                shouldSell = true
                                break
                            end
                        end
                    end

                    if shouldSell and Settings.AutoSell_Types and type(Settings.AutoSell_Types) == "table" then
                        local typeMatch = false
                        for _, t in ipairs(Settings.AutoSell_Types) do
                            if itemType:lower() == t:lower() then
                                typeMatch = true
                                break
                            end
                        end
                        shouldSell = shouldSell and typeMatch
                    end

                    if shouldSell and Settings.AutoSell_MaxLevel then
                        if levelReq > Settings.AutoSell_MaxLevel then
                            shouldSell = false
                        end
                    end
                end

                if shouldSell then
                    if SellTable[1][itemType] then
                        table.insert(SellTable[1][itemType], guidValue)
                    else
                        warn("Unknown item type: " .. itemType)
                    end
                end
            end
        end
    end

    local hasItemsToSell = false
    for _, itemList in pairs(SellTable[1]) do
        if #itemList > 0 then
            hasItemsToSell = true
            break
        end
    end

    if hasItemsToSell then
        Vars.ReplicatedStorage.sellItems:InvokeServer(unpack(SellTable))
        print("Bulk-sold eligible items.")
    else
        print("No eligible items found to sell.")
    end
end

function Vars.teleportToMob(enemy)
    if not Vars.HumanoidRootPart then return end
    if not enemy or not enemy.Parent then return end

    -- Find a usable root part in the enemy model
    local enemyHRP =
        enemy:FindFirstChild("Hitbox") or
        enemy:FindFirstChild("HitboxPart") or
        enemy:FindFirstChild("HumanoidRootPart0") or
        enemy:FindFirstChild("HumanoidRootPart") or
        enemy:FindFirstChild("RootPart")

    if not enemyHRP then
        warn("TeleportToMob: Enemy has no root part.")
        return
    end

    -- Calculate final teleport position using settings
    local further = tonumber(Settings.DistanceOffset) or 0
    local height = tonumber(Settings.HeightOffset) or 0
    local targetPos = enemyHRP.Position + (enemyHRP.CFrame.LookVector * further)
    targetPos = targetPos + Vector3.new(0, height, 0)

    -- Create or reuse the teleport platform
    local platformPart = workspace:FindFirstChild("TeleportPlatform")
    if not platformPart then
        platformPart = Instance.new("Part")
        platformPart.Name = "TeleportPlatform"
        platformPart.Size = Vector3.new(6, 1, 6)
        platformPart.Transparency = 1
        platformPart.CanCollide = true
        platformPart.Anchored = true
        platformPart.Parent = workspace
    end

    -- Move player and platform
    Vars.HumanoidRootPart.CFrame = CFrame.new(targetPos)
    platformPart.CFrame = Vars.HumanoidRootPart.CFrame * CFrame.new(0, -3, 0)
end

function Vars.startAutofarm()
    spawn(function()
        while getgenv().TeleportEnabled do
            wait()

            if getgenv().TeleportEnabled then

                if workspace:FindFirstChild("dungeonStarted") and not workspace.dungeonStarted.Value then
                    Vars.ReplicatedStorage.StartDungeon:FireServer()
                end

                if (workspace:FindFirstChild("dungeonFinished") and workspace.dungeonFinished.Value) or (workspace:FindFirstChild("dungeonFailed") and workspace.dungeonFailed.Value) then
                    if Settings.AutoRetry then
                        Vars.ReplicatedStorage.voteRemote:FireServer("repeat")
                    elseif Settings.AutoLeave then
                        Vars.ReplicatedStorage.voteRemote:FireServer("return")
                    end
                    wait(6.5)
                    checkForNewItems()
                end

                -- Enforce noclip: set CanCollide = false on every BasePart in the character.
                for _, part in ipairs(Vars.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end

                -- Validate current target
                if getgenv().CurrentTarget and 
                   (not getgenv().CurrentTarget:IsDescendantOf(Vars.Workspace.Enemies) or 
                    not getgenv().CurrentTarget:FindFirstChildWhichIsA("Humanoid")) then
                    getgenv().CurrentTarget = nil
                end

                -- Acquire a new target if needed
                if not getgenv().CurrentTarget then
                    for _, enemy in ipairs(Vars.Workspace.Enemies:GetChildren()) do
                        if enemy:IsA("Model") then
                            local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
                            if humanoid and humanoid.Health > 0 then
                                getgenv().CurrentTarget = enemy
                                break
                            end
                        end
                    end
                else
                    -- Check if the current target is dead
                    local humanoid = getgenv().CurrentTarget:FindFirstChildWhichIsA("Humanoid")
                    if not humanoid or humanoid.Health <= 0 then
                        getgenv().CurrentTarget = nil
                    end
                end

                -- Teleport to the enemy using the new function
                if getgenv().CurrentTarget then
                    Vars.teleportToMob(getgenv().CurrentTarget)
                end

            else
                break
            end
        end
    end)
end

function Vars.GetClosestEnemy(maxDistance)
    local closest, shortest = nil, maxDistance
    local pos = Vars.HumanoidRootPart.Position

    for _, enemy in ipairs(Vars.Enemies:GetChildren()) do
        -- Look for a hitbox part first
        local hitbox = enemy:FindFirstChild("Hitbox") 
                      or enemy:FindFirstChild("HitboxPart") 
                      or enemy:FindFirstChild("HumanoidRootPart0")
                      or enemy:FindFirstChild("HumanoidRootPart")
                      or enemy:FindFirstChild("RootPart")
        -- If no hitbox is found, then try to get the standard HRP.
        local basePart = hitbox or enemy:FindFirstChild("HRP")
        
        if basePart and basePart:IsA("BasePart") then
            local targetDistance
            if hitbox then
                -- Use hitbox for distance calculation.
                local localPos = hitbox.CFrame:PointToObjectSpace(pos)
                local halfSize = hitbox.Size * 0.5
                local dx = math.max(math.abs(localPos.X) - halfSize.X, 0)
                local dy = math.max(math.abs(localPos.Y) - halfSize.Y, 0)
                local dz = math.max(math.abs(localPos.Z) - halfSize.Z, 0)
                targetDistance = math.sqrt(dx * dx + dy * dy + dz * dz)
            else
                -- Fall back to using the base part position (HRP)
                targetDistance = (pos - basePart.Position).Magnitude
            end

            local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
            if humanoid and targetDistance < shortest then
                if humanoid.Health > 0 then  -- adjust to humanoid.Health.Value if using a NumberValue instead
                    shortest = targetDistance
                    closest = basePart
                end
            end
        end
    end

    return closest
end

spawn(function()
    while true do
        wait()

        local spellTarget = Vars.GetClosestEnemy(tonumber(Settings.SpellDistance_Sli))
        if spellTarget and spellTarget:IsA("BasePart") then
            spellTarget = spellTarget.Parent
        end

        if spellTarget and Settings.AOESpell_Tog then
            local humanoid = spellTarget:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                Vars.HumanoidRootPart.CFrame = CFrame.lookAt(
                    Vars.HumanoidRootPart.Position,
                    Vector3.new(spellTarget:GetPivot().Position.X, Vars.HumanoidRootPart.Position.Y, spellTarget:GetPivot().Position.Z)
                )

                local qChargeLabel = Vars.SpellGui.qMainFrame:FindFirstChild("Charges")
                local qCharges = (qChargeLabel and tonumber(qChargeLabel.Text)) or 0
                if qCharges > 0 or Vars.cooldownQ.Value == 0 then
                    Vars.UseSpell:FireServer("Q")
                end

                local eChargeLabel = Vars.SpellGui.eMainFrame:FindFirstChild("Charges")
                local eCharges = (eChargeLabel and tonumber(eChargeLabel.Text)) or 0
                if eCharges > 0 or Vars.cooldownE.Value == 0 then
                    Vars.UseSpell:FireServer("E")
                end
            end
        end

        local sigilTarget = Vars.GetClosestEnemy(tonumber(Settings.SigilDistance_Sli))
        if sigilTarget and sigilTarget:IsA("BasePart") then
            sigilTarget = sigilTarget.Parent
        end

        if sigilTarget and Vars.cooldownR.Value == 0 and Settings.AOESpell_Tog then
            local humanoid = sigilTarget:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                Vars.UseSpell:FireServer("R")
            end
        end

        local swingTarget = Vars.GetClosestEnemy(tonumber(Settings.SwingDistance_Sli))
        if swingTarget and swingTarget:IsA("BasePart") then
            swingTarget = swingTarget.Parent
        end

        if swingTarget and Settings.AOESwing_Tog then
            local humanoid = swingTarget:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                Vars.Swing:FireServer()
            end
        end
    end
end)

--// Autofarm Tab

UIElements.Sections.Autofarm = Tabs.Main:CreateSection("Autofarm")

UIElements.Sliders.TeleportHeight = UIElements.Sections.Autofarm:CreateSlider({
    Name = "Teleport Height Offset",
    Range = {-50, 50},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(Value)
        Settings.HeightOffset = Value
    end
}, "TeleportHeight_Sli")

UIElements.Sliders.TeleportDistance = UIElements.Sections.Autofarm:CreateSlider({
    Name = "Teleport Distance Offset",
    Range = {-50, 50},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(Value)
        Settings.DistanceOffset = Value
    end
}, "TeleportDistance_Sli")

UIElements.Toggles.Autofarm = UIElements.Sections.Autofarm:CreateToggle({
    Name = "Autofarm",
    Description = "When enabled, continuously teleport to an enemy until it dies, then move to the next.",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().TeleportEnabled = Value
        -- Reset the current target when toggling off or on.
        getgenv().CurrentTarget = nil

        Vars.startAutofarm()
        --[[if not getgenv().TeleportEnabled then
            -- If autofarm is off, re-enable collisions for all character parts.
            for _, part in ipairs(Vars.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if part.CanCollide == false then
                        part.CanCollide = true
                    end
                end
            end
        end--]]
    end
}, "Autofarm_Tog")

UIElements.Sections.AutofarmSettings = Tabs.Main:CreateSection("Autofarm Settings")

UIElements.Toggles.AutoRetry = UIElements.Sections.AutofarmSettings:CreateToggle({
    Name = "Auto Retry",
    Description = "When enabled, this will auto vote to restart the match",
    CurrentValue = false,
    Callback = function(Value)
        Settings.AutoRetry = Value
    end
}, "AutoRetry_Tog")

UIElements.Toggles.AutoLeave = UIElements.Sections.AutofarmSettings:CreateToggle({
    Name = "Auto Leave",
    Description = "When enabled, this will auto vote to leave the match",
    CurrentValue = false,
    Callback = function(Value)
        Settings.AutoLeave = Value
    end
}, "AutoLeave_Tog")

--// Combat Tab

UIElements.Sections.KillAura = Tabs.Combat:CreateSection("Kill Aura")

UIElements.Toggles.AOESpell = UIElements.Sections.KillAura:CreateToggle({
	Name = "Spell Aura",
	Description = nil,
	CurrentValue = false,
    	Callback = function(Value)
            Settings.AOESpell_Tog = Value
    	end
}, "AOESpell_Tog")

UIElements.Toggles.AOESwing = UIElements.Sections.KillAura:CreateToggle({
	Name = "Swing Aura",
	Description = nil,
	CurrentValue = false,
    	Callback = function(Value)
            Settings.AOESwing_Tog = Value
    	end
}, "AOESwing_Tog")

UIElements.Sliders.SpellDistance = UIElements.Sections.KillAura:CreateSlider({
	Name = "Spell Distance",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 50,
    	Callback = function(Value)
            Settings.SpellDistance_Sli = Value
    	end
}, "SpellDistance_Sli")

UIElements.Sliders.SigilDistance = UIElements.Sections.KillAura:CreateSlider({
	Name = "Sigil Distance",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 35,
    	Callback = function(Value)
       	    Settings.SigilDistance_Sli = Value
    	end
}, "SigilDistance_Sli")

UIElements.Sliders.SwingDistance = UIElements.Sections.KillAura:CreateSlider({
	Name = "Swing Distance",
	Range = {0, 50},
	Increment = 1,
	CurrentValue = 22,
    	Callback = function(Value)
       	    Settings.SwingDistance_Sli = Value
    	end
}, "SwingDistance_Sli")

--// Inventory Tab

UIElements.Sections.AutoSell = Tabs.Inventory:CreateSection("Auto Sell")

--[[
UIElements.Toggles.AutoSell = UIElements.Sections.AutoSell:CreateToggle({
    Name = "Auto Sell",
    Description = nil,
    CurrentValue = false,
    	Callback = function(Value)
            Settings.AutoSell_Tog = Value
    	end
}, "AutoSell_Tog")
--]]

UIElements.Labels.AutoSellInfo = UIElements.Sections.AutoSell:CreateLabel({
	Text = "WILL SELL ALL ITEMS BESIDES LOCKED ITEMS! LOCK YOUR NEEDED ITEMS!",
	Style = 3
})

UIElements.Dropdowns.AutoSellRarity = UIElements.Sections.AutoSell:CreateDropdown({
    Name = "Auto Sell Rarity",
    	Description = "Select which Rarities you want to sell",
    Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary"},
    	CurrentOption = {"Common", "Uncommon"},
    	MultipleOptions = true,
    	SpecialType = nil,
    Callback = function(Options)   
        Settings.AutoSell_Rarity = Options
    end
}, "AutoSellRarity_Drp")

UIElements.Dropdowns.AutoSellTypes = UIElements.Sections.AutoSell:CreateDropdown({
    Name = "Auto Sell Types",
    	Description = "Select which types of items you want to sell",
    Options = {"helmets", "armors", "legs", "weapons", "rings", "sigils", "spells"},
    	CurrentOption = {"helmets", "armors", "legs", "weapons", "rings", "sigils", "spells"},
    	MultipleOptions = true,
    	SpecialType = nil,
    Callback = function(Options)   
        Settings.AutoSell_Types = Options
    end
}, "AutoSellType_Drp")

UIElements.Sliders.AutoSellLevel = UIElements.Sections.AutoSell:CreateSlider({
	Name = "Below Level",
	Range = {0, 300},
	Increment = 1,
	CurrentValue = 1,
    	Callback = function(Value)
       	    Settings.AutoSell_MaxLevel = Value
    	end
}, "SwingDistance_Sli")

UIElements.Buttons.SellItems  = UIElements.Sections.AutoSell:CreateButton({
	Name = "Sell Items",
	Description = "Will sell all items that fit the selected options",
    Callback = function()
        Vars.sellAllEligibleItems()
    end
})

--// Webhook Tab


--// Settings Tab
UIElements.Buttons.Destroy_UI  = Tabs.Settings:CreateButton({
	Name = "Destroy UI",
	Description = "Will remove the UI",
    Callback = function()
        DestroyUI()
    end
})

Tabs.Settings:BuildConfigSection()
Luna:LoadAutoloadConfig()
