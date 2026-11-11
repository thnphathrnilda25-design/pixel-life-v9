class_name TownArt
## TownArt.gd — วาดภาพพิกเซลทั้งเมืองจากโค้ด 100%
## v5 "อบอุ่น": ต้นไม้แน่น ๆ บ้านไม้/อิฐ ไฟอบอุ่น เงานุ่ม และตัวละครที่มีรายละเอียดขึ้น
## ไม่มีไฟล์รูป: ทุกอย่างเป็นสี่เหลี่ยม/วงกลม/เส้น ที่คำนวณจากข้อมูลใน TownData

const SEASON_GRASS := [
	["#78bf68", "#64ab55", "#8fcf7a", "#5a9a4c"],   # ใบไม้ผลิ
	["#69b25a", "#579a49", "#7fc46c", "#4c8a40"],   # ร้อน
	["#c09a5e", "#a77e45", "#d4b078", "#94703c"],   # ใบไม้ร่วง
	["#e5edf0", "#d2dee4", "#f2f7f9", "#c4d2da"],   # หนาว
]
const SEASON_TREE := [
	{"leaf": "#4f8a46", "dark": "#3d7038", "light": "#71b25a", "tip": "#8fcf72"},
	{"leaf": "#4c8a3e", "dark": "#3a7030", "light": "#68a84c", "tip": "#82c05e"},
	{"leaf": "#b07834", "dark": "#8f5c26", "light": "#d09a4e", "tip": "#e8b868"},
	{"leaf": "#9ab8b0", "dark": "#7fa098", "light": "#c8ded8", "tip": "#eef6f4"},
]

# ============================================================
#  โซน
# ============================================================

static func draw_zone(c: CanvasItem, zone_id: String, zone: Dictionary, hour: int, season: int, t: float) -> void:
	if bool(zone.get("outdoor", false)):
		_draw_outdoor(c, zone_id, zone, hour, season, t)
	else:
		_draw_interior(c, zone_id, zone, hour, t)
	_draw_zone_decor(c, zone, hour, season, t)
	_draw_props(c, zone, t, season)
	_draw_ambient(c, zone_id, zone, hour, season, t)
	_draw_edge_signs(c, zone)


static func _draw_outdoor(c: CanvasItem, zone_id: String, zone: Dictionary, hour: int, season: int, t: float) -> void:
	season = clampi(season, 0, 3)
	var grass: Array = SEASON_GRASS[season]
	c.draw_rect(Rect2(0, 0, TownData.W, TownData.H), Color(grass[0]))

	# ลายหญ้าแบบพิกเซล + จุดสว่าง/เงา (ตำแหน่งตายตัว)
	for row in range(0, 13):
		for col in range(0, 20):
			var h := _hash01(col * 53 + row * 97)
			if h < 0.30:
				var px := float(col) * 50.0 + _hash01(col * 7 + row * 31) * 34.0
				var py := float(row) * 44.0 + _hash01(col * 17 + row * 13) * 30.0
				c.draw_rect(Rect2(px, py, 9, 3), Color(grass[1]))
				c.draw_rect(Rect2(px + 2, py - 3, 2, 4), Color(grass[2]))
			elif h > 0.78:
				var px2 := float(col) * 50.0 + _hash01(col * 23 + row * 11) * 40.0
				var py2 := float(row) * 44.0 + _hash01(col * 5 + row * 29) * 36.0
				c.draw_rect(Rect2(px2, py2, 5, 2), Color(grass[3]))

	# แสงแดดอ่อน ๆ เป็นแถบ
	if hour >= 7 and hour < 17:
		for i in 5:
			var sx := 90.0 + float(i) * 210.0
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(sx, 0), Vector2(sx + 90, 0), Vector2(sx + 210, 540), Vector2(sx + 120, 540),
			]), Color(1.0, 0.96, 0.78, 0.035))

	for p in zone.get("paths", []):
		_draw_path(c, p, season)

	for b in zone.get("buildings", []):
		_draw_building(c, b, hour, season, t)

	# ต้นไม้ / ดอกไม้ / ตะเกียง / ม้านั่ง
	for t3 in zone.get("trees", []):
		if t3.size() >= 2:
			_draw_tree(c, Vector2(float(t3[0]), float(t3[1])), float(t3[2]) if t3.size() > 2 else 1.0, season)
	for f in zone.get("flowers", []):
		if f.size() >= 3:
			_draw_flower(c, Vector2(float(f[0]), float(f[1])), Color(String(f[2])))
	for l in zone.get("lamps", []):
		_draw_lamp(c, Vector2(float(l[0]), float(l[1])), hour)
	for bch in zone.get("benches", []):
		_draw_bench(c, Vector2(float(bch[0]), float(bch[1])))

	if zone.has("fountain"):
		_draw_fountain(c, zone["fountain"], t)
	if zone.has("bus"):
		_draw_bus_stop(c, zone["bus"], t)
	if zone_id == "downtown":
		_draw_string_lights(c, 34.0, 86.0, 900.0, t)
	if zone_id == "park":
		c.draw_rect(Rect2(0, 520, 960, 20), Color(0.36, 0.29, 0.18, 0.10))
	if zone_id == "backyard":
		if zone.has("pond"):
			_draw_pond(c, zone["pond"], t)
		# รั้วไม้เตี้ย ๆ ด้านหลังสวน
		c.draw_rect(Rect2(24, 188, 912, 5), Color("#b08a5a"))
		c.draw_rect(Rect2(24, 193, 912, 2), Color("#8a6a46"))
		var fx := 40.0
		while fx < 936:
			c.draw_rect(Rect2(fx, 172, 6, 22), Color("#a07a4a"))
			c.draw_rect(Rect2(fx, 172, 6, 3), Color("#c89a62"))
			fx += 46.0


static func _draw_path(c: CanvasItem, p: Dictionary, season: int) -> void:
	var r := Rect2(float(p.get("x", 0)), float(p.get("y", 0)), float(p.get("w", 10)), float(p.get("h", 10)))
	var kind := String(p.get("kind", "walk"))
	match kind:
		"road":
			c.draw_rect(r, Color("#55525a"))
			c.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 5), Color("#403e46"))
			c.draw_rect(Rect2(r.position.x, r.end.y - 5, r.size.x, 5), Color("#403e46"))
			c.draw_rect(Rect2(r.position.x, r.position.y + 7, r.size.x, 2), Color("#66636b"))
			var dash_x := r.position.x + 16.0
			while dash_x < r.end.x:
				c.draw_rect(Rect2(dash_x, r.position.y + r.size.y * 0.5 - 2, 28, 4), Color("#e8c85a"))
				dash_x += 62.0
		"plaza":
			c.draw_rect(r, Color("#cdbfa2"))
			var tile := 46.0
			var gx := r.position.x
			var ix := 0
			while gx < r.end.x:
				var gy := r.position.y
				var iy := 0
				while gy < r.end.y:
					var shade := 0.04 if (ix + iy) % 2 == 0 else -0.02
					c.draw_rect(Rect2(gx + 1, gy + 1, tile - 2, 46 - 2),
						Color("#cdbfa2").lightened(shade))
					gy += 46.0
					iy += 1
				gx += tile
				ix += 1
			c.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3), Color("#b3a282"))
			c.draw_rect(Rect2(r.position.x, r.end.y - 3, r.size.x, 3), Color("#b3a282"))
		"track":
			c.draw_rect(r, Color("#b35d48"))
			c.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 4), Color("#8f4536"))
			c.draw_rect(Rect2(r.position.x, r.end.y - 4, r.size.x, 4), Color("#8f4536"))
			if r.size.x > r.size.y:
				for i in 3:
					c.draw_rect(Rect2(r.position.x, r.position.y + 6 + i * 11, r.size.x, 1), Color(0.96, 0.88, 0.78, 0.5))
			else:
				for i in 3:
					c.draw_rect(Rect2(r.position.x + 6 + i * 11, r.position.y, 1, r.size.y), Color(0.96, 0.88, 0.78, 0.5))
		"soil":
			c.draw_rect(r, Color("#6b4a30"))
			c.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 4), Color("#5a3c26"))
			var sy := r.position.y + 10.0
			var row_i := 0
			while sy < r.end.y - 2:
				c.draw_rect(Rect2(r.position.x + 4, sy, r.size.x - 8, 9), Color("#8a5f3c"))
				c.draw_rect(Rect2(r.position.x + 4, sy, r.size.x - 8, 2), Color("#a5764c"))
				sy += 16.0
				row_i += 1
		_:
			c.draw_rect(r, Color("#cdbfa4"))
			c.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3), Color("#ded2b8"))
			c.draw_rect(Rect2(r.position.x, r.end.y - 3, r.size.x, 3), Color("#b3a487"))
			var step := 34.0
			var sx := r.position.x
			var n := 0
			while sx < r.end.x:
				c.draw_line(Vector2(sx, r.position.y + 2), Vector2(sx - 4, r.end.y - 2), Color("#bbae91"), 1.0)
				if n % 3 == 1:
					c.draw_rect(Rect2(sx + 10, r.position.y + 6, 8, 2), Color("#e0d4bc"))
				sx += step
				n += 1


static func _draw_building(c: CanvasItem, b: Dictionary, hour: int, season: int, t: float) -> void:
	var x := float(b.get("x", 0))
	var y := float(b.get("y", 0))
	var w := float(b.get("w", 100))
	var h := float(b.get("h", 100))
	var wall := Color(String(b.get("wall", "#d8c8a8")))
	var roof := Color(String(b.get("roof", "#a85a42")))
	var door_x := float(b.get("door_x", x + w * 0.5))
	var snow := season == 3
	var glow := hour >= 17 or hour < 6
	var wood := Color("#6b4a32")

	# เงาบ้าน
	c.draw_rect(Rect2(x + 12, y + 10, w, h), Color(0.15, 0.11, 0.08, 0.18))
	c.draw_rect(Rect2(x, y, w, h), wall)
	# ผนังไม้: เส้นแนวนอน + ไม้ดิ่งหัวมุม
	var sy := y + 18.0
	while sy < y + h:
		c.draw_rect(Rect2(x, sy, w, 2), wall.darkened(0.10))
		sy += 20.0
	for bx in [x + 9, x + w - 15]:
		c.draw_rect(Rect2(bx, y + 6, 6, h - 16), wood.darkened(0.15))
	c.draw_rect(Rect2(x - 4, y + h - 14, w + 8, 14), wall.darkened(0.32))
	c.draw_rect(Rect2(x - 2, y + h - 6, w + 4, 6), Color("#4a3628"))

	# หลังคา
	var roof_h := 52.0 if h > 150 else 40.0
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(x - 18, y + 4), Vector2(x + w + 18, y + 4),
		Vector2(x + w - 4, y - roof_h), Vector2(x + 4, y - roof_h),
	]), roof)
	c.draw_rect(Rect2(x + 2, y - roof_h, w - 4, 6), roof.lightened(0.12))
	# กระเบื้อง
	var row_y := y - roof_h + 10.0
	var row_i := 0
	while row_y < y:
		var rx := x + 8.0 + (12.0 if row_i % 2 == 0 else 0.0)
		while rx < x + w - 8.0:
			c.draw_rect(Rect2(rx, row_y, 18, 3), roof.darkened(0.16))
			c.draw_rect(Rect2(rx + 2, row_y - 2, 14, 2), roof.lightened(0.10))
			rx += 26.0
		row_y += 12.0
		row_i += 1
	# ชายคา
	c.draw_rect(Rect2(x - 22, y, w + 44, 7), roof.darkened(0.30))
	c.draw_rect(Rect2(x - 22, y + 7, w + 44, 3), Color(0.20, 0.14, 0.10, 0.35))
	if snow:
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(x - 16, y + 1), Vector2(x + w + 16, y + 1),
			Vector2(x + w - 8, y - 13), Vector2(x + 8, y - 13),
		]), Color("#eef4f7"))
	# ปล่องไฟ + ควัน
	if int(w) % 2 == 0:
		var cx := x + w - 58
		c.draw_rect(Rect2(cx, y - roof_h - 20, 24, 28), roof.darkened(0.35))
		c.draw_rect(Rect2(cx - 4, y - roof_h - 25, 32, 8), roof.darkened(0.45))
		for i in 3:
			var ph := fmod(t * 0.35 + float(i) * 0.33, 1.0)
			var sx := cx + 12 + sin(ph * 6.0 + float(i)) * 6.0
			var sy2 := y - roof_h - 30 - ph * 48.0
			c.draw_circle(Vector2(sx, sy2), 5.0 + ph * 6.0, Color(0.92, 0.9, 0.86, 0.18 * (1.0 - ph)))

	# หน้าต่าง + กล่องดอกไม้
	var win_y := y + h * 0.40
	for wx in [x + w * 0.22, x + w * 0.78]:
		if absf(wx - door_x) < 46.0:
			continue
		c.draw_rect(Rect2(wx - 27, win_y - 21, 54, 44), wood)
		c.draw_rect(Rect2(wx - 22, win_y - 16, 44, 34), Color("#f7d98a") if glow else Color("#aed8ec"))
		if glow:
			c.draw_circle(Vector2(wx, win_y), 26.0, Color(1.0, 0.82, 0.42, 0.13))
			c.draw_rect(Rect2(wx - 22, win_y - 16, 44, 8), Color("#ffe9b0"))
		c.draw_line(Vector2(wx, win_y - 16), Vector2(wx, win_y + 18), wood, 2.0)
		c.draw_line(Vector2(wx - 22, win_y + 1), Vector2(wx + 22, win_y + 1), wood, 2.0)
		c.draw_rect(Rect2(wx - 26, win_y + 20, 52, 7), Color("#8a5a3a"))
		for fi in 5:
			var fx: float = float(wx) - 20.0 + float(fi) * 10.0
			c.draw_circle(Vector2(fx, win_y + 18), 4.0, Color(["#e86a8a", "#f2d05a", "#c08ae0", "#f28a5a"][fi % 4]))
			c.draw_circle(Vector2(fx, win_y + 17), 1.6, Color("#7a9a4a"))

	# ประตู + กันสาด
	c.draw_rect(Rect2(door_x - 26, y + h - 60, 52, 60), wood.darkened(0.25))
	c.draw_rect(Rect2(door_x - 21, y + h - 55, 42, 55), Color("#7a4e32"))
	c.draw_rect(Rect2(door_x - 17, y + h - 51, 34, 22), Color("#936040"))
	c.draw_rect(Rect2(door_x - 17, y + h - 25, 34, 20), Color("#6f452c"))
	c.draw_circle(Vector2(door_x + 11, y + h - 29), 2.3, Color("#f2cc6a"))
	c.draw_rect(Rect2(door_x - 34, y + h - 4, 68, 6), Color("#b8a88a"))
	c.draw_rect(Rect2(door_x - 36, y + h - 76, 72, 7), roof.darkened(0.15))
	# ป้ายร้าน
	c.draw_rect(Rect2(door_x - 45, y + h - 100, 90, 24), wood.darkened(0.18))
	c.draw_rect(Rect2(door_x - 40, y + h - 96, 80, 16), Color("#f5e6c8"))
	for i in 3:
		c.draw_circle(Vector2(door_x - 24 + i * 24, y + h - 88), 5.0, roof.lightened(0.18))
	# ไฟหน้าบ้าน
	c.draw_circle(Vector2(door_x - 40, y + h - 66), 4.5, Color("#ffe6a0") if glow else Color("#d8d8c8"))
	if glow:
		c.draw_circle(Vector2(door_x - 40, y + h - 66), 18.0, Color(1.0, 0.85, 0.45, 0.09))


static func _draw_tree(c: CanvasItem, pos: Vector2, scale: float, season: int) -> void:
	var s := maxf(scale, 0.5)
	var pal: Dictionary = SEASON_TREE[clampi(season, 0, 3)]
	var leaf := Color(String(pal["leaf"]))
	var dark := Color(String(pal["dark"]))
	var light := Color(String(pal["light"]))
	var tip := Color(String(pal["tip"]))
	c.draw_circle(Vector2(pos.x, pos.y + 3), 20.0 * s, Color(0.16, 0.12, 0.08, 0.18))
	# ลำต้น
	c.draw_rect(Rect2(pos.x - 6 * s, pos.y - 48 * s, 12 * s, 49 * s), Color("#6b4a32"))
	c.draw_rect(Rect2(pos.x - 3 * s, pos.y - 46 * s, 3 * s, 44 * s), Color("#8a5e3e"))
	c.draw_rect(Rect2(pos.x - 12 * s, pos.y - 3 * s, 24 * s, 5 * s), Color("#5a3e2a"))
	c.draw_rect(Rect2(pos.x - 15 * s, pos.y + 1 * s, 8 * s, 3 * s), Color("#5a3e2a"))
	c.draw_rect(Rect2(pos.x + 8 * s, pos.y + 1 * s, 8 * s, 3 * s), Color("#5a3e2a"))

	if season == 3:
		c.draw_circle(Vector2(pos.x, pos.y - 54 * s), 29 * s, dark)
		c.draw_circle(Vector2(pos.x - 19 * s, pos.y - 42 * s), 20 * s, leaf)
		c.draw_circle(Vector2(pos.x + 19 * s, pos.y - 42 * s), 20 * s, leaf)
		c.draw_circle(Vector2(pos.x, pos.y - 64 * s), 24 * s, Color("#eef6f8"))
		c.draw_circle(Vector2(pos.x - 18 * s, pos.y - 56 * s), 15 * s, Color("#e2eef2"))
		c.draw_circle(Vector2(pos.x + 17 * s, pos.y - 56 * s), 14 * s, Color("#e2eef2"))
		c.draw_circle(Vector2(pos.x + 2 * s, pos.y - 70 * s), 10 * s, Color("#ffffff"))
		return

	c.draw_circle(Vector2(pos.x, pos.y - 56 * s), 30 * s, dark)
	c.draw_circle(Vector2(pos.x - 21 * s, pos.y - 44 * s), 21 * s, leaf)
	c.draw_circle(Vector2(pos.x + 21 * s, pos.y - 44 * s), 21 * s, leaf)
	c.draw_circle(Vector2(pos.x - 8 * s, pos.y - 68 * s), 20 * s, leaf)
	c.draw_circle(Vector2(pos.x + 10 * s, pos.y - 62 * s), 18 * s, light)
	c.draw_circle(Vector2(pos.x - 17 * s, pos.y - 58 * s), 13 * s, light)
	c.draw_circle(Vector2(pos.x + 2 * s, pos.y - 76 * s), 12 * s, tip)
	c.draw_circle(Vector2(pos.x + 23 * s, pos.y - 52 * s), 9 * s, tip)
	c.draw_circle(Vector2(pos.x - 28 * s, pos.y - 50 * s), 8 * s, light)
	# ผลไม้/ดอกไม้ตามฤดู
	if season == 0 and int(pos.x) % 3 == 0:
		for i in 7:
			var a := float(i) * 1.7 + pos.x * 0.01
			var bx := pos.x + cos(a) * 22.0 * s
			var by := pos.y - 52 * s + sin(a) * 18.0 * s
			c.draw_circle(Vector2(bx, by), 4.0 * s, Color("#f4a8c2"))
			c.draw_circle(Vector2(bx, by), 1.6 * s, Color("#ffe0ea"))
	elif season == 2:
		for i in 5:
			c.draw_circle(Vector2(pos.x - 20 * s + float(i) * 10 * s, pos.y - 45 * s - float(i % 2) * 8 * s), 3.5 * s, Color("#d8643a"))


