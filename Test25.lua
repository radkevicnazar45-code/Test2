--==================================================
-- Simple ESP + Aim Assist
-- Для собственного Lua-клиента / тестовой игры
--==================================================

local Config = {
    ESP = true,
    ESPBox = true,
    ESPName = true,
    ESPDistance = true,

    AimAssist = true,
    AimFOV = 120,          -- радиус поиска цели
    AimSmooth = 0.18,      -- 0 = резко, 1 = почти без помощи
    AimMaxDistance = 300,

    TeamCheck = true
}

--==================================================
-- АДАПТЕР ДВИЖКА
-- Замени содержимое этих функций API своей игры
--==================================================

local function GetLocalPlayer()
    return Game.GetLocalPlayer()
end

local function GetPlayers()
    return Game.GetPlayers()
end

local function GetCamera()
    return Game.GetCamera()
end

local function GetPosition(player)
    return player:GetPosition()
end

local function GetName(player)
    return player:GetName()
end

local function GetTeam(player)
    return player:GetTeam()
end

local function IsAlive(player)
    return player:IsAlive()
end

-- Должна вернуть:
-- screenX, screenY, visible
local function WorldToScreen(position)
    return GetCamera():WorldToScreen(position)
end

-- Направляет камеру/прицел на мировую точку
local function AimAt(worldPosition, smooth)
    GetCamera():AimAt(worldPosition, smooth)
end

--==================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
--==================================================

local function Distance(a, b)
    local x = a.x - b.x
    local y = a.y - b.y
    local z = a.z - b.z

    return math.sqrt(x*x + y*y + z*z)
end

local function IsEnemy(localPlayer, player)
    if not Config.TeamCheck then
        return true
    end

    return GetTeam(localPlayer) ~= GetTeam(player)
end

--==================================================
-- ESP
--==================================================

local function DrawESP(player)
    if not Config.ESP then return end
    if not IsAlive(player) then return end

    local localPlayer = GetLocalPlayer()

    if player == localPlayer then
        return
    end

    if not IsEnemy(localPlayer, player) then
        return
    end

    local pos = GetPosition(player)

    -- Верх/низ условного персонажа.
    -- Подстрой высоту под свою модель.
    local bottom = {
        x = pos.x,
        y = pos.y,
        z = pos.z
    }

    local top = {
        x = pos.x,
        y = pos.y + 1.8,
        z = pos.z
    }

    local bx, by, visibleBottom = WorldToScreen(bottom)
    local tx, ty, visibleTop = WorldToScreen(top)

    if not visibleBottom or not visibleTop then
        return
    end

    local height = math.abs(by - ty)
    local width = height * 0.42

    local left = tx - width
    local right = tx + width

    -- Box
    if Config.ESPBox then
        UI.DrawRectOutline(
            left,
            ty,
            right,
            by,
            2
        )
    end

    -- Name
    if Config.ESPName then
        UI.DrawText(
            GetName(player),
            tx,
            ty - 18
        )
    end

    -- Distance
    if Config.ESPDistance then
        local distance = Distance(
            GetPosition(localPlayer),
            pos
        )

        UI.DrawText(
            string.format("%.0fm", distance),
            tx,
            by + 5
        )
    end
end

--==================================================
-- AIM ASSIST
--==================================================

local function GetAimTarget()
    if not Config.AimAssist then
        return nil
    end

    local localPlayer = GetLocalPlayer()
    local camera = GetCamera()

    local cameraPos = camera:GetPosition()

    local centerX, centerY = UI.GetScreenCenter()

    local bestPlayer = nil
    local bestDistance = Config.AimFOV

    for _, player in ipairs(GetPlayers()) do

        if player ~= localPlayer
        and IsAlive(player)
        and IsEnemy(localPlayer, player) then

            local position = GetPosition(player)

            local distance = Distance(
                cameraPos,
                position
            )

            if distance <= Config.AimMaxDistance then

                -- Целимся примерно в голову
                local head = {
                    x = position.x,
                    y = position.y + 1.55,
                    z = position.z
                }

                local sx, sy, visible = WorldToScreen(head)

                if visible then
                    local dx = sx - centerX
                    local dy = sy - centerY

                    local screenDistance =
                        math.sqrt(dx*dx + dy*dy)

                    if screenDistance < bestDistance then
                        bestDistance = screenDistance
                        bestPlayer = player
                    end
                end
            end
        end
    end

    return bestPlayer
end

local function UpdateAim()
    local target = GetAimTarget()

    if not target then
        return
    end

    local position = GetPosition(target)

    local head = {
        x = position.x,
        y = position.y + 1.55,
        z = position.z
    }

    AimAt(head, Config.AimSmooth)
end

--==================================================
-- MAIN LOOP
--==================================================

function Update()
    for _, player in ipairs(GetPlayers()) do
        DrawESP(player)
    end

    UpdateAim()
end

-- Подключи Update() к игровому tick/update:
-- Game.OnUpdate(Update)
