extends Node2D
## Town.gd — ตัวควบคุมโลกเดินได้ v4
## โหลดโซนจาก TownData, วาดเมือง, สร้างผู้เล่น/HUD, จัดการประตู/รถเมล์/NPC/มินิเกม

const HUD_SCRIPT := preload("res://scripts/TownHud.gd")
const PLAYER_SCRIPT := preload("res://scripts/Player.gd")
const OVERLAY_SCRIPT := preload("res://scripts/TownOverlay.gd")

## ตำแหน่งบูธเทศกาลประจำฤดู (เฉพาะโซนที่มีเทศกาล)
const FESTIVAL_SPOTS := {
	"park": Vector2(700, 430),
	"downtown": Vector2(480, 280),
}

var hud
var player
var overlay

var zone: Dictionary = {}
var npcs: Array = []
var nearest: Dictionary = {}
var checkpoints: Array = []

var _npc_tick := 0.0
var _draw_tick := 0.0
var _edge_cooldown := 0.0
var _next_cp := 0
var _laps := 0
var _last_day := 1
var _name_font: Font
var _t := 0.0


func _ready() -> void:
	_setup_input()
	_name_font = Fonts.regular()

	var layer := CanvasLayer.new()
	layer.name = "HudLayer"
	add_child(layer)
	hud = HUD_SCRIPT.new()
	layer.add_child(hud)
	hud.interact_pressed.connect(_interact)
	hud.travel_requested.connect(_on_bus_travel)
	hud.life_started.connect(_on_life_started)

	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	add_child(player)
	player.visible = Game.created

	overlay = OVERLAY_SCRIPT.new()
	overlay.name = "Overlay"
	add_child(overlay)

	_last_day = Game.day
	_load_zone(Game.zone_id, _initial_spawn())
	if not Game.created:
		player.visible = false
		hud.show_creation()


func _initial_spawn() -> Vector2:
	if Game.zone_id != "" and Game.player_pos != Vector2.ZERO:
		return Game.player_pos
	return TownData.spawn_of(Game.zone_id)


func _setup_input() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
	var has_key := false
	for ev in InputMap.action_get_events("interact"):
		if ev is InputEventKey and ev.keycode == KEY_E:
			has_key = true
	if not has_key:
		var e := InputEventKey.new()
		e.keycode = KEY_E
		InputMap.action_add_event("interact", e)
	var has_enter := false
	for ev in InputMap.action_get_events("interact"):
		if ev is InputEventKey and ev.keycode == KEY_ENTER:
			has_enter = true
	if not has_enter:
		var e2 := InputEventKey.new()
		e2.keycode = KEY_ENTER
		InputMap.action_add_event("interact", e2)


# ============================================================
#  โหลดโซน
# ============================================================
func _load_zone(id: String, spawn: Vector2) -> void:
	if not TownData.ZONES.has(id):
		id = "home"
	zone = TownData.zone(id)
	Game.zone_id = id

	var bounds := Rect2(22, 158, 916, 348)
	if TownData.is_outdoor(id):
		bounds = Rect2(24, 160, 912, 350)

	var solids: Array[Rect2] = []
	for b in zone.get("buildings", []):
		solids.append(Rect2(
			float(b.get("x", 0)), float(b.get("y", 0)),
			float(b.get("w", 0)), float(b.get("h", 0))
		))

	player.set_zone(id, spawn, bounds, solids)
	player.visible = Game.created
	Game.player_pos = spawn

	checkpoints = zone.get("checkpoints", [])
	_next_cp = 0
	_laps = 0
	npcs = TownData.npcs_for(id, Game.time_min, Game.weekday)
	_seed_npc_motion()
	nearest = {}
	_edge_cooldown = 0.8
	hud.set_prompt("")
	hud.set_run_status("")
	hud.refresh()
	queue_redraw()


func _refresh_npcs() -> void:
	var fresh: Array = TownData.npcs_for(Game.zone_id, Game.time_min, Game.weekday)
	var old := {}
	for npc in npcs:
		old[String(npc.get("id", ""))] = npc
	for i in fresh.size():
		var npc: Dictionary = fresh[i]
		var nid := String(npc.get("id", ""))
		if old.has(nid):
			var prev: Dictionary = old[nid]
			for key in ["pos", "home", "face", "walk_t", "pause", "target", "wander_n"]:
				if prev.has(key):
					npc[key] = prev[key]
		else:
			_seed_one_npc(npc, i)
	npcs = fresh


