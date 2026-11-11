extends Node2D
## CharLineup.gd — ตารางตรวจตัวละคร v8 (ชุด / ทรงผม / สีหน้า / สีผิว / ท่า)
## รัน: godot --path . res://tests/CharLineup.tscn

var font: SystemFont
var tiny: SystemFont


func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(TownHud.FONT_NAMES)
	font.font_weight = 600
	tiny = SystemFont.new()
	tiny.font_names = PackedStringArray(TownHud.FONT_NAMES)
	tiny.font_weight = 400
	queue_redraw()
	for i in 6:
		await get_tree().process_frame
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		var path := ProjectSettings.globalize_path("res://screenshots/char_lineup.png")
		img.save_png(path)
		print("saved: ", path, " size=", img.get_size())
	else:
		print("capture failed: char_lineup")
	get_tree().quit()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#efe0c2"))
	# กระดาษอบอุ่น + เส้นตารางจาง
	for i in 11:
		draw_line(Vector2(0, 44 + i * 46), Vector2(960, 44 + i * 46), Color(0.55, 0.42, 0.28, 0.07), 1.0)
	draw_rect(Rect2(0, 0, 960, 36), Color("#6b4a32"))
	draw_string(font, Vector2(18, 25), "ตัวละคร v8 — cozy chibi", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f8efd8"))
	draw_string(tiny, Vector2(724, 24), "14 ชุด • 8 ทรงผม • 7 สีหน้า • 5 สีผิว • ท่ายืน/หลัง/นั่ง/เดิน",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.98, 0.93, 0.80, 0.85))

	# ---------- แถว 1: ชุดทั้ง 14 ----------
	draw_string(tiny, Vector2(14, 58), "ชุด", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#7a5536"))
	var look := {"skin": "#f2c39b", "hair": "#3a2a1a", "hair_style": "short", "expression": "happy"}
	var x := 44.0
	for o in Game.OUTFITS:
		var oid := String(o.get("id", "casual"))
		var nm := String(o.get("name", oid))
		var pal := TownArt.player_palette(oid, look)
		TownArt.draw_person(self, Vector2(x, 196), pal, 1.42, 0.0, 1, 1.4)
		_center(nm, x, 214, 9, Color("#5a4028"))
		x += 66.0

	# ---------- แถว 2 ซ้าย: ทรงผม 8 ----------
	draw_string(tiny, Vector2(14, 244), "ทรงผม", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#7a5536"))
	var hair_names := {}
	for hs in Game.HAIR_STYLES:
		hair_names[String(hs["id"])] = String(hs["name"])
	var hx := 34.0
	for hs in Game.HAIR_STYLES:
		var hid := String(hs["id"])
		var hp := {"skin": "#f2c39b", "hair": "#3a2a1a", "hair_style": hid,
			"expression": "neutral", "outfit": "casual"}
		TownArt.draw_person(self, Vector2(hx, 366), hp, 1.38, 0.0, 1, 1.1)
		_center(String(hair_names.get(hid, hid)), hx, 382, 9, Color("#5a4028"))
		hx += 58.0

	# ---------- แถว 2 ขวา: สีหน้า 7 ----------
	draw_string(tiny, Vector2(500, 244), "สีหน้า", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#7a5536"))
	var exprs := [["neutral", "ปกติ"], ["happy", "ยิ้ม"], ["love", "รัก"], ["tired", "เหนื่อย"],
		["stressed", "เครียด"], ["sad", "เศร้า"], ["sick", "ป่วย"]]
	var ex := 524.0
	for e in exprs:
		var ep := {"skin": "#f2c39b", "hair": "#3a2a1a", "hair_style": "bob",
			"expression": String(e[0]), "outfit": "casual"}
		TownArt.draw_person(self, Vector2(ex, 366), ep, 1.38, 0.0, 1, 0.8)
		_center(String(e[1]), ex, 382, 9, Color("#5a4028"))
		ex += 60.0

	# ---------- แถว 3 ซ้าย: สีผิว 5 ----------
	draw_string(tiny, Vector2(14, 424), "สีผิว", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#7a5536"))
	var sx := 40.0
	for st in Game.SKIN_TONES:
		var sp := {"skin": String(st["hex"]), "hair": "#3a2a1a", "hair_style": "short",
			"expression": "happy", "outfit": "casual"}
		TownArt.draw_person(self, Vector2(sx, 512), sp, 1.32, 0.0, 1, 1.6)
		_center(String(st["name"]), sx, 526, 9, Color("#5a4028"))
		sx += 68.0

	# ---------- แถว 3 ขวา: ท่า / การหัน ----------
	draw_string(tiny, Vector2(404, 424), "ท่าและการหัน", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#7a5536"))
	var base := {"skin": "#f2c39b", "hair": "#3a2a1a", "hair_style": "ponytail",
		"expression": "happy", "outfit": "school"}
	var poses := [
		["ยืนหน้า", 1, 0.0, "stand"],
		["ยืนหลัง", 2, 0.0, "stand"],
		["เดิน", 1, 0.42, "stand"],
		["หันซ้าย", -1, 0.0, "stand"],
		["นั่ง", 1, 0.0, "sit"],
	]
	var px := 440.0
	for p in poses:
		var pp := base.duplicate(true)
		pp["pose"] = String(p[3])
		TownArt.draw_person(self, Vector2(px, 512), pp, 1.34, float(p[2]), int(p[1]), 1.0)
		_center(String(p[0]), px, 526, 9, Color("#5a4028"))
		px += 82.0

	# กรอบรวม
	draw_rect(Rect2(4, 40, 952, 496), Color(0.42, 0.30, 0.19, 0.28), false, 2.0)


func _center(text: String, cx: float, y: float, size: int, color: Color) -> void:
	var w := tiny.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(tiny, Vector2(cx - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
