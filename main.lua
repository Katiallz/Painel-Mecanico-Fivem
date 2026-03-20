-- ============================================
-- VRP PROXY (Creative Framework)
-- ============================================

local Proxy = module("vrp", "lib/Proxy")
local Tunnel = module("vrp", "lib/Tunnel")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

CreateThread(function()
    print('^3====================================================^0')
    print('^3  Painel Mecanica carregado com sucesso!^0')
    print('^3====================================================^0')
end)

local onlineMechanics = {}

-- ============================================
-- AUTO-CREATE TABLES
-- ============================================

CreateThread(function()
    -- Tabela de diagnósticos
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `ryze_mec_diagnostics` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `patient_passport` int(11) NOT NULL,
            `patient_name` varchar(100) NOT NULL DEFAULT '',
            `doctor_passport` int(11) NOT NULL,
            `doctor_name` varchar(100) NOT NULL DEFAULT '',
            `diagnosis` text NOT NULL,
            `treatment` text DEFAULT NULL,
            `status` varchar(20) NOT NULL DEFAULT 'Em tratamento',
            `permission` varchar(100) NOT NULL DEFAULT 'Paramedic01',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Tabela de consultas
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `ryze_mec_consultations` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `patient_passport` int(11) NOT NULL,
            `patient_name` varchar(100) NOT NULL DEFAULT '',
            `doctor_passport` int(11) DEFAULT NULL,
            `doctor_name` varchar(100) NOT NULL DEFAULT '',
            `specialty` varchar(100) NOT NULL,
            `scheduled_date` varchar(50) NOT NULL DEFAULT '',
            `notes` text DEFAULT NULL,
            `status` varchar(20) NOT NULL DEFAULT 'Agendada',
            `permission` varchar(100) NOT NULL DEFAULT 'Paramedic01',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Tabela de receitas / prescrições
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `ryze_mec_prescriptions` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `patient_passport` int(11) NOT NULL,
            `patient_name` varchar(100) NOT NULL DEFAULT '',
            `doctor_passport` int(11) NOT NULL,
            `doctor_name` varchar(100) NOT NULL DEFAULT '',
            `medication` text NOT NULL,
            `dosage` varchar(255) NOT NULL DEFAULT '',
            `notes` text DEFAULT NULL,
            `permission` varchar(100) NOT NULL DEFAULT 'Paramedic01',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Tabela de atendimentos / chamados
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `ryze_mec_attendances` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `patient_passport` int(11) NOT NULL,
            `patient_name` varchar(100) NOT NULL DEFAULT '',
            `doctor_passport` int(11) DEFAULT NULL,
            `doctor_name` varchar(100) NOT NULL DEFAULT '',
            `reason` text DEFAULT NULL,
            `location` varchar(255) NOT NULL DEFAULT '',
            `status` varchar(20) NOT NULL DEFAULT 'Pendente',
            `permission` varchar(100) NOT NULL DEFAULT 'Paramedic01',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            `completed_at` timestamp NULL DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Tabela de chat médico
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `ryze_mec_chat` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `passport` int(11) NOT NULL,
            `name` varchar(100) NOT NULL,
            `message` text NOT NULL,
            `permission` varchar(100) NOT NULL DEFAULT 'Paramedic01',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Tabela de planos de saúde
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `ryze_mec_healthplans` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `patient_passport` int(11) NOT NULL,
            `plan_type` varchar(50) NOT NULL DEFAULT 'Básico',
            `granted_by` int(11) NOT NULL,
            `granted_name` varchar(100) NOT NULL DEFAULT '',
            `active` tinyint(1) NOT NULL DEFAULT 1,
            `permission` varchar(100) NOT NULL DEFAULT 'Paramedic01',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    Wait(3000)
    -- Indexar médicos online
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src then
            local passport = GetPassport(src)
            local level = GetPlayerMechanicLevel(src)
            if passport and level then
                onlineMechanics[src] = {
                    passport = passport,
                    level = level,
                    name = GetCharacterName(src),
                }
            end
        end
    end
    print("^2[Painel_Mecanica]^0 Resource carregado com sucesso!")
end)

