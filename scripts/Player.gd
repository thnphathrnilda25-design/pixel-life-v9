extends Node2D
## Player.gd — ตัวละครเดินได้ 4 ทิศ (วาดพิกเซลจากโค้ด)
## รับอินพุตคีย์บอร์ด + joystick จาก HUD, ถูกจำกัดขอบเขตตามโซน

const SPEED := 165.0

var can_move := true
var joystick := Vector2.ZERO
var bounds := Rect2(24, 150, 912, 366)
var blockers: Array[Rect2] = []
var walk_time := 0.0
var facing := 1
var moving := false
var sitting := false
var zone_id := "home"

var _input_dir := Vector2.ZERO


func _ready() -> void:
	z_index = 50
	set_process(true)


func set_zone(id: String, spawn: Vector2, walk_bounds: Rect2, solid: Array[Rect2] = []) -> void:
	zone_id = id
	position = spawn
	bounds = walk_bounds
	blockers = solid
	walk_time = 0.0
	facing = 1
	sitting = false


## นั่งลงบนม้านั่ง/โซฟา — ลุกอัตโนมัติเมื่อกดเดิน
func sit_at(p: Vector2) -> void:
	sitting = true
	position = p
	moving = false
	walk_time = 0.0
	queue_redraw()


func stand_up() -> void:
	sitting = false
	queue_redraw()


func _process(delta: float) -> void:
	if not can_move:
		_input_dir = Vector2.ZERO
		moving = false
		queue_redraw()
		return

	var kx := Input.get_axis("ui_left", "ui_right")
	var ky := Input.get_axis("ui_up", "ui_down")
	# รองรับ WASD เพิ่มจากลูกศร
	if Input.is_key_pressed(KEY_A):
		kx -= 1.0
	if Input.is_key_pressed(KEY_D):
		kx += 1.0
	if Input.is_key_pressed(KEY_W):
		ky -= 1.0
	if Input.is_key_pressed(KEY_S):
		ky += 1.0
	var key_dir := Vector2(clampf(kx, -1.0, 1.0), clampf(ky, -1.0, 1.0))
	var dir := key_dir + joystick
	if dir.length() > 1.0:
		dir = dir.normalized()

	if sitting:
		if dir.length() > 0.08:
			sitting = false
		else:
			moving = false
			walk_time = 0.0
			queue_redraw()
			return

	# เดินช้าลงเมื่อพลังงานต่ำ
	var spd := SPEED
	if Game.energy < 20:
		spd *= 0.72
	elif Game.energy < 40:
		spd *= 0.88

	if dir.length() > 0.08:
		moving = true
		walk_time += delta
		var next := position + dir * spd * delta
		next.x = clampf(next.x, bounds.position.x, bounds.end.x)
		next.y = clampf(next.y, bounds.position.y, bounds.end.y)
		if not _blocked(next):
			position = next
		else:
			# ลองแยกแกนเพื่อเลื่อนไปตามกำแพง
			var try_x := Vector2(next.x, position.y)
			var try_y := Vector2(position.x, next.y)
			if not _blocked(try_x):
				position = try_x
			elif not _blocked(try_y):
				position = try_y
		if absf(dir.x) > 0.12:
			facing = 1 if dir.x > 0 else -1
	else:
		moving = false
		walk_time = 0.0

	queue_redraw()


func _blocked(p: Vector2) -> bool:
	for r in blockers:
		if r.has_point(Vector2(p.x, p.y - 4)):
			return true
	return false


func _draw() -> void:
	var is_child := Game.age < 12
	var scale := 0.86 if is_child else (0.98 if Game.age < 18 else 1.08)
	var look := Game.character_look()
	if sitting:
		look["pose"] = "sit"
	var pal := TownArt.player_palette(Game.outfit, look)
	TownArt.draw_person(self, Vector2.ZERO, pal, scale, walk_time if moving else 0.0, facing, Time.get_ticks_msec() / 1000.0)
