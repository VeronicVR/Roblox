local HttpService = game:GetService("HttpService")
local Url = "https://raw.githubusercontent.com/VeronicVR/Roblox/refs/heads/main/Index.json"

local Success, Response = pcall(function()
    return game:HttpGet(Url)
end)

if Success then
    local Data = HttpService:JSONDecode(Response)
    local PlaceId = tostring(game.PlaceId)
    local ScriptUrl = nil

    if Data.games then
        for _, creatorGames in pairs(Data.games) do
            if creatorGames[PlaceId] then
                ScriptUrl = creatorGames[PlaceId]
                break
            end
        end
    end

    if ScriptUrl then
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