-- ============================================
-- UTILITÁRIOS
-- ============================================

function GetPassport(source)
    local user_id = vRP.getUserId(source)
    if user_id and user_id > 0 then
        return user_id
    end
    return nil
end

function GetCharacterName(source)
    local user_id = GetPassport(source)
    if not user_id then return "Desconhecido" end
    local result = MySQL.query.await("SELECT name, name2 FROM characters WHERE id = ?", { user_id })
    if result and result[1] then
        return (result[1].name or "") .. " " .. (result[1].name2 or "")
    end
    return "Desconhecido"
end

function GetCharacterNameByPassport(passport)
    local result = MySQL.query.await("SELECT name, name2 FROM characters WHERE id = ?", { passport })
    if result and result[1] then
        return (result[1].name or "") .. " " .. (result[1].name2 or "")
    end
    return "Desconhecido"
end

function GetPlayerMechanicLevel(source)
    local user_id = GetPassport(source)
    if not user_id then return nil end
    local uid = tostring(user_id)

    local result = MySQL.query.await(
        "SELECT dvalue FROM entitydata WHERE dkey = ?",
        { "Permissions:" .. Config.MechanicOrg }
    )

    if result and result[1] and result[1].dvalue then
        local perms = json.decode(result[1].dvalue)
        if perms then
            for id, level in pairs(perms) do
                if tostring(id) == uid then
                    return tonumber(level) or nil
                end
            end
        end
    end
    return nil
end

function HasPermission(level, perm)
    if level == 0 then return true end
    local maxLevel = Config.Permissions[perm]
    if not maxLevel then return false end
    return level <= maxLevel
end

function GetRoleLabel(level)
    return Config.Roles[level] or Config.Roles[0] or "Desconhecido"
end

function GetBloodTypeLabel(blood)
    return Config.BloodTypes[blood] or "Desconhecido"
end

function FormatTimestamp(ts)
    if not ts or ts == 0 then return "Nunca" end
    return os.date("%d/%m/%Y %H:%M", ts)
end

function FormatMoney(value)
    local formatted = tostring(value)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return "R$ " .. formatted
end