static func _draw_flower(c: CanvasItem, pos: Vector2, col: Color) -> void:
	c.draw_rect(Rect2(pos.x, pos.y - 6, 2, 6), Color("#4f8a3a"))
	c.draw_circle(Vector2(pos.x - 3, pos.y - 8), 2.6, col)
	c.draw_circle(Vector2(pos.x + 3, pos.y - 8), 2.6, col.lightened(0.08))
	c.draw_circle(Vector2(pos.x, pos.y - 11), 2.6, col)
	c.draw_circle(Vector2(pos.x, pos.y - 8), 1.5, Color("#ffe17a"))


static func _draw_lamp(c: CanvasItem, pos: Vector2, hour: int) -> void:
	var on := hour >= 17 or hour < 6
	c.draw_circle(Vector2(pos.x, pos.y + 2), 8.0, Color(0.15, 0.11, 0.08, 0.18))
	c.draw_rect(Rect2(pos.x - 3, pos.y - 60, 6, 62), Color("#3f4652"))
	c.draw_rect(Rect2(pos.x - 1, pos.y - 58, 2, 56), Color("#66707c"))
	c.draw_rect(Rect2(pos.x - 12, pos.y - 68, 24, 9), Color("#2f3540"))
	c.draw_rect(Rect2(pos.x - 9, pos.y - 72, 18, 5), Color("#4a505c"))
	c.draw_circle(Vector2(pos.x, pos.y - 62), 7.5, Color("#ffe6a0") if on else Color("#b8c2cc"))
	if on:
		c.draw_circle(Vector2(pos.x, pos.y - 62), 20.0, Color(1.0, 0.82, 0.42, 0.10))
		c.draw_circle(Vector2(pos.x, pos.y - 62), 34.0, Color(1.0, 0.78, 0.38, 0.045))


static func _draw_bench(c: CanvasItem, pos: Vector2) -> void:
	c.draw_circle(Vector2(pos.x, pos.y + 2), 26.0, Color(0.15, 0.11, 0.08, 0.16))
	c.draw_rect(Rect2(pos.x - 36, pos.y - 20, 72, 7), Color("#8a5a3a"))
	c.draw_rect(Rect2(pos.x - 36, pos.y - 34, 72, 8), Color("#a06a44"))
	c.draw_rect(Rect2(pos.x - 36, pos.y - 34, 72, 3), Color("#c08a5a"))
	for i in 3:
		c.draw_rect(Rect2(pos.x - 32 + i * 23, pos.y - 27, 3, 8), Color("#6b452c"))
	c.draw_rect(Rect2(pos.x - 29, pos.y - 13, 6, 15), Color("#4a3a30"))
	c.draw_rect(Rect2(pos.x + 23, pos.y - 13, 6, 15), Color("#4a3a30"))
	c.draw_rect(Rect2(pos.x - 33, pos.y - 8, 10, 3), Color("#3a2e26"))
	c.draw_rect(Rect2(pos.x + 23, pos.y - 8, 10, 3), Color("#3a2e26"))


static func _draw_pond(c: CanvasItem, pos: Vector2, t: float) -> void:
	c.draw_circle(Vector2(pos.x, pos.y + 16), 108.0, Color(0.15, 0.11, 0.08, 0.10))
	c.draw_colored_polygon(_ellipse_points(pos + Vector2(0, 5), 112, 58), Color("#8a7a5a"))
	c.draw_colored_polygon(_ellipse_points(pos, 106, 54), Color("#a89878"))
	c.draw_colored_polygon(_ellipse_points(pos, 98, 48), Color("#5a98b8"))
	c.draw_colored_polygon(_ellipse_points(pos, 90, 42), Color("#78b8d8"))
	c.draw_colored_polygon(_ellipse_points(pos + Vector2(0, -4), 72, 30), Color(0.55, 0.80, 0.90, 0.45))
	for i in 3:
		var a := t * 0.8 + float(i) * 2.1
		var rx := 24.0 + float(i) * 18.0
		var ry := rx * 0.46
		var cx := pos.x + cos(a) * 26.0
		var cy := pos.y - 4.0 + sin(a * 1.3) * 8.0
		c.draw_colored_polygon(_ellipse_points(Vector2(cx, cy), rx, ry), Color(0.86, 0.95, 0.99, 0.10))
	for i in 3:
		var lx := pos.x - 54.0 + float(i) * 44.0
		var ly := pos.y + 8.0 + sin(t * 1.2 + float(i)) * 3.0
		c.draw_circle(Vector2(lx, ly), 10.0, Color("#5a9a5a"))
		c.draw_rect(Rect2(lx - 5, ly - 6, 10, 3), Color("#7ab86a"))
		if i == 1:
			c.draw_circle(Vector2(lx + 2, ly - 5), 4.0, Color("#f2a8c2"))
			c.draw_circle(Vector2(lx + 2, ly - 5), 2.0, Color("#f6e0a0"))
	for i in 2:
		var rx2 := pos.x + 88.0 + float(i) * 9.0
		c.draw_line(Vector2(rx2, pos.y + 10), Vector2(rx2 - 4, pos.y - 26 - float(i) * 4),
			Color("#6a8a4a"), 2.0)
		c.draw_rect(Rect2(rx2 - 7, pos.y - 34 - float(i) * 4, 5, 12), Color("#8a6a3a"))


static func _ellipse_points(center: Vector2, rx: float, ry: float, n: int = 26) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _draw_fountain(c: CanvasItem, pos: Vector2, t: float) -> void:
	c.draw_circle(Vector2(pos.x, pos.y + 12), 66.0, Color(0.15, 0.12, 0.09, 0.18))
	c.draw_circle(pos, 62.0, Color("#b0a998"))
	c.draw_circle(pos, 56.0, Color("#8f897c"))
	c.draw_circle(pos, 48.0, Color("#5aa8d8"))
	c.draw_circle(pos, 43.0, Color("#7cc4e8"))
	# ระลอกน้ำ
	for i in 3:
		var rr := 18.0 + fmod(t * 8.0 + float(i) * 12.0, 38.0)
		c.draw_arc(pos, rr, 0, TAU, 26, Color(0.9, 0.97, 1.0, 0.20), 1.3, true)
	for i in 6:
		var a := t * 1.2 + float(i) * TAU / 6.0
		c.draw_circle(pos + Vector2(cos(a), sin(a)) * 20.0, 2.8, Color(0.9, 0.97, 1.0, 0.65))
	c.draw_rect(Rect2(pos.x - 7, pos.y - 26, 14, 34), Color("#b8b2a4"))
	c.draw_rect(Rect2(pos.x - 4, pos.y - 24, 8, 30), Color("#d0cabb"))
	c.draw_circle(Vector2(pos.x, pos.y - 30), 9.0, Color("#8fd0e8"))
	for i in 4:
		var a2 := -PI * 0.5 + (float(i) - 1.5) * 0.45
		var end := pos + Vector2(cos(a2), sin(a2)) * (20.0 + sin(t * 5.0 + float(i)) * 4.0)
		c.draw_line(Vector2(pos.x, pos.y - 34), end, Color(0.82, 0.93, 1.0, 0.55), 2.0)
	# ปลา
	for i in 2:
		var fx := pos.x + cos(t * 0.8 + float(i) * 2.4) * 28.0
		var fy := pos.y + 8.0 + sin(t * 1.4 + float(i) * 2.0) * 7.0
		c.draw_circle(Vector2(fx, fy), 3.0, Color("#e8a04a") if i == 0 else Color("#f2d05a"))
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(fx + (4 if cos(t * 0.8 + float(i) * 2.4) > 0 else -4), fy),
			Vector2(fx + (9 if cos(t * 0.8 + float(i) * 2.4) > 0 else -9), fy - 3),
			Vector2(fx + (9 if cos(t * 0.8 + float(i) * 2.4) > 0 else -9), fy + 3),
		]), Color(0.9, 0.6, 0.3, 0.8))


static func _draw_bus_stop(c: CanvasItem, pos: Vector2, t: float) -> void:
	c.draw_circle(Vector2(pos.x, pos.y + 3), 42.0, Color(0.15, 0.11, 0.08, 0.14))
	c.draw_rect(Rect2(pos.x - 54, pos.y - 70, 108, 12), Color("#8a4a38"))
	c.draw_rect(Rect2(pos.x - 50, pos.y - 64, 100, 6), Color("#a85a44"))
	c.draw_rect(Rect2(pos.x - 44, pos.y - 58, 6, 54), Color("#6b4a32"))
	c.draw_rect(Rect2(pos.x + 38, pos.y - 58, 6, 54), Color("#6b4a32"))
	c.draw_rect(Rect2(pos.x - 44, pos.y - 6, 88, 5), Color("#8a5a3a"))
	# ม้านั่ง
	c.draw_rect(Rect2(pos.x - 28, pos.y - 26, 56, 5), Color("#a06a44"))
	c.draw_rect(Rect2(pos.x - 28, pos.y - 26, 56, 2), Color("#c08a5a"))
	c.draw_rect(Rect2(pos.x - 24, pos.y - 21, 4, 15), Color("#5a3e2a"))
	c.draw_rect(Rect2(pos.x + 20, pos.y - 21, 4, 15), Color("#5a3e2a"))
	# ป้ายรถเมล์
	c.draw_rect(Rect2(pos.x + 62, pos.y - 62, 6, 66), Color("#3f4652"))
	c.draw_rect(Rect2(pos.x + 44, pos.y - 92, 42, 30), Color("#2f6ea8"))
	c.draw_rect(Rect2(pos.x + 48, pos.y - 88, 34, 22), Color("#eef6f8"))
	c.draw_rect(Rect2(pos.x + 52, pos.y - 84, 26, 3), Color("#2f6ea8"))
	c.draw_rect(Rect2(pos.x + 52, pos.y - 78, 18, 3), Color("#2f6ea8"))
	c.draw_rect(Rect2(pos.x + 52, pos.y - 72, 22, 3), Color("#2f6ea8"))
	var a := 0.5 + sin(t * 3.0) * 0.35
	c.draw_circle(Vector2(pos.x + 65, pos.y - 100), 4.0, Color(1.0, 0.85, 0.3, a))
	c.draw_circle(Vector2(pos.x - 40, pos.y - 48), 3.0, Color(1.0, 0.9, 0.5, 0.4 + a * 0.4))


static func _draw_string_lights(c: CanvasItem, x0: float, y0: float, x1: float, t: float) -> void:
	var sag := 26.0
	var steps := 18
	var prev := Vector2(x0, y0)
	for i in range(1, steps + 1):
		var k := float(i) / float(steps)
		var x := lerpf(x0, x1, k)
		var y := y0 + sin(k * PI) * sag
		var p := Vector2(x, y)
		c.draw_line(prev, p, Color(0.24, 0.19, 0.15, 0.7), 1.5)
		if i % 2 == 0:
			var col := Color(["#ffd98a", "#ffb07a", "#ffe6b0", "#f2a0b8"][(i / 2) % 4])
			c.draw_circle(p + Vector2(0, 4), 3.2, col)
			c.draw_circle(p + Vector2(0, 4), 9.0, Color(col.r, col.g, col.b, 0.09))
		prev = p


static func _draw_zone_decor(c: CanvasItem, zone: Dictionary, hour: int, season: int, t: float) -> void:
	for f in zone.get("fences", []):
		_draw_fence(c, f)
	for b in zone.get("bushes", []):
		if b.size() >= 2:
			_draw_bush(c, Vector2(float(b[0]), float(b[1])), float(b[2]) if b.size() > 2 else 1.0, season)
	for s in zone.get("stones", []):
		_draw_stone(c, Vector2(float(s[0]), float(s[1])))
	for m in zone.get("mailboxes", []):
		_draw_mailbox(c, Vector2(float(m[0]), float(m[1])))
	for p in zone.get("planters", []):
		_draw_planter(c, Vector2(float(p[0]), float(p[1])))
	for st in zone.get("stalls", []):
		_draw_market_stall(c, Vector2(float(st[0]), float(st[1])), t)
	for b2 in zone.get("bicycles", []):
		_draw_bicycle(c, Vector2(float(b2[0]), float(b2[1])))
	for pic in zone.get("picnic", []):
		_draw_picnic(c, Vector2(float(pic[0]), float(pic[1])))
	if bool(zone.get("outdoor", false)) and season == 3:
		for i in 6:
			var px := 80.0 + float(i) * 150.0 + sin(t + float(i)) * 12.0
			c.draw_circle(Vector2(px, 516), 18.0, Color(0.95, 0.97, 0.99, 0.25))
			c.draw_circle(Vector2(px + 14, 514), 12.0, Color(0.95, 0.97, 0.99, 0.22))


static func _draw_fence(c: CanvasItem, f: Dictionary) -> void:
	var x := float(f.get("x", 0))
	var y := float(f.get("y", 0))
	var w := float(f.get("w", 100))
	var col := Color(String(f.get("color", "#f2ead8")))
	var dark := col.darkened(0.28)
	c.draw_rect(Rect2(x, y - 3, w, 3), Color(0.15, 0.11, 0.08, 0.12))
	c.draw_rect(Rect2(x, y - 22, w, 4), col)
	c.draw_rect(Rect2(x, y - 12, w, 4), col.darkened(0.08))
	var px := x + 6.0
	while px <= x + w - 6.0:
		c.draw_rect(Rect2(px - 3, y - 28, 6, 30), col)
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(px - 3, y - 28), Vector2(px + 3, y - 28), Vector2(px, y - 34),
		]), col.lightened(0.08))
		c.draw_rect(Rect2(px - 3, y - 28, 2, 30), col.lightened(0.16))
		px += 24.0
	c.draw_rect(Rect2(x, y - 22, w, 1), dark)


static func _draw_bush(c: CanvasItem, pos: Vector2, scale: float, season: int) -> void:
	var s := maxf(scale, 0.5)
	var green := Color("#4f8a46") if season != 2 else Color("#8f7a3a")
	if season == 3:
		green = Color("#b8ccc4")
	c.draw_circle(Vector2(pos.x, pos.y + 2), 16.0 * s, Color(0.15, 0.11, 0.08, 0.14))
	c.draw_circle(Vector2(pos.x - 10 * s, pos.y - 9 * s), 12 * s, green.darkened(0.12))
	c.draw_circle(Vector2(pos.x + 10 * s, pos.y - 9 * s), 12 * s, green.darkened(0.06))
	c.draw_circle(Vector2(pos.x, pos.y - 16 * s), 14 * s, green)
	c.draw_circle(Vector2(pos.x - 4 * s, pos.y - 22 * s), 7 * s, green.lightened(0.15))
	c.draw_circle(Vector2(pos.x + 9 * s, pos.y - 16 * s), 5 * s, green.lightened(0.08))
	if season == 0:
		for i in 3:
			c.draw_circle(Vector2(pos.x - 8 * s + float(i) * 8 * s, pos.y - 16 * s), 2.2 * s, Color("#f2a8c0"))


static func _draw_stone(c: CanvasItem, pos: Vector2) -> void:
	c.draw_circle(Vector2(pos.x, pos.y + 1), 7.0, Color(0.15, 0.11, 0.08, 0.13))
	c.draw_circle(pos, 6.0, Color("#a8a294"))
	c.draw_circle(Vector2(pos.x - 1, pos.y - 2), 4.0, Color("#c0baac"))
	c.draw_circle(Vector2(pos.x - 2, pos.y - 3), 1.8, Color("#d8d2c4"))


static func _draw_mailbox(c: CanvasItem, pos: Vector2) -> void:
	c.draw_rect(Rect2(pos.x - 2, pos.y - 30, 4, 30), Color("#6b4a32"))
	c.draw_rect(Rect2(pos.x - 11, pos.y - 46, 22, 18), Color("#4a6a8a"))
	c.draw_rect(Rect2(pos.x - 8, pos.y - 43, 16, 5), Color("#6a8aaa"))
	c.draw_rect(Rect2(pos.x + 8, pos.y - 42, 8, 3), Color("#e05a4a"))
	c.draw_rect(Rect2(pos.x - 5, pos.y - 55, 10, 3), Color("#4a3a30"))


static func _draw_planter(c: CanvasItem, pos: Vector2) -> void:
	c.draw_rect(Rect2(pos.x - 20, pos.y - 14, 40, 15), Color("#a06a44"))
	c.draw_rect(Rect2(pos.x - 22, pos.y - 17, 44, 5), Color("#c08a5a"))
	c.draw_rect(Rect2(pos.x - 20, pos.y - 14, 40, 3), Color("#8a5a3a"))
	for i in 5:
		var fx := pos.x - 16 + float(i) * 8.0
		c.draw_rect(Rect2(fx, pos.y - 24, 2, 9), Color("#4f8a3a"))
		c.draw_circle(Vector2(fx, pos.y - 27), 4.0, Color(["#e86a8a", "#f2d05a", "#c08ae0", "#f28a5a", "#8ac86a"][i]))


static func _draw_market_stall(c: CanvasItem, pos: Vector2, t: float) -> void:
	c.draw_circle(Vector2(pos.x, pos.y + 2), 36.0, Color(0.15, 0.11, 0.08, 0.14))
	c.draw_rect(Rect2(pos.x - 40, pos.y - 58, 80, 8), Color("#8a5a3a"))
	c.draw_rect(Rect2(pos.x - 44, pos.y - 92, 88, 10), Color("#e05a4a"))
	for i in 5:
		c.draw_rect(Rect2(pos.x - 44 + i * 18, pos.y - 82, 9, 9), Color("#f2ead8"))
	for i in 4:
		c.draw_rect(Rect2(pos.x - 36 + i * 24, pos.y - 58, 5, 56), Color("#6b4a32"))
	c.draw_rect(Rect2(pos.x - 32, pos.y - 50, 64, 8), Color("#c08a5a"))
	# สินค้า
	for i in 4:
		c.draw_circle(Vector2(pos.x - 24 + i * 16, pos.y - 45), 5.0, Color(["#e86a6a", "#f2c05a", "#8ac86a", "#d88a5a"][i]))
	var a := 0.5 + sin(t * 2.4) * 0.4
	c.draw_circle(Vector2(pos.x + 34, pos.y - 96), 3.5, Color(1.0, 0.85, 0.4, a))


static func _draw_bicycle(c: CanvasItem, pos: Vector2) -> void:
	c.draw_circle(Vector2(pos.x - 20, pos.y - 10), 11.0, Color(0.15, 0.11, 0.08, 0.12))
	c.draw_arc(Vector2(pos.x - 20, pos.y - 12), 11.0, 0, TAU, 18, Color("#3f4652"), 2.0, true)
	c.draw_arc(Vector2(pos.x + 20, pos.y - 12), 11.0, 0, TAU, 18, Color("#3f4652"), 2.0, true)
	c.draw_line(Vector2(pos.x - 20, pos.y - 12), Vector2(pos.x, pos.y - 30), Color("#8a4a3a"), 2.5)
	c.draw_line(Vector2(pos.x, pos.y - 30), Vector2(pos.x + 20, pos.y - 12), Color("#8a4a3a"), 2.5)
	c.draw_line(Vector2(pos.x - 20, pos.y - 12), Vector2(pos.x + 5, pos.y - 12), Color("#8a4a3a"), 2.0)
	c.draw_line(Vector2(pos.x + 5, pos.y - 12), Vector2(pos.x, pos.y - 30), Color("#8a4a3a"), 2.0)
	c.draw_line(Vector2(pos.x + 5, pos.y - 12), Vector2(pos.x + 20, pos.y - 12), Color("#8a4a3a"), 2.0)
	c.draw_rect(Rect2(pos.x - 6, pos.y - 36, 12, 5), Color("#4a3a30"))
	c.draw_line(Vector2(pos.x - 20, pos.y - 12), Vector2(pos.x - 26, pos.y - 26), Color("#5a6470"), 1.5)
	c.draw_line(Vector2(pos.x + 20, pos.y - 12), Vector2(pos.x + 26, pos.y - 26), Color("#5a6470"), 1.5)
	c.draw_rect(Rect2(pos.x - 28, pos.y - 28, 8, 3), Color("#4a3a30"))