func _seed_npc_motion() -> void:
	for i in npcs.size():
		_seed_one_npc(npcs[i], i)


func _seed_one_npc(npc: Dictionary, i: int) -> void:
	var p: Vector2 = npc.get("pos", Vector2(480, 420))
	npc["home"] = p
	npc["pos"] = p
	npc["face"] = 1 if i % 2 == 0 else -1
	npc["walk_t"] = 0.0
	npc["pause"] = 0.6 + float(i % 4) * 0.5
	npc["target"] = p
	npc["wander_n"] = i


func _npc_spot_ok(p: Vector2) -> bool:
	var b := Rect2(40, 190, 880, 310)
	if player != null:
		b = player.bounds.grow(-18.0)
	if not b.has_point(p):
		return false
	for bd in zone.get("buildings", []):
		var r := Rect2(
			float(bd.get("x", 0)), float(bd.get("y", 0)),
			float(bd.get("w", 0)), float(bd.get("h", 0))
		)
		if r.grow(10.0).has_point(p):
			return false
	if zone.has("bus") and p.distance_to(zone["bus"]) < 26.0:
		return false
	return true


func _npc_wander_target(npc: Dictionary, i: int) -> Vector2:
	var home: Vector2 = npc.get("home", npc.get("pos", Vector2(480, 420)))
	var n := int(npc.get("wander_n", 0))
	npc["wander_n"] = n + 1
	for attempt in 8:
		var ang := float((i * 37 + n * 53 + attempt * 71) % 360) * PI / 180.0
		var rad := 30.0 + float((i * 13 + n * 29 + attempt * 17) % 46)
		var cand := home + Vector2(cos(ang) * rad, sin(ang) * rad * 0.55)
		if _npc_spot_ok(cand):
			return cand
	return home


func _update_npcs(delta: float) -> void:
	if not Game.created or hud == null or hud.busy:
		return
	for i in npcs.size():
		var npc: Dictionary = npcs[i]
		if not npc.has("home"):
			_seed_one_npc(npc, i)
		var pos: Vector2 = npc.get("pos", Vector2(480, 420))
		var pause := float(npc.get("pause", 0.0))
		if pause > 0.0:
			npc["pause"] = pause - delta
			npc["walk_t"] = 0.0
			if player != null and pos.distance_to(player.position) < 82.0:
				var dx0: float = player.position.x - pos.x
				if absf(dx0) > 5.0:
					npc["face"] = 1 if dx0 > 0.0 else -1
			continue
		var target: Vector2 = npc.get("target", pos)
		var to := target - pos
		if to.length() < 3.0:
			npc["pause"] = 1.1 + float((i * 7) % 5) * 0.45 + absf(sin(_t * 0.7 + float(i))) * 1.3
			npc["target"] = _npc_wander_target(npc, i)
			npc["walk_t"] = 0.0
			continue
		var step := to.normalized() * 21.0 * delta
		if step.length() > to.length():
			step = to
		var nx := pos + step
		if _npc_spot_ok(nx):
			npc["pos"] = nx
			npc["walk_t"] = float(npc.get("walk_t", 0.0)) + delta
			if absf(step.x) > 0.04:
				npc["face"] = 1 if step.x > 0.0 else -1
		else:
			npc["target"] = _npc_wander_target(npc, i)


func _on_life_started() -> void:
	Game.zone_id = "home"
	player.visible = true
	_load_zone("home", TownData.spawn_of("home"))
	hud.toast("เริ่มชีวิตที่อายุ 6 ขวบ — เดินออกจากบ้านไปโรงเรียนได้เลย")
	Game.save_game()


# ============================================================
#  ลูปเกม
# ============================================================
func _process(delta: float) -> void:
	_t += delta
	if _edge_cooldown > 0.0:
		_edge_cooldown -= delta

	if Game.day != _last_day:
		_last_day = Game.day
		_refresh_npcs()

	player.can_move = Game.created and Game.alive and not hud.busy
	if player.can_move:
		_check_edges()

	_npc_tick -= delta
	if _npc_tick <= 0.0:
		_npc_tick = 0.7
		_refresh_npcs()
	_update_npcs(delta)

	if Game.created:
		_update_nearest()
		_check_park()
		Game.player_pos = player.position

	_draw_tick += delta
	if _draw_tick >= 1.0 / 30.0:
		_draw_tick = 0.0
		queue_redraw()


