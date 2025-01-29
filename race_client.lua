-- Configuration
local CHECKPOINT_PROXIMITY_THRESHOLD = 10.0 -- Distance to consider a checkpoint passed (in units)
local CHECKPOINT_BLIP_COLOR = 5 -- Blip color (green)
local CHECKPOINT_BLIP_SCALE = 0.8 -- Blip size
local CHECKPOINT_BLIP_SPRITE = 1 -- Blip sprite (default marker)
local ADD_CHECKPOINT_KEY = 57 -- F10 key to add a checkpoint (change as needed)
local CHECKPOINT_3D_COLOR = {
    r = 0,
    g = 255,
    b = 0,
    a = 100
} -- Cor do checkpoint 3D (verde)
local CHECKPOINT_3D_SIZE = 3.0 -- Tamanho do marcador 3D

-- Local variables
local checkpoints = {} -- List of checkpoints
local currentCheckpointIndex = 1 -- Index of the current checkpoint
local raceBuilding = true -- Whether the race is being built

-- Função para criar um checkpoint 3D visível
local function create3DCheckpoint(x, y, z)
    local checkpoint = CreateCheckpoint(4, -- Tipo de checkpoint (4 = cilindro com seta)
    x, y, z, -- Posição
    x, y, z, -- Direção (não relevante para cilindro)
    CHECKPOINT_3D_SIZE, -- Tamanho
    CHECKPOINT_3D_COLOR.r, CHECKPOINT_3D_COLOR.g, CHECKPOINT_3D_COLOR.b, CHECKPOINT_3D_COLOR.a, -- Cor
    100, -- Alpha
    0 -- "Reserved"
    )
    return checkpoint
end

-- Function to show a checkpoint blip on the map
local function showCheckpointBlip(x, y, z)
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, CHECKPOINT_BLIP_SPRITE)
    SetBlipColour(blip, CHECKPOINT_BLIP_COLOR)
    SetBlipScale(blip, CHECKPOINT_BLIP_SCALE)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Checkpoint")
    EndTextCommandSetBlipName(blip)
    return blip
end

-- Function to add a new checkpoint
local function addCheckpoint(x, y, z)
    if not raceBuilding then
        print("Race has already started! Cannot add more checkpoints.")
        return
    end

    local checkpoint = {
        x = x,
        y = y,
        z = z,
        blip = showCheckpointBlip(x, y, z),
        checkpoint = create3DCheckpoint(x, y, z + 1.0), -- +1.0 para flutuar acima do chão
        passed = false -- Mark checkpoint as not passed
    }
    table.insert(checkpoints, checkpoint)
    TriggerServerEvent('race:addCheckpoint', checkpoint)
    print("New checkpoint added at: ", x, y, z)
end

-- Function to remove a checkpoint
local function removeCheckpoint(index)
    if checkpoints[index] then
        -- Remove blip
        if checkpoints[index].blip then
            RemoveBlip(checkpoints[index].blip)
        end
        -- Remove checkpoint 3D
        if checkpoints[index].checkpoint then
            DeleteCheckpoint(checkpoints[index].checkpoint)
        end
        table.remove(checkpoints, index)
        print("Checkpoint removed: ", index)
    end
end

-- Function to check if the player is near a checkpoint
local function isPlayerNearCheckpoint(playerPed, checkpoint)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, checkpoint.x, checkpoint.y, checkpoint.z)
    return distance < CHECKPOINT_PROXIMITY_THRESHOLD
end

-- Function to start the race
local function startRace()
    if #checkpoints < 2 then
        print("You need at least 2 checkpoints to start the race!")
        return
    end

    raceBuilding = false
    currentCheckpointIndex = 1

    -- Set the first waypoint
    if checkpoints[currentCheckpointIndex] then
        SetNewWaypoint(checkpoints[currentCheckpointIndex].x, checkpoints[currentCheckpointIndex].y)
        print("Race started! First checkpoint set.")
    end
end

-- Function to reset the race state
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
    print("Race state reset. Ready to create a new race.")
end

-- Thread to handle checkpoint creation
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        -- Check if the player pressed the key to add a checkpoint
        if IsControlJustPressed(0, ADD_CHECKPOINT_KEY) then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            addCheckpoint(playerCoords.x, playerCoords.y, playerCoords.z)
        end
    end
end)

-- Thread to track checkpoint progress
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        if raceBuilding then
            -- Do nothing if the race is still being built
            goto continue
        end

        local playerPed = PlayerPedId()
        local currentCheckpoint = checkpoints[currentCheckpointIndex]

        if currentCheckpoint and not currentCheckpoint.passed and isPlayerNearCheckpoint(playerPed, currentCheckpoint) then
            currentCheckpoint.passed = true -- Mark the checkpoint as passed
            currentCheckpointIndex = currentCheckpointIndex + 1 -- Move to the next checkpoint

            if checkpoints[currentCheckpointIndex] then
                -- Notify the server and update the waypoint
                TriggerServerEvent('race:checkpointPassed', currentCheckpointIndex)
                SetNewWaypoint(checkpoints[currentCheckpointIndex].x, checkpoints[currentCheckpointIndex].y)
                print("Next checkpoint: ", checkpoints[currentCheckpointIndex].x, checkpoints[currentCheckpointIndex].y)
            else
                print("All checkpoints passed! Race completed.")
                resetRace() -- Reset the race state for the next race
            end
        end

        ::continue::
    end
end)

-- Event to show the next checkpoint (triggered by the server)
RegisterNetEvent('race:showNextCheckpoint')
AddEventHandler('race:showNextCheckpoint', function(x, y)
    SetNewWaypoint(x, y)
    print("Next checkpoint set to: ", x, y)
end)

-- Command to start the race
RegisterCommand("startRace", function()
    startRace()
end, false)

-- Command to reset the race
RegisterCommand("resetRace", function()
    resetRace()
end, false)
