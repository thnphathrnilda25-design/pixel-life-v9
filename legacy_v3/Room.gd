extends Node2D
## Room.gd — ห้อง 2.5D: เดินได้ แตะเฟอร์นิเจอร์เพื่อทำกิจกรรม
## v3: ตัวละครโตตามอายุ เปลี่ยนชุดได้ และรองรับการสร้างตัวละครใหม่

const FLOOR_TOP := 250.0
const FLOOR_BOTTOM := 500.0
const HUD_TOP := 520.0
const SPEED := 150.0
const REACH := 86.0

# เฟอร์นิเจอร์: pos = จุดฐานล่างกลาง
const FURNITURE := [
	{"key": "bookshelf", "pos": Vector2(62, 302), "action": "study", "scale": 2.0},
	{"key": "desk", "pos": Vector2(206, 300), "action": "work", "scale": 2.0},
	{"key": "plant", "pos": Vector2(302, 296), "action": "", "scale": 2.0},
	{"key": "fridge", "pos": Vector2(424, 322), "action": "eat", "scale": 2.0},
	{"key": "bed", "pos": Vector2(98, 422), "action": "rest", "scale": 2.0},
	{"key": "dumbbell", "pos": Vector2(306, 432), "action": "gym", "scale": 2.0},
	{"key": "sofa", "pos": Vector2(202, 492), "action": "social", "scale": 2.0},
	{"key": "plant", "pos": Vector2(26, 486), "action": "", "scale": 2.0},
]

const MOOD_COLORS := [
	Color(1.0, 0.85, 0.63, 0.06), # เช้า
	Color(1.0, 1.0, 1.0, 0.0), # บ่าย
	Color(1.0, 0.60, 0.35, 0.12), # เย็น
	Color(0.16, 0.23, 0.54, 0.42), # กลางคืน
]

@onready var player: Sprite2D = $Player
@onready var hud: Control = $HudLayer/Hud
@onready var night_overlay: ColorRect = $NightOverlay
@onready var room_art: Node2D = $RoomArt

var textures := {}
var interactables: Array = []
var obstacles: Array[Rect2] = []
var shadow: Sprite2D
var partner_sprite: Sprite2D
var partner_shadow: Sprite2D

var move_target := Vector2.ZERO
var has_target := false
var pending_action := ""
var walk_time := 0.0
var mood_step := 0
var base_scale := 3.0


func _ready() -> void:
	textures = Art.build()
	_setup_player()
	_build_furniture()
	_build_partner()

	hud.action_pressed.connect(_on_action_pressed)
	hud.job_apply_requested.connect(_on_job_apply)
	hud.job_quit_requested.connect(_on_job_quit)
	hud.date_requested.connect(_on_date)
	hud.propose_requested.connect(_on_propose)
	hud.child_requested.connect(_on_child)
	hud.breakup_requested.connect(_on_breakup)
	hud.event_choice.connect(_on_event_choice)
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.creation_confirmed.connect(_on_creation_confirmed)
	hud.bank_deposit_requested.connect(_on_deposit)
	hud.bank_withdraw_requested.connect(_on_withdraw)
	hud.loan_requested.connect(_on_borrow)
	hud.repay_requested.connect(_on_repay)
	hud.insurance_requested.connect(_on_insurance)
	hud.medicine_requested.connect(_on_medicine)
	hud.doctor_requested.connect(_on_doctor)
	hud.checkup_requested.connect(_on_checkup)
	hud.outfit_buy_requested.connect(_on_outfit_buy)
	hud.outfit_equip_requested.connect(_on_outfit_equip)

	mood_step = maxi(Game.week - 1, 0)
	_sync_player()
	hud.refresh()
	_sync_partner()
	_apply_mood()

	if not Game.created:
		hud.show_creation()
	elif not Game.alive:
		hud.show_game_over()
	else:
		_stage_toast()


