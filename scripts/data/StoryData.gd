## StoryData.gd
## A história dentro do jogo (base: GDD §9–§11): prólogo, abertura de cada cenário (com a lição
## de cálculo daquela região), o rival de cada fase e os desfechos.
class_name StoryData
extends RefCounted

const CARTO := "A CARTÓGRAFA"
const PORTRAIT_CARTO := "res://assets/ui/cartografa.png"
const PORTRAIT_KING := "res://assets/ui/arquiteto-rei.png"

## Rival e provocação de cada fase (1..20).
const RIVALS := [
	["Reino de Aldrasq", "Meu reino é um quadrado perfeito. O seu é só um rascunho."],
	["Ducado de Kermith", "Cresci um lado de cada vez. Adivinhe qual."],
	["Baronato do Campo Longo", "Sou comprido. Comprido não quer dizer grande... ou quer?"],
	["Condado da Torre Alta", "Olhe para cima, Arquiteto. A altura também conta."],
	["Senhorio do Penhasco", "Cortei os cantos das minhas muralhas. Conte as metades, se puder."],
	["Marquesado da Névoa", "No vale, quem defende vale mais."],
	["Principado da Ponte Quebrada", "Cada canto que falta é uma armadilha."],
	["Fortaleza de Kheldorn", "Ninguém toma o vale pelo tamanho que aparenta."],
	["Clã da Pedra Inclinada", "Duas bases, uma altura. Esqueça uma delas e caia."],
	["Guarda das Raízes", "Sem malha para contar. E a sua Cartógrafa, onde está?"],
	["Irmandade do Machado", "Meus anexos crescem para onde você não olha."],
	["Rei da Serra Viva", "Na serra, atacar custa caro. Tem certeza das suas contas?"],
	["Ilha das Marés", "A maré sobe depressa. Decida depressa."],
	["Corsários do Cristal", "Minhas costas não têm linha reta. Boa sorte."],
	["Arquiduquesa do Oblívio", "Quem hesita aqui é esquecido."],
	["Almirantado Sem Nome", "Atacar compensa no meu litoral. Será que compensa hoje?"],
	["Vigia das Ruínas", "O que falta por dentro também se mede."],
	["Arauto das Formas", "O terreno muda a cada rodada. Suas certezas também."],
	["Guardião Vazado", "Sou feito de buracos. Subtraia, se tiver coragem."],
	["Império das Formas Irregulares", "Um único erro, Arquiteto, e seu reino será nosso."],
]

static func rival(phase: int) -> Dictionary:
	var r: Array = RIVALS[clampi(phase, 1, RIVALS.size()) - 1]
	return {"name": r[0], "quote": r[1]}

static func prologue() -> Array:
	return [
		{"title": "O CONTINENTE DE GEOMETRIA", "speaker": "CRÔNICA DO REINO", "portrait": "res://assets/ui/capa.png",
		"text": "Durante séculos, ninguém precisou derramar sangue em Geometria. As Leis da Forma diziam: toda disputa se resolve comparando territórios. Quem tinha mais área, vencia."},
		{"title": "O IMPÉRIO DAS FORMAS", "speaker": "CRÔNICA DO REINO", "portrait": "res://assets/ui/mapa.png",
		"text": "Então surgiu o Império das Formas Irregulares. Ele deforma as próprias fronteiras para que ninguém consiga calculá-las — e engole, um a um, os reinos que erram a conta."},
		{"title": "O ARQUITETO-REI", "speaker": CARTO, "portrait": PORTRAIT_KING,
		"text": "Agora a coroa é sua. Seu reino é pequeno e o Império já avista as suas Planícies. Você não tem o maior exército... mas tem a única arma que importa: saber medir."},
		{"title": "SUA CAMPANHA", "speaker": CARTO, "portrait": PORTRAIT_CARTO,
		"text": "São cinco regiões até o coração do Império. Em cada batalha, compare o seu reino com o inimigo: ataque se for mais forte, defenda se for mais fraco. Eu caminho ao seu lado... enquanto você precisar de mim."},
	]