static func _draw_picnic(c: CanvasItem, pos: Vector2) -> void:
	c.draw_rect(Rect2(pos.x - 52, pos.y - 36, 104, 40), Color(0.15, 0.11, 0.08, 0.12))
	c.draw_rect(Rect2(pos.x - 48, pos.y - 34, 96, 36), Color("#d86a6a"))
	for i in 4:
		c.draw_rect(Rect2(pos.x - 48 + i * 24, pos.y - 34, 11, 36), Color("#f2ead8"))
	for i in 4:
		c.draw_rect(Rect2(pos.x - 48, pos.y - 34 + i * 9, 96, 8), Color(0.96, 0.92, 0.84, 0.85))
	c.draw_rect(Rect2(pos.x + 12, pos.y - 42, 22, 14), Color("#b08a5a"))
	c.draw_rect(Rect2(pos.x + 12, pos.y - 46, 22, 5), Color("#8a5a3a"))
	c.draw_circle(Vector2(pos.x - 24, pos.y - 38), 6.0, Color("#e8c05a"))
	c.draw_circle(Vector2(pos.x - 10, pos.y - 38), 5.0, Color("#d85a5a"))


static func _draw_edge_signs(c: CanvasItem, zone: Dictionary) -> void:
	for e in zone.get("exits", []):
		var edge := String(e.get("edge", ""))
		var col := Color("#f2e2c8")
		var dark := Color("#6b4a32")
		match edge:
			"left":
				c.draw_rect(Rect2(0, 246, 10, 68), dark)
				c.draw_rect(Rect2(10, 256, 42, 44), col)
				c.draw_rect(Rect2(10, 256, 42, 4), Color("#d8c8a8"))
				c.draw_colored_polygon(PackedVector2Array([
					Vector2(24, 270), Vector2(42, 280), Vector2(24, 290),
				]), dark)
			"right":
				c.draw_rect(Rect2(950, 246, 10, 68), dark)
				c.draw_rect(Rect2(908, 256, 42, 44), col)
				c.draw_rect(Rect2(908, 256, 42, 4), Color("#d8c8a8"))
				c.draw_colored_polygon(PackedVector2Array([
					Vector2(936, 270), Vector2(918, 280), Vector2(936, 290),
				]), dark)
			"top":
				c.draw_rect(Rect2(450, 0, 60, 10), dark)
				c.draw_rect(Rect2(458, 10, 44, 18), col)
			"bottom":
				c.draw_rect(Rect2(450, 530, 60, 10), dark)


static func _draw_interior(c: CanvasItem, zone_id: String, zone: Dictionary, hour: int, t: float) -> void:
	var wall := Color(String(zone.get("wall", "#d8c8a8")))
	var floor := Color(String(zone.get("floor", "#b07c4f")))
	var dark_room := zone_id == "bar"
	var warm := not dark_room

	c.draw_rect(Rect2(0, 0, TownData.W, 146), wall)
	c.draw_rect(Rect2(0, 0, TownData.W, 8), wall.darkened(0.22))
	c.draw_rect(Rect2(0, 8, TownData.W, 3), wall.lightened(0.10))
	# ลายวอลเปเปอร์
	if not dark_room:
		var wx := 0.0
		while wx < TownData.W:
			c.draw_rect(Rect2(wx, 11, 2, 112), wall.darkened(0.06))
			c.draw_circle(Vector2(wx + 32, 58), 2.2, wall.darkened(0.08))
			wx += 64.0
	# ไม้บุผนังด้านล่าง
	c.draw_rect(Rect2(0, 108, TownData.W, 30), wall.darkened(0.16))
	for wx2 in range(0, 960, 48):
		c.draw_rect(Rect2(wx2, 110, 2, 26), wall.darkened(0.28))
	c.draw_rect(Rect2(0, 102, TownData.W, 7), Color("#8a5a3a"))
	c.draw_rect(Rect2(0, 102, TownData.W, 2), Color("#a87a4a"))
	c.draw_rect(Rect2(0, 136, TownData.W, 4), wall.darkened(0.42))
	c.draw_rect(Rect2(0, 140, TownData.W, 6), Color("#5a3e2a"))

	# พื้นไม้ / กระเบื้องตามธีม
	var plank := zone_id in ["home", "neighbor_home", "cafe", "bar", "university", "office"]
	if plank:
		c.draw_rect(Rect2(0, 146, TownData.W, TownData.H - 146), floor)
		for py in range(146, 540, 30):
			c.draw_rect(Rect2(0, py, TownData.W, 2), floor.darkened(0.12))
			var offset := 48.0 if (py / 30) % 2 == 0 else 0.0
			var px := offset
			while px < TownData.W:
				c.draw_rect(Rect2(px, py, 2, 30), floor.darkened(0.08))
				px += 96.0
	else:
		c.draw_rect(Rect2(0, 146, TownData.W, TownData.H - 146), floor)
		var tw := 64.0
		var th := 48.0
		var gx := 0.0
		var ix := 0
		while gx < TownData.W:
			var gy := 146.0
			var iy := 0
			while gy < TownData.H:
				if (ix + iy) % 2 == 0:
					c.draw_rect(Rect2(gx, gy, tw, th), floor.lightened(0.05))
				c.draw_line(Vector2(gx, gy), Vector2(gx + tw, gy), floor.darkened(0.10), 1.0)
				gy += th
				iy += 1
			c.draw_line(Vector2(gx, 146), Vector2(gx, TownData.H), floor.darkened(0.10), 1.0)
			gx += tw
			ix += 1

	# ไฟเพดาน + แสงอบอุ่น
	for lx in [180.0, 480.0, 780.0]:
		c.draw_line(Vector2(lx, 0), Vector2(lx, 32), Color("#4a3a30"), 2.0)
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(lx - 26, 32), Vector2(lx + 26, 32), Vector2(lx + 16, 48), Vector2(lx - 16, 48),
		]), Color("#c8a05a"))
		c.draw_rect(Rect2(lx - 15, 44, 30, 9), Color("#ffe6a0") if hour >= 17 or hour < 7 else Color("#f2ead8"))
		if warm:
			c.draw_circle(Vector2(lx, 54), 42.0, Color(1.0, 0.86, 0.52, 0.045))
			c.draw_circle(Vector2(lx, 54), 74.0, Color(1.0, 0.82, 0.46, 0.022))

	# แสงจากหน้าต่างตอนกลางวัน
	if hour >= 7 and hour < 17:
		for wpos in [Vector2(210, 120), Vector2(740, 120)]:
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(wpos.x - 26, 146), Vector2(wpos.x + 26, 146),
				Vector2(wpos.x + 66, 300), Vector2(wpos.x + 6, 300),
			]), Color(1.0, 0.94, 0.72, 0.07))

	# รายละเอียดตามโซน
	match zone_id:
		"home", "neighbor_home":
			_draw_room_clock(c, Vector2(760, 64), hour)
			# ชั้นวางของเล็ก ๆ
			c.draw_rect(Rect2(300, 52, 120, 5), Color("#8a5a3a"))
			for i in 3:
				c.draw_rect(Rect2(310 + i * 34, 36, 20, 16), Color(["#d85a5a", "#5a8ac0", "#d8b05a"][i]))
		"classroom", "university":
			_draw_room_clock(c, Vector2(880, 64), hour)
			for i in 3:
				c.draw_rect(Rect2(120 + i * 54, 40, 42, 30), Color(["#f2ead8", "#e8f0d8", "#e8e0f0"][i]))
				c.draw_rect(Rect2(126 + i * 54, 46, 30, 3), Color("#8a7a6a"))
				c.draw_rect(Rect2(126 + i * 54, 53, 22, 3), Color("#a89a88"))
		"bar":
			for i in 4:
				c.draw_circle(Vector2(180.0 + i * 200.0, 52.0), 9.0, Color(0.55, 0.4, 0.75, 0.4))
				c.draw_circle(Vector2(180.0 + i * 200.0, 52.0), 22.0, Color(0.45, 0.3, 0.7, 0.08))
		"hospital":
			c.draw_rect(Rect2(0, 100, TownData.W, 8), Color("#a8c8cc"))
			c.draw_rect(Rect2(0, 108, TownData.W, 2), Color("#d8eef0"))
		"cafe":
			_draw_string_lights(c, 40.0, 26.0, 920.0, t)
		"store":
			for i in 3:
				c.draw_rect(Rect2(120 + i * 76, 34, 60, 18), Color("#f2ead8"))
				c.draw_rect(Rect2(126 + i * 76, 40, 48, 3), Color("#8a6a4a"))
				c.draw_rect(Rect2(126 + i * 76, 47, 34, 3), Color("#a88a6a"))
		"mall":
			for i in 5:
				c.draw_rect(Rect2(120 + i * 150, 22, 3, 34), Color("#a88a9a"))
				c.draw_circle(Vector2(121 + i * 150, 60), 7.0, Color("#f2d8e8"))
		"office":
			for i in 4:
				c.draw_rect(Rect2(100 + i * 200, 30, 110, 52), Color("#a8c8d8"))
				c.draw_rect(Rect2(104 + i * 200, 34, 102, 44), Color("#c8e0ec"))
				c.draw_line(Vector2(155 + i * 200, 34), Vector2(155 + i * 200, 78), Color("#8aa8b8"), 2.0)
		"gym":
			c.draw_rect(Rect2(0, 16, TownData.W, 4), Color("#5a6470"))
			for i in 4:
				c.draw_rect(Rect2(80 + i * 220, 20, 6, 16), Color("#8a94a0"))
				c.draw_circle(Vector2(83 + i * 220, 42), 5.0, Color("#ffe6a0"))


static func _draw_room_clock(c: CanvasItem, pos: Vector2, hour: int) -> void:
	c.draw_circle(pos, 24.0, Color("#6b4a32"))
	c.draw_circle(pos, 20.0, Color("#f6ecd8"))
	c.draw_circle(pos, 2.2, Color("#8a4a3a"))
	var hx := pos + Vector2(cos(float(hour) / 12.0 * TAU - PI * 0.5), sin(float(hour) / 12.0 * TAU - PI * 0.5)) * 10.0
	var mx := pos + Vector2(0, -16)
	c.draw_line(pos, hx, Color("#4a3a30"), 2.4)
	c.draw_line(pos, mx, Color("#4a3a30"), 1.5)
	for i in 4:
		var a := float(i) * TAU / 4.0
		c.draw_circle(pos + Vector2(cos(a), sin(a)) * 15.0, 1.2, Color("#8a7a6a"))


static func _draw_props(c: CanvasItem, zone: Dictionary, t: float, season: int) -> void:
	for p in zone.get("props", []):
		if not p.has("pos"):
			continue
		_draw_prop(c, p, t, season)