func _stage_toast() -> void:
	if Game.is_child():
		hud.toast(
			"แตะเฟอร์นิเจอร์เพื่อเลือกกิจกรรมของปีนี้ • เมนูล่างดูเงิน/สุขภาพ/แต่งตัว",
			Color("#cfe3ff")
		)
	else:
		hud.toast(
			"แตะเฟอร์นิเจอร์เพื่อทำกิจกรรม • เมนูล่างดูอาชีพ/ความรัก/ชีวิต/เงิน/สุขภาพ/แต่งตัว",
			Color("#cfe3ff")
		)


func _setup_player() -> void:
	player.texture = textures["hero_casual"]
	base_scale = _age_scale()
	player.scale = Vector2(base_scale, base_scale)
	var hero_size: Vector2 = textures["hero_casual"].get_size()
	player.centered = false
	player.offset = Vector2(-hero_size.x / 2.0, -hero_size.y)

	shadow = Sprite2D.new()
	shadow.texture = textures["shadow"]
	shadow.centered = true
	add_child(shadow)
	_update_shadow()


func _age_scale() -> float:
	if Game.age < 3:
		return 1.8
	if Game.age < 6:
		return 2.1
	if Game.age < 12:
		return 2.4
	if Game.age < 18:
		return 2.7
	return 3.0


## เปลี่ยน texture ตามชุด + ขนาดตามอายุ
func _sync_player() -> void:
	base_scale = _age_scale()
	var key := "hero_" + Game.outfit
	if not textures.has(key):
		key = "hero_casual"
	player.texture = textures[key]
	player.scale = Vector2(base_scale, base_scale)
	player.offset = Vector2(
		-textures[key].get_width() / 2.0,
		-textures[key].get_height()
	)
	if shadow != null:
		shadow.scale = Vector2(base_scale / 3.0, base_scale / 3.0)


func _build_partner() -> void:
	partner_sprite = Sprite2D.new()
	partner_sprite.texture = textures["partner"]
	partner_sprite.scale = Vector2(3, 3)
	partner_sprite.centered = false
	partner_sprite.offset = Vector2(-6, -18)
	partner_sprite.position = Vector2(246, 502)
	partner_sprite.z_index = 502
	partner_sprite.visible = false
	add_child(partner_sprite)

	partner_shadow = Sprite2D.new()
	partner_shadow.texture = textures["shadow"]
	partner_shadow.position = Vector2(246, 500)
	partner_shadow.z_index = 501
	partner_shadow.visible = false
	add_child(partner_shadow)


func _sync_partner() -> void:
	var has_partner: bool = Game.partner_name != "" and not Game.is_child()
	partner_sprite.visible = has_partner
	partner_shadow.visible = has_partner


func _build_furniture() -> void:
	for item in FURNITURE:
		var tex: Texture2D = textures[item["key"]]
		var size: Vector2 = tex.get_size() * float(item["scale"])

		# เงาใต้เฟอร์นิเจอร์ ช่วยให้ดูเป็น 2.5D
		var furn_shadow := Sprite2D.new()
		furn_shadow.texture = textures["shadow"]
		furn_shadow.position = Vector2(item["pos"].x, item["pos"].y - 2)
		furn_shadow.scale = Vector2(maxf(size.x / 30.0, 1.0), 1.0)
		furn_shadow.z_index = int(item["pos"].y) - 1
		$Furniture.add_child(furn_shadow)

		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.centered = false
		sprite.scale = Vector2(item["scale"], item["scale"])
		sprite.position = item["pos"]
		sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
		sprite.z_index = int(item["pos"].y)
		$Furniture.add_child(sprite)

		var rect := Rect2(item["pos"] - Vector2(size.x / 2.0, size.y), size)
		obstacles.append(rect)

		if item["action"] != "":
			interactables.append({
				"action": item["action"], "pos": item["pos"], "rect": rect, "node": sprite,
			})


