## AccuracyTracker.gd
## Índice de Precisão (IP) derivado das decisões + estrelas da fase (dadas pelo Domínio).
## Não há entrada de estimativa: o IP mede o quão bem a decisão acompanhou a diferença real.
class_name AccuracyTracker
extends RefCounted

## Domínio final mínimo de cada medalha. Sem Bronze, a fase é perdida.
const BRONZE_MIN_DOM := 60.0
const SILVER_MIN_DOM := 80.0
const GOLD_MIN_DOM := 100.0
## XP extra pela medalha, indexado pelo número de estrelas.
const STAR_XP := [0, 150, 350, 600]

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

## Estrelas: 3 ouro, 2 prata, 1 bronze, 0 nenhuma (derrota).
static func stars(final_dom: float) -> int:
	if final_dom >= GOLD_MIN_DOM:
		return 3
	if final_dom >= SILVER_MIN_DOM:
		return 2
	if final_dom >= BRONZE_MIN_DOM:
		return 1
	return 0