static func _draw_prop(c: CanvasItem, p: Dictionary, t: float, season: int) -> void:
	var pos: Vector2 = p["pos"]
	var typ := String(p.get("type", "plant"))
	var w := float(p.get("w", 0))
	match typ:
		"bed":
			var bw := w if w > 0.0 else 140.0
			c.draw_circle(Vector2(pos.x, pos.y + 2), bw * 0.5, Color(0.15, 0.11, 0.08, 0.14))
			c.draw_rect(Rect2(pos.x - bw / 2 - 4, pos.y - 62, bw + 8, 64), Color("#5a3e2a"))
			c.draw_rect(Rect2(pos.x - bw / 2, pos.y - 58, bw, 56), Color("#f6ecd8"))
			c.draw_rect(Rect2(pos.x - bw / 2 + 4, pos.y - 54, bw - 8, 18), Color("#ffffff"))
			c.draw_rect(Rect2(pos.x - bw / 2 + 4, pos.y - 54, 34, 14), Color("#fffaf0"))
			c.draw_rect(Rect2(pos.x - bw / 2 + 4, pos.y - 34, bw - 8, 30), Color("#7aa8d8"))
			c.draw_rect(Rect2(pos.x - bw / 2 + 4, pos.y - 34, bw - 8, 4), Color("#a8c8e8"))
			for i in 4:
				c.draw_rect(Rect2(pos.x - bw / 2 + 16 + i * 28, pos.y - 30, 10, 3), Color("#c8e0f0"))
		"desk":
			var dw := w if w > 0.0 else 92.0
			c.draw_circle(Vector2(pos.x, pos.y + 2), dw * 0.5, Color(0.15, 0.11, 0.08, 0.13))
			c.draw_rect(Rect2(pos.x - dw / 2, pos.y - 48, dw, 9), Color("#a06a44"))
			c.draw_rect(Rect2(pos.x - dw / 2, pos.y - 48, dw, 3), Color("#c08a5a"))
			c.draw_rect(Rect2(pos.x - dw / 2 + 5, pos.y - 39, 8, 39), Color("#7a5234"))
			c.draw_rect(Rect2(pos.x + dw / 2 - 13, pos.y - 39, 8, 39), Color("#7a5234"))
			c.draw_rect(Rect2(pos.x - dw / 2 + 14, pos.y - 40, dw - 28, 4), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 26, pos.y - 57, 26, 10), Color("#f6ecd8"))
			c.draw_rect(Rect2(pos.x - 22, pos.y - 54, 18, 2), Color("#b8a88a"))
			c.draw_rect(Rect2(pos.x + 8, pos.y - 55, 14, 7), Color("#e8d8b8"))
			c.draw_rect(Rect2(pos.x - 4, pos.y - 62, 8, 6), Color("#f2c04a"))
		"computer":
			c.draw_rect(Rect2(pos.x - 24, pos.y - 56, 48, 36), Color("#2a2e36"))
			c.draw_rect(Rect2(pos.x - 20, pos.y - 52, 40, 27), Color("#6ac0d8"))
			c.draw_rect(Rect2(pos.x - 18, pos.y - 50, 36, 4), Color("#a8e8f0"))
			c.draw_rect(Rect2(pos.x - 8, pos.y - 20, 16, 8), Color("#3a3e46"))
			c.draw_rect(Rect2(pos.x - 16, pos.y - 12, 32, 4), Color("#3a3e46"))
			c.draw_rect(Rect2(pos.x - 10, pos.y - 8, 20, 8), Color("#d8d8d8"))
		"fridge":
			c.draw_rect(Rect2(pos.x - 30, pos.y - 108, 60, 110), Color("#e8eef0"))
			c.draw_rect(Rect2(pos.x - 26, pos.y - 104, 52, 44), Color("#f6fafc"))
			c.draw_rect(Rect2(pos.x - 26, pos.y - 56, 52, 54), Color("#f0f6f8"))
			c.draw_rect(Rect2(pos.x - 30, pos.y - 108, 60, 4), Color("#c8d4d8"))
			c.draw_rect(Rect2(pos.x + 16, pos.y - 98, 5, 18), Color("#8a9aa4"))
			c.draw_rect(Rect2(pos.x + 16, pos.y - 50, 5, 20), Color("#8a9aa4"))
			c.draw_rect(Rect2(pos.x - 12, pos.y - 90, 12, 10), Color("#e05a5a"))
			c.draw_rect(Rect2(pos.x - 8, pos.y - 96, 4, 6), Color("#6ac08a"))
		"tv":
			c.draw_rect(Rect2(pos.x - 52, pos.y - 54, 104, 56), Color("#2a2e36"))
			c.draw_rect(Rect2(pos.x - 48, pos.y - 50, 96, 46), Color("#3a4a5e"))
			c.draw_rect(Rect2(pos.x - 43, pos.y - 45, 86, 36), Color("#5a8aa8"))
			c.draw_rect(Rect2(pos.x - 38, pos.y - 40, 40, 6), Color("#a8d8e8"))
			c.draw_rect(Rect2(pos.x + 8, pos.y - 32, 24, 18), Color("#7aa8c8"))
			c.draw_rect(Rect2(pos.x - 34, pos.y + 2, 68, 5), Color("#1f232a"))
		"sofa":
			c.draw_circle(Vector2(pos.x, pos.y + 1), 54.0, Color(0.15, 0.11, 0.08, 0.13))
			c.draw_rect(Rect2(pos.x - 62, pos.y - 48, 124, 48), Color("#8a4a4a"))
			c.draw_rect(Rect2(pos.x - 56, pos.y - 42, 112, 22), Color("#a85a5a"))
			c.draw_rect(Rect2(pos.x - 62, pos.y - 48, 14, 42), Color("#7a3f3f"))
			c.draw_rect(Rect2(pos.x + 48, pos.y - 48, 14, 42), Color("#7a3f3f"))
			c.draw_rect(Rect2(pos.x - 50, pos.y - 40, 2, 18), Color("#c07a7a"))
			c.draw_rect(Rect2(pos.x - 48, pos.y - 18, 96, 4), Color("#6b3a3a"))
			c.draw_rect(Rect2(pos.x - 52, pos.y - 12, 10, 12), Color("#5a3e2a"))
			c.draw_rect(Rect2(pos.x + 42, pos.y - 12, 10, 12), Color("#5a3e2a"))
			c.draw_rect(Rect2(pos.x - 40, pos.y - 46, 22, 12), Color("#e8c05a"))
		"table":
			var tw := w if w > 0.0 else 100.0
			c.draw_circle(Vector2(pos.x, pos.y + 1), tw * 0.45, Color(0.15, 0.11, 0.08, 0.12))
			c.draw_rect(Rect2(pos.x - tw / 2, pos.y - 42, tw, 10), Color("#a06a44"))
			c.draw_rect(Rect2(pos.x - tw / 2, pos.y - 42, tw, 3), Color("#c08a5a"))
			c.draw_rect(Rect2(pos.x - tw / 2 + 7, pos.y - 32, 7, 32), Color("#7a5234"))
			c.draw_rect(Rect2(pos.x + tw / 2 - 14, pos.y - 32, 7, 32), Color("#7a5234"))
			c.draw_rect(Rect2(pos.x - 14, pos.y - 50, 24, 9), Color("#f6ecd8"))
			c.draw_circle(Vector2(pos.x + 18, pos.y - 46), 5.0, Color("#d86a5a"))
		"chair":
			c.draw_rect(Rect2(pos.x - 15, pos.y - 38, 30, 8), Color("#a06a44"))
			c.draw_rect(Rect2(pos.x - 15, pos.y - 38, 30, 3), Color("#c08a5a"))
			c.draw_rect(Rect2(pos.x - 15, pos.y - 58, 7, 22), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 13, pos.y - 30, 5, 30), Color("#7a5234"))
			c.draw_rect(Rect2(pos.x + 8, pos.y - 30, 5, 30), Color("#7a5234"))
			c.draw_rect(Rect2(pos.x - 15, pos.y - 48, 30, 3), Color("#b07a4a"))
		"counter":
			var cw := w if w > 0.0 else 140.0
			c.draw_circle(Vector2(pos.x, pos.y + 2), cw * 0.5, Color(0.15, 0.11, 0.08, 0.14))
			c.draw_rect(Rect2(pos.x - cw / 2, pos.y - 62, cw, 62), Color("#8a6a4a"))
			c.draw_rect(Rect2(pos.x - cw / 2, pos.y - 64, cw, 10), Color("#c09a62"))
			c.draw_rect(Rect2(pos.x - cw / 2, pos.y - 64, cw, 3), Color("#e0b87a"))
			c.draw_rect(Rect2(pos.x - cw / 2 + 10, pos.y - 50, cw - 20, 7), Color("#6b4a32"))
			for i in 3:
				c.draw_rect(Rect2(pos.x - cw / 2 + 14 + i * 26, pos.y - 40, 16, 18), Color(["#e05a5a", "#e0c05a", "#6ad08a"][i]))
			c.draw_rect(Rect2(pos.x + cw / 2 - 36, pos.y - 80, 28, 20), Color("#3a3e46"))
			c.draw_rect(Rect2(pos.x + cw / 2 - 32, pos.y - 76, 20, 9), Color("#8ad8b0"))
		"shelf":
			c.draw_rect(Rect2(pos.x - 44, pos.y - 78, 88, 80), Color("#a87a4a"))
			c.draw_rect(Rect2(pos.x - 40, pos.y - 74, 80, 66), Color("#6b4a32"))
			for row in 3:
				c.draw_rect(Rect2(pos.x - 40, pos.y - 72 + row * 22, 80, 4), Color("#c29a62"))
				for col in 4:
					var cols := ["#e05a5a", "#5aa8e0", "#e0c05a", "#6ad08a"]
					c.draw_rect(Rect2(pos.x - 34 + col * 19, pos.y - 68 + row * 22, 13, 16), Color(cols[(row + col) % 4]))
					c.draw_rect(Rect2(pos.x - 32 + col * 19, pos.y - 66 + row * 22, 4, 12), Color(1, 1, 1, 0.22))
		"plant":
			c.draw_circle(Vector2(pos.x, pos.y + 1), 16.0, Color(0.15, 0.11, 0.08, 0.12))
			c.draw_rect(Rect2(pos.x - 16, pos.y - 24, 32, 26), Color("#b06a4a"))
			c.draw_rect(Rect2(pos.x - 18, pos.y - 26, 36, 6), Color("#c47a56"))
			c.draw_circle(Vector2(pos.x, pos.y - 40), 15.0, Color("#4f8a3a"))
			c.draw_circle(Vector2(pos.x - 11, pos.y - 48), 11.0, Color("#5aa044"))
			c.draw_circle(Vector2(pos.x + 11, pos.y - 50), 10.0, Color("#6ab04f"))
			c.draw_circle(Vector2(pos.x + 2, pos.y - 56), 7.0, Color("#8ac86a"))
		"treadmill":
			c.draw_rect(Rect2(pos.x - 48, pos.y - 24, 96, 24), Color("#3a3e46"))
			c.draw_rect(Rect2(pos.x - 44, pos.y - 20, 88, 15), Color("#252830"))
			for i in 5:
				c.draw_rect(Rect2(pos.x - 40 + i * 17, pos.y - 19, 10, 13), Color("#3a3e46"))
			c.draw_rect(Rect2(pos.x - 40, pos.y - 70, 6, 48), Color("#8a94a0"))
			c.draw_rect(Rect2(pos.x + 34, pos.y - 70, 6, 48), Color("#8a94a0"))
			c.draw_rect(Rect2(pos.x - 44, pos.y - 74, 88, 7), Color("#3f4652"))
			c.draw_rect(Rect2(pos.x - 20, pos.y - 73, 40, 4), Color("#8ad8e8"))
		"weights":
			c.draw_rect(Rect2(pos.x - 46, pos.y - 24, 92, 24), Color("#3a3e46"))
			for i in 3:
				c.draw_circle(Vector2(pos.x - 28 + i * 28, pos.y - 34), 11.0, Color("#5a6070"))
				c.draw_circle(Vector2(pos.x - 28 + i * 28, pos.y - 34), 4.5, Color("#2a2e36"))
				c.draw_rect(Rect2(pos.x - 33 + i * 28, pos.y - 46, 10, 4), Color("#8a94a0"))
		"atm":
			c.draw_rect(Rect2(pos.x - 32, pos.y - 88, 64, 90), Color("#4a3a30"))
			c.draw_rect(Rect2(pos.x - 27, pos.y - 82, 54, 32), Color("#a8e0c8"))
			c.draw_rect(Rect2(pos.x - 22, pos.y - 76, 44, 6), Color("#2a5a4a"))
			c.draw_rect(Rect2(pos.x - 22, pos.y - 66, 30, 4), Color("#3a7a64"))
			c.draw_rect(Rect2(pos.x - 20, pos.y - 44, 40, 20), Color("#2a2e36"))
			for r in 2:
				for q in 3:
					c.draw_rect(Rect2(pos.x - 17 + q * 12, pos.y - 41 + r * 9, 8, 5), Color("#e8e0c8"))
			c.draw_rect(Rect2(pos.x - 10, pos.y + 2, 20, 4), Color("#2a2e36"))
		"rack":
			c.draw_rect(Rect2(pos.x - 44, pos.y - 4, 88, 4), Color("#8a94a0"))
			c.draw_rect(Rect2(pos.x - 40, pos.y - 90, 5, 88), Color("#8a94a0"))
			c.draw_rect(Rect2(pos.x + 35, pos.y - 90, 5, 88), Color("#8a94a0"))
			c.draw_rect(Rect2(pos.x - 38, pos.y - 88, 76, 4), Color("#5a6070"))
			var cols2 := ["#e05a5a", "#5aa8e0", "#e0c05a", "#6ad08a", "#c07ad0"]
			for i in 5:
				c.draw_rect(Rect2(pos.x - 34 + i * 14, pos.y - 84, 11, 46), Color(cols2[i]))
				c.draw_rect(Rect2(pos.x - 34 + i * 14, pos.y - 84, 11, 4), Color(cols2[i]).lightened(0.25))
				c.draw_rect(Rect2(pos.x - 30 + i * 14, pos.y - 42, 3, 6), Color("#d8d0c0"))
		"speaker":
			c.draw_rect(Rect2(pos.x - 22, pos.y - 80, 44, 80), Color("#1f232a"))
			c.draw_circle(Vector2(pos.x, pos.y - 52), 13.0, Color("#3a3e46"))
			c.draw_circle(Vector2(pos.x, pos.y - 52), 5.0, Color("#6a7480"))
			c.draw_circle(Vector2(pos.x, pos.y - 20), 10.0, Color("#3a3e46"))
			c.draw_rect(Rect2(pos.x - 18, pos.y - 76, 36, 3), Color("#4a505c"))
		"bar":
			var bw2 := w if w > 0.0 else 180.0
			c.draw_rect(Rect2(pos.x - bw2 / 2, pos.y - 62, bw2, 62), Color("#5a3f37"))
			c.draw_rect(Rect2(pos.x - bw2 / 2, pos.y - 66, bw2, 10), Color("#a06a44"))
			c.draw_rect(Rect2(pos.x - bw2 / 2, pos.y - 66, bw2, 3), Color("#c08a5a"))
			c.draw_rect(Rect2(pos.x - bw2 / 2, pos.y - 52, bw2, 6), Color("#3a2a26"))
			for i in 6:
				c.draw_rect(Rect2(pos.x - bw2 / 2 + 14 + i * 24, pos.y - 86, 9, 22),
					Color(["#6ad08a", "#e0c05a", "#e05a5a", "#5aa8e0"][i % 4]))
				c.draw_rect(Rect2(pos.x - bw2 / 2 + 14 + i * 24, pos.y - 90, 9, 5), Color("#2a2e36"))
			var a2 := 0.5 + sin(t * 3.0) * 0.3
			c.draw_circle(Vector2(pos.x, pos.y - 100), 4.0, Color(1.0, 0.85, 0.5, a2))
		"dancefloor":
			var dw2 := 180.0
			for r in 4:
				for q in 6:
					var col2 := Color("#8a5ac0") if (r + q) % 2 == 0 else Color("#5a3a8a")
					c.draw_rect(Rect2(pos.x - dw2 / 2 + q * 30, pos.y - 96 + r * 24, 30, 24), col2)
					c.draw_circle(Vector2(pos.x - dw2 / 2 + q * 30 + 15, pos.y - 84 + r * 24), 3.0,
						Color(0.9, 0.7, 1.0, 0.15 + 0.12 * sin(t * 2.0 + float(r + q))))
			c.draw_rect(Rect2(pos.x - dw2 / 2, pos.y - 96, dw2, 4), Color("#c09ae8"))
		"window":
			c.draw_rect(Rect2(pos.x - 42, pos.y - 38, 84, 62), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 37, pos.y - 33, 74, 52), Color("#a8d8f0"))
			c.draw_rect(Rect2(pos.x - 37, pos.y - 33, 74, 18), Color("#c8e8f8"))
			c.draw_circle(Vector2(pos.x + 20, pos.y - 22), 7.0, Color("#f2e6a0"))
			c.draw_line(Vector2(pos.x, pos.y - 33), Vector2(pos.x, pos.y + 19), Color("#8a5a3a"), 3.0)
			c.draw_line(Vector2(pos.x - 37, pos.y - 6), Vector2(pos.x + 37, pos.y - 6), Color("#8a5a3a"), 3.0)
			c.draw_rect(Rect2(pos.x - 42, pos.y + 20, 84, 4), Color("#c09a6a"))
		"board":
			c.draw_rect(Rect2(pos.x - 112, pos.y - 80, 224, 82), Color("#6b4a32"))
			c.draw_rect(Rect2(pos.x - 106, pos.y - 74, 212, 70), Color("#2f5a42"))
			c.draw_rect(Rect2(pos.x - 92, pos.y - 62, 74, 3), Color("#e8f0e8"))
			c.draw_rect(Rect2(pos.x - 92, pos.y - 51, 116, 3), Color("#c8d8c8"))
			c.draw_rect(Rect2(pos.x - 92, pos.y - 40, 88, 3), Color("#e8f0e8"))
			c.draw_rect(Rect2(pos.x + 30, pos.y - 62, 44, 28), Color("#f2e8c8"))
			c.draw_rect(Rect2(pos.x - 100, pos.y - 8, 200, 4), Color("#a87a4a"))
		"rug":
			var rw := w if w > 0.0 else 200.0
			c.draw_rect(Rect2(pos.x - rw / 2, pos.y - 42, rw, 56), Color("#7a4a4a"))
			c.draw_rect(Rect2(pos.x - rw / 2 + 6, pos.y - 36, rw - 12, 44), Color("#a86a6a"))
			c.draw_rect(Rect2(pos.x - rw / 2 + 14, pos.y - 30, rw - 28, 32), Color("#c08a7a"))
			for i in 6:
				c.draw_rect(Rect2(pos.x - rw / 2 + 22 + i * (rw - 44) / 6.0, pos.y - 26, 6, 24), Color("#e0b0a0"))
		"medcross":
			c.draw_circle(pos, 32.0, Color("#e05a5a"))
			c.draw_circle(pos, 26.0, Color("#fafafa"))
			c.draw_rect(Rect2(pos.x - 7, pos.y - 17, 14, 34), Color("#e05a5a"))
			c.draw_rect(Rect2(pos.x - 17, pos.y - 7, 34, 14), Color("#e05a5a"))
		"bench":
			_draw_bench(c, pos)
		"benchpress":
			c.draw_rect(Rect2(pos.x - 54, pos.y - 32, 108, 16), Color("#2f3540"))
			c.draw_rect(Rect2(pos.x - 48, pos.y - 16, 8, 16), Color("#3f4652"))
			c.draw_rect(Rect2(pos.x + 40, pos.y - 16, 8, 16), Color("#3f4652"))
			c.draw_rect(Rect2(pos.x - 62, pos.y - 68, 6, 52), Color("#8a94a0"))
			c.draw_rect(Rect2(pos.x + 56, pos.y - 68, 6, 52), Color("#8a94a0"))
			c.draw_rect(Rect2(pos.x - 64, pos.y - 72, 128, 5), Color("#b8c0c8"))
			for i in 2:
				c.draw_circle(Vector2(pos.x - 52 + i * 104, pos.y - 70), 13.0, Color("#2a2e36"))
		"water":
			c.draw_rect(Rect2(pos.x - 22, pos.y - 74, 44, 76), Color("#c8d8e0"))
			c.draw_rect(Rect2(pos.x - 16, pos.y - 68, 32, 34), Color("#8ac8e8"))
			c.draw_rect(Rect2(pos.x - 8, pos.y - 32, 16, 16), Color("#5a8aa8"))
			c.draw_circle(Vector2(pos.x, pos.y - 76), 7.0, Color("#3a5a6a"))
		"mirror":
			c.draw_rect(Rect2(pos.x - 74, pos.y - 62, 148, 66), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 68, pos.y - 56, 136, 54), Color("#b8d8e8"))
			c.draw_line(Vector2(pos.x - 44, pos.y - 50), Vector2(pos.x - 12, pos.y - 22), Color("#eef8fc"), 3.0)
			c.draw_line(Vector2(pos.x - 30, pos.y - 50), Vector2(pos.x - 6, pos.y - 28), Color(1, 1, 1, 0.55), 2.0)
		"bookshelf":
			c.draw_rect(Rect2(pos.x - 44, pos.y - 82, 88, 84), Color("#6b4a32"))
			c.draw_rect(Rect2(pos.x - 40, pos.y - 78, 80, 76), Color("#4a3424"))
			for row in 3:
				c.draw_rect(Rect2(pos.x - 40, pos.y - 76 + row * 25, 80, 4), Color("#9a6a44"))
				for col in 4:
					c.draw_rect(Rect2(pos.x - 36 + col * 19, pos.y - 72 + row * 25, 12, 19),
						Color(["#e05a5a", "#5aa8e0", "#e0c05a", "#6ad08a"][(row + col) % 4]))
		"door_mat":
			c.draw_rect(Rect2(pos.x - 46, pos.y - 10, 92, 20), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 40, pos.y - 7, 80, 14), Color("#c49a6a"))
			c.draw_rect(Rect2(pos.x - 40, pos.y - 7, 80, 3), Color("#e8c8a0"))
			var dp := 0.5 + sin(t * 3.0) * 0.5
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(pos.x - 10, pos.y - 48), Vector2(pos.x + 10, pos.y - 48), Vector2(pos.x, pos.y - 32),
			]), Color(1.0, 0.9, 0.45, 0.55 + dp * 0.35))
		"easel":
			c.draw_rect(Rect2(pos.x - 34, pos.y - 92, 68, 54), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 29, pos.y - 88, 58, 46), Color("#f6ecd8"))
			c.draw_circle(Vector2(pos.x - 10, pos.y - 72), 9.0, Color("#7ac0d8"))
			c.draw_circle(Vector2(pos.x + 10, pos.y - 62), 11.0, Color("#8ac86a"))
			c.draw_rect(Rect2(pos.x - 26, pos.y - 56, 52, 10), Color("#d8b05a"))
			c.draw_line(Vector2(pos.x - 24, pos.y - 38), Vector2(pos.x - 30, pos.y - 2), Color("#6b4a32"), 4.0)
			c.draw_line(Vector2(pos.x + 24, pos.y - 38), Vector2(pos.x + 30, pos.y - 2), Color("#6b4a32"), 4.0)
			c.draw_line(Vector2(pos.x, pos.y - 38), Vector2(pos.x, pos.y - 2), Color("#7a5234"), 3.0)
		"kitchen":
			c.draw_rect(Rect2(pos.x - 62, pos.y - 70, 124, 72), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 58, pos.y - 66, 116, 10), Color("#b08a5a"))
			c.draw_rect(Rect2(pos.x - 52, pos.y - 52, 46, 46), Color("#6b4a32"))
			c.draw_circle(Vector2(pos.x - 29, pos.y - 29), 13.0, Color("#3a3e46"))
			c.draw_circle(Vector2(pos.x - 29, pos.y - 29), 8.0, Color("#5a6070"))
			c.draw_rect(Rect2(pos.x + 6, pos.y - 58, 44, 8), Color("#3a3e46"))
			for i in 2:
				c.draw_rect(Rect2(pos.x + 10 + i * 20, pos.y - 54, 12, 4), Color("#8a94a0"))
			c.draw_rect(Rect2(pos.x + 8, pos.y - 84, 46, 26), Color("#c8d0d4"))
			c.draw_rect(Rect2(pos.x + 12, pos.y - 80, 38, 5), Color("#e8eef0"))
			c.draw_rect(Rect2(pos.x + 12, pos.y - 72, 8, 8), Color("#e05a5a"))
			c.draw_rect(Rect2(pos.x + 24, pos.y - 70, 8, 6), Color("#6ac08a"))
		"workbench":
			c.draw_rect(Rect2(pos.x - 56, pos.y - 48, 112, 10), Color("#a06a44"))
			c.draw_rect(Rect2(pos.x - 56, pos.y - 48, 112, 3), Color("#c08a5a"))
			c.draw_rect(Rect2(pos.x - 50, pos.y - 38, 9, 38), Color("#7a5234"))
			c.draw_rect(Rect2(pos.x + 41, pos.y - 38, 9, 38), Color("#7a5234"))
			c.draw_rect(Rect2(pos.x - 44, pos.y - 40, 88, 4), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 44, pos.y - 58, 22, 10), Color("#8a94a0"))
			c.draw_rect(Rect2(pos.x - 14, pos.y - 60, 26, 12), Color("#b08a5a"))
			c.draw_circle(Vector2(pos.x + 30, pos.y - 54), 7.0, Color("#e0c05a"))
			c.draw_rect(Rect2(pos.x + 26, pos.y - 52, 8, 2), Color("#8a6a3a"))
		"picture":
			c.draw_rect(Rect2(pos.x - 34, pos.y - 44, 68, 48), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 29, pos.y - 39, 58, 38), Color("#f6ecd8"))
			c.draw_circle(Vector2(pos.x - 12, pos.y - 28), 7.0, Color("#f2c39b"))
			c.draw_circle(Vector2(pos.x + 10, pos.y - 30), 6.0, Color("#e8b98a"))
			c.draw_rect(Rect2(pos.x - 18, pos.y - 18, 12, 12), Color("#8ac86a"))
			c.draw_rect(Rect2(pos.x + 4, pos.y - 20, 14, 14), Color("#7ab0d8"))
		"sparkle":
			var bob := sin(t * 2.2) * 4.0
			var glow_pos := pos + Vector2(0, -26 + bob)
			c.draw_circle(Vector2(pos.x, pos.y + 1), 13.0, Color(0.15, 0.11, 0.08, 0.12))
			c.draw_circle(glow_pos, 16.0, Color(1.0, 0.9, 0.55, 0.08))
			c.draw_circle(glow_pos, 9.0, Color(1.0, 0.9, 0.55, 0.18))
			var icon_col := Color("#f2a8c2") if season == 0 else (Color("#8ad8a0") if season == 1 else (Color("#e8a04a") if season == 2 else Color("#b8e0f0")))
			match season:
				0:
					for i in 5:
						var a := float(i) * TAU / 5.0 + t * 0.6
						c.draw_circle(glow_pos + Vector2(cos(a), sin(a)) * 6.0, 3.2, icon_col)
				1:
					c.draw_circle(glow_pos, 4.0, icon_col)
					c.draw_line(glow_pos + Vector2(-4, 0), glow_pos + Vector2(-9, -4), Color(0.8, 0.95, 0.9, 0.7), 1.5)
					c.draw_line(glow_pos + Vector2(4, 0), glow_pos + Vector2(9, -4), Color(0.8, 0.95, 0.9, 0.7), 1.5)
				2:
					c.draw_colored_polygon(PackedVector2Array([
						glow_pos + Vector2(0, -7), glow_pos + Vector2(6, -2),
						glow_pos + Vector2(3, 7), glow_pos + Vector2(-3, 7), glow_pos + Vector2(-6, -2),
					]), icon_col)
					c.draw_line(glow_pos + Vector2(0, 4), glow_pos + Vector2(0, -5), Color("#8a5a3a"), 1.5)
				_:
					for i in 3:
						var a2 := float(i) * TAU / 3.0 - PI * 0.5
						c.draw_line(glow_pos, glow_pos + Vector2(cos(a2), sin(a2)) * 8.0, icon_col, 2.0)
			for i in 4:
				var a3 := t * 1.4 + float(i) * TAU / 4.0
				var sp := glow_pos + Vector2(cos(a3), sin(a3)) * 18.0
				c.draw_circle(sp, 2.0, Color(1.0, 0.97, 0.82, 0.5 + 0.3 * sin(t * 4.0 + float(i))))
		"farm_plot":
			var idx := int(p.get("index", 0))
			var stage := Game.farm_stage(idx)
			var crop_id := Game.farm_crop(idx)
			c.draw_circle(Vector2(pos.x, pos.y + 2), 43.0, Color(0.15, 0.11, 0.08, 0.12))
			c.draw_rect(Rect2(pos.x - 40, pos.y - 36, 80, 40), Color("#5a3c26"))
			c.draw_rect(Rect2(pos.x - 36, pos.y - 33, 72, 34), Color("#7a5234"))
			for i in 3:
				c.draw_rect(Rect2(pos.x - 33, pos.y - 29 + i * 11, 66, 6), Color("#8f6440"))
				c.draw_rect(Rect2(pos.x - 33, pos.y - 29 + i * 11, 66, 2), Color("#a5764c"))
			if bool(Game.farm_plot_data(idx).get("watered", false)):
				c.draw_circle(Vector2(pos.x + 33, pos.y - 30), 5.0, Color("#7ac0e8"))
				c.draw_circle(Vector2(pos.x + 33, pos.y - 30), 2.5, Color("#c8ecfa"))
			if stage != "empty":
				var grow := 0.35
				match stage:
					"sprout":
						grow = 0.6
					"grown":
						grow = 0.85
					"ready":
						grow = 1.0
				_draw_crop_plants(c, crop_id, stage, grow, Vector2(pos.x, pos.y - 8.0))
			if stage == "ready":
				var pulse2 := 0.5 + sin(t * 4.0) * 0.5
				c.draw_circle(Vector2(pos.x, pos.y - 54), 8.0, Color(1.0, 0.9, 0.5, 0.14 + pulse2 * 0.14))
		"farm_sign":
			c.draw_rect(Rect2(pos.x - 4, pos.y - 46, 8, 46), Color("#7a5234"))
			c.draw_rect(Rect2(pos.x - 44, pos.y - 78, 88, 38), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 40, pos.y - 74, 80, 30), Color("#c49a6a"))
			c.draw_circle(Vector2(pos.x - 22, pos.y - 58), 8.0, Color("#8ac86a"))
			c.draw_line(Vector2(pos.x - 22, pos.y - 50), Vector2(pos.x - 22, pos.y - 64), Color("#4a7a3a"), 2.0)
			c.draw_circle(Vector2(pos.x + 14, pos.y - 60), 9.0, Color("#e0624a"))
			c.draw_rect(Rect2(pos.x + 11, pos.y - 70, 6, 5), Color("#5a9a4a"))
		"pier":
			c.draw_rect(Rect2(pos.x - 46, pos.y - 16, 92, 9), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 46, pos.y - 16, 92, 3), Color("#b08050"))
			for i in 4:
				c.draw_rect(Rect2(pos.x - 42 + i * 24, pos.y - 7, 6, 22), Color("#6b452c"))
			c.draw_rect(Rect2(pos.x - 54, pos.y + 11, 108, 5), Color("#5a3e2a"))
			c.draw_line(Vector2(pos.x + 20, pos.y - 16), Vector2(pos.x + 46, pos.y - 66), Color("#c8a060"), 2.0)
			c.draw_line(Vector2(pos.x + 46, pos.y - 66), Vector2(pos.x + 52, pos.y - 20), Color(0.92, 0.94, 0.97, 0.55), 1.0)
			c.draw_circle(Vector2(pos.x + 52, pos.y - 18), 3.0, Color("#e05a4a"))
		"bug_spot":
			c.draw_circle(Vector2(pos.x, pos.y + 2), 25.0, Color(0.15, 0.11, 0.08, 0.12))
			for i in 3:
				var bx := pos.x - 14.0 + float(i) * 14.0
				c.draw_line(Vector2(bx, pos.y), Vector2(bx, pos.y - 18), Color("#5a9a4a"), 2.0)
				c.draw_circle(Vector2(bx, pos.y - 22), 6.0, Color(["#f2a8c2", "#f2d05a", "#b09ae8"][i]))
				c.draw_circle(Vector2(bx, pos.y - 22), 2.5, Color("#fff2b0"))
			var wing := 3.0 + sin(t * 5.0) * 1.5
			c.draw_circle(Vector2(pos.x + 15, pos.y - 44), wing + 2.0, Color(0.98, 0.7, 0.82, 0.92))
			c.draw_circle(Vector2(pos.x + 23, pos.y - 44), wing + 2.0, Color(0.98, 0.82, 0.9, 0.92))
			c.draw_rect(Rect2(pos.x + 18, pos.y - 44, 2, 6), Color("#5a3a3a"))
		"coop":
			c.draw_circle(Vector2(pos.x, pos.y + 2), 42.0, Color(0.15, 0.11, 0.08, 0.13))
			c.draw_rect(Rect2(pos.x - 38, pos.y - 56, 76, 58), Color("#c49a6a"))
			c.draw_rect(Rect2(pos.x - 34, pos.y - 52, 68, 52), Color("#d8b482"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(pos.x - 48, pos.y - 54), Vector2(pos.x, pos.y - 92),
				Vector2(pos.x + 48, pos.y - 54),
			]), Color("#b0533f"))
			c.draw_rect(Rect2(pos.x - 14, pos.y - 34, 28, 34), Color("#8a5a3a"))
			c.draw_rect(Rect2(pos.x - 10, pos.y - 30, 20, 26), Color("#6b452c"))
			c.draw_rect(Rect2(pos.x + 18, pos.y - 40, 10, 10), Color("#f2d05a"))
			var peck := absf(sin(t * 2.2)) * 3.0
			c.draw_circle(Vector2(pos.x - 58, pos.y - 12), 9.0, Color("#f6ecd8"))
			c.draw_circle(Vector2(pos.x - 58, pos.y - 22), 6.0, Color("#f6ecd8"))
			c.draw_rect(Rect2(pos.x - 62, pos.y - 24, 2, 2), Color("#2a2018"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(pos.x - 52, pos.y - 21), Vector2(pos.x - 44, pos.y - 19 + peck),
				Vector2(pos.x - 52, pos.y - 17),
			]), Color("#e8a03a"))
			c.draw_rect(Rect2(pos.x - 60, pos.y - 4, 2 + peck, 4), Color("#e8a03a"))
		"back_door":
			c.draw_rect(Rect2(pos.x - 30, pos.y - 78, 60, 80), Color("#6b452c"))
			c.draw_rect(Rect2(pos.x - 25, pos.y - 73, 50, 72), Color("#9a6a44"))
			c.draw_rect(Rect2(pos.x - 21, pos.y - 69, 42, 30), Color("#b08050"))
			c.draw_rect(Rect2(pos.x - 21, pos.y - 35, 42, 30), Color("#a5764c"))
			c.draw_rect(Rect2(pos.x + 14, pos.y - 48, 4, 4), Color("#e8c85a"))
			c.draw_rect(Rect2(pos.x - 34, pos.y - 82, 68, 6), Color("#5a3e2a"))
		"stall":
			_draw_market_stall(c, pos, t)
		"bicycle":
			_draw_bicycle(c, pos)
		_:
			c.draw_rect(Rect2(pos.x - 20, pos.y - 20, 40, 20), Color("#8a6a4a"))

	# จุดบอกว่ากดใช้ได้
	if String(p.get("action", "")) != "":
		var pulse := 0.5 + sin(t * 4.0) * 0.5
		var iy := pos.y - 96.0
		c.draw_circle(Vector2(pos.x, iy - 2), 6.0, Color(1.0, 0.9, 0.5, 0.10 + pulse * 0.10))
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(pos.x - 6, iy), Vector2(pos.x + 6, iy), Vector2(pos.x, iy + 9),
		]), Color(1.0, 0.92, 0.5, 0.55 + pulse * 0.45))