# ---------- อินพุต ----------

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	var pos := Vector2.ZERO

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pressed = true
			pos = event.position
	elif event is InputEventScreenTouch:
		if event.pressed:
			pressed = true
			pos = event.position

	if not pressed or pos.y >= HUD_TOP:
		return

	if (
		hud.creation_layer != null or hud.panel_layer != null
		or hud.event_layer != null or hud.game_over_layer != null
	):
		return

	for item in interactables:
		if item["rect"].has_point(pos):
			_interact(item)
			return

	pending_action = ""
	move_target = pos
	has_target = true


func _interact(item: Dictionary) -> void:
	var target: Vector2 = item["pos"]
	if player.position.distance_to(target) <= REACH:
		_do_action(item["action"])
		return
	pending_action = item["action"]
	move_target = Vector2(target.x, minf(target.y + 40.0, FLOOR_BOTTOM))
	has_target = true


# ---------- การเคลื่อนที่ ----------

func _blocked(point: Vector2) -> bool:
	var feet := Vector2(point.x, point.y - 2.0)
	for rect in obstacles:
		if rect.has_point(feet):
			return true
	return false


func _process(delta: float) -> void:
	if (
		hud.creation_layer != null or hud.panel_layer != null
		or hud.event_layer != null or hud.game_over_layer != null
	):
		return

	var kx := 0.0
	var ky := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		kx -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		kx += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		ky -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		ky += 1.0

	var moving := false

	if kx != 0.0 or ky != 0.0:
		has_target = false
		pending_action = ""
		var dir := Vector2(kx, ky).normalized()
		_try_move(dir * SPEED * delta)
		player.flip_h = kx < 0.0
		moving = true
	elif has_target:
		var diff := move_target - player.position
		if diff.length() < 3.0:
			has_target = false
			if pending_action != "":
				var action := pending_action
				pending_action = ""
				_do_action(action)
		else:
			var step := minf(SPEED * delta, diff.length())
			var before := player.position
			_try_move(diff.normalized() * step)
			player.flip_h = diff.x < 0.0
			moving = true
			if player.position.distance_to(before) < 0.01:
				has_target = false
				if pending_action != "":
					var action := pending_action
					pending_action = ""
					_do_action(action)

	if moving:
		walk_time += delta * 12.0
		player.scale.y = base_scale + sin(walk_time) * 0.15
	else:
		player.scale.y = base_scale

	player.z_index = int(player.position.y)
	_update_shadow()


func _update_shadow() -> void:
	if shadow == null:
		return
	shadow.position = player.position + Vector2(0, -2)
	shadow.z_index = int(player.position.y) - 1


func _try_move(delta: Vector2) -> void:
	var nx := clampf(player.position.x + delta.x, 30.0, 450.0)
	var ny := clampf(player.position.y + delta.y, FLOOR_TOP, FLOOR_BOTTOM)
	if not _blocked(Vector2(nx, player.position.y)):
		player.position.x = nx
	if not _blocked(Vector2(player.position.x, ny)):
		player.position.y = ny


# ---------- เกมเพลย์ ----------

func _on_action_pressed(key: String) -> void:
	_do_action(key)


func _do_action(key: String) -> void:
	if not Game.created:
		return
	var was_child := Game.is_child()
	var result := Game.run_action(key)
	if result.get("ok", false):
		_pop_effect(key)
	if was_child and not Game.is_child() and Game.alive:
		hud.toast("🎉 โตเป็นผู้ใหญ่แล้ว! เริ่มชีวิตวัยทำงาน", Color("#ffe9a8"))
	_after_turn(result)


## อัปเดตหน้าจอหลังทุกการกระทำ + โชว์เหตุการณ์ถ้ามี
func _after_turn(result: Dictionary) -> void:
	_sync_player()
	hud.refresh()
	_sync_partner()
	_apply_mood()

	if not result.get("ok", false):
		hud.toast(String(result.get("message", "")), Color("#ffb4b4"))
		return

	mood_step = (mood_step + 1) % 4
	_apply_mood()
	hud.toast(String(result.get("message", "")), Color("#d7ffe0"))

	if not Game.alive:
		hud.show_game_over()
		return

	if not Game.pending_event.is_empty():
		hud.show_event(Game.pending_event)