func _check_edges() -> void:
	if _edge_cooldown > 0.0:
		return
	for e in zone.get("exits", []):
		var edge := String(e.get("edge", ""))
		var hit := false
		match edge:
			"left":
				hit = player.position.x <= 30.0
			"right":
				hit = player.position.x >= 930.0
			"top":
				hit = player.position.y <= 166.0
			"bottom":
				hit = player.position.y >= 502.0
		if hit:
			_enter_zone(String(e.get("zone", "home")), e.get("spawn", Vector2(480, 440)), 4)
			return


func _enter_zone(id: String, spawn: Vector2, minutes: int = 4) -> void:
	if not TownData.ZONES.has(id):
		return
	if minutes > 0:
		Game.advance_minutes(minutes)
	Game.save_game()
	_load_zone(id, spawn)
	Game.save_game()
	hud.toast("ถึง%s" % TownData.zone_name(id))


func _on_bus_travel(id: String) -> void:
	var spawn: Vector2 = TownData.spawn_of(id)
	var res := Game.travel_to(id, spawn)
	hud.toast(String(res.get("message", "")))
	if bool(res.get("ok", false)):
		_load_zone(id, spawn)


func set_joystick(v: Vector2) -> void:
	if player != null:
		player.joystick = v


# ============================================================
#  จุดกดใช้ / บทสนทนา
# ============================================================
func _update_nearest() -> void:
	nearest = {}
	var best := 74.0

	for npc in npcs:
		var d: float = player.position.distance_to(npc["pos"])
		if d < best:
			best = d
			nearest = {
				"kind": "npc", "pos": npc["pos"],
				"label": "คุยกับ %s" % String(npc.get("name", "?")),
				"npc": npc,
			}

	for door in zone.get("doors", []):
		var d: float = player.position.distance_to(door["pos"])
		if d < best:
			best = d
			nearest = {
				"kind": "door", "pos": door["pos"],
				"label": String(door.get("label", "เข้าอาคาร")),
				"zone": String(door.get("zone", "home")),
				"spawn": door.get("spawn", Vector2(480, 440)),
			}

	var interior := TownData.interior_door(Game.zone_id)
	if not interior.is_empty():
		var d: float = player.position.distance_to(interior["pos"])
		if d < best:
			best = d
			nearest = {
				"kind": "door", "pos": interior["pos"],
				"label": String(interior.get("label", "ออกไปข้างนอก")),
				"zone": String(interior["zone"]),
				"spawn": interior["spawn"],
			}

	if zone.has("bus"):
		var d: float = player.position.distance_to(zone["bus"])
		if d < best:
			best = d
			nearest = {"kind": "bus", "pos": zone["bus"], "label": "ขึ้นรถเมล์"}

	for p in zone.get("props", []):
		var action := String(p.get("action", ""))
		if action == "":
			continue
		var d: float = player.position.distance_to(p["pos"])
		if d < best:
			best = d
			nearest = {
				"kind": "prop", "pos": p["pos"], "prop": p,
				"label": String(p.get("label", "ใช้งาน")),
				"action": action,
			}

	# ม้านั่งสาธารณะ — นั่งพักได้
	for bch in zone.get("benches", []):
		var bp := Vector2(float(bch[0]), float(bch[1]))
		var db: float = player.position.distance_to(bp)
		if db < best and db < 54.0:
			best = db
			nearest = {
				"kind": "bench", "pos": bp,
				"label": "นั่งพักผ่อน", "action": "sit_rest",
			}

	# บูธเทศกาล (เฉพาะวันเทศกาล)
	var fpos := _festival_spot()
	if fpos != Vector2.ZERO:
		var d2: float = player.position.distance_to(fpos)
		if d2 < 104.0 and d2 < best:
			best = d2
			nearest = {
				"kind": "festival", "pos": fpos,
				"label": String(Game.festival_today().get("name", "เทศกาล")),
				"action": "festival",
			}

	# แมวที่บ้าน (ถ้าซื้อที่นอนแมวแล้ว)
	if Game.zone_id == "home" and Game.pet_name != "" and TownData.FURNITURE_SLOTS.has("cat_bed"):
		var cpos: Vector2 = TownData.FURNITURE_SLOTS["cat_bed"]
		var d3: float = player.position.distance_to(cpos)
		if d3 < 68.0 and d3 < best:
			best = d3
			nearest = {
				"kind": "prop", "pos": cpos,
				"label": "เล่นกับ%s" % Game.pet_name,
				"action": "pet_cat",
			}

	if nearest.is_empty():
		hud.set_prompt("")
	else:
		hud.set_prompt("[E] " + String(nearest.get("label", "")))


