local isOpen = false

-- ============================================
-- ABRIR/FECHAR PAINEL
-- ============================================

local function OpenPanel()
    if isOpen then return end
    isOpen = true
    TriggerEvent("dynamic:closeSystem")
    SetNuiFocus(true, true)
    TriggerServerEvent("Painel_Mecanica:server:getData")
    TriggerServerEvent("Painel_Mecanica:server:registerOnline")
end

local function ClosePanel()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

-- ============================================
-- COMANDO
-- ============================================

RegisterCommand(Config.Command, function()
    if isOpen then
        ClosePanel()
    else
        OpenPanel()
    end
end, false)

-- ============================================
-- EVENTO EXTERNO (Dynamic, etc.)
-- ============================================

RegisterNetEvent("Painel_Mecanica:client:OpenPanel", function()
    if isOpen then ClosePanel() else OpenPanel() end
end)

-- ============================================
-- RECEBER DADOS
-- ============================================

RegisterNetEvent("Painel_Mecanica:client:receiveData", function(data)
    if data.error then
        SetNuiFocus(false, false)
        isOpen = false
        TriggerEvent("creative_notify:SendAlert", "error", data.error)
        return
    end
    SendNUIMessage({ action = "open", data = data })
end)

RegisterNetEvent("Painel_Mecanica:client:refreshData", function()
    if isOpen then
        TriggerServerEvent("Painel_Mecanica:server:getData")
    end
end)

RegisterNetEvent("Painel_Mecanica:client:notify", function(message)
    SendNUIMessage({ action = "notification", message = message })
    TriggerEvent("creative_notify:SendAlert", "info", message)
end)

RegisterNetEvent("Painel_Mecanica:client:viewBudget", function(data)
    SendNUIMessage({ action = "viewBudget", data = data })
    SetNuiFocus(true, true)
    isOpen = true -- Considerar como aberto para poder fechar
end)

RegisterNetEvent("Painel_Mecanica:client:receiveSearch", function(data)
    SendNUIMessage({ action = "receiveSearch", data = data })
end)

RegisterNetEvent("Painel_Mecanica:client:receiveChat", function(msg)
    SendNUIMessage({ action = "receiveChat", data = msg })
end)

RegisterNetEvent("Painel_Mecanica:client:receiveConsultations", function(data)
    SendNUIMessage({ action = "receiveConsultations", data = data })
end)

RegisterNetEvent("Painel_Mecanica:client:receiveAttendances", function(data)
    SendNUIMessage({ action = "receiveAttendances", data = data })
end)

RegisterNetEvent("Painel_Mecanica:client:receiveDiagnostics", function(data)
    SendNUIMessage({ action = "receiveDiagnostics", data = data })
end)

-- ============================================
-- NUI CALLBACKS
-- ============================================

RegisterNUICallback("close", function(_, cb)
    ClosePanel()
    cb("ok")
end)

RegisterNUICallback("searchPatient", function(data, cb)
    local passport = tonumber(data.passport)
    if passport then
        TriggerServerEvent("Painel_Mecanica:server:searchPatient", passport)
    end
    cb("ok")
end)

RegisterNUICallback("createDiagnostic", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:createDiagnostic", data)
    cb("ok")
end)

RegisterNUICallback("updateDiagnostic", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:updateDiagnostic", data.id, data.status)
    cb("ok")
end)

RegisterNUICallback("createConsultation", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:createConsultation", data)
    cb("ok")
end)

RegisterNUICallback("updateConsultation", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:updateConsultation", data.id, data.status)
    cb("ok")
end)

RegisterNUICallback("createPrescription", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:createPrescription", data)
    cb("ok")
end)

RegisterNUICallback("createAttendance", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:createAttendance", data)
    cb("ok")
end)

RegisterNUICallback("claimAttendance", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:claimAttendance", data.id)
    cb("ok")
end)

RegisterNUICallback("completeAttendance", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:completeAttendance", data.id)
    cb("ok")
end)

RegisterNUICallback("grantHealthPlan", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:grantHealthPlan", data.passport, data.plan_type)
    cb("ok")
end)

RegisterNUICallback("removeHealthPlan", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:removeHealthPlan", data.passport)
    cb("ok")
end)

