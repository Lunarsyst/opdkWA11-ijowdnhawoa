local Config = {
    -- Valid keys
    ValidKeys = {
        "aegis-staff-27Dbh8d",
        "shwagglite-279",
        "ifuguessthisugotit",
        "boy8989",
        "aegis-prem-10nFigR5",
    },

    BannedHWIDs = {
         ["D79CCECFF7319C9DE3F97FD81C0468"] = "test",
        -- ["a1b2c3d4-example-hwid"] = "Leaked script",
    },

    BannedUserIDs = {
        -- [USER_ID_HERE] = "reason",
        -- [123456789] = "Shared key publicly",
    },

    ScriptURL = "https://raw.githubusercontent.com/Lunarsyst/093812r809hjiHSDUOAF814r0/refs/heads/main/ccas.lua",

    WebhookURL = "https://discordapp.com/api/webhooks/1471589603361292348/QQxzy3LKLhrhEfNqIEu-bmlv4aNF6gyViiP-cM52bcQR6qGsz6zPRDnwqHaggK_By-VS",

    Webhook = {
        AcceptedColor = 3066993,
        DeclinedColor = 15158332,
        ErrorColor    = 15105570,
        BannedColor   = 10038562,

        FooterText    = "Aegis Loader",
        CensorKey     = true,
        LogDeclined   = true,
        LogErrors     = true,

        PingOnBanned  = "<@1023326249306816562>",
        PingOnAccept  = "",
        PingOnDecline = "",
    },

    Notifications = {
        Accepted = {
            Title    = "Aegis Loader",
            Message  = "Loading..",
            Duration = 5,
        },
        Declined = {
            Title    = "Aegis Loader",
            Message  = "Invalid key!",
            Duration = 5,
        },
        Loaded = {
            Title    = "Aegis Loader",
            Message  = "Script loaded..",
            Duration = 5,
        },
        Error = {
            Title    = "Aegis Loader",
            Message  = "Failed to load script, contact 1_aegis on discord.",
            Duration = 5,
        },
        NoKey = {
            Title    = "Aegis Loader",
            Message  = "No key provided!",
            Duration = 5,
        },
        Banned = {
            Title    = "Aegis Loader",
            Message  = "Banned, contact 1_aegis on discord for reason.",
            Duration = 10,
        },
    },

    ConsoleLogging = false,
}

-- ============================================
-- SERVICES
-- ============================================

local Players       = game:GetService("Players")
local HttpService   = game:GetService("HttpService")
local MarketPlace   = game:GetService("MarketplaceService")
local LocalPlayer   = Players.LocalPlayer

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function Log(msg)
    if Config.ConsoleLogging then
        print("[Aegis Loader] " .. msg)
    end
end

local function SendNotification(info)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = info.Title,
            Text     = info.Message,
            Duration = info.Duration or 5,
        })
    end)
end

local function IsKeyValid(key)
    if not key or type(key) ~= "string" then
        return false
    end
    for _, validKey in ipairs(Config.ValidKeys) do
        if key == validKey then
            return true
        end
    end
    return false
end

local function HttpPost(url, body, headers)
    local request = (syn and syn.request)
        or (http and http.request)
        or http_request
        or (fluxus and fluxus.request)
        or request

    if request then
        local success, response = pcall(request, {
            Url     = url,
            Method  = "POST",
            Headers = headers or { ["Content-Type"] = "application/json" },
            Body    = body,
        })
        return success, response
    else
        return false, "No request function"
    end
end

