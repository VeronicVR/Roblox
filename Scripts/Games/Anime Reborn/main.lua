local wait, spawn = task.wait, task.spawn
repeat wait() until game:IsLoaded()

local GameName = "Anime Reborn"
-- Clone each service once
local ClonedPlayers = cloneref(game:GetService("Players"))
local ClonedUserInputService = cloneref(game:GetService("UserInputService"))
local ClonedTweenService = cloneref(game:GetService("TweenService"))
local ClonedReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local ClonedRunService = cloneref(game:GetService("RunService"))
local ClonedCoreGui = cloneref(game:GetService("CoreGui"))
local ClonedHttpService = cloneref(game:GetService("HttpService"))

local Locals = {
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
    JobId = game.JobId,

    -- Game Specific
    Events = ClonedReplicatedStorage:WaitForChild("Events"),
    UiCommunication = ClonedReplicatedStorage.Events:WaitForChild("UiCommunication"),
    ChallengeModifiers = {},
    Maps = {},
    
}
repeat wait() until Locals.ReplicatedStorage.ServerLoaded.Value == true

ProfileData = require(game.ReplicatedStorage.Libs.DataAccessAPIClient):GetAPI():GetLocalProfileClass()

print(ProfileData:GetField("Level"))
local function deepEquals(a, b)
    if type(a) ~= type(b) then
        return false
    end
    if type(a) ~= "table" then
        return a == b
    end
    for k, v in pairs(a) do
        if not deepEquals(v, b[k]) then
            return false
        end
    end
    for k, v in pairs(b) do
        if a[k] == nil then
            return false
        end
    end
    return true
end
local ClientData_ChangeLog = {
    Level = {},
    XP = {},
    Currencies = {},
    SlotData = {},
    Inventory = {}
}

local ClientData = {
    Level = nil,
    XP = nil,
    Currencies = nil,
    SlotData = nil,
    Inventory = nil
}

-- Assumes that ProfileData and deepEquals are defined and available in your environment.
task.spawn(function()
    -- Fetch initial profile data.
    local previous = {
        Level = ProfileData:GetField("Level"),
        XP = ProfileData:GetField("XP"),
        Currencies = ProfileData:GetField("Currencies"),
        SlotData = ProfileData:GetField("Slotbar"),
        Inventory = ProfileData:GetField("Inventory")
    }
    
    -- Initialize ClientData with current values.
    ClientData.Level = previous.Level
    ClientData.XP = previous.XP
    ClientData.Currencies = previous.Currencies
    ClientData.SlotData = previous.SlotData
    ClientData.Inventory = previous.Inventory

    -- Prepare the change log for inventory sub-keys.
    if type(previous.Inventory) == "table" then
        for subKey, _ in pairs(previous.Inventory) do
            ClientData_ChangeLog.Inventory[subKey] = {}
        end
    end

    while true do
        -- Fetch the current profile data.
        local current = {
            Level = ProfileData:GetField("Level"),
            XP = ProfileData:GetField("XP"),
            Currencies = ProfileData:GetField("Currencies"),
            SlotData = ProfileData:GetField("Slotbar"),
            Inventory = ProfileData:GetField("Inventory")
        }

        -- Loop through each key to compare previous and current values.
        for key, currentValue in pairs(current) do
            if key == "Inventory" then
                -- Handle inventory as a table with possible sub-keys.
                local previousValue = previous.Inventory or {}
                local inventoryKeys = {}

                -- Build union of keys from current and previous inventory.
                if type(currentValue) == "table" then
                    for subKey, _ in pairs(currentValue) do
                        inventoryKeys[subKey] = true
                    end
                end
                if type(previousValue) == "table" then
                    for subKey, _ in pairs(previousValue) do
                        inventoryKeys[subKey] = true
                    end
                end

                -- Compare each sub-key in the inventory.
                for subKey, _ in pairs(inventoryKeys) do
                    local prevSub = (previousValue or {})[subKey]
                    local currSub = (currentValue or {})[subKey]
                    if not deepEquals(prevSub, currSub) then
                        -- Ensure the change log for the subKey exists.
                        if ClientData_ChangeLog.Inventory[subKey] == nil then
                            ClientData_ChangeLog.Inventory[subKey] = {}
                        end
                        table.insert(ClientData_ChangeLog.Inventory[subKey], {
                            old = prevSub,
                            new = currSub,
                            time = os.time()
                        })
                        previous.Inventory = previous.Inventory or {}
                        previous.Inventory[subKey] = currSub
                    end
                end

                ClientData.Inventory = currentValue

            else
                -- For other top-level keys (Level, XP, Currencies, SlotData).
                local previousValue = previous[key]
                if not deepEquals(previousValue, currentValue) then
                    table.insert(ClientData_ChangeLog[key], {
                        old = previousValue,
                        new = currentValue,
                        time = os.time()
                    })
                    previous[key] = currentValue
                end
                ClientData[key] = currentValue
            end
        end

        task.wait(1)
    end
end)

--#region Unit Registry
    Locals.unitsRegistry = Locals.ReplicatedStorage.Registry.Units
    local AllUnits = {}
    local UniInfo = {}

    for _, moduleScript in ipairs(Locals.unitsRegistry:GetChildren()) do
        if moduleScript:IsA("ModuleScript") then
            local success, moduleData = pcall(function() return require(moduleScript) end)
            if success and moduleData and moduleData.configuration then
                local cfg = moduleData.configuration

                table.insert(AllUnits, cfg.DisplayName)

                table.insert(UniInfo, {
                    MaxPlacementAmount = cfg.MaxPlacementAmount,
                    MaxUpgrades = cfg.MaxUpgrades,
                    DisplayName = cfg.DisplayName,
                    PlacementType = cfg.PlacementType,
                    PlacementPrice = cfg.PlacementPrice,
                    UpgradesInfo = cfg.UpgradesInfo,
                })
            else
                warn("Failed to load module: " .. moduleScript.Name)
            end
        end
    end
--#endregion

local Directory = "Akora Hub/Games/" .. GameName .. "/" .. Locals.Client.DisplayName .. " [ @" .. Locals.Client.Name .. " - " .. Locals.Client.UserId .. " ]"

function DebugPrint(...)
    local args = {...}
    local message = ""
    for i, v in ipairs(args) do
        message = message .. tostring(v) .. "\t"
    end
    print("[Akora Hub] |", message)
end

