## UnitFormatter.gd
## Converte área em quadrados para m² ou km², conforme a escala do mapa na fase.
class_name UnitFormatter
extends RefCounted

## Número no padrão pt-BR: milhar com ponto, decimal com vírgula.
static func fmt_number(v: float, decimals: int = 0) -> String:
	var neg := v < 0.0
	v = absf(v)
	var s := String.num(v, decimals)
	var parts := s.split(".")
	var int_part: String = parts[0]
	var out := ""
	var count := 0
	for i in range(int_part.length() - 1, -1, -1):
		out = int_part[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	if parts.size() > 1:
		var dec: String = parts[1].rstrip("0")
		if dec != "":
			out += "," + dec
	return ("-" if neg else "") + out

## Área do território na unidade da fase: "2.500 m²" ou "27,5 km²" (uma unidade só, sem conversões).
static func format_area(cells_area: float, cfg: Dictionary) -> String:
	var side := side_m(cfg)
	if side >= 1000:
		return "%s km²" % fmt_number(cells_area * pow(side / 1000.0, 2), 1)
	return "%s m²" % fmt_number(cells_area * side * side, 1)

## Lado de um quadrado do mapa, em metros.
static func side_m(cfg: Dictionary) -> int:
	return int(cfg.get("side_m", 1))

## "10 m" ou "1 km".
static func side_text(cfg: Dictionary) -> String:
	var side := side_m(cfg)
	return "%d km" % int(side / 1000.0) if side >= 1000 else "%d m" % side

## Legenda da escala: "1 quadrado = 10 m × 10 m = 100 m²".
static func scale_text(cfg: Dictionary) -> String:
	var side := side_text(cfg)
	return "1 quadrado = %s × %s = %s" % [side, side, format_area(1.0, cfg)]