## O que o briefing conta: quem o jogador é e por que parte para a conquista.
const FIRST_MISSION := "Você é o Arquiteto-Rei, o novo governante de um reino pequeno em Geometria, onde vence quem tem mais área. O Império das Formas Irregulares deforma fronteiras para ninguém conseguir calculá-las e já engoliu os seus vizinhos. Você parte para a conquista para salvar o seu povo, com a única arma que tem: saber medir."
const MISSIONS := [
	"O Império já encosta nas suas fronteiras. Como Arquiteto-Rei, liberte as Planícies antes que ele tome o seu reino.",
	"O Império ocupa os vales e corta os cantos das muralhas para confundir quem mede. Liberte as fortalezas de Kheldorn. Atenção: aqui o terreno muda a conta.",
	"A Serra caiu para o Império. Sem malha para contar, o Arquiteto-Rei precisa confiar nas próprias contas para abrir caminho.",
	"O Império esconde seus reinos nas ilhas do Oblívio. Vencê-las é o último passo do Arquiteto-Rei antes do Abismo.",
	"No Abismo está o trono do Império. Se o Arquiteto-Rei errar aqui, Geometria perde as fronteiras que se podem medir.",
]

static func mission(phase: int) -> String:
	return FIRST_MISSION if phase <= 1 else str(MISSIONS[CampaignData.scenario_index(phase)])

## Aberturas dos cenários (índice 0..4). A segunda página é a lição da região, com um exemplo desenhado.
static func chapter(index: int) -> Array:
	match index:
		0:
			return [
				{"title": "CAPÍTULO I — PLANÍCIES DE ALDRATH", "speaker": CARTO, "portrait": PORTRAIT_CARTO,
				"text": "Aqui você nasceu. Os primeiros a se curvar ao Império foram seus vizinhos. Liberte as planícies antes que as fronteiras deles encostem nas suas."},
				{"title": "LIÇÃO: O RETÂNGULO", "speaker": CARTO, "portrait": PORTRAIT_CARTO, "shape": example("RECT"),
				"text": "Não é preciso contar quadrado por quadrado. Conte uma fileira (a base) e quantas fileiras existem (a altura). Multiplique os dois."},
			]
		1:
			return [
				{"title": "CAPÍTULO II — VALES DE KHELDORN", "speaker": CARTO, "portrait": PORTRAIT_CARTO,
				"text": "As planícies são livres, e agora o Império sabe o seu nome. Nos vales, as fortalezas cortam os cantos das muralhas para confundir quem mede. E cuidado: aqui quem defende vale ×1,25."},
				{"title": "LIÇÃO: OS MEIOS-BLOCOS", "speaker": CARTO, "portrait": PORTRAIT_CARTO, "shape": example("HALF"),
				"text": "Imagine o retângulo inteiro em volta. Depois tire meio bloco para cada canto cortado em diagonal. No Vale, um inimigo um pouco menor ainda pode ser mais forte que você."},
			]
		2:
			return [
				{"title": "CAPÍTULO III — SERRA DAS PEDRAS VIVAS", "speaker": CARTO, "portrait": PORTRAIT_CARTO,
				"text": "Arquiteto... estas matas eu não posso atravessar com você. Deixo minhas últimas anotações. Daqui em diante, não haverá malha para contar — e atacar na serra vale só ×0,85."},
				{"title": "LIÇÃO: TRAPÉZIOS E FORMAS COMPOSTAS", "speaker": "ANOTAÇÃO DA CARTÓGRAFA", "portrait": PORTRAIT_CARTO, "shape": example("TRAPEZOID"),
				"text": "No trapézio, some a base maior com a menor, multiplique pela altura e divida por 2. Nas formas em L, T ou U: calcule o retângulo em volta e subtraia o que falta."},
			]
		3:
			return [
				{"title": "CAPÍTULO IV — ARQUIPÉLAGO DO OBLÍVIO", "speaker": "ANOTAÇÃO DA CARTÓGRAFA", "portrait": PORTRAIT_CARTO,
				"text": "Você chegou às ilhas sem mim, como eu esperava. Aqui os reinos são esquecidos por quem hesita: o relógio corre mais rápido. No litoral, atacar vale ×1,10 e defender, ×0,90."},
				{"title": "LIÇÃO: DIVIDIR PARA SOMAR", "speaker": "ANOTAÇÃO DA CARTÓGRAFA", "portrait": PORTRAIT_CARTO, "shape": example("COMPLEX"),
				"text": "Nenhuma fórmula cobre uma costa torta. Quebre a forma em fileiras ou em retângulos menores, calcule cada pedaço e some. Meios-blocos valem ½."},
			]
		_:
			return [
				{"title": "CAPÍTULO V — ABISMO IRREGULAR", "speaker": "ÚLTIMA CARTA DA CARTÓGRAFA", "portrait": PORTRAIT_CARTO,
				"text": "Além das ruínas está o trono do Império das Formas. O terreno muda a cada rodada, o tempo é curto e, na última batalha, um único erro encerra tudo."},
				{"title": "LIÇÃO: SUBTRAIR OS VAZIOS", "speaker": "ÚLTIMA CARTA DA CARTÓGRAFA", "portrait": PORTRAIT_CARTO, "shape": example("HOLLOW"),
				"text": "Meça por fora, como se a forma fosse inteira. Depois subtraia a área de cada buraco. Você já sabe tudo o que precisa, Arquiteto."},
			]

