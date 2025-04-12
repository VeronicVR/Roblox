print([[     _    _                      _   _       _     ]])
print([[    / \  | | _____  _ __ __ _   | | | |_   _| |__  ]])
print([[   / _ \ | |/ / _ \| '__/ _` |  | |_| | | | | '_ \ ]])
print([[  / ___ \|   < (_) | | | (_| |  |  _  | |_| | |_) |]])
print([[ /_/   \_\_|\_\___/|_|  \__,_|  |_| |_|\__,_|_.__/ ]])
print([[                                                   ]])
print("Welcome, " .. game.Players.LocalPlayer.DisplayName .. " [ @" .. game.Players.LocalPlayer.Name .. " ]")

if not getgenv().AkoraHubExecuted then
    getgenv().AkoraHubExecuted = true

    local HttpService = game:GetService("HttpService")
    local Url = "https://raw.githubusercontent.com/VeronicVR/Roblox/refs/heads/main/Scripts/Index.json"

    local Success, Response = pcall(function()
        return game:HttpGet(Url)
    end)

    if Success then
        local Data = HttpService:JSONDecode(Response)
        local PlaceId = tostring(game.PlaceId)
        local ScriptUrl = nil

        if Data.Games then
            for _, gameEntry in pairs(Data.Games) do
                if typeof(gameEntry) == "table" then
                    for id, url in pairs(gameEntry) do
                        if typeof(id) == "string" and not id:match("^_") then
                            if id == PlaceId and url ~= "" then
                                ScriptUrl = url
                                break
                            end
                        end
                    end
                
                    if not ScriptUrl and gameEntry["default"] and gameEntry["default"] ~= "" then
                        ScriptUrl = gameEntry["default"]
                        break
                    end
                
                elseif typeof(gameEntry) == "string" and gameEntry ~= "" then
                    ScriptUrl = gameEntry
                    break
                end
            
                if ScriptUrl then break end
            end
        end

        if ScriptUrl and ScriptUrl ~= "" then
            print("Loading Script For Game ID:", PlaceId)
        
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
            warn("No Supported Script Found For This Game (PlaceId:", PlaceId, ")")
        end
    else
        warn("Failed To Fetch Game Script Index From:", Url)
    end
else
    warn("AkoraHub Already Executed. Please Restart The Game To Reload.") 
end