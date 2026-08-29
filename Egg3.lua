-- ServerScriptService > AutoEggFarm

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TARGETS = {
    Secret = true,
    Eternal = true,
    Divine = true
}

local RETURN_TIME = 1
local CHECK_DELAY = 0.25

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getEggs()
    local eggs = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if TARGETS[obj.Name] then
            local part

            if obj:IsA("BasePart") then
                part = obj
            elseif obj:IsA("Model") then
                part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            end

            if part then
                table.insert(eggs, {
                    object = obj,
                    part = part
                })
            end
        end
    end

    return eggs
end

local function nearestEgg(position)
    local best
    local distance = math.huge

    for _, egg in ipairs(getEggs()) do
        local d = (egg.part.Position - position).Magnitude

        if d < distance then
            distance = d
            best = egg
        end
    end

    return best
end

local function findSpawn()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            return obj
        end
    end
end

local function moveTo(character, position)
    local root = getRoot(character)
    if not root then return false end

    root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    return true
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(2)

        task.spawn(function()
            while character.Parent do
                local root = getRoot(character)
                local spawn = findSpawn()

                if root and spawn then
                    local egg = nearestEgg(root.Position)

                    if egg then
                        -- Подлетаем к яйцу
                        moveTo(character, egg.part.Position)

                        task.wait(0.3)

                        -- Здесь вызывается ТВОЯ серверная функция подбора.
                        -- Например:
                        -- collectEgg(player, egg.object)

                        task.wait(RETURN_TIME)

                        -- Возвращаемся на Spawn
                        moveTo(character, spawn.Position)
                    end
                end

                task.wait(CHECK_DELAY)
            end
        end)
    end)
end)
