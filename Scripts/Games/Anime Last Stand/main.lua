local wait, spawn = task.wait, task.spawn
repeat wait() until game:IsLoaded()
             
getgenv().debugvisible = false
getgenv().SmartAutoplay = {
    Autoplace = false,
    FinishedPlacing = false,
    EquippedUnits = {},
    SelectedPathFolder = game.workspace,
}

getgenv().MatchStartTime = os.time()
local SummonDropsLog = {}
getgenv().AutoUpgrade_Enabled = false

local GameName = "Anime Last Stand"
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
    GuiService = game:GetService("GuiService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),

    -- Player & Character
    Client = ClonedPlayers.LocalPlayer,
    PlayerGui = ClonedPlayers.LocalPlayer.PlayerGui,
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
    IsAllowedPlace = function(...)
        local pid = game.PlaceId
        for _, id in ipairs({ ... }) do
            if pid == id then
                return true
            end
        end
        return false
    end,
    formatCommas = function(n)
        local s = tostring(n)
        local sign, int, frac = s:match("([-]?)(%d+)(%.?%d*)")
        int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse()
        int = int:gsub("^,", "")
        return sign..int..frac
    end,
    isPlacedAt = function(pos, name)
        local tol = 2
        for _, inst in ipairs(game.Workspace.Towers:GetChildren()) do
            if inst.Name == name and inst.PrimaryPart then
                if (inst.PrimaryPart.Position - pos).Magnitude < tol then
                    return true
                end
            end
        end
        return false
    end,
    safeGet = function(childName)
        local success,obj = pcall(function() return workspace[childName] end)
        return success and obj
    end,
    ActivatePromptButton = function(uiElement, buttonIndex)
        buttonIndex = buttonIndex or 1
        if uiElement:IsA("TextButton") then
            uiElement.Selectable = true
            game:GetService("GuiService").SelectedObject = uiElement
            game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            wait(0.5)
            game:GetService("GuiService").SelectedObject = nil
            return
        end
    
        local textButtons = {}
        for _, child in ipairs(uiElement:GetChildren()) do
            if child:IsA("TextButton") then
                table.insert(textButtons, child)
            end
        end
        if #textButtons >= buttonIndex then
            local selectedButton = textButtons[buttonIndex]
            selectedButton.Selectable = true
            game:GetService("GuiService").SelectedObject = selectedButton
            game:GetService("VirtualInputManager")r:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            wait(0.5)
            game:GetService("GuiService").SelectedObject = nil
        else
            warn("No TextButton found at index " .. buttonIndex .. " in the given directory!")
        end
    end,
    -- Game Specific
}
local Directory = "Akora Hub/Games/" .. GameName .. "/" .. Locals.Client.DisplayName .. " [ @" .. Locals.Client.Name .. " - " .. Locals.Client.UserId .. " ]"
local cubeContainer
globalPlacements = {}

if not Locals.IsAllowedPlace(12886143095, 18583778121) then
    getgenv().SmartAutoplay.SelectedPathFolder = game.workspace.Map:WaitForChild("Waypoints")

    local pg = game.Players.LocalPlayer.PlayerGui
    repeat task.wait() until pg:FindFirstChild("Bottom")
                      and pg.Bottom:FindFirstChild("Frame")
                      and pg.Bottom.Frame.Visible
end

local Cash_Loc, Player_Cash 
local PlayerData = game:GetService("ReplicatedStorage").Remotes.GetPlayerData:InvokeServer()
local TowerInfo = require(game:GetService("ReplicatedStorage").Modules.TowerInfo)
local UnitNames = require(game:GetService("ReplicatedStorage").Modules.UnitNames)