# ============================================================
#  คน
# ============================================================

# ============================================================
#  พืชในแปลง — แต่ละชนิดมีรูปทรงของตัวเอง
# ============================================================
static func _draw_crop_plants(c: CanvasItem, crop_id: String, stage: String, grow: float, base: Vector2) -> void:
	var ready := stage == "ready"
	match crop_id:
		"tomato":
			for i in 3:
				var bx := base.x - 22.0 + float(i) * 22.0
				c.draw_line(Vector2(bx, base.y), Vector2(bx, base.y - 26.0 * grow), Color("#4a7a3a"), 2.0)
				c.draw_line(Vector2(bx, base.y - 9.0 * grow), Vector2(bx - 7.0, base.y - 15.0 * grow), Color("#5a9a4a"), 1.5)
				c.draw_line(Vector2(bx, base.y - 14.0 * grow), Vector2(bx + 7.0, base.y - 20.0 * grow), Color("#5a9a4a"), 1.5)
				if ready:
					c.draw_circle(Vector2(bx - 4.0, base.y - 10.0 * grow), 3.3, Color("#e0624a"))
					c.draw_circle(Vector2(bx + 4.0, base.y - 16.0 * grow), 3.3, Color("#e0624a"))
					c.draw_circle(Vector2(bx + 1.0, base.y - 8.0 * grow), 2.8, Color("#f08a6a"))
				elif grow > 0.7:
					c.draw_circle(Vector2(bx - 4.0, base.y - 12.0 * grow), 2.0, Color("#e88a6a"))
					c.draw_circle(Vector2(bx + 4.0, base.y - 17.0 * grow), 2.0, Color("#e88a6a"))
		"corn":
			for i in 2:
				var bx := base.x - 14.0 + float(i) * 28.0
				c.draw_line(Vector2(bx, base.y), Vector2(bx, base.y - 32.0 * grow), Color("#6a9a4a"), 2.5)
				c.draw_line(Vector2(bx, base.y - 8.0 * grow), Vector2(bx - 12.0, base.y - 3.0), Color("#7ab85a"), 3.0)
				c.draw_line(Vector2(bx, base.y - 15.0 * grow), Vector2(bx + 12.0, base.y - 9.0), Color("#7ab85a"), 3.0)
				c.draw_line(Vector2(bx, base.y - 22.0 * grow), Vector2(bx - 10.0, base.y - 30.0 * grow), Color("#8ac86a"), 2.5)
				if grow > 0.7:
					var ear_y := base.y - 22.0 * grow
					_ellipse(c, Vector2(bx + 4.0, ear_y), 3.6, 7.0 * grow, Color("#f2c84a"))
					c.draw_line(Vector2(bx + 1.0, ear_y - 5.0), Vector2(bx + 1.0, ear_y + 5.0), Color("#d8a83a"), 1.0)
					c.draw_line(Vector2(bx + 6.0, ear_y - 5.0), Vector2(bx + 6.0, ear_y + 5.0), Color("#d8a83a"), 1.0)
		"pumpkin":
			var cx := base.x
			c.draw_line(Vector2(cx - 20.0, base.y - 2.0), Vector2(cx + 20.0, base.y - 5.0), Color("#5a9a4a"), 2.0)
			for i in 3:
				var lx := cx - 14.0 + float(i) * 14.0
				c.draw_circle(Vector2(lx, base.y - 4.0), 5.0 * grow + 1.0, Color("#6aa84a") if i % 2 == 0 else Color("#7ab85a"))
			var pr := 4.0 + 7.0 * grow
			_ellipse(c, Vector2(cx + 2.0, base.y - pr * 0.55), pr, pr * 0.8, Color("#e8903a"))
			c.draw_line(Vector2(cx + 2.0, base.y - pr * 1.35), Vector2(cx + 2.0, base.y - pr * 1.55), Color("#6a9a4a"), 2.0)
			if ready:
				c.draw_line(Vector2(cx - 3.0, base.y - pr * 1.15), Vector2(cx - 3.0, base.y - 1.0), Color("#c8742a"), 1.0)
				c.draw_line(Vector2(cx + 7.0, base.y - pr * 1.15), Vector2(cx + 7.0, base.y - 1.0), Color("#c8742a"), 1.0)
				c.draw_circle(Vector2(cx - 6.0, base.y - pr * 0.7), 2.0, Color(1.0, 0.95, 0.7, 0.46))
		"strawberry":
			for i in 3:
				var bx := base.x - 22.0 + float(i) * 22.0
				var r := 4.0 + 4.0 * grow
				c.draw_circle(Vector2(bx, base.y - r), r, Color("#5a9a4a"))
				c.draw_circle(Vector2(bx - r * 0.6, base.y - r * 0.4), r * 0.7, Color("#6ab85a"))
				if grow > 0.7:
					c.draw_circle(Vector2(bx - 3.0, base.y - 6.0), 2.8, Color("#e05a7a"))
					c.draw_circle(Vector2(bx + 3.0, base.y - 9.0), 2.4, Color("#e05a7a"))
					c.draw_circle(Vector2(bx + 1.0, base.y - 3.0), 2.0, Color("#f07a9a"))
					c.draw_circle(Vector2(bx + 4.0, base.y - 14.0), 1.2, Color("#fff2d8"))
		_:
			for i in 3:
				var bx := base.x - 22.0 + float(i) * 22.0
				var r := 3.0 * grow + 1.5
				c.draw_circle(Vector2(bx - 3.0, base.y - 5.0 * grow), r, Color("#6aa84a"))
				c.draw_circle(Vector2(bx + 3.0, base.y - 7.0 * grow), r, Color("#8ac86a"))
				c.draw_circle(Vector2(bx, base.y - 10.0 * grow), r * 1.2, Color("#a8d878"))


# ============================================================
#  คน — cozy chibi renderer v7
#  หัวโตเล็กน้อย • มีคอ/ไหล่/มือ/ขา/รองเท้าแยกชัด • หันซ้าย/ขวา/หลัง
# ============================================================

static func draw_person(c: CanvasItem, foot: Vector2, pal: Dictionary, scale: float, walk_t: float, facing: int, idle_t: float = 0.0) -> void:
	var s := maxf(scale, 0.3)
	var moving := walk_t > 0.0001
	var step_t := walk_t * 12.0
	var bob := (absf(sin(step_t)) * 1.3 - 0.65) * s if moving else sin(idle_t * 2.0) * 0.55 * s
	var base := Vector2(foot.x, foot.y + bob)
	var dir := 1.0 if facing >= 0 else -1.0
	var expression := String(pal.get("expression", "neutral"))

	var skin := Color(String(pal.get("skin", "#f2c39b")))
	var hair := Color(String(pal.get("hair", "#3a2a1a")))
	var shirt := Color(String(pal.get("shirt", "#4aa3ff")))
	var pants := Color(String(pal.get("pants", "#2e3a59")))
	var shoes := Color(String(pal.get("shoes", "#2a2018")))
	var style := String(pal.get("style", "normal"))
	var hair_style := String(pal.get("hair_style", "short"))
	var accessory := String(pal.get("accessory", "none"))
	var outfit := String(pal.get("outfit", ""))
	var sitting := String(pal.get("pose", "stand")) == "sit"

	var line := Color("#3a2a20")
	var line_soft := Color(line.r, line.g, line.b, 0.55)
	var shadow := Color(0.14, 0.10, 0.07, 0.20)
	var blush := Color(0.90, 0.48, 0.42, 0.30)

	# ---------- สัดส่วน ----------
	var drop := 2.2 * s if sitting else 0.0
	var hip_y := base.y - 19.5 * s + drop
	var shoulder_y := base.y - 35.5 * s + drop
	var head_cy := base.y - 46.0 * s + drop
	var head_rx := 9.8 * s
	var head_ry := 8.8 * s
	var head_c := Vector2(base.x, head_cy)
	var neck_top := head_cy + head_ry - 1.0 * s
	var neck_bot := shoulder_y + 2.0 * s

	var stride := sin(step_t) * 3.2 * s if moving else 0.0
	var swing := sin(step_t) * 2.8 * s if moving else sin(idle_t * 1.8) * 0.45 * s

	# ---------- เงา ----------
	_ellipse(c, Vector2(foot.x, foot.y + 1.6 * s), 12.6 * s, 3.3 * s, shadow)

	# ---------- ผมด้านหลัง (อยู่หลังลำตัว) ----------
	_draw_back_hair(c, head_c, head_rx, head_ry, s, hair, hair_style, dir, idle_t)

	# ---------- ขา / รองเท้า ----------
	if sitting:
		# นั่งพับขา — ต้นขาไปข้างหน้า ปลายเท้าลงพื้น
		_draw_sit_leg(c, Vector2(base.x - 3.6 * s, hip_y), s, dir,
			pants.darkened(0.12), shoes.darkened(0.12), line_soft)
		_draw_sit_leg(c, Vector2(base.x + 3.6 * s, hip_y), s, dir,
			pants, shoes, line_soft)
	else:
		var far_leg := base.x - 4.0 * s - stride * 0.9
		var near_leg := base.x + 4.0 * s + stride * 0.9
		var lift_l := maxf(0.0, sin(step_t)) * 1.5 * s if moving else 0.0
		var lift_r := maxf(0.0, -sin(step_t)) * 1.5 * s if moving else 0.0
		_draw_leg(c, Vector2(far_leg, hip_y), Vector2(far_leg + stride * 0.25, base.y - 3.8 * s - lift_l),
			s, pants.darkened(0.10), shoes.darkened(0.10), dir, line_soft)
		_draw_leg(c, Vector2(near_leg, hip_y), Vector2(near_leg + stride * 0.25, base.y - 3.8 * s - lift_r),
			s, pants, shoes, dir, line_soft)

	# ---------- แขนไกล (หลังลำตัว) ----------
	var far_side := -1.0 if dir >= 0.0 else 1.0
	_draw_arm(c, Vector2(base.x, shoulder_y), far_side, s, -swing, shirt, skin, line_soft,
		_long_sleeve(outfit, style), false)

	# ---------- คอ ----------
	_capsule(c, Vector2(base.x, neck_bot), Vector2(base.x, neck_top), 3.0 * s, line_soft)
	_capsule(c, Vector2(base.x, neck_bot), Vector2(base.x, neck_top), 2.5 * s, skin.darkened(0.04))
	c.draw_rect(Rect2(base.x - 3.2 * s, neck_top - 1.0 * s, 6.4 * s, 1.8 * s), Color(0.36, 0.23, 0.16, 0.20))

	# ---------- ลำตัว ----------
	_draw_torso(c, base.x, shoulder_y, hip_y, s, shirt, pants, outfit, style, accessory, skin, line, line_soft)

	# ---------- แขนใกล้ (หน้าลำตัว) ----------
	_draw_arm(c, Vector2(base.x, shoulder_y), dir, s, swing, shirt, skin, line_soft,
		_long_sleeve(outfit, style), true)

	# ---------- หัว ----------
	_ellipse(c, head_c, head_rx + 0.9 * s, head_ry + 0.9 * s, line_soft)
	_ellipse(c, head_c, head_rx, head_ry, skin)
	# หู
	for side in [-1.0, 1.0]:
		var ear_x: float = head_c.x + side * (head_rx - 0.7 * s)
		var ear_y := head_cy + 2.1 * s
		c.draw_circle(Vector2(ear_x, ear_y), 2.7 * s, line_soft)
		c.draw_circle(Vector2(ear_x, ear_y), 2.05 * s, skin.darkened(0.05))
	# ใบหน้า
	if facing != 2:
		_draw_face(c, head_c, s, dir, hair, expression, blush)
	else:
		c.draw_rect(Rect2(head_c.x - 2.0 * s, head_cy + head_ry - 2.2 * s, 4.0 * s, 2.4 * s), skin.darkened(0.09))

	# ---------- ผมด้านหน้า ----------
	_draw_front_hair(c, head_c, head_rx, head_ry, s, hair, hair_style, dir, facing, idle_t)

	# ---------- แว่น / ต่างหู / ที่คาดผม / ผ้าพันคอ ----------
	_draw_accessories(c, head_c, head_rx, head_ry, s, accessory, dir, outfit, hair)

	# ---------- หมวก ----------
	_draw_hat_if_any(c, head_c, head_rx, head_ry, s, accessory, dir)


