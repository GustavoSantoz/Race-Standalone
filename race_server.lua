-- race_server.lua
local checkpoints = {}
local raceActive = false

-- Function to add a new checkpoint
RegisterNetEvent('race:addCheckpoint')
AddEventHandler('race:addCheckpoint', function(checkpoint)
    -- Validate the checkpoint data
    if type(checkpoint) == "table" and checkpoint.x and checkpoint.y then
        table.insert(checkpoints, checkpoint)
        print("Checkpoint added: ", checkpoint.x, checkpoint.y)
    else
        print("Invalid checkpoint data received.")
    end
end)

-- Function to activate the next checkpoint
function activateNextCheckpoint(source)
    if #checkpoints > 0 then
        local nextCheckpoint = table.remove(checkpoints, 1) -- Remove the first checkpoint from the list
        TriggerClientEvent('race:showNextCheckpoint', source, nextCheckpoint.x, nextCheckpoint.y)
        print("Next checkpoint activated for player: ", source, nextCheckpoint.x, nextCheckpoint.y)
    else
        TriggerClientEvent('race:raceFinished', source)
        print("Race finished for player: ", source)
        raceActive = false
    end
end

-- Function to start the race
function startRace(source)
    if #checkpoints > 0 then
        raceActive = true
        activateNextCheckpoint(source)
        print("Race started by player: ", source)
    else
        print("No checkpoints available to start the race.")
    end
end

-- Command to start the race
RegisterCommand('start_race', function(source)
    if not raceActive then
        startRace(source)
    else
        print("Race is already active.")
    end
end)

-- Event to handle checkpoint reached by the player
RegisterNetEvent('race:checkpointReached')
AddEventHandler('race:checkpointReached', function()
    if raceActive then
        activateNextCheckpoint(source)
    else
        print("Race is not active.")
    end
end)

-- Command to reset the race (optional)
RegisterCommand('reset_race', function(source)
    checkpoints = {}
    raceActive = false
    TriggerClientEvent('race:resetRace', -1) -- Notify all clients to reset the race
    print("Race reset by player: ", source)
end)
