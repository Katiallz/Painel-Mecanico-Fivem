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
    -- Tabela de atendimentos / chamados
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `ryze_mec_attendances` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `client_passport` int(11) NOT NULL,
            `client_name` varchar(100) NOT NULL DEFAULT '',
            `mechanic_passport` int(11) DEFAULT NULL,
            `mechanic_name` varchar(100) NOT NULL DEFAULT '',
            `reason` text DEFAULT NULL,
            `location` varchar(255) NOT NULL DEFAULT '',
            `status` varchar(20) NOT NULL DEFAULT 'Pendente',
            `permission` varchar(100) NOT NULL DEFAULT 'Mechanic01',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            `completed_at` timestamp NULL DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Tabela de chat 
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `ryze_mec_chat` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `passport` int(11) NOT NULL,
            `name` varchar(100) NOT NULL,
            `message` text NOT NULL,
            `permission` varchar(100) NOT NULL DEFAULT 'Mechanic01',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Tabela de serviços (Vendas e Serviços)
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `ryze_mec_diagnostics` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `client_passport` int(11) NOT NULL,
            `client_name` varchar(100) NOT NULL DEFAULT '',
            `mechanic_passport` int(11) DEFAULT NULL,
            `mechanic_name` varchar(100) NOT NULL DEFAULT '',
            `diagnosis` text NOT NULL,
            `treatment` text DEFAULT NULL,
            `status` varchar(50) NOT NULL DEFAULT 'Concluído',
            `permission` varchar(100) NOT NULL DEFAULT 'Mechanic01',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Tabela de pedidos extras (antigas receitas)
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `ryze_mec_prescriptions` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `client_passport` int(11) NOT NULL,
            `client_name` varchar(100) NOT NULL DEFAULT '',
            `mechanic_passport` int(11) DEFAULT NULL,
            `mechanic_name` varchar(100) NOT NULL DEFAULT '',
            `medication` varchar(100) NOT NULL,
            `dosage` varchar(100) DEFAULT NULL,
            `notes` text DEFAULT NULL,
            `permission` varchar(100) NOT NULL DEFAULT 'Mechanic01',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Tabela de bancos das empresas (Caso a base não tenha)
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `panel` (
            `name` varchar(50) NOT NULL,
            `bank` int(11) NOT NULL DEFAULT 0,
            `buff` int(11) NOT NULL DEFAULT 0,
            `premium` int(11) NOT NULL DEFAULT 0,
            PRIMARY KEY (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Insere Mechanic01 se não existir
    MySQL.update.await("INSERT IGNORE INTO `panel` (`name`, `bank`) VALUES (?, 0)", { Config.MechanicOrg })

    -- Tabela de transações de log
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS `paneltransactions` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `name` varchar(50) NOT NULL,
            `Type` varchar(255) NOT NULL,
            `Value` int(11) NOT NULL DEFAULT 0,
            `date` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`),
            KEY `name` (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Garante que o Type suporta textos longos de log caso a base já existisse
    pcall(function()
        MySQL.update.await("ALTER TABLE `paneltransactions` MODIFY COLUMN `Type` VARCHAR(255)")
    end)

    Wait(3000)
    -- Indexar mecanicos online
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
    print("^2[Painel_Mecanica]^0 Sistema de mecânica carregado!")
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
        TriggerClientEvent("Painel_Mecanica:client:receiveData", src, { error = "Sem permissão. Você não é mecânico." })
        return
    end

    local org = Config.MechanicOrg
    local myName = GetCharacterName(src)

    -- Estatísticas
    local diagCount = MySQL.scalar.await("SELECT COUNT(*) FROM ryze_mec_diagnostics WHERE permission = ?", { org }) or 0
    local attendCount = MySQL.scalar.await("SELECT COUNT(*) FROM ryze_mec_attendances WHERE permission = ? AND status = 'Concluído'", { org }) or 0
    local pendingCount = MySQL.scalar.await("SELECT COUNT(*) FROM ryze_mec_attendances WHERE permission = ? AND status IN ('Pendente', 'Em andamento')", { org }) or 0

    -- Últimos diagnósticos
    local recentDiags = MySQL.query.await(
        "SELECT * FROM ryze_mec_diagnostics WHERE permission = ? ORDER BY created_at DESC LIMIT 10",
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

    -- Mecanico (todos da organização)
    local mechanics = GetAllMechanics()

    -- Contar mecanicos online
    local mechanicCount = 0
    for _ in pairs(onlineMechanics) do
        mechanicCount = mechanicCount + 1
    end

    local data = {
        myPassport = passport,
        myName = myName,
        myLevel = level,
        myRole = GetRoleLabel(level),
        stats = {
            diagnostics = diagCount,
            attendances = attendCount,
            mechanicsOnline = mechanicCount,
            pending = pendingCount,
        },
        recentDiags = recentDiags,
        pendingAttendances = pendingAttendances,
        chat = reversedChat,
        mechanics = mechanics,
        specialties = Config.Specialties,
        permissions = Config.Permissions,
        roles = Config.Roles,
    }

    TriggerClientEvent("Painel_Mecanica:client:receiveData", src, data)
end)

-- ============================================
-- GET ALL mecanicos
-- ============================================

function GetAllMechanics()
    local org = Config.MechanicOrg
    local result = MySQL.query.await(
        "SELECT dvalue FROM entitydata WHERE dkey = ?",
        { "Permissions:" .. org }
    )

    if result and result[1] and result[1].dvalue then
        local perms = json.decode(result[1].dvalue)
        if perms then
            local mechanics = {}
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

                    table.insert(mechanics, {
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
            table.sort(mechanics, function(a, b) return a.level < b.level end)
            return mechanics
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

    -- Dados do cliente
    local charResult = MySQL.query.await(
        "SELECT * FROM characters WHERE id = ? AND deleted = 0",
        { searchPassport }
    )
    if not charResult or not charResult[1] then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Cliente não encontrado.")
        return
    end

    local char = charResult[1]
    local clientName = (char.name or "") .. " " .. (char.name2 or "")

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

    -- Histórico
    local diagnostics = MySQL.query.await(
        "SELECT * FROM ryze_mec_diagnostics WHERE client_passport = ? ORDER BY created_at DESC LIMIT 20",
        { searchPassport }
    ) or {}

    local prescriptions = MySQL.query.await(
        "SELECT * FROM ryze_mec_prescriptions WHERE client_passport = ? ORDER BY created_at DESC LIMIT 20",
        { searchPassport }
    ) or {}

    local healthplan = {} -- Mecânica não usa plano de saúde ativamente

    local patientData = {
        passport = searchPassport,
        name = clientName,
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
        prescriptions = prescriptions,
    }

    TriggerClientEvent("Painel_Mecanica:client:receiveSearch", src, patientData)
end)

-- ============================================
-- VENDAS E SERVIÇOS (DIAGNÓSTICOS)
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:getDiagnostics", function()
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end

    local diagnostics = MySQL.query.await(
        "SELECT * FROM ryze_mec_diagnostics WHERE permission = ? ORDER BY created_at DESC LIMIT 100",
        { org }
    ) or {}

    TriggerClientEvent("Painel_Mecanica:client:receiveDiagnostics", src, diagnostics)
end)

RegisterNetEvent("Painel_Mecanica:server:createDiagnostic", function(data)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "diagnose") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão para registrar serviço.")
        return
    end

    local clientPassport = tonumber(data.patient_passport)
    if not clientPassport then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Passaporte inválido.")
        return
    end

    local clientName = GetCharacterNameByPassport(clientPassport)
    local mechanicName = GetCharacterName(src)

    MySQL.insert.await(
        "INSERT INTO ryze_mec_diagnostics (client_passport, client_name, mechanic_passport, mechanic_name, diagnosis, treatment, status, permission) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        { clientPassport, clientName, passport, mechanicName, data.diagnosis, data.treatment or "", "Concluído", org }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Serviço registrado com sucesso!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)

RegisterNetEvent("Painel_Mecanica:server:updateDiagnostic", function(diagId, status)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)

    if not passport or level == nil then return end

    diagId = tonumber(diagId)
    if not diagId then return end

    MySQL.update.await(
        "UPDATE ryze_mec_diagnostics SET status = ? WHERE id = ?",
        { status, diagId }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Status atualizado!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)


-- ============================================
-- PEDIDOS DE PEÇAS / EXTRAS (RECEITAS)
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:getPrescriptions", function()
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end

    local prescriptions = MySQL.query.await(
        "SELECT * FROM ryze_mec_prescriptions WHERE permission = ? ORDER BY created_at DESC LIMIT 100",
        { org }
    ) or {}

    TriggerClientEvent("Painel_Mecanica:client:receivePrescriptions", src, prescriptions)
end)

RegisterNetEvent("Painel_Mecanica:server:createPrescription", function(data)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)
    local org = Config.MechanicOrg

    if not passport or level == nil then return end
    if not HasPermission(level, "prescribe") then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Sem permissão para criar pedido de peças.")
        return
    end

    local clientPassport = tonumber(data.patient_passport)
    if not clientPassport then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Passaporte inválido.")
        return
    end

    local clientName = GetCharacterNameByPassport(clientPassport)
    local mechanicName = GetCharacterName(src)

    MySQL.insert.await(
        "INSERT INTO ryze_mec_prescriptions (client_passport, client_name, mechanic_passport, mechanic_name, medication, dosage, notes, permission) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        { clientPassport, clientName, passport, mechanicName, data.medication, data.dosage or "", data.notes or "", org }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Pedido de peças registrado!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)

    -- Notificar cliente
    for _, playerId in ipairs(GetPlayers()) do
        local psrc = tonumber(playerId)
        if psrc then
            local pp = GetPassport(psrc)
            if pp == clientPassport then
                TriggerClientEvent("Painel_Mecanica:client:notify", psrc, "📦 Peças solicitadas para seu veículo: " .. data.medication)
                break
            end
        end
    end
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

    local clientPassport = tonumber(data.patient_passport)
    if not clientPassport then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Passaporte inválido.")
        return
    end

    local clientName = GetCharacterNameByPassport(clientPassport)

    MySQL.insert.await(
        "INSERT INTO ryze_mec_attendances (client_passport, client_name, reason, location, permission) VALUES (?, ?, ?, ?, ?)",
        { clientPassport, clientName, data.reason or "Não especificado", data.location or "Não informada", org }
    )

    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Chamado criado com sucesso!")

    -- Notificar todos os mecânicos online
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

    local mechanicName = GetCharacterName(src)

    MySQL.update.await(
        "UPDATE ryze_mec_attendances SET status = 'Em andamento', mechanic_passport = ?, mechanic_name = ? WHERE id = ? AND status = 'Pendente'",
        { passport, mechanicName, attendId }
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
-- CHAT MÉcanico
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

    -- Enviar para todos os mecânicos online
    for mechanicSrc, _ in pairs(onlineMechanics) do
        TriggerClientEvent("Painel_Mecanica:client:receiveChat", mechanicSrc, chatMsg)
    end
end)

-- ============================================
-- GERENCIAMENTO DE STAFF
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:hireMechanic", function(targetPassport)
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

    -- Verificar se já é mecânico
    local permResult = MySQL.query.await("SELECT dvalue FROM entitydata WHERE dkey = ?", { "Permissions:" .. org })
    local perms = {}
    if permResult and permResult[1] and permResult[1].dvalue then
        perms = json.decode(permResult[1].dvalue) or {}
    end

    if perms[tostring(targetPassport)] then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Este cidadão já faz parte do mecanica.")
        return
    end

    -- Verificar se o alvo está online
    local targetSrc = vRP.Source(targetPassport)
    if not targetSrc then
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "O cidadão precisa estar online para ser contratado.")
        return
    end

    local myName = GetCharacterName(src)
    local targetName = GetCharacterNameByPassport(targetPassport)

    -- Enviar convite
    TriggerClientEvent("Painel_Mecanica:client:notify", src, "Convite enviado para " .. targetName .. "!")
    
    Citizen.CreateThread(function()
        if vRP.Request(targetSrc, "Você deseja entrar na mecânica <b>" .. Config.PanelName .. "</b> como <b>" .. GetRoleLabel(Config.DefaultHireLevel) .. "</b>?", 60) then
            -- Aceitou
            if vRP.Source(targetPassport) then
                vRP.SetPermission(targetPassport, org, Config.DefaultHireLevel)
                TriggerClientEvent("Painel_Mecanica:client:notify", targetSrc, "Você agora faz parte da mecânica!")
                TriggerClientEvent("Painel_Mecanica:client:notify", src, targetName .. " aceitou o convite!")
                TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
            else
                TriggerClientEvent("Painel_Mecanica:client:notify", src, "O jogador desconectou antes de aceitar.")
            end
        else
            -- Recusou / Timeout
            TriggerClientEvent("Painel_Mecanica:client:notify", src, targetName .. " recusou o convite.")
        end
    end)
end)

RegisterNetEvent("Painel_Mecanica:server:fireMechanic", function(targetPassport)
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
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Este cidadão não faz parte da mecanica.")
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

RegisterNetEvent("Painel_Mecanica:server:setMechanicLevel", function(targetPassport, newLevel)
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
        TriggerClientEvent("Painel_Mecanica:client:notify", src, "Este cidadão não faz parte da mecanica.")
        return
    end

    vRP.SetPermission(targetPassport, org, newLevel)

    local targetName = GetCharacterNameByPassport(targetPassport)
    TriggerClientEvent("Painel_Mecanica:client:notify", src, targetName .. " agora é " .. GetRoleLabel(newLevel) .. "!")
    TriggerClientEvent("Painel_Mecanica:client:refreshData", src)
end)

-- COMANDO DE TESTE (Para você ver como ficou o convite)
RegisterCommand("testemec", function(source)
    local passport = vRP.Passport(source)
    if passport then
        vRP.Request(source, "Você deseja entrar na mecânica <b>" .. Config.PanelName .. "</b> como <b>" .. GetRoleLabel(Config.DefaultHireLevel) .. "</b>?", 60)
    end
end)

-- Salvar foto de um cliente pesquisado (via câmera do celular)
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
-- BANCO (DEPOSIT / WITHDRAW / DATA)
-- ============================================

RegisterNetEvent("Painel_Mecanica:server:getBankData", function()
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)

    if not passport or not level or not HasPermission(level, "view_bank") then
        TriggerClientEvent("Painel_Mecanica:client:receiveBankData", src, { error = "Sem permissão." })
        return
    end

    local orgName = Config.MechanicOrg

    -- Busca Saldo Atual
    local bankData = vRP.Query("panel/GetInformations", { name = orgName })
    local balance = 0
    if bankData and bankData[1] then
        balance = bankData[1].bank or 0
    end

    -- Busca Transações
    local transactions = vRP.Query("panel/GetTransactions", { name = orgName }) or {}

    TriggerClientEvent("Painel_Mecanica:client:receiveBankData", src, {
        balance = balance,
        transactions = transactions
    })
end)

RegisterNetEvent("Painel_Mecanica:server:depositBank", function(amount)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)

    if not passport or not level or not HasPermission(level, "view_bank") then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    -- Tentar retirar dinheiro do banco/carteira do jogador
    if vRP.PaymentBank(passport, amount) or vRP.PaymentFull(passport, amount) then
        local orgName = Config.MechanicOrg

        local identity = vRP.Identity(passport)
        local pName = identity and (identity.name .. " " .. identity.name2) or "Desconhecido"
        local logString = "Depósito (" .. pName .. " - ID:" .. passport .. ")"

        -- Adiciona ao Banco do Painel
        vRP.Query("panel/UpgradeBank", { name = orgName, Value = amount })
        vRP.Query("panel/InsertTransaction", { name = orgName, Type = string.sub(logString, 1, 250), Value = amount })

        TriggerClientEvent("Notify", src, "sucesso", "FEITO", "Você depositou $"..amount.." no cofre da empresa.", 5000)
    else
        TriggerClientEvent("Notify", src, "erro", "ERRO", "Você não tem saldo suficiente.", 5000)
    end
end)

RegisterNetEvent("Painel_Mecanica:server:withdrawBank", function(amount)
    local src = source
    local passport = GetPassport(src)
    local level = GetPlayerMechanicLevel(src)

    if not passport or not level or not HasPermission(level, "withdraw_bank") then 
        TriggerClientEvent("Notify", src, "erro", "ERRO", "Você não tem cargo de chefia para sacar do cofre.", 5000)
        return 
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    local orgName = Config.MechanicOrg

    -- Verifica saldo do painel
    local bankData = vRP.Query("panel/GetInformations", { name = orgName })
    local balance = 0
    if bankData and bankData[1] then
        balance = bankData[1].bank or 0
    end

    if balance >= amount then
        local identity = vRP.Identity(passport)
        local pName = identity and (identity.name .. " " .. identity.name2) or "Desconhecido"
        local logString = "Saque (" .. pName .. " - ID:" .. passport .. ")"

        -- Remove do Banco do Painel
        vRP.Query("panel/DowngradeBank", { name = orgName, Value = amount })
        vRP.Query("panel/InsertTransaction", { name = orgName, Type = string.sub(logString, 1, 250), Value = amount })

        -- Adiciona para o jogador
        vRP.GenerateItem(passport, "dollars", amount, true)
        TriggerClientEvent("Notify", src, "sucesso", "FEITO", "Você sacou $"..amount.." do cofre da empresa.", 5000)
    else
        TriggerClientEvent("Notify", src, "erro", "ERRO", "A empresa não tem saldo suficiente.", 5000)
    end
end)
