local _, ns = ...
local E, L = ns.E, ns.L

if E.locale ~= "ptBR" then return end

-- keys backed by Blizzard globals in enUS.lua are already localized by the client

-- general
L.GHOST = "Fantasma"

-- merchant
L.merchant.notEnoughMoney = "Você não tem dinheiro suficiente para reparar."
L.merchant.repairCost = "Seu equipamento foi reparado por %s."
L.merchant.junkSold = "Seus itens de sucata foram vendidos." -- REVIEW: client term for "junk"
L.merchant.junkSoldFor = "Seus itens de sucata foram vendidos por %s." -- REVIEW: client term for "junk"

-- tooltips
L.PET_HAPINESS = "Mascote está %s"
L.PET_DAMAGE = "Mascote está causando %s de dano"
L.PET_LOYALTY = "Mascote está %s lealdade"
L.PET_HAPPINESS_STATES = { "Infeliz", "Contente", "Feliz" } -- REVIEW: client happiness terms
L.PET_LOYALTY_GAINING = "ganhando"
L.PET_LOYALTY_LOSING = "perdendo"
L.IN_BAG = "Na Bolsa"
L.VENDOR_PRICE = "Preço de Venda: %s"

-- experience
L.PET_EXPERIENCE = "Experiência do Mascote"

-- datatexts
L.ADDON_CPU = "CPU dos AddOns"
L.ADDON_MEMORY = "Memória dos AddOns"
L.BANDWIDTH = "Largura de Banda"
L.COLLECT_GARBAGE = "(Ctrl ou Alt + Clique) Coletar Lixo"
L.COORDINATES = "Coordenadas"
L.DEFICIT = "Déficit"
L.DOWNLOAD = "Download"
L.EARNED = "Ganho"
L.FRAMERATE = "Taxa de Quadros"
L.HEALING_BONUS = "Bônus de Cura"
L.HIT_CHANCE = "Chance de Acerto"
L.INSTANCES = "Instâncias Salvas" -- REVIEW: client term (Raid Info)
L.KEY_STONES = "Pedras-chave" -- REVIEW: client term for Mythic Keystone
L.LATENCY = "Latência"
L.LOCAL_TIME = "Local"
L.LOOT_SPEC = "Espec. de Saque" -- REVIEW: abbreviation
L.MANA_PER_SEC = "%0.2f mana por seg."
L.MEMBERS = "Membros"
L.MICRO_MENU = "Micromenu" -- REVIEW: shown on the datatext bar
L.NO_GUILD = "Sem Guilda"
L.PROFIT = "Lucro"
L.PROTOCOL = "Protocolo"
L.REAGENTS = "Reagentes"
L.SERVER_TIME = "Servidor"
L.SESSION = "Sessão"
-- REVIEW: slot names, compare with the character frame tooltips
L.SLOTS[_G.INVSLOT_HEAD] = "Cabeça"
L.SLOTS[_G.INVSLOT_NECK] = "Pescoço"
L.SLOTS[_G.INVSLOT_SHOULDER] = "Ombros"
L.SLOTS[_G.INVSLOT_BODY] = "Camisa"
L.SLOTS[_G.INVSLOT_CHEST] = "Peito"
L.SLOTS[_G.INVSLOT_WAIST] = "Cintura"
L.SLOTS[_G.INVSLOT_LEGS] = "Pernas"
L.SLOTS[_G.INVSLOT_FEET] = "Pés"
L.SLOTS[_G.INVSLOT_WRIST] = "Pulsos"
L.SLOTS[_G.INVSLOT_HAND] = "Mãos"
L.SLOTS[_G.INVSLOT_FINGER1] = "Dedo 1"
L.SLOTS[_G.INVSLOT_FINGER2] = "Dedo 2"
L.SLOTS[_G.INVSLOT_TRINKET1] = "Berloque 1"
L.SLOTS[_G.INVSLOT_TRINKET2] = "Berloque 2"
L.SLOTS[_G.INVSLOT_BACK] = "Costas"
L.SLOTS[_G.INVSLOT_MAINHAND] = "Mão Principal"
L.SLOTS[_G.INVSLOT_OFFHAND] = "Mão Secundária"
L.SLOTS[_G.INVSLOT_RANGED] = "À Distância"
L.SLOTS[_G.INVSLOT_TABARD] = "Tabardo"
L.SPEC = "Espec." -- REVIEW: abbreviation, shown on the datatext bar
L.SPENT = "Gasto"
L.SUBZONE = "Subzona"
L.WARBAND = "Bando de Guerra" -- REVIEW: client term for Warband
L.WORLD_BOSSES = "Chefes Mundiais" -- REVIEW: client term (Raid Info)

L.TOGGLE_BAGS_TEXT = "Clique para Mostrar/Ocultar as Bolsas"
L.TOGGLE_BAGS_BAR_TEXT = "Shift + Clique para Mostrar/Ocultar a Barra de Bolsas"
L.TOGGLE_CHARACTER_TEXT = "Clique para Mostrar/Ocultar as Informações do Personagem"
L.TOGGLE_TALENTS_TEXT = "Clique para Mostrar/Ocultar os Talentos"
L.TOGGLE_WORLD_MAP_TEXT = "Clique para Mostrar/Ocultar o Mapa-múndi"
L.CHANGE_LOOT_SPEC_TEXT = "Clique Direito para Alterar a Especialização de Saque"
L.SWITCH_SPEC_TEXT = "Clique Direito para Trocar de Especialização"
L.PRINT_IDS_TEXT = "Shift + Clique para Exibir os IDs no Chat"
L.HOLD_SHIFT_TO_SHOW_ALL_CHARACTERS = "Segure Shift para mostrar todos os personagens"