function Locals.JoinQueue(queueZoneName)
    local map = Locals.Workspace:FindFirstChild("Map")
    if not map then
        warn("Map not found in Workspace!")
        return
    end

    local targetZone = map:FindFirstChild(queueZoneName)
    if not targetZone then
        warn(queueZoneName .. " not found in workspace.Map!")
        return
    end

    for _, descendant in ipairs(targetZone:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name == "Hitbox" then
            firetouchinterest(Locals.HumanoidRootPart, descendant, 0)
            wait()
            firetouchinterest(Locals.HumanoidRootPart, descendant, 1)
        end
    end
    wait(0.5)
end

function Locals.SelectLaunch(GameScenarioID, MapName, GameType, Owner, FriendsOnly, Difficulty)
    local secondArg = {
        GameScenarioID = GameScenarioID,
        MapName = MapName,
        GameType = GameType,
        Owner = Owner,
        FriendsOnly = FriendsOnly,
        Difficulty = Difficulty
    }
    
    local args = {
        "MapSelection/SelectMap",
        secondArg
    }
    
    Locals.UiCommunication:FireServer(unpack(args))
end

Locals.QueueZoneData = Locals.QueueZoneData or {}
local function logOnTextChange(textLabel, labelType, uiData)
    textLabel:GetPropertyChangedSignal("Text"):Connect(function()
        local newText = textLabel.Text
        if labelType == "ActName" then
            uiData.ActName = newText
        elseif labelType == "MapName" then
            uiData.MapName = newText
        elseif labelType == "Challenge" then
            uiData.ChallengeModifiers[textLabel.Name] = newText
        end
    end)
    -- Store the initial value.
    if labelType == "ActName" then
        uiData.ActName = textLabel.Text
    elseif labelType == "MapName" then
        uiData.MapName = textLabel.Text
    elseif labelType == "Challenge" then
        uiData.ChallengeModifiers[textLabel.Name] = textLabel.Text
    end
end
function Locals.UpdateQueueZoneData()
    Locals.QueueZoneData = {}

    local map = Locals.Workspace:FindFirstChild("Map")
    if not map then
        warn("Map not found in Workspace!")
        return
    end

    local zoneNames = {
        "QueueChallengeZones",
        "QueueDungeonZones",
        "QueueRaidZones",
        "QueueYearZones",
        "QueueZones"
    }

    -- Loop through each zone model.
    for _, zoneName in ipairs(zoneNames) do
        local zoneModel = map:FindFirstChild(zoneName)
        if zoneModel and zoneModel:IsA("Model") then
            Locals.QueueZoneData[zoneName] = {}  -- Create a table for this zone

            -- Process each child model within the zone.
            for _, childModel in ipairs(zoneModel:GetChildren()) do
                if childModel:IsA("Model") then
                    local childData = {
                        Model = childModel,
                        Hitboxes = {},
                        QueueDisplays = {},
                        GuiContainers = {},
                        SurfaceGuiData = {}  -- Stores UI logging data for each connected SurfaceGui.
                    }

                    -- Search this model for Hitbox, QueueDisplay, and GuiContainer parts.
                    for _, descendant in ipairs(childModel:GetDescendants()) do
                        if descendant:IsA("BasePart") then
                            if descendant.Name == "Hitbox" then
                                table.insert(childData.Hitboxes, descendant)
                            elseif descendant.Name == "QueueDisplay" then
                                table.insert(childData.QueueDisplays, descendant)
                            elseif descendant.Name == "GuiContainer" then
                                table.insert(childData.GuiContainers, descendant)
                                -- Search within the LocalPlayer's PlayerGui MatchStatsFolder for SurfaceGuis with Adornee = descendant.
                                local playerGui = Locals.Client:WaitForChild("PlayerGui")
                                local matchStatsFolder = playerGui:WaitForChild("MatchStatsFolder")
                                for _, obj in ipairs(matchStatsFolder:GetDescendants()) do
                                    if obj:IsA("SurfaceGui") and obj.Adornee == descendant then
                                        table.insert(childData.SurfaceGuiData, {
                                            SurfaceGui = obj,
                                            UIData = {    -- This table will store our logged UI text data.
                                                ActName = nil,
                                                MapName = nil
                                                -- ChallengeModifiers will only be added if a valid Challenge frame exists.
                                            }
                                        })
                                    end
                                end
                            end
                        end
                    end

                    table.insert(Locals.QueueZoneData[zoneName], childData)
                end
            end
        else
            warn(zoneName .. " not found or is not a Model in workspace.Map!")
        end
    end

    for zoneName, zoneEntries in pairs(Locals.QueueZoneData) do
        for _, entry in ipairs(zoneEntries) do
            for _, sgEntry in ipairs(entry.SurfaceGuiData) do
                local surfaceGui = sgEntry.SurfaceGui
                local containerFrame = surfaceGui:FindFirstChild("Container", true)
                if containerFrame then
                    local mapData = containerFrame:FindFirstChild("MapData", true)
                    if mapData then
                        local uiData = sgEntry.UIData  -- Shortcut reference

                        -- Set up ActName and MapName logging.
                        local actNameLabel = mapData:FindFirstChild("ActName", true)
                        if actNameLabel and actNameLabel:IsA("TextLabel") then
                            logOnTextChange(actNameLabel, "ActName", uiData)
                        else
                            uiData.ActName = "Not found"
                        end

                        local mapNameLabel = mapData:FindFirstChild("MapName", true)
                        if mapNameLabel and mapNameLabel:IsA("TextLabel") then
                            logOnTextChange(mapNameLabel, "MapName", uiData)
                        else
                            uiData.MapName = "Not found"
                        end

                        -- For challenge modifiers: only add them if a Challenge frame exists AND it contains at least one non-empty TextLabel.
                        local challengeFrame = mapData:FindFirstChild("Challenge", true)
                        if challengeFrame and challengeFrame:IsA("Frame") then
                            local foundNonEmpty = false
                            for _, child in ipairs(challengeFrame:GetChildren()) do
                                if child:IsA("TextLabel") and child.Name ~= "TimerDisplay" and child.Text ~= "" then
                                    foundNonEmpty = true
                                    break
                                end
                            end
                            if foundNonEmpty then
                                uiData.ChallengeModifiers = {}
                                for _, child in ipairs(challengeFrame:GetChildren()) do
                                    if child:IsA("TextLabel") and child.Name ~= "TimerDisplay" and child.Text ~= "" then
                                        logOnTextChange(child, "Challenge", uiData)
                                    end
                                end
                            end
                        end
                    else
                        sgEntry.UIData.MapDataFound = false
                    end
                else
                    sgEntry.UIData.ContainerFound = false
                end
            end
        end
    end
end

function Locals.PrintQueueZoneData()
    for zoneName, zoneEntries in pairs(Locals.QueueZoneData) do
        print("===== Zone: " .. zoneName .. " =====")
        for i, entry in ipairs(zoneEntries) do
            print("  Model: " .. (entry.Model and entry.Model:GetFullName() or "None"))
            if entry.Hitboxes and #entry.Hitboxes > 0 then
                for j, hitbox in ipairs(entry.Hitboxes) do
                    print("    Hitbox: " .. hitbox:GetFullName())
                end
            end
            if entry.QueueDisplays and #entry.QueueDisplays > 0 then
                for j, qd in ipairs(entry.QueueDisplays) do
                    print("    QueueDisplay: " .. qd:GetFullName())
                end
            end
            if entry.GuiContainers and #entry.GuiContainers > 0 then
                for j, gc in ipairs(entry.GuiContainers) do
                    print("    GuiContainer: " .. gc:GetFullName())
                end
            end
            if entry.SurfaceGuiData and #entry.SurfaceGuiData > 0 then
                for j, sgEntry in ipairs(entry.SurfaceGuiData) do
                    print("    SurfaceGui: " .. (sgEntry.SurfaceGui and sgEntry.SurfaceGui:GetFullName() or "Unknown"))
                    local uiData = sgEntry.UIData or {}
                    print("      ActName: " .. tostring(uiData.ActName))
                    print("      MapName: " .. tostring(uiData.MapName))
                    if uiData.ChallengeModifiers then
                        if next(uiData.ChallengeModifiers) then
                            for modName, modVal in pairs(uiData.ChallengeModifiers) do
                                print("      Challenge Modifier - " .. modName .. ": " .. tostring(modVal))
                            end
                        else
                            print("      Challenge Modifier: (present but no valid modifiers found)")
                        end
                    else
                        print("      Challenge Modifier: not present")
                    end
                end
            end
        end
    end
end
Locals.UpdateQueueZoneData()

local puppyPuns = {
    "Zero-day alert: Puppy mode activated.",
    "System log: Puppy injection executed on the mainframe.",
    "Security notice: Unpatched puppy protocol exploited the interface.",
    "Network scan: Puppy backdoor bypassed firewall defenses.",
    "Error detected: Puppy buffer overflow—excess puppy bytes in memory.",
    "Incident report: Rogue puppy payload infiltrated the endpoint.",
    "Alert: Unauthorized puppy shell command triggered remote execution.",
    "Forensic trace: Puppy script accessed secure nodes via a hidden backdoor.",
    "Critical update: Puppy patch applied to remediate the exploit.",
    "Debug log: Puppy debug mode uncovered concealed vulnerabilities."
}
math.randomseed(os.time())
local selectedPun = puppyPuns[math.random(1, #puppyPuns)]

for _, module in ipairs(Locals.ReplicatedStorage.Registry.Challenges:GetChildren()) do
    if module:IsA("ModuleScript") then
        local challengeData = require(module)
        table.insert(Locals.ChallengeModifiers, challengeData.DisplayName or "Unknown")
    end
end

for _, module in ipairs(Locals.ReplicatedStorage.Registry.Maps:GetChildren()) do
    if module:IsA("ModuleScript") then
        local mapData = require(module)
        table.insert(Locals.Maps, mapData.DisplayName or "Unknown")
    end
end


local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = true
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = GameName .. " 🐾 Akora Hub",
    Footer = selectedPun,
    Size = UDim2.fromOffset(820, 450),
    ShowCustomCursor = false,
    Font = Enum.Font.FredokaOne,
    ToggleKeybind = Enum.KeyCode.RightControl,
    Center = true,
    AutoShow = true,
    Resizable = false
})

local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Summoning = Window:AddTab("Summoning", "atom"),
    AutoPlay = Window:AddTab("Auto Play", "play"),
    Macro = Window:AddTab("Macro", "cpu"),
    Webhook = Window:AddTab("Webhook", "webhook"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

--#region UI Settings
    local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
    MenuGroup:AddButton("Unload UI", function()
        Library:Unload()
    end)
    MenuGroup:AddToggle("KeybindMenuOpen", {
        Default = Library.KeybindFrame.Visible,
        Text = "Open Keybind Menu",
        Callback = function(value)
            Library.KeybindFrame.Visible = value
        end,
    })
    MenuGroup:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor",
        Default = false,
        Callback = function(Value)
            Library.ShowCustomCursor = Value
        end,
    })
    MenuGroup:AddDropdown("NotificationSide", {
        Values = { "Left", "Right" },
        Default = "Right",

        Text = "Notification Side",

        Callback = function(Value)
            Library:SetNotifySide(Value)
        end,
    })
    MenuGroup:AddDropdown("DPIDropdown", {
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%",

        Text = "DPI Scale",

        Callback = function(Value)
            Value = Value:gsub("%%", "")
            local DPI = tonumber(Value)

            Library:SetDPIScale(DPI)
        end,
    })
    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Menu bind")
        :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

    Library.ToggleKeybind = Options.MenuKeybind
