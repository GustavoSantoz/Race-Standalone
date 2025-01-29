local checkpoints = {}
local currentCheckpointIndex = 1
local raceBuilding = true
local isRaceStarting = false
local raceStartTime = 0
local isRaceActive = false
local bestTime = nil
local isPlayerFrozen = false

-- Função para congelar/descongelar o jogador
local function freezePlayer(freeze)
    isPlayerFrozen = freeze
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if DoesEntityExist(vehicle) then
        FreezeEntityPosition(vehicle, freeze)
        SetVehicleEngineOn(vehicle, not freeze, true, false)
    else
        FreezeEntityPosition(playerPed, freeze)
    end
end

-- Função de teleporte para checkpoint
local function teleportToCheckpoint(checkpoint)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    SetEntityCollision(playerPed, false, false)
    if DoesEntityExist(vehicle) then
        SetEntityCollision(vehicle, false, false)
        SetEntityCoords(vehicle, checkpoint.x, checkpoint.y, checkpoint.z + 1.0)
        SetVehicleOnGroundProperly(vehicle)
    else
        SetEntityCoords(playerPed, checkpoint.x, checkpoint.y, checkpoint.z + 1.0)
    end

    Citizen.Wait(100)
    SetEntityCollision(playerPed, true, true)
    if DoesEntityExist(vehicle) then
        SetEntityCollision(vehicle, true, true)
    end
end

-- Contagem regressiva modificada
local function startCountdown()
    isRaceStarting = true
    local firstCheckpoint = checkpoints[1]

    if firstCheckpoint then
        teleportToCheckpoint(firstCheckpoint)
        SetNewWaypoint(firstCheckpoint.x, firstCheckpoint.y)
    end

    freezePlayer(true)

    -- Contagem regressiva
    for i = 3, 1, -1 do
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName("~y~" .. i)
        SetTextFont(4)
        SetTextScale(5.0, 5.0)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        SetTextCentre(true)
        EndTextCommandDisplayText(0.5, 0.5)
        PlaySoundFrontend(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", true)
        Citizen.Wait(1000)
    end

    -- Início da corrida
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName("~g~GO!")
    SetTextFont(4)
    SetTextScale(5.0, 5.0)
    SetTextOutline()
    SetTextCentre(true)
    EndTextCommandDisplayText(0.5, 0.5)
    PlaySoundFrontend(-1, "GO", "HUD_MINI_GAME_SOUNDSET", true)
    Citizen.Wait(1000)

    freezePlayer(false)
    isRaceStarting = false
    raceBuilding = false
    isRaceActive = true
    raceStartTime = GetGameTimer()
end

-- Função para exibir tempo
local function displayTime()
    if not isRaceActive then
        return
    end

    local elapsedTime = GetGameTimer() - raceStartTime
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

-- Função de finalização
local function finishRace()
    isRaceActive = false
    local elapsedTime = GetGameTimer() - raceStartTime
    local minutes = math.floor(elapsedTime / 60000)
    local seconds = math.floor((elapsedTime % 60000) / 1000)
    local milliseconds = math.floor((elapsedTime % 1000) / 10)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentString(string.format("~g~FINALIZADO!~w~\nTempo: ~y~%02d:%02d:%02d", minutes, seconds, milliseconds))
    SetTextFont(4)
    SetTextScale(0.8, 0.8)
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

-- Sistema de checkpoints
local function create3DCheckpoint(x, y, z, isPassed)
    local color = isPassed and CHECKPOINT_3D_PASSED_COLOR or CHECKPOINT_3D_COLOR
    return CreateCheckpoint(4, x, y, z, x, y, z, CHECKPOINT_3D_SIZE, color.r, color.g, color.b, color.a, 100, 0)
end

local function showCheckpointBlip(x, y, z, isPassed)
    local blip = AddBlipForCoord(x, y, z)
    SetBlipColour(blip, isPassed and CHECKPOINT_BLIP_PASSED_COLOR or CHECKPOINT_BLIP_COLOR)
    SetBlipSprite(blip, CHECKPOINT_BLIP_SPRITE)
    SetBlipScale(blip, CHECKPOINT_BLIP_SCALE)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(isPassed and "Checkpoint Passado" or "Checkpoint")
    EndTextCommandSetBlipName(blip)
    return blip
end

local function addCheckpoint(x, y, z)
    if not raceBuilding then
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
    print("Checkpoint adicionado: " .. x .. ", " .. y .. ", " .. z)
end

local function resetRace()
    for _, cp in pairs(checkpoints) do
        RemoveBlip(cp.blip)
        DeleteCheckpoint(cp.checkpoint)
    end
    checkpoints = {}
    currentCheckpointIndex = 1
    raceBuilding = true
    freezePlayer(false)
    print("Corrida resetada")
end

-- Threads principais
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        displayTime()

        if IsControlJustPressed(0, ADD_CHECKPOINT_KEY) and raceBuilding then
            local coords = GetEntityCoords(PlayerPedId())
            addCheckpoint(coords.x, coords.y, coords.z)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if not isRaceActive then
            goto continue
        end

        local playerPed = PlayerPedId()
        local currentCp = checkpoints[currentCheckpointIndex]

        if currentCp and not currentCp.passed and
            Vdist(GetEntityCoords(playerPed), currentCp.x, currentCp.y, currentCp.z) < CHECKPOINT_PROXIMITY_THRESHOLD then
            currentCp.passed = true
            SetBlipColour(currentCp.blip, CHECKPOINT_BLIP_PASSED_COLOR)
            DeleteCheckpoint(currentCp.checkpoint)
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

-- Controle de inputs durante congelamento
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isPlayerFrozen then
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- Chat de voz
            EnableControlAction(0, 245, true) -- Chat textual
        end
    end
end)

-- Comandos
RegisterCommand("startRace", function()
    if isRaceStarting or #checkpoints < 2 then
        return
    end
    if not IsPedInAnyVehicle(PlayerPedId(), false) then
        print("Entre em um veículo primeiro!")
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId() then
        SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end

    startCountdown()
end)

RegisterCommand("resetRace", resetRace)
