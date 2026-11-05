## AccuracyTracker.gd
## Índice de Precisão (IP) derivado das decisões + estrelas da fase.
## Não há entrada de estimativa: o IP mede o quão bem a decisão acompanhou a diferença real.
class_name AccuracyTracker
extends RefCounted

const BRONZE_MIN_DOM := 70.0
const SILVER_MAX_ROUND := 6
const GOLD_MIN_IP := 85.0

## info: resultado de CombatResolver.resolve
static func round_ip(info: Dictionary) -> float:
	var m: float = info["margin"]
	var action: int = info["action"]
	if action == CombatResolver.ACTION_RETREAT:
		return 70.0 if m < 0.05 else 40.0
	if info["result"] == "WIN":
		return 100.0
	if m < 0.05:
		return 50.0
	if m < 0.15:
		return 25.0
	return 0.0

static func phase_ip(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var s := 0.0
	for v in values:
		s += float(v)
	return s / values.size()

## Som por rodada: "precise" (>=90), "imprecise" (<40) ou "" (silêncio neutro).
static func sound_for(ip: float) -> String:
	if ip >= 90.0:
		return "precise"
	if ip < 40.0:
		return "imprecise"
	return ""

## Estrelas: 3 ouro, 2 prata, 1 bronze, 0 nenhuma.
static func stars(final_dom: float, first_reach_round: int, ip: float, losses: int) -> int:
	if final_dom < BRONZE_MIN_DOM:
		return 0
	if ip >= GOLD_MIN_IP and losses == 0:
		return 3
	if first_reach_round > 0 and first_reach_round <= SILVER_MAX_ROUND:
		return 2
	return 1