static func _draw_leg(c: CanvasItem, hip: Vector2, ankle: Vector2, s: float,
		pants: Color, shoes: Color, dir: float, line: Color) -> void:
	# ขากางเกงมี outline นุ่ม
	_capsule(c, hip, ankle, 3.7 * s, line)
	_capsule(c, hip, ankle, 2.9 * s, pants)
	# รองเท้าหัวมน
	var heel := ankle + Vector2(-dir * 1.0 * s, 0.0)
	var toe := ankle + Vector2(dir * 3.4 * s, 1.1 * s)
	_capsule(c, heel, toe, 3.2 * s, line)
	_capsule(c, heel, toe, 2.4 * s, shoes)
	c.draw_line(heel + Vector2(0, 2.0 * s), toe + Vector2(0, 2.0 * s),
		shoes.darkened(0.28), 1.1 * s, true)


static func _draw_sit_leg(c: CanvasItem, hip: Vector2, s: float, dir: float,
		pants: Color, shoes: Color, line: Color) -> void:
	var knee := hip + Vector2(dir * 8.4 * s, 1.6 * s)
	var ankle := knee + Vector2(dir * 1.0 * s, 7.8 * s)
	_capsule(c, hip, knee, 3.6 * s, line)
	_capsule(c, hip, knee, 2.8 * s, pants)
	_capsule(c, knee, ankle, 3.0 * s, line)
	_capsule(c, knee, ankle, 2.25 * s, pants.darkened(0.05))
	# รองเท้า
	var heel := ankle + Vector2(-dir * 1.0 * s, 0.4 * s)
	var toe := ankle + Vector2(dir * 3.2 * s, 1.3 * s)
	_capsule(c, heel, toe, 3.0 * s, line)
	_capsule(c, heel, toe, 2.25 * s, shoes)
	c.draw_line(heel + Vector2(0, 1.9 * s), toe + Vector2(0, 1.9 * s),
		shoes.darkened(0.28), 1.0 * s, true)


static func _draw_arm(c: CanvasItem, shoulder: Vector2, side: float, s: float, swing: float,
		shirt: Color, skin: Color, line: Color, long_sleeve: bool, front: bool) -> void:
	var sh := shoulder + Vector2(side * 8.2 * s, 1.7 * s)
	var elbow := sh + Vector2(side * 1.5 * s + swing * 0.55, 6.6 * s)
	var wrist := sh + Vector2(side * 2.6 * s + swing, 13.0 * s)
	# outline
	_capsule(c, sh, elbow, 3.5 * s, line)
	_capsule(c, elbow, wrist, 3.0 * s, line)
	# แขนเสื้อ
	_capsule(c, sh, elbow, 2.8 * s, shirt.darkened(0.05))
	if long_sleeve:
		_capsule(c, elbow, wrist, 2.35 * s, shirt.darkened(0.09))
		c.draw_circle(wrist, 2.45 * s, shirt.darkened(0.15))
	else:
		_capsule(c, elbow, wrist, 2.15 * s, skin)
	# มือ
	var hand := wrist + Vector2(side * 0.5 * s, 0.9 * s)
	c.draw_circle(hand, 2.55 * s, line)
	c.draw_circle(hand, 1.95 * s, skin.lightened(0.03))
	if front:
		c.draw_circle(hand + Vector2(-side * 0.4 * s, -0.5 * s), 0.7 * s, skin.lightened(0.14))


static func _draw_torso(c: CanvasItem, cx: float, shoulder_y: float, hip_y: float, s: float,
		shirt: Color, pants: Color, outfit: String, style: String, accessory: String,
		skin: Color, line: Color, line_soft: Color) -> void:
	var sh_w := 9.6 * s
	var waist_w := 7.5 * s
	var top := shoulder_y - 1.0 * s
	var outline_pts := PackedVector2Array([
		Vector2(cx - sh_w - 0.9 * s, top - 0.9 * s),
		Vector2(cx + sh_w + 0.9 * s, top - 0.9 * s),
		Vector2(cx + waist_w + 0.9 * s, hip_y + 0.9 * s),
		Vector2(cx - waist_w - 0.9 * s, hip_y + 0.9 * s),
	])
	c.draw_colored_polygon(outline_pts, line_soft)
	var body_pts := PackedVector2Array([
		Vector2(cx - sh_w, top), Vector2(cx + sh_w, top),
		Vector2(cx + waist_w, hip_y), Vector2(cx - waist_w, hip_y),
	])
	c.draw_colored_polygon(body_pts, shirt)
	# ไหล่มน
	for side in [-1.0, 1.0]:
		c.draw_circle(Vector2(cx + side * (sh_w - 2.0 * s), shoulder_y + 1.4 * s), 2.9 * s, shirt)
	# คอเสื้อ (เห็นผิว)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 3.0 * s, top), Vector2(cx + 3.0 * s, top),
		Vector2(cx, top + 2.6 * s),
	]), skin.darkened(0.05))
	c.draw_line(Vector2(cx - 3.2 * s, top + 0.6 * s), Vector2(cx + 3.2 * s, top + 0.6 * s),
		shirt.darkened(0.13), 0.9 * s, true)
	# ชายเสื้อ
	c.draw_rect(Rect2(cx - waist_w, hip_y - 2.2 * s, waist_w * 2.0, 2.2 * s), shirt.darkened(0.10))
	c.draw_line(Vector2(cx - waist_w, hip_y - 2.2 * s), Vector2(cx + waist_w, hip_y - 2.2 * s),
		shirt.lightened(0.08), 0.7 * s, true)

	# ---------- รายละเอียดตามชุดจริง ----------
	match outfit:
		"school":
			_draw_school_collar(c, cx, top, s, Color("#f8f8f4"), Color("#23304f"))
			c.draw_circle(Vector2(cx, top + 4.0 * s), 1.7 * s, Color("#c04a5a"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 1.0 * s, top + 4.0 * s), Vector2(cx + 1.0 * s, top + 4.0 * s),
				Vector2(cx + 2.6 * s, top + 8.2 * s), Vector2(cx + 0.2 * s, top + 7.0 * s),
			]), Color("#c04a5a"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 3.4 * s, hip_y - 0.5 * s), Vector2(cx + 3.4 * s, hip_y - 0.5 * s),
				Vector2(cx + 1.8 * s, hip_y + 1.4 * s), Vector2(cx - 1.8 * s, hip_y + 1.4 * s),
			]), pants.darkened(0.08))
		"work":
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 5.2 * s, top + 1.2 * s), Vector2(cx - 1.4 * s, top + 2.6 * s),
				Vector2(cx - 2.6 * s, hip_y - 1.0 * s), Vector2(cx - 6.6 * s, hip_y - 3.0 * s),
			]), Color("#3a4658"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(cx + 5.2 * s, top + 1.2 * s), Vector2(cx + 1.4 * s, top + 2.6 * s),
				Vector2(cx + 2.6 * s, hip_y - 1.0 * s), Vector2(cx + 6.6 * s, hip_y - 3.0 * s),
			]), Color("#3a4658"))
		"winter":
			c.draw_rect(Rect2(cx - waist_w - 0.8 * s, hip_y - 4.5 * s, (waist_w + 0.8) * 2.0, 7.5 * s), shirt.darkened(0.04))
			for i in 3:
				c.draw_circle(Vector2(cx + 2.0 * s, top + (4.0 + i * 4.2) * s), 0.9 * s, Color("#f2e6c8"))
		"cozy":
			for i in 3:
				c.draw_line(Vector2(cx - waist_w + 1.0 * s, top + (4.0 + i * 4.0) * s),
					Vector2(cx + waist_w - 1.0 * s, top + (4.0 + i * 4.0) * s),
					shirt.darkened(0.10), 0.8 * s, true)
			c.draw_rect(Rect2(cx - 4.0 * s, top + 2.0 * s, 8.0 * s, 1.6 * s), shirt.lightened(0.12))
		"raincoat":
			c.draw_line(Vector2(cx, top + 3.0 * s), Vector2(cx, hip_y - 1.0 * s),
				shirt.darkened(0.18), 1.1 * s, true)
			for i in 3:
				c.draw_circle(Vector2(cx + 1.4 * s, top + (5.0 + i * 4.4) * s), 1.0 * s, shirt.darkened(0.25))
		"thai":
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(cx - waist_w - 0.4 * s, top + 10.5 * s), Vector2(cx + waist_w + 0.4 * s, top + 9.2 * s),
				Vector2(cx + waist_w + 0.4 * s, top + 12.4 * s), Vector2(cx - waist_w - 0.4 * s, top + 13.8 * s),
			]), Color("#f2d05a"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(cx + 2.0 * s, top + 1.0 * s), Vector2(cx + 4.4 * s, top + 2.0 * s),
				Vector2(cx + 1.0 * s, top + 9.0 * s), Vector2(cx - 0.8 * s, top + 8.0 * s),
			]), Color("#f2d05a"))
		"party", "luxury":
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(cx - waist_w + 0.5 * s, hip_y - 1.0 * s), Vector2(cx + waist_w - 0.5 * s, hip_y - 1.0 * s),
				Vector2(cx + waist_w + 1.8 * s, hip_y + 4.8 * s), Vector2(cx - waist_w - 1.8 * s, hip_y + 4.8 * s),
			]), pants)
			c.draw_line(Vector2(cx - 3.4 * s, top + 2.4 * s), Vector2(cx + 3.4 * s, top + 2.4 * s),
				Color("#f2d88a"), 1.1 * s, true)
			if outfit == "luxury":
				c.draw_circle(Vector2(cx, top + 4.2 * s), 1.4 * s, Color("#f2e6a0"))
		"sleep":
			for i in 3:
				c.draw_line(Vector2(cx - waist_w + 1.0 * s, top + (4.0 + i * 4.4) * s),
					Vector2(cx + waist_w - 1.0 * s, top + (4.0 + i * 4.4) * s),
					shirt.lightened(0.18), 1.0 * s, true)
		"sport":
			c.draw_rect(Rect2(cx - waist_w, top + 5.0 * s, waist_w * 2.0, 2.8 * s), shirt.darkened(0.16))
			c.draw_rect(Rect2(cx - waist_w, top + 5.4 * s, waist_w * 2.0, 0.9 * s), Color(1, 1, 1, 0.55))
		"heirloom_blue", "heirloom_rose", "heirloom_green":
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 7.0 * s, top + 2.0 * s), Vector2(cx + 7.0 * s, top + 2.0 * s),
				Vector2(cx + 5.0 * s, hip_y - 2.0 * s), Vector2(cx - 5.0 * s, hip_y - 2.0 * s),
			]), shirt.lightened(0.16))
			c.draw_circle(Vector2(cx, top + 6.0 * s), 1.2 * s, shirt.darkened(0.12))
		_:
			c.draw_line(Vector2(cx - 4.5 * s, top + 6.0 * s), Vector2(cx + 4.5 * s, top + 6.0 * s),
				shirt.darkened(0.10), 0.8 * s, true)

	# ---------- รายละเอียดตามสไตล์ NPC ----------
	match style:
		"chef":
			c.draw_rect(Rect2(cx - 5.0 * s, top + 2.0 * s, 2.0 * s, 11.0 * s), Color("#d8d8d0"))
			c.draw_rect(Rect2(cx + 3.0 * s, top + 2.0 * s, 2.0 * s, 11.0 * s), Color("#d8d8d0"))
			c.draw_rect(Rect2(cx - 5.0 * s, top - 0.5 * s, 10.0 * s, 2.6 * s), Color("#c04a3a"))
		"child":
			c.draw_rect(Rect2(cx - 5.5 * s, top + 3.0 * s, 11.0 * s, 10.5 * s), shirt.lightened(0.10))
			c.draw_rect(Rect2(cx - 5.5 * s, top + 3.0 * s, 2.2 * s, 8.0 * s), shirt.darkened(0.12))
			c.draw_rect(Rect2(cx + 3.3 * s, top + 3.0 * s, 2.2 * s, 8.0 * s), shirt.darkened(0.12))
			c.draw_circle(Vector2(cx - 3.0 * s, top + 4.5 * s), 0.9 * s, Color("#f2d05a"))
			c.draw_circle(Vector2(cx + 3.0 * s, top + 4.5 * s), 0.9 * s, Color("#f2d05a"))
		"chic":
			c.draw_rect(Rect2(cx - waist_w, hip_y - 5.0 * s, waist_w * 2.0, 2.0 * s), Color("#e0c05a"))
			c.draw_circle(Vector2(cx, hip_y - 4.0 * s), 1.2 * s, Color("#f2d88a"))
		"elder":
			c.draw_line(Vector2(cx, top + 2.0 * s), Vector2(cx, hip_y - 2.0 * s),
				shirt.darkened(0.14), 1.0 * s, true)
			for i in 3:
				c.draw_circle(Vector2(cx + 1.0 * s, top + (5.0 + i * 3.8) * s), 0.8 * s, shirt.lightened(0.24))
		"student":
			_draw_school_collar(c, cx, top, s, shirt.lightened(0.22), pants.darkened(0.15))
			c.draw_circle(Vector2(cx, top + 4.0 * s), 1.5 * s, Color("#c04a5a"))
		"formal":
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 4.8 * s, top + 1.0 * s), Vector2(cx - 0.8 * s, top + 3.0 * s),
				Vector2(cx - 2.4 * s, top + 9.0 * s),
			]), shirt.darkened(0.20))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(cx + 4.8 * s, top + 1.0 * s), Vector2(cx + 0.8 * s, top + 3.0 * s),
				Vector2(cx + 2.4 * s, top + 9.0 * s),
			]), shirt.darkened(0.20))
		"sport":
			c.draw_rect(Rect2(cx - waist_w, top + 6.0 * s, waist_w * 2.0, 2.4 * s), Color(1, 1, 1, 0.32))
		"floral":
			c.draw_circle(Vector2(cx + 5.2 * s, top + 4.0 * s), 1.9 * s, Color("#e88aa8"))
			c.draw_circle(Vector2(cx + 5.2 * s, top + 4.0 * s), 0.8 * s, Color("#f2d05a"))
		"vet":
			c.draw_rect(Rect2(cx - 6.0 * s, top + 3.0 * s, 3.2 * s, 4.0 * s), Color("#f8f8f4"))
			c.draw_rect(Rect2(cx - 5.2 * s, top + 3.8 * s, 1.6 * s, 2.4 * s), Color("#d85a5a"))
		"work":
			c.draw_line(Vector2(cx - 3.0 * s, top + 1.5 * s), Vector2(cx + 3.0 * s, top + 7.0 * s),
				Color("#4a6a8a"), 1.0 * s, true)
		"home":
			for i in 2:
				c.draw_circle(Vector2(cx + 1.4 * s, top + (6.0 + i * 4.2) * s), 0.9 * s, shirt.darkened(0.18))
		_:
			pass

	# ---------- เครื่องประดับบนลำตัว ----------
	if accessory == "apron" or style == "vendor" or style == "gardener":
		c.draw_rect(Rect2(cx - 6.2 * s, top + 3.0 * s, 12.4 * s, 12.5 * s), Color("#f0e2c8"))
		c.draw_rect(Rect2(cx - 2.0 * s, top + 4.0 * s, 4.0 * s, 2.0 * s), Color("#c8a87a"))
		c.draw_rect(Rect2(cx - 6.2 * s, hip_y - 2.0 * s, 12.4 * s, 2.2 * s), Color("#d8c8a8"))
		c.draw_line(Vector2(cx - 5.0 * s, top + 1.0 * s), Vector2(cx - 2.4 * s, top + 4.0 * s), Color("#d8c8a8"), 0.9 * s)
		c.draw_line(Vector2(cx + 5.0 * s, top + 1.0 * s), Vector2(cx + 2.4 * s, top + 4.0 * s), Color("#d8c8a8"), 0.9 * s)
	if accessory == "shawl":
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(cx - sh_w - 0.5 * s, top + 1.0 * s), Vector2(cx - 4.0 * s, top + 2.5 * s),
			Vector2(cx - 3.0 * s, top + 10.0 * s), Vector2(cx - sh_w - 0.5 * s, top + 8.0 * s),
		]), Color("#8a6a8a"))
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(cx + sh_w + 0.5 * s, top + 1.0 * s), Vector2(cx + 4.0 * s, top + 2.5 * s),
			Vector2(cx + 3.0 * s, top + 10.0 * s), Vector2(cx + sh_w + 0.5 * s, top + 8.0 * s),
		]), Color("#8a6a8a"))
	if accessory == "tie" or style == "formal":
		c.draw_rect(Rect2(cx - 1.5 * s, top + 2.2 * s, 3.0 * s, 2.2 * s), Color("#7a2e3a"))
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 2.4 * s, top + 4.2 * s), Vector2(cx + 2.4 * s, top + 4.2 * s),
			Vector2(cx, top + 10.0 * s),
		]), Color("#8a3a4a"))
	if accessory == "badge":
		c.draw_rect(Rect2(cx - 6.4 * s, top + 3.0 * s, 3.4 * s, 4.2 * s), Color("#f2f2f2"))
		c.draw_rect(Rect2(cx - 5.1 * s, top + 4.2 * s, 1.4 * s, 2.0 * s), Color("#d85a5a"))
	if accessory == "sash" and outfit != "thai":
		c.draw_rect(Rect2(cx - waist_w, top + 7.0 * s, waist_w * 2.0, 2.8 * s), Color("#f2d05a"))
		c.draw_rect(Rect2(cx - 3.8 * s, top + 9.8 * s, 7.6 * s, 6.0 * s), Color("#f2d05a"))


static func _draw_school_collar(c: CanvasItem, cx: float, top: float, s: float, collar: Color, edge: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 6.0 * s, top + 0.5 * s), Vector2(cx - 0.4 * s, top + 2.4 * s),
		Vector2(cx - 2.8 * s, top + 5.0 * s), Vector2(cx - 6.8 * s, top + 3.0 * s),
	]), collar)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 6.0 * s, top + 0.5 * s), Vector2(cx + 0.4 * s, top + 2.4 * s),
		Vector2(cx + 2.8 * s, top + 5.0 * s), Vector2(cx + 6.8 * s, top + 3.0 * s),
	]), collar)
	c.draw_line(Vector2(cx - 6.0 * s, top + 0.6 * s), Vector2(cx - 2.8 * s, top + 4.8 * s), edge, 0.8 * s, true)
	c.draw_line(Vector2(cx + 6.0 * s, top + 0.6 * s), Vector2(cx + 2.8 * s, top + 4.8 * s), edge, 0.8 * s, true)