## ใช้กับการกระทำที่ไม่เดินเวลา (เงิน/ยา/แต่งตัว)
func _after_instant(result: Dictionary) -> void:
	_sync_player()
	hud.refresh()
	_sync_partner()

	if not result.get("ok", false):
		hud.toast(String(result.get("message", "")), Color("#ffb4b4"))
		return

	hud.toast(String(result.get("message", "")), Color("#d7ffe0"))
	if not Game.alive:
		hud.show_game_over()
		return
	if not Game.pending_event.is_empty():
		hud.show_event(Game.pending_event)


func _on_creation_confirmed(pname: String, pgender: String, wealth: int) -> void:
	Game.start_life(pname, pgender, wealth)
	player.position = Vector2(330, 482)
	_update_shadow()
	has_target = false
	pending_action = ""
	mood_step = 0
	hud.hide_game_over()
	_sync_player()
	hud.refresh()
	_sync_partner()
	_apply_mood()
	hud.toast("ชีวิตใหม่เริ่มต้นแล้ว 🎉 แตะเฟอร์นิเจอร์เพื่อเลือกกิจกรรมของปีนี้", Color("#d7ffe0"))


func _on_job_apply(id: String) -> void:
	_after_turn(Game.apply_job(id))


func _on_job_quit() -> void:
	_after_turn(Game.quit_job())


func _on_date() -> void:
	_after_turn(Game.date_night())


func _on_propose() -> void:
	_after_turn(Game.propose())


func _on_child() -> void:
	_after_turn(Game.have_child())


func _on_breakup() -> void:
	_after_turn(Game.break_up())


func _on_deposit() -> void:
	_after_instant(Game.deposit(1000))


func _on_withdraw() -> void:
	_after_instant(Game.withdraw(1000))


func _on_borrow() -> void:
	_after_instant(Game.borrow(5000))


func _on_repay() -> void:
	_after_instant(Game.repay(5000))


func _on_insurance() -> void:
	_after_instant(Game.toggle_insurance())


func _on_medicine() -> void:
	_after_instant(Game.buy_medicine())


func _on_doctor() -> void:
	_after_instant(Game.see_doctor())


func _on_checkup() -> void:
	_after_instant(Game.checkup())


func _on_outfit_buy(id: String) -> void:
	_after_instant(Game.buy_outfit(id))


func _on_outfit_equip(id: String) -> void:
	_after_instant(Game.equip_outfit(id))


func _on_event_choice(index: int) -> void:
	var result := Game.resolve_event(index)
	_sync_player()
	hud.refresh()
	_sync_partner()
	hud.toast(String(result.get("message", "")), Color("#ffe9a8"))
	if not Game.alive:
		hud.show_game_over()


func _on_restart_pressed() -> void:
	Game.new_game()
	player.position = Vector2(330, 482)
	_update_shadow()
	has_target = false
	pending_action = ""
	mood_step = 0
	hud.hide_game_over()
	_sync_player()
	hud.refresh()
	_sync_partner()
	_apply_mood()
	hud.show_creation()


func _pop_effect(key: String) -> void:
	for item in interactables:
		if item["action"] != key:
			continue
		var spark := Label.new()
		spark.text = "+"
		spark.position = item["pos"] + Vector2(0, -70)
		spark.add_theme_font_size_override("font_size", 22)
		spark.z_index = 500
		add_child(spark)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "position:y", spark.position.y - 40.0, 0.7)
		tween.tween_property(spark, "modulate:a", 0.0, 0.7)
		tween.chain().tween_callback(spark.queue_free)
		return


func _apply_mood() -> void:
	night_overlay.color = MOOD_COLORS[mood_step % 4]
	room_art.queue_redraw()
