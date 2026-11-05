## UnitFormatter.gd
## Converte área em células para m², km² ou hectares conforme a fase (Relatório §3.5).
class_name UnitFormatter
extends RefCounted

const KM2_THRESHOLD_M2 := 10000.0

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

## Retorna { "main": "2,5 km²", "sub": "= 2.500.000 m²" }. "sub" vazio quando não há conversão.
static func format_area(cells_area: float, cfg: Dictionary) -> Dictionary:
	var m2: float = cells_area * float(cfg.get("unit_scale", 1.0))
	var mode := str(cfg.get("unit_mode", "m2"))
	if mode == "m2":
		return {"main": "%s m²" % fmt_number(m2, 1), "sub": ""}
	if mode == "m2_km2":
		if m2 > KM2_THRESHOLD_M2:
			return {"main": "%s km²" % fmt_number(m2 / 1000000.0, 3), "sub": "= %s m²" % fmt_number(m2, 0)}
		return {"main": "%s m²" % fmt_number(m2, 0), "sub": ""}
	if mode == "km2":
		return {"main": "%s km²" % fmt_number(m2 / 1000000.0, 2), "sub": "= %s m²" % fmt_number(m2, 0)}
	if mode == "ha":
		return {"main": "%s ha" % fmt_number(m2 / 10000.0, 1), "sub": "= %s m²" % fmt_number(m2, 0)}
	return {"main": "%s u²" % fmt_number(cells_area, 1), "sub": ""}

static func short(cells_area: float, cfg: Dictionary) -> String:
	return str(format_area(cells_area, cfg)["main"])