local function CensorKey(key)
    if not Config.Webhook.CensorKey then return key end
    if #key <= 6 then return string.rep("*", #key) end
    return key:sub(1, 3) .. string.rep("*", #key - 5) .. key:sub(-2)
end

local function GetExecutor()
    local name = "Unknown"
    pcall(function()
        if identifyexecutor then
            name = identifyexecutor()
        elseif getexecutorname then
            name = getexecutorname()
        end
    end)
    return name
end

local function GetHWID()
    local hwid = "Unavailable"
    pcall(function()
        if gethwid then
            hwid = gethwid()
        elseif getsystemhwid then
            hwid = getsystemhwid()
        end
    end)
    return hwid
end

local function GetGameName()
    local name = "Unknown"
    pcall(function()
        local info = MarketPlace:GetProductInfo(game.PlaceId)
        if info and info.Name then
            name = info.Name
        end
    end)
    return name
end

local function GetAvatarURL(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId="
        .. tostring(userId)
        .. "&width=420&height=420&format=png"
end

local function GetTimestamp()
    return os.date("!%Y/%m/%d %H:%M:%S UTC")
end

-- ============================================
-- BAN CHECK
-- ============================================

local function CheckBanned(hwid, userId)
    if Config.BannedHWIDs[hwid] then
        return true, Config.BannedHWIDs[hwid], "HWID Ban"
    end

    if Config.BannedUserIDs[userId] then
        return true, Config.BannedUserIDs[userId], "UserID Ban"
    end

    return false, nil, nil
end

-- ============================================
-- WEBHOOK
-- ============================================

local function SendWebhook(status, userKey, banReason, banSource)
    local userId      = LocalPlayer.UserId
    local username    = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName
    local avatarURL   = GetAvatarURL(userId)
    local profileURL  = "https://www.roblox.com/users/" .. tostring(userId) .. "/profile"
    local gameName    = GetGameName()
    local placeId     = tostring(game.PlaceId)
    local jobId       = tostring(game.JobId)
    local executor    = GetExecutor()
    local hwid        = GetHWID()
    local timestamp   = GetTimestamp()
    local censoredKey = CensorKey(tostring(userKey or "None"))

    local color, title, ping

    if status == "accepted" then
        color = Config.Webhook.AcceptedColor
        title = "Script Executed - Key Accepted"
        ping  = Config.Webhook.PingOnAccept
    elseif status == "declined" then
        color = Config.Webhook.DeclinedColor
        title = "Execution Denied - Invalid Key"
        ping  = Config.Webhook.PingOnDecline
    elseif status == "error" then
        color = Config.Webhook.ErrorColor
        title = "Execution Error"
        ping  = ""
    elseif status == "nokey" then
        color = Config.Webhook.DeclinedColor
        title = "No Key Provided"
        ping  = Config.Webhook.PingOnDecline
    elseif status == "banned" then
        color = Config.Webhook.BannedColor
        title = "BANNED USER ATTEMPTED EXECUTION"
        ping  = Config.Webhook.PingOnBanned
    end

    local fields = {
        {
            name   = "Player Info",
            value  = "```"
                .. "\nUsername:     " .. username
                .. "\nDisplay:     " .. displayName
                .. "\nUser ID:     " .. tostring(userId)
                .. "\n```",
            inline = false,
        },
        {
            name   = "Game Info",
            value  = "```"
                .. "\nGame:        " .. gameName
                .. "\nPlace ID:    " .. placeId
                .. "\nJob ID:      " .. jobId
                .. "\n```",
            inline = false,
        },
        {
            name   = "Key Info",
            value  = "```"
                .. "\nKey Used:    " .. censoredKey
                .. "\nStatus:      " .. status:upper()
                .. "\n```",
            inline = true,
        },
        {
            name   = "Executor Info",
            value  = "```"
                .. "\nExecutor:    " .. executor
                .. "\nHWID:        " .. hwid
                .. "\n```",
            inline = true,
        },
    }

    if status == "banned" and banReason then
        table.insert(fields, {
            name   = "BAN DETAILS",
            value  = "```"
                .. "\nReason:      " .. tostring(banReason)
                .. "\nBan Type:    " .. tostring(banSource)
                .. "\nFull HWID:   " .. hwid
                .. "\n```",
            inline = false,
        })
    end

    table.insert(fields, {
        name   = "Profile Link",
        value  = "[Click to view profile](" .. profileURL .. ")",
        inline = false,
    })

    local embed = {
        {
            title     = title,
            color     = color,
            thumbnail = { url = avatarURL },
            fields    = fields,
            footer    = { text = Config.Webhook.FooterText .. " - " .. timestamp },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        },
    }

    local payload = {
        content = (ping and ping ~= "") and ping or nil,
        embeds  = embed,
    }

    local body = HttpService:JSONEncode(payload)

    task.spawn(function()
        HttpPost(Config.WebhookURL, body)
    end)
end

-- ============================================
-- SCRIPT LOADER
-- ============================================

local function LoadScript(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if success and result then
        local exec, err = loadstring(result)
        if exec then
            exec()
            return true
        else
            return false
        end
    else
        return false
    end
end

-- ============================================
-- MAIN
-- ============================================

local function Main()
    local hwid    = GetHWID()
    local userId  = LocalPlayer.UserId
    local userKey = getgenv().AegisKey

    -- Ban check first
    local isBanned, banReason, banSource = CheckBanned(hwid, userId)
    if isBanned then
        SendNotification(Config.Notifications.Banned)
        SendWebhook("banned", userKey, banReason, banSource)
        getgenv().AegisKey = nil
        return
    end

    -- No key
    if not userKey then
        SendNotification(Config.Notifications.NoKey)
        if Config.Webhook.LogDeclined then
            SendWebhook("nokey", nil)
        end
        return
    end

    -- Invalid key
    if not IsKeyValid(userKey) then
        SendNotification(Config.Notifications.Declined)
        if Config.Webhook.LogDeclined then
            SendWebhook("declined", userKey)
        end
        return
    end

    -- Accepted
    SendNotification(Config.Notifications.Accepted)
    SendWebhook("accepted", userKey)

    task.wait(1)

    local loaded = LoadScript(Config.ScriptURL)

    if loaded then
        SendNotification(Config.Notifications.Loaded)
    else
        SendNotification(Config.Notifications.Error)
        if Config.Webhook.LogErrors then
            SendWebhook("error", userKey)
        end
    end

    getgenv().AegisKey = nil
end

Main()