function GenerateRegistration(passport)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local reg = ""
    math.randomseed(passport * 7919)
    for i = 1, 3 do
        local idx = math.random(1, #chars)
        reg = reg .. chars:sub(idx, idx)
    end
    return tostring(os.date("%y", os.time())) .. reg .. tostring(passport)
end

-- ============================================
-- PLAYER CONNECT/DISCONNECT TRACKING
-- ============================================

AddEventHandler("playerDropped", function()
    local src = source
    onlineMechanics[src] = nil
end)

RegisterNetEvent("Painel_Mecanica:server:registerOnline", function()
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    if passport and level then
        onlineMechanics[src] = {
            passport = passport,
            level = level,
            name = GetCharacterName(src),
        }
    end
end)

-- ============================================
-- GET DATA (DASHBOARD)
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:getData", function()
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)

    if not passport or level == nil then
        TriggerClientEvent("Painel_Mecanica:client:receiveData", src, { error = "Sem permissão. Você não é médico." })
        return
    end

    local org = Config.MechanicOrg
    local myName = GetCharacterName(src)

    -- Estatísticas
    local diagCount = MySQL.scalar.await("SELECT COUNT(*) FROM ryze_mec_diagnostics WHERE permission = ?", { org }) or 0
    local consultCount = MySQL.scalar.await("SELECT COUNT(*) FROM ryze_mec_consultations WHERE permission = ?", { org }) or 0
    local attendCount = MySQL.scalar.await("SELECT COUNT(*) FROM ryze_mec_attendances WHERE permission = ? AND status = 'Concluído'", { org }) or 0
    local pendingCount = MySQL.scalar.await("SELECT COUNT(*) FROM ryze_mec_attendances WHERE permission = ? AND status IN ('Pendente', 'Em andamento')", { org }) or 0

    -- Últimos diagnósticos
    local recentDiags = MySQL.query.await(
        "SELECT id, patient_name, doctor_name, diagnosis, status, created_at FROM ryze_mec_diagnostics WHERE permission = ? ORDER BY created_at DESC LIMIT 5",
        { org }
    ) or {}

    -- Atendimentos pendentes
    local pendingAttendances = MySQL.query.await(
        "SELECT * FROM ryze_mec_attendances WHERE permission = ? AND status IN ('Pendente', 'Em andamento') ORDER BY created_at ASC LIMIT 10",
        { org }
    ) or {}

    -- Chat
    local chatMessages = MySQL.query.await(
        "SELECT * FROM ryze_mec_chat WHERE permission = ? ORDER BY id DESC LIMIT 50",
        { org }
    ) or {}
    -- Reverter ordem para mais antigo primeiro
    local reversedChat = {}
    for i = #chatMessages, 1, -1 do
        table.insert(reversedChat, chatMessages[i])
    end

    -- Médicos (todos da organização)
    local medics = GetAllMedics()

    -- Contar médicos online
    local medicCount = 0
    for _ in pairs(onlineMechanics) do
        medicCount = medicCount + 1
    end

    local data = {
        myPassport = passport,
        myName = myName,
        myLevel = level,
        myRole = GetRoleLabel(level),
        stats = {
            diagnostics = diagCount,
            consultations = consultCount,
            attendances = attendCount,
            medicsOnline = medicCount,
            pending = pendingCount,
        },
        recentDiags = recentDiags,
        pendingAttendances = pendingAttendances,
        chat = reversedChat,
        medics = medics,
        specialties = Config.Specialties,
        permissions = Config.Permissions,
        roles = Config.Roles,
    }

    TriggerClientEvent("Painel_Mecanica:client:receiveData", src, data)
end)

-- ============================================
-- GET ALL MEDICS
-- ============================================

function GetAllMedics()
    local org = Config.MechanicOrg
    local result = MySQL.query.await(
        "SELECT dvalue FROM entitydata WHERE dkey = ?",
        { "Permissions:" .. org }
    )

    if result and result[1] and result[1].dvalue then
        local perms = json.decode(result[1].dvalue)
        if perms then
            local medics = {}
            for id, level in pairs(perms) do
                local passportId = tonumber(id)
                if passportId then
                    level = tonumber(level)
                    local char = MySQL.query.await(
                        "SELECT name, name2, lastlogin FROM characters WHERE id = ? AND deleted = 0",
                        { passportId }
                    )
                    local name = "Desconhecido"
                    local lastloginTs = 0
                    if char and char[1] then
                        name = (char[1].name or "") .. " " .. (char[1].name2 or "")
                        lastloginTs = char[1].lastlogin or 0
                    end

                    -- Verificar se está online
                    local isOnline = false
                    for _, pData in pairs(onlineMechanics) do
                        if pData.passport == passportId then
                            isOnline = true
                            break
                        end
                    end
                    if not isOnline then
                        for _, playerId in ipairs(GetPlayers()) do
                            local psrc = tonumber(playerId)
                            if psrc then
                                local pp = GetPassport(psrc)
                                if pp == passportId then isOnline = true; break end
                            end
                        end
                    end

                    local status = isOnline and "online" or "offline"

                    table.insert(medics, {
                        passport = passportId,
                        name = name,
                        level = level,
                        role = GetRoleLabel(level),
                        online = isOnline,
                        status = status,
                        lastlogin = lastloginTs,
                        lastlogin_formatted = FormatTimestamp(lastloginTs),
                    })
                end
            end
            table.sort(medics, function(a, b) return a.level < b.level end)
            return medics
        end
    end
    return {}
end