local challengeOptions = {"Barebones", "Tower Limit", "Flight", "No Hit", "Speedy", "High Cost", "Short Range", "Immunity"}
local challengeRatings = {
    ["Barebones"]     = 3,
    ["Tower Limit"]   = 8,
    ["Flight"]        = 7.5,
    ["No Hit"]        = 8,
    ["Speedy"]        = 5,
    ["High Cost"]     = 1,
    ["Short Range"]   = 3,
    ["Immunity"]      = 3,
}
--#region Autoplay Logic
    if not Locals.IsAllowedPlace(12886143095, 18583778121) then
        getgenv().MapName, getgenv().MapMode, getgenv().MapDifficulty, getgenv().MapWave = workspace.Map.MapName.Value, game.ReplicatedStorage.Gamemode.Value, workspace.Map.MapDifficulty.Value, game.ReplicatedStorage.Wave.Value
        --#region Vareiables & Functions



            function resetAutoplayState()
                print("🔄 Resetting Autoplay State...")
                wait(0.2)
            
                print("✅ Autoplay State reset complete. Ready to restart.")
            end
        
            -- Visual Placement Settings
            local radius = 15
            local spacing = 2.5
            local cubeSize = Vector3.new(0.25, 0.25, 0.25)
            local nodeIndex = 2
            local heightOffset = -0.15
            local PlacementheightOffset = 1.35
            local clearance = 0.2

            -- Safe Map and Waypoint handling
            local Map = game.Workspace:FindFirstChild("Map")
            local Waypoints = {}
            local Start, End = nil, nil
        
            if Map then
                local WaypointContainer = Map:FindFirstChild("Waypoints")
                if WaypointContainer then
                    Waypoints = WaypointContainer:GetChildren()
                end
        
                Start = Map:FindFirstChild("Start")
                End = Map:FindFirstChild("Finish")
            end
            
            -- Global variables
            getgenv().circlePosition = nil
            local cubes = {}
            globalPlacements = {}
        
            -- Returns the world‐space position of the Nth node (Start → selected waypoints → Finish)
            function getNodePosition(index, heightOffset)
                heightOffset = heightOffset or 0
                local mapFolder = workspace:FindFirstChild("Map")
                if not mapFolder then
                    warn("Map folder not found!")
                    return nil
                end
            
                -- figure out which Waypoints folder we’re using
                local wpFold = getgenv().SmartAutoplay.SelectedPathFolder
                               or mapFolder:FindFirstChild("Waypoints")
                if not wpFold then
                    warn("Waypoints folder not found!")
                    return nil
                end
            
                local nodes = {}
            
                -- only include the Start block if we’re on the MAIN path
                if wpFold.Name == "Waypoints" then
                    local startBlock = mapFolder:FindFirstChild("Start")
                    if startBlock then
                        table.insert(nodes, startBlock)
                    else
                        warn("Start block not found!")
                    end
                end
            
                -- add all waypoints from the chosen folder, sorted numerically
                local wpNodes = wpFold:GetChildren()
                table.sort(wpNodes, function(a, b)
                    return (tonumber(a.Name:match("(%d+)")) or 0) < (tonumber(b.Name:match("(%d+)")) or 0)
                end)
                for _, node in ipairs(wpNodes) do
                    table.insert(nodes, node)
                end
            
                -- always include the Finish block last
                local finishBlock = mapFolder:FindFirstChild("Finish")
                if finishBlock then
                    table.insert(nodes, finishBlock)
                else
                    warn("Finish block not found!")
                end
            
                -- pick the requested node
                if index < 1 or index > #nodes then
                    warn("Invalid node index:", index)
                    return nil
                end
            
                return nodes[index].Position + Vector3.new(0, heightOffset, 0)
            end

            if workspace:FindFirstChild("Placements_Container") then
                workspace.Placements_Container:Destroy()
            end
            
            local PlacementContainer = Instance.new("Folder")
            local cylinder = Instance.new("Part")
            local cubeContainer = Instance.new("Folder")

            function generateCubes()
                if not cylinder or not cubeContainer then
                    warn("generateCubes: missing cylinder or cubeContainer")
                    return
                end
            
                -- Use the actual cylinder position as the base
                local basePos = cylinder.Position
                getgenv().circlePosition = basePos
            
                cubes = {}  -- reset
            
                for x = -radius, radius, spacing do
                    for z = -radius, radius, spacing do
                        local distance = math.sqrt(x*x + z*z)
                        if distance <= radius then
                            local cubeOffset   = Vector3.new(x, cubeSize.Y/2, z)
                            local cubePosition = basePos + cubeOffset + Vector3.new(0, heightOffset, 0)
            
                            local cube = Instance.new("Part")
                            cube.Size        = cubeSize
                            cube.Position    = cubePosition
                            cube.Anchored    = false
                            cube.CanCollide  = false
                            cube.Color       = Color3.fromRGB(255, 255, 255)
                            cube.Transparency= getgenv().debugvisible and 0.25 or 1
                            cube.Material    = Enum.Material.Neon
                            cube.Parent      = cubeContainer
            
                            table.insert(cubes, { cube = cube, distance = distance, offset = cubeOffset })
            
                            -- weld directly to our cylinder instance
                            local weld = Instance.new("WeldConstraint")
                            weld.Part0 = cylinder
                            weld.Part1 = cube
                            weld.Parent = cube
                        end
                    end
                end
            
                -- sort by distance so naming/order is consistent
                table.sort(cubes, function(a, b)
                    return a.distance < b.distance
                end)
                for i, data in ipairs(cubes) do
                    data.cube.Name = "Placement_" .. i
                end
            
                -- rebuild globalPlacements
                globalPlacements = {}
                for _, part in ipairs(cubeContainer:GetChildren()) do
                    local num = tonumber(part.Name:match("^Placement_(%d+)"))
                    if num then
                        table.insert(globalPlacements, part)
                    end
                end
            end

            -- blacklisted instances for raycasting
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Blacklist
            rp.FilterDescendantsInstances = {
                game.Players.LocalPlayer.Character,
                workspace:FindFirstChild("Towers"),
                workspace:FindFirstChild("Placements_Container"),
                workspace:FindFirstChild("Enemies"),
            }
        
            -- find nearest surface Y under or above `pos`
            local function findSurfaceY(pos, maxDist)
                maxDist = maxDist or (radius*2)
                local down = workspace:Raycast(
                    pos + Vector3.new(0, maxDist/2, 0),
                    Vector3.new(0, -maxDist, 0),
                    rp
                )
                if down then return down.Position.Y end
            
                local up = workspace:Raycast(
                    pos - Vector3.new(0, maxDist/2, 0),
                    Vector3.new(0, maxDist, 0),
                    rp
                )
                if up then return up.Position.Y end
            
                return pos.Y
            end
            
            -- Call this once to create the cylinder + cubes at node #1 (or any nodeIndex)
            function InitializePlacementVisualizer(nodeIndex)
                -- compute the base world position of that node
                local basePos = getNodePosition(nodeIndex)
                if not basePos then return end
            
                -- clean out any previous visualizer
                if workspace:FindFirstChild("Placements_Container") then
                    if workspace.Placements_Container:FindFirstChild("PlacementVisualizer") then
                        workspace.Placements_Container.PlacementVisualizer:Destroy()
                    end
                end
            
                local PlacementContainer
                -- make the new container
                if not workspace:FindFirstChild("Placements_Container") then
                    PlacementContainer = Instance.new("Folder")
                    PlacementContainer.Name   = "Placements_Container"
                    PlacementContainer.Parent = workspace
                else
                    PlacementContainer = workspace.Placements_Container
                end
            
                ManualPlacementContainer = Instance.new("Folder")
                ManualPlacementContainer.Name   = "ManualPlacements_Container"
                ManualPlacementContainer.Parent = PlacementContainer

                -- make the cylinder
                cylinder = Instance.new("Part")
                cylinder.Name        = "PlacementVisualizer"
                cylinder.Size        = Vector3.new(0.1, radius*2, radius*2)
                cylinder.Material    = Enum.Material.SmoothPlastic
                cylinder.Anchored    = true
                cylinder.CanCollide  = false
                cylinder.Shape       = Enum.PartType.Cylinder
                cylinder.Orientation = Vector3.new(0, 0, 90)
                cylinder.Color       = Color3.fromRGB(70, 0, 0)
                cylinder.Transparency= getgenv().debugvisible and 0.8 or 1
                cylinder.Parent      = PlacementContainer
            
                -- position the cylinder flush to that surface
                local surfaceY  = findSurfaceY(basePos)
                local halfHeight= (radius*2) / 2
                cylinder.Position = Vector3.new(basePos.X, surfaceY + halfHeight, basePos.Z)
            
                -- create the cube container and generate the cubes
                cubeContainer = Instance.new("Folder")
                cubeContainer.Name   = "Placements"
                cubeContainer.Parent = cylinder
            
                generateCubes()
            end

            -- example usage at startup or after dropdown change:
            InitializePlacementVisualizer(1)

            -- Moves the cylinder to a new node position and regenerates cubes.
            function moveCylinderTo(newNodeIndex)
                local newPosition = getNodePosition(newNodeIndex)
                if newPosition then
                    cylinder.Position = newPosition
                    getgenv().circlePosition = newPosition
                
                    -- Remove only cubes (named "Placement_#") from the container.
                    for _, child in ipairs(PlacementContainer:GetChildren()) do
                        if child.Name:match("^Placement_") then
                            child:Destroy()
                        end
                    end
                
                    cubes = {}
                    generateCubes()
                else
                    warn("Node " .. newNodeIndex .. " position not found!")
                end
            end

            moveCylinderTo(1)
            -- Generate the initial set of cubes.
            generateCubes()

            function updatePlacementVisualizer(percent, heightOffset)
                heightOffset = heightOffset or 0
                local mapFolder = workspace:FindFirstChild("Map")
                if not mapFolder then return end
            
                -- build node list exactly as getNodePosition does
                local wpFold = getgenv().SmartAutoplay.SelectedPathFolder
                               or mapFolder:FindFirstChild("Waypoints")
                local nodes = {}
                if wpFold.Name == "Waypoints" then
                    local s = mapFolder:FindFirstChild("Start")
                    if s then table.insert(nodes, s) end
                end
                local list = wpFold:GetChildren()
                table.sort(list, function(a, b)
                    return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
                end)
                for _, n in ipairs(list) do table.insert(nodes, n) end
                local f = mapFolder:FindFirstChild("Finish")
                if f then table.insert(nodes, f) end
                if #nodes < 2 then return end
            
                -- compute the new position along the track
                local pos = {}
                for i,n in ipairs(nodes) do pos[i] = n.Position end
                local total = 0
                for i=2,#pos do total += (pos[i]-pos[i-1]).Magnitude end
                local target = (percent/100)*total
            
                local cum = 0
                local newPos = pos[1]
                for i=1,#pos-1 do
                    local seg = (pos[i+1]-pos[i]).Magnitude
                    if cum+seg >= target then
                        local t = (target-cum)/seg
                        newPos = pos[i]:Lerp(pos[i+1], t)
                        break
                    else
                        cum += seg
                    end
                end
                newPos += Vector3.new(0, heightOffset, 0)
            
                -- move cylinder
                local vis = workspace.Placements_Container
                            and workspace.Placements_Container:FindFirstChild("PlacementVisualizer")
                if vis then
                    local ts = game:GetService("TweenService")
                    local tw = ts:Create(vis, TweenInfo.new(0.2), {Position=newPos})
                    tw:Play()
                    tw.Completed:Wait()
                    getgenv().circlePosition = newPos
                end
            
                -- clear old cubes
                local cubeContainer = vis and vis:FindFirstChild("Placements")
                if cubeContainer then
                    for _, c in ipairs(cubeContainer:GetChildren()) do
                        if c.Name:match("^Placement_%d+") then c:Destroy() end
                    end
                end
            
                -- regenerate
                generateCubes()
            end
        
            local EquippedUnits = getgenv().SmartAutoplay.EquippedUnits
            local PlayerSoulData = {}
            local ShinyUnitNames = require(game:GetService("ReplicatedStorage").Modules.UnitNames.ShinyInfo)
            repeat wait() until PlayerData ~= nil
            local function GetUnitName(name)
                if UnitNames[name] then
                    return UnitNames[name]
                end
                for key, value in pairs(UnitNames) do
                    if value == name then
                        return key
                    end
                end
                return nil
            end
            -- Store PlayerSoulData
            for index, value in PlayerData do
                if index == "SoulData" then
                    for Soul, Info in value do
                        --warn(Soul)
                        PlayerSoulData[Soul] = {
                            ["EquippedOnUnit"] = Info.EquippedUnit or "None",
                            ["Upgrade"] = Info.Upgrades or 0, -- Default upgrade to 0 if missing
                        }
                    end
                end
            end 

            for index, value in pairs(PlayerData.Slots) do
                if value.UnitID ~= '' then
                    -- Extract the slot number using a pattern
                    local newIndex = tonumber(index:match("%d+"))
                
                    -- Retrieve enchant & soul value safely
                    local enchantValue = PlayerData.UnitData[value.UnitID].Enchant or "None"
                    local soulValue = PlayerData.UnitData[value.UnitID].EquippedSoul or "None"
                
                    -- Get soul upgrade level from PlayerSoulData
                    local soulUpgradeLevel = 0
                    if PlayerSoulData[soulValue] then
                        soulUpgradeLevel = PlayerSoulData[soulValue].Upgrade or 0
                    end
                
                    -- Max Place check
                    local MaxPlace = Locals.ReplicatedStorage.Units[value.Value].PlacementLimit.Value or 1
                    --print(Locals.ReplicatedStorage.Units[value.Value].PlacementLimit.Value)
                    --print(value.Quirk)
                    local UnitQuirk = value.Quirk or "None"
                    if UnitQuirk == "Overlord" or UnitQuirk == "Avatar" or UnitQuirk == "Glitched" then
                        MaxPlace = 1
                    end
                    --warn("MaxPlace: " .. MaxPlace)
                
                    -- Create table for this unit, preserving the slot information.
                    EquippedUnits[newIndex] = {
                        Slot = newIndex,  -- Store the slot number so later logic can use the proper slider.
                        ["UnitID"] = value.UnitID or "None",
                        ["UnitName"] = value.Value or "None",
                        ["TrueName"] = GetUnitName(value.Value) or "None",
                        ["Enchant"] = enchantValue,
                        ["Trait"] = value.Quirk or "None",
                        ["Soul"] = soulValue,
                        ["SoulUpgradeLevel"] = soulUpgradeLevel,
                        ["UpgradeCosts"] = {},
                        ["InitCost"] = 0,
                        ["Abilities"] = {},
                        ["MaxPlacement"] = MaxPlace,
                    }
                
                    -- Check if unit has TowerInfo
                    if TowerInfo[value.Value] ~= nil then
                        for a, b in next, TowerInfo[value.Value] do
                            if type(b) == "table" and b.Cost then
                                local cost = b.Cost
                                -- Base cost before any discount
                                local baseCost = cost
                            
                                -- Calculate total discount percentage
                                local totalDiscount = 0 -- Start with no discount
                            
                                if enchantValue == "Efficiency" then
                                    totalDiscount = totalDiscount + 0.20 -- 20% reduction
                                end
                            
                                if soulValue == "BenevolentSoul" and soulUpgradeLevel >= 10 then
                                    totalDiscount = totalDiscount + 0.04 -- 4% reduction
                                elseif soulValue == "IdolSoul" then
                                    local idolSoulDiscount = 0.99 - (soulUpgradeLevel * 0.003) -- Dynamic reduction based on upgrade level
                                    idolSoulDiscount = math.max(0.96, idolSoulDiscount) -- Ensure it doesn't go below 0.96
                                    totalDiscount = totalDiscount + (1 - idolSoulDiscount) 
                                end
                            
                                -- Apply the **total** discount all at once, and round **only once**
                                cost = math.round(baseCost * (1 - totalDiscount))
                            
                                EquippedUnits[newIndex]["UpgradeCosts"][a] = cost
                            
                                -- Look for ability info in this upgrade.
                                local abilityContainer = nil
                                if b.Ability then
                                    abilityContainer = { [1] = b.Ability }
                                elseif b.Abilities then
                                    abilityContainer = b.Abilities
                                end
                            
                                if abilityContainer then
                                    for abilityNumber, abilityInfo in pairs(abilityContainer) do
                                        local alreadyRegistered = false
                                        for _, existing in ipairs(EquippedUnits[newIndex]["Abilities"]) do
                                            if existing.AbilityNumber == abilityNumber and existing.AbilityData.Name == abilityInfo.Name then
                                                alreadyRegistered = true
                                                if a < existing.UpgradeRequired then
                                                    existing.UpgradeRequired = a
                                                end
                                                break
                                            end
                                        end
                                        if not alreadyRegistered then
                                            table.insert(EquippedUnits[newIndex]["Abilities"], {
                                                UpgradeRequired = a,
                                                AbilityNumber = abilityNumber,
                                                AbilityData = abilityInfo
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    
                        -- Sort upgrade costs in ascending order
                        table.sort(EquippedUnits[newIndex]["UpgradeCosts"], function(a, b)
                            return a < b
                        end)
                    
                        -- Grab index 0 in UpgradeCosts which is InitCost and separate it to InitCost
                        EquippedUnits[newIndex]["InitCost"] = EquippedUnits[newIndex]["UpgradeCosts"][0]
                        EquippedUnits[newIndex]["UpgradeCosts"][0] = nil
                    end
                end
            end

        
            function CurrentPlace(unitID)
                local count = 0
                --print("Debug: Locals.Client.Name is:", Locals.Client.Name)
                for _, tower in ipairs(workspace.Towers:GetChildren()) do
                    if tower:IsA("Model") then
                        local ownerObj = tower:FindFirstChild("Owner")
                        local idObj = tower:FindFirstChild("UnitID")
                        local ownerStr = ownerObj and tostring(ownerObj.Value) or "nil"
                        local unitIDStr = idObj and tostring(idObj.Value) or "nil"
                        --print("Debug: Tower:", tower.Name, "Owner:", ownerStr, "UnitID:", unitIDStr)
                        if ownerObj and idObj then
                            if tostring(ownerObj.Value) == tostring(Locals.Client.Name) and tostring(idObj.Value) == tostring(unitID) then
                                count = count + 1
                            end
                        end
                    end
                end
                --print("Debug: CurrentPlace count for unitID", unitID, "is", count)
                return count
            end
            
            function NotPlacedCube()
                local cube = nil
                for i,v in next, globalPlacements do
                    if v.Color ~= Color3.fromRGB(255,0,0) and v.Color ~= Color3.fromRGB(255,255,0) then
                        return v
                    end
                end
            
                return cube
            end
            function ResetPlaced()
                for _, v in pairs(globalPlacements) do
                    v.Color = Color3.fromRGB(255, 255, 255)
                end
            end
            function WorkspaceUnit(unitID)
                local unit = nil
                for i,v in next, workspace.Towers:GetChildren() do
                    if v:FindFirstChild('UnitID') and v.UnitID.Value == unitID and v.Owner.Value == Locals.Client.Name then
                        unit = v
                        break
                    end
                end
            
                return unit
            end


        --#endregion
    end
--#endregion

function DebugPrint(...)
    local args = {...}
    local message = ""
    for i, v in ipairs(args) do
        message = message .. tostring(v) .. "\t"
    end
    print("[Akora Hub] |", message)
end

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

--#region Map Data
    local MapDataModule = require(game:GetService("ReplicatedStorage").Modules.MapData)
    local NestedMapData = {
        NotActiveMaps = {}
    }

    for mapName, mapInfo in pairs(MapDataModule) do
        local isPortalMap = false

        for _, typeName in ipairs(mapInfo.Type) do
            if string.find(typeName, "Portal") then
                isPortalMap = true
            end

            local spacedTypeName = typeName
            if #spacedTypeName > 1 then
                spacedTypeName = spacedTypeName:sub(1, 1) .. spacedTypeName:sub(2):gsub("(%u)", " %1")
            end

            if not NestedMapData[spacedTypeName] then
                NestedMapData[spacedTypeName] = {}
            end

            table.insert(NestedMapData[spacedTypeName], mapName)
        end

        if not mapInfo.HasAct and not isPortalMap then
            table.insert(NestedMapData.NotActiveMaps, mapName)
        end
    end
--#endregion

--#region UI Library Setup
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

    local Options = Library.Options
    local Toggles = Library.Toggles

    Library.ForceCheckbox = true -- Forces AddToggle to AddCheckbox
    Library.ShowToggleFrameInKeybinds = true -- Make toggle keybinds work inside the keybinds UI (aka adds a toggle to the UI). Good for mobile users (Default value = true)

    local Window = Library:CreateWindow({
        Title = GameName .. " 🐾 Akora Hub",
        Footer = selectedPun,
        Size = UDim2.fromOffset(860, 450),
        ShowCustomCursor = false,
        Font = Enum.Font.FredokaOne,
        ToggleKeybind = Enum.KeyCode.RightControl,
        Center = true,
        AutoShow = true,
        Resizable = false
    })

    local Tabs = {
        --Main = Window:AddTab("Main", "user"),
        Main = Window:AddTab("Main", "house"),
        Summoning = Window:AddTab("Summoning", "atom"),
        AutoPlay = Window:AddTab("Auto Play", "play"),
        Macro = Window:AddTab("Macro", "cpu"),
        Webhook = Window:AddTab("Webhook", "webhook"),
        ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
    }
--#endregion

--#region UI Settings
    local hubBtn
    if not Locals.IsAllowedPlace(12886143095, 18583778121) then
        local TweenService     = Locals.TweenService
        local VirtualInput     = Locals.VirtualInputManager
        local bottomFrame      = Locals.PlayerGui:WaitForChild("Bottom"):WaitForChild("Frame")

        for _, subframe in ipairs(bottomFrame:GetChildren()) do
            if not subframe:IsA("Frame") then continue end

            for _, btn in ipairs(subframe:GetChildren()) do
                if not btn:IsA("TextButton") then continue end

                -- clone + rename
                hubBtn = btn:Clone()
                hubBtn.Name   = "Hub"
                hubBtn.Parent = subframe

                hubBtn.TextLabel.Text = "Akora"

                -- swap icon + size
                local img = hubBtn:FindFirstChildWhichIsA("ImageLabel")
                if img then
                    img.Image = "rbxassetid://116790885950088"
                    img.Size  = UDim2.new(0,40,0,40)
                end

                -- shift it right by 85px
                local p = hubBtn.Position
                hubBtn.Position = UDim2.new(
                    p.X.Scale, p.X.Offset + 85,
                    p.Y.Scale, p.Y.Offset
                )

                -- hook up the UIScale animations
                local inner = hubBtn:FindFirstChild("Frame")
                              and hubBtn.Frame:FindFirstChild("Frame")
                local uiScale = inner and inner:FindFirstChildOfClass("UIScale")
                if uiScale then
                    local DEFAULT = 1.003
                    local HOVER   = 1.097
                    local PRESS   = 0.956
                    uiScale.Scale = DEFAULT

                    local ti = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
                    local hovering = false

                    local function go(toScale)
                        TweenService:Create(uiScale, ti, { Scale = toScale }):Play()
                    end

                    hubBtn.MouseEnter:Connect(function()
                        hovering = true
                        go(HOVER)
                    end)
                    hubBtn.MouseLeave:Connect(function()
                        hovering = false
                        go(DEFAULT)
                    end)
                    hubBtn.MouseButton1Down:Connect(function()
                        go(PRESS)
                    end)
                    hubBtn.MouseButton1Up:Connect(function()
                        go(hovering and HOVER or DEFAULT)
                    end)
                end

                -- when clicked, simulate RightShift
                hubBtn.MouseButton1Click:Connect(function()
                    VirtualInput:SendKeyEvent(true,  Enum.KeyCode[Library.ToggleKeybind.Value], false, game)
                    VirtualInput:SendKeyEvent(false, Enum.KeyCode[Library.ToggleKeybind.Value], false, game)
                end)
            end
        end
    end

    local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
    MenuGroup:AddButton("Unload UI", function()
        Library:Unload()
        if hubBtn ~= nil then
            hubBtn:Destroy()
        end
        if workspace:FindFirstChild("Placements_Container") then
            workspace.Placements_Container:Destroy()
        end
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

    local Credits = Tabs["UI Settings"]:AddRightGroupbox("Credits")
    Credits:AddLabel("Scripter & Creator: Ako")
    Credits:AddButton("Scripter & Creator: Ako", function()
        --setclipboard("")
    end)
    Credits:AddButton("UI Lib: Deividcomsono", function()
        setclipboard("https://github.com/deividcomsono/Obsidian")
        Library:Notify({
            Title       = "Success",
            Description = "URL Copied to clipboard!",
            Time        = 5,
            SoundId     = 18403881159,
        })
    end)

    
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
    --#region Launcher Section
        local excludedSubstrings = {
            "Challenge","Tournament",
            "Boss Rush","Global Boss",
            "Portal","Halloween Portal",
            "Survival","Dungeon",
            "Elemental Cavern",
            "Elemental Expansion"
        }

        function isExcluded(key)
            for _, substring in ipairs(excludedSubstrings) do
                if string.find(key, substring) then
                    return true
                end
            end
            return false
        end
        local LaunchDropdownValues = {}
        local defaultMode = nil

        for category, _ in pairs(NestedMapData) do
            if category ~= "NotActiveMaps" and not isExcluded(category) then
                table.insert(LaunchDropdownValues, category)
                if category == "Story" then
                    defaultMode = category
                end
            end
        end
        table.sort(LaunchDropdownValues)
        if not defaultMode then
            defaultMode = LaunchDropdownValues[1]
        end

        local Launcher_GroupBox = Tabs.Main:AddLeftGroupbox("Launcher")
        Launcher_GroupBox:AddDropdown("Launch_Mode", {
        	Values = LaunchDropdownValues,
        	Default = defaultMode,
        	Multi = false,

        	Text = "Mode",
        	Tooltip = "Select what Mode to launch into",
        	DisabledTooltip = "I am disabled!",

        	Searchable = true,

        	Callback = function(Value)
        		if Value == "Legendary Stages" then
                    Options.Launch_Act:SetDisabled(false)
                    Options.Launch_Act:SetValues({"1", "2", "3"})
                    Options.Launch_Difficulty:SetValues({"Purgatory"})
                    Options.Launch_Difficulty:SetValue(1)
                elseif Value == "Infinite" then
                    Options.Launch_Act:SetDisabled(true)
                    Options.Launch_Difficulty:SetValue(nil)
                elseif Value == "Raids" then
                    Options.Launch_Act:SetValues({"1", "2", "3", "4", "5", "6"})
                    Options.Launch_Difficulty:SetValue(1)
                else
                    Options.Launch_Act:SetDisabled(false)
                    Options.Launch_Act:SetValues({"1", "2", "3", "4", "5", "6"})
                    Options.Launch_Difficulty:SetValue(nil)
                end
            
                Options.Launch_Map:SetValues(NestedMapData[Options.Launch_Mode.Value] or {})
                Options.Launch_Map:SetValue(nil)
                Options.Launch_Act:SetValue(nil)
        	end,

        	Disabled = false,
        	Visible = true,
        })

        local defaultMaps = NestedMapData[Options.Launch_Mode.Value] or {}
        Launcher_GroupBox:AddDropdown("Launch_Map", {
         	Values = defaultMaps,
        	Default = defaultMaps[1] or 1,
        	Multi = false,

        	Text = "Map",
        	Tooltip = "Will join the selected map",
        	DisabledTooltip = "I am disabled!",

        	Searchable = true,

        	Callback = function(Value)

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
                if Options.Launch_Mode.Value == "Story" then
        		    if Value == "6" then
                        Options.Launch_Difficulty:SetValues({"Normal", "Nightmare", "Purgatory"})
                        Options.Launch_Difficulty:SetValue(nil)
                    else
                        Options.Launch_Difficulty:SetValues({"Normal", "Nightmare",})
                        Options.Launch_Difficulty:SetValue(nil)
                    end
                elseif Options.Launch_Mode.Value == "Legendary Stages" then
                    Options.Launch_Difficulty:SetValues({"Purgatory"})
                    Options.Launch_Difficulty:SetValue(1)
                elseif Options.Launch_Mode.Value == "Raids" then
                    Options.Launch_Difficulty:SetValues({"Nightmare"})
                    Options.Launch_Difficulty:SetValue(1)
                end
        	end,

        	Disabled = false,
        	Visible = true,
        })

        Launcher_GroupBox:AddDropdown("Launch_Difficulty", {
        	Values = { "Normal", "Nightmare"},
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
        	Default = 0,
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
            
        	end,
        })
        Launcher_GroupBox:AddToggle("AutoLaunch", {
        	Text = "Auto Launch",
        	Tooltip = "Enable this after setting the above options!",
        	DisabledTooltip = "I am disabled!",

        	Default = false,
        	Disabled = false,
        	Visible = true,
        	Risky = false,

        	Callback = function(Value)
                
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
        	Disabled = false,
        	Visible = true,
        	Risky = true,

        	Callback = function(Value)
        		--print("Akora Hub | MyToggle changed to:", Value)
        	end,
        })
    --#endregion

    --#region Auto Challenge
        local challengeInfoFolder = game:GetService("ReplicatedStorage").Modules.ChallengeInfo
        local challenges = {}

        for _, child in ipairs(challengeInfoFolder:GetChildren()) do
            if child:IsA("ModuleScript") then
                table.insert(challenges, child.Name)
            end
        end
        local Challenge_GroupBox = Tabs.Main:AddLeftGroupbox("Auto Challenge")
        Challenge_GroupBox:AddDropdown("Ignore_Map", {
        	Values = NestedMapData.Story,
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
        	Values = challenges,
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

    local Portal_GroupBox = Tabs.Main:AddRightGroupbox("Portal")
    --#region Auto Portal
        local sortedSelectedChallenges = {}

        function resortChallenges()
            sortedSelectedChallenges = {}
            for _, ch in ipairs(Options.SelectedChallenges.Value) do
                table.insert(sortedSelectedChallenges, _)
            end
            table.sort(sortedSelectedChallenges, function(a, b)
                local ra, rb = challengeRatings[a] or 0, challengeRatings[b] or 0
                if ra == rb then
                    if a == "No Hit"   and b == "Tower Limit" then return true
                    elseif a == "Tower Limit" and b == "No Hit"   then return false
                    else return a < b
                    end
                else
                    return ra > rb
                end
            end)
        end

        Portal_GroupBox:AddLabel("Auto Claim Portal")
        Portal_GroupBox:AddDropdown("SelectedChallenges", {
            Values          = {"Barebones","Tower Limit","Flight","No Hit","Speedy","High Cost","Short Range","Immunity"},
            Default         = {},
            Multi           = true,
        
            Text            = "Select Challenges",
            Tooltip         = "Select which challenges to prioritize for both claiming and auto using.",
        
            Searchable      = true,
        
            Callback = function(Value)
                resortChallenges()
                --for i,v in next, Value do
                --    print(i,v)
                --end
            end,
        
            Disabled = false,
            Visible  = true,
        })
        Portal_GroupBox:AddToggle("AutoClaimPortal", {
            Text            = "Auto Claim Portal",
            Tooltip         = "Automatically pick the best portal for claim and use",
        
            Default  = false,
            Disabled = false,
            Visible  = true,
            Risky    = false,
        
            Callback = function(val)
                --print("Auto‑claim set to", val)
            end,
        })

        Portal_GroupBox:AddDivider()

        Portal_GroupBox:AddLabel("Auto Next Portal")
        Portal_GroupBox:AddDropdown("PortalLaunch_Maps", {
            Values          = NestedMapData["Portal"],
            Default         = 0,
            Multi           = true,
        
            Text            = "Select Map(s)",
            Tooltip         = "Will use the selected Map(s)",
            DisabledTooltip = "I am disabled!",
        
            Searchable      = true,
        
            Callback = function(Value)

            end,
        
            Disabled        = false,
            Visible         = true,
        })
        Portal_GroupBox:AddDropdown("PortalLaunch_Challenge", {
            Values          = {"Barebones","Tower Limit","Flight","No Hit","Speedy","High Cost","Short Range","Immunity"},
            Default         = 0,
            Multi           = true,
        
            Text            = "Select Challenge(s)",
            Tooltip         = "Will filter to use the selected Challenge(s)",
            DisabledTooltip = "I am disabled!",
        
            Searchable      = true,
        
            Callback = function(Value)

            end,
        
            Disabled        = false,
            Visible         = true,
        })
        Portal_GroupBox:AddDropdown("PortalLaunch_Tier", {
            Values          = { "Tier 1","Tier 2","Tier 3",
                                "Tier 4","Tier 5","Tier 6",
                            },
            Default         = 0,
            Multi           = true,
        
            Text            = "Select Tier(s)",
            Tooltip         = "Will filter to use the selected Tier(s)",
            DisabledTooltip = "I am disabled!",
        
            Searchable      = true,
        
            Callback = function(Value)

            end,
        
            Disabled        = false,
            Visible         = true,
        })
        Portal_GroupBox:AddToggle("PortalLaunch_Toggle", {
            Text            = "Auto Next Portal",
            Tooltip         = "Automatically use the best portal that matches the settings above after you finish a match.",
        
            Default         = false,
            Disabled        = false,
            Visible         = true,
            Risky           = false,
        
            Callback = function(val)
                --print("Auto‑claim set to", val)
            end,
        })

        --#region initialize our list
            resortChallenges()

            if not Locals.IsAllowedPlace(12886143095, 18583778121) then
                local rem = Locals.ReplicatedStorage.Remotes:FindFirstChild("PortalSelection")
                if rem then
                    rem.OnClientEvent:Connect(function(portals)
                        if type(portals) ~= "table" then return end
                    
                        -- DEBUG: show selected challenges in priority order
                        --print("Debug ▶ Selected challenges (priority):")
                        for idx, ch in ipairs(sortedSelectedChallenges) do
                            print(string.format("  #%d: %s", idx, ch))
                        end
                    
                        -- DEBUG: list incoming portals
                        for i, p in ipairs(portals) do
                            local d = p.PortalData or {}
                            --print(string.format(
                            --    "Portal[%d] → Map:%s | Challenge:%s | Tier:%s | Name:%s",
                            --    i,
                            --    d.Map or "?",
                            --    d.Challenges or "?",
                            --    d.Tier or "?",
                            --    p.PortalName or "?"
                            --))
                        end
                    
                        if Toggles.AutoClaimPortal.Value then
                            --print("Debug ▶ Auto‑claim is ON")
                        
                            -- 1) Grab raw selectedChallenges table
                            local raw = Options.SelectedChallenges.Value
                            --print("Debug ▶ RAW Options.SelectedChallenges.Value type:", type(raw))
                        
                            -- 2) Build sortedSelectedChallenges from keys with true values
                            sortedSelectedChallenges = {}
                            if type(raw) == "table" then
                                for challengeName, isSelected in pairs(raw) do
                                    if isSelected then
                                        table.insert(sortedSelectedChallenges, challengeName)
                                        --print("Debug ▶ Loaded challenge:", challengeName)
                                    end
                                end
                            else
                                --warn("Debug ▶ SelectedChallenges.Value isn’t a table!", tostring(raw))
                            end
                            --print("Debug ▶ #sortedSelectedChallenges =", #sortedSelectedChallenges)
                        
                            -- 3) Find best portal
                            --print("Debug ▶ Total portals available:", #portals)
                            local best, bestPrio, bestIndex
                            for i = 1, math.min(3, #portals) do
                                local p = portals[i]
                                local pd = p.PortalData or {}
                                --print(string.format(
                                --    "Debug ▶ Portal[%d] → Map:%s | Challenge:%s",
                                --    i,
                                --    tostring(pd.Map),
                                --    tostring(pd.Challenges)
                                --))
                            
                                local ch = pd.Challenges
                                if ch then
                                    for prio, sel in ipairs(sortedSelectedChallenges) do
                                        --print(string.format("  Comparing '%s' to '%s' (priority %d)", ch, sel, prio))
                                        if ch == sel then
                                            --print("    → Match!")
                                            if not bestPrio or prio > bestPrio then
                                                best, bestPrio, bestIndex = p, prio, i
                                                --print(string.format("      New best: portal #%d (priority %d)", i, prio))
                                            end
                                            break
                                        end
                                    end
                                else
                                    --print("  No challenge field on this portal")
                                end
                            end

                            if best then
                                --print(string.format(
                                --    "Debug ▶ Claiming portal #%d with '%s' (priority %d)",
                                --    bestIndex, best.PortalData.Challenges, bestPrio
                                --))
                                wait(2)
                                local ok, err = pcall(function()
                                    rem:FireServer(bestIndex)

                                    local Players = game:GetService("Players")
                                    local plr     = Players.LocalPlayer
                                    local prompt  = plr.PlayerGui:WaitForChild("Prompt")
                                    local mainF   = prompt:WaitForChild("TextButton"):WaitForChild("Frame")

                                    -- Step 1: find the one child‑Frame that has 3 nested Frames (and no direct TextButton),
                                    -- then inside those 3 Frames grab its TextButton and click it.
                                    for _, f in ipairs(mainF:GetChildren()) do
                                        if f:IsA("Frame") then
                                            -- count direct Frame children
                                            local frameCount = 0
                                            for _, ch in ipairs(f:GetChildren()) do
                                                if ch:IsA("Frame") then
                                                    frameCount += 1
                                                end
                                            end
                                        
                                            -- ensure no direct TextButton, but exactly 3 Frames inside
                                            if frameCount == 3 and not f:FindFirstChildWhichIsA("TextButton") then
                                                for _, nested in ipairs(f:GetChildren()) do
                                                    if nested:IsA("Frame") then
                                                        local btn = nested:FindFirstChildWhichIsA("TextButton")
                                                        if btn then
                                                            Locals.ActivatePromptButton(btn)
                                                            break
                                                        end
                                                    end
                                                end
                                                break
                                            end
                                        end
                                    end

                                    -- Step 2: find the child‑Frame that has a direct TextButton and click it
                                    for _, f in ipairs(mainF:GetChildren()) do
                                        if f:IsA("Frame") then
                                            local btn = f:FindFirstChildWhichIsA("TextButton")
                                            if btn then
                                                Locals.ActivatePromptButton(btn)
                                                break
                                            end
                                        end
                                    end
                                end)
                                if ok then
                                    --print("Debug ▶ FireServer succeeded")
                                    Library:Notify({
                                        Title       = "Success",
                                        Description = "✅ Claimed portal: " .. best.PortalData.Challenges,
                                        Time        = 5,
                                        SoundId     = 18403881159,
                                    })
                                else
                                    print("Debug ▶ Portal claim failed")
                                    Library:Notify({
                                        Title       = "Error",
                                        Description = "❌ Portal claim failed",
                                        Time        = 5,
                                        SoundId     = 8400918001,
                                    })
                                    --warn("Debug ▶ FireServer failed:", err)
                                end

                            else
                                print("Debug ▶ No matching portal found.")
                                Library:Notify({
                                    Title       = "Error",
                                    Description = "❌ No portal found",
                                    Time        = 5,
                                    SoundId     = 8400918001,
                                })
                            end
                        else
                            --print("Debug ▶ Auto‑claim is OFF")
                        end
                    end)
                end
            end
        --#endregion
    --#endregion

    local BossRush_GroupBox = Tabs.Main:AddRightGroupbox("Boss Rush")
    --#region Boss Rush Section
        BossRush_GroupBox:AddLabel("Joiner")
        BossRush_GroupBox:AddToggle("JoinTitan_BossRush", {
            Text            = "Auto Join (Titan Rush)",
            --Tooltip         = "Will automatically fire the cannons at the boss once they become active.",
        
            Default         = false,
            Disabled        = false,
            Visible         = true,
            Risky           = false,
        
            Callback = function(Value)
                
            end,
        })

        BossRush_GroupBox:AddToggle("JoinGodly_BossRush", {
            Text            = "Auto Join (Godly Rush)",
            --Tooltip         = "Will automatically fire the cannons at the boss once they become active.",
        
            Default         = false,
            Disabled        = false,
            Visible         = true,
            Risky           = false,
        
            Callback = function(Value)

            end,
        })


        BossRush_GroupBox:AddDivider()

        BossRush_GroupBox:AddLabel("Boss Rush Functions")
        BossRush_GroupBox:AddToggle("Auto_Cannon_TitanRush", {
            Text            = "Auto Fire Cannons (Titan Rush)",
            Tooltip         = "Will automatically fire the cannons at the boss once they become active.",
        
            Default         = false,
            Disabled        = false,
            Visible         = true,
            Risky           = false,
        
            Callback = function(Value)

            end,
        })

        BossRush_GroupBox:AddDivider()

        BossRush_GroupBox:AddLabel("Card Picker")
        BossRush_GroupBox:AddDropdown("CardPickerSelector", {
            Values          = {"Raging Power", "Feeding Madness", "Demon Takeover", "Insanity", "Venoshock", 
                                "Fortune", "Godspeed", "Metal Skin", "Emotional Damage", "Chaos Eater"},
            Default         = 0,
            Multi           = true,
        
            Text            = "Select Card(s) to automatically",
            Tooltip         = "Will use the selected Map(s)",
            DisabledTooltip = "I am disabled!",
        
            Searchable      = true,
        
            Callback = function(Value)

            end,
        
            Disabled        = false,
            Visible         = true,
        })
        BossRush_GroupBox:AddToggle("AutoCardPicker", {
            Text            = "Auto Card Picker",
            Tooltip         = "Automatically pick the best card for you.",
        
            Default         = false,
            Disabled        = false,
            Visible         = true,
            Risky           = false,
        
            Callback = function(Value)

            end,
        })
    --#endregion
--#endregion

--#region Summoning Section

    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    local promptName = "Prompt"   

    local function getTextButton()
        local promptGui = playerGui:FindFirstChild(promptName)
        if not promptGui then
            return nil
        end
        return promptGui:FindFirstChild("TextButton")
    end

    local function simulateKey(key)
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end)
    end

    local function waitForPrompt(timeout)
        timeout = timeout or 5
        local elapsed = 0
        local btn

        repeat
            btn = getTextButton()
            if btn then break end
            wait(0.1)
            elapsed = elapsed + 0.1
        until elapsed >= timeout
    
        if not btn then
            --warn("waitForPrompt ▶ prompt never appeared")
            return
        end
    
        Locals.GuiService.SelectedObject = btn
        btn.Activated:Wait()
    
        wait(0.1)
    
        simulateKey("Return")
    end

    
    local AllUnitAliases = {}
    for _, alias in pairs(UnitNames) do
        table.insert(AllUnitAliases, alias)
    end

    local Summon_GroupBox = Tabs.Summoning:AddLeftGroupbox("Summoning")
    Summon_GroupBox:AddDropdown("Summon_Banner", {
        Values = {"Mythic", "Celestial", "Ultimate"},
        Default = 0,
        Multi = false,

        Text = "Select Summon Banner",
        Tooltip = "Will summon from this Banner.",
        DisabledTooltip = "I am disabled!",

        Searchable = true,

        Callback = function(Value)
            
        end,

        Disabled = false,
        Visible = true,
    })
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
        Disabled = false,
        Visible = true,
        Risky = false,

        Callback = function(Value)
            
        end,
    })
    Summon_GroupBox:AddDivider()
    Summon_GroupBox:AddLabel("Summon Settings")
    Summon_GroupBox:AddDropdown("Summon_Settings_Type", {
        Values = {"Till Unit", "Use Gem Amount"},
        Default = 2,
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
        Values = AllUnitAliases,
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
        Default = 600,
        Numeric = true,
        Finished = false,
        ClearTextOnFocus = false,

        Text = "Gem Amount",

        Placeholder = "Put a number here",

        Callback = function(Value)
            --print("Akora Hub | Text updated. New text:", Value)
        end,

        Disabled = false,
        Visible = true,
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

    if Locals.PlaceId == 18583778121 or Locals.PlaceId == 12886143095 then
        Locals.ReplicatedStorage.Remotes.SummonDrop.OnClientEvent:Connect(function(drops, indices, isTenPull)
            for i, unit in ipairs(drops) do
                table.insert(SummonDropsLog, unit.Name)
                print(("[SummonDrop #%d] %s (%s)")
                    :format(
                        #SummonDropsLog,
                        unit.Name,
                        unit.Rarity
                    )
                )
            end
        end)
    end

    Options.Summon_Settings_Type:OnChanged(function()
        if Options.Summon_Settings_Type.Value == "Till Unit" then
            Options.Summon_Til_Unit:SetVisible(true)
            Options.Summon_UseGemAmount:SetVisible(false)
        elseif Options.Summon_Settings_Type.Value == "Use Gem Amount" then
            Options.Summon_Til_Unit:SetVisible(false)
            Options.Summon_UseGemAmount:SetVisible(true)
        end
    end)

    local SummonPrices = {
        ["No VIP"] = { B1 = 500, B2 = 750, B3 = 500 },
        ["1 VIP"]  = { B1 = 450, B2 = 675, B3 = 450 },
        ["2 VIP"]  = { B1 = 400, B2 = 600, B3 = 400 },
    }

    function getVipTier(gamepasses)
        local has1, has2 = false, false
        for passName in pairs(gamepasses or {}) do
            if passName == "Vip1" then has1 = true end
            if passName == "Vip2" then has2 = true end
        end
        if     has1 and has2 then return "2 VIP"
        elseif has1 or has2 then return "1 VIP"
        else   return "No VIP"    end
    end
    
    Toggles.Auto_Summon:OnChanged(function()
        local bannerMap = {
            Mythic    = 1,
            Celestial = 2,
            Ultimate  = 3,
        }
    
        task.spawn(function()
            if not Toggles.Auto_Summon.Value then return end
            local settingType = Options.Summon_Settings_Type.Value   -- "Use Gem Amount" or "Till Unit"
            local method      = Options.Summon_Method.Value          -- "1 Pull" or "10 Pull"
            local bannerName  = Options.Summon_Banner.Value
            local bannerNum   = bannerMap[bannerName]
            if not bannerNum then
                warn("Invalid banner name:", bannerName)
                return
            end
            local bannerStr   = tostring(bannerNum)
        
            local tierKey = getVipTier(PlayerData.Gamepasses)
            if not tierKey or not SummonPrices[tierKey] then
                warn("Invalid VIP tier:", tierKey)
                return
            end
        
            local bannerKey = "B"..bannerNum
            local price10   = SummonPrices[tierKey][bannerKey]
            if type(price10) ~= "number" then
                warn("No price for tier/banner:", tierKey, bannerKey)
                return
            end
            local cost1 = math.ceil(price10 / 10)
        
            local function doPull(amount)
                print(("Pulling %dx banner #%s"):format(amount, bannerStr))
                Locals.ReplicatedStorage.Remotes.Summon:InvokeServer(amount, bannerStr)
                wait(1.2)
                spawn(function()
                    waitForPrompt()
                end)
            end
        
            print(("Mode=%s | Method=%s | Banner=%s(%s) | Tier=%s | price10=%d | cost1=%d")
                :format(settingType, method, bannerName, bannerStr, tierKey, price10, cost1)
            )

            while Toggles.Auto_Summon.Value do
                if settingType == "Use Gem Amount" then
                    local actualGems = Locals.Client:FindFirstChild("Emeralds") and Locals.Client.Emeralds.Value or 0
                    local requested = tonumber(Options.Summon_UseGemAmount.Value)
                    if not requested or requested <= 0 then
                        warn("Invalid summon‑gem amount:", requested)
                        return
                    end
            
                    local remaining = requested
                    while Toggles.Auto_Summon.Value and remaining > 0 do
                        local haveGems = Locals.Client:FindFirstChild("Emeralds") and Locals.Client.Emeralds.Value or 0
                    
                        if method == "10 Pull" 
                          and remaining >= price10 
                          and haveGems   >= price10 
                        then
                            doPull(10)
                            remaining = remaining - price10
                        else
                            doPull(1)
                            remaining = remaining - cost1
                        end
                        Toggles.Auto_Summon:SetValue(false)
                    end
                    break
                elseif settingType == "Till Unit" then
                    SummonDropsLog = {}
                
                    local targetName = Options.Summon_Til_Unit.Value
                    if not targetName or targetName == "" then
                        warn("No target unit specified")
                        return
                    end
                
                    print("Summoning until you get:", targetName)
                    while Toggles.Auto_Summon.Value do
                        local haveGems = Locals.Client:FindFirstChild("Emeralds") and Locals.Client.Emeralds.Value or 0
                        if method == "10 Pull" and haveGems >= price10 then
                            doPull(10)
                        else
                            doPull(1)
                        end
                
                        local gotTarget = false
                        for _, drop in ipairs(SummonDropsLog) do
                            if drop == targetName or UnitNames[drop] == targetName then
                                gotTarget = true
                                break
                            end
                        end
                
                        if gotTarget then
                            print("✅ Got your target:", targetName)
                            Toggles.Auto_Summon:SetValue(false)
                            break
                        end
                    end
                    break
                end
            end
        end)
    end)
--#endregion

--#region Auto Play Section
    --#region Smart Autoplay Section

        local waypointList = {}
        local pathNames = {}

        if not Locals.IsAllowedPlace(12886143095, 18583778121) then
            local map = workspace:WaitForChild("Map")
            for _, obj in ipairs(map:GetChildren()) do
                if obj:IsA("Folder") then
                    if obj.Name == "Waypoints" then
                        table.insert(waypointList, { folder = obj, num = 1 })
                    else
                        local digits = obj.Name:match("^Waypoints(%d+)$")
                        if digits then
                            table.insert(waypointList, { folder = obj, num = tonumber(digits) })
                        end
                    end
                end
            end

            table.sort(waypointList, function(a, b)
                return a.num < b.num
            end)


            for _, entry in ipairs(waypointList) do
                if entry.num == 1 then
                    table.insert(pathNames, "Main Path")
                else
                    table.insert(pathNames, "Path " .. entry.num)
                end
            end
        end
        
        local SmartAutoplay_GroupBox = Tabs.AutoPlay:AddLeftGroupbox("Smart Auto Play")
        SmartAutoplay_GroupBox:AddDropdown("Autoplay_Path", {
            Values      = pathNames,
            Default     = 1,
            Multi       = false,
            Text        = "Select Path to place on",
            DisabledTooltip = "I am disabled!",
            Searchable  = true,
            Callback    = function(selectedName)
                for i, name in ipairs(pathNames) do
                    if name == selectedName then
                        local chosenFolder = waypointList[i].folder
                        print("Chose path folder:", chosenFolder.Name)
                        getgenv().SmartAutoplay.SelectedPathFolder = chosenFolder
                        updatePlacementVisualizer(Options.Autoplay_Distance.Value)
                        break
                    end
                end
            end,
            Disabled    = false,
            Visible     = true,
        })
        SmartAutoplay_GroupBox:AddSlider("Autoplay_Distance", {
        	Text = "Placement Distance",
        	Default = 30,
        	Min = 0,
        	Max = 100,
        	Rounding = 0,
        	Compact = false,
        
        	Callback = function(Value)
                if not Locals.IsAllowedPlace(12886143095, 18583778121) then
        		    updatePlacementVisualizer(Value)
                end
        	end,
        
        	Tooltip = "How far away from the enemy spawn units place.",
        	DisabledTooltip = "I am disabled!",
        
        	Disabled = false,
        	Visible = true,
        })
        SmartAutoplay_GroupBox:AddToggle("Autoplay_Enable", {
        	Text = "Enable Smart Autoplay",
        	Tooltip = "Will automatically place and upgrade units at selected distance.",
        	DisabledTooltip = "I am disabled!",
        
        	Default = false,
        	Disabled = false,
        	Visible = true,
        	Risky = false,
        
        	Callback = function(Value)
                
        	end,
        })

        SmartAutoplay_GroupBox:AddToggle("Autoplay_DebugDisplay", {
        	Text = "Enabled Debug Display",
        	Tooltip = "Will show placement debug parts.",
        	DisabledTooltip = "I am disabled!",
        
        	Default = false,
        	Disabled = false,
        	Visible = true,
        	Risky = false,
        
        	Callback = function(Value)
        		--pcall(function()

                    getgenv().debugvisible = Value
                    local placementContainer = Workspace:FindFirstChild("Placements_Container")
                    if not placementContainer then return end

                    local cylinder = placementContainer:FindFirstChild("PlacementVisualizer")
                    if not cylinder then return end

                    if Value then
                        cylinder.Transparency = 0.8
                    else
                        cylinder.Transparency = 1
                    end

                    local cubeContainer = cylinder:FindFirstChild("Placements")
                    if cubeContainer then
                        for _, cube in ipairs(cubeContainer:GetChildren()) do
                            if cube:IsA("Part") then
                                if Value then
                                    cube.Transparency = 0.25
                                else
                                    cube.Transparency = 1
                                end
                            end
                        end
                    end
                --end)
        	end,
        })
        if not Locals.IsAllowedPlace(12886143095, 18583778121) then
            updatePlacementVisualizer(Options.Autoplay_Distance.Value)
        end
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
                Rounding = 0,
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
                Rounding = 0,
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
                getgenv().AutoUpgrade_Enabled = Value
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
                Rounding = 0,
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
                Default = 12,
                Min = 0,
                Max = 15,
                Rounding = 0,
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
    
    local ManualLocationPlacement_Groupbox = Tabs.AutoPlay:AddLeftGroupbox("Manual Location Autoplay")
    --#region Manual Location Section

        -- Manual‑location persistence
        local ManualMapName
        if getgenv().MapName == nil then
            ManualMapName = "Lobby"
        else
            ManualMapName = getgenv().MapName
        end

        local locationsFile   = Directory .. "/manual locations/" .. ManualMapName .. ".json"
        local ManualLocations = {}
            
        -- if the file doesn't exist yet, create it as an empty JSON `{}` 
        if not pcall(function() readfile(locationsFile) end) then
            writefile(locationsFile, Locals.HttpService:JSONEncode({}))
        end
        
        -- now safely load whatever’s in there
        local raw  = readfile(locationsFile)
        local data = Locals.HttpService:JSONDecode(raw) or {}
        for k,v in pairs(data) do
            ManualLocations[tonumber(k)] = Vector3.new(v.X, v.Y, v.Z)
        end

        -- six unique colors for each unit marker
        local markerColors = {
            Color3.fromRGB(255, 0, 0),    -- Red
            Color3.fromRGB(255,165, 0),   -- Orange
            Color3.fromRGB(255,255, 0),   -- Yellow
            Color3.fromRGB(0,255, 0),     -- Green
            Color3.fromRGB(0,  0,255),    -- Blue
            Color3.fromRGB(128,  0,128),  -- Purple
        }

        local ManualMarkers = {}

        for i = 1, 6 do
            -- determine displayName or disable if none
            local slotInfo   = PlayerData.Slots["Slot"..i]
            local rawName    = slotInfo and slotInfo.Value or ""
            local displayName = ""
            if rawName ~= "" then
                displayName = UnitNames[rawName] or rawName
            end
        
            local label    = (displayName ~= "" and (displayName .. " Location Selector")) or "No Unit Present"
            local disabled = (displayName == "")
        
            local btn = ManualLocationPlacement_Groupbox:AddButton(label, function()
                if disabled then return end
        
                Library:Notify({
                    Title       = "Info",
                    Description = "Click to place marker for " .. displayName,
                    Time        = 5,
                })
        
                -- spawn your color‑coded marker
                local marker = Instance.new("Part")
                marker.Name         = "ManualLocMarker"
                marker.Size         = Vector3.new(1,1,1)
                marker.Anchored     = true
                marker.CanCollide   = false
                marker.Transparency = 0.5
                marker.Material     = Enum.Material.Neon
                marker.Color        = markerColors[i]
                marker.Parent       = Locals.Workspace.Placements_Container.ManualPlacements_Container
        
                -- raycast params ignoring the marker itself
                local rayParams2 = RaycastParams.new()
                rayParams2.FilterType = Enum.RaycastFilterType.Blacklist
                rayParams2.FilterDescendantsInstances = {
                    marker,
                    game.Players.LocalPlayer.Character,
                    workspace:FindFirstChild("Towers"),
                    workspace:FindFirstChild("Placements_Container"),
                    workspace:FindFirstChild("Enemies"),
                }
        
                -- follow cursor with raycast
                local rsConn = Locals.RunService.RenderStepped:Connect(function()
                    local unitRay = Locals.Mouse.UnitRay
                    local hit = Locals.Workspace:Raycast(
                        unitRay.Origin,
                        unitRay.Direction * 10000,
                        rayParams2
                    )
                    if hit then
                        marker.Position = hit.Position
                    end
                end)
        
                -- on click, save & cleanup
                local uiConn
                uiConn = Locals.UserInputService.InputBegan:Connect(function(input, gp)
                    if not gp and input.UserInputType == Enum.UserInputType.MouseButton1 then
                        -- save the location
                        ManualLocations[i] = marker.Position
        
                        -- write file
                        local out = {}
                        for idx, pos in pairs(ManualLocations) do
                            out[tostring(idx)] = { X = pos.X, Y = pos.Y, Z = pos.Z }
                        end
                        writefile(locationsFile, Locals.HttpService:JSONEncode(out))
        
                        -- remove old visuals for this slot
                        if ManualMarkers[i] then
                            if ManualMarkers[i].pillar then ManualMarkers[i].pillar:Destroy() end
                            if ManualMarkers[i].gui    then ManualMarkers[i].gui:Destroy()    end
                        end
    
                        local pillar = Instance.new("Part")
                        pillar.Name         = "ManualPlacementPillar_"..i
                        pillar.Size         = Vector3.new(0.5, 2.5, 0.5)
                        pillar.Anchored     = true
                        if Toggles.Show_ManualPlacements.Value then
                            pillar.Transparency = 0
                        else
                            pillar.Transparency = 1
                        end
                        pillar.CanCollide   = false
                        pillar.Material     = Enum.Material.Neon
                        pillar.Color        = markerColors[i] or Color3.new(1,1,1)
                        pillar.Position     = marker.Position + Vector3.new(0,1,0)
                        pillar.Parent       = Locals.Workspace.Placements_Container.ManualPlacements_Container
    
                        -- attach a BillboardGui with the unit name
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name          = "ManualPlacementLabel_"..i
                        billboard.Adornee       = pillar
                        billboard.Size          = UDim2.new(0, 100, 0, 50)
                        billboard.StudsOffset   = Vector3.new(0, 3, 0)
                        billboard.AlwaysOnTop   = true
                        if Toggles.Show_ManualPlacements.Value then
                            billboard.Enabled   = true
                        else
                            billboard.Enabled   = false
                        end
                        billboard.Parent        = pillar
    
                        local label = Instance.new("TextLabel")
                        label.Size               = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text               = displayName
                        label.TextSize           = 20
                        label.TextColor3         = markerColors[i] or Color3.new(1,1,1)
                        label.TextStrokeTransparency = 0
                        label.Parent             = billboard
    
                        ManualMarkers[i] = { pillar = pillar, gui = billboard }
        
                        Library:Notify({
                            Title       = "Saved",
                            Description = displayName .. " location saved.",
                            Time        = 5,
                            SoundId     = 18403881159,
                        })
        
                        -- cleanup
                        marker:Destroy()
                        rsConn:Disconnect()
                        uiConn:Disconnect()
                    end
                end)
            end)
        
            btn:SetDisabled(disabled)
        end
        ManualLocationPlacement_Groupbox:AddToggle("ManualPlacements_Play", {
            Text = "Auto Play - Manual Location",
            Tooltip = "Will autoplay using the selected manual locations.",
            DisabledTooltip = "I am disabled!",
        
            Default = false,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(Value)
                --print("Akora Hub | MyToggle changed to:", Value)
            end,
        })

        ManualLocationPlacement_Groupbox:AddDivider()
        ManualLocationPlacement_Groupbox:AddToggle("Show_ManualPlacements", {
            Text            = "Show Manual Placements",
            Tooltip         = "Display saved manual unit locations",
            DisabledTooltip = "No data yet!",
        
            Default = false,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(show)
                
            end
        })
        function InitializeManualMarkers()
            for i, pos in pairs(ManualLocations) do
                -- figure out what unit’s in slot i
                local slotInfo    = PlayerData.Slots["Slot"..i]
                local rawName     = slotInfo and slotInfo.Value or ""
                local displayName = rawName ~= "" and (UnitNames[rawName] or rawName) or ""
                if displayName ~= "" then
                    -- create the pillar
                    local pillar = Instance.new("Part")
                    pillar.Name         = "ManualPlacementPillar_"..i
                    pillar.Size         = Vector3.new(0.5, 2.5, 0.5)
                    pillar.Anchored     = true
                    pillar.CanCollide   = false
                    pillar.Material     = Enum.Material.Neon
                    pillar.Color        = markerColors[i] or Color3.new(1,1,1)
                    -- hide or show based on current toggle
                    pillar.Transparency = Toggles.Show_ManualPlacements.Value and 0 or 1
                    pillar.Position     = pos + Vector3.new(0,1,0)
                    pillar.Parent       = Locals.Workspace.Placements_Container.ManualPlacements_Container
        
                    -- create its BillboardGui
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name        = "ManualPlacementLabel_"..i
                    billboard.Adornee     = pillar
                    billboard.Size        = UDim2.new(0,100,0,50)
                    billboard.StudsOffset = Vector3.new(0,3,0)
                    billboard.AlwaysOnTop = true
                    billboard.Enabled     = Toggles.Show_ManualPlacements.Value
                    billboard.Parent      = pillar
        
                    local label = Instance.new("TextLabel")
                    label.Size                   = UDim2.new(1,0,1,0)
                    label.BackgroundTransparency = 1
                    label.Text                   = displayName
                    label.TextSize               = 20
                    label.TextColor3             = markerColors[i] or Color3.new(1,1,1)
                    label.TextStrokeTransparency = 0
                    label.Parent                 = billboard
        
                    -- store it so your button‑click or toggle code can later update/hide it
                    ManualMarkers[i] = { pillar = pillar, gui = billboard }
                end
            end
        end
        if not Locals.IsAllowedPlace(12886143095, 18583778121) then
            InitializeManualMarkers()
        end
        Toggles.Show_ManualPlacements:OnChanged(function(show)
            for _, data in pairs(ManualMarkers) do
                data.pillar.Transparency = show and 0 or 1
                data.gui.Enabled         = show
            end
        end)

        function getPatternOffsets(count, spacing)
            if count == 1 then
                return { Vector3.new(0,0,0) }
            elseif count == 2 then
                local d = spacing/2
                return { Vector3.new(-d,0,0), Vector3.new(d,0,0) }
            elseif count == 3 then
                local d, h = spacing, math.sqrt(3)/2 * spacing
                return {
                    Vector3.new(   0, 0,   d ),
                    Vector3.new(-h, 0, -d/2),
                    Vector3.new( h, 0, -d/2),
                }
            elseif count == 4 then
                local d = spacing/2
                return {
                    Vector3.new(-d, 0, -d),
                    Vector3.new( d, 0, -d),
                    Vector3.new(-d, 0,  d),
                    Vector3.new( d, 0,  d),
                }
            else
                local offsets = getPatternOffsets(4, spacing)
                for i = 1, count - 4 do
                    local base = offsets[((i-1)%4)+1]
                    local dir  = Vector3.new(
                        ((i%2==0) and 1 or -1) * spacing,
                        0,
                        ((i%2==1) and 1 or -1) * spacing
                    )
                    table.insert(offsets, base + dir)
                end
                return offsets
            end
        end
    --#endregion

    local SellOnWave_Groupbox = Tabs.AutoPlay:AddLeftGroupbox("Sell On Wave")
    --#region Autosell On Wave Section
        SellOnWave_Groupbox:AddInput("Sell_WaveReq", {
            Text = "Wave",
            Default = "",
            Numeric = true,
            Finished = false,
            Placeholder = "Wave Required to sell units...",
            Callback = function(Value)
            end
        })
        
        SellOnWave_Groupbox:AddToggle("Sell_Enabled", {
            Text = "Enabled Auto Sell on Wave",
            Tooltip = "Will automatically sell units at required wave.",
            DisabledTooltip = "I am disabled!",
        
            Default = false,
            Disabled = false,
            Visible = true,
            Risky = false,
        
            Callback = function(Value)

            end,
        })
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
                Url = Options.Webhook_Link.Value,
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
        if Locals.PlaceId == 18583778121 or Locals.PlaceId == 12886143095 then
            local QueueTPFolder = workspace.TeleporterFolder
            function Locals.JoinQueue(queueName)
                local found = false
                repeat
                    for i, TeleporterModel in next, QueueTPFolder[queueName]:GetChildren() do
                        if TeleporterModel.Door.UI.PlayerCount.text == "0/4 Players" then
                            firetouchinterest(TeleporterModel.Door, Locals.HumanoidRootPart, 1)
                            firetouchinterest(TeleporterModel.Door, Locals.HumanoidRootPart, 0)
                            found = true
                            break
                        end
                    end
                    if not found then
                        wait(0.5)
                    end
                until found
                wait(1.5)
            end

            Toggles.AutoLaunch:OnChanged(function()
            	if Toggles.AutoLaunch.Value then
                    wait(Options.Launch_JoinDelay.Value)
                    if Options.Launch_Mode.Value == "Story" or Options.Launch_Mode.Value == "Legendary Stages" then
                        Locals.JoinQueue("Story")

                        game:GetService("ReplicatedStorage").Remotes.Story.Select:InvokeServer(Options.Launch_Map.Value, tonumber(Options.Launch_Act.Value), Options.Launch_Difficulty.Value, Toggles.Friends_Only.Value)

                    elseif Options.Launch_Mode.Value == "Raids" then
                        Locals.JoinQueue("Raids")

                        warn("Please select it yourself, currently bugged")
                        --[[
                            game:GetService("ReplicatedStorage").Remotes.Story.Select:InvokeServer(Options.Launch_Map.Value, tonumber(Options.Launch_Act.Value), Options.Launch_Difficulty.Value, Toggles.Friends_Only.Value)

                            Correct remote, but will error with 
                                ServerScriptService.TeleporterHandler.Story:135: Player XXXXXXXX is not in a teleporter - function SafeCallback:2572 function SetValue:2609 
                        ]]
                                
                    elseif Options.Launch_Mode.Value == "Infinite" then
                        Locals.JoinQueue("Story")

                        game:GetService("ReplicatedStorage").Remotes.Story.Select:InvokeServer(Options.Launch_Map.Value, Options.Launch_Mode.Value, Options.Launch_Difficulty.Value, Toggles.Friends_Only.Value)

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
        elseif Locals.PlaceId == 12900046592 then
            local toDisable = {
                Toggles.Autoplay_Enable,
                Toggles.ManualPlacements_Play,
                Toggles.Autoplay_Upgrade,
            }
            game.ReplicatedStorage.Wave:GetPropertyChangedSignal("Value"):Connect(function()
                getgenv().MapWave = game:GetService("ReplicatedStorage").Wave.Value

                if Toggles.Sell_Enabled.Value and Options.Sell_WaveReq.Value ~= "" and Options.Sell_WaveReq.Value ~= nil then
                    if getgenv().MapWave and tonumber(getgenv().MapWave) >= tonumber(Options.Sell_WaveReq.Value) then
                        for _, tg in ipairs(toDisable) do
                            tg:SetValue(false)
                        end
                        Locals.ReplicatedStorage.Remotes.UnitManager.SellAll:FireServer()
                    end
                end
            end)
            Cash_Loc = game.Players.LocalPlayer.Cash
            Player_Cash = Cash_Loc.Value
            Cash_Loc:GetPropertyChangedSignal("Value"):Connect(function()
                Player_Cash = Cash_Loc.Value
            end)
            print("-----------Map Data-----------")
            print(" Map Name:", getgenv().MapName)
            print(" Map Mode:", getgenv().MapMode)
            print(" Map Difficulty:", getgenv().MapDifficulty)
            print("------------------------------")
        end
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

    --#region Auto Play Logic
        --#region Functions  
            local placeFunc
            for i,v in next, getgc() do
                if type(v) == "function" and debug.info(v, "n") == "Place" then
                    placeFunc = v
                    break
                end
            end

            if placeFunc ~= nil then
                spawn(function()
                    while wait() do
                        if Toggles.PlaceAnywhere.Value or getgenv().SmartAutoplay.Autoplace then 
                            debug.setupvalue(placeFunc, 2, true)
                        end
                    end
                end)
            end    

            -- Helper: Find the EquippedUnit entry by its UnitID.
            function FindEquippedUnitByID(unitID)
                for _, eUnit in pairs(getgenv().SmartAutoplay.EquippedUnits) do
                    if eUnit.UnitID == unitID then
                        return eUnit
                    end
                end
                return nil
            end
            
            local filterList = {
                game.Players.LocalPlayer.Character,
                Locals.safeGet("Towers"),
                Locals.safeGet("Placements_Container"),
                Locals.safeGet("Enemies"),
            }
            
            for i = #filterList,1,-1 do
                if not filterList[i] then table.remove(filterList, i) end
            end
            
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = filterList

            function findFloorY(cubePos, maxDistance)
                maxDistance = maxDistance or 100

                local downResult = workspace:Raycast(
                    cubePos + Vector3.new(0, maxDistance/2, 0),
                    Vector3.new(0, -maxDistance, 0),
                    raycastParams
                )
                if downResult then
                    return downResult.Position.Y
                end
            
                local upResult = workspace:Raycast(
                    cubePos - Vector3.new(0, maxDistance/2, 0),
                    Vector3.new(0, maxDistance, 0),
                    raycastParams
                )
                if upResult then
                    return upResult.Position.Y
                end
            
                return cubePos.Y
            end

            function PlaceUnits()
                wait(0.5)
                if not getgenv().SmartAutoplay.Autoplace then
                    return
                end
            
                if #getgenv().SmartAutoplay.EquippedUnits <= 0 then
                    print("Warning: EquippedUnits is empty. Aborting PlaceUnits function.")
                    return
                end
            
                -- check if Tower‑Limit challenge is active
                local isTowerLimit = (getgenv().MapMode == "Portal" or getgenv().MapMode == "Challenge")
                                 and game:GetService("ReplicatedStorage").Challenge.Value == "Tower Limit"
            
                --print(isTowerLimit and "Debug ▶ Tower Limit challenge active." or "Debug ▶ No Tower Limit challenge.")
                
                -- sort placements and units (unchanged)
                table.sort(globalPlacements, function(a, b)
                    local aNum = tonumber(a.Name:match("Placement_(%d+)")) or 0
                    local bNum = tonumber(b.Name:match("Placement_(%d+)")) or 0
                    return aNum < bNum
                end)
            
                local sortedUnitList, farmUnits, nonfarmUnits = {}, {}, {}
                local farmUnitNames = {
                    ["Idol"] = true, ["Idol (Pop-Star!)"] = true,
                    ["Businessman Yojin"] = true,
                    ["Demon Child"] = true, ["Demon Child (Unleashed)"] = true,
                    ["Best Waifu"] = true, ["Speedcart"] = true,
                }
            
                for _, entry in ipairs(getgenv().SmartAutoplay.EquippedUnits) do
                    if farmUnitNames[entry.TrueName] then
                        table.insert(farmUnits, entry)
                    else
                        table.insert(nonfarmUnits, entry)
                    end
                end
            
                table.sort(farmUnits,    function(a, b) return a.InitCost    < b.InitCost    end)
                table.sort(nonfarmUnits, function(a, b) return a.InitCost    < b.InitCost    end)
            
                if Toggles.Autoplay_PlaceFocusFarm.Value then
                    for _, u in ipairs(farmUnits)    do table.insert(sortedUnitList, u) end
                    for _, u in ipairs(nonfarmUnits) do table.insert(sortedUnitList, u) end
                else
                    local allUnits = {}
                    for _, u in ipairs(farmUnits)    do table.insert(allUnits, u) end
                    for _, u in ipairs(nonfarmUnits) do table.insert(allUnits, u) end
                    table.sort(allUnits, function(a, b) return a.InitCost < b.InitCost end)
                    sortedUnitList = allUnits
                end
            
                local placedCounts = {}
                for _, entry in ipairs(sortedUnitList) do
                    placedCounts[entry.UnitID] = 0
                end
            
                local allEligiblePlaced = false
                repeat
                    -- refresh placedCounts
                    for _, entry in ipairs(sortedUnitList) do
                        placedCounts[entry.UnitID] = CurrentPlace(entry.UnitID)
                    end
            
                    -- placement attempts
                    for _, entry in ipairs(sortedUnitList) do
                        local requiredWave = Options["SmartPlay_PlaceWave_Unit" .. entry.Slot].Value
                        local capSlider    = Options["SmartPlay_PlaceCap_Unit"   .. entry.Slot].Value
                        local effectiveCap = math.min(entry.MaxPlacement, capSlider)
            
                        if getgenv().MapWave >= requiredWave then
                            -- enforce tower limit before any placement
                            if isTowerLimit then
                                local towerCount = 0
                                local towerFolder = workspace:FindFirstChild("Towers")
                                if towerFolder then
                                    for _, tower in ipairs(towerFolder:GetChildren()) do
                                        local owner = tower:FindFirstChild("Owner")
                                        if owner and tostring(owner.Value) == game.Players.LocalPlayer.Name then
                                            towerCount = towerCount + 1
                                        end
                                    end
                                end
                                if towerCount >= 5 then
                                    -- clear remainingUnits below by setting flag
                                    allEligiblePlaced = true
                                    break
                                end
                            end
            
                            while getgenv().SmartAutoplay.Autoplace and placedCounts[entry.UnitID] < effectiveCap do
                                wait(0.1)
                                if not getgenv().SmartAutoplay.Autoplace then
                                    return
                                end
            
                                local cube = NotPlacedCube()
                                if cube and Player_Cash >= entry.InitCost then
                                    -- compute placeCFrame as before…
                                    local floorY = findFloorY(cube.Position, 100)
                                    local template   = game.ReplicatedStorage.Units[entry.UnitName]
                                    local modelClone = template:Clone()
                                    -- compute height, halfHeight…
                                    local partsToCheck = {
                                        "Head","HumanoidRootPart",
                                        "Left Arm","Right Arm",
                                        "Left Leg","Right Leg",
                                        "Torso",
                                    }
                                    local minY, maxY
                                    for _, partName in ipairs(partsToCheck) do
                                        local part = modelClone:FindFirstChild(partName, true)
                                        if part and part:IsA("BasePart") then
                                            local topY = part.Position.Y + part.Size.Y/2
                                            local botY = part.Position.Y - part.Size.Y/2
                                            minY = minY and math.min(minY, botY) or botY
                                            maxY = maxY and math.max(maxY, topY) or topY
                                        end
                                    end
                                    modelClone:Destroy()
                                    local halfHeight = ((maxY and minY) and (maxY - minY) or modelClone:GetBoundingBox())/2 + 0.25
                                    local placeCFrame = CFrame.new(cube.Position.X, floorY + halfHeight, cube.Position.Z)
            
                                    for attempt = 1, 2 do
                                        Locals.ReplicatedStorage.Remotes.PlaceTower:FireServer(entry.UnitName, placeCFrame)
                                        wait(0.5)
                                        if Locals.isPlacedAt(placeCFrame.Position, entry.UnitName) then
                                            placedCounts[entry.UnitID] = placedCounts[entry.UnitID] + 1
                                            cube.Color = Color3.fromRGB(255, 0, 0)
                                            break
                                        else
                                            cube.Color = Color3.fromRGB(255, 255, 0)
                                        end
                                    end
                                else
                                    wait(0.2)
                                end
                            end
                        end
                    end
            
                    -- build remainingUnits
                    local remainingUnits = {}
                    for _, entry in ipairs(sortedUnitList) do
                        local requiredWave = Options["SmartPlay_PlaceWave_Unit" .. entry.Slot].Value
                        local capSlider    = Options["SmartPlay_PlaceCap_Unit" .. entry.Slot].Value
                        local effectiveCap = math.min(entry.MaxPlacement, capSlider)
                        if placedCounts[entry.UnitID] < effectiveCap then
                            table.insert(remainingUnits, entry)
                        end
                    end
            
                    -- if tower limit hit during the loop, clear out remainingUnits
                    if allEligiblePlaced and isTowerLimit then
                        remainingUnits = {}
                    end
            
                    if #remainingUnits > 0 then
                        wait(2)
                    else
                        allEligiblePlaced = true
                    end
                until allEligiblePlaced
            
                getgenv().SmartAutoplay.FinishedPlacing = true
                spawn(AutoUpgradeUnits)
            
                spawn(function()
                    while true do
                        wait(2)
                
                        -- === new: tower‑limit guard ===
                        if (getgenv().MapMode == "Portal" or getgenv().MapMode == "Challenge") 
                        and game:GetService("ReplicatedStorage").Challenge.Value == "Tower Limit" then
                            local towerCount = 0
                            local tf = workspace:FindFirstChild("Towers")
                            if tf then
                                for _, t in ipairs(tf:GetChildren()) do
                                    local owner = t:FindFirstChild("Owner")
                                    if owner and owner.Value == game.Players.LocalPlayer.UserId then
                                        towerCount = towerCount + 1
                                    end
                                end
                            end
                            if towerCount >= 5 then
                                --print("Debug ▶ Tower Limit watcher sees 5 towers—stopping PlaceUnits re‑trigger.")
                                return
                            end
                        end
                        -- === end tower‑limit guard ===
                
                        for _, entry in ipairs(sortedUnitList) do
                            local requiredWave = Options["SmartPlay_PlaceWave_Unit" .. entry.Slot].Value
                            if getgenv().MapWave >= requiredWave then
                                local capSlider    = Options["SmartPlay_PlaceCap_Unit" .. entry.Slot].Value
                                local effectiveCap = math.min(entry.MaxPlacement, capSlider)
                                if CurrentPlace(entry.UnitID) < effectiveCap then
                                    getgenv().SmartAutoplay.FinishedPlacing = false
                                    spawn(PlaceUnits)
                                    return
                                end
                            end
                        end
                    end
                end)
            end               
            
            function PlaceUnitsManual()
                wait(0.5)
                if not getgenv().SmartAutoplay.Autoplace then return end
            
                local units = getgenv().SmartAutoplay.EquippedUnits
                if #units == 0 then return end
            
                -- detect Tower‑Limit challenge
                local isTowerLimit = (getgenv().MapMode == "Portal" or getgenv().MapMode == "Challenge")
                                  and game:GetService("ReplicatedStorage").Challenge.Value == "Tower Limit"
            
                -- count existing towers if needed
                local initialTowerCount = 0
                if isTowerLimit then
                    local tf = workspace:FindFirstChild("Towers")
                    if tf then
                        for _, t in ipairs(tf:GetChildren()) do
                            local owner = t:FindFirstChild("Owner")
                            if owner and tostring(owner.Value) == game.Players.LocalPlayer.Name then
                                initialTowerCount += 1
                            end
                        end
                    end
                end
            
                -- prepare sorted unit list
                local farmUnits, nonfarmUnits = {}, {}
                local farmNames = {
                    Idol=true, ["Idol (Pop-Star!)"]=true,
                    ["Businessman Yojin"]=true,
                    ["Demon Child"]=true, ["Demon Child (Unleashed)"]=true,
                    ["Best Waifu"]=true, Speedcart=true,
                }
                for _, u in ipairs(units) do
                    if farmNames[u.TrueName] then
                        table.insert(farmUnits, u)
                    else
                        table.insert(nonfarmUnits, u)
                    end
                end
                table.sort(farmUnits,    function(a,b) return a.InitCost < b.InitCost end)
                table.sort(nonfarmUnits, function(a,b) return a.InitCost < b.InitCost end)
            
                local sortedUnitList = {}
                if Toggles.Autoplay_PlaceFocusFarm.Value then
                    for _, u in ipairs(farmUnits)    do table.insert(sortedUnitList, u) end
                    for _, u in ipairs(nonfarmUnits) do table.insert(sortedUnitList, u) end
                else
                    local all = {}
                    for _, u in ipairs(farmUnits)    do table.insert(all, u) end
                    for _, u in ipairs(nonfarmUnits) do table.insert(all, u) end
                    table.sort(all, function(a,b) return a.InitCost < b.InitCost end)
                    sortedUnitList = all
                end
            
                -- track how many of each UnitID have been placed
                local placedCounts = {}
                for _, e in ipairs(sortedUnitList) do
                    placedCounts[e.UnitID] = CurrentPlace(e.UnitID)
                end
            
                -- map displayName → pillar
                local pillarMap = {}
                for _, dat in pairs(ManualMarkers) do
                    local lbl = dat.gui:FindFirstChildWhichIsA("TextLabel")
                    if lbl and lbl.Text ~= "" then
                        pillarMap[lbl.Text] = dat.pillar
                    end
                end
            
                -- track new towers placed this run
                local newPlacedTotal = 0
            
                -- place each unit at its matching pillar
                for _, entry in ipairs(sortedUnitList) do
                    local disp   = UnitNames[entry.TrueName] or entry.TrueName
                    local pillar = pillarMap[disp]
                    if pillar then
                        local center       = pillar.Position
                        local capVal       = Options["SmartPlay_PlaceCap_Unit"..entry.Slot].Value
                        local effectiveCap = math.min(entry.MaxPlacement, capVal)
                        local offsets      = getPatternOffsets(effectiveCap, 2.5)
            
                        for _, off in ipairs(offsets) do
                            -- enforce Tower Limit
                            if isTowerLimit and (initialTowerCount + newPlacedTotal) >= 5 then
                                getgenv().SmartAutoplay.FinishedPlacing = true
                                spawn(AutoUpgradeUnits)
                                return
                            end
            
                            if placedCounts[entry.UnitID] >= effectiveCap then break end
                            if not getgenv().SmartAutoplay.Autoplace then return end
            
                            -- wait for enough cash
                            local cost = entry.InitCost
                            while Player_Cash < cost do
                                wait(0.5)
                                if not getgenv().SmartAutoplay.Autoplace then return end
                            end
            
                            wait(0.1)
            
                            -- raycast down with blacklist
                            local origin = center + off + Vector3.new(0,50,0)
                            local params = RaycastParams.new()
                            params.FilterType = Enum.RaycastFilterType.Blacklist
                            params.FilterDescendantsInstances = {
                                game.Players.LocalPlayer.Character,
                                workspace:FindFirstChild("Towers"),
                                workspace:FindFirstChild("Placements_Container"),
                                workspace:FindFirstChild("Enemies"),
                            }
                            local hit    = workspace:Raycast(origin, Vector3.new(0,-100,0), params)
                            local floorY = hit and hit.Position.Y or (center.Y + 1)
            
                            -- compute model half‑height
                            local clone = game.ReplicatedStorage.Units[entry.UnitName]:Clone()
                            local minY, maxY
                            for _, pn in ipairs({"Head","HumanoidRootPart","Left Arm","Right Arm","Left Leg","Right Leg","Torso"}) do
                                local p = clone:FindFirstChild(pn, true)
                                if p and p:IsA("BasePart") then
                                    local top = p.Position.Y + p.Size.Y/2
                                    local bot = p.Position.Y - p.Size.Y/2
                                    minY = minY and math.min(minY, bot) or bot
                                    maxY = maxY and math.max(maxY, top) or top
                                end
                            end
                            clone:Destroy()
                            local halfH = ((maxY and minY) and (maxY-minY) or 2)/2 + 0.25
            
                            local placeCFrame = CFrame.new(
                                center.X + off.X,
                                floorY + halfH,
                                center.Z + off.Z
                            )
            
                            Locals.ReplicatedStorage.Remotes.PlaceTower:FireServer(entry.UnitName, placeCFrame)
                            wait(0.5)
            
                            if Locals.isPlacedAt(placeCFrame.Position, entry.UnitName) then
                                placedCounts[entry.UnitID] = placedCounts[entry.UnitID] + 1
                                newPlacedTotal += 1
                            end
                        end
                    end
                end
            
                getgenv().SmartAutoplay.FinishedPlacing = true
                spawn(AutoUpgradeUnits)
            
                -- watcher: re‑trigger if more units are needed (and respect tower limit)
                spawn(function()
                    while true do
                        wait(2)
                        if isTowerLimit and (initialTowerCount + newPlacedTotal) >= 5 then
                            return
                        end
                        for _, entry in ipairs(sortedUnitList) do
                            local reqWave    = Options["SmartPlay_PlaceWave_Unit"..entry.Slot].Value
                            if getgenv().MapWave >= reqWave then
                                local capVal       = Options["SmartPlay_PlaceCap_Unit"..entry.Slot].Value
                                local effectiveCap = math.min(entry.MaxPlacement, capVal)
                                if CurrentPlace(entry.UnitID) < effectiveCap then
                                    getgenv().SmartAutoplay.FinishedPlacing = false
                                    spawn(PlaceUnitsManual)
                                    return
                                end
                            end
                        end
                    end
                end)
            end

            function AutoUpgradeUnits()
                spawn(function()
                    while Toggles.Autoplay_Upgrade.Value do

                        if not getgenv().SmartAutoplay.FinishedPlacing then
                            --rconsoleprint("[AutoUpgrade] Remaining units not fully placed. Re-triggering PlaceUnits() for remaining units.")
                            break
                        end

                        --print("[AutoUpgrade] Toggle is ON, beginning loop iteration.")
                        if not getgenv().SmartAutoplay then
                            --print("[AutoUpgrade] Warning: getgenv().SmartAutoplay is nil!")
                        elseif not getgenv().SmartAutoplay.FinishedPlacing then
                            --print("[AutoUpgrade] Waiting: FinishedPlacing is false.")
                        end
            
                        if getgenv().SmartAutoplay and getgenv().SmartAutoplay.FinishedPlacing and Toggles.Autoplay_Upgrade.Value then
                            --print("[AutoUpgrade] Conditions met: Running upgrade checks.")
                            local towers = workspace.Towers:GetChildren()
                            --print(string.format("[AutoUpgrade] Found %d towers in workspace.Towers.", #towers))
                            
                            for _, tower in ipairs(towers) do
                                local owner = tower:FindFirstChild("Owner")
                                local unitIDObj = tower:FindFirstChild("UnitID")
                                local upgradeVal = tower:FindFirstChild("Upgrade")
                                
                                if not owner then
                                    --print("[AutoUpgrade] Tower " .. tower.Name .. " missing 'Owner' object.")
                                end
                                if not unitIDObj then
                                    --print("[AutoUpgrade] Tower " .. tower.Name .. " missing 'UnitID' object.")
                                end
                                if not upgradeVal then
                                    --print("[AutoUpgrade] Tower " .. tower.Name .. " missing 'Upgrade' object.")
                                end
                                
                                if owner and unitIDObj and upgradeVal then
                                    local clientName = tostring(Locals.Client.Name)
                                    local ownerName = tostring(owner.Value)
                                    local Player_Cash = Locals.Client.Cash.Value
                                    
                                    if ownerName ~= clientName then
                                        --print("[AutoUpgrade] Tower " .. tower.Name .. " is NOT owned by " .. clientName .. " (Owner: " .. ownerName .. ").")
                                    else
                                        --print("[AutoUpgrade] Tower " .. tower.Name .. " IS owned by " .. clientName .. ". UnitID: " .. tostring(unitIDObj.Value) .. ", Current Upgrade Level: " .. tostring(upgradeVal.Value))
                                        
                                        local upgraded = false
                                        local nextUpgradeIndex = upgradeVal.Value + 1
                                        
                                        local eqUnit = FindEquippedUnitByID(unitIDObj.Value)
                                        if eqUnit and eqUnit.UpgradeCosts then
                                            local nextCost = eqUnit.UpgradeCosts[nextUpgradeIndex]
                                            if nextCost then
                                                --print(string.format("[AutoUpgrade] (EquippedUnits) Tower %s: NextUpgradeIndex=%d, NextCost=%d, Player_Cash=%d",
                                                --    tower.Name, nextUpgradeIndex, nextCost, Player_Cash))
                                                if Player_Cash >= nextCost then
                                                    --print(string.format("[AutoUpgrade] (EquippedUnits) Upgrading %s (UnitID=%s) from level %d to %d. Cost: %d",
                                                    --    tower.Name, tostring(unitIDObj.Value), upgradeVal.Value, nextUpgradeIndex, nextCost))
                                                    Locals.ReplicatedStorage.Remotes.Upgrade:InvokeServer(tower)
                                                    upgraded = true
                                                    wait(0.1)
                                                else
                                                    --print("[AutoUpgrade] (EquippedUnits) Insufficient cash for tower " .. tower.Name .. ". Needed: " .. nextCost .. ", Current Cash: " .. Player_Cash)
                                                end
                                            else
                                                --print("[AutoUpgrade] (EquippedUnits) Tower " .. tower.Name .. " has no next upgrade cost for upgrade level " .. nextUpgradeIndex)
                                            end
                                        else
                                            --print("[AutoUpgrade] No equipped unit data found for UnitID " .. tostring(unitIDObj.Value) .. " in tower " .. tower.Name)
                                        end
                                        
                                        if not upgraded then
                                            local mockTowerInfo = require(game:GetService("ReplicatedStorage").FusionPackage.Dependencies.Mock.MockTowerInfo)
                                            local moduleUnitData = mockTowerInfo[tower.Name]
                                            if moduleUnitData and type(moduleUnitData) == "table" then
                                                local currentUpgrade = upgradeVal.Value
                                                local cheapestUpgradeIndex, cheapestCost = nil, math.huge

                                                for key, upgradeData in pairs(moduleUnitData) do
                                                    if type(key) == "number" and key > currentUpgrade and upgradeData.Cost then
                                                        if upgradeData.Cost < cheapestCost then
                                                            cheapestUpgradeIndex = key
                                                            cheapestCost = upgradeData.Cost
                                                        end
                                                    end
                                                end

                                                if cheapestUpgradeIndex and cheapestCost < math.huge then
                                                    --print(string.format("[AutoUpgrade] (ModuleData) Tower %s: Cheapest Upgrade Found at index=%d with Cost=%d, Player_Cash=%d",
                                                    --    tower.Name, cheapestUpgradeIndex, cheapestCost, Player_Cash))
                                                    if Player_Cash >= cheapestCost then
                                                        --print(string.format("[AutoUpgrade] (ModuleData) Upgrading %s (Unit Name: %s) from level %d to %d. Cost: %d",
                                                        --    tower.Name, tower.Name, upgradeVal.Value, cheapestUpgradeIndex, cheapestCost))
                                                        Locals.ReplicatedStorage.Remotes.Upgrade:InvokeServer(tower)
                                                        upgraded = true
                                                        wait(0.1)
                                                    else
                                                        --print("[AutoUpgrade] (ModuleData) Insufficient cash for tower " .. tower.Name .. ". Needed: " .. cheapestCost .. ", Current Cash: " .. Player_Cash)
                                                    end
                                                else
                                                    --print("[AutoUpgrade] No valid upgrade data (with cost) found for tower " .. tower.Name .. " after current level " .. currentUpgrade)
                                                end
                                            else
                                                --print("[AutoUpgrade] No module data found for tower " .. tower.Name)
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            --print(string.format("[AutoUpgrade] Conditions not met. SmartAutoplay: %s, FinishedPlacing: %s, Autoplay_Upgrade Toggle: %s",
                            --    tostring(getgenv().SmartAutoplay),
                            --    (getgenv().SmartAutoplay and tostring(getgenv().SmartAutoplay.FinishedPlacing)) or "nil",
                            --    tostring(Toggles.Autoplay_Upgrade.Value)))
                        end                        
                        wait(0.5)
                    end
                    
                    --print("[AutoUpgrade] Stopped")
                end)
            end
            
        --#endregion
        
        Toggles.Autoplay_Enable:OnChanged(function()
            if Toggles.Autoplay_Enable.Value then  
                if not Locals.IsAllowedPlace(12886143095, 18583778121) then
                    repeat wait() 
                        if not Toggles.Autoplay_Enable.Value then return end 
                    until game.ReplicatedStorage.PlayersReady.Value == true

                    --generateCubes()
                    if not Toggles.Autoplay_Enable.Value then 
                        return 
                    else
                        getgenv().SmartAutoplay.Autoplace = true
                        getgenv().MatchStartTime = os.time()
                        PlaceUnits()
                    end
                else
                    return
                end
            else
                getgenv().SmartAutoplay.Autoplace = false
            end
        end)

        Toggles.ManualPlacements_Play:OnChanged(function()
            if Toggles.ManualPlacements_Play.Value then
                if not Locals.IsAllowedPlace(12886143095, 18583778121) then
                    repeat wait() 
                        if not Toggles.ManualPlacements_Play.Value then return end 
                    until game.ReplicatedStorage.PlayersReady.Value == true

                    if not Toggles.ManualPlacements_Play.Value then 
                        return 
                    else
                        getgenv().SmartAutoplay.Autoplace = true
                        getgenv().MatchStartTime = os.time()
                        spawn(PlaceUnitsManual)
                    end
                end
            end
        end)

        Toggles.JoinTitan_BossRush:OnChanged(function()
            if Toggles.JoinTitan_BossRush.Value then 
                if Locals.IsAllowedPlace(12886143095, 18583778121) then
                    game:GetService("ReplicatedStorage").Remotes.Snej.StartBossRush:FireServer("The Wall")
                else
                    --Library:Notify({
                    --    Title       = "Error",
                    --    Description = "❌ You are not in a lobby!",
                    --    Time        = 5,
                    --    SoundId     = 8400918001,
                    --})
                end
            end
        end)

        Toggles.JoinGodly_BossRush:OnChanged(function()
            if Toggles.JoinGodly_BossRush.Value then 
                if Locals.IsAllowedPlace(12886143095, 18583778121) then
                    game:GetService("ReplicatedStorage").Remotes.Snej.StartBossRush:FireServer("Heavens Theatre")
                else
                    --Library:Notify({
                    --    Title       = "Error",
                    --    Description = "❌ You are not in a lobby!",
                    --    Time        = 5,
                    --    SoundId     = 8400918001,
                    --})
                end
            end
        end)

        function MonitorEndGame()
            local PlayerGui = Locals.Client:WaitForChild("PlayerGui")
            
            PlayerGui.ChildAdded:Connect(function(child)
                if child.Name == "Prompt" then
                    --print("Detected Prompt GUI. Activating its TextButton via simulated key press...")
                    task.spawn(function()
                        while child and child:IsDescendantOf(PlayerGui) do
                            -- The desired button is at Prompt.TextButton.TextButton
                            local container = child:FindFirstChild("TextButton")
                            if container then
                                local targetButton = container:FindFirstChild("TextButton")
                                if targetButton and targetButton:IsA("TextButton") then
                                    --if Settings.Main["Auto Rewards Screen"] then
                                    Locals.ActivatePromptButton(targetButton)
                                    --end
                                else
                                    --warn("Prompt.TextButton.TextButton not found!")
                                end
                            else
                                --warn("Prompt.TextButton container not found!")
                            end 
                            task.wait(0.1)
                        end
                        Locals.GuiService.SelectedObject = nil
                    end)
                elseif child.Name == "EndGameUI" then
                    -- wait for any prompt to close
                    NewPlayerData = game:GetService("ReplicatedStorage").Remotes.GetPlayerData:InvokeServer()
                    repeat wait() until not Locals.PlayerGui:FindFirstChild("Prompt")

                    task.spawn(function()
                        --#region Client Info
                            local uid      = Locals.Client.UserId
                            local userUrl  = "https://www.roblox.com/users/"..uid
                            local thumbRes = Locals.HttpRequest({Url = ("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=420x420&format=Png&isCircular=false"):format(uid), Method="GET"})
                            local thumbUrl = (pcall(function() return Locals.HttpService:JSONDecode(thumbRes.Body).data[1].imageUrl end) and thumbRes and thumbRes.Body) and Locals.HttpService:JSONDecode(thumbRes.Body).data[1].imageUrl or ""

                            local level        = NewPlayerData.Level or 0
                            local currentXP    = NewPlayerData.EXP or 0
                            local xpForNext    = NewPlayerData.MaxEXP or 0

                            local descText = string.format(
                                "**User**: ||[%s(@%s)](%s)||\n" ..
                                "**Level**: %d [%d/%d]",
                                Locals.Client.DisplayName,
                                Locals.Client.Name,
                                userUrl,
                                level,
                                currentXP,
                                xpForNext
                            )
                        --#endregion

                        --#region Client Stats Info
                            local statEmotes = {
                                Emeralds         = "<:emerald:1347254552914825320>",
                                Gold             = "<:gold:1347254327399546992>",
                                Rerolls          = "<:reroll:1347254330604126319>",
                                Jewels           = "<:jewel:1347254547118161970>",
                                SkinTickets      = "<:ticket:1347254307057041440>",
                                RaidTokens       = "<:raid:1347254305626787863>",
                                BossRushTokens   = "<:godlyrush:1362420836853616660>",
                                TitanRushTokens  = "<:titanrush:1362420838183211291>",
                            }

                            local statsLines = {}
                            for key, emoji in pairs(statEmotes) do
                                local val = NewPlayerData[key]
                                if val ~= nil then
                                    local formatted = Locals.formatCommas(val)
                                    table.insert(statsLines, ("%s %s"):format(emoji, formatted))
                                end
                            end
                            local statsField = table.concat(statsLines, "\n")
                        --#endregion

                        --#region Unit Info
                            local unitLines = {}
                            for _, u in pairs(NewPlayerData.UnitData) do
                                if u.Equipped then
                                    local lvl   = u.Level or 0
                                    local name  = u.UnitName or "Unknown"
                                    local kills = u.Kills or 0
                                    local worth = u.Worthiness or 0
                                    local pct   = math.min(math.floor(worth / 75), 100)
                                    table.insert(unitLines, 
                                        string.format(
                                            "[%d] %s = %d%%",
                                            lvl, name, pct
                                        )
                                    )
                                end
                            end

                            local unitsFieldValue = #unitLines > 0
                                and table.concat(unitLines, "\n")
                                or "No equipped units"
                        --#endregion

                        --#region Reward Info
                            local rewards = {}
                            local holder
                            repeat
                                holder = Locals.PlayerGui:FindFirstChild("EndGameUI",true)
                                holder = holder and holder:FindFirstChild("BG",true)
                                holder = holder and holder:FindFirstChild("Container",true)
                                holder = holder and holder:FindFirstChild("Rewards",true)
                                holder = holder and holder:FindFirstChild("Holder",true)
                                if not holder then task.wait(0.1) end
                            until holder

                            local lastCount = 0
                            local stableFor = 0
                            while stableFor < 0.3 do
                                local count = #holder:GetChildren()
                                if count == lastCount then
                                    stableFor = stableFor + 0.1
                                else
                                    lastCount  = count
                                    stableFor  = 0
                                end
                                task.wait(0.1)
                            end

                            for _, btn in ipairs(holder:GetChildren()) do
                                if not btn:IsA("TextButton") then continue end
                            
                                local itemName, amount, unitName, portalName, portalTier
                            
                                for _, lbl in ipairs(btn:GetChildren()) do
                                    if not lbl:IsA("TextLabel") then continue end
                            
                                    if lbl.Name == "UnitName" then
                                        unitName = lbl.Text
                            
                                    elseif lbl.Name == "PortalName" then
                                        portalName = lbl.Text .. " Portal"
                            
                                    elseif lbl.Name == "PortalTier" then
                                        portalTier = lbl.Text
                            
                                    elseif lbl.Name == "Amount" then
                                        amount = tonumber(lbl.Text:match("(%d+)")) or amount
                            
                                    elseif lbl.Name == "ItemName" then
                                        itemName = lbl.Text
                            
                                    elseif lbl.Name ~= "Cost" and lbl.Name ~= "Level" then
                                        warn("Extra label in", btn.Name, "→", lbl.Name, lbl.Text)
                                    end
                                end
                            
                                if unitName then
                                    table.insert(rewards, string.format("+1 %s [%s]", unitName, btn.Name))
                            
                                elseif portalName and portalTier then
                                    table.insert(rewards, string.format("+1 %s [%s]", portalName, portalTier))
                            
                                elseif itemName and amount then
                                    table.insert(rewards, { Name = itemName, Amount = amount })
                            
                                else
                                    warn("Missing Name/Amount/UnitName/PortalName for", btn.Name)
                                end
                            end
                        --#endregion

                        --#region Match Result Info
                            local EmbedColor = 0x42F593
                            local stats = Locals.PlayerGui:FindFirstChild("EndGameUI", true) and Locals.PlayerGui.EndGameUI.BG.Container.Stats
                            local res = "UNKNOWN"

                            for _, lbl in ipairs(stats and stats:GetDescendants() or {}) do
                                --if lbl:IsA("TextLabel") then warn(lbl.Text) end
                                if lbl:IsA("TextLabel") and (lbl.Text=="Win" or lbl.Text=="Defeat" or lbl.Text=="Portal Cleared!") then
                                    if lbl.Text=="Win" or lbl.Text=="Portal Cleared!" then
                                        res = "Victory"
                                        EmbedColor = 0x42F593
                                    elseif lbl.Text=="Defeat" then
                                        res = "Defeat"
                                        EmbedColor = 0xFD4036
                                    else 
                                        EmbedColor = 0xA1A1A1
                                    end
                                    break
                                end
                            end

                            local elapsed = os.time() - getgenv().MatchStartTime
                            local h = math.floor(elapsed/3600)
                            local m = math.floor((elapsed%3600)/60)
                            local s = elapsed%60

                            local mr = string.format("%s: %s [%s] - %s\n%02d:%02d:%02d - Wave %d",
                            getgenv().MapMode, getgenv().MapName, getgenv().MapDifficulty, res, h, m, s, getgenv().MapWave or 0
                            )
                        --#endregion

                        --if #rewards > 0 then
                            local content = ""
                            local webhookUrl = Options.Webhook_Link.Value or ""
                            local DiscordID = Options.Discord_ID.Value or ""

                            local isValidWebhook = type(webhookUrl) == "string"
                                and webhookUrl:match("^https://discord%.com/api/webhooks/") ~= nil
                            
                            if DiscordID:match("^%d+$") and #DiscordID == 18 then
                                if Toggles.Ping_On_Mission_End.Value then
                                    content = "<@" .. DiscordID .. ">"
                                end
                            else
                                warn("Invalid Discord ID, no ping will be sent.")
                            end

                            if not isValidWebhook then
                                warn("Invalid webhook URL! It must start with: https://discord.com/api/webhooks/")
                            else
                                
                                local lines = {}
                                for _, r in ipairs(rewards) do
                                    if type(r) == "table" then
                                        lines[#lines+1] = ("+%d %s"):format(r.Amount, r.Name)
                                    elseif type(r) == "string" then
                                        lines[#lines+1] = r
                                    else
                                        warn("Unexpected reward type:", r)
                                    end
                                end

                                Locals.HttpRequest({
                                    Url     = Options.Webhook_Link.Value,
                                    Method  = "POST",
                                    Headers = {["Content-Type"]="application/json"},
                                    Body    = Locals.HttpService:JSONEncode({
                                        username   = "Akora Hub",
                                        avatar_url = "https://raw.githubusercontent.com/VeronicVR/Roblox/refs/heads/main/Scripts/Logo/Akora%20Hub%20Logo.png",
                                        content=content,
                                        embeds = {{
                                            title       = "Akora Hub 🐾 "..GameName,
                                            description = descText,
                                            color       = EmbedColor,
                                            fields      = {
                                                {name="Client Stats",  value=statsField~="" and statsField or "No data", inline=true},
                                                {name="Rewards",       value=table.concat(lines,"\n"), inline=true},
                                                {name="Units (Worthiness)",         value=unitsFieldValue, inline=false},
                                                {name="Match Results", value=mr, inline=false},
                                            },
                                            thumbnail   = {url=thumbUrl},
                                            footer      = {text="Powered by Akora Hub – Stay Pawsome!",icon_url="https://raw.githubusercontent.com/VeronicVR/Roblox/refs/heads/main/Scripts/Logo/Akora%20Hub%20Logo.png"},
                                            timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                                        }},
                                    }),
                                })
                            end
                        --end

                        local Buttons = child.BG and child.BG:FindFirstChild("Buttons")
                        if Buttons then
                            if (Toggles.AutoNext.Value == true or Toggles.PortalLaunch_Toggle.Value == true) and Buttons:FindFirstChild("Next") then
                                NewPlayerData = game:GetService("ReplicatedStorage").Remotes.GetPlayerData:InvokeServer()
                                if Toggles.PortalLaunch_Toggle.Value then
                                    local portals = NewPlayerData.PortalData or {}
                                    --print("Debug ▶ PortalLaunch starting. MapName =", getgenv().MapName)
                                                                    
                                    -- build + debug approved maps (handles both { [“Map”]=true } and {“Map”} forms)
                                    local approvedMaps = {}
                                    --print("Debug ▶ Selected Maps:")
                                    for k, v in pairs(Options.PortalLaunch_Maps.Value) do
                                        if type(k) == "number" and type(v) == "string" then
                                            approvedMaps[v] = true
                                            --print("  ▶", v)
                                        elseif type(k) == "string" and v == true then
                                            approvedMaps[k] = true
                                            --print("  ▶", k)
                                        end
                                    end
                                    
                                    -- build + debug approved challenges
                                    local approvedChallenges = {}
                                    --print("Debug ▶ Selected Challenges:")
                                    do
                                        local cval = Options.PortalLaunch_Challenge.Value
                                        if type(cval) == "table" then
                                            for k, v in pairs(cval) do
                                                if type(k) == "number" and type(v) == "string" then
                                                    approvedChallenges[v] = true
                                                    --print("  ▶", v)
                                                elseif type(k) == "string" and v == true then
                                                    approvedChallenges[k] = true
                                                    --print("  ▶", k)
                                                end
                                            end
                                        elseif type(cval) == "string" then
                                            approvedChallenges[cval] = true
                                            --print("  ▶", cval)
                                        end
                                    end
                                    
                                    -- build + debug allowed tiers
                                    local allowedTiers = {}
                                    --print("Debug ▶ Selected Tiers:")
                                    for k, v in pairs(Options.PortalLaunch_Tier.Value) do
                                        local tierStr
                                        if type(k) == "number" and type(v) == "string" then
                                            tierStr = v
                                        elseif type(k) == "string" and v == true then
                                            tierStr = k
                                        end
                                        if tierStr then
                                            local n = tonumber(tierStr:match("%d+"))
                                            if n then
                                                allowedTiers[n] = true
                                                --print("  ▶ Tier", n)
                                            end
                                        end
                                    end
                                    
                                    -- now filter portals
                                    local candidates = {}
                                    for uid, entry in pairs(portals) do
                                        local pd = entry.PortalData
                                        if not pd then
                                            --print("Debug ▶ Skipping", uid, "- no PortalData")
                                        else
                                            local tierNum = tonumber(pd.Tier) or 0
                                            --print(("Debug ▶ Checking portal %s | Map=%s | Challenge=%s | Tier=%d")
                                            --    :format(uid, pd.Map, pd.Challenges, tierNum))
                                        
                                            local okMap   = approvedMaps[pd.Map]
                                            local okChal  = approvedChallenges[pd.Challenges]
                                            local okTier  = allowedTiers[tierNum]
                                        
                                            --print(("         Map OK? %s  Challenge OK? %s  Tier OK? %s")
                                            --    :format(tostring(okMap), tostring(okChal), tostring(okTier)))
                                        
                                            if okMap and okChal and okTier then
                                                table.insert(candidates, {
                                                    uid    = uid,
                                                    name   = entry.PortalName or uid,
                                                    map    = pd.Map,
                                                    chal   = pd.Challenges,
                                                    tier   = tierNum,
                                                    rating = challengeRatings[pd.Challenges] or 0,
                                                })
                                                --print("  → Added as candidate")
                                            end
                                        end
                                    end
                                    
                                    -- sort + activate or report none
                                    if #candidates > 0 then
                                        table.sort(candidates, function(a, b)
                                            if a.tier ~= b.tier then
                                                return a.tier > b.tier
                                            else
                                                return a.rating > b.rating
                                            end
                                        end)
                                    
                                        --print("Debug ▶ Final sorted candidates:")
                                        for i, c in ipairs(candidates) do
                                            --print(("  %d) %s | Map=%s | Chal=%s | Tier=%d | Rating=%.1f")
                                            --    :format(i, c.uid, c.map, c.chal, c.tier, c.rating))
                                        end
                                    
                                        local best = candidates[1]
                                        --print(("Debug ▶ Activating portal %s (Tier %d, Challenge %s)")
                                        --    :format(best.uid, best.tier, best.chal))
                                        Locals.ReplicatedStorage.Remotes.Portals.Activate:InvokeServer(best.uid)
                                        Library:Notify({
                                            Title = "Success",
                                            Description = string.format(
                                                "Using %s portal (%s, Tier %d, Challenge %s)",
                                                best.name, best.uid, best.tier, best.chal
                                            ),
                                            Time = 5,
                                            SoundId = 7167887983
                                        })
                                    else
                                        Library:Notify({
                                            Title = "Error",
                                            Description = "No portal matched map/challenge/tier filters.",
                                            Time = 5,
                                            SoundId = 8400918001
                                        })
                                    end
                                else
                                    Locals.ActivatePromptButton(Buttons.Next)
                                end
                            elseif Toggles.AutoRetry.Value == true and Buttons:FindFirstChild("Retry") then
                                    Locals.ActivatePromptButton(Buttons.Retry)
                            elseif Toggles.AutoLeave.Value == true  and Buttons:FindFirstChild("Leave") then
                                Locals.ActivatePromptButton(Buttons.Leave)
                            end
                            getgenv().MatchStartTime = os.time()
                        end

                        task.wait(0.1)
                        --Locals.GuiService.SelectedObject = nil
                    end)

                    ResetPlaced()
                end
            end)
            
            PlayerGui.ChildRemoved:Connect(function(child)
                if child.Name == "EndGameUI" then
                    ResetPlaced()
                end
            end)
        end
        MonitorEndGame()


        local remotesFolder = Locals.ReplicatedStorage:FindFirstChild("Remotes")
        local CardAction = remotesFolder and remotesFolder:FindFirstChild("CardAction")

        -- priority list (1 = highest)
        local priorityOrder = {
            "Raging Power",
            "Feeding Madness",
            "Demon Takeover",
            "Insanity",
            "Venoshock",
            "Fortune",
            "Godspeed",
            "Metal Skin",
            "Emotional Damage",
            "Chaos Eater",
        }
        local priorityMap = {}
        for i, name in ipairs(priorityOrder) do
            priorityMap[name] = i
        end

        if not CardAction or not CardAction.OnClientEvent then
            return
        else
            CardAction.OnClientEvent:Connect(function(actionType, cardList, count, flag)
                -- only on the card‐selection phase
                if actionType ~= "StartSelection" then return end
                -- only if auto‐picker is enabled
                if not Toggles.AutoCardPicker.Value then return end
            
                -- grab the user’s dropdown selections (table keyed by name → true)
                local picks = Options.CardPickerSelector.Value
            
                local bestIdx, bestPrio
                for idx, card in ipairs(cardList or {}) do
                    local name = card.CardName
                    --print("Debug ▶ Saw card:", name)
            
                    if picks[name] then
                        local prio = priorityMap[name] or (#priorityOrder + 1)
                        --print(("Debug ▶ Candidate %q at idx %d has priority %d"):format(name, idx, prio))
            
                        if not bestPrio or prio < bestPrio then
                            bestPrio = prio
                            bestIdx  = idx
                        end
                    end
                end
            
                if bestIdx then
                    --print("Debug ▶ Auto‐picking card at index", bestIdx)
                    CardAction:FireServer(bestIdx)
                else
                    --print("Debug ▶ No user‐selected cards present; skipping pick.")
                end
            end)
        end

        local FireCannonRemote
        local remotesFolder

        -- helper: collect all cannon models under Workspace.Map.Map.Cannons
        local function getCannons()
            local cannons = {}
            local mapRoot = Locals.Workspace:FindFirstChild("Map")
                            and Locals.Workspace.Map:FindFirstChild("Map")
                            and Locals.Workspace.Map.Map
            local cannonsFolder = mapRoot and mapRoot:FindFirstChild("Cannons")
            if cannonsFolder then
                for _, child in ipairs(cannonsFolder:GetChildren()) do
                    if child.Name == "Model" and child.PrimaryPart then
                        table.insert(cannons, child)
                    end
                end
            end
            return cannons
        end

        -- spam loop control
        local spamming = false
        local function startCannonSpam()
            if spamming then return end
            if not FireCannonRemote then
                warn("FireCannon remote missing! Cannot spam.")
                return
            end
        
            spamming = true
            task.spawn(function()
                -- fire each cannon exactly once
                for _, cannon in ipairs(getCannons()) do
                    FireCannonRemote:FireServer(cannon)
                    task.wait(0.1)
                end
                -- done, allow future retriggers
                spamming = false
            end)
        end

        -- listen for the titan warning in the player's GUI
        Locals.PlayerGui.DescendantAdded:Connect(function(descendant)
            if   Toggles.Auto_Cannon_TitanRush.Value
            and descendant:IsA("TextLabel")
            and descendant.Text:find("The Colossal Titan is about to stun/destroy several units!")
            then
                realRemotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
                FireCannonRemote = realRemotes:WaitForChild("FireCannon")
                task.wait(0.1)
                startCannonSpam()
            end
        end)
    --#endregion
--#endregion

--#region Autoload Config
    SaveManager:LoadAutoloadConfig()
--#endregion