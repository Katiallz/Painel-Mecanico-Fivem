Config = {}

-- Organização mecânica (Mechanic01 = Ryze Custom)
Config.MechanicOrg = "Mechanic01"

-- Comando para abrir o painel
Config.Command = "mecanica"

-- Nome do Painel Interface
Config.PanelName = "Ryze Custom"

-- Nível padrão ao contratar (mais baixo = Estagiário = 5)
Config.DefaultHireLevel = 5

-- Mapeamento de tipo sanguíneo (coluna `blood` da tabela characters) (mantido por base)
Config.BloodTypes = {
    [1] = "O+",
    [2] = "A+",
    [3] = "B+",
    [4] = "AB+",
}

-- Especialidades / Serviços oferecidos
Config.Specialties = {
    "Troca de Cor",
    "Kit Estético",
    "Stage 1",
    "Stage 2",
    "Reparo Completo",
    "Revisão Elétrica",
    "Blindagem",
    "Geral",
}

-- Hierarquia da Mecânica (conforme Groups.lua enviado)
-- Nível menor = cargo mais alto
Config.Roles = {
    [0] = "Chefe", -- Fallback para SuperAdmin se precisar
    [1] = "Chefe",
    [2] = "Sub-Chefe",
    [3] = "Gerente",
    [4] = "Mecânico",
    [5] = "Estagiário",
}

-- Permissões: nível <= X pode usar
-- Nível 0 passa automaticamente em tudo
Config.Permissions = {
    search          = 5,   -- Todos (até Estagiário)
    chat            = 5,   -- Todos
    diagnose        = 4,   -- Mecânico+ (Registro de Venda Diária)
    consult         = 3,   -- Gerente+ (Orçamentos Maiores)
    prescribe       = 3,   -- Gerente+ 
    attend          = 5,   -- Todos podem atender guinchos
    healthplan      = 1,   -- Nao usado para mecs ativamente
    manage_staff    = 2,   -- Sub-Chefe+
    hire            = 2,   -- Sub-Chefe+
    fire            = 2,   -- Sub-Chefe+
    view_bank       = 5,   -- Todos (Visualizar e Depositar)
    withdraw_bank   = 3,   -- Gerente, Sub-Chefe e Chefe (Sacar)
}
