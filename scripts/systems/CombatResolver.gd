## CombatResolver.gd
## Resolução determinística do combate (sem aleatoriedade).
## Uma única comparação, com o terreno já aplicado:
##   Força J = Área_J x atacante x (1 + Embalo) x Muralha        Força I = Área_I x defensor
## ATACAR vence se Força J > Força I; DEFENDER vence se Força I > Força J.
## Assim Atacar e Defender são complementares: sempre existe exatamente uma decisão certa
## (o terreno só desloca o limiar: em Serra um inimigo levemente menor "vale" mais).
class_name CombatResolver
extends RefCounted

const ACTION_ATTACK  := 0
const ACTION_DEFEND  := 1
const ACTION_RETREAT := 2

const WALL_MULT          := 1.25
const WIN_DOMINANCE      := 10.0
const RETREAT_DOMINANCE  := 3.0
const WIN_AREA_ATTACK    := 0.10
const WIN_AREA_DEFEND    := 0.05
const LOSS_ATTACK        := 0.20
const LOSS_ATTACK_ENGI   := 0.15
const LOSS_DEFEND        := 0.10

## fx: { embalo: float, muralha: bool, golpe: bool, consolidacao: bool }
## Retorna Vector2(força do jogador, força do inimigo).
static func forces(area_j: float, area_i: float, atk: float, def: float, fx: Dictionary) -> Vector2:
	var wall: float = WALL_MULT if fx.get("muralha", false) else 1.0
	var boost: float = (1.0 + float(fx.get("embalo", 0.0))) * wall
	return Vector2(area_j * atk * boost, area_i * def)

static func resolve(action: int, area_j: float, area_i: float, terrain: Dictionary, fx: Dictionary) -> Dictionary:
	var atk: float = terrain.get("atk", 1.0)
	var def: float = terrain.get("def", 1.0)
	var f := forces(area_j, area_i, atk, def, fx)
	var attack_wins: bool = f.x > f.y
	var defend_wins: bool = f.y > f.x
	var result := "DRAW"
	var dom := 0.0
	var area_pct := 0.0
	var mult: float = 2.0 if fx.get("golpe", false) else 1.0

	if action == ACTION_ATTACK:
		if attack_wins:
			result = "WIN"
			dom = WIN_DOMINANCE * mult
			area_pct = WIN_AREA_ATTACK * mult
		else:
			result = "LOSE"
			var loss: float = LOSS_ATTACK_ENGI if fx.get("consolidacao", false) else LOSS_ATTACK
			area_pct = -loss * mult
	elif action == ACTION_DEFEND:
		if defend_wins:
			result = "WIN"
			dom = WIN_DOMINANCE * mult
			area_pct = WIN_AREA_DEFEND * mult
		else:
			result = "LOSE"
			area_pct = -LOSS_DEFEND * mult
	else:
		dom = -RETREAT_DOMINANCE

	var correct := "NONE"
	if attack_wins:
		correct = "ATTACK"
	elif defend_wins:
		correct = "DEFEND"
	return {
		"result": result,
		"action": action,
		"force_player": f.x,
		"force_enemy": f.y,
		"margin": absf(f.x - f.y) / maxf(f.x, f.y),
		"correct": correct,
		"dom_delta": dom,
		"area_pct": area_pct,
		"atk": atk, "def": def,
		"embalo": float(fx.get("embalo", 0.0)),
		"muralha": bool(fx.get("muralha", false)),
		"golpe": bool(fx.get("golpe", false)),
		"area_j": area_j, "area_i": area_i,
	}

## Verdadeiro se a decisão é inequívoca (margem mínima de 1%; sem empate).
static func is_unambiguous(area_j: float, area_i: float, atk: float, def: float, min_margin: float = 0.01) -> bool:
	var f := forces(area_j, area_i, atk, def, {})
	return absf(f.x - f.y) / maxf(f.x, f.y) >= min_margin