func _festival_spot() -> Vector2:
	var f := Game.festival_today()
	if f.is_empty():
		return Vector2.ZERO
	var zid := String(f.get("zone", ""))
	if zid != Game.zone_id:
		return Vector2.ZERO
	return FESTIVAL_SPOTS.get(zid, Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if hud != null and not hud.busy and Game.created and Game.alive:
			_interact()
		get_viewport().set_input_as_handled()


func _interact() -> void:
	if nearest.is_empty():
		hud.toast("เดินไปใกล้ ๆ สิ่งที่ต้องการใช้ก่อน")
		return
	match String(nearest.get("kind", "")):
		"npc":
			var npc: Dictionary = nearest["npc"]
			if String(npc.get("kind", "npc")) == "parent":
				hud.open_parent_dialog(String(npc.get("id", "dad")))
			else:
				hud.open_npc_dialog(npc)
		"door":
			_enter_zone(String(nearest["zone"]), nearest["spawn"], 4)
		"bus":
			hud.open_bus()
		"festival":
			_do_festival()
		"bench":
			_sit_on_bench(nearest.get("pos", player.position) + Vector2(0, -1))
		"prop":
			_do_prop_action(String(nearest.get("action", "")), nearest.get("pos", player.position),
				nearest.get("prop", {}))


func _do_festival() -> void:
	var f := Game.festival_today()
	if f.is_empty():
		hud.toast("วันนี้ไม่มีเทศกาล")
		return
	if Game.festival_attended_today():
		hud.toast("วันนี้ร่วม%sแล้ว — กลับมาอีกครั้งฤดูหน้า" % String(f.get("name", "เทศกาล")))
		return
	var title := "เทศกาล • %s" % String(f.get("name", "เทศกาล"))
	hud.start_minigame(String(f.get("kind", "timing")), title, 4, func(score: int) -> void:
		_show(Game.join_festival(score))
	)


func _interact_farm(index: int) -> void:
	if index < 0 or index >= Game.farm_plots.size():
		hud.toast("แปลงนี้ใช้งานไม่ได้")
		return
	var stage := Game.farm_stage(index)
	if stage == "empty":
		hud.open_summary("farm")
		hud.toast("เลือกเมล็ดพันธุ์ในแท็บฟาร์ม แล้วกลับมากดที่แปลงอีกครั้ง")
		return
	if stage == "ready":
		_show(Game.farm_harvest(index))
		return
	var plot := Game.farm_plot_data(index)
	if not bool(plot.get("watered", false)):
		_show(Game.farm_water(index))
		return
	var crop := Game.crop_data(Game.farm_crop(index))
	var need := maxi(int(crop.get("days", 1)), 1)
	hud.toast("%sกำลังโต (%d/%d วัน) • วันนี้รดน้ำแล้ว" % [
		String(crop.get("name", "พืช")), int(plot.get("growth", 0)), need
	])


func _do_fish() -> void:
	if Game.fish_actions >= 5:
		hud.toast("วันนี้ตกปลาครบ 5 ครั้งแล้ว — พรุ่งนี้มาใหม่")
		return
	if Game.energy < 8:
		hud.toast("เหนื่อยเกินไปสำหรับตกปลา")
		return
	hud.start_minigame("timing", "ตกปลาที่ท่าเรือ", 4, func(score: int) -> void:
		var good := score >= 40
		var quality := 2 if score >= 85 else (1 if score >= 65 else 0)
		_show(Game.fish_result(good, quality))
	)


func _do_catch_bug() -> void:
	if Game.bug_actions >= 5:
		hud.toast("วันนี้จับแมลงครบ 5 ครั้งแล้ว — พรุ่งนี้มาใหม่")
		return
	if Game.energy < 6:
		hud.toast("เหนื่อยเกินไปสำหรับไล่จับแมลง")
		return
	hud.start_minigame("catch", "จับแมลงในสวน", 4, func(score: int) -> void:
		var good := score >= 40
		var quality := 2 if score >= 85 else (1 if score >= 65 else 0)
		_show(Game.bug_result(good, quality))
	)


func _do_booth() -> void:
	if Game.booth_plays >= 3:
		hud.toast("วันนี้เล่นบูธครบ 3 ครั้งแล้ว")
		return
	if Game.money < 50:
		hud.toast("เงินไม่พอค่าเล่นบูธ (ต้อง ฿50)")
		return
	hud.start_minigame("timing", "บูธเกมเทศกาล", 4, func(score: int) -> void:
		var good := score >= 50
		var quality := 2 if score >= 85 else (1 if score >= 70 else 0)
		_show(Game.play_festival_booth(good, quality))
	)


func _sit_on_bench(p: Vector2) -> void:
	player.sit_at(p)
	var res := Game.rest_bench()
	hud.toast(String(res.get("message", "")))
	hud.refresh()


func _do_prop_action(action: String, at := Vector2.ZERO, prop: Dictionary = {}) -> void:
	match action:
		"sit_rest":
			_sit_on_bench((at if at != Vector2.ZERO else player.position) + Vector2(0, 14))
		"farm_plot":
			_interact_farm(int(prop.get("index", -1)))
		"fish":
			_do_fish()
		"catch_bug":
			_do_catch_bug()
		"festival_booth":
			_do_booth()
		"sleep":
			hud.open_alarm()
		"homework":
			_show(Game.do_homework())
		"eat_home":
			_show(Game.eat_food(Game.COST_HOME_MEAL, 32, 5, 30, "ข้าวที่บ้าน"))
		"watch_tv":
			_show(Game.watch_tv())
		"dinner":
			_show(Game.family_dinner())
		"school":
			_do_school()
		"university":
			_do_university()
		"work":
			_do_work()
		"gym":
			hud.open_shop("gym")
		"shop_store":
			hud.open_shop("store")
		"shop_cafe":
			hud.open_shop("cafe")
		"shop_mall":
			hud.open_shop("mall")
		"hospital":
			hud.open_shop("hospital")
		"bank":
			hud.open_shop("bank")
		"bar":
			hud.open_shop("bar")
		"collect":
			_show(Game.collect_find(Game.zone_id))
		"practice_art":
			_show(Game.practice_art())
		"cook_meal":
			_show(Game.cook_meal())
		"craft_item":
			_show(Game.craft_item())
		"pet_cat":
			_show(Game.pet_cat())
		_:
			hud.toast("ยังใช้งานไม่ได้")


func _do_school() -> void:
	var reason := Game.school_block_reason()
	if reason != "":
		hud.toast(reason)
		return
	hud.start_minigame("math", "คาบเรียนวันนี้", 4, func(score: int) -> void:
		_show(Game.attend_school(score))
	)


func _do_university() -> void:
	if Game.is_child():
		hud.toast("ยังต้องเรียนมัธยมก่อน")
		return
	if Game.money < Game.COST_STUDY:
		hud.toast("เงินไม่พอค่าเล่าเรียน ฿%d" % Game.COST_STUDY)
		return
	hud.start_minigame("math", "คาบเรียนมหาวิทยาลัย", 4, func(score: int) -> void:
		_show(Game.study_lecture(score))
	)


func _do_work() -> void:
	var reason := Game.work_block_reason()
	if reason != "":
		hud.toast(reason)
		return
	if Game.job_id != "" and Game.current_workplace() != Game.zone_id:
		hud.toast("ที่นี่ไม่ใช่ที่ทำงานของคุณ — ที่ทำงานคือ%s" % TownData.zone_name(Game.current_workplace()))
		return
	var kind := "timing"
	match Game.zone_id:
		"office":
			kind = "sequence"
		"store", "cafe":
			kind = "catch"
		"hospital", "university":
			kind = "math"
	var title := "กะทำงาน • %s" % Game.job_title() if Game.job_id != "" else "รับจ้างรายวัน"
	hud.start_minigame(kind, title, 4, func(score: int) -> void:
		_show(Game.work_shift(score))
	)


func _show(res: Dictionary) -> void:
	hud.toast(String(res.get("message", "")))
	hud.refresh()
	if not Game.alive:
		hud.show_game_over()


# ============================================================
#  สวนสาธารณะ — วิ่งผ่านจุดตรวจ 3 รอบ
# ============================================================
func _check_park() -> void:
	if Game.zone_id != "park" or checkpoints.is_empty():
		hud.set_run_status("")
		return
	if hud.busy:
		return
	hud.set_run_status("🏃 รอบ %d/3 • จุด %d/%d" % [
		_laps + 1, _next_cp + 1, checkpoints.size()
	])
	if player.position.distance_to(checkpoints[_next_cp]) > 42.0:
		return
	_next_cp += 1
	if _next_cp < checkpoints.size():
		return
	_next_cp = 0
	_laps += 1
	if _laps >= 3:
		var res := Game.park_run(3)
		_laps = 0
		_next_cp = 0
		_show(res)
		hud.toast("🏃 วิ่งครบ 3 รอบ! " + String(res.get("message", "")))
	else:
		hud.toast("🏃 ครบ %d รอบ! อีก %d รอบ" % [_laps, 3 - _laps])


# ============================================================
#  วาด
# ============================================================
func _draw() -> void:
	if zone.is_empty():
		return
	TownArt.draw_zone(self, Game.zone_id, zone, int(Game.time_min) / 60, Game.season, _t)

	# เฟอร์นิเจอร์ที่ซื้อไว้ในบ้าน
	if Game.zone_id == "home":
		var hour := int(Game.time_min) / 60
		for fid in Game.home_items:
			var key := String(fid)
			if TownData.FURNITURE_SLOTS.has(key):
				var slot: Vector2 = TownData.FURNITURE_SLOTS[key]
				TownArt.draw_furniture(self, key, slot, _t, hour)

	# บูธเทศกาลประจำฤดู
	var fspot := _festival_spot()
	if fspot != Vector2.ZERO:
		TownArt.draw_festival_booth(self, fspot, Game.festival_today(), _t)

	# จุดตรวจสวนสาธารณะ
	if Game.zone_id == "park" and not checkpoints.is_empty():
		for i in checkpoints.size():
			var cp: Vector2 = checkpoints[i]
			var active := i == _next_cp
			var pulse := 0.5 + sin(_t * 4.0 + float(i)) * 0.5
			var col := Color(0.95, 0.85, 0.3, 0.8) if active else Color(0.85, 0.85, 0.85, 0.35)
			draw_circle(cp, 22.0, Color(0, 0, 0, 0.18))
			draw_arc(cp, 19.0, 0, TAU, 28, col, 3.0, true)
			if active:
				draw_arc(cp, 24.0 + pulse * 3.0, 0, TAU, 28,
					Color(1.0, 0.9, 0.4, 0.35 + pulse * 0.25), 2.0, true)
			draw_string(_name_font, cp + Vector2(-8, 7), str(i + 1),
				HORIZONTAL_ALIGNMENT_CENTER, 16, 14, Color(1, 1, 1, 0.9))

	# NPC
	for i in npcs.size():
		var npc: Dictionary = npcs[i]
		var pos: Vector2 = npc.get("pos", Vector2(480, 400))
		var npc_id := String(npc.get("id", ""))
		var pal := {
			"skin": String(npc.get("skin", "#f2c39b")),
			"hair": String(npc.get("hair", "#2a2118")),
			"shirt": String(npc.get("shirt", "#4aa3ff")),
			"pants": String(npc.get("pants", "#2e3a59")),
			"shoes": "#2a2018",
			"hair_style": String(npc.get("hair_style", "short")),
			"style": String(npc.get("style", "normal")),
			"accessory": String(npc.get("accessory", "none")),
			"expression": "happy" if Game.friendship_of(npc_id) >= 55 else "neutral",
		}
		TownArt.draw_person(self, pos, pal, 1.02,
			float(npc.get("walk_t", 0.0)), int(npc.get("face", 1)), _t + float(i) * 0.9)
		# ป้ายชื่อสไตล์กระดาษ
		var nm := String(npc.get("name", "?"))
		var tag_w := maxf(48.0, float(nm.length()) * 8.6 + 14.0)
		var tag_x := pos.x - tag_w * 0.5
		var tag_y := pos.y - 84.0
		draw_rect(Rect2(tag_x - 1.0, tag_y - 1.0, tag_w + 2.0, 19.0), Color("#6b4a32"))
		draw_rect(Rect2(tag_x, tag_y, tag_w, 17.0), Color("#f6ecd8"))
		draw_rect(Rect2(tag_x, tag_y, tag_w, 2.0), Color("#fffaf0"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(pos.x - 5, tag_y + 17.0), Vector2(pos.x + 5, tag_y + 17.0),
			Vector2(pos.x, tag_y + 23.0),
		]), Color("#6b4a32"))
		draw_string(_name_font, Vector2(tag_x, tag_y + 13.0), nm,
			HORIZONTAL_ALIGNMENT_CENTER, tag_w, 11, Color("#4a3626"))
		# หัวใจเล็ก ๆ ตามระดับความสัมพันธ์
		var f := Game.friendship_of(npc_id)
		if f >= 25:
			var hearts := 1 + int(f / 35)
			for h in hearts:
				draw_circle(Vector2(pos.x - 8 + h * 8, pos.y - 62), 2.2, Color("#f07a9a"))