--#endregion
--#region Theme & Save
    ThemeManager:SetLibrary( Library )
    SaveManager:SetLibrary( Library )
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    ThemeManager:SetFolder( "Akora Hub" )
    SaveManager:SetFolder( Directory )
    SaveManager:BuildConfigSection( Tabs["UI Settings"] )
    ThemeManager:ApplyToTab( Tabs["UI Settings"] )
    SaveManager:LoadAutoloadConfig()
--#endregion

--[[
    local WarningTab = Tabs["UI Settings"]:AddTab("Warning Box", "user")
    
    WarningTab:UpdateWarningBox({
    	Visible = true,
    	Title = "Warning",
    	Text = "This is a warning box!",
    })
--]]

--#region Main
    local Launcher_GroupBox = Tabs.Main:AddLeftGroupbox("Launcher")
    Launcher_GroupBox:AddDropdown("Launch_Mode", {
    	Values = { "Story", "Legend", "Raids", "Dungeons", "Adventure" },
    	Default = 1,
    	Multi = false,

    	Text = "Mode",
    	Tooltip = "Select what Mode to launch into",
    	DisabledTooltip = "I am disabled!",

    	Searchable = true,

    	Callback = function(Value)
    		--print("Akora Hub | Dropdown got changed. New value:", Value)
    	end,

    	Disabled = false,
    	Visible = true,
    })
    Launcher_GroupBox:AddDropdown("Launch_Map", {
     	Values = Locals.Maps,
    	Default = 1,
    	Multi = false,

    	Text = "Map",
    	Tooltip = "Will join the selected map",
    	DisabledTooltip = "I am disabled!",

    	Searchable = true,

    	Callback = function(Value)
    		--print("Akora Hub | Dropdown got changed. New value:", Value)
    	end,

    	Disabled = false,
    	Visible = true,
    })
    Launcher_GroupBox:AddDropdown("Launch_Act", {
     	Values = {"1", "2", "3", "4", "5", "6"},
    	Default = 1,
    	Multi = false,

    	Text = "Act",
    	Tooltip = "Will set the desired Act",
    	DisabledTooltip = "I am disabled!",

    	Searchable = true,

    	Callback = function(Value)
    		--print("Akora Hub | Dropdown got changed. New value:", Value)
    	end,

    	Disabled = false,
    	Visible = true,
    })
    Launcher_GroupBox:AddDropdown("Launch_Difficulty", {
    	Values = { "Normal", "Nightmare", "Infinite" },
    	Default = 1,
    	Multi = false,

    	Text = "Difficulty",
    	Tooltip = "WIll set the Difficulty of the map",
    	DisabledTooltip = "I am disabled!",

    	Searchable = true,

    	Callback = function(Value)
    		--print("Akora Hub | Dropdown got changed. New value:", Value)
    	end,

    	Disabled = false,
    	Visible = true,
    })
    Launcher_GroupBox:AddSlider("Launch_JoinDelay", {
    	Text = "Join Delay (Seconds)",
    	Default = 2,
    	Min = 0,
    	Max = 15,
    	Rounding = 1,
    	Compact = false,

    	Callback = function(Value)
    		--print("Akora Hub | MySlider was changed! New value:", Value)
    	end,

    	Tooltip = "This is the delay (in seconds) that it will wait to join a match.",
    	DisabledTooltip = "I am disabled!",

    	Disabled = false,
    	Visible = true,
    })
    Launcher_GroupBox:AddToggle("Friends_Only", {
    	Text = "Friend's Only",
    	Tooltip = "Will set the launch type to be `Friends Only`",
    	DisabledTooltip = "I am disabled!",

    	Default = true,
    	Disabled = false,
    	Visible = true,
    	Risky = false,

    	Callback = function(Value)
    		--print("Akora Hub | MyToggle changed to:", Value)
    	end,
    })
    Launcher_GroupBox:AddToggle("AutoLaunch", {
    	Text = "Auto Launch",
    	Tooltip = "Enable this after setting the above options!", -- Information shown when you hover over the toggle
    	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the toggle while it's disabled

    	Default = false, -- Default value (true / false)
    	Disabled = false, -- Will disable the toggle (true / false)
    	Visible = true, -- Will make the toggle invisible (true / false)
    	Risky = false, -- Makes the text red (the color can be changed using Library.Scheme.Red) (Default value = false)

    	Callback = function(Value)
    		--print("Akora Hub | MyToggle changed to:", Value)
    	end,
    })