RegisterNUICallback("sendChat", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:sendChat", data.message)
    cb("ok")
end)

RegisterNUICallback("hireMechanic", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:hireMechanic", data.passport)
    cb("ok")
end)

RegisterNUICallback("fireMechanic", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:fireMechanic", data.passport)
    cb("ok")
end)

RegisterNUICallback("setMechanicLevel", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:setMechanicLevel", data.passport, data.level)
    cb("ok")
end)

RegisterNUICallback("getConsultations", function(_, cb)
    TriggerServerEvent("Painel_Mecanica:server:getConsultations")
    cb("ok")
end)

RegisterNUICallback("getAttendances", function(_, cb)
    TriggerServerEvent("Painel_Mecanica:server:getAttendances")
    cb("ok")
end)

RegisterNUICallback("getDiagnostics", function(_, cb)
    TriggerServerEvent("Painel_Mecanica:server:getDiagnostics")
    cb("ok")
end)

RegisterNUICallback("refreshData", function(_, cb)
    TriggerServerEvent("Painel_Mecanica:server:getData")
    cb("ok")
end)

RegisterNetEvent("Painel_Mecanica:client:receiveBankData", function(data)
    SendNUIMessage({ action = "receiveBankData", data = data })
end)

RegisterNUICallback("getBankData", function(_, cb)
    TriggerServerEvent("Painel_Mecanica:server:getBankData")
    cb("ok")
end)

RegisterNUICallback("depositBank", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:depositBank", data.amount)
    cb("ok")
end)

RegisterNUICallback("withdrawBank", function(data, cb)
    TriggerServerEvent("Painel_Mecanica:server:withdrawBank", data.amount)
    cb("ok")
end)

-- ============================================
-- CÂMERA DO CELULAR PARA FOTO 3x4
-- ============================================

local function CellFrontCamActivate(activate)
    return Citizen.InvokeNative(0x2491A93618B7D838, activate)
end

local cameraActive = false

RegisterNUICallback("openCamera", function(data, cb)
    cb("ok")
    if cameraActive then return end
    cameraActive = true

    local targetPassport = data.passport

    -- Fechar painel temporariamente
    SendNUIMessage({ action = "close" })
    SetNuiFocus(false, false)

    Wait(300)

    -- Abrir câmera do celular
    CreateMobilePhone(10)
    CellCamActivate(true, true)
    CellFrontCamActivate(true)

    local frontCam = true

    CreateThread(function()
        while cameraActive do
            -- Instruções na tela
            SetTextFont(4)
            SetTextScale(0.50, 0.50)
            SetTextColour(255, 255, 255, 200)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString("PRESSIONE  ~b~E~w~  PARA  TIRAR  A  FOTO")
            DrawText(0.5, 0.91)

            SetTextFont(4)
            SetTextScale(0.42, 0.42)
            SetTextColour(186, 186, 186, 200)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString("~g~R~w~ = CANCELAR  |  ~b~Q~w~ = TROCAR CAMERA (FRENTE/TRAS)")
            DrawText(0.5, 0.95)

            -- E = tirar foto
            if IsControlJustPressed(0, 38) then
                exports['screenshot-basic']:requestScreenshot({
                    encoding = 'jpg',
                    quality = 0.7
                }, function(photoData)
                    if photoData and type(photoData) == "string" and #photoData > 100 then
                        TriggerServerEvent("Painel_Mecanica:server:saveCitizenPhoto", targetPassport, photoData)
                        TriggerEvent("creative_notify:SendAlert", "success", "Foto salva com sucesso!")
                    end
                end)

                Wait(500)
                DestroyMobilePhone()
                CellCamActivate(false, false)
                cameraActive = false

                -- Reabrir painel
                isOpen = false
                OpenPanel()
                break
            end

            -- R = cancelar
            if IsControlJustPressed(0, 45) then
                DestroyMobilePhone()
                CellCamActivate(false, false)
                cameraActive = false

                Wait(300)
                isOpen = false
                OpenPanel()
                break
            end

            -- Q = trocar câmera frontal/traseira
            if IsControlJustPressed(0, 44) then
                frontCam = not frontCam
                CellFrontCamActivate(frontCam)
            end

            Wait(4)
        end
    end)
end)
