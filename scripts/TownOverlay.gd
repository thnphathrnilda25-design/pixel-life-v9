extends Node2D
## TownOverlay.gd — แสงกลางวัน/กลางคืน + ฝน/หิมะ (วาดทับโลก)

var t := 0.0


func _ready() -> void:
	z_index = 70


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var zone_id := Game.zone_id
	var outdoor := TownData.is_outdoor(zone_id)
	var hour := float(Game.time_min) / 60.0
	var tint := Color(0, 0, 0, 0)

	if outdoor:
		if hour < 6.5:
			tint = Color(0.30, 0.32, 0.56, 0.26)
		elif hour < 8.0:
			tint = Color(1.0, 0.85, 0.65, 0.12)
		elif hour >= 21.0:
			tint = Color(0.14, 0.13, 0.30, 0.40)
		elif hour >= 19.0:
			tint = Color(0.24, 0.20, 0.42, 0.25)
		elif hour >= 17.0:
			tint = Color(1.0, 0.6, 0.35, 0.15)
	else:
		if hour >= 21.0:
			tint = Color(0.14, 0.13, 0.30, 0.14)

	if tint.a > 0.0:
		draw_rect(Rect2(0, 0, 960, 540), tint)

	if not outdoor:
		return

	if Game.weather == "rain":
		for i in 64:
			var x := fmod(float(i) * 151.0 + t * 260.0, 1000.0) - 20.0
			var y := fmod(float(i) * 83.0 + t * 420.0, 580.0) - 20.0
			draw_line(Vector2(x, y), Vector2(x - 4, y + 13), Color(0.72, 0.78, 0.88, 0.34), 1.0)
		draw_rect(Rect2(0, 0, 960, 540), Color(0.32, 0.36, 0.46, 0.10))
	elif Game.weather == "snow":
		for i in 54:
			var x := fmod(float(i) * 173.0 + sin(t * 0.8 + float(i)) * 22.0, 980.0)
			var y := fmod(float(i) * 97.0 + t * 42.0, 560.0)
			draw_circle(Vector2(x, y), 2.2, Color(1, 1, 1, 0.72))
		draw_rect(Rect2(0, 0, 960, 540), Color(0.75, 0.85, 1.0, 0.10))
