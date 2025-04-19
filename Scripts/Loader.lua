repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
                       and game.Players.LocalPlayer.Character
                       and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")

local queue_on_teleport = (syn and syn.queue_on_teleport)
                         or (fluxus and fluxus.queue_on_teleport)
                         or queue_on_teleport

if not getgenv().AkoraHubExecuted then
    getgenv().AkoraHubExecuted = true

    print([[     _    _                      _   _       _     ]])
    print([[    / \  | | _____  _ __ __ _   | | | |_   _| |__  ]])
    print([[   / _ \ | |/ / _ \| '__/ _` |  | |_| | | | | '_ \ ]])
    print([[  / ___ \|   < (_) | | | (_| |  |  _  | |_| | |_) |]])
    print([[ /_/   \_\_|\_\___/|_|  \__,_|  |_| |_|\__,_|_.__/ ]])
    print([[                                                   ]])
    print("Welcome, " .. game.Players.LocalPlayer.DisplayName
          .. " [ @" .. game.Players.LocalPlayer.Name .. " ]")

    if queue_on_teleport then
        queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/VeronicVR/Roblox/refs/heads/main/Scripts/Loader.lua'))()")
    end

    local HttpService        = game:GetService("HttpService")
    local MarketplaceService = game:GetService("MarketplaceService")
    local Url                = "https://raw.githubusercontent.com/VeronicVR/Roblox/refs/heads/main/Scripts/Index.json"

    local httpRequest = (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or request
    assert(typeof(httpRequest) == "function", "No HTTP request function available")

    local function getCommitCount(owner, repo, filePath, token)
        local rawPath     = filePath:gsub("%%20"," ")
        local encodedPath = rawPath:gsub(" ","%%20")
        local apiUrl = string.format(
            "https://api.github.com/repos/%s/%s/commits?sha=main&path=%s&per_page=1",
            owner, repo, encodedPath
        )
        local headers = {
            ["User-Agent"] = "Roblox-Lua",
            ["Accept"]     = "application/vnd.github.v3+json",
        }
        if token then headers["Authorization"] = "token "..token end

        local res = httpRequest({
            Url     = apiUrl,
            Method  = "GET",
            Headers = headers,
        })
        if not res or (res.StatusCode and res.StatusCode >= 400) then
            error(("GitHub API request failed (%s)"):format(tostring(res and res.StatusCode)))
        end

        local link = res.Headers and (res.Headers["Link"] or res.Headers["link"])
        if link then
            local lastUrl = link:match('<([^>]-)>;%s*rel="last"')
            if lastUrl then
                local page = lastUrl:match("[&?]page=(%d+)")
                return tonumber(page)
            end
        end

        local arr = HttpService:JSONDecode(res.Body or res.body or "[]")
        return type(arr)=="table" and #arr or 0
    end

    local ok, response = pcall(function()
        return game:HttpGet(Url)
    end)
    if not ok then
        warn("Failed To Fetch Game Script Index From:", Url)
        return
    end

    local Data    = HttpService:JSONDecode(response)
    local PlaceId = tostring(game.PlaceId)
    local ScriptUrl, CreatorName

    local infoOk, pi = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if infoOk and pi and pi.Creator and pi.Creator.Name then
        CreatorName = pi.Creator.Name
    end

    if Data.Games and CreatorName and Data.Games[CreatorName] then
        local ge = Data.Games[CreatorName]
        if ge[PlaceId] and ge[PlaceId] ~= "" then
            ScriptUrl = ge[PlaceId]
        elseif ge.default and ge.default ~= "" then
            ScriptUrl = ge.default
        end
    end

    if not ScriptUrl or ScriptUrl == "" then
        warn("No Supported Script For PlaceId:", PlaceId,
             "Creator:", CreatorName or "Unknown")
        return
    end

    do
        local owner, repo, filePath = ScriptUrl:match(
            "^https://raw%.githubusercontent%.com/([^/]+)/([^/]+)/refs/heads/[^/]+/(.+)$"
        )
        if owner and repo and filePath then
            local suc, commits = pcall(getCommitCount, owner, repo, filePath)
            if suc then
                local X = math.floor(commits/1000) + 1
                local rem = commits % 1000
                local Y = math.floor(rem/10)
                local Z = rem % 10
                getgenv().Version = string.format("Version %d.%d.%d", X, Y, Z)
                print("↪ Loading "..getgenv().Version)
            else
                --warn("Could not retrieve version number", commits)
            end
        else
            warn("ScriptUrl not in expected raw.githubusercontent format:", ScriptUrl)
        end
    end

    print("If you encounter any errors below this line, please report them to our Discord server.")
    local ok2, ScriptResponse = pcall(function()
        return game:HttpGet(ScriptUrl .. "?t=" .. tostring(tick()))
    end)
    if not ok2 then
        warn("Failed To Fetch Script From:", ScriptUrl)
        return
    end

    local loadOk, err = pcall(function()
    
        loadstring(ScriptResponse)()
    end)
    if not loadOk then
        warn("Error Executing Script:", err)
    end
end