static func _draw_face(c: CanvasItem, head_c: Vector2, s: float, dir: float, hair: Color,
		expression: String, blush: Color) -> void:
	var eye_y := head_c.y + 1.7 * s
	var spread := 3.8 * s
	var look := dir * 1.15 * s
	var ex1 := head_c.x - spread + look
	var ex2 := head_c.x + spread + look
	var ink := Color("#3a2a20")
	var brow := hair.darkened(0.25)
	# แก้ม
	c.draw_circle(Vector2(head_c.x - 6.1 * s + look * 0.4, eye_y + 3.7 * s), 1.8 * s, blush)
	c.draw_circle(Vector2(head_c.x + 6.1 * s + look * 0.4, eye_y + 3.7 * s), 1.8 * s, blush)
	# จมูก
	c.draw_circle(Vector2(head_c.x + 1.4 * s + look * 0.5, eye_y + 2.6 * s), 0.75 * s, ink.lerp(Color("#d89a78"), 0.55))

	match expression:
		"happy":
			# ตากลมสดใส + ยิ้มกว้าง
			_ellipse(c, Vector2(ex1, eye_y + 0.2 * s), 2.0 * s, 2.55 * s, ink)
			_ellipse(c, Vector2(ex2, eye_y + 0.2 * s), 2.0 * s, 2.55 * s, ink)
			c.draw_circle(Vector2(ex1 - 0.6 * s, eye_y - 0.8 * s), 0.8 * s, Color("#fffdf6"))
			c.draw_circle(Vector2(ex2 - 0.6 * s, eye_y - 0.8 * s), 0.8 * s, Color("#fffdf6"))
			c.draw_arc(Vector2(head_c.x, eye_y + 3.7 * s), 1.65 * s, 0.15 * PI, 0.85 * PI, 10, Color("#a85a4a"), 0.8 * s, true)
		"tired":
			c.draw_line(Vector2(ex1 - 2.0 * s, eye_y), Vector2(ex1 + 2.0 * s, eye_y), ink, 1.2 * s, true)
			c.draw_line(Vector2(ex2 - 2.0 * s, eye_y), Vector2(ex2 + 2.0 * s, eye_y), ink, 1.2 * s, true)
			c.draw_line(Vector2(head_c.x - 1.6 * s, eye_y + 5.0 * s), Vector2(head_c.x + 1.6 * s, eye_y + 5.0 * s), Color("#a04a3a"), 0.9 * s, true)
			# หยดเหงื่อ
			c.draw_circle(Vector2(head_c.x + 8.0 * s, head_c.y - 4.0 * s), 1.0 * s, Color(0.55, 0.78, 0.95, 0.75))
			c.draw_rect(Rect2(ex1 - 2.4 * s, eye_y - 2.4 * s, 4.8 * s, 0.8 * s), brow)
			c.draw_rect(Rect2(ex2 - 2.4 * s, eye_y - 2.4 * s, 4.8 * s, 0.8 * s), brow)
		"stressed":
			c.draw_line(Vector2(ex1 - 2.4 * s, eye_y - 2.2 * s), Vector2(ex1 + 1.6 * s, eye_y - 0.9 * s), brow, 1.0 * s, true)
			c.draw_line(Vector2(ex2 - 1.6 * s, eye_y - 0.9 * s), Vector2(ex2 + 2.4 * s, eye_y - 2.2 * s), brow, 1.0 * s, true)
			_ellipse(c, Vector2(ex1, eye_y + 0.4 * s), 1.5 * s, 1.6 * s, ink)
			_ellipse(c, Vector2(ex2, eye_y + 0.4 * s), 1.5 * s, 1.6 * s, ink)
			c.draw_line(Vector2(head_c.x - 1.8 * s, eye_y + 5.0 * s), Vector2(head_c.x, eye_y + 4.4 * s), Color("#a04a3a"), 0.9 * s, true)
			c.draw_line(Vector2(head_c.x, eye_y + 4.4 * s), Vector2(head_c.x + 1.8 * s, eye_y + 5.0 * s), Color("#a04a3a"), 0.9 * s, true)
			c.draw_circle(Vector2(head_c.x - 8.6 * s, head_c.y - 3.0 * s), 1.1 * s, Color(0.55, 0.78, 0.95, 0.75))
		"sad":
			c.draw_line(Vector2(ex1 - 2.4 * s, eye_y - 1.2 * s), Vector2(ex1 + 1.8 * s, eye_y - 2.4 * s), brow, 1.0 * s, true)
			c.draw_line(Vector2(ex2 - 1.8 * s, eye_y - 2.4 * s), Vector2(ex2 + 2.4 * s, eye_y - 1.2 * s), brow, 1.0 * s, true)
			_ellipse(c, Vector2(ex1, eye_y + 0.8 * s), 1.6 * s, 2.1 * s, ink)
			_ellipse(c, Vector2(ex2, eye_y + 0.8 * s), 1.6 * s, 2.1 * s, ink)
			c.draw_arc(Vector2(head_c.x, eye_y + 6.2 * s), 1.9 * s, PI * 1.15, PI * 1.85, 10, Color("#a04a3a"), 0.9 * s, true)
		"sick":
			c.draw_line(Vector2(ex1 - 2.0 * s, eye_y + 0.2 * s), Vector2(ex1 + 2.0 * s, eye_y + 0.2 * s), ink, 1.1 * s, true)
			c.draw_line(Vector2(ex2 - 2.0 * s, eye_y + 0.2 * s), Vector2(ex2 + 2.0 * s, eye_y + 0.2 * s), ink, 1.1 * s, true)
			c.draw_line(Vector2(head_c.x - 1.4 * s, eye_y + 5.0 * s), Vector2(head_c.x + 1.4 * s, eye_y + 5.0 * s), Color("#8a5a5a"), 0.9 * s, true)
			# แต้มไข้
			c.draw_circle(Vector2(head_c.x - 5.4 * s, eye_y + 3.8 * s), 1.5 * s, Color(0.85, 0.35, 0.30, 0.28))
			c.draw_circle(Vector2(head_c.x + 5.4 * s, eye_y + 3.8 * s), 1.5 * s, Color(0.85, 0.35, 0.30, 0.28))
			c.draw_circle(Vector2(head_c.x + 8.2 * s, head_c.y - 4.2 * s), 1.0 * s, Color(0.55, 0.78, 0.95, 0.7))
		"love":
			_draw_heart(c, Vector2(ex1, eye_y), 2.1 * s, Color("#e0627a"))
			_draw_heart(c, Vector2(ex2, eye_y), 2.1 * s, Color("#e0627a"))
			c.draw_arc(Vector2(head_c.x, eye_y + 3.8 * s), 1.9 * s, 0.15 * PI, 0.85 * PI, 10, Color("#a04a3a"), 0.9 * s, true)
		_:
			# ตาโตแบบชิบิ + ประกาย
			_ellipse(c, Vector2(ex1, eye_y + 0.2 * s), 2.15 * s, 2.75 * s, ink)
			_ellipse(c, Vector2(ex2, eye_y + 0.2 * s), 2.15 * s, 2.75 * s, ink)
			c.draw_circle(Vector2(ex1 - 0.65 * s, eye_y - 0.85 * s), 0.85 * s, Color("#fffdf6"))
			c.draw_circle(Vector2(ex2 - 0.65 * s, eye_y - 0.85 * s), 0.85 * s, Color("#fffdf6"))
			c.draw_circle(Vector2(ex1 + 0.65 * s, eye_y + 1.1 * s), 0.45 * s, Color(1, 1, 1, 0.55))
			c.draw_circle(Vector2(ex2 + 0.65 * s, eye_y + 1.1 * s), 0.45 * s, Color(1, 1, 1, 0.55))
			c.draw_line(Vector2(head_c.x - 1.1 * s, eye_y + 5.0 * s), Vector2(head_c.x + 1.1 * s, eye_y + 5.0 * s), Color("#a85a4a"), 0.75 * s, true)


static func _draw_heart(c: CanvasItem, center: Vector2, r: float, col: Color) -> void:
	c.draw_circle(center + Vector2(-r * 0.45, -r * 0.2), r * 0.55, col)
	c.draw_circle(center + Vector2(r * 0.45, -r * 0.2), r * 0.55, col)
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-r * 0.95, 0.0),
		center + Vector2(r * 0.95, 0.0),
		center + Vector2(0.0, r * 1.05),
	]), col)


static func _draw_back_hair(c: CanvasItem, head_c: Vector2, rx: float, ry: float, s: float,
		hair: Color, style: String, dir: float, idle_t: float) -> void:
	var dark := hair.darkened(0.10)
	match style:
		"long":
			var sway := sin(idle_t * 1.5) * 1.0 * s
			_ellipse(c, head_c + Vector2(0, 6.0 * s), rx + 2.8 * s, ry + 7.5 * s, dark)
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(head_c.x - rx - 2.4 * s, head_c.y + 2.0 * s),
				Vector2(head_c.x + rx + 2.4 * s, head_c.y + 2.0 * s),
				Vector2(head_c.x + rx + 1.0 * s, head_c.y + 15.0 * s + sway),
				Vector2(head_c.x - rx - 1.0 * s, head_c.y + 15.0 * s - sway),
			]), dark)
		"bob":
			_ellipse(c, head_c + Vector2(0, 2.2 * s), rx + 2.4 * s, ry + 2.6 * s, dark)
		"ponytail":
			var sway := sin(idle_t * 2.2) * 1.6 * s
			var tie := head_c + Vector2(-dir * (rx - 0.5 * s), -1.0 * s)
			c.draw_line(tie, tie + Vector2(-dir * 3.0 * s, 10.0 * s) + Vector2(sway, 0), dark, 4.2 * s, true)
			c.draw_circle(tie + Vector2(-dir * 3.0 * s, 10.0 * s) + Vector2(sway, 0), 2.6 * s, dark)
		"bun":
			c.draw_circle(head_c + Vector2(0, -ry - 2.2 * s), 4.0 * s, dark)
		"curly":
			for i in 5:
				var a := PI + PI * float(i) / 4.0
				c.draw_circle(head_c + Vector2(cos(a) * (rx + 0.5 * s), sin(a) * (ry + 0.5 * s)), 3.4 * s, dark)
		"messy":
			_ellipse(c, head_c + Vector2(0, 0.5 * s), rx + 1.5 * s, ry + 1.2 * s, dark)
		"bald":
			pass
		_:
			_ellipse(c, head_c + Vector2(0, 1.0 * s), rx + 1.6 * s, ry + 0.8 * s, dark)


static func _draw_front_hair(c: CanvasItem, head_c: Vector2, rx: float, ry: float, s: float,
		hair: Color, style: String, dir: float, facing: int, idle_t: float) -> void:
	var light := hair.lightened(0.10)
	if facing == 2:
		# มองจากด้านหลัง — ผมคลุมทั้งหัว
		_ellipse(c, head_c + Vector2(0, 0.3 * s), rx + 0.7 * s, ry + 0.6 * s, hair)
		_ellipse(c, head_c + Vector2(0, -3.2 * s), rx - 1.0 * s, ry - 2.0 * s, light)
		# ไรผมท้ายทอย
		for i in 3:
			c.draw_line(Vector2(head_c.x - 4.0 * s + i * 4.0 * s, head_c.y + ry - 0.8 * s),
				Vector2(head_c.x - 3.0 * s + i * 4.0 * s, head_c.y + ry + 2.2 * s), hair.darkened(0.15), 0.9 * s, true)
		match style:
			"long":
				c.draw_rect(Rect2(head_c.x - rx - 1.0 * s, head_c.y + 2.0 * s, (rx + 1.0) * 2.0 * s, 14.0 * s), hair.darkened(0.06))
			"bun":
				c.draw_circle(head_c + Vector2(0, -ry - 2.2 * s), 4.0 * s, hair)
		return
	if style == "bald":
		c.draw_circle(Vector2(head_c.x - rx + 1.2 * s, head_c.y + 1.0 * s), 2.0 * s, hair)
		c.draw_circle(Vector2(head_c.x + rx - 1.2 * s, head_c.y + 1.0 * s), 2.0 * s, hair)
		return

	# หมวกผมด้านบน + หน้าม้า
	var cap_rx := rx + 0.5 * s
	var cap_ry := ry + 0.7 * s
	var cap_c := head_c + Vector2(0, -1.6 * s)
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		pts.append(cap_c + Vector2(cos(a) * cap_rx, sin(a) * cap_ry))
	var fringe_y := head_c.y - 2.3 * s
	for i in 7:
		var fx := cap_c.x + cap_rx - (2.0 * cap_rx) * float(i) / 6.0
		var fy := fringe_y + (1.4 * s if i % 2 == 0 else -0.6 * s)
		pts.append(Vector2(fx, fy))
	c.draw_colored_polygon(pts, hair)
	# ไฮไลต์ผม
	c.draw_arc(cap_c + Vector2(-cap_rx * 0.15, -0.2 * s), cap_rx * 0.72, PI * 1.12, PI * 1.55, 10, light, 1.2 * s, true)
	# ปอยผมข้าง
	var lock_len := 5.2 * s
	match style:
		"short": lock_len = 3.2 * s
		"bob": lock_len = 10.5 * s
		"long": lock_len = 14.0 * s
		"bun": lock_len = 5.0 * s
		"curly": lock_len = 4.0 * s
		"messy": lock_len = 3.8 * s
	for side in [-1.0, 1.0]:
		var lx: float = head_c.x + side * (rx - 0.4 * s)
		c.draw_line(Vector2(lx, head_c.y - 2.0 * s), Vector2(lx + side * 0.4 * s, head_c.y - 2.0 * s + lock_len),
			hair.darkened(0.04), 2.8 * s, true)
	# หน้าม้าซอย
	for i in 3:
		var fx2 := head_c.x - 4.6 * s + float(i) * 4.6 * s + dir * 0.6 * s
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(fx2 - 2.0 * s, fringe_y - 0.8 * s),
			Vector2(fx2 + 1.8 * s, fringe_y - 1.0 * s),
			Vector2(fx2 + 0.3 * s + dir * 0.8 * s, fringe_y + 2.4 * s),
		]), hair)

	match style:
		"curly":
			for i in 6:
				var a := PI + PI * float(i) / 5.0
				c.draw_circle(cap_c + Vector2(cos(a) * cap_rx * 0.9, sin(a) * cap_ry * 0.9), 2.4 * s, hair.lightened(0.04))
		"messy":
			for i in 4:
				var mx := head_c.x - 6.0 * s + float(i) * 4.0 * s
				c.draw_colored_polygon(PackedVector2Array([
					Vector2(mx - 1.8 * s, cap_c.y - cap_ry + 1.0 * s),
					Vector2(mx + 0.2 * s, cap_c.y - cap_ry - 3.6 * s),
					Vector2(mx + 2.2 * s, cap_c.y - cap_ry + 1.2 * s),
				]), hair)
		"bun":
			c.draw_circle(head_c + Vector2(-dir * 1.0 * s, -ry - 3.0 * s), 3.8 * s, hair)
			c.draw_circle(head_c + Vector2(-dir * 1.8 * s, -ry - 4.0 * s), 1.6 * s, light)
		"ponytail":
			var tie := head_c + Vector2(-dir * (rx - 1.0 * s), -1.5 * s)
			c.draw_circle(tie, 1.7 * s, Color("#d86a6a"))
		"long":
			# ปอยผมยาวด้านหน้า
			for side in [-1.0, 1.0]:
				c.draw_line(Vector2(head_c.x + side * (rx - 0.8 * s), head_c.y + 1.0 * s),
					Vector2(head_c.x + side * (rx + 0.6 * s), head_c.y + 13.0 * s),
					hair.darkened(0.03), 2.4 * s, true)


static func _draw_accessories(c: CanvasItem, head_c: Vector2, rx: float, ry: float, s: float,
		accessory: String, dir: float, outfit: String, hair: Color) -> void:
	if accessory == "glasses":
		var eye_y := head_c.y + 1.7 * s
		var shift := dir * 1.0 * s
		for side in [-1.0, 1.0]:
			var lens_c := Vector2(head_c.x + side * 3.9 * s + shift, eye_y + 0.2 * s)
			var w := 4.7 * s
			var h := 4.6 * s
			c.draw_rect(Rect2(lens_c.x - w * 0.5 - 0.7 * s, lens_c.y - h * 0.5 - 0.7 * s, w + 1.4 * s, h + 1.4 * s), Color("#3a2a20"))
			c.draw_rect(Rect2(lens_c.x - w * 0.5, lens_c.y - h * 0.5, w, h), Color(0.72, 0.9, 0.96, 0.30))
			c.draw_line(Vector2(lens_c.x - w * 0.28, lens_c.y - h * 0.2), Vector2(lens_c.x + w * 0.1, lens_c.y + h * 0.25), Color(1, 1, 1, 0.55), 0.7 * s, true)
		c.draw_line(Vector2(head_c.x - 1.6 * s + shift, eye_y), Vector2(head_c.x + 1.6 * s + shift, eye_y), Color("#3a2a20"), 0.8 * s, true)
		# ขาแว่น
		c.draw_line(Vector2(head_c.x - 6.4 * s + shift, eye_y - 0.4 * s), Vector2(head_c.x - rx + 0.4 * s, eye_y - 1.2 * s), Color("#3a2a20"), 0.7 * s, true)
		c.draw_line(Vector2(head_c.x + 6.4 * s + shift, eye_y - 0.4 * s), Vector2(head_c.x + rx - 0.4 * s, eye_y - 1.2 * s), Color("#3a2a20"), 0.7 * s, true)
	if accessory == "earring":
		for side in [-1.0, 1.0]:
			var ex: float = head_c.x + side * (rx - 0.5 * s)
			var ey := head_c.y + 4.0 * s
			c.draw_line(Vector2(ex, ey - 1.2 * s), Vector2(ex, ey + 0.6 * s), Color("#d8b04a"), 0.7 * s, true)
			c.draw_circle(Vector2(ex, ey + 1.5 * s), 1.35 * s, Color("#f2d05a"))
			c.draw_circle(Vector2(ex - 0.35 * s, ey + 1.15 * s), 0.45 * s, Color("#fff6c8"))
	if accessory == "headband":
		var by := head_c.y - 1.8 * s
		c.draw_rect(Rect2(head_c.x - rx - 0.2 * s, by, (rx + 0.2) * 2.0 * s, 2.1 * s), Color("#e8a0b8"))
		c.draw_line(Vector2(head_c.x - rx - 0.2 * s, by + 0.5 * s), Vector2(head_c.x + rx + 0.2 * s, by + 0.5 * s), Color("#f6c6d6"), 0.7 * s, true)
		c.draw_circle(Vector2(head_c.x + rx - 1.2 * s, by - 0.6 * s), 1.8 * s, Color("#f2c0d0"))
	if accessory == "scarf" or outfit == "winter" or outfit == "cozy":
		var ny := head_c.y + ry + 1.2 * s
		c.draw_rect(Rect2(head_c.x - 7.8 * s, ny, 15.6 * s, 3.2 * s), Color("#d86a6a"))
		c.draw_rect(Rect2(head_c.x - 7.8 * s, ny, 15.6 * s, 1.1 * s), Color("#e88a8a"))
		c.draw_rect(Rect2(head_c.x + 2.4 * s, ny + 2.6 * s, 3.6 * s, 6.5 * s), Color("#c05a5a"))
		c.draw_rect(Rect2(head_c.x + 2.4 * s, ny + 7.6 * s, 3.6 * s, 1.6 * s), Color("#a84a4a"))