## Texto de desfecho ao vencer a última fase de um cenário.
const OUTROS := [
	"As Planícies de Aldrath estão livres! Camponeses hasteiam sua bandeira. Ao norte, as fortalezas de Kheldorn pedem socorro.",
	"Os Vales de Kheldorn juram lealdade. A Cartógrafa sorri em silêncio: você já mede sem precisar ouvi-la.",
	"A Serra das Pedras Vivas se rendeu — e você a venceu sozinho. Do alto, avistam-se as ilhas do Oblívio.",
	"O Arquipélago se lembra do seu nome. Resta apenas o Abismo, onde o Império nasceu.",
	"O Império das Formas caiu! As Leis da Forma voltam a reger Geometria. No último pergaminho, a Cartógrafa escreveu: “Você nunca precisou de mim para medir. Só para acreditar.”",
]

static func is_chapter_end(phase: int) -> bool:
	return phase % 4 == 0

## Frase de encerramento da fase, mostrada na crônica da batalha.
static func epilogue(phase: int, won: bool) -> String:
	var name: String = rival(phase)["name"]
	if not won:
		return "%s resiste. Revise seus cálculos, Arquiteto — o reino ainda conta com você." % name
	if is_chapter_end(phase):
		return str(OUTROS[CampaignData.scenario_index(phase)])
	return "%s agora faz parte do seu reino. A marcha contra o Império continua." % name

# ─────────────────────────────────────────────
#  FORMAS DE EXEMPLO (história e guia)
# ─────────────────────────────────────────────
static func _block(w: int, h: int) -> Dictionary:
	var c := {}
	for x in w:
		for y in h:
			c[Vector2i(x, y)] = TerritoryGenerator.FULL
	return c

static func example(kind: String) -> Dictionary:
	var c := _block(6, 4)
	if kind == "HALF":
		c[Vector2i(0, 0)] = TerritoryGenerator.SE
		c[Vector2i(5, 0)] = TerritoryGenerator.SW
	elif kind == "TRAPEZOID":
		c = {}
		for r in 3:
			for x in range(3 - r, 6 + r):
				c[Vector2i(x, r)] = TerritoryGenerator.FULL
			c[Vector2i(2 - r, r)] = TerritoryGenerator.SE
			c[Vector2i(6 + r, r)] = TerritoryGenerator.SW
	elif kind == "COMPOSITE":
		for x in range(3, 6):
			for y in 2:
				c.erase(Vector2i(x, y))
	elif kind == "COMPLEX":
		for p in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(4, 0), Vector2i(0, 1), Vector2i(5, 3), Vector2i(2, 3)]:
			c.erase(p)
		c[Vector2i(2, 0)] = TerritoryGenerator.SE
		c[Vector2i(5, 0)] = TerritoryGenerator.SW
	elif kind == "HOLLOW":
		c = _block(7, 5)
		for p in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(5, 3)]:
			c.erase(p)
	return c