--#endregion

--#region Auto Challenge
    local Challenge_GroupBox = Tabs.Main:AddLeftGroupbox("Auto Challenge")
    Challenge_GroupBox:AddDropdown("Ignore_Map", {
    	Values = Locals.Maps,
    	Default = 0,
    	Multi = true,

    	Text = "Ignore Map",
    	Tooltip = "Will ignore the selected map(s)",
    	DisabledTooltip = "I am disabled!",

    	Searchable = true,

    	Callback = function(Value)
    		--print("Akora Hub | Dropdown got changed. New value:", Value)
    	end,

    	Disabled = false,
    	Visible = true,
    })
    Challenge_GroupBox:AddDropdown("Ignore_ChallengeType", {
    	Values = Locals.ChallengeModifiers,
    	Default = 0,
    	Multi = true,

    	Text = "Ignore Challenge",
    	Tooltip = "Will ignore the selected challenges",
    	DisabledTooltip = "I am disabled!", 

    	Searchable = true,

    	Callback = function(Value)
    		--print("Akora Hub | Dropdown got changed. New value:", Value)
    	end,

    	Disabled = false,
    	Visible = true,
    })
    Challenge_GroupBox:AddToggle("Launch_Challenge", {
    	Text = "Launch Challenge",
    	Tooltip = "While in lobby, WIll automatically join into desired Challenges",
    	DisabledTooltip = "I am disabled!",

    	Default = false,
    	Disabled = false,
    	Visible = true,
    	Risky = false,

    	Callback = function(Value)
    		--print("Akora Hub | MyToggle changed to:", Value)
    	end,
    })
--#endregion

--#region Auto Functions
    local MiscFunc_GroupBox = Tabs.Main:AddRightGroupbox("Misc Functions")
    MiscFunc_GroupBox:AddToggle("AutoNext", {
    	Text = "Auto Next",
    	Tooltip = "Will Automatically go to the next Act or Portal (if possible) once match ends.",
    	DisabledTooltip = "I am disabled!",

    	Default = false,
    	Disabled = false,
    	Visible = true,
    	Risky = false,

    	Callback = function(Value)
    		--print("Akora Hub | MyToggle changed to:", Value)
    	end,
    })
    MiscFunc_GroupBox:AddToggle("AutoRetry", {
    	Text = "Auto Retry",
    	Tooltip = "Will Auto Retry/Restart (if possible) once match ends.",
    	DisabledTooltip = "I am disabled!",

    	Default = false,
    	Disabled = false,
    	Visible = true,
    	Risky = false,

    	Callback = function(Value)
    		--print("Akora Hub | MyToggle changed to:", Value)
    	end,
    })
    MiscFunc_GroupBox:AddToggle("AutoLeave", {
    	Text = "Auto Leave",
    	Tooltip = "Will Auto Retry/Restart (if possible) once match ends.",
    	DisabledTooltip = "I am disabled!",

    	Default = false,
    	Disabled = false,
    	Visible = true,
    	Risky = false,

    	Callback = function(Value)
    		--print("Akora Hub | MyToggle changed to:", Value)
    	end,
    })
    MiscFunc_GroupBox:AddToggle("PlaceAnywhere", {
    	Text = "Place Anywhere",
    	Tooltip = "Will allow you to place units anywhere.",
    	DisabledTooltip = "Currently a WIP!",

    	Default = false,
    	Disabled = true,
    	Visible = true,
    	Risky = true,

    	Callback = function(Value)
    		--print("Akora Hub | MyToggle changed to:", Value)
    	end,
    })
--#endregion