static func _draw_hat_if_any(c: CanvasItem, head_c: Vector2, rx: float, ry: float, s: float,
		accessory: String, dir: float) -> void:
	var top := head_c.y - ry - 0.8 * s
	match accessory:
		"hat":
			c.draw_rect(Rect2(head_c.x - rx - 3.2 * s, top - 0.4 * s, (rx + 3.2) * 2.0 * s, 2.6 * s), Color("#8a5a3a"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(head_c.x - 6.6 * s, top - 0.4 * s), Vector2(head_c.x + 6.6 * s, top - 0.4 * s),
				Vector2(head_c.x + 5.2 * s, top - 5.8 * s), Vector2(head_c.x - 5.2 * s, top - 5.8 * s),
			]), Color("#c8a05a"))
			c.draw_rect(Rect2(head_c.x - 6.2 * s, top - 2.2 * s, 12.4 * s, 1.7 * s), Color("#8a5a3a"))
			c.draw_rect(Rect2(head_c.x - 5.2 * s, top - 5.8 * s, 10.4 * s, 1.0 * s), Color("#d8b87a"))
		"cap":
			c.draw_circle(Vector2(head_c.x, top + 0.4 * s), 7.2 * s, Color("#c04a3a"))
			c.draw_rect(Rect2(head_c.x - 7.2 * s, top - 0.2 * s, 14.4 * s, 3.0 * s), Color("#c04a3a"))
			c.draw_rect(Rect2(head_c.x + dir * 2.0 * s, top + 1.4 * s, dir * 8.0 * s, 2.0 * s), Color("#8a2e26"))
			c.draw_line(Vector2(head_c.x - 6.4 * s, top - 0.2 * s), Vector2(head_c.x + 6.4 * s, top - 0.2 * s), Color("#e06a5a"), 0.8 * s, true)
		"chef_hat":
			c.draw_rect(Rect2(head_c.x - 7.2 * s, top - 1.0 * s, 14.4 * s, 3.0 * s), Color("#f8f8f4"))
			c.draw_circle(Vector2(head_c.x - 4.2 * s, top - 4.0 * s), 4.6 * s, Color("#ffffff"))
			c.draw_circle(Vector2(head_c.x + 0.8 * s, top - 6.0 * s), 5.4 * s, Color("#ffffff"))
			c.draw_circle(Vector2(head_c.x + 5.0 * s, top - 3.6 * s), 4.2 * s, Color("#f2f2ee"))
			c.draw_circle(Vector2(head_c.x - 1.6 * s, top - 3.0 * s), 4.2 * s, Color("#ffffff"))
		"rain_hat":
			c.draw_rect(Rect2(head_c.x - rx - 2.6 * s, top - 0.2 * s, (rx + 2.6) * 2.0 * s, 2.6 * s), Color("#d8b84a"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(head_c.x - 6.4 * s, top - 0.2 * s), Vector2(head_c.x + 6.4 * s, top - 0.2 * s),
				Vector2(head_c.x + 3.6 * s, top - 6.4 * s), Vector2(head_c.x - 3.6 * s, top - 6.4 * s),
			]), Color("#f2d05a"))
			c.draw_line(Vector2(head_c.x - 6.4 * s, top - 0.2 * s), Vector2(head_c.x + 6.4 * s, top - 0.2 * s), Color("#c8a83a"), 0.8 * s, true)


static func _long_sleeve(outfit: String, style: String) -> bool:
	if outfit in ["school", "work", "winter", "raincoat", "cozy", "thai", "party", "luxury",
			"heirloom_blue", "heirloom_rose", "heirloom_green", "sleep"]:
		return true
	if style in ["formal", "chef", "work", "scholar", "vet", "elder", "student", "home"]:
		return true
	return false


static func _ellipse(c: CanvasItem, center: Vector2, rx: float, ry: float, col: Color, seg: int = 22) -> void:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	c.draw_colored_polygon(pts, col)


static func _capsule(c: CanvasItem, a: Vector2, b: Vector2, r: float, col: Color) -> void:
	var d := b - a
	if d.length() < 0.01:
		c.draw_circle(a, r, col)
		return
	c.draw_line(a, b, col, r * 2.0, true)
	c.draw_circle(a, r, col)
	c.draw_circle(b, r, col)


static func player_palette(outfit: String, look: Dictionary = {}) -> Dictionary:
	var extra := {}
	if Art.OUTFIT_PALETTES.has(outfit):
		var src: Dictionary = Art.OUTFIT_PALETTES[outfit]
		var skin_c: Color = src.get("s", Color("#f2c39b"))
		var hair_c: Color = src.get("h", Color("#3a2a1a"))
		var shirt_c: Color = src.get("b", Color("#4aa3ff"))
		var pants_c: Color = src.get("p", Color("#2e3a59"))
		var shoes_c: Color = src.get("k", Color("#1f1a16"))
		extra = {
			"skin": skin_c.to_html(false),
			"hair": hair_c.to_html(false),
			"shirt": shirt_c.to_html(false),
			"pants": pants_c.to_html(false),
			"shoes": shoes_c.to_html(false),
		}
	else:
		extra = {"skin": "#f2c39b", "hair": "#3a2a1a", "shirt": "#4aa3ff",
			"pants": "#2e3a59", "shoes": "#1f1a16"}
	match outfit:
		"winter":
			extra["accessory"] = "scarf"
			extra["hair_style"] = "bob"
		"raincoat":
			extra["accessory"] = "rain_hat"
		"thai":
			extra["accessory"] = "sash"
			extra["hair_style"] = "bun"
		"cozy":
			extra["accessory"] = "scarf"
			extra["hair_style"] = "long"
		"party", "luxury":
			extra["accessory"] = "earring"
			extra["hair_style"] = "long"
		"work":
			extra["accessory"] = "tie"
		"heirloom_blue", "heirloom_rose", "heirloom_green", "sleep":
			extra["accessory"] = "shawl"
	extra["outfit"] = outfit
	if look is Dictionary:
		if look.has("skin") and String(look["skin"]) != "":
			extra["skin"] = String(look["skin"])
		if look.has("hair") and String(look["hair"]) != "":
			extra["hair"] = String(look["hair"])
		if look.has("hair_style") and String(look["hair_style"]) != "":
			extra["hair_style"] = String(look["hair_style"])
		if look.has("expression") and String(look["expression"]) != "":
			extra["expression"] = String(look["expression"])
		if look.has("pose") and String(look["pose"]) != "":
			extra["pose"] = String(look["pose"])
	return extra


static func draw_portrait_card(c: CanvasItem, rect: Rect2, pal: Dictionary, expression: String,
		t: float, facing: int = 1) -> void:
	# กรอบกระดาษอุ่น ๆ
	c.draw_rect(Rect2(rect.position + Vector2(2, 3), rect.size), Color(0.30, 0.20, 0.13, 0.30))
	c.draw_rect(rect, Color("#6b4a32"))
	c.draw_rect(rect.grow(-2.5), Color("#f8efd8"))
	c.draw_rect(rect.grow(-5.5), Color("#f3e3c6"))
	# แสงเช้า + ประกาย
	c.draw_circle(rect.position + Vector2(20, 22), 9.0, Color(0.98, 0.90, 0.62, 0.45))
	c.draw_circle(rect.position + Vector2(rect.size.x - 24, 26), 2.2, Color(1, 0.95, 0.7, 0.6))
	c.draw_circle(rect.position + Vector2(rect.size.x - 16, 40), 1.5, Color(1, 0.95, 0.7, 0.45))
	# ฮาโลอุ่นหลังศีรษะ (ไม่วาดพื้น/เงา เพราะเป็นภาพ bust)
	var halo := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.37)
	c.draw_circle(halo, rect.size.x * 0.36, Color(1.0, 0.92, 0.68, 0.16))
	var scale := minf(rect.size.x / 30.0, rect.size.y / 34.0)
	var foot := Vector2(rect.position.x + rect.size.x * 0.5,
		rect.position.y + rect.size.y * 0.34 + 46.0 * scale + 12.0)
	var p := pal.duplicate(true)
	p["expression"] = expression
	draw_person(c, foot, p, scale, 0.0, facing, t)


static func draw_person_old(c: CanvasItem, foot: Vector2, pal: Dictionary, scale: float, walk_t: float, facing: int) -> void:
	draw_person(c, foot, pal, scale, walk_t, facing, 0.0)


# ============================================================

static func draw_furniture(c: CanvasItem, id: String, pos: Vector2, t: float, hour: int = 12) -> void:
	match id:
		"cozy_lamp":
			c.draw_circle(Vector2(pos.x, pos.y + 2), 10.0, Color(0.15, 0.11, 0.08, 0.14))
			c.draw_rect(Rect2(pos.x - 2, pos.y - 54, 4, 56), Color("#6b4a32"))
			c.draw_rect(Rect2(pos.x - 10, pos.y - 2, 20, 4), Color("#5a3e2a"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(pos.x - 16, pos.y - 70), Vector2(pos.x + 16, pos.y - 70),
				Vector2(pos.x + 10, pos.y - 54), Vector2(pos.x - 10, pos.y - 54),
			]), Color("#e8c88a"))
			c.draw_rect(Rect2(pos.x - 10, pos.y - 54, 20, 3), Color("#f2d8a8"))
			c.draw_circle(Vector2(pos.x, pos.y - 52), 16.0, Color(1.0, 0.86, 0.52, 0.13))
			c.draw_circle(Vector2(pos.x, pos.y - 52), 28.0, Color(1.0, 0.82, 0.46, 0.06))
		"bookshelf":
			_draw_prop(c, {"type": "bookshelf", "pos": pos}, t, 0)
		"plant":
			_draw_prop(c, {"type": "plant", "pos": pos}, t, 0)
		"fish_tank":
			c.draw_rect(Rect2(pos.x - 38, pos.y - 78, 76, 80), Color("#6b4a32"))
			c.draw_rect(Rect2(pos.x - 33, pos.y - 73, 66, 62), Color("#8ac8e0"))
			c.draw_rect(Rect2(pos.x - 33, pos.y - 73, 66, 20), Color("#a8e0f0"))
			c.draw_rect(Rect2(pos.x - 33, pos.y - 13, 66, 8), Color("#c8b08a"))
			for i in 3:
				var fx := pos.x - 20 + fmod(t * 14.0 + float(i) * 26.0, 48.0)
				var fy := pos.y - 48 + sin(t * 2.0 + float(i) * 1.7) * 8.0
				c.draw_circle(Vector2(fx, fy), 3.4, Color(["#e8a04a", "#f2d05a", "#e05a5a"][i]))
				c.draw_colored_polygon(PackedVector2Array([
					Vector2(fx + 4, fy), Vector2(fx + 8, fy - 3), Vector2(fx + 8, fy + 3),
				]), Color(0.9, 0.6, 0.3, 0.8))
			for i in 4:
				c.draw_rect(Rect2(pos.x - 24 + i * 14, pos.y - 28, 3, 16), Color("#4f8a3a"))
			c.draw_rect(Rect2(pos.x - 38, pos.y - 82, 76, 4), Color("#8a5a3a"))
		"cat_bed":
			c.draw_circle(Vector2(pos.x, pos.y + 2), 34.0, Color(0.15, 0.11, 0.08, 0.13))
			c.draw_circle(Vector2(pos.x, pos.y - 10), 30.0, Color("#c88a5a"))
			c.draw_circle(Vector2(pos.x, pos.y - 12), 24.0, Color("#e8b88a"))
			c.draw_circle(Vector2(pos.x, pos.y - 14), 19.0, Color("#f6d8b8"))
			# แมวหลับ
			c.draw_circle(Vector2(pos.x + 2, pos.y - 18), 13.0, Color("#e89a4a"))
			c.draw_circle(Vector2(pos.x - 8, pos.y - 24), 9.5, Color("#f2aa5a"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(pos.x - 15, pos.y - 30), Vector2(pos.x - 11, pos.y - 38), Vector2(pos.x - 7, pos.y - 31),
			]), Color("#f2aa5a"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(pos.x - 1, pos.y - 31), Vector2(pos.x + 3, pos.y - 39), Vector2(pos.x + 6, pos.y - 30),
			]), Color("#f2aa5a"))
			c.draw_rect(Rect2(pos.x - 13, pos.y - 25, 6, 1.4), Color("#6b4a32"))
			c.draw_rect(Rect2(pos.x - 4, pos.y - 26, 6, 1.4), Color("#6b4a32"))
			c.draw_circle(Vector2(pos.x - 10, pos.y - 22), 1.8, Color(0.9, 0.6, 0.45, 0.5))
			c.draw_circle(Vector2(pos.x - 1, pos.y - 23), 1.8, Color(0.9, 0.6, 0.45, 0.5))
			c.draw_arc(Vector2(pos.x + 18, pos.y - 14), 14.0, -1.2, 1.8, 12, Color("#e89a4a"), 3.0, true)
			var zz := fmod(t * 0.7, 1.0)
			c.draw_circle(Vector2(pos.x + 14, pos.y - 44 - zz * 8), 2.0, Color(0.95, 0.92, 0.82, 0.45 * (1.0 - zz)))
		"wall_clock":
			_draw_room_clock(c, pos, hour)
		"picture":
			_draw_prop(c, {"type": "picture", "pos": pos}, t, 0)
		"easel":
			_draw_prop(c, {"type": "easel", "pos": pos}, t, 0)
		"kitchen":
			_draw_prop(c, {"type": "kitchen", "pos": pos}, t, 0)
		"rug":
			_draw_prop(c, {"type": "rug", "pos": pos, "w": 220.0}, t, 0)
		_:
			_draw_prop(c, {"type": "plant", "pos": pos}, t, 0)


static func draw_festival_booth(c: CanvasItem, pos: Vector2, festival: Dictionary, t: float) -> void:
	var fid := String(festival.get("id", "blossom"))
	var main := Color("#e88aa8")
	var accent := Color("#f6d0dc")
	match fid:
		"summer_market":
			main = Color("#e88a4a")
			accent = Color("#f6d8a8")
		"harvest":
			main = Color("#c08a3a")
			accent = Color("#f2d88a")
		"winter_lights":
			main = Color("#6a9ac8")
			accent = Color("#d8ecf8")

	c.draw_circle(Vector2(pos.x, pos.y + 3), 72.0, Color(0.15, 0.11, 0.08, 0.18))
	# เสาและเคาน์เตอร์
	c.draw_rect(Rect2(pos.x - 66, pos.y - 118, 8, 120), Color("#6b4a32"))
	c.draw_rect(Rect2(pos.x + 58, pos.y - 118, 8, 120), Color("#6b4a32"))
	c.draw_rect(Rect2(pos.x - 60, pos.y - 62, 120, 12), Color("#a06a44"))
	c.draw_rect(Rect2(pos.x - 60, pos.y - 62, 120, 4), Color("#c08a5a"))
	c.draw_rect(Rect2(pos.x - 52, pos.y - 50, 104, 50), main.darkened(0.18))
	for i in 4:
		c.draw_rect(Rect2(pos.x - 44 + i * 24, pos.y - 44, 16, 20), Color(accent))
	# กันสาดลายทาง
	for i in 8:
		var col := main if i % 2 == 0 else accent
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(pos.x - 78 + i * 19.5, pos.y - 132),
			Vector2(pos.x - 78 + (i + 1) * 19.5, pos.y - 132),
			Vector2(pos.x - 70 + (i + 1) * 18.0, pos.y - 105),
			Vector2(pos.x - 70 + i * 18.0, pos.y - 105),
		]), col)
	c.draw_rect(Rect2(pos.x - 78, pos.y - 136, 156, 6), Color("#f6ecd8"))
	for i in 7:
		var fx := pos.x - 66 + i * 22.0
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(fx, pos.y - 104), Vector2(fx + 10, pos.y - 104),
			Vector2(fx + 5, pos.y - 96),
		]), main.darkened(0.08))
	# ป้ายเทศกาล
	c.draw_rect(Rect2(pos.x - 54, pos.y - 98, 108, 22), Color("#f6ecd8"))
	c.draw_rect(Rect2(pos.x - 50, pos.y - 94, 100, 14), main)
	for i in 4:
		c.draw_circle(Vector2(pos.x - 24 + i * 16, pos.y - 87), 3.2, accent)
	# โคมไฟ
	for i in 4:
		var lx := pos.x - 60 + i * 40.0
		c.draw_line(Vector2(lx, pos.y - 130), Vector2(lx, pos.y - 116), Color("#4a3a30"), 1.5)
		var glow := 0.55 + sin(t * 2.0 + float(i)) * 0.3
		c.draw_circle(Vector2(lx, pos.y - 112), 7.0, Color(1.0, 0.82, 0.42, 0.20 + glow * 0.18))
		c.draw_circle(Vector2(lx, pos.y - 112), 4.0, Color("#ffd98a"))
	# ของขวัญ/ผลไม้
	for i in 3:
		c.draw_rect(Rect2(pos.x - 44 + i * 18, pos.y - 74, 13, 12), Color(["#e05a5a", "#e8c05a", "#6ad08a"][i]))
		c.draw_rect(Rect2(pos.x - 44 + i * 18, pos.y - 74, 13, 3), Color(1, 1, 1, 0.30))
	# ธงเล็ก
	for i in 5:
		var a := sin(t * 2.2 + float(i) * 0.8) * 0.3
		var fx2 := pos.x - 50 + i * 25.0
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(fx2, pos.y - 150), Vector2(fx2 + 12, pos.y - 148 + a * 6), Vector2(fx2, pos.y - 142),
		]), main)


# ============================================================
#  บรรยากาศเล็ก ๆ
# ============================================================

static func _draw_ambient(c: CanvasItem, zone_id: String, zone: Dictionary, hour: int, season: int, t: float) -> void:
	if not bool(zone.get("outdoor", false)):
		# ฝุ่นในแสงตอนกลางวัน
		if hour >= 8 and hour < 17:
			for i in 8:
				var dx := 120.0 + _hash01(i * 17) * 720.0 + sin(t * 0.4 + float(i)) * 14.0
				var dy := 160.0 + _hash01(i * 29) * 260.0 + cos(t * 0.3 + float(i) * 1.4) * 10.0
				c.draw_circle(Vector2(dx, dy), 1.2, Color(1.0, 0.95, 0.8, 0.16))
		return

	match season:
		0:
			for i in 14:
				var px := fmod(_hash01(i * 7 + 3) * 1000.0 + t * (10.0 + float(i % 5) * 3.0), 1000.0) - 20.0
				var py := fmod(_hash01(i * 13 + 11) * 560.0 + t * (14.0 + float(i % 4) * 4.0), 560.0) - 10.0
				var petal_w := 3.6 + sin(t * 2.0 + float(i)) * 1.6
				c.draw_colored_polygon(PackedVector2Array([
					Vector2(px, py), Vector2(px + petal_w, py + 2.2), Vector2(px, py + 5),
				]), Color(0.96, 0.68, 0.78, 0.55))
		2:
			for i in 10:
				var px2 := fmod(_hash01(i * 11 + 5) * 1000.0 + t * (16.0 + float(i % 4) * 4.0), 1000.0) - 20.0
				var py2 := fmod(_hash01(i * 19 + 7) * 560.0 + t * (20.0 + float(i % 3) * 5.0), 560.0) - 10.0
				var sway := sin(t * 3.0 + float(i) * 0.8) * 8.0
				c.draw_colored_polygon(PackedVector2Array([
					Vector2(px2 + sway, py2), Vector2(px2 + 6 + sway, py2 + 3), Vector2(px2 + 3 + sway, py2 + 8),
				]), Color(0.82, 0.46, 0.22, 0.60))
	if hour >= 18 or hour < 6:
		var fireflies := 16 if zone_id == "park" else 8
		for i in fireflies:
			var fx := 70.0 + _hash01(i * 31 + 2) * 820.0 + sin(t * 0.7 + float(i) * 2.1) * 26.0
			var fy := 210.0 + _hash01(i * 47 + 9) * 280.0 + cos(t * 0.5 + float(i) * 1.3) * 18.0
			var a := 0.25 + 0.55 * (0.5 + sin(t * 2.6 + float(i) * 1.9) * 0.5)
			c.draw_circle(Vector2(fx, fy), 1.8, Color(1.0, 0.94, 0.62, a))
			c.draw_circle(Vector2(fx, fy), 5.0, Color(1.0, 0.88, 0.45, a * 0.16))
	if zone_id == "downtown":
		for i in 6:
			var a2 := 0.10 + 0.06 * sin(t * 1.2 + float(i))
			c.draw_circle(Vector2(130.0 + float(i) * 140.0, 300.0), 26.0, Color(1.0, 0.78, 0.42, a2))


static func _hash01(n: int) -> float:
	var x := sin(float(n) * 12.9898) * 43758.5453
	return x - floor(x)