-- ============================================
-- SEARCH PATIENT
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:searchPatient", function(searchPassport)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)

    if not passport or level == nil then return end
    if not HasPermission(level, "search") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão para pesquisar.")
        return
    end

    searchPassport = tonumber(searchPassport)
    if not searchPassport then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "ID inválido.")
        return
    end

    local org = Config.MechanicOrg

    -- Dados do paciente
    local charResult = MySQL.query.await(
        "SELECT * FROM characters WHERE id = ? AND deleted = 0",
        { searchPassport }
    )
    if not charResult or not charResult[1] then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Paciente não encontrado.")
        return
    end

    local char = charResult[1]
    local patientName = (char.name or "") .. " " .. (char.name2 or "")

    -- Histórico de diagnósticos
    local diagnostics = MySQL.query.await(
        "SELECT * FROM ryze_mec_diagnostics WHERE patient_passport = ? ORDER BY created_at DESC LIMIT 20",
        { searchPassport }
    ) or {}

    -- Histórico de consultas
    local consultations = MySQL.query.await(
        "SELECT * FROM ryze_mec_consultations WHERE patient_passport = ? ORDER BY created_at DESC LIMIT 20",
        { searchPassport }
    ) or {}

    -- Receitas
    local prescriptions = MySQL.query.await(
        "SELECT * FROM ryze_mec_prescriptions WHERE patient_passport = ? ORDER BY created_at DESC LIMIT 20",
        { searchPassport }
    ) or {}

    -- Plano de saúde ativo
    local healthplan = MySQL.query.await(
        "SELECT * FROM ryze_mec_healthplans WHERE patient_passport = ? AND active = 1 LIMIT 1",
        { searchPassport }
    ) or {}

    -- Online?
    local isOnline = false
    for _, playerId in ipairs(GetPlayers()) do
        local psrc = tonumber(playerId)
        if psrc then
            local pp = GetPassport(psrc)
            if pp == searchPassport then
                isOnline = true
                break
            end
        end
    end

    local patientData = {
        passport = searchPassport,
        name = patientName,
        sex = char.sex or "M",
        age = char.age or 20,
        phone = char.phone or "N/A",
        blood = char.blood or 1,
        bloodLabel = GetBloodTypeLabel(char.blood or 1),
        registration = GenerateRegistration(searchPassport),
        online = isOnline,
        linked_image = char.linked_image or "",
        healthplan = healthplan,
        diagnostics = diagnostics,
        consultations = consultations,
        prescriptions = prescriptions,
    }

    TriggerClientEvent("Painel_Mecanica:client:receiveSearch", src, patientData)
end)

-- ============================================
-- DIAGNÓSTICOS
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:createDiagnostic", function(data)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "diagnose") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão.")
        return
    end

    local patientPassport = tonumber(data.patient_passport)
    if not patientPassport or not data.diagnosis or data.diagnosis == "" then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Dados inválidos.")
        return
    end

    local patientName = GetCharacterNameByPassport(patientPassport)
    local doctorName = GetCharacterName(src)

    MySQL.insert.await(
        "INSERT INTO ryze_mec_diagnostics (patient_passport, patient_name, doctor_passport, doctor_name, diagnosis, treatment, permission) VALUES (?, ?, ?, ?, ?, ?, ?)",
        { patientPassport, patientName, passport, doctorName, data.diagnosis, data.treatment or "", org }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Diagnóstico registrado com sucesso!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)

RegisterNetEvent("Painel_Mecanica:server:updateDiagnostic", function(diagId, newStatus)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)

    if not passport or level == nil then return end
    if not HasPermission(level, "diagnose") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão.")
        return
    end

    diagId = tonumber(diagId)
    if not diagId or not newStatus then return end

    MySQL.update.await(
        "UPDATE ryze_mec_diagnostics SET status = ? WHERE id = ?",
        { newStatus, diagId }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Status do diagnóstico atualizado!")
end)