--#region Join Friends Section
    local JoinFriend_GroupBox = Tabs.Main:AddRightGroupbox("Join Friends")
    JoinFriend_GroupBox:AddDropdown("JoinFriendList", {
        SpecialType = "Player",
        Text = "Select Friends",
        Multi = true,
        ExcludeLocalPlayer = true
    })
    JoinFriend_GroupBox:AddToggle("JoinFriend", {
    	Text = "Join Friend",
    	Tooltip = "Will try to join the friend(s) selected above if they are in the lobby.",
    	DisabledTooltip = "I am disabled!",

    	Default = false,
    	Disabled = false,
    	Visible = true,
    	Risky = false,

    	Callback = function(Value)
    		--print("Akora Hub | MyToggle changed to:", Value)
    	end,
    })
--#endregion

--#region Summoning
    local Summon_GroupBox = Tabs.Summoning:AddLeftGroupbox("Summoning")
    Summon_GroupBox:AddDropdown("Summon_Method", {
        Values = {"1 Pull", "10 Pull"},
        Default = 0,
        Multi = false,

        Text = "Select Summon Method",
        Tooltip = "Will summon till you aquire the selected unit.",
        DisabledTooltip = "I am disabled!",

        Searchable = true,

        Callback = function(Value)
            --print("Akora Hub | Dropdown got changed. New value:", Value)
        end,

        Disabled = false,
        Visible = true,
    })
    
    Summon_GroupBox:AddToggle("Auto_Summon", {
        Text = "Auto Summon",
        Tooltip = "Will automatically summon units.",
        DisabledTooltip = "I am disabled!",

        Default = false,
        Disabled = true,
        Visible = true,
        Risky = false,

        Callback = function(Value)
            --print("Akora Hub | MyToggle changed to:", Value)
        end,
    })
    Summon_GroupBox:AddDivider()
    Summon_GroupBox:AddLabel("Summon Settings")
    Summon_GroupBox:AddDropdown("Summon_Settings_Type", {
        Values = {"Till Unit", "Use Gem Amount"},
        Default = 0,
        Multi = false,

        Text = "Select Units",
        Tooltip = "Will summon till you aquire the selected unit.",
        DisabledTooltip = "I am disabled!",

        Searchable = true,

        Callback = function(Value)
            --print("Akora Hub | Dropdown got changed. New value:", Value)
        end,

        Disabled = false,
        Visible = true,
    })
    Summon_GroupBox:AddDropdown("Summon_Til_Unit", {
        Values = AllUnits,
        Default = 0,
        Multi = false,

        Text = "Select Units",
        Tooltip = "Will summon till you acquire the selected unit.",
        DisabledTooltip = "I am disabled!",

        Searchable = true,

        Callback = function(Value)
            --print("Akora Hub | Dropdown got changed. New value:", Value)
        end,

        Disabled = false,
        Visible = false,
    })
    Summon_GroupBox:AddInput("Summon_UseGemAmount", {
        Default = 1,
        Numeric = true,
        Finished = false,
        ClearTextOnFocus = false,

        Text = "Gem Amount",

        Placeholder = "Put a number here",

        Callback = function(Value)
            --print("Akora Hub | Text updated. New text:", Value)
        end,

        Disabled = false,
        Visible = false,
    })
    Summon_GroupBox:AddToggle("SkipSummonAnimation", {
        Text = "Skip Animation",
        Tooltip = "Will automatically skip the summon animation.",
        DisabledTooltip = "I am disabled!",

        Default = false,
        Disabled = true,
        Visible = true,
        Risky = false,

        Callback = function(Value)
            --print("Akora Hub | MyToggle changed to:", Value)
        end,
    })

    Options.Summon_Settings_Type:OnChanged(function()
        if Options.Summon_Settings_Type.Value == "Till Unit" then
            Options.Summon_Til_Unit:SetVisible(true)
            Options.Summon_UseGemAmount:SetVisible(false)
        elseif Options.Summon_Settings_Type.Value == "Use Gem Amount" then
            Options.Summon_Til_Unit:SetVisible(false)
            Options.Summon_UseGemAmount:SetVisible(true)
        end
    end)
--endregion

