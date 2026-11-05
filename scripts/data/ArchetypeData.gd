## ArchetypeData.gd
## Os três arquétipos do Relatório PAC IV §3.2.
class_name ArchetypeData
extends RefCounted

const IDS := ["ESTRATEGISTA", "ENGENHEIRO", "GUERREIRO"]

const DATA := {
	"ESTRATEGISTA": {
		"name": "Estrategista", "tagline": "Inteligência e Controle",
		"passive_name": "Olho de Águia",
		"passive_desc": "Projeta 2 células de grade adicionais ao redor do adversário como referencial visual.",
		"active_name": "Análise de Campo",
		"active_desc": "Exibe a área real do oponente por 5 segundos.",
		"cost": 1,
		"goal": "Suporte analítico: mais formas de visualizar o inimigo.",
		"color": Color8(60, 110, 190),
	},
	"ENGENHEIRO": {
		"name": "Engenheiro", "tagline": "Expansão e Fortificação",
		"passive_name": "Consolidação",
		"passive_desc": "Reduz o prejuízo ao atacar e perder de 20% para 15% da área.",
		"active_name": "Muralha de Emergência",
		"active_desc": "Confere o modificador de montanha (×1,25) ao seu território por uma rodada.",
		"cost": 2,
		"goal": "Escolhas defensivas e controle de perdas.",
		"color": Color8(30, 100, 70),
	},
	"GUERREIRO": {
		"name": "Guerreiro", "tagline": "Ímpeto e Força",
		"passive_name": "Embalo de Combate",
		"passive_desc": "+5% de área efetiva por vitória consecutiva (até +15%). Zera ao recuar ou perder.",
		"active_name": "Golpe Decisivo",
		"active_desc": "Dobra o ganho de território no sucesso, mas duplica a penalidade no revés.",
		"cost": 1,
		"goal": "Alto risco e alta recompensa.",
		"color": Color8(160, 30, 30),
	},
}

static func get_data(id: String) -> Dictionary:
	return DATA.get(id, {})

static func display_name(id: String) -> String:
	return str(DATA.get(id, {}).get("name", "—"))
