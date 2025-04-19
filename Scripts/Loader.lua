repeat task.wait() until game:IsLoaded()
repeat wait() until Game.Players.LocalPlayer and Game.Players.LocalPlayer.Character and Game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")

print([[     _    _                      _   _       _     ]])
print([[    / \  | | _____  _ __ __ _   | | | |_   _| |__  ]])
print([[   / _ \ | |/ / _ \| '__/ _` |  | |_| | | | | '_ \ ]])
print([[  / ___ \|   < (_) | | | (_| |  |  _  | |_| | |_) |]])
print([[ /_/   \_\_|\_\___/|_|  \__,_|  |_| |_|\__,_|_.__/ ]])
print([[                                                   ]])
print("Welcome, " .. game.Players.LocalPlayer.DisplayName .. " [ @" .. game.Players.LocalPlayer.Name .. " ]")
print("If you encounter any errors below this line, please report them to our Discord server.")

local queue_on_teleport = (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or queue_on_teleport
if not getgenv().AkoraHubExecuted then
    getgenv().AkoraHubExecuted = true

    if queue_on_teleport then
        queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/VeronicVR/Roblox/refs/heads/main/Scripts/Loader.lua'))()")
    end

    local HttpService = game:GetService("HttpService")
    local MarketplaceService = game:GetService("MarketplaceService")
    local Url = "https://raw.githubusercontent.com/VeronicVR/Roblox/refs/heads/main/Scripts/Index.json"

    local Success, Response = pcall(function()
        return game:HttpGet(Url)
    end)

    if Success then
        local Data = HttpService:JSONDecode(Response)
        local PlaceId = tostring(game.PlaceId)
        local ScriptUrl = nil
        local CreatorName = nil

        local infoSuccess, placeInfo = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)

        if infoSuccess and placeInfo and placeInfo.Creator and placeInfo.Creator.Name then
            CreatorName = placeInfo.Creator.Name
        end

        if Data.Games and CreatorName and Data.Games[CreatorName] then
            local gameEntry = Data.Games[CreatorName]

            if gameEntry[PlaceId] and gameEntry[PlaceId] ~= "" then
                ScriptUrl = gameEntry[PlaceId]
            elseif gameEntry["default"] and gameEntry["default"] ~= "" then
                ScriptUrl = gameEntry["default"]
            end
        end

        if ScriptUrl and ScriptUrl ~= "" then
            local ScriptSuccess, ScriptResponse = pcall(function()
                return game:HttpGet(ScriptUrl .. "?t=" .. tostring(tick()))
            end)

            if ScriptSuccess then
                local LoadSuccess, ErrorMsg = pcall(function()
                    loadstring(ScriptResponse)()
                end)

                if not LoadSuccess then
                    warn("Error Executing Script:", ErrorMsg)
                end
            else
                warn("Failed To Fetch Script From:", ScriptUrl)
            end
        else
            warn("No Supported Script Found For This Game (PlaceId:", PlaceId, ") or under creator:", CreatorName or "Unknown")
        end
    else
        warn("Failed To Fetch Game Script Index From:", Url)
    end
else
    warn("AkoraHub Already Executed. Please Restart The Game To Reload.") 
end