## CampaignData.gd
## Tabela das 20 fases em 5 cenários (Relatório PAC IV §3.3–3.5 + GDD §10).
class_name CampaignData
extends RefCounted

const TOTAL_PHASES := 20

## Modificadores sorteados por rodada no Abismo Irregular: [atacante, defensor, nome]
const MIXED_TERRAINS := [
	[1.00, 1.00, "Plano"],
	[1.00, 1.25, "Vale"],
	[0.85, 1.25, "Serra"],
	[1.10, 0.90, "Costeiro"],
]

const SCENARIOS := [
	{
		"name": "Planícies de Aldrath", "roman": "I", "first": 1, "last": 4,
		"terrain": "Plano", "atk": 1.0, "def": 1.0, "shape": "RECT", "ref_ring": 99,
		"time": 60.0, "unit_mode": "m2", "unit_scale": 1.0,
		"area_min": 12, "area_max": 20, "carto": ["ACTIVE", "ACTIVE", "ACTIVE", "ACTIVE"],
		"blurb": "Campos abertos e castelos de pedra simples. Formas retangulares.",
	},
	{
		"name": "Vales de Kheldorn", "roman": "II", "first": 5, "last": 8,
		"terrain": "Vale", "atk": 1.0, "def": 1.25, "shape": "HALF_DIAGONAL", "ref_ring": 1,
		"time": 60.0, "unit_mode": "m2_km2", "unit_scale": 400.0,
		"area_min": 20, "area_max": 30, "carto": ["ACTIVE", "ACTIVE", "SILENT", "SILENT"],
		"blurb": "Vales profundos e fortalezas sobre penhascos. Meios-blocos e arestas diagonais.",
	},
	{
		"name": "Serra das Pedras Vivas", "roman": "III", "first": 9, "last": 12,
		"terrain": "Serra", "atk": 0.85, "def": 1.25, "shape": "TRAPEZOID", "ref_ring": 0,
		"time": 60.0, "unit_mode": "km2", "unit_scale": 50000.0,
		"area_min": 30, "area_max": 40, "carto": ["SILENT", "ABSENT", "ABSENT", "ABSENT"],
		"blurb": "Florestas densas. Trapézios e formas compostas, sem malha de apoio.",
	},
	{
		"name": "Arquipélago do Oblívio", "roman": "IV", "first": 13, "last": 16,
		"terrain": "Costeiro", "atk": 1.10, "def": 0.90, "shape": "COMPLEX", "ref_ring": 0,
		"time": 45.0, "unit_mode": "ha", "unit_scale": 10000.0,
		"area_min": 40, "area_max": 55, "carto": ["ABSENT", "ABSENT", "ABSENT", "ABSENT"],
		"blurb": "Ilhas ligadas por pontes de cristal. 45 segundos por rodada.",
	},
	{
		"name": "Abismo Irregular", "roman": "V", "first": 17, "last": 20,
		"terrain": "Misto", "atk": 1.0, "def": 1.0, "shape": "HOLLOW", "ref_ring": 0,
		"time": 30.0, "unit_mode": "ha", "unit_scale": 10000.0,
		"area_min": 50, "area_max": 65, "carto": ["ABSENT", "ABSENT", "ABSENT", "ABSENT"],
		"blurb": "Ruínas geométricas com áreas vazadas. 30 segundos. Fase 20: morte súbita.",
	},
]

static func scenario_index(phase: int) -> int:
	return clampi((phase - 1) / 4, 0, SCENARIOS.size() - 1)

## Retorna a configuração completa de uma fase (1..20).
static func get_phase(n: int) -> Dictionary:
	n = clampi(n, 1, TOTAL_PHASES)
	var si := scenario_index(n)
	var sc: Dictionary = SCENARIOS[si]
	var t := float(n - 1) / float(TOTAL_PHASES - 1)
	return {
		"phase": n,
		"phase_in_scenario": n - int(sc["first"]) + 1,
		"scenario_idx": si,
		"scenario_name": sc["name"],
		"roman": sc["roman"],
		"terrain_name": sc["terrain"],
		"terrain_atk": float(sc["atk"]),
		"terrain_def": float(sc["def"]),
		"mixed_terrain": sc["terrain"] == "Misto",
		"shape": sc["shape"],
		"ref_ring": int(sc["ref_ring"]),
		"time": float(sc["time"]),
		"unit_mode": sc["unit_mode"],
		"unit_scale": float(sc["unit_scale"]),
		"area_min": int(sc["area_min"]),
		"area_max": int(sc["area_max"]),
		"cartographer": sc["carto"][n - int(sc["first"])],
		"diff_min": lerpf(0.25, 0.02, t),
		"diff_max": lerpf(0.35, 0.05, t),
		"sudden_death": n == TOTAL_PHASES,
		"blurb": sc["blurb"],
	}

static func terrain_text(cfg: Dictionary) -> String:
	if cfg["mixed_terrain"]:
		return "Misto (muda a cada rodada)"
	var a: float = cfg["terrain_atk"]
	var d: float = cfg["terrain_def"]
	if is_equal_approx(a, 1.0) and is_equal_approx(d, 1.0):
		return "Plano (×1,0 para ambos)"
	return "Atacante ×%s | Defensor ×%s" % [str(a).replace(".", ","), str(d).replace(".", ",")]
