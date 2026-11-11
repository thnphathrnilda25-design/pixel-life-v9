extends Node2D
## RoomArt.gd — วาดห้อง (กำแพง/พื้น/หน้าต่าง/พรม) ด้วยโค้ด

const WALL_BOTTOM := 170.0
const FLOOR_BOTTOM := 520.0


func _draw() -> void:
	# กำแพง
	draw_rect(Rect2(0, 0, 480, WALL_BOTTOM), Color("#262c42"))
	for x in range(0, 480, 32):
		draw_rect(Rect2(x, 0, 16, WALL_BOTTOM), Color("#2b3250"))
	draw_rect(Rect2(0, 160, 480, 12), Color("#1b2033")) # บัวพื้น

	# พื้น ไล่เฉดตามระยะ
	var rows := 9
	for i in rows:
		var y1 := 172.0 + pow(float(i) / rows, 1.5) * (FLOOR_BOTTOM - 172.0)
		var y2 := 172.0 + pow(float(i + 1) / rows, 1.5) * (FLOOR_BOTTOM - 172.0)
		var color := Color("#40485f") if i % 2 == 0 else Color("#384054")
		draw_rect(Rect2(0, y1, 480, y2 - y1), color)
	for x in range(0, 481, 60):
		draw_rect(Rect2(x, 172, 1, FLOOR_BOTTOM - 172), Color("#333a4d"))

	# หน้าต่าง (สีท้องฟ้าเปลี่ยนตามช่วงเวลา)
	draw_rect(Rect2(314, 54, 132, 84), _sky_color())
	draw_rect(Rect2(314, 54, 132, 84), Color("#141824"), false, 4.0)
	draw_rect(Rect2(378, 54, 4, 84), Color("#141824"))
	draw_rect(Rect2(314, 94, 132, 4), Color("#141824"))

	# รูปติดผนัง (วิวภูเขาน้อย ๆ)
	draw_rect(Rect2(64, 44, 100, 74), Color("#141824"))
	draw_rect(Rect2(70, 50, 88, 62), Color("#6f9fd8"))
	draw_rect(Rect2(70, 78, 88, 34), Color("#4a7a5a"))
	draw_circle(Vector2(140, 64), 8, Color("#f0d78c"))
	draw_colored_polygon(
		PackedVector2Array([Vector2(70, 92), Vector2(104, 62), Vector2(132, 92)]),
		Color("#3c6b4c")
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(96, 92), Vector2(126, 68), Vector2(158, 92)]),
		Color("#2f5a3f")
	)

	# นาฬิกาติดผนัง
	draw_circle(Vector2(252, 76), 24, Color("#141824"))
	draw_circle(Vector2(252, 76), 20, Color("#e8e3d8"))
	draw_line(Vector2(252, 76), Vector2(252, 62), Color("#141824"), 3.0)
	draw_line(Vector2(252, 76), Vector2(262, 80), Color("#141824"), 2.0)

	# พรม
	draw_rect(Rect2(160, 417, 160, 70), Color("#3b4a6b"))
	draw_rect(Rect2(166, 423, 148, 58), Color("#4d5f86"))
	draw_rect(Rect2(174, 431, 132, 42), Color("#3b4a6b"))
	draw_rect(Rect2(174, 452, 132, 4), Color("#5d719c"))


func _sky_color() -> Color:
	# ท้องฟ้าตามฤดูของไทย (เดือน 1-12)
	match Game.month:
		3, 4, 5:
			return Color("#ffe0a8") # ร้อนจัด ฟ้าใสออกเหลือง
		6, 7, 8, 9, 10:
			return Color("#8fa8c8") # ฝนตก ฟ้าครึ้ม
		11, 12, 1, 2:
			return Color("#b8d8f0") # หน้าหนาว ฟ้าใส
	return Color("#9fd8ff")
