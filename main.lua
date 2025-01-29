-- Importar configurações do arquivo config.lua
    local config = require 'config'

    -- Variáveis locais
    local checkpoints = {} -- Lista de checkpoints
    local currentCheckpointIndex = 1 -- Índice do checkpoint atual
    local raceBuilding = true -- Indica se a corrida está sendo construída
    
    -- Função para criar um checkpoint 3D visível
    local function create3DCheckpoint(x, y, z)
        local checkpoint = CreateCheckpoint(4, -- Tipo de checkpoint (4 = cilindro com seta)
        x, y, z, -- Posição
        x, y, z, -- Direção (não relevante para cilindro)
        config.CHECKPOINT_3D_SIZE, -- Tamanho
        config.CHECKPOINT_3D_COLOR.r, config.CHECKPOINT_3D_COLOR.g, config.CHECKPOINT_3D_COLOR.b, config.CHECKPOINT_3D_COLOR.a, -- Cor
        100, -- Alpha
        0 -- "Reserved"
        )
        return checkpoint
    end
    
    -- Função para mostrar um blip no mapa
    local function showCheckpointBlip(x, y, z)
        local blip = AddBlipForCoord(x, y, z)
        SetBlipSprite(blip, config.CHECKPOINT_BLIP_SPRITE)
        SetBlipColour(blip, config.CHECKPOINT_BLIP_COLOR)
        SetBlipScale(blip, config.CHECKPOINT_BLIP_SCALE)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Checkpoint")
        EndTextCommandSetBlipName(blip)
        return blip
    end
    
    -- Função para adicionar um novo checkpoint
    local function addCheckpoint(x, y, z)
        if not raceBuilding then
            print("A corrida já começou! Não é possível adicionar mais checkpoints.")
            return
        end
    
        local checkpoint = {
            x = x,
            y = y,
            z = z,
            blip = showCheckpointBlip(x, y, z),
            checkpoint = create3DCheckpoint(x, y, z + 1.0), -- +1.0 para flutuar acima do chão
            passed = false -- Marca o checkpoint como não passado
        }
        table.insert(checkpoints, checkpoint)
        TriggerServerEvent('race:addCheckpoint', checkpoint)
        print("Novo checkpoint adicionado em: ", x, y, z)
    end
    
    -- Função para remover um checkpoint
    local function removeCheckpoint(index)
        if checkpoints[index] then
            -- Remove o blip
            if checkpoints[index].blip then
                RemoveBlip(checkpoints[index].blip)
            end
            -- Remove o checkpoint 3D
            if checkpoints[index].checkpoint then
                DeleteCheckpoint(checkpoints[index].checkpoint)
            end
            table.remove(checkpoints, index)
            print("Checkpoint removido: ", index)
        end
    end
    
    -- Função para verificar se o jogador está próximo a um checkpoint
    local function isPlayerNearCheckpoint(playerPed, checkpoint)
        local playerCoords = GetEntityCoords(playerPed)
        local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, checkpoint.x, checkpoint.y, checkpoint.z)
        return distance < config.CHECKPOINT_PROXIMITY_THRESHOLD
    end
    
    -- Função para iniciar a corrida
    local function startRace()
        if #checkpoints < 2 then
            print("Você precisa de pelo menos 2 checkpoints para iniciar a corrida!")
            return
        end
    
        raceBuilding = false
        currentCheckpointIndex = 1
    
        -- Define o primeiro waypoint
        if checkpoints[currentCheckpointIndex] then
            SetNewWaypoint(checkpoints[currentCheckpointIndex].x, checkpoints[currentCheckpointIndex].y)
            print("Corrida iniciada! Primeiro checkpoint definido.")
        end
    end
    
    -- Função para resetar o estado da corrida
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
        print("Estado da corrida resetado. Pronto para criar uma nova corrida.")
    end
    
    -- Thread para adicionar checkpoints
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            -- Verifica se o jogador pressionou a tecla para adicionar um checkpoint
            if IsControlJustPressed(0, config.ADD_CHECKPOINT_KEY) then
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                addCheckpoint(playerCoords.x, playerCoords.y, playerCoords.z)
            end
        end
    end)
    
    -- Thread para acompanhar o progresso dos checkpoints
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(500)
    
            if raceBuilding then
                -- Não faz nada se a corrida ainda está sendo construída
                goto continue
            end
    
            local playerPed = PlayerPedId()
            local currentCheckpoint = checkpoints[currentCheckpointIndex]
    
            if currentCheckpoint and not currentCheckpoint.passed and isPlayerNearCheckpoint(playerPed, currentCheckpoint) then
                currentCheckpoint.passed = true -- Marca o checkpoint como passado
                currentCheckpointIndex = currentCheckpointIndex + 1 -- Avança para o próximo checkpoint
    
                if checkpoints[currentCheckpointIndex] then
                    -- Notifica o servidor e atualiza o waypoint
                    TriggerServerEvent('race:checkpointPassed', currentCheckpointIndex)
                    SetNewWaypoint(checkpoints[currentCheckpointIndex].x, checkpoints[currentCheckpointIndex].y)
                    print("Próximo checkpoint: ", checkpoints[currentCheckpointIndex].x, checkpoints[currentCheckpointIndex].y)
                else
                    print("Todos os checkpoints passados! Corrida concluída.")
                    resetRace() -- Reseta o estado da corrida para a próxima
                end
            end
    
            ::continue::
        end
    end)
    
    -- Evento para mostrar o próximo checkpoint (acionado pelo servidor)
    RegisterNetEvent('race:showNextCheckpoint')
    AddEventHandler('race:showNextCheckpoint', function(x, y)
        SetNewWaypoint(x, y)
        print("Próximo checkpoint definido para: ", x, y)
    end)
    
    -- Comando para iniciar a corrida
    RegisterCommand("startRace", function()
        startRace()
    end, false)
    
    -- Comando para resetar a corrida
    RegisterCommand("resetRace", function()
        resetRace()
    end, false)