--#region Auto Play Section
    --#region Smart Autoplay Section
        local SmartAutoplay_GroupBox = Tabs.AutoPlay:AddLeftGroupbox("Smart Auto Play")
        SmartAutoplay_GroupBox:AddSlider("Autoplay_Distance", {
            Text = "Placement Distance",
            Default = 30,
            Min = 0,
            Max = 100,
            Rounding = 0,
            Compact = false,
        
            Callback = function(Value)
                --print("Akora Hub | MySlider was changed! New value:", Value)
            end,
        
            Tooltip = "How far away from the enemy spawn units place.",
            DisabledTooltip = "I am disabled!",
        
            Disabled = false,
            Visible = true,
        })
        SmartAutoplay_GroupBox:AddToggle("Autoplay_Enable", {
            Text = "Enabled Smart Autoplay",
            Tooltip = "Will automatically place and upgrade units at selected distance.",
            DisabledTooltip = "I am disabled!",
        
            Default = false,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(Value)
                --print("Akora Hub | MyToggle changed to:", Value)
            end,
        })
    --#endregion
    
    local SmartPlacement_TabBox = Tabs.AutoPlay:AddRightTabbox()
    --#region Smart (Place on Wave) Settings Section
        local Smart_PlaceWave = SmartPlacement_TabBox:AddTab("Place on Wave")
        Smart_PlaceWave:AddToggle("Autoplay_PlaceFocusFarm", {
            Text = "Prioritize Farm(s)",
            Tooltip = "Will prioritize placing farms before other units.",
            DisabledTooltip = "I am disabled!",
        
            Default = false,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(Value)
                --print("Akora Hub | MyToggle changed to:", Value)
            end,
        })
        for i = 1, 6 do
            Smart_PlaceWave:AddSlider("SmartPlay_PlaceWave_Unit" .. i, {
                Text = "Unit " .. i,
                Default = 1,
                Min = 0,
                Max = 40,
                Rounding = 1,
                Compact = false,
            
                Callback = function(Value)
                    --print("Akora Hub | MySlider was changed! New value:", Value)
                end,
            
                --Tooltip = "",
                DisabledTooltip = "I am disabled!",
            
                Disabled = false,
                Visible = true,
            })
        end
    --#endregion
    
    --#region Smart (Place Cap) Settings Section
        local Smart_PlaceCap = SmartPlacement_TabBox:AddTab("Place Cap")
        for i = 1, 6 do
            Smart_PlaceCap:AddSlider("SmartPlay_PlaceCap_Unit" .. i, {
                Text = "Unit " .. i,
                Default = 1,
                Min = 0,
                Max = 8,
                Rounding = 1,
                Compact = false,
            
                Callback = function(Value)
                    --print("Akora Hub | MySlider was changed! New value:", Value)
                end,
            
                --Tooltip = "",
                DisabledTooltip = "I am disabled!",
            
                Disabled = false,
                Visible = true,
            })
        end
    --#endregion
    
    local SmartUpgrade_TabBox = Tabs.AutoPlay:AddRightTabbox()
    --#region Smart (Upgrade on Wave) Settings Section
        local Smart_UpgradeWave = SmartUpgrade_TabBox:AddTab("Upgrade on Wave")
        Smart_UpgradeWave:AddToggle("Autoplay_Upgrade", {
            Text = "Enabled Auto Upgrade",
            Tooltip = "Will automatically upgrade units at required waves.",
            DisabledTooltip = "I am disabled!",
        
            Default = false,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(Value)
                --print("Akora Hub | MyToggle changed to:", Value)
            end,
        })
        Smart_UpgradeWave:AddToggle("Autoplay_UpgradeFocusFarm", {
            Text = "Prioritize Farm(s)",
            Tooltip = "Will automatically upgrade farm(s) before other units.",
            DisabledTooltip = "I am disabled!",
        
            Default = false,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(Value)
                --print("Akora Hub | MyToggle changed to:", Value)
            end,
        })
        for i = 1, 6 do
            Smart_UpgradeWave:AddSlider("SmartPlay_UpgradeWave_Unit" .. i, {
                Text = "Unit " .. i,
                Default = 1,
                Min = 0,
                Max = 40,
                Rounding = 1,
                Compact = false,
            
                Callback = function(Value)
                    --print("Akora Hub | MySlider was changed! New value:", Value)
                end,
            
                --Tooltip = "",
                DisabledTooltip = "I am disabled!",
            
                Disabled = false,
                Visible = true,
            })
        end
    --#endregion
    
    --#region Smart (Upgrade Cap) Settings Section
        local Smart_UpgradeCap = SmartUpgrade_TabBox:AddTab("Upgrade Cap")
        for i = 1, 6 do
            Smart_UpgradeCap:AddSlider("SmartUpgrade_UpgradeCap_Unit" .. i, {
                Text = "Unit " .. i,
                Default = 1,
                Min = 0,
                Max = 10,
                Rounding = 1,
                Compact = false,
            
                Callback = function(Value)
                    --print("Akora Hub | MySlider was changed! New value:", Value)
                end,
            
                --Tooltip = "",
                DisabledTooltip = "I am disabled!",
            
                Disabled = false,
                Visible = true,
            })
        end
    --#endregion    
--#endregion