-- ============================================
-- CONSULTAS
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:getConsultations", function()
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end

    local consultations = MySQL.query.await(
        "SELECT * FROM ryze_mec_consultations WHERE permission = ? ORDER BY created_at DESC LIMIT 50",
        { org }
    ) or {}

    TriggerClientEvent("Painel_Mecanica:client:receiveConsultations", src, consultations)
end)

RegisterNetEvent("Painel_Mecanica:server:createConsultation", function(data)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "consult") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão.")
        return
    end

    local patientPassport = tonumber(data.patient_passport)
    if not patientPassport or not data.specialty or data.specialty == "" then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Dados inválidos.")
        return
    end

    local patientName = GetCharacterNameByPassport(patientPassport)
    local doctorName = GetCharacterName(src)

    MySQL.insert.await(
        "INSERT INTO ryze_mec_consultations (patient_passport, patient_name, doctor_passport, doctor_name, specialty, scheduled_date, notes, permission) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        { patientPassport, patientName, passport, doctorName, data.specialty, data.scheduled_date or "", data.notes or "", org }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Consulta agendada com sucesso!")
    TriggerServerEvent("Painel_Mecanica:server:getConsultations")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)

RegisterNetEvent("Painel_Mecanica:server:updateConsultation", function(consultId, newStatus)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)

    if not passport or level == nil then return end
    if not HasPermission(level, "consult") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão.")
        return
    end

    consultId = tonumber(consultId)
    if not consultId or not newStatus then return end

    MySQL.update.await(
        "UPDATE ryze_mec_consultations SET status = ? WHERE id = ?",
        { newStatus, consultId }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Consulta atualizada!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)

-- ============================================
-- RECEITAS / PRESCRIÇÕES
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:createPrescription", function(data)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "prescribe") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão.")
        return
    end

    local patientPassport = tonumber(data.patient_passport)
    if not patientPassport or not data.medication or data.medication == "" then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Dados inválidos.")
        return
    end

    local patientName = GetCharacterNameByPassport(patientPassport)
    local doctorName = GetCharacterName(src)

    MySQL.insert.await(
        "INSERT INTO ryze_mec_prescriptions (patient_passport, patient_name, doctor_passport, doctor_name, medication, dosage, notes, permission) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        { patientPassport, patientName, passport, doctorName, data.medication, data.dosage or "", data.notes or "", org }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Receita criada com sucesso!")
end)

-- ============================================
-- ATENDIMENTOS / CHAMADOS
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:getAttendances", function()
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end

    local attendances = MySQL.query.await(
        "SELECT * FROM ryze_mec_attendances WHERE permission = ? ORDER BY FIELD(status, 'Pendente', 'Em andamento', 'Concluído'), created_at DESC LIMIT 50",
        { org }
    ) or {}

    TriggerClientEvent("Painel_Mecanica:client:receiveAttendances", src, attendances)
end)

