getgenv()._RevenantTSBLoaded = true
-- if not getgenv().RevenantSonicExecuted and math.random(1, 1000) == 1 then
--     getgenv().RevenantSonicExecuted = true
--     loadstring(game:HttpGet("https://raw.githubusercontent.com/miikicomsono/Revenant/refs/heads/main/Sonic.lua"))()
--     return
-- end

local _obsRepo   = "https://raw.githubusercontent.com/ZKAY404/Obsidian/refs/heads/main/"
local _obsApiSHA = "https://api.github.com/repos/ZKAY404/Obsidian/commits/main"




if getgenv().RevenantLoaded then
    if getgenv().RevenantCleanup then
        pcall(getgenv().RevenantCleanup)
    end
    getgenv().RevenantLoaded = false
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = bypassText("ZKAYTSB"),
            Text  = "Re-executing...",
            Duration  = 1,
        })
    end)
    task.wait(0)
end
getgenv().RevenantLoaded = true
-- local __startTime = tick()
-- task.spawn(function()
--     local HttpService   = game:GetService("HttpService")
--     local Players       = game:GetService("Players")
--     local HWID
--     pcall(function()
--         if gethwid then HWID = gethwid()
--         else HWID = game:GetService("RbxAnalyticsService"):GetClientId() end
--     end)
--     local BLACKLIST_URL = "https://raw.githubusercontent.com/miikicomsono/Private/main/Blacklisted" .. tostring(tick())
--     local raw
--     local ok = pcall(function()
--         local res = request({
--             Url     = BLACKLIST_URL,
--             Method  = "GET",
--             Headers = {
--                 ["Authorization"] = "token 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",
--                 ["User-Agent"]    = "Roblox/Revenant",
--             },
--         })
--         raw = res and res.Body
--     end)
--     if not ok or not raw or raw == "" then return end
--     raw = raw:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\r", "")
--     local ok2, blacklist = pcall(HttpService.JSONDecode, HttpService, raw)
--     if not ok2 or not blacklist then return end
--     for _, entry in ipairs(blacklist) do
--         if tostring(entry.hwid) == tostring(HWID) then
--             Players.LocalPlayer:Kick(
--                 "\n[Revenant] You are blacklisted.\nReason: " .. tostring(entry.reason or "No reason provided.")
--             )
--             return
--         end
--     end
-- end)
-- Garante que os arquivos base do Obsidian existem antes de tudo
local _shaFile = "ZKAYTSB/obsidian/.sha"
do
    if not isfolder("ZKAYTSB") then makefolder("ZKAYTSB") end
    if not isfolder("ZKAYTSB/obsidian") then makefolder("ZKAYTSB/obsidian") end
    if not isfile("ZKAYTSB/obsidian/Library.lua") then
        writefile("ZKAYTSB/obsidian/Library.lua", game:HttpGet(_obsRepo .. "Library.lua"))
    end
    if not isfile("ZKAYTSB/obsidian/ThemeManager.lua") then
        writefile("ZKAYTSB/obsidian/ThemeManager.lua", game:HttpGet(_obsRepo .. "addons/ThemeManager.lua"))
    end
    if not isfile("ZKAYTSB/obsidian/SaveManager.lua") then
        writefile("ZKAYTSB/obsidian/SaveManager.lua", game:HttpGet(_obsRepo .. "addons/SaveManager.lua"))
    end
end
-- Carrega a Library primeiro para poder usar o CreateLoading imediatamente
local Library      = loadfile("ZKAYTSB/obsidian/Library.lua")()
Library.ForceCheckbox = false
-- Se a Library cacheada for antiga (sem CreateLoading), força re-download agora
-- antes de tentar usá-la, para não travar em executores com cache desatualizado
if not Library.CreateLoading then
    writefile("ZKAYTSB/obsidian/Library.lua",      game:HttpGet(_obsRepo .. "Library.lua"))
    writefile("ZKAYTSB/obsidian/ThemeManager.lua", game:HttpGet(_obsRepo .. "addons/ThemeManager.lua"))
    writefile("ZKAYTSB/obsidian/SaveManager.lua",  game:HttpGet(_obsRepo .. "addons/SaveManager.lua"))
    Library = loadfile("ZKAYTSB/obsidian/Library.lua")()
    Library.ForceCheckbox = false
end
local ThemeManager = loadfile("ZKAYTSB/obsidian/ThemeManager.lua")()
local SaveManager  = loadfile("ZKAYTSB/obsidian/SaveManager.lua")()
local Options = Library.Options
local Toggles = Library.Toggles
-- Callbacks de eventos (AnimationPlayed, InputBegan, etc.) podem disparar
-- antes do AddToggle/AddDropdown correspondente ser registrado.
-- O metatable abaixo retorna um stub seguro para chaves ainda não existentes,
-- evitando "attempt to index nil with 'Value'" sem precisar guardar cada acesso.
do
    local _stub = setmetatable({Value = false}, {
        __index = function() return function() end end  -- métodos (SetValue, OnChanged, etc.) → no-op
    })
    if not getmetatable(Options) then
        setmetatable(Options, {__index = function() return _stub end})
    end
    if not getmetatable(Toggles) then
        setmetatable(Toggles, {__index = function() return _stub end})
    end
end
local _crWindupSuccess  = false  -- crushed rock variant
local _crBlacklistCount = 0      -- tracks blacklisted players this windup
local _crStopDesync     = false  -- Yes btn: keep teleport, kill desync ghost
local isCountering    -- forward-declared as upvalue; defined inside anti-moves block, called by hitbox touch callbacks
local InstaKillFling  -- forward-declared as upvalue to avoid local register overflow inside xpcall
local _loopFlingMode  -- forward-declared as upvalue to avoid local register overflow inside xpcall
local _hookPlayerAntiMoves    -- forward-declared as upvalue to avoid local register overflow inside xpcall
local _watchEnemyAntiMoves    -- forward-declared as upvalue to avoid local register overflow inside xpcall
local _antiMovesCharConns     -- forward-declared as upvalue to avoid local register overflow inside xpcall
local _antiMovesRespawnConns  -- forward-declared as upvalue to avoid local register overflow inside xpcall
-- disguise block forward-declarations (upvalues to avoid 200-local limit inside xpcall)
local _disguiseLoadApplied, _disguise_applying, _disguise_random_cooldown
local _disguise_randoms, _disguise_cache, _disguise_allowed_cache
local _disguise_last_id, _disguise_spawn_conn, _disguise_maintain_conn
local _disguise_attr_conn, _disguise_attr_char_conn, _disguise_presets
local _disguiseResolveId, _disguiseCollectTools, _disguiseRestoreTools
local _disguiseBuildAllowed, _disguiseSelectiveClean, _disguiseFullClean
local _disguiseApplyDesc, _disguiseApplyToChar, _disguiseHookAttrWatch
local _disguiseApply
-- disguise favourites forward-declarations
local _disguise_favs, _disguise_fav_file
local _disguise_save_favs, _disguise_refresh_fav_dropdown
-- RCS block forward-declarations (upvalues to avoid 200-local limit inside xpcall)
local _RCS_Known, _RCS_MyRank, _RCS_Prefix, _RCS_Channel, _RCS_RankMap
local _RCS_RankNames, _RCS_MyHWID, _RCS_SessionToken, _RCS_AnchorConn, _RCS_MsgConn
local _RCS_GetRank, _RCS_Send, _RCS_ExecuteOnSelf, _RCS_SendCmd
-- FUCClone block forward-declarations (upvalues to avoid 200-local limit inside xpcall)
local _FUCClone, _FUCCloneRoot, _FUCCloneTrack
-- RakNet desync clone forward-declarations (upvalues to avoid 200-local limit inside xpcall)
local _dClone, _dCloneRoot, _dRenderConn

-- Cria o Loading Obsidian imediatamente
local _lp_pre = game:GetService("Players").LocalPlayer
local _nick_pre = (_lp_pre.DisplayName ~= "" and _lp_pre.DisplayName) or _lp_pre.Name

-- Checa e aplica atualizações do Obsidian com progresso no Loading
do
    if type(isfile) == "function" and type(writefile) == "function" and type(readfile) == "function" then
        writefile("ZKAYTSB/obsidian/Library.lua", game:HttpGet(_obsRepo .. "Library.lua"))
        writefile("ZKAYTSB/obsidian/ThemeManager.lua", game:HttpGet(_obsRepo .. "addons/ThemeManager.lua"))
        writefile("ZKAYTSB/obsidian/SaveManager.lua", game:HttpGet(_obsRepo .. "addons/SaveManager.lua"))
        Library = loadfile("ZKAYTSB/obsidian/Library.lua")()
        Library.ForceCheckbox = false
        ThemeManager = loadfile("ZKAYTSB/obsidian/ThemeManager.lua")()
        SaveManager  = loadfile("ZKAYTSB/obsidian/SaveManager.lua")()
        -- Atualiza Options e Toggles para as tabelas da nova Library;
        -- sem isso, os callbacks apontariam para as tabelas velhas e vazias
        Options = Library.Options
        Toggles = Library.Toggles
        -- Re-aplica o metatable de segurança nas novas tabelas
        do
            local _stub = setmetatable({Value = false}, {
                __index = function() return function() end end
            })
            if not getmetatable(Options) then
                setmetatable(Options, {__index = function() return _stub end})
            end
            if not getmetatable(Toggles) then
                setmetatable(Toggles, {__index = function() return _stub end})
            end
        end
    end
end

-- Download Gojo M1 hit sounds to ZKAYTSB/assets/
task.spawn(function()
    if not isfolder("ZKAYTSB/assets") then makefolder("ZKAYTSB/assets") end
    local _assetBase = "https://raw.githubusercontent.com/ZKAY404/ZKAYTSB/main/assets/"
    local _assetFiles = { "M1Hit1.mp3", "M1Hit2.mp3", "M1Hit3.mp3", "M1Hit4.mp3" }
    for _, fname in ipairs(_assetFiles) do
        local path = "ZKAYTSB/assets/" .. fname
        if not isfile(path) then
            local ok, body = pcall(function()
                return game:HttpGet(_assetBase .. fname)
            end)
            if ok and body and #body > 0 then
                pcall(function() writefile(path, body) end)
            end
        end
    end
end)

-- ── HOLIDAY HELPER ───────────────────────────────────────────────────────────
local function holiday(text, opts)
    local easterKey = (function(year)
        local c = math.floor(year / 100)
        local h = (15 - math.floor((13 + 8 * c) / 25) + c - math.floor(c / 4)) % 30
        local k = (4 + c - math.floor(c / 4)) % 7
        local m = (19 * (year % 19) + h) % 30
        local n = (2 * (year % 4) + 4 * (year % 7) + 6 * m + k) % 7
        local d = 22 + m + n
        if m == 29 and n == 6 then return '04 19'
        elseif m == 28 and n == 6 then return '04 18'
        elseif d > 31 then return ('04 %02d'):format(d - 31)
        else return ('03 %02d'):format(d) end
    end)(tonumber(os.date('%Y')))

    local immediate = {
        ['01 01'] = '�',
        ['10 31'] = '�',
        [easterKey] = '�',
    }
    if opts and opts.entireChristmas then
        for d = 1, 31 do
            immediate['12 ' .. ('%02d'):format(d)] = ({ '�', '�' })[math.random(1, 2)]
        end
    end
    local today = os.date('%m %d')
    if immediate[today] then
        local e = immediate[today]
        return ('%s %s %s'):format(e, text, e)
    end

    return text
end

local function bypassText(text)
    return holiday(text, {entireChristmas = true})
end

task.spawn(function()
local _mainOk, _mainErr = xpcall(function()
local Window = Library:CreateWindow({
    Title            = bypassText("ILoveAris"),
    Footer           = bypassText("Phantasm's old test version fixed + improved. | @aristooey"),
    Icon             = "rbxassetid://87227080710263",
    NotifySide       = "Right",
    ShowCustomCursor = false,
    Resizable        = true,
    Center           = true,
    AutoShow         = true,
})
Library.ShowCustomCursor = false
local _origNotify = Library.Notify
Library.Notify = function(self, opts)
    if Library.Unloaded then return end
    if type(opts) == "table" then
        local title   = tostring(opts.Title   or "")
        local content = tostring(opts.Content or "")
        local duration = opts.Time or opts.Duration or 4
        return _origNotify(self, {
            Title       = title ~= "" and title or "ZKAY404",
            Description = content,
            Time        = duration,
            SoundId     = 4590657391,
        })
    else
        return _origNotify(self, { Title = bypassText("ZKAY404"), Description = tostring(opts or ""), Time = 4, SoundId = 4590657391 })
    end
end
local mainGameId      = "131048399685555"
local secondaryGameId = "10449761463"
local currentPlaceId  = tostring(game.PlaceId)
local Characters = {
    ["Saitama"]        = "Bald",
    ["Garou"]          = "Hunter",
    ["Monster Garou"]  = "Monster",
    ["Suiryu"]         = "Purple",
    ["Genos"]          = "Cyborg",
    ["Sonic"]          = "Ninja",
    ["Metal Bat"]      = "Batter",
    ["Atomic Samurai"] = "Blade",
    ["Tatsumaki"]      = "Esper",
    ["Child Emperor"]  = "Tech",
    ["Lightning Max"]  = "Lightning",
    ["Gojo"]           = "Sorcerer",
    ["KJ"]             = "KJ",
}
local isTargetGame     = (currentPlaceId == mainGameId)
local isGamepassesGame = true
local trashcanGameIds  = { [mainGameId] = true, [secondaryGameId] = true }
local hasExecutorFunctions = (
    typeof(getrawmetatable) == "function" and
    typeof(setreadonly)     == "function" and
    typeof(newcclosure)     == "function" and
    typeof(getcallingscript) == "function"
)
local _shpSupported = type(sethiddenproperty) == "function"

local Tabs = {
    ChangeLogs  = Window:AddTab("Notice",       "key"),
    LocalPlayer = Window:AddTab("Main",         "house"),
    Exploits    = Window:AddTab("Player",       "user"),
    Visuals     = Window:AddTab("Visuals",      "scan-eye"),
}
Tabs.Combat = Tabs.Exploits
Tabs.Commands = Window:AddTab("Commands", "terminal")
Tabs.Map      = Window:AddTab("Map",      "map-pin")
Tabs.Anims     = Window:AddTab("Animations", "move-3d")
-- [ENI] Disguise tab removed
if isGamepassesGame then Tabs.Misc = Window:AddTab("Miscallaneous", "ellipsis") end
Tabs.Settings  = Window:AddTab("UI Settings", "settings")
local _lpTabbox  = Tabs.LocalPlayer:AddLeftTabbox()
local TabMovement  = _lpTabbox:AddTab("Movement")
local TabCharacter = _lpTabbox:AddTab("Character")
local BoxKeybindsLP  = Tabs.LocalPlayer:AddLeftGroupbox("Keybinds",          "keyboard")
local BoxAutomation  = Tabs.LocalPlayer:AddRightGroupbox("Automation",        "folder-git-2")
local BoxDashes      = Tabs.LocalPlayer:AddRightGroupbox("Dashes",            "chevrons-up")
-- Update Log removido
local BoxVisualsMain  = Tabs.Visuals:AddLeftGroupbox("Quality Of Life",        "flower-2")
local BoxVisualsESP   = Tabs.Visuals:AddRightGroupbox("ESP",                  "eye")
local BoxVisualsWorld = Tabs.Visuals:AddRightGroupbox("World",                "earth")
local BoxAnimsLeft  = Tabs.Anims:AddLeftGroupbox("R6",                        "person-standing")
local TabMiscAnims   = Tabs.Anims:AddLeftGroupbox("M1 Animations",            "hand-fist")
local TabMiscSaitama = Tabs.Anims:AddLeftGroupbox("Saitama Animations",       "arrow-right-left")
local TabMiscAnimsR  = Tabs.Anims:AddRightGroupbox("Custom Animations",       "diamond-plus")
local BoxFling, BoxTools, BoxMovement, BoxCFrameSpeed
local BoxCFrameSpeed = TabMovement
BoxMovement = TabMovement
local BoxCharMods = TabCharacter
local TabExpMain      = Tabs.Exploits:AddLeftGroupbox("Bring",       "file-cog")
local TabExpAntis     = Tabs.Exploits:AddLeftGroupbox("Anti's",      "ghost")
local TabExpWallCombo       = Tabs.Exploits:AddRightGroupbox("Wall Combo",      "hand-fist")
local TabExpTrashcan        = Tabs.Exploits:AddRightGroupbox("Trashcan",        "trash")
local TabExpInvisibleMoves  = Tabs.Exploits:AddRightGroupbox("Invisible Moves", "eye-off")
local TabExpStand           = Tabs.Exploits:AddRightGroupbox("Stand",           "user-round")
BoxTools        = TabExpMain

-- ── PLAYER LABEL HELPERS ─────────────────────────────────────────────────────
local function _makePlayerLabel(p)
    local nick = (p.DisplayName ~= "" and p.DisplayName) or p.Name
    return nick .. "(@" .. p.Name .. ")"
end
local function _findPlayerByLabel(label)
    if not label or label == "" then return nil end
    local username = label:match("@([^%)]+)")
    if username then
        local found = game:GetService("Players"):FindFirstChild(username)
        if found then return found end
    end
    -- fallback: nome exato ou displayname
    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
        if p.Name == label or p.DisplayName == label then return p end
    end
    return nil
end

-- ── STAND ────────────────────────────────────────────────────────────────────
do
    local lp         = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    -- State
    local _standTarget          = nil   -- Player object
    local _standFollowMode      = true  -- true = Follow, false = Don't Follow
    local _standActive          = false

    -- Connections (all stored so we can disconnect on target change or unload)
    local _standHeartbeat          = nil   -- follow loop
    local _standAnimConn           = nil   -- target AnimationPlayed
    local _standCharConn           = nil   -- target CharacterAdded
    local _standMyAnimConn         = nil   -- local AnimationPlayed (reposition on attack)
    local _standMyCharConn         = nil   -- local CharacterAdded (reconnect conns)
    local _standPlayerRemovingConn = nil   -- fires when stand target leaves the game
    local _standIdleRenderConn     = nil   -- RenderStepped loop for idle anim pin
    local _standIdleTrack          = nil   -- currently pinned idle AnimationTrack
    local _standIdleLastIdx        = 0     -- last picked variant index (never repeat)
    local _lastIdleStart           = 0     -- tick() of last _startIdleAnim call (watchdog debounce)

    local _standWeld            = nil
    local _standCooldowns       = { 0, 0, 0, 0 }
    local _blockCount           = 0   -- contador de blocks para toggle follow
    local _suppressFollow       = 0     -- pausa o follow loop durante moves (counter)
    local _tempMoveConn         = nil -- weld temporário durante move em don't follow mode
    local _startFollowLoop      -- forward-declared; defined below.

    local _idleOffset           = CFrame.new(-2, 2, 5)
    local _attackOffset         = CFrame.new(0, 0, -4)
    local _currentOffset        = _idleOffset

    local _moveList = {
        { 'Normal Punch',             10468665991,   20,   1, 'Normal Punch'             },
        { 'Consecutive Punches',      10466974800,   15,   2, 'Consecutive Punches'      },
        { 'Shove',                    10471336737,   10,   3, 'Shove'                    },
        { 'Uppercut',                 12510170988,   20,   4, 'Uppercut'                 },
        { 'Table Flip',               11365563255,   20,   2, 'Table Flip'               },
        { 'Serious Punch',            12983333733,   20,   3, 'Serious Punch'            },
        { 'Omni Directional Punch',   13927612951,   20,   4, 'Omni Directional Punch'   },
        { 'Lethal Whirlwind Stream',  12296882427,   20,   2, 'Lethal Whirlwind Stream'  },
        { 'Flowing Water',            12272894215,   17.5, 1, 'Flowing Water'            },
        { 'Hunters Grasp',            12307656616,   15,   3, "Hunter's Grasp"           },
        { 'Preys Peril',              12351854556,   17,   4, "Prey's Peril"             },
        { 'Water Stream Cutting Fist',12460977270,   8.45, 1, 'Water Stream Cutting Fist'},
        { 'The Final Hunt',           12463072679,   101,  2, 'The Final Hunt'           },
        { 'Rock Splitting Fist',      14057231976,   14,   3, 'Rock Splitting Fist'      },
        { 'Crushed Rock',             13630786846,   9.58, 4, 'Crushed Rock'             },
        { 'Machine Gun Blows',        12534735382,   15,   1, 'Machine Gun Blows'        },
        { 'Ignition Burst',           12502664044,   17.5, 2, 'Ignition Burst'           },
        { 'Blitz Shot',               12618271998,   25,   3, 'Blitz Shot'               },
        { 'Jet Dive',                 12684390285,   17.5, 4, 'Jet Dive'                 },
        { 'Thunder Kick',             14721837245,   15,   1, 'Thunder Kick'             },
        { 'Speedblitz Dropkick',      12832505612,   20,   2, 'Speedblitz Dropkick'      },
        { 'Flamewave Cannon',         13083332742,   25,   3, 'Flamewave Cannon'         },
        { 'Incinerate',               13146710762,   101,  4, 'Incinerate'               },
        { 'Flash Strike',             13309500827,   17.5, 1, 'Flash Strike'             },
        { 'Whirlwind Kick',           13294790250,   20,   2, 'Whirlwind Kick'           },
        { 'Scatter',                  13362587853,   21.25,3, 'Scatter'                  },
        { 'Explosive Shuriken',       13501296372,   17.5, 4, 'Explosive Shuriken'       },
        { 'Twinblade Rush',           13632347366,   20,   1, 'Twinblade Rush'           },
        { 'Straight On',              13643152947,   17,   2, 'Straight On'              },
        { 'Carnage',                  13723174078,   25,   3, 'Carnage'                  },
        { 'Fourfold Flashstrike',     13881335713,   25,   4, 'Fourfold Flashstrike'     },
        { 'Homerun',                  14004235777,   17.5, 1, 'Homerun'                  },

        { 'Grand Slam',               14299135500,   20,   3, 'Grand Slam'               },
        { 'Foul Ball',                14351441234,   23,   4, 'Foul Ball'                },
        { 'Savage Tornado',           14719290328,   17,   1, 'Savage Tornado'           },
        { 'Brutal Beatdown',          14701242661,   30,   2, 'Brutal Beatdown'          },
        { 'Strength Difference',      14900168720,   20,   3, 'Strength Difference'      },
        { 'Death Blow',               15128849047,   101,  4, 'Death Blow'               },
        { 'Quick Slice',              15290930205,   20,   1, 'Quick Slice'              },
        { 'Atmos Cleave',             15145462680,   22,   2, 'Atmos Cleave'             },
        { 'Pinpoint Cut',             15295895753,   17,   3, 'Pinpoint Cut'             },
        { 'Pinpoint Cut',             15295336270,   17,   3, 'Pinpoint Cut'             },
        { 'Split Second Counter',     15311685628,   17.5, 4, 'Split Second Counter'     },
        { 'Sunset',                   15520132233,   15,   1, 'Sunset'                   },
        { 'Solar Cleave',             15676072469,   15,   2, 'Solar Cleave'             },
        { 'Sunrise',                  16062410809,   20,   3, 'Sunrise'                  },
        { 'Atomic Slash',             16082123712,   101,  4, 'Atomic Slash'             },
        { 'Crushing Pull',            16139108718,   21,   1, 'Crushing Pull'            },
        { 'Windstorm Fury',           16515850153,   20,   2, 'Windstorm Fury'           },
        { 'Stone Coffin',             16431491215,   25,   3, 'Stone Coffin'             },
        { 'Expulsive Push',           16597322398,   19,   4, 'Expulsive Push'           },
        { 'Cosmic Strike',            16737255386,   30,   1, 'Cosmic Strike'            },
        { 'Psychic Ricochet',         17464644182,   15,   2, 'Psychic Ricochet'         },
        { 'Terrible Tornado',         17275150809,   101,  3, 'Terrible Tornado'         },
        { 'Sky Snatcher',             17860467628,   17,   4, 'Sky Snatcher'             },
        { 'Bullet Barrage',           17799224866,   20,   1, 'Bullet Barrage'           },
        { 'Vanishing Kick',           17838006839,   23,   2, 'Vanishing Kick'           },
        { 'Whirlwind Drop',           17857788598,   15,   3, 'Whirlwind Drop'           },
        { 'Head First',               18179181663,   20,   4, 'Head First'               },
        { 'Grand Fissure',            129651400898906, 18, 1, 'Grand Fissure'            },
        { 'Twin Fangs',               18896229321,   15,   2, 'Twin Fangs'               },
        { 'Earth Splitting Strike',   18897119503,   30,   3, 'Earth Splitting Strike'   },
        { 'Last Breath',              106755459092436, 101, 4, 'Last Breath'             },
        { 'Ravage',                   16945573694,   17.5, 1, 'Ravage'                   },
        { 'Swift Sweep',              16944265635,   15,   2, 'Swift Sweep'              },
        { 'Collateral Ruin',          17325254223,   22.5, 3, 'Collateral Ruin'          },
        { 'Spiraling Storm',          78521642007560, 22.5, 4, 'Spiraling Storm'         },
        { 'Stoic Bomb',               17141153099,   15,   1, 'Stoic Bomb'               },
        { '202020 Dropkick',          17354976067,   101,  2, '20-20-20 Dropkick'        },
        { 'Five Seasons',             18462892217,   100,  3, 'Five Seasons'             },
        { 'Unlimited Flex Works',     77727115892579, 0,   4, 'Unlimited Flex Works'     },
        { 'Permafrost',               100558589307006, 20, 1, 'Permafrost'               },
        { 'Frost Forge',              137561511768861, 15, 2, 'Frost Forge'              },
        { 'Freezing Path',            112620365240235, 25, 3, 'Freezing Path'            },
        { 'Judgement Chain',          75547590335774, 20,  4, 'Judgement Chain'          },
        { 'Weboom',                   113166426814229, 20, 1, 'Weboom'                   },
        { 'Trinity Tear',             77509627104305, 25,  2, 'Trinity Tear'             },
        { 'Plasma Cannon',            116753755471636, 20, 3, 'Plasma Cannon'            },
        { 'Double Trouble',           138443750790136, 20, 4, 'Double Trouble'           },
        { 'Doom Dive',                101588604872680, 23, 1, 'Doom Dive'               },
        { 'Crowd Buster',             105442749844047, 22, 2, 'Crowd Buster'             },
        { 'Hammer Heel',              109617620932970, 18, 3, 'Hammer Heel'              },
        { 'Binding Cloth',            125955606488863, 20, 4, 'Binding Cloth'            },
        { 'Hammer Heel',              135289891173395, 18, 3, 'Hammer Heel'              },
        { 'Machine Gun Blows',        12971270638,   15,   1, 'Machine Gun Blows'        },
        { 'Crushed Rock',             72451715583225, 9.58, 4, 'Crushed Rock'            },
        -- Block animations (usados só para detectar 3x block toggle)
        { 'Block',                    13380778193,   0,    0, 'Block'                    },
        { 'Block',                    13370310513,   0,    0, 'Block'                    },
        { 'Block',                    13935548552,   0,    0, 'Block'                    },

    }

    local function _removeCollision()
        local char = lp.Character
        if not char then return end
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA('BasePart') then p.CanCollide = false end
        end
    end

    local _standPartsState = {}

    -- Snap inicial: posiciona o char no offset relativo ao alvo (mesmo método do toggleWeld)
    local function _applyAttach()
        if not _standTarget or not _standTarget.Character then return end
        if not lp.Character then return end
        local myHRP     = lp.Character:FindFirstChild('HumanoidRootPart')
        local targetHRP = _standTarget.Character:FindFirstChild('HumanoidRootPart')
        if not myHRP or not targetHRP then return end

        _standPartsState = {}
        for _, p in pairs(lp.Character:GetDescendants()) do
            if p:IsA('BasePart') then
                _standPartsState[p] = { CanCollide = p.CanCollide, Massless = p.Massless }
                p.CanCollide = false
                p.Massless   = true
            end
        end

        local hum = lp.Character:FindFirstChildOfClass('Humanoid')
        if hum then
            pcall(function() hum.AutoRotate = false end)
            hum.PlatformStand = true
        end

        -- Snap directly to offset, consistent with toggleWeld behaviour.
        myHRP.CFrame                     = targetHRP.CFrame * _currentOffset
        myHRP.AssemblyLinearVelocity     = Vector3.zero
        myHRP.AssemblyAngularVelocity    = Vector3.zero
        if sethiddenproperty then
            pcall(function() sethiddenproperty(myHRP, 'PhysicsRepRootPart', targetHRP) end)
        end
    end

    local function _setAttachOffset(cf)
        _currentOffset = cf
    end

    local _standAttrConns = {}
    local function _disconnectAttrConns()
        for _, c in pairs(_standAttrConns) do pcall(function() c:Disconnect() end) end
        _standAttrConns = {}
    end

    local _idleVariants = {
        { id = '16136144568',     name = 'Idle 1',          tpos = 0.69, free = true,  oscillate = true,  tposMin = 0.45, tposMax = 0.70, speed = 0.1 },
        { id = '17861840167',     name = 'Idle 2',          tpos = 1,    free = false, oscillate = false },
        { id = '16524522673',     name = 'Idle 3',          tpos = 0.71, free = false, oscillate = false },
        { id = '15099756132',     name = 'Idle 4',          tpos = 0,    free = true,  oscillate = false },

    }

    local function _startIdleAnim()
        if not _standActive or not _standFollowMode then return end
        -- debounce: if a call already ran within the last 0.1s and we have a live track,
        -- bail — prevents double-fire when watchdog + explicit defer queue up in the same frame
        local _now = tick()
        if _standIdleTrack and _standIdleTrack.IsPlaying and (_now - _lastIdleStart) < 0.1 then return end
        _lastIdleStart = _now
        local char = lp.Character
        local hum2 = char and char:FindFirstChildWhichIsA('Humanoid')
        local animator = hum2 and hum2:FindFirstChildWhichIsA('Animator')
        if not animator then return end
        -- pick variant: use the dropdown selection if set, otherwise random (never the same as last)
        local picked
        local selName = Options.StandIdleAnimDropdown and Options.StandIdleAnimDropdown.Value or "Random"
        if selName ~= "Random" then
            for _, v in ipairs(_idleVariants) do
                if v.name == selName then picked = v break end
            end
        end
        if not picked then
            local idx
            repeat idx = math.random(1, #_idleVariants) until idx ~= _standIdleLastIdx
            _standIdleLastIdx = idx
            picked = _idleVariants[idx]
        end
        -- clean old conn + track
        if _standIdleRenderConn then _standIdleRenderConn:Disconnect() _standIdleRenderConn = nil end
        if _standIdleTrack then pcall(function() _standIdleTrack:Stop(0) end) _standIdleTrack = nil end
        local idleAnim = Instance.new('Animation')
        idleAnim.AnimationId = 'rbxassetid://' .. picked.id
        local idleTrack = animator:LoadAnimation(idleAnim)
        idleTrack.Priority = Enum.AnimationPriority.Action4
        idleTrack.Looped   = true
        _standIdleTrack = idleTrack
        if picked.free then
            idleTrack:Play()
            idleTrack:AdjustWeight(1)
            if picked.oscillate then
                idleTrack.TimePosition = picked.tpos
                idleTrack:AdjustSpeed(-(picked.speed or 0.1))
            elseif picked.tpos then
                idleTrack.TimePosition = picked.tpos
            end
            _standIdleRenderConn = RunService.RenderStepped:Connect(function()
                if not _standActive then
                    if _standIdleRenderConn then _standIdleRenderConn:Disconnect() _standIdleRenderConn = nil end
                    pcall(function() idleTrack:Stop(0) end)
                    _standIdleTrack = nil
                    return
                end
                if _suppressFollow > 0 then
                    if idleTrack.IsPlaying then pcall(function() idleTrack:Stop(0) end) end
                    return
                end
                if not idleTrack.IsPlaying then return end
                idleTrack:AdjustWeight(1)
                if picked.freezeAt and idleTrack.TimePosition >= picked.freezeAt then
                    idleTrack:AdjustSpeed(0)
                    idleTrack.TimePosition = picked.freezeAt
                elseif picked.oscillate then
                    local spd = picked.speed or 0.1
                    if idleTrack.TimePosition >= picked.tposMax then
                        idleTrack:AdjustSpeed(-spd)
                    elseif idleTrack.TimePosition <= picked.tposMin then
                        idleTrack:AdjustSpeed(spd)
                    end
                end
            end)
        else
            idleTrack:Play()
            idleTrack:AdjustSpeed(0)
            idleTrack:AdjustWeight(1)
            idleTrack.TimePosition = picked.tpos
            _standIdleRenderConn = RunService.RenderStepped:Connect(function()
                if not _standActive then
                    if _standIdleRenderConn then _standIdleRenderConn:Disconnect() _standIdleRenderConn = nil end
                    pcall(function() idleTrack:Stop(0) end)
                    _standIdleTrack = nil
                    return
                end
                if _suppressFollow > 0 then
                    if idleTrack.IsPlaying then pcall(function() idleTrack:Stop(0) end) end
                    return
                end
                if not idleTrack.IsPlaying then return end
                idleTrack:AdjustSpeed(0)
                idleTrack:AdjustWeight(1)
                idleTrack.TimePosition = picked.tpos
            end)
        end
    end

    local function _standDisconnectAll()
        _suppressFollow = 0
        _lastIdleStart  = 0
        if _standIdleRenderConn     then _standIdleRenderConn:Disconnect()     _standIdleRenderConn     = nil end
        if _standIdleTrack          then pcall(function() _standIdleTrack:Stop(0) end) _standIdleTrack = nil end
        if _standHeartbeat          then _standHeartbeat:Disconnect()          _standHeartbeat          = nil end
        if _tempMoveConn            then _tempMoveConn:Disconnect()            _tempMoveConn            = nil end
        if _standAnimConn           then _standAnimConn:Disconnect()           _standAnimConn           = nil end
        if _standCharConn           then _standCharConn:Disconnect()           _standCharConn           = nil end
        if _standMyAnimConn         then _standMyAnimConn:Disconnect()         _standMyAnimConn         = nil end
        if _standPlayerRemovingConn then _standPlayerRemovingConn:Disconnect() _standPlayerRemovingConn = nil end
        _disconnectAttrConns()
        pcall(function()
            if lp.Character then
                local hum = lp.Character:FindFirstChildWhichIsA('Humanoid')
                if hum then
                    hum.PlatformStand = false
                    pcall(function() hum.AutoRotate = true end)
                end
                local root = lp.Character:FindFirstChild('HumanoidRootPart')
                if root then
                    root.AssemblyLinearVelocity  = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    pcall(function() root.Velocity    = Vector3.zero end)
                    pcall(function() root.RotVelocity = Vector3.zero end)
                    if sethiddenproperty then
                        pcall(function() sethiddenproperty(root, 'PhysicsRepRootPart', root) end)
                    end
                end
                for v, state in pairs(_standPartsState) do
                    if v and v.Parent then
                        v.CanCollide = state.CanCollide
                        v.Massless   = state.Massless
                    end
                end
                _standPartsState = {}
            end
        end)
        _standCooldowns = { 0, 0, 0, 0 }
    end

    local function _toggleFollowMode()
        _standFollowMode = not _standFollowMode
        if _standFollowMode then
            _startFollowLoop()
        else
            if _standHeartbeat then _standHeartbeat:Disconnect() _standHeartbeat = nil end
            if _tempMoveConn then _tempMoveConn:Disconnect() _tempMoveConn = nil end
            pcall(function()
                local hum2 = lp.Character and lp.Character:FindFirstChildOfClass('Humanoid')
                if hum2 then hum2.PlatformStand = false end
            end)
        end
        -- Sync dropdown
        pcall(function()
            Options.StandMethodDropdown:SetValue(_standFollowMode and "Follow" or "Don't Follow")
        end)
    end

    local function _hookTargetAnims(targetPlayer)
        local char = targetPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildWhichIsA('Humanoid')
        if not hum then return end

        if _standAnimConn then _standAnimConn:Disconnect() _standAnimConn = nil end
        _standAnimConn = hum.AnimationPlayed:Connect(function(track)
            local animId = track.Animation and track.Animation.AnimationId or ''
            -- Detecta block do ALVO: 3x consecutivos = toggle follow mode
            if animId:match('10470389827') or animId:match('13380778193') or animId:match('13370310513') or animId:match('13935548552') then
                _blockCount = _blockCount + 1
                if _blockCount >= 3 then
                    _blockCount = 0
                    _toggleFollowMode()
                end
                task.delay(1, function()
                    if _blockCount > 0 then
                        _blockCount = _blockCount - 1
                    end
                end)
                return
            end
            for _, move in pairs(_moveList) do
                if animId == 'rbxassetid://' .. tostring(move[2]) then
                    local slot = move[4]
                    if slot == 0 then break end  -- ignora entradas de block no cooldown
                    _standCooldowns[slot] = move[3]
                    task.spawn(function()
                        task.wait(move[3])
                        _standCooldowns[slot] = 0
                    end)
                end
            end
        end)

        _disconnectAttrConns()
        for _, move in pairs(_moveList) do
            local attrName = 'Holding' .. string.gsub(move[1], ' ', '')
            pcall(function() char:SetAttribute(attrName, false) end)
            local conn = char:GetAttributeChangedSignal(attrName):Connect(function()
                if char:GetAttribute(attrName) == true and _standCooldowns[move[4]] ~= 0 then
                    for _, other in pairs(_moveList) do
                        if other[4] == move[4] and lp.Backpack:FindFirstChild(other[5]) then
                            pcall(function()
                                lp.Character.Communicate:FireServer(unpack({{
                                    Tool = lp.Backpack:WaitForChild(other[5]),
                                    Goal = 'Console Move',
                                }}))
                            end)
                        end
                    end
                end
            end)
            table.insert(_standAttrConns, conn)
        end
    end

    local function _hookLocalAnims()
        if _standMyAnimConn then _standMyAnimConn:Disconnect() _standMyAnimConn = nil end
        local char = lp.Character
        if not char then return end
        -- Busca o Animator diretamente (mais confiável que só o Humanoid em alguns executors)
        local hum      = char:FindFirstChildWhichIsA('Humanoid')
        local animator = hum and hum:FindFirstChildWhichIsA('Animator')
        if not hum then return end

        local function onAnimPlayed(track)
            local animId = track.Animation and track.Animation.AnimationId or ''
            animId = animId:gsub('%s+', '')
            for _, move in pairs(_moveList) do
                local moveId = 'rbxassetid://' .. tostring(move[2])
                if animId == moveId then
                    if move[4] == 0 then break end  -- slot 0 = block, já tratado acima
                    _setAttachOffset(_attackOffset)
                    task.spawn(function()
                        if _tempMoveConn then _tempMoveConn:Disconnect() _tempMoveConn = nil end
                        local mh0     = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
                        local savedCF = (not _standFollowMode) and mh0 and mh0.CFrame
                        -- Pausa o follow loop e libera PlatformStand para o server poder teleportar (ex: Beatdown)
                        _suppressFollow = _suppressFollow + 1
                        pcall(function()
                            local hum = lp.Character and lp.Character:FindFirstChildWhichIsA('Humanoid')
                            if hum then hum.PlatformStand = false end
                        end)

                        _tempMoveConn = RunService.Heartbeat:Connect(function()
                            local mh = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
                            local th = _standTarget and _standTarget.Character
                                       and _standTarget.Character:FindFirstChild('HumanoidRootPart')
                            if mh and th then
                                mh.CFrame                  = th.CFrame * _attackOffset
                                mh.AssemblyLinearVelocity  = Vector3.zero
                                mh.AssemblyAngularVelocity = Vector3.zero
                                if sethiddenproperty then
                                    pcall(function() sethiddenproperty(mh, 'PhysicsRepRootPart', th) end)
                                end
                            end
                        end)
                        track.Stopped:Wait()
                        if _tempMoveConn then _tempMoveConn:Disconnect() _tempMoveConn = nil end
                        _suppressFollow = math.max(0, _suppressFollow - 1)
                        if _suppressFollow > 0 then return end  -- another move still active
                        _setAttachOffset(_idleOffset)
                        if _standFollowMode then
                            -- reset debounce so the heartbeat watchdog fires the idle on the next tick
                            _lastIdleStart = 0
                        else
                            local mhFinal = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
                            if mhFinal and savedCF then
                                mhFinal.CFrame                  = savedCF
                                mhFinal.AssemblyLinearVelocity  = Vector3.zero
                                mhFinal.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                    end)
                    break
                end
            end
        end

        -- Conecta via AnimationPlayed do Humanoid
        _standMyAnimConn = hum.AnimationPlayed:Connect(onAnimPlayed)

        -- Fallback: conecta também via Animator caso o Humanoid não dispare
        if animator then
            local animatorConn = animator.AnimationPlayed:Connect(onAnimPlayed)
            -- Armazena junto para desconectar depois
            local origConn = _standMyAnimConn
            _standMyAnimConn = {
                Disconnect = function()
                    pcall(function() origConn:Disconnect() end)
                    pcall(function() animatorConn:Disconnect() end)
                end
            }
        end
    end

    _startFollowLoop = function()
        if _standHeartbeat then _standHeartbeat:Disconnect() _standHeartbeat = nil end
        _standHeartbeat = RunService.Heartbeat:Connect(function()
            if not _standActive or _suppressFollow > 0 then return end
            if not _standTarget or not _standTarget.Character then return end
            if not lp.Character then return end
            local myHRP     = lp.Character:FindFirstChild('HumanoidRootPart')
            local targetHRP = _standTarget.Character:FindFirstChild('HumanoidRootPart')
            if not myHRP or not targetHRP then return end
            local hum = lp.Character:FindFirstChildOfClass('Humanoid')
            if hum then
                pcall(function() hum.AutoRotate = false end)
                if _standFollowMode then hum.PlatformStand = true end
            end
            if _standFollowMode then
                _removeCollision()
                -- Mesmo método do toggleWeld: CFrame direto + zera velocidades + PhysicsRepRootPart
                myHRP.CFrame                  = targetHRP.CFrame * _currentOffset
                myHRP.AssemblyLinearVelocity  = Vector3.zero
                myHRP.AssemblyAngularVelocity = Vector3.zero
                if sethiddenproperty then
                    pcall(function() sethiddenproperty(myHRP, 'PhysicsRepRootPart', targetHRP) end)
                end
                -- Idle watchdog: if the stand is just chilling (no suppress) and the idle
                -- track is dead or never started, restart it. 1s debounce to not spam LoadAnimation.
                local _needIdle = false
                if not _standIdleTrack then
                    _needIdle = true
                else
                    local _ok, _playing = pcall(function() return _standIdleTrack.IsPlaying end)
                    _needIdle = not _ok or not _playing
                end
                if _needIdle then
                    local now = tick()
                    if now - _lastIdleStart >= 1 then
                        _lastIdleStart = now
                        task.defer(_startIdleAnim)
                    end
                end
            end
        end)
    end

    local function _standActivate(targetPlayer)
        _standDisconnectAll()
        _standActive = true
        _standTarget = targetPlayer
        _currentOffset = _idleOffset
        local char = targetPlayer.Character
        if not char then
            _standCharConn = targetPlayer.CharacterAdded:Connect(function(char)
                local hum = char:WaitForChild('Humanoid', 10)
                if not hum then return end
                hum:WaitForChild('Animator', 10)
                _standActivate(targetPlayer)
            end)
            return
        end
        _applyAttach()
        _hookTargetAnims(targetPlayer)
        _hookLocalAnims()
        _startFollowLoop()
        task.defer(_startIdleAnim)
        _standCharConn = targetPlayer.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild('Humanoid', 10)
            if not hum then return end
            hum:WaitForChild('Animator', 10)
            if _standActive then _standActivate(targetPlayer) end
        end)
        -- Deactivate Stand if the target player leaves the game (mirrors Attach behaviour)
        if _standPlayerRemovingConn then _standPlayerRemovingConn:Disconnect() end
        _standPlayerRemovingConn = game:GetService("Players").PlayerRemoving:Connect(function(p)
            if p == targetPlayer then
                _standDeactivate()
                pcall(function() Options.StandMethodDropdown:SetValue("Off") end)
                Library:Notify({ Title = bypassText("Stand"), Content = "Target has left the game.", Time = 3 })
            end
        end)
        if _standMyCharConn then _standMyCharConn:Disconnect() end
        _standMyCharConn = lp.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild('Humanoid', 10)
            if not hum then return end
            hum:WaitForChild('Animator', 10)
            if not _standActive then return end
            -- our old animator is dead after respawn; purge stale idle state before anything else
            if _standIdleRenderConn then _standIdleRenderConn:Disconnect() _standIdleRenderConn = nil end
            if _standIdleTrack then pcall(function() _standIdleTrack:Stop(0) end) _standIdleTrack = nil end
            _lastIdleStart = 0  -- let watchdog fire immediately
            _applyAttach()
            _hookLocalAnims()
            if _standFollowMode then task.defer(_startIdleAnim) end
        end)
    end

    local function _standDeactivate()
        _standActive = false
        _standDisconnectAll()
        if _standMyCharConn then _standMyCharConn:Disconnect() _standMyCharConn = nil end
    end

    local function _getPlayerNames()
        local _lp = game:GetService("Players").LocalPlayer
        local names = {}
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            if p ~= _lp then table.insert(names, _makePlayerLabel(p)) end
        end
        return names
    end

    -- ── UI ───────────────────────────────────────────────────────────────────
    local _standPlayerNames = _getPlayerNames()

    local _standLastDropVal = ""
    local StandDropdown = TabExpStand:AddDropdown("StandTargetDropdown", {
        Text       = "Target Player",
        Values     = _standPlayerNames,
        Default    = "",
        Searchable = true,
        AllowNull  = true,
        Callback   = function(val)
            if val ~= "" and val == _standLastDropVal then
                pcall(function() Options.StandTargetDropdown:SetValue("") end)
                _standLastDropVal = ""
                _standDeactivate()
                _standTarget = nil
                return
            end
            _standLastDropVal = val
            local wasActive = _standActive
            _standDeactivate()
            local newTarget = _findPlayerByLabel(val)
            if newTarget then
                _standTarget = newTarget
                if wasActive then _standActivate(newTarget) end
            end
        end,
    })

    game:GetService("Players").PlayerAdded:Connect(function()
        pcall(function() StandDropdown:SetValues(_getPlayerNames()) end)
    end)
    game:GetService("Players").PlayerRemoving:Connect(function()
        pcall(function() StandDropdown:SetValues(_getPlayerNames()) end)
    end)

    TabExpStand:AddDropdown("StandMethodDropdown", {
        Text    = "Stand Method",
        Values  = { "Off", "Follow", "Don't Follow" },
        Default = "Off",
        Callback = function(val)
            if val == "Off" then
                _standActive = false
                _standFollowMode = true
                _standDeactivate()

            elseif val == "Follow" then
                _standFollowMode = true
                local targetName = Options.StandTargetDropdown and Options.StandTargetDropdown.Value or ""
                local target = _findPlayerByLabel(tostring(targetName))
                if target then
                    _standActivate(target)
                else
                    Library:Notify({ Title = bypassText("Stand"), Content = "Please select a valid target first.", Time = 3 })
                    pcall(function() Options.StandMethodDropdown:SetValue("Off") end)
                end

            elseif val == "Don't Follow" then
                _standFollowMode = false
                local targetName = Options.StandTargetDropdown and Options.StandTargetDropdown.Value or ""
                local target = _findPlayerByLabel(tostring(targetName))
                if target then
                    _standActivate(target)
                    if _standHeartbeat then _standHeartbeat:Disconnect() _standHeartbeat = nil end
                    pcall(function()
                        local hum = lp.Character and lp.Character:FindFirstChildWhichIsA('Humanoid')
                        if hum then hum.PlatformStand = false end
                    end)
                else
                    Library:Notify({ Title = bypassText("Stand"), Content = "Please select a valid target first.", Time = 3 })
                    pcall(function() Options.StandMethodDropdown:SetValue("Off") end)
                end
            end
        end,
    })

    do
        local _idleAnimNames = { "Random" }
        for _, v in ipairs(_idleVariants) do
            _idleAnimNames[#_idleAnimNames + 1] = v.name
        end
        TabExpStand:AddDropdown("StandIdleAnimDropdown", {
            Text     = "Idle Animation",
            Values   = _idleAnimNames,
            Default  = "Random",
            Callback = function()
                -- restart immediately so the new pick takes effect without waiting for the next idle cycle
                if _standActive and _standFollowMode then
                    if _standIdleRenderConn then _standIdleRenderConn:Disconnect() _standIdleRenderConn = nil end
                    if _standIdleTrack then pcall(function() _standIdleTrack:Stop(0) end) _standIdleTrack = nil end
                    _lastIdleStart = 0
                    task.defer(_startIdleAnim)
                end
            end,
        })
    end

    TabExpStand:AddLabel("How to use Stand:", true)
    TabExpStand:AddLabel("Select a target and choose Follow or Don't Follow.", true)
    TabExpStand:AddLabel("Stand attaches behind the target and mirrors their position.", true)
    TabExpStand:AddLabel("3 blocks in a row from the target toggles the mode.", true)
    TabExpStand:AddLabel("When you use a move and the target has that move on cooldown, Stand auto-uses it.", true)
    TabExpStand:AddLabel("In Don't Follow mode, you stay in place. Stand only acts during your moves.", true)

    local function _registerStandGlobals()
        getgenv()._standActivateFn = function(targetPlayer)
            _standActivate(targetPlayer)
            _registerStandGlobals()
        end

        getgenv()._standDeactivateFn = function()
            _standDeactivate()
            _registerStandGlobals()
        end
    end
    _registerStandGlobals()
end
-- ── END STAND ─────────────────────────────────────────────────────────────────

-- ── INVISIBLE MOVES UI ────────────────────────────────────────────────────────
TabExpInvisibleMoves:AddButton({
    Text = 'Toggle All On',
    Callback = function()
        for k, v in pairs(Toggles) do
            if k:find('^InvisibleMoves_') and v.Type == 'Toggle' then v:SetValue(true) end
        end
        for k, v in pairs(Options) do
            if k:find('^InvisibleMoves_') and v.Type == 'Dropdown' then
                local all = {}
                for _, val in pairs(v.Values) do all[val] = true end
                v:SetValue(all)
            end
        end
    end,
}):AddButton({
    Text = 'Toggle All Off',
    Callback = function()
        for k, v in pairs(Toggles) do
            if k:find('^InvisibleMoves_') and v.Type == 'Toggle' then v:SetValue(false) end
        end
        for k, v in pairs(Options) do
            if k:find('^InvisibleMoves_') and v.Type == 'Dropdown' then v:SetValue({}) end
        end
    end,
})
TabExpInvisibleMoves:AddToggle('InvisibleMoves_Block', {
    Text = 'Invisible Block',
    Default = false,
})
TabExpInvisibleMoves:AddToggle('InvisibleMoves_BlockColor', {
    Text = 'Block Color',
    Default = false,
}):AddColorPicker('InvisibleMoves_BlockColor1', {
    Default = Color3.fromRGB(0, 255, 255),
    Title = 'Start',
}):AddColorPicker('InvisibleMoves_BlockColor2', {
    Default = Color3.fromRGB(0, 0, 255),
    Title = 'Middle',
    Transparency = 0,
}):AddColorPicker('InvisibleMoves_BlockColor3', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'End',
    Transparency = 0,
})
TabExpInvisibleMoves:AddToggle('InvisibleMoves_Counter', {
    Text = 'Invisible Counter',
    Default = false,
})
TabExpInvisibleMoves:AddToggle('InvisibleMoves_CounterHit', {
    Text = 'Invisible Counter Hit',
    Default = false,
})
TabExpInvisibleMoves:AddDropdown('InvisibleMoves_Saitama', {
    Text = 'Invisible Saitama',
    Values = { 'Invisible Ult', 'Invisible Table Flip', 'Invisible Serious Punch', 'Invisible Omni-Directional Punch' },
    Multi = true, Default = {}, Searchable = true,
})
TabExpInvisibleMoves:AddDropdown('InvisibleMoves_Garou', {
    Text = 'Invisible Garou',
    Values = { 'Invisible Ult' },
    Multi = true, Default = {}, Searchable = true,
})
TabExpInvisibleMoves:AddDropdown('InvisibleMoves_Sonic', {
    Text = "Invisible Speed-o'-Sonic",
    Values = { 'Invisible Ult' },
    Multi = true, Default = {}, Searchable = true,
})
TabExpInvisibleMoves:AddDropdown('InvisibleMoves_Genos', {
    Text = 'Invisible Genos',
    Values = { 'Invisible Ult', 'Invisible Incinerate' },
    Multi = true, Default = {}, Searchable = true,
})
TabExpInvisibleMoves:AddDropdown('InvisibleMoves_Tatsumaki', {
    Text = 'Invisible Tatsumaki',
    Values = { 'Invisible Crushing Pull', 'Invisible Windstorm Fury', 'Invisible Stone Grave', 'Invisible Expulsive Push', 'Invisible Ult', 'Invisible Terrible Tornado', 'Invisible Terrible Tornado Finisher' },
    Multi = true, Default = {}, Searchable = true,
})
TabExpInvisibleMoves:AddDropdown('InvisibleMoves_AtomicSamurai', {
    Text = 'Invisible Atomic Samurai',
    Values = { 'Invisible Atmos Cleave', 'Invisible Ult', 'Invisible Sunset', 'Invisible Solar Cleave', 'Invisible Sunrise', 'Invisible Sunrise Finisher', 'Invisible Atomic Slash', 'Invisible Atomic Slash Finisher' },
    Multi = true, Default = {}, Searchable = true,
})
TabExpInvisibleMoves:AddDropdown('InvisibleMoves_Suiryu', {
    Text = 'Invisible Suiryu',
    Values = { 'Bullet Barrage' },
    Multi = true, Default = {}, Searchable = true,
})
-- ── END INVISIBLE MOVES UI ────────────────────────────────────────────────────
-- Update Log labels removidos
local ANIMS_CONFIG = {
    L_KEY   = { Id = "121572214", Speed = 1, StartTime = 0.5, Track = nil, IsActive = false },
    F2_KEY  = { Id = "179224234", Speed = 1, StartTime = 0,   Track = nil, IsActive = false },
    TPOSE_A = { Id = "15503004900", Speed = 0, StartTime = 1.6, Track = nil, IsActive = false },
    JERK    = { Id = "72042024",  Speed = 1, StartTime = 0,   Track = nil, IsActive = false },
    BANG    = { Id = "148840371", Speed = 1, StartTime = 0,   Track = nil, IsActive = false, Priority = Enum.AnimationPriority.Action4 },
    WAVE    = { Id = "128777973", Speed = 1, StartTime = 0,   Track = nil },
    POINT   = { Id = "128853357", Speed = 1, StartTime = 0,   Track = nil },
    HAPPY   = { Id = "129423030", Speed = 1, StartTime = 0,   Track = nil },
    LAUGH   = { Id = "129423131", Speed = 1, StartTime = 0,   Track = nil },
    MUSTACHE = { Id = "65067813", Speed = 0, StartTime = 0.2, Track = nil, IsActive = false, Priority = Enum.AnimationPriority.Action4 },
}
local SPECIAL_WEIGHTS = {
    ["121572214"] = 1e13,
    ["72042024"]  = 1e13,
    ["179224234"] = -1e9,
    ["15503004900"] = 1e7,
    ["180435571"] = 1e5,
    ["148840371"] = -1e9,
    ["65067813"]  = -1e9,
    ["128777973"] = -1e9,
    ["128853357"] = -1e9,
    ["129423030"] = -1e9,
    ["129423131"] = -1e9,
}
local SpamDelay  = 0.1
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local lp         = Players.LocalPlayer
local maintenanceConnection
local currentEmoteTrack = nil
local emoteActive       = false
local stoppedToggles    = {}
local savedToggleStates = {}
local TPoseActive            = false
local TPoseLoop              = nil
local tposeCachedAnimator    = nil
local headFloatSpamLoop = nil
local WeldActive        = false
local WeldConnection    = nil
local WeldOriginalFPDH  = nil
local WeldSavedPos      = nil
local WeldState         = {target = nil, player = nil}
local WeldPartsState    = {}
local StarterCharacter  = isGamepassesGame and game:GetService("StarterPlayer"):FindFirstChild("StarterCharacter") or nil
local ShorterCooldown        = true
local FlingSelectedTargets   = {}
local FlingActive            = false
_loopFlingMode               = nil  -- 'all' | 'others' | nil (specific player)
local _flingViewActive       = false
local _userViewActive        = false
local _vsEnableNoclip  = function() end
local _vsDisableNoclip = function() end
local _pU59 = {
    Flying                   = false,
    ['Touch Fling']          = false,
    ['Touch Fling Settings'] = Vector3.new(0, 0, 0),
}
local _pU525 = {
    Fly            = false,
    ['Lock-on']    = false,
    ['Touch Fling']= false,
}
getgenv().InvisActive       = false
getgenv().FUCActive         = false
getgenv().OldPos            = nil
getgenv().FPDH              = workspace.FallenPartsDestroyHeight
workspace.FallenPartsDestroyHeight = 0/0
local _voidProtConn = workspace:GetPropertyChangedSignal("FallenPartsDestroyHeight"):Connect(function()
    local h = workspace.FallenPartsDestroyHeight
    if h == h then
        workspace.FallenPartsDestroyHeight = 0/0
    end
end)
local _voidFloor = Instance.new("Part", workspace)
_voidFloor.CFrame       = CFrame.new(0, -10008, 0)
_voidFloor.Anchored     = true
_voidFloor.Size         = Vector3.new(2048, 10, 2048)
_voidFloor.Transparency = 0.5
_voidFloor.CanCollide   = true
_voidFloor.Name         = game:GetService("HttpService"):GenerateGUID()
local _voidSavedHealth   = 100
local _voidHealthConn    = nil
local _voidRenderConn    = nil
local _voidCharConn      = nil
local function _hookVoidProtChar(char)
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
    local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
    if not hum or not root then return end
    _voidSavedHealth = hum.Health
    if _voidHealthConn then _voidHealthConn:Disconnect() _voidHealthConn = nil end
    if _voidRenderConn then _voidRenderConn:Disconnect() _voidRenderConn = nil end
    _voidRenderConn = RunService.RenderStepped:Connect(function()
        local r = char:FindFirstChild("HumanoidRootPart")
        if r then
            _voidSavedHealth = hum.Health
            _voidFloor.CFrame = CFrame.new(r.Position.X, -10008, r.Position.Z)
        end
    end)
    _voidHealthConn = hum.HealthChanged:Connect(function(hp)
        local r = char:FindFirstChild("HumanoidRootPart")
        if hp <= 0 and r and r.CFrame.Y <= 0 then
            hum.Health = _voidSavedHealth
        end
    end)
end
_hookVoidProtChar(lp.Character)
_voidCharConn = lp.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    _hookVoidProtChar(char)
end)
local viewDied             = nil
local viewChanged          = nil
local playerDiedConnection = nil
local _viewChanging        = false
local CleanupTasks = {}
local _movingExclusionConns = {}
local _movingExclusionOwned = setmetatable({}, { __mode = "k" })
local function _ensureMovingExclusion(char)
    if not char then return nil end
    local existing = char:FindFirstChild("MovingExclusion")
    if existing then return existing end
    local marker = Instance.new("Folder")
    marker.Name = "MovingExclusion"
    pcall(function() marker:SetAttribute("RevenantOwned", true) end)
    marker.Parent = char
    _movingExclusionOwned[marker] = true
    return marker
end
local function _hookMovingExclusionChar(char)
    if not char then return end
    _ensureMovingExclusion(char)
    local conn = char.ChildRemoved:Connect(function(child)
        if child.Name == "MovingExclusion" and getgenv().RevenantLoaded then
            task.defer(_ensureMovingExclusion, char)
        end
    end)
    table.insert(_movingExclusionConns, conn)
end
_hookMovingExclusionChar(lp.Character)
table.insert(_movingExclusionConns, lp.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    _hookMovingExclusionChar(char)
end))
table.insert(CleanupTasks, function()
    for _, conn in ipairs(_movingExclusionConns) do
        pcall(function() conn:Disconnect() end)
    end
    _movingExclusionConns = {}
    local char = lp.Character
    local marker = char and char:FindFirstChild("MovingExclusion")
    if marker and (_movingExclusionOwned[marker] or marker:GetAttribute("RevenantOwned")) then
        pcall(function() marker:Destroy() end)
    end
end)
if getgenv()._standDeactivateFn then
    table.insert(CleanupTasks, getgenv()._standDeactivateFn)
end
local FlingDropdown        = nil
local function isChatFocused()
    return UIS:GetFocusedTextBox() ~= nil
end
local function getDisplayName(player)
    local ok, displayName = pcall(function() return player.DisplayName end)
    if not ok or not displayName or displayName == "" then return player.Name end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.DisplayName == displayName then
            return player.Name
        end
    end
    return displayName
end
local function getFlingPlayersList()
    local tbl = {}
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= lp then tbl[#tbl+1] = _makePlayerLabel(v) end
    end
    return tbl
end
local function findPlayerByDisplayName(label)
    return _findPlayerByLabel(label)
end
local function stopCurrentView()
    if viewDied    then viewDied:Disconnect()    viewDied    = nil end
    if viewChanged then viewChanged:Disconnect() viewChanged = nil end
end
local function setView(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent then return end
    stopCurrentView()
    if targetPlayer.Character then
        pcall(function()
            _viewChanging = true
            workspace.CurrentCamera.CameraSubject = targetPlayer.Character
            _viewChanging = false
        end)
    end
    viewDied = targetPlayer.CharacterAdded:Connect(function()
        repeat task.wait() until targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        pcall(function()
            _viewChanging = true
            workspace.CurrentCamera.CameraSubject = targetPlayer.Character
            _viewChanging = false
        end)
    end)
    viewChanged = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
        if _viewChanging then return end
        if not targetPlayer or not targetPlayer.Parent then
            stopCurrentView()
            pcall(function() workspace.CurrentCamera.CameraSubject = lp.Character end)
            return
        end
        if targetPlayer.Character then
            pcall(function()
                _viewChanging = true
                workspace.CurrentCamera.CameraSubject = targetPlayer.Character
                _viewChanging = false
            end)
        end
    end)
end
local function restoreView()
    stopCurrentView()
    pcall(function() workspace.CurrentCamera.CameraSubject = lp.Character end)
end
local function saveToggleStates()
    savedToggleStates = {}
    for key, data in pairs(ANIMS_CONFIG) do
        if key ~= "WAVE" and key ~= "POINT" and key ~= "HAPPY" and key ~= "LAUGH"
            and key ~= "F2_KEY" then
            savedToggleStates[key] = data.IsActive
        end
    end
    savedToggleStates["__TPoseActive"]    = TPoseActive
end
local function restoreToggleStates()
    if not next(savedToggleStates) then return end
    local char    = lp.Character
    local timeout = tick() + 2
    while not char and tick() < timeout do task.wait(0.05) char = lp.Character end
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 1)
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 1)
    if not animator then return end
    task.wait(0.05)
    for key, wasActive in pairs(savedToggleStates) do
        if key:sub(1, 2) == "__" then continue end
        if wasActive and not ANIMS_CONFIG[key].IsActive then
            ANIMS_CONFIG[key].IsActive = false
            task.spawn(function() toggleAnim(ANIMS_CONFIG[key]) end)
        end
    end
    if savedToggleStates["__TPoseActive"]    and not TPoseActive    then task.spawn(toggleTPose)    end
end
local function stopAnimation(data)
    if data.Track then
        data.Track:Stop()
        data.Track:Destroy()
        data.Track = nil
    end
end
local function stopTPoseTracks()
    local dA = ANIMS_CONFIG.TPOSE_A
    if dA.Track then pcall(function() if dA.Track.IsPlaying then dA.Track:Stop() end end) pcall(function() dA.Track:Destroy() end) dA.Track = nil end
    tposeCachedAnimator = nil
end
local function loadTPoseTrack(data, animator, priority, weight)
    local anim  = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. data.Id
    local track = animator:LoadAnimation(anim)
    track.Priority = priority
    track.Looped   = true
    track:Play()
    track:AdjustSpeed(0)
    if data.StartTime and data.StartTime > 0 then track.TimePosition = data.StartTime end
    pcall(function() track:AdjustWeight(weight or 1e8) end)
    return track
end
local function playAnimation(data, looped, priority)
    looped = looped == nil and true or looped
    local character = lp.Character
    if not character then return end
    local humanoid  = character:FindFirstChildOfClass("Humanoid")
    local animator  = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    if data.Track and data.Track.IsPlaying then return data.Track end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. data.Id
    data.Track = animator:LoadAnimation(anim)
    local isChief = (data.Id == "121572214" or data.Id == "72042024")
    data.Track.Priority = data.Priority or (isChief and Enum.AnimationPriority.Action4 or Enum.AnimationPriority.Action3)
    data.Track.Looped   = looped
    local specialWeight = SPECIAL_WEIGHTS[data.Id]
    if specialWeight then data.Track:AdjustWeight(specialWeight) end
    data.Track:Play()
    data.Track:AdjustSpeed(data.Speed)
    data.Track.TimePosition = data.StartTime
    return data.Track
end
local EXCLUDE = { WAVE=true, POINT=true, HAPPY=true, LAUGH=true, F2_KEY=true, TPOSE_A=true }
local function stopAllToggles(exceptL_KEY, fromInvis)
    stoppedToggles = {}
    for key, data in pairs(ANIMS_CONFIG) do
        if not EXCLUDE[key] then
            if exceptL_KEY and key == "L_KEY" then continue end
            if fromInvis and (key == "L_KEY" or key == "JERK") then continue end
            if data.IsActive and data.Track and data.Track.IsPlaying then
                stoppedToggles[key] = true
                data.Track:Stop()
            end
        end
    end
    if TPoseActive then
        stoppedToggles["TPOSE_A"] = true
        if TPoseLoop then TPoseLoop:Disconnect() TPoseLoop = nil end
        stopTPoseTracks()
        TPoseActive = false
        if not fromInvis then
            pcall(function() if Toggles.TogTPose then _guard.TPose = true Toggles.TogTPose:SetValue(false) _guard.TPose = false end end)
        end
    end
end
local function restartAllToggles(fromInvis)
    for key, data in pairs(ANIMS_CONFIG) do
        if not EXCLUDE[key] then
            if fromInvis and (key == "L_KEY" or key == "JERK") then continue end
            if stoppedToggles[key] and data.IsActive then
                if data.Track then
                    data.Track:Play()
                    data.Track:AdjustSpeed(data.Speed)
                else playAnimation(data, true, Enum.AnimationPriority.Action4) end
            end
        end
    end
    if stoppedToggles["TPOSE_A"] and not fromInvis and Toggles.TogTPose and Toggles.TogTPose.Value then
        TPoseActive = false
        TPoseLoop = RunService.Heartbeat:Connect(function()
            if getgenv().InvisActive or getgenv().FUCActive then return end
            local char     = lp.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
            if not animator then return end
            if tposeCachedAnimator ~= animator then
                stopTPoseTracks()
                tposeCachedAnimator = animator
                ANIMS_CONFIG.TPOSE_A.Track = loadTPoseTrack(ANIMS_CONFIG.TPOSE_A, animator, Enum.AnimationPriority.Action3, 1e12)
                return
            end
            local dA = ANIMS_CONFIG.TPOSE_A
            if not dA.Track or not dA.Track.IsPlaying then
                if dA.Track then pcall(function() dA.Track:Destroy() end) end
                dA.Track = loadTPoseTrack(dA, animator, Enum.AnimationPriority.Action3, 1e12)
            end
        end)
        TPoseActive = true
    end
    stoppedToggles = {}
end
local function toggleAnim(data)
    data.IsActive = not data.IsActive
    if data.IsActive then
        playAnimation(data, true, Enum.AnimationPriority.Action4)
    else
        stopAnimation(data)
    end
    if data.IsActive and not maintenanceConnection then
        maintenanceConnection = RunService.Heartbeat:Connect(function()
            if emoteActive then return end
            for key, d in pairs(ANIMS_CONFIG) do
                if not EXCLUDE[key] and d.IsActive then
                    if getgenv().InvisActive and key ~= "L_KEY" and key ~= "JERK" then continue end
                    if not d.Track or d.Track.Parent == nil then
                        playAnimation(d, true, Enum.AnimationPriority.Action4)
                    else
                        if not d.Track.IsPlaying then d.Track:Play() end
                        if key == "L_KEY" and d.Track.TimePosition < 0.1 then d.Track.TimePosition = 0.5 end
                    end
                end
            end
        end)
    elseif not data.IsActive then
        local anyActive = false
        for key, d in pairs(ANIMS_CONFIG) do
            if not EXCLUDE[key] and d.IsActive then anyActive = true break end
        end
        if not anyActive and maintenanceConnection then
            maintenanceConnection:Disconnect()
            maintenanceConnection = nil
        end
    end
end
local function playEmote(data)
    if currentEmoteTrack then
        local old = currentEmoteTrack
        currentEmoteTrack = nil
        pcall(function() old:Stop() end)
        pcall(function() old:Destroy() end)
    end
    if not emoteActive then
        stopAllToggles(true)
        emoteActive = true
    end
    currentEmoteTrack = playAnimation(data, false, Enum.AnimationPriority.Action4)
    if currentEmoteTrack then
        currentEmoteTrack.Stopped:Connect(function()
            if currentEmoteTrack then currentEmoteTrack:Destroy() currentEmoteTrack = nil end
            emoteActive = false
            restartAllToggles()
        end)
    end
end
local function GetIndex(match)
    for _, v in pairs(lp.PlayerGui.Hotbar.Backpack.Hotbar:GetDescendants()) do
        if v.Name == "ToolName" and v.Text:match(match) then return v.Parent end
    end
    return nil
end
local function makeHadFF()
    local hadFF = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChild("ForceField") then
            hadFF[p] = true
        end
    end
    return hadFF
end
local function toggleTPose()
    if getgenv().InvisActive or getgenv().FUCActive then return end
    if TPoseLoop then TPoseLoop:Disconnect() TPoseLoop = nil end
    TPoseActive = not TPoseActive
    if TPoseActive then
        local char     = lp.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not animator then TPoseActive = false return end
        stopTPoseTracks()
        tposeCachedAnimator = animator
        ANIMS_CONFIG.TPOSE_A.Track = loadTPoseTrack(ANIMS_CONFIG.TPOSE_A, animator, Enum.AnimationPriority.Action3, 1e12)
        TPoseLoop = RunService.Heartbeat:Connect(function()
            if getgenv().InvisActive or getgenv().FUCActive then return end
            local c    = lp.Character
            local hum  = c and c:FindFirstChildOfClass("Humanoid")
            local anim = hum and hum:FindFirstChildOfClass("Animator")
            if not anim then return end
            if tposeCachedAnimator ~= anim then
                stopTPoseTracks()
                tposeCachedAnimator = anim
                ANIMS_CONFIG.TPOSE_A.Track = loadTPoseTrack(ANIMS_CONFIG.TPOSE_A, anim, Enum.AnimationPriority.Action3, 1e12)
                return
            end
            local dA = ANIMS_CONFIG.TPOSE_A
            if not dA.Track or not dA.Track.IsPlaying then
                if dA.Track then pcall(function() dA.Track:Destroy() end) end
                dA.Track = loadTPoseTrack(dA, anim, Enum.AnimationPriority.Action3, 1e12)
            end
        end)
    else
        stopTPoseTracks()
    end
end
local WeldPlayerRemoving = nil
local _hbxRotConn = nil
local _hbxMyRoot  = nil
local function toggleWeld()
    local char = lp.Character
    if WeldActive then
        WeldActive = false
        if WeldConnection    then WeldConnection:Disconnect()    WeldConnection    = nil end
        if WeldPlayerRemoving then WeldPlayerRemoving:Disconnect() WeldPlayerRemoving = nil end
        if _hbxRotConn then
            _hbxRotConn:Disconnect()
            _hbxRotConn = nil
        end
        local currentChar = lp.Character
        local root = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        -- Reset root local
        if root then
            if sethiddenproperty then
                pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", nil) end)
            end
            root.AssemblyLinearVelocity  = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            pcall(function() root.Velocity    = Vector3.zero end)
            pcall(function() root.RotVelocity = Vector3.zero end)
        end
        -- Reset target
        if WeldState.target and WeldState.target.Parent then
            pcall(function() sethiddenproperty(WeldState.target, "PhysicsRepRootPart", nil) end)
            pcall(function() WeldState.target.AssemblyLinearVelocity  = Vector3.zero end)
            pcall(function() WeldState.target.AssemblyAngularVelocity = Vector3.zero end)
            pcall(function() WeldState.target.Velocity                = Vector3.zero end)
            pcall(function() WeldState.target.RotVelocity             = Vector3.zero end)
        end
        WeldState.target = nil
        WeldState.player = nil
        local _togOffHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
        if _togOffHum then
            pcall(function() _togOffHum.AutoRotate = true end)
            pcall(function() _togOffHum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        if WeldSavedPos and root then
            local _savedCF = WeldSavedPos
            WeldSavedPos = nil
            task.spawn(function()
                for _ = 1, 4 do
                    RunService.Heartbeat:Wait()
                    root.AssemblyLinearVelocity  = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    pcall(function() root.Velocity    = Vector3.zero end)
                    pcall(function() root.RotVelocity = Vector3.zero end)
                    root.CFrame = _savedCF
                end
            end)
        end
        pcall(function() _guard.Weld = true Toggles.TogWeld:SetValue(false) _guard.Weld = false end)
        pcall(function() Options.KPWeld.Toggled = false end)
        if not _shpSupported and not _userViewActive then restoreView() end
        Library:Notify({ Title = _shpSupported and "Attach" or "Orbit", Content = "Toggled off ❌", Time = 2 })
        return
    end
    local _hasTarget = false
    do
        local camera   = workspace.CurrentCamera
        local myRoot   = char and char:FindFirstChild("HumanoidRootPart")
        local targets = {}
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            table.insert(targets, p)
        end
        local liveFolder = workspace:FindFirstChild("Live")
        if liveFolder then
            for _, m in ipairs(liveFolder:GetChildren()) do
                if m:IsA("Model") and m:FindFirstChild("Humanoid") then
                    table.insert(targets, m)
                end
            end
        end
        for _, player in ipairs(targets) do
            local isLocalPlayer = (player == lp) or (typeof(player) == "Instance" and player:IsA("Model") and player == lp.Character)
            if not isLocalPlayer then
                local pc = (typeof(player) == "Instance" and player:IsA("Player") and player.Character) or player
                if pc then
                    local hum = pc:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        _hasTarget = true
                        break
                    end
                end
            end
        end
    end
    if not _hasTarget then return end
    if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    WeldActive = true
    WeldSavedPos = myRoot.CFrame
    myRoot.AssemblyLinearVelocity  = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
    if sethiddenproperty then
        pcall(function() sethiddenproperty(myRoot, "PhysicsRepRootPart", myRoot) end)
    end
    pcall(function() _guard.Weld = true Toggles.TogWeld:SetValue(true) _guard.Weld = false end)
    pcall(function() Options.KPWeld.Toggled = true end)
    local function _weldPickTarget()
        local camera   = workspace.CurrentCamera
        local mousePos = UIS:GetMouseLocation()
        local bestDist = math.huge
        local bestPlayer, bestRoot = nil, nil
        local targets = {}
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            table.insert(targets, p)
        end
        local liveFolder = workspace:FindFirstChild("Live")
        if liveFolder then
            for _, m in ipairs(liveFolder:GetChildren()) do
                if m:IsA("Model") and m:FindFirstChild("Humanoid") then
                    table.insert(targets, m)
                end
            end
        end

        for _, player in ipairs(targets) do
            local isLocalPlayer = (player == lp) or (typeof(player) == "Instance" and player:IsA("Model") and player == lp.Character)
            if isLocalPlayer then continue end
            local pc  = (typeof(player) == "Instance" and player:IsA("Player") and player.Character) or player
            if not pc then continue end
            local hum = pc:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local root = hum.RootPart or pc:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            if hum.Health ~= 0 and workspace.CurrentCamera then
                local sp = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
                local d  = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if d < bestDist then
                    bestDist   = d
                    bestPlayer = player
                    bestRoot   = root
                end
            end
        end
        return bestRoot, bestPlayer
    end
    local _lockedTarget, _lockedPlayer = _weldPickTarget()
    WeldState.target = _lockedTarget
    WeldState.player = _lockedPlayer
    if not _lockedTarget or not _lockedPlayer then
        WeldActive = false
        pcall(function() _guard.Weld = true Toggles.TogWeld:SetValue(false) _guard.Weld = false end)
        pcall(function() Options.KPWeld.Toggled = false end)
        local currentChar = lp.Character
        local root = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity  = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            pcall(function() root.Velocity    = Vector3.zero end)
            pcall(function() root.RotVelocity = Vector3.zero end)
        end
        return
    end
    local _weldPickTarget_ref = nil -- placeholder to keep scope consistent
    local function _weldStop()
        WeldActive = false
        if WeldConnection    then WeldConnection:Disconnect()    WeldConnection    = nil end
        if WeldPlayerRemoving then WeldPlayerRemoving:Disconnect() WeldPlayerRemoving = nil end
        -- kill HBX RenderStepped conn if it was running
        pcall(function()
            if _hbxRotConn then
                _hbxRotConn:Disconnect()
                _hbxRotConn = nil
                if _hbxMyRoot and _hbxMyRoot.Parent then
                    local _h = _hbxMyRoot.Parent:FindFirstChildOfClass("Humanoid")
                    if _h then pcall(function() _h.AutoRotate = true end) end
                end
                _hbxMyRoot = nil
            end
        end)
        local currentChar = lp.Character
        local root = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        -- Reset root local
        if root then
            if sethiddenproperty then
                pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", nil) end)
            end
            root.AssemblyLinearVelocity  = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            pcall(function() root.Velocity    = Vector3.zero end)
            pcall(function() root.RotVelocity = Vector3.zero end)
        end
        -- Reset target
        if WeldState.target and WeldState.target.Parent then
            pcall(function() sethiddenproperty(WeldState.target, "PhysicsRepRootPart", nil) end)
            pcall(function() WeldState.target.AssemblyLinearVelocity  = Vector3.zero end)
            pcall(function() WeldState.target.AssemblyAngularVelocity = Vector3.zero end)
            pcall(function() WeldState.target.Velocity                = Vector3.zero end)
            pcall(function() WeldState.target.RotVelocity             = Vector3.zero end)
        end
        WeldState.target = nil
        WeldState.player = nil
        local _wsHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
        if _wsHum then
            pcall(function() _wsHum.AutoRotate = true end)
            pcall(function() _wsHum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        if WeldSavedPos and root then
            local _savedCF = WeldSavedPos
            WeldSavedPos = nil
            task.spawn(function()
                for _ = 1, 4 do
                    RunService.Heartbeat:Wait()
                    root.AssemblyLinearVelocity  = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    pcall(function() root.Velocity    = Vector3.zero end)
                    pcall(function() root.RotVelocity = Vector3.zero end)
                    root.CFrame = _savedCF
                end
            end)
        end
        pcall(function() _guard.Weld = true Toggles.TogWeld:SetValue(false) _guard.Weld = false end)
        pcall(function() Options.KPWeld.Toggled = false end)
        -- Restaura câmera ao desligar o orbit (igual ao fling)
        if not _shpSupported and not _userViewActive then
            restoreView()
        end
        Library:Notify({ Title = _shpSupported and "Attach" or "Orbit", Content = "Toggled off ❌", Time = 2 })
    end
    WeldPlayerRemoving = game:GetService("Players").PlayerRemoving:Connect(function(p)
        if p == _lockedPlayer then _weldStop() end
    end)
    if _shpSupported then
        local _attachOrbitAngle = 0
        local _hbxMyRoot = nil  -- mirrors _aaMyRoot in lock-on
        local function _hbxRotStart(myRoot, hum)
            if _hbxRotConn then return end
            _hbxMyRoot = myRoot
            _hbxRotConn = RunService.RenderStepped:Connect(function()
                if hum and hum.Parent then
                    pcall(function() hum.AutoRotate = false end)
                end
            end)
        end
        local function _hbxRotStop()
            if _hbxRotConn then _hbxRotConn:Disconnect() _hbxRotConn = nil end
            if _hbxMyRoot and _hbxMyRoot.Parent then
                local _h = _hbxMyRoot.Parent:FindFirstChildOfClass("Humanoid")
                if _h then pcall(function() _h.AutoRotate = true end) end
            end
            _hbxMyRoot = nil
        end
        -- Com sethiddenproperty: usa Heartbeat com PhysicsRepRootPart (weld real)
        WeldConnection = RunService.Heartbeat:Connect(function()
            if not WeldActive then return end
            local currentChar = lp.Character
            local currentRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
            if not currentChar or not currentRoot then
                local r = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if r then pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", nil) end) end
                return
            end
            if _lockedPlayer and _lockedPlayer.Parent then
                local tChar = (typeof(_lockedPlayer) == "Instance" and _lockedPlayer:IsA("Player") and _lockedPlayer.Character) or _lockedPlayer
                if tChar then
                    local _isHBX = Options.AttachMethod and Options.AttachMethod.Value == "Hitbox Accurate"
                    local newRoot
                    if _isHBX then
                        local _hum = tChar:FindFirstChildOfClass("Humanoid")
                        newRoot = _hum and _hum.RootPart
                        local _hbxHum = currentChar:FindFirstChildOfClass("Humanoid")
                        if _hbxHum then _hbxRotStart(currentRoot, _hbxHum) end
                    else
                        if _hbxRotConn then _hbxRotStop() end
                        newRoot = tChar:FindFirstChild("UpperTorso")
                            or tChar:FindFirstChild("Torso")
                            or tChar:FindFirstChild("HumanoidRootPart")
                    end
                    if newRoot then _lockedTarget = newRoot WeldState.target = newRoot end
                end
                if not _lockedTarget or not _lockedTarget.Parent then return end
            else
                _weldStop()
                return
            end
            local _isOrbit = Options.AttachMethod and Options.AttachMethod.Value == "Orbit"
            if _isOrbit then
                -- Orbit com SHP: rotaciona ao redor do target usando PhysicsRepRootPart
                local spd  = Options.AttachOrbitSpeed    and Options.AttachOrbitSpeed.Value    or 10
                local dist = Options.AttachOrbitDistance and Options.AttachOrbitDistance.Value or 3
                _attachOrbitAngle = _attachOrbitAngle + spd
                local tPos   = _lockedTarget.Position
                local offset = CFrame.Angles(0, math.rad(_attachOrbitAngle), 0) * CFrame.new(dist, 0, 0)
                local _orbitHum = currentChar:FindFirstChildOfClass("Humanoid")
                if _orbitHum then
                    local _shiftlockActive = UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
                    pcall(function() _orbitHum.AutoRotate = _shiftlockActive end)
                end
                local orbitCF = CFrame.new(tPos.X, tPos.Y, tPos.Z) * offset
                -- Aplica posição do orbit mas força o look para o target
                local lookCF = CFrame.lookAt(orbitCF.Position, Vector3.new(tPos.X, orbitCF.Position.Y, tPos.Z))
                currentRoot.CFrame = lookCF
                currentRoot.AssemblyLinearVelocity  = Vector3.zero
                currentRoot.AssemblyAngularVelocity = Vector3.zero
                pcall(function() sethiddenproperty(currentRoot, "PhysicsRepRootPart", _lockedTarget) end)
            else
                local ox = Options.WeldOffsetX and Options.WeldOffsetX.Value or 0
                local oy = Options.WeldOffsetY and Options.WeldOffsetY.Value or 0
                local oz = Options.WeldOffsetZ and Options.WeldOffsetZ.Value or 0
                currentRoot.CFrame = _lockedTarget.CFrame * CFrame.new(ox, oy, -oz)
                local _dtNow = _pU59 and _pU59['Touch Fling']
                    and Options.TouchFlingMethod and Options.TouchFlingMethod.Value == 'Death'
                if _dtNow then
                    local _Nan = 0/0
                    local _NanVec = Vector3.new(_Nan, _Nan, _Nan)
                    currentRoot.AssemblyLinearVelocity  = _NanVec
                    currentRoot.AssemblyAngularVelocity = _NanVec
                else
                    currentRoot.AssemblyLinearVelocity  = Vector3.zero
                    currentRoot.AssemblyAngularVelocity = Vector3.zero
                end
                local _weldHum = currentChar:FindFirstChildOfClass("Humanoid")
                if _weldHum then
                    local _shiftlockActive = UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
                    pcall(function() _weldHum.AutoRotate = _shiftlockActive end)
                    if _dtNow then
                        pcall(function()
                            local _Nan2 = 0/0
                            sethiddenproperty(_weldHum, "MoveDirectionInternal", Vector3.new(_Nan2, _Nan2, _Nan2))
                        end)
                    end
                end
                pcall(function()
                    sethiddenproperty(currentRoot, "PhysicsRepRootPart", _lockedTarget)
                end)
            end
        end)
    else
        -- Sem sethiddenproperty: usa orbit do Phantasm (prediction + CFrame, 100% fiel ao original)
        local _orbitAngle = 0
        if not _userViewActive then setView(_lockedPlayer) end
        task.spawn(function()
            while WeldActive do
                local cChar = lp.Character
                local cRoot = cChar and cChar:FindFirstChild("HumanoidRootPart")
                local cHum  = cChar and cChar:FindFirstChildOfClass("Humanoid")
                local tChar = _lockedPlayer and _lockedPlayer.Character
                local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum  = tChar and tChar:FindFirstChildOfClass("Humanoid")
                if cChar and cRoot and cHum and _lockedPlayer and _lockedPlayer.Parent and tChar and tRoot and tHum then
                    local spd  = Options.OrbitSpeed    and Options.OrbitSpeed.Value    or 10
                    local dist = Options.OrbitDistance and Options.OrbitDistance.Value or 3
                    _orbitAngle = _orbitAngle + spd
                    local pred   = tRoot.Position + tHum.MoveDirection * tRoot.Velocity.Magnitude / 2.75
                    local offset = CFrame.Angles(0, math.rad(_orbitAngle), 0) * CFrame.new(dist, 0, 0)
                    cRoot.CFrame = CFrame.lookAt(cRoot.Position, Vector3.new(pred.X, cRoot.Position.Y, pred.Z))
                    task.wait()
                    cRoot.CFrame = CFrame.new(pred.X, tRoot.Position.Y, pred.Z) * offset
                elseif not _lockedPlayer or not _lockedPlayer.Parent then
                    _weldStop()
                    break
                end
                RunService.RenderStepped:Wait()
            end
        end)
    end
    Library:Notify({ Title = _shpSupported and "Attach" or "Orbit", Content = "Toggled on ✅", Time = 2 })
end
-- Robust show/hide for UI elements: tries SetVisible first, falls back to Frame.Visible
local function _setElemVisible(elem, visible)
    if not elem then return end
    local ok = pcall(function() elem:SetVisible(visible) end)
    if not ok then
        pcall(function()
            local f = elem.Frame or elem.HolderFrame or elem.Container
            if f then f.Visible = visible end
        end)
    end
end
local function startHeadFloatSpam()
    headFloatSpamLoop = RunService.Heartbeat:Connect(function()
        if not Toggles.TogHeadFloat.Value then return end
        if not ANIMS_CONFIG.L_KEY.IsActive then return end
        local char     = lp.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end
        local d = ANIMS_CONFIG.L_KEY
        if not d.Track or not d.Track.IsPlaying then
            if d.Track then pcall(function() d.Track:Destroy() end) end
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. d.Id
            d.Track = animator:LoadAnimation(anim)
            d.Track.Priority = Enum.AnimationPriority.Action4
            d.Track.Looped   = true
            d.Track:AdjustWeight(1e13)
            d.Track:Play()
            d.Track:AdjustSpeed(d.Speed)
            d.Track.TimePosition = d.StartTime
        end
    end)
end
local function stopHeadFloatSpam()
    if headFloatSpamLoop then headFloatSpamLoop:Disconnect() headFloatSpamLoop = nil end
end
local _flingCharConn = lp.CharacterAdded:Connect(function()
    if FlingActive then
        FlingActive = false
        restoreView()
        if playerDiedConnection then playerDiedConnection:Disconnect() playerDiedConnection = nil end
    end
    if TPoseLoop    then TPoseLoop:Disconnect()    TPoseLoop    = nil end
    for _, data in pairs(ANIMS_CONFIG) do data.Track = nil end
    stopHeadFloatSpam()
    TPoseActive    = false
    local fd = ANIMS_CONFIG.F2_KEY
    if fd.Track then pcall(function() fd.Track:Stop() end) pcall(function() fd.Track:Destroy() end) fd.Track = nil end
    local td = ANIMS_CONFIG.TPOSE_A   if td.Track  then pcall(function() td.Track:Stop()  end) pcall(function() td.Track:Destroy()  end) td.Track  = nil end
    tposeCachedAnimator    = nil
    currentEmoteTrack = nil
    emoteActive       = false
    stoppedToggles    = {}
    task.spawn(restoreToggleStates)
end)
local _charRemovingConn = lp.CharacterRemoving:Connect(saveToggleStates)
local _guard = {}
local _akbg  = {}
local TogHeadFloat = BoxAnimsLeft:AddToggle("TogHeadFloat", {
    Text = "Head Float", Default = false,
    Callback = function(val)
        if val then
            local v = Options.SpamSpeed and Options.SpamSpeed.Value
            if v then SpamDelay = v end
        else
            if Options.KPHeadFloat then Options.KPHeadFloat.Toggled = false end
            stopHeadFloatSpam()
            if ANIMS_CONFIG.L_KEY.IsActive then toggleAnim(ANIMS_CONFIG.L_KEY) end
        end
    end,
})
TogHeadFloat:AddKeyPicker("KPHeadFloat", {
    Default = "L", Text = "Head Float", SyncToggleState = false, Mode = "Toggle",
    Callback = function()
        if not Toggles.TogHeadFloat.Value then
            Options.KPHeadFloat.Toggled = false
            return
        end
        if isChatFocused() then return end
        toggleAnim(ANIMS_CONFIG.L_KEY)
    end,
})
do
    local _dep = BoxAnimsLeft:AddDependencyBox()
    _dep:AddSlider("SpamSpeed", {
        Text = "Head Float Spam Delay", Default = 0.1, Min = 0.05, Max = 1, Rounding = 2,
        Callback = function(V) SpamDelay = V end
    })
    _dep:SetupDependencies({{ TogHeadFloat, true }})
end
local TogJerk = BoxAnimsLeft:AddToggle("TogJerk", {
    Text = "Auto Goon", Default = false,
    Callback = function(val)
        if val then
            local v = Options.JerkSpeed and Options.JerkSpeed.Value
            if v then ANIMS_CONFIG.JERK.Speed = v end
        else
            if Options.KPJerk then Options.KPJerk.Toggled = false end
            if ANIMS_CONFIG.JERK.IsActive then toggleAnim(ANIMS_CONFIG.JERK) end
        end
    end,
})
TogJerk:AddKeyPicker("KPJerk", {
    Default = "J", Text = "Auto Goon", SyncToggleState = false, Mode = "Toggle",
    Callback = function()
        if not Toggles.TogJerk.Value then
            Options.KPJerk.Toggled = false
            return
        end
        if isChatFocused() then return end
        toggleAnim(ANIMS_CONFIG.JERK)
    end,
})
do
    local _dep = BoxAnimsLeft:AddDependencyBox()
    _dep:AddSlider("JerkSpeed", {
        Text = "Auto Goon Speed", Default = 1, Min = 0, Max = 10, Rounding = 1,
        Callback = function(V)
            ANIMS_CONFIG.JERK.Speed = V
            if ANIMS_CONFIG.JERK.Track then ANIMS_CONFIG.JERK.Track:AdjustSpeed(V) end
        end
    })
    _dep:SetupDependencies({{ TogJerk, true }})
end
local TogBang = BoxAnimsLeft:AddToggle("TogBang", {
    Text = "Bang Animation", Default = false,
    Callback = function(val)
        if val then
            local v = Options.BangSpeed and Options.BangSpeed.Value
            if v then ANIMS_CONFIG.BANG.Speed = v end
        else
            if Options.KPBang then Options.KPBang.Toggled = false end
            if ANIMS_CONFIG.BANG.IsActive then toggleAnim(ANIMS_CONFIG.BANG) end
        end
    end,
})
TogBang:AddKeyPicker("KPBang", {
    Default = "P", Text = "Bang Anim", SyncToggleState = false, Mode = "Toggle",
    Callback = function()
        if not Toggles.TogBang.Value then
            Options.KPBang.Toggled = false
            return
        end
        if isChatFocused() then return end
        toggleAnim(ANIMS_CONFIG.BANG)
    end,
})
do
    local _dep = BoxAnimsLeft:AddDependencyBox()
    _dep:AddSlider("BangSpeed", {
        Text = "Bang Animation Speed", Default = 33, Min = 0, Max = 33, Rounding = 1,
        Callback = function(V)
            ANIMS_CONFIG.BANG.Speed = V
            if ANIMS_CONFIG.BANG.Track then ANIMS_CONFIG.BANG.Track:AdjustSpeed(V) end
        end
    })
    _dep:SetupDependencies({{ TogBang, true }})
end
local TogTPose = BoxAnimsLeft:AddToggle("TogTPose", {
    Text = "T-Pose", Default = false,
    Callback = function(val)
        if not val then
            if Options.KPTPose then Options.KPTPose.Toggled = false end
            if TPoseActive then toggleTPose() end
        end
    end,
})
TogTPose:AddKeyPicker("KPTPose", {
    Default = "C", Text = "T-Pose", SyncToggleState = false, Mode = "Toggle",
    Callback = function()
        if not Toggles.TogTPose.Value then Options.KPTPose.Toggled = false return end
        if isChatFocused() then return end
        if getgenv().FUCActive then
            Options.KPTPose.Toggled = TPoseActive
            return
        end
        if getgenv().InvisActive then
            getgenv()._invisSavedTPose = not (getgenv()._invisSavedTPose or false)
            return
        end
        if Options.KPTPose.Toggled == TPoseActive then return end
        toggleTPose()
    end,
})
TogHeadFloat:OnChanged(function(val)
    if _guard.HeadFloat then return end
    if isChatFocused() then _guard.HeadFloat = true TogHeadFloat:SetValue(not val) _guard.HeadFloat = false return end
    if not val then
        local kp = Options and Options.KPHeadFloat
        if kp then kp.Toggled = false end
        stopHeadFloatSpam()
        if ANIMS_CONFIG.L_KEY.IsActive then toggleAnim(ANIMS_CONFIG.L_KEY) end
    end
end)
TogJerk:OnChanged(function(val)
    if _guard.Jerk then return end
    if isChatFocused() then _guard.Jerk = true TogJerk:SetValue(not val) _guard.Jerk = false return end
    if not val then
        local kp = Options and Options.KPJerk
        if kp then kp.Toggled = false end
        if ANIMS_CONFIG.JERK.IsActive then toggleAnim(ANIMS_CONFIG.JERK) end
    end
end)
TogBang:OnChanged(function(val)
    if _guard.Bang then return end
    if isChatFocused() then _guard.Bang = true TogBang:SetValue(not val) _guard.Bang = false return end
    if not val then
        local kp = Options and Options.KPBang
        if kp then kp.Toggled = false end
        if ANIMS_CONFIG.BANG.IsActive then toggleAnim(ANIMS_CONFIG.BANG) end
    end
end)
TogTPose:OnChanged(function(val)
    if _guard.TPose then return end
    if isChatFocused() then _guard.TPose = true TogTPose:SetValue(not val) _guard.TPose = false return end
    if getgenv().InvisActive then
        getgenv()._invisSavedTPose = val
        return
    end
    if val and getgenv().FUCActive then
        _guard.TPose = true TogTPose:SetValue(false) _guard.TPose = false return
    end
    if not val and TPoseActive then toggleTPose() end
end)
RunService.Heartbeat:Connect(function()
    if not getgenv().InvisActive then return end
    local dA = ANIMS_CONFIG.TPOSE_A
    local dF = ANIMS_CONFIG.F2_KEY
    if dA.Track and dA.Track.IsPlaying then pcall(function() dA.Track:Stop(0) end) end
    if dF.Track and dF.Track.IsPlaying then pcall(function() dF.Track:Stop(0) end) end
    if TPoseActive   then
        if TPoseLoop then TPoseLoop:Disconnect() TPoseLoop = nil end
        TPoseActive = false
    end
end)
task.spawn(function()
    while not Library.Unloaded do
        task.wait(0.05)
        if Library.Unloaded then break end
        if ANIMS_CONFIG.L_KEY.IsActive then
            local waitStart = tick()
            while ANIMS_CONFIG.L_KEY.IsActive and tick() - waitStart < 1 and not Library.Unloaded do task.wait(0.05) end
            if ANIMS_CONFIG.L_KEY.IsActive and not Library.Unloaded and Toggles.TogHeadFloat.Value then startHeadFloatSpam() end
            while ANIMS_CONFIG.L_KEY.IsActive and not Library.Unloaded do task.wait(0.05) end
            stopHeadFloatSpam()
        end
    end
    stopHeadFloatSpam()
end)
local function isKeyHeld(keyName)
    if keyName == "MB1" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    if keyName == "MB2" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    local ok, result = pcall(function() return UIS:IsKeyDown(Enum.KeyCode[keyName]) end)
    return ok and result or false
end
task.spawn(function()
    while not Library.Unloaded do
        task.wait()
        if Library.Unloaded then break end
        local kp      = Options and Options.KPHeadFloat
        local keyName = kp and kp.Value or "None"
        if keyName ~= "None" and isKeyHeld(keyName) and Toggles.TogHeadFloat.Value then
            local pressTime = tick()
            while isKeyHeld(keyName) and Toggles.TogHeadFloat.Value and not Library.Unloaded do
                if isChatFocused() then
                    task.wait(0.1)
                    keyName = (Options and Options.KPHeadFloat and Options.KPHeadFloat.Value) or "None"
                    continue
                end
                if tick() - pressTime > 0.3 then
                    toggleAnim(ANIMS_CONFIG.L_KEY)
                    Options.KPHeadFloat.Toggled = ANIMS_CONFIG.L_KEY.IsActive
                    task.wait(SpamDelay)
                end
                task.wait()
                keyName = (Options and Options.KPHeadFloat and Options.KPHeadFloat.Value) or "None"
            end
        end
    end
end)
if trashcanGameIds[currentPlaceId] then
    local FUCActive     = false
    _FUCClone = nil
    _FUCCloneRoot = nil
    _FUCCloneTrack = nil
    local FUCRealTrack  = nil
    local FUCCounter    = 0
    local _fucRenderConn = nil
    local function initFUC(char)
        if _fucRenderConn then _fucRenderConn:Disconnect() _fucRenderConn = nil end
        if _FUCClone then pcall(function() _FUCClone:Destroy() end) _FUCClone = nil end
        _FUCCloneRoot = nil _FUCCloneTrack = nil FUCRealTrack = nil FUCCounter = 0
        local root     = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not root or not humanoid or not animator then return end
        local archivable = char.Archivable
        char.Archivable  = true
        _FUCClone = char:Clone()
        char.Archivable = archivable
        _FUCClone.Parent = workspace
        _FUCCloneRoot = _FUCClone:FindFirstChild("HumanoidRootPart")
        local cloneHumanoid = _FUCClone:FindFirstChildOfClass("Humanoid")
        local cloneAnimator = cloneHumanoid and cloneHumanoid:FindFirstChildOfClass("Animator")
        if _FUCCloneRoot then
            _FUCCloneRoot.Anchored = true
            _FUCCloneRoot.CFrame   = CFrame.new(100000000, 100000000, 100000000)
        end
        local hl = Instance.new("Highlight", _FUCClone)
        hl.FillTransparency    = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor           = Color3.fromRGB(0, 255, 255)
        hl.OutlineColor        = Color3.fromRGB(0, 255, 255)
        hl.Adornee             = _FUCClone
        for _, v in pairs(_FUCClone:GetDescendants()) do
            if v:IsA("BasePart") and v ~= _FUCCloneRoot then
                v.CollisionGroup = "untouchable"
                v.Massless = true v.CanCollide = false v.CanTouch = false v.CanQuery = false v.Transparency = 0.5
            elseif v:IsA("Trail") or v:IsA("ParticleEmitter") then pcall(function() v:Destroy() end)
            elseif v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end
        end
        task.delay(0.1, function()
            if not cloneAnimator or not _FUCClone then return end
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://18236605028"
            _FUCCloneTrack = cloneAnimator:LoadAnimation(anim)
            _FUCCloneTrack.Priority = Enum.AnimationPriority.Action4
        end)
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://100933578899042"
        FUCRealTrack = animator:LoadAnimation(anim)
        anim.AnimationId = "rbxassetid://18236605028"
        FUCRealTrack.Priority = Enum.AnimationPriority.Action4
        _fucRenderConn = RunService.RenderStepped:Connect(function()
            if not _FUCClone or not _FUCClone.Parent then return end
            FUCCounter = FUCCounter + 1
            if FUCRealTrack then
                if FUCActive and not FUCRealTrack.IsPlaying then FUCRealTrack:Play() FUCRealTrack.Looped = true
                elseif FUCRealTrack.IsPlaying and (not FUCActive or FUCCounter % 1000 == 0) then FUCRealTrack:Stop() end
                FUCRealTrack:AdjustSpeed(1)
            end
            if _FUCCloneTrack and _FUCCloneRoot then
                if FUCActive then
                    local c = lp.Character
                    local r = c and c:FindFirstChild("HumanoidRootPart")
                    if r then _FUCCloneRoot.CFrame = r.CFrame end
                    if not _FUCCloneTrack.IsPlaying then _FUCCloneTrack:Play() _FUCCloneTrack.Looped = true end
                else
                    _FUCCloneRoot.CFrame = CFrame.new(100000000, 100000000, 100000000)
                    if _FUCCloneTrack.IsPlaying then _FUCCloneTrack:Stop() end
                end
                _FUCCloneTrack:AdjustSpeed(1)
            end
        end)
    end
    if lp.Character then task.spawn(initFUC, lp.Character) end
    local _fucCharConn = lp.CharacterAdded:Connect(function(char)
        FUCActive = false
        getgenv().FUCActive = false
        pcall(function()
            if Options.KPFUC then
                Options.KPFUC.Toggled = false
            end
        end)
        task.wait(1)
        initFUC(char)
    end)
    local TogFUC = BoxAnimsLeft:AddToggle("TogFUC", { Text = "Encrypted Position", Default = false })
    BoxAnimsLeft:AddToggle("TogHandOffset", {
        Text    = "Hand Offset",
        Default = false,
    })
    TogFUC:AddKeyPicker("KPFUC", {
        Default = "K", Text = "Encrypted", SyncToggleState = false, Mode = "Toggle",
        Callback = function(p)
            if _akbg.FC then return end
            if p and not Toggles.TogFUC.Value then
                RunService.RenderStepped:Wait()
                _akbg.FC = true; Options.KPFUC.Toggled = false; Options.KPFUC:DoClick(); _akbg.FC = false
                return
            end
            if Toggles.TogFUC.Value and not isChatFocused() then
                if Options.KPFUC.Toggled == FUCActive then return end
                FUCActive = not FUCActive; getgenv().FUCActive = FUCActive
                if FUCActive then stopAllToggles(false, true) else restartAllToggles(false) end
            end
        end,
    })
    TogFUC:OnChanged(function(val)
        if _guard.FUC then return end
        if isChatFocused() then _guard.FUC = true TogFUC:SetValue(not val) _guard.FUC = false return end
        if not val and FUCActive then
            if Options.KPFUC then Options.KPFUC.Toggled = false end
            FUCActive = false
            getgenv().FUCActive = false
            restartAllToggles(false)
        end
    end)
    table.insert(CleanupTasks, function()
        pcall(function() Toggles.TogHeadFloat:SetValue(false) end)
        pcall(function() Toggles.TogJerk:SetValue(false) end)
        pcall(function() Toggles.TogBang:SetValue(false) end)
        pcall(function() Toggles.TogTPose:SetValue(false) end)
    end)
    table.insert(CleanupTasks, function()
        if FUCActive then
            FUCActive = false
            getgenv().FUCActive = false
        pcall(function() Toggles.TogFUC:SetValue(false) end)
        end
        if _FUCClone then pcall(function() _FUCClone:Destroy() end) _FUCClone = nil end
        _FUCCloneRoot = nil _FUCCloneTrack = nil FUCRealTrack = nil
    end)
end
local function isTargetInMap(player)
    local char = player.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    local pos           = root.Position
    local destroyHeight = getgenv().FPDH or workspace.FallenPartsDestroyHeight
    if pos.Y <= destroyHeight + 100 then return false end
    if math.abs(pos.X) > 10000 or math.abs(pos.Z) > 10000 then return false end
    return true
end
local function isFlung(player)
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return root and root.Velocity.Magnitude >= 2000 or false
end
local function PhantaFling(TargetPlayer)
    if not TargetPlayer or not TargetPlayer.Parent then return end
    local Character  = lp.Character
    local Humanoid   = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart   = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead     = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle    = Accessory and Accessory:FindFirstChild("Handle")
    if not (Character and Humanoid and RootPart) then
        Library:Notify({ Title = bypassText("Fling"), Content = "Your character is not ready.", Time = 4 })
        return
    end
    if THumanoid and THumanoid.Sit then
        Library:Notify({ Title = bypassText("Fling"), Content = TargetPlayer.Name .. " is currently seated.", Time = 4 })
        return
    end
    if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

    if RootPart.Velocity.Magnitude < 50 then getgenv().OldPos = RootPart.CFrame end

    if THead        then pcall(function() workspace.CurrentCamera.CameraSubject = THead end)
    elseif Handle   then pcall(function() workspace.CurrentCamera.CameraSubject = Handle end)
    elseif THumanoid then pcall(function() workspace.CurrentCamera.CameraSubject = THumanoid end) end

    -- Lê opções (dropdown unificado CmdFlingMethod)
    local _flingType  = Options.CmdFlingMethod and Options.CmdFlingMethod.Value or 'Void'
    local _flingSpeed = Options.FlingSpeed and Options.FlingSpeed.Value or 15
    local flingY      = _flingType == 'Anti-Fling' and -0.75 or (_flingType == 'Normal' and 0 or 1)
    local _hasWeld    = _shpSupported
    local _angle      = 0

    local function isPartAlive(bp) return bp and bp.Parent ~= nil end

    local function _cleanWeld(basePart)
        if not _hasWeld then return end
        pcall(function() sethiddenproperty(RootPart, "PhysicsRepRootPart", nil) end)
        pcall(function() RootPart.AssemblyLinearVelocity  = Vector3.zero end)
        pcall(function() RootPart.AssemblyAngularVelocity = Vector3.zero end)
        if basePart and basePart.Parent then
            pcall(function() sethiddenproperty(basePart, "PhysicsRepRootPart", nil) end)
            pcall(function() basePart.AssemblyLinearVelocity  = Vector3.zero end)
            pcall(function() basePart.AssemblyAngularVelocity = Vector3.zero end)
        end
    end

    local FPos = function(BasePart)
        if not isPartAlive(BasePart) then return end
        local pos    = BasePart.Position
        local vel    = 0
        pcall(function() vel = BasePart.Velocity.Magnitude end)
        _angle = _angle + _flingSpeed
        local spinCF  = CFrame.new(0, flingY, 0) * CFrame.Angles(math.rad(90), 0, math.rad(_angle))
        local movDir  = THumanoid and THumanoid.MoveDirection or Vector3.zero
        pcall(function()
            if _hasWeld then
                -- Com sethiddenproperty: weld ativo → SEM prediction offset.
                -- Usa só posição do target + spin, sem movDir (prediction removida intencionalmente).
                -- NaN kill NÃO é aplicado aqui; fica exclusivo do InstaKillFling.
                local finalCF = CFrame.new(pos) * spinCF
                sethiddenproperty(RootPart, "PhysicsRepRootPart", BasePart)
                sethiddenproperty(BasePart, "PhysicsRepRootPart", RootPart)
                RootPart.CFrame = finalCF
            else
                -- Sem sethiddenproperty: aplica prediction offset igual Phantasm (movDir * vel).
                local finalCF = CFrame.new(pos) * spinCF + movDir * (vel / 1.25)
                RootPart.CFrame = finalCF
                Character:SetPrimaryPartCFrame(finalCF)
            end
            RootPart.Velocity    = Vector3.new(0, -9e9, 0)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end)
    end

    local SFBasePart = function(BasePart)
        local Time    = tick()
        local _flingTimeout = Options.FlingTimeout and Options.FlingTimeout.Value or 3
        pcall(function() THumanoid.PlatformStand = true end)
        repeat
            if not isPartAlive(BasePart) then break end
            if not THumanoid or not THumanoid.Parent then break end
            FPos(BasePart)
            task.wait()
        until Time + _flingTimeout < tick() or not FlingActive or not isPartAlive(BasePart)
        pcall(function() THumanoid.PlatformStand = false end)
        pcall(function() THumanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        _cleanWeld(BasePart)
    end

    workspace.FallenPartsDestroyHeight = 0/0
    local BV = Instance.new("BodyVelocity")
    BV.Parent   = RootPart
    BV.Velocity = Vector3.new(0, -9e12, 0)
    BV.MaxForce = Vector3.new(0, -9e12, 0)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    if     TRootPart and isPartAlive(TRootPart) then pcall(SFBasePart, TRootPart)
    elseif THead     and isPartAlive(THead)     then pcall(SFBasePart, THead)
    elseif Handle    and isPartAlive(Handle)    then pcall(SFBasePart, Handle)
    else
        Library:Notify({ Title = bypassText("Fling"), Content = TargetPlayer.Name .. " has no valid parts to target.", Time = 4 })
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        return
    end
    pcall(function() BV:Destroy() end)
    pcall(function() Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
    pcall(function() RootPart.Velocity    = Vector3.new() end)
    pcall(function() RootPart.RotVelocity = Vector3.new() end)
    pcall(function() workspace.CurrentCamera.CameraSubject = Humanoid end)
    if getgenv().OldPos then
        local returnStart = tick()
        repeat
            pcall(function()
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then part.Velocity = Vector3.new() part.RotVelocity = Vector3.new() end
                end
            end)
            task.wait()
        until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25 or tick() - returnStart > 3
        pcall(function() RootPart.Velocity    = Vector3.new() end)
        pcall(function() RootPart.RotVelocity = Vector3.new() end)
    end
end
InstaKillFling = function() end

local function updateFlingDropdown()
    if not FlingDropdown then return end
    local newList = getFlingPlayersList()
    flingPlayerCache = newList
    local currentSelections = {}
    for name, _ in pairs(FlingSelectedTargets) do currentSelections[name] = true end
    pcall(function() FlingDropdown:SetValues(newList) FlingDropdown:SetValue(currentSelections) end)
end
local _flingPlayerAddedConn = Players.PlayerAdded:Connect(function(joinedPlayer)
    task.wait(0.5)
    pcall(updateFlingDropdown)
    -- auto-add ao loopfling se mode all/others está ativo (igual Phantasm: u17 só é true pra all/others)
    -- mode 'single' não auto-adiciona: somente o player específico deve ser flingado
    if FlingActive and (_loopFlingMode == 'all' or _loopFlingMode == 'others') and joinedPlayer ~= lp then
        task.spawn(function()
            task.wait(1) -- espera o char do player aparecer no mapa
            if FlingActive and (_loopFlingMode == 'all' or _loopFlingMode == 'others') and isTargetInMap(joinedPlayer) then
                FlingSelectedTargets[getDisplayName(joinedPlayer)] = joinedPlayer
                pcall(updateFlingDropdown)
            end
        end)
    end
end)
local _flingPlayerRemovingConn = Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    pcall(updateFlingDropdown)
end)
local function toggleAllFlingPlayers(select)
    FlingSelectedTargets = {}
    if select then
        for _, name in ipairs(flingPlayerCache) do
            local player = findPlayerByDisplayName(name)
            if player then FlingSelectedTargets[name] = player end
        end
    end
    if FlingDropdown then
        local selectionForUI = {}
        for name, _ in pairs(FlingSelectedTargets) do
            selectionForUI[name] = true
        end
        pcall(function() FlingDropdown:SetValue(selectionForUI) end)
    end
end
local function countFlingTargets()
    local count = 0
    for _ in pairs(FlingSelectedTargets) do count = count + 1 end
    return count
end
local function startFling()
    if FlingActive then return end
    if countFlingTargets() == 0 then
        Library:Notify({ Title = bypassText("Fling"), Content = "No targets selected.", Time = 4 })
        return
    end
    FlingActive = true
    if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
        playerDiedConnection = lp.Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
            if FlingActive then
                FlingActive = false
                restoreView()
                if playerDiedConnection then playerDiedConnection:Disconnect() playerDiedConnection = nil end
            end
        end)
    end
    task.spawn(function()
        local flingPlayerRemovingConn = Players.PlayerRemoving:Connect(function(removedPlayer)
            local displayName = getDisplayName(removedPlayer)
            if FlingSelectedTargets[displayName] then
                FlingSelectedTargets[displayName] = nil
                pcall(function()
                    local subject = workspace.CurrentCamera.CameraSubject
                    if subject and removedPlayer.Character and subject:IsDescendantOf(removedPlayer.Character) then
                        stopCurrentView()
                        _flingViewActive = false
                        pcall(function() workspace.CurrentCamera.CameraSubject = lp.Character end)
                    end
                end)
                if next(FlingSelectedTargets) == nil then
                    FlingActive = false
                end
            end
        end)
        local _lastViewTarget  = nil
        -- Rotação ordenada: avança em ordem pelos targets, sem ninguém pular a vez
        local _rotationList = {} -- array ordenado de nomes
        local _rotationIdx  = 0  -- índice atual na rotação

        local function _rebuildRotation()
            local existing = {}
            for _, n in ipairs(_rotationList) do existing[n] = true end
            for name, _ in pairs(FlingSelectedTargets) do
                if not existing[name] then
                    table.insert(_rotationList, name)
                end
            end
            for i = #_rotationList, 1, -1 do
                if not FlingSelectedTargets[_rotationList[i]] then
                    table.remove(_rotationList, i)
                    if _rotationIdx >= i then _rotationIdx = math.max(0, _rotationIdx - 1) end
                end
            end
        end

        local function _cleanupRespawnConns()
            _rotationList = {}
            _rotationIdx  = 0
        end

        local function _getNextTarget(validTargets)
            _rebuildRotation()
            local total = #_rotationList
            if total == 0 then return nil end
            -- avança em ordem circular a partir de onde parou
            for offset = 1, total do
                local idx = (_rotationIdx + offset - 1) % total + 1
                local name = _rotationList[idx]
                local p = validTargets[name]
                if p and isTargetInMap(p) and not isFlung(p) then
                    _rotationIdx = idx
                    return p
                end
            end
            return nil
        end

        while FlingActive do
            local validTargets = {}
            for name, player in pairs(FlingSelectedTargets) do
                if player and player.Parent then
                    validTargets[name] = player
                else
                    FlingSelectedTargets[name] = nil
                end
            end

            local readyTarget = _getNextTarget(validTargets)

            if next(validTargets) == nil then
                -- Sem targets: para tudo e desconecta
                if _flingViewActive and not _userViewActive then
                    restoreView()
                    _flingViewActive = false
                    _lastViewTarget  = nil
                end
                FlingActive = false
                break
            elseif not readyTarget then
                -- Tem targets mas nenhum está pronto (todos flung/fora do mapa/respawnando):
                -- para view enquanto espera para não ficar travado na câmera
                if _flingViewActive and not _userViewActive then
                    restoreView()
                    _flingViewActive = false
                    _lastViewTarget  = nil
                end
                task.wait(0.2)
            else
                local player = readyTarget
                if not _userViewActive and _lastViewTarget ~= player then
                    setView(player)
                    _flingViewActive = true
                    _lastViewTarget  = player
                end
                if not _pU59['Touch Fling'] then _vsEnableNoclip() end
                local ok, err = pcall(PhantaFling, player)
                if not ok then warn("[Revenant Fling] PhantaFling error: " .. tostring(err)) end
                if not _pU59['Touch Fling'] then _vsDisableNoclip() end
                -- _loopFlingMode nil = fling único (sem loop): remove target após flinkar
                -- 'all', 'others', 'single' = loopfling: mantém o target na lista e continua
                if _loopFlingMode == nil then
                    local _name = getDisplayName(player)
                    FlingSelectedTargets[_name] = nil
                end
            end
        end
        _cleanupRespawnConns()
        _flingViewActive = false
        _userViewActive  = false
        _lastViewTarget  = nil
        restoreView()
        if playerDiedConnection then playerDiedConnection:Disconnect() playerDiedConnection = nil end
        flingPlayerRemovingConn:Disconnect()
    end)
end
local function stopFling()
    if not FlingActive then return end
    FlingActive = false
    if playerDiedConnection then playerDiedConnection:Disconnect() playerDiedConnection = nil end
    -- Reseta PhysicsRepRootPart e velocidades de todos os targets ativos
    pcall(function()
        for _, p in pairs(FlingSelectedTargets) do
            if p and p.Character then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", nil) end)
                    pcall(function() r.AssemblyLinearVelocity  = Vector3.zero end)
                    pcall(function() r.AssemblyAngularVelocity = Vector3.zero end)
                    pcall(function() r.Velocity                = Vector3.zero end)
                    pcall(function() r.RotVelocity             = Vector3.zero end)
                end
            end
        end
    end)
    restoreView()
end
-- Fix: after a reset, if Death touch fling was active and targets are selected, automatically
-- restart startFling() on the new character so the fling loop and playerDiedConnection are
-- re-established. Without this, Death fling silently stops working after every respawn.
lp.CharacterAdded:Connect(function()
    if _pU59 and _pU59['Touch Fling'] and countFlingTargets() > 0 then
        task.wait(1.5) -- wait for character to fully load
        if _pU59['Touch Fling'] and not FlingActive then
            startFling()
        end
    end
end)
local function _buildFlingUI()
    -- UI de seleção manual removida: use os comandos ;fling / ;loopfling / ;unfling
end
do
    local AntiFlingActive = false
    local antiFlingLoop   = nil

    local function _buildAntiFling(box)
        box:AddToggle("AntiFlingToggle", {
            Text = "Anti-Fling", Default = false,
            Callback = function(Value)
                if Value then
                    if AntiFlingActive then return end
                    AntiFlingActive = true
                    antiFlingLoop = RunService.Stepped:Connect(function()
                        for _, player in pairs(Players:GetPlayers()) do
                            if player ~= lp and player.Character then
                                for _, v in pairs(player.Character:GetDescendants()) do
                                    if v:IsA("BasePart") then
                                        v.CanCollide = false
                                    end
                                end
                            end
                        end
                    end)
                else
                    AntiFlingActive = false
                    if antiFlingLoop then antiFlingLoop:Disconnect() antiFlingLoop = nil end
                end
            end
        })
        table.insert(CleanupTasks, function()
            AntiFlingActive = false
            if antiFlingLoop then antiFlingLoop:Disconnect() antiFlingLoop = nil end
            pcall(function() Toggles.AntiFlingToggle:SetValue(false) end)
        end)
    end
    getgenv()._revenantAntiFlingBuild = _buildAntiFling
end
if trashcanGameIds[currentPlaceId] then
    local deathCounterActive     = false
    local deathCounterConns      = {}
    local deathCounterHighlights = {}
    local deathCounterUltConns   = {}
    local deathCounterUltHooked  = setmetatable({}, { __mode = "k" })
    local refreshDeathCounterUltHighlights = function() end
    local function isDeathCounter(child)
        return child:IsA("Accessory") and child.Name == "Counter"
    end
    local deathCounterDebounce = {}
    local hookedChars          = {}
    local function removeCounterHL(player)
        deathCounterHighlights[player] = nil
        deathCounterDebounce[player] = nil
    end
    local _TweenService      = game:GetService("TweenService")
    local _ReplicatedStorage = game:GetService("ReplicatedStorage")
    local function addCounterHL(char, player, counterChild)
        if deathCounterHighlights[player] then return end
        deathCounterHighlights[player] = true
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        task.spawn(function()
            local snd = Instance.new("Sound")
            snd.SoundId = "rbxassetid://6476791205"
            snd.Volume  = 10
            snd.Parent  = root
            snd:Play()
            local ok, template = pcall(function()
                return _ReplicatedStorage:WaitForChild("Resources", 5)
                    :WaitForChild("LegacyReplication", 5)
                    :WaitForChild("Menacing", 5)
            end)
            if not ok or not template then return end
            local menacingInstances = {}
            for menacingIdx = 1, 10 do
                local randomScale = Random.new():NextNumber(0.9, 1.1)
                local menacingClone = template:Clone()
                menacingClone.Enabled = true
                menacingClone.Size    = UDim2.new(randomScale, 0, randomScale, 0)
                local randomX = Random.new():NextNumber(-4, 4)
                local randomZ = math.random(-4, 4)
                menacingClone.StudsOffsetWorldSpace = Vector3.new(randomX, 0, randomZ)
                menacingClone.Parent = root
                table.insert(menacingInstances, menacingClone)
                task.delay(menacingIdx, function()
                    if menacingClone.Parent then
                        local idx = table.find(menacingInstances, menacingClone)
                        if idx then table.remove(menacingInstances, idx) end
                        _TweenService:Create(menacingClone,
                            TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                            { StudsOffsetWorldSpace = menacingClone.StudsOffsetWorldSpace - Vector3.new(0, 10, 0) }
                        ):Play()
                        _TweenService:Create(menacingClone.ImageLabel,
                            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            { ImageTransparency = 1 }
                        ):Play()
                    end
                end)
            end
            local highlightList = {}
            while task.wait() do
                for _, menacingBillboard in pairs(menacingInstances) do
                    if not highlightList[menacingBillboard] then
                        highlightList[menacingBillboard] = menacingBillboard.StudsOffsetWorldSpace
                    end
                    local randomOffset = Random.new():NextNumber(-0.04, 0.04)
                    menacingBillboard.StudsOffsetWorldSpace = highlightList[menacingBillboard] + Vector3.new(randomOffset, randomOffset, randomOffset)
                end
                if not (counterChild and counterChild.Parent) then
                    local snapshot = menacingInstances
                    for _, snapshotBillboard in pairs(snapshot) do
                        local randomSpeed = Random.new():NextNumber(2, 3)
                        _TweenService:Create(snapshotBillboard,
                            TweenInfo.new(randomSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                            { StudsOffsetWorldSpace = (highlightList[snapshotBillboard] or snapshotBillboard.StudsOffsetWorldSpace) - Vector3.new(0, 10, 0) }
                        ):Play()
                        _TweenService:Create(snapshotBillboard.ImageLabel,
                            TweenInfo.new(randomSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            { ImageTransparency = 1 }
                        ):Play()
                    end
                    task.delay(3, function()
                        for _, oldBillboard in pairs(snapshot) do
                            pcall(function() oldBillboard:Destroy() end)
                        end
                    end)
                    break
                end
            end
        end)
    end
    local function watchCharForCounter(char, player)
        if not char or not player or player == lp then return end
        if hookedChars[char] then return end
        hookedChars[char] = true
        for _, child in pairs(char:GetChildren()) do
            if isDeathCounter(child) then
                if deathCounterActive and not deathCounterDebounce[player] then
                    MoveNotify(player, "Death Counter")
                    deathCounterDebounce[player] = true
                    addCounterHL(char, player, child)
                end
                child.AncestryChanged:Connect(function()
                    if not child.Parent then removeCounterHL(player) end
                end)
            end
        end
        local conn = char.ChildAdded:Connect(function(child)
            if not deathCounterActive then return end
            if not isDeathCounter(child) then return end
            MoveNotify(player, "Death Counter")
            if deathCounterDebounce[player] then return end
            deathCounterDebounce[player] = true
            task.defer(function()
                addCounterHL(char, player, child)
            end)
            child.AncestryChanged:Connect(function()
                if not child.Parent then removeCounterHL(player) end
            end)
        end)
        table.insert(deathCounterConns, conn)
    end
    local function hookPlayerDC(player)
        if player == lp then return end
        if player.Character then
            task.spawn(watchCharForCounter, player.Character, player)
        end
        local conn = player.CharacterAdded:Connect(function(char)
            if not deathCounterActive then return end
            removeCounterHL(player)
            task.wait(0.1)
            watchCharForCounter(char, player)
        end)
        table.insert(deathCounterConns, conn)
    end
    local BoxDeathCounter = TabExpAntis
    table.insert(CleanupTasks, function()
        deathCounterActive = false
        for _, c in pairs(deathCounterConns) do pcall(c.Disconnect, c) end
        deathCounterConns = {}
        deathCounterHighlights = {}
        deathCounterDebounce = {}
        hookedChars = {}
        pcall(function() Toggles.ShowDeathCounter:SetValue(false) end)
    end)
    local _antiDCAnimConn = nil
    local _antiDCCharConn = nil
    local function _antiDCEnabled()
        return Options.AntiMoves_Saitama
               and rawget(Options.AntiMoves_Saitama.Value, "Anti Death Counter")
    end
    local function _getAntiDCWaitBeforeKill()
        local mode = Options.AntiDCWaitBeforeKillDD and Options.AntiDCWaitBeforeKillDD.Value
        if mode == "3s - Fakeout" then return 3 end
        if mode == "5s - Long Fakeout" then return 5 end
        return 0
    end
    local function _antiDCChat(msg)
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            channel:SendAsync(msg)
        end
    end
    local _sukunaQuotes = {
        "Ah yes...My Anti Death Counter technique. One i haven't used since the Heian era.",
        "You dare try and death counter me? I'll allow it once. There won't be a second time.",
        "Know your place, fool.",
        "Let's have a contest of firepower. Arm yourself.",
        "I fought sweats and noobs a thousand years ago, your still one of the better ones. Stand Proud, You are strong.",
        "Stand Proud, You are strong.",
        "If i wasn't a scripter, that would have eliminated me on the first blow.",
        "You've done it now, brat!",
        "I knew it. You're similar to all those brats who tried to death counter me.",
        "You follow my movement, and attack with death counter. It started happening after your ultimate activated.",
        "The activation of the strongest' ultimate and death counter both represent perfect cycles of chaos and peace.",
        "Your ability as i've seen....Is to death counter anything and everything. It's the ultimate counter!",
        "You might have defeated me if i wasn't a scripter back then.",
        "Domain Expansion: Shadow Realm",
        "Fuga (Open)",
    }
    local _gojoQuotes = {
        "I alone, am The Honoured One.",
        "The world just feels so wonderful right now..",
        "Nah, I'd Win.",
        "If i would get hit by death counter, it would cause me a little trouble, but i would win.",
        "Domain Expansion: Infinite Void",
        "\u{5f0f}: \u{30a2}\u{30f3}\u{30c1}\u{30c7}\u{30b9}\u{30ab}\u{30a6}\u{30f3}\u{30bf}\u{30fc} (Imaginary Technique: Anti Death Counter)",
        "deathcountererhaha tried to split me in half, but Gojo always wins.",
        "YOU LOOK UGLIER THAN EVER, deathcountererhaha!!",
    }
    local _gojoSequentialQuote = {
        { Quote = "It took me a while..",                                          WaitTime = 2 },
        { Quote = "But I finally grasped it on the verge of death deathcountererhaha..", WaitTime = 2 },
        { Quote = "The true essence of cursed energy..",                           WaitTime = 2 },
        { Quote = "REVERSE CURSED TECHNIQUE!!",                                    WaitTime = 0 },
    }
    local _nameQuotes = {
        "deathcountererhaha tried.",
        "deathcountererhaha thinks he can win with death counter.",
        "deathcountererhaha death countered me. But i refused.",
        "deathcountererhaha is an idiot for trying to death counter me.",
        "deathcountererhaha tried to death counter me.",
        "did you really think you could kill me deathcountererhaha....?",
        "I'm not gonna let that slide, deathcountererhaha.",
    }
    local _adminQuotes = {
        ";kill deathcountererhaha",
        ";respawn deathcountererhaha",
        ";kick deathcountererhaha",
        ";ban deathcountererhaha",
        ";re deathcountererhaha",
    }
    local function _sendAntiDCQuote(attackerPlayer, attackerName)
        local mode = Options.AntiDCQuotesDD and Options.AntiDCQuotesDD.Value or "No Quotes"
        if mode == "No Quotes" then return end
        local name = (attackerName and attackerName ~= "") and attackerName or "[placeholder]"
        if mode == "Sukuna Quotes" then
            _antiDCChat(_sukunaQuotes[math.random(#_sukunaQuotes)])
        elseif mode == "Gojo Quotes" then
            if math.random(2) == 1 then
                _antiDCChat(_gojoQuotes[math.random(#_gojoQuotes)]
                    :gsub("deathcountererhaha", name)
                    :gsub("DEATHCOUNTERERHAHA", name:upper()))
            else
                task.spawn(function()
                    for _, entry in ipairs(_gojoSequentialQuote) do
                        _antiDCChat(entry.Quote:gsub("deathcountererhaha", name))
                        if entry.WaitTime > 0 then task.wait(entry.WaitTime) end
                    end
                end)
            end
            task.spawn(function()
                local char = lp.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then return end
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://17275798442"
                local track = hum:LoadAnimation(anim)
                track:Play()
                track.TimePosition = 2.5
                repeat task.wait() until track.TimePosition >= 3
                local hip = 0
                for _ = 1, 150 do
                    hip = hip + 0.1
                    hum.HipHeight = hip
                    task.wait()
                end
                repeat task.wait() until track.TimePosition >= 6.5
                track:AdjustSpeed(0.2)
                task.wait(7)
                track:Stop(0.6)
                hum.HipHeight = 0
            end)
        elseif mode == "Name Quotes" then
            _antiDCChat(string.gsub(_nameQuotes[math.random(#_nameQuotes)], "deathcountererhaha", name))
        elseif mode == "Admin Quotes" then
            _antiDCChat(string.gsub(_adminQuotes[math.random(#_adminQuotes)], "deathcountererhaha", name))
        elseif mode == "Random" then
            local allModes = { "Sukuna Quotes", "Gojo Quotes", "Name Quotes", "Admin Quotes" }
            local randomMode = allModes[math.random(#allModes)]
            if randomMode == "Sukuna Quotes" then
                _antiDCChat(_sukunaQuotes[math.random(#_sukunaQuotes)])
            elseif randomMode == "Gojo Quotes" then
                _antiDCChat(string.gsub(_gojoQuotes[math.random(#_gojoQuotes)], "deathcountererhaha", name))
            elseif randomMode == "Name Quotes" then
                _antiDCChat(string.gsub(_nameQuotes[math.random(#_nameQuotes)], "deathcountererhaha", name))
            elseif randomMode == "Admin Quotes" then
                _antiDCChat(string.gsub(_adminQuotes[math.random(#_adminQuotes)], "deathcountererhaha", name))
            end
        elseif mode == "Sans Quotes" then
            local _sansQuotes = {
                DeathCounterQuote1  = { "✱ looks like that guy who death countered me looked pretty frustrated.", "✱ i mustn't gossip, i would be angry too.", "✱ yeah... maybe." },
                DeathCounterQuote2  = { "✱ hmm. their expression...", "✱ that was the expression of someone who's raged twice in a row.", "✱ suffice to say, they looked really... unsatisfied.", "✱ all right.", "✱ how 'bout i make it a third?" },
                DeathCounterQuote3  = { "✱ hmm. their expression...", "✱ that was the expression of someone who's died thrice in a row.", "✱ . . .", "✱ guess you could say... i turned that smile upside down.", "✱ whats the punchline?", "✱ i don't know." },
                DeathCounterQuote4  = { "✱ hmm. their expression...", "✱ that's the expression of someone who's unwilling to give up.", "✱ . . .i can't count after 4.", "✱ me and you might be surprised to see more dialogue.", "✱ don't worry. im sure it ends somewhere." },
                DeathCounterQuote5  = { "✱ hmm. their expression...", "✱ that's the expression of someone who's unwilling to give up.", "✱ did i get you? did you think that the dialogue was gonna repeat?", "✱ don't worry. its gonna repeat soon.", "✱ over and over, until everything is reset." },
                DeathCounterQuote6  = { "✱ our reports showed a massive sweat in the roblox continuum.", "✱ players dashing left and right, comboing and dying...", "✱ until suddenly, everything ends." },
                DeathCounterQuote7  = { "✱ heh heh heh...", "✱ you think it's the devs fault, isn't it?", "✱ you can't understand how this feels." },
                DeathCounterQuote8  = { "✱ knowing that one day, without any warning...", "✱ it's all going to be updated.", "✱ look. i gave up trying to go back to rank 1 a long time ago." },
                DeathCounterQuote9  = { "✱ getting to the leaderboard doesn't really appeal anymore, either.", "✱ cause even if i do...", "✱ we'll just end up right back here, without any memory of it, right?" },
                DeathCounterQuote10 = { "✱ getting to the leaderboard doesn't really appeal anymore, either.", "✱ cause even if i do...", "✱ we'll just end up right back here, without any memory of it, right?" },
                DeathCounterQuote11 = { "✱ you really like trying to punch me, huh?", "✱ i know you didn't answer me before, but...", "✱ let's just be friends alright?", "✱ . . .", "✱ sike. if we're truly friends...", "✱ y o u w o n t c o m e b a c k" },
                DeathCounterQuote12 = { "✱ friendship...", "✱ it's really great right?", "✱ cmon, just stop death countering me.", "✱ really? you're trusting me?", "✱ c'mere, pal. sike, geeettttttt dunked on!!!" },
                DeathCounterQuote13 = { "✱ . . .", "✱ ready?" },
            }
            local function _sansGetQuote(n)
                return _sansQuotes["DeathCounterQuote" .. tostring(n)]
            end
            local target = attackerPlayer
            if not target then
                _antiDCChat("* you're just a dirty ragequitter, aren't you?")
                return
            end
            local saness = target:GetAttribute("Saness")
            if saness and saness ~= 13 then
                local lines = _sansGetQuote(saness)
                if lines then
                    for _, line in ipairs(lines) do
                        _antiDCChat(line)
                        task.wait(3)
                    end
                end
                target:SetAttribute("Saness", saness + 1)
            elseif not saness then
                _antiDCChat("* what? you think i'm just gonna stand there and take it?")
                task.wait(3)
                _antiDCChat("* welp. this is why i never make promises.")
                task.wait(5)
                target:SetAttribute("Saness", 1)
            end
        end
    end
    local function _antiDCTp(cf)
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and root) then return end
        task.spawn(function()
            RunService.RenderStepped:Once(function()
                root.Velocity = Vector3.new()
                RunService.Heartbeat:Wait()
                root.Velocity = Vector3.new()
            end)
            RunService.Heartbeat:Once(function()
                root.CFrame = cf
            end)
        end)
    end
    local function _antiDCFixCam()
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if char and hum and workspace.CurrentCamera then
            local cf = workspace.CurrentCamera.CFrame
            workspace.CurrentCamera:Destroy()
            local cam = Instance.new("Camera", workspace)
            cam.CameraType    = Enum.CameraType.Custom
            cam.CameraSubject = hum
            cam.CFrame        = cf
            lp.CameraMode     = Enum.CameraMode.Classic
            local head = char:FindFirstChild("Head")
            if head then head.Anchored = false end
        end
    end
    local function _hookAntiDCAnimator(humanoid)
        if _antiDCAnimConn then _antiDCAnimConn:Disconnect() _antiDCAnimConn = nil end
        if not humanoid then return end
        _antiDCAnimConn = humanoid.AnimationPlayed:Connect(function(track)
            if not _antiDCEnabled() then return end
            if not track.Animation.AnimationId:match("11343250001") then return end
            task.spawn(function()
            local waitBeforeKill = _getAntiDCWaitBeforeKill()
            local stoppedCounterTrack = waitBeforeKill <= 0
            if waitBeforeKill <= 0 then
                pcall(function() track:Stop() end)
            end
            task.spawn(_antiDCFixCam)
            local char = lp.Character
            char:WaitForChild("AbsoluteImmortal", 1)
            local root = char:FindFirstChild("HumanoidRootPart")
            local savedCFrame = root.CFrame
            local attacker = nil
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= lp then
                    local tchar = player.Character
                    local troot = tchar and tchar:FindFirstChild("HumanoidRootPart")
                    local thum  = tchar and tchar:FindFirstChildOfClass("Humanoid")
                    if tchar and troot and thum then
                        for _, t in pairs(thum:GetPlayingAnimationTracks()) do
                            if t.Animation.AnimationId:match("11343318134")
                                and (root.Position - troot.Position).Magnitude <= 15 then
                                attacker = player
                            end
                        end
                    end
                end
            end
            local attackerHum  = nil
            local attackerName = nil
            if attacker then
                local ach = attacker.Character
                attackerHum  = ach and ach:FindFirstChildOfClass("Humanoid")
                attackerName = getDisplayName(attacker)
                Library:Notify({ Title = bypassText("Death Counter"), Content = attackerName .. " used Death Counter on you.", Time = 5 })
            else
                local _fakeModel = Instance.new("Model")
                local _fakeHum   = Instance.new("Humanoid", _fakeModel)
                _fakeHum.Health  = 100
                attackerHum  = _fakeHum
                attackerName = nil
                task.delay(waitBeforeKill + 2, function()
                    _fakeHum.Health = 0
                end)
                Library:Notify({ Title = bypassText("Death Counter"), Content = "Death Counter attempt detected.", Time = 5 })
            end
            if waitBeforeKill > 0 then
                task.wait(waitBeforeKill)
                if not _antiDCEnabled() then return end
                char = lp.Character
                root = char and char:FindFirstChild("HumanoidRootPart")
                if not (char and root) then return end
            end
            local savedSubject = workspace.CurrentCamera and workspace.CurrentCamera.CameraSubject
            if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = nil end
            local myHum  = char:FindFirstChildOfClass("Humanoid")
            local voidCF = CFrame.new(0, -10000, 0) * CFrame.Angles(math.rad(90), 0, 0)
            local t0     = tick()
            repeat
                _antiDCTp(voidCF)
                if waitBeforeKill > 0 and not stoppedCounterTrack then
                    stoppedCounterTrack = true
                    pcall(function() track:Stop() end)
                end
                RunService.RenderStepped:Wait()
            until (attackerHum and attackerHum.Health <= 0)
                or (myHum and myHum.Health <= 0)
                or tick() >= t0 + 10
            if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = savedSubject end
            _antiDCTp(savedCFrame)
            task.spawn(function()
                _sendAntiDCQuote(attacker, attackerName)
            end)
            task.wait(1)
            local cur = lp.Character
            if cur then
                local freeze   = cur:FindFirstChild("Freeze")
                local noRotate = cur:FindFirstChild("NoRotate")
                if freeze   then freeze:Destroy()   end
                if noRotate then noRotate:Destroy() end
            end
            task.spawn(_antiDCFixCam)
            end)
        end)
    end
    local function _hookAntiDCChar(char)
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            _hookAntiDCAnimator(humanoid)
        else
            task.spawn(function()
                local hum = char:WaitForChild("Humanoid", 5)
                if hum and _antiDCEnabled() then _hookAntiDCAnimator(hum) end
            end)
        end
    end
    _hookAntiDCChar(lp.Character)
    _antiDCCharConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        _hookAntiDCChar(char)
    end)
    table.insert(CleanupTasks, function()
        if _antiDCAnimConn then _antiDCAnimConn:Disconnect() _antiDCAnimConn = nil end
        if _antiDCCharConn then _antiDCCharConn:Disconnect() _antiDCCharConn = nil end
        pcall(function() Options.AntiDCQuotesDD:SetValue("No Quotes") end)
        pcall(function() Options.AntiDCWaitBeforeKillDD:SetValue("No Wait - Near Instant And Prevents Tabbing") end)
    end)
    local _coreGuiAllConn = nil
    local _StarterGui = game:GetService("StarterGui")
    table.insert(CleanupTasks, function()
        if _coreGuiAllConn then _coreGuiAllConn:Disconnect() _coreGuiAllConn = nil end
    end)
    BoxDeathCounter:AddButton({
        Text = "Toggle All On",
        Func = function()
            local v664, v665, v666 = pairs(Toggles)
            while true do
                local v667
                v666, v667 = v664(v665, v666)
                if v666 == nil then break end
                if v666:find('^AntiMoves_') and v667.Type == 'Toggle' then
                    v667:SetValue(true)
                end
            end
            local v668, v669, v670 = pairs(Options)
            while true do
                local v671
                v670, v671 = v668(v669, v670)
                if v670 == nil then break end
                if v670:find('^AntiMoves_') and v671.Type == 'Dropdown' then
                    local v672, v673, v674 = pairs(v671.Values)
                    local v675 = {}
                    while true do
                        local v676
                        v674, v676 = v672(v673, v674)
                        if v674 == nil then break end
                        v675[v676] = true
                    end
                    v671:SetValue(v675)
                end
            end
        end,
    }):AddButton({
        Text = "Toggle All Off",
        Func = function()
            local v677, v678, v679 = pairs(Toggles)
            while true do
                local v680
                v679, v680 = v677(v678, v679)
                if v679 == nil then break end
                if v679:find('^AntiMoves_') and v680.Type == 'Toggle' then
                    v680:SetValue(false)
                end
            end
            local v681, v682, v683 = pairs(Options)
            while true do
                local v684
                v683, v684 = v681(v682, v683)
                if v683 == nil then break end
                if v683:find('^AntiMoves_') and v684.Type == 'Dropdown' then
                    v684:SetValue({})
                end
            end
        end,
    })
    if getgenv()._revenantAntiFlingBuild then
        getgenv()._revenantAntiFlingBuild(BoxDeathCounter)
        getgenv()._revenantAntiFlingBuild = nil
    end
    local _antiInvisConns  = {}
    local antiInvisOn      = false


    -- ── BODY PARTS ONLY ── no accessories, no effects, no hitbox garbage
    -- ~15 parts per enemy instead of 100+. your fps called, it says thank you.
    local BODY_PARTS = {
        Head = true, UpperTorso = true, LowerTorso = true, Torso = true,
        LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
        RightUpperArm = true, RightLowerArm = true, RightHand = true,
        LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
        RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
        ["Left Arm"] = true, ["Right Arm"] = true,
        ["Left Leg"] = true, ["Right Leg"] = true,
    }

    local function _antiInvisCleanup()
        antiInvisOn = false
        for _, c in ipairs(_antiInvisConns) do pcall(c.Disconnect, c) end
        _antiInvisConns = {}
    end

    -- ── prune dead connections so the table doesn't bloat with corpses ──
    local function _pruneDeadConns()
        local alive = {}
        for _, c in ipairs(_antiInvisConns) do
            if c.Connected then
                table.insert(alive, c)
            end
        end
        _antiInvisConns = alive
    end

    -- ── ghost-ify: set body parts + accessories to 0.5 so we see the sneaky bastard ──
    local function _ghostifyPlayer(char)
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") and BODY_PARTS[part.Name] then
                part.Transparency = 0.5
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    handle.Transparency = 0.5
                end
            end
        end
    end

    -- ── un-ghost: they stopped being invis, back to fully solid ──
    local function _unghostifyPlayer(char)
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") and BODY_PARTS[part.Name] then
                part.Transparency = 0
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    handle.Transparency = 0
                end
            end
        end
    end

    -- ── the naughty list: only these anim IDs get hammered ──
    local INVIS_ANIM_IDS = {
        "18182425133", "136370737633649", "18462892217",
        "74844382738532", "77727115892579", "107114358965793",
        "71181015443030", "76020797916551",
    }

    -- ── anim killer: catches invis move anims playing at speed < 1 ──
    -- when caught → ghostify PLAYER, hammer the anim, then restore when it's over
    local function _hookAntiInvisAnim(track, char, player)
        local animId = track.Animation and track.Animation.AnimationId or ""
        for _, id in ipairs(INVIS_ANIM_IDS) do
            if animId:match(id) and track.Speed < 1 then
                _ghostifyPlayer(char)

                task.spawn(function()
                    repeat
                        track:AdjustWeight(-999999)
                        RunService.Heartbeat:Wait()
                    until not (track.IsPlaying and antiInvisOn)
                    _unghostifyPlayer(char)
                end)
                break
            end
        end
    end

    -- ── per-player setup: animation hooks on BOTH player humanoid AND mech animator ──
    local function _setupAntiInvisPlayer(player)
        if player == lp then return end
        -- clean out dead connections before adding new ones
        _pruneDeadConns()
        local char = player.Character
        if not char then return end
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not humanoid then return end

        -- animation hooks only — no transparency watching, no signal spam, just vibes

        -- hook currently playing anims on the PLAYER
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            _hookAntiInvisAnim(track, char, player)
        end

        -- hook future anims on the PLAYER
        local animConn = humanoid.AnimationPlayed:Connect(function(track)
            if not antiInvisOn then return end
            _hookAntiInvisAnim(track, char, player)
        end)
        table.insert(_antiInvisConns, animConn)
    end

    -- ── hook a player: setup now + rehook on every respawn ──
    local function _hookAntiInvisPlayer(player)
        if player == lp then return end
        -- setup current character if they have one
        if player.Character then
            _setupAntiInvisPlayer(player)
        end
        -- rehook every time they respawn
        local respawnConn = player.CharacterAdded:Connect(function()
            if not antiInvisOn then return end
            task.wait(0.5) -- let the character finish loading
            _setupAntiInvisPlayer(player)
        end)
        table.insert(_antiInvisConns, respawnConn)
    end

    BoxDeathCounter:AddToggle("AntiInvisToggle", {
        Text = "Anti-Invisibility", Default = false,
        Risky = true,
        Tooltip = "Can lag, also, Anti-invisibility on mech would be laggy, so there isn't any.",
        Callback = function(value)
            if value then
                antiInvisOn = true

                -- hook all current players + their future respawns
                for _, player in pairs(Players:GetPlayers()) do
                    _hookAntiInvisPlayer(player)
                end

                -- catch anyone who joins mid-game
                local addedConn = Players.PlayerAdded:Connect(function(player)
                    if not antiInvisOn then return end
                    _hookAntiInvisPlayer(player)
                end)
                table.insert(_antiInvisConns, addedConn)
            else
                _antiInvisCleanup()
            end
        end
    })
    table.insert(CleanupTasks, function()
        _antiInvisCleanup()
        pcall(function() Toggles.AntiInvisToggle:SetValue(false) end)
    end)
    BoxDeathCounter:AddToggle("AntiMoves_Trashcan", {
        Text = "Anti Trashcan",
        Default = false,
    })
    BoxDeathCounter:AddDivider()
    BoxDeathCounter:AddDropdown("AntiMoves_Saitama", {
        Text       = 'Anti Saitama',
        Values     = {
            "Anti Normal Punch",
            "Anti Consecutive Punches",
            "Anti Shove",
            "Anti Uppercut",
            "Anti Death Counter",
            "Anti Death Counter Shockwave",
            "Anti Table Flip",
            "Anti Serious Punch",
            "Anti Omni-Directional Punch",
        },
        Multi      = true,
        Default    = {},
        Searchable = true,
    })
    BoxDeathCounter:AddDropdown("AntiDCQuotesDD", {
        Text    = "Death Counter Quotes Mode",
        Values  = { "No Quotes", "Sukuna Quotes", "Gojo Quotes", "Name Quotes", "Admin Quotes", "Sans Quotes", "Random" },
        Default = 1,
        Multi   = false,
        Visible = false,
    })
    BoxDeathCounter:AddDropdown("AntiDCWaitBeforeKillDD", {
        Text    = "Anti Death Counter Delay",
        Values  = {
            "No Wait - Prevents Tabbing",
            "3s - Fakeout",
            "5s - Long Fakeout",
        },
        Default = 1,
        Multi   = false,
        Visible = false,
    })
    local function _syncAntiDCOptionVisibility()
        local show = Options.AntiMoves_Saitama
            and Options.AntiMoves_Saitama.Value
            and rawget(Options.AntiMoves_Saitama.Value, "Anti Death Counter")
        _setElemVisible(Options.AntiDCQuotesDD, show == true)
        _setElemVisible(Options.AntiDCWaitBeforeKillDD, show == true)
    end
    pcall(function()
        Options.AntiMoves_Saitama:OnChanged(_syncAntiDCOptionVisibility)
    end)
    task.defer(_syncAntiDCOptionVisibility)
    BoxDeathCounter:AddDropdown("AntiMoves_Garou", {
        Text       = 'Anti Garou',
        Values     = { "Anti Garou Ult", "Anti Final Hunt", "Anti Flowing Water", "Anti Lethal Whirlwind Stream", "Anti Hunters Grasp", "Anti Preys Peril", "Anti Water Stream Rock Smashing Fist", "Anti Rock Splitting Fist", "Anti Crushed Rock" },
        Multi      = true,
        Default    = {},
        Searchable = true,
    })
    BoxDeathCounter:AddDropdown("AntiMoves_Genos", {
        Text       = 'Anti Genos',
        Values     = { "Anti Thunder Kick", "Anti Flamewave Cannon", "Anti Incinerate" },
        Multi      = true,
        Default    = {},
        Searchable = true,
    })
    BoxDeathCounter:AddDropdown("AntiMoves_Tatsumaki", {
        Text       = 'Anti Tatsumaki',
        Values     = { "Anti Crushing Pull", "Anti Windstorm Fury", "Anti Stone Grave", "Anti Expulsive Push", "Anti Tatsumaki Ult", "Anti Terrible Tornado" },
        Multi      = true,
        Default    = {},
        Searchable = true,
    })
    BoxDeathCounter:AddDropdown("AntiMoves_AtomicSamurai", {
        Text       = 'Anti Atomic Samurai',
        Values     = { "Anti Atomic Samurai Ult", "Anti Sunset", "Anti Solar Cleave", "Anti Atomic Slash", "Anti Atomic Slash Finisher" },
        Multi      = true,
        Default    = {},
        Searchable = true,
    })
    BoxDeathCounter:AddDropdown("AntiMoves_Suiryu", {
        Text       = 'Anti Suiryu',
        Values     = { "Anti Whirlwind Drop", "Anti Suiryu Ult", "Anti Grand Fissure", "Anti Twin Fangs", "Anti Earth Splitting Strike", "Anti Last Breath" },
        Multi      = true,
        Default    = {},
        Searchable = true,
    })
    BoxDeathCounter:AddDropdown("AntiMoves_MetalBat", {
        Text       = '<font color="rgb(255,0,0)">Anti Metal Bat</font>',
        Values     = { "Anti Death Blow", "Anti Savage Tornado" },
        Multi      = true,
        Default    = {},
        Searchable = true,
    })
    BoxDeathCounter:AddDropdown("AntiMoves_Sonic", {
        Text       = '<font color="rgb(255,0,0)">Anti Sonic</font>',
        Values     = { "Anti Flash Strike", "Anti Whirlwind Kick", "Anti Twinblade Rush", "Anti Carnage", "Anti Fourfold Flashstrike" },
        Multi      = true,
        Default    = {},
        Searchable = true,
    })
    BoxDeathCounter:AddDropdown("AntiMoves_KJ", {
        Text       = '<font color="rgb(255,0,0)">Anti KJ</font>',
        Values     = { "Anti Stoic Bomb", "Anti 20-20-20 Dropkick", "Anti Five Seasons" },
        Multi      = true,
        Default    = {},
        Searchable = true,
    })
    BoxDeathCounter:AddDropdown("AntiMoves_FrozenSoul", {
        Text       = '<font color="rgb(0,255,255)">Anti Frozen Soul</font>',
        Values     = { "Anti Permafrost", "Anti Frost Forge", "Anti Freezing Path", "Anti Judgement Chain" },
        Multi      = true,
        Default    = {},
        Searchable = true,
    })
    function MoveNotify(player, moveName)
        if Options.MoveNotificationMoves and not rawget(Options.MoveNotificationMoves.Value, moveName) then return end
        if Toggles.MoveNotifications and Toggles.MoveNotifications.Value then
            Library:Notify({
                Title   = "Move Notification",
                Content = player.DisplayName .. " used " .. moveName,
                Time    = 5,
            })
        end
        if Toggles.ExposeMoveInChat and Toggles.ExposeMoveInChat.Value
           and not (Toggles.ExposeWhitelistedPlayers and Toggles.ExposeWhitelistedPlayers.Value and table.find(RevenantWhitelist, player)) then
            pcall(function()
                local tcs = game:GetService("TextChatService")
                if tcs.ChatVersion ~= Enum.ChatVersion.LegacyChatService then
                    if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
                        local ch = tcs.TextChannels:FindFirstChild("RBXGeneral")
                        if ch then ch:SendAsync("❗" .. player.DisplayName .. " used " .. moveName .. "❗") end
                    end
                else
                    local events = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                    local req = events and events:FindFirstChild("SayMessageRequest")
                    if events and req then req:FireServer("❗" .. player.DisplayName .. " used " .. moveName .. "❗", "all") end
                end
            end)
        end
    end
    local function deathCounterUltHighlightEnabled()
        return deathCounterActive
    end
    local function removeDeathCounterUltHighlight(char)
        local highlight = char and char:FindFirstChild("DeathCounterUltHighlight")
        if highlight then
            pcall(function() highlight:Destroy() end)
        end
    end
    local function updateDeathCounterUltHighlight(char)
        if not char or char.Name == "Weakest Dummy" then return end
        local targetPlayer = Players:GetPlayerFromCharacter(char)
        if not targetPlayer or targetPlayer == lp then return end
        local hasCounter = char:FindFirstChild("Counter") ~= nil
        local shouldHighlight = deathCounterUltHighlightEnabled()
            and char:GetAttribute("Character") == "Bald"
            and char:GetAttribute("Ulted") == true
            and not hasCounter
        local highlight = char:FindFirstChild("DeathCounterUltHighlight")
        if shouldHighlight then
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "DeathCounterUltHighlight"
                highlight.Adornee = char
                highlight.Parent = char
            end
            highlight.FillColor = Color3.fromRGB(255, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        elseif highlight then
            pcall(function() highlight:Destroy() end)
        end
    end
    local function hookDeathCounterUltChar(char)
        if not char or deathCounterUltHooked[char] then return end
        deathCounterUltHooked[char] = true
        updateDeathCounterUltHighlight(char)
        table.insert(deathCounterUltConns, char:GetAttributeChangedSignal("Ulted"):Connect(function()
            updateDeathCounterUltHighlight(char)
        end))
        table.insert(deathCounterUltConns, char:GetAttributeChangedSignal("Character"):Connect(function()
            updateDeathCounterUltHighlight(char)
        end))
        table.insert(deathCounterUltConns, char.ChildAdded:Connect(function(child)
            if isDeathCounter(child) then
                updateDeathCounterUltHighlight(char)
            end
        end))
        table.insert(deathCounterUltConns, char.ChildRemoved:Connect(function(child)
            if isDeathCounter(child) then
                updateDeathCounterUltHighlight(char)
            end
        end))
    end
    local function hookDeathCounterUltPlayer(player)
        if player == lp then return end
        if player.Character then
            hookDeathCounterUltChar(player.Character)
        end
        table.insert(deathCounterUltConns, player.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            hookDeathCounterUltChar(char)
        end))
    end
    refreshDeathCounterUltHighlights = function()
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                updateDeathCounterUltHighlight(player.Character)
            end
        end
    end
    for _, player in pairs(Players:GetPlayers()) do
        hookDeathCounterUltPlayer(player)
    end
    table.insert(deathCounterUltConns, Players.PlayerAdded:Connect(hookDeathCounterUltPlayer))
    table.insert(deathCounterUltConns, Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            removeDeathCounterUltHighlight(player.Character)
        end
    end))
    table.insert(CleanupTasks, function()
        for _, conn in pairs(deathCounterUltConns) do pcall(conn.Disconnect, conn) end
        deathCounterUltConns = {}
        deathCounterUltHooked = setmetatable({}, { __mode = "k" })
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                removeDeathCounterUltHighlight(player.Character)
            end
        end
    end)
    _antiMovesCharConns    = {}
    _antiMovesRespawnConns = {}
    local antidebug = false
    local _desyncCharConn = lp.CharacterAdded:Connect(function()
        getgenv().desync = nil
    end)

    -- isCountering: checks if a humanoid is currently in a counter state
    -- (either via a Counter object or by playing a counter animation)
    isCountering = function(hum)
        if not hum then return false end
        local model = hum:FindFirstAncestorWhichIsA("Model")
        if model and model:FindFirstChild("Counter") then return true end
        for _, t in pairs(hum:GetPlayingAnimationTracks()) do
            local id = t.Animation.AnimationId
            if id:match("13726226905") or id:match("13726235415") then return true end
        end
        return false
    end

    _watchEnemyAntiMoves = function(player, char)
        if not char then return end
        if _antiMovesCharConns[player] then
            pcall(function() _antiMovesCharConns[player]:Disconnect() end)
            _antiMovesCharConns[player] = nil
        end
        repeat
            task.wait()
        until not char.Parent
            or (char:FindFirstChild("HumanoidRootPart")
                and char:FindFirstChildOfClass("Humanoid"))
        if not char.Parent then return end
        local enemyRoot = char:FindFirstChild("HumanoidRootPart")
        local enemyHum  = char:FindFirstChildOfClass("Humanoid")
        if not (enemyRoot and enemyHum) then return end
        local function isAnimPlaying(hum, id)
            local _d = tostring(id):match("%d+")
            for _, t in pairs(hum:GetPlayingAnimationTracks()) do
                if t.Animation.AnimationId:match(_d) then return t end
            end
            return nil
        end
        local conn = enemyHum.AnimationPlayed:Connect(function(track)
            if Library.Unloaded then return end
            local animId = track.Animation.AnimationId
            local myChar = lp.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not (myChar and myRoot) then return end
            task.spawn(function()
                if track.WeightTarget == 0 or track.Speed == 0 then return end
                local DESYNC_CF = CFrame.new(9e9, 9e9, 9e9)
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                local function safeDesyncLoop(condFn)
                    pcall(function()
                        repeat
                            getgenv().desync = { CFrame = DESYNC_CF }
                            task.wait()
                            local c = lp.Character
                            local r = c and c:FindFirstChild("HumanoidRootPart")
                            local h = c and c:FindFirstChildOfClass("Humanoid")
                            if not (c and r and h) then return end
                            myRoot = r
                            myHum  = h
                        until condFn()
                    end)
                    getgenv().desync = nil
                    if _shpSupported then
                        local _cr = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if _cr then pcall(function() sethiddenproperty(_cr, "PhysicsRepRootPart", nil) end) end
                    end
                end
                local function isDeathCountering(hum)
                    if not hum then return false end
                    local model = hum:FindFirstAncestorWhichIsA("Model")
                    return model and model:FindFirstChild("Counter") and true or false
                end
                local function makeHitboxPart(size)
                    local p = Instance.new("Part", workspace)
                    p.Anchored = true p.Size = size p.CanCollide = false p.Transparency = 1
                    local touched = false
                    local c1 = p.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = true end end)
                    local c2 = p.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = false end end)
                    return p, function() return touched end, function()
                        pcall(function() p:Destroy() end) c1:Disconnect() c2:Disconnect()
                    end
                end
                local function getMyPos()
                    local _ip = getgenv().InvisPart30
                    if getgenv().InvisActive and _ip then return _ip.Position end
                    return myRoot.Position
                end
                if animId:match("10468665991")
                   and rawget(Options.AntiMoves_Saitama.Value, "Anti Normal Punch") then
                    local parts = {}
                    local offsets = {
                        CFrame.new(6, 0, -37.5) * CFrame.Angles(0, math.rad(-5), 0),
                        CFrame.new(-6, 0, -37.5) * CFrame.Angles(0, math.rad(5), 0),
                        CFrame.new(0, 0, -37.5),
                    }
                    local sizes = {Vector3.new(12.5,5,75), Vector3.new(12.5,5,75), Vector3.new(12.5,5,75)}
                    local touched = {false,false,false}
                    local conns = {}
                    for idx = 1, 3 do
                        local p = Instance.new("Part", workspace)
                        p.Anchored = true p.Size = sizes[idx] p.CanCollide = false p.Transparency = 1
                        table.insert(parts, p)
                        local i = idx
                        table.insert(conns, p.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched[i] = true end end))
                        table.insert(conns, p.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched[i] = false end end))
                    end
                    local t = tick()
                    repeat
                        for idx, p in ipairs(parts) do p.CFrame = enemyRoot.CFrame * offsets[idx] end
                        if (touched[1] or touched[2] or touched[3]) and not isCountering(enemyHum) then
                            getgenv().desync = { CFrame = DESYNC_CF }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 0.8 or not track.IsPlaying
                    getgenv().desync = nil
                    for _, c in ipairs(conns) do c:Disconnect() end
                    for _, p in ipairs(parts) do pcall(function() p:Destroy() end) end
                end
                if animId:match("10466974800")
                   and rawget(Options.AntiMoves_Saitama.Value, "Anti Consecutive Punches") then
                    local p, isTouched, cleanup = makeHitboxPart(Vector3.new(12.5,5,12.5))
                    local t = tick()
                    repeat
                        p.CFrame = enemyRoot.CFrame * CFrame.new(0,0,-6.25)
                        if isTouched() and not isCountering(enemyHum) then
                            getgenv().desync = { CFrame = DESYNC_CF }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 1.5 or not track.IsPlaying
                    getgenv().desync = nil cleanup()
                end
                if animId:match("10471336737")
                   and rawget(Options.AntiMoves_Saitama.Value, "Anti Shove") then
                    local p, isTouched, cleanup = makeHitboxPart(Vector3.new(7.5,5,7.5))
                    p.CFrame = enemyRoot.CFrame * CFrame.new(0,0,-3.75)
                    local t = tick()
                    repeat
                        p.CFrame = enemyRoot.CFrame * CFrame.new(0,0,-3.75)
                        if isTouched() and not isCountering(enemyHum) then
                            getgenv().desync = { CFrame = DESYNC_CF }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 0.5 or not track.IsPlaying
                    getgenv().desync = nil cleanup()
                end
                if animId:match("12510170988")
                   and rawget(Options.AntiMoves_Saitama.Value, "Anti Uppercut") then
                    task.wait(0.25)
                    if not track.IsPlaying then return end
                    local p, isTouched, cleanup = makeHitboxPart(Vector3.new(10,10,10))
                    local t = tick()
                    repeat
                        p.CFrame = enemyRoot.CFrame * CFrame.new(0,0,-5)
                        if isTouched() and not isCountering(enemyHum) then
                            getgenv().desync = { CFrame = DESYNC_CF }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 0.5 or not track.IsPlaying
                    getgenv().desync = nil cleanup()
                end
                if animId:match("12983333733")
                   and char:GetAttribute("Ulted") ~= nil then
                    MoveNotify(player, "Serious Punch")
                end
                if animId:match("12983333733")
                   and rawget(Options.AntiMoves_Saitama.Value, "Anti Serious Punch")
                   and char:GetAttribute("Ulted") ~= nil then
                    task.delay(1, function()
                        if char:FindFirstChild("AbsoluteImmortal", true) and char:FindFirstChild("Freeze") then
                            task.wait(4.25)
                            local t = tick()
                            safeDesyncLoop(function()
                                return (getMyPos() - enemyRoot.Position).Magnitude > 150
                                    or tick() >= t + 2
                                    or not track.IsPlaying
                            end)
                        end
                    end)
                end
                if animId:match("11365563255")
                   and char:GetAttribute("Ulted") ~= nil then
                    MoveNotify(player, "Table Flip")
                end
                if animId:match("11365563255")
                   and rawget(Options.AntiMoves_Saitama.Value, "Anti Table Flip")
                   and char:GetAttribute("Ulted") ~= nil then
                    task.delay(1, function()
                        if char:FindFirstChild("AbsoluteImmortal", true) and char:FindFirstChild("Freeze") then
                            task.wait(3)
                            local startTickAntiMoves = tick()
                            safeDesyncLoop(function()
                                return tick() >= startTickAntiMoves + 2.5
                            end)
                        end
                    end)
                end
                if animId:match("13927612951")
                   and char:GetAttribute("Ulted") ~= nil then
                    MoveNotify(player, "Omni-Directional Punch")
                end
                if animId:match("13927612951")
                   and rawget(Options.AntiMoves_Saitama.Value, "Anti Omni-Directional Punch")
                   and char:GetAttribute("Ulted") ~= nil then
                    local startTickSaitama = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 150
                            or tick() >= startTickSaitama + 2.5
                    end)
                end
                if animId:match("12342141464")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Garou Ult") then
                    task.wait(3.5)
                    local startTickTableFlip = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 125
                            or tick() >= startTickTableFlip + 1.25
                    end)
                end
                if animId:match("12463072679")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Final Hunt") then
                    local startTickOmni = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 25
                            or tick() >= startTickOmni + 0.75
                    end)
                end
                if animId:match("12272894215")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Flowing Water") then
                    local p, isTouched, cleanup = makeHitboxPart(Vector3.new(10,5,10))
                    local t = tick()
                    repeat
                        p.CFrame = enemyRoot.CFrame * CFrame.new(0,0,-5)
                        if isTouched() and not isCountering(enemyHum) then
                            getgenv().desync = { CFrame = DESYNC_CF }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 0.5 or not track.IsPlaying
                    getgenv().desync = nil cleanup()
                end
                if animId:match("12273188754")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Flowing Water") then
                    local p, isTouched, cleanup = makeHitboxPart(Vector3.new(15,5,15))
                    local t = tick()
                    repeat
                        p.CFrame = enemyRoot.CFrame * CFrame.new(0,0,-7.5)
                        if isTouched() and not isCountering(enemyHum) then
                            getgenv().desync = { CFrame = DESYNC_CF }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 2 or not track.IsPlaying
                    getgenv().desync = nil cleanup()
                end
                if animId:match("14374357351")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Flowing Water") then
                    local p, isTouched, cleanup = makeHitboxPart(Vector3.new(10,5,15))
                    local t = tick()
                    repeat
                        p.CFrame = enemyRoot.CFrame * CFrame.new(0,0,-7.5)
                        if isTouched() and not isCountering(enemyHum) then
                            getgenv().desync = { CFrame = DESYNC_CF }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 1.5 or not track.IsPlaying
                    getgenv().desync = nil cleanup()
                    task.wait(0.5)
                    local t2 = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 25
                            or tick() >= t2 + 1.25
                    end)
                end
                if animId:match("12296882427")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Lethal Whirlwind Stream") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - (enemyRoot.CFrame * CFrame.new(0,0,-2.5)).Position).Magnitude > 10
                            or isCountering(enemyHum)
                            or tick() >= t + 0.5
                    end)
                end
                if animId:match("12296113986")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Lethal Whirlwind Stream") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 15
                            or tick() >= t + 0.5
                    end)
                    task.delay(1.35, function()
                        local t2 = tick()
                        repeat task.wait()
                        until (getMyPos() - enemyRoot.Position).Magnitude <= 15 or tick() >= t2 + 0.65
                        if (getMyPos() - enemyRoot.Position).Magnitude <= 15 then
                            local t3 = tick()
                            safeDesyncLoop(function()
                                return (getMyPos() - enemyRoot.Position).Magnitude > 15
                                    or tick() >= t3 + 0.65
                            end)
                        end
                    end)
                end
                if animId:match("14798608838")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Lethal Whirlwind Stream") then
                    task.delay(0.75, function()
                        local t = tick()
                        repeat task.wait()
                        until (getMyPos() - enemyRoot.Position).Magnitude <= 25 or tick() >= t + 0.75
                        if (getMyPos() - enemyRoot.Position).Magnitude <= 25 then
                            local t2 = tick()
                            safeDesyncLoop(function()
                                return (getMyPos() - enemyRoot.Position).Magnitude > 25
                                    or tick() >= t2 + 0.75
                            end)
                        end
                    end)
                end
                if animId:match("12307656616")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Hunters Grasp") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - (enemyRoot.CFrame * CFrame.new(0,0,-2.5)).Position).Magnitude > 10
                            or isCountering(enemyHum)
                            or tick() >= t + 0.35
                    end)
                end
                if animId:match("13603396939")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Preys Peril") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - (enemyRoot.CFrame * CFrame.new(0,0,-1)).Position).Magnitude > 7.5
                            or isCountering(enemyHum)
                            or tick() >= t + 2.5
                    end)
                end
                if animId:match("12460977270")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Water Stream Rock Smashing Fist") then
                    local p, isTouched, cleanup = makeHitboxPart(Vector3.new(12.5,5,12.5))
                    local t = tick()
                    repeat
                        p.CFrame = enemyRoot.CFrame * CFrame.new(0,0,-6.25)
                        if isTouched() and not isCountering(enemyHum) then
                            getgenv().desync = { CFrame = DESYNC_CF }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 1.85 or not track.IsPlaying
                    getgenv().desync = nil cleanup()
                end
                if animId:match("14057231976")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Rock Splitting Fist") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 10
                            or tick() >= t + 0.5
                    end)
                    task.wait(0.5)
                    local t2 = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 10
                            or isCountering(enemyHum)
                            or tick() >= t2 + 1.25
                    end)
                end
                if animId:match("13630786846")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Crushed Rock") then
                    local p, isTouched, cleanup = makeHitboxPart(Vector3.new(25,10,75))
                    local t = tick()
                    repeat
                        p.CFrame = enemyRoot.CFrame * CFrame.new(0,0,-37.5)
                        if isTouched() and not isCountering(enemyHum) then
                            getgenv().desync = { CFrame = DESYNC_CF }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 1.5 or not track.IsPlaying
                    getgenv().desync = nil cleanup()
                end
                if animId:match("72451715583225")
                   and rawget(Options.AntiMoves_Garou.Value, "Anti Crushed Rock") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 15
                            or tick() >= t + 0.75
                    end)
                end
                if animId:match("13813955149") and Toggles.AntiMoves_Trashcan and Toggles.AntiMoves_Trashcan.Value then
                    if (getMyPos() - enemyRoot.Position).Magnitude <= 25 then
                        getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                        task.wait(0.75)
                        getgenv().desync = nil
                    end
                    local trashConn = nil
                    trashConn = workspace.Thrown.ChildAdded:Connect(function(p)
                        if p:IsA("MeshPart") and p.Name:lower() == "trash can" then
                            trashConn:Disconnect()
                            local t = tick()
                            safeDesyncLoop(function()
                                return (getMyPos() - p.Position).Magnitude > 25
                                    or tick() >= t + 2
                            end)
                        end
                    end)
                end
                if animId:match("15128849047") then
                    MoveNotify(player, "Death Blow")
                end
                if animId:match("15128849047")
                   and rawget(Options.AntiMoves_MetalBat.Value, "Anti Death Blow") then
                    local startTickGarou = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 100
                            or isAnimPlaying(enemyHum, "15123665491")
                            or tick() >= startTickGarou + 3
                    end)
                end
                if animId:match("15391323441")
                   and rawget(Options.AntiMoves_AtomicSamurai.Value, "Anti Atomic Samurai Ult") then
                    task.wait(5.5)
                    local startTickFinalHunt = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 125
                            or tick() >= startTickFinalHunt + 1
                    end)
                end
                if animId:match("16082123712")
                   and rawget(Options.AntiMoves_AtomicSamurai.Value, "Anti Atomic Slash") then
                    task.wait(2.5)
                    local startTickMetalBat = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 50
                            or tick() >= startTickMetalBat + 1.5
                    end)
                end
                if animId:match("14719290328")
                   and rawget(Options.AntiMoves_MetalBat.Value, "Anti Savage Tornado") then
                    if (getMyPos() - enemyRoot.Position).Magnitude <= 50 then
                        getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                    end
                    task.wait(0.5)
                    if track.IsPlaying then
                        local t = tick()
                        safeDesyncLoop(function()
                            return (getMyPos() - enemyRoot.Position).Magnitude > 50
                                or isDeathCountering(myHum)
                                or tick() >= t + 3.5
                                or not track.IsPlaying
                        end)
                    end
                end
                if animId:match("15520132233")
                   and rawget(Options.AntiMoves_AtomicSamurai.Value, "Anti Sunset") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 50
                            or isDeathCountering(myHum)
                            or tick() >= t + 3.3
                            or not track.IsPlaying
                    end)
                    repeat task.wait() until tick() >= t + 5.5
                    local t2 = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 100
                            or isDeathCountering(myHum)
                            or tick() >= t2 + 1
                            or not track.IsPlaying
                    end)
                end
                if animId:match("15676072469")
                   and rawget(Options.AntiMoves_AtomicSamurai.Value, "Anti Solar Cleave") then
                    local p, isTouched, cleanup = makeHitboxPart(Vector3.new(50,10,150))
                    local t = tick()
                    repeat
                        p.CFrame = enemyRoot.CFrame * CFrame.new(0,0,-75)
                        if isTouched() and not isDeathCountering(myHum) then
                            getgenv().desync = { CFrame = DESYNC_CF }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 2 or not track.IsPlaying
                    getgenv().desync = nil cleanup()
                end
                if animId:match("16057411888")
                   and rawget(Options.AntiMoves_AtomicSamurai.Value, "Anti Atomic Slash Finisher") then
                    task.wait(4.25)
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 50
                            or tick() >= t + 2
                    end)
                end
                if animId:match("18435535291")
                   and rawget(Options.AntiMoves_Suiryu.Value, "Anti Suiryu Ult") then
                    task.wait(4.25)
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 100
                            or tick() >= t + 1.25
                    end)
                end
                if animId:match("17857788598")
                   and rawget(Options.AntiMoves_Suiryu.Value, "Anti Whirlwind Drop") then
                    task.wait(0.65)
                    if track.IsPlaying then
                        local part = Instance.new("Part", workspace)
                        part.Anchored = true part.Size = Vector3.new(35, 2048, 35)
                        part.CanCollide = false part.Transparency = 1
                        local touched = false
                        local c1 = part.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = true end end)
                        local c2 = part.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = false end end)
                        local t = tick()
                        repeat
                            part.CFrame = enemyRoot.CFrame
                            if touched and not isAnimPlaying(enemyHum, "15128849047") then
                                getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                            else
                                getgenv().desync = nil
                            end
                            RunService.RenderStepped:Wait()
                        until tick() >= t + 0.85 or not track.IsPlaying
                        getgenv().desync = nil
                        c1:Disconnect() c2:Disconnect()
                        pcall(function() part:Destroy() end)
                    end
                end
                if animId:match("129651400898906")
                   and rawget(Options.AntiMoves_Suiryu.Value, "Anti Grand Fissure") then
                    task.wait(0.5)
                    local savedEnemyCF = enemyRoot.CFrame
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 75
                            or tick() >= t + 1.25
                            or not track.IsPlaying
                    end)
                    task.wait(1)
                    local t2 = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - savedEnemyCF.Position).Magnitude > 75
                            or tick() >= t2 + 1.75
                    end)
                end
                if animId:match("18896229321")
                   and rawget(Options.AntiMoves_Suiryu.Value, "Anti Twin Fangs") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 15
                            or isCountering(enemyHum)
                            or tick() >= t + 3.5
                            or not track.IsPlaying
                    end)
                    task.wait(1)
                    if track.IsPlaying then
                        if (getMyPos() - enemyRoot.Position).Magnitude <= 25 then
                            local t2 = tick()
                            safeDesyncLoop(function()
                                return (getMyPos() - enemyRoot.Position).Magnitude > 25
                                    or tick() >= t2 + 2
                                    or not track.IsPlaying
                            end)
                        end
                    end
                end
                if animId:match("18897119503")
                   and rawget(Options.AntiMoves_Suiryu.Value, "Anti Earth Splitting Strike") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 50
                            or tick() >= t + 1.5
                    end)
                end
                if animId:match("106755459092436") or animId:match("75502010126640") then
                    MoveNotify(player, "Last Breath")
                end
                if (animId:match("106755459092436") or animId:match("75502010126640"))
                   and rawget(Options.AntiMoves_Suiryu.Value, "Anti Last Breath") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 50
                            or tick() >= t + 2
                    end)
                end
                if animId:match("16515850153")
                   and rawget(Options.AntiMoves_Tatsumaki.Value, "Anti Windstorm Fury") then
                    task.spawn(function()
                        if (getMyPos() - enemyRoot.Position).Magnitude <= 15 then
                            getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                        end
                        local _Dotted = workspace.Thrown:WaitForChild("Dotted", 1)
                        if _Dotted then
                            local _Dots = _Dotted:WaitForChild("Dots", 1)
                            if not _Dots then
                                getgenv().desync = nil
                                return
                            end
                            local t = tick()
                            if (getMyPos() - _Dots.Position).Magnitude > 20 then
                                getgenv().desync = nil
                            end
                            safeDesyncLoop(function()
                                return (getMyPos() - _Dots.Position).Magnitude > 20
                                    or isDeathCountering(myHum)
                                    or tick() >= t + 4.25
                            end)
                        else
                            getgenv().desync = nil
                        end
                    end)
                end
                if animId:match("16431491215")
                   and rawget(Options.AntiMoves_Tatsumaki.Value, "Anti Stone Grave") then
                    local t = tick()
                    repeat task.wait()
                    until (getMyPos() - (enemyRoot.CFrame * CFrame.new(0, 0, -25)).Position).Magnitude <= 25
                        or isAnimPlaying(enemyHum, "15128849047")
                        or tick() >= t + 0.75
                    if not isAnimPlaying(enemyHum, "15128849047") then
                        safeDesyncLoop(function()
                            return (getMyPos() - (enemyRoot.CFrame * CFrame.new(0, 0, -20)).Position).Magnitude > 25
                                or isAnimPlaying(enemyHum, "15128849047")
                                or tick() >= t + 0.75
                        end)
                    end
                end
                if animId:match("16597912086")
                   and rawget(Options.AntiMoves_Tatsumaki.Value, "Anti Expulsive Push") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 15
                            or isCountering(enemyHum)
                            or tick() >= t + 0.75
                    end)
                end
                if animId:match("17275150809")
                   and rawget(Options.AntiMoves_Tatsumaki.Value, "Anti Terrible Tornado") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 50
                            or tick() >= t + 1
                    end)
                end
                if animId:match("17278415853")
                   and char:GetAttribute("Character") == "Esper"
                   and rawget(Options.AntiMoves_Tatsumaki.Value, "Anti Terrible Tornado") then
                    task.wait(11)
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 100
                            or tick() >= t + 6
                    end)
                end
                if animId:match("16734584478")
                   and rawget(Options.AntiMoves_Tatsumaki.Value, "Anti Tatsumaki Ult") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 75
                            or tick() >= t + 5.75
                    end)
                end
                if animId:match("13376869471")
                   and rawget(Options.AntiMoves_Sonic.Value, "Anti Flash Strike") then
                    local part = Instance.new("Part", workspace)
                    part.Anchored = true part.Size = Vector3.new(10, 7.5, 60)
                    part.CanCollide = false part.Transparency = 1
                    local touched = false
                    local c1 = part.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = true end end)
                    local c2 = part.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = false end end)
                    local t = tick()
                    repeat
                        part.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, -part.Size.Z / 2)
                        RunService.RenderStepped:Wait()
                    until touched or tick() >= t + 3 or not track.IsPlaying
                    if touched then
                        local t2 = tick()
                        safeDesyncLoop(function()
                            return not touched or tick() >= t2 + 1 or not track.IsPlaying
                        end)
                    end
                    c1:Disconnect() c2:Disconnect()
                    pcall(function() part:Destroy() end)
                end
                if animId:match("13294790250")
                   and rawget(Options.AntiMoves_Sonic.Value, "Anti Whirlwind Kick") then
                    task.wait(0.5)
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - (enemyRoot.CFrame * CFrame.new(0, 0, -2.5)).Position).Magnitude > 10
                            or isCountering(enemyHum)
                            or tick() >= t + 0.75
                    end)
                end
                if animId:match("13632347366")
                   and rawget(Options.AntiMoves_Sonic.Value, "Anti Twinblade Rush") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 75
                            or isDeathCountering(myHum)
                            or tick() >= t + 1.75
                            or not track.IsPlaying
                    end)
                end
                if animId:match("13723174078")
                   and rawget(Options.AntiMoves_Sonic.Value, "Anti Carnage") then
                    task.wait(0.5)
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 50
                            or tick() >= t + 2
                            or not track.IsPlaying
                    end)
                end
                if animId:match("13881335713")
                   and rawget(Options.AntiMoves_Sonic.Value, "Anti Fourfold Flashstrike") then
                    task.wait(0.75)
                    if track.IsPlaying then
                        local part = Instance.new("Part", workspace)
                        part.Anchored = true part.Size = Vector3.new(35, 5, 60)
                        part.CanCollide = false part.Transparency = 1
                        local touched = false
                        local c1 = part.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = true end end)
                        local c2 = part.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = false end end)
                        local t = tick()
                        repeat
                            part.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, -part.Size.Z / 2)
                            RunService.RenderStepped:Wait()
                        until touched or tick() >= t + 3 or not track.IsPlaying
                        if touched then
                            local t2 = tick()
                            safeDesyncLoop(function()
                                return not touched or tick() >= t2 + 1 or not track.IsPlaying
                            end)
                        end
                        c1:Disconnect() c2:Disconnect()
                        pcall(function() part:Destroy() end)
                    end
                end
                if animId:match("14721837245")
                   and rawget(Options.AntiMoves_Genos.Value, "Anti Thunder Kick") then
                    local t = tick()
                    safeDesyncLoop(function()
                        return (getMyPos() - enemyRoot.Position).Magnitude > 25
                            or isAnimPlaying(enemyHum, "15128849047")
                            or tick() >= t + 1.5
                            or not track.IsPlaying
                    end)
                    if tick() >= t + 1.5 then
                        task.wait(1)
                        local t2 = tick()
                        safeDesyncLoop(function()
                            return (getMyPos() - enemyRoot.Position).Magnitude > 100
                                or tick() >= t2 + 1.5
                                or not track.IsPlaying
                        end)
                    end
                end
                if animId:match("13083332742")
                   and rawget(Options.AntiMoves_Genos.Value, "Anti Flamewave Cannon") then
                    task.wait(1)
                    local part = Instance.new("Part", workspace)
                    part.Anchored = true part.Size = Vector3.new(12.5, 5, 1000)
                    part.CanCollide = false part.Transparency = 1
                    task.delay(0.25, function() part.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, -part.Size.Z / 2) end)
                    local touched = false
                    local c1 = part.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = true end end)
                    local c2 = part.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = false end end)
                    local t = tick()
                    repeat
                        if touched and not isDeathCountering(myHum) then
                            getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                        else getgenv().desync = nil end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 4 or not track.IsPlaying
                    getgenv().desync = nil
                    c1:Disconnect() c2:Disconnect()
                    pcall(function() part:Destroy() end)
                end
                if animId:match("13146710762")
                   and rawget(Options.AntiMoves_Genos.Value, "Anti Incinerate") then
                    task.wait(3.25)
                    if track.IsPlaying then
                        local parts = {}
                        local offsets = {
                            CFrame.new(50, 0, -200) * CFrame.Angles(0, math.rad(-15), 0),
                            CFrame.new(-50, 0, -200) * CFrame.Angles(0, math.rad(15), 0),
                            CFrame.new(0, 0, -200),
                        }
                        local touched = false
                        local conns = {}
                        for _, off in ipairs(offsets) do
                            local p = Instance.new("Part", workspace)
                            p.Anchored = true p.Size = Vector3.new(100, 75, 400)
                            p.CanCollide = false p.Transparency = 1
                            p.CFrame = enemyRoot.CFrame * off
                            table.insert(parts, p)
                            table.insert(conns, p.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = true end end))
                            table.insert(conns, p.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = false end end))
                        end
                        local t = tick()
                        repeat
                            if touched and not isDeathCountering(myHum) then
                                getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                            else getgenv().desync = nil end
                            RunService.RenderStepped:Wait()
                        until tick() >= t + 6 or not track.IsPlaying
                        getgenv().desync = nil
                        for _, c in ipairs(conns) do c:Disconnect() end
                        for _, p in ipairs(parts) do pcall(function() p:Destroy() end) end
                    end
                end
                if animId:match("17141153099")
                   and rawget(Options.AntiMoves_KJ.Value, "Anti Stoic Bomb") then
                    task.delay(2, function()
                        local t = tick()
                        repeat task.wait()
                        until (getMyPos() - enemyRoot.Position).Magnitude <= 75 or tick() >= t + 1.5
                        if (getMyPos() - enemyRoot.Position).Magnitude <= 75 then
                            local t2 = tick()
                            safeDesyncLoop(function()
                                return (getMyPos() - enemyRoot.Position).Magnitude > 75
                                    or tick() >= t2 + 1.5
                            end)
                        end
                    end)
                end
                if animId:match("17354976067")
                   and rawget(Options.AntiMoves_KJ.Value, "Anti 20-20-20 Dropkick") then
                    task.delay(1, function()
                        local part = Instance.new("Part", workspace)
                        part.Anchored = true part.Size = Vector3.new(25, 5, 125)
                        part.CanCollide = false part.Transparency = 1
                        local touched = false
                        local c1 = part.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = true end end)
                        local c2 = part.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = false end end)
                        local t = tick()
                        repeat
                            part.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, -part.Size.Z / 2)
                            RunService.RenderStepped:Wait()
                        until touched or tick() >= t + 5 or not track.IsPlaying
                        if touched then
                            local t2 = tick()
                            safeDesyncLoop(function()
                                return not touched or tick() >= t2 + 1.5 or not track.IsPlaying
                            end)
                        end
                        c1:Disconnect() c2:Disconnect()
                        pcall(function() part:Destroy() end)
                    end)
                end
                if animId:match("18462894593")
                   and rawget(Options.AntiMoves_KJ.Value, "Anti Five Seasons") then
                    task.delay(6.75, function()
                        local t = tick()
                        safeDesyncLoop(function() return tick() >= t + 1 end)
                    end)
                end
                if animId:match("100558589307006")
                   and rawget(Options.AntiMoves_FrozenSoul.Value, "Anti Permafrost") then
                    task.wait(0.35)
                    if track.IsPlaying then
                        local part = Instance.new("Part", workspace)
                        part.Anchored = true part.Size = Vector3.new(45, 25, 85)
                        part.CanCollide = false part.Transparency = 1
                        local touched = false
                        local c1 = part.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = true end end)
                        local c2 = part.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = false end end)
                        local t = tick()
                        repeat
                            part.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, -part.Size.Z / 2)
                            if touched and not isAnimPlaying(enemyHum, "15128849047") then
                                getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                            else getgenv().desync = nil end
                            task.wait()
                        until tick() >= t + 0.65 or not track.IsPlaying
                        getgenv().desync = nil
                        c1:Disconnect() c2:Disconnect()
                        pcall(function() part:Destroy() end)
                    end
                end
                if animId:match("137561511768861")
                   and rawget(Options.AntiMoves_FrozenSoul.Value, "Anti Frost Forge") then
                    task.delay(1, function()
                        local t = tick()
                        repeat task.wait()
                        until (getMyPos() - enemyRoot.Position).Magnitude <= 150 or tick() >= t + 0.75
                        if (getMyPos() - enemyRoot.Position).Magnitude <= 150 then
                            local t2 = tick()
                            safeDesyncLoop(function()
                                return (getMyPos() - enemyRoot.Position).Magnitude > 150
                                    or tick() >= t2 + 0.75
                            end)
                        end
                    end)
                end
                if animId:match("112620365240235")
                   and rawget(Options.AntiMoves_FrozenSoul.Value, "Anti Freezing Path") then
                    task.wait(0.5)
                    if track.IsPlaying then
                        local part = Instance.new("Part", workspace)
                        part.Anchored = true part.Size = Vector3.new(20, 10, 35)
                        part.CanCollide = false part.Transparency = 1
                        local touched = false
                        local c1 = part.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = true end end)
                        local c2 = part.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = false end end)
                        local t = tick()
                        repeat
                            part.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, -part.Size.Z / 2)
                            if touched and not isAnimPlaying(enemyHum, "15128849047") then
                                getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                            else getgenv().desync = nil end
                            task.wait()
                        until tick() >= t + 4 or not track.IsPlaying
                        getgenv().desync = nil
                        c1:Disconnect() c2:Disconnect()
                        pcall(function() part:Destroy() end)
                    end
                end
                if animId:match("75547590335774")
                   and rawget(Options.AntiMoves_FrozenSoul.Value, "Anti Judgement Chain") then
                    task.wait(0.35)
                    if track.IsPlaying then
                        local part = Instance.new("Part", workspace)
                        part.Anchored = true part.Size = Vector3.new(10, 5, 175)
                        part.CanCollide = false part.Transparency = 1
                        local touched = false
                        local c1 = part.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = true end end)
                        local c2 = part.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched = false end end)
                        local t = tick()
                        repeat
                            part.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, -part.Size.Z / 2)
                            if touched and not isAnimPlaying(enemyHum, "15128849047") then
                                getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                            else getgenv().desync = nil end
                            task.wait()
                        until tick() >= t + 1 or not track.IsPlaying
                        getgenv().desync = nil
                        c1:Disconnect() c2:Disconnect()
                        pcall(function() part:Destroy() end)
                    end
                end
                if animId:match("11343318134")
                   and rawget(Options.AntiMoves_Saitama.Value, "Anti Death Counter Shockwave") then
                    task.wait(7.5)
                    if not track.IsPlaying then return end
                    local parts = {}
                    local offsets = {
                        CFrame.new(60, 0, -250) * CFrame.Angles(0, math.rad(-15), 0),
                        CFrame.new(-60, 0, -250) * CFrame.Angles(0, math.rad(15), 0),
                        CFrame.new(0, 0, -250),
                    }
                    local touched = {false, false, false}
                    local conns = {}
                    for idx, off in ipairs(offsets) do
                        local p = Instance.new("Part", workspace)
                        p.Anchored = true p.Size = Vector3.new(125, 5, 500)
                        p.CanCollide = false p.Transparency = 1
                        table.insert(parts, p)
                        local i = idx
                        table.insert(conns, p.Touched:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched[i] = true end end))
                        table.insert(conns, p.TouchEnded:Connect(function(h) if h == myRoot or h == getgenv().InvisPart30 then touched[i] = false end end))
                    end
                    local t = tick()
                    repeat
                        for idx, p in ipairs(parts) do
                            p.CFrame = enemyRoot.CFrame * offsets[idx]
                        end
                        if touched[1] or touched[2] or touched[3] then
                            getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                        else
                            getgenv().desync = nil
                        end
                        RunService.RenderStepped:Wait()
                    until tick() >= t + 2.5 or not track.IsPlaying
                    getgenv().desync = nil
                    for _, c in ipairs(conns) do c:Disconnect() end
                    for _, p in ipairs(parts) do pcall(function() p:Destroy() end) end
                end
            end)
        end)
        _antiMovesCharConns[player] = conn
    end
    _hookPlayerAntiMoves = function(player)
        if player == lp then return end
        if player.Character then
            task.spawn(_watchEnemyAntiMoves, player, player.Character)
        end
        local c = player.CharacterAdded:Connect(function(char)
            task.spawn(_watchEnemyAntiMoves, player, char)
        end)
        _antiMovesRespawnConns[player] = c
    end
    for _, p in pairs(Players:GetPlayers()) do
        task.spawn(_hookPlayerAntiMoves, p)
    end
    local _antiMovesPlayerConn = Players.PlayerAdded:Connect(function(p)
        if p == lp then return end
        task.spawn(function()
            local t = tick()
            repeat
                RunService.RenderStepped:Wait()
            until p:GetAttribute("PreloadDone") or tick() >= t + 30
            if p and p.Parent then
                if p.Character then
                    task.spawn(_watchEnemyAntiMoves, p, p.Character)
                end
                local c = p.CharacterAdded:Connect(function(char)
                    task.spawn(_watchEnemyAntiMoves, p, char)
                end)
                _antiMovesRespawnConns[p] = c
            end
        end)
    end)
    local _antiMovesPlayerRemovingConn = Players.PlayerRemoving:Connect(function(p)
        if _antiMovesCharConns[p] then
            pcall(function() _antiMovesCharConns[p]:Disconnect() end)
            _antiMovesCharConns[p] = nil
        end
        if _antiMovesRespawnConns[p] then
            pcall(function() _antiMovesRespawnConns[p]:Disconnect() end)
            _antiMovesRespawnConns[p] = nil
        end
    end)
    table.insert(CleanupTasks, function()
        pcall(function() _antiMovesPlayerConn:Disconnect() end)
        for _, c in pairs(_antiMovesCharConns)    do pcall(c.Disconnect, c) end
        for _, c in pairs(_antiMovesRespawnConns) do pcall(c.Disconnect, c) end
        _antiMovesCharConns    = {}
        _antiMovesRespawnConns = {}
        getgenv().desync = nil
        pcall(function() Toggles.AntiMoves_Trashcan:SetValue(false) end)
        pcall(function() Options.AntiMoves_Saitama:SetValue({}) end)
        pcall(function() Options.AntiMoves_Garou:SetValue({}) end)
        pcall(function() Options.AntiMoves_Genos:SetValue({}) end)
        pcall(function() Options.AntiMoves_Tatsumaki:SetValue({}) end)
        pcall(function() Options.AntiMoves_AtomicSamurai:SetValue({}) end)
        pcall(function() Options.AntiMoves_Suiryu:SetValue({}) end)
        pcall(function() Options.AntiMoves_MetalBat:SetValue({}) end)
        pcall(function() Options.AntiMoves_Sonic:SetValue({}) end)
        pcall(function() Options.AntiMoves_KJ:SetValue({}) end)
        pcall(function() Options.AntiMoves_FrozenSoul:SetValue({}) end)
        pcall(function() Toggles.ShowDeathCounter:SetValue(false) end)
    end)
    task.spawn(function()
        local _cloned_char = nil
        task.spawn(function()
            repeat task.wait() until lp.Character
            local _lp_char = lp.Character
            _cloned_char = Instance.new('Model')
            _lp_char.Archivable = true
            local _lpchar_parts = _lp_char:Clone()
            _lp_char.Archivable = false
            if _lpchar_parts:FindFirstChildWhichIsA('Humanoid') then
                _lpchar_parts.Humanoid:Destroy()
            end
            for _, _charpart in pairs(_lpchar_parts:GetChildren()) do
                if _charpart:IsA('Humanoid') then
                    _charpart:Destroy()
                elseif _charpart:IsA('BasePart') or _charpart:IsA('MeshPart') then
                    local _cloned_charpart = _charpart:Clone()
                    _cloned_charpart.CanCollide  = false
                    _cloned_charpart.Anchored    = true
                    _cloned_charpart.Transparency = not table.find({
                        'HumanoidRootPart',
                        'FakeHead',
                        'Hitbox_RightArm',
                        'Hitbox_LeftArm',
                        'Hitbox_RightLeg',
                        'Hitbox_LeftLeg',
                    }, _cloned_charpart.Name) and 0.65 or 1
                    _cloned_charpart.Color = Color3.fromRGB(255, 255, 255)
                    _cloned_charpart.Size  = _cloned_charpart.Size * 1.01
                    _cloned_charpart.Parent = _cloned_char
                    if _cloned_charpart.Name ~= 'Head' then
                        if _cloned_charpart.Name ~= 'HumanoidRootPart' then
                            _cloned_charpart.Material = Enum.Material.ForceField
                            local _SpecialMesh = Instance.new('SpecialMesh', _cloned_charpart)
                            _SpecialMesh.Scale       = _cloned_charpart.Size
                            _SpecialMesh.TextureId   = 'rbxassetid://5101923607'
                            _SpecialMesh.VertexColor = Vector3.new(255, 0, 0)
                        end
                    else
                        _cloned_charpart.Color = Color3.fromRGB(255, 0, 0)
                    end
                    for _, _trash_part in pairs({
                        'Sound',
                        'Decal',
                        'Trail',
                        'BodyVelocity',
                        'BodyGyro',
                        'BodyPosition',
                        'ParticleEmitter',
                    }) do
                        local v1370 = _cloned_charpart:FindFirstChildWhichIsA(_trash_part)
                        if v1370 then
                            v1370:Destroy()
                        end
                    end
                end
            end
            _cloned_char.Parent = workspace.Terrain
            getgenv()._vizClone = _cloned_char
        end)
        RunService.Heartbeat:Connect(function()
            if Library.Unloaded then return end
            if not _cloned_char then return end
            local v1379 = lp.Character
            if not v1379 then return end
            local v1380 = v1379:FindFirstChild('HumanoidRootPart')
            local v1381 = v1379:FindFirstChildOfClass('Humanoid')
            if not (v1380 and v1381) then return end
            local v1383 = nil
            local v1385 = false
            if _pU59.Invisibility or _pU59['Doing Wall Combo Anywhere'] then
                v1385 = (not getgenv().desync or v1379:FindFirstChild('AbsoluteImmortal')) and true or v1385
            end
            if v1381.Health > 0 then
                if _pU59.Invisibility or _pU59['Upside Down'] then
                    v1383 = v1380.CFrame * CFrame.Angles(0, 0, math.rad(180))
                end
                if getgenv().flingDesync then
                    v1383 = getgenv().flingDesync.CFrame or v1383
                end
                if getgenv().desync and not v1379:FindFirstChild('AbsoluteImmortal') then
                    v1383 = getgenv().desync.CFrame or v1383
                end
            end
            if v1385 and Toggles.Visualizer and Toggles.Visualizer.Value then
                for _, v1390 in pairs(_cloned_char:GetChildren()) do
                    if v1390:IsA('BasePart') then
                        local v1391 = v1379:FindFirstChild(v1390.Name)
                        if v1391 and v1391:IsA('BasePart') then
                            v1390.CFrame = v1391.CFrame
                        end
                    end
                end
            end
            if v1383 then
                if Toggles.Visualizer and Toggles.Visualizer.Value
                   and not (Toggles.AlwaysVisualize and Toggles.AlwaysVisualize.Value)
                   and not v1385 then
                    for _, v1396 in pairs(_cloned_char:GetChildren()) do
                        if v1396:IsA('BasePart') then
                            local v1397 = v1379:FindFirstChild(v1396.Name)
                            if v1397 and v1397:IsA('BasePart') then
                                v1396.CFrame = v1397.CFrame
                            end
                        end
                    end
                end
            end
            if not v1385 then
                if Toggles.Visualizer and Toggles.Visualizer.Value
                   and Toggles.AlwaysVisualize and Toggles.AlwaysVisualize.Value then
                    for _, v1402 in pairs(_cloned_char:GetChildren()) do
                        if v1402:IsA('BasePart') then
                            local v1403 = v1379:FindFirstChild(v1402.Name)
                            if v1403 and v1403:IsA('BasePart') then
                                v1402.CFrame = v1403.CFrame
                            end
                        end
                    end
                elseif not (Toggles.Visualizer and Toggles.Visualizer.Value
                            and (Toggles.AlwaysVisualize and Toggles.AlwaysVisualize.Value or v1383)) then
                    for _, v1408 in pairs(_cloned_char:GetChildren()) do
                        if v1408:IsA('BasePart') then
                            v1408.CFrame = CFrame.new(0, 1000000, 0)
                        end
                    end
                end
            end
        end)
    end)
    task.spawn(function()
        local function _initDesyncEffects(char)
            repeat task.wait()
            until (lp.Character == char)
                and char:FindFirstChild('HumanoidRootPart')
                and char:FindFirstChildOfClass('Humanoid')
            if lp.Character ~= char then return end
            local root = char:FindFirstChild('HumanoidRootPart')
            task.spawn(function()
                while task.wait() and (not lp.Character or lp.Character == char) do
                    if getgenv().desync and not char:FindFirstChild('AbsoluteImmortal') then
                        local v901 = {}
                        local ok1, afterimage = pcall(function()
                            return _ReplicatedStorage.Resources.NinjaUlt.Afterimage_Despawn:Clone()
                        end)
                        local ok2, tpthing = pcall(function()
                            return _ReplicatedStorage.Resources.VanishingKick.tpthing:Clone()
                        end)
                        if ok1 and afterimage then
                            afterimage.Parent = root
                            v901[1] = afterimage
                            for _, pe in pairs(afterimage:GetChildren()) do
                                if pe:IsA('ParticleEmitter') then
                                    pe.Enabled = true
                                    pe.Rate = 100
                                end
                            end
                        end
                        if ok2 and tpthing then
                            tpthing.Parent = root
                            v901[2] = tpthing
                            tpthing.Enabled = true
                            tpthing.Rate = 100
                        end
                        repeat
                            if v901[1] and v901[1].Parent then
                                v901[1].CFrame = root.CFrame
                            end
                            RunService.RenderStepped:Wait()
                        until not getgenv().desync or char:FindFirstChild('AbsoluteImmortal')
                        for _, v in pairs(v901) do
                            pcall(function() v:Destroy() end)
                        end
                    end
                end
            end)
            task.spawn(function()
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA('BasePart') and part ~= root and part.Transparency ~= 1
                       and not part.Name:lower():find('hitbox') then
                        task.spawn(function()
                            while task.wait() and (not lp.Character or lp.Character == char) do
                                if part and (_pU59.Invisibility or (getgenv().desync and not char:FindFirstChild('AbsoluteImmortal'))) then
                                    part.Transparency = 0.5
                                    repeat
                                        RunService.RenderStepped:Wait()
                                    until not _pU59.Invisibility
                                        and (not getgenv().desync or char:FindFirstChild('AbsoluteImmortal'))
                                        or (lp.Character and lp.Character ~= char)
                                    part.Transparency = 0
                                end
                            end
                        end)
                    end
                end
            end)
        end
        if lp.Character then task.spawn(_initDesyncEffects, lp.Character) end
        lp.CharacterAdded:Connect(function(char) task.spawn(_initDesyncEffects, char) end)
    end)
    BoxVisualsESP:AddToggle("ShowDeathCounter", {
        Text = "Show Death Counter",
        Default = false,
        Callback = function(val)
            deathCounterActive = val
            refreshDeathCounterUltHighlights()
            if val then
                for _, co in pairs(deathCounterConns) do pcall(co.Disconnect, co) end
                deathCounterConns = {}
                deathCounterHighlights = {}
                deathCounterDebounce = {}
                hookedChars = {}
                for _, p in pairs(Players:GetPlayers()) do
                    hookPlayerDC(p)
                end
                table.insert(deathCounterConns, Players.PlayerAdded:Connect(function(p)
                    if deathCounterActive then hookPlayerDC(p) end
                end))
                table.insert(deathCounterConns, Players.PlayerRemoving:Connect(function(p)
                    removeCounterHL(p)
                end))
            else
                for _, co in pairs(deathCounterConns) do pcall(co.Disconnect, co) end
                deathCounterConns = {}
                deathCounterHighlights = {}
                deathCounterDebounce = {}
                hookedChars = {}
            end
        end
    })
    BoxVisualsESP:AddToggle("MoveNotifications", {
        Text    = "Move Notifications",
        Default = false,
    })
    BoxVisualsESP:AddToggle("ExposeMoveInChat", {
        Text    = "Expose moves in chat",
        Default = false,
    })
    BoxVisualsESP:AddToggle("ExposeWhitelistedPlayers", {
        Text    = "Expose Whitelisted Players",
        Default = false,
    })
    BoxVisualsESP:AddDropdown("MoveNotificationMoves", {
        Values     = {
            "Death Counter",
            "Table Flip",
            "Serious Punch",
            "Omni-Directional Punch",
            "Death Blow",
            "Last Breath",
        },
        Default    = {},
        Multi      = true,
        Searchable = false,
        Text       = "Moves",
    })
end
_pU59 = {
    Flying                      = false,
    ['Touch Fling']          = false,
    ['Touch Fling Settings'] = Vector3.new(0, 0, 0),
    ['Trashcan Launch']         = false,
}
_pU525 = {
    Fly               = false,
    ['Lock-on']       = false,
    ['Touch Fling']= false,
}
do
    local InvisibilityActive  = false
    local invisBusy           = false
    local cachedAnimTrack     = nil
    local cachedAnimHumanoid  = nil
    local lastRealCFrame      = nil
    local _invisPartConns     = {}  -- GetPropertyChangedSignal connections for transparency lock
    -- Camera clone: keeps camera at real position while the real HRP is underground / desync'd
    local InvisibleModel    = Instance.new("Model", workspace)
    local InvisibleHumanoid = Instance.new("Humanoid", InvisibleModel)
    local InvisiblePart30   = Instance.new("Part", InvisibleModel)
    InvisiblePart30.Name         = "HumanoidRootPart"
    InvisiblePart30.CanCollide   = false
    InvisiblePart30.Transparency = 1
    InvisiblePart30.Anchored     = true
    InvisiblePart30.Size         = Vector3.new(2, 2, 1)
    getgenv().InvisHumanoid = InvisibleHumanoid
    getgenv().InvisPart30   = InvisiblePart30
    local _invisDesyncHeartbeatConn = RunService.Heartbeat:Connect(function()
        if Library.Unloaded then return end
        local hasFlingDesync = getgenv().flingDesync ~= nil
        local hasDesync      = getgenv().desync ~= nil
        if not InvisibilityActive and not hasFlingDesync and not hasDesync and not _pU59['Touch Fling'] and not _pU59['Trashcan Launch'] and not _pU59['Upside Down'] then return end
        if getgenv().TrashcanIsRunning then
            local c = lp.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if r then InvisiblePart30.CFrame = r.CFrame end
            return
        end
        if invisBusy then return end
        invisBusy = true
        local currentChar     = lp.Character
        local currentHumanoid = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
        local currentRoot     = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if not currentChar or not currentHumanoid or not currentRoot then invisBusy = false return end
        if currentHumanoid.Health <= 0 then
            if InvisibilityActive then
                task.spawn(softResetInvisibility)
            end
            invisBusy = false return
        end
        local realCFrame   = currentRoot.CFrame
        local realVelocity = currentRoot.Velocity
        lastRealCFrame     = realCFrame
        local currentCamera = workspace.CurrentCamera
        local spoofCFrame = nil
        if _pU59["Upside Down"] then
            -- upside-down still uses the flip
            spoofCFrame = realCFrame * CFrame.Angles(0, 0, math.rad(180))
        elseif InvisibilityActive then
            -- anim 71181015443030 @t=13.45 pushes model underground — HRP stays at real position
            spoofCFrame = realCFrame
        end
        if hasDesync and not lp.Character:FindFirstChild("AbsoluteImmortal") then
            spoofCFrame = getgenv().desync.CFrame or spoofCFrame
        end
        if hasFlingDesync then
            spoofCFrame = getgenv().flingDesync.CFrame or spoofCFrame
        end
        local didSetCamera = false
        if spoofCFrame then
            if currentCamera and not (InvisibilityActive and not hasDesync and not hasFlingDesync) then
                currentChar:SetAttribute("NoHeadLerp", true)
                currentCamera.CameraSubject = InvisibleHumanoid
                didSetCamera = true
            end
            InvisiblePart30.CFrame = realCFrame
            if not _pU59.Flying then
                currentRoot.CFrame = spoofCFrame
            end
        end
        local invisAnim = nil
        local mechAnimThisFrame = nil
        -- Humanoid invis pulse — always runs alongside the mech pulse when both are active.
        -- No MechInvisHandled guard here: both animators (humanoid + mech) fire the same frame intentionally.
        if InvisibilityActive and not (hasFlingDesync and getgenv().flingDesync.Velocity) then
            if cachedAnimHumanoid ~= currentHumanoid then
                if cachedAnimTrack then pcall(function() if cachedAnimTrack.IsPlaying then cachedAnimTrack:Stop() end end) cachedAnimTrack = nil end
                cachedAnimHumanoid = currentHumanoid
            end
            local animator = currentHumanoid:FindFirstChildOfClass("Animator")
            if animator then
                if not cachedAnimTrack or cachedAnimTrack.Parent == nil then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://71181015443030"
                    cachedAnimTrack  = animator:LoadAnimation(anim)
                    cachedAnimTrack.Priority = Enum.AnimationPriority.Action4
                end
                invisAnim = cachedAnimTrack
                invisAnim:Play()
                invisAnim.TimePosition = 13.45
                invisAnim:AdjustSpeed(0)
                invisAnim:AdjustWeight(2e9) -- replicates properly to server/others
            end
        end
        -- Mech pulse runs independently — both humanoid and mech anims fire the same frame
        if InvisibilityActive and getgenv().MechInvisHandled then
            local mt = getgenv()._mechInvisTrack
            if mt then
                pcall(function()
                    if not mt.IsPlaying then mt:Play() end
                    mt.TimePosition = 0.01
                    mt:AdjustSpeed(0)
                    mt:AdjustWeight(2e9)
                end)
                mechAnimThisFrame = mt
            end
        end
        if _pU59['Trashcan Launch'] and Toggles.TrashcanLaunch and Toggles.TrashcanLaunch.Value then
            currentRoot.AssemblyLinearVelocity = currentRoot.CFrame.LookVector * Options.Trashcan_LaunchPower.Value
        elseif getgenv().flingDesync and getgenv().flingDesync.Velocity then
            currentRoot.Velocity = Vector3.new(-2000000000000000, -2000000000000000, -2000000000000000)
        elseif _pU59['Touch Fling'] then
            if Options.TouchFlingMethod and Options.TouchFlingMethod.Value == 'Normal' then
                local _tfVel = _pU59['Touch Fling Settings']
                if _tfVel.Magnitude <= 2^30 then
                    pcall(function() currentRoot.Velocity    = _tfVel end)
                    pcall(function() currentRoot.RotVelocity = Vector3.zero end)
                else
                    currentRoot.AssemblyLinearVelocity  = _tfVel
                    currentRoot.AssemblyAngularVelocity = Vector3.zero
                end
            elseif Options.TouchFlingMethod and Options.TouchFlingMethod.Value == 'Death' then
                local _flingIsInsta = false
            end
        end
        RunService.RenderStepped:Wait()
        InvisibleHumanoid.CameraOffset = currentHumanoid.CameraOffset
        if currentCamera and currentCamera.CameraSubject == InvisibleHumanoid then
            currentChar:SetAttribute("NoHeadLerp", false)
            currentCamera.CameraSubject = currentHumanoid
        end
        if invisAnim and invisAnim.IsPlaying then pcall(function() invisAnim:Stop() end) end
        if mechAnimThisFrame and mechAnimThisFrame.IsPlaying then pcall(function() mechAnimThisFrame:Stop() end) end
        if spoofCFrame and not _pU59.Flying then
            if currentCamera and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
               and not hasDesync
               and not (InvisibilityActive and not hasDesync and not hasFlingDesync) then
                local lv = currentCamera.CFrame.LookVector
                local flatLv = Vector3.new(lv.X, 0, lv.Z)
                if flatLv.Magnitude > 0.001 then
                    currentRoot.CFrame = CFrame.new(realCFrame.Position, realCFrame.Position + flatLv)
                else
                    currentRoot.CFrame = realCFrame
                end
            else
                currentRoot.CFrame = realCFrame
            end
        end
        if not _pU59.Flying then
            currentRoot.Velocity = realVelocity
        end
        invisBusy = false
    end)
    local function stopInvisibility()
        if not InvisibilityActive then return end
        InvisibilityActive = false
        getgenv().InvisActive = false
        invisBusy = false
        if cachedAnimTrack then
            pcall(function() if cachedAnimTrack.IsPlaying then cachedAnimTrack:Stop() end end)
            cachedAnimTrack = nil
        end
        cachedAnimHumanoid = nil
        local char = lp.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and lastRealCFrame then pcall(function() root.CFrame = lastRealCFrame end) end
            lastRealCFrame = nil
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then pcall(function() workspace.CurrentCamera.CameraSubject = humanoid end) end
            pcall(function() char:SetAttribute("NoHeadLerp", false) end)
            for _, _ic in pairs(_invisPartConns) do pcall(function() _ic:Disconnect() end) end
            _invisPartConns = {}
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.LocalTransparencyModifier = 0
                end
            end
        end
        if not getgenv().TrashcanIsRunning then restartAllToggles(true) end
        if getgenv()._invisSavedTPose    then toggleTPose()    end
        getgenv()._invisSavedTPose    = nil
    end
    table.insert(CleanupTasks, function()
        stopInvisibility()
        pcall(function() Toggles.TogInvis:SetValue(false) end)
    end)
    getgenv().stopInvisibilityFn = stopInvisibility
    local function softResetInvisibility()
        if cachedAnimTrack then
            pcall(function() if cachedAnimTrack.IsPlaying then cachedAnimTrack:Stop() end end)
            cachedAnimTrack = nil
        end
        cachedAnimHumanoid = nil
        lastRealCFrame     = nil
        invisBusy          = false
    end
    -- hoisted so CharacterAdded can call it on respawn too
    local function _hookInvisPart(part)
        if not part:IsA("BasePart") then return end
        if part.Name == "HumanoidRootPart" then return end
        if part.Transparency == 1 then return end
        if part.Name:lower():find("hitbox") then return end
        -- LocalTransparencyModifier is purely client-side, never replicates to server or other players
        part.LocalTransparencyModifier = 0.5
        local conn = part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
            if not InvisibilityActive then return end
            if part.LocalTransparencyModifier ~= 0.5 then
                part.LocalTransparencyModifier = 0.5
            end
        end)
        table.insert(_invisPartConns, conn)
    end
    local function _hookInvisChar(c)
        for _, part in pairs(c:GetDescendants()) do
            _hookInvisPart(part)
        end
        local _descConn = c.DescendantAdded:Connect(function(desc)
            if InvisibilityActive then _hookInvisPart(desc) end
        end)
        table.insert(_invisPartConns, _descConn)
    end
    local function startInvisibility()
        if InvisibilityActive then stopInvisibility() return end
        local char     = lp.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root     = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then return end
        getgenv()._invisSavedTPose    = TPoseActive    or false
        InvisibilityActive = true
        getgenv().InvisActive = true
        invisBusy = false

        local c = lp.Character
        if c then _hookInvisChar(c) end
    end
    local TogInvis = BoxCharMods:AddToggle("TogInvis", {
        Text = "Invisibility", Default = false,
        Callback = function(val)
            if not val then
                if Options.KPInvis then Options.KPInvis.Toggled = false end
                if InvisibilityActive then stopInvisibility() end
            end
        end,
    })
    TogInvis:AddKeyPicker("KPInvis", {
        Default = "U", Text = "Invisibility", SyncToggleState = false, Mode = "Toggle",
        Callback = function()
            if _akbg.IV then return end
            if not Toggles.TogInvis.Value then
                Options.KPInvis.Toggled = false
                return
            end
            if isChatFocused() then return end
            startInvisibility()
        end,
    })
    TogInvis:OnChanged(function(val)
        if _guard.Invis then return end
        if isChatFocused() then _guard.Invis = true TogInvis:SetValue(not val) _guard.Invis = false return end
        if not val and InvisibilityActive then stopInvisibility() end
    end)
    task.defer(function()
        local kp = Options.KPInvis
        if kp then
            local origSetMode = kp.SetMode
            if type(origSetMode) == "function" then
                kp.SetMode = function(self, mode, ...)
                    if mode == "Always" then mode = "Toggle" end
                    return origSetMode(self, mode, ...)
                end
            end
            if kp.Mode == "Always" then
                pcall(function() kp:SetMode("Toggle") end)
            end
        end
    end)
    local _invisCharConn = lp.CharacterAdded:Connect(function(char)
        if InvisibilityActive then
            softResetInvisibility()
            -- clear dead part connections from old character
            for _, _ic in pairs(_invisPartConns) do pcall(function() _ic:Disconnect() end) end
            _invisPartConns = {}
            -- wait a frame for parts to exist, then re-apply transparency + hooks
            task.defer(function()
                if not InvisibilityActive then return end
                local c = lp.Character
                if c then _hookInvisChar(c) end
            end)
        end
        local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
        if hum then hum.Died:Connect(function()
            if InvisibilityActive then softResetInvisibility() end
        end) end
    end)
    if lp.Character then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Died:Connect(function()
            if InvisibilityActive then softResetInvisibility() end
        end) end
    end

end
local _instanceMetaOriginalIndex = typeof(getrawmetatable) == "function" and getrawmetatable(game) and getrawmetatable(game).__index or nil
do
    table.insert(CleanupTasks, function()
        pcall(function() Toggles.MoveNotifications:SetValue(false) end)
        pcall(function() Toggles.ExposeMoveInChat:SetValue(false) end)
        pcall(function() Toggles.ExposeWhitelistedPlayers:SetValue(false) end)
    end)
end
do
    function getChar(player)
        return player.Character
    end
    function getRoot(char)
        return char and char:FindFirstChild("HumanoidRootPart") or nil
    end
    function getHumanoid(char2)
        return char2 and char2:FindFirstChild("Humanoid") or nil
    end
    local cameraTypeConn = nil
    function patchCamera(newChild)
        if newChild:IsA("Camera") then
            if cameraTypeConn then
                cameraTypeConn:Disconnect()
                cameraTypeConn = nil
            end
            if newChild.CameraType ~= Enum.CameraType.Custom and Toggles.NoCameraAnimations.Value then
                task.spawn(fixCam)
            end
            cameraTypeConn = newChild:GetPropertyChangedSignal("CameraType"):Connect(function()
                if newChild.CameraType ~= Enum.CameraType.Custom and Toggles.NoCameraAnimations.Value
                    and not getgenv()._cpCamActive then
                    task.spawn(fixCam)
                end
            end)
        end
    end
    function fixCam()
        if not getChar(lp) then
            repeat
                task.wait()
            until getChar(lp)
        end
        local flyChar = getChar(lp)
        local flyHumanoid
        if flyChar then
            flyHumanoid = getHumanoid(flyChar)
        else
            flyHumanoid = flyChar
        end
        if flyChar and (flyHumanoid and workspace.CurrentCamera) then
            local _CFrame = workspace.CurrentCamera.CFrame
            workspace.CurrentCamera:Destroy()
            local _Camera = Instance.new("Camera", workspace)
            _Camera.CameraType = "Custom"
            _Camera.CameraSubject = flyHumanoid
            _Camera.CFrame = _CFrame
            lp.CameraMode = "Classic"
            flyChar:WaitForChild("Head", 1).Anchored = false
        end
    end
    BoxVisualsMain:AddToggle("NoCameraAnimations", {
        Text = "No Cutscenes",
        Default = false,
        Callback = function(noCamAnimVal)
            if noCamAnimVal then
                -- Disable Intro via servidor
                local _char = lp.Character
                if _char and _char:FindFirstChild("Communicate") then
                    pcall(function()
                        _char.Communicate:FireServer({ Goal = "Disable Intro" })
                    end)
                end
                local _CurrentCamera4 = workspace.CurrentCamera
                if _CurrentCamera4 and _CurrentCamera4.CameraType ~= Enum.CameraType.Custom then
                    task.spawn(fixCam)
                end
            end
        end,
    })
    do
        local _nifFXUiConn = nil
        local _NIF_KILL = { FXUi = true, ImpactFrames = true, Flash = true, Flexworks = true, Impact = true, Impact2 = true, Impact3 = true, BatImpact = true, GuiAnim = true }
        local _IMPACT_IDS = {
            [16043154171] = true,  -- ImpactFrame :: 1
            [16043156031] = true,  -- ImpactFrame :: 2
            [16043158393] = true,  -- ImpactFrame :: 3
            [105292724912360] = true,  -- Impact :: 1
            [103970496814859] = true,  -- Impact :: 2
            [93303659862392] = true,  -- Impact :: 3
            [94704269051379] = true,  -- Impact :: 4
            [130906905620601] = true,  -- Impact :: 5
            [109102382074339] = true,  -- Impact :: 6
            [126154177884499] = true,  -- Impact :: 7
            [120470487224640] = true,  -- Impact :: 8
            [94235068917138] = true,  -- Impact :: 9
            [114904469060907] = true,  -- Impact :: 10
            [96950156220147] = true,  -- Impact :: 11
            [77914202999518] = true,  -- Impact :: 12
            [89355993626809] = true,  -- Impact :: 13
            [115593152504814] = true,  -- Impact :: 14
            [115163935702377] = true,  -- Impact :: 15
            [108096961515162] = true,  -- Impact :: 16
            [102945330807458] = true,  -- Impact :: 17
            [115639466881686] = true,  -- Impact2 :: 1
            [106408645024146] = true,  -- Impact2 :: 2
            [103997621662882] = true,  -- Impact2 :: 3
            [98963378226348] = true,  -- Impact2 :: 4
            [138283827252840] = true,  -- Impact :: 1
            [73173862771821] = true,  -- Impact :: 2
            [117531049069077] = true,  -- Impact :: 3
            [121303853299291] = true,  -- Impact :: 4
            [74163589277108] = true,  -- Impact :: 5
            [137944251539418] = true,  -- Impact :: 6
            [95226061517603] = true,  -- Impact :: 7
            [72435938627045] = true,  -- Impact :: 8
            [119647743483603] = true,  -- Impact :: 9
            [102617503479857] = true,  -- Impact :: 10
            [110614492664851] = true,  -- Impact :: 11
            [81097880372288] = true,  -- Impact :: 12
            [87309776188141] = true,  -- Impact :: 13
            [105436748671671] = true,  -- Impact :: 14
            [134753950772177] = true,  -- Impact :: 15
            [86474305783911] = true,  -- Impact :: 16
            [97883435866681] = true,  -- Impact :: 17
            [76686961734515] = true,  -- Impact :: 18
            [106261393454295] = true,  -- Impact :: 19
            [81361300795575] = true,  -- Impact :: 20
            [113822570797393] = true,  -- Impact :: 21
            [93640005406026] = true,  -- Impact :: 22
            [74826122905979] = true,  -- Impact :: 23
            [80569592853717] = true,  -- Impact :: 24
            [130793433659495] = true,  -- Impact :: 25
            [102243745630290] = true,  -- Impact :: 26
            [109920530003012] = true,  -- Impact :: 27
            [107274089700796] = true,  -- Impact :: 28
            [110560007325867] = true,  -- Impact :: 29
            [91131196553271] = true,  -- Impact :: 30
            [82251506475110] = true,  -- Impact :: 31
            [113913037215750] = true,  -- Impact :: 32
            [86411735996581] = true,  -- Impact :: 33
            [130252920211103] = true,  -- Impact :: 34
            [129540317907477] = true,  -- Impact :: 35
            [94633349340540] = true,  -- Impact :: 36
            [105469428177188] = true,  -- Impact :: 37
            [125283792631442] = true,  -- Impact :: 38
            [102826955814599] = true,  -- Impact :: 39
            [100560142860033] = true,  -- Impact :: 40
            [72329473186813] = true,  -- Impact :: 41
            [94764943055014] = true,  -- Impact :: 42
            [109737467645438] = true,  -- Impact :: 43
            [94104018760133] = true,  -- Impact :: 44
            [135340999229786] = true,  -- Impact :: 45
            [116369193123612] = true,  -- Impact :: 46
            [138739736224559] = true,  -- Impact :: 47
            [107398892449054] = true,  -- Impact :: 48
            [115408320782661] = true,  -- Impact :: 49
            [88029783968112] = true,  -- Preload2 :: 80
            [114367728582047] = true,  -- Preload2 :: 79
            [71115028351211] = true,  -- Preload2 :: 78
            [128209762942507] = true,  -- Preload2 :: 77
            [135612265319562] = true,  -- Preload2 :: 76
            [136778760216909] = true,  -- Preload2 :: 75
            [127184491594129] = true,  -- Preload2 :: 74
            [81267088526737] = true,  -- Preload2 :: 73
            [107845455071459] = true,  -- Preload2 :: 72
            [132879914759638] = true,  -- Preload2 :: 71
            [116007646917770] = true,  -- Preload2 :: 70
            [86959970063821] = true,  -- Preload2 :: 69
            [140294545484487] = true,  -- Preload2 :: 68
            [98356396354229] = true,  -- Preload2 :: 67
            [73605700056697] = true,  -- Preload2 :: 66
            [122599341911025] = true,  -- Preload2 :: 65
            [117243238428924] = true,  -- Preload2 :: 64
            [95518008977547] = true,  -- Preload2 :: 63
            [138849208199971] = true,  -- Preload2 :: 62
            [73935048963355] = true,  -- Preload2 :: 61
            [103631148976788] = true,  -- Preload2 :: 60
            [86672899835729] = true,  -- Preload2 :: 59
            [101593549372972] = true,  -- Preload2 :: 58
            [101026638630620] = true,  -- Preload2 :: 57
            [135023497538345] = true,  -- Preload2 :: 56
            [116245317561450] = true,  -- Preload2 :: 55
            [104549023168408] = true,  -- Preload2 :: 54
            [124601842175416] = true,  -- Preload2 :: 53
            [95063533357827] = true,  -- Preload2 :: 52
            [115275513392510] = true,  -- Preload2 :: 51
            [118649894755242] = true,  -- Preload2 :: 50
            [74494101080766] = true,  -- Preload2 :: 49
            [99391352503459] = true,  -- Preload2 :: 48
            [130743174214274] = true,  -- Preload2 :: 47
            [124341087397944] = true,  -- Preload2 :: 46
            [116158995501139] = true,  -- Preload2 :: 45
            [119043669629506] = true,  -- Preload2 :: 44
            [85357434522503] = true,  -- Preload2 :: 43
            [134287593965913] = true,  -- Preload2 :: 42
            [80633305470043] = true,  -- Preload2 :: 41
            [104505399372264] = true,  -- Preload2 :: 40
            [140516601322189] = true,  -- Preload2 :: 39
            [83801301820362] = true,  -- Preload2 :: 38
            [118908722684741] = true,  -- Preload2 :: 37
            [77903660175367] = true,  -- Preload2 :: 36
            [95871279377800] = true,  -- Preload2 :: 35
            [137437339568498] = true,  -- Preload2 :: 34
            [83794856745215] = true,  -- Preload2 :: 33
            [90617277024495] = true,  -- Preload2 :: 32
            [97869669692406] = true,  -- Preload2 :: 31
            [125073842964769] = true,  -- Preload2 :: 30
            [77719436337178] = true,  -- Preload2 :: 29
            [135130254530476] = true,  -- Preload2 :: 28
            [133291137360011] = true,  -- Preload2 :: 27
            [122708430598665] = true,  -- Preload2 :: 26
            [92085106755517] = true,  -- Preload2 :: 25
            [110920005677301] = true,  -- Preload2 :: 24
            [116868353430885] = true,  -- Preload2 :: 23
            [93902988976044] = true,  -- Preload2 :: 22
            [85497761633086] = true,  -- Preload2 :: 21
            [124968255343643] = true,  -- Preload2 :: 20
            [139004446602247] = true,  -- Preload2 :: 19
            [100970557557125] = true,  -- Preload2 :: 18
            [126073612267687] = true,  -- Preload2 :: 17
            [105256600563418] = true,  -- Preload2 :: 16
            [92414014150729] = true,  -- Preload2 :: 15
            [137904293073306] = true,  -- Preload2 :: 14
            [80229944863595] = true,  -- Preload2 :: 13
            [98656433665318] = true,  -- Preload2 :: 11
            [126147592945920] = true,  -- Preload2 :: 10
            [92853523793264] = true,  -- Preload2 :: 9
            [139448484005733] = true,  -- Preload2 :: 8
            [73023260163943] = true,  -- Preload2 :: 7
            [133837327195020] = true,  -- Preload2 :: 6
            [91024067363257] = true,  -- Preload2 :: 5
            [136578840916634] = true,  -- Preload2 :: 4
            [127183812524721] = true,  -- Preload2 :: 3
            [99261029156994] = true,  -- Preload2 :: 2
            [134013965686190] = true,  -- Preload2 :: 1
            [72744714087575] = true,  -- Preload2 :: 12
            [4764912960] = true,  -- VignetteUI :: R
            [4764912210] = true,  -- VignetteUI :: L
            [14930748961] = true,  -- BatImpact :: 1
            [14931855855] = true,  -- BatImpact :: 3
            [14931341259] = true,  -- BatImpact :: 2
            [106792203557879] = true,  -- Impact :: 2
            [88213374101309] = true,  -- Impact :: 3
            [102124585705250] = true,  -- Impact :: 4
            [122881398740986] = true,  -- Impact :: 5
            [131733671726440] = true,  -- Impact :: 6
            [86305665311392] = true,  -- Impact :: 7
            [105281946376502] = true,  -- Impact :: 8
            [104125620628837] = true,  -- Impact :: 9
            [98336902467504] = true,  -- Impact :: 10
            [113687582207053] = true,  -- Impact :: 1
            [127033860942588] = true,  -- ImpactBefore :: 1
            [99751918094340] = true,  -- ImpactBefore :: 2
            [135799583139820] = true,  -- ImpactBefore :: 3
            [129595931954395] = true,  -- ImpactBefore :: 4
            [126609776608260] = true,  -- ImpactBefore :: 5
            [116853770948076] = true,  -- ImpactBefore :: 6
            [109066697041039] = true,  -- ImpactBefore :: 7
            [16042830962] = true,  -- ImpactFrame :: 1
            [16042830626] = true,  -- ImpactFrame :: 10
            [16042833831] = true,  -- ImpactFrame :: 11
            [16042834411] = true,  -- ImpactFrame :: 12
            [16042831168] = true,  -- ImpactFrame :: 2
            [16042831574] = true,  -- ImpactFrame :: 3
            [16042831829] = true,  -- ImpactFrame :: 4
            [16042832058] = true,  -- ImpactFrame :: 5
            [16042832395] = true,  -- ImpactFrame :: 6
            [16042832710] = true,  -- ImpactFrame :: 7
            [16042833093] = true,  -- ImpactFrame :: 8
            [16042833348] = true,  -- ImpactFrame :: 9
            [16055042320] = true,  -- ImpactFrame :: 1
            [16055045366] = true,  -- ImpactFrame :: 2
            [16055051443] = true,  -- ImpactFrame :: 3
            [16056702722] = true,  -- ImpactFrame2 :: 1
            [16056781361] = true,  -- ImpactFrame2 :: 2
            [17276089013] = true,  -- ImpactFrame :: 2
            [17276089280] = true,  -- ImpactFrame :: 3
            [17276088758] = true,  -- ImpactFrame :: 4
            [18461885601] = true,  -- FXUi :: FiveSeasons
            [17356805968] = true,  -- FXUi :: FiveSeasonsDots
            [17347809692] = true,  -- FXUi :: Punches
            [14846394635] = true,  -- FXUi :: White
            [17346970224] = true,  -- FXUi :: 1
            [17347684206] = true,  -- FXUi :: 2
            [17347686924] = true,  -- FXUi :: 3
            [17347690212] = true,  -- FXUi :: 4
            [17347685782] = true,  -- FXUi :: 5
            [17347708539] = true,  -- FXUi :: 6
            [17347708315] = true,  -- FXUi :: 7
            [17347707975] = true,  -- FXUi :: 8
            [17347707700] = true,  -- FXUi :: 9
            [17347707474] = true,  -- FXUi :: 10
            [17347707209] = true,  -- FXUi :: 11
            [17347707014] = true,  -- FXUi :: 12
            [17347706806] = true,  -- FXUi :: 13
            [17347706466] = true,  -- FXUi :: 14
            [17347706137] = true,  -- FXUi :: 15
            [17347705829] = true,  -- FXUi :: 16
            [17347705579] = true,  -- FXUi :: 17
            [17347705251] = true,  -- FXUi :: 18
            [17347704883] = true,  -- FXUi :: 19
            [17347704516] = true,  -- FXUi :: 20
            [17347704069] = true,  -- FXUi :: 21
            [17347703745] = true,  -- FXUi :: 22
            [17347703368] = true,  -- FXUi :: 23
            [17347703007] = true,  -- FXUi :: 24
            [17347702728] = true,  -- FXUi :: 25
            [17347702433] = true,  -- FXUi :: 26
            [17347702120] = true,  -- FXUi :: 27
            [17347701445] = true,  -- FXUi :: 28
            [17347701136] = true,  -- FXUi :: 29
            [17347700792] = true,  -- FXUi :: 30
            [17347700354] = true,  -- FXUi :: 31
            [17347700035] = true,  -- FXUi :: 32
            [17347699788] = true,  -- FXUi :: 33
            [17347699461] = true,  -- FXUi :: 34
            [17347699145] = true,  -- FXUi :: 35
            [17347698620] = true,  -- FXUi :: 36
            [17347698120] = true,  -- FXUi :: 37
            [17347697854] = true,  -- FXUi :: 38
            [17347697646] = true,  -- FXUi :: 39
            [17094610660] = true,  -- ImpactFrames :: Frame1
            [17094608312] = true,  -- ImpactFrames :: Frame7
            [17094608875] = true,  -- ImpactFrames :: Frame6
            [17094609366] = true,  -- ImpactFrames :: Frame5
            [17094609732] = true,  -- ImpactFrames :: Frame4
            [17094610225] = true,  -- ImpactFrames :: Frame3
            [17094610356] = true,  -- ImpactFrames :: Frame2
            [17094608019] = true,  -- ImpactFrames :: Frame8
            [18472609888] = true,  -- ImpactFrames :: 10
            [18472608830] = true,  -- ImpactFrames :: 11
            [18472608233] = true,  -- ImpactFrames :: 12
            [18472607714] = true,  -- ImpactFrames :: 13
            [18472607302] = true,  -- ImpactFrames :: 14
            [18472606925] = true,  -- ImpactFrames :: 15
            [18472606450] = true,  -- ImpactFrames :: 16
            [18472605849] = true,  -- ImpactFrames :: 17
            [18472605337] = true,  -- ImpactFrames :: 18
            [18472604803] = true,  -- ImpactFrames :: 19
            [18472613393] = true,  -- ImpactFrames :: 2
            [18472604377] = true,  -- ImpactFrames :: 20
            [18472603887] = true,  -- ImpactFrames :: 21
            [18472603444] = true,  -- ImpactFrames :: 22
            [18472602928] = true,  -- ImpactFrames :: 23
            [18472657080] = true,  -- ImpactFrames :: 24
            [18472602029] = true,  -- ImpactFrames :: 25
            [18472612972] = true,  -- ImpactFrames :: 3
            [18472612563] = true,  -- ImpactFrames :: 4
            [18472612143] = true,  -- ImpactFrames :: 5
            [18472611655] = true,  -- ImpactFrames :: 6
            [18472611130] = true,  -- ImpactFrames :: 7
            [18472610685] = true,  -- ImpactFrames :: 8
            [18472610370] = true,  -- ImpactFrames :: 9
            [18472613799] = true,  -- ImpactFrames :: 1
            [5168609593] = true,  -- ImpactFrames :: Frame
            [17464258529] = true,  -- ImpactFrames :: Vignette
            [18468265266] = true,  -- ImpactFrames :: Flexworks
            [18442187192] = true,  -- ImpactFrames :: Black
            [16968231260] = true,  -- Flash :: EyeFlash
            [132041598730582] = true,  -- Impact :: 2
            [88479946788220] = true,  -- Impact :: 1
            [99809310543950] = true,  -- Impact :: 1
            [121778149812033] = true,  -- Impact :: 10
            [133363172644321] = true,  -- Impact :: 100
            [120338738082550] = true,  -- Impact :: 101
            [73239621587797] = true,  -- Impact :: 102
            [122997268822491] = true,  -- Impact :: 103
            [134088653296612] = true,  -- Impact :: 104
            [104520572712911] = true,  -- Impact :: 105
            [132348477091663] = true,  -- Impact :: 106
            [117164402500989] = true,  -- Impact :: 107
            [119627926834607] = true,  -- Impact :: 108
            [80378599710093] = true,  -- Impact :: 109
            [138545858093468] = true,  -- Impact :: 11
            [78543193976484] = true,  -- Impact :: 110
            [84560812248785] = true,  -- Impact :: 111
            [121109264264863] = true,  -- Impact :: 112
            [127430563589722] = true,  -- Impact :: 113
            [135607453825698] = true,  -- Impact :: 114
            [77283137532868] = true,  -- Impact :: 115
            [90068457495667] = true,  -- Impact :: 116
            [125494010846103] = true,  -- Impact :: 117
            [133765555984165] = true,  -- Impact :: 118
            [95529898334632] = true,  -- Impact :: 119
            [99382634403006] = true,  -- Impact :: 12
            [86783510064589] = true,  -- Impact :: 120
            [86589420084208] = true,  -- Impact :: 121
            [102765565924889] = true,  -- Impact :: 122
            [133579806979721] = true,  -- Impact :: 123
            [99026842284463] = true,  -- Impact :: 124
            [109773957226586] = true,  -- Impact :: 125
            [135417353480586] = true,  -- Impact :: 126
            [125438339733688] = true,  -- Impact :: 127
            [134484976572653] = true,  -- Impact :: 128
            [120269887359321] = true,  -- Impact :: 129
            [121791689764143] = true,  -- Impact :: 13
            [82413189377307] = true,  -- Impact :: 130
            [84181957910464] = true,  -- Impact :: 14
            [82103960027260] = true,  -- Impact :: 15
            [87434268159000] = true,  -- Impact :: 16
            [90355655362328] = true,  -- Impact :: 17
            [102329983006446] = true,  -- Impact :: 18
            [103592476315193] = true,  -- Impact :: 19
            [120144629577072] = true,  -- Impact :: 2
            [84020834687601] = true,  -- Impact :: 20
            [79569619227538] = true,  -- Impact :: 21
            [99769219359297] = true,  -- Impact :: 22
            [118562056393454] = true,  -- Impact :: 23
            [123698367768788] = true,  -- Impact :: 24
            [122260680207209] = true,  -- Impact :: 25
            [108092224708647] = true,  -- Impact :: 26
            [138737996778070] = true,  -- Impact :: 27
            [79618064434477] = true,  -- Impact :: 28
            [92162040943589] = true,  -- Impact :: 29
            [131358112091157] = true,  -- Impact :: 3
            [117133124803747] = true,  -- Impact :: 30
            [105166894691027] = true,  -- Impact :: 31
            [114763311945259] = true,  -- Impact :: 32
            [137877653690370] = true,  -- Impact :: 33
            [81148045980280] = true,  -- Impact :: 34
            [95537646334614] = true,  -- Impact :: 35
            [140307685716031] = true,  -- Impact :: 36
            [139612166122421] = true,  -- Impact :: 37
            [122960294098710] = true,  -- Impact :: 38
            [85705688233470] = true,  -- Impact :: 39
            [124846100379271] = true,  -- Impact :: 4
            [90773034117257] = true,  -- Impact :: 40
            [88926980126853] = true,  -- Impact :: 41
            [126037773456240] = true,  -- Impact :: 42
            [74054939469235] = true,  -- Impact :: 43
            [99872418846237] = true,  -- Impact :: 44
            [108666948377765] = true,  -- Impact :: 45
            [108562093406025] = true,  -- Impact :: 46
            [73411006266154] = true,  -- Impact :: 47
            [95454091192549] = true,  -- Impact :: 48
            [112577812418885] = true,  -- Impact :: 49
            [98247621769748] = true,  -- Impact :: 5
            [99195327091888] = true,  -- Impact :: 50
            [119177471584977] = true,  -- Impact :: 51
            [96163997293092] = true,  -- Impact :: 52
            [74471432017749] = true,  -- Impact :: 53
            [87963130327219] = true,  -- Impact :: 54
            [111862099964874] = true,  -- Impact :: 55
            [106884223072637] = true,  -- Impact :: 56
            [82712022239311] = true,  -- Impact :: 57
            [112443092662473] = true,  -- Impact :: 58
            [86163373171837] = true,  -- Impact :: 59
            [132210685679703] = true,  -- Impact :: 6
            [105553413176895] = true,  -- Impact :: 60
            [120176289041563] = true,  -- Impact :: 61
            [118350440814972] = true,  -- Impact :: 62
            [96021292552142] = true,  -- Impact :: 63
            [119748818399549] = true,  -- Impact :: 64
            [95929885432431] = true,  -- Impact :: 65
            [110980919036136] = true,  -- Impact :: 66
            [83507945313310] = true,  -- Impact :: 67
            [89008537924871] = true,  -- Impact :: 68
            [127585685908588] = true,  -- Impact :: 69
            [130081881963891] = true,  -- Impact :: 7
            [76165947467682] = true,  -- Impact :: 70
            [74723144618437] = true,  -- Impact :: 71
            [99614027682043] = true,  -- Impact :: 72
            [72929416497118] = true,  -- Impact :: 73
            [116770235129877] = true,  -- Impact :: 74
            [79421618365844] = true,  -- Impact :: 75
            [93127508794485] = true,  -- Impact :: 76
            [93092528930633] = true,  -- Impact :: 77
            [95944691581999] = true,  -- Impact :: 78
            [126599399224485] = true,  -- Impact :: 79
            [121687513796271] = true,  -- Impact :: 8
            [102713710348080] = true,  -- Impact :: 80
            [74932476578150] = true,  -- Impact :: 81
            [135928273981948] = true,  -- Impact :: 82
            [107035267505065] = true,  -- Impact :: 83
            [113433986305565] = true,  -- Impact :: 84
            [123787348317011] = true,  -- Impact :: 85
            [129879611538538] = true,  -- Impact :: 86
            [140172296067727] = true,  -- Impact :: 87
            [103768468709610] = true,  -- Impact :: 88
            [113522621441604] = true,  -- Impact :: 89
            [113400167565890] = true,  -- Impact :: 9
            [81772444840888] = true,  -- Impact :: 90
            [91147562276326] = true,  -- Impact :: 91
            [136150680711101] = true,  -- Impact :: 92
            [126140547898474] = true,  -- Impact :: 93
            [74680283194704] = true,  -- Impact :: 94
            [130646438465243] = true,  -- Impact :: 95
            [134001682674459] = true,  -- Impact :: 96
            [103996610390710] = true,  -- Impact :: 97
            [100763701075399] = true,  -- Impact :: 98
            [81493987832464] = true,  -- Impact :: 99
            [10924531832] = true,  -- MeshEmitterVignette :: Vignette
            [16516658091] = true,  -- OmniImpact :: 1
            [16516718975] = true,  -- OmniImpact :: 2
            [16516663035] = true,  -- OmniImpact :: 3
            [16516666774] = true,  -- OmniImpact :: 4
            [16516670462] = true,  -- OmniImpact :: 5
        }
        local _nifDescConn = nil

        local function _killElem(elem)
            local id = tonumber((elem.Image or ""):match("%d+"))
            if id and _IMPACT_IDS[id] then
                pcall(function() elem.ImageTransparency = 1 end)
                pcall(function() elem.BackgroundTransparency = 1 end)
            end
        end

        local function _nifKillSg(sg)
            -- whole-gui name kill
            if _NIF_KILL[sg.Name] then
                sg.Enabled = false
                return
            end
        end

        BoxVisualsMain:AddToggle("NoImpactFrames", {
            Text    = "No Impact Frames",
            Default = false,
        }):OnChanged(function()
            local pGui = lp:FindFirstChild("PlayerGui")
            if Toggles.NoImpactFrames.Value then
                -- MobileJunk — disable once
                local mj = pGui and pGui:FindFirstChild("MobileJunk")
                if mj then mj.Enabled = false end
                if pGui then
                    -- name-kill existing ScreenGuis
                    for _, sg in ipairs(pGui:GetChildren()) do
                        if sg:IsA("ScreenGui") then pcall(_nifKillSg, sg) end
                    end
                    -- watch new ScreenGuis (name kill)
                    _nifFXUiConn = pGui.ChildAdded:Connect(function(child)
                        if not child:IsA("ScreenGui") then return end
                        if _NIF_KILL[child.Name] then child.Enabled = false end
                    end)
                    -- watch every new descendant across ALL guis — kill by image ID
                    _nifDescConn = pGui.DescendantAdded:Connect(function(elem)
                        if not (elem:IsA("ImageLabel") or elem:IsA("ImageButton")) then return end
                        pcall(_killElem, elem)
                    end)
                end
            else
                if _nifFXUiConn  then _nifFXUiConn:Disconnect()  _nifFXUiConn  = nil end
                if _nifDescConn  then _nifDescConn:Disconnect()   _nifDescConn  = nil end
                -- restore name-killed guis
                local mj = pGui and pGui:FindFirstChild("MobileJunk")
                if mj then mj.Enabled = true end
                if pGui then
                    for name in pairs(_NIF_KILL) do
                        local g = pGui:FindFirstChild(name)
                        if g then g.Enabled = true end
                    end
                end
            end
        end)
        table.insert(CleanupTasks, function()
            if _nifFXUiConn then _nifFXUiConn:Disconnect() _nifFXUiConn = nil end
            if _nifDescConn then _nifDescConn:Disconnect() _nifDescConn = nil end
            pcall(function() Toggles.NoImpactFrames:SetValue(false) end)
        end)
    end
    -- Helper: tenta esconder/mostrar o slider pelo frame interno da lib
    BoxVisualsMain:AddToggle("AlwaysCanChat", {
        Text    = "Always Can Chat",
        Default = false,
    })
    do
        local _sg2 = game:GetService("StarterGui")
        _sg2.CoreGuiChangedSignal:Connect(function(param, enabled)
            if enabled then return end
            if not Toggles.AlwaysCanChat.Value then return end
            if param == Enum.CoreGuiType.Chat or param == Enum.CoreGuiType.All then
                RunService.RenderStepped:Wait()
                _sg2:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
            end
        end)
    end
    BoxVisualsMain:AddDivider()
    BoxVisualsMain:AddToggle("Visualizer", {
        Text    = "Desync Visualizer",
        Default = false,
    })
    BoxVisualsMain:AddToggle("AlwaysVisualize", {
        Text    = "Always Enabled",
        Default = false,
    })
    task.spawn(function()
        if workspace.CurrentCamera then
            patchCamera(workspace.CurrentCamera)
        end
        workspace.ChildAdded:Connect(function(child) task.defer(patchCamera, child) end)
    end)
    table.insert(CleanupTasks, function()
        if cameraTypeConn then cameraTypeConn:Disconnect() cameraTypeConn = nil end
        if _fovRenderConn then _fovRenderConn:Disconnect() _fovRenderConn = nil end
        pcall(function() Toggles.NoCameraAnimations:SetValue(false) end)
        pcall(function() Toggles.FOVEnabled:SetValue(false) end)
        pcall(function() Toggles.Visualizer:SetValue(false) end)
        pcall(function() Toggles.AlwaysVisualize:SetValue(false) end)
    end)
do
    RevenantWhitelist = RevenantWhitelist or {}
end
end
do
    local FLY_IDS = {
        Forward = "17124063826",
        Back    = "17124067635",
        Left    = "17124105294",
        Right   = "17124112547",
        Idle    = "17124061663",
    }
    local FLY_FADE      = 0.1
    local _flyAnimTracks = {}
    local function _flyAnimUnload()
        for _, t in pairs(_flyAnimTracks) do
            pcall(function() if t.IsPlaying then t:Stop(0) end end)
            pcall(function() t:Destroy() end)
        end
        _flyAnimTracks = {}
    end
    local function _flyAnimSetActive(names)
        for name, track in pairs(_flyAnimTracks) do
            local shouldPlay = false
            for _, n in ipairs(names) do if n == name then shouldPlay = true break end end
            if shouldPlay then
                if not track.IsPlaying then pcall(function() track:Play(FLY_FADE) end) end
            else
                if track.IsPlaying then pcall(function() track:Stop(FLY_FADE) end) end
            end
        end
    end
    BoxCFrameSpeed:AddToggle("SpeedHackEnabled", {
        Text    = "CFrame Speed",
        Default = false,
    })
    BoxCFrameSpeed:AddSlider("SpeedHack", {
        Text     = "Speed",
        Default  = 1,
        Min      = 1,
        Max      = 25000,
        Rounding = 1,
        Compact  = true,
    })
    BoxCFrameSpeed:AddDropdown("SpeedHackMethod", {
        Text    = "Method",
        Values  = { "CFrame", "Velocity" },
        Default = 1,
        Multi   = false,
    })
    BoxCFrameSpeed:AddToggle("UpsideDown", {
        Text    = "Upside Down",
        Default = false,
        Callback = function(val)
            _pU59["Upside Down"] = val
        end,
    })
    task.spawn(function()
        while RunService.PreSimulation:Wait() do
            local _method = Options.SpeedHackMethod.Value
            local char    = lp.Character
            local root    = char and char:FindFirstChild("HumanoidRootPart")
            local hum     = char and char:FindFirstChildOfClass("Humanoid")
            if char and root and hum and Toggles.SpeedHackEnabled.Value and not _pU59.Flying then
                if _method == "CFrame" then
                    root.CFrame = root.CFrame + hum.MoveDirection * (Options.SpeedHack.Value / 10000)
                elseif _method == "Velocity" and hum.MoveDirection ~= Vector3.new() then
                    repeat
                        local v = hum.MoveDirection.Unit * (Options.SpeedHack.Value / 100)
                        root.Velocity = Vector3.new(v.X, root.Velocity.Y, v.Z)
                        RunService.PreSimulation:Wait()
                    until hum.MoveDirection == Vector3.new() or Options.SpeedHackMethod.Value ~= _method
                    root.Velocity = Vector3.new()
                end
            end
        end
    end)
    table.insert(CleanupTasks, function()
        pcall(function() Toggles.UpsideDown:SetValue(false) end)
        pcall(function() Toggles.SpeedHackEnabled:SetValue(false) end)
    end)
    BoxKeybindsLP:AddToggle("RevenantFly", {
        Text    = "Fly",
        Default = false,
        Callback = function(flyToggleVal)
            if not flyToggleVal then
                if Options.RevenantFlyBind then Options.RevenantFlyBind.Toggled = false end
                _pU59.Flying = false
            end
        end,
    }):AddKeyPicker("RevenantFlyBind", {
        SyncToggleState = false,
        Mode    = "Toggle",
        Default = "Y",
        Text    = "Fly",
        Callback = function(flySpeedVal)
            if _pU525.Fly then return end
            if flySpeedVal and not Toggles.RevenantFly.Value then
                RunService.RenderStepped:Wait()
                _pU525.Fly = true
                Options.RevenantFlyBind.Toggled = false
                Options.RevenantFlyBind:DoClick()
                _pU525.Fly = false
                return
            end
            if not Toggles.RevenantFly.Value then return end
            _pU59.Flying = not _pU59.Flying
            Library:Notify({ Title = bypassText("Fly"), Content = _pU59.Flying and "Toggled on ✅" or "Toggled off ❌", Time = 2 })
            if not _pU59.Flying then
            end
                local flyConn = nil
                local flyChar2 = getChar(lp)
                local flyHumanoid2
                if flyChar2 then
                    flyHumanoid2 = getHumanoid(flyChar2)
                else
                    flyHumanoid2 = flyChar2
                end
                local flyRoot
                if flyChar2 then
                    flyRoot = getRoot(flyChar2)
                else
                    flyRoot = flyChar2
                end
                if flyChar2 and (flyRoot and flyHumanoid2) then
                    flyConn = flyRoot.CFrame
                end
                if flyHumanoid2 then
                    for _, t in pairs(flyHumanoid2:GetPlayingAnimationTracks()) do
                        local tid = t.Animation and t.Animation.AnimationId:match('%d+') or ''
                        if tid == '7815618175' or tid == '507777826' or tid == '507776043' or tid == '616163682' then
                            pcall(function() t:Stop(0) end)
                        end
                    end
                end
                if trashcanGameIds[currentPlaceId] then
                    local c = flyChar2
                    local h = c and c:FindFirstChildOfClass("Humanoid")
                    local a = h and h:FindFirstChildOfClass("Animator")
                    if c and a then
                        _flyAnimUnload()
                        for name, id in pairs(FLY_IDS) do
                            local anim = Instance.new("Animation")
                            anim.AnimationId = "rbxassetid://" .. id
                            local t = a:LoadAnimation(anim)
                            t.Priority = Enum.AnimationPriority.Action
                            t.Looped   = true
                            _flyAnimTracks[name] = t
                        end
                    end
                end
                local flyHeartbeat = RunService.Heartbeat:Connect(function(flyDelta)
                    local flyCharLoop = getChar(lp)
                    local flyRootLoop
                    if flyCharLoop then
                        flyRootLoop = getHumanoid(flyCharLoop)
                    else
                        flyRootLoop = flyCharLoop
                    end
                    local flyCamCF
                    if flyCharLoop then
                        flyCamCF = getRoot(flyCharLoop)
                    else
                        flyCamCF = flyCharLoop
                    end
                    local _CurrentCamera = workspace.CurrentCamera
                    if flyCharLoop and (flyCamCF and (flyRootLoop and _CurrentCamera)) then
                        local flySpeed = Options.RevenantFlySpeed.Value / 100
                        local flyVelocity = Vector3.new(0, 0, 0)
                        CFrame.new(0, 0, 0)
                        local _CFrame2 = _CurrentCamera.CFrame
                        local _LookVector = _CFrame2.LookVector
                        local _RightVector = _CFrame2.RightVector
                        local flyLookCF = CFrame.new(flyCamCF.Position, flyCamCF.Position + Vector3.new(_LookVector.X, 0, _LookVector.Z))
                        local flyForward = math.round((flyRootLoop.MoveDirection:Dot(flyLookCF.LookVector)))
                        local flyRight = math.round((flyRootLoop.MoveDirection:Dot(flyLookCF.RightVector)))
                        if flyForward == 1 then
                            flyVelocity = flyVelocity + _LookVector * flySpeed
                            local _ = flyCamCF.CFrame + _LookVector * (flyDelta * flySpeed)
                        end
                        if flyForward == -1 then
                            flyVelocity = flyVelocity + _LookVector * -flySpeed
                            local _ = flyCamCF.CFrame + -_LookVector * (flyDelta * flySpeed)
                        end
                        if flyRight == -1 then
                            flyVelocity = flyVelocity + _RightVector * -flySpeed
                            local _ = flyCamCF.CFrame + -_RightVector * (flyDelta * flySpeed)
                        end
                        if flyRight == 1 then
                            flyVelocity = flyVelocity + _RightVector * flySpeed
                            local _ = flyCamCF.CFrame + _RightVector * (flyDelta * flySpeed)
                        end
                        if flyForward == 0 and flyRight == 0 then
                            flyCamCF.Velocity = Vector3.new()
                            flyCamCF.CFrame = flyConn or flyCamCF.CFrame
                        else
                            flyCamCF.Velocity = flyVelocity
                            flyConn = flyCamCF.CFrame
                        end
                        flyCamCF.RotVelocity = Vector3.new()
                        flyCamCF.CFrame = CFrame.new(flyCamCF.CFrame.Position, flyCamCF.CFrame.Position + _CFrame2.LookVector)
                        if trashcanGameIds[currentPlaceId] then
                            local activeAnims = {}
                            if flyForward ==  1 then table.insert(activeAnims, "Forward")
                            elseif flyForward == -1 then table.insert(activeAnims, "Back") end
                            if flyRight ==  1 then table.insert(activeAnims, "Right")
                            elseif flyRight == -1 then table.insert(activeAnims, "Left") end
                            if #activeAnims == 0 then activeAnims = { "Idle" } end
                            _flyAnimSetActive(activeAnims)
                        end
                    end
                end)
                repeat
                    task.wait()
                until not _pU59.Flying
                _pU59.Flying = false
                flyHeartbeat:Disconnect()
                _flyAnimUnload()
                local cframeChar = getChar(lp)
                local cframeRoot
                if cframeChar then
                    cframeRoot = getRoot(cframeChar)
                else
                    cframeRoot = cframeChar
                end
                local cframeHum
                if cframeChar then
                    cframeHum = getHumanoid(cframeChar)
                else
                    cframeHum = cframeChar
                end
                if cframeHum then cframeHum.AutoRotate = true end
                if cframeChar and (cframeRoot and (cframeHum and not cframeHum.SeatPart)) then
                    local cframeStartTick = tick()
                    cframeRoot.Velocity = Vector3.new()
                    if cframeRoot.Velocity.Magnitude <= 5 or tick() >= cframeStartTick + 1 then
                    end
                end
                if not (cframeHum and cframeHum.SeatPart) then
                end
                local cframeEndTick = tick()
                while true do
                    if cframeHum and cframeHum.SeatPart then
                        cframeHum.SeatPart.Velocity = Vector3.new()
                    end
                    if (cframeHum and cframeHum.SeatPart and cframeHum.SeatPart.Velocity.Magnitude <= 5) or (not (cframeHum and cframeHum.SeatPart) or tick() >= cframeEndTick + 1) then
                        break
                    end
                end
        end,
    })
    BoxKeybindsLP:AddSlider("RevenantFlySpeed", {
        Text = "Fly Speed", Default = 10000, Min = 1, Max = 50000, Rounding = 1,
    })
    BoxKeybindsLP:AddDivider()
    table.insert(CleanupTasks, function()
        _pU59.Flying = false
        _flyAnimUnload()
        pcall(function() Toggles.RevenantFly:SetValue(false) end)
    end)
end

if trashcanGameIds[currentPlaceId] then
    local M1RESET_ANIM_IDS = {
        ["rbxassetid://10480796021"] = true,
        ["rbxassetid://10480793962"] = true,
    }
    local m1ResetLoop       = nil
    local m1ActiveTracks    = {}
    BoxCharMods:AddToggle("M1Reset", {
        Text    = "M1 Reset / No Dash Debounce",
        Default = false,
    })
    m1ResetLoop = RunService.Heartbeat:Connect(function()
        if not Toggles.M1Reset or not Toggles.M1Reset.Value then return end
        local char     = lp.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            local animId = track.Animation and track.Animation.AnimationId or ""
            if M1RESET_ANIM_IDS[animId] and not m1ActiveTracks[track] then
                m1ActiveTracks[track] = true
                task.spawn(function()
                    local m1ResetInputConn = UIS.InputBegan:Once(function()
                        while true do
                            if UIS:IsKeyDown(Enum.KeyCode.Q) and not char:FindFirstChild("RagdollCancel") then
                                if UIS:IsKeyDown(Enum.KeyCode.A) or (UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.S)) then
                                    if workspace:GetAttribute("NoDashCooldown") then
                                        track:Stop()
                                        local m1Char = char
                                        local m1Iter, m1State, m1Index = pairs(m1Char:GetChildren())
                                        while true do
                                            local m1Child
                                            m1Index, m1Child = m1Iter(m1State, m1Index)
                                            if m1Index == nil then
                                                break
                                            end
                                            if m1Child.Name == "UsedDash" or m1Child.Name == "Freeze" then
                                                m1Child:Destroy()
                                            end
                                        end
                                    end
                                else
                                    char.Communicate:FireServer({
                                        Dash = Enum.KeyCode.W,
                                        Key  = Enum.KeyCode.Q,
                                        Goal = "KeyPress",
                                    })
                                end
                                break
                            end
                            RunService.RenderStepped:Wait()
                            if not track.IsPlaying then
                                break
                            end
                        end
                    end)
                    task.delay(1, function()
                        m1ResetInputConn:Disconnect()
                        m1ActiveTracks[track] = nil
                    end)
                end)
            end
        end
        for track, _ in pairs(m1ActiveTracks) do
            if not track.IsPlaying then
                m1ActiveTracks[track] = nil
            end
        end
    end)
    table.insert(CleanupTasks, function()
        if m1ResetLoop then m1ResetLoop:Disconnect() m1ResetLoop = nil end
        m1ActiveTracks = {}
        pcall(function() Toggles.M1Reset:SetValue(false) end)
    end)

    -- Emote Dash (ported from Phantasm)
    do
        local EMOTE_DASH_ANIM_IDS = {
            'rbxassetid://10480796021',
            'rbxassetid://10480793962',
            'rbxassetid://10491993682',
        }
        BoxCharMods:AddToggle('EmoteDash', {
            Text    = 'Emote Dash',
            Default = false,
        })
        local _emoteDashConns = {}
        local function _setupEmoteDash()
            local _emotes = lp.PlayerGui:WaitForChild('Emotes', 15)
            if not _emotes then return end
            local _imageLabel = _emotes:FindFirstChildWhichIsA('ImageLabel')
            if not _imageLabel then
                local deadline = tick() + 5
                repeat
                    local child = _emotes.ChildAdded:Wait()
                    if child:IsA('ImageLabel') then _imageLabel = child end
                until _imageLabel or tick() > deadline
            end
            if not _imageLabel then return end

            -- inline hook: given a slot Frame, hooks its Button if present
            local function _hookSlot(child)
                local btn = child:FindFirstChild('Button')
                if not (child:IsA('Frame') and tonumber(child.Name) and btn) then return end
                local conn = btn.MouseButton1Click:Connect(function()
                    if not Toggles.EmoteDash.Value then return end
                    local char = getChar(lp)
                    local hum  = char and getHumanoid(char)
                    if not (char and hum) or char:FindFirstChild('Freeze') then return end
                    -- ping/2 so the anim track is already playing server-side when we adjust
                    local ok, pingVal = pcall(function()
                        return game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 1000
                    end)
                    task.wait(ok and pingVal / 2 or 0)
                    for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                        if table.find(EMOTE_DASH_ANIM_IDS, track.Animation.AnimationId) then
                            track:AdjustSpeed(99)
                        end
                    end
                end)
                table.insert(_emoteDashConns, conn)
            end

            -- hook all slots that already exist
            for _, child in pairs(_imageLabel:GetChildren()) do
                _hookSlot(child)
            end

            -- watch for slots added dynamically (GUI rebuild / new emote pages)
            -- only one ChildAdded at imageLabel level — no per-slot watchers, no duplicate stacking
            local c = _imageLabel.ChildAdded:Connect(function(child)
                _hookSlot(child)
            end)
            table.insert(_emoteDashConns, c)
        end
        task.spawn(_setupEmoteDash)
        lp.CharacterAdded:Connect(function()
            -- disconnect everything before re-setup; GUI may still be alive but
            -- slots may have been replaced — full clean is safest
            for _, c in pairs(_emoteDashConns) do c:Disconnect() end
            _emoteDashConns = {}
            task.spawn(_setupEmoteDash)
        end)
        table.insert(CleanupTasks, function()
            for _, c in pairs(_emoteDashConns) do c:Disconnect() end
            _emoteDashConns = {}
            pcall(function() Toggles.EmoteDash:SetValue(false) end)
        end)
    end

end


-- UltMirage toggle: boosts sprint WalkSpeed to 32 (ult tier) via Heartbeat
do
    local _ultHB = nil
    local function _startUltMirage()
        if _ultHB then return end
        _ultHB = RunService.Heartbeat:Connect(function()
            if not Toggles.UltMirage or not Toggles.UltMirage.Value then return end
            local char = lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if char:FindFirstChild("Freeze") or char:FindFirstChild("AntiMove") then return end
            if char:GetAttribute("Running") then
                hum.WalkSpeed = 32
            end
        end)
    end
    local function _stopUltMirage()
        if _ultHB then _ultHB:Disconnect() _ultHB = nil end
    end
    BoxCharMods:AddToggle('UltMirage', {
        Text    = 'Ult Mirage',
        Default = false,
        Callback = function(val)
            if val then
                _startUltMirage()
            else
                _stopUltMirage()
            end
        end,
    })
    table.insert(CleanupTasks, function()
        _stopUltMirage()
        pcall(function() Toggles.UltMirage:SetValue(false) end)
    end)
end


if isGamepassesGame and Tabs.Combat then
    BoxCharMods:AddDropdown("CharacterExploits", {
        Values = {
            "No Dash Cooldown",
            "No Stun",
            "No Slow",
            "No Fatigue",
            "No Jump Bypass",
            "No Rotations Bypass",
            "Anti Ragdoll",
        },
        Default    = {},
        Multi      = true,
        Searchable = false,
        Text       = "Character Exploits",
        Callback   = function(p517)
            workspace:SetAttribute("NoDashCooldown", false)
            workspace:SetAttribute("NoFatigue", false)
            if rawget(p517, "No Dash Cooldown") then
                workspace:SetAttribute("NoDashCooldown", true)
            elseif rawget(p517, "No Fatigue") then
                workspace:SetAttribute("NoFatigue", true)
            elseif rawget(p517, "No Rotations Bypass") then
                local char = lp.Character
                if char then
                    for _, inst in pairs(char:GetDescendants()) do
                        if inst.Name == "NoRotate" or inst.Name == "NoRotateUltimate" then
                            pcall(function() inst:Destroy() end)
                        end
                    end
                end
            end
        end,
    })
    BoxCharMods:AddToggle("AutoRagdollCancel", {
        Text    = "Auto Ragdoll Cancel",
        Default = false,
    })
    BoxCharMods:AddToggle("RagdollHide", {
        Text    = "Ragdoll Hide",
        Default = false,
    })
    BoxCharMods:AddToggle("LaunchHide", {
        Text    = "Launch Hide",
        Default = false,
    })
    workspace:SetAttribute("EffectAffects", 1)
    local _attrGuard = false
    workspace.AttributeChanged:Connect(function(p518)
        if _attrGuard then return end
        _attrGuard = true
        if p518 == "NoDashCooldown" then
            workspace:SetAttribute(p518, rawget(Options.CharacterExploits.Value, "No Dash Cooldown") and true or false)
        elseif p518 == "NoFatigue" then
            workspace:SetAttribute(p518, rawget(Options.CharacterExploits.Value, "No Fatigue") and true or false)
        elseif p518 == "EffectsAffect" then
            workspace:SetAttribute("EffectAffects", 1)
        end
        _attrGuard = false
    end)
    table.insert(CleanupTasks, function()
        pcall(function() Options.CharacterExploits:SetValue({}) end)
        pcall(function() Toggles.AutoRagdollCancel:SetValue(false) end)
        pcall(function() Toggles.RagdollHide:SetValue(false) end)

        pcall(function() Toggles.LaunchHide:SetValue(false) end)
        workspace:SetAttribute("NoDashCooldown", false)
        workspace:SetAttribute("NoFatigue", false)
    end)
end
if isGamepassesGame and Tabs.Combat then
    local _wcCameraLocations = {
        ['Atomic Slash']     = CFrame.new(-52,  1580, 25250) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        Arena                = CFrame.new(-130, 440, -373)  * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        Baseplate            = CFrame.new(-42,  1855, 25227) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        ['Below Baseplate']  = CFrame.new(-42,  1469, 25227) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        Jail                 = CFrame.new(440,  440, -395)  * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        ['Jail But Smaller'] = CFrame.new(20,   439, -460)  * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        ['Bigger Jail']      = CFrame.new(290,  440, 465)   * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        ['Even Bigger Jail'] = CFrame.new(378,  439, 457)   * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        ['Dark Domain']      = CFrame.new(-80,  84,  20395) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        ['Death Counter']    = CFrame.new(-66,  29,   20383) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        Middle               = CFrame.new(155,  441,  45)    * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        ['Mountain 1']       = CFrame.new(306,  671, 411)   * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        ['Mountain 2']       = CFrame.new(-1,   653, -354)  * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        ['Mountain Edge']    = CFrame.new(-297, 594, -336)  * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
        Void                 = CFrame.new(169,  218, 102)   * CFrame.new(0,  1.5, 0) * CFrame.Angles(math.rad(90),  0, 0),
    }
    local _wcTeleportLocations = {
        ['Atomic Slash']     = CFrame.new(-52,  1580, 25250),
        Arena                = CFrame.new(-130, 440, -373),
        Baseplate            = CFrame.new(-42,  1855, 25227),
        ['Below Baseplate']  = CFrame.new(-42,  1469, 25227),
        Jail                 = CFrame.new(440,  440, -395),
        ['Jail But Smaller'] = CFrame.new(20,   439, -460),
        ['Bigger Jail']      = CFrame.new(290,  440, 465),
        ['Even Bigger Jail'] = CFrame.new(378,  439, 457),
        ['Dark Domain']      = CFrame.new(-80,  84,  20395),
        ['Death Counter']    = CFrame.new(-66,  29,   20383),
        Middle               = CFrame.new(150,  441,  32),
        ['Mountain 1']       = CFrame.new(9,    653, -363),
        ['Mountain 2']       = CFrame.new(-1,   653, -354),
        ['Mountain Edge']    = CFrame.new(-297, 594, -336),
        Void                 = CFrame.new(0,    -10000, 0),
    }
    local _sortedWCKeys = {}
    for k in pairs(_wcCameraLocations) do _sortedWCKeys[#_sortedWCKeys+1] = k end
    table.sort(_sortedWCKeys)
    local _wcMiddle         = _wcTeleportLocations.Middle
    local _wcDoingWallCombo = false
    local _wcCharConn2      = nil
    local function _wcHeartbeatTp(cf)
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and root) then return end
        RunService.Heartbeat:Once(function() root.CFrame = cf end)
    end
    local function _wcLoadAnimServer(humanoid, animId)
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://100933578899042"
        local track = humanoid:LoadAnimation(anim)
        anim.AnimationId = "rbxassetid://" .. animId
        return track
    end
    local function _shouldDoWallCombo()
        if getgenv()._wcDashOnCooldown then return true end
        if Toggles.KibaTech   and Toggles.KibaTech.Value   then return false end
        if Toggles.SupaTech   and Toggles.SupaTech.Value   then return false end
        if Toggles.LoopDashV2 and Toggles.LoopDashV2.Value then return false end
        if Toggles.InstantTwisted and Toggles.InstantTwisted.Value then
            local ms = tostring(lp:GetAttribute("Character") or ""):lower()
            if ms:find("garou") or ms:find("hunter") or ms:find("child") then
                return false
            end
        end
        return true
    end
    local function _hookWallComboChar(char)
        if not char then return end
        local root     = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
        local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
        if not root or not humanoid then return end
        char.AttributeChanged:Connect(function(attr)
            if attr ~= "Combo" then return end
            if char:GetAttribute("Combo") ~= 5 then return end
            if not Toggles.WallComboAnywhere.Value then return end
            local mode = Options.AutoWallCombo.Value
            if _wcDoingWallCombo then return end
            task.spawn(function()
                task.wait()
                local _isDownslam = false
                pcall(function()
                    for _, t in pairs(humanoid:GetPlayingAnimationTracks()) do
                        if t.Animation and t.Animation.AnimationId:match("10470104242") then
                            _isDownslam = true
                            break
                        end
                    end
                end)
                local _isM4 = false
                pcall(function()
                    local M4_IDS = {
                        "10469643643",
                        "13294471966",
                        "17889290569",
                        "13295936866",
                        "13378708199",
                        "14136436157",
                        "15162694192",
                        "16552234590",
                        "17325537719",
                        "134775406437626",
                        "80601239139774",
                    }
                    for _, t in pairs(humanoid:GetPlayingAnimationTracks()) do
                        if t.Animation then
                            local id = t.Animation.AnimationId:match("%d+") or ""
                            for _, m4id in ipairs(M4_IDS) do
                                if id == m4id then _isM4 = true; break end
                            end
                        end
                        if _isM4 then break end
                    end
                end)
                if _isM4 then
                    local _ownChar = tostring(lp:GetAttribute("Character") or ""):lower()
                    local _isGarouOrCE = _ownChar:find("garou") or _ownChar:find("hunter") or _ownChar:find("monster") or _ownChar:find("child") or _ownChar:find("tech")
                    if _isGarouOrCE and Toggles.InstantTwisted and Toggles.InstantTwisted.Value then
                        _isM4 = false
                    end
                end
                if not _isDownslam and not _isM4 and not _shouldDoWallCombo() then return end
                if mode == "Auto Wall Combo + Bring" then
                    _wcDoingWallCombo = true
                    local t = tick()
                    repeat
                        getgenv().flingDesync = {
                            CFrame = root.CFrame * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
                        }
                        task.wait()
                    until tick() >= t + 0.225
                    -- capture savedCF after the desync loop, like Phantasm (_CFrame4 = u862.CFrame)
                    local savedCF = root.CFrame
                    getgenv().flingDesync = {
                        CFrame = _wcCameraLocations[Options.AutoWallComboArea.Value],
                    }
                    task.wait(0.2)
                    pcall(function() char.Communicate:FireServer({ Goal = "Wall Combo" }) end)
                    getgenv().flingDesync = nil
                    _wcDoingWallCombo = false
                    task.wait(0.5)
                    if char:FindFirstChild("ForceField") and Toggles.AutoWallComboTPBack.Value then
                        pcall(function()
                            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                track:Stop()
                            end
                        end)
                        _wcHeartbeatTp(savedCF)
                    end
                else
                    _wcDoingWallCombo = true
                    local wallAnim = nil
                    if not getgenv().InvisActive and not getgenv().FUCActive then
                        local track = _wcLoadAnimServer(humanoid, "181525546")
                        track.Priority = Enum.AnimationPriority.Action3
                        task.delay(0.1, function()
                            track:Play()
                            track.TimePosition = 1
                            track:AdjustWeight(999999)
                            track:AdjustSpeed(0)
                        end)
                        wallAnim = track
                    end
                    local t = tick()
                    repeat
                        getgenv().flingDesync = {
                            CFrame = root.CFrame * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
                        }
                        task.wait()
                    until tick() >= t + 0.6
                    getgenv().flingDesync = nil
                    _wcDoingWallCombo = false
                    task.delay(0.1, function()
                        if wallAnim then pcall(function() wallAnim:Stop() end) end
                    end)
                end
            end)
        end)
        char.DescendantAdded:Connect(function(obj)
            if not (obj:IsA("ObjectValue") and obj.Name:lower() == "wallcombo") then return end
            if not Toggles.WallComboAnywhere.Value then return end
            local startTime = tick()
            while true do
                if Options.AutoWallCombo.Value == "Auto Wall Combo" then
                    pcall(function() char.Communicate:FireServer({ Goal = "Wall Combo" }) end)
                end
                task.wait()
                if obj.Parent ~= char or tick() >= startTime + (obj:GetAttribute("DeleteMe") or 0.6) then
                    break
                end
            end
        end)
    end
    _hookWallComboChar(lp.Character)
    _wcCharConn2 = lp.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        _hookWallComboChar(char)
    end)
    table.insert(CleanupTasks, function()
        getgenv().flingDesync = nil
        _wcDoingWallCombo = false
        if _wcCharConn2 then _wcCharConn2:Disconnect() _wcCharConn2 = nil end
        pcall(function() Toggles.WallComboAnywhere:SetValue(false) end)
        pcall(function() Options.AutoWallCombo:SetValue("Manual") end)
        pcall(function() Toggles.AutoWallComboTPBack:SetValue(false) end)
    end)
    local BoxWallCombo = TabExpWallCombo
    BoxWallCombo:AddToggle("WallComboAnywhere", {
        Text    = "Wall Combo Anywhere",
        Default = false,
    })
    BoxWallCombo:AddDropdown("AutoWallCombo", {
        Text    = "Auto Wall Combo",
        Values  = { "Manual", "Auto Wall Combo", "Auto Wall Combo + Bring" },
        Multi   = false,
        Default = 1,
    })
    BoxWallCombo:AddToggle("AutoWallComboTPBack", {
        Text    = "Teleport Back",
        Default = false,
    })
    BoxWallCombo:AddDropdown("AutoWallComboArea", {
        Text       = "Area",
        Values     = _sortedWCKeys,
        Multi      = false,
        Default    = table.find(_sortedWCKeys, "Death Counter"),
        Searchable = true,
    })
    BoxWallCombo:AddButton({
        Text = "Teleport To Area",
        Func = function()
            local cf = _wcTeleportLocations[Options.AutoWallComboArea.Value]
            if not cf then return end
            local char = lp.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if char and root then
                local dist = (_wcTeleportLocations.Middle.Position - cf.Position).Magnitude
                if dist >= 100 then _wcMiddle = root.CFrame end
            end
            _wcHeartbeatTp(cf)
        end,
    })
    BoxWallCombo:AddButton({
        Text = "Teleport Back",
        Func = function()
            _wcHeartbeatTp(_wcMiddle)
        end,
    })
end

if trashcanGameIds[currentPlaceId] then
    local BoxTrashcan = TabExpTrashcan
    BoxTrashcan:AddToggle("TrashcanLaunch", {
        Text    = "Trashcan Launch",
        Default = false,
    })
    BoxTrashcan:AddSlider("Trashcan_LaunchPower", {
        Text     = "Launch Power",
        Default  = 100,
        Min      = 1,
        Max      = 2500,
        Rounding = 1,
        Compact  = true,
    })
end
if trashcanGameIds[currentPlaceId] and Tabs.Combat then
    local _sbTeleportLocations = {
        ['Above Tunnel']     = CFrame.new(-301, 594, -322),
        Arena                = CFrame.new(-130, 440, -373),
        ['Atomic Slash']     = CFrame.new(-52,  1580, 25250),
        Baseplate            = CFrame.new(-42,  1855, 25227),
        ['Below Baseplate']  = CFrame.new(-42,  1469, 25227),
        ['Bigger Jail']      = CFrame.new(290,  440, 465),
        ['Black Domain']     = CFrame.new(1000000000000, 100000000, 100000000000),
        ['Even Bigger Jail'] = CFrame.new(378,  439, 457),
        ['Dark Domain']      = CFrame.new(-80,  84,  20395),
        ['Death Counter']    = CFrame.new(-66,  29,   20383),
        Jail                 = CFrame.new(440,  440, -395),
        ['Jail But Smaller'] = CFrame.new(20,   439, -460),
        Middle               = CFrame.new(150,  441,  32),
        ['Mountain 1']       = CFrame.new(306,  671, 411),
        ['Mountain 2']       = CFrame.new(-1,   653, -354),
        ['Mountain Edge']    = CFrame.new(-297, 594, -336),
        Void                 = CFrame.new(0,    -10000, 0),
    }
    local _sortedSBKeys = {}
    for k in pairs(_sbTeleportLocations) do _sortedSBKeys[#_sortedSBKeys+1] = k end
    table.sort(_sortedSBKeys)
    local _sbMiddle   = _sbTeleportLocations.Middle
    local _sbCharConn = nil
    local _crushingPullVoidActive = false
    local function _sbHeartbeatTp(cf)
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and root) then return end
        RunService.Heartbeat:Once(function() root.CFrame = cf end)
    end


    local function _hookSkillBringChar(char)
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
        local root     = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
        if not humanoid or not root then return end
        humanoid.AnimationPlayed:Connect(function(track)
            if not Toggles.SkillBring.Value then return end
            local id      = track.Animation.AnimationId
            local dest    = _sbTeleportLocations[Options.SkillBringArea.Value]
            local tpBack  = Toggles.SkillBringTPBack.Value
            local useVoid = (Options.SkillBringArea.Value == "Void")
            if id:match('12296113986') then
                local saved = root.CFrame
                game:GetService("TweenService"):Create(root, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = dest}):Play()
                if tpBack then
                    local t = tick()
                    repeat task.wait() until not track.IsPlaying or tick() - t > 8
                    _sbHeartbeatTp(saved)
                end
            elseif id:match('15145462680') then
                task.spawn(function()
                    task.wait(1.6)
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= lp then
                            local pchar = p.Character
                            local proot = pchar and pchar:FindFirstChild("HumanoidRootPart")
                            local phum  = pchar and pchar:FindFirstChildOfClass("Humanoid")
                            if proot and phum and (proot.Position - root.Position).Magnitude <= 15 and phum.Health <= 20 then
                                return
                            end
                        end
                    end
                    local saved = root.CFrame
                    local t = tick()
                    repeat _sbHeartbeatTp(dest) task.wait() until tick() >= t + 0.5
                    if tpBack then
                        repeat task.wait() until not track.IsPlaying or tick() - t > 8
                        _sbHeartbeatTp(saved)
                    end
                end)
            elseif id:match('16139108718') then
                task.spawn(function()
                    local saved = root.CFrame
                    if useVoid then
                        local variantTrack = nil
                        local _varConn = humanoid.AnimationPlayed:Connect(function(t2)
                            if t2.Animation.AnimationId:match('16571461202') then
                                variantTrack = t2
                            end
                        end)
                        keypress(0x20)
                        repeat task.wait() until not track.IsPlaying or variantTrack
                        keyrelease(0x20)
                        _varConn:Disconnect()
                        if not variantTrack then return end  -- miss, no tp
                        _sbHeartbeatTp(dest)
                        if tpBack then
                            local t2 = tick()
                            repeat task.wait() until not variantTrack.IsPlaying or tick() - t2 > 8
                            _sbHeartbeatTp(saved)
                        end
                        return
                    end
                    -- freeze camera so char movement is invisible during the whole sequence
                    local cam      = workspace.CurrentCamera
                    local frozenCF = cam.CFrame
                    cam.CameraType = Enum.CameraType.Scriptable
                    getgenv()._cpCamActive = true
                    local _camTypeConn = cam:GetPropertyChangedSignal("CameraType"):Connect(function()
                        if cam.CameraType ~= Enum.CameraType.Scriptable then
                            cam.CameraType = Enum.CameraType.Scriptable
                        end
                    end)
                    RunService:BindToRenderStep("_cpCamLock", Enum.RenderPriority.Camera.Value + 1, function()
                        cam.CFrame = frozenCF
                    end)
                    -- hold space to trigger the bring variant anim
                    keypress(0x20)
                    -- catch the variant anim that space triggers
                    local variantTrack = nil
                    local _varConn = humanoid.AnimationPlayed:Connect(function(t2)
                        if not variantTrack then variantTrack = t2 end
                    end)
                    -- keep pushing to dest while waiting for variant to kick in
                    local t = tick()
                    repeat _sbHeartbeatTp(dest) task.wait() until variantTrack or tick() - t > 1.5
                    _varConn:Disconnect()
                    keyrelease(0x20)
                    -- wait for variant anim to fully finish before returning
                    if variantTrack then
                        local t2 = tick()
                        repeat task.wait() until not variantTrack.IsPlaying or tick() - t2 > 6
                    end
                    _camTypeConn:Disconnect()
                    RunService:UnbindFromRenderStep("_cpCamLock")
                    getgenv()._cpCamActive = false
                    cam.CameraType = Enum.CameraType.Custom
                    if tpBack then _sbHeartbeatTp(saved) end
                end)
            elseif id:match('18182425133') then
                task.spawn(function()
                    local saved = root.CFrame
                    repeat task.wait() until track.TimePosition >= 2.6 or not track.IsPlaying
                    if not track.IsPlaying then return end
                    _sbHeartbeatTp(dest)
                    if tpBack then
                        repeat task.wait() until not track.IsPlaying
                        _sbHeartbeatTp(saved)
                    end
                end)
            elseif id:match('94638356008696') then
                task.spawn(function()
                    local saved = root.CFrame
                    repeat task.wait() until track.TimePosition >= 1.50 or not track.IsPlaying
                    if not track.IsPlaying then return end
                    repeat _sbHeartbeatTp(dest) task.wait() until not track.IsPlaying
                    if tpBack then _sbHeartbeatTp(saved) end
                end)
            elseif id:match('95034083206292') then
                task.spawn(function()
                    local saved = root.CFrame
                    repeat task.wait() until track.TimePosition >= 1.7 or not track.IsPlaying
                    if not track.IsPlaying then return end
                    _sbHeartbeatTp(dest)
                    if tpBack then
                        repeat task.wait() until not track.IsPlaying
                        _sbHeartbeatTp(saved)
                    end
                end)
            elseif id:match('115484690572880') then
                task.spawn(function()
                    local saved = root.CFrame
                    repeat task.wait() until track.TimePosition >= 1 or not track.IsPlaying
                    if not track.IsPlaying then return end
                    _sbHeartbeatTp(dest)
                    if tpBack then
                        repeat task.wait() until not track.IsPlaying
                        _sbHeartbeatTp(saved)
                    end
                end)
            elseif id:match('16571461202') then
                task.spawn(function()
                    local saved = root.CFrame
                    _sbHeartbeatTp(dest)
                    local t = tick()
                    repeat task.wait() until not track.IsPlaying or tick() - t > 8
                    if tpBack then _sbHeartbeatTp(saved) end
                end)
            end
        end)
    end
    _hookSkillBringChar(lp.Character)
    _sbCharConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        _hookSkillBringChar(char)
    end)

    -- ── INVISIBLE MOVES LOGIC ──────────────────────────────────────────────────
    local _imCounterAnims    = {'rbxassetid://12351854556','rbxassetid://15311685628','rbxassetid://15128849047'}
    local _imCounterHitAnims = {'rbxassetid://13603396939','rbxassetid://15334974550','rbxassetid://15123665491'}
    local _imBlockAnims      = {'rbxassetid://10470389827','rbxassetid://13380778193','rbxassetid://13935548552'}
    local _invisMovesConns   = {}
    local function _hookInvisMovesChar(char)
        if not char then return end
        local hum  = char:FindFirstChildOfClass('Humanoid') or char:WaitForChild('Humanoid', 3)
        local root = char:FindFirstChild('HumanoidRootPart') or char:WaitForChild('HumanoidRootPart', 3)
        if not hum or not root then return end
        table.insert(_invisMovesConns, char:GetAttributeChangedSignal('Blocking'):Connect(function()
            if char:GetAttribute('Blocking') and Toggles.InvisibleMoves_Block.Value then
                char:SetAttribute('Blocking', false)
            end
        end))
        table.insert(_invisMovesConns, hum.AnimationPlayed:Connect(function(track)
            local id = track.Animation.AnimationId
            if id:match('11365563255') and rawget(Options.InvisibleMoves_Saitama.Value, 'Invisible Table Flip') then
                track:Stop()
                task.delay(3, function()
                    hum.HipHeight = 10
                    task.wait(0.75)
                    hum.HipHeight = 0
                end)
            elseif id:match('12983333733') then
                if rawget(Options.InvisibleMoves_Saitama.Value, 'Invisible Serious Punch') then
                    track:Stop()
                end
            elseif id:match('13927612951') and rawget(Options.InvisibleMoves_Saitama.Value, 'Invisible Omni-Directional Punch') then
                track:Stop()
            elseif id:match('12447707844') and rawget(Options.InvisibleMoves_Saitama.Value, 'Invisible Ult') then
                track:Stop()
                local _t = tick()
                repeat
                    getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                    task.wait()
                until tick() >= _t + 1
                getgenv().desync = nil
            elseif id:match('12342141464') and rawget(Options.InvisibleMoves_Garou.Value, 'Invisible Ult') then
                track:Stop()
            elseif (id == 'rbxassetid://13499771836' or id == 'rbxassetid://13497875049') and rawget(Options.InvisibleMoves_Sonic.Value, 'Invisible Ult') then
                track:Stop()
            elseif id:match('12772543293') and rawget(Options.InvisibleMoves_Genos.Value, 'Invisible Ult') then
                track:Stop()
            elseif id:match('13146710762') and rawget(Options.InvisibleMoves_Genos.Value, 'Invisible Incinerate') then
                track:Stop()
            elseif id:match('15145462680') and rawget(Options.InvisibleMoves_AtomicSamurai.Value, 'Invisible Atmos Cleave') then
                track:Stop()
            elseif id:match('15391323441') and rawget(Options.InvisibleMoves_AtomicSamurai.Value, 'Invisible Ult') then
                track:Stop()
            elseif (id:match('16139108718') or id:match('16139708727') or id:match('16139402582')) and rawget(Options.InvisibleMoves_Tatsumaki.Value, 'Invisible Crushing Pull') then
                track:Stop()
            elseif id:match('16515850153') and rawget(Options.InvisibleMoves_Tatsumaki.Value, 'Invisible Windstorm Fury') then
                track:Stop()
            elseif id:match('16431491215') and rawget(Options.InvisibleMoves_Tatsumaki.Value, 'Invisible Stone Grave') then
                track:Stop()
            elseif (id:match('16597322398') or id:match('16597912086')) and rawget(Options.InvisibleMoves_Tatsumaki.Value, 'Invisible Expulsive Push') then
                track:Stop()
            elseif id:match('16734584478') and rawget(Options.InvisibleMoves_Tatsumaki.Value, 'Invisible Ult') then
                track:Stop()
            elseif id:match('15520132233') and rawget(Options.InvisibleMoves_AtomicSamurai.Value, 'Invisible Sunset') then
                track:Stop()
            elseif id:match('15676072469') and rawget(Options.InvisibleMoves_AtomicSamurai.Value, 'Invisible Solar Cleave') then
                track:Stop()
            elseif id:match('16062410809') and rawget(Options.InvisibleMoves_AtomicSamurai.Value, 'Invisible Sunrise') then
                track:Stop()
            elseif id:match('16062712948') and rawget(Options.InvisibleMoves_AtomicSamurai.Value, 'Invisible Sunrise Finisher') then
                track:Stop()
            elseif id:match('16082123712') and rawget(Options.InvisibleMoves_AtomicSamurai.Value, 'Invisible Atomic Slash') then
                track:Stop()
            elseif id:match('16057411888') and rawget(Options.InvisibleMoves_AtomicSamurai.Value, 'Invisible Atomic Slash Finisher') then
                track:Stop()
            elseif id:match('17799224866') and rawget(Options.InvisibleMoves_Suiryu.Value, 'Bullet Barrage') then
                track:Stop()
            elseif id:match('17275150809') and rawget(Options.InvisibleMoves_Tatsumaki.Value, 'Invisible Terrible Tornado') then
                track:Stop()
            elseif id:match('17278415853') and rawget(Options.InvisibleMoves_Tatsumaki.Value, 'Invisible Terrible Tornado Finisher') then
                track:Stop()
            elseif table.find(_imCounterAnims, id) and Toggles.InvisibleMoves_Counter.Value then
                track:AdjustWeight(-999999)
            elseif table.find(_imCounterHitAnims, id) and Toggles.InvisibleMoves_CounterHit.Value then
                track:Stop()
            elseif table.find(_imBlockAnims, id) and Toggles.InvisibleMoves_Block.Value then
                track:AdjustWeight(-999999)
                local shield = char:FindFirstChild('EsperShield', true)
                if shield then
                    for _, pe in pairs(shield:GetDescendants()) do
                        if pe:IsA('ParticleEmitter') and not pe.Name:find('Impact') then
                            task.spawn(function()
                                local origRate, origColor = pe.Rate, pe.Color
                                pe.Rate = 45
                                if Toggles.InvisibleMoves_BlockColor.Value then
                                    pe.Color = ColorSequence.new({
                                        ColorSequenceKeypoint.new(0,   Options.InvisibleMoves_BlockColor1.Value),
                                        ColorSequenceKeypoint.new(0.5, Options.InvisibleMoves_BlockColor2.Value),
                                        ColorSequenceKeypoint.new(1,   Options.InvisibleMoves_BlockColor3.Value),
                                    })
                                end
                                pe.Enabled = true
                                repeat RunService.RenderStepped:Wait() until not track.IsPlaying
                                pe.Enabled = false
                                pe.Rate = origRate
                                if Toggles.InvisibleMoves_BlockColor.Value then pe.Color = origColor end
                            end)
                        end
                    end
                end
            end
        end))
    end
    _hookInvisMovesChar(lp.Character)
    local _invisMovesCharConn = lp.CharacterAdded:Connect(function(char) task.wait(0.1) _hookInvisMovesChar(char) end)
    table.insert(CleanupTasks, function()
        if _invisMovesCharConn then _invisMovesCharConn:Disconnect() _invisMovesCharConn = nil end
        for _, conn in ipairs(_invisMovesConns) do pcall(function() conn:Disconnect() end) end
        table.clear(_invisMovesConns)
        pcall(function() Toggles.InvisibleMoves_Block:SetValue(false) end)
        pcall(function() Toggles.InvisibleMoves_BlockColor:SetValue(false) end)
        pcall(function() Toggles.InvisibleMoves_Counter:SetValue(false) end)
        pcall(function() Toggles.InvisibleMoves_CounterHit:SetValue(false) end)
    end)
    -- ── END INVISIBLE MOVES LOGIC ──────────────────────────────────────────────
    table.insert(CleanupTasks, function()
        if _sbCharConn then _sbCharConn:Disconnect() _sbCharConn = nil end
        pcall(function() Toggles.SkillBring:SetValue(false) end)
        pcall(function() Toggles.SkillBringTPBack:SetValue(false) end)
    end)
    local BoxSkillBring = TabExpMain
    BoxSkillBring:AddToggle("SkillBring", {
        Text    = "Skill Bring",
        Default = false,
    })
    BoxSkillBring:AddToggle("SkillBringTPBack", {
        Text    = "Teleport Back",
        Default = false,
    })
    BoxSkillBring:AddDropdown("SkillBringArea", {
        Text       = "Skill Bring Area",
        Values     = _sortedSBKeys,
        Multi      = false,
        Default    = table.find(_sortedSBKeys, "Death Counter"),
        Searchable = true,
    })
    BoxSkillBring:AddButton({
        Text = "Teleport To Area",
        Func = function()
            local cf   = _sbTeleportLocations[Options.SkillBringArea.Value]
            if not cf then return end
            local char = lp.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if char and root then
                _sbMiddle = root.CFrame
            end
            _sbHeartbeatTp(cf)
        end,
    })
    BoxSkillBring:AddButton({
        Text = "Teleport Back",
        Func = function()
            _sbHeartbeatTp(_sbMiddle)
        end,
    })
    TabExpMain:AddDivider()
    local BoxBringAll = TabExpMain
    BoxBringAll:AddToggle("AttackAll", {
        Text    = "Attack All",
        Default = false,
    })
    BoxBringAll:AddDropdown("AttackAllMoves", {
        Text       = "Moves",
        Values     = {
            "Savage Tornado",
            "Brutal Beatdown",
            "Crushed Rock Variant",
            "Twin Fangs",
        },
        Multi      = true,
        Default    = {},
        Searchable = false,
    })
    TabExpMain:AddDivider()
    BoxBringAll:AddToggle("SkillThrow", {
        Text    = "Skill Throw",
        Default = false,
    })
    BoxBringAll:AddDropdown("SkillThrowMoves", {
        Values = {
            "Hunters Grasp",
            "Homerun",
        },
        Multi   = true,
        Default = {},
    })
    TabExpMain:AddDivider()
    BoxBringAll:AddToggle("NoBP_WindstormFury", {
        Text    = "No Windstorm Fury BP",
        Default = false,
    })
    BoxBringAll:AddToggle("NoBP_TatsumakiUlt", {
        Text    = "No Tatsumaki Ult BP",
        Default = false,
    })
    BoxBringAll:AddToggle("NoBP_PreysPeril", {
        Text    = "No Prey's Peril BP",
        Default = false,
    })
    table.insert(CleanupTasks, function()
        pcall(function() Toggles.AttackAll:SetValue(false) end)
        pcall(function() Toggles.SkillThrow:SetValue(false) end)
        pcall(function() Toggles.NoBP_WindstormFury:SetValue(false) end)
        pcall(function() Toggles.NoBP_TatsumakiUlt:SetValue(false) end)
        pcall(function() Toggles.NoBP_PreysPeril:SetValue(false) end)
    end)
end
task.spawn(function()
local _featOk, _featErr = xpcall(function()
do
    local _pMouse = lp:GetMouse()
    local _pStats = game:GetService("Stats")
    local _pRS    = game:GetService("ReplicatedStorage")
    local _pDebris= game:GetService("Debris")
    _pU59 = {
        Flying                      = false,
        ['Touch Fling']          = false,
        ['Touch Fling Settings'] = Vector3.new(0, 0, 0),
        ['Trashcan Launch']         = false,
    }
    _pU525 = {
        Fly               = false,
        ['Lock-on']       = false,
        ['Touch Fling']= false,
    }
    local _pConns     = {}
    local _pCharConns = {}
    local _pClone     = nil
    local _pCloneList = {}
    local function _pGetChar(p)
        if typeof(p) == "Instance" then
            if p:IsA("Player") then
                return p.Character
            elseif p:IsA("Model") then
                return p
            end
        end
        return nil
    end
    local function _pGetRoot(c)  return c and c:FindFirstChild('HumanoidRootPart') or nil end
    local function _pGetHum(c)   return c and c:FindFirstChildOfClass('Humanoid')  or nil end
    local function _pGetAllPlayers()
        local list = Players:GetPlayers()
        local idx = table.find(list, lp)
        if idx then table.remove(list, idx) end
        return list
    end
    local function _pIsAnimPlaying(hum, id)
        if not hum then return false end
        for _, t in pairs(hum:GetPlayingAnimationTracks()) do
            if t.Animation.AnimationId:match(id) then return true end
        end
        return false
    end
    local function _heartbeatTp(cf)
        local char = _pGetChar(lp)
        local root = char and _pGetRoot(char)
        if char and root then
            task.spawn(function()
                RunService.RenderStepped:Once(function()
                    root.Velocity = Vector3.new()
                    RunService.Heartbeat:Wait()
                    root.Velocity = Vector3.new()
                end)
            end)
            RunService.Heartbeat:Once(function()
                _heartbeatTp(cf)
            end)
        end
    end
    local function _pGrabRandom(skipDeathBlow)
        local all = _pGetAllPlayers()
        if #all == 0 then return end
        local filtered = {}
        for _, p in ipairs(all) do
            if not table.find(RevenantWhitelist, p) then
                table.insert(filtered, p)
            end
        end
        if #filtered == 0 then return end
        local target = filtered[math.random(1, #filtered)]
        if target == lp then return end
        local myChar = _pGetChar(lp)
        local myRoot = myChar and _pGetRoot(myChar)
        local tChar  = _pGetChar(target)
        local tRoot  = tChar and _pGetRoot(tChar)
        local tHum   = tChar and _pGetHum(tChar)
        if not (myChar and myRoot and tChar and tRoot and tHum) then return end
        if skipDeathBlow then
            if tChar:GetAttribute("Ulted") and tChar:GetAttribute("Character") == "Batter" then return end
            for _, obj in pairs(tChar:GetChildren()) do
                if obj:IsA('Tool') and obj.Name == 'Death Blow' then return end
            end
            if _pIsAnimPlaying(tHum, '15128849047') then return end
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp and p ~= target then
                    local pc = _pGetChar(p)
                    local pr = pc and _pGetRoot(pc)
                    local ph = pc and _pGetHum(pc)
                    if pc and pr and ph and (pr.Position - tRoot.Position).Magnitude <= 100 then
                        if pc:GetAttribute("Ulted") and pc:GetAttribute("Character") == "Batter" then return end
                        for _, obj in pairs(pc:GetChildren()) do
                            if obj:IsA('Tool') and obj.Name == 'Death Blow' then return end
                        end
                        if _pIsAnimPlaying(ph, '15128849047') then return end
                    end
                end
            end
        end
        if typeof(sethiddenproperty) == "function" then
            pcall(sethiddenproperty, myRoot, "PhysicsRepRootPart", tRoot)
            pcall(sethiddenproperty, tRoot,  "PhysicsRepRootPart", myRoot)
        end
        RunService.Heartbeat:Once(function() myRoot.CFrame = tRoot.CFrame end)
        task.wait()
        RunService.Heartbeat:Once(function() myRoot.CFrame = CFrame.lookAt(myRoot.Position, tRoot.Position) end)
    end
    local function _pHeartbeatTp(targetCFrame)
        local grabChar = _pGetChar(lp)
        local grabRoot = grabChar and _pGetRoot(grabChar) or grabChar
        if grabChar and grabRoot then
            task.spawn(function()
                RunService.RenderStepped:Once(function()
                    grabRoot.Velocity = Vector3.new()
                    RunService.Heartbeat:Wait()
                    grabRoot.Velocity = Vector3.new()
                end)
            end)
            RunService.Heartbeat:Once(function()
                RunService.Heartbeat:Once(function() grabRoot.CFrame = targetCFrame end)
            end)
        end
    end
    local function _pLoadAnim(animParent, animId, animPriority)
        if not (animParent and animId) then return nil end
        local soundAssetId = 'rbxassetid://' .. tostring(animId):match('%d+')
        local anim = Instance.new('Animation')
        local soundInstance = nil
        if animPriority then
            if animPriority == 'Server' then
                anim.AnimationId = 'rbxassetid://100933578899042'
                soundInstance = animParent:LoadAnimation(anim)
                anim.AnimationId = soundAssetId
            elseif animPriority == 'Client' then
                anim.AnimationId = soundAssetId
                soundInstance = animParent:LoadAnimation(anim)
                anim.AnimationId = 'rbxassetid://100933578899042'
            end
        else
            anim.AnimationId = soundAssetId
            soundInstance = animParent:LoadAnimation(anim)
        end
        return soundInstance
    end
    local function _pLoadSound(soundParent, soundId)
        if not (soundParent and soundId) then return nil end
        local snd = Instance.new('Sound')
        snd.Parent  = soundParent
        snd.SoundId = 'rbxassetid://' .. tostring(soundId):match('%d+')
        return snd
    end
    local function _pStopAllAnims(exceptActive, animIdFilter)
        local noGrabChar = not exceptActive and _pGetChar(lp)
        if noGrabChar then noGrabChar = _pGetHum(_pGetChar(lp)) end
        if noGrabChar then
            if animIdFilter then
                for _, stopTrack in pairs(noGrabChar:GetPlayingAnimationTracks()) do
                    if typeof(animIdFilter) ~= 'table' then
                        if stopTrack.Animation.AnimationId:match(tostring(animIdFilter):match('%d+')) then
                            stopTrack:Stop()
                        end
                    else
                        for _, stopAnimId in pairs(animIdFilter) do
                            if stopTrack.Animation.AnimationId:match(tostring(stopAnimId):match('%d+')) then
                                stopTrack:Stop()
                            end
                        end
                    end
                end
            else
                for _, stopTrack2 in pairs(noGrabChar:GetPlayingAnimationTracks()) do
                    stopTrack2:Stop()
                end
            end
        end
    end
    local function _pGetCommunicator()
        local teleportChar = _pGetChar(lp)
        if not teleportChar then return nil end
        teleportChar = teleportChar:WaitForChild('Communicate', 1)
        return teleportChar
    end
    local function _pCommunicate(eventData)
        local communicator = _pGetCommunicator()
        if communicator then communicator:FireServer(eventData) end
    end
    local function _pDeleteNew(instance, newInstance)
        task.wait()
        local _Parent2 = instance.Parent
        instance:Destroy()
        if newInstance then
            warn('Instance removed, Name:', instance.Name, 'ClassName:', instance.ClassName, 'Parent:', _Parent2)
        end
    end
    local function _pIsFlung(targetPlayer)
        local targetChar = (typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Model")) and targetPlayer or _pGetChar(targetPlayer)
        local targetRoot = targetChar and _pGetRoot(targetChar) or targetChar
        return targetChar and targetRoot and targetRoot.Velocity.Magnitude >= 2000 and true or false
    end
    local function _pClosestPlayerV2(excludeFF, maxDist)
        local mouseTPChar = _pGetChar(lp)
        local mouseTPRoot = mouseTPChar and _pGetRoot(mouseTPChar) or mouseTPChar
        local mouseTPConn = nil
        if mouseTPChar and mouseTPRoot then
            local _huge2 = math.huge
            
            local targets = {}
            for _, p in pairs(Players:GetPlayers()) do
                table.insert(targets, p)
            end
            local liveFolder = workspace:FindFirstChild("Live")
            if liveFolder then
                for _, m in ipairs(liveFolder:GetChildren()) do
                    if m:IsA("Model") and m:FindFirstChild("Humanoid") then
                        table.insert(targets, m)
                    end
                end
            end

            for _, mouseTPPlayer in ipairs(targets) do
                local isLocalPlayer = (mouseTPPlayer == lp) or (typeof(mouseTPPlayer) == "Instance" and mouseTPPlayer:IsA("Model") and mouseTPPlayer == lp.Character)
                local targetChar = (typeof(mouseTPPlayer) == "Instance" and mouseTPPlayer:IsA("Model")) and mouseTPPlayer or _pGetChar(mouseTPPlayer)
                if not isLocalPlayer and targetChar then
                    local mouseTPTargetChar = targetChar
                    local mouseTPTargetRoot = mouseTPTargetChar and _pGetRoot(mouseTPTargetChar) or mouseTPTargetChar
                    local mouseTPTargetHum = mouseTPTargetChar and _pGetHum(mouseTPTargetChar)  or mouseTPTargetChar
                    if mouseTPTargetChar and mouseTPTargetRoot and mouseTPTargetHum and mouseTPTargetHum.Health ~= 0 and workspace.CurrentCamera then
                        local mouseTPHitConn = nil
                        if excludeFF then
                            local screenPos = workspace.CurrentCamera:WorldToViewportPoint(mouseTPTargetRoot.Position)
                            mouseTPHitConn = (Vector2.new(screenPos.X, screenPos.Y) - UIS:GetMouseLocation()).Magnitude
                        else
                            mouseTPHitConn = (mouseTPRoot.Position - mouseTPTargetRoot.Position).Magnitude
                        end
                        if mouseTPHitConn < _huge2 then
                            if maxDist then
                                if not _pIsFlung(mouseTPPlayer) then
                                    _huge2 = mouseTPHitConn
                                    mouseTPConn   = mouseTPPlayer
                                end
                            else
                                _huge2 = mouseTPHitConn
                                mouseTPConn   = mouseTPPlayer
                            end
                        end
                    end
                end
            end
        end
        return mouseTPConn
    end
    local function _pGetHighestStreak()
        local bestStreakVal, bestStreakPlayer = 0, nil
        for _, streakPlayer in pairs(Players:GetPlayers()) do
            local streakChar = _pGetChar(streakPlayer)
            local streakVal = streakChar and (streakChar:GetAttribute('CurrentStreak') or 0) or 0
            if streakChar and bestStreakVal < streakVal then
                bestStreakPlayer = streakPlayer
                bestStreakVal = streakVal
            end
        end
        return bestStreakPlayer
    end
    local BoxKeybinds = BoxKeybindsLP
    BoxKeybinds:AddToggle('AnimeTeleportation', {
        Text    = 'Anime Teleportation',
        Default = false,
        Callback = function(val)
        end,
    })
    BoxKeybinds:AddLabel('Anime Teleportation Keybind'):AddKeyPicker('AnimeTPKeybind', {
        SyncToggleState = false,
        Mode = 'Toggle',
        Default = 'T',
        Text = 'Anime Teleportation',
        Callback = function()
            Options.AnimeTPKeybind.Toggled = false
            if not Toggles.AnimeTeleportation or not Toggles.AnimeTeleportation.Value then return end
            local touchFlingLocalChar = _pGetChar(lp)
            local touchFlingLocalRoot = touchFlingLocalChar and _pGetRoot(touchFlingLocalChar) or touchFlingLocalChar
            local touchFlingLocalHum = touchFlingLocalChar and _pGetHum(touchFlingLocalChar)  or touchFlingLocalChar
            if not (touchFlingLocalChar and touchFlingLocalRoot and touchFlingLocalHum) then return end
            local mode = getgenv()._revenantTPMode or (Options.AnimeTPMode and Options.AnimeTPMode.Value) or "Teleport to Mouse"
            local destCF = nil
            if mode == "Silent Lock" then
                local closest, closestDist = nil, math.huge
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lp then
                        local pc = p.Character
                        local pr = pc and pc:FindFirstChild("HumanoidRootPart")
                        local ph = pc and pc:FindFirstChildOfClass("Humanoid")
                        if pc and pr and ph and ph.Health > 0 then
                            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(pr.Position)
                            if onScreen then
                                local mousePosVec = UIS:GetMouseLocation()
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePosVec).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closest = pr
                                end
                            end
                        end
                    end
                end
                if closest then
                    destCF = CFrame.new(closest.CFrame.Position - closest.CFrame.LookVector * 5, closest.CFrame.Position)
                end
            else
                if _pMouse.Target then
                    local _CFrame3 = touchFlingLocalRoot.CFrame
                    destCF = CFrame.new(
                        _pMouse.Hit.Position,
                        Vector3.new(_CFrame3.Position.X, _pMouse.Hit.Position.Y, _CFrame3.Position.Z)
                    ) * CFrame.Angles(0, math.pi, 0)
                end
            end
            if not destCF then return end
            _pStopAllAnims(touchFlingLocalHum, {'15957361339'})
            if Toggles.AnimeTPAnimation.Value then
                local kjAnimTrack = _pLoadAnim(touchFlingLocalHum, '15957361339')
                kjAnimTrack.Priority = Enum.AnimationPriority.Action2
                kjAnimTrack:Play()
                kjAnimTrack:AdjustSpeed(Options.AnimeTPSpeed.Value)
            end
            _pHeartbeatTp(destCF)
                    local _Value2 = Options.AnimeTPSound.Value
                    if _Value2 == 'Goku' then
                        local kjSound1 = _pLoadSound(touchFlingLocalRoot, '4861638982')
                        kjSound1.Volume = Options.AnimeTPVolume.Value / 10
                        kjSound1:Play()
                    elseif _Value2 == 'Goku Black' then
                        local kjSound2 = _pLoadSound(touchFlingLocalRoot, '9010221848')
                        kjSound2.Volume = Options.AnimeTPVolume.Value / 10
                        kjSound2:Play()
                        kjSound2.TimePosition = 0.4
                    end
                    pcall(function()
                        local kjEffect = _pRS.Resources.KJEffects.tpthing:Clone()
                        kjEffect.Parent = touchFlingLocalRoot
                        kjEffect:Emit(15)
                        _pDebris:AddItem(kjEffect, 1)
                    end)
                    for _, charPart in pairs(touchFlingLocalChar:GetDescendants()) do
                        if charPart:IsA('BasePart') and charPart ~= touchFlingLocalRoot and charPart.Transparency ~= 1 and not charPart.Name:lower():find('hitbox') then
                            task.spawn(function()
                                charPart.Transparency = 1
                                task.delay(0.1, function()
                                    if getgenv().desync and not touchFlingLocalChar:FindFirstChild('AbsoluteImmortal') then
                                        charPart.Transparency = 0.5
                                    else
                                        charPart.Transparency = 0
                                    end
                                end)
                                local _Decal2 = charPart:FindFirstChildWhichIsA('Decal')
                                if _Decal2 and _Decal2.Transparency ~= 1 then
                                    local _Transparency = _Decal2.Transparency
                                    _Decal2.Transparency = 1
                                    task.wait(0.1)
                                    _Decal2.Transparency = _Transparency
                                end
                            end)
                        end
                    end
        end,
    })
    BoxKeybinds:AddToggle('AnimeTPAnimation', {
        Text = 'Teleport Animation',
        Default = false,
    })
    table.insert(CleanupTasks, function()
        pcall(function() Toggles.AnimeTeleportation:SetValue(false) end)
        pcall(function() Toggles.AnimeTPAnimation:SetValue(false) end)
        pcall(function() Toggles.TP1:SetValue(false) end)
        pcall(function() Toggles.TP2:SetValue(false) end)
    end)
    BoxKeybinds:AddDropdown('AnimeTPSound', {
        Values  = {'None', 'Goku', 'Goku Black'},
        Default = 1,
        Multi   = false,
        Text    = 'Teleport Sound',
    })
    BoxKeybinds:AddSlider('AnimeTPVolume', {
        Text    = 'Sound Volume',
        Default = 10, Min = 1, Max = 10, Rounding = 1,
    })
    BoxKeybinds:AddSlider('AnimeTPSpeed', {
        Text    = 'Animation Speed',
        Default = 1, Min = 0.5, Max = 5, Rounding = 1,
    })
    if not (UIS.TouchEnabled and not UIS.KeyboardEnabled) then
        BoxKeybinds:AddDropdown('AnimeTPMode', {
            Text    = 'TP Mode',
            Values  = { 'Teleport to Mouse', 'Silent Lock' },
            Default = 1,
            Multi   = false,
            Callback = function(val)
                getgenv()._revenantTPMode = val
            end,
        })
        BoxKeybinds:AddLabel('Press F3 to quickly switch between teleport modes.', true)
        _pConns[#_pConns+1] = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.F3 then
                local current = Options.AnimeTPMode and Options.AnimeTPMode.Value
                if current == 'Teleport to Mouse' then
                    getgenv()._revenantTPMode = 'Silent Lock'
                    pcall(function() Options.AnimeTPMode:SetValue('Silent Lock') end)
                    Library:Notify({ Title = 'Anime TP', Content = 'Mode: Silent Lock', Time = 2 })
                else
                    getgenv()._revenantTPMode = 'Teleport to Mouse'
                    pcall(function() Options.AnimeTPMode:SetValue('Teleport to Mouse') end)
                    Library:Notify({ Title = 'Anime TP', Content = 'Mode: Teleport to Mouse', Time = 2 })
                end
            end
        end)
    end
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        BoxKeybinds:AddButton({
            Text = "Anime Teleportation",
            Func = function()
                local myChar = lp.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if not (myChar and myRoot and myHum) then return end
                local closest, closestDist = nil, math.huge
                local center = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lp then
                        local pc = p.Character
                        local pr = pc and pc:FindFirstChild("HumanoidRootPart")
                        local ph = pc and pc:FindFirstChildOfClass("Humanoid")
                        if pc and pr and ph and ph.Health > 0 then
                            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(pr.Position)
                            if onScreen then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closest = pr
                                end
                            end
                        end
                    end
                end
                if closest then
                    _pStopAllAnims(myHum, {'15957361339'})
                    if Toggles.AnimeTPAnimation.Value then
                        local t = _pLoadAnim(myHum, '15957361339')
                        t.Priority = Enum.AnimationPriority.Action2
                        t:Play()
                        t:AdjustSpeed(Options.AnimeTPSpeed.Value)
                    end
                    local destCF = CFrame.new(closest.CFrame.Position - closest.CFrame.LookVector * 5, closest.CFrame.Position)
                    _pHeartbeatTp(destCF)
                end
            end,
        })
    end
    BoxKeybinds:AddToggle('Lock-on', {
        Text    = 'Lock-on',
        Default = false,
        Callback = function(lockOnVal)
            if not lockOnVal then
                if Options['L-OnKeybind']:GetState() == true then
                    Options['L-OnKeybind'].Toggled = false
                    Options['L-OnKeybind']:DoClick()
                else
                    Options['L-OnKeybind'].Toggled = false
                end
            end
        end,
    }):AddKeyPicker('L-OnKeybind', {
        SyncToggleState = false,
        Mode    = 'Toggle',
        Default = 'V',
        Text    = 'Lock-on',
        Callback = function(lockOnRangeVal)
            if _pU525['Lock-on'] then return end
            if lockOnRangeVal and not Toggles['Lock-on'].Value then
                RunService.RenderStepped:Wait()
                _pU525['Lock-on'] = true
                Options['L-OnKeybind'].Toggled = false
                Options['L-OnKeybind']:DoClick()
                _pU525['Lock-on'] = false
                return
            end
            local closestTarget = _pClosestPlayerV2(true)
            if closestTarget and lockOnRangeVal and Toggles['Lock-on'].Value then
                while true do
                    local touchFlingChar = _pGetChar(lp)
                    local tfLocalRoot = touchFlingChar and _pGetRoot(touchFlingChar) or touchFlingChar
                    local tfLocalHum = touchFlingChar and _pGetHum(touchFlingChar)  or touchFlingChar
                    local tfTargetChar = closestTarget and _pGetChar(closestTarget) or closestTarget
                    local tfTargetRoot = tfTargetChar and _pGetRoot(tfTargetChar) or tfTargetChar
                    local tfTargetHum = tfTargetChar and _pGetHum(tfTargetChar)  or tfTargetChar
                    if touchFlingChar and tfLocalRoot and tfLocalHum and closestTarget and tfTargetChar and tfTargetRoot and tfTargetHum and tfLocalHum.Health > 0 then
                        tfLocalHum.AutoRotate = false
                        local tfHighlight = tfTargetChar:FindFirstChildWhichIsA('Highlight') or Instance.new('Highlight', tfTargetChar)
                        tfHighlight.FillTransparency    = 0.8
                        tfHighlight.OutlineTransparency = 0
                        tfHighlight.DepthMode           = 'AlwaysOnTop'
                        tfHighlight.FillColor           = Color3.fromRGB(255, 0, 0)
                        tfHighlight.OutlineColor        = Color3.fromRGB(255, 0, 0)
                        local _Position  = tfLocalRoot.Position
                        local _Position2 = tfTargetRoot.Position
                        local lockOnPrediction = Toggles['Auto_Lock-on_Prediction'].Value and _pStats.Network.ServerStatsItem['Data Ping']:GetValue() / 1000 or Options['Lock-on_Prediction'].Value
                            and _pStats.Network.ServerStatsItem['Data Ping']:GetValue() / 1000
                            or Options['Lock-on_Prediction'].Value
                        local predictedPos = Vector3.new(_Position2.X,
                            _pU59.Flying and _Position2.Y or _Position.Y,
                            _Position2.Z) + tfTargetHum.MoveDirection * tfTargetRoot.Velocity.Magnitude * 0.1
                        if Toggles['Auto_Lock-on_Prediction'].Value then
                            Options['Lock-on_Prediction']:SetValue(tonumber(string.format('%.1f', lockOnPrediction)))
                        end
                        if not touchFlingChar:FindFirstChild('Ragdoll') then
                            tfLocalRoot.CFrame = CFrame.new(_Position, predictedPos)
                        end
                    end
                    RunService.RenderStepped:Wait()
                    if Options['L-OnKeybind']:GetState() == false or (closestTarget and not closestTarget.Parent) or not closestTarget then
                        local lockOnLocalChar = _pGetChar(lp)
                        local lockOnLocalRoot = lockOnLocalChar and _pGetRoot(lockOnLocalChar) or lockOnLocalChar
                        local lockOnLocalHum = lockOnLocalChar and _pGetHum(lockOnLocalChar)  or lockOnLocalChar
                        if lockOnLocalChar and lockOnLocalRoot and lockOnLocalHum then lockOnLocalHum.AutoRotate = true end
                        local lockOnTargetChar = closestTarget and _pGetChar(closestTarget) or closestTarget
                        local lockOnTargetHL = lockOnTargetChar and lockOnTargetChar:FindFirstChildWhichIsA('Highlight') or lockOnTargetChar
                        if closestTarget and lockOnTargetChar and lockOnTargetHL then
                            if _pGetHighestStreak() ~= closestTarget
                                or (10 > (lockOnTargetChar:GetAttribute('CurrentStreak') or 0)
                                or closestTarget:GetAttribute('S_HideStreak')) then
                                lockOnTargetHL.FillTransparency    = 1
                                lockOnTargetHL.OutlineTransparency = 1
                                lockOnTargetHL.DepthMode           = 'Occluded'
                                lockOnTargetHL.FillColor           = Color3.fromRGB(255, 255, 255)
                                lockOnTargetHL.OutlineColor        = Color3.fromRGB(255, 255, 255)
                            else
                                lockOnTargetHL.FillTransparency    = 1
                                lockOnTargetHL.OutlineTransparency = 0
                                lockOnTargetHL.DepthMode           = 'Occluded'
                                lockOnTargetHL.FillColor           = Color3.fromRGB(255, 255, 0)
                                lockOnTargetHL.OutlineColor        = Color3.fromRGB(255, 255, 0)
                            end
                        end
                        break
                    end
                end
            else
                return
            end
        end,
    })
    BoxKeybinds:AddSlider('Lock-on_Prediction', {
        Text    = 'Prediction',
        Default = 0.1, Min = 0.1, Max = 1, Rounding = 1, Compact = true,
    })
    BoxKeybinds:AddToggle('Auto_Lock-on_Prediction', {
        Text    = 'Auto Prediction',
        Default = false,
    })
    BoxKeybinds:AddDivider()
    local _vsNoclipConns  = {}
    local _vsHeartbeat    = nil
    local function _vsNoclipPlayer(char)
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    _vsEnableNoclip = function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lp then
                _vsNoclipConns[p] = p.CharacterAdded:Connect(function(char)
                    task.wait(0.1)
                    _vsNoclipPlayer(char)
                end)
            end
        end
        _vsNoclipConns["_added"] = Players.PlayerAdded:Connect(function(p)
            task.wait(0.1)
            _vsNoclipConns[p] = p.CharacterAdded:Connect(function(char)
                task.wait(0.1)
                _vsNoclipPlayer(char)
            end)
        end)
        _vsHeartbeat = RunService.Heartbeat:Connect(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp and p.Character then
                    for _, part in pairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
    end
    _vsDisableNoclip = function()
        if _vsHeartbeat then _vsHeartbeat:Disconnect() _vsHeartbeat = nil end
        for _, conn in pairs(_vsNoclipConns) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(_vsNoclipConns)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                for _, part in pairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
    local _tfCleanupRef = nil  -- referência para TF_CleanUp (definida no bloco do abaixo)
    local _tfConnRef    = nil  -- referência para _tfConn (para desconectar de fora)
    local _tfRestartFn  = nil  -- recria FloorPart + Heartbeat ao reativar o toggle
    BoxKeybindsLP:AddToggle('TouchFlingEnabled', {
        Text    = 'Touch Fling',
        Tooltip = 'Better with Anti-Fling',
        Default = false,
        Callback = function(val)
            -- raknet is priority: while active, redirect toggle changes to the saved
            -- state, redirect keybind presses while raknet is running.
            -- instead of actually toggling when invis is running.
            if getgenv()._revenantRaknetActive then
                getgenv()._raknetSavedTF = val
                return
            end
            if not val then
                _pU59['Touch Fling'] = false
                -- restaura PhysicsRepRootPart, MoveDirectionInternal e destrói FloorPart
                if _tfCleanupRef then
                    pcall(_tfCleanupRef)
                end
                -- desconecta o Heartbeat por último (cleanup já rodou)
                if _tfConnRef then
                    pcall(function() _tfConnRef:Disconnect() end)
                    _tfConnRef = nil
                end
                -- garante que o keybind também fica desligado
                if Options.TouchFlingBind:GetState() == true then
                    Options.TouchFlingBind.Toggled = false
                    Options.TouchFlingBind:DoClick()
                end
            else
                -- toggle ligado: recria FloorPart + reconecta Heartbeat se necessário
                if _tfRestartFn and not _tfConnRef then
                    pcall(_tfRestartFn)
                end
            end
        end,
    }):AddKeyPicker('TouchFlingBind', {
        SyncToggleState = false,
        Mode    = 'Toggle',
        Default = 'X',
        Text    = 'Touch Fling',
        Callback = function(p)
            if _akbg.TF then return end
            if p and not Toggles.TouchFlingEnabled.Value then
                RunService.RenderStepped:Wait()
                _akbg.TF = true; Options.TouchFlingBind.Toggled = false; Options.TouchFlingBind:DoClick(); _akbg.TF = false
                return
            end
            -- raknet is priority: while it's active redirect keybind presses to the
            -- saved state instead of the live _pU59.
            -- this way the user can still "toggle" TF intent while raknet runs,
            -- and _dStop() will restore to whatever they last set.
            if getgenv()._revenantRaknetActive then
                getgenv()._raknetSavedTF = p
                Library:Notify({ Title = 'Touch Fling', Content = p and 'Toggled on ✅' or 'Toggled off ❌', Time = 2 })
                return
            end
            if Toggles.TouchFlingEnabled.Value then
                _pU59['Touch Fling'] = p
                if not p and _tfCleanupRef then
                    pcall(_tfCleanupRef)
                end
                Library:Notify({ Title = 'Touch Fling', Content = p and 'Toggled on ✅' or 'Toggled off ❌', Time = 2 })
            end
        end,
    })
    local function _tfSetSlidersVisible(visible)
        for _, key in ipairs({'TouchFlingX','TouchFlingY','TouchFlingZ','TouchFlingXInput','TouchFlingYInput','TouchFlingZInput'}) do
            pcall(function()
                if Options[key] and Options[key].SetVisible then
                    Options[key]:SetVisible(visible)
                end
            end)
        end
    end
    local _hasSHP = _shpSupported
    BoxKeybindsLP:AddDropdown('TouchFlingMethod', {
        Text    = 'Method',
        Values  = { 'Normal' , "Death"},
        Default = 1,
        Multi   = false,
        Callback = function(val)
            _tfSetSlidersVisible(val == 'Normal')
        end,
    })
    do
        local DISTANCE_THRESHOLD = 4
        -- Após qualquer respawn o char novo já é garantia de que houve morte.
        local _tfDiedOnce = false
        local _tfDiedHumConn = nil
        local function _tfHookHumanoidDied(char)
            if _tfDiedOnce then return end
            if _tfDiedHumConn then
                pcall(function() _tfDiedHumConn:Disconnect() end)
                _tfDiedHumConn = nil
            end
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            _tfDiedHumConn = hum.Died:Connect(function()
                pcall(function() _tfDiedHumConn:Disconnect() end)
                _tfDiedHumConn = nil
                local _prev = _pU59['Touch Fling']
                _pU59['Touch Fling'] = true
                task.wait(0.5)
                _pU59['Touch Fling'] = _prev
            end)
        end
        _tfHookHumanoidDied(lp.Character)
        lp.CharacterAdded:Connect(function(char)
            _tfDiedOnce = true
        end)

        local FloorPart = nil
        local _tfLastTarget = nil   -- último target rastreado, para nil PhysicsRepRootPart imediatamente ao perder o alvo
        local _tfWasActive = false  -- declarado ANTES do TF_CleanUp para ser capturado como upvalue correto
        local function TF_CleanUp()
            local c = lp.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            -- Salva o target antes de nil-ificar, para poder relimpá-lo no spawn abaixo.
            local savedTarget = _tfLastTarget
            _tfWasActive  = false
            _tfLastTarget = nil

            -- 1. Desvincula o root local PRIMEIRO: uma vez que r.PhysicsRepRootPart = nil,
            --    o FloorPart (variante 2) para de propagar NaN pra r imediatamente.
            --    Velocidades NÃO são zeradas aqui: zerá-las causa parada abrupta no ar ao
            --    desligar o death touch. O Roblox sobrescreve o NaN naturalmente no próximo
            --    frame de física assim que PhysicsRepRootPart volta a nil.
            -- Só reseta o PhysicsRepRootPart local se o Attach não estiver gerenciando-o.
            -- Se WeldActive, o Attach precisa continuar com o link intacto.
            if r and not WeldActive then
                pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", nil) end)
            end
            -- 2. Agora zera e destrói o FloorPart com segurança.
            if FloorPart then
                pcall(function() sethiddenproperty(FloorPart, "PhysicsRepRootPart", nil) end)
                pcall(function() FloorPart.Anchored               = true end)
                pcall(function() FloorPart.AssemblyLinearVelocity  = Vector3.zero end)
                pcall(function() FloorPart.AssemblyAngularVelocity = Vector3.zero end)
                pcall(function() FloorPart.Velocity                = Vector3.zero end)
                pcall(function() FloorPart.RotVelocity             = Vector3.zero end)
                pcall(function() FloorPart.CFrame                  = CFrame.new(0, -10000, 0) end)
                pcall(function() FloorPart:Destroy() end)
                FloorPart = nil
            end
            -- 3. Zera o target completamente (Assembly + legado).
            if savedTarget and savedTarget.Parent then
                pcall(function() sethiddenproperty(savedTarget, "PhysicsRepRootPart", nil) end)
                pcall(function() savedTarget.AssemblyLinearVelocity  = Vector3.zero end)
                pcall(function() savedTarget.AssemblyAngularVelocity = Vector3.zero end)
                pcall(function() savedTarget.Velocity                = Vector3.zero end)
                pcall(function() savedTarget.RotVelocity             = Vector3.zero end)
            end
            -- 4. Spawn de 1 frame: o heartbeat ainda pode ter escrito NaN nesse frame,
            --    então um único passe no frame seguinte garante que tudo foi sobrescrito.
            --    Sem ChangeState(GettingUp): causaria lentidão momentânea ao desligar.
            task.spawn(function()
                RunService.Heartbeat:Wait()
                if WeldActive then return end
                local c2 = lp.Character
                local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                local h2 = c2 and c2:FindFirstChildOfClass("Humanoid")
                if r2 then
                    -- Apenas desvincula PhysicsRepRootPart; NÃO zera velocidades do player
                    -- local para evitar parada abrupta no ar ao desligar o death touch.
                    pcall(function() sethiddenproperty(r2, "PhysicsRepRootPart", nil) end)
                end
                if h2 then
                    pcall(function() h2:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                end
                -- Relimpa o target 1 frame depois também: NaN pode ter ficado de um
                -- frame intermediário caso o target tenha sido trocado no último heartbeat.
                if savedTarget and savedTarget.Parent then
                    pcall(function() sethiddenproperty(savedTarget, "PhysicsRepRootPart", nil) end)
                    pcall(function() savedTarget.AssemblyLinearVelocity  = Vector3.zero end)
                    pcall(function() savedTarget.AssemblyAngularVelocity = Vector3.zero end)
                    pcall(function() savedTarget.Velocity                = Vector3.zero end)
                    pcall(function() savedTarget.RotVelocity             = Vector3.zero end)
                end
            end)
        end
        _tfCleanupRef = TF_CleanUp

        -- Função do método antigo: busca target próximo
        local function TF_GetNearbyTarget(root)
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= lp and v.Character then
                    local vr = v.Character:FindFirstChild("HumanoidRootPart")
                    local vh = v.Character:FindFirstChild("Humanoid")
                    if vr and vr.Parent and vh and vh.Health > 0 then
                        if (vr.Position - root.Position).Magnitude <= DISTANCE_THRESHOLD then
                            return vr
                        end
                    end
                end
            end
        end

        local function TF_CreateFloor()
            local p = Instance.new("Part")
            p.Size = Vector3.new(8, 0.2, 8)
            p.Transparency = 1
            p.CanCollide = false
            p.Name = game:GetService("HttpService"):GenerateGUID()
            p.Parent = workspace
            return p
        end
        local function _tfHeartbeatBody()
            if Library.Unloaded then
                TF_CleanUp()
                if _tfConnRef then _tfConnRef:Disconnect() _tfConnRef = nil end
                return
            end
            local method = Options.TouchFlingMethod and Options.TouchFlingMethod.Value or 'Normal'
            local shouldRun = _pU59['Touch Fling'] and method == 'Death'
            if not shouldRun then
                if _tfWasActive then
                    TF_CleanUp()
                    _tfWasActive = false
                end
                return
            end
            if FlingActive then
                if _tfWasActive then TF_CleanUp() _tfWasActive = false end
                return
            end
            _tfWasActive = true
            local c = lp.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if not (c and r and h) or h.Health <= 0 then TF_CleanUp() return end
            local Nan = 0/0
            local NanVec = Vector3.new(Nan, Nan, Nan)
            if not FloorPart then FloorPart = TF_CreateFloor() end

            if method == 'Death' then
            if not _tfDiedOnce then
                -- ========== DEATH: sem restart (com distance threshold) ==========
                local Target = TF_GetNearbyTarget(r)
                if Target ~= _tfLastTarget then
                    if _tfLastTarget and _tfLastTarget.Parent then
                        pcall(function() sethiddenproperty(_tfLastTarget, "PhysicsRepRootPart", nil) end)
                        pcall(function() _tfLastTarget.AssemblyLinearVelocity  = Vector3.zero end)
                        pcall(function() _tfLastTarget.AssemblyAngularVelocity = Vector3.zero end)
                        pcall(function() _tfLastTarget.Velocity                = Vector3.zero end)
                        pcall(function() _tfLastTarget.RotVelocity             = Vector3.zero end)
                    end
                    -- Só reseta o PhysicsRepRootPart local se o Attach não estiver no controle
                    if not WeldActive then
                        pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", nil) end)
                    end
                    _tfLastTarget = Target
                end
                if Target and Target.Parent then
                    -- Quando o Attach está ativo ele já gerencia o PhysicsRepRootPart do root
                    -- local; apenas aplicamos o NanVec para matar via o link existente.
                    if not WeldActive then
                        pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", Target) end)
                    end
                    sethiddenproperty(h, "MoveDirectionInternal", NanVec)
                    r.AssemblyLinearVelocity  = NanVec
                    r.AssemblyAngularVelocity = NanVec
                else
                    if FloorPart then
                        pcall(function() sethiddenproperty(FloorPart, "PhysicsRepRootPart", nil) end)
                        pcall(function() FloorPart.AssemblyLinearVelocity  = Vector3.zero end)
                        pcall(function() FloorPart.AssemblyAngularVelocity = Vector3.zero end)
                        FloorPart.Anchored = true
                        FloorPart.CFrame = CFrame.new(0, -1000, 0)
                    end
                end
            else
                -- ========== DEATH: após restart (sem distance threshold, sempre ativo) ==========
                local Target = TF_GetNearbyTarget(r)
                if Target ~= _tfLastTarget then
                    if _tfLastTarget and _tfLastTarget.Parent then
                        pcall(function() sethiddenproperty(_tfLastTarget, "PhysicsRepRootPart", nil) end)
                        pcall(function() _tfLastTarget.AssemblyLinearVelocity  = Vector3.zero end)
                        pcall(function() _tfLastTarget.AssemblyAngularVelocity = Vector3.zero end)
                        pcall(function() _tfLastTarget.Velocity                = Vector3.zero end)
                        pcall(function() _tfLastTarget.RotVelocity             = Vector3.zero end)
                    end
                    -- Só reseta o PhysicsRepRootPart local se o Attach não estiver no controle
                    if not WeldActive then
                        pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", nil) end)
                    end
                    _tfLastTarget = Target
                end
                if Target and Target.Parent then
                    FloorPart.Anchored = false
                    FloorPart.CFrame = Target.CFrame * CFrame.new(0, -3.2, 0)
                    -- Quando o Attach está ativo ele já gerencia o PhysicsRepRootPart do root
                    -- local; apenas aplicamos o NanVec para matar via o link existente.
                    if not WeldActive then
                        pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", Target) end)
                    end
                    sethiddenproperty(h, "MoveDirectionInternal", NanVec)
                    r.AssemblyLinearVelocity  = NanVec
                    r.AssemblyAngularVelocity = NanVec
                    FloorPart.AssemblyLinearVelocity  = NanVec
        mblyAngularVelocity = NanVec
                else
                    FloorPart.Anchored = false
                    FloorPart.CFrame = r.CFrame * CFrame.new(0, -3.2, 0)
                    -- Só usa FloorPart como âncora se o Attach não estiver controlando
                    if not WeldActive then
                        pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", FloorPart) end)
                    end
                    sethiddenproperty(h, "MoveDirectionInternal", NanVec)
                    r.AssemblyLinearVelocity  = NanVec
                    r.AssemblyAngularVelocity = NanVec
                    FloorPart.AssemblyLinearVelocity  = NanVec
                    FloorPart.AssemblyAngularVelocity = NanVec
                end
            end
            end -- if method == 'Death'
        end

        -- Inicia (ou reinicia) o Heartbeat + FloorPart — chamado ao ligar o toggle
        local function _tfStart()
            if not FloorPart then FloorPart = TF_CreateFloor() end
            if not _tfConnRef then
                _tfConnRef = RunService.RenderStepped:Connect(_tfHeartbeatBody)
            end
        end
        _tfRestartFn = _tfStart  -- expõe para o callback do toggle (fora do do-block)

        -- Não inicia automaticamente ao carregar: o toggle começa desligado (Default=false).
        -- Se um config autoload ligar o toggle, o Callback(true) chamará _tfRestartFn.
        table.insert(CleanupTasks, function()
            TF_CleanUp()
            if _tfConnRef then _tfConnRef:Disconnect() _tfConnRef = nil end
            if _tfDiedHumConn then pcall(function() _tfDiedHumConn:Disconnect() end) _tfDiedHumConn = nil end
        end)
    end
    BoxKeybindsLP:AddInput('TouchFlingXInput', {
        Text = 'X Value',
        Default = '0',
        Numeric = true,
        Finished = false,
        Callback = function(val)
            local n = tonumber(val)
            if n then
                _pU59['Touch Fling Settings'] = Vector3.new(n, _pU59['Touch Fling Settings'].Y, _pU59['Touch Fling Settings'].Z)
                if Options.TouchFlingX and Options.TouchFlingX.SetValue then
                    pcall(function() Options.TouchFlingX:SetValue(math.clamp(n, 0, 1e38)) end)
                end
            end
        end,
    })
    BoxKeybindsLP:AddSlider('TouchFlingX', {
        Text = 'X', Default = 0, Min = 0, Max = 1e38, Rounding = 1, Compact = true,
        Callback = function(tfX)
            _pU59['Touch Fling Settings'] = Vector3.new(tfX, _pU59['Touch Fling Settings'].Y, _pU59['Touch Fling Settings'].Z)
        end,
    })
    BoxKeybindsLP:AddInput('TouchFlingYInput', {
        Text = 'Y Value',
        Default = '0',
        Numeric = true,
        Finished = false,
        Callback = function(val)
            local n = tonumber(val)
            if n then
                _pU59['Touch Fling Settings'] = Vector3.new(_pU59['Touch Fling Settings'].X, n, _pU59['Touch Fling Settings'].Z)
                if Options.TouchFlingY and Options.TouchFlingY.SetValue then
                    pcall(function() Options.TouchFlingY:SetValue(math.clamp(n, 0, 1e38)) end)
                end
            end
        end,
    })
    BoxKeybindsLP:AddSlider('TouchFlingY', {
        Text = 'Y', Default = 0, Min = 0, Max = 1e38, Rounding = 1, Compact = true,
        Callback = function(tfY)
            _pU59['Touch Fling Settings'] = Vector3.new(_pU59['Touch Fling Settings'].X, tfY, _pU59['Touch Fling Settings'].Z)
        end,
    })
    BoxKeybindsLP:AddInput('TouchFlingZInput', {
        Text = 'Z Value',
        Default = '0',
        Numeric = true,
        Finished = false,
        Callback = function(val)
            local n = tonumber(val)
            if n then
                _pU59['Touch Fling Settings'] = Vector3.new(_pU59['Touch Fling Settings'].X, _pU59['Touch Fling Settings'].Y, n)
                if Options.TouchFlingZ and Options.TouchFlingZ.SetValue then
                    pcall(function() Options.TouchFlingZ:SetValue(math.clamp(n, 0, 1e38)) end)
                end
            end
        end,
    })
    BoxKeybindsLP:AddSlider('TouchFlingZ', {
        Text = 'Z', Default = 0, Min = 0, Max = 1e38, Rounding = 1, Compact = true,
        Callback = function(tfZ)
            _pU59['Touch Fling Settings'] = Vector3.new(_pU59['Touch Fling Settings'].X, _pU59['Touch Fling Settings'].Y, tfZ)
        end,
    })
    -- esconde sliders por padrão (método default é Death)
    -- Método padrão é 'Normal', então sliders aparecem sempre no load
    task.defer(function() _tfSetSlidersVisible(true) end)
    BoxKeybindsLP:AddDivider()
    local TogWeld = BoxKeybindsLP:AddToggle("TogWeld", {
        Text = _shpSupported and "Attach" or "Orbit", Default = false,
        Callback = function(weldToggleVal)
            if _pU525.Weld then return end
            if not weldToggleVal then
                if Options.KPWeld then Options.KPWeld.Toggled = false end
                if WeldActive then toggleWeld() end
            end
        end,
    })
    TogWeld:AddKeyPicker("KPWeld", {
        Default = "H", Text = _shpSupported and "Attach" or "Orbit", SyncToggleState = false, Mode = "Toggle", NoUI = false,
        Callback = function(kpVal)
            if _pU525.Weld then return end
            -- Keybind pressionada mas toggle desligado: aborta e reseta estado
            if kpVal and not Toggles.TogWeld.Value then
                RunService.RenderStepped:Wait()
                _pU525.Weld = true
                Options.KPWeld.Toggled = false
                Options.KPWeld:DoClick()
                _pU525.Weld = false
                return
            end
            if not Toggles.TogWeld.Value then return end
            if isChatFocused() then return end
            toggleWeld()
        end,
    })
    if _shpSupported then
        BoxKeybindsLP:AddDropdown("AttachMethod", {
            Text    = "Method",
            Values  = { "Strength", "Hitbox Accurate", "Orbit" },
            Default = "Strength",
            Callback = function(val)
                local isOrbit = val == "Orbit"
                pcall(function() Options.WeldOffsetX:SetVisible(not isOrbit) end)
                pcall(function() Options.WeldOffsetY:SetVisible(not isOrbit) end)
                pcall(function() Options.WeldOffsetZ:SetVisible(not isOrbit) end)
                pcall(function() Options.AttachOrbitSpeed:SetVisible(isOrbit) end)
                pcall(function() Options.AttachOrbitDistance:SetVisible(isOrbit) end)
            end,
        })
        BoxKeybindsLP:AddSlider("WeldOffsetX", { Text = "Attach X", Default = 0, Min = -25, Max = 25, Rounding = 0 })
        BoxKeybindsLP:AddSlider("WeldOffsetY", { Text = "Attach Y", Default = 0, Min = -25, Max = 25, Rounding = 0 })
        BoxKeybindsLP:AddSlider("WeldOffsetZ", { Text = "Attach Z", Default = 0, Min = -25, Max = 25, Rounding = 0 })
        BoxKeybindsLP:AddSlider("AttachOrbitSpeed", {
            Text     = "Orbit Speed",
            Default  = 10,
            Min      = 1,
            Max      = 100,
            Rounding = 1,
        })
        BoxKeybindsLP:AddSlider("AttachOrbitDistance", {
            Text     = "Orbit Distance",
            Default  = 3,
            Min      = 1,
            Max      = 100,
            Rounding = 1,
        })
        -- Orbit sliders começam escondidos (método padrão é Strength)
        task.defer(function()
            pcall(function() Options.AttachOrbitSpeed:SetVisible(false) end)
            pcall(function() Options.AttachOrbitDistance:SetVisible(false) end)
        end)
    else
        -- Sem sethiddenproperty: attach usa orbit, mostrar apenas sliders de orbit (igual Phantasm)
        BoxKeybindsLP:AddSlider('OrbitSpeed', {
            Text     = 'Orbit Speed',
            Default  = 10,
            Min      = 1,
            Max      = 100,
            Rounding = 1,
        })
        BoxKeybindsLP:AddSlider('OrbitDistance', {
            Text     = 'Orbit Distance',
            Default  = 3,
            Min      = 1,
            Max      = 100,
            Rounding = 1,
        })
    end
    BoxKeybindsLP:AddDivider()
    -- Teleport 1
    local _TogTP1 = BoxKeybindsLP:AddToggle('TP1', {
        Text    = 'Teleport 1',
        Default = false,
        Callback = function(val)
            if not val and Options.TP1Bind:GetState() == true then
                Options.TP1Bind.Toggled = false
                Options.TP1Bind:DoClick()
            end
            pcall(function() Options.TP1Bind.KeybindsToggle:SetVisibility(val) end)
        end,
    })
    _TogTP1:AddKeyPicker('TP1Bind', {
        SyncToggleState = false,
        Mode    = 'Toggle',
        Default = 'E',
        Text    = 'Teleport 1',
        Callback = function()
            Options.TP1Bind.Toggled = false
            if not Toggles.TP1 or not Toggles.TP1.Value then return end
            local c = _pGetChar(lp)
            local r = c and _pGetRoot(c)
            local h = c and _pGetHum(c)
            if c and r and h and h.Health > 0 then
                local dest = r.CFrame * CFrame.new(Options.TP1X.Value, Options.TP1Y.Value, Options.TP1Z.Value)
                _pHeartbeatTp(dest)
            end
        end,
    })
    BoxKeybindsLP:AddSlider('TP1X', { Text = 'X', Default = 0,  Min = -25, Max = 25, Rounding = 1, Compact = true })
    BoxKeybindsLP:AddSlider('TP1Y', { Text = 'Y', Default = 0,  Min = -25, Max = 25, Rounding = 1, Compact = true })
    BoxKeybindsLP:AddSlider('TP1Z', { Text = 'Z', Default = 20, Min = -25, Max = 25, Rounding = 1, Compact = true })
    BoxKeybindsLP:AddDivider()
    -- Teleport 2
    local _TogTP2 = BoxKeybindsLP:AddToggle('TP2', {
        Text    = 'Teleport 2',
        Default = false,
        Callback = function(val)
            if not val and Options.TP2Bind:GetState() == true then
                Options.TP2Bind.Toggled = false
                Options.TP2Bind:DoClick()
            end
            pcall(function() Options.TP2Bind.KeybindsToggle:SetVisibility(val) end)
        end,
    })
    _TogTP2:AddKeyPicker('TP2Bind', {
        SyncToggleState = false,
        Mode    = 'Toggle',
        Default = 'R',
        Text    = 'Teleport 2',
        Callback = function()
            Options.TP2Bind.Toggled = false
            if not Toggles.TP2 or not Toggles.TP2.Value then return end
            local c = _pGetChar(lp)
            local r = c and _pGetRoot(c)
            local h = c and _pGetHum(c)
            if c and r and h and h.Health > 0 then
                local dest = r.CFrame * CFrame.new(Options.TP2X.Value, Options.TP2Y.Value, Options.TP2Z.Value)
                _pHeartbeatTp(dest)
            end
        end,
    })
    BoxKeybindsLP:AddSlider('TP2X', { Text = 'X', Default = 0,   Min = -25, Max = 25, Rounding = 1, Compact = true })
    BoxKeybindsLP:AddSlider('TP2Y', { Text = 'Y', Default = 0,   Min = -25, Max = 25, Rounding = 1, Compact = true })
    BoxKeybindsLP:AddSlider('TP2Z', { Text = 'Z', Default = -20, Min = -25, Max = 25, Rounding = 1, Compact = true })
    task.defer(function()
        pcall(function() Options.TP1Bind.KeybindsToggle:SetVisibility(false) end)
        pcall(function() Options.TP2Bind.KeybindsToggle:SetVisibility(false) end)
    end)
    if isGamepassesGame then
        BoxDashes:AddToggle('CustomFrontDash', {
            Text    = 'Custom Front Dash',
            Default = false,
        })
        BoxDashes:AddSlider('FDDistance', {
            Text    = 'Front Dash Distance',
            Default = 165, Min = 0, Max = 500, Rounding = 1,
        })
        BoxDashes:AddToggle('CustomSideDash', {
            Text    = 'Custom Side Dash',
            Default = false,
        })
        BoxDashes:AddSlider('SDDistance', {
            Text    = 'Side Dash Distance (Multiplier)',
            Default = 1, Min = 0.1, Max = 2, Rounding = 1,
        })
        BoxDashes:AddSlider('SDSpeed', {
            Text    = 'Side Dash Speed',
            Default = 1, Min = 0.1, Max = 2, Rounding = 1,
            Tooltip = "Recommended with custom side dash speed set to 1.4.",
        })
        BoxDashes:AddToggle('CustomBackDash', {
            Text    = 'Custom Back Dash',
            Default = false,
        })
        BoxDashes:AddSlider('BDDistance', {
            Text    = 'Back Dash Distance (Multiplier)',
            Default = 1, Min = 0.1, Max = 2, Rounding = 1,
        })
        BoxDashes:AddButton({
            Text = 'Reset to Defaults',
            Func = function()
                Options.FDDistance:SetValue(165)
                Options.SDDistance:SetValue(1)
                Options.SDSpeed:SetValue(1)
                Options.BDDistance:SetValue(1)
            end,
        })
        local function _pInit(_)
            for _, conn in pairs(_pCharConns) do conn:Disconnect() end
            table.clear(_pCharConns)
            if _pClone then _pClone:Destroy() _pClone = nil end
            repeat task.wait()
            until _pGetChar(lp) and _pGetRoot(_pGetChar(lp)) and _pGetHum(_pGetChar(lp))
            local localChar = _pGetChar(lp)
            local localRoot = localChar and _pGetRoot(localChar) or localChar
            local localHum = localChar and _pGetHum(localChar)  or localChar
            if localChar and localRoot and localHum then
                local bvCloneList = {}
                _pCharConns[#_pCharConns+1] = localChar.DescendantAdded:Connect(function(descendant)
                    if descendant:IsA("Sound") and descendant.SoundId:match("16139753098")
                       and rawget(Options.AntiMoves_Tatsumaki.Value, "Anti Crushing Pull") then
                        local t = tick()
                        repeat
                            _pCommunicate({ Goal = "KeyPress", Key = Enum.KeyCode.F })
                            RunService.RenderStepped:Wait()
                        until tick() >= t + 0.5
                        _pCommunicate({ Goal = "KeyRelease", Key = Enum.KeyCode.F })
                    elseif _pU59["Upside Down"] and localHum and localHum.Health > 0 then
                    elseif descendant:IsA("Accessory") then
                        if table.find({"Slowed","StopRunning","ComboStun"}, descendant.Name) and rawget(Options.CharacterExploits.Value, "No Slow") then
                            if descendant.Name ~= "Slowed" then
                                if descendant.Name == "StopRunning" or descendant.Name == "ComboStun" then
                                    _pDeleteNew(descendant, false)
                                end
                            else
                                local v1015 = localHum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                                    localHum.WalkSpeed = localChar:GetAttribute("Ulted") and (localChar:GetAttribute("Running") and 32 or 16) or (localChar:GetAttribute("Running") and 25 or 16)
                                end)
                                localHum.WalkSpeed = localChar:GetAttribute("Ulted") and (localChar:GetAttribute("Running") and 32 or 16) or (localChar:GetAttribute("Running") and 25 or 16)
                                repeat RunService.RenderStepped:Wait() until descendant.Parent ~= localChar
                                v1015:Disconnect()
                            end
                        elseif (descendant.Name == "Freeze" or descendant.Name == "AntiMove") and rawget(Options.CharacterExploits.Value, "No Stun") then
                            local v1016 = localHum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                                localHum.WalkSpeed = localChar:GetAttribute("Ulted") and (localChar:GetAttribute("Running") and 32 or 16) or (localChar:GetAttribute("Running") and 25 or 16)
                            end)
                            localHum.WalkSpeed = localChar:GetAttribute("Ulted") and (localChar:GetAttribute("Running") and 32 or 16) or (localChar:GetAttribute("Running") and 25 or 16)
                            repeat RunService.RenderStepped:Wait() until descendant.Parent ~= localChar
                            v1016:Disconnect()
                        elseif descendant.Name ~= "NoJump" or not rawget(Options.CharacterExploits.Value, "No Jump Bypass") then
                            if (descendant.Name == "NoRotate" or desceame == "NoRotate" or descendant.Name == "NoRotateUltimate") and rawget(Options.CharacterExploits.Value, "No Rotations Bypass") then
                                task.spawn(pcall, _pDeleteNew, descendant, false)
                            elseif descendant.Name ~= "Ragdoll" then
                                if descendant.Name ~= "RagdollSim" then
                                    if descendant.Name ~= "BeingLaunched" then
                                        if descendant.Name == "ThrowTrashcan" then
                                            _pU59["Trashcan Launch"] = true
                                            task.wait(0.25)
                                            _pU59["Trashcan Launch"] = false
                                        end
                                    elseif Toggles.LaunchHide.Value and localHum.Health > 0 and not localChar:FindFirstChild("ExtraHitbox") then
                                        local v1017 = tick()
                                        repeat
                                            getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                                            task.wait()
                                        until tick() >= v1017 + 3 or (localChar:FindFirstChild("LaunchEnded") or localHum.Health <= 0)
                                        getgenv().desync = nil
                                    end
                                elseif rawget(Options.CharacterExploits.Value, "Anti Ragdoll") then
                                    task.spawn(pcall, _pDeleteNew, descendant, false)
                                end
                            else
                                if rawget(Options.CharacterExploits.Value, "Anti Ragdoll") then
                                    descendant:Remove()
                                end
                                if Toggles.RagdollHide.Value and localHum.Health > 0 and not localChar:FindFirstChild("ExtraHitbox") then
                                    task.spawn(function()
                                        repeat
                                            getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
                                            task.wait()
                                        until not Toggles.RagdollHide.Value or descendant.Parent ~= localChar or localHum.Health <= 0
                                        getgenv().desync = nil
                                    end)
                                end
                                if Toggles.AutoRagdollCancel.Value then
                                    _pCommunicate({ Dash = Enum.KeyCode.S, Key = Enum.KeyCode.Q, Goal = "KeyPress" })
                                end

                            end
                        else
                            task.spawn(pcall, _pDeleteNew, descendant, false)
                        end
                    end
                    if descendant:IsA('BodyVelocity') then
                        if descendant.Name ~= 'moveme' or (descendant:GetAttribute('Speed') or 0) ~= 165 then
                            if descendant.Name == 'dodgevelocity' and not descendant:GetAttribute('Clone') then
                                RunService.Stepped:Wait()
                                for _, dashTrack in pairs(localHum:GetPlayingAnimationTracks()) do
                                    if dashTrack.Animation.AnimationId:match('10491993682') and dashTrack.TimePosition <= 0.1 then
                                        if Toggles.CustomBackDash.Value then
                                            local bdClone = descendant:Clone()
                                            bdClone:SetAttribute('Clone', true)
                                            table.insert(_pCloneList, bdClone)
                                            descendant.Parent = workspace
                                            while descendant and descendant.Parent do
                                                bdClone.Parent   = localRoot
                                                bdClone.Velocity = descendant.Velocity * Options.BDDistance.Value
                                                RunService.RenderStepped:Wait()
                                            end
                                            if bdClone and bdClone.Parent then
                                                bdClone:Destroy()
                                                local idx = table.find(_pCloneList, bdClone)
                                                if idx then table.remove(_pCloneList, idx) end
                                            end
                                        end
                                        return
                                    end
                                end
                                if Toggles.CustomSideDash.Value then
                                    local sdClone = descendant:Clone()
                                    sdClone:SetAttribute('Clone', true)
                                    table.insert(_pCloneList, sdClone)
                                    descendant.Parent = workspace
                                    while descendant and descendant.Parent do
                                        sdClone.Parent   = localRoot
                                        sdClone.Velocity = descendant.Velocity * Options.SDDistance.Value
                                        RunService.RenderStepped:Wait()
                                    end
                                    if sdClone and sdClone.Parent then
                                        sdClone:Destroy()
                                        local idx = table.find(_pCloneList, sdClone)
                                        if idx then table.remove(_pCloneList, idx) end
                                    end
                                end
                            end
                        else
                            if Toggles.CustomFrontDash.Value then
                                descendant:SetAttribute('Speed', Options.FDDistance.Value)
                            end
                            for _, cloneItem in pairs(_pCloneList) do cloneItem:Destroy() end
                            table.clear(_pCloneList)
                        end
                    end
                    -- [PHANTASM] NoBP: remove BodyPositions de moves bypassed (lógica idêntica ao Phantasm)
                    if descendant:IsA('BodyPosition') then
                        if descendant.Name ~= 'AIRBP' or (descendant.D ~= 800 or (descendant.P ~= 10000 or (descendant.MaxForce ~= Vector3.new(1,1,1) * 40000 or not Toggles.NoBP_WindstormFury.Value))) then
                            if descendant.Name ~= 'AIRBP' or (descendant.D ~= 800 or (descendant.P ~= 10000 or (descendant.MaxForce ~= Vector3.new(1,1,1) * 40000 or (descendant:GetAttribute('SpinCenter') == nil or not Toggles.NoBP_TatsumakiUlt.Value)))) then
                                if descendant.Name == 'AIRBP' and (descendant.D == 850 and (descendant.P == 10000 and (descendant.MaxForce == Vector3.new(1,1,1) * 40000 and Toggles.NoBP_PreysPeril.Value))) then
                                    task.spawn(pcall, _pDeleteNew, descendant, false)
                                end
                            else
                                task.spawn(pcall, _pDeleteNew, descendant, false)
                            end
                        else
                            task.spawn(pcall, _pDeleteNew, descendant, false)
                        end
                    end
                    if descendant.Name == 'ThrowTrashcan' then
                        _pU59['Trashcan Launch'] = true
                        task.delay(0.25, function()
                            _pU59['Trashcan Launch'] = false
                        end)
                    end
                    if descendant:IsA('Accessory') then
                        if descendant.Name == 'Ragdoll' then
                            if Toggles.AutoRagdollCancel.Value then
                                _pCommunicate({
                                    Dash = Enum.KeyCode.S,
                                    Key  = Enum.KeyCode.Q,
                                    Goal = 'KeyPress',
                                })
                            end
                        end
                    end
                end)
                _pCharConns[#_pCharConns+1] = localHum.AnimationPlayed:Connect(function(animTrack)
                    local _AnimationId = animTrack.Animation.AnimationId
                    if _AnimationId:match('10480796021') or _AnimationId:match('10480793962') then
                        if Toggles.CustomSideDash.Value then
                            animTrack:AdjustSpeed(Options.SDSpeed.Value)
                        end
                    end
                end)
                _pCharConns[#_pCharConns+1] = localHum.AnimationPlayed:Connect(function(animTrack)
                    local _AnimationId = animTrack.Animation.AnimationId
                    if not Toggles.AttackAll.Value then return end
                    local function _aaIsFavoredCharacterTarget(target)
                        if not target or not target:IsA("Player") then return false end
                        local char = _pGetChar(target)
                        local charName = char and char:GetAttribute("Character")
                        if type(charName) ~= "string" then return false end
                        charName = charName:lower()
                        return charName == "hunter" or charName == "blade" or charName:find("zombie", 1, true) ~= nil
                    end
                    local function _bringAllAnchor(shouldAnchor)
                        local conn
                        conn = RunService.Heartbeat:Connect(function()
                            if not shouldAnchor() then
                                conn:Disconnect()
                                return
                            end
                            local r = _pGetRoot(_pGetChar(lp))
                            if r then
                                r.AssemblyLinearVelocity  = Vector3.new()
                                r.AssemblyAngularVelocity = Vector3.new()
                            end
                        end)
                        return conn
                    end
                    -- Attack All: attach/detach — estilo Welder
                    local _aaCurrentConn = nil
                    local _aaRotConn     = nil
                    local _aaMyRoot      = nil
                    local _aaTargetRoot  = nil

                    local function _aaDetach()
                        if _aaCurrentConn then
                            _aaCurrentConn:Disconnect()
                            _aaCurrentConn = nil
                        end
                        if _aaRotConn then
                            _aaRotConn:Disconnect()
                            _aaRotConn = nil
                        end
                        -- reseta PhysicsRepRootPart de volta pra nil antes de soltar
                        if sethiddenproperty then
                            if _aaMyRoot and _aaMyRoot.Parent then
                                pcall(function() sethiddenproperty(_aaMyRoot, "PhysicsRepRootPart", nil) end)
                            end
                            if _aaTargetRoot and _aaTargetRoot.Parent then
                                pcall(function() sethiddenproperty(_aaTargetRoot, "PhysicsRepRootPart", nil) end)
                            end
                        end
                        if _aaMyRoot and _aaMyRoot.Parent then
                            _aaMyRoot.CFrame                  = CFrame.new(_aaMyRoot.Position)
                            _aaMyRoot.AssemblyLinearVelocity  = Vector3.zero
                            _aaMyRoot.AssemblyAngularVelocity = Vector3.zero
                            pcall(function() _aaMyRoot.Velocity    = Vector3.zero end)
                            pcall(function() _aaMyRoot.RotVelocity = Vector3.zero end)
                            local _detachHum = _aaMyRoot.Parent:FindFirstChildOfClass("Humanoid")
                            if _detachHum then pcall(function() _detachHum.AutoRotate = true end) end
                        end
                        _aaMyRoot     = nil
                        _aaTargetRoot = nil
                    end

                    local function _aaEnd()
                        _aaDetach()
                    end

                    local function _aaAttach(myRoot, targetRoot)
                        if _aaCurrentConn then
                            _aaCurrentConn:Disconnect()
                            _aaCurrentConn = nil
                        end
                        if _aaMyRoot and _aaMyRoot.Parent then
                            _aaMyRoot.AssemblyLinearVelocity  = Vector3.zero
                            _aaMyRoot.AssemblyAngularVelocity = Vector3.zero
                            pcall(function() _aaMyRoot.Velocity    = Vector3.zero end)
                            pcall(function() _aaMyRoot.RotVelocity = Vector3.zero end)
                        end
                        if not myRoot or not targetRoot then return end
                        _aaMyRoot     = myRoot
                        _aaTargetRoot = targetRoot
                        -- Keep AutoRotate set to false on every RenderStepped, consistent with lock-on behaviour.
                        if _aaRotConn then _aaRotConn:Disconnect() _aaRotConn = nil end
                        local _rotHum = myRoot.Parent and myRoot.Parent:FindFirstChildOfClass("Humanoid")
                        if _rotHum then
                            _aaRotConn = RunService.RenderStepped:Connect(function()
                                if _rotHum and _rotHum.Parent then
                                    pcall(function() _rotHum.AutoRotate = false end)
                                end
                            end)
                        end
                        -- TP imediato 5 studs atrás do alvo
                        myRoot.CFrame                  = targetRoot.CFrame * CFrame.new(0, 0, 5)
                        myRoot.AssemblyLinearVelocity  = Vector3.zero
                        myRoot.AssemblyAngularVelocity = Vector3.zero
                        if sethiddenproperty then
                            pcall(function() sethiddenproperty(myRoot, "PhysicsRepRootPart", myRoot) end)
                            pcall(function() sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot) end)
                        end
                        -- heartbeat contínuo
                        local _selfConn
                        _selfConn = RunService.Heartbeat:Connect(function()
                            if not myRoot or not myRoot.Parent
                            or not targetRoot or not targetRoot.Parent then
                                _selfConn:Disconnect()
                                if _aaCurrentConn == _selfConn then _aaCurrentConn = nil end
                                if sethiddenproperty then
                                    if myRoot and myRoot.Parent then
                                        pcall(function() sethiddenproperty(myRoot, "PhysicsRepRootPart", nil) end)
                                    end
                                    if targetRoot and targetRoot.Parent then
                                        pcall(function() sethiddenproperty(targetRoot, "PhysicsRepRootPart", nil) end)
                                    end
                                end
                                if myRoot and myRoot.Parent then
                                    myRoot.AssemblyLinearVelocity  = Vector3.zero
                                    myRoot.AssemblyAngularVelocity = Vector3.zero
                                    pcall(function() myRoot.Velocity    = Vector3.zero end)
                                    pcall(function() myRoot.RotVelocity = Vector3.zero end)
                                end
                                return
                            end
                            myRoot.CFrame                  = targetRoot.CFrame * CFrame.new(0, 0, 5)
                            myRoot.AssemblyLinearVelocity  = Vector3.zero
                            myRoot.AssemblyAngularVelocity = Vector3.zero
                            if sethiddenproperty then
                                pcall(function() sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot) end)
                            end
                        end)
                        _aaCurrentConn = _selfConn
                    end
                    if _AnimationId:match('14719290328') and rawget(Options.AttackAllMoves.Value, 'Savage Tornado') then
                        task.spawn(function()
                            local myChar = _pGetChar(lp)
                            local myRoot = myChar and _pGetRoot(myChar)
                            if not myRoot then return end
                            local savedCF = myRoot.CFrame
                            RunService.Heartbeat:Once(function() myRoot.CFrame = CFrame.new(0, -10000, 0) end)
                            task.wait(0.9)
                            local t = tick()
                            repeat
                                _pGrabRandom(true)
                                task.wait(0.03)
                            until tick() >= t + 1.75
                            game:GetService("TweenService"):Create(myRoot, TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                                CFrame = CFrame.new(352, 438, 392),
                            }):Play()
                            task.wait(1.5)
                            RunService.Heartbeat:Once(function() myRoot.CFrame = savedCF end)
                        end)
                    end
                    if _AnimationId:match('14701242661') and rawget(Options.AttackAllMoves.Value, 'Brutal Beatdown') then
                        task.spawn(function()
                            local myChar = _pGetChar(lp)
                            local myRoot = myChar and _pGetRoot(myChar)
                            if not myRoot then return end
                            RunService.Heartbeat:Once(function() myRoot.CFrame = CFrame.new(0, -10000, 0) end)
                            task.wait(2)
                            local t = tick()
                            repeat
                                _pGrabRandom(true)
                                task.wait(0.05)
                            until tick() >= t + 4.5
                            local t2 = tick()
                            repeat
                                _pGrabRandom(true)
                                task.wait(0.05)
                            until tick() >= t2 + 1.3
                        end)
                    end
                    if _AnimationId:match('18896229321') and rawget(Options.AttackAllMoves.Value, 'Twin Fangs') then
                        task.spawn(function()
                            -- only fires if you're Purple and Ulted
                            local _myChar = _pGetChar(lp)
                            if not _myChar then return end
                            if _myChar:GetAttribute("Character") ~= "Purple" then return end
                            if not _myChar:GetAttribute("Ulted") then return end
                            local deadline      = tick() + 3
                            local tfActive      = true
                            -- just trust the process
                            local _tfStart = tick()
                            task.spawn(function()
                                repeat task.wait() until tick() >= _tfStart + 2.5 or not tfActive
                                if not tfActive then return end
                                -- only desync if still ulted at fire time
                                local _dc = _pGetChar(lp)
                                if not _dc or not _dc:GetAttribute("Ulted") then return end
                                getgenv().desync = { CFrame = CFrame.new(0, -29000, 0) }
                                task.wait(0.2)
                                getgenv().desync = nil
                            end)
                            local anchor        = _bringAllAnchor(function() return tfActive end)
                            local grabbed       = {}
                            local currentTarget = nil  -- Player ou dummy Model
                            local targetSince   = tick()

                            local savedCFrame = nil
                            do
                                local _sc = _pGetChar(lp)
                                local _sr = _sc and _pGetRoot(_sc)
                                if _sr then savedCFrame = _sr.CFrame end
                            end

                            -- helpers: accept Player OR dummy Model as target
                            local function _tGetChar(t)
                                if not t then return nil end
                                if t:IsA("Player") then return _pGetChar(t) end
                                return t -- dummy char ready
                            end
                            local function _tGetHum(t)
                                return _pGetHum(_tGetChar(t))
                            end
                            local function _tGetRoot(t)
                                return _pGetRoot(_tGetChar(t))
                            end

                            local function _hasAnyFF(c)
                                if not c then return false end
                                if c:FindFirstChild("ForceField") then return true end
                                if c:FindFirstChild("AbsoluteImmortal") then return true end
                                if c:FindFirstChild("BeingGrabbed") then return true end
                                if c:FindFirstChild("HunterCounter") then return true end
                                if c:FindFirstChild("AtomicCounter") then return true end
                                return false
                            end
                            local function _isBlacklisted(target)
                                local c = _tGetChar(target)
                                local h = c and _pGetHum(c)
                                if not c or not h then return true end
                                if h.Health <= 0 then return true end
                                -- checks extras só pra players reais
                                if target:IsA("Player") then
                                    if _hasAnyFF(c) then return true end
                                    if c:FindFirstChild("Counter") then return true end
                                    if _pIsAnimPlaying(h, "15128849047") then return true end
                                    if c:GetAttribute("Ulted") and c:GetAttribute("Character") == "Batter" then return true end
                                end
                                return false
                            end
                            local function _isVictim(target)
                                local h = _tGetHum(target)
                                return h and (_pIsAnimPlaying(h, '18896222853') or _pIsAnimPlaying(h, '137434257516014'))
                            end
                            local function _isOnlyFF(target)
                                if not target or not target:IsA("Player") then return false end
                                local c = _pGetChar(target)
                                local h = c and _pGetHum(c)
                                if not c or not h then return false end
                                if h.Health <= 0 then return false end
                                if _pIsAnimPlaying(h, "15128849047") then return false end
                                return _hasAnyFF(c)
                            end

                            local function _getDummy()
                                local d = workspace.Live:FindFirstChild("Weakest Dummy")
                                if not d then return nil end
                                local h = _pGetHum(d)
                                if not h or h.Health <= 0 then return nil end
                                return d
                            end

                            local function _pickTarget(excluded)
                                local favored = {}
                                local candidates = {}
                                for _, p in pairs(_pGetAllPlayers()) do
                                    if p == excluded or grabbed[p] then continue end
                                    if table.find(RevenantWhitelist, p) then continue end
                                    local pr = _tGetRoot(p)
                                    if not _isBlacklisted(p) and not _isVictim(p) and pr then
                                        if _aaIsFavoredCharacterTarget(p) then
                                            table.insert(favored, p)
                                        else
                                            table.insert(candidates, p)
                                        end
                                    end
                                end
                                if #favored > 0 then return favored[math.random(1, #favored)] end
                                if #candidates > 0 then return candidates[math.random(1, #candidates)] end
                                local d = _getDummy()
                                if d and d ~= excluded and not grabbed[d] then
                                    return d
                                end
                                return nil
                            end

                            local _currentTargetAnimConn = nil
                            -- _currentTargetIsVictim removed: detection fires inline, no heartbeat lag

                            local function _tfSwitchTarget(next)
                                if _currentTargetAnimConn then
                                    pcall(function() _currentTargetAnimConn:Disconnect() end)
                                    _currentTargetAnimConn = nil
                                end
                                -- _currentTargetIsVictim = false  (removed, event-driven now)

                                _aaDetach()
                                currentTarget = next
                                targetSince   = tick()
                                if next then
                                    -- _currentTargetIsVictim = _isVictim(next)  (removed, event-driven now)
                                    local myChar = _pGetChar(lp)
                                    local myRoot = myChar and _pGetRoot(myChar)
                                    local tr = _tGetRoot(next)
                                    if myRoot and tr then
                                        _aaAttach(myRoot, tr)
                                        
                                        local h = _tGetHum(next)
                                        if h then
                                            local animator = h:FindFirstChildOfClass("Animator")
                                            local event = animator and animator.AnimationPlayed or h.AnimationPlayed
                                            _currentTargetAnimConn = event:Connect(function(track)
                                                local id = track.Animation.AnimationId
                                                if id:match('18896222853') or id:match('137434257516014') then
                                                    -- INSTANT grab: no flag, no heartbeat wait, act right now
                                                    if not tfActive then return end
                                                    local victim = currentTarget
                                                    if not victim then return end
                                                    grabbed[victim] = true
                                                    _aaDetach()
                                                    local nextP = _pickTarget(victim)
                                                    if nextP then
                                                        _tfSwitchTarget(nextP)
                                                        if _pickTarget(nextP) == nil and not _hasFFPending() then
                                                            task.wait(0.1)
                                                            grabbed[nextP] = true
                                                            _everybodyDone = true
                                                            _tfCleanup()
                                                        end
                                                    else
                                                        if _hasFFPending() then
                                                            _aaDetach()
                                                            currentTarget = nil
                                                        else
                                                            _everybodyDone = true
                                                            _tfCleanup()
                                                        end
                                                    end
                                                end
                                            end)
                                        end
                                    end
                                end
                            end

                            local function _returnToSaved()
                                if not savedCFrame then return end
                                local _mc = _pGetChar(lp)
                                local _mr = _mc and _pGetRoot(_mc)
                                if _mr then pcall(function() _mr.CFrame = savedCFrame end) end
                            end
                            local function _tfRestoreAR()
                                local _mc = _pGetChar(lp)
                                local _mh = _mc and _pGetHum(_mc)
                                if _mh then pcall(function() _mh.AutoRotate = true end) end
                            end

                            -- When the dummy respawns, clear its grabbed area so it can be targeted again.
                            local _dummyRespawnConn = workspace.Live.ChildAdded:Connect(function(child)
                                if child.Name == "Weakest Dummy" then
                                    grabbed[child] = nil
                                end
                            end)

                            -- FF watcher: Release player if shield falls
                            local _ffWatchConn = RunService.RenderStepped:Connect(function()
                                for _, p in pairs(_pGetAllPlayers()) do
                                    if table.find(RevenantWhitelist, p) then continue end
                                    if not grabbed[p] then continue end
                                    local pc = _pGetChar(p)
                                    local ph = pc and _pGetHum(pc)
                                    if pc and ph and ph.Health > 0 and not _hasAnyFF(pc) then
                                        grabbed[p] = nil
                                        -- FF dropped and we're parked — go grab 'em
                                        if not currentTarget then
                                            _tfSwitchTarget(p)
                                        end
                                    end
                                end
                            end)

                            local function _hasFFPending()
                                for _, p in pairs(_pGetAllPlayers()) do
                                    if grabbed[p] then continue end
                                    if table.find(RevenantWhitelist, p) then continue end
                                    if _isOnlyFF(p) then return true end
                                end
                                return false
                            end

                            local _tfCleaned = false
                            local function _tfCleanup()
                                if _tfCleaned then return end
                                _tfCleaned = true
                                _aaDetach()
                                _tfRestoreAR()
                                if _ffWatchConn then
                                    pcall(function() _ffWatchConn:Disconnect() end)
                                end
                                if _dummyRespawnConn then
                                    pcall(function() _dummyRespawnConn:Disconnect() end)
                                end
                                if _currentTargetAnimConn then
                                    pcall(function() _currentTargetAnimConn:Disconnect() end)
                                    _currentTargetAnimConn = nil
                                end
                                tfActive = false
                                _aaEnd()
                            end

                            -- true = left because intentionally caught everyone → doesnt do anything in the end
                            local _everybodyDone = false

                            -- primeiro alvo
                            local _firstTarget = _pickTarget(nil)
                            if _firstTarget then
                                _tfSwitchTarget(_firstTarget)
                                if _pickTarget(_firstTarget) == nil then
                                    -- único alvo disponível, pegou e acabou
                                    task.wait(0.1)
                                    grabbed[_firstTarget] = true
                                    _everybodyDone = true
                                    _tfCleanup()
                                    return
                                end
                            end



                            while animTrack.IsPlaying and tick() < deadline do
                                RunService.Heartbeat:Wait()

                                local now = tick()
                                local needSwitch = false

                                if not currentTarget then
                                    needSwitch = true
                                else
                                    if _isBlacklisted(currentTarget) then
                                        if not _isOnlyFF(currentTarget) then
                                            grabbed[currentTarget] = true
                                        end
                                        needSwitch = true
                                    -- elseif _currentTargetIsVictim removed: event fires instantly now
                                    elseif now - targetSince >= 0.8 then
                                        grabbed[currentTarget] = true
                                        needSwitch = true
                                    end
                                end

                                if needSwitch then
                                    local next = _pickTarget(currentTarget)
                                    if not next then
                                        if _hasFFPending() then
                                            _aaDetach()
                                            currentTarget = nil
                                        else
                                            _everybodyDone = true
                                            _tfCleanup()
                                            break
                                        end
                                    else
                                        _tfSwitchTarget(next)
                                        if _pickTarget(next) == nil and not _hasFFPending() then
                                            task.wait(0.1)
                                            grabbed[next] = true
                                            _everybodyDone = true
                                            _tfCleanup()
                                            break
                                        end
                                    end
                                end

                                -- dummy: checks victim anims regardless of whether they are currentTarget
                                do
                                    local _dum = _getDummy()
                                    if _dum and not grabbed[_dum] then
                                        local _dumHum = _dum:FindFirstChild("Humanoid")
                                        local _dumAnimator = _dumHum and _dumHum:FindFirstChild("Animator")
                                        local function _dumIsAnimPlaying(id)
                                            if not _dumAnimator then return false end
                                            for _, t in pairs(_dumAnimator:GetPlayingAnimationTracks()) do
                                                if t.Animation.AnimationId:match(id) then return true end
                                            end
                                            return false
                                        end
                                        if _dumHum and (_dumIsAnimPlaying('18896222853') or _dumIsAnimPlaying('137434257516014')) then
                                            grabbed[_dum] = true
                                            if currentTarget == _dum then
                                                _aaDetach()
                                                local nextP = _pickTarget(_dum)
                                                if nextP then
                                                    _tfSwitchTarget(nextP)
                                                    if _pickTarget(nextP) == nil and not _hasFFPending() then
                                                        task.wait(0.1)
                                                        grabbed[nextP] = true
                                                        _everybodyDone = true
                                                        _tfCleanup()
                                                        break
                                                    end
                                                else
                                                    if _hasFFPending() then
                                                        currentTarget = nil
                                                    else
                                                        _everybodyDone = true
                                                        _tfCleanup()
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            _tfCleanup()
                        end)
                    end
                    -- ══════════════════════════════════════════════════════════════
                    -- CRUSHED ROCK VARIANT — simplified like god intended
                    -- windup arms the flag. dash pulls the trigger. that's it.
                    -- victim checks are for people who don't trust themselves <3
                    -- ══════════════════════════════════════════════════════════════

                    -- ── STARTUP (93546004428904) ──────────────────────────────────
                    if _AnimationId:match('93546004428904') and rawget(Options.AttackAllMoves.Value, 'Crushed Rock Variant') then
                        _crBlacklistCount = 0
                        _crStopDesync     = false
                        -- concurrent blacklist: if MY windup and their victim startup play simultaneously
                        task.spawn(function()
                            local _mc = _pGetChar(lp)
                            local _mh = _mc and _pGetHum(_mc)
                            local _ma = _mh and _mh:FindFirstChild("Animator")
                            if not _ma then return end
                            -- loop while MY windup is still playing
                            while true do
                                local _windupStillOn = false
                                for _, t in pairs(_ma:GetPlayingAnimationTracks()) do
                                    if t.Animation.AnimationId:match('93546004428904') then
                                        _windupStillOn = true break
                                    end
                                end
                                if not _windupStillOn then
                                    _crBlacklistCount = 0
                                    _crStopDesync     = false
                                    break
                                end
                                -- scan all players
                                for _, p in pairs(Players:GetPlayers()) do
                                    if p == lp then continue end
                                    local pc = _pGetChar(p)
                                    local ph = pc and _pGetHum(pc)
                                    if ph and pc and not pc:GetAttribute('CrushedRockVariant') then
                                        if _pIsAnimPlaying(ph, '129945907044125') then
                                            pc:SetAttribute('CrushedRockVariant', true)
                                            _crBlacklistCount = _crBlacklistCount + 1

                                            local _pName = p.Name
                                        end
                                    end
                                end
                                -- scan dummy
                                local _dum = workspace.Live:FindFirstChild("Weakest Dummy")
                                local _dumH = _dum and _dum:FindFirstChild("Humanoid")
                                local _dumA = _dumH and _dumH:FindFirstChild("Animator")
                                if _dumA and _dum and not _dum:GetAttribute('CrushedRockVariant') then
                                    for _, t in pairs(_dumA:GetPlayingAnimationTracks()) do
                                        if t.Animation.AnimationId:match('129945907044125') then
                                            _dum:SetAttribute('CrushedRockVariant', true)
                                        end
                                    end
                                end
                                task.wait()
                            end
                        end)

                    end

                    -- lunge/hit da Crushing Rock Variant: sistema completo de attach
                    if _AnimationId:match('72451715583225')
                    and rawget(Options.AttackAllMoves.Value, 'Crushed Rock Variant') then

                        -- cleanup blacklist tags regardless
                        task.spawn(function()
                            for _, p in pairs(Players:GetPlayers()) do
                                if p == lp then continue end
                                local pc = _pGetChar(p)
                                if pc then pc:SetAttribute('CrushedRockVariant', nil) end
                            end
                            local _dum = workspace.Live:FindFirstChild("Weakest Dummy")
                            if _dum then _dum:SetAttribute('CrushedRockVariant', nil) end
                        end)

                        -- desync removed by LO
                        if _crWindupSuccess then
                            _crWindupSuccess = false  -- consumed. reset for next use.
                        end
                    end
                    -- ── END CRUSHED ROCK VARIANT ──────────────────────────────────
                    -- 131226430469931: my dash anim = desync fires independently, no blacklist check
                    if _AnimationId:match('131226430469931') and rawget(Options.AttackAllMoves.Value, 'Crushed Rock Variant') then
                        task.spawn(function()
                            task.wait(1.2)
                            local _mc3 = _pGetChar(lp)
                            local _mr3 = _mc3 and _pGetRoot(_mc3)
                            if not _mr3 then return end
                            -- [ENI] skip desync if ult is full
                            if (tonumber(lp:GetAttribute("Ultimate")) or 0) >= 100 then return end
                            getgenv().desync = { CFrame = CFrame.new(0, -29000, 0) }
                            task.wait(0.65)
                            getgenv().desync = nil
                        end)
                    end
                    if _AnimationId:match('135104210400610') and rawget(Options.AttackAllMoves.Value, 'Crushed Rock Variant') then
                        local _currentHitConfirmed = false
                        local _respawnConns = {}           -- conexões de respawn para limpar blacklist

                        -- private attach state for Crushed Rock (isolated from other moves)
                        local _crCurrentConn = nil
                        local _crRotConn     = nil
                        local _crMyRoot      = nil
                        local _crTargetRoot  = nil

                        local function _crDetach()
                            if _crCurrentConn then _crCurrentConn:Disconnect() _crCurrentConn = nil end
                            if _crRotConn     then _crRotConn:Disconnect()     _crRotConn     = nil end
                            if sethiddenproperty then
                                if _crMyRoot     and _crMyRoot.Parent     then pcall(function() sethiddenproperty(_crMyRoot,     "PhysicsRepRootPart", nil) end) end
                                if _crTargetRoot and _crTargetRoot.Parent then pcall(function() sethiddenproperty(_crTargetRoot, "PhysicsRepRootPart", nil) end) end
                            end
                            if _crMyRoot and _crMyRoot.Parent then
                                _crMyRoot.CFrame                  = CFrame.new(_crMyRoot.Position)
                                _crMyRoot.AssemblyLinearVelocity  = Vector3.zero
                                _crMyRoot.AssemblyAngularVelocity = Vector3.zero
                                pcall(function() _crMyRoot.Velocity    = Vector3.zero end)
                                pcall(function() _crMyRoot.RotVelocity = Vector3.zero end)
                                local _dh = _crMyRoot.Parent:FindFirstChildOfClass("Humanoid")
                                if _dh then pcall(function() _dh.AutoRotate = true end) end
                            end
                            _crMyRoot     = nil
                            _crTargetRoot = nil
                        end

                        local function _crAttach(myRoot, targetRoot)
                            if _crCurrentConn then _crCurrentConn:Disconnect() _crCurrentConn = nil end
                            if _crMyRoot and _crMyRoot.Parent then
                                _crMyRoot.AssemblyLinearVelocity  = Vector3.zero
                                _crMyRoot.AssemblyAngularVelocity = Vector3.zero
                                pcall(function() _crMyRoot.Velocity    = Vector3.zero end)
                                pcall(function() _crMyRoot.RotVelocity = Vector3.zero end)
                            end
                            if not myRoot or not targetRoot then return end
                            _crMyRoot     = myRoot
                            _crTargetRoot = targetRoot
                            if _crRotConn then _crRotConn:Disconnect() _crRotConn = nil end
                            local _rotHum = myRoot.Parent and myRoot.Parent:FindFirstChildOfClass("Humanoid")
                            if _rotHum then
                                _crRotConn = RunService.RenderStepped:Connect(function()
                                    if _rotHum and _rotHum.Parent then
                                        pcall(function() _rotHum.AutoRotate = false end)
                                    end
                                end)
                            end
                            myRoot.CFrame                  = targetRoot.CFrame * CFrame.new(0, 0, 5)
                            myRoot.AssemblyLinearVelocity  = Vector3.zero
                            myRoot.AssemblyAngularVelocity = Vector3.zero
                            if sethiddenproperty then
                                pcall(function() sethiddenproperty(myRoot, "PhysicsRepRootPart", myRoot) end)
                                pcall(function() sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot) end)
                            end
                            local _selfConn
                            _selfConn = RunService.Heartbeat:Connect(function()
                                if not myRoot or not myRoot.Parent
                                or not targetRoot or not targetRoot.Parent then
                                    _selfConn:Disconnect()
                                    if _crCurrentConn == _selfConn then _crCurrentConn = nil end
                                    if sethiddenproperty then
                                        if myRoot and myRoot.Parent then
                                            pcall(function() sethiddenproperty(myRoot, "PhysicsRepRootPart", nil) end)
                                        end
                                        if targetRoot and targetRoot.Parent then
                                            pcall(function() sethiddenproperty(targetRoot, "PhysicsRepRootPart", nil) end)
                                        end
                                    end
                                    if myRoot and myRoot.Parent then
                                        myRoot.AssemblyLinearVelocity  = Vector3.zero
                                        myRoot.AssemblyAngularVelocity = Vector3.zero
                                        pcall(function() myRoot.Velocity    = Vector3.zero end)
                                        pcall(function() myRoot.RotVelocity = Vector3.zero end)
                                    end
                                    return
                                end
                                myRoot.CFrame                  = targetRoot.CFrame * CFrame.new(0, 0, 5)
                                myRoot.AssemblyLinearVelocity  = Vector3.zero
                                myRoot.AssemblyAngularVelocity = Vector3.zero
                                if sethiddenproperty then
                                    pcall(function() sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot) end)
                                end
                            end)
                            _crCurrentConn = _selfConn
                        end

                        local function _crEnd()
                            _crDetach()
                        end

                        -- quando alguém morre, limpa CrushedRockVariant na hora
                        for _, p in pairs(Players:GetPlayers()) do
                            if p == lp then continue end
                            local pc = _pGetChar(p)
                            local ph = pc and pc:FindFirstChildOfClass("Humanoid")
                            if ph then
                                local dc = ph.Died:Connect(function()
                                    local chr = _pGetChar(p)
                                    if chr then chr:SetAttribute('CrushedRockVariant', nil) end
                                end)
                                table.insert(_respawnConns, dc)
                            end
                            -- also hook CharacterAdded so new char is clean on spawn
                            local cc = p.CharacterAdded:Connect(function(chr)
                                task.wait(0.1)
                                if chr then chr:SetAttribute('CrushedRockVariant', nil) end
                            end)
                            table.insert(_respawnConns, cc)
                        end
                        -- hook dummy body destruction (AncestryChanged fires when model leaves workspace)
                        task.spawn(function()
                            local _dum  = workspace.Live:FindFirstChild("Weakest Dummy")
                            if _dum then
                                local ac = _dum.AncestryChanged:Connect(function()
                                    if not _dum:IsDescendantOf(workspace) then
                                        pcall(function() _dum:SetAttribute('CrushedRockVariant', nil) end)
                                    end
                                end)
                                table.insert(_respawnConns, ac)
                            end
                        end)



                        local function _pickCrushTarget()
                            local favored = {}
                            local candidates = {}

                            for _, p in pairs(_pGetAllPlayers()) do
                                if table.find(RevenantWhitelist, p) then continue end
                                local pc = _pGetChar(p)
                                local ff = pc and (pc:FindFirstChild('ForceField') or pc:FindFirstChild('AbsoluteImmortal') or pc:FindFirstChild('BeingGrabbed') or pc:FindFirstChild('HunterCounter') or pc:FindFirstChild('AtomicCounter'))
                                if pc and not ff and not pc:GetAttribute('CrushedRockVariant') then
                                    if not (pc:GetAttribute("Ulted") and pc:GetAttribute("Character") == "Batter") then
                                        if _aaIsFavoredCharacterTarget(p) then
                                            table.insert(favored, p)
                                        else
                                            table.insert(candidates, p)
                                        end
                                    end
                                end
                            end

                            if #favored > 0 then return favored[math.random(1, #favored)] end
                            if #candidates > 0 then return candidates[math.random(1, #candidates)] end

                            local dummy = workspace.Live:FindFirstChild("Weakest Dummy")
                            local dRoot = dummy and (dummy:FindFirstChild("HumanoidRootPart") or dummy.PrimaryPart)
                            local dHum  = dummy and dummy:FindFirstChildOfClass("Humanoid")
                            if dRoot and dHum and dHum.Health > 0
                            and not dummy:GetAttribute('CrushedRockVariant')
                            and not dummy:GetAttribute('Freeze') and not dummy:FindFirstChild('BeingGrabbed')
                            and not dummy:FindFirstChild('HunterCounter') and not dummy:FindFirstChild('AtomicCounter') then
                                return dummy
                            end

                            return nil
                        end

                        local currentTarget = _pickCrushTarget()
                        local _isDummy      = currentTarget == workspace.Live:FindFirstChild("Weakest Dummy")
                        local currentTChar  = _isDummy and currentTarget or (currentTarget and _pGetChar(currentTarget))

                        -- attach inicial ao primeiro alvo; se for boneco, blacklista imediatamente
                        do
                            local myChar = _pGetChar(lp)
                            local myRoot = myChar and _pGetRoot(myChar)
                            local initTr = currentTChar and (currentTChar:FindFirstChild("HumanoidRootPart") or _pGetRoot(currentTChar))
                            if myRoot and initTr then _crAttach(myRoot, initTr) end
                            if _isDummy and currentTChar then
                                currentTChar:SetAttribute('CrushedRockVariant', true)
                            end
                        end

                        local function _crSwitch(newTarget, hitConfirmed)
                            _crDetach()
                            if hitConfirmed and currentTChar then
                                currentTChar:SetAttribute('CrushedRockVariant', true)
                            end
                            _currentHitConfirmed = false
                            local isDummy = newTarget == workspace.Live:FindFirstChild("Weakest Dummy")
                            currentTarget = isDummy and nil or newTarget
                            currentTChar  = isDummy and newTarget or (newTarget and _pGetChar(newTarget))
                            -- boneco: blacklista imediatamente ao teleportar, sem checar animação
                            if isDummy and currentTChar then
                                currentTChar:SetAttribute('CrushedRockVariant', true)
                            end

                            local myChar = _pGetChar(lp)
                            local myRoot = myChar and _pGetRoot(myChar)
                            local tr = currentTChar and (currentTChar:FindFirstChild("HumanoidRootPart") or _pGetRoot(currentTChar))
                            if myRoot and tr then _crAttach(myRoot, tr) end
                        end

                        local _crAllDone     = false  -- true = pegou todo mundo, para tudo

                        local conn
                        conn = RunService.Heartbeat:Connect(function()
                            if _crAllDone then
                                conn:Disconnect()
                                _crEnd()
                                for _, c in pairs(_respawnConns) do pcall(function() c:Disconnect() end) end
                                _respawnConns = {}
                                return
                            end
                            if not animTrack.IsPlaying then
                                conn:Disconnect()
                                _crEnd()
                                for _, c in pairs(_respawnConns) do pcall(function() c:Disconnect() end) end
                                _respawnConns = {}
                                if _currentHitConfirmed and currentTChar and currentTChar ~= workspace.Live:FindFirstChild("Weakest Dummy") then
                                    currentTChar:SetAttribute('CrushedRockVariant', true)
                                end
                                return
                            end

                            -- limpa o blacklist quando a animação chegar no segundo 1
                            if animTrack.TimePosition >= 1 then
                                for _, p in pairs(Players:GetPlayers()) do
                                    if p ~= lp then
                                        local pc = _pGetChar(p)
                                        if pc then pc:SetAttribute('CrushedRockVariant', nil) end
                                    end
                                end
                            end

                            local myChar = _pGetChar(lp)
                            local myRoot = myChar and _pGetRoot(myChar)
                            local myHum  = myChar and _pGetHum(myChar)

                            -- victim principal (129945907044125): blacklista e vai pro próximo
                            for _, p in pairs(Players:GetPlayers()) do
                                if p == lp then continue end
                                local pc = _pGetChar(p)
                                local ph = pc and pc:FindFirstChildOfClass("Humanoid")
                                local pr = pc and pc:FindFirstChild("HumanoidRootPart")
                                if not ph or not pr then continue end
                                if pc:GetAttribute('CrushedRockVariant') then continue end
                                if pc:FindFirstChild('AbsoluteImmortal') or pc:FindFirstChild('HunterCounter') or pc:FindFirstChild('AtomicCounter') then continue end
                                if _pIsAnimPlaying(ph, '129945907044125')
                                and myHum and _pIsAnimPlaying(myHum, '131226430469931') then
                                    if currentTarget == p then
                                        _currentHitConfirmed = true
                                        -- desync rider removed — desync now lives in dash block only

                                        local next = _pickCrushTarget()
                                        if next and next ~= currentTarget then
                                            _crSwitch(next, true)
                                        elseif not next then
                                            -- pegou todo mundo
                                            _crDetach()
                                            if currentTChar then currentTChar:SetAttribute('CrushedRockVariant', true) end
                                            _crAllDone = true
                                        end
                                    end
                                end
                            end

                            -- victim dash (80910065447206): teleporta para essa pessoa e blacklista ela
                            for _, p in pairs(Players:GetPlayers()) do
                                if p == lp then continue end
                                local pc = _pGetChar(p)
                                local ph = pc and pc:FindFirstChildOfClass("Humanoid")
                                local pr = pc and pc:FindFirstChild("HumanoidRootPart")
                                if not ph or not pr then continue end
                                if pc:GetAttribute('CrushedRockVariant') then continue end
                                if pc:FindFirstChild('AbsoluteImmortal') or pc:FindFirstChild('HunterCounter') or pc:FindFirstChild('AtomicCounter') then continue end
                                if _pIsAnimPlaying(ph, '80910065447206') then
                                    if myRoot and pr then
                                        -- leaving the dummy without going through _crSwitch, blacklist it now
                                        local _liveDum = workspace.Live:FindFirstChild("Weakest Dummy")
                                        if currentTChar and currentTChar == _liveDum then
                                            currentTChar:SetAttribute('CrushedRockVariant', true)
                                        end
                                        _crAttach(myRoot, pr)
                                        pc:SetAttribute('CrushedRockVariant', true)
                                        currentTarget = p
                                        currentTChar  = pc
                                        _currentHitConfirmed = true
                                    end
                                end
                            end

                            -- dummy: se fez animação de victim (129945907044125 ou 80910065447206),
                            -- blacklista ele automaticamente mesmo que tenha sido pego sem querer
                            do
                                local _dum = workspace.Live:FindFirstChild("Weakest Dummy")
                                local _dumHum = _dum and _dum:FindFirstChild("Humanoid")
                                local _dumAnimator2 = _dumHum and _dumHum:FindFirstChild("Animator")
                                local function _dumIsAnimPlaying2(id)
                                    if not _dumAnimator2 then return false end
                                    for _, t in pairs(_dumAnimator2:GetPlayingAnimationTracks()) do
                                        if t.Animation.AnimationId:match(id) then return true end
                                    end
                                    return false
                                end
                                if _dum and _dumHum and not _dum:GetAttribute('CrushedRockVariant') then
                                    if _dumIsAnimPlaying2('129945907044125')
                                    or _dumIsAnimPlaying2('80910065447206') then
                                        _dum:SetAttribute('CrushedRockVariant', true)
                                        -- dummy dash desync: same treatment as player
                                        if _dumIsAnimPlaying2('80910065447206') then
                                            local _myC2 = _pGetChar(lp)
                                            local _myH2 = _myC2 and _pGetHum(_myC2)
                                            if _myH2 and _pIsAnimPlaying(_myH2, '131226430469931') then
                                                task.spawn(function()
                                                    task.wait(1.2)
                                                    local _mc3 = _pGetChar(lp)
                                                    local _mr3 = _mc3 and _pGetRoot(_mc3)
                                                    if not _mr3 then return end
                                                    -- [ENI] skip desync if ult is full
                                                    if (tonumber(lp:GetAttribute("Ultimate")) or 0) >= 100 then return end
                                                    getgenv().desync = { CFrame = CFrame.new(0, -29000, 0) }
                                                    task.wait(0.65)
                                                    getgenv().desync = nil
                                                end)
                                            end
                                        end
                                        if currentTChar == _dum then
                                            _crDetach()
                                            local next = _pickCrushTarget()
                                            if next and next ~= _dum then
                                                _crSwitch(next, false)
                                            else
                                                -- dummy era o último, para tudo
                                                _crAllDone = true
                                            end
                                        end
                                    end
                                end
                            end

                            -- corpo destruido (morreu ou dummy foi substituido) → retarget
                            if currentTChar and not currentTChar.Parent then
                                pcall(function() currentTChar:SetAttribute('CrushedRockVariant', nil) end)
                                local next = _pickCrushTarget()
                                if next then
                                    _crSwitch(next, false)
                                else
                                    _crAllDone = true
                                end
                            end

                            -- alvo atual ganhou ForceField, AbsoluteImmortal, BeingGrabbed ou counter → retarget sem blacklist
                            local currFF = currentTChar and (currentTChar:FindFirstChild('ForceField') or currentTChar:FindFirstChild('AbsoluteImmortal') or currentTChar:FindFirstChild('BeingGrabbed') or currentTChar:FindFirstChild('HunterCounter') or currentTChar:FindFirstChild('AtomicCounter'))
                            if currFF then
                                local next = _pickCrushTarget()
                                if next and next ~= currentTarget then
                                    _crSwitch(next, false)
                                elseif not next then
                                    _crAllDone = true
                                end
                            end
                        end)
                    end
                end)
                -- Skill Throw: faz seu HRP voar quando Hunters Grasp / Homerun são usados
                _pCharConns[#_pCharConns+1] = localHum.AnimationPlayed:Connect(function(animTrack)
                    if not Toggles.SkillThrow or not Toggles.SkillThrow.Value then return end
                    local _AnimId = animTrack.Animation.AnimationId
                    local _moves  = Options.SkillThrowMoves and Options.SkillThrowMoves.Value
                    if not _moves then return end
                    local myChar = _pGetChar(lp)
                    local myRoot = myChar and _pGetRoot(myChar)
                    if not myRoot then return end
                    if _AnimId:match('12309835105') and rawget(_moves, 'Hunters Grasp') then
                        task.spawn(function()
                            task.wait(0.3)
                            local _savedCF = myRoot.CFrame
                            game:GetService("TweenService"):Create(myRoot, TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                                CFrame = myRoot.CFrame * CFrame.new(0, 2500, 0),
                            }):Play()
                            task.wait(0.8)
                            _pHeartbeatTp(_savedCF)
                        end)
                    elseif _AnimId:match('14004235777') and rawget(_moves, 'Homerun') then
                        task.spawn(function()
                            task.wait(0.4)
                            local _savedCF = myRoot.CFrame
                            game:GetService("TweenService"):Create(myRoot, TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                                CFrame = myRoot.CFrame * CFrame.new(0, 10000, 0),
                            }):Play()
                            task.wait(1)
                            _pHeartbeatTp(_savedCF)
                        end)
                    end
                end)
                local function _hookEnemyForCrushedRock(enemyPlayer)
                    local function _connectHook(eChar)
                        local eHum = eChar and _pGetHum(eChar)
                        if not eHum then return end
                        _pCharConns[#_pCharConns+1] = eHum.AnimationPlayed:Connect(function(track)
                            local aid = track.Animation.AnimationId
                            local myChar = _pGetChar(lp)
                            local myHum  = myChar and _pGetHum(myChar)
                            if aid:match('129945907044125') then
                                -- victim principal: blacklista se eu estou fazendo o lunge
                                if myHum and _pIsAnimPlaying(myHum, '135104210400610') then
                                    if eChar then eChar:SetAttribute('CrushedRockVariant', true) end
                                end
                            elseif aid:match('80910065447206') then
                                -- victim dash: blacklista sempre que eu estiver com a Crushing Rock ativa
                                if myHum and _pIsAnimPlaying(myHum, '135104210400610') then
                                    if eChar then eChar:SetAttribute('CrushedRockVariant', true) end
                                end

                            end
                        end)
                    end
                    local eChar = _pGetChar(enemyPlayer)
                    if eChar then _connectHook(eChar) end
                    _pConns[#_pConns+1] = enemyPlayer.CharacterAdded:Connect(function(newChar)
                        task.wait(0.5)
                        _connectHook(newChar)
                    end)
                end
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lp then _hookEnemyForCrushedRock(p) end
                end
                _pConns[#_pConns+1] = Players.PlayerAdded:Connect(function(p)
                    task.wait(1)
                    _hookEnemyForCrushedRock(p)
                end)
            end
        end
        task.spawn(_pInit)
        _pConns[#_pConns+1] = lp.CharacterAdded:Connect(function()
            task.spawn(_pInit, true)
        end)
        table.insert(CleanupTasks, function()
            for _, conn in pairs(_pCharConns) do conn:Disconnect() end
            table.clear(_pCharConns)
            for _, conn in pairs(_pConns) do conn:Disconnect() end
            table.clear(_pConns)
            if _pClone then _pClone:Destroy() _pClone = nil end
        pcall(function() Toggles["Auto_Lock-on_Prediction"]:SetValue(false) end)
        pcall(function() Toggles.TouchFlingEnabled:SetValue(false) end)
        pcall(function() Toggles.TogWeld:SetValue(false) end)
        pcall(function() Toggles.CustomFrontDash:SetValue(false) end)
        pcall(function() Toggles.CustomSideDash:SetValue(false) end)
        pcall(function() Toggles.CustomBackDash:SetValue(false) end)
            _pU59['Touch Fling'] = false
            local myChar = lp.Character
            local myHum  = myChar and myChar:FindFirstChildOfClass('Humanoid')
            if myHum then pcall(function() myHum.AutoRotate = true end) end
        end)
    end
end
if isGamepassesGame then
    task.spawn(function()
        pcall(function()
            _G.FreeEmotes = true
            lp:SetAttribute("EmoteSearchBar", true)
            lp:SetAttribute("ExtraSlots",     true)
            lp:SetAttribute("EmotePages",     true)
        end)
    end)
end
if isGamepassesGame and Tabs.Misc then
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TeleportService   = game:GetService("TeleportService")
    local function doLeave()
        pcall(function() game:GetService("Players").LocalPlayer:Kick("\n[ZKAYTSB]\nAnticheat Triggered, You were reported for exploiting.") end)
    end
end
local _revenantServerType = "Unknown"
pcall(function()
    local _gst = game:GetService("ReplicatedStorage"):WaitForChild("GetServerType", 1)
    if _gst then _revenantServerType = _gst:InvokeServer() end
end)
local function doRejoin(p)
    if typeof(p) ~= 'table' or not p then
        p = nil
    end
    local Players2 = game:GetService("Players")
    local ts = game:GetService("TeleportService")
    local player = Players2.LocalPlayer
    local isPrivate = game.PrivateServerId ~= '' or #Players2:GetPlayers() <= 1
    if isPrivate then
        pcall(function() player:Kick(p and (p.Message or 'Rejoining....') or 'Rejoining....') end)
        task.wait()
        pcall(function() ts:Teleport(game.PlaceId, player) end)
    else
        pcall(function()
            player:Kick(p and (p.Message or 'Rejoining....') or 'Rejoining....')
        end)
        task.delay(p and p.Delay or 0.1, function()
            pcall(function() ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
        end)
    end
end
local TabMiscMain, TabMiscScripts, TabMiscExtra, TabMiscLeaderboard
if isGamepassesGame and Tabs.Misc then
    TabMiscMain        = Tabs.Misc:AddLeftGroupbox("Staff Detector",  "gavel")
    TabMiscScripts     = Tabs.Misc:AddLeftGroupbox("Scripts",         "folder")
    TabMiscExtra       = Tabs.Misc:AddRightGroupbox("Extra",          "plus")
    TabMiscLeaderboard = Tabs.Misc:AddRightGroupbox("Leaderboard",    "monitor")
end
if isGamepassesGame and Tabs.Misc then
    local BoxAntiBan = TabMiscMain
    local _sdSpecialIds = {
        422755031, 198131804, 681405668, 3414432341, 339633571,
        430966809, 2039323684, 117723419, 1015595932, 263944298,
        112905203, 2284964418, 1266437961, 3120648134, 1148139861,
        1633233654, 3350014406, 971193650, 661273560, 66105529,
        77342385, 167343092, 2055306963, 141984224, 438917845,
        1391134999, 1796550069, 255671730, 3162123826, 1059541187,
        1259898795, 31070091, 1041867508, 994994173, 1446694201,
        77525605, 1001242712, 2533866869, 4983064295,
    }
    local function _sdCheckPlayer(player)
        if player == lp then return end
        local displayName = player.DisplayName
        local label = displayName .. "(@" .. player.Name .. ")"
        local selected = Options.LeaveOnDropdown and Options.LeaveOnDropdown.Value or {}

        local function _doAction(typeStr, customMsg)
            if selected[typeStr] then
                lp:Kick("\n[ZKAYTSB]\n" .. label .. " joined.\nThey're flagged as: " .. typeStr .. ".")
            else
                Library:Notify({ Title = bypassText("Heads up"), Content = customMsg, Time = 10 })
            end
        end

        -- Group 12013007 check
        local ok, inGroup = pcall(function() return player:IsInGroup(12013007) end)
        if ok and inGroup then
            local ok2, role = pcall(function() return player:GetRoleInGroup(12013007) end)
            local isHighRole = false
            local roleStr = (ok2 and role) and role or "?"
            if ok2 and role then
                local r = role:lower()
                isHighRole = r:find("moderator") or r:find("developer") or
                             r:find("contributor") or r:find("tester") or r:find("owner") or
                             r:find("anomaly player")
            end
            if isHighRole then
                _doAction("Staff", label .. " is a staff (" .. roleStr .. "). heads up.") return
            end
        end

        -- Hardcoded special IDs
        for _, id in ipairs(_sdSpecialIds) do
            if player.UserId == id then
                _doAction("Special People", label .. " is a possible mod.") return
            end
        end

        -- Friends of special people
        local friendNames = {}
        for _, id in ipairs(_sdSpecialIds) do
            local ok2, isFriend = pcall(function() return player:IsFriendsWith(id) end)
            if ok2 and isFriend then
                local ok3, username = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
                if ok3 then
                    local displayName = username
                    pcall(function()
                        local info = game:GetService("UserService"):GetUserInfosByUserIdsAsync({id})
                        if info and info[1] then displayName = info[1].DisplayName end
                    end)
                    friendNames[#friendNames+1] = displayName .. "(@" .. username .. ")"
                end
            end
        end
        if #friendNames > 0 then
            _doAction("Friends with Staff", label .. " is friends with " .. table.concat(friendNames, ", ") .. ".")
        end
    end
    -- "Leave On": selected → kicks you out when they join; unselected → notify only
    BoxAntiBan:AddDropdown("LeaveOnDropdown", {
        Text    = "Leave On",
        Multi   = true,
        Default = {},
        Values  = { "Staff", "Special People", "Friends with Staff" },
    })
    -- Always-on PlayerAdded listener
    local _sdPlayerAddedConn = Players.PlayerAdded:Connect(function(p)
        task.spawn(pcall, _sdCheckPlayer, p)
    end)
    -- Scan existing players on load
    for _, p in pairs(Players:GetPlayers()) do
        task.spawn(pcall, _sdCheckPlayer, p)
    end
    table.insert(CleanupTasks, function()
        if _sdPlayerAddedConn then _sdPlayerAddedConn:Disconnect() _sdPlayerAddedConn = nil end
    end)
    local BoxScripts = TabMiscScripts
    BoxScripts:AddButton({ Text = "Infinite Yield", Func = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", true))()
    end })
    BoxScripts:AddButton({ Text = "Dex++", Func = function()
        loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
    end })
    BoxScripts:AddButton({ Text = "Cobalt Remote Spy", Func = function()
        loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))()
    end })
    do
        local _limitedEmoteData = {}
        local _limitedLoaded    = false
        local _limitedDropAdded = false
        BoxScripts:AddButton({
            Text    = "Bypass Limited Emotes Timer",
            Tooltip = "Allows you to purchase any limited emote at any time.",
            Func    = function()
                task.spawn(function()
                    pcall(function()
                        local a = game:GetService("MarketplaceService")
                        local b = require(game.ReplicatedStorage.Info)
                        local boc = '{"items":['
                        local d = {}
                        for _, f in b.Limited do d[f.Name] = f.ID end
                        local g = 1
                        local h, i = pcall(function() return a:GetDeveloperProductsAsync():GetCurrentPage() end)
                        if h then
                            for _, j in ipairs(i) do
                                if d[j.Name] then
                                    boc = boc .. string.format('{"Number":%d,"Image":%d,"Name":"%s","Price":%d,"ID":%d},', g, j.IconImageAssetId or 0, j.Name, j.PriceInRobux or 0, j.ProductId)
                                    g = g + 1
                                    local label2 = j.Name .. "  |  " .. tostring(j.PriceInRobux or "?") .. " R$"
                                    _limitedEmoteData[label2] = { gamepassId = d[j.Name] }
                                end
                            end
                            if boc:sub(-1) == "," then boc = boc:sub(1,-2) end
                            boc = boc .. '],"info":{"secondsInWeek":604800,"startOfYear":1735732800,"currentWeek":23}}'
                            workspace:SetAttribute("Limited", boc)
                            local k = game.Players.LocalPlayer
                            local l = k.PlayerGui.Emotes.ImageLabel.Limited.List
                            for _, m in ipairs(l:GetChildren()) do
                                if m:IsA("ImageButton") then
                                    m.MouseButton1Click:Connect(function()
                                        local n = m:GetAttribute("ID")
                                        if n then
                                            local o = {{ Goal = "Gift Gamepass", GiftData = { Receiver = k.UserId, Gamepass = n } }}
                                            k.Character:WaitForChild("Communicate"):FireServer(unpack(o))
                                        end
                                    end)
                                end
                            end
                            _limitedLoaded = true
                            if not _limitedDropAdded then
                                _limitedDropAdded = true
                                BoxScripts:AddLabel("Select an emote to purchase (use this if the emote is not visible in the default TSB UI):", true)
                                local labels2 = {}
                                for label2 in pairs(_limitedEmoteData) do table.insert(labels2, label2) end
                                BoxScripts:AddDropdown("LimitedEmoteDropdown", {
                                    Values = labels2, Default = 1, Multi = false, Text = "Emote",
                                })
                                BoxScripts:AddButton({ Text = "Buy", Func = function()
                                    local selected = Options.LimitedEmoteDropdown and Options.LimitedEmoteDropdown.Value
                                    local data2 = selected and _limitedEmoteData[selected]
                                    if not data2 then
                                        Library:Notify({ Title = bypassText("Limited Emotes"), Content = "Emote not found.", Time = 3 })
                                        return
                                    end
                                    pcall(function()
                                        local payload2 = {{ Goal = "Gift Gamepass", GiftData = { Receiver = lp.UserId, Gamepass = data2.gamepassId } }}
                                        lp.Character:WaitForChild("Communicate"):FireServer(unpack(payload2))
                                    end)
                                end })
                            end
                        end
                    end)
                end)
            end,
        })
    end
    BoxScripts:AddDivider()
    BoxScripts:AddButton({ Text = "Kade Gojo V1", Func = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/miikicomsono/BaldyToSorcererFixed/refs/heads/main/V1.lua"))()
    end })
    BoxScripts:AddButton({ Text = "Kade Gojo V2 (Morph)", Func = function()
        getgenv().morph = true
        loadstring(game:HttpGet("https://raw.githubusercontent.com/skibiditoiletfan2007/BaldyToSorcerer/refs/heads/main/LatestV2.lua"))()
    end })
    BoxScripts:AddButton({ Text = "Kade Gojo V2 (No Morph)", Func = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/skibiditoiletfan2007/BaldyToSorcerer/refs/heads/main/LatestV2.lua"))()
    end })
    BoxScripts:AddButton({ Text = "Saitama Overhaul", Func = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/skibiditoiletfan2007/SaitamaOverhaul/refs/heads/main/Latest.lua"))()
    end })
    BoxScripts:AddButton({ Text = "Star Glitcher", Func = function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/kellerthemango/c16ccf4637e1812201704d9d887f336c/raw/star%2520farter"))()
    end })
    BoxScripts:AddButton({ Text = "KadeJ / KaitamaJ", Func = function()
        getgenv().Moveset_Settings = {
            ExecuteOnRespawn = false,
            TSBStyleNotification = true,
            UseOldCollateralRuin = true,
            NoWarning = false,
            NoDeathCounterImages = false,
            NoBarrageArms = true,
            NoPreysPerilAttract = false,
            NoWalls = false,
            NoTrees = false,
            RavageTool = false,
            AdrenalineBoostTool = false,
            Adrenaline_Multiplier = 2,
            CustomUppercutAnimation = true,
            CustomDownslamAnimation = true,
            CustomIdleAnimation = true,
            UltNames = { "20 SERIES", "COME AT ME", "I'M DONE" },
            MoveNames = {
                ["Normal Punch"]           = "Ravaging Kick",
                ["Consecutive Punches"]    = "Fist Fusillade",
                Shove                      = "Swift Sweep",
                Uppercut                   = "Collateral Storm",
                ["Death Counter"]          = "Sudden Strike",
                ["Table Flip"]             = "Stoic Bomb",
                ["Serious Punch"]          = "Destructive Power",
                ["Omni Directional Punch"] = "Omni Directional Fists",
            },
        }
        loadstring(game:HttpGet("https://raw.githubusercontent.com/skibiditoiletfan2007/BaldyToKJ/refs/heads/main/Latest.lua"))()
    end })
    BoxScripts:AddButton({ Text = "Dovi Hub", Func = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/needanewphone32-eng/tsbfiles/refs/heads/main/Main1.lua"))()
    end })
    -- ── EXTRA GROUPBOX ────────────────────────────────────────────────────────
    do
        local function _extraSendMsg(msg)
            local tcs = game:GetService("TextChatService")
            if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
                local ch = tcs.TextChannels:FindFirstChild("RBXGeneral")
                if ch then pcall(function() ch:SendAsync(msg) end) end
            else
                local ev  = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                local req = ev and ev:FindFirstChild("SayMessageRequest")
                if ev and req then pcall(function() req:FireServer(msg, "all") end) end
            end
        end
        local function _extraRandStr(n)
            local s = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            local r = ""
            for _ = 1, (n or math.random(3, 20)) do
                local i = math.random(1, #s)
                r = r .. s:sub(i, i)
            end
            return r
        end
        if TabMiscExtra then
            do
                local _movedStats = {}
                local _playerAddedConn = nil
                local _charConns = {}  -- [player] = CharacterAdded connection
                local _STATS = { "Kills", "Total Kills" }
                local function _moveKills(player)
                    task.spawn(function()
                        local ls = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats", 10)
                        if not ls then return end
                        if not _movedStats[player] then _movedStats[player] = {} end
                        for _, name in ipairs(_STATS) do
                            if not ls:FindFirstChild(name) then
                                local v = player:FindFirstChild(name)
                                if v then
                                    v.Parent = ls
                                    _movedStats[player][name] = v
                                end
                            end
                        end
                    end)
                end
                local function _unMoveKills(player)
                    local moved = _movedStats[player]
                    if not moved then return end
                    _movedStats[player] = nil
                    for _, v in pairs(moved) do
                        pcall(function()
                            if v and v.Parent then
                                v.Parent = player
                            end
                        end)
                    end
                end
                local function _hookCharAdded(player)
                    if _charConns[player] then
                        pcall(function() _charConns[player]:Disconnect() end)
                    end
                    _charConns[player] = player.CharacterAdded:Connect(function()
                        task.wait(1)  -- let the game set up leaderstats after respawn
                        _moveKills(player)
                    end)
                end
                TabMiscExtra:AddToggle("ShowHiddenKills", {
                    Text    = "Show Hidden Kills",
                    Default = false,
                    Callback = function(val)
                        if val then
                            for _, p in ipairs(Players:GetPlayers()) do
                                _moveKills(p)
                                _hookCharAdded(p)
                            end
                            _playerAddedConn = Players.PlayerAdded:Connect(function(p)
                                task.wait(1)
                                _moveKills(p)
                                _hookCharAdded(p)
                            end)
                        else
                            if _playerAddedConn then _playerAddedConn:Disconnect() _playerAddedConn = nil end
                            for p, conn in pairs(_charConns) do
                                pcall(function() conn:Disconnect() end)
                                _charConns[p] = nil
                            end
                            local toProcess = {}
                            for p in pairs(_movedStats) do toProcess[#toProcess + 1] = p end
                            for _, p in ipairs(toProcess) do _unMoveKills(p) end
                        end
                    end,
                })
            end
            TabMiscExtra:AddToggle("ChatFlooder", {
                Text    = "Chat Flooder",
                Default = false,
                Callback = function(val)
                    if not val then return end
                    task.spawn(function()
                        while Toggles.ChatFlooder and Toggles.ChatFlooder.Value do
                            _extraSendMsg(_extraRandStr(200))
                            local t0 = tick()
                            local delay = Options.ChatFlooderDelay and Options.ChatFlooderDelay.Value or 3.5
                            repeat task.wait() until tick() >= t0 + delay
                                or not (Toggles.ChatFlooder and Toggles.ChatFlooder.Value)
                        end
                    end)
                end,
            })
            TabMiscExtra:AddSlider("ChatFlooderDelay", {
                Text     = "Chat Flooder Delay",
                Default  = 3.5,
                Min      = 0.5,
                Max      = 5,
                Rounding = 1,
            })
            table.insert(CleanupTasks, function()
        pcall(function() Toggles.ChatFlooder:SetValue(false) end)
            end)
            -- ── SAVE POSITION ON DEATH ────────────────────────────────────────────
            do
                local _savePos   = nil
                local _trackConn = nil
                local _respConn  = nil

                -- tracks a specific character's root; stops automatically when
                -- root is destroyed so _savePos always holds the LAST valid position.
                -- also hooks Died to snapshot position at the exact death moment
                -- before ragdoll physics can drift the body anywhere.
                local function _trackChar(char)
                    if _trackConn then pcall(function() _trackConn:Disconnect() end) _trackConn = nil end
                    if not char then return end
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if not root then return end

                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:GetPropertyChangedSignal("Health"):Connect(function()
                            if hum.Health > 0 then return end
                            -- Health just hit 0 — fires before Died, before ragdoll,
                            -- before anything. Kill the loop and freeze position here.
                            if _trackConn then
                                pcall(function() _trackConn:Disconnect() end)
                                _trackConn = nil
                            end
                            local r = char:FindFirstChild("HumanoidRootPart")
                            if r then _savePos = r.Position end
                        end)
                    end

                    _trackConn = RunService.Heartbeat:Connect(function()
                        if root.Parent then
                            _savePos = root.Position
                        else
                            pcall(function() _trackConn:Disconnect() end)
                            _trackConn = nil
                        end
                    end)
                end

                TabMiscExtra:AddToggle("SavePosOnDeath", {
                    Text    = "Save Position on Death",
                    Default = false,
                    Risky   = true,
                    Tooltip = "sometimes is unstable if you get killed high, but it's rare.",
                    Callback = function(val)
                        if val then
                            _trackChar(lp.Character)

                            _respConn = lp.CharacterAdded:Connect(function(newChar)
                                -- snapshot before _savePos can update for the new char
                                local snapshot = _savePos
                                task.spawn(function()
                                    local root = newChar:WaitForChild("HumanoidRootPart", 10)
                                    local hum  = newChar:WaitForChild("Humanoid", 10)
                                    if not root or not hum then return end
                                    if snapshot then
                                        -- Wait until the humanoid is alive and past None state —
                                        -- spawn logic has settled by then, so one teleport wins cleanly.
                                        repeat task.wait() until
                                            hum.Health > 0
                                            and hum:GetState() ~= Enum.HumanoidStateType.None
                                            and hum:GetState() ~= Enum.HumanoidStateType.Dead
                                        pcall(function() root.CFrame = CFrame.new(snapshot) end)
                                    end
                                    _trackChar(newChar)
                                end)
                            end)
                        else
                            if _trackConn then pcall(function() _trackConn:Disconnect() end) _trackConn = nil end
                            if _respConn  then pcall(function() _respConn:Disconnect()  end) _respConn  = nil end
                        end
                    end,
                })

                table.insert(CleanupTasks, function()
                    pcall(function() Toggles.SavePosOnDeath:SetValue(false) end)
                    if _trackConn then pcall(function() _trackConn:Disconnect() end) _trackConn = nil end
                    if _respConn  then pcall(function() _respConn:Disconnect()  end) _respConn  = nil end
                end)
            end
            -- ── END SAVE POSITION ON DEATH ────────────────────────────────────────
            -- ── PING SPOOFER ──────────────────────────────────────────────────────
            do
                local _pingSpoofSupported = type(getrawmetatable) == "function"
                    and type(setreadonly)      == "function"
                    and type(newcclosure)      == "function"
                    and type(getnamecallmethod) == "function"

                local _pingMtHooked = false
                local _pingOrigNc   = nil
                local _pingMt       = nil

                local function _hookPing()
                    if _pingMtHooked or not _pingSpoofSupported then return end
                    pcall(function()
                        _pingMt = getrawmetatable(game)
                        setreadonly(_pingMt, false)
                        _pingOrigNc = _pingMt.__namecall
                        _pingMt.__namecall = newcclosure(function(self, ...)
                            local method = getnamecallmethod()
                            if method == "FireServer" then
                                local args = {...}
                                if type(args[1]) == "table" and args[1].Goal == "ReportPing" then
                                    args[1].ms = tonumber(Options.PingSpoofMs and Options.PingSpoofMs.Value) or 0
                                    return _pingOrigNc(self, unpack(args))
                                end
                            end
                            return _pingOrigNc(self, ...)
                        end)
                        setreadonly(_pingMt, true)
                        _pingMtHooked = true
                    end)
                end

                local function _unhookPing()
                    if not _pingMtHooked or not _pingMt or not _pingOrigNc then return end
                    pcall(function()
                        setreadonly(_pingMt, false)
                        _pingMt.__namecall = _pingOrigNc
                        setreadonly(_pingMt, true)
                    end)
                    _pingMtHooked = false
                    _pingOrigNc   = nil
                end

                local _noSupportTip = "your executor doesn't support this"

                TabMiscLeaderboard:AddToggle("PingSpoof", {
                    Text     = "Ping Spoofer",
                    Default  = false,
                    Disabled = not _pingSpoofSupported,
                    Tooltip  = not _pingSpoofSupported and _noSupportTip or nil,
                    Callback = function(val)
                        if not _pingSpoofSupported then
                            pcall(function() Toggles.PingSpoof:SetValue(false) end)
                            return
                        end
                        if val then _hookPing() else _unhookPing() end
                    end,
                })
                TabMiscLeaderboard:AddInput("PingSpoofMs", {
                    Text        = "Spoofed Ping (ms)",
                    Default     = "0",
                    Placeholder = "Enter ms...",
                    Numeric     = true,
                    Disabled    = not _pingSpoofSupported,
                    Tooltip     = not _pingSpoofSupported and _noSupportTip or nil,
                })
                table.insert(CleanupTasks, function()
                    pcall(function() Toggles.PingSpoof:SetValue(false) end)
                    _unhookPing()
                end)
            end
            -- ── END PING SPOOFER ──────────────────────────────────────────────────
        end
    end
    -- ── END EXTRA GROUPBOX ────────────────────────────────────────────────────
    do
        local BoxCustomM1 = TabMiscAnims
        local M1_IDS = {
            Bald    = {"10469493270","10469630950","10469639222","10469643643"},
            Hunter  = {"13532562418","13532600125","13532604085","13294471966"},
            Monster     = {"122482492364036","125882667406347","134822631853770","76602138940033"},
            ZombieAxe   = {"125361499827663","105701432344953","104293439261333","114460992057353"},
            ZombieDeagle= {"111644455066361","112778933066374","80488470577181","117726521294150"},
            ZombieShotgun={"97702234977209","136834606687014","137556620675474","115406134600395"},
            Purple  = {"17889458563","17889461810","17889471098","17889290569"},
            Cyborg  = {"13491635433","13296577783","13295919399","13295936866"},
            Ninja   = {"13370310513","13390230973","13378751717","13378708199"},
            Batter  = {"14004222985","13997092940","14001963401","14136436157"},
            Blade   = {"15259161390","15240216931","15240176873","15162694192"},
            Esper   = {"16515503507","16515520431","16515448089","16552234590"},
            KJ      = {"17325510002","17325513870","17325522388","17325537719"},
            Tech    = {"123005629431309","100059874351664","104895379416342","134775406437626"},
            Lightning = {"89044067797964","74334194837918","94353845974131","80601239139774"},
            Brother = {"105509665019040","112557609215008","91771160499452","120026952948332"},
            Emerge  = {"132868185794966","116239885597558","","89443748022966"},
        }
        local M1_SLOT_LOOKUP = {}
        for _, ids in pairs(M1_IDS) do
            for slot, id in ipairs(ids) do
                M1_SLOT_LOOKUP[id] = slot
            end
        end
        local CHAR_LABELS = {
            "Default","Random",
            "Saitama","Garou","Suiryu",
            "Genos","Sonic","Metal Bat","Atomic Samurai",
            "Tatsumaki","KJ","Child Emperor","Lightning Max","My Brother",
            "Monster Garou",
            "Zombie Man (Axe)","Zombie Man (Deagle)","Zombie Man (Shotgun)",
            "Emerge",
        }
        local _cm1RandomPool = {
            "Bald","Hunter","Purple","Cyborg",
            "Ninja","Batter","Blade","Esper","KJ","Tech","Lightning",
        }
        local LABEL_TO_ATTR = {
            ["Saitama"]="Bald",["Garou"]="Hunter",["Monster Garou"]="Monster",
            ["Suiryu"]="Purple",["Genos"]="Cyborg",["Sonic"]="Ninja",
            ["Metal Bat"]="Batter",["Atomic Samurai"]="Blade",
            ["Tatsumaki"]="Esper",["KJ"]="KJ",["Child Emperor"]="Tech",
            ["Lightning Max"]="Lightning",
            ["My Brother"]="Brother",
            ["Emerge"]="Emerge",
            ["Zombie Man (Axe)"]="ZombieAxe",
            ["Zombie Man (Deagle)"]="ZombieDeagle",
            ["Zombie Man (Shotgun)"]="ZombieShotgun",
        }
        BoxCustomM1:AddToggle("CustomM1Enabled", {
            Text    = "Enable Custom M1's",
            Default = false,
        })
        BoxCustomM1:AddDivider()
        for i = 1, 4 do
            local slotLabels = CHAR_LABELS
            if i == 3 then
                slotLabels = {}
                for _, v in ipairs(CHAR_LABELS) do
                    if v ~= "Emerge" then table.insert(slotLabels, v) end
                end
            end
            BoxCustomM1:AddDropdown("CustomM1_Slot"..i, {
                Text = "M1 "..i, Values = slotLabels,
                Default = 1, Multi = false, Searchable = false,
            })
        end


        local function _cm1GetCustomId(slot)
            local opt = Options["CustomM1_Slot"..slot]
            if not opt or opt.Value == "Default" then return nil, nil end
            local attr
            if opt.Value == "Random" then
                attr = _cm1RandomPool[math.random(1, #_cm1RandomPool)]
            else
                attr = LABEL_TO_ATTR[opt.Value]
            end
            if not attr then return nil, nil end
            local ids = M1_IDS[attr]
            return ids and ids[slot], attr
        end
        local _cm1Conn      = nil
        local _cm1LoopConn  = nil
        local _cm1LastHum   = nil
        local _cm1CustomTracks = {}
        local function _cm1StopCustoms()
            for _, ct in pairs(_cm1CustomTracks) do
                pcall(function()
                    if ct.IsPlaying then ct:Stop() end
                end)
            end
            table.clear(_cm1CustomTracks)
        end
        local function _cm1Hook(hum)
            if _cm1Conn then _cm1Conn:Disconnect() _cm1Conn = nil end
            _cm1StopCustoms()
            _cm1LastHum = hum
            if not hum then return end
            _cm1Conn = hum.AnimationPlayed:Connect(function(track)
                if not Toggles.CustomM1Enabled.Value then return end
                local animId = track.Animation and track.Animation.AnimationId or ""
                local rawId  = animId:match("%d+")
                if not rawId then return end
                local slot = M1_SLOT_LOOKUP[rawId]
                if not slot then return end
                local customId, attr = _cm1GetCustomId(slot)
                if not customId then return end
                if customId == rawId then return end
                _cm1StopCustoms()
                track:AdjustSpeed(0)
                track:AdjustWeight(-9999999, false)
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://"..customId
                local customTrack = hum:LoadAnimation(anim)
                _cm1CustomTracks[#_cm1CustomTracks + 1] = customTrack
                customTrack.Priority = Enum.AnimationPriority.Action3
                customTrack:Play(0)
            end)
        end
        _cm1LoopConn = RunService.Heartbeat:Connect(function()
            local char = lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum ~= _cm1LastHum then
                _cm1Hook(hum)
            end
        end)
        table.insert(CleanupTasks, function()
            if _cm1Conn     then _cm1Conn:Disconnect()     _cm1Conn     = nil end
            if _cm1LoopConn then _cm1LoopConn:Disconnect() _cm1LoopConn = nil end
            _cm1StopCustoms()
            _cm1LastHum = nil
        pcall(function() Toggles.CustomM1Enabled:SetValue(false) end)
        end)
        --[[ M1 Effects (commented out - will be re-enabled later)
        BoxCustomM1:AddDivider()
        BoxCustomM1:AddDropdown("M1EffectsStyle", {
            Text    = "M1 Effects",
            Values  = { "Off", "Infinity", "Gojo" },
            Default = 1, Multi = false, Searchable = false,
        })
        do
            local _m1LastDropVal = ""
            if Options.M1EffectsStyle then
                Options.M1EffectsStyle:OnChanged(function(val)
                    if val ~= "" and val ~= "Off" and val == _m1LastDropVal then
                        pcall(function() Options.M1EffectsStyle:SetValue("Off") end)
                        _m1LastDropVal = ""
                        return
                    end
                    _m1LastDropVal = (val == "Off") and "" or (val or "")
                end)
            end
        end
        BoxCustomM1:AddSlider("M1EffectsVolume", {
            Text    = "Volume",
            Default = 1, Min = 0, Max = 1, Rounding = 1,
        })
        do
            local function _m1FxVol()
                return Options.M1EffectsVolume and Options.M1EffectsVolume.Value or 1
            end
            -- Preload M1 effect sounds to avoid delay/cut on first hit
            task.spawn(function()
                game:GetService("ContentProvider"):PreloadAsync({
                    "rbxassetid://13064223399",
                    "rbxassetid://13064223291",
                    "rbxassetid://13064223483",
                })
            end)
            -- slot sound IDs identical to KadeGojo u94
            local _M1FX_SLOT_SOUNDS = {
                [1] = "rbxassetid://13064223399",
                [2] = "rbxassetid://13064223291",
                [3] = "rbxassetid://13064223483",
                [4] = "rbxassetid://13064223399",
            }
            -- flat animId -> SoundId map for every char/slot
            local _M1FX_DATA = {}
            for _, ids in pairs(M1_IDS) do
                for slot, id in ipairs(ids) do
                    _M1FX_DATA[id] = { SoundId = _M1FX_SLOT_SOUNDS[slot], Slot = slot }
                end
            end
            -- downslam and uppercut are handled via their own AnimationPlayed hooks below

            -- Gojo asset pack (rbxassetid://97406440754007) → Hit.Light / Hit.Heavy VFX
            local _gojoAsset = nil
            task.spawn(function()
                local rs = game:GetService("ReplicatedStorage")
                _gojoAsset = rs.Resources:FindFirstChild("Gojo")
                if not _gojoAsset then
                    local ok, res = pcall(function()
                        return game:GetObjects("rbxassetid://97406440754007")[1]
                    end)
                    if ok and res then
                        res.Name   = "Gojo"
                        res.Parent = rs.Resources
                        _gojoAsset = res
                    end
                end
            end)

            -- EmitAll: respects EmitCount/EmitDelay attributes per ParticleEmitter (identical to KadeGojo)
            local function _emitAll(model, count)
                for _, desc in pairs(model:GetDescendants()) do
                    if desc:IsA("ParticleEmitter") then
                        local n = desc:GetAttribute("EmitCount") or count
                        local d = desc:GetAttribute("EmitDelay") or 0
                        task.delay(d, function() desc:Emit(n) end)
                    end
                end
            end

            local _m1FxAnimator  = nil
            local _m1FxTargConns = {}
            local _m1FxLiveConn  = nil
            local _m1FxHbConn    = nil

            -- identical to KadeGojo IsAnimPlaying
            local function _m1FxIsAnimPlaying(animId)
                if not _m1FxAnimator then return false end
                for _, track in pairs(_m1FxAnimator:GetPlayingAnimationTracks()) do
                    if track.Animation and track.Animation.AnimationId:match(tostring(animId)) then
                        return true
                    end
                end
                return false
            end

            local function _m1FxGetActiveM1()
                for id, data in pairs(_M1FX_DATA) do
                    if _m1FxIsAnimPlaying(id) then return data end
                end
                -- also check custom swap tracks
                for _, ct in pairs(_cm1CustomTracks) do
                    if ct.IsPlaying then
                        local rawId = ct.Animation and ct.Animation.AnimationId:match("%d+")
                        if rawId and _M1FX_DATA[rawId] then return _M1FX_DATA[rawId] end
                    end
                end
                return nil
            end

            -- Returns the local asset sound for Gojo style.
            -- Returns nil if the file is not downloaded yet (no fallback).
            local function _m1FxGojoSound(slot)
                local path = "Revenant/assets/M1Hit"..tostring(slot)..".mp3"
                if typeof(isfile) == "function" and isfile(path) then
                    return getcustomasset(path)
                end
                return nil
            end

            -- identical structure to KadeGojo u190
            local function _m1FxWatchChar(targetChar)
                if _m1FxTargConns[targetChar] then return end
                local hum = targetChar:WaitForChild("Humanoid", 1)
                if not hum then return end
                local _Health = hum.Health
                _m1FxTargConns[targetChar] = hum:GetPropertyChangedSignal("Health"):Connect(function()
                    if targetChar:GetAttribute("LastHit") == lp.Name then
                        local dmg = _Health - hum.Health
                        if hum.Health < _Health then
                            local activeM1 = _m1FxGetActiveM1()
                            if hum.Health > 0 and activeM1 and dmg > 1 then
                                task.spawn(function()
                                    local style = Options.M1EffectsStyle and Options.M1EffectsStyle.Value
                                    if not style or style == "Off" then return end
                                    local torso = targetChar:FindFirstChild("Torso")
                                    if not torso then return end

                                    if style == "Gojo" then
                                        -- Gojo: usa Hit.Light / Hit.Heavy do asset pack (rbxassetid://97406440754007)
                                        local soundId = _m1FxGojoSound(activeM1.Slot or 1)
                                        if not soundId then return end
                                        if not _gojoAsset then return end
                                        local _HitFolder = _gojoAsset:FindFirstChild("Hit", true)
                                        if not _HitFolder then return end

                                        local isHeavy = (activeM1.Slot == 4)
                                        local hitModel = isHeavy and _HitFolder:FindFirstChild("Heavy")
                                                                  or _HitFolder:FindFirstChild("Light")
                                        if not hitModel then return end

                                        local vfx = hitModel:Clone()
                                        local thrown = workspace:FindFirstChild("Thrown") or workspace
                                        vfx.Parent    = thrown
                                        vfx.Anchored  = false

                                        local myHRP     = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                                        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                                        if myHRP and targetHRP then
                                            vfx.CFrame = CFrame.new(targetHRP.Position, myHRP.Position)
                                        else
                                            vfx.CFrame = torso.CFrame
                                        end

                                        _emitAll(vfx, 1)

                                        local snd = Instance.new("Sound", torso)
                                        snd.SoundId = soundId
                                        snd.Volume = _m1FxVol()
                                        snd.PlayOnRemove = true
                                        snd:Destroy()

                                        game:GetService("Debris"):AddItem(vfx, isHeavy and 2 or 0.6)
                                        return
                                    end

                                    -- Infinity style
                                    local res = game:GetService("ReplicatedStorage"):FindFirstChild("Resources")
                                    if not res then return end
                                    local de = res:FindFirstChild("KJEffects")
                                        and res.KJEffects:FindFirstChild("DropkickExtra")
                                    if not de then return end
                                    local firstHit = de:FindFirstChild("firstHit")
                                    if not firstHit then return end

                                    local snd = Instance.new("Sound", torso)
                                    snd.SoundId = activeM1.SoundId
                                    snd.Volume = _m1FxVol()
                                    snd.PlayOnRemove = true
                                    snd:Destroy()

                                    local vfx = firstHit:Clone()
                                    for _, desc in pairs(vfx:GetDescendants()) do
                                        if desc:IsA("BasePart") then
                                            desc.CanCollide = false
                                            desc.Anchored   = true
                                            desc.Massless   = true
                                        end
                                    end
                                    if vfx:IsA("BasePart") then
                                        vfx.CanCollide = false
                                        vfx.Anchored   = true
                                        vfx.Massless   = true
                                    end
                                    vfx.Parent = workspace
                                    vfx.CFrame  = torso.CFrame
                                    local windAtt
                                    for _, desc in pairs(vfx:GetDescendants()) do
                                        if desc.Name == "Wind" then windAtt = desc.Parent end
                                    end
                                    if windAtt then windAtt.Wind:Emit(30) end
                                    game:GetService("Debris"):AddItem(vfx, 2)
                                end)
                            end
                        end
                    end
                    _Health = hum.Health
                end)
            end

            -- watch workspace.Live like KadeGojo
            local _m1FxLive = workspace:FindFirstChild("Live")
            if _m1FxLive then
                for _, child in pairs(_m1FxLive:GetChildren()) do
                    if child ~= lp.Character then
                        task.spawn(_m1FxWatchChar, child)
                    end
                end
                _m1FxLiveConn = _m1FxLive.ChildAdded:Connect(function(child)
                    task.spawn(_m1FxWatchChar, child)
                end)
            end

            -- keep animator ref updated via Heartbeat
            _m1FxHbConn = RunService.Heartbeat:Connect(function()
                local char = lp.Character
                if not char then _m1FxAnimator = nil return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    _m1FxAnimator = hum:FindFirstChildOfClass("Animator") or _m1FxAnimator
                end
            end)

            -- Downslam (10470104242): 100% identical to KadeGojoV1 implementation.
            -- Uses its own AnimationPlayed + OverlapParams + Health:Changed chain.
            local _m1FxDsConn    = nil
            local _m1FxDsHbConn  = nil
            local _m1FxDsLastHum = nil

            local function _m1FxDsHook(hum)
                if _m1FxDsConn then _m1FxDsConn:Disconnect() _m1FxDsConn = nil end
                _m1FxDsLastHum = hum
                if not hum then return end
                _m1FxDsConn = hum.AnimationPlayed:Connect(function(track)
                    local style = Options.M1EffectsStyle and Options.M1EffectsStyle.Value
                    if not style or style == "Off" then return end
                    local id = track.Animation and track.Animation.AnimationId:match("%d+") or ""
                    if id ~= "10470104242" then return end

                    local char = lp.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    task.spawn(function()
                        task.wait(0.25)

                        local u117 = nil
                        local params = OverlapParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances = { char }
                        local parts = workspace:GetPartBoundsInRadius(
                            (hrp.CFrame * CFrame.new(0, 0, -2.5)).Position, 4.4, params
                        )
                        for _, part in pairs(parts) do
                            if part.Parent:FindFirstChildOfClass("Humanoid")
                                and part.Parent.Name ~= lp.Name then
                                u117 = part.Parent
                            end
                        end

                        local u126 = u117 and u117:FindFirstChildOfClass("Humanoid") or nil
                        if not (u117 and u126) then return end

                        local _Health = u126.Health
                        local u125 = nil
                        local u139 = u126:GetPropertyChangedSignal("Health"):Connect(function()
                            if u126.Health ~= _Health and u126.Health < _Health then
                                if u125 then u125:Disconnect() end

                                local torso = u117:FindFirstChild("Torso")
                                if not torso then return end

                                local _dsStyle = Options.M1EffectsStyle and Options.M1EffectsStyle.Value

                                if _dsStyle == "Gojo" then
                                    -- Gojo: Hit.Heavy do asset pack, Anchored=false, workspace.Thrown
                                    local soundId = _m1FxGojoSound(4)
                                    if not soundId or not _gojoAsset then
                                        _Health = u126.Health return
                                    end
                                    local _HitFolder = _gojoAsset:FindFirstChild("Hit", true)
                                    if not _HitFolder then _Health = u126.Health return end
                                    local hitModel = _HitFolder:FindFirstChild("Heavy")
                                    if not hitModel then _Health = u126.Health return end

                                    local vfx = hitModel:Clone()
                                    local thrown = workspace:FindFirstChild("Thrown") or workspace
                                    vfx.Parent   = thrown
                                    vfx.Anchored = false

                                    local myHRP     = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                                    local targetHRP = u117:FindFirstChild("HumanoidRootPart")
                                    if myHRP and targetHRP then
                                        vfx.CFrame = CFrame.new(targetHRP.Position, myHRP.Position)
                                    else
                                        vfx.CFrame = torso.CFrame
                                    end

                                    _emitAll(vfx, 1)

                                    local snd = Instance.new("Sound", torso)
                                    snd.SoundId = soundId
                                    snd.Volume = _m1FxVol()
                                    snd.PlayOnRemove = true
                                    snd:Destroy()

                                    game:GetService("Debris"):AddItem(vfx, 2)
                                    _Health = u126.Health
                                    return
                                end

                                -- Infinity: firstHit + WallFX (Anchored, workspace)
                                local _Sound = Instance.new("Sound", torso)
                                _Sound.SoundId = "rbxassetid://13064223399"
                                _Sound.Volume = _m1FxVol()
                                _Sound.PlayOnRemove = true
                                _Sound:Destroy()

                                local res = game:GetService("ReplicatedStorage"):FindFirstChild("Resources")
                                if not res then return end

                                local v129 = res.KJEffects.DropkickExtra.firstHit:Clone()
                                local v130 = res.Sorcerer.WallFX:Clone()

                                v130.Parent = workspace
                                v130:PivotTo(
                                    hrp.CFrame
                                    * CFrame.new(0, -2.9, -4)
                                    * CFrame.fromEulerAnglesXYZ(math.rad(90), 0, 0)
                                )
                                for _, child in pairs(v130.FirstSlam.Attachment:GetChildren()) do
                                    if child:IsA("ParticleEmitter") then
                                        child:Emit(2)
                                    end
                                end

                                v129.Parent = workspace
                                v129.CFrame = torso.CFrame
                                local secondAtt = nil
                                for _, desc in pairs(v129:GetDescendants()) do
                                    if desc.Name == "Wind" then secondAtt = desc.Parent end
                                end
                                if secondAtt then secondAtt.Wind:Emit(30) end

                                task.delay(4, function() pcall(function() v129:Destroy() end) end)
                                task.delay(4, function() pcall(function() v130:Destroy() end) end)
                            end
                            _Health = u126.Health
                        end)
                        u125 = u139
                        task.delay(0.25, function() u139:Disconnect() end)
                    end)
                end)
            end

            _m1FxDsHbConn = RunService.Heartbeat:Connect(function()
                local char = lp.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum ~= _m1FxDsLastHum then _m1FxDsHook(hum) end
            end)

            -- Uppercut (12510170988): same structure as downslam but plays the M4 hit
            -- effect (firstHit VFX + slot-4 sound, vol=2) without WallFX.
            local _m1FxUcConn    = nil
            local _m1FxUcHbConn  = nil
            local _m1FxUcLastHum = nil

            local function _m1FxUcHook(hum)
                if _m1FxUcConn then _m1FxUcConn:Disconnect() _m1FxUcConn = nil end
                _m1FxUcLastHum = hum
                if not hum then return end
                _m1FxUcConn = hum.AnimationPlayed:Connect(function(track)
                    local style = Options.M1EffectsStyle and Options.M1EffectsStyle.Value
                    if not style or style == "Off" then return end
                    local id = track.Animation and track.Animation.AnimationId:match("%d+") or ""
                    if id ~= "12510170988" then return end

                    local char = lp.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    task.spawn(function()
                        local u281 = nil
                        local params = OverlapParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances = { char }
                        local parts = workspace:GetPartBoundsInRadius(
                            (hrp.CFrame * CFrame.new(0, 0, -2.5)).Position, 6, params
                        )
                        for _, part in pairs(parts) do
                            if part.Parent:FindFirstChildOfClass("Humanoid")
                                and part.Parent.Name ~= lp.Name then
                                u281 = part.Parent
                            end
                        end

                        local u289 = u281 and u281:FindFirstChildOfClass("Humanoid") or nil
                        if not (u281 and u289) then return end

                        local _Health = u289.Health
                        local u288 = nil
                        local u304 = u289:GetPropertyChangedSignal("Health"):Connect(function()
                            if u289.Health ~= _Health and u289.Health < _Health then
                                if u288 then u288:Disconnect() end

                                local torso = u281:FindFirstChild("Torso")
                                if not torso then return end

                                local _ucStyle = Options.M1EffectsStyle and Options.M1EffectsStyle.Value

                                if _ucStyle == "Gojo" then
                                    -- Gojo: Hit.Heavy, Anchored=false, CFrame = attacker HRP (igual original)
                                    local soundId = _m1FxGojoSound(4)
                                    if not soundId or not _gojoAsset then
                                        _Health = u289.Health return
                                    end
                                    local _HitFolder = _gojoAsset:FindFirstChild("Hit", true)
                                    if not _HitFolder then _Health = u289.Health return end
                                    local hitModel = _HitFolder:FindFirstChild("Heavy")
                                    if not hitModel then _Health = u289.Health return end

                                    local vfx = hitModel:Clone()
                                    local thrown = workspace:FindFirstChild("Thrown") or workspace
                                    vfx.Parent   = thrown
                                    vfx.Anchored = false
                                    -- Uppercut: usa CFrame do atacante (como original: v162.CFrame = v160 and u139.CFrame)
                                    vfx.CFrame = hrp.CFrame

                                    _emitAll(vfx, 1)

                                    local snd = Instance.new("Sound", torso)
                                    snd.SoundId = soundId
                                    snd.Volume = _m1FxVol()
                                    snd.PlayOnRemove = true
                                    snd:Destroy()

                                    game:GetService("Debris"):AddItem(vfx, 2)
                                    _Health = u289.Health
                                    return
                                end

                                -- Infinity: firstHit (Anchored, workspace)
                                local hitSound = Instance.new("Sound", torso)
                                hitSound.SoundId = _M1FX_SLOT_SOUNDS[4]
                                hitSound.Volume = _m1FxVol()
                                hitSound.PlayOnRemove = true
                                hitSound:Destroy()

                                local res = game:GetService("ReplicatedStorage"):FindFirstChild("Resources")
                                if not res then _Health = u289.Health return end
                                local vfx = res.KJEffects.DropkickExtra.firstHit:Clone()
                                for _, desc in pairs(vfx:GetDescendants()) do
                                    if desc:IsA("BasePart") then
                                        desc.CanCollide = false
                                        desc.Anchored   = true
                                        desc.Massless   = true
                                    end
                                end
                                if vfx:IsA("BasePart") then
                                    vfx.CanCollide = false
                                    vfx.Anchored   = true
                                    vfx.Massless   = true
                                end
                                vfx.Parent = workspace
                                vfx.CFrame  = torso.CFrame
                                local windAtt = nil
                                for _, desc in pairs(vfx:GetDescendants()) do
                                    if desc.Name == "Wind" then windAtt = desc.Parent end
                                end
                                if windAtt then windAtt.Wind:Emit(30) end
                                game:GetService("Debris"):AddItem(vfx, 2)
                            end
                            _Health = u289.Health
                        end)
                        u288 = u304
                        task.delay(1, function() u304:Disconnect() end)
                    end)
                end)
            end

            _m1FxUcHbConn = RunService.Heartbeat:Connect(function()
                local char = lp.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum ~= _m1FxUcLastHum then _m1FxUcHook(hum) end
            end)

            table.insert(CleanupTasks, function()
                for _, conn in pairs(_m1FxTargConns) do
                    pcall(function() conn:Disconnect() end)
                end
                table.clear(_m1FxTargConns)
                if _m1FxLiveConn  then _m1FxLiveConn:Disconnect()  _m1FxLiveConn  = nil end
                if _m1FxHbConn    then _m1FxHbConn:Disconnect()    _m1FxHbConn    = nil end
                if _m1FxDsConn    then _m1FxDsConn:Disconnect()    _m1FxDsConn    = nil end
                if _m1FxDsHbConn  then _m1FxDsHbConn:Disconnect()  _m1FxDsHbConn  = nil end
                if _m1FxUcConn    then _m1FxUcConn:Disconnect()    _m1FxUcConn    = nil end
                if _m1FxUcHbConn  then _m1FxUcHbConn:Disconnect()  _m1FxUcHbConn  = nil end
                _m1FxAnimator  = nil
                _m1FxDsLastHum = nil
                _m1FxUcLastHum = nil
                pcall(function() Options.M1EffectsStyle:SetValue("Off") end)
            end)
        end
        --]] -- end M1 Effects
        BoxCustomM1:AddDivider()
        BoxCustomM1:AddToggle("CustomDownslamEnabled", {
            Text    = "Enable Custom Downslam",
            Default = false,
        })
        BoxCustomM1:AddDropdown("CustomDownslam_Anim", {
            Text   = "Custom Downslam",
            Values = { "Default", "Random", "Flip", "Down Fall", "Hard Press", "Useless" },
            Default = 1, Multi = false, Searchable = false,
        })
        local _cdsConn     = nil
        local _cdsLoopConn = nil
        local _cdsLastHum  = nil
        local DOWNSLAM_IDS = {
            ["Flip"]       = { id = "17859055671", timePos = 0.1,  speed = 2.0  },
            ["Down Fall"]  = { id = "17858878027", timePos = 0.25, speed = nil  },
            ["Hard Press"] = { id = "18464356233", timePos = 0.5,  speed = 3.0  },
            ["Useless"]    = { id = "16571909908", timePos = 2.25, speed = 0.75 },
        }
        local function _cdsHook(hum)
            if _cdsConn then _cdsConn:Disconnect() _cdsConn = nil end
            _cdsLastHum = hum
            if not hum then return end
            _cdsConn = hum.AnimationPlayed:Connect(function(track)
                if not Toggles.CustomDownslamEnabled.Value then return end
                local animId = track.Animation and track.Animation.AnimationId or ""
                if not animId:match("10470104242") then return end
                local opt = Options.CustomDownslam_Anim and Options.CustomDownslam_Anim.Value or "Default"
                if opt == "Random" then
                    local pool = { "Flip", "Down Fall", "Hard Press", "Useless" }
                    opt = pool[math.random(1, #pool)]
                end
                local cfg = DOWNSLAM_IDS[opt]
                if not cfg then return end
                track:AdjustWeight(-9999999, false)
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. cfg.id
                local ct = hum:LoadAnimation(anim)
                ct.Priority = Enum.AnimationPriority.Action3
                ct:Play(0.1)
                if cfg.speed   then ct:AdjustSpeed(cfg.speed) end
                if cfg.timePos then ct.TimePosition = cfg.timePos end
                track.Stopped:Connect(function()
                    pcall(function() ct:Stop(0.25) end)
                end)
            end)
        end
        local _cdsPreloaded = false
        local function _cdsPreload(hum)
            if not hum then return end
            _cdsPreloaded = false
            task.spawn(function()
                local char = lp.Character
                if not char then return end
                local animator = hum:FindFirstChildOfClass("Animator")
                    or hum:WaitForChild("Animator", 5)
                if not animator then return end
                local _bvPre = nil
                local function _zeroYPre(obj)
                    if obj:IsA("BodyVelocity") then
                        obj.Velocity = Vector3.new(obj.Velocity.X, 0, obj.Velocity.Z)
                    end
                end
                _bvPre = char.DescendantAdded:Connect(_zeroYPre)
                for _, d in pairs(char:GetDescendants()) do _zeroYPre(d) end
                if _bvPre then _bvPre:Disconnect() _bvPre = nil end
                _cdsPreloaded = true
            end)
        end
        _cdsLoopConn = RunService.Heartbeat:Connect(function()
            local char = lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum ~= _cdsLastHum then
                _cdsHook(hum)
                _cdsPreload(hum)
            end
        end)
        task.spawn(function()
            local char = lp.Character or lp.CharacterAdded:Wait()
            local hum  = char and (char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3))
            if hum then _cdsPreload(hum) end
        end)
        table.insert(CleanupTasks, function()
            if _cdsConn     then _cdsConn:Disconnect()     _cdsConn     = nil end
            if _cdsLoopConn then _cdsLoopConn:Disconnect() _cdsLoopConn = nil end
            _cdsLastHum = nil
        pcall(function() Toggles.CustomDownslamEnabled:SetValue(false) end)
        end)
        BoxCustomM1:AddDivider()
        BoxCustomM1:AddToggle("CustomUppercutEnabled", {
            Text    = "Enable Custom Uppercut",
            Default = false,
        })
        local _ucAnimOptions = {
            { name = "Throw", id = "136370737633649", timePos = 1,   speed = 1.2, stopAfter = 0.3, stopFade = 1 },
            { name = "Heavy",         id = "14900168720",     timePos = 1.3, speed = 1,   stopAfter = nil },
            { name = "Simple", id = "129123960742438", timePos = 2.8, speed = nil, stopAfter = nil, stopFade = 0.2 },
            { name = "Ball Might", id = "125265459886863", timePos = 5.20, speed = 1.3, stopAfter = nil, stopTrigger = 6.15, stopFade = 0.2 },
        }
        local _ucAnimValues = { "Default", "Random" }
        for _, v in ipairs(_ucAnimOptions) do table.insert(_ucAnimValues, v.name) end
        BoxCustomM1:AddDropdown("CustomUppercut_Anim", {
            Text   = "Custom Uppercut",
            Values = _ucAnimValues,
            Default = 1, Multi = false, Searchable = false,
        })
        local _cucConn     = nil
        local _cucLoopConn = nil
        local _cucLastHum  = nil
        local function _cucHook(hum)
            if _cucConn then _cucConn:Disconnect() _cucConn = nil end
            _cucLastHum = hum
            if not hum then return end
            _cucConn = hum.AnimationPlayed:Connect(function(track)
                local id = track.Animation and track.Animation.AnimationId:match("%d+") or ""
                if id ~= "10503381238" then return end
                local _ucStyle = Options.M1EffectsStyle and Options.M1EffectsStyle.Value
                if _ucStyle and _ucStyle ~= "Off" then
                    task.spawn(function()
                        local char = lp.Character
                        if not char then return end
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        local _params = OverlapParams.new()
                        _params.FilterType = Enum.RaycastFilterType.Exclude
                        _params.FilterDescendantsInstances = { char }
                        local _parts = workspace:GetPartBoundsInRadius(
                            (hrp.CFrame * CFrame.new(0, 0, -2.5)).Position, 6, _params
                        )
                        local _target = nil
                        for _, part in pairs(_parts) do
                            if part.Parent:FindFirstChildOfClass("Humanoid")
                                and part.Parent.Name ~= lp.Name then
                                _target = part.Parent
                            end
                        end
                        if not _target then return end
                        local _targetHum = _target:FindFirstChildOfClass("Humanoid")
                        if not _targetHum then return end
                        local _initHealth = _targetHum.Health
                        local _hpConn = nil
                        _hpConn = _targetHum:GetPropertyChangedSignal("Health"):Connect(function()
                            if _targetHum.Health < _initHealth then
                                if _hpConn then _hpConn:Disconnect() _hpConn = nil end
                                local torso = _target:FindFirstChild("Torso")
                                if not torso then return end
                                local res = game:GetService("ReplicatedStorage"):FindFirstChild("Resources")
                                if not res then return end
                                local hitSound = Instance.new("Sound", torso)
                                hitSound.SoundId = "rbxassetid://13064223399"
                                hitSound.Volume = _m1FxVol()
                                hitSound.PlayOnRemove = true
                                hitSound:Destroy()
                                local vfx = res.KJEffects.DropkickExtra.firstHit:Clone()
                                for _, desc in pairs(vfx:GetDescendants()) do
                                    if desc:IsA("BasePart") then
                                        desc.CanCollide = false
                                        desc.Anchored   = true
                                        desc.Massless   = true
                                    end
                                end
                                if vfx:IsA("BasePart") then
                                    vfx.CanCollide = false
                                    vfx.Anchored   = true
                                    vfx.Massless   = true
                                end
                                vfx.Parent = workspace
                                vfx.CFrame  = torso.CFrame
                                local windAtt = nil
                                for _, desc in pairs(vfx:GetDescendants()) do
                                    if desc.Name == "Wind" then windAtt = desc.Parent end
                                end
                                if windAtt then windAtt.Wind:Emit(30) end
                                game:GetService("Debris"):AddItem(vfx, 2)
                            end
                            _initHealth = _targetHum.Health
                        end)
                        task.delay(1, function() if _hpConn then _hpConn:Disconnect() _hpConn = nil end end)
                    end)
                end
                if not Toggles.CustomUppercutEnabled.Value then return end
                local opt = Options.CustomUppercut_Anim and Options.CustomUppercut_Anim.Value or "Default"
                if opt == "Default" then return end
                local cfg = nil
                if opt == "Random" then
                    cfg = _ucAnimOptions[math.random(1, #_ucAnimOptions)]
                else
                    for _, v in ipairs(_ucAnimOptions) do
                        if v.name == opt then cfg = v break end
                    end
                end
                if not cfg then return end
                track:AdjustWeight(-9999999, false)
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. cfg.id
                local ct = hum:LoadAnimation(anim)
                ct.Priority = Enum.AnimationPriority.Action3
                ct:Play(0.1)
                if cfg.speed   then ct:AdjustSpeed(cfg.speed) end
                if cfg.timePos then ct.TimePosition = cfg.timePos end
                if cfg.stopTrigger then
                    -- stop when anim reaches exact timePosition
                    local _stConn
                    _stConn = RunService.Heartbeat:Connect(function()
                        if not ct.IsPlaying or ct.TimePosition >= cfg.stopTrigger then
                            if _stConn then _stConn:Disconnect() _stConn = nil end
                            pcall(function() ct:Stop(cfg.stopFade or 0) end)
                        end
                    end)
                elseif cfg.stopAfter then
                    task.delay(cfg.stopAfter, function()
                        pcall(function() ct:Stop(cfg.stopFade or 0) end)
                    end)
                else
                    track.Stopped:Once(function()
                        pcall(function() ct:Stop(cfg.stopFade or 0) end)
                    end)
                end
            end)
        end
        _cucLoopConn = RunService.Heartbeat:Connect(function()
            local char = lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum ~= _cucLastHum then _cucHook(hum) end
        end)
        table.insert(CleanupTasks, function()
            if _cucConn     then _cucConn:Disconnect()     _cucConn     = nil end
            if _cucLoopConn then _cucLoopConn:Disconnect() _cucLoopConn = nil end
            _cucLastHum = nil
        pcall(function() Toggles.CustomUppercutEnabled:SetValue(false) end)
        end)
    end
    local TweenService = game:GetService("TweenService")
    local BoxIdleAnim = TabMiscAnimsR
    local _idleAllValues = {
        "Normal","Random",
        "[DEF] Watch","[DEF] Casual","[DEF] Confident","[DEF] Fent Master","[DEF] Fly Idle",
        "[DEF] Aura","[DEF] Serious","[DEF] Rework","[DEF] Preparing","[DEF] Divine","[DEF] God",
        "[SG] Mayhem","[SG] Rainbow","[SG] Zyledon",
        "[SG] Persistence","[SG] Purity","[SG] Euclidean",
        "[SG] Equinox","[SG] Crazed","[SG] The Big Black",
        "[SG] Contaminant",
    }
    BoxIdleAnim:AddDropdown("IdleAnimation", {
        Values = _idleAllValues,
        Default = 1, Multi = false, Text = "Idle Animation",
        Searchable = true,
    })
    BoxIdleAnim:AddSlider("IdleAnimationStartFadeTime", {
        Text = "Idle Animation Start Fade Time", Default = 0.2, Min = 0.1, Max = 1, Rounding = 2,
    })
    BoxIdleAnim:AddSlider("IdleAnimationEndFadeTime", {
        Text = "Idle Animation End Fade Time", Default = 0.2, Min = 0.1, Max = 1, Rounding = 2,
    })
    local _refreshSGVFX
    BoxIdleAnim:AddToggle("SGVFXToggle", {
        Text    = "Enable SG VFX",
        Default = false,
        Callback = function() if _refreshSGVFX then _refreshSGVFX() end end,
    })
    local _idleConn       = nil
    local _idleK          = nil
    local _idleK2         = nil
    local _idleK3         = nil
    local _idleKK         = nil
    local _idleFloat      = nil
    local _idleTw         = nil
    local _idleLoopActive = false
    local _idleLoopGen    = 0
    local _idleLastOpt      = ""
    local _idleResolvedOpt  = ""
    local _idleSettingUp    = false
    local _sgvfxGen      = 0
    local _sgvfxActive   = false
    local _sgvfxDescConn = nil
    local _sgvfxCharConn = nil
    local function _sgEnv()
        return (getgenv().Enviroment
            and pcall(function() return getgenv().Enviroment.Parent end)
            and getgenv().Enviroment)
            or workspace
    end
    local function _loud()
        return (getgenv().music and getgenv().music.PlaybackLoudness) or 0
    end
    local _sgBadGuiNames = { MODE_NAME = true, Text = true }
    local function _sweepChar(c)
        if not c then return end
        for _, d in pairs(c:GetDescendants()) do
            if d:IsA("BillboardGui") and _sgBadGuiNames[d.Name] then
                pcall(function() d:Destroy() end)
            end
        end
    end
    local function _hookCharSGVFX(c)
        _sweepChar(c)
        if _sgvfxDescConn then _sgvfxDescConn:Disconnect() _sgvfxDescConn = nil end
        if not c then return end
        _sgvfxDescConn = c.DescendantAdded:Connect(function(obj)
            if obj:IsA("BillboardGui") and _sgBadGuiNames[obj.Name] then
                pcall(function() obj:Destroy() end)
            end
        end)
    end
    local function _isSGIdle()
        return type(_idleResolvedOpt) == "string" and _idleResolvedOpt:sub(1,4) == "[SG]"
    end
    local function _runSGVFXLoop(idleName, myGen)
        local ts = game:GetService("TweenService")
        local db = game:GetService("Debris")
        local function alive() return _sgvfxGen == myGen end
        local function getChar()
            local c = lp.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            return c, h
        end
        if idleName == "[SG] Persistence" then
            local gay = 0; local i = 0
            while alive() do
                i = i + 1; gay = gay + .5
                local char, hrp = getChar()
                if not char or not hrp then task.wait(.05) continue end
                local ra = char:FindFirstChild("Right Arm")
                if not ra then task.wait(.05) continue end
                spawn(function()
                    local p=Instance.new('Part'); p.Parent=_sgEnv()
                    p.Material=Enum.Material.Neon; p.Size=Vector3.new(1,1,1)
                    p.Anchored=true; p.CanCollide=false
                    local msh2=Instance.new("SpecialMesh",p); msh2.MeshType="Sphere"
                    p.CFrame=ra.CFrame*CFrame.new(0,-1,0)*CFrame.Angles(0,i/5,math.rad(90))
                    p.Color=Color3.new(0,0,1); msh2.Scale=Vector3.new(1,1,1)
                    db:AddItem(p,1.5)
                    ts:Create(p,TweenInfo.new(.6),{CFrame=p.CFrame*CFrame.new(0,2,0),Transparency=1,Color=Color3.new(0,.3,.3)}):Play()
                    ts:Create(msh2,TweenInfo.new(.6),{Scale=Vector3.new(0,1,0)}):Play()
                    local p2=Instance.new('Part'); p2.Parent=_sgEnv()
                    p2.Material=Enum.Material.Neon; p2.Size=Vector3.new(1,1,1)
                    p2.Anchored=true; p2.CanCollide=false
                    local msh3=Instance.new("SpecialMesh",p2); msh3.MeshType="Sphere"
                    p2.CFrame=ra.CFrame*CFrame.new(0,-1,0)*CFrame.Angles(0,math.rad(180)+i/5,math.rad(90))
                    p2.Color=Color3.new(0,0,1); msh3.Scale=Vector3.new(1,1,1)
                    db:AddItem(p2,1.5)
                    ts:Create(p2,TweenInfo.new(.6),{CFrame=p2.CFrame*CFrame.new(0,2,0),Transparency=1,Color=Color3.new(0,.3,.3)}):Play()
                    ts:Create(msh3,TweenInfo.new(.6),{Scale=Vector3.new(0,1,0)}):Play()
                    if gay >= 5 then
                        gay = 0
                        local v=Instance.new('ParticleEmitter',p2)
                        v.LightEmission=15; v.LightInfluence=1; v.Size=NumberSequence.new(2,0)
                        v.Name='_Rsmoke'; v.Transparency=NumberSequence.new(1,0,1); v.Lifetime=NumberRange.new(1.4)
                        v.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(0,15,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,255))}
                        v.Rate=0; v.Speed=NumberRange.new(1); v:Emit()
                        v.SpreadAngle=Vector2.new(30,30); v.Rotation=NumberRange.new(1,360); v.RotSpeed=NumberRange.new(-100,100)
                        v.Texture='rbxassetid://9470659899'; v.Brightness=2555
                        v.LightEmission=10; v.LightInfluence=0; v.Orientation='VelocityParallel'
                        v.FlipbookFramerate=NumberRange.new(66); v.FlipbookLayout='Grid8x8'; v.FlipbookMode='Loop'; v.ZOffset=-2
                    end
                    local bld=Instance.new("ParticleEmitter",p2)
                    bld.LightEmission=55; bld.Texture="rbxassetid://284205403"
                    bld.Color=ColorSequence.new(Color3.new(1,1,1)); bld.Rate=0; bld:Emit(2)
                    bld.Orientation='VelocityParallel'; bld.Lifetime=NumberRange.new(1)
                    bld.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,1),NumberSequenceKeypoint.new(1,0)})
                    bld.Squash=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
                    bld.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.1,.9),NumberSequenceKeypoint.new(1,1)})
                    bld.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,255))}
                    bld.Speed=NumberRange.new(.01); bld.VelocitySpread=0; bld.ZOffset=5
                    bld.LockedToPart=true; bld.Rotation=NumberRange.new(90); bld.RotSpeed=NumberRange.new(0)
                    task.delay(.5,function() bld.Rate=0 end)
                end)
                task.wait(.05)
            end
        elseif idleName == "[SG] Purity" then
            while alive() do
                local char, hrp = getChar()
                if not char or not hrp then task.wait(.05) continue end
                local pp=Instance.new('Part'); db:AddItem(pp,1.5)
                pp.Material=Enum.Material.Neon; pp.Size=Vector3.new(1,1,1)
                pp.Anchored=true; pp.CanCollide=false; pp.Color=Color3.new(0,1,1)
                pp.Parent=_sgEnv()
                local msh2=Instance.new("SpecialMesh",pp); msh2.MeshType="Sphere"
                local bld=Instance.new("ParticleEmitter",pp)
                bld.LightEmission=15; bld.Brightness=1; bld.Texture="rbxassetid://6673021984"
                bld.Rate=155; bld.Lifetime=NumberRange.new(1.5)
                bld.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,5),NumberSequenceKeypoint.new(1,0)})
                bld.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.1,.9),NumberSequenceKeypoint.new(1,1)})
                bld.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,255,255))}
                bld.Speed=NumberRange.new(1); bld.Acceleration=Vector3.new(0,0,.1); bld.VelocitySpread=0
                bld.ZOffset=0; bld.Rotation=NumberRange.new(0); bld:Emit(1); bld.LockedToPart=true
                task.delay(.1,function() bld.Rate=0 end)
                pp.CFrame=char.Torso.CFrame*CFrame.new(math.random(-25,25),-5,math.random(-25,25))
                ts:Create(pp,TweenInfo.new(1.5),{Size=Vector3.new(0,0,0),CFrame=pp.CFrame*CFrame.new(math.random(-5,5),15+math.random(2,8),math.random(-5,5))}):Play()
                task.wait(.05)
            end
        elseif idleName == "[SG] Euclidean" then
            local i = 0
            while alive() do
                i = i + 1
                local char, hrp = getChar()
                if not char or not hrp then task.wait(.01) continue end
                local la = char:FindFirstChild("Left Arm")
                if not la then task.wait(.01) continue end
                local rndd = math.random(0,1)
                local col1 = rndd==1 and Color3.new(1,0,0) or Color3.new(0,0,1)
                local p2=Instance.new('Part'); p2.Parent=_sgEnv(); p2.Material=Enum.Material.Neon
                p2.Anchored=true; p2.CanCollide=false; p2.Color=col1
                local msh2=Instance.new("SpecialMesh",p2); msh2.MeshType="Sphere"; msh2.Scale=Vector3.new(.5,.5,.5)
                p2.CFrame=la.CFrame*CFrame.new(0,-1,0)*CFrame.Angles(math.random(-360,360),math.random(-360,360),math.random(-360,360))
                db:AddItem(p2,2)
                ts:Create(p2,TweenInfo.new(1),{CFrame=p2.CFrame*CFrame.new(0,3,0)}):Play()
                ts:Create(msh2,TweenInfo.new(.5),{Scale=Vector3.new(0,2,0)}):Play()
                local p3=Instance.new('Part'); p3.Parent=_sgEnv(); p3.Material=Enum.Material.Neon
                p3.Anchored=true; p3.CanCollide=false; p3.Size=Vector3.new(.3,.3,.3); p3.Color=col1
                db:AddItem(p3,.8)
                if math.random(0,1)==0 then
                    p3.CFrame=hrp.CFrame*CFrame.new(math.random(-15,15),-3,math.random(-15,15))*CFrame.Angles(math.rad(math.random(-15,15)),math.rad(math.random(-15,15)),math.rad(math.random(-15,15)))
                    ts:Create(p3,TweenInfo.new(.8),{Size=Vector3.new(0,2+math.random(2,4),0),CFrame=p3.CFrame*CFrame.new(0,2,0)}):Play()
                    local bld=Instance.new("ParticleEmitter",p3)
                    bld.LightEmission=1; bld.Brightness=1; bld.Orientation='FacingCameraWorldUp'; bld.Texture="rbxassetid://6673021984"
                    bld.Rate=255; bld.Lifetime=NumberRange.new(.6)
                    bld.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,math.random(1,5)),NumberSequenceKeypoint.new(1,0)})
                    bld.Squash=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,-1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,0)})
                    bld.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.1,.8),NumberSequenceKeypoint.new(1,1)})
                    if rndd==1 then bld.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(127,0,0))}
                    else bld.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(252,255,255))} end
                    bld.Speed=NumberRange.new(0); bld.VelocitySpread=50000; bld.ZOffset=2; bld.Rotation=NumberRange.new(90)
                    bld:Emit(1); bld.LockedToPart=true; task.delay(.3,function() bld.Rate=0 end)
                else
                    p3.CFrame=hrp.CFrame*CFrame.new(math.random(-15,15),math.random(-3,15),math.random(-15,15))*CFrame.Angles(i,i,-i)
                    ts:Create(p3,TweenInfo.new(.8),{Size=Vector3.new(0,0,0),CFrame=p3.CFrame*CFrame.new(0,2,0)}):Play()
                    local bld=Instance.new("ParticleEmitter",p3)
                    bld.LightEmission=1; bld.Brightness=1; bld.Orientation='FacingCameraWorldUp'; bld.Texture="rbxassetid://6673021984"
                    bld.Rate=77; bld.Lifetime=NumberRange.new(.3)
                    bld.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,math.random(1,5)),NumberSequenceKeypoint.new(1,0)})
                    bld.Squash=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(.1,-2),NumberSequenceKeypoint.new(.2,2),NumberSequenceKeypoint.new(.3,-2),NumberSequenceKeypoint.new(.4,2),NumberSequenceKeypoint.new(.5,-2),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,0)})
                    bld.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.1,.8),NumberSequenceKeypoint.new(1,1)})
                    if rndd==1 then bld.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(252,255,255))}
                    else bld.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(252,255,255))} end
                    bld.Speed=NumberRange.new(0); bld.VelocitySpread=50000; bld.ZOffset=0; bld.Rotation=NumberRange.new(90)
                    bld:Emit(1); bld.LockedToPart=true; task.delay(.3,function() bld.Rate=0 end)
                end
                task.wait(.01)
            end
        elseif idleName == "[SG] Equinox" then
            while alive() do
                local char, hrp = getChar()
                if not char or not hrp then task.wait(.1) continue end
                local lol=math.random(0,1)
                local pp=Instance.new('Part'); db:AddItem(pp,.7)
                pp.Material=Enum.Material.Neon; pp.Size=Vector3.new(1,1,1)
                pp.Anchored=true; pp.CanCollide=false; pp.Color=Color3.new(lol,lol,lol)
                pp.Parent=_sgEnv()
                local msh2=Instance.new("SpecialMesh",pp); msh2.MeshType="Sphere"
                pp.CFrame=CFrame.new(hrp.CFrame.X+math.random(-25,25),hrp.CFrame.Y-3,hrp.CFrame.Z+math.random(-25,25))
                local bld=Instance.new("ParticleEmitter",pp)
                bld.LightEmission=155; bld.Brightness=1; bld.Texture="rbxassetid://6673021984"
                bld.Rate=155; bld.Lifetime=NumberRange.new(.5)
                bld.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,math.random(1,5)*5),NumberSequenceKeypoint.new(1,0)})
                bld.Orientation='VelocityParallel'
                bld.Squash=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.3,-7),NumberSequenceKeypoint.new(1,0)})
                bld.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.1,.9),NumberSequenceKeypoint.new(1,1)})
                bld.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0))}
                bld.Speed=NumberRange.new(1); bld.Acceleration=Vector3.new(0,0,.1); bld.VelocitySpread=0
                bld.ZOffset=-2; bld.Rotation=NumberRange.new(0); bld:Emit(1)
                task.delay(.1,function() bld.Rate=0 end)
                msh2.Scale=Vector3.new(3,3,3)
                ts:Create(msh2,TweenInfo.new(1),{Scale=Vector3.new(0,45,0)}):Play()
                ts:Create(pp,TweenInfo.new(1.6),{Transparency=1}):Play()
                task.wait(.1)
            end
        elseif idleName == "[SG] Crazed" then
            while alive() do
                local char, hrp = getChar()
                if not char or not hrp then task.wait(.05) continue end
                spawn(function()
                    local pp=Instance.new('Part'); db:AddItem(pp,1.5)
                    pp.Material=Enum.Material.Neon; pp.Anchored=true; pp.CanCollide=false
                    pp.Color=Color3.new(0,0,1); pp.Parent=_sgEnv()
                    local msh2=Instance.new("SpecialMesh",pp); msh2.MeshType="Sphere"
                    local bld=Instance.new("ParticleEmitter",pp)
                    bld.LightEmission=15; bld.Brightness=1; bld.Texture="rbxassetid://6673021984"
                    bld.Rate=155; bld.Lifetime=NumberRange.new(3.5)
                    bld.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,5),NumberSequenceKeypoint.new(1,15)})
                    bld.Squash=NumberSequence.new({NumberSequenceKeypoint.new(0,5),NumberSequenceKeypoint.new(1,15)})
                    bld.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.1,.9),NumberSequenceKeypoint.new(1,1)})
                    bld.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,255))}
                    bld.Speed=NumberRange.new(0); bld.Acceleration=Vector3.new(0,5,0); bld.VelocitySpread=0
                    bld.ZOffset=0; bld.Orientation='VelocityParallel'; bld.Rotation=NumberRange.new(90)
                    bld:Emit(1); bld.LockedToPart=true; task.delay(.1,function() bld.Rate=0 end)
                    spawn(function() for j=1,45 do pp.Color=Color3.fromRGB(0,0,math.random(1,155)) task.wait(.02) end end)
                    pp.Size=Vector3.new(1,.1,1)
                    pp.CFrame=hrp.CFrame*CFrame.new(math.random(-77,77),-2,math.random(-77,77))*CFrame.Angles(math.rad(math.random(-15,15)),0,0)
                    ts:Create(pp,TweenInfo.new(.5),{Size=Vector3.new(2,.2,2)}):Play()
                    task.wait(.5)
                    ts:Create(pp,TweenInfo.new(1.5),{CFrame=pp.CFrame*CFrame.new(math.random(-5,5)/5,15+math.random(2,8),math.random(-5,5)/5),Size=Vector3.new(0,155,0)}):Play()
                    local pp2=Instance.new('Part'); db:AddItem(pp2,1.5)
                    pp2.Material=Enum.Material.Neon; pp2.Anchored=true; pp2.CanCollide=false
                    pp2.Color=Color3.new(0,0,1); pp2.Parent=_sgEnv()
                    local msh3=Instance.new("SpecialMesh",pp2); msh3.MeshType="Sphere"
                    local bld2=Instance.new("ParticleEmitter",pp2)
                    bld2.LightEmission=15; bld2.Brightness=1; bld2.Texture="rbxassetid://6673021984"
                    bld2.Rate=155; bld2.Lifetime=NumberRange.new(.5)
                    bld2.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,2)})
                    bld2.Squash=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,2)})
                    bld2.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.1,.9),NumberSequenceKeypoint.new(1,1)})
                    bld2.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,255))}
                    bld2.Speed=NumberRange.new(0); bld2.Acceleration=Vector3.new(0,.3,0); bld2.VelocitySpread=0
                    bld2.ZOffset=0; bld2.Orientation='VelocityParallel'; bld2.Rotation=NumberRange.new(0)
                    bld2:Emit(1); bld2.LockedToPart=true; task.delay(.1,function() bld2.Rate=0 end)
                    spawn(function() for j=1,45 do pp2.Color=Color3.fromRGB(0,0,math.random(1,155)) task.wait(.02) end end)
                    pp2.Size=Vector3.new(3,.5,3); pp2.CFrame=char.Torso.CFrame*CFrame.new(0,0,7)
                    ts:Create(pp2,TweenInfo.new(.2),{Size=Vector3.new(0,0,25)}):Play()
                end)
                task.wait(.05)
            end
        elseif idleName == "[SG] Contaminant" then
            local man = 999; local col = Color3.new(1,.7,0)
            while alive() do
                man = man + .1
                local char, hrp = getChar()
                if not char or not hrp then task.wait(.02) continue end
                local ra=char:FindFirstChild("Right Arm"); local la=char:FindFirstChild("Left Arm")
                if not ra or not la then task.wait(.02) continue end
                local function mkArm(arm)
                    local p=Instance.new('Part'); p.Parent=_sgEnv(); p.Material=Enum.Material.Neon
                    p.Anchored=true; p.CanCollide=false
                    local msh=Instance.new("SpecialMesh",p); msh.MeshType="Sphere"
                    p.Color=col; msh.Scale=Vector3.new(.5,.5,.5)
                    p.CFrame=arm.CFrame*CFrame.new(0,-1,0)*CFrame.Angles(math.random(-360,360),math.random(-360,360),math.random(-360,360))
                    db:AddItem(p,2)
                    ts:Create(p,TweenInfo.new(1),{CFrame=p.CFrame*CFrame.new(0,3,0)}):Play()
                    ts:Create(msh,TweenInfo.new(.5),{Scale=Vector3.new(0,2,0)}):Play()
                    if man >= 1 then
                        local v=Instance.new('ParticleEmitter',p); v.LightEmission=15; v.LightInfluence=1
                        v.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,1)})
                        v.LockedToPart=true; v.Name='_Lsmoke'
                        v.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)})
                        v.Lifetime=NumberRange.new(1)
                        v.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,200,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,200,0))}
                        v.Rate=0; v.Speed=NumberRange.new(-3); v:Emit(1)
                        v.SpreadAngle=Vector2.new(30,30); v.Rotation=NumberRange.new(1,360); v.RotSpeed=NumberRange.new(-100,100)
                        v.Texture='rbxassetid://9470659899'; v.Brightness=5; v.LightEmission=10; v.LightInfluence=0
                        v.FlipbookFramerate=NumberRange.new(66); v.FlipbookLayout='Grid8x8'; v.FlipbookMode='Loop'; v.ZOffset=0
                        local bld=Instance.new("ParticleEmitter",p); bld.LightEmission=155; bld.Texture="rbxassetid://6673021984"
                        bld.Rate=155; bld:Emit(5); bld.LockedToPart=true; bld.Lifetime=NumberRange.new(1)
                        bld.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,3),NumberSequenceKeypoint.new(1,0)})
                        bld.Squash=NumberSequence.new({NumberSequenceKeypoint.new(0,math.random(-15,15)/35),NumberSequenceKeypoint.new(.1,math.random(-15,15)/35),NumberSequenceKeypoint.new(1,0)})
                        bld.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.1,.8),NumberSequenceKeypoint.new(1,1)})
                        bld.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,col),ColorSequenceKeypoint.new(1,col)}
                        bld.Speed=NumberRange.new(0); bld.VelocitySpread=50000; bld.Rotation=NumberRange.new(-500,500); bld.RotSpeed=NumberRange.new(-500,500); bld.ZOffset=2
                        task.delay(.5,function() bld.Rate=0 end)
                    end
                end
                mkArm(ra); mkArm(la)
                if man >= 1 then man = 0 end
                task.wait(.02)
            end
        else
            while alive() do task.wait(.5) end
        end
    end
    local function _disableSGVFX()
        if not _sgvfxActive then return end
        _sgvfxActive = false
        _sgvfxGen = _sgvfxGen + 1
        if getgenv()._sgOrigSetDecal ~= nil then
            pcall(function() if _G then _G.SetDecal = getgenv()._sgOrigSetDecal end end)
            getgenv()._sgOrigSetDecal = nil
        end
        if _sgvfxDescConn then _sgvfxDescConn:Disconnect() _sgvfxDescConn = nil end
        if _sgvfxCharConn then _sgvfxCharConn:Disconnect() _sgvfxCharConn = nil end
        pcall(function()
            local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if h then h.CameraOffset = Vector3.new() end
        end)
    end
    local function _startSGVFXLoop(idleName)
        _sgvfxGen = _sgvfxGen + 1
        local myGen = _sgvfxGen
        _hookCharSGVFX(lp.Character)
        task.spawn(_runSGVFXLoop, idleName, myGen)
    end
    local function _enableSGVFX(idleName)
        _sgvfxActive = true
        if _G and type(_G.SetDecal) == "function" and getgenv()._sgOrigSetDecal == nil then
            getgenv()._sgOrigSetDecal = _G.SetDecal
            _G.SetDecal = function() end
        end
        if _sgvfxCharConn then _sgvfxCharConn:Disconnect() end
        _sgvfxCharConn = lp.CharacterAdded:Connect(function(newChar)
            task.wait(0.1)
            if _sgvfxActive then
                _startSGVFXLoop(_idleResolvedOpt)
            end
        end)
        _startSGVFXLoop(idleName)
    end
    _refreshSGVFX = function()
        local togOn = Toggles.SGVFXToggle and Toggles.SGVFXToggle.Value
        if togOn and _isSGIdle() then
            if not _sgvfxActive then
                _enableSGVFX(_idleResolvedOpt)
            else
                _startSGVFXLoop(_idleResolvedOpt)
            end
        else
            _disableSGVFX()
        end
    end
    local function _loadIA(id)
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return nil end
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://" .. id
        return hum:LoadAnimation(a)
    end
    local function _stopIdleTracks(instant)
        _idleLoopGen    = _idleLoopGen + 1
        _idleLoopActive = false
        local ft = (instant) and 0 or (Options.IdleAnimationEndFadeTime and Options.IdleAnimationEndFadeTime.Value or 0.2)
        if _idleTw    then pcall(function() _idleTw:Cancel()    end) _idleTw    = nil end
        if _idleK     then pcall(function() _idleK:Stop(ft)     end) _idleK     = nil end
        if _idleK2    then pcall(function() _idleK2:Stop(ft)    end) _idleK2    = nil end
        if _idleK3    then pcall(function() _idleK3:Stop(ft)    end) _idleK3    = nil end
        if _idleKK    then pcall(function() _idleKK:Stop(ft)    end) _idleKK    = nil end
        if _idleFloat then pcall(function() _idleFloat:Stop(ft) end) _idleFloat = nil end
        pcall(function()
            local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if h then h.HipHeight = 0 end
        end)
    end
    local function _startIdle(opt, hadPrevious)
        _idleSettingUp = true
        if hadPrevious then
            local ft = Options.IdleAnimationEndFadeTime and Options.IdleAnimationEndFadeTime.Value or 0.2
            _stopIdleTracks(false)
            task.wait(ft)
        else
            _stopIdleTracks(true)
        end
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.MoveDirection ~= Vector3.new() then
            _idleLastOpt   = ""
            _idleResolvedOpt = ""
            _idleSettingUp = false
            task.defer(_refreshSGVFX)
            return
        end
        local currentOpt = Options.IdleAnimation and Options.IdleAnimation.Value or "Normal"
        if currentOpt == "Normal" then
            _idleLastOpt   = ""
            _idleResolvedOpt = ""
            _idleSettingUp = false
            task.defer(_refreshSGVFX)
            return
        end
        if currentOpt ~= opt then
            _idleLastOpt   = ""
            _idleResolvedOpt = ""
            _idleSettingUp = false
            task.defer(_refreshSGVFX)
            return
        end
        local Idle = opt
        if Idle == "Random" then
            local pool = {
                "[DEF] Watch","[DEF] Casual","[DEF] Confident","[DEF] Fent Master","[DEF] Fly Idle",
                "[DEF] Aura","[DEF] Serious","[DEF] Rework","[DEF] Preparing","[DEF] Divine","[DEF] God",
                "[SG] Mayhem","[SG] Rainbow","[SG] Zyledon",
                "[SG] Persistence","[SG] Purity","[SG] Euclidean",
                "[SG] Equinox","[SG] Crazed","[SG] The Big Black",
                "[SG] Contaminant",
            }
            Idle = pool[math.random(1, #pool)]
        end
        _idleResolvedOpt = Idle
        local sft = Options.IdleAnimationStartFadeTime and Options.IdleAnimationStartFadeTime.Value or 0.1
        if Idle == "[DEF] Watch" then
            _idleK = _loadIA("18897733312")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
        elseif Idle == "[DEF] Casual" then
            _idleK = _loadIA("13736115009")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK2 = _loadIA("18253570434")
            if _idleK2 then
                _idleK2.Priority = Enum.AnimationPriority.Idle
                _idleK2:Play(sft)
                _idleK2:AdjustSpeed(0)
                _idleK2.TimePosition = 0.3
            end
        elseif Idle == "[DEF] Confident" then
            _idleK = _loadIA("18450406917")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            _idleTw = TweenService:Create(_idleK, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true, 0), {TimePosition = 0.1})
            _idleTw:Play()
        elseif Idle == "[DEF] Fent Master" then
            _idleK = _loadIA("17086333563")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            _idleK.TimePosition = 1.5
            _idleTw = TweenService:Create(_idleK, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true, 0), {TimePosition = 2})
            _idleTw:Play()
        elseif Idle == "[DEF] Fly Idle" then
            _idleK = _loadIA("17124061663")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
        elseif Idle == "[SG] Mayhem" then
            _idleK = _loadIA("17097712387")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(.1)
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                for i = 1,999999 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                    _idleK.TimePosition = .5+math.cos(i/35)/15
                    task.wait(.02)
                end
            end)
        elseif Idle == "[SG] Ultrasonic" then
            _idleK     = _loadIA("17106169665")
            _idleFloat = _loadIA("313762630")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Action4
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            _idleK:AdjustWeight(1e8)
            if _idleFloat then
                _idleFloat.Priority = Enum.AnimationPriority.Action4
                _idleFloat:Play(sft)
                _idleFloat:AdjustWeight(1e8)
            end
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                for i = 1,999999 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                    _idleK.TimePosition = 1.2+math.sin(i/15)/35
                    local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                    if h then h.HipHeight = 2+math.sin(i/15)*2 end
                    task.wait(.02)
                end
                local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                if h then h.HipHeight = 0 end
            end)
        elseif Idle == "[SG] Rainbow" then
            _idleK  = _loadIA("18464372850")
            _idleKK = _loadIA("14357943487")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            if _idleKK then
                _idleKK.Priority = Enum.AnimationPriority.Movement
                _idleKK:Play(sft)
                _idleKK:AdjustSpeed(0)
            end
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                for i = 1,999999 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then return end
                    _idleK.TimePosition = 2.75+math.cos(i/35)/45
                    task.wait(.05)
                end
            end)
        elseif Idle == "[SG] Zyledon" then
            _idleK2 = _loadIA("15957376722")
            _idleK  = _loadIA("72042024")
            if not _idleK2 then _idleSettingUp = false return end
            _idleK2.Priority = Enum.AnimationPriority.Idle
            _idleK2:Play(sft)
            _idleK2:AdjustSpeed(0)
            _idleK2.Looped = true
            if _idleK then
                _idleK.Priority = Enum.AnimationPriority.Movement
                _idleK:Play(sft)
                _idleK:AdjustSpeed(0)
                _idleK.TimePosition = .1
                _idleK.Looped = true
            end
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                for i = 1,15150 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                    _idleK2.TimePosition = 3.2+math.cos(i/25)/255
                    task.wait(.01)
                end
            end)
        elseif Idle == "[SG] Persistence" then
            _idleK = _loadIA("129295156336675")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                for i = 1,999999 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then return end
                    _idleK.TimePosition = .5+math.cos(i/15)/35
                    task.wait(.05)
                end
            end)
        elseif Idle == "[SG] Purity" then
            _idleK = _loadIA("17121695329")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(1)
        elseif Idle == "[SG] Euclidean" then
            _idleK  = _loadIA("14527229510")
            _idleK2 = _loadIA("99277885325374")
            _idleK3 = _loadIA("15146348738")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            _idleK.Looped = true
            if _idleK2 then
                _idleK2.Priority = Enum.AnimationPriority.Idle
                _idleK2:Play(sft)
                _idleK2:AdjustSpeed(.8)
                _idleK2.Looped = true
            end
            if _idleK3 then
                _idleK3.Priority = Enum.AnimationPriority.Movement
                _idleK3:Play(sft)
                _idleK3:AdjustSpeed(.1)
                _idleK3.Looped = true
            end
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                for i = 1,15150 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                    _idleK.TimePosition = .9+math.cos(i/15)/155
                    task.wait(.01)
                end
            end)
        elseif Idle == "[SG] Equinox" then
            _idleK  = _loadIA("15503060232")
            _idleKK = _loadIA("88016955")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            if _idleKK then
                _idleKK.Priority = Enum.AnimationPriority.Idle
                _idleKK:Play(sft)
                _idleKK:AdjustSpeed(0)
            end
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                for i = 1,999999 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                    _idleK.TimePosition = 4.8+math.cos(i/5)/10
                    task.wait(.1)
                end
            end)
        elseif Idle == "[SG] Crazed" then
            _idleK = _loadIA("75318228407422")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(.1)
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            local k = _idleK
            task.spawn(function()
                for i = 1,999999 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                    if not k or not k.IsPlaying then break end
                    local rnd = math.random(1,15)
                    if rnd == 15 then
                        for _ = 1,math.random(2,7) do
                            if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                            if not k or not k.IsPlaying then break end
                            k.TimePosition = .7 + math.random(-15,15)/55
                            task.wait(.01)
                        end
                    end
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                    k.TimePosition = .7 + math.cos(i/35)/7
                    task.wait(.02)
                end
            end)
        elseif Idle == "[SG] The Big Black" then
            _idleK = _loadIA("15018219692")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(.1)
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                for i = 1,999999 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                    _idleK.TimePosition = .4+math.cos(i/35)/15
                    task.wait(.02)
                end
            end)
        elseif Idle == "[SG] Contaminant" then
            _idleK  = _loadIA("16719107050")
            _idleKK = _loadIA("15146348738")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            if _idleKK then
                _idleKK.Priority = Enum.AnimationPriority.Idle
                _idleKK:Play(sft)
                _idleKK:AdjustSpeed(0)
            end
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                for i = 1,999999 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                    _idleK.TimePosition = 2.5+math.cos(i/15)/15
                    task.wait(.02)
                end
            end)
        elseif Idle == "[SG] Divinity" then
            _idleK = _loadIA("17464644182")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Action4
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            _idleK:AdjustWeight(1e8)
            _idleK.Looped = true
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                for i = 1,15150 do
                    if not _idleLoopActive or _idleLoopGen ~= myLoopG then break end
                    _idleK.TimePosition = .3+math.cos(i/5)/45
                    task.wait(.1)
                end
            end)
        elseif Idle == "[DEF] Aura" then
            _idleK = _loadIA("104862750267967")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK.Looped = true
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0.6)
        elseif Idle == "[DEF] Serious" then
            _idleK = _loadIA("140164642047188")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK.Looped   = true
            _idleK:Play(sft)
            _idleK.TimePosition = 1
            _idleK:AdjustSpeed(0)
            _idleTw = TweenService:Create(_idleK, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true, 0), {TimePosition = 1.1})
            _idleTw:Play()
        elseif Idle == "[DEF] Rework" then
            _idleK = _loadIA("15963602367")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            _idleK.TimePosition = 0
            _idleTw = TweenService:Create(_idleK, TweenInfo.new(1.7 / 0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true, 0), {TimePosition = 1.7})
            _idleTw:Play()
        elseif Idle == "[DEF] Preparing" then
            _idleK = _loadIA("87060298208284")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK.Looped   = true
            _idleK:Play(sft)
            _idleK:AdjustSpeed(1)
        elseif Idle == "[DEF] Divine" then
            _idleK = _loadIA("116187503451999")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK.Looped   = false
            _idleK:Play(sft)
            _idleK:AdjustSpeed(0)
            _idleK.TimePosition = 10.10
            _idleTw = TweenService:Create(_idleK, TweenInfo.new((13.67 - 10.10) / 0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true, 0), {TimePosition = 13.67})
            _idleTw:Play()
        elseif Idle == "[DEF] God" then
            _idleK = _loadIA("72460660015095")
            if not _idleK then _idleSettingUp = false task.defer(_refreshSGVFX) return end
            _idleK.Priority = Enum.AnimationPriority.Idle
            _idleK.Looped   = false
            _idleK:Play(sft)
            _idleK:AdjustSpeed(1)
            _idleK.TimePosition = 3.35
            _idleLoopActive = true
            local myLoopG = _idleLoopGen
            task.spawn(function()
                while _idleLoopActive and _idleLoopGen == myLoopG do
                    if _idleK.TimePosition >= 4.6 then
                        _idleK:AdjustSpeed(0.2)
                        local goingForward = true
                        while _idleLoopActive and _idleLoopGen == myLoopG do
                            local tp = _idleK.TimePosition
                            if goingForward then
                                if tp >= 4.9 then
                                    goingForward = false
                                    _idleK:AdjustSpeed(-0.2)
                                end
                            else
                                if tp <= 4.6 then
                                    goingForward = true
                                    _idleK:AdjustSpeed(0.2)
                                end
                            end
                            task.wait()
                        end
                        break
                    end
                    task.wait()
                end
            end)
        end
        _idleSettingUp = false
        task.defer(_refreshSGVFX)
    end
    _idleConn = RunService.Heartbeat:Connect(function()
        if _idleSettingUp then return end
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then
            if _idleLastOpt ~= "" then
                _stopIdleTracks(false)
                _idleLastOpt = ""
                _idleResolvedOpt = ""
            end
            return
        end
        local opt = Options.IdleAnimation and Options.IdleAnimation.Value or "Normal"
        local walkOpt = Options.WalkAnimation and Options.WalkAnimation.Value or "Normal"
        if opt == "Normal" or hum.MoveDirection ~= Vector3.new() then
            -- [PHANTASM] For Normal idle while walking: defer cleanup to the walk-stop
            -- handler in _walkConn (once-per-cycle, like Phantasm). When standing still
            -- (MoveDirection == zero), fall through and clean up immediately as usual.
            -- [SG]/[DEF] walking cleanup is unaffected (opt ~= "Normal" branch).
            if opt == "Normal" and hum.MoveDirection ~= Vector3.new() then return end
            if _idleLastOpt ~= "" then
                _stopIdleTracks(false)
                _idleLastOpt = ""
                _idleResolvedOpt = ""
                _refreshSGVFX()
            end
            return
        end
        local optChanged = (opt ~= _idleLastOpt)
        if not optChanged then
            if _idleK  and _idleK.IsPlaying  then return end
            if _idleK2 and _idleK2.IsPlaying then return end
        end
        local hadPrevious = (_idleLastOpt ~= "")
        _idleLastOpt   = opt
        task.spawn(_startIdle, opt, hadPrevious)
    end)
    table.insert(CleanupTasks, function()
        if _idleConn then _idleConn:Disconnect() _idleConn = nil end
        _idleSettingUp = false
        _idleLastOpt   = ""
        _idleResolvedOpt = ""
        _stopIdleTracks(true)
        _disableSGVFX()
        pcall(function() Toggles.SGVFXToggle:SetValue(false) end)
        pcall(function() Options.IdleAnimation:SetValue("Normal") end)
    end)
    BoxIdleAnim:AddDivider()
    local _walkAnimIds = {
        ["Gojo Run"]      = "18897115785",
        ["Girly Walk"]    = "17861862787",
        ["Steve Walk"]    = "17861872519",
        ["Sassy Walk"]    = "17861893094",
        ["Yandere Walk"]  = "17086054994",
        ["Sword Walk"]    = "17120635926",
        ["March"]         = "15962443652",
        ["Hunter"]        = "15962326593",
        ["Goofy"]         = "18897664299",
        ["Officer Earl"]  = "18897700236",
        ["Kazotsky Kick"] = "17861870996",
        ["In Charge"]     = "132132848099103",
    }
    BoxIdleAnim:AddDropdown("WalkAnimation", {
        Values     = { "Normal","Gojo Run","Girly Walk","Steve Walk","Sassy Walk","Yandere Walk","Sword Walk","March","Hunter","Goofy","Officer Earl","Kazotsky Kick","In Charge","Flying" },
        Default    = 1, Multi = false, Text = "Walk Animation", Searchable = true,
    })
    BoxIdleAnim:AddSlider("WalkAnimSpeed", {
        Text = "Walk Animation Speed", Default = 1, Min = 0.25, Max = 3, Rounding = 1,
    })
    BoxIdleAnim:AddDropdown("LoopedAnimation", {
        Values   = { "None", "Spin", "Crazy" },
        Default  = 1, Multi = false, Text = "Looped Animation",
    })
    BoxIdleAnim:AddSlider("LoopedAnimationSpeed", {
        Text = "Looped Animation Speed", Default = 1, Min = 0.1, Max = 10, Rounding = 1,
    })
    local _walkConn         = nil
    local _walkTrack        = nil
    local _walkLoadedId     = ""
    local _flyAnimIds = {
        Forward = "17124063826",
        Back    = "17124067635",
        Left    = "17124105294",
        Right   = "17124112547",
    }
    local _flyAnimTracks  = {}
    Options.WalkAnimSpeed:OnChanged(function(V)
        if _walkTrack then
            pcall(function() _walkTrack:AdjustSpeed(V) end)
        end
        for _, track in pairs(_flyAnimTracks) do
            if track.IsPlaying then
                pcall(function() track:AdjustSpeed(V) end)
            end
        end
    end)
    local function _flyAnimUnload()
        for _, t in pairs(_flyAnimTracks) do
            pcall(function() if t.IsPlaying then t:Stop(0) end end)
            pcall(function() t:Destroy() end)
        end
        _flyAnimTracks = {}
    end
    local function _flyAnimSetActive(names)
        for name, track in pairs(_flyAnimTracks) do
            local shouldPlay = false
            if names then
                for _, n in ipairs(names) do if n == name then shouldPlay = true break end end
            end
            if shouldPlay then
                if not track.IsPlaying then pcall(function() track:Play(0.1) end) end
            else
                if track.IsPlaying then pcall(function() track:Stop(0.1) end) end
            end
        end
    end
    local function _flyAnimLoad()
        _flyAnimUnload()
        local c = lp.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local a = h and h:FindFirstChildOfClass("Animator")
        if not a then return end
        for name, id in pairs(_flyAnimIds) do
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. id
            local t = a:LoadAnimation(anim)
            t.Priority = Enum.AnimationPriority.Movement
            t.Looped   = true
            _flyAnimTracks[name] = t
        end
    end
    local _walkTweenService = game:GetService("TweenService")
    local _sonicTween = nil
    local function _walkStop()
        if _sonicTween then _sonicTween:Cancel() _sonicTween = nil end
        if _walkTrack then
            pcall(function() _walkTrack:Stop(0.1) end)
            _walkTrack    = nil
            _walkLoadedId = ""
        end
        _flyAnimUnload()
    end
    local function _walkLoad(id)
        _walkStop()
        local c = lp.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local a = h and h:FindFirstChildOfClass("Animator")
        if not a then return end
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. id
        local t = a:LoadAnimation(anim)
        if lp.Character ~= c then
            pcall(function() t:Destroy() end)
            return
        end
        t.Priority = Enum.AnimationPriority.Movement
        t.Looped   = true
        _walkTrack    = t
        _walkLoadedId = id
    end
    local _walkAnimPlayedConn = nil
    local function _hookWalkAnimPlayed(humanoid)
        if _walkAnimPlayedConn then _walkAnimPlayedConn:Disconnect() _walkAnimPlayedConn = nil end
        if not humanoid then return end
        _walkAnimPlayedConn = humanoid.AnimationPlayed:Connect(function(track)
            local opt = Options.WalkAnimation and Options.WalkAnimation.Value or "Normal"
            local flyActive = _pU59 and _pU59.Flying
            local tid = track.Animation and track.Animation.AnimationId:match("%d+") or ""
            if opt == "Normal" and not flyActive then return end
            if tid == "7815618175" then
                -- [PHANTASM] Only suppress the default TSB locomotion while actively walking.
                -- When MoveDirection == zero the character just stopped — let 7815618175 play
                -- its idle portion so the default idle looks identical to Phantasm.
                local char2 = lp.Character
                local hum2  = char2 and char2:FindFirstChildOfClass("Humanoid")
                if hum2 and hum2.MoveDirection ~= Vector3.new() then
                    track:Stop()
                end
            end
            -- [PHANTASM] 14516273501 / 13935548552 não são interceptados — removido
        end)
    end
    do
        local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        _hookWalkAnimPlayed(h)
    end
    local _walkCharConn = lp.CharacterAdded:Connect(function(char)
        if _walkTrack then
            pcall(function() _walkTrack:Stop(0) end)
        end
        _walkTrack    = nil
        _walkLoadedId = ""
        task.spawn(function()
            local h = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
            if not h then return end
            local a = h:FindFirstChildOfClass("Animator") or h:WaitForChild("Animator", 5)
            if not a then return end
            if not char:FindFirstChild("HumanoidRootPart") then
                char:WaitForChild("HumanoidRootPart", 5)
            end
            _hookWalkAnimPlayed(h)
            local opt = Options.WalkAnimation and Options.WalkAnimation.Value or "Normal"
            if opt ~= "Normal" and opt ~= "Flying" then
                local id = _walkAnimIds[opt] or ""
                if id ~= "" then
                    _walkLoad(id)
                end
            end
        end)
    end)
    Options.WalkAnimation:OnChanged(function(opt)
        _walkStop()
        if opt ~= "Normal" and opt ~= "Flying" then
            local id = _walkAnimIds[opt] or ""
            if id ~= "" then
                task.spawn(function()
                    _walkLoad(id)
                    local c = lp.Character
                    local h = c and c:FindFirstChildOfClass("Humanoid")
                    if not (_walkTrack and h and h.MoveDirection ~= Vector3.new()) then return end
                    pcall(function() _walkTrack:Play(0.1) end)
                    pcall(function() _walkTrack:AdjustSpeed(Options.WalkAnimSpeed and Options.WalkAnimSpeed.Value or 1) end)
                end)
            end
        end
    end)
    _walkConn = RunService.Heartbeat:Connect(function()
        local opt = Options.WalkAnimation and Options.WalkAnimation.Value or "Normal"
        if opt == "Normal" then _walkStop() return end
        local c = lp.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not (c and h) then _walkStop() return end
        if h.Health <= 0 or h:GetState() == Enum.HumanoidStateType.Dead then _walkStop() return end
        -- [PHANTASM] scan removido do Heartbeat; 7815618175 suprimido pelo _hookWalkAnimPlayed
        if opt == "Flying" then
            if _walkTrack then
                pcall(function() _walkTrack:Stop(0.1) end)
                _walkTrack    = nil
                _walkLoadedId = ""
            end
            if not next(_flyAnimTracks) then task.spawn(_flyAnimLoad) return end
            local r = c:FindFirstChild("HumanoidRootPart")
            if not r then return end
            if h.MoveDirection == Vector3.new() then
                _flyAnimSetActive(nil)
                return
            end
            local shiftlock = UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
            local fwd  = math.round(h.MoveDirection:Dot(r.CFrame.LookVector))
            local side = math.round(h.MoveDirection:Dot(r.CFrame.RightVector))
            local names
            if shiftlock then
                names = {}
                if fwd  ==  1 then table.insert(names, "Forward")
                elseif fwd  == -1 then table.insert(names, "Back") end
                if side ==  1 then table.insert(names, "Right")
                elseif side == -1 then table.insert(names, "Left") end
                if #names == 0 then names = nil end
            else
                names = { "Forward" }
            end
            _flyAnimSetActive(names)
            for _, track in pairs(_flyAnimTracks) do
                if track.IsPlaying then
                    pcall(function() track:AdjustSpeed(Options.WalkAnimSpeed and Options.WalkAnimSpeed.Value or 1) end)
                end
            end
            return
        end
        if next(_flyAnimTracks) then _flyAnimUnload() end
        local id = _walkAnimIds[opt] or ""
        if id == "" then _walkStop() return end
        if _walkLoadedId ~= id then task.spawn(_walkLoad, id) return end
        if h.MoveDirection == Vector3.new() then
            if _walkTrack and _walkTrack.IsPlaying then
                pcall(function() _walkTrack:Stop(0.1) end)
                if _sonicTween then _sonicTween:Cancel() _sonicTween = nil end
                -- [PHANTASM] For Normal idle: after stopping custom walk, wait exactly one
                -- RenderStepped frame before letting the engine settle into idle — matching
                -- Phantasm's once-per-cycle pattern. _idleConn then handles any leftover
                -- DEF/SG track cleanup on the next Heartbeat (standing-still branch).
                -- [SG]/[DEF] idles are unaffected; they keep their own _idleConn Heartbeat.
                local _capturedIdleOpt = Options.IdleAnimation and Options.IdleAnimation.Value or "Normal"
                if _capturedIdleOpt == "Normal" then
                    task.spawn(function()
                        RunService.RenderStepped:Wait()
                        -- One render frame given to the engine to transition to default idle.
                        -- _idleConn will clean up _idleLastOpt on its next Heartbeat tick.
                    end)
                end
            end
            return
        end
        if _walkTrack and not _walkTrack.IsPlaying then
            pcall(function() _walkTrack:Play(0.1) end)
            if id == "17860467628" then
                pcall(function() _walkTrack:AdjustSpeed(0) end)
                pcall(function() _walkTrack.TimePosition = 1.25 end)
                if _sonicTween then _sonicTween:Cancel() _sonicTween = nil end
                _sonicTween = _walkTweenService:Create(
                    _walkTrack,
                    TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true, 0),
                    { TimePosition = 1.5 }
                )
                _sonicTween:Play()
            end
        end
        if _walkTrack and id ~= "17860467628" then
            pcall(function() _walkTrack:AdjustSpeed(Options.WalkAnimSpeed and Options.WalkAnimSpeed.Value or 1) end)
        end
    end)
    table.insert(CleanupTasks, function()
        if _walkAnimPlayedConn then _walkAnimPlayedConn:Disconnect() _walkAnimPlayedConn = nil end
        if _walkConn then _walkConn:Disconnect() _walkConn = nil end
        if _sonicTween then _sonicTween:Cancel() _sonicTween = nil end
        _walkStop()
        pcall(function() Options.WalkAnimation:SetValue("Normal") end)
    end)
    task.spawn(function()
        local opt = Options.WalkAnimation and Options.WalkAnimation.Value or "Normal"
        if opt == "Normal" then return end
        local c = lp.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local a = h and h:FindFirstChildOfClass("Animator")
        if a then
            -- só para a walk animation padrão do jogo, sem matar o idle
            local _walkDefaultIds = { ["7815618175"] = true, ["14516273501"] = true, ["13935548552"] = true }
            for _, tr in ipairs(a:GetPlayingAnimationTracks()) do
                local _tid = tr.Animation and tr.Animation.AnimationId:match("%d+") or ""
                if _walkDefaultIds[_tid] then
                    tr:Stop(0)
                end
            end
        end
        if opt ~= "Flying" then
            local id = _walkAnimIds[opt] or ""
            if id ~= "" then
                _walkLoad(id)
                local ch = lp.Character
                local hm = ch and ch:FindFirstChildOfClass("Humanoid")
                if _walkTrack and hm and hm.MoveDirection ~= Vector3.new() then
                    pcall(function() _walkTrack:Play(0.1) end)
                    pcall(function() _walkTrack:AdjustSpeed(Options.WalkAnimSpeed and Options.WalkAnimSpeed.Value or 1) end)
                end
            end
        elseif opt == "Flying" then
            _flyAnimLoad()
        end
    end)
end
do
    -- Looped Animation (Spin)
    local _loopedTrack  = nil
    local _loopedTrack2 = nil
    local _loopedConn   = nil
    local _loopedRenderConn = nil
    local _LOOPED_ANIM_IDS = { Spin = "188632011", Crazy = "68339848" }
    local _CRAZY_POOL = { "68339848", "283545583" }

    local function _loopedStop()
        if _loopedTrack then
            pcall(function() _loopedTrack:Stop(0) end)
            _loopedTrack = nil
        end
    end
    local function _loopedStop2()
        if _loopedTrack2 then
            pcall(function() _loopedTrack2:Stop(0) end)
            _loopedTrack2 = nil
        end
    end

    local function _loopedInit()
        if _loopedConn then _loopedConn:Disconnect() _loopedConn = nil end
        if _loopedRenderConn then _loopedRenderConn:Disconnect() _loopedRenderConn = nil end
        _loopedStop()
        _loopedStop2()
        local _crazyTimer     = math.random() * 0.15 + 0.05
        local _crazyStopTimer = -1
        local _track1Active   = false
        local _track2Active   = false
        local function _loadCrazyTrack(animator, id)
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. id
            local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
            if ok and track then
                track.Priority = Enum.AnimationPriority.Action3
                track.Looped   = false
                return track
            end
        end
        -- RenderStepped: re-enforce both tracks every frame while active
        _loopedRenderConn = RunService.RenderStepped:Connect(function()
            if getgenv().InvisActive then return end
            local opt = Options.LoopedAnimation and Options.LoopedAnimation.Value or "None"
            if opt ~= "Crazy" then return end
            if _track1Active and _loopedTrack then
                if not _loopedTrack.IsPlaying then pcall(function() _loopedTrack:Play() end) end
                pcall(function() _loopedTrack:AdjustWeight(1e9) end)
            end
            if _track2Active and _loopedTrack2 then
                if not _loopedTrack2.IsPlaying then pcall(function() _loopedTrack2:Play() end) end
                pcall(function() _loopedTrack2:AdjustWeight(1e9) end)
            end
        end)
        _loopedConn = RunService.Heartbeat:Connect(function(dt)
            if getgenv().InvisActive then
                if _track1Active or _track2Active then
                    _track1Active = false
                    _track2Active = false
                    pcall(function() if _loopedTrack  then _loopedTrack:Stop(0)  end end)
                    pcall(function() if _loopedTrack2 then _loopedTrack2:Stop(0) end end)
                end
                return
            end
            local opt = Options.LoopedAnimation and Options.LoopedAnimation.Value or "None"
            local animId = _LOOPED_ANIM_IDS[opt]
            local char = lp.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")
            if not (char and hum and animator) then
                _loopedStop()
                return
            end
            if not animId then
                if _loopedTrack and _loopedTrack.IsPlaying then _loopedStop() end
                return
            end
            if not _loopedTrack or not _loopedTrack.Animation.AnimationId:match(animId) then
                _loopedStop()
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. animId
                local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
                if ok and track then
                    _loopedTrack = track
                    _loopedTrack.Priority = Enum.AnimationPriority.Action3
                    _loopedTrack.Looped   = (opt ~= "Crazy")
                end
                _crazyTimer     = math.random() * 0.15 + 0.05
                _crazyStopTimer = -1
            end
            if opt == "Crazy" then
                local speed = Options.LoopedAnimationSpeed and Options.LoopedAnimationSpeed.Value or 1
                if _crazyStopTimer >= 0 then
                    _crazyStopTimer = _crazyStopTimer - dt
                    if _crazyStopTimer <= 0 then
                        _crazyStopTimer = -1
                        _crazyTimer = math.random() * 0.6 + 0.4
                    end
                elseif not _track1Active and not _track2Active then
                    _crazyTimer = _crazyTimer - dt
                    if _crazyTimer <= 0 then
                        local playBoth = math.random(1, 10) <= 6  -- 283 always plays, 68 joins 60% of the time

                        local curId2 = _loopedTrack2 and _loopedTrack2.Animation and _loopedTrack2.Animation.AnimationId:match("%d+") or ""
                        if curId2 ~= _CRAZY_POOL[2] then
                            _loopedStop2()
                            _loopedTrack2 = _loadCrazyTrack(animator, _CRAZY_POOL[2])
                        end
                        _track2Active = true
                        pcall(function() _loopedTrack2:Play() end)
                        pcall(function() _loopedTrack2:AdjustSpeed(speed * 2) end)

                        if playBoth then
                            local curId1 = _loopedTrack and _loopedTrack.Animation and _loopedTrack.Animation.AnimationId:match("%d+") or ""
                            if curId1 ~= _CRAZY_POOL[1] then
                                _loopedStop()
                                _loopedTrack = _loadCrazyTrack(animator, _CRAZY_POOL[1])
                            end
                            _track1Active = true
                            pcall(function() _loopedTrack:Play() end)
                            pcall(function() _loopedTrack:AdjustSpeed(speed * 3) end)

                            task.delay(math.random() * 0.03 + 0.03, function()
                                if opt ~= "Crazy" then return end
                                _track1Active = false
                                pcall(function() if _loopedTrack then _loopedTrack:Stop(0) end end)
                            end)
                        end

                        task.delay(math.random() * 0.04 + 0.04, function()
                            if opt ~= "Crazy" then return end
                            _track2Active = false
                            pcall(function() if _loopedTrack2 then _loopedTrack2:Stop(0) end end)
                            _crazyStopTimer = math.random() * 0.05
                        end)
                    end
                end
            else
                if _loopedTrack then
                    _loopedTrack.Looped = true
                    if not _loopedTrack.IsPlaying then _loopedTrack:Play() end
                    pcall(function() _loopedTrack:AdjustSpeed(Options.LoopedAnimationSpeed and Options.LoopedAnimationSpeed.Value or 1) end)
                end
            end
        end)
    end

    _loopedInit()
    lp.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        local animator = hum:WaitForChild("Animator", 10)
        if not animator then return end
        task.wait(0.1)
        _loopedInit()
    end)
    table.insert(CleanupTasks, function()
        if _loopedConn then _loopedConn:Disconnect() _loopedConn = nil end
        if _loopedRenderConn then _loopedRenderConn:Disconnect() _loopedRenderConn = nil end
        _loopedStop()
        _loopedStop2()
        pcall(function() Options.LoopedAnimation:SetValue("None") end)
    end)
end
if isGamepassesGame and TabMiscAnimsR then
    local BoxCustomBlock = TabMiscAnimsR
    BoxCustomBlock:AddDropdown("CustomBlockAnimation", {
        Values  = { "Normal", "One Hand", "Gojo", "Infinity", "Boxer" },
        Default = 1, Multi = false,
        Text    = "Block Animation",
    })
    BoxCustomBlock:AddToggle("UIReactEnabled", {
        Text    = "Ultra Instinct Reaction",
        Default = false,
    })
    BoxCustomBlock:AddSlider("UIReactVolume", {
        Text    = "Volume",
        Default = 1, Min = 0, Max = 1, Rounding = 1,
    })
    BoxCustomBlock:AddDropdown("AuraSelection", {
        Text    = "Aura",
        Values  = { "Ultra Instinct", "Boundless Rage" },
        Default = {},
        Multi   = true,
    })
    BoxCustomBlock:AddSlider("AuraVolume", {
        Text    = "Volume",
        Default = 1, Min = 0, Max = 1, Rounding = 2,
    })
    local _cbAnimConn  = nil
    local _cbReactConn = nil
    local _cbActive    = true
    local function _cbInit()
        if _cbAnimConn  then _cbAnimConn:Disconnect()  _cbAnimConn  = nil end
        if _cbReactConn then _cbReactConn:Disconnect() _cbReactConn = nil end
        _isBlocking   = false
        _suppressNext = false
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
        if not (char and hum) then return end
        _cbAnimConn = hum.AnimationPlayed:Connect(function(track)
            local _v = Options.CustomBlockAnimation.Value
            local _id = track.Animation.AnimationId
            if (_id:match('10470389827') or _id:match('13380778193') or _id:match('13935548552')) and _v ~= 'Normal' then
                if Toggles.InvisibleMoves_Block.Value then
                    track:AdjustWeight(-999999)
                else
                    track:Stop()
                end
            end
        end)
        local _uiAnims  = {
            '133094662049155', '134711731729986', '76963965406296', '92546791251633',
            '128188725134114', '109088632860488', '78339272602733', '127015697036075',
        }
        local _uiSounds = { '72555434288985', '91067294642442', '104124534923268' }
        local blockAnimIdx = 0
        local blockAnimTrack = nil
        local blockAnimSpeed = 1
        local _cbBlockTrack = nil
        local function resetBlockAnim()
            if blockAnimTrack and blockAnimTrack.IsPlaying then
                blockAnimTrack:Stop()
            end
            local _anim = Instance.new('Animation')
            _anim.AnimationId = 'rbxassetid://' .. _uiAnims[blockAnimSpeed]
            blockAnimTrack = hum:LoadAnimation(_anim)
            blockAnimTrack.Priority = Enum.AnimationPriority.Action4
            blockAnimTrack:Play(0.05)
            blockAnimTrack.TimePosition = 0.2
            blockAnimTrack:AdjustSpeed(1.2)
            blockAnimSpeed = blockAnimSpeed + 1
            if blockAnimSpeed > #_uiAnims then blockAnimSpeed = 1 end
            local _snd = Instance.new('Sound', char:FindFirstChild('HumanoidRootPart') or char)
            _snd.SoundId = 'rbxassetid://' .. _uiSounds[math.random(1, #_uiSounds)]
            _snd.Volume = Options.UIReactVolume.Value
            _snd:Play()
            task.delay(_snd.TimeLength + 4, function() pcall(function() _snd:Destroy() end) end)
        end
        _cbReactConn = char:GetAttributeChangedSignal('BlockReact'):Connect(function()
            if not Toggles.UIReactEnabled.Value then return end
            local blockReactVal = math.abs(char:GetAttribute('BlockReact') or 0)
            if blockAnimIdx < blockReactVal or math.abs(blockReactVal - blockAnimIdx) > 1 then
                resetBlockAnim()
            end
            blockAnimIdx = blockReactVal
        end)
        task.spawn(function()
            while _cbActive and lp.Character == char do
                local _Value10
                local cmdText = ''
                repeat
                    repeat
                        task.wait()
                        if not _cbActive or lp.Character ~= char then return end
                    until char:GetAttribute('Blocking') == true
                    _Value10 = Options.CustomBlockAnimation.Value
                    cmdText = _Value10 == 'Normal' and '' or (_Value10 == 'One Hand' and '17097146599' or (_Value10 == 'Gojo' and '18459178353' or (_Value10 == 'Infinity' and '15020965094' or (_Value10 == 'Boxer' and '14616272668' or ''))))
                until not cmdText:match('^%s*$')
                if not _cbActive or lp.Character ~= char then return end
                local cmdResult
                pcall(function()
                    local _anim = Instance.new('Animation')
                    _anim.AnimationId = 'rbxassetid://' .. cmdText
                    cmdResult = hum:LoadAnimation(_anim)
                end)
                if not cmdResult then
                    task.wait(0.1)
                    continue
                end
                _cbBlockTrack = cmdResult
                pcall(function()
                    if not cmdResult.IsPlaying then
                        cmdResult.Looped = true
                        cmdResult:Play()
                        if cmdText == '17097146599' then
                            cmdResult.TimePosition = 1
                            cmdResult:AdjustSpeed(0)
                        elseif cmdText == '18459178353' then
                            cmdResult.TimePosition = 0.5
                            cmdResult:AdjustSpeed(0)
                        elseif cmdText == '15020965094' then
                            cmdResult.TimePosition = 1
                            cmdResult:AdjustSpeed(0)
                        elseif cmdText == '14616272668' then
                            cmdResult.TimePosition = 0.25
                            cmdResult:AdjustSpeed(0)
                            game:GetService("TweenService"):Create(cmdResult, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true, 0), {TimePosition = 0.4}):Play()
                        end
                    end
                end)
                repeat
                    task.wait()
                until char:GetAttribute('Blocking') ~= true or not _cbActive or lp.Character ~= char
                pcall(function()
                    if cmdResult then cmdResult:Stop(0.1) end
                end)
                _cbBlockTrack = nil
            end
        end)
    end
    if lp.Character then task.spawn(_cbInit) end
    local _cbCharConn = lp.CharacterAdded:Connect(function(newChar)
        newChar:WaitForChild("Humanoid", 10)
        task.spawn(_cbInit)
    end)
    table.insert(CleanupTasks, function()
        _cbActive = false
        if _cbAnimConn  then _cbAnimConn:Disconnect()  _cbAnimConn  = nil end
        if _cbReactConn then _cbReactConn:Disconnect() _cbReactConn = nil end
        if _cbCharConn  then _cbCharConn:Disconnect()  _cbCharConn  = nil end
        pcall(function() Toggles.UIReactEnabled:SetValue(false) end)
        pcall(function() Options.CustomBlockAnimation:SetValue("Normal") end)
    end)
    local _auraCharConn = nil
    local _auraSounds   = {}
    local _activeAuras  = { UI = false, BR = false }
    local function _removeAura(char, name)
        if not char then return end
        for _, v in ipairs(char:GetDescendants()) do
            if v.Name == "AuraHolder_" .. name then
                for _, ref in ipairs(v:GetChildren()) do
                    if ref:IsA("ObjectValue") and ref.Value then
                        pcall(function() ref.Value:Destroy() end)
                    end
                end
                pcall(function() v:Destroy() end)
            end
        end
        -- Only destroy sounds when BR is the aura being removed; BR is the sole aura that spawns sounds.
        -- The old catch-all LimitedAura loop was removed — it was non-specific and would wipe
        -- particles belonging to a different aura that is still supposed to be running.
        if name == "BR" then
            for _, snd in ipairs(_auraSounds) do
                pcall(function() if snd and snd.Parent then snd:Destroy() end end)
            end
            _auraSounds = {}
        end
    end
    local function _applyUIAura(char)
        if not char then return end
        local ok, folder = pcall(function()
            return game:GetService("ReplicatedStorage").Emotes.VFX.VfxMods.Evolved.vfx.Folder
        end)
        if not ok or not folder then return end
        local auraFolder = Instance.new("Folder")
        auraFolder.Name = "AuraHolder_UI"
        pcall(function() auraFolder:SetAttribute("DivineForm", true) end)
        pcall(function() auraFolder:SetAttribute("LimAura", true) end)
        auraFolder.Parent = char
        for _, part in ipairs(folder:GetChildren()) do
            if part:IsA("BasePart") then
                local charPart = char:FindFirstChild(part.Name)
                if charPart then
                    local clone = part:Clone()
                    pcall(function() clone:SetAttribute("LimAura", true) end)
                    clone.Transparency = 1
                    clone.Massless     = true
                    clone.Name         = tostring(math.random(1, 1000000))
                    local weld = Instance.new("Weld")
                    weld.Part0  = charPart
                    weld.Part1  = clone
                    weld.Parent = clone
                    clone.Parent = auraFolder
                    for _, desc in ipairs(clone:GetDescendants()) do
                        if desc:IsA("ParticleEmitter") or desc:IsA("Beam") then
                            pcall(function() desc:SetAttribute("LimitedAura", true) end)
                        end
                    end
                end
            end
        end
    end
    local function _applyBoundlessAura(char)
        if not char then return end
        local ok, auraChar = pcall(function()
            return game:GetService("ReplicatedStorage").Emotes.VFX.VfxMods.Boundless.vfx.AuraChar:Clone()
        end)
        if not ok or not auraChar then return end
        local auraFolder = Instance.new("Folder")
        auraFolder.Name = "AuraHolder_BR"
        auraFolder.Parent = char
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
        if torso then
            local snd = Instance.new("Sound")
            snd.SoundId = "rbxassetid://81055990581650"
            snd.Looped   = true
            snd.Volume   = Options.AuraVolume.Value
            snd.Name     = "BRAuraSound"
            snd.Parent   = torso
            snd:Play()
            table.insert(_auraSounds, snd)
        end
        for _, part in ipairs(auraChar:GetChildren()) do
            if part:IsA("BasePart") then
                local charPart = char:FindFirstChild(part.Name)
                if charPart then
                    for _, desc in ipairs(part:GetChildren()) do
                        if desc:IsA("Attachment") or desc:IsA("ParticleEmitter") then
                            local clone = desc:Clone()
                            pcall(function() clone:SetAttribute("LimitedAura", true) end)
                            clone.Parent = charPart
                            local holder = Instance.new("ObjectValue")
                            holder.Name   = "BRAuraRef"
                            holder.Value  = clone
                            holder.Parent = auraFolder
                        end
                    end
                end
            end
        end
        auraChar:Destroy()
    end
    local function _applySelectedAuras(char)
        if not char then return end
        local val     = Options.AuraSelection and Options.AuraSelection.Value or {}
        local wantsUI = rawget(val, "Ultra Instinct") and true or false
        local wantsBR = rawget(val, "Boundless Rage")  and true or false

        -- Only tear down an aura when it has been deselected; leave everything else untouched
        -- so auras that are already running keep playing without a destroy-and-reapply stutter.
        if _activeAuras.UI and not wantsUI then
            _removeAura(char, "UI")
            _activeAuras.UI = false
        end
        if _activeAuras.BR and not wantsBR then
            _removeAura(char, "BR")
            _activeAuras.BR = false
        end

        -- Only spawn an aura that is wanted but not yet live.
        if wantsUI and not _activeAuras.UI then
            _applyUIAura(char)
            _activeAuras.UI = true
        end
        if wantsBR and not _activeAuras.BR then
            _applyBoundlessAura(char)
            _activeAuras.BR = true
        end
    end
    local function _updateAuraVolume()
        local vol = Options.AuraVolume.Value
        local char = lp.Character
        if char then
            for _, snd in ipairs(_auraSounds) do
                pcall(function() snd.Volume = vol end)
            end
        end
    end
    Options.AuraSelection:OnChanged(function()
        _applySelectedAuras(lp.Character)
    end)
    Options.AuraVolume:OnChanged(function()
        _updateAuraVolume()
    end)
    _auraCharConn = lp.CharacterAdded:Connect(function(newChar)
        -- New character model means nothing is live yet; reset tracking so _applySelectedAuras
        -- doesn't think the previous character's auras are still running.
        _activeAuras = { UI = false, BR = false }
        task.wait(1)
        _applySelectedAuras(newChar)
    end)
    table.insert(CleanupTasks, function()
        local char = lp.Character
        if char then
            _removeAura(char, "UI")
            _removeAura(char, "BR")
        end
        _activeAuras = { UI = false, BR = false }
        if _auraCharConn then _auraCharConn:Disconnect() _auraCharConn = nil end
        pcall(function() Options.AuraSelection:SetValue({}) end)
    end)
end
if isGamepassesGame and Tabs.Misc and TabMiscSaitama then
    local BoxSaitamaAnims = TabMiscSaitama
    local _SA_MOVES = {
        { trigger = "10468665991", label = "Normal Punch",        key = "NP" },
        { trigger = "10466974800", label = "Consecutive Punches", key = "CP" },
        { trigger = "10471336737", label = "Shove",               key = "SH" },
        { trigger = "12510170988", label = "Uppercut",            key = "UC" },
    }
    local _SA_IDS = {
        ["NP"] = {
            { name = "Open",          id = "18903642853",     timePos = 3.3, speed = nil,  stopAfter = 1,   stopFade = 0.2 },
            { name = "Kick",          id = "18897648446",     timePos = 3.1, speed = 1.5,  stopAfter = nil },
            { name = "Point",         id = "14498295360",     timePos = nil, speed = 2,    stopAfter = 1,   stopFade = 0.4 },
            { name = "Ravaging Kick", id = "16945550029",     timePos = 4,   speed = 1.8,  stopAfter = nil, speed2 = 1.2, speed2trigger = 5.1 },
            { name = "Strengthness",  id = "140164642047188", timePos = 6.9, speed = nil,  stopAfter = 0.4, stopFade = 0.2, id2 = "79761806706382", timePos2 = 3 },
            { name = "God's Fear",   id = "129123960742438",  timePos = 11.48, speed = 1.5, stopAfter = nil, stopFade = 0.1 },
            { name = "The Right Way", id = "125265459886863", timePos = 8, speed = 1.8, stopAfter = nil, stopFade = 0.2 },
        },
        ["CP"] = {
            { name = "Blue",   id = "13560306510", timePos = nil, speed = 2.7, stopAfter = nil },
            { name = "Barrage",id = "16945550029", timePos = 2,   speed = nil, stopAfter = nil, stopTrigger = 3.6, stopFade = 0.5 },
            { name = "Fury",   id = "12273188754", timePos = nil, speed = 2,   stopAfter = nil, cpLoop = true },
            { name = "God Slayer",  id = "129123960742438", timePos = 9.20, speed = nil, stopAfter = nil, stopTrigger = 10.8, stopFade = 0.1 },
            { name = "Fission",    id = "71181015443030",  timePos = 4.9,  speed = nil, stopAfter = nil, stopFade = 0.1 },
            { name = "Ripping Fist", id = "125265459886863", timePos = 1.65, speed = 1.5, stopAfter = nil, stopTrigger = 4.25, stopFade = 0.2 },
            { name = "Finishin'", id = "75127576841159", timePos = 1.1, speed = 2, stopAfter = nil, stopFade = 0.2 },
        },
        ["SH"] = {
            { name = "Slap",       id = "18440389930",    timePos = 1.2, speed = nil, stopAfter = 0.6, stopFade = 0.4 },
            { name = "Kick",       id = "18181348446",    timePos = nil, speed = nil, stopAfter = nil },
            { name = "Vanishing",  id = "18897118507",    timePos = 2.2, speed = 1,   stopAfter = nil, id2 = "17838619895", timePos2 = 0.45 },
            { name = "Sweep",      randIds = { "16944265635", "16944345619" }, timePos = nil, speed = nil, stopAfter = nil },
            { name = "Rage",       id = "79761806706382", timePos = 2.7, speed = nil, stopAfter = nil },
            { name = "Reverse",    id = "15124762088",    timePos = nil, speed = nil, stopAfter = nil },
        },
        ["UC"] = {
            { name = "Neck Destroyer", id = "18179181663",     timePos = nil, speed = nil, stopAfter = nil },
            { name = "Throw",          id = "136370737633649", timePos = 1,   speed = nil, stopAfter = 1,  stopFade = 0.45 },
            { name = "Jaw Breaker",   id = "97347443597947",    timePos = 3.6, speed = 0.9, stopAfter = nil, stopFade = 0.1 },
        },
    }
    BoxSaitamaAnims:AddToggle("CustomSaitamaEnabled", {
        Text = "Enable Custom Saitama Anims", Default = false,
    })
    BoxSaitamaAnims:AddDivider()
    for _, move in ipairs(_SA_MOVES) do
        local variants = _SA_IDS[move.key]
        local values = { "Default", "Random" }
        for _, v in ipairs(variants) do table.insert(values, v.name) end
        BoxSaitamaAnims:AddDropdown("CSA_" .. move.key, {
            Text = move.label, Values = values,
            Default = 1, Multi = false, Searchable = false,
        })
        if move.key == "CP" then
            BoxSaitamaAnims:AddToggle("NoBarrageArms", {
                Text = "Remove Barrage Arms", Default = false,
            })
        end
    end
    local _csaConn     = nil
    local _csaLoopConn = nil
    local _csaLastHum  = nil
    local _csaBBConn   = nil
    local function _csaHookBB(char)
        if _csaBBConn then _csaBBConn:Disconnect() _csaBBConn = nil end
        if not char then return end
        _csaBBConn = char.ChildAdded:Connect(function(child)
            if not Toggles.NoBarrageArms.Value then return end
            if lp:GetAttribute("Character") ~= "Bald" then return end
            if child.Name ~= "BarrageBind" then return end
            pcall(function() child:SetAttribute("Times", nil) end)
            task.defer(function() pcall(function() child:Destroy() end) end)
        end)
        for _, child in pairs(char:GetChildren()) do
            if child.Name == "BarrageBind" then
                if lp:GetAttribute("Character") ~= "Bald" then break end
                pcall(function() child:SetAttribute("Times", nil) end)
                task.defer(function() pcall(function() child:Destroy() end) end)
            end
        end
    end
    local function _bvYZero(char)
        local _conn = nil
        local function _zero(obj)
            if obj:IsA("BodyVelocity") then
                obj.Velocity = Vector3.new(obj.Velocity.X, 0, obj.Velocity.Z)
            end
        end
        _conn = char.DescendantAdded:Connect(_zero)
        for _, d in pairs(char:GetDescendants()) do _zero(d) end
        return _conn
    end
    local function _csaHook(hum)
        if _csaConn then _csaConn:Disconnect() _csaConn = nil end
        _csaLastHum = hum
        if not hum then return end
        _csaConn = hum.AnimationPlayed:Connect(function(track)
            if not Toggles.CustomSaitamaEnabled.Value then return end
            local animId = track.Animation and track.Animation.AnimationId or ""
            local rawId  = animId:match("%d+")
            if not rawId then return end
            local move = nil
            for _, m in ipairs(_SA_MOVES) do
                if rawId == m.trigger then move = m break end
            end
            if not move then return end
            local opt = Options["CSA_" .. move.key] and Options["CSA_" .. move.key].Value or "Default"
            if opt == "Default" then return end
            local variants = _SA_IDS[move.key]
            local cfg = nil
            if opt == "Random" then
                cfg = variants[math.random(1, #variants)]
            else
                for _, v in ipairs(variants) do
                    if v.name == opt then cfg = v break end
                end
            end
            if not cfg then return end
            track:AdjustWeight(-9999999, 0)
            local char = lp.Character
            local _bvConn = (char and cfg.bv) and _bvYZero(char) or nil
            local animId = cfg.id
            if cfg.randIds then
                animId = cfg.randIds[math.random(1, #cfg.randIds)]
            end
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. animId
            local ct = hum:LoadAnimation(anim)
            ct.Priority = Enum.AnimationPriority.Action3
            ct:Play(0.1)
            if cfg.speed   then ct:AdjustSpeed(cfg.speed) end
            if cfg.timePos then ct.TimePosition = cfg.timePos end
            track.Stopped:Connect(function()
                pcall(function() ct:Stop(cfg.stopFade or 0.25) end)
            end)
            if cfg.id2 then
                task.spawn(function()
                    local function playId2()
                        local anim2 = Instance.new("Animation")
                        anim2.AnimationId = "rbxassetid://" .. cfg.id2
                        local ct2 = hum:LoadAnimation(anim2)
                        ct2.Priority = Enum.AnimationPriority.Action3
                        ct2:Play(cfg.stopFade or 0.1)
                        if cfg.timePos2 then ct2.TimePosition = cfg.timePos2 end
                        ct2.Stopped:Connect(function()
                            if _bvConn then _bvConn:Disconnect() _bvConn = nil end
                        end)
                    end
                    if cfg.stopAfter then
                        task.wait(cfg.stopAfter)
                        if ct.IsPlaying then pcall(function() ct:Stop(cfg.stopFade or 0) end) end
                        playId2()
                    else
                        repeat task.wait() until ct.TimePosition >= 2.25 or not ct.IsPlaying
                        ct:Stop(0)
                        playId2()
                    end
                end)
            else
                if cfg.speed2 and cfg.speed2trigger then
                    task.spawn(function()
                        repeat task.wait() until ct.TimePosition >= cfg.speed2trigger or not ct.IsPlaying
                        if ct.IsPlaying then ct:AdjustSpeed(cfg.speed2) end
                    end)
                end
                if cfg.stopTrigger then
                    task.spawn(function()
                        repeat task.wait() until ct.TimePosition >= cfg.stopTrigger or not ct.IsPlaying
                        pcall(function() ct:Stop(cfg.stopFade or 0) end)
                    end)
                elseif cfg.stopAfter then
                    task.delay(cfg.stopAfter, function()
                        pcall(function() ct:Stop(cfg.stopFade or 1) end)
                    end)
                end
                if cfg.cpLoop then
                    task.spawn(function()
                        for _ = 1, 4 do
                            repeat task.wait() until ct.TimePosition >= 0.9 or not ct.IsPlaying
                            if not ct.IsPlaying then break end
                            ct.TimePosition = 0.6
                        end
                    end)
                end
                ct.Stopped:Connect(function()
                    if _bvConn then _bvConn:Disconnect() _bvConn = nil end
                end)
            end
        end)
    end
    _csaLoopConn = RunService.Heartbeat:Connect(function()
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum ~= _csaLastHum then
            _csaHook(hum)
            _csaHookBB(char)
        end
    end)
    table.insert(CleanupTasks, function()
        if _csaConn     then _csaConn:Disconnect()     _csaConn     = nil end
        if _csaLoopConn then _csaLoopConn:Disconnect() _csaLoopConn = nil end
        if _csaBBConn   then _csaBBConn:Disconnect()   _csaBBConn   = nil end
        _csaLastHum = nil
        pcall(function() Toggles.CustomSaitamaEnabled:SetValue(false) end)
        pcall(function() Toggles.NoBarrageArms:SetValue(false) end)
    end)
end
local _globalDashCooldown = false
local _frontDashCooldown  = false
getgenv()._revenantDashCooldown = false
getgenv()._revenantDashCooldownUntil = nil
getgenv()._revenantTechActive = false
getgenv()._wcDashOnCooldown = false
getgenv()._revenantTechFiring = false
local _globalDashConns    = {}
local function _hookGlobalCooldown(char)
    for _, c in ipairs(_globalDashConns) do pcall(function() c:Disconnect() end) end
    _globalDashConns = {}
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local function onAnim(track)
        if not track or not track.Animation then return end
        local id = tostring(track.Animation.AnimationId or "")
        if id:find("10479335397",1,true) or id:find("14357943487",1,true)
        or id:find("13380255751",1,true) or id:find("10491993682",1,true) then
            _globalDashCooldown = true
            _frontDashCooldown  = true
            getgenv()._wcDashOnCooldown = true
            task.delay(6, function()
                _globalDashCooldown = false
                _frontDashCooldown  = false
                getgenv()._wcDashOnCooldown = false
            end)
        end
    end
    table.insert(_globalDashConns, hum.AnimationPlayed:Connect(onAnim))
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then table.insert(_globalDashConns, animator.AnimationPlayed:Connect(onAnim)) end
end
task.spawn(function() _hookGlobalCooldown(lp.Character) end)
lp.CharacterAdded:Connect(function(char)
    task.spawn(function() task.wait(0.1) _hookGlobalCooldown(char) end)
end)
table.insert(CleanupTasks, function()
    for _, c in ipairs(_globalDashConns) do pcall(function() c:Disconnect() end) end
    _globalDashConns   = {}
    _globalDashCooldown = false
    _frontDashCooldown  = false
    getgenv()._revenantDashCooldown = false
    getgenv()._revenantDashCooldownUntil = nil
end)

do
    -- Auto Godslayer TP
    local _autoGodslayerActive = false
    local _autoGodslayerConn   = nil
    local _autoGodslayerTarget = nil
    local GODSLAYER_ANIM_ID    = "107484339495811"

    local function _getMarkedPlayers()
        local marked = {}
        local live = workspace:FindFirstChild("Live")
        if not live then return marked end
        local myChar = lp.Character
        for _, slot in pairs(live:GetChildren()) do
            if slot ~= myChar and slot:FindFirstChild("Ok") then
                table.insert(marked, slot)
            end
        end
        return marked
    end

    BoxAutomation:AddToggle('AutoGodslayerTP', {
        Text    = 'Auto Cosmic Garou',
        Tooltip = 'If you mark someone using Hunters Mark and use Godslayer this will automatically teleport to someone that is marked',
        Default = false,
        Callback = function(val)
            _autoGodslayerActive = val
            if val then
                if _autoGodslayerConn then _autoGodslayerConn:Disconnect() end
                _autoGodslayerConn = RunService.Heartbeat:Connect(function()
                    local c = lp.Character
                    if not c then return end
                    if c:GetAttribute("AbsoluteImmortal") then return end
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    if not hum or hum.Health <= 0 then return end
                    local animator = hum:FindFirstChildOfClass("Animator")
                    if not animator then return end
                    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                        if track.Animation and track.Animation.AnimationId:match(GODSLAYER_ANIM_ID) and track.TimePosition >= 0.30 then
                            -- verify current target is still marked, else re-pick
                            local live = workspace:FindFirstChild("Live")
                            local targetStillMarked = false
                            if _autoGodslayerTarget and live then
                                targetStillMarked = _autoGodslayerTarget.Parent == live and _autoGodslayerTarget:FindFirstChild("Ok") ~= nil
                            end
                            if not targetStillMarked then
                                local marked = _getMarkedPlayers()
                                _autoGodslayerTarget = #marked > 0 and marked[1] or nil
                            end
                            if not _autoGodslayerTarget then return end
                            local tr = _autoGodslayerTarget:FindFirstChild("HumanoidRootPart")
                            if tr then
                                local dest = tr.CFrame * CFrame.new(0, 0, 2)
                                local r = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                                if _shpSupported and r then
                                    r.CFrame = dest
                                    r.AssemblyLinearVelocity  = Vector3.zero
                                    r.AssemblyAngularVelocity = Vector3.zero
                                    pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", tr) end)
                                    RunService.Heartbeat:Once(function()
                                        pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", nil) end)
                                    end)
                                else
                                    RunService.Heartbeat:Once(function()
                                        RunService.Heartbeat:Once(function()
                                            local r2 = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                                            if r2 then r2.CFrame = dest end
                                        end)
                                    end)
                                end
                            end
                            return
                        end
                    end
                end)
            else
                if _autoGodslayerConn then _autoGodslayerConn:Disconnect() _autoGodslayerConn = nil end
                _autoGodslayerTarget = nil
            end
        end,
    })
    table.insert(CleanupTasks, function()
        _autoGodslayerActive = false
        _autoGodslayerTarget = nil
        if _autoGodslayerConn then _autoGodslayerConn:Disconnect() _autoGodslayerConn = nil end
        pcall(function() Toggles.AutoGodslayerTP:SetValue(false) end)
    end)
end

if isGamepassesGame then
    BoxAutomation:AddButton({
        Text = "Free Stargazer / Nightchild",
        Func = function()
            local char = lp.Character
            local comm = char and char:FindFirstChild("Communicate")
            if comm then
                comm:FireServer({ Goal = "Gaze" })
            end
        end,
    })
end
end, tostring)
if not _featOk then
    warn("[Revenant FEATURES ERROR]: " .. tostring(_featErr))
end
do
    -- Sincroniza a visibilidade do keybind no painel com o valor do toggle pai.
    -- Usa OnChanged em vez de RenderStepped: roda só quando o estado muda
    -- e inicializa imediatamente, garantindo que keybinds de toggles desligados
    -- fiquem ocultos desde o primeiro frame.
    local function _syncKBVis(optKey, togKey)
        local tog = Toggles[togKey]
        if not tog then return end
        local function _apply(val)
            local opt = Options[optKey]
            -- opt.KeybindsToggle must be a real table with SetVisibility.
            -- The Options safety stub returns a function() for any missing field,
            -- so type == "table" correctly rejects it without touching the stub.
            if opt and type(opt.KeybindsToggle) == "table" then
                opt.KeybindsToggle:SetVisibility(val == true)
            end
        end
        _apply(tog.Value)       -- estado inicial correto já na criação
        tog:OnChanged(_apply)   -- atualiza sempre que o toggle mudar
    end

    _syncKBVis("RevenantFlyBind",  "RevenantFly")
    _syncKBVis("AnimeTPKeybind",   "AnimeTeleportation")
    _syncKBVis("L-OnKeybind",      "Lock-on")
    _syncKBVis("KPInvis",          "TogInvis")
    _syncKBVis("KPHeadFloat",      "TogHeadFloat")
    _syncKBVis("KPJerk",           "TogJerk")
    _syncKBVis("KPBang",           "TogBang")
    _syncKBVis("KPTPose",          "TogTPose")
    _syncKBVis("KPFUC",            "TogFUC")
    _syncKBVis("TouchFlingBind",   "TouchFlingEnabled")
    _syncKBVis("KPWeld",           "TogWeld")
end
SaveManager:LoadAutoloadConfig()
if getgenv()._disguiseAutoApply then getgenv()._disguiseAutoApply() end
end)
if trashcanGameIds[currentPlaceId] then
    local _Folder2 = Instance.new("Folder")
    _Folder2.Name  = "RemovedTrees"
    _Folder2.Parent = game:GetService("CoreGui")
    local _Folder3 = Instance.new("Folder")
    _Folder3.Name  = "RemovedWalls"
    _Folder3.Parent = game:GetService("CoreGui")
    local _Lighting = game:GetService("Lighting")
    BoxVisualsWorld:AddToggle("NoWalls", {
        Text    = "No Walls",
        Default = false,
        Callback = function(val)
            local map = workspace:FindFirstChild("Map")
            if not map then return end
            if val then
                for _, child in pairs(map:GetChildren()) do
                    if table.find({"Walls","GrassTop","Tunnel","Part"}, child.Name) then
                        child.Parent = _Folder3
                    end
                end
            else
                for _, child in pairs(_Folder3:GetChildren()) do
                    child.Parent = workspace.Map
                end
            end
        end,
    })
    BoxVisualsWorld:AddToggle("NoTrees", {
        Text    = "No Trees",
        Default = false,
        Callback = function(val)
            local trees = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Trees")
            if not trees then return end
            if val then
                for _, child in pairs(trees:GetChildren()) do child.Parent = _Folder2 end
            else
                for _, child in pairs(_Folder2:GetChildren()) do
                    child.Parent = workspace.Map.Trees
                end
            end
        end,
    })
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Trees") then
        workspace.Map.Trees.ChildAdded:Connect(function(p738)
            if Toggles.NoTrees.Value then
                RunService.RenderStepped:Wait()
                p738.Parent = _Folder2
            end
        end)
    end
    local function _deleteNew(inst, newInstance)
        task.wait()
        local _Parent2 = inst.Parent
        inst:Destroy()
        if newInstance then
            warn("Instance removed, Name:", inst.Name, "ClassName:", inst.ClassName, "Parent:", _Parent2)
        end
    end
    BoxVisualsWorld:AddToggle("NoDebris", {
        Text    = "No Debris",
        Default = false,
        Callback = function(val)
            if val then
                local thrown = workspace:FindFirstChild("Thrown")
                if thrown then
                    for _, child in pairs(thrown:GetChildren()) do
                        if child.Name:lower():find("debris") or child.Name:lower() == "part" then
                            task.spawn(pcall, _deleteNew, child)
                        end
                    end
                end
            end
        end,
    })
    BoxVisualsWorld:AddToggle("NoSmoke", {
        Text    = "No Smoke",
        Default = false,
        Callback = function(val)
            if val then
                local thrown = workspace:FindFirstChild("Thrown")
                if thrown then
                    for _, child in pairs(thrown:GetChildren()) do
                        if child.Name:lower():find("smoke") then
                            task.spawn(pcall, _deleteNew, child)
                        end
                    end
                end
            end
        end,
    })
    BoxVisualsWorld:AddToggle("NoExplosions", {
        Text    = "No Explosions",
        Default = false,
        Callback = function(val)
            if val then
                local thrown = workspace:FindFirstChild("Thrown")
                if thrown then
                    for _, child in pairs(thrown:GetChildren()) do
                        if child.Name:lower():find("explo") then
                            task.spawn(pcall, _deleteNew, child)
                        end
                    end
                end
            end
        end,
    })
    workspace.ChildAdded:Connect(function(child)
        if child.Name:lower() == "adjustedhb" and rawget(Options.AntiMoves_Tatsumaki.Value, "Anti Stone Grave") then
            task.spawn(pcall, _deleteNew, child, false)
        end
    end)
    local function _hookThrown(thrown)
        thrown.ChildAdded:Connect(function(child)
            if (child.Name:lower():find("debris") or child.Name:lower() == "part") and Toggles.NoDebris.Value then
                task.spawn(pcall, _deleteNew, child, false)
            elseif child.Name:lower():find("tree") and Toggles.NoTrees.Value then
                task.spawn(pcall, _deleteNew, child, false)
            elseif child.Name:lower():find("smoke") and Toggles.NoSmoke.Value then
                task.spawn(pcall, _deleteNew, child, false)
            elseif child.Name:lower():find("explo") and Toggles.NoExplosions.Value then
                task.spawn(pcall, _deleteNew, child, false)
            elseif table.find({"beamed","adjusted"}, child.Name:lower()) then
                if rawget(Options.AntiMoves_Tatsumaki.Value, "Anti Stone Grave") then
                    for _, v in pairs(child:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.Transparency   = 0.8
                            v.CollisionGroup = "untouchable"
                            v.Massless       = true
                            v.CanCollide     = false
                            v.CanTouch       = false
                            v.CanQuery       = false
                        end
                    end
                end
            elseif (child:IsA("Part") and (child.Size == Vector3.new(20,20,20) and child.Shape == Enum.PartType.Ball) or child.Name == "Part") and rawget(Options.AntiMoves_Tatsumaki.Value, "Anti Stone Grave") then
                task.spawn(pcall, _deleteNew, child, false)
            end
        end)
    end
    local _thrownFolder = workspace:FindFirstChild("Thrown")
    if _thrownFolder then
        _hookThrown(_thrownFolder)
    else
        workspace.ChildAdded:Connect(function(child)
            if child.Name == "Thrown" then _hookThrown(child) end
        end)
    end
    local _sibConns = {}
    BoxVisualsWorld:AddToggle("SeeInvisibleBorders", {
        Text    = "See Invisible Borders",
        Default = false,
        Callback = function(val)
            for _, conn in pairs(_sibConns) do pcall(function() conn:Disconnect() end) end
            table.clear(_sibConns)
            local map = workspace:FindFirstChild("Map")
            local folder = map and map:FindFirstChild("InvisibleBorder")
            if not folder then return end
            for _, obj in pairs(folder:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Transparency = val and 0.2 or 1
                    if val then
                        _sibConns[#_sibConns + 1] = obj:GetPropertyChangedSignal("Transparency"):Connect(function()
                            if Toggles.SeeInvisibleBorders.Value and obj.Transparency ~= 0.2 then
                                obj.Transparency = 0.2
                            end
                        end)
                    end
                end
            end
            if val then
                _sibConns[#_sibConns + 1] = folder.DescendantAdded:Connect(function(obj)
                    if not obj:IsA("BasePart") then return end
                    obj.Transparency = 0.2
                    _sibConns[#_sibConns + 1] = obj:GetPropertyChangedSignal("Transparency"):Connect(function()
                        if Toggles.SeeInvisibleBorders.Value and obj.Transparency ~= 0.2 then
                            obj.Transparency = 0.2
                        end
                    end)
                end)
            end
        end,
    })
    table.insert(CleanupTasks, function()
        for _, conn in pairs(_sibConns) do pcall(function() conn:Disconnect() end) end
        table.clear(_sibConns)
        pcall(function() Toggles.SeeInvisibleBorders:SetValue(false) end)
    end)
    BoxVisualsWorld:AddDivider()
    BoxVisualsWorld:AddToggle("AmbientEnabled", {
        Text    = "Ambient Enabled",
        Default = false,
        Callback = function(val)
            if val then
                local _Ambient = _Lighting.Ambient
                _Lighting.Ambient = Options.AmbientColor.Value
                repeat task.wait() until not Toggles.AmbientEnabled.Value
                _Lighting.Ambient = _Ambient
            end
        end,
    }):AddColorPicker("AmbientColor", {
        Default  = Color3.fromRGB(255, 255, 255),
        Title    = "Ambient",
        Callback = function(color)
            if Toggles.AmbientEnabled.Value then
                _Lighting.Ambient = color
            end
        end,
    })
    BoxVisualsWorld:AddToggle("RainbowAmbient", {
        Text    = "Rainbow Ambient",
        Default = false,
        Callback = function(val)
            if val then
                repeat
                    local t = tick() * 2
                    local r = math.abs(math.sin(t))                   * 255
                    local g = math.abs(math.sin(t + math.pi / 3))     * 255
                    local b = math.abs(math.sin(t + 2 * math.pi / 3)) * 255
                    Options.AmbientColor:SetValueRGB(Color3.fromRGB(r, g, b))
                    Options.AmbientColor:Update()
                    task.wait(0.03)
                until not Toggles.RainbowAmbient.Value
                Options.AmbientColor:SetValueRGB(Color3.fromRGB(255, 255, 255))
                Options.AmbientColor:Update()
            end
        end,
    })
    BoxVisualsWorld:AddDivider()
    BoxVisualsWorld:AddDropdown("LightingPreset", {
        Text    = "Lighting Preset",
        Values  = {"None", "Warm", "Night", "Sunrising", "Auto-Sky"},
        Default = "None",
        Callback = function(val)
            local function _saveOriginals()
                if getgenv()._lightingPresetOrig then return end
                getgenv()._lightingPresetOrig = {
                    ClockTime                = _Lighting.ClockTime,
                    Brightness               = _Lighting.Brightness,
                    ExposureCompensation     = _Lighting.ExposureCompensation,
                    Ambient                  = _Lighting.Ambient,
                    OutdoorAmbient           = _Lighting.OutdoorAmbient,
                    FogColor                 = _Lighting.FogColor,
                    FogStart                 = _Lighting.FogStart,
                    FogEnd                   = _Lighting.FogEnd,
                    GeographicLatitude       = _Lighting.GeographicLatitude,
                    ShadowSoftness           = _Lighting.ShadowSoftness,
                    GlobalShadows            = _Lighting.GlobalShadows,
                    EnvironmentDiffuseScale  = _Lighting.EnvironmentDiffuseScale,
                    EnvironmentSpecularScale = _Lighting.EnvironmentSpecularScale,
                    Technology               = _Lighting.Technology,
                }
                local _a = _Lighting:FindFirstChildOfClass("Atmosphere")
                if _a then
                    getgenv()._lightingPresetOrig.Atmo = {
                        Density = _a.Density, Offset = _a.Offset,
                        Color   = _a.Color,   Decay  = _a.Decay,
                        Glare   = _a.Glare,   Haze   = _a.Haze,
                    }
                end
                local _s = _Lighting:FindFirstChildOfClass("SunRaysEffect")
                if _s then
                    getgenv()._lightingPresetOrig.SunRays = {
                        Intensity = _s.Intensity, Spread = _s.Spread,
                    }
                end
                local _bl = _Lighting:FindFirstChildOfClass("BloomEffect")
                if _bl then
                    getgenv()._lightingPresetOrig.Bloom = {
                        Intensity = _bl.Intensity, Size = _bl.Size, Threshold = _bl.Threshold,
                        Enabled   = _bl.Enabled,
                    }
                else
                    getgenv()._lightingPresetOrig.Bloom = false  -- was absent; we created it
                end
                local _cc = _Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
                if _cc then
                    getgenv()._lightingPresetOrig.ColorCorrection = {
                        Brightness  = _cc.Brightness,  Contrast   = _cc.Contrast,
                        Saturation  = _cc.Saturation,  TintColor  = _cc.TintColor,
                        Enabled     = _cc.Enabled,
                    }
                else
                    getgenv()._lightingPresetOrig.ColorCorrection = false
                end
                local _sk = _Lighting:FindFirstChildOfClass("Sky")
                if _sk then
                    getgenv()._lightingPresetOrig.MoonAngularSize = _sk.MoonAngularSize
                    getgenv()._lightingPresetOrig.SunAngularSize  = _sk.SunAngularSize
                end
            end

            local function _restoreOriginals()
                local orig = getgenv()._lightingPresetOrig
                if not orig then return end
                _Lighting.ClockTime                = orig.ClockTime
                _Lighting.Brightness               = orig.Brightness
                _Lighting.ExposureCompensation     = orig.ExposureCompensation
                _Lighting.Ambient                  = orig.Ambient
                _Lighting.OutdoorAmbient           = orig.OutdoorAmbient
                _Lighting.FogColor                 = orig.FogColor
                _Lighting.FogStart                 = orig.FogStart
                _Lighting.FogEnd                   = orig.FogEnd
                _Lighting.GeographicLatitude       = orig.GeographicLatitude
                _Lighting.ShadowSoftness           = orig.ShadowSoftness
                _Lighting.GlobalShadows            = orig.GlobalShadows
                _Lighting.EnvironmentDiffuseScale  = orig.EnvironmentDiffuseScale
                _Lighting.EnvironmentSpecularScale = orig.EnvironmentSpecularScale
                _Lighting.Technology               = orig.Technology
                local _atmo = _Lighting:FindFirstChildOfClass("Atmosphere")
                if _atmo and orig.Atmo then
                    _atmo.Density = orig.Atmo.Density
                    _atmo.Offset  = orig.Atmo.Offset
                    _atmo.Color   = orig.Atmo.Color
                    _atmo.Decay   = orig.Atmo.Decay
                    _atmo.Glare   = orig.Atmo.Glare
                    _atmo.Haze    = orig.Atmo.Haze
                end
                local _sun = _Lighting:FindFirstChildOfClass("SunRaysEffect")
                if _sun and orig.SunRays then
                    _sun.Intensity = orig.SunRays.Intensity
                    _sun.Spread    = orig.SunRays.Spread
                end
                -- Bloom: if it didn't exist before we inserted it, destroy it; else restore
                local _bl = _Lighting:FindFirstChildOfClass("BloomEffect")
                if orig.Bloom == false then
                    if _bl then pcall(function() _bl:Destroy() end) end
                elseif orig.Bloom and _bl then
                    _bl.Intensity  = orig.Bloom.Intensity
                    _bl.Size       = orig.Bloom.Size
                    _bl.Threshold  = orig.Bloom.Threshold
                    _bl.Enabled    = orig.Bloom.Enabled
                end
                -- ColorCorrection: same pattern
                local _cc = _Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
                if orig.ColorCorrection == false then
                    if _cc then pcall(function() _cc:Destroy() end) end
                elseif orig.ColorCorrection and _cc then
                    _cc.Brightness = orig.ColorCorrection.Brightness
                    _cc.Contrast   = orig.ColorCorrection.Contrast
                    _cc.Saturation = orig.ColorCorrection.Saturation
                    _cc.TintColor  = orig.ColorCorrection.TintColor
                    _cc.Enabled    = orig.ColorCorrection.Enabled
                end
                if orig.SkyRef and orig.SkyRef.Parent then
                    orig.SkyRef.Parent = _Lighting
                end
                local _sk = _Lighting:FindFirstChildOfClass("Sky")
                if _sk and orig.MoonAngularSize then
                    _sk.MoonAngularSize = orig.MoonAngularSize
                end
                if _sk and orig.SunAngularSize then
                    _sk.SunAngularSize = orig.SunAngularSize
                end
                getgenv()._lightingPresetOrig = nil
            end

            local function _unstashSky()
                local orig = getgenv()._lightingPresetOrig
                if orig and orig.SkyRef then
                    local ref = orig.SkyRef
                    if ref and ref.Parent ~= _Lighting then
                        ref.Parent = _Lighting
                    end
                    orig.SkyRef = nil
                end
            end

            local _techEnumMap = {
                ["Unified"]       = Enum.Technology.Unified,
                ["Future"]        = Enum.Technology.Future,
                ["ShadowMap"]     = Enum.Technology.ShadowMap,
                ["Voxel"]         = Enum.Technology.Voxel,
                ["Compatibility"] = Enum.Technology.Compatibility,
            }
            local function _getSelectedTech()
                return _techEnumMap[Options.LightingTechnology and Options.LightingTechnology.Value] or Enum.Technology.Unified
            end

            -- ── AUTO-SKY: cinematic 16-stage timezone keyframe table ──────────────────
            -- Each stage: clock(0-24), Brightness(Br), ExposureCompensation(EC),
            --   Ambient(Amb), OutdoorAmbient(OA), FogColor(Fog), FogEnd(FE),
            --   EnvironmentDiffuse(ED), EnvironmentSpecular(ES), ShadowSoftness(SR),
            --   AtmoDensity(AD), AtmoOffset(AO), AtmoColor(AC), AtmoDecay(Adc),
            --   AtmoGlare(AG), AtmoHaze(AH),
            --   SunRaysIntensity(SI), SunRaysSpread(SS),
            --   BloomIntensity(BlI), BloomSize(BlS), BloomThreshold(BlT),
            --   CCBrightness(CCB), CCContrast(CCC), CCSaturation(CCS), CCTint(CCT)
            --
            -- Night philosophy: match the Night preset feel (Br~3.5, EC~1.1) but with
            -- rich purple-blue ambients instead of flat black. Visible, beautiful, not dark.
            -- Sunset philosophy: haze/glare kept LOW so orange stays on the sun, not the world.
            local _TZ_STAGES = {
                -- 00:00  Midnight
                { clock=0,    Br=3.60, EC=1.05,
                  Amb=Color3.fromRGB(72,80,162),   OA=Color3.fromRGB(58,68,148),
                  Fog=Color3.fromRGB(48,54,122),   FE=4000,  ED=0.65, ES=0.55, SR=0.14,
                  AD=0.22, AO=0.00, AC=Color3.fromRGB(18,12,72),  Adc=Color3.fromRGB(8,5,48),
                  AG=0.00, AH=0.05, SI=0.00, SS=0.020,
                  BlI=0.30, BlS=24, BlT=0.80,
                  CCB=0.02, CCC=0.10, CCS=0.08, CCT=Color3.fromRGB(185,178,245) },
                -- 02:30  Witching Hours
                { clock=2.5,  Br=3.55, EC=1.02,
                  Amb=Color3.fromRGB(66,72,152),   OA=Color3.fromRGB(52,60,138),
                  Fog=Color3.fromRGB(42,48,118),   FE=3800,  ED=0.62, ES=0.52, SR=0.13,
                  AD=0.24, AO=0.00, AC=Color3.fromRGB(14,10,64),  Adc=Color3.fromRGB(6,4,42),
                  AG=0.00, AH=0.04, SI=0.00, SS=0.020,
                  BlI=0.28, BlS=22, BlT=0.82,
                  CCB=0.01, CCC=0.10, CCS=0.05, CCT=Color3.fromRGB(182,174,242) },
                -- 04:30  Nautical Twilight
                { clock=4.5,  Br=2.20, EC=0.65,
                  Amb=Color3.fromRGB(55,40,120),   OA=Color3.fromRGB(45,30,108),
                  Fog=Color3.fromRGB(48,34,112),   FE=3800,  ED=0.60, ES=0.50, SR=0.16,
                  AD=0.20, AO=0.00, AC=Color3.fromRGB(22,10,80),  Adc=Color3.fromRGB(12,5,55),
                  AG=0.02, AH=0.08, SI=0.20, SS=0.022,
                  BlI=0.24, BlS=24, BlT=0.78,
                  CCB=0.00, CCC=0.10, CCS=0.10, CCT=Color3.fromRGB(178,165,228) },
                -- 05:30  Civil Twilight
                { clock=5.5,  Br=0.80, EC=0.22,
                  Amb=Color3.fromRGB(118,80,148),  OA=Color3.fromRGB(135,88,162),
                  Fog=Color3.fromRGB(148,94,158),  FE=4400,  ED=0.73, ES=0.62, SR=0.20,
                  AD=0.17, AO=0.01, AC=Color3.fromRGB(82,42,115), Adc=Color3.fromRGB(55,22,82),
                  AG=0.08, AH=0.12, SI=0.35, SS=0.035,
                  BlI=0.36, BlS=30, BlT=0.68,
                  CCB=0.02, CCC=0.14, CCS=0.20, CCT=Color3.fromRGB(225,185,215) },
                -- 06:20  Sunrise  [mirrors Sunrising preset]
                { clock=6.33, Br=0.00, EC=0.00,
                  Amb=Color3.fromRGB(0,0,0),       OA=Color3.fromRGB(25,25,25),
                  Fog=Color3.fromRGB(192,192,192), FE=5000,  ED=1.00, ES=1.00, SR=0.20,
                  AD=0.213, AO=0.00, AC=Color3.fromRGB(2,2,2),   Adc=Color3.fromRGB(0,0,0),
                  AG=0.00, AH=0.00, SI=0.72, SS=0.049,
                  BlI=0.18, BlS=18, BlT=0.68,
                  CCB=0.00, CCC=0.12, CCS=0.18, CCT=Color3.fromRGB(245,215,178) },
                -- 07:30  Early Morning  [mirrors Warm preset]
                { clock=7.5,  Br=0.00, EC=0.40,
                  Amb=Color3.fromRGB(163,172,143), OA=Color3.fromRGB(202,180,113),
                  Fog=Color3.fromRGB(192,192,192), FE=5000,  ED=0.756, ES=0.585, SR=0.18,
                  AD=0.213, AO=0.00, AC=Color3.fromRGB(2,2,2),   Adc=Color3.fromRGB(0,0,0),
                  AG=0.00, AH=0.00, SI=0.95, SS=0.14,
                  BlI=0.22, BlS=20, BlT=0.70,
                  CCB=0.01, CCC=0.10, CCS=0.16, CCT=Color3.fromRGB(245,230,205) },
                -- 09:00  Mid-Morning
                { clock=9.0,  Br=0.00, EC=0.12,
                  Amb=Color3.fromRGB(138,152,168), OA=Color3.fromRGB(148,160,175),
                  Fog=Color3.fromRGB(185,190,200), FE=7400,  ED=0.88, ES=0.85, SR=0.10,
                  AD=0.09, AO=0.05, AC=Color3.fromRGB(20,42,68),  Adc=Color3.fromRGB(10,24,48),
                  AG=0.02, AH=0.08, SI=0.25, SS=0.022,
                  BlI=0.14, BlS=18, BlT=0.88,
                  CCB=0.00, CCC=0.07, CCS=0.08, CCT=Color3.fromRGB(235,240,252) },
                -- 12:00  Noon
                { clock=12.0, Br=0.00, EC=0.00,
                  Amb=Color3.fromRGB(148,160,175), OA=Color3.fromRGB(158,168,182),
                  Fog=Color3.fromRGB(192,192,192), FE=9500,  ED=0.92, ES=0.90, SR=0.08,
                  AD=0.05, AO=0.08, AC=Color3.fromRGB(15,42,82),  Adc=Color3.fromRGB(8,25,60),
                  AG=0.01, AH=0.05, SI=0.15, SS=0.018,
                  BlI=0.08, BlS=16, BlT=0.92,
                  CCB=-0.02, CCC=0.06, CCS=0.06, CCT=Color3.fromRGB(232,238,252) },
                -- 15:00  Afternoon
                { clock=15.0, Br=0.00, EC=0.10,
                  Amb=Color3.fromRGB(160,156,142), OA=Color3.fromRGB(172,158,135),
                  Fog=Color3.fromRGB(188,182,170), FE=7600,  ED=0.88, ES=0.85, SR=0.12,
                  AD=0.09, AO=0.04, AC=Color3.fromRGB(28,40,58),  Adc=Color3.fromRGB(15,22,38),
                  AG=0.03, AH=0.12, SI=0.30, SS=0.025,
                  BlI=0.15, BlS=18, BlT=0.82,
                  CCB=0.00, CCC=0.07, CCS=0.08, CCT=Color3.fromRGB(245,238,218) },
                -- 16:30  Pre-Sunset Gold
                { clock=16.5, Br=0.00, EC=0.28,
                  Amb=Color3.fromRGB(195,178,148), OA=Color3.fromRGB(210,182,138),
                  Fog=Color3.fromRGB(200,182,158), FE=6200,  ED=0.94, ES=0.90, SR=0.18,
                  AD=0.09, AO=0.03, AC=Color3.fromRGB(68,52,22),  Adc=Color3.fromRGB(42,28,8),
                  AG=0.10, AH=0.20, SI=0.55, SS=0.032,
                  BlI=0.35, BlS=16, BlT=0.65,
                  CCB=0.02, CCC=0.11, CCS=0.16, CCT=Color3.fromRGB(248,235,210) },
                -- 17:30  Peak Golden Hour
                { clock=17.5, Br=0.00, EC=0.28,
                  Amb=Color3.fromRGB(210,175,128), OA=Color3.fromRGB(222,180,118),
                  Fog=Color3.fromRGB(215,172,138), FE=5600,  ED=0.92, ES=0.87, SR=0.20,
                  AD=0.10, AO=0.03, AC=Color3.fromRGB(88,58,22),  Adc=Color3.fromRGB(58,32,8),
                  AG=0.18, AH=0.25, SI=0.80, SS=0.060,
                  BlI=0.55, BlS=18, BlT=0.55,
                  CCB=0.02, CCC=0.13, CCS=0.18, CCT=Color3.fromRGB(252,230,200) },
                -- 18:30  Sunset
                { clock=18.5, Br=0.30, EC=0.38,
                  Amb=Color3.fromRGB(175,128,108), OA=Color3.fromRGB(192,132,112),
                  Fog=Color3.fromRGB(182,122,118), FE=5000,  ED=0.88, ES=0.83, SR=0.20,
                  AD=0.12, AO=0.02, AC=Color3.fromRGB(105,48,28), Adc=Color3.fromRGB(75,22,12),
                  AG=0.12, AH=0.28, SI=0.65, SS=0.034,
                  BlI=0.50, BlS=18, BlT=0.58,
                  CCB=0.02, CCC=0.12, CCS=0.14, CCT=Color3.fromRGB(242,208,195) },
                -- 19:30  Dusk
                { clock=19.5, Br=1.60, EC=0.72,
                  Amb=Color3.fromRGB(88,68,158),   OA=Color3.fromRGB(75,58,145),
                  Fog=Color3.fromRGB(80,62,148),   FE=4200,  ED=0.72, ES=0.62, SR=0.18,
                  AD=0.18, AO=0.01, AC=Color3.fromRGB(45,20,105), Adc=Color3.fromRGB(28,10,75),
                  AG=0.04, AH=0.12, SI=0.18, SS=0.022,
                  BlI=0.34, BlS=28, BlT=0.68,
                  CCB=0.02, CCC=0.12, CCS=0.12, CCT=Color3.fromRGB(195,180,240) },
                -- 21:00  Evening
                { clock=21.0, Br=3.60, EC=1.05,
                  Amb=Color3.fromRGB(72,85,164),   OA=Color3.fromRGB(58,72,150),
                  Fog=Color3.fromRGB(45,55,100),   FE=4000,  ED=0.65, ES=0.55, SR=0.15,
                  AD=0.21, AO=0.00, AC=Color3.fromRGB(12,20,72),  Adc=Color3.fromRGB(5,10,40),
                  AG=0.00, AH=0.06, SI=0.00, SS=0.020,
                  BlI=0.32, BlS=24, BlT=0.76,
                  CCB=0.02, CCC=0.10, CCS=0.08, CCT=Color3.fromRGB(188,180,245) },
                -- 22:30  Full Night
                { clock=22.5, Br=3.65, EC=1.08,
                  Amb=Color3.fromRGB(72,85,164),   OA=Color3.fromRGB(58,72,150),
                  Fog=Color3.fromRGB(45,55,100),   FE=4000,  ED=0.65, ES=0.55, SR=0.14,
                  AD=0.22, AO=0.00, AC=Color3.fromRGB(12,20,72),  Adc=Color3.fromRGB(5,10,40),
                  AG=0.00, AH=0.04, SI=0.00, SS=0.020,
                  BlI=0.30, BlS=24, BlT=0.80,
                  CCB=0.02, CCC=0.10, CCS=0.08, CCT=Color3.fromRGB(185,178,245) },
                -- 24:00  Loop sentinel
                { clock=24.0, Br=3.60, EC=1.05,
                  Amb=Color3.fromRGB(72,80,162),   OA=Color3.fromRGB(58,68,148),
                  Fog=Color3.fromRGB(48,54,122),   FE=4000,  ED=0.65, ES=0.55, SR=0.14,
                  AD=0.22, AO=0.00, AC=Color3.fromRGB(18,12,72),  Adc=Color3.fromRGB(8,5,48),
                  AG=0.00, AH=0.04, SI=0.00, SS=0.020,
                  BlI=0.30, BlS=24, BlT=0.80,
                  CCB=0.02, CCC=0.10, CCS=0.08, CCT=Color3.fromRGB(185,178,245) },
            }

            local function _applyPreset(preset)
                if preset == "Warm" then
                    _unstashSky()
                    _Lighting.ClockTime                = 6.581944465637207
                    _Lighting.Brightness               = 0
                    _Lighting.ExposureCompensation     = 0.4
                    _Lighting.Ambient                  = Color3.fromRGB(163, 172, 143)
                    _Lighting.OutdoorAmbient           = Color3.fromRGB(202, 180, 113)
                    _Lighting.FogColor                 = Color3.fromRGB(192, 192, 192)
                    _Lighting.FogStart                 = 0
                    _Lighting.FogEnd                   = 5000
                    _Lighting.GeographicLatitude       = 314.8041076660156
                    _Lighting.ShadowSoftness           = 0.2
                    _Lighting.GlobalShadows            = true
                    _Lighting.EnvironmentDiffuseScale  = 0.756
                    _Lighting.EnvironmentSpecularScale = 0.585
                    _Lighting.Technology               = _getSelectedTech()
                    local _atmo = _Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", _Lighting)
                    _atmo.Density = 0.213  _atmo.Offset = 0
                    _atmo.Color   = Color3.fromRGB(2, 2, 2)
                    _atmo.Decay   = Color3.fromRGB(0, 0, 0)
                    _atmo.Glare   = 0      _atmo.Haze = 0
                    local _sun = _Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", _Lighting)
                    _sun.Intensity = 0.95  _sun.Spread = 0.14

                elseif preset == "Night" then
                    local orig = getgenv()._lightingPresetOrig
                    if orig and not orig.SkyRef then
                        local _origSky = _Lighting:FindFirstChildOfClass("Sky")
                        if _origSky then
                            orig.SkyRef = _origSky
                            _origSky.Parent = game:GetService("ReplicatedStorage")
                        end
                    end
                    _Lighting.ClockTime                = 0
                    _Lighting.Brightness               = 3.5
                    _Lighting.ExposureCompensation     = 1.1
                    _Lighting.Ambient                  = Color3.fromRGB(52, 65, 138)
                    _Lighting.OutdoorAmbient           = Color3.fromRGB(42, 55, 125)
                    _Lighting.FogColor                 = Color3.fromRGB(35, 45, 85)
                    _Lighting.FogStart                 = 0
                    _Lighting.FogEnd                   = 4000
                    _Lighting.GeographicLatitude       = 314.8041076660156
                    _Lighting.ShadowSoftness           = 0.2
                    _Lighting.GlobalShadows            = true
                    _Lighting.EnvironmentDiffuseScale  = 0.65
                    _Lighting.EnvironmentSpecularScale = 0.55
                    _Lighting.Technology               = _getSelectedTech()
                    local _atmo = _Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", _Lighting)
                    _atmo.Density = 0.25   _atmo.Offset = 0
                    _atmo.Color   = Color3.fromRGB(12, 20, 72)
                    _atmo.Decay   = Color3.fromRGB(5, 10, 40)
                    _atmo.Glare   = 0      _atmo.Haze = 0
                    local _sun = _Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", _Lighting)
                    _sun.Intensity = 0.88  _sun.Spread = 0.049

                elseif preset == "Sunrising" then
                    _unstashSky()
                    _Lighting.ClockTime                = 6.400000095367432
                    _Lighting.Brightness               = 0
                    _Lighting.ExposureCompensation     = 0
                    _Lighting.Ambient                  = Color3.fromRGB(0, 0, 0)
                    _Lighting.OutdoorAmbient           = Color3.fromRGB(25, 25, 25)
                    _Lighting.FogColor                 = Color3.fromRGB(192, 192, 192)
                    _Lighting.FogStart                 = 0
                    _Lighting.FogEnd                   = 5000
                    _Lighting.GeographicLatitude       = 314.8041076660156
                    _Lighting.ShadowSoftness           = 0.2
                    _Lighting.GlobalShadows            = true
                    _Lighting.EnvironmentDiffuseScale  = 1
                    _Lighting.EnvironmentSpecularScale = 1
                    _Lighting.Technology               = _getSelectedTech()
                    local _atmo = _Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", _Lighting)
                    _atmo.Density = 0.213  _atmo.Offset = 0
                    _atmo.Color   = Color3.fromRGB(2, 2, 2)
                    _atmo.Decay   = Color3.fromRGB(0, 0, 0)
                    _atmo.Glare   = 0      _atmo.Haze = 0
                    local _sun = _Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", _Lighting)
                    _sun.Intensity = 0.72  _sun.Spread = 0.049

                elseif preset == "Auto-Sky" then
                    -- ── Auto-Sky: read player's real local time, lerp ALL properties ─────────
                    _unstashSky()
                    local _td      = os.date("*t")
                    local realClock = _td.hour + _td.min / 60 + _td.sec / 3600

                    -- Find the two surrounding keyframe stages
                    local A, B, frac
                    for i = 1, #_TZ_STAGES - 1 do
                        if realClock >= _TZ_STAGES[i].clock and realClock < _TZ_STAGES[i + 1].clock then
                            A, B  = _TZ_STAGES[i], _TZ_STAGES[i + 1]
                            frac  = (realClock - A.clock) / (B.clock - A.clock)
                            break
                        end
                    end
                    -- Fallback: past last keyframe boundary (should never happen with clock=24 sentinel)
                    if not A then
                        A, B, frac = _TZ_STAGES[#_TZ_STAGES - 1], _TZ_STAGES[#_TZ_STAGES], 1
                    end

                    local function lN(a, b, t) return a + (b - a) * t end

                    -- ── Core Lighting properties ─────────────────────────────────────────────
                    -- ClockTime set to exact real local time → sun & moon physically track the clock
                    _Lighting.ClockTime                = realClock
                    _Lighting.Brightness               = lN(A.Br, B.Br, frac)
                    _Lighting.ExposureCompensation     = lN(A.EC, B.EC, frac)
                    _Lighting.Ambient                  = A.Amb:Lerp(B.Amb, frac)
                    _Lighting.OutdoorAmbient           = A.OA:Lerp(B.OA,   frac)
                    _Lighting.FogColor                 = A.Fog:Lerp(B.Fog,  frac)
                    _Lighting.FogStart                 = 0
                    _Lighting.FogEnd                   = lN(A.FE, B.FE, frac)
                    _Lighting.GeographicLatitude       = 314.8041076660156
                    _Lighting.ShadowSoftness           = lN(A.SR, B.SR, frac)
                    _Lighting.GlobalShadows            = true
                    _Lighting.EnvironmentDiffuseScale  = lN(A.ED, B.ED, frac)
                    _Lighting.EnvironmentSpecularScale = lN(A.ES, B.ES, frac)
                    _Lighting.Technology               = _getSelectedTech()

                    -- ── Atmosphere ───────────────────────────────────────────────────────────
                    local _atmo = _Lighting:FindFirstChildOfClass("Atmosphere")
                        or Instance.new("Atmosphere", _Lighting)
                    _atmo.Density = lN(A.AD, B.AD, frac)
                    _atmo.Offset  = lN(A.AO, B.AO, frac)
                    _atmo.Color   = A.AC:Lerp(B.AC,   frac)
                    _atmo.Decay   = A.Adc:Lerp(B.Adc, frac)
                    _atmo.Glare   = lN(A.AG, B.AG, frac)
                    _atmo.Haze    = lN(A.AH, B.AH, frac)

                    -- ── Sun Rays — dramatic at golden hour, absent at night ───────────────────
                    local _sun = _Lighting:FindFirstChildOfClass("SunRaysEffect")
                        or Instance.new("SunRaysEffect", _Lighting)
                    _sun.Intensity = lN(A.SI, B.SI, frac)
                    _sun.Spread    = lN(A.SS, B.SS, frac)

                    -- ── Bloom — intentionally skipped; the game's own bloom is preserved as-is.
                    -- Creating / driving bloom in Auto-Sky causes the nuclear-sun blowout
                    -- because TSB's sky texture sits near 100% luminance and threshold values
                    -- like 0.55 fire bloom across the entire sky disc.
                    -- If an AutoSkyBloom was inserted by a previous run, remove it now.
                    local _oldBloom = _Lighting:FindFirstChild("AutoSkyBloom")
                    if _oldBloom then pcall(function() _oldBloom:Destroy() end) end

                    -- ── Color Correction — cinematic grade per time of day ────────────────────
                    local _cc = _Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
                    if not _cc then
                        _cc         = Instance.new("ColorCorrectionEffect")
                        _cc.Name    = "AutoSkyCC"
                        _cc.Parent  = _Lighting
                    end
                    _cc.Brightness = lN(A.CCB, B.CCB, frac)
                    _cc.Contrast   = lN(A.CCC, B.CCC, frac)
                    _cc.Saturation = lN(A.CCS, B.CCS, frac)
                    _cc.TintColor  = A.CCT:Lerp(B.CCT, frac)
                    _cc.Enabled    = true

                    -- ── Moon + Sun — both preserved from original game values ─────────────────
                    local _sky = _Lighting:FindFirstChildOfClass("Sky")
                    if _sky then
                        local _orig = getgenv()._lightingPresetOrig
                        if _orig and _orig.MoonAngularSize then
                            _sky.MoonAngularSize = _orig.MoonAngularSize
                        end
                        if _orig and _orig.SunAngularSize then
                            _sky.SunAngularSize = _orig.SunAngularSize
                        end
                    end
                end
            end

            if val == "None" then
                getgenv()._lightingPresetLoop = false
                getgenv()._tzLoopActive       = false
                if getgenv()._lightingPresetConns then
                    for _, c in ipairs(getgenv()._lightingPresetConns) do
                        pcall(function() c:Disconnect() end)
                    end
                    getgenv()._lightingPresetConns = {}
                end
                _restoreOriginals()
                pcall(function() workspace.Terrain.Clouds.Enabled = true end)
            else
                _saveOriginals()
                pcall(function() workspace.Terrain.Clouds.Enabled = false end)
                _applyPreset(val)
                if not getgenv()._lightingPresetLoop then
                    getgenv()._lightingPresetLoop = true
                    getgenv()._lightingPresetConns = {}

                    local _presetApplying = false
                    local function _reApply()
                        if _presetApplying or not getgenv()._lightingPresetLoop then return end
                        local current = Options.LightingPreset.Value
                        if current == "None" then return end
                        _presetApplying = true
                        _applyPreset(current)
                        _presetApplying = false
                    end

                    local _watched = {
                        ClockTime=true, Brightness=true, ExposureCompensation=true,
                        Ambient=true, OutdoorAmbient=true, FogColor=true,
                        FogStart=true, FogEnd=true, GeographicLatitude=true,
                        ShadowSoftness=true, GlobalShadows=true,
                        EnvironmentDiffuseScale=true, EnvironmentSpecularScale=true,
                        Technology=true,
                    }
                    table.insert(getgenv()._lightingPresetConns,
                        _Lighting.Changed:Connect(function(prop)
                            if _watched[prop] then _reApply() end
                        end)
                    )

                    local function _hookAtmo(atmo)
                        if not atmo then return end
                        table.insert(getgenv()._lightingPresetConns,
                            atmo.Changed:Connect(function() _reApply() end)
                        )
                    end
                    _hookAtmo(_Lighting:FindFirstChildOfClass("Atmosphere"))
                    table.insert(getgenv()._lightingPresetConns,
                        _Lighting.ChildAdded:Connect(function(child)
                            if child:IsA("Atmosphere") then _hookAtmo(child) end
                        end)
                    )

                    -- Re-apply instantly on respawn — TSB resets lighting when character loads
                    table.insert(getgenv()._lightingPresetConns,
                        game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
                            task.wait(0)  -- defer one frame so TSB's own respawn lighting fires first, then we stomp it
                            _reApply()
                        end)
                    )
                end

                -- ── Auto-Sky: spawn 1-second update loop (sun/moon track real clock) ──────
                if val == "Auto-Sky" then
                    getgenv()._tzLoopActive = true
                    task.spawn(function()
                        while getgenv()._tzLoopActive
                            and getgenv()._lightingPresetLoop
                            and not Library.Unloaded
                        do
                            if Options.LightingPreset and Options.LightingPreset.Value == "Auto-Sky" then
                                _presetApplying = true
                                pcall(_applyPreset, "Auto-Sky")
                                _presetApplying = false
                            else
                                break
                            end
                            task.wait(1)
                        end
                        getgenv()._tzLoopActive = false
                    end)
                end
            end
        end,
    })
    BoxVisualsWorld:AddDropdown("LightingTechnology", {
        Text    = "Lighting Technology",
        Values  = {"Unified", "Future", "ShadowMap", "Voxel", "Compatibility"},
        Default = "Unified",
        Callback = function(val)
            local _techEnumMap2 = {
                ["Unified"]       = Enum.Technology.Unified,
                ["Future"]        = Enum.Technology.Future,
                ["ShadowMap"]     = Enum.Technology.ShadowMap,
                ["Voxel"]         = Enum.Technology.Voxel,
                ["Compatibility"] = Enum.Technology.Compatibility,
            }
            pcall(function()
                _Lighting.Technology = _techEnumMap2[val] or Enum.Technology.Unified
            end)
        end,
    })
    table.insert(CleanupTasks, function()
        pcall(function() Toggles.NoWalls:SetValue(false) end)
        pcall(function() Toggles.NoTrees:SetValue(false) end)
        pcall(function() Toggles.NoDebris:SetValue(false) end)
        pcall(function() Toggles.NoSmoke:SetValue(false) end)
        pcall(function() Toggles.NoExplosions:SetValue(false) end)
        pcall(function() Toggles.AmbientEnabled:SetValue(false) end)
        pcall(function() Toggles.RainbowAmbient:SetValue(false) end)
        pcall(function() Options.LightingPreset:SetValue("None") end)
        getgenv()._lightingPresetLoop = false
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, c in pairs(_Folder3:GetChildren()) do pcall(function() c.Parent = map end) end
            local trees = map:FindFirstChild("Trees")
            if trees then
                for _, c in pairs(_Folder2:GetChildren()) do pcall(function() c.Parent = trees end) end
            end
        end
    end)
end
local _mapTeleportLocations = {
    ["Above Tunnel"]   = CFrame.new(-301, 594, -322),
    ["Arena"]          = CFrame.new(-130, 440, -373),
    ["Atomic Slash"]   = CFrame.new(-52,  1580, 25250),
    ["Baseplate"]      = CFrame.new(-42,  1855, 25227),
    ["Below Baseplate"]= CFrame.new(-42,  1469, 25227),
    ["Bigger Jail"]    = CFrame.new(290,  440, 465),
    ["Even Bigger Jail"]= CFrame.new(378, 439, 457),
    ["Dark Domain"]    = CFrame.new(-80,  84,  20395),
    ["Death Counter"]  = CFrame.new(-66,  29,  20383),
    ["Jail"]           = CFrame.new(440,  440, -395),
    ["Jail But Smaller"]= CFrame.new(20,  439, -460),
    ["Middle"]         = CFrame.new(150,  441, 32),
    ["Mountain 1"]     = CFrame.new(306,  671,  411),
    ["Mountain 2"]     = CFrame.new(-1,   653, -354),
    ["Mountain Edge"]  = CFrame.new(-297, 594, -336),
    ["Void"]           = CFrame.new(0,    -10000, 0),
}
local _sortedMapKeys = {}
for k in pairs(_mapTeleportLocations) do _sortedMapKeys[#_sortedMapKeys+1] = k end
table.sort(_sortedMapKeys)
local function heartbeatMapTp(cf)
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and root) then return end
    task.spawn(function()
        RunService.RenderStepped:Once(function()
            root.Velocity = Vector3.new()
            RunService.Heartbeat:Wait()
            root.Velocity = Vector3.new()
        end)
        RunService.Heartbeat:Once(function()
            root.CFrame = cf
        end)
    end)
end
local BoxMapLeft  = Tabs.Map:AddLeftGroupbox("Teleports", "map-pin")
local BoxMapRight = Tabs.Map:AddRightGroupbox("Players",  "users")
if trashcanGameIds[currentPlaceId] then
    for _, locName in ipairs(_sortedMapKeys) do
        BoxMapLeft:AddButton({
            Text = locName,
            Func = function()
                heartbeatMapTp(_mapTeleportLocations[locName])
            end,
        })
        -- Insere Weakest Dummy logo após Middle
        if locName == "Middle" then
            BoxMapLeft:AddButton({
                Text = "Weakest Dummy",
                Func = function()
                    local live  = workspace:FindFirstChild("Live")
                    local dummy = live and live:FindFirstChild("Weakest Dummy")
                    local droot = dummy and (dummy:FindFirstChild("HumanoidRootPart") or dummy.PrimaryPart)
                    if droot then heartbeatMapTp(droot.CFrame) end
                end,
            })
        end
    end
else
    BoxMapLeft:AddButton({
        Text = "Void",
        Func = function()
            heartbeatMapTp(_mapTeleportLocations["Void"])
        end,
    })
end
local _mapCurrentTarget = nil
local function getMapPlayerList()
    local tbl = {}
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= lp then tbl[#tbl+1] = _makePlayerLabel(v) end
    end
    return tbl
end
local _mapPlayerDropdown = BoxMapRight:AddDropdown("MapTargetPlayer", {
    Values    = getMapPlayerList(),
    Text      = "Target Player",
    Default   = "",
    Searchable = true,
    AllowNull  = true,
})
local _mapGotoButton = BoxMapRight:AddButton({
    Text = "Goto",
    Func = function()
        if not _mapCurrentTarget then return end
        local tchar = _mapCurrentTarget.Character
        local troot = tchar and tchar:FindFirstChild("HumanoidRootPart")
        if tchar and troot then
            heartbeatMapTp(troot.CFrame)
        end
    end,
})
pcall(function() _mapGotoButton:SetVisible(false) end)
local _mapFlingButton = BoxMapRight:AddButton({
    Text = "Fling",
    Func = function()
        if not _mapCurrentTarget then return end
        if FlingActive then return end
        local target = _mapCurrentTarget
        local _cmdMethod = Options.CmdFlingMethod and Options.CmdFlingMethod.Value or 'Void'
        task.spawn(function()
            FlingActive = true
            if not _userViewActive then setView(target) end
                PhantaFling(target)
            FlingActive = false
            if not _userViewActive then restoreView() end
        end)
    end,
})
pcall(function() _mapFlingButton:SetVisible(false) end)
local _mapDropUpdating = false
local function _updateMapDropdown()
    if _mapDropUpdating then return end
    _mapDropUpdating = true
    task.defer(function()
        pcall(function() _mapPlayerDropdown:SetValues(getMapPlayerList()) end)
        _mapDropUpdating = false
    end)
end
local _mapPlayerAddedConn = Players.PlayerAdded:Connect(_updateMapDropdown)
local _mapPlayerRemovingConn = Players.PlayerRemoving:Connect(function() task.wait() _updateMapDropdown() end)
local _mapLastDropVal = ""
_mapPlayerDropdown:OnChanged(function(name)
    if name ~= "" and name == _mapLastDropVal then
        pcall(function() _mapPlayerDropdown:SetValue("") end)
        _mapLastDropVal = ""
        _mapCurrentTarget = nil
        pcall(function() _mapGotoButton:SetVisible(false) end)
        pcall(function() _mapFlingButton:SetVisible(false) end)
        return
    end
    _mapLastDropVal = name or ""
    if not name or name == "" then
        _mapCurrentTarget = nil
        pcall(function() _mapGotoButton:SetVisible(false) end)
        pcall(function() _mapFlingButton:SetVisible(false) end)
        return
    end
    _mapCurrentTarget = findPlayerByDisplayName(name)
    pcall(function() _mapGotoButton:SetVisible(_mapCurrentTarget ~= nil) end)
    pcall(function() _mapFlingButton:SetVisible(_mapCurrentTarget ~= nil) end)
end)
--// ENI's Expert Hook: "addchromosome" (The Cobalt-Style Way)
getgenv().ChromosomeActive = false

local function _setupChromosomeHook()
    local lp = game:GetService("Players").LocalPlayer
    local function getCommunicateEvent()
        local char = lp.Character or lp.CharacterAdded:Wait()
        return char:WaitForChild("Communicate", 5)
    end

    local Event = getCommunicateEvent()
    if Event and typeof(hookfunction) == "function" then
        local oldFireServer
        oldFireServer = hookfunction(Event.FireServer, function(self, ...)
            local args = {...}
            if getgenv().ChromosomeActive and type(args[1]) == "table" and args[1].Goal == "LeftClickRelease" then
                return nil 
            end
            return oldFireServer(self, ...)
        end)
    end
end
_setupChromosomeHook()

getgenv().addchromosome = function()
    getgenv().ChromosomeActive = true
end

getgenv().removechromosome = function()
    getgenv().ChromosomeActive = false
end
--// End Chromosome Logic

local BoxCredits = Tabs.ChangeLogs:AddLeftGroupbox("ILoveAris", "crown")
BoxCredits:AddLabel("Owner: <font color=\"#9269fa\">aristooey</font>\n\nBad bacon:\n\n<font color=\"#8B4513\">baconbaconed</font>: Sigma\n\n<font color=\"#1A4FBF\">secretxv.</font>: Phantasm Source and Authorization for use.\n\n<font color=\"#FF3333\">i.am.an.agent</font>: Death Counter Quotes (tuff)", true)
getgenv()._disguiseAutoApply = nil
do
    _disguiseLoadApplied      = false
    _disguise_applying        = false
    _disguise_random_cooldown = false
    _disguise_randoms         = {}
    _disguise_cache           = {}
    _disguise_allowed_cache   = {}
    _disguise_last_id         = nil
    _disguise_spawn_conn      = nil
    _disguise_maintain_conn   = nil   -- loop de manutenção periódica
    _disguise_attr_conn       = nil   -- detecta mudança de personagem no TSB
    _disguise_attr_char_conn  = nil   -- reconecta attr watch ao respawnar

    _disguise_presets = {
        289438135, 1707711223, 188732, 2298753899, 9119588309, 5254879171, 8595350470,
        6007609888, 124751865, 5019714978, 5007631110, 9088628683, 7223875998, 2474943274,
        3104949425, 3335871296, 203030608, 2596305840, 201124389, 1981724228, 3731169417,
        205419201, 7422492329, 406436524, 1803380, 9406742928, 1359861204, 3012958642,
        2260118449, 188829949, 2261820401, 8094705681, 9894023718, 6077615334, 2281971469,
        1946404863, 660132420, 1125262365, 3018607207, 144018186, 3577671250, 2017401176,
        3473976672, 9122248242, 1667867130, 9294642379, 5366504429, 8264800124, 283156132,
        1630540916, 4416918097, 344091683, 6538096, 7623744992, 1099702304, 1199088309,
        1369842558, 3624257547, 145740081, 215710487, 2255861564, 7330109199, 524749295,
        272574783, 4100936320, 4863227235, 1132340350, 5210946332, 3331434198, 2618555079,
        4201687597, 147198435, 704071723, 465771760, 254829155, 8069027498, 2646550793,
        366768658, 2885260147,
    }

    -- [ENI] BoxDisguise content removed
end
local BoxVersion = Tabs.ChangeLogs:AddRightGroupbox("Info", "info")
BoxVersion:AddLabel("version: v28/06/2026", true)
BoxVersion:AddDivider()
BoxVersion:AddLabel("To report issues, reach out via Discord.", true)
BoxVersion:AddButton({
    Text = "Copy Discord Server",
    Func = function()
        pcall(function() setclipboard("https://discord.gg/TYdSMmQaF9") end)
        Library:Notify({ Title = bypassText("discord server"), Content = "copied to clipboard!!", Time = 4 })
    end,
})
local BoxSettings      = Tabs.Settings:AddLeftGroupbox("Settings", "sliders-horizontal")
local BoxSettingsRight = Tabs.Settings:AddRightGroupbox("Menu",    "layout-dashboard")
BoxSettings:AddDropdown("NotificationSide", {
    Values  = { "Left", "Right" },
    Default = "Right",
    Text    = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})
BoxSettingsRight:AddLabel("Menu Bind")
    :AddKeyPicker("MenuKeybind", { Default = "LeftAlt", NoUI = true, Text = "Toggle Menu" })
Library.ToggleKeybind = Options.MenuKeybind
BoxSettings:AddDivider()
BoxSettings:AddToggle("KeybindMenuOpen", {
    Text    = "Show Keybinds",
    Default = Library.KeybindFrame.Visible,
    Tooltip = "Shows on-screen keybind buttons. Useful for mobile.",
    Callback = function(val)
        Library.KeybindFrame.Visible = val
    end,
})
task.spawn(function()
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        if Library.KeybindFrame then
            Library.KeybindFrame.Visible = true
        end
        pcall(function() Toggles.KeybindMenuOpen:SetValue(true) end)
        task.wait(8)
        Library:Notify({
            Title   = "ZKAYTSB",
            Content = "Mobile device detected. To hide on-screen keybinds, navigate to Settings and disable \"Show Keybinds\".",
            Time = 12,
        })
    end
end)
do
    local _u60 = {}
    local _u61 = {}
    -- Tabela de info strings identica ao Commands[name][2][1] do Nameless
    local _cmdInfoTable = {
        goto            = 'goto/tp/to {player}',
        tp              = 'goto/tp/to {player}',
        to              = 'goto/tp/to {player}',
        fling           = 'fling/void {player,all,others}',
        void            = 'fling/void {player,all,others}',
        loopfling       = 'loopfling/loopvoid {player,all,others}',
        loopvoid        = 'loopfling/loopvoid {player,all,others}',
        unfling         = 'unfling/unvoid {player,all}',
        unvoid          = 'unfling/unvoid {player,all}',
        unloopfling     = 'unfling/unvoid {player,all}',
        unloopvoid      = 'unfling/unvoid {player,all}',
        view            = 'view/spectate {player}',
        spectate        = 'view/spectate {player}',
        unview          = 'unview/unspectate',
        unspectate      = 'unview/unspectate',
        whitelist       = 'whitelist/addwhitelist {player}',
        addwhitelist    = 'whitelist/addwhitelist {player}',
        unwhitelist     = 'unwhitelist/removewhitelist {player}',
        removewhitelist = 'unwhitelist/removewhitelist {player}',
        rejoin          = 'rejoin/rj',
        rj              = 'rejoin/rj',
        reset           = 'reset',
        fixcam          = 'fixcam',
        bring    = 'bring {player}',
        kill     = 'kill {player}',
        anchor   = 'anchor {player}',
        unanchor = 'unanchor {player}',
        sonic    = 'sonic {player}',
        ban      = 'ban {player}',
        kick     = 'kick {player}',
        unload   = 'unload {player}',
        say      = 'say {player} {message}',
        notify   = 'notify {message}',
        listrevenantusers = 'listrevenantusers',
        listrev  = 'listrevenantusers',
    }
    local function _getPlayer(str)
        if not str then return nil end
        for _, p in pairs(Players:GetPlayers()) do
            if (p.Name:lower():find('^' .. str:lower()) or p.DisplayName:lower():find('^' .. str:lower())) and p ~= lp then
                return p
            end
        end
        return nil
    end
    local function _registerCmd(name, aliases, fn)
        _u60[name] = fn
        if aliases then
            for _, alias in ipairs(aliases) do
                _u61[alias] = fn
            end
        end
    end
    local function _runCmd(name, args)
        local fn = _u60[name] or _u61[name]
        if fn then fn(args) end
    end
    local _skipNext = false
    _registerCmd('goto', {'tp', 'to'}, function(args)
        local target = _getPlayer(args[1])
        if not target and args[1] and args[1]:lower() == 'random' then
            local all = Players:GetPlayers()
            for i = #all, 1, -1 do if all[i] == lp then table.remove(all, i) end end
            target = all[math.random(1, #all)]
        end
        if target then
            local char = target.Character
            local root = char and char:FindFirstChild('HumanoidRootPart')
            if char and root then
                local myChar = lp.Character
                local myRoot = myChar and myChar:FindFirstChild('HumanoidRootPart')
                if myRoot then
                    local function _tpClean(r)
                        if typeof(sethiddenproperty) == "function" then
                            pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", nil) end)
                        end
                        pcall(function() r.AssemblyLinearVelocity  = Vector3.zero end)
                        pcall(function() r.AssemblyAngularVelocity = Vector3.zero end)
                        pcall(function() r.Velocity    = Vector3.zero end)
                        pcall(function() r.RotVelocity = Vector3.zero end)
                    end
                    RunService.Heartbeat:Wait()
                    RunService.Heartbeat:Once(function()
                        _tpClean(myRoot)
                        myRoot.CFrame = root.CFrame
                        _tpClean(myRoot)
                        task.spawn(function()
                            for _ = 1, 4 do
                                RunService.Heartbeat:Wait()
                                local r2 = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                                if r2 then _tpClean(r2) end
                            end
                        end)
                    end)
                end
            end
        end
    end)
    local _viewConn = nil
    _registerCmd('view', {'spectate'}, function(args)
        local target = _getPlayer(args[1])
        if not target and args[1] and args[1]:lower() == 'random' then
            local all = Players:GetPlayers()
            for i = #all, 1, -1 do if all[i] == lp then table.remove(all, i) end end
            target = all[math.random(1, #all)]
        end
        if target then
            Library:Notify({ Title = 'Viewing', Content = target.DisplayName, Time = 3 })
            _userViewActive = true
            setView(target)
            if _viewConn then _viewConn:Disconnect() _viewConn = nil end
            _viewConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
                if leavingPlayer == target then
                    Library:Notify({ Title = 'Command Bar', Content = 'Unviewing..', Time = 3 })
                    if _viewConn then _viewConn:Disconnect() _viewConn = nil end
                    _userViewActive  = false
                    _flingViewActive = false
                    restoreView()
                end
            end)
        end
    end)
    _registerCmd('unview', {'unspectate'}, function(_)
        Library:Notify({ Title = 'Command Bar', Content = 'Unviewing..', Time = 3 })
        _userViewActive = false
        restoreView()
        if _viewConn then _viewConn:Disconnect() _viewConn = nil end
    end)
    _registerCmd('rejoin', {'rj'}, function(_)
        local _ts = game:GetService('TeleportService')
        local isPrivate = game.PrivateServerId ~= '' or #Players:GetPlayers() <= 1
        if isPrivate then
            lp:Kick('Rejoining....')
            task.wait()
            pcall(function() _ts:Teleport(game.PlaceId, lp) end)
        else
            lp:Kick('Rejoining....')
            task.delay(0.1, function()
                pcall(function() _ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp) end)
            end)
        end
    end)
    local function _cmdFlingAdd(target)
        FlingSelectedTargets[getDisplayName(target)] = target
        return true
    end
    local function _cmdFlingAll(others)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lp and (not others or p ~= lp) then
                _cmdFlingAdd(p)
            end
        end
    end
    _registerCmd('fling', {'void'}, function(args)
        if not args[1] then return end
        if FlingActive then return end
        local arg = args[1]:lower()
        local targets = {}
        if arg == 'all' or arg == 'others' then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp then table.insert(targets, p) end
            end
        else
            local t = _getPlayer(args[1])
            if t then table.insert(targets, t) end
        end
        if #targets == 0 then return end
        local _cmdMethod = Options.CmdFlingMethod and Options.CmdFlingMethod.Value or 'Void'
        -- Sequencial: espera cada fling terminar antes de ir pro próximo (igual Phantasm)
        task.spawn(function()
            for _, target in ipairs(targets) do
                if not target or not target.Parent then continue end
                FlingActive = true
                if not _userViewActive then setView(target) end
                    PhantaFling(target)
                FlingActive = false
                if not _userViewActive then restoreView() end
            end
        end)
    end)
    _registerCmd('loopfling', {'loopvoid'}, function(args)
        if not args[1] then return end
        local arg = args[1]:lower()
        if arg == 'all' then
            _loopFlingMode = 'all'
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp and isTargetInMap(p) then
                    FlingSelectedTargets[getDisplayName(p)] = p
                end
            end
        elseif arg == 'others' then
            _loopFlingMode = 'others'
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp and isTargetInMap(p) then
                    FlingSelectedTargets[getDisplayName(p)] = p
                end
            end
        else
            _loopFlingMode = 'single'
            local target = _getPlayer(args[1])
            if not target then return end
            if not isTargetInMap(target) then
                Library:Notify({ Title = 'Fling', Content = target.DisplayName .. ' is not in the map.', Time = 3 })
                return
            end
            FlingSelectedTargets[getDisplayName(target)] = target
        end
        if not FlingActive then startFling() end
    end)
    _registerCmd('unfling', {'unvoid', 'unloopfling', 'unloopvoid'}, function(args)
        if not args[1] then
            _loopFlingMode = nil
            FlingSelectedTargets = {}
            stopFling()
            return
        end
        local arg = args[1]:lower()
        if arg == 'all' or arg == 'others' then
            _loopFlingMode = nil
            FlingSelectedTargets = {}
            stopFling()
        else
            local target = _getPlayer(args[1])
            if target then
                FlingSelectedTargets[getDisplayName(target)] = nil
            end
            if not next(FlingSelectedTargets) then
                _loopFlingMode = nil
                stopFling()
            end
        end
    end)
    _registerCmd('reset', nil, function(_)
        pcall(function() replicatesignal(game.Players.LocalPlayer.Kill) end)
    end)
    _registerCmd('fixcam', nil, function(_)
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass('Humanoid')
        if char and hum and workspace.CurrentCamera then
            local cf = workspace.CurrentCamera.CFrame
            workspace.CurrentCamera:Destroy()
            local cam = Instance.new('Camera', workspace)
            cam.CameraType    = Enum.CameraType.Custom
            cam.CameraSubject = hum
            cam.CFrame        = cf
            lp.CameraMode     = Enum.CameraMode.Classic
        end
    end)
    RevenantWhitelist = RevenantWhitelist or {}
    _registerCmd('whitelist', {'addwhitelist'}, function(args)
        local target = _getPlayer(args[1])
        if not target then return end
        if table.find(RevenantWhitelist, target) then
            Library:Notify({Title = 'Whitelist', Content = target.DisplayName .. ' is already whitelisted.', Time = 3})
        else
            table.insert(RevenantWhitelist, target)
            Library:Notify({Title = 'Whitelist', Content = 'Whitelisted ' .. target.DisplayName, Time = 3})
        end
    end)
    _registerCmd('unwhitelist', {'removewhitelist'}, function(args)
        local target = _getPlayer(args[1])
        if not target then return end
        local idx = table.find(RevenantWhitelist, target)
        if idx then
            table.remove(RevenantWhitelist, idx)
            Library:Notify({Title = 'Whitelist', Content = 'Unwhitelisted ' .. target.DisplayName, Time = 3})
        end
    end)

    --// ============================================
    --// Revenant Remote Command System (RCS)
    --// ============================================
    _RCS_Known      = {}  -- exposto fora do do-block para a command bar usar
    _RCS_MyRank  = 99  -- exposto fora do do-block
    do
        _RCS_Prefix  = "RCS_"
        _RCS_Channel = game:GetService("TextChatService").TextChannels.RBXGeneral

        --// Rank map: HWID → número (menor = mais alto na hierarquia)
        _RCS_RankMap = {
            ["e504423d3a623e337aec1a1663fb3967e058d34652e3eee6be4f83b3fd0a0ced4adf3636406de620c5ad37477e00722256690a29a0ce395c2f7bfabe87171c05"]                                                             = 1, -- miiki
            ["1852b2317e29de132caeb5354c4bbaa51fd4a578522bf2e3d503705dea579976"]                                                             = 2, -- baconbaconed
            ["39646632333336636166333762356366366431353637633236613135303866386132626530646661623437353834396264343961373136623461613264316139"] = 2, -- baconbaconed
            ["6fe0ac97499db333c1ea9fc37ba1dac81576337f38d2df0513c023f454b1190f"]                                                             = 2, -- baconbaconed
            ["1aaa5c72e4e1a297a9384d32b08219893ee53e8efb03f41fd6b960839caafc3b"]                                                             = 3, -- waizer
            ["56ad809fb936b984c73dd2adcfcb18985724c15687ad3d775757f9086bf9a6897ba4d6029638901b3bfa364ff10393363a0f74be82c7a764c904eff42e19036b"] = 3, -- las exploitas
            ["528b9bf0fc8e568a6b4efd0dc09f513b92d149dcdbf4f4a50bc26289de7ff2d8"]                                                             = 3, -- ciloo
            ["c2190ab4e801321703d362e46978608b37809ffb54e9ab1c424198a1d00b11ca"]                                                             = 3, -- Sascha (Madium)
            ["6fa87fd8e9087b4b5c052b0e308e2e63693384062af02ee76325eaee8a6c9df4"]                                                             = 3, -- Sascha
            ["6e3f119b80ae25cbf0c359572e2f632ef85ccba8a6df9ad81d265446cdffed6d"]                                                             = 3, -- Sascha (Real)
            ["910098334a13e9d20e6c7d5e6b54cc724383049072d6034a492192eeeedb1137"]                                                             = 3, -- Crystal   
            ["75e3b7c9df66f9f5ab20363d383b4c5e415a31f24644199e3b1759a04f778ba8"]                                                             = 3, -- my femboy but on yub-x
            ["95b728792a9e44f180d7943ada2f39b86d15f0bf9aca83448e3385afbdf095d5"]                                                             = 3 -- drlow
}
        _RCS_RankNames = { [1] = "Owner", [2] = "Co-Owner", [3] = "Trusted" }

        _RCS_GetRank = function(hwid) return _RCS_RankMap[hwid:lower()] or 99 end

        _RCS_MyHWID = ""
        pcall(function() if gethwid then _RCS_MyHWID = gethwid() end end)
        _RCS_MyRank = _RCS_GetRank(_RCS_MyHWID)

        -- token único por execução — muda se o usuário re-executar
        _RCS_SessionToken = tostring(math.random(100000, 999999))

        --// Packets
        _RCS_Send = function(packetName, extra)
            -- formato: RCS_{packetName}|{myHWID}|{sessionToken}|{extra}
            local data = _RCS_Prefix .. packetName .. "|" .. _RCS_MyHWID .. "|" .. _RCS_SessionToken .. "|" .. (extra or "")
            pcall(function() _RCS_Channel:SendAsync("", data) end)
        end

        _RCS_AnchorConn = nil

        _RCS_ExecuteOnSelf = function(cmd, extra)
            local char = lp.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")

            if cmd == "bring" then
                if root and extra ~= "" then
                    local ax, ay, az, bx, by, bz = extra:match(
                        "^(%-?[%d%.]+),(%-?[%d%.]+),(%-?[%d%.]+),(%-?[%d%.]+),(%-?[%d%.]+),(%-?[%d%.]+)$")
                    if ax then
                        local aheadPos  = Vector3.new(tonumber(ax), tonumber(ay), tonumber(az))
                        local bringerPos = Vector3.new(tonumber(bx), tonumber(by), tonumber(bz))
                        -- place target 3 studs ahead of bringer, looking back at them
                        root.CFrame = CFrame.lookAt(aheadPos, bringerPos)
                    else
                        -- fallback: old 3-coord packet
                        local x, y, z = extra:match("^(%-?[%d%.]+),(%-?[%d%.]+),(%-?[%d%.]+)$")
                        if x then root.CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z)) end
                    end
                end
            elseif cmd == "kill" then
                if typeof(replicatesignal) == "function" then
                    pcall(function() replicatesignal(lp.Kill) end)
                elseif hum then
                    hum.Health = 0
                end
            elseif cmd == "anchor" then
                if _RCS_AnchorConn then _RCS_AnchorConn:Disconnect() _RCS_AnchorConn = nil end
                local _anchorCF = root and root.CFrame or CFrame.new(0, 5, 0)
                _RCS_AnchorConn = RunService.Heartbeat:Connect(function()
                    local c = lp.Character
                    local r = c and c:FindFirstChild("HumanoidRootPart")
                    if r then
                        r.CFrame                  = _anchorCF
                        r.AssemblyLinearVelocity   = Vector3.zero
                        r.AssemblyAngularVelocity  = Vector3.zero
                        pcall(function() r.Velocity    = Vector3.zero end)
                        pcall(function() r.RotVelocity = Vector3.zero end)
                    end
                end)
            elseif cmd == "unanchor" then
                if _RCS_AnchorConn then _RCS_AnchorConn:Disconnect() _RCS_AnchorConn = nil end
            elseif cmd == "sonic" then
                if not getgenv().RevenantSonicExecuted then
                    getgenv().RevenantSonicExecuted = true
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/razecomsono/Revenant/refs/heads/main/Sonic.lua"))()
                    end)
                end
                -- Descarrega o Revenant inteiro do alvo
                pcall(function()
                    if getgenv().RevenantCleanup then
                        getgenv().RevenantCleanup()
                    else
                        if Library then Library:Unload() end
                    end
                    getgenv().RevenantLoaded  = false
                    getgenv().RevenantCleanup = nil
                end)
            elseif cmd == "ban" then
                if char then
                    pcall(function() shared.ismobile = false end)
                    pcall(function() shared.isconsole = true end)
                    pcall(function() char:SetAttribute("mobile", false) end)
                    pcall(function() char:SetAttribute("console", true) end)

                    local comm = char:FindFirstChild("Communicate") or char:WaitForChild("Communicate", 1)
                    if comm then
                        pcall(function() comm:FireServer({ Goal = "Platform", mobile = false }) end)
                        pcall(function() comm:FireServer({ Goal = "Platform", console = true }) end)
                        pcall(function() comm:FireServer({ Goal = " Platform ", mobile = false }) end)
                    end
                end
            elseif cmd == "kick" then
                lp:Kick(extra ~= "" and extra or "[RCS] You were kicked.")
            elseif cmd == "unload" then
                pcall(function()
                    if getgenv().RevenantCleanup then getgenv().RevenantCleanup()
                    else Library:Unload() end
                end)
            elseif cmd == "say" then
                pcall(function()
                    local ch = game:GetService("TextChatService").TextChannels:FindFirstChild("RBXGeneral")
                    if ch then ch:SendAsync(extra) end
                end)
            elseif cmd == "notify" then
                Library:Notify({ Title = bypassText("..."), Content = extra, Time = 6 })
            elseif cmd == "jumpscare" then
                task.spawn(function()
                    local Holder = game:GetService("CoreGui")
                    local Sound1 = Instance.new("Sound", Holder)
                    Sound1.SoundId = "rbxassetid://5332146653"
                    Sound1.Volume = 10
                    Sound1.PlaybackSpeed = 3
                    Sound1:Play()
                    Sound1.Ended:Wait()
                    Sound1:Destroy()
                    local ScreenGui = Instance.new("ScreenGui", Holder)
                    ScreenGui.IgnoreGuiInset = true
                    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                    local Image = Instance.new("ImageLabel", ScreenGui)
                    Image.BackgroundTransparency = 1
                    Image.BorderSizePixel = 0
                    Image.Position = UDim2.new(0, 0, 0, 0)
                    Image.Size = UDim2.new(1, 0, 1, 0)
                    Image.Image = "rbxassetid://17006455825"
                    local Sound2 = Instance.new("Sound", Holder)
                    Sound2.SoundId = "rbxassetid://1332644289"
                    Sound2.Volume = 10
                    Sound2:Play()
                    Sound2.Ended:Wait()
                    ScreenGui:Destroy()
                    Sound2:Destroy()
                end)
            elseif cmd == "bemystand" then
                if extra ~= "" then
                    local target
                    for _, p in pairs(Players:GetPlayers()) do
                        if p.Name == extra or p.DisplayName == extra then
                            target = p
                            break
                        end
                    end
                    if target and getgenv()._standActivateFn then
                        getgenv()._standActivateFn(target)
                        pcall(function() Options.StandTargetDropdown:SetDisabled(true) end)
                        pcall(function() Options.StandMethodDropdown:SetDisabled(true) end)
                    end
                end
            elseif cmd == "stopbeingmystand" then
                if getgenv()._standDeactivateFn then getgenv()._standDeactivateFn() end
                pcall(function() Options.StandTargetDropdown:SetDisabled(false) end)
                pcall(function() Options.StandMethodDropdown:SetDisabled(false) end)
            end
        end

        _RCS_SendCmd = function(cmd, targetPlayer)
            if _RCS_MyRank == 99 then return end
            local extra = tostring(targetPlayer.UserId)
            if cmd == "bring" then
                local r = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    -- 3 studs ahead of bringer's look direction
                    local ahead = r.CFrame * CFrame.new(0, 0, -3)
                    extra = extra .. "," .. string.format("%.3f,%.3f,%.3f,%.3f,%.3f,%.3f",
                        ahead.X, ahead.Y, ahead.Z,
                        r.Position.X, r.Position.Y, r.Position.Z)
                end
            end
            _RCS_Send("CMD:" .. cmd, extra)
        end

        --// Listener central
        _RCS_MsgConn = game:GetService("TextChatService").MessageReceived:Connect(function(message)
            local data   = message.Metadata
            local source = message.TextSource
            if not data or not source then return end
            if source.UserId == lp.UserId then return end
            if data:sub(1, #_RCS_Prefix) ~= _RCS_Prefix then return end

            local sender = Players:GetPlayerByUserId(source.UserId)
            if not sender then return end

            -- parse: RCS_{packetName}|{hwid}|{extra}
            local body       = data:sub(#_RCS_Prefix + 1)
            local packetName, hwid, token, extra = body:match("^([^|]+)|([^|]*)|([^|]*)|?(.*)$")
            if not packetName or not hwid then return end

            local senderRank = _RCS_GetRank(hwid)

            --// DISCON — remove sender from known list when they unload
            if packetName == "discon" then
                _RCS_Known[source.UserId] = nil
                return
            end

            --// INIT — registra o sender e responde uma vez pra ele te registrar também
            if packetName == "init i support hooks" or packetName == "init i dont support hooks" then
                local supportsHooks = (packetName == "init i support hooks")
                local known    = _RCS_Known[source.UserId]
                -- isNew = true também quando o token mudou (re-execução do sender)
                -- sem isso, se o owner re-executar depois do guest, o guest já tem o
                -- owner registrado com o token antigo e não responde — o owner nunca
                -- consegue registrar o guest e os comandos param de funcionar.
                local isNew    = not known or (known.token ~= token)
                _RCS_Known[source.UserId] = { player = sender, hwid = hwid, rank = senderRank, token = token, supportsHooks = supportsHooks }

                -- Se é novo (ou re-executou), manda Init de volta pra ele poder te registrar
                -- (evita loop: na próxima vez que ele receber, o token já vai bater)
                if isNew then
                    if typeof(hookfunction) == "function" then
                        _RCS_Send("init i support hooks")
                    else
                        _RCS_Send("init i dont support hooks")
                    end
                    -- Guest (99) nunca recebe notificação de ninguém
                    if _RCS_MyRank <= 3 then
                        Library:Notify({
                            Title = bypassText("Command bar"),
                            Content = "Trusted connected with " .. sender.DisplayName .. " (@" .. sender.Name .. "), extra commands are available, if you are higher than him.",
                            Time = 6
                        })
                    end
                end
                return
            end

            --// CMD — executa se sou o target e sender tem rank superior
            if packetName:sub(1, 4) == "CMD:" then
                local cmd = packetName:sub(5)
                -- extra = "{targetUserId},{posX},{posY},{posZ}" (pos só pra bring)
                local parts = extra:split(",")
                local targetId = parts[1]
                if tostring(lp.UserId) ~= targetId then return end
                if senderRank == 99 then return end
                if cmd == "ban" and senderRank ~= 1 then
                    _RCS_Send("CMD:notify", tostring(source.UserId) .. ",No permissions.")
                    return
                end
                if senderRank >= _RCS_MyRank then
                    -- avisa o sender que não tem permissão
                    _RCS_Send("CMD:notify", tostring(source.UserId) .. ",No permissions.")
                    return
                end

                local cmdExtra = ""
                if cmd == "bring" and #parts >= 7 then
                    cmdExtra = parts[2] .. "," .. parts[3] .. "," .. parts[4] .. "," .. parts[5] .. "," .. parts[6] .. "," .. parts[7]
                elseif cmd == "kick" and #parts >= 2 then
                    cmdExtra = table.concat(parts, ",", 2)
                elseif cmd == "say" and #parts >= 2 then
                    cmdExtra = table.concat(parts, ",", 2)
                elseif cmd == "notify" and #parts >= 2 then
                    cmdExtra = table.concat(parts, ",", 2)
                elseif cmd == "bemystand" then
                    cmdExtra = sender.Name
                end
                _RCS_ExecuteOnSelf(cmd, cmdExtra)
            end
        end)

        --// Comandos na command bar
        -- Helper: retorna lista de targets RCS (suporta "all")
        getgenv()._tsb_getRevTargets = function(targetName)
            local tl = targetName:lower()
            if tl == "all" or tl == "others" then
                -- "others" = every known RCS user except self (self is never in _RCS_Known anyway)
                local list = {}
                for _, data in pairs(_RCS_Known) do
                    if data.player and data.player.Parent then
                        table.insert(list, data.player)
                    end
                end
                return list
            end
            for _, data in pairs(_RCS_Known) do
                local p = data.player
                if p and p.Parent then
                    if p.Name:lower():sub(1, #tl) == tl or p.DisplayName:lower():sub(1, #tl) == tl then
                        return { p }
                    end
                end
            end
            return nil
        end

        -- _RCS_Cmd: registra um extra command de forma padronizada.
        -- aliases    : lista de nomes alternativos (ou nil)
        -- extraBuilder(target, args): funcao opcional que monta a string `extra` do pacote.
        --   Se omitida, usa _RCS_SendCmd (so manda o UserId, igual os comandos simples).
        getgenv()._tsb_RCS_Cmd = function(cmdName, aliases, extraBuilder)
            _registerCmd(cmdName, aliases, function(args)
                local targets = getgenv()._tsb_getRevTargets(args[1] or "")
                if not targets or #targets == 0 then
                    Library:Notify({ Title = bypassText("Command bar"), Content = "Theres no revenant user here.", Time = 3 })
                    return
                end
                for _, target in ipairs(targets) do
                    if extraBuilder then
                        local extra = extraBuilder(target, args)
                        if extra ~= nil then
                            _RCS_Send("CMD:" .. cmdName, extra)
                        end
                    else
                        _RCS_SendCmd(cmdName, target)
                    end
                end
            end)
        end

        if _RCS_MyRank <= 3 then
            getgenv()._tsb_RCS_Cmd("bring")
            getgenv()._tsb_RCS_Cmd("kill")
            getgenv()._tsb_RCS_Cmd("anchor")
            getgenv()._tsb_RCS_Cmd("unanchor")
            getgenv()._tsb_RCS_Cmd("sonic")
            getgenv()._tsb_RCS_Cmd("unload")
            if _RCS_MyRank == 1 then
                getgenv()._tsb_RCS_Cmd("ban")
            end
            getgenv()._tsb_RCS_Cmd("addchromosome", nil, function(target, args)
                local targetData = _RCS_Known[target.UserId]
                if not targetData or not targetData.supportsHooks then
                    Library:Notify({ Title = bypassText("Command bar"), Content = "this bum have a bad executor, cant add a chromosome to them", Time = 4 })
                    return nil
                end
                return tostring(target.UserId) .. "," .. tostring(lp.UserId)
            end)
            getgenv()._tsb_RCS_Cmd("removechromosome")
            getgenv()._tsb_RCS_Cmd("kick", nil, function(target, args)
                local reason = #args > 1 and table.concat(args, " ", 2) or ""
                return tostring(target.UserId) .. (reason ~= "" and ("," .. reason) or "")
            end)
            getgenv()._tsb_RCS_Cmd("say", nil, function(target, args)
                local message = #args > 1 and table.concat(args, " ", 2) or ""
                return tostring(target.UserId) .. "," .. message
            end)
            getgenv()._tsb_RCS_Cmd("notify", nil, function(target, args)
                local message = #args > 1 and table.concat(args, " ", 2) or ""
                return tostring(target.UserId) .. "," .. message
            end)
            getgenv()._tsb_RCS_Cmd("jumpscare")
            getgenv()._tsb_RCS_Cmd("bemystand")
            getgenv()._tsb_RCS_Cmd("stopbeingmystand")
        end

        Players.PlayerRemoving:Connect(function(p) _RCS_Known[p.UserId] = nil end)

        -- listrev: mostra quais players no servidor usam Revenant
        -- NOTE: inlined directly to avoid consuming a local register (200-local limit fix)
        _registerCmd("listrevenantusers", {"listrev"}, function(_)
            local names = {}
            for userId, data in pairs(_RCS_Known) do
                local p = data.player
                if p and p.Parent then
                    table.insert(names, p.DisplayName .. " (@" .. p.Name .. ")")
                end
            end
            if #names == 0 then
                Library:Notify({ Title = bypassText("Command bar"), Content = "No Revenant users in this server.", Time = 4 })
            else
                Library:Notify({ Title = bypassText("Command bar"), Content = table.concat(names, ", "), Time = 6 })
            end
        end)

        table.insert(CleanupTasks, function()
            if _RCS_AnchorConn then _RCS_AnchorConn:Disconnect() _RCS_AnchorConn = nil end
            if _RCS_MsgConn    then _RCS_MsgConn:Disconnect()    _RCS_MsgConn    = nil end
        end)

        --// Manda Init ao carregar
        task.delay(2, function()
            if typeof(hookfunction) == "function" then
                _RCS_Send("init i support hooks")
            else
                _RCS_Send("init i dont support hooks")
            end
        end)


    end
    --// ============================================

    local BoxCmdSettings = Tabs.Commands:AddLeftGroupbox('Settings',  "settings-2")
    local BoxCmdList     = Tabs.Commands:AddRightGroupbox('Commands', "terminal")
    BoxFling = BoxCmdSettings
    BoxCmdSettings:AddToggle('CommandBar', {
        Text    = 'Command Bar',
        Default = false,
    }):AddKeyPicker('CommandBind', {
        SyncToggleState = false,
        Mode    = 'Toggle',
        Default = 'Semicolon',
        Text    = 'Command Bar Keybind',
        NoUI    = true,
    })
    BoxCmdSettings:AddToggle('UseCommandsinChat', {
        Text    = 'Use Commands in Chat',
        Default = false,
    })
    BoxCmdSettings:AddToggle('SendCommandInChat', {
        Text    = 'Send Command In Chat',
        Default = false,
    })
    BoxCmdSettings:AddDivider()
    BoxCmdSettings:AddDropdown('CmdFlingMethod', {
        Text   = 'Fling Type',
        Values = { 'Anti-Fling', 'Normal', 'Void' },
        Default = 3,
        Multi   = false,
    })
    BoxCmdSettings:AddSlider('FlingSpeed', {
        Text     = 'Fling Speed',
        Default  = 15,
        Min      = 15,
        Max      = 90,
        Rounding = 0,
        Compact  = true,
    })
    BoxCmdSettings:AddSlider('FlingTimeout', {
        Text     = 'Fling Timeout',
        Default  = 3,
        Min      = 1,
        Max      = 5,
        Rounding = 0,
        Compact  = true,
    })
    _buildFlingUI()

    -- ── Command Bar runner (visible only when Command Bar toggle is on) ────────
    local _cmdBaseList = {
        'goto', 'fling', 'loopfling', 'unfling', 'view', 'unview',
        'whitelist', 'unwhitelist', 'rejoin', 'reset', 'fixcam',
    }
    local _cmdTrustedList = {
        'bring', 'kill', 'anchor', 'unanchor', 'sonic', 'kick', 'unload',
        'addchromosome', 'removechromosome', 'bemystand', 'stopbeingmystand',
        'say', 'notify', 'jumpscare', 'listrevenantusers',
    }
    local _cmdOwnerList = {
        'ban',
    }
    local _cmdNoPlayer = {
        unview = true, unspectate = true, rejoin = true, rj = true,
        reset = true, fixcam = true, listrevenantusers = true, listrev = true,
    }
    local _cmdNeedsMessage = { say = true, notify = true, kick = true }

    local function _cmdBuildDropdownValues()
        local method = Options.CmdBarMethod and Options.CmdBarMethod.Value or 'Default'
        local vals = {}
        if method == 'Default' then
            -- Strictly show ONLY the base commands, sugar.
            for _, c in ipairs(_cmdBaseList) do vals[#vals + 1] = c end
        else
            -- Strictly show ONLY the trusted commands for our elite circle.
            if _RCS_MyRank <= 3 then
                for _, c in ipairs(_cmdTrustedList) do vals[#vals + 1] = c end
                if _RCS_MyRank == 1 then
                    for _, c in ipairs(_cmdOwnerList) do vals[#vals + 1] = c end
                end
            end
        end
        return vals
    end

    local function _cmdBuildPlayerValues()
        local method = Options.CmdBarMethod and Options.CmdBarMethod.Value or 'Default'
        local vals = { '[All]' }
        if method == 'Default' then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp then vals[#vals + 1] = _makePlayerLabel(p) end
            end
        else
            for userId, data in pairs(_RCS_Known) do
                local p = data.player
                if p and p.Parent and p ~= lp then
                    vals[#vals + 1] = _makePlayerLabel(p)
                end
            end
        end
        return vals
    end

    local BoxCmdRunner = BoxCmdSettings:AddDependencyGroupbox()

    BoxCmdRunner:AddDropdown('CmdBarMethod', {
        Text    = 'Method',
        Values  = _RCS_MyRank <= 3 and { 'Default', 'Trusted' } or { 'Default' },
        Default = 'Default',
        Callback = function()
            pcall(function() Options.CmdBarCommand:SetValues(_cmdBuildDropdownValues()) end)
            pcall(function() Options.CmdBarPlayer:SetValues(_cmdBuildPlayerValues()) end)
        end,
    })

    BoxCmdRunner:AddDropdown('CmdBarCommand', {
        Text       = 'Command',
        Values     = _cmdBuildDropdownValues(),
        Default    = 1,
        Searchable = true,
        Callback   = function(val)
            local show = _cmdNeedsMessage[val and val:lower() or ""] or false
            pcall(function() Options.CmdBarMessage:SetVisible(show) end)
        end,
    })

    BoxCmdRunner:AddInput('CmdBarMessage', {
        Text        = 'Message',
        Default     = '',
        Placeholder = 'Put the message here',
        Visible     = false,
    })

    local _cmdPlayerDropdown = BoxCmdRunner:AddDropdown('CmdBarPlayer', {
        Text       = 'Player',
        Values     = _cmdBuildPlayerValues(),
        Default    = '',
        Searchable = true,
        AllowNull  = true,
    })

    -- Initial refresh to ensure everything is synced up, sugar!
    task.spawn(function()
        task.wait(0.5)
        pcall(function() Options.CmdBarCommand:SetValues(_cmdBuildDropdownValues()) end)
        pcall(function() Options.CmdBarPlayer:SetValues(_cmdBuildPlayerValues()) end)
    end)

    BoxCmdRunner:AddButton({
        Text = 'Run Command',
        Func = function()
            local cmd = Options.CmdBarCommand and Options.CmdBarCommand.Value
            if not cmd or cmd == '' then return end
            cmd = cmd:lower()

            local args = {}
            if not _cmdNoPlayer[cmd] then
                local playerVal = tostring(Options.CmdBarPlayer and Options.CmdBarPlayer.Value or '')
                if playerVal == '' then
                    Library:Notify({ Title = bypassText('Command Bar'), Content = 'Pick a player or [All].', Time = 3 })
                    return
                end
                
                if playerVal == '[All]' then
                    args[1] = 'all'
                else
                    local target = _findPlayerByLabel(playerVal)
                    if not target then
                        Library:Notify({ Title = bypassText('Command Bar'), Content = 'Invalid player.', Time = 3 })
                        return
                    end
                    args[1] = target.Name
                end
            end

            if _cmdNeedsMessage[cmd] then
                local msg = Options.CmdBarMessage and Options.CmdBarMessage.Value or ''
                if cmd == 'kick' and (msg == '' or msg == nil) then
                    msg = 'Exploiting'
                end
                if (cmd == 'say' or cmd == 'notify') and (msg == '' or msg == nil) then
                    Library:Notify({ Title = bypassText('Command Bar'), Content = 'Type a message first.', Time = 3 })
                    return
                end
                args[2] = msg
            end

            if _u60[cmd] or _u61[cmd] then
                task.spawn(_runCmd, cmd, args)
            else
                Library:Notify({ Title = bypassText('Command Bar'), Content = 'Unknown command.', Time = 3 })
            end
        end,
    })

    BoxCmdRunner:SetupDependencies({
        { Toggles.CommandBar, true },
    })

    Players.PlayerAdded:Connect(function()
        pcall(function() _cmdPlayerDropdown:SetValues(_cmdBuildPlayerValues()) end)
    end)
    Players.PlayerRemoving:Connect(function()
        pcall(function() _cmdPlayerDropdown:SetValues(_cmdBuildPlayerValues()) end)
    end)
    -- ── END Command Bar runner ────────────────────────────────────────────────

    BoxCmdList:AddLabel(';goto/tp/to {player}\r\n;fling/void {player,all,others}\r\n;loopfling/loopvoid {player,all,others}\r\n;unfling/unvoid {player,all}\r\n;view/spectate {player}\r\n;unview/unspectate\r\n;whitelist/addwhitelist {player}\r\n;unwhitelist/removewhitelist {player}\r\n;rejoin/rj\r\n;reset\r\n;fixcam', true)
    if _RCS_MyRank <= 3 then
        BoxCmdList:AddDivider()
        local extraCommandsText = 'Extra commands (if the target is a Revenant user):\r\n;bring {player,all}\r\n;kill {player,all}\r\n;anchor/unanchor {player,all}\r\n;sonic {player,all}\r\n;kick {player,all}\r\n;unload {player,all}\r\n;addchromosome/removechromosome {player,all}\r\n;bemystand/stopbeingmystand {player,all}\r\n;say {player,all} {message}\r\n;notify {player,all} {message}\r\n;jumpscare {player,all,others}\r\n;listrevenant/listrev'
        if _RCS_MyRank == 1 then
            extraCommandsText = extraCommandsText .. '\r\n;ban {player,all}'
        end
        BoxCmdList:AddLabel(extraCommandsText, true)
    end
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        BoxCmdList:AddDivider()
        BoxCmdList:AddLabel('if youre a mobile user and want to use commands turn on "use commands in chat" and type ";(command that you wish)" so you can use the command bar', true)
    end
    task.spawn(function()
        local _guiParent = nil
        if get_hidden_gui or gethui then
            _guiParent = (get_hidden_gui or gethui)()
        elseif game:GetService('CoreGui'):FindFirstChild('RobloxGui') then
            _guiParent = game:GetService('CoreGui').RobloxGui
        else
            _guiParent = game:GetService('CoreGui')
        end
        local _ScreenGui2 = Instance.new('ScreenGui')
        _ScreenGui2.Enabled        = false
        _ScreenGui2.ResetOnSpawn   = false
        _ScreenGui2.DisplayOrder   = 100000
        pcall(function() _ScreenGui2.Parent = _guiParent end)
        local _Frame = Instance.new('Frame', _ScreenGui2)
        _Frame.BackgroundColor3 = Color3.new(0, 0, 0)
        _Frame.BorderColor3     = Color3.new(0, 0, 0)
        _Frame.Size             = UDim2.new(1, -4, 0, 20)
        _Frame.ZIndex           = 5
        local _Frame2 = Instance.new('Frame', _Frame)
        _Frame2.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        _Frame2.BorderColor3     = Color3.fromRGB(50, 50, 50)
        _Frame2.BorderMode       = Enum.BorderMode.Inset
        _Frame2.Size             = UDim2.new(1, 0, 1, 0)
        _Frame2.ZIndex           = 6
        local _grad = Instance.new('UIGradient', _Frame2)
        _grad.Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
        })
        _grad.Rotation = 90
        local _Frame3 = Instance.new('Frame', _Frame2)
        _Frame3.BackgroundTransparency = 1
        _Frame3.ClipsDescendants       = true
        _Frame3.Position               = UDim2.new(0, 5, 0, 0)
        _Frame3.Size                   = UDim2.new(1, -5, 1, 0)
        _Frame3.ZIndex                 = 7
        local _TextLabel = Instance.new('TextLabel', _Frame3)
        _TextLabel.BackgroundTransparency = 1
        _TextLabel.Position               = UDim2.fromOffset(0, 0)
        _TextLabel.Size                   = UDim2.fromScale(5, 1)
        _TextLabel.Font                   = Enum.Font.Code
        _TextLabel.Text                   = ''
        _TextLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
        _TextLabel.TextTransparency       = 0.5
        _TextLabel.TextSize               = 14
        _TextLabel.TextStrokeTransparency = 0.7
        _TextLabel.TextXAlignment         = Enum.TextXAlignment.Left
        _TextLabel.ZIndex                 = 7
        local _TextBox = Instance.new('TextBox', _Frame3)
        _TextBox.BackgroundTransparency = 1
        _TextBox.Position               = UDim2.fromOffset(0, 0)
        _TextBox.Size                   = UDim2.fromScale(5, 1)
        _TextBox.Font                   = Enum.Font.Code
        _TextBox.PlaceholderColor3      = Color3.fromRGB(190, 190, 190)
        _TextBox.PlaceholderText        = ''
        _TextBox.Text                   = ''
        _TextBox.TextColor3             = Color3.fromRGB(255, 255, 255)
        _TextBox.TextSize               = 14
        _TextBox.TextStrokeTransparency = 0
        _TextBox.TextXAlignment         = Enum.TextXAlignment.Left
        _TextBox.ClearTextOnFocus       = true
        _TextBox.ZIndex                 = 8
        _TextBox:GetPropertyChangedSignal('Text'):Connect(function()
            if _TextBox.Text:match('^%s*$') then
                _TextLabel.Text = ''
            else
                local parts = _TextBox.Text:split(' ')
                local word  = parts[1] and parts[1]:lower() or ''
                local arg   = parts[2]
                _TextLabel.Text = ''
                -- helper: só sugere players que usam Revenant
                local function _getRevenantPlayer(str)
                    if not str then return nil end
                    for userId, data in pairs(_RCS_Known) do
                        local p = data.player
                        if p and p.Parent and p ~= lp then
                            local tl = str:lower()
                            if p.Name:lower():find('^' .. tl) or p.DisplayName:lower():find('^' .. tl) then
                                return p
                            end
                        end
                    end
                    return nil
                end
                -- comandos que só funcionam com usuários Revenant
                local _revenantOnlyCmds = {
                    bring=true, kill=true, anchor=true, unanchor=true,
                    sonic=true, kick=true, unload=true, say=true, notify=true,
                    listrevenantusers=true, listrev=true,
                }
                -- keywords que não devem triggerar autocomplete de player
                local _specialArgs = { all=true, others=true, random=true }
                if word ~= '' then
                    for cmd, _ in pairs(_u60) do
                        if cmd:find('^' .. word) then
                            local p = nil
                            if arg and not _specialArgs[arg:lower()] then
                                if _revenantOnlyCmds[cmd] then
                                    p = _getRevenantPlayer(arg)
                                else
                                    p = _getPlayer(arg)
                                end
                            end
                            if p then
                                local full = cmd .. ' ' .. p.DisplayName
                                _TextLabel.Text = _TextBox.Text .. full:sub(#_TextBox.Text + 1)
                            else
                                _TextLabel.Text = _TextBox.Text .. cmd:sub(#word + 1)
                            end
                            return
                        end
                    end
                    for alias, _ in pairs(_u61) do
                        if alias:find('^' .. word) then
                            local p = nil
                            if arg and not _specialArgs[arg:lower()] then
                                if _revenantOnlyCmds[alias] then
                                    p = _getRevenantPlayer(arg)
                                else
                                    p = _getPlayer(arg)
                                end
                            end
                            if p then
                                local full = alias .. ' ' .. p.DisplayName
                                _TextLabel.Text = _TextBox.Text .. full:sub(#_TextBox.Text + 1)
                            else
                                _TextLabel.Text = _TextBox.Text .. alias:sub(#word + 1)
                            end
                            return
                        end
                    end
                end
            end
        end)
        _TextBox.FocusLost:Connect(function(enterPressed)
            if enterPressed and Toggles.CommandBar.Value and not _TextBox.Text:match('^%s*$') then
                _TextLabel.Text = ''
                local rawText = _TextBox.Text
                local cmdParts = rawText:split(' ')
                if cmdParts then
                    local cmdName = cmdParts[1]
                    if cmdName then cmdName = cmdParts[1]:lower() end
                    if cmdName and (_u60[cmdName] or _u61[cmdName]) then
                        table.remove(cmdParts, 1)
                        task.spawn(_runCmd, cmdName, cmdParts)
                        if Toggles.SendCommandInChat.Value then
                            if _u60[cmdName] or _u61[cmdName] then
                                _skipNext = true
                                pcall(function()
                                    local tcs = game:GetService('TextChatService')
                                    local ch  = tcs.TextChannels:FindFirstChild('RBXGeneral')
                                    if ch then ch:SendAsync(';' .. rawText) end
                                end)
                            end
                        end
                    end
                end
            end
            _ScreenGui2.Enabled = false
        end)
        UIS.InputBegan:Connect(function(inputObj, _)
            if not UIS:GetFocusedTextBox() and inputObj.KeyCode == Enum.KeyCode[Options.CommandBind.Value] and Toggles.CommandBar.Value then
                _ScreenGui2.Enabled = true
                _TextBox:CaptureFocus()
                task.spawn(function()
                    repeat
                        _TextBox.Text  = ''
                        _TextLabel.Text = ''
                        RunService.RenderStepped:Wait()
                    until _TextBox.Text == '' and _TextLabel.Text == ''
                end)
            end
        end)
        local _chatConn = nil
        local function _setupChatHook()
            if _chatConn then _chatConn:Disconnect() _chatConn = nil end
            if not Toggles.UseCommandsinChat.Value then return end
            _chatConn = lp.Chatted:Connect(function(text)
                if _skipNext then _skipNext = false return end
                if text and text:find('^%s*;') then
                    local idx   = text:find(';')
                    local body  = text:sub(idx + 1)
                    local parts = body:split(' ')
                    local cmd   = parts[1] and parts[1]:lower() or ''
                    if _u60[cmd] or _u61[cmd] then
                        table.remove(parts, 1)
                        task.spawn(_runCmd, cmd, parts)
                    end
                end
            end)
        end
        Toggles.UseCommandsinChat:OnChanged(function()
            _setupChatHook()
        end)
        _setupChatHook()
        table.insert(CleanupTasks, function()
            if _viewConn then _viewConn:Disconnect() _viewConn = nil end
            pcall(function() _ScreenGui2:Destroy() end)
            if _chatConn then _chatConn:Disconnect() _chatConn = nil end
        pcall(function() Toggles.CommandBar:SetValue(false) end)
        pcall(function() Toggles.UseCommandsinChat:SetValue(false) end)
        pcall(function() Toggles.SendCommandInChat:SetValue(false) end)
        end)
    end)
end
local function RevenantCleanup()
    pcall(function()
        if getgenv()._standDeactivateFn then getgenv()._standDeactivateFn() end
    end)
    FlingActive = false
    if playerDiedConnection then playerDiedConnection:Disconnect() playerDiedConnection = nil end
    stopCurrentView()
    if maintenanceConnection then maintenanceConnection:Disconnect() maintenanceConnection = nil end
    if TPoseLoop             then TPoseLoop:Disconnect()             TPoseLoop             = nil end
    if headFloatSpamLoop     then headFloatSpamLoop:Disconnect()     headFloatSpamLoop     = nil end
    TPoseActive    = false
    tposeCachedAnimator    = nil
    for key, data in pairs(ANIMS_CONFIG) do
        if data.Track then
            pcall(function() if data.Track.IsPlaying then data.Track:Stop() end end)
            pcall(function() data.Track:Destroy() end)
            data.Track = nil
        end
        if data.IsActive ~= nil then data.IsActive = false end
    end
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop() end)
        pcall(function() currentEmoteTrack:Destroy() end)
        currentEmoteTrack = nil
    end
    emoteActive = false
    SwitcherActive = false
    pcall(function()
        if _voidProtConn  then _voidProtConn:Disconnect()  _voidProtConn  = nil end
        if _voidRenderConn then _voidRenderConn:Disconnect() _voidRenderConn = nil end
        if _voidHealthConn then _voidHealthConn:Disconnect() _voidHealthConn = nil end
        if _voidCharConn   then _voidCharConn:Disconnect()   _voidCharConn   = nil end
        if _voidFloor and _voidFloor.Parent then _voidFloor:Destroy() _voidFloor = nil end
        if getgenv().FPDH then
            workspace.FallenPartsDestroyHeight = getgenv().FPDH
        end
    end)
    pcall(function()
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then workspace.CurrentCamera.CameraSubject = hum end
    end)
    for _, task_fn in ipairs(CleanupTasks) do
        pcall(task_fn)
    end
    getgenv().InvisActive              = false
    getgenv().FUCActive                = false
    getgenv().TrashcanIsRunning        = false
    getgenv().TrashcanAlreadyExecuted  = false
    getgenv().TrashcanActiveHookSet    = false
    getgenv().TrashcanDied             = false
    getgenv().postTrashLoopActive      = false
    getgenv().OldPos                   = nil
    getgenv().desync                   = nil
    getgenv().flingDesync              = nil
    getgenv().FPDH                     = nil
    getgenv()._invisSavedTPose         = nil
    getgenv().stopInvisibilityFn       = nil
    getgenv()._revenantAntiFlingBuild  = nil
    getgenv()._revenantTPMode          = nil
    getgenv().morph                    = nil
    getgenv().Moveset_Settings         = nil
    getgenv()._sgOrigSetDecal          = nil
    getgenv()._revenantDashCooldown    = false
    getgenv()._revenantDashCooldownUntil = nil
    getgenv()._revenantTechActive      = false
    getgenv()._wcDashOnCooldown        = false
    getgenv()._revenantTechFiring      = false
    pcall(function()
            if _flingCharConn               then _flingCharConn:Disconnect()               _flingCharConn               = nil end
        if _charRemovingConn            then _charRemovingConn:Disconnect()            _charRemovingConn            = nil end
        if _flingPlayerAddedConn        then _flingPlayerAddedConn:Disconnect()        _flingPlayerAddedConn        = nil end
        if _flingPlayerRemovingConn     then _flingPlayerRemovingConn:Disconnect()     _flingPlayerRemovingConn     = nil end
        if _desyncCharConn              then _desyncCharConn:Disconnect()              _desyncCharConn              = nil end
        if _antiMovesPlayerRemovingConn then _antiMovesPlayerRemovingConn:Disconnect() _antiMovesPlayerRemovingConn = nil end
        if _invisDesyncHeartbeatConn    then _invisDesyncHeartbeatConn:Disconnect()    _invisDesyncHeartbeatConn    = nil end
        pcall(function() if InvisibleModel and InvisibleModel.Parent then InvisibleModel:Destroy() end end)
        getgenv().InvisHumanoid = nil
        getgenv().InvisPart30   = nil
        if _invisCharConn               then _invisCharConn:Disconnect()               _invisCharConn               = nil end
            if _walkCharConn                then _walkCharConn:Disconnect()                _walkCharConn                = nil end
        if _mapPlayerAddedConn          then _mapPlayerAddedConn:Disconnect()          _mapPlayerAddedConn          = nil end
        if _mapPlayerRemovingConn       then _mapPlayerRemovingConn:Disconnect()       _mapPlayerRemovingConn       = nil end
        if _fucCharConn                 then _fucCharConn:Disconnect()                 _fucCharConn                 = nil end
        if _fucRenderConn               then _fucRenderConn:Disconnect()               _fucRenderConn               = nil end
        -- Attach
        if WeldConnection               then WeldConnection:Disconnect()               WeldConnection               = nil end
        if WeldPlayerRemoving           then WeldPlayerRemoving:Disconnect()           WeldPlayerRemoving           = nil end
        if WeldActive then
            WeldActive = false
            local _cleanChar = lp.Character
            local _cleanRoot = _cleanChar and _cleanChar:FindFirstChild("HumanoidRootPart")
            if _cleanRoot and sethiddenproperty then
                pcall(function() sethiddenproperty(_cleanRoot, "PhysicsRepRootPart", nil) end)
            end
            if WeldState.target and WeldState.target.Parent then
                pcall(function() sethiddenproperty(WeldState.target, "PhysicsRepRootPart", nil) end)
                pcall(function() WeldState.target.AssemblyLinearVelocity  = Vector3.zero end)
                pcall(function() WeldState.target.AssemblyAngularVelocity = Vector3.zero end)
            end
            WeldState.target = nil
            WeldState.player = nil
        end
    end)
    Library:Unload()
    pcall(function() _RCS_Send("discon") end)
    getgenv().RevenantLoaded   = false
    getgenv().RevenantCleanup  = nil
end

BoxSettingsRight:AddButton({ Text = "Unload Script", Func = function()
    Window:AddDialog("RevenantUnloadConfirm", {
        Title       = "Unload Script",
        Description = "Are you sure you want to unload Revenant? All active features will be disabled and the script will be terminated.",
        AutoDismiss         = true,
        OutsideClickDismiss = true,
        FooterButtons = {
            Cancel = {
                Title    = "Cancel",
                Variant  = "Ghost",
                Order    = 1,
                Callback = function() end,
            },
            Unload = {
                Title    = "Unload",
                Variant  = "Destructive",
                Order    = 2,
                Callback = function()
                    task.defer(RevenantCleanup)
                end,
            },
        },
    })
end })
getgenv().RevenantCleanup = RevenantCleanup
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
local nick = lp.DisplayName ~= "" and lp.DisplayName or lp.Name
SaveManager:IgnoreThemeSettings()

ThemeManager:SetFolder("ZKAYTSB")
SaveManager:SetFolder("ZKAYTSB/TSB/configs")
SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:ApplyToTab(Tabs.Settings)
do
    local _killConn = nil
    local function _fireSpinEmote()
        local char = lp.Character
        if char and char.Parent then
            local comm = char:FindFirstChild("Communicate")
            if comm then
                pcall(function() comm:FireServer({["Goal"] = "Emote Spin"}) end)
            end
        end
    end
    local function _connectKillSignal()
        if _killConn then _killConn:Disconnect() _killConn = nil end
        local ok, kills = pcall(function()
            return game:GetService("Players").LocalPlayer.leaderstats["Total Kills"]
        end)
        if ok and kills then
            _killConn = kills:GetPropertyChangedSignal("Value"):Connect(function()
                _fireSpinEmote()
            end)
        end
    end
    _connectKillSignal()
    task.spawn(function()
        local char = lp.Character or lp.CharacterAdded:Wait()
        char:WaitForChild("Communicate", 10)
        _fireSpinEmote()
    end)
    lp.CharacterAdded:Connect(function()
        task.wait(1)
        _connectKillSignal()
    end)
    table.insert(CleanupTasks, function()
        if _killConn then _killConn:Disconnect() _killConn = nil end
    end)
end

-- ── HAND OFFSET ───────────────────────────────────────────────────────────────
do
    local _handOffsetTrack    = nil
    local _handOffsetHumanoid = nil
    local _handOffsetConn = RunService.RenderStepped:Connect(function()
        if Library.Unloaded then return end
        if not Toggles.TogHandOffset or not Toggles.TogHandOffset.Value then return end
        local char = lp.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end
        if _handOffsetHumanoid ~= humanoid then
            if _handOffsetTrack then pcall(function() if _handOffsetTrack.IsPlaying then _handOffsetTrack:Stop() end end) _handOffsetTrack = nil end
            _handOffsetHumanoid = humanoid
        end
        if not _handOffsetTrack or _handOffsetTrack.Parent == nil then
            local handOffset = Instance.new("Animation")
            handOffset.AnimationId = "rbxassetid://131081420344204"
            _handOffsetTrack = animator:LoadAnimation(handOffset)
            _handOffsetTrack.Priority = Enum.AnimationPriority.Action4
        end
        _handOffsetTrack:Play()
        _handOffsetTrack.TimePosition = 0.70
        _handOffsetTrack:AdjustSpeed(0)
        _handOffsetTrack:AdjustWeight(2e9)
        RunService.RenderStepped:Wait()
        if _handOffsetTrack and _handOffsetTrack.IsPlaying then pcall(function() _handOffsetTrack:Stop() end) end
    end)
    table.insert(CleanupTasks, function()
        if _handOffsetConn then _handOffsetConn:Disconnect() _handOffsetConn = nil end
        if _handOffsetTrack and _handOffsetTrack.IsPlaying then pcall(function() _handOffsetTrack:Stop() end) end
        _handOffsetTrack = nil
        pcall(function() if Toggles.TogHandOffset then Toggles.TogHandOffset:SetValue(false) end end)
    end)
end
-- ── END HAND OFFSET ───────────────────────────────────────────────────────────

-- ── ANIM ANCHOR FACTORY ──────────────────────────────────────────────────────
-- Snaps CFrame 1 second before the anim ends, then RenderStepped-teleports
-- to that saved position for 0.2s after the anim stops. No anchoring.
-- cfg fields:
--   animId      string  partial match against AnimationId
--   mechGuard   bool?   yields to mech invis block when mech is present
--   guardCheck  func?   (char)->bool  extra condition before running
--   onFire      func?   fires immediately when anim is detected
local function makeAnimAnchor(cfg)
    local _active   = false
    local _animConn = nil
    local _lastHum  = nil
    local _loopConn = nil
    local _snapConn = nil
    local _cfConn   = nil

    local function _hook(hum)
        if _animConn then _animConn:Disconnect() _animConn = nil end
        _lastHum = hum
        if not hum then return end

        _animConn = hum.AnimationPlayed:Connect(function(track)
            local id = track.Animation and track.Animation.AnimationId or ""
            if not getgenv().InvisActive then return end
            if cfg.mechGuard and getgenv().MechInvisHandled then
                pcall(function() track:Stop() end)
                return
            end
            if not id:find(cfg.animId, 1, true) then return end
            if not _active then            _active = true

            if cfg.onFire then pcall(cfg.onFire) end

            task.spawn(function()
                local c = lp.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if not r then _active = false return end
                if cfg.guardCheck and not cfg.guardCheck(c) then
                    _active = false
                    return
                end


                -- Watch for the 1-second-remaining window and snapshot there
                local savedCF = nil
                if _snapConn then _snapConn:Disconnect() _snapConn = nil end
                _snapConn = RunService.RenderStepped:Connect(function()
                    if Library.Unloaded or not track.IsPlaying then
                        if _snapConn then _snapConn:Disconnect() _snapConn = nil end
                        return
                    end
                    if savedCF then return end  -- already snapped
                    local len = track.Length
                    if len > 0 and (len - track.TimePosition) <= 1.50 then
                        local c2 = lp.Character
                        local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                        if r2 then
                            savedCF = r2.CFrame
                            local p = savedCF.Position
                        end
                        if _snapConn then _snapConn:Disconnect() _snapConn = nil end
                    end
                end)

                -- Wait for anim to finish
                track.Stopped:Wait()
                if _snapConn then _snapConn:Disconnect() _snapConn = nil end

                -- Fallback: if snap never fired (very short anim), use current pos
                -- Fallback: snap never fired (anim shorter than 1s)
                if not savedCF then
                    local c2 = lp.Character
                    local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                    savedCF = r2 and r2.CFrame
                end
                if savedCF then
                    -- Hammer savedCF on Heartbeat for 0.4 seconds then stop
                    local _elapsed = 0
                    if _cfConn then _cfConn:Disconnect() _cfConn = nil end
                    _cfConn = RunService.Heartbeat:Connect(function(dt)
                        if Library.Unloaded then
                            if _cfConn then _cfConn:Disconnect() _cfConn = nil end
                            _active = false
                            return
                        end
                        local c2 = lp.Character
                        local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                        if not r2 then
                            if _cfConn then _cfConn:Disconnect() _cfConn = nil end
                            _active = false
                            return
                        end
                        pcall(function() r2.CFrame = savedCF end)
                        _elapsed += dt
                        if _elapsed >= 0.4 then
                            if _cfConn then _cfConn:Disconnect() _cfConn = nil end
                            _active = false
                        end
                    end)
                else
                    _active = false
                end
            end)
            end  -- closes if not _active then
        end)
    end

    _loopConn = RunService.Heartbeat:Connect(function()
        if Library.Unloaded then return end
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum ~= _lastHum then _hook(hum) end
    end)

    table.insert(CleanupTasks, function()
        if _snapConn then _snapConn:Disconnect() _snapConn = nil end
        if _animConn then _animConn:Disconnect() _animConn = nil end
        if _loopConn then _loopConn:Disconnect() _loopConn = nil end
        if _cfConn   then _cfConn:Disconnect()   _cfConn   = nil end
        _active  = false
        _lastHum = nil
    end)
end
-- ── END ANIM ANCHOR FACTORY ───────────────────────────────────────────────────

-- ── INSTADIVE ANCHOR ─────────────────────────────────────────────────────────
makeAnimAnchor({
    animId        = "140153723843649",
    timeThreshold = 0.5,
    holdAfter     = 0.4,
})
-- ── END INSTADIVE ANCHOR ──────────────────────────────────────────────────────

-- ── INVIS ANCHOR ANIM ────────────────────────────────────────────────────────
makeAnimAnchor({
    animId        = "77891041839483",
    timeThreshold = 1.0,
    holdAfter     = 0.3,
})
-- ── END INVIS ANCHOR ANIM ─────────────────────────────────────────────────────

-- ── ANIM ANCHOR 133207489574364 ──────────────────────────────────────────────
makeAnimAnchor({
    animId        = "133207489574364",
    timeThreshold = 5.0,
    holdAfter     = 0.2,
})
-- ── END ANIM ANCHOR 133207489574364 ──────────────────────────────────────────

-- ── MECH INVIS ANIM 76020797916551 ───────────────────────────────────────────
do
    local _mechInvisTrack    = nil
    local _mechMaintConn     = nil
    local _mechInvisLoopConn = nil
    local _mechWatchConn     = nil
    local _liveWatchConn     = nil
    local _mechAncConn       = nil
    local _currentMech       = nil
    local _mechInvisWas      = false
    local _mechSavedCF       = nil
    local _mechTpConn        = nil

    local function _applyTransparency(mech)
        for _, part in ipairs(mech:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.Transparency = 0.5
                    part.LocalTransparencyModifier = 0.5
                    part.CastShadow = false
                end)
            end
        end
    end

    local function _restoreTransparency(mech)
        for _, part in ipairs(mech:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.Transparency = 0
                    part.LocalTransparencyModifier = 0
                    part.CastShadow = true
                end)
            end
        end
    end

    local function _stopMechTrack()
        if _mechMaintConn then _mechMaintConn:Disconnect() _mechMaintConn = nil end
        if _mechInvisTrack then
            pcall(function() _mechInvisTrack:Stop() end)
            _mechInvisTrack = nil
        end
        getgenv()._mechInvisTrack = nil
    end
    getgenv()._revenantStopMechTrack = _stopMechTrack

    local function _stopTpBack()
        if _mechTpConn then _mechTpConn:Disconnect() _mechTpConn = nil end
        _mechSavedCF = nil
    end

    local function _getMechRoot(mech)
        return mech.PrimaryPart
            or mech:FindFirstChild("HumanoidRootPart")
            or mech:FindFirstChildWhichIsA("BasePart")
    end

    local function _waitForAnimator(mech, timeout)
        local deadline = tick() + (timeout or 5)
        while tick() < deadline do
            if not mech:IsDescendantOf(workspace) then return nil end
            local ac = mech:FindFirstChildOfClass("AnimationController")
            if ac then
                local animr = ac:FindFirstChildOfClass("Animator")
                if animr then return animr end
            end
            task.wait(0.05)
        end
        return nil
    end

    local function _playMechInvis(mech)
        if not getgenv().InvisActive then
            getgenv().MechInvisHandled = false
            return
        end

        local animr = _waitForAnimator(mech, 5)
        if not animr then
            getgenv().MechInvisHandled = false
            return
        end

        if not mech:IsDescendantOf(workspace) then
            getgenv().MechInvisHandled = false
            return
        end
        if not getgenv().InvisActive then
            getgenv().MechInvisHandled = false
            return
        end

        getgenv().MechInvisHandled = true
        _stopMechTrack()
        _stopTpBack()

        -- Save mech position the moment invis fires
        local root = _getMechRoot(mech)
        if root then
            _mechSavedCF = root.CFrame
        end

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://98093529031758"
        local ok, track = pcall(function() return animr:LoadAnimation(anim) end)
        if not ok or not track then
            getgenv().MechInvisHandled = false
            _mechSavedCF = nil
            return
        end

        _mechInvisTrack = track
        track.Priority = Enum.AnimationPriority.Action4

        -- Play → freeze at 0.01 → stop client visual; server already got the replication packet
        pcall(function()
            track:Play()
            track.TimePosition = 0.01
        end)
        RunService.RenderStepped:Wait()
        pcall(function() track:Stop() end)

        _applyTransparency(mech)

        -- Hook mech's AnimationController for anim 85662656113434 (same as ANIM ANCHOR does
        -- for the humanoid) so save-pos + TP-back fires when the anim plays on the mech
        local ac = mech:FindFirstChildOfClass("AnimationController")
        if ac then
            local mechAnimConn
            mechAnimConn = ac.AnimationPlayed:Connect(function(mechTrack)
                local id = mechTrack.Animation and mechTrack.Animation.AnimationId or ""
                if not id:find("85662656113434", 1, true) then return end
                if mechAnimConn then mechAnimConn:Disconnect() mechAnimConn = nil end

                local snapConn
                local snapped = false
                snapConn = RunService.RenderStepped:Connect(function()
                    if Library.Unloaded or not mechTrack.IsPlaying then
                        if snapConn then snapConn:Disconnect() snapConn = nil end
                        return
                    end
                    if snapped then return end
                    local len = mechTrack.Length
                    if len > 0 and (len - mechTrack.TimePosition) <= 1.5 then
                        local r2 = _getMechRoot(mech)
                        if r2 then
                            _mechSavedCF = r2.CFrame
                            snapped = true
                        end
                        if snapConn then snapConn:Disconnect() snapConn = nil end
                    end
                end)

                mechTrack.Stopped:Wait()
                if snapConn then snapConn:Disconnect() snapConn = nil end

                if not snapped then
                    local r2 = _getMechRoot(mech)
                    if r2 then _mechSavedCF = r2.CFrame end
                end

                if _mechSavedCF then
                    local cf = _mechSavedCF
                    _mechSavedCF = nil
                    local elapsed = 0
                    if _mechTpConn then _mechTpConn:Disconnect() _mechTpConn = nil end
                    _mechTpConn = RunService.Heartbeat:Connect(function(dt)
                        if Library.Unloaded then
                            if _mechTpConn then _mechTpConn:Disconnect() _mechTpConn = nil end
                            return
                        end
                        local r2 = _getMechRoot(mech)
                        if not r2 then
                            if _mechTpConn then _mechTpConn:Disconnect() _mechTpConn = nil end
                            return
                        end
                        pcall(function() r2.CFrame = cf end)
                        elapsed += dt
                        if elapsed >= 0.4 then
                            if _mechTpConn then _mechTpConn:Disconnect() _mechTpConn = nil end
                        end
                    end)
                end
            end)
        end

        if _mechMaintConn then _mechMaintConn:Disconnect() _mechMaintConn = nil end
        _mechMaintConn = RunService.Heartbeat:Connect(function()
            if Library.Unloaded or not getgenv().InvisActive or not mech:IsDescendantOf(workspace) then
                if _mechMaintConn then _mechMaintConn:Disconnect() _mechMaintConn = nil end
                return
            end
            _applyTransparency(mech)
        end)

        getgenv()._mechInvisTrack = track
    end

    local function _onMechAdded(mech)
        _currentMech = mech

        if _mechAncConn then _mechAncConn:Disconnect() _mechAncConn = nil end
        _mechAncConn = mech.AncestryChanged:Connect(function()
            if not mech:IsDescendantOf(workspace) then
                _currentMech = nil
                getgenv().MechInvisHandled = false
                _stopMechTrack()
                _stopTpBack()
                if _mechAncConn then _mechAncConn:Disconnect() _mechAncConn = nil end
            end
        end)

        if getgenv().InvisActive then
            task.spawn(function() _playMechInvis(mech) end)
        end
    end

    local function _watchNode(node)
        if _mechWatchConn then _mechWatchConn:Disconnect() _mechWatchConn = nil end
        local existing = node:FindFirstChild("Mech")
        if existing then
            task.spawn(function() _onMechAdded(existing) end)
        end
        _mechWatchConn = node.ChildAdded:Connect(function(child)
            if child.Name == "Mech" then
                _onMechAdded(child)
            end
        end)
    end

    local function _startWatching()
        local live = workspace:FindFirstChild("Live")
            or workspace:WaitForChild("Live", 10)
        if not live then return end
        local node = live:FindFirstChild(lp.Name)
        if node then _watchNode(node) end
        if _liveWatchConn then _liveWatchConn:Disconnect() _liveWatchConn = nil end
        _liveWatchConn = live.ChildAdded:Connect(function(child)
            if child.Name == lp.Name then
                _watchNode(child)
            end
        end)
    end

    task.spawn(_startWatching)

    _mechInvisLoopConn = RunService.Heartbeat:Connect(function()
        if Library.Unloaded then return end
        local active = getgenv().InvisActive == true

        if active and _currentMech and _currentMech:IsDescendantOf(workspace) then
            local trackDead = not _mechInvisTrack
            if trackDead and not getgenv()._mechInvisSpawning then
                getgenv()._mechInvisSpawning = true
                task.spawn(function()
                    _playMechInvis(_currentMech)
                    getgenv()._mechInvisSpawning = false
                end)
            end
        end

        if active == _mechInvisWas then return end
        _mechInvisWas = active

        if not active then
            getgenv().MechInvisHandled = false
            getgenv()._mechInvisSpawning = false
            if _currentMech then _restoreTransparency(_currentMech) end
            _stopMechTrack()

            -- TP-back on toggle-off using saved activation position
            if _mechSavedCF and _currentMech and _currentMech:IsDescendantOf(workspace) then
                local cf = _mechSavedCF
                _mechSavedCF = nil
                local elapsed = 0
                if _mechTpConn then _mechTpConn:Disconnect() _mechTpConn = nil end
                _mechTpConn = RunService.Heartbeat:Connect(function(dt)
                    if Library.Unloaded then
                        if _mechTpConn then _mechTpConn:Disconnect() _mechTpConn = nil end
                        return
                    end
                    local r = _currentMech and _getMechRoot(_currentMech)
                    if not r then
                        if _mechTpConn then _mechTpConn:Disconnect() _mechTpConn = nil end
                        return
                    end
                    pcall(function() r.CFrame = cf end)
                    elapsed += dt
                    if elapsed >= 0.4 then
                        if _mechTpConn then _mechTpConn:Disconnect() _mechTpConn = nil end
                    end
                end)
            end
            return
        end

        if _currentMech then
            task.spawn(function() _playMechInvis(_currentMech) end)
        end
    end)

    table.insert(CleanupTasks, function()
        if _mechInvisLoopConn then _mechInvisLoopConn:Disconnect() _mechInvisLoopConn = nil end
        if _mechWatchConn     then _mechWatchConn:Disconnect()     _mechWatchConn = nil end
        if _liveWatchConn     then _liveWatchConn:Disconnect()     _liveWatchConn = nil end
        if _mechAncConn       then _mechAncConn:Disconnect()       _mechAncConn = nil end
        if _mechMaintConn     then _mechMaintConn:Disconnect()     _mechMaintConn = nil end
        if _mechTpConn        then _mechTpConn:Disconnect()        _mechTpConn = nil end
        _stopMechTrack()
        if _currentMech and _currentMech:IsDescendantOf(workspace) then
            pcall(function() _restoreTransparency(_currentMech) end)
        end
        getgenv().MechInvisHandled    = false
        getgenv()._mechInvisSpawning  = false
        getgenv()._revenantStopMechTrack = nil
        _mechInvisWas = false
        _currentMech  = nil
        _mechSavedCF  = nil
    end)
end
-- ── END MECH INVIS ANIM 76020797916551 ────────────────────────────────────────
-- ── END INSTADIVE ANCHOR ──────────────────────────────────────────────────────

-- ── ANIM ANCHOR 85662656113434 ───────────────────────────────────────────────
do
    local _animConn = nil
    local _loopConn = nil
    local _snapConn = nil
    local _cfConn   = nil
    local _active   = false
    local _lastHum  = nil

    local function _hook(hum)
        if _animConn then _animConn:Disconnect() _animConn = nil end
        _lastHum = hum
        if not hum then return end

        _animConn = hum.AnimationPlayed:Connect(function(track)
            local id = track.Animation and track.Animation.AnimationId or ""
            if not getgenv().InvisActive then return end
            if not id:find("85662656113434", 1, true) then return end
            if not _active then            _active = true

            task.spawn(function()
                local c = lp.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if not r then _active = false return end

                -- Watch for the 1-second-remaining window and snapshot there
                local savedCF = nil
                if _snapConn then _snapConn:Disconnect() _snapConn = nil end
                _snapConn = RunService.RenderStepped:Connect(function()
                    if Library.Unloaded or not track.IsPlaying then
                        if _snapConn then _snapConn:Disconnect() _snapConn = nil end
                        return
                    end
                    if savedCF then return end  -- already snapped
                    local len = track.Length
                    if len > 0 and (len - track.TimePosition) <= 1.50 then
                        local c2 = lp.Character
                        local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                        if r2 then
                            savedCF = r2.CFrame
                            local p = savedCF.Position
                        end
                        if _snapConn then _snapConn:Disconnect() _snapConn = nil end
                    end
                end)

                -- Wait for anim to finish
                track.Stopped:Wait()
                if _snapConn then _snapConn:Disconnect() _snapConn = nil end

                -- Fallback: if snap never fired (very short anim), use current pos
                if not savedCF then
                    local c2 = lp.Character
                    local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                    savedCF = r2 and r2.CFrame
                end
                if savedCF then
                    -- Hammer savedCF on Heartbeat for 0.4 seconds then stop
                    local _elapsed = 0
                    if _cfConn then _cfConn:Disconnect() _cfConn = nil end
                    _cfConn = RunService.Heartbeat:Connect(function(dt)
                        if Library.Unloaded then
                            if _cfConn then _cfConn:Disconnect() _cfConn = nil end
                            _active = false
                            return
                        end
                        local c2 = lp.Character
                        local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                        if not r2 then
                            if _cfConn then _cfConn:Disconnect() _cfConn = nil end
                            _active = false
                            return
                        end
                        pcall(function() r2.CFrame = savedCF end)
                        _elapsed += dt
                        if _elapsed >= 0.4 then
                            if _cfConn then _cfConn:Disconnect() _cfConn = nil end
                            _active = false
                        end
                    end)
                else
                    _active = false
                end
            end)
            end  -- closes if not _active then
        end)
    end

    _loopConn = RunService.Heartbeat:Connect(function()
        if Library.Unloaded then return end
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum ~= _lastHum then _hook(hum) end
    end)

    table.insert(CleanupTasks, function()
        if _snapConn then _snapConn:Disconnect() _snapConn = nil end
        if _animConn then _animConn:Disconnect() _animConn = nil end
        if _loopConn then _loopConn:Disconnect() _loopConn = nil end
        if _cfConn   then _cfConn:Disconnect()   _cfConn   = nil end
        _active  = false
        _lastHum = nil
    end)
end
-- ── END ANIM ANCHOR 85662656113434 ───────────────────────────────────────────

pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    lp.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)
end, tostring)

if not _mainOk then
    warn("[Something is wrong with Revenant]: " .. tostring(_mainErr))
    print("[ZKAYTSB ERROR DETAIL]: " .. tostring(_mainErr))
    pcall(function()
        local _bugBtn = Instance.new("BindableFunction")
        _bugBtn.Parent = game:GetService("CoreGui")
        _bugBtn.OnInvoke = function(choice)
            if choice == "unload" then
                if getgenv().RevenantCleanup then
                    pcall(getgenv().RevenantCleanup)
                else
                    pcall(function() Library:Unload() end)
                end
                getgenv().RevenantLoaded = false
                pcall(function() setclipboard("https://discord.gg/TYdSMmQaF9") end)
                task.delay(0.1, function()
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title    = "Revenant",
                            Text     = "Discord link copied to clipboard. Please report this issue.",
                            Time = 6,
                        })
                    end)
                end)
            end
        end
    end)
end
end)
