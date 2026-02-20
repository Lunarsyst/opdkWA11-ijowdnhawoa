local Config = {
    -- Valid keys
    ValidKeys = {
        "aegis-staff-27Dbh8d",
        "shwagglite-279",
        "ifuguessthisugotit",
        "boy8989",
    },

    ScriptURL = "https://raw.githubusercontent.com/Lunarsyst/093812r809hjiHSDUOAF814r0/refs/heads/main/ccas.lua",

    WebhookURL = "https://discordapp.com/api/webhooks/1471589603361292348/QQxzy3LKLhrhEfNqIEu-bmlv4aNF6gyViiP-cM52bcQR6qGsz6zPRDnwqHaggK_By-VS",

    -- Webhook embed settings
    Webhook = {
        -- Embed colors (decimal)
        AcceptedColor = 3066993,   -- Green
        DeclinedColor = 15158332,  -- Red
        ErrorColor    = 15105570,  -- Orange

        -- Footer text
        FooterText = "Aegis Loader",

        -- Censor middle of the key in logs? (security)
        CensorKey = true,

        -- Log declined/invalid attempts too?
        LogDeclined = true,

        -- Log errors?
        LogErrors = true,

        -- Ping a role/user on new execution? (leave "" to disable)
        PingOnAccept  = "",  -- e.g. "<@123456789>" or "<@&ROLEID>"
        PingOnDecline = "",
    },

    -- Notifications
    Notifications = {
        Accepted = {
            Title    = "Aegis Loader",
            Message  = "Loading..",
            Duration = 5,
        },
        Declined = {
            Title    = "Aegis Loader",
            Message  = "Invalid key!.",
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

-- Universal HTTP request (works across most executors)
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
        Log("No HTTP request function found on this executor.")
        return false, "No request function"
    end
end

-- Censor a key: "supersecrethappytime" → "sup***************me"
local function CensorKey(key)
    if not Config.Webhook.CensorKey then return key end
    if #key <= 6 then return string.rep("*", #key) end
    return key:sub(1, 3) .. string.rep("*", #key - 5) .. key:sub(-2)
end

-- Get executor name
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

-- Get HWID (if available — for banning/tracking)
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

-- Get game name safely
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

-- Get avatar headshot URL
local function GetAvatarURL(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId="
        .. tostring(userId)
        .. "&width=420&height=420&format=png"
end

-- Get current UTC time
local function GetTimestamp()
    return os.date("!%Y/%m/%d %H:%M:%S UTC")
end

-- ============================================
-- WEBHOOK TRACKER
-- ============================================

local function SendWebhook(status, userKey)
    if Config.WebhookURL == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        Log("Webhook URL not set — skipping tracking.")
        return
    end

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

    local color, title, statusIcon, ping

    if status == "accepted" then
        color      = Config.Webhook.AcceptedColor
        title      = "Script Executed — Key Accepted"
        statusIcon = ""
        ping       = Config.Webhook.PingOnAccept
    elseif status == "declined" then
        color      = Config.Webhook.DeclinedColor
        title      = "Execution Denied — Invalid Key"
        statusIcon = ""
        ping       = Config.Webhook.PingOnDecline
    elseif status == "error" then
        color      = Config.Webhook.ErrorColor
        title      = "Execution Error"
        statusIcon = ""
        ping       = ""
    elseif status == "nokey" then
        color      = Config.Webhook.DeclinedColor
        title      = "No Key Provided"
        statusIcon = ""
        ping       = Config.Webhook.PingOnDecline
    end

    local embed = {
        {
            title       = title,
            color       = color,
            thumbnail   = {
                url = avatarURL,
            },
            fields      = {
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
                        .. "\nStatus:      " .. statusIcon .. " " .. status:upper()
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
                {
                    name   = "Profile Link",
                    value  = "[Click to view profile](" .. profileURL .. ")",
                    inline = false,
                },
            },
            footer      = {
                text = Config.Webhook.FooterText .. " • " .. timestamp,
            },
            timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        },
    }

    local payload = {
        content = (ping and ping ~= "") and ping or nil,
        embeds  = embed,
    }

    local body = HttpService:JSONEncode(payload)

    task.spawn(function()
        local success, response = HttpPost(Config.WebhookURL, body)
        if success then
            Log("Webhook sent successfully (" .. status .. ")")
        else
            Log("Webhook failed: " .. tostring(response))
        end
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
            Log("Loadstring error: " .. tostring(err))
            return false
        end
    else
        Log("HttpGet error: " .. tostring(result))
        return false
    end
end

-- ============================================
-- MAIN
-- ============================================

local function Main()
    Log("Loader initialized.")

    local userKey = getgenv().AegisKey

    -- No key provided
    if not userKey then
        Log("No key provided.")
        SendNotification(Config.Notifications.NoKey)
        if Config.Webhook.LogDeclined then
            SendWebhook("nokey", nil)
        end
        return
    end

    -- Invalid key
    if not IsKeyValid(userKey) then
        Log("Invalid key: " .. tostring(userKey))
        SendNotification(Config.Notifications.Declined)
        if Config.Webhook.LogDeclined then
            SendWebhook("declined", userKey)
        end
        return
    end

    -- Key accepted
    Log("Key accepted!")
    SendNotification(Config.Notifications.Accepted)
    SendWebhook("accepted", userKey)

    task.wait(1)

    -- Load main script
    Log("Loading script...")
    local loaded = LoadScript(Config.ScriptURL)

    if loaded then
        Log("Script loaded successfully.")
        SendNotification(Config.Notifications.Loaded)
    else
        Log("Script failed to load.")
        SendNotification(Config.Notifications.Error)
        if Config.Webhook.LogErrors then
            SendWebhook("error", userKey)
        end
    end

    -- Clear key from memory
    getgenv().AegisKey = nil
end

Main()