RegisterNetEvent("Painel_Mecanica:server:createAttendance", function(data)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end

    local patientPassport = tonumber(data.patient_passport)
    if not patientPassport then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Passaporte inválido.")
        return
    end

    local patientName = GetCharacterNameByPassport(patientPassport)

    MySQL.insert.await(
        "INSERT INTO ryze_mec_attendances (patient_passport, patient_name, reason, location, permission) VALUES (?, ?, ?, ?, ?)",
        { patientPassport, patientName, data.reason or "Não especificado", data.location or "Não informada", org }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Chamado criado com sucesso!")

    -- Notificar todos os médicos online
    for mechanicsSrc, _ in pairs(onlineMechanics) do
        TriggerClientEvent("Painel_Mecanica:client:notify", mechanicsSrc, "🚨 Novo chamado de atendimento!")
    end
end)

RegisterNetEvent("Painel_Mecanica:server:claimAttendance", function(attendId)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)

    if not passport or level == nil then return end

    attendId = tonumber(attendId)
    if not attendId then return end

    local doctorName = GetCharacterName(src)

    MySQL.update.await(
        "UPDATE ryze_mec_attendances SET status = 'Em andamento', doctor_passport = ?, doctor_name = ? WHERE id = ? AND status = 'Pendente'",
        { passport, doctorName, attendId }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Atendimento assumido!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)

RegisterNetEvent("Painel_Mecanica:server:completeAttendance", function(attendId)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)

    if not passport or level == nil then return end

    attendId = tonumber(attendId)
    if not attendId then return end

    MySQL.update.await(
        "UPDATE ryze_mec_attendances SET status = 'Concluído', completed_at = NOW() WHERE id = ?",
        { attendId }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Atendimento concluído!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)

-- ============================================
-- PLANO DE SAÚDE
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:grantHealthPlan", function(patientPassport, planType)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "healthplan") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão.")
        return
    end

    patientPassport = tonumber(patientPassport)
    if not patientPassport or not planType then return end

    -- Cobrar o paciente pelo plano de saúde
    local planPrice = Config.HealthPlanPrices and Config.HealthPlanPrices[planType] or 0
    if planPrice > 0 then
        local paid = vRP.PaymentFull(patientPassport, planPrice)
        if not paid then
            TriggerClientEvent("Painel_Mecanica:client:notify", src, "Paciente não possui dinheiro suficiente (R$" .. planPrice .. ").")
            return
        end

        -- Registrar no extrato bancário
        pcall(function()
            exports["Banco_Briann1k_"]:LogSubscription(patientPassport, planPrice, "Plano de Saúde " .. planType)
        end)
    end

    -- Desativar planos anteriores
    MySQL.update.await(
        "UPDATE ryze_mec_healthplans SET active = 0 WHERE patient_passport = ? AND permission = ?",
        { patientPassport, org }
    )

    local doctorName = GetCharacterName(src)

    MySQL.insert.await(
        "INSERT INTO ryze_mec_healthplans (patient_passport, plan_type, granted_by, granted_name, permission) VALUES (?, ?, ?, ?, ?)",
        { patientPassport, planType, passport, doctorName, org }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Plano de saúde '" .. planType .. "' concedido!")
end)

RegisterNetEvent("Painel_Mecanica:server:removeHealthPlan", function(patientPassport)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "healthplan") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão.")
        return
    end

    patientPassport = tonumber(patientPassport)
    if not patientPassport then return end

    MySQL.update.await(
        "UPDATE ryze_mec_healthplans SET active = 0 WHERE patient_passport = ? AND permission = ?",
        { patientPassport, org }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Plano de saúde removido!")
end)

-- ============================================
-- CHAT MÉDICO
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:sendChat", function(message)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "chat") then return end

    if not message or message == "" or #message > 500 then return end

    local name = GetCharacterName(src)

    MySQL.insert.await(
        "INSERT INTO ryze_mec_chat (passport, name, message, permission) VALUES (?, ?, ?, ?)",
        { passport, name, message, org }
    )

    local chatMsg = {
        passport = passport,
        name = name,
        message = message,
        created_at = os.date("%Y-%m-%d %H:%M:%S"),
    }

    -- Enviar para todos os médicos online
    for mechanicSrc, _ in pairs(onlineMechanics) do
        TriggerClientEvent("Painel_Mecanica:client:receiveChat", mechanicSrc, chatMsg)
    end
end)