--#region Macro Section
    --#region Macro - Grab Needed Info
        local macroDirectory = Directory .. "/macro"
        function loadMacroOptions(directory)
            local macroOptions = {}
            if type(isfolder) == "function" and not isfolder(directory) then
                makefolder(directory)
            end
            if type(listfiles) == "function" then
                local files = listfiles(directory)
                for _, filePath in ipairs(files) do
                    local fileName = filePath:match("([^/\\]+)$") or filePath
                    fileName = fileName:gsub("%.AkoraMacro$", "")
                    macroOptions[#macroOptions + 1] = fileName
                end
            else
                --print("listfiles is not available on your exploit.")
            end
            return macroOptions
        end
    --#endregion
    --#region Macro - Play/Load
        local MacroPlay_GroupBox = Tabs.Macro:AddRightGroupbox("Play Macro")
        MacroPlay_GroupBox:AddDropdown("Macro_Selected", {
            Values = loadMacroOptions(macroDirectory),
            Default = 0,
            Multi = false,
        
            Text = "Select Macro",
            DisabledTooltip = "I am disabled!",
        
            Searchable = true,
        
            Callback = function(Value)
                --print("Akora Hub | Dropdown got changed. New value:", Value)
            end,
        
            Disabled = false,
            Visible = true,
        })
       
        MacroPlay_GroupBox:AddToggle("Macro_Play", {
            Text = "Play Macro",
            Tooltip = "Will play through your recorded macro.",
            DisabledTooltip = "I am disabled!",
        
            Default = false,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(Value)
                --print("Akora Hub | MyToggle changed to:", Value)
            end,
        })
        MacroPlay_GroupBox:AddDivider()
        MacroPlay_GroupBox:AddLabel("Play Macro Settings")
        MacroPlay_GroupBox:AddToggle("Macro_IgnoreTiming", {
            Text = "Ignore Timing",
            Tooltip = "If enabled, will ignore the timing settings of the macro.",
            DisabledTooltip = "I am disabled!",
        
            Default = true,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(Value)
                --print("Akora Hub | MyToggle changed to:", Value)
            end,
        })
        MacroPlay_GroupBox:AddToggle("Macro_PlayDebugging", {
            Text = "Ignore Timing",
            Tooltip = "If enabled, will ignore the timing settings of the macro.",
            DisabledTooltip = "I am disabled!",
        
            Default = true,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(Value)
                --print("Akora Hub | MyToggle changed to:", Value)
            end,
        })
    --#endregion
    --#region Macro - Create
        local MacroConfig_GroupBox = Tabs.Macro:AddLeftGroupbox("Macro Config")
        MacroConfig_GroupBox:AddLabel("Create Macro")
        MacroConfig_GroupBox:AddInput("MacroName", {
            Default = "",
            Numeric = false,
            Finished = false,
            ClearTextOnFocus = true,
        
            Text = "Macro Name",
        
            Placeholder = "Put a name here",
        
            Callback = function(Value)
                --print("Akora Hub | Text updated. New text:", Value)
            end,
        })
        MacroConfig_GroupBox:AddButton("Create Macro", function()
            if type(writefile) == "function" then
                if Options.MacroName.Value ~= "" then
                    local filename = Directory .. "/macro/" .. Options.MacroName.Value .. ".AkoraMacro"
                    if type(isfile) == "function" and isfile(filename) then
                        Library:Notify({
                            Title = "Warning",
                            Description = "File already exists at: " .. filename,
                            Time = 5,
                            SoundId = 124951621656853
                        })
                    else
                        local success, err = pcall(function()
                            writefile(filename, "")
                        end)
                        if success then
                            Options.Macro_Selected:SetValues(loadMacroOptions(macroDirectory))
                            Options.Macro_DeleteSelected:SetValues(loadMacroOptions(macroDirectory))
                            Options.Macro_RecordOption:SetValues(loadMacroOptions(macroDirectory))
                            Library:Notify({
                                Title = "Success",
                                Description = "File created at: " .. filename,
                                Time = 5,
                                SoundId = 18403881159
                            })
                        else
                            Library:Notify({
                                Title = "Error",
                                Description = "Failed to create file at: " .. filename .. "\nError: " .. err,
                                Time = 5,
                                SoundId = 8400918001
                            })
                        end
                    end
                else
                    Library:Notify({
                        Title = "Error",
                        Description = "Please add a name for the Macro first!",
                        Time = 5,
                        SoundId = 8400918001
                    })
                end
            else
                --print("writefile is not available on your exploit.")
            end
        end)
        MacroConfig_GroupBox:AddDivider()
    --#endregion
    --#region Macro - Record Macro
        MacroConfig_GroupBox:AddLabel("Record Macro")
        MacroConfig_GroupBox:AddDropdown("Macro_RecordOption", {
            Values = loadMacroOptions(macroDirectory),
            Default = 0,
            Multi = false,
        
            Text = "Select Macro File",
            DisabledTooltip = "I am disabled!",
        
            Searchable = true,
        
            Callback = function(Value)
                --print("Akora Hub | Dropdown got changed. New value:", Value)
            end,
        
            Disabled = false,
            Visible = true,
        })
        MacroConfig_GroupBox:AddDropdown("Macro_RecordSettings", {
            Values = { "Timing", "Wave" },
            Default = { "Timing" },
            Multi = true,
        
            Text = "Recording Settings",
            DisabledTooltip = "I am disabled!",
        
            Searchable = true,
        
            Callback = function(Value)
                --print("Akora Hub | Dropdown got changed. New value:", Value)
            end,
        
            Disabled = false,
            Visible = true,
        })
        MacroConfig_GroupBox:AddToggle("Macro_Record", {
            Text = "Record Macro",
            Tooltip = "Will record a replayable macro.",
            DisabledTooltip = "I am disabled!",
        
            Default = false,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(Value)
                --print("Akora Hub | MyToggle changed to:", Value)
            end,
        })
        MacroConfig_GroupBox:AddDivider()
    --#endregion
    --#region Macro - Delete
        MacroConfig_GroupBox:AddLabel("Delete Macro")
        MacroConfig_GroupBox:AddDropdown("Macro_DeleteSelected", {
            Values = loadMacroOptions(macroDirectory),
            Default = 0,
            Multi = false,
        
            Text = "Select Macro to Delete",
            DisabledTooltip = "I am disabled!",
        
            Searchable = true,
        
            Callback = function(Value)
                --print("Akora Hub | Dropdown got changed. New value:", Value)
            end,
        
            Disabled = false,
            Visible = true,
        })
        MacroConfig_GroupBox:AddButton("Delete Macro", function()
            if type(delfile) == "function" then
                if Options.Macro_DeleteSelected.Value ~= nil then
                    print(Options.Macro_DeleteSelected.Value)
                    local filePath = macroDirectory .. "/" .. Options.Macro_DeleteSelected.Value .. ".AkoraMacro"
                    if type(isfile) == "function" and isfile(filePath) then
                        local success, err = pcall(function()
                            delfile(filePath)
                        end)
                        if success then
                            Options.Macro_Selected:SetValues(loadMacroOptions(macroDirectory))
                            Options.Macro_DeleteSelected:SetValues(loadMacroOptions(macroDirectory))
                            Options.Macro_RecordOption:SetValues(loadMacroOptions(macroDirectory))
                            Library:Notify({
                                Title = "Success",
                                Description = Options.Macro_DeleteSelected.Value .. " macro deleted",
                                Time = 5,
                                SoundId = 7167887983
                            })
                        else
                            Library:Notify({
                                Title = "Error",
                                Description = "Failed to delete " .. Options.Macro_DeleteSelected.Value .. " macro.\nError: " .. err,
                                Time = 5,
                                SoundId = 8400918001
                            })
                        end
                    else
                        Library:Notify({
                            Title = "Error",
                            Description = "Macro " .. Options.Macro_DeleteSelected.Value .. " does not exist.",
                            Time = 5,
                            SoundId = 8400918001
                        })
                    end
                else
                    Library:Notify({
                        Title = "Error",
                        Description = "Please select a Macro!",
                        Time = 5,
                        SoundId = 8400918001
                    })
                end
            else
                print("delfile is not available on your exploit.")
            end
        end)
    --#endregion
    --#region Macro - Info
        local MacroInfo_GroupBox = Tabs.Macro:AddRightGroupbox("Macro Information")
        local MacroPlaying = MacroInfo_GroupBox:AddLabel("Playing Macro: None")
        local MacroStep = MacroInfo_GroupBox:AddLabel("Macro Step: None")        
    --#endregion
--#endregion

--#region Webhook Section
    local Webhook_Left = Tabs.Webhook:AddLeftGroupbox("Webhook Settings")
    Webhook_Left:AddInput("Webhook_Link", {
        Default = "",
        Placeholder = "Enter webhook URL",
        Text = "Webhook URL:",
        Callback = function(Value)
            --print("Webhook URL set to:", Value)
        end
    })
    Webhook_Left:AddInput("Discord_ID", {
        Default = "",
        Placeholder = "Enter Discord User ID",
        Numeric = true,
        Text = "Discord ID (@ mention):",
        Callback = function(Value)
            --print("Discord ID set to:", Value)
        end
    })
    Webhook_Left:AddButton("Test Webhook", function()
        if Options.Webhook_Link.Value ~= "" then        
            local userId = tostring(Locals.Client.UserId)
            local userUrl = "https://www.roblox.com/users/" .. userId

            local thumbnailUrl
            local apiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=420x420&format=Png&isCircular=false"
            local success, result = pcall(function() 
                return Locals.HttpRequest({ Url = apiUrl, Method = "GET" }) 
            end)
            if success and result and result.Body then
                local data = Locals.HttpService:JSONDecode(result.Body)
                if data and data.data and #data.data > 0 and data.data[1].imageUrl then
                    thumbnailUrl = data.data[1].imageUrl
                else
                    print("New thumbnail API response did not include an imageUrl, using default.")
                end
            else
                print("Failed to fetch new thumbnail, using default.")
            end

            local bannerUrl = ""

            local embed = {
                title = "Akora Hub 🐾 " .. GameName,
                description = "Greetings ||**[" .. Locals.Client.DisplayName .. " (@" .. Locals.Client.Name .. ")](" .. userUrl .. ")**||!\n",
                color = 0xFF4500,
                fields = {
                    {
                        name = "Roblox User ID",
                        value = userId,
                        inline = true
                    },
                    {
                        name = "Display Name",
                        value = (Locals.Client.DisplayName or "N/A"),
                        inline = true
                    },
                    {
                        name = "Script Version",
                        value = "v1.0.0",
                        inline = true
                    },
                    {
                        name = "Status",
                        value = "All systems **operational**.",
                        inline = true
                    }
                },
                footer = {
                    text = "Powered by Akora Hub - Stay Pawsome!",
                    icon_url = "https://raw.githubusercontent.com/VeronicVR/Roblox/refs/heads/main/Scripts/Logo/Akora%20Hub%20Logo.png"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                thumbnail = {
                    url = thumbnailUrl
                },
                --image = {
                --    url = bannerUrl
                --}
            }

            local payload = {
                content = "This is just a test embed!",
                embeds = { embed }
            }

            local jsonPayload = Locals.HttpService:JSONEncode(payload)
            local headers = { ["Content-Type"] = "application/json" }
            local requestData = {
                Url = Options.Webhook_Link,
                Method = "POST",
                Headers = headers,
                Body = jsonPayload
            }

            local response = Locals.HttpRequest(requestData)
            print("Webhook test response:", response)
        else
            print("Webhook URL is not set!")
        end
    end)

    local Webhook_Right = Tabs.Webhook:AddRightGroupbox("Webhook Pings")
    Webhook_Right:AddToggle("Ping_On_Mission_End", {
        Text = "Ping on Mission End",
        Tooltip = "Placeholder: Will ping when the mission ends.",
        Default = false,
        Callback = function(Value)
            --print("Ping on Mission End set to:", Value)
        end
    })

    Webhook_Right:AddToggle("Rare_Obtainment_Mention", {
        Text = "Rare Obtainment Mention",
        Tooltip = "Will ping when a unit is dropped or obtained.",
        Default = false,
        Callback = function(Value)
            --print("Rare Obtainment Mention set to:", Value)
        end
    })
--#endregion

--#region Logic
    --#region Launch Logic
        Toggles.AutoLaunch:OnChanged(function()
        	if Toggles.AutoLaunch.Value then
                wait(Options.Launch_JoinDelay.Value)
                if Options.Launch_Mode.Value == "Story" or Options.Launch_Mode.Value == "Legend" then
                    Locals.JoinQueue("QueueZones")

                    if Options.Launch_Mode.Value ~= "Legend" then
                        Locals.SelectLaunch(tonumber(Options.Launch_Act.Value), Options.Launch_Map.Value, "Story", Locals.Client, Toggles.Friends_Only.Value, Options.Launch_Difficulty.Value)
                    else
                        Locals.SelectLaunch(tonumber(Options.Launch_Act.Value), Options.Launch_Map.Value, "Legend", Locals.Client, Toggles.Friends_Only.Value, "Legend")
                    end

                elseif Options.Launch_Mode.Value == "Raids" then
                    Locals.JoinQueue("QueueRaidZones")

                    Locals.SelectLaunch(tonumber(Options.Launch_Act.Value), Options.Launch_Map.Value, "Raid", Locals.Client, Toggles.Friends_Only.Value, "Raid")

                elseif Options.Launch_Mode.Value == "Dungeons" then
                    Locals.JoinQueue("QueueDungeonZones")

                    Locals.SelectLaunch(1, Options.Launch_Map.Value, "Dungeon", Locals.Client, Toggles.Friends_Only.Value, "Dungeon")

                elseif Options.Launch_Mode.Value == "Adventure" then
                    Locals.JoinQueue("QueueYearZones")
                else
                    Toggles.AutoLaunch:SetValue(false)
                    Library:Notify({
                        Title = "Error",
                        Description = "Please select valid options!",
                        Time = 5,
                        SoundId = 8400918001
                    })
                end
            end
        end)
    --#endregion

    --#region Macro Logic
        --#region Record Logic
            Toggles.Macro_Record:OnChanged(function()
                if Toggles.Macro_Record.Value then
                    if Options.Macro_RecordOption.Value ~= nil then
                    
                    else
                        Toggles.Macro_Record:SetValue(false)
                        Library:Notify({
                            Title = "Error",
                            Description = "Please select a Macro file first!",
                            Time = 5,
                            SoundId = 8400918001
                        })
                    end
                else
                
                end
            end)
        --#endregion 
        --#region Play Logic
            Toggles.Macro_Play:OnChanged(function()
                if Toggles.Macro_Play.Value then 
                    if Options.Macro_Selected.Value ~= nil then
                        MacroPlaying:SetText("Playing Macro:", Options.Macro_Selected.Value)
                        --MacroStep:SetText("Macro Step: None")
                    else
                        Toggles.Macro_Play:SetValue(false)
                        Library:Notify({
                            Title = "Error",
                            Description = "Please select a Macro to play first!",
                            Time = 5,
                            SoundId = 8400918001
                        })
                    end
                else
                
                end
            end)
        --#endregion    
    --#endregion

    --#region Autoplay Logic

        Toggles.Autoplay_Enable:OnChanged(function()
            if Toggles.Autoplay_Enable.Value then
                while Toggles.Autoplay_Enable.Value do
                    --if PlayerLoaded then
                        
                    --end
                        --[[Toggles.Macro_Record:SetValue(false)
                        Library:Notify({
                            Title = "Error",
                            Description = "Please select a Macro file first!",
                            Time = 5,
                            SoundId = 8400918001
                        })--]]
                end
            else
            
            end
        end)
    --#endregion
--#endregion

--#region Autoload Config
    SaveManager:LoadAutoloadConfig()
--#endregion



--[[

local args = {
    nil
}
game:GetService("Players").LocalPlayer.PlayerGui.LocalGUIServices.ClientUnitHandler.ForceSelectFunction:Invoke(unpack(args))


game:GetService("ReplicatedStorage").Events.SkipWave:FireServer(true)

local args = {
    "GameFinish",
    "Restart"
}
game:GetService("ReplicatedStorage").Events.VoteEvent:FireServer(unpack(args))




local args = {
    [1] = "Place",
    [2] = {
        ["rot"] = 0,
        ["slot"] = "Slot1",
        ["position"] = CFrame.new(300.6984558105469, 22.980314254760742, 35.310604095458984, -0.6100442409515381, -0.6897538304328918, 0.38998186588287354, -1.4901161193847656e-08, 0.49217307567596436, 0.8704974055290222, -0.7923674583435059, 0.5310419201850891, -0.30024734139442444)
    }
}

game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Unit"):FireServer(unpack(args))
--]]