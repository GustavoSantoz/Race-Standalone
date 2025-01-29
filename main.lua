-- Variáveis locais
local checkpoints = {}
local currentCheckpointIndex = 1
local raceBuilding = true
local isRaceStarting = false
local raceStartTime = 0
local isRaceActive = false
local bestTime = nil

-- Função para exibir o tempo na tela
local function displayTime()
    if not isRaceActive then
        return
    end

    local currentTime = GetGameTimer()
    local elapsedTime = currentTime - raceStartTime
    local minutes = math.floor(elapsedTime / 60000)
    local seconds = math.floor((elapsedTime % 60000) / 1000)
    local milliseconds = math.floor((elapsedTime % 1000) / 10)

    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(string.format("Tempo: %02d:%02d:%02d", minutes, seconds, milliseconds))
    EndTextCommandDisplayText(0.95, 0.02)
end

-- Função para marcar checkpoint como passado (azul)
local function markCheckpointAsPassed(checkpoint)
    SetBlipColour(checkpoint.blip, CHECKPOINT_BLIP_PASSED_COLOR)
    if checkpoint.checkpoint then
        DeleteCheckpoint(checkpoint.checkpoint)
    end
end

-- Função para criar checkpoint 3D
local function create3DCheckpoint(x, y, z, isPassed)
    local color = isPassed and CHECKPOINT_3D_PASSED_COLOR or CHECKPOINT_3D_COLOR
    return CreateCheckpoint(4, x, y, z, x, y, z, CHECKPOINT_3D_SIZE, color.r, color.g, color.b, color.a, 100, 0)
end

-- Função para mostrar blip no mapa
local function showCheckpointBlip(x, y, z, isPassed)
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, CHECKPOINT_BLIP_SPRITE)
    SetBlipColour(blip, isPassed and CHECKPOINT_BLIP_PASSED_COLOR or CHECKPOINT_BLIP_COLOR)
    SetBlipScale(blip, CHECKPOINT_BLIP_SCALE)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(isPassed and "Checkpoint Passado" or "Checkpoint")
    EndTextCommandSetBlipName(blip)
    return blip
end

-- Função para adicionar checkpoint
local function addCheckpoint(x, y, z)
    if not raceBuilding then
        print("A corrida já começou!")
        return
    end

    local checkpoint = {
        x = x,
        y = y,
        z = z,
        blip = showCheckpointBlip(x, y, z, false),
        checkpoint = create3DCheckpoint(x, y, z + 1.0, false),
        passed = false
    }
    table.insert(checkpoints, checkpoint)
    print("Checkpoint adicionado: ", x, y, z)
end

-- Função para iniciar contagem regressiva
local function startCountdown()
    isRaceStarting = true

    for i = 3, 1, -1 do
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(tostring(i))
        SetTextFont(4)
        SetTextScale(5.0, 5.0)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        SetTextCentre(true)
        EndTextCommandDisplayText(0.5, 0.5)
        PlaySoundFrontend(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", true)
        Citizen.Wait(1000)
    end

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName("~g~GO!")
    SetTextFont(4)
    SetTextScale(5.0, 5.0)
    SetTextColour(0, 255, 0, 255)
    SetTextOutline()
    SetTextCentre(true)
    EndTextCommandDisplayText(0.5, 0.5)
    PlaySoundFrontend(-1, "GO", "HUD_MINI_GAME_SOUNDSET", true)
    Citizen.Wait(1000)

    isRaceStarting = false
    raceBuilding = false
    isRaceActive = true
    raceStartTime = GetGameTimer()

    if checkpoints[currentCheckpointIndex] then
        SetNewWaypoint(checkpoints[currentCheckpointIndex].x, checkpoints[currentCheckpointIndex].y)
    end
end

-- Função para finalizar corrida
local function finishRace()
    isRaceActive = false

    local currentTime = GetGameTimer()
    local elapsedTime = currentTime - raceStartTime
    local minutes = math.floor(elapsedTime / 60000)
    local seconds = math.floor((elapsedTime % 60000) / 1000)
    local milliseconds = math.floor((elapsedTime % 1000) / 10)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(string.format("~g~Corrida Concluída!~w~\nTempo: ~y~%02d:%02d:%02d", minutes,
        seconds, milliseconds))
    SetTextFont(4)
    SetTextScale(0.8, 0.8)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    EndTextCommandDisplayText(0.5, 0.5)
    PlaySoundFrontend(-1, "MP_5_SECOND_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    Citizen.Wait(5000)

    if not bestTime or elapsedTime < bestTime then
        bestTime = elapsedTime
        print("Novo recorde: " .. string.format("%02d:%02d:%02d", minutes, seconds, milliseconds))
    end

    resetRace()
end

-- Função para resetar corrida
local function resetRace()
    for _, cp in pairs(checkpoints) do
        if cp.blip then
            RemoveBlip(cp.blip)
        end
        if cp.checkpoint then
            DeleteCheckpoint(cp.checkpoint)
        end
    end
    checkpoints = {}
    currentCheckpointIndex = 1
    raceBuilding = true
    print("Corrida resetada.")
end

-- Threads
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        displayTime()
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, ADD_CHECKPOINT_KEY) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            addCheckpoint(playerCoords.x, playerCoords.y, playerCoords.z)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if raceBuilding then
            goto continue
        end

        local playerPed = PlayerPedId()
        local currentCheckpoint = checkpoints[currentCheckpointIndex]

        if currentCheckpoint and not currentCheckpoint.passed and
            Vdist(GetEntityCoords(playerPed), currentCheckpoint.x, currentCheckpoint.y, currentCheckpoint.z) <
            CHECKPOINT_PROXIMITY_THRESHOLD then
            currentCheckpoint.passed = true
            markCheckpointAsPassed(currentCheckpoint)
            currentCheckpointIndex = currentCheckpointIndex + 1

            if checkpoints[currentCheckpointIndex] then
                SetNewWaypoint(checkpoints[currentCheckpointIndex].x, checkpoints[currentCheckpointIndex].y)
            else
                finishRace()
            end
        end

        ::continue::
    end
end)

-- Comandos
RegisterCommand("startRace", function()
    if #checkpoints >= 2 then
        startCountdown()
    else
        print("Adicione pelo menos 2 checkpoints!")
    end
end)

RegisterCommand("resetRace", resetRace)