-- ============================================
-- GERENCIAMENTO DE STAFF
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:hireMedic", function(targetPassport)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "hire") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão.")
        return
    end

    targetPassport = tonumber(targetPassport)
    if not targetPassport then return end

    -- Verificar se o cidadão existe
    local charResult = MySQL.query.await("SELECT id FROM characters WHERE id = ? AND deleted = 0", { targetPassport })
    if not charResult or not charResult[1] then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Cidadão não encontrado.")
        return
    end

    -- Verificar se já é médico
    local currentLevel = nil
    local permResult = MySQL.query.await("SELECT dvalue FROM entitydata WHERE dkey = ?", { "Permissions:" .. org })
    local perms = {}
    if permResult and permResult[1] and permResult[1].dvalue then
        perms = json.decode(permResult[1].dvalue) or {}
    end

    if perms[tostring(targetPassport)] then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Este cidadão já faz parte do hospital.")
        return
    end

    -- Adicionar com nível padrão
    vRP.SetPermission(targetPassport, org, Config.DefaultHireLevel)

    local targetName = GetCharacterNameByPassport(targetPassport)
    TriggerClientEvent("Painel_Mecanica:client:notify", src, targetName .. " contratado(a) como " .. GetRoleLabel(Config.DefaultHireLevel) .. "!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)

RegisterNetEvent("Painel_Mecanica:server:fireMedic", function(targetPassport)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "fire") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão.")
        return
    end

    targetPassport = tonumber(targetPassport)
    if not targetPassport then return end

    if targetPassport == passport then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Você não pode se demitir.")
        return
    end

    local permResult = MySQL.query.await("SELECT dvalue FROM entitydata WHERE dkey = ?", { "Permissions:" .. org })
    if not permResult or not permResult[1] then return end

    local perms = json.decode(permResult[1].dvalue) or {}
    local targetLevel = perms[tostring(targetPassport)]
    if not targetLevel then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Este cidadão não faz parte do hospital.")
        return
    end

    -- Não pode demitir alguém de cargo igual ou superior
    if tonumber(targetLevel) <= level and level ~= 0 then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Não pode demitir alguém de cargo igual ou superior.")
        return
    end

    vRP._RemovePermission(targetPassport, org)

    local targetName = GetCharacterNameByPassport(targetPassport)
    TriggerClientEvent("Painel_Mecanica:client:notify", src, targetName .. " foi demitido(a)!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)

RegisterNetEvent("Painel_Mecanica:server:setMedicLevel", function(targetPassport, newLevel)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "manage_staff") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão.")
        return
    end

    targetPassport = tonumber(targetPassport)
    newLevel = tonumber(newLevel)
    if not targetPassport or not newLevel then return end

    -- Não pode promover acima do próprio nível
    if newLevel < level and level ~= 0 then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Não pode promover acima do seu cargo.")
        return
    end

    local permResult = MySQL.query.await("SELECT dvalue FROM entitydata WHERE dkey = ?", { "Permissions:" .. org })
    if not permResult or not permResult[1] then return end

    local perms = json.decode(permResult[1].dvalue) or {}
    if not perms[tostring(targetPassport)] then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Este cidadão não faz parte do hospital.")
        return
    end

    vRP.SetPermission(targetPassport, org, newLevel)

    local targetName = GetCharacterNameByPassport(targetPassport)
    TriggerClientEvent("Painel_Mecanica:client:notify", src, targetName .. " agora é " .. GetRoleLabel(newLevel) .. "!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)

-- Salvar foto de um paciente pesquisado (via câmera do celular)
RegisterNetEvent("Painel_Mecanica:server:saveCitizenPhoto", function(targetPassport, base64)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    if not passport or level == nil then return end

    targetPassport = tonumber(targetPassport)
    if not targetPassport then return end

    if type(base64) ~= "string" or #base64 < 100 or #base64 > 500000 then return end

    pcall(function()
        MySQL.update.await("ALTER TABLE characters MODIFY COLUMN linked_image LONGTEXT")
    end)

    MySQL.update.await("UPDATE characters SET linked_image = ? WHERE id = ?", { base64, targetPassport })
end)

-- ============================================
-- LIST DIAGNOSTICS (for diagnostics page)
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:getDiagnostics", function()
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end

    local diagnostics = MySQL.query.await(
        "SELECT * FROM ryze_mec_diagnostics WHERE permission = ? ORDER BY created_at DESC LIMIT 50",
        { org }
    ) or {}

    TriggerClientEvent("Painel_Mecanica:client:receiveDiagnostics", src, diagnostics)
end)
