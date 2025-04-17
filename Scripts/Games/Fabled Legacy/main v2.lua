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


local Repository = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library = loadstring(game:HttpGet(Repository .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repository .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repository .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Fabled Legacy 🐾 Akora Hub",
    Footer = "v1.0.0",
    Size = UDim2.fromOffset(820, 500),
    ShowCustomCursor = false,
    Font = Enum.Font.FredokaOne,
    ToggleKeybind = Enum.KeyCode.RightControl,
    Center = true,
    AutoShow = true
})

DestroyUI = function()
    Window:Destroy()
end

local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Combat = Window:AddTab("Combat", "sword"),
    Inventory = Window:AddTab("Inventory", "backpack"),
    Webhook = Window:AddTab("Webhook", "webhook"),
    Settings = Window:AddTab("Settings", "settings")
}

local UIElements = {
    Sections = {
        GroupBox = {
            Left = {

            },
            Right = {

            },
        },
        Tabbox = {
            Left = {
                AF,
                AFMain,
                AFSettings,
            },
            Right = {

            },
        },
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

-- Default Settings
local Default_Settings = {
    ["Main"] = {
        ["Autofarm"] = {
            ["Enabled"] = false,
            ["Auto Retry"] = false,
            ["Auto Leave"] = false,
            ["TeleportHeight_Sli"] = 0,
            ["TeleportDistance_Sli"] = 0,
        },
        ["Combat"] = {
            ["AOESpell_Tog"] = false,
            ["AOESwing_Tog"] = false,
            ["SpellDistance_Sli"] = 50,
            ["SigilDistance_Sli"] = 35,
            ["SwingDistance_Sli"] = 22,
        },
    },
    ["Inventory"] = {
        ["AutoSell_Tog"] = false,
        ["AutoSell_Rarity"] = {"Common", "Uncommon"},
        ["AutoSell_Types"] = {"helmets", "armors", "legs", "weapons", "rings", "sigils", "spells"},
        ["AutoSell_MaxLevel"] = 1,
    },
    ["Webhook"] = {
        ["WebhookURL"] = "https://discord.com/api/webhooks/123456789012345678/abcdefghijklmnopqrstuvwxyz",
        ["WebhookEnabled"] = false,
    },

}

local HttpS = game:GetService("HttpService")
local FileName = "Akora Hub/Games/" .. GameName .. "/" .. Vars.Client.DisplayName .. " [ @" .. Vars.Client.Name .. " - " .. Vars.Client.UserId .. " ]"

local function LoadSettings()
    writefile(FileName, HttpS:JSONEncode(Default_Settings))
    if not pcall(function() readfile(FileName) end) then
        writefile(FileName, HttpS:JSONEncode(Default_Settings))
        return Default_Settings
    end

    local success, data = pcall(function() return HttpS:JSONDecode(readfile(FileName)) end)
    if not success or type(data) ~= "table" then
        writefile(FileName, HttpS:JSONEncode(Default_Settings))
        return Default_Settings
    end

    return data
end

local Settings = LoadSettings()

function Save_Settings()
    writefile(FileName, HttpS:JSONEncode(Settings))
end


UIElements.Sections.Tabbox.Left.AF = Tabs.Main:AddLeftTabbox("AF")
UIElements.Sections.Tabbox.Left.AFMain = UIElements.Sections.Tabbox.Left.AF:AddTab("Autofarm")
UIElements.Sections.Tabbox.Left.AFSettings = UIElements.Sections.Tabbox.Left.AF:AddTab("AF Settings")

UIElements.Toggles.Autofarm = UIElements.Sections.Tabbox.Left.AFMain:AddCheckbox("Autofarm", {
    Text = "Example Checkbox",
    Default = Settings["Main"]["Autofarm"]["Enabled"],
    Callback = function(Value)
        Settings["Main"]["Autofarm"]["Enabled"] = Value
        Save_Settings()

        print("Checkbox changed to:", Value)
    end
})

UIElements.Toggles.AutoRetry = UIElements.Sections.Tabbox.Left.AFMain:AddCheckbox("AutoRetry", {
    Text = "Auto Retry",
    Default = Settings["Main"]["Autofarm"]["Auto Retry"],
    Callback = function(Value)
        Settings["Main"]["Autofarm"]["Auto Retry"] = Value
        Save_Settings()

        print("Checkbox changed to:", Value)
    end
})

UIElements.Toggles.AutoLeave = UIElements.Sections.Tabbox.Left.AFMain:AddCheckbox("AutoLeave", {
    Text = "Auto Leave",
    Default = Settings["Main"]["Autofarm"]["Auto Leave"],
    Callback = function(Value)
        Settings["Main"]["Autofarm"]["Auto Leave"] = Value
        Save_Settings()

        print("Checkbox changed to:", Value)
    end
})



UIElements.Buttons.Destroy_UI = Tabs.Settings:AddButton({
    Text = "Destroy UI",
    Func = function()
        DestroyUI()
    end,
    DoubleClick = true -- Requires double-click for risky actions
})


Library:Toggle(true)