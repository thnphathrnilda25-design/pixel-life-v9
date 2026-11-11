extends Node
## Smoke.gd — ทดสอบอัตโนมัติ v7 (เมืองเดินได้ / เวลา / โรงเรียน / งาน / นอน / สวน / NPC
## / ทักษะ / บ้าน / ของสะสม / เทศกาล / กำเนิดและกรรมพัน)
## รัน: godot --headless --path . res://tests/Smoke.tscn

var ok: Array[String] = []
var bad: Array[String] = []
var town = null


func _ready() -> void:
	await get_tree().process_frame
	seed(20260709)

	if FileAccess.file_exists("user://pixel_life.save"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pixel_life.save"))
	Game.new_game()
	Game.time_paused = true

	var town_scene: PackedScene = load("res://scenes/Town.tscn")
	town = town_scene.instantiate()
	add_child(town)
	await get_tree().process_frame
	await get_tree().process_frame

	_test_town_data()
	await _test_scene()
	_test_creation()
	_test_character_v6()
	_test_v7_farm()
	_test_v7_hobby()
	_test_v7_business()
	_test_v7_home_social()
	_test_v7_awards_family()
	await _test_npc_walking()
	_test_birth_inheritance()
	await _test_v9_genetics()
	_test_time_calendar()
	_test_school()
	_test_work()
	_test_sleep()
	_test_gym_park()
	_test_family()
	_test_npcs()
	_test_bus()
	_test_zone_travel()
	_test_interactions()
	_test_home_actions()
	_test_skills()
	_test_home_decor()
	_test_collectibles()
	_test_festivals()
	await _test_festival_scene()
	_test_save_load()
	_test_hud_panels()
	await _test_minigame()
	_test_creation_flow()
	_test_v8_quests()
	_test_v8_goals()

	print("\n===== SMOKE TEST v9 =====")
	for line in ok:
		print("PASS  ", line)
	for line in bad:
		print("FAIL  ", line)
	print("========================\n")
	print("RESULT: %d passed, %d failed" % [ok.size(), bad.size()])

	if FileAccess.file_exists("user://pixel_life.save"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pixel_life.save"))

	get_tree().quit(1 if bad.size() > 0 else 0)


func _check(condition: bool, label: String) -> void:
	if condition:
		ok.append(label)
	else:
		bad.append(label)


func _fresh(p_age: int = 6) -> void:
	Game.new_game()
	Game.created = true
	Game.age = p_age
	Game.time_paused = true


# ============================================================
#  ข้อมูลเมือง
# ============================================================

func _test_town_data() -> void:
	var errors := TownData.validate()
	_check(errors.is_empty(), "TownData ผ่านการตรวจ (%d ปัญหา)" % errors.size())
	if not errors.is_empty():
		for e in errors:
			print("   TOWN ERROR: ", e)
	_check(TownData.ZONES.size() == 17, "มี 17 โซน (ได้ %d)" % TownData.ZONES.size())
	_check(TownData.NPCS.size() == 28, "มี NPC 28 คน (ได้ %d)" % TownData.NPCS.size())
	var styled := 0
	for nid in TownData.NPCS.keys():
		var npc: Dictionary = TownData.NPCS[nid]
		if npc.has("hair_style") and npc.has("style") and npc.has("accessory"):
			styled += 1
	_check(styled == TownData.NPCS.size(), "NPC ทุกคนมีทรงผม/สไตล์/เครื่องประดับ (%d/%d)" % [styled, TownData.NPCS.size()])
	for fid in TownData.FURNITURE_SLOTS.keys():
		_check(not Game.furniture_data(String(fid)).is_empty(),
			"ช่องเฟอร์นิเจอร์ %s มีของจริง" % fid)
	for f in Game.FESTIVALS:
		_check(TownData.ZONES.has(String(f.get("zone", ""))),
			"เทศกาล %sอยู่โซนจริง" % String(f.get("id", "")))
	var outdoor := 0
	for zid in TownData.ZONES.keys():
		if TownData.is_outdoor(zid):
			outdoor += 1
	_check(outdoor == 5, "โซนกลางแจ้ง 5 โซน (ได้ %d)" % outdoor)
	for zid in ["home", "home_street", "classroom", "school_district", "park",
			"downtown", "office", "store", "cafe", "hospital", "bank", "mall", "bar", "gym",
			"neighbor_home", "university", "backyard"]:
		_check(TownData.ZONES.has(zid), "มีโซน %s" % zid)
	var park_npcs := TownData.npcs_for("park", 17 * 60, 1)
	_check(park_npcs.size() >= 2, "สวนสาธารณะมี NPC ช่วงเย็น (%d คน)" % park_npcs.size())
	var school_npcs := TownData.npcs_for("classroom", 9 * 60, 1)
	_check(school_npcs.size() >= 1, "ห้องเรียนมี NPC/ครูช่วงเรียน (%d คน)" % school_npcs.size())
	var weekend_school := TownData.npcs_for("classroom", 9 * 60, 6)
	_check(weekend_school.is_empty(), "วันหยุดไม่มีครูในห้องเรียน")


# ============================================================
#  ฉาก / HUD
# ============================================================

func _test_scene() -> void:
	_check(town != null, "Town scene โหลดได้")
	_check(town.player != null, "มีผู้เล่นในฉาก")
	_check(town.hud != null, "มี HUD ในฉาก")
	_check(town.overlay != null, "มี overlay กลางวัน/กลางคืน")
	_check(town.hud.get_busy(), "เกมใหม่เปิดหน้าสร้างตัวละคร")
	town.hud.close_all()
	await get_tree().process_frame
	_check(not town.hud.get_busy(), "ปิดหน้าสร้างตัวละครได้")


# ============================================================
#  สร้างตัวละคร v4
# ============================================================

func _test_creation() -> void:
	Game.new_game()
	_check(not Game.created, "เกมใหม่ยังไม่สร้างตัวละคร")
	_check(Game.age == 6, "เริ่มที่อายุ 6 ขวบ")
	_check(Game.stage_key() == "child", "อยู่ในวัยเด็ก")
	_check(Game.zone_id == "home", "เริ่มที่บ้าน")
	_check(Game.grades == 50 and Game.fitness == 30, "เกรด 50 / ฟิตเนส 30")
	_check(Game.edu == 4, "การศึกษาเริ่มต้น 4")
	_check(Game.owns_outfit("school"), "มีชุดนักเรียนตั้งแต่ต้น")
	_check(Game.time_min == 6 * 60, "เริ่มเวลา 06:00")
	_check(Game.weekday == 1 and Game.season == 0 and Game.season_day == 1, "เริ่มวันจันทร์ ฤดูใบไม้ผลิ วันที่ 1")
	_check(Game.skill_of("communication") == 5, "ทักษะเริ่มต้นทุกอย่าง 5")
	_check(Game.birth_outfit == "heirloom_blue" and Game.karma_id == "warm", "ค่าเริ่มต้นผ้าห่อตัวฟ้า/กรรมพันอบอุ่น")

	Game.start_life("นุ่น", "หญิง", 2, "heirloom_rose", "artist")
	_check(Game.created, "start_life ตั้ง created = true")
	_check(Game.player_name == "นุ่น" and Game.gender == "หญิง", "ชื่อ/เพศถูกบันทึก")
	_check(Game.family_wealth == 2 and Game.family_wealth_name() == "ฐานะร่ำรวย", "ฐานะครอบครัวถูกบันทึก")
	_check(Game.annual_allowance() == 6000, "ครอบครัวรวยให้เงินใช้ปีละ ฿6,000")
	_check(Game.birth_outfit == "heirloom_rose", "ผ้าห่อตัวที่เลือกถูกบันทึก")
	_check(Game.parent_trait == "artist" and Game.karma_id == "dreamer", "ครอบครัวศิลปินให้กรรมพันแห่งความฝัน")
	_check(Game.outfit == "heirloom_rose" and Game.owns_outfit("heirloom_rose"), "สวมผ้าห่อตัวที่เลือกอัตโนมัติ")
	_check(Game.skill_of("art") >= 13, "ศิลปะเริ่มต้นสูงจากครอบครัวศิลปิน (%d)" % Game.skill_of("art"))
	Game.time_paused = true


func _test_birth_inheritance() -> void:
	var expected := {
		"kind": "warm", "strict": "diligent", "artist": "dreamer",
		"merchant": "lucky", "farmer": "grounded",
	}
	for trait_id in expected.keys():
		Game.new_game()
		Game.start_life("ทดสอบ", "ชาย", 1, "heirloom_green", String(trait_id))
		_check(Game.parent_trait == String(trait_id), "พ่อแม่แบบ %s ถูกบันทึก" % trait_id)
		_check(Game.karma_id == String(expected[trait_id]),
			"พ่อแม่แบบ %s ให้%s" % [trait_id, Game.karma_name()])
		_check(Game.outfit == "heirloom_green", "พ่อแม่แบบ %s: สวมผ้าห่อตัวเขียว" % trait_id)
		_check(Game.owned_outfits.has("heirloom_green"), "พ่อแม่แบบ %s: มีผ้าห่อตัวในคลัง" % trait_id)

	Game.new_game()
	Game.start_life("ทดสอบ", "หญิง", 0, "heirloom_blue", "merchant")
	_check(Game.money == 2000, "ครอบครัวพ่อค้าให้เงินเริ่มต้น ฿2,000")
	_check(Game.birth_outfit_name() == "ผ้าห่อตัวฟ้า", "ชื่อผ้าห่อตัวถูกต้อง")
	_check(Game.karma_desc() != "", "กรรมพันมีคำอธิบาย")
	_check(Game.parent_trait_desc() != "", "ลักษณะครอบครัวมีคำอธิบาย")
	Game.time_paused = true


func _test_v9_genetics() -> void:
	Game.new_game()
	Game.start_life("ทดสอบยีน", "หญิง", 1, "heirloom_rose", "kind", "tan", "auburn", "ponytail")
	Game.age = 25
	Game.money = 50000
	Game.partner_name = "แนน"
	Game.partner_love = 82
	Game.married = false
	Game.partner_npc_id = "nan"
	Game.partner_look = {
		"skin": "#8a5a3a", "hair": "#d8b06a", "hair_style": "curly",
		"shirt": "#f29ac0", "pants": "#5a3a5e", "style": "home",
		"accessory": "headband",
	}
	Game.partner_genes = Game._default_genes(Game.partner_look)
	Game.save_game()
	_check(not Game.married, "未婚但有稳定伴侣也能规划家庭")

	seed(20261110)
	for i in 5:
		if not Game.children.is_empty():
			break
		Game.have_child()
	_check(Game.children.size() == 1, "可和恋人拥有孩子")
	if not Game.children.is_empty():
		var child: Dictionary = Game.children[0]
		var look: Dictionary = child.get("appearance", {})
		var genes: Dictionary = child.get("genes", {})
		var sources: Dictionary = child.get("traits_from", {})
		_check(look.size() == 3, "孩子具有皮肤、发色和发型表现型")
		_check(genes.size() == 3, "孩子保存来自双方的遗传等位特征")
		_check(String(look.get("skin", "")) in [Game.skin_tone_hex(), "#8a5a3a"],
			"孩子皮肤继承自玩家或恋人")
		_check(String(look.get("hair", "")) in [Game.hair_color_hex(), "#d8b06a"],
			"孩子发色继承自玩家或恋人")
		_check(String(sources.get("skin", "")) != "" and String(sources.get("hair_style", "")) != "",
			"บันทึกว่าลักษณะลูกมาจากพ่อหรือแม่คนใด")
		var saved_look := look.duplicate(true)
		Game.save_game()
		Game.children = []
		Game.partner_look = {}
		Game.load_game()
		var loaded_child: Dictionary = Game.children[0]
		_check(loaded_child.get("appearance", {}) == saved_look,
			"เซฟ/โหลดลักษณะและพันธุกรรมของลูกได้")
		_check(Game.partner_look.get("hair_style", "") == "curly",
			"เซฟ/โหลดรูปลักษณ์ของคู่รักได้")
		var save_file := FileAccess.open(Game.SAVE_PATH, FileAccess.READ)
		var legacy_save: Dictionary = JSON.parse_string(save_file.get_as_text())
		save_file.close()
		legacy_save["version"] = 8
		legacy_save.erase("partner_npc_id")
		legacy_save.erase("partner_look")
		legacy_save.erase("partner_genes")
		legacy_save.erase("player_genes")
		var legacy_children: Array = legacy_save.get("children", [])
		for legacy_child in legacy_children:
			legacy_child.erase("appearance")
			legacy_child.erase("genes")
			legacy_child.erase("traits_from")
		var legacy_file := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		legacy_file.store_string(JSON.stringify(legacy_save))
		legacy_file.close()
		Game.load_game()
		_check(Game.partner_name == "แนน" and Game.children.size() == 1,
			"โหลดเซฟ v8 ที่มีคู่รักและลูกเดิมได้")
		_check(Game.partner_look.get("hair_style", "") == "long"
			and Game.children[0].get("appearance", {}).size() == 3,
			"แปลงข้อมูลครอบครัว v8 ให้มีรูปลักษณ์เริ่มต้นได้")
		town.hud.close_all()
		town.hud.open_summary("love")
		await get_tree().process_frame
		await get_tree().process_frame
		_check(town.hud.get_busy(), "เปิดแผงครอบครัวพร้อมภาพคู่รักและลูกได้")
		town.hud.close_all()
	Game.time_paused = true


# ============================================================
#  เวลา / ปฏิทิน / ฤดู
# ============================================================

func _test_time_calendar() -> void:
	_fresh()
	Game.time_min = 6 * 60
	Game.advance_minutes(90)
	_check(Game.time_min == 7 * 60 + 30, "เดินเวลา 90 นาทีถึง 07:30 (ได้ %s)" % Game.time_string())
	var h0 := Game.hunger
	Game.advance_minutes(120)
	_check(Game.time_min == 9 * 60 + 30, "เดินเวลาต่อถึง 09:30")
	_check(Game.hunger < h0, "ความอิ่มลดลงตามเวลา")

	var day0 := Game.day
	var weekday0 := Game.weekday
	var season0 := Game.season
	Game.time_min = 20 * 60
	var res := Game.sleep_now(6 * 60)
	_check(bool(res.get("ok", false)), "นอนหลับได้ตอน 20:00")
	_check(Game.day == day0 + 1, "ตื่นมาเป็นวันถัดไป")
	_check(Game.weekday == (weekday0 % 7) + 1, "วันในสัปดาห์เลื่อนไป 1")
	_check(Game.time_min == 6 * 60, "ตื่นตามนาฬิกาปลุก 06:00")
	_check(Game.season == season0 and Game.season_day == 2, "ฤดูกาลเดิม วันที่ 2")
	_check(Game.energy == 100, "พลังงานเต็มหลังนอน")

	# ครบ 7 วัน -> เปลี่ยนฤดู
	Game.season_day = 7
	Game.time_min = 20 * 60
	Game.sleep_now(6 * 60)
	_check(Game.season == 1, "ครบ 7 วันเปลี่ยนเป็นฤดูร้อน")
	_check(Game.season_day == 1, "เริ่มฤดูใหม่วันที่ 1")
	Game.weekday = 6
	_check(Game.is_school_day() == false, "วันเสาร์เป็นวันหยุด")
	Game.weekday = 1

	# ครบ 28 วัน -> อายุเพิ่ม
	var age0 := Game.age
	Game.season = 3
	Game.season_day = 7
	Game.time_min = 20 * 60
	Game.sleep_now(6 * 60)
	_check(Game.age == age0 + 1, "ครบ 28 วันอายุเพิ่ม 1 ปี (ได้ %d)" % Game.age)
	_check(Game.season == 0, "วนกลับฤดูใบไม้ผลิ")


# ============================================================
#  โรงเรียน
# ============================================================

func _test_school() -> void:
	_fresh(6)
	Game.weekday = 1
	Game.time_min = 9 * 60
	_check(Game.school_block_reason() == "", "เด็กประถมเข้าเรียนได้ตอน 09:00 วันจันทร์")
	var edu0 := Game.edu
	var grades0 := Game.grades
	var res := Game.attend_school(90)
	_check(bool(res.get("ok", false)), " attend_school สำเร็จ")
	_check(Game.edu > edu0, "ความรู้เพิ่มขึ้น")
	_check(Game.grades > grades0, "เกรดเพิ่มขึ้นเมื่อสอบได้คะแนนดี")
	_check(Game.school_attended_today, "บันทึกว่าเรียนวันนี้แล้ว")
	_check(Game.time_min == 15 * 60, "เรียนถึง 15:00")
	_check(not bool(Game.attend_school(80).get("ok", true)), "เรียนซ้ำวันเดิมไม่ได้")

	Game.time_min = 16 * 60
	Game.school_attended_today = false
	_check(Game.school_block_reason() != "", "หลัง 15:00 เข้าเรียนไม่ได้")

	Game.weekday = 6
	Game.time_min = 9 * 60
	_check(Game.school_block_reason().contains("หยุด"), "วันเสาร์ไม่มีเรียน")

	# ขาดเรียน -> เกรด/ความรักพ่อแม่ลด
	_fresh(6)
	Game.weekday = 1
	Game.time_min = 18 * 60
	var g0 := Game.grades
	var p0 := Game.parent_love
	Game.sleep_now(6 * 60)
	_check(Game.school_absences == 1, "ขาดเรียนถูกนับ 1 วัน")
	_check(Game.grades == g0 - 2, "ขาดเรียนเกรดลด 2")
	_check(Game.parent_love == p0 - 1, "ขาดเรียนพ่อแม่ไม่พอใจ")


# ============================================================
#  งาน
# ============================================================

func _test_work() -> void:
	_fresh(22)
	Game.job_id = "account"
	Game.weekday = 2
	Game.time_min = 9 * 60
	_check(Game.current_workplace() == "office", "พนักงานบัญชีทำงานที่ออฟฟิศ")
	_check(Game.work_block_reason() == "", "ทำงานได้ตอน 09:00 วันอังคาร")

	# ทุกที่ทำงานต้องมีจุดเริ่มกะจริงในโซน
	var workplaces := {}
	for job in Game.JOBS:
		workplaces[String(Game.JOB_WORKPLACES.get(String(job["id"]), "office"))] = true
	for zid in workplaces.keys():
		var has_station := false
		for p in TownData.zone(String(zid)).get("props", []):
			if String(p.get("action", "")) == "work":
				has_station = true
		_check(has_station, "ที่ทำงาน %s มีจุดเริ่มกะ" % zid)

	var money0 := Game.money
	var res := Game.work_shift(90)
	_check(bool(res.get("ok", false)), "work_shift สำเร็จ")
	_check(Game.money > money0, "ได้รับค่าจ้าง")
	_check(Game.job_shifts == 1, "นับกะทำงาน 1")
	_check(Game.worked_today, "บันทึกว่าทำงานวันนี้แล้ว")
	_check(Game.time_min == 17 * 60, "เลิกงาน 17:00")
	_check(not bool(Game.work_shift(90).get("ok", true)), "ทำงานซ้ำวันเดิมไม่ได้")

	Game.weekday = 6
	Game.worked_today = false
	_check(Game.work_block_reason() != "", "วันหยุดทำงานไม่ได้")

	_fresh(10)
	_check(Game.work_block_reason().contains("เรียน"), "เด็กทำงานประจำไม่ได้")

	# รับจ้างรายวันเมื่อไม่มีงานประจำ
	_fresh(22)
	Game.job_id = ""
	Game.weekday = 3
	Game.time_min = 10 * 60
	var m0 := Game.money
	var daily := Game.work_shift(70)
	_check(bool(daily.get("ok", false)) and Game.money > m0, "รับจ้างรายวันได้เงิน")


# ============================================================
#  การนอน
# ============================================================

func _test_sleep() -> void:
	_fresh()
	Game.time_min = 10 * 60
	_check(not bool(Game.sleep_now(6 * 60).get("ok", true)), "นอนกลางวันไม่ได้")
	Game.time_min = 18 * 60
	_check(bool(Game.sleep_now(6 * 60).get("ok", false)), "นอนได้หลัง 18:00")

	# สลบตอนเที่ยงคืน
	_fresh()
	var day0 := Game.day
	Game.time_min = 23 * 60 + 59
	Game.advance_minutes(3)
	_check(Game.day == day0 + 1, "เลยเที่ยงคืนแล้วสลบ ข้ามไปวันใหม่")
	_check(Game.time_min == 6 * 60, "สลบแล้วตื่น 06:00")
	_check(is_equal_approx(Game.last_sleep_hours, 5.0), "สลบได้นอนเพียง 5 ชั่วโมง")
	_check(Game.stress > 10, "สลบทำให้เครียดเพิ่ม")


# ============================================================
#  ฟิตเนส / สวนสาธารณะ
# ============================================================

func _test_gym_park() -> void:
	_fresh(20)
	Game.money = 1000
	Game.fitness = 30
	var res := Game.gym_session(90)
	_check(bool(res.get("ok", false)), "ออกกำลังกายโรงยิมสำเร็จ")
	_check(Game.money == 1000 - Game.COST_GYM, "จ่ายค่าเข้า gym ฿80")
	_check(Game.fitness > 30, "ฟิตเนสเพิ่มขึ้น")
	_check(Game.time_min == 6 * 60 + Game.GYM_MINUTES, "ใช้เวลา 90 นาที")

	_fresh(9)
	Game.money = 1000
	_check(not bool(Game.gym_session(80).get("ok", true)), "เด็กอายุ 9 เข้า gym ไม่ได้")

	_fresh(20)
	var fit0 := Game.fitness
	var park := Game.park_run(3)
	_check(bool(park.get("ok", false)), "วิ่งสวน 3 รอบสำเร็จ")
	_check(Game.fitness >= fit0 + 4, "ฟิตเนสเพิ่มจากการวิ่ง")
	_check(not bool(Game.park_run(2).get("ok", true)), "วิ่งไม่ครบ 3 รอบไม่ได้รางวัล")


# ============================================================
#  พ่อแม่ / ครอบครัว
# ============================================================

func _test_family() -> void:
	_fresh()
	Game.zone_id = "home"
	Game.time_min = 18 * 60 + 30
	Game.hunger = 50
	var love0 := Game.parent_love
	var dinner := Game.family_dinner()
	_check(bool(dinner.get("ok", false)), "กินข้าวเย็นกับครอบครัวได้")
	_check(Game.hunger >= 75, "อิ่มขึ้นราว 30 (ได้ %d)" % Game.hunger)
	_check(Game.parent_love == love0 + 3, "ความรักพ่อแม่ +3")
	_check(not bool(Game.family_dinner().get("ok", true)), "กินข้าวเย็นซ้ำวันเดิมไม่ได้")

	Game.zone_id = "park"
	Game.dinner_day = -1
	_check(not bool(Game.family_dinner().get("ok", true)), "ต้องอยู่บ้านจึงกินข้าวเย็นด้วยกันได้")

	Game.zone_id = "home"
	Game.time_min = 19 * 60
	Game.parent_talked.clear()
	var p0 := Game.parent_love
	var talk := Game.talk_parent("mom")
	_check(bool(talk.get("ok", false)), "คุยกับแม่ได้")
	_check(Game.parent_love == p0 + 2, "ความรักพ่อแม่ +2")
	_check(not bool(Game.talk_parent("mom").get("ok", true)), "คุยกับแม่ซ้ำวันเดิมไม่ได้")

	Game.allowance_week = -1
	Game.money = 0
	var allow := Game.ask_allowance()
	_check(bool(allow.get("ok", false)), "ขอเงินพ่อแม่ได้")
	_check(Game.money > 0, "ได้เงินใช้")
	_check(not bool(Game.ask_allowance().get("ok", true)), "ขอเงินซ้ำสัปดาห์เดิมไม่ได้")

	_fresh(20)
	_check(not bool(Game.ask_allowance().get("ok", true)), "โตแล้วขอเงินพ่อแม่ไม่ได้")


# ============================================================
#  NPC / ความสัมพันธ์
# ============================================================

func _test_npcs() -> void:
	_fresh(20)
	Game.money = 2000
	Game.zone_id = "park"
	var npc: Dictionary = TownData.NPCS["gun"].duplicate(true)
	npc["id"] = "gun"
	var f0 := Game.friendship_of("gun")
	var talk := Game.npc_talk(npc)
	_check(bool(talk.get("ok", false)), "คุยกับกันได้")
	_check(Game.friendship_of("gun") > f0, "ความสัมพันธ์เพิ่มขึ้น")
	_check(not bool(Game.npc_talk(npc).get("ok", true)), "คุยซ้ำวันเดิมไม่ได้")

	var m0 := Game.money
	var g0 := Game.friendship_of("gun")
	var gift := Game.npc_gift(npc)
	_check(bool(gift.get("ok", false)), "ให้ของขวัญกันได้")
	_check(Game.money == m0 - Game.COST_GIFT, "ของขวัญราคา ฿150")
	_check(Game.friendship_of("gun") == g0 + 12, "ของขวัญเพิ่มใจ +12")

	Game.npc_friendship["gun"] = 100
	Game.social = 100
	Game.partner_name = ""
	var m1 := Game.money
	var date := Game.npc_date(npc)
	_check(bool(date.get("ok", false)), "ชวนกันเดทได้เมื่อใจถึง 30")
	_check(Game.money == m1 - Game.COST_DATE_NPC, "เดทราคา ฿300")
	_check(Game.partner_name == "กัน" and Game.partner_look.get("hair_style", "") == "messy",
		"คนรัก NPC เก็บรูปลักษณ์ต้นฉบับไว้ใช้ถ่ายทอดยีน")

	_fresh(10)
	Game.zone_id = "park"
	Game.npc_friendship["gun"] = 60
	_check(not bool(Game.npc_date(npc).get("ok", true)), "เด็กยังเดทไม่ได้")

	# NPC ปรากฏตามตารางเวลา
	_check(TownData.npcs_for("classroom", 9 * 60, 1).size() >= 1, "กันอยู่ในห้องเรียนช่วงเช้า")
	var gun_park := TownData.npcs_for("park", 17 * 60, 1)
	var found := false
	for n in gun_park:
		if String(n.get("id", "")) == "gun":
			found = true
	_check(found, "กันไปสวนสาธารณะตอนเย็น")


# ============================================================
#  รถเมล์
# ============================================================

func _test_bus() -> void:
	_fresh(6)
	Game.money = 100
	Game.zone_id = "home_street"
	Game.time_min = 10 * 60
	_check(Game.travel_fare() == 8, "เด็กค่ารถเมล์ ฿8")
	var res := Game.travel_to("downtown", Vector2(60, 480))
	_check(bool(res.get("ok", false)), "นั่งรถเมล์ไปดาวน์ทาวน์ได้")
	_check(Game.zone_id == "downtown", "ถึงดาวน์ทาวน์แล้ว")
	_check(Game.money == 92, "หักค่าโดยสาร ฿8")
	_check(Game.time_min == 10 * 60 + 20, "รถเมล์ใช้เวลา 20 นาที")

	_fresh(20)
	Game.money = 0
	_check(not bool(Game.travel_to("park").get("ok", true)), "เงินไม่พอขึ้นรถเมล์ไม่ได้")


# ============================================================
#  เดินข้ามโซน
# ============================================================

func _test_zone_travel() -> void:
	_fresh()
	town.hud.close_all()
	for zid in TownData.ZONES.keys():
		town._load_zone(String(zid), TownData.spawn_of(String(zid)))
		_check(Game.zone_id == String(zid), "โหลดโซน %s ได้" % zid)
		_check(town.player.visible, "ผู้เล่นมองเห็นได้ในโซน %s" % zid)
	town._load_zone("home", TownData.spawn_of("home"))
	_check(Game.zone_id == "home", "กลับบ้านได้")

	# ประตูภายในต้องพาออกไปข้างนอกได้
	for zid in ["office", "store", "cafe", "hospital", "bank", "mall", "bar", "gym",
			"classroom", "university", "neighbor_home"]:
		var door := TownData.interior_door(zid)
		_check(not door.is_empty(), "%s มีประตูออก" % zid)
		_check(TownData.ZONES.has(String(door.get("zone", ""))), "%s ประตูไปโซนจริง" % zid)

	# ทางออกขอบแผนที่
	var home_street: Dictionary = TownData.zone("home_street")
	_check(home_street.get("exits", []).size() == 2, "ถนนบ้านมีทางออก 2 ทาง")
	var downtown: Dictionary = TownData.zone("downtown")
	_check(downtown.get("doors", []).size() == 8, "ดาวน์ทาวน์มีประตู 8 บาน")


# ============================================================
#  กด E ใช้งานของในโลก
# ============================================================

func _test_interactions() -> void:
	_fresh(12)
	town.hud.close_all()

	# ประตูบ้าน
	town._load_zone("home_street", Vector2(200, 360))
	town._update_nearest()
	_check(String(town.nearest.get("kind", "")) == "door", "ใกล้ประตูบ้านมี prompt interact")
	town._interact()
	_check(Game.zone_id == "home", "กด E ที่ประตูเข้าบ้านได้")

	# เตียง -> เปิดนาฬิกาปลุก
	town._load_zone("home", Vector2(130, 265))
	town._update_nearest()
	_check(String(town.nearest.get("action", "")) == "sleep", "ใกล้เตียงมี action นอน")
	town._interact()
	_check(town.hud.get_busy(), "กด E ที่เตียงเปิดแผงนาฬิกาปลุก")
	town.hud.close_modal()

	# ป้ายรถเมล์
	town._load_zone("home_street", Vector2(820, 360))
	town._update_nearest()
	town._interact()
	_check(town.hud.get_busy(), "กด E ที่ป้ายรถเมล์เปิดแผงรถเมล์")
	town.hud.close_modal()

	# ประตูร้าน
	town._load_zone("downtown", Vector2(565, 265))
	town._update_nearest()
	town._interact()
	_check(Game.zone_id == "cafe", "กด E เข้าคาเฟ่ได้")

	# จุดตรวจสวนสาธารณะ 3 รอบ
	_fresh(20)
	Game.fitness = 30
	town._load_zone("park", TownData.spawn_of("park"))
	var fit0 := Game.fitness
	for lap in 3:
		for cp in 4:
			town.player.position = town.checkpoints[cp]
			town._check_park()
	_check(Game.fitness > fit0, "วิ่งผ่านจุดครบ 3 รอบได้ฟิตเนส")
	_check(Game.zone_id == "park", "วิ่งเสร็จยังอยู่สวนสาธารณะ")


# ============================================================
#  กิจกรรมที่บ้าน
# ============================================================

func _test_home_actions() -> void:
	_fresh(10)
	Game.time_min = 16 * 60
	Game.money = 500
	Game.hunger = 40
	var edu0 := Game.edu
	var hw := Game.do_homework()
	_check(bool(hw.get("ok", false)), "ทำการบ้านได้")
	_check(Game.edu == edu0 + 1, "ทำการบ้านความรู้ +1")

	var eat := Game.eat_food(Game.COST_HOME_MEAL, 32, 5, 30, "ข้าวที่บ้าน")
	_check(bool(eat.get("ok", false)), "กินข้าวที่บ้านได้")
	_check(Game.money == 380, "ค่าข้าวที่บ้าน ฿120")
	_check(Game.hunger >= 70, "อิ่มขึ้นจากการกิน")

	var tv := Game.watch_tv()
	_check(bool(tv.get("ok", false)), "ดูทีวีได้")
	_check(Game.time_min > 16 * 60, "กิจกรรมที่บ้านกินเวลา")


# ============================================================
#  ทักษะชีวิต v5
# ============================================================

func _test_skills() -> void:
	_fresh(16)
	Game.money = Game.TRAIN_COST * 2
	var art0 := Game.skill_of("art")
	var res := Game.train_skill("art")
	_check(bool(res.get("ok", false)), "ฝึกทักษะศิลปะได้")
	_check(Game.skill_of("art") > art0, "ทักษะศิลปะเพิ่มขึ้น")
	_check(Game.money == Game.TRAIN_COST, "ฝึกทักษะจ่าย ฿300")
	_check(not bool(Game.train_skill("art").get("ok", true)), "ฝึกซ้ำวันเดิมไม่ได้")
	Game.day += 1
	Game.money = 0
	_check(not bool(Game.train_skill("cooking").get("ok", true)), "เงินไม่พอฝึกทักษะไม่ได้")
	_check(not bool(Game.train_skill("unknown").get("ok", true)), "ฝึกทักษะที่ไม่รู้จักไม่ได้")
	_check(Game.SKILL_KEYS.size() == 7, "มีทักษะ 7 ด้าน")
	for sk in Game.SKILL_KEYS:
		_check(Game.skill_name(String(sk)) != String(sk), "ทักษะ %s มีชื่อไทย" % sk)
	var avg := Game.skill_average()
	_check(avg > 0 and avg <= 100, "ทักษะเฉลี่ยอยู่ในช่วง 0-100 (%d)" % avg)
	Game.skills["art"] = 90
	_check(Game.skill_tier("art") == "ระดับอาจารย์", "ทักษะ 90 ขึ้นระดับอาจารย์")
	Game.skills["art"] = 30
	_check(Game.skill_tier("art") == "ฝึกฝน", "ทักษะ 30 อยู่ระดับฝึกฝน")

	# ฝึกทักษะจากกิจกรรมในโลก
	_fresh(18)
	Game.zone_id = "home"
	Game.time_min = 10 * 60
	Game.hunger = 40
	Game.money = 500
	var cook0 := Game.skill_of("cooking")
	_check(bool(Game.cook_meal().get("ok", false)), "ทำอาหารที่บ้านได้")
	_check(Game.skill_of("cooking") > cook0, "ทำอาหารเพิ่มทักษะทำอาหาร")
	_check(Game.money == 440, "ทำอาหารค่าวัตถุดิบ ฿60")
	var craft0 := Game.skill_of("craft")
	Game.energy = 80
	_check(bool(Game.craft_item().get("ok", false)), "ประดิษฐ์ของที่บ้านได้")
	_check(Game.skill_of("craft") > craft0, "ประดิษฐ์เพิ่มทักษะงานฝีมือ")
	var art1 := Game.skill_of("art")
	Game.stress = 50
	_check(bool(Game.practice_art().get("ok", false)), "วาดรูปที่บ้านได้")
	_check(Game.skill_of("art") > art1, "วาดรูปเพิ่มทักษะศิลปะ")
	Game.zone_id = "park"
	_check(bool(Game.practice_art().get("ok", false)), "วาดรูปที่สวนสาธารณะได้")
	Game.zone_id = "downtown"
	_check(not bool(Game.practice_art().get("ok", true)), "วาดรูปกลางดาวน์ทาวน์ไม่ได้")


# ============================================================
#  บ้าน / เฟอร์นิเจอร์ / แมว v5
# ============================================================

func _test_home_decor() -> void:
	_fresh(22)
	Game.money = 10000
	var cozy0 := Game.home_cozy()
	var res := Game.buy_furniture("cozy_lamp")
	_check(bool(res.get("ok", false)), "ซื้อโคมไฟแต่งบ้านได้")
	_check(Game.home_cozy() == cozy0 + 6, "โคมไฟเพิ่มความอบอุ่น +6")
	_check(Game.money == 9100, "โคมไฟราคา ฿900")
	_check(Game.owns_furniture("cozy_lamp"), "บันทึกว่าเป็นเจ้าของโคมไฟ")
	_check(not bool(Game.buy_furniture("cozy_lamp").get("ok", true)), "ซื้อเฟอร์นิเจอร์ซ้ำไม่ได้")
	_check(not bool(Game.buy_furniture("unknown").get("ok", true)), "ซื้อเฟอร์นิเจอร์ที่ไม่มีจริงไม่ได้")
	Game.money = 500
	_check(not bool(Game.buy_furniture("bookshelf").get("ok", true)), "เงินไม่พอซื้อเฟอร์นิเจอร์ไม่ได้")

	Game.money = 2000
	var pet := Game.buy_furniture("cat_bed")
	_check(bool(pet.get("ok", false)), "ซื้อที่นอนแมวได้")
	_check(Game.pet_name != "", "ได้แมวมาอยู่ด้วย (%s)" % Game.pet_name)
	var ph := Game.pet_happy
	var play := Game.pet_cat()
	_check(bool(play.get("ok", false)), "เล่นกับแมวได้")
	_check(Game.pet_happy == ph + 12, "แมวมีความสุขเพิ่มขึ้น +12")
	_check(not bool(Game.pet_cat().get("ok", true)), "เล่นกับแมวซ้ำวันเดิมไม่ได้")
	_check(Game.home_cozy() > 8, "บ้านมีความอบอุ่นมากกว่าเริ่มต้น")


# ============================================================
#  ของสะสมตามฤดู v5
# ============================================================

func _test_collectibles() -> void:
	_fresh(14)
	Game.season = 0
	Game.season_day = 2
	Game.zone_id = "park"
	Game.collect_day = -1
	Game.money = 0
	var res := Game.collect_find("park")
	_check(bool(res.get("ok", false)), "เก็บของสะสมที่สวนสาธารณะได้")
	_check(Game.collection_count() == 1, "สะสมได้ 1 ชนิด")
	_check(Game.money >= 120, "เก็บของสะสมได้เงิน")
	_check(not bool(Game.collect_find("park").get("ok", true)), "เก็บของสะสมซ้ำวันเดิมไม่ได้")
	_check(Game.collection_total() == 12, "ของสะสมทั้งหมด 12 ชนิด")

	# ครบ 4 ชนิด -> โบนัส
	Game.season = 1
	Game.season_day = 3
	Game.zone_id = "park"
	Game.collect_day = -1
	Game.collections = {"dragonfly": 1, "sunstone": 1, "sakura": 1}
	Game.collection_milestone = 0
	Game.money = 0
	var r2 := Game.collect_find("park")
	_check(bool(r2.get("ok", false)), "เก็บของสะสมฤดูร้อนได้")
	_check(Game.collection_count() == 4, "สะสมครบ 4 ชนิด")
	_check(Game.money >= 120 + 2000, "สะสมครบ 4 ชนิดได้โบนัส ฿2,000")
	_check(Game.collection_milestone == 4, "บันทึกไมล์สโตน 4 ชนิด")


# ============================================================
#  เทศกาลประจำฤดู v5
# ============================================================

func _test_festivals() -> void:
	_fresh(22)
	Game.season = 0
	Game.season_day = 5
	var fest := Game.festival_today()
	_check(String(fest.get("id", "")) == "blossom", "วันที่ 5 ใบไม้ผลิเป็นเทศกาลดอกไม้บาน")
	Game.zone_id = "park"
	Game.festival_attended = {}
	Game.money = 0
	var res := Game.join_festival(80)
	_check(bool(res.get("ok", false)), "ร่วมเทศกาลที่สวนสาธารณะได้")
	_check(Game.festival_wins == 1, "นับจำนวนเทศกาลที่ร่วม 1")
	_check(Game.money >= 1800 + 80 * 8, "เทศกาลให้รางวัลตามคะแนน")
	_check(Game.festival_attended_today(), "บันทึกว่าร่วมเทศกาลวันนี้แล้ว")
	_check(not bool(Game.join_festival(50).get("ok", true)), "ร่วมเทศกาลซ้ำวันเดิมไม่ได้")
	Game.season_day = 6
	_check(Game.festival_today().is_empty(), "วันที่ 6 ไม่มีเทศกาล")
	Game.season = 1
	Game.season_day = 6
	Game.zone_id = "park"
	Game.festival_attended = {}
	_check(not bool(Game.join_festival(50).get("ok", true)), "อยู่นอกสถานที่ร่วมเทศกาลไม่ได้")
	for f in Game.FESTIVALS:
		_check(["timing", "math", "sequence", "catch"].has(String(f["kind"])),
			"เทศกาล %s มีมินิเกมที่รองรับ" % String(f.get("id", "")))
	_check(Game.festival_name("harvest") == "เทศกาลเก็บเกี่ยว", "เรียกชื่อเทศกาลได้")


func _test_festival_scene() -> void:
	_fresh(22)
	Game.season = 0
	Game.season_day = 5
	town._load_zone("park", TownData.spawn_of("park"))
	Game.time_paused = true
	_check(town._festival_spot() != Vector2.ZERO, "บูธเทศกาลปรากฏในสวนสาธารณะ")
	for i in 4:
		await get_tree().process_frame
	_check(Game.zone_id == "park", "วาดฉากเทศกาลได้โดยไม่ค้าง")
	Game.season_day = 3


# ============================================================
#  เซฟ / โหลด v4
# ============================================================

func _test_save_load() -> void:
	_fresh(14)
	Game.time_min = 13 * 60 + 25
	Game.day = 12
	Game.weekday = 4
	Game.season = 2
	Game.season_day = 5
	Game.weather = "rain"
	Game.zone_id = "park"
	Game.player_pos = Vector2(321, 277)
	Game.grades = 77
	Game.fitness = 66
	Game.school_days = 9
	Game.school_absences = 2
	Game.parent_love = 88
	Game.npc_friendship["gun"] = 44
	Game.npc_gifted["gun-12"] = true
	Game.skills["art"] = 61
	Game.skills["cooking"] = 42
	Game.home_items = ["cozy_lamp", "cat_bed"]
	Game.pet_name = "ส้ม"
	Game.pet_happy = 74
	Game.collections["sakura"] = 2
	Game.collection_milestone = 4
	Game.festival_wins = 3
	Game.festival_attended["1-0-blossom"] = true
	Game.birth_outfit = "heirloom_green"
	Game.parent_trait = "artist"
	Game.karma_id = "dreamer"
	Game.skin_tone = "tan"
	Game.hair_color = "auburn"
	Game.hair_style = "ponytail"
	Game.farm_plots[0] = {"crop": "tomato", "growth": 2, "watered": true}
	Game.harvest_total = 3
	Game.fish_total = 4
	Game.bug_total = 2
	Game.fame = 26
	Game.club_id = "art"
	Game.club_level = 2
	Game.club_points = 11
	Game.business_level = 2
	Game.business_stock = 22
	Game.business_sales_total = 1234
	Game.achievements["first_fish"] = true
	Game.achievement_claimed["first_fish"] = true
	Game.home_level = 2
	Game.party_count = 1
	Game.cat_toy_owned = true
	Game.honeymoon_done = true
	Game.booth_plays = 2
	Game.life_goal = "legend"
	Game.quest_week = Game.quest_week_index()
	Game.quests = [{"id": "fish4", "claimed": true}]
	Game.quest_counts = {"fish": 2}
	Game.quest_total_done = 6
	Game.quest_certificates = ["bronze"]
	Game.save_game()

	Game.grades = 1
	Game.fitness = 1
	Game.zone_id = "home"
	Game.time_min = 0
	Game.season = 0
	Game.pet_name = ""
	Game.home_items = []
	Game.festival_wins = 0
	Game.skin_tone = ""
	Game.hair_color = ""
	Game.hair_style = ""
	Game.farm_plots[0] = {"crop": "", "growth": 0, "watered": false}
	Game.harvest_total = 0
	Game.fish_total = 0
	Game.bug_total = 0
	Game.fame = 0
	Game.club_id = ""
	Game.club_level = 1
	Game.club_points = 0
	Game.business_level = 0
	Game.business_stock = 0
	Game.business_sales_total = 0
	Game.achievements = {}
	Game.achievement_claimed = {}
	Game.home_level = 1
	Game.party_count = 0
	Game.cat_toy_owned = false
	Game.honeymoon_done = false
	Game.booth_plays = 0
	Game.load_game()
	_check(Game.grades == 77, "เซฟ/โหลดเกรดได้")
	_check(Game.fitness == 66, "เซฟ/โหลดฟิตเนสได้")
	_check(Game.zone_id == "park", "เซฟ/โหลดโซนได้")
	_check(Game.time_min == 13 * 60 + 25, "เซฟ/โหลดเวลาได้")
	_check(Game.day == 12 and Game.weekday == 4, "เซฟ/โหลดวัน/สัปดาห์ได้")
	_check(Game.season == 2 and Game.season_day == 5, "เซฟ/โหลดฤดูได้")
	_check(Game.weather == "rain", "เซฟ/โหลดอากาศได้")
	_check(Game.friendship_of("gun") == 44, "เซฟ/โหลดความสัมพันธ์ NPC ได้")
	_check(Game.player_pos.distance_to(Vector2(321, 277)) < 0.5, "เซฟ/โหลดตำแหน่งผู้เล่นได้")
	_check(Game.skill_of("art") == 61 and Game.skill_of("cooking") == 42, "เซฟ/โหลดทักษะได้")
	_check(Game.home_items.size() == 2 and Game.owns_furniture("cat_bed"), "เซฟ/โหลดเฟอร์นิเจอร์ได้")
	_check(Game.pet_name == "ส้ม" and Game.pet_happy == 74, "เซฟ/โหลดแมวได้")
	_check(int(Game.collections.get("sakura", 0)) == 2, "เซฟ/โหลดของสะสมได้")
	_check(Game.collection_milestone == 4, "เซฟ/โหลดไมล์สโตนของสะสมได้")
	_check(Game.festival_wins == 3, "เซฟ/โหลดจำนวนเทศกาลได้")
	_check(bool(Game.festival_attended.get("1-0-blossom", false)), "เซฟ/โหลดประวัติเทศกาลได้")
	_check(Game.birth_outfit == "heirloom_green" and Game.parent_trait == "artist"
		and Game.karma_id == "dreamer", "เซฟ/โหลดกำเนิด/กรรมพันได้")
	_check(Game.skin_tone == "tan" and Game.hair_color == "auburn"
		and Game.hair_style == "ponytail", "เซฟ/โหลดสีผิว/สีผม/ทรงผมได้")
	_check(Game.farm_crop(0) == "tomato" and int(Game.farm_plot_data(0).get("growth", 0)) == 2,
		"เซฟ/โหลดแปลงผักได้")
	_check(Game.harvest_total == 3 and Game.fish_total == 4 and Game.bug_total == 2,
		"เซฟ/โหลดสถิติฟาร์ม/ตกปลา/แมลงได้")
	_check(Game.fame == 26, "เซฟ/โหลดชื่อเสียงได้")
	_check(Game.club_id == "art" and Game.club_level == 2 and Game.club_points == 11,
		"เซฟ/โหลดชมรมได้")
	_check(Game.business_level == 2 and Game.business_stock == 22
		and Game.business_sales_total == 1234, "เซฟ/โหลดธุรกิจได้")
	_check(Game.achievement_unlocked("first_fish") and Game.achievement_is_claimed("first_fish"),
		"เซฟ/โหลดความสำเร็จได้")
	_check(Game.home_level == 2 and Game.party_count == 1 and Game.cat_toy_owned,
		"เซฟ/โหลดบ้าน/ปาร์ตี้/ของเล่นแมวได้")
	_check(Game.honeymoon_done and Game.booth_plays == 2, "เซฟ/โหลดฮันนีมูน/บูธได้")
	_check(Game.life_goal == "legend" and Game.quest_total_done == 6,
		"เซฟ/โหลดเป้าหมายชีวิตและภารกิจสะสมได้")
	_check(Game.quests.size() == 1 and String(Game.quests[0].get("id", "")) == "fish4"
		and bool(Game.quests[0].get("claimed", false)), "เซฟ/โหลดสถานะภารกิจได้")
	_check(int(Game.quest_counts.get("fish", 0)) == 2
		and Game.has_quest_certificate("bronze"), "เซฟ/โหลดตัวนับและใบประกาศได้")
	Game.time_paused = true

	# ไฟล์เซฟต้องเป็นเวอร์ชัน 9
	if FileAccess.file_exists("user://pixel_life.save"):
		var f := FileAccess.open("user://pixel_life.save", FileAccess.READ)
		var raw := f.get_as_text()
		var parsed = JSON.parse_string(raw)
		_check(typeof(parsed) == TYPE_DICTIONARY and int(parsed.get("version", 0)) == 9,
			"ไฟล์เซฟเป็นเวอร์ชัน 9")


# ============================================================
#  HUD / แผงสรุป
# ============================================================

func _test_hud_panels() -> void:
	_fresh(16)
	Game.money = 5000
	Game.zone_id = "home"
	town.hud.close_all()

	for tab in ["overview", "career", "money", "skills", "home", "farm", "hobby",
			"awards", "quests", "business", "social", "festival", "health", "love", "life", "outfits"]:
		town.hud.open_summary(String(tab))
		_check(town.hud.get_busy(), "เปิดแผง %s ได้" % tab)
		town.hud.close_modal()
	_check(not town.hud.get_busy(), "ปิดแผงสรุปได้")
	_check(town.hud.TAB_DEFS.size() == 16, "แผงสรุปมี 16 แท็บ")

	town.hud.open_bus()
	_check(town.hud.get_busy(), "เปิดแผงรถเมล์ได้")
	town.hud.close_modal()

	town.hud.open_alarm()
	_check(town.hud.get_busy(), "เปิดแผงนาฬิกาปลุกได้")
	town.hud.close_modal()

	for kind in ["store", "cafe", "mall", "bank", "hospital", "gym", "bar"]:
		town.hud.open_shop(String(kind))
		_check(town.hud.get_busy(), "เปิดร้าน %s ได้" % kind)
		town.hud.close_modal()

	var npc: Dictionary = TownData.NPCS["nan"].duplicate(true)
	npc["id"] = "nan"
	town.hud.open_npc_dialog(npc)
	_check(town.hud.get_busy(), "เปิดบทสนทนา NPC ได้")
	town.hud.close_dialog()

	town.hud.open_parent_dialog("dad")
	_check(town.hud.get_busy(), "เปิดบทสนทนาพ่อได้")
	town.hud.close_dialog()
	_check(not town.hud.get_busy(), "ปิดบทสนทนาได้")


# ============================================================
#  มินิเกม
# ============================================================

func _test_minigame() -> void:
	_fresh(12)
	town.hud.close_all()
	var got: Array[int] = []
	town.hud.start_minigame("math", "ทดสอบ", 2, func(score: int) -> void:
		got.append(score)
	)
	_check(town.hud.get_busy(), "เปิดมินิเกมได้")
	# ตอบคำถามถูกทั้งสองรอบ แล้วรอจนมินิเกมส่งคะแนน
	for i in 2:
		var mg = town.hud._minigame
		if mg == null:
			break
		mg._on_math_answer(mg._math_answer)
		await get_tree().create_timer(0.5).timeout
	var waited := 0.0
	while town.hud.get_busy() and waited < 3.0:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	_check(not town.hud.get_busy(), "มินิเกมปิดตัวเองเมื่อจบ")
	_check(got.size() == 1, "มินิเกมส่งคะแนนกลับ 1 ครั้ง")
	if got.size() == 1:
		_check(got[0] >= 50, "ตอบถูกได้คะแนนดี (%d)" % got[0])

	# ยกเลิก
	town.hud.start_minigame("timing", "ทดสอบยกเลิก", 4, func(_s: int) -> void: pass)
	_check(town.hud.get_busy(), "เปิดมินิเกม timing ได้")
	town.hud._minigame._cancel()
	await get_tree().process_frame
	_check(not town.hud.get_busy(), "ยกเลิกมินิเกมได้")


# ============================================================
#  หน้าสร้างตัวละครใหม่
# ============================================================

func _test_creation_flow() -> void:
	Game.new_game()
	Game.time_paused = true
	town.hud.close_all()
	town.hud.show_creation()
	_check(town.hud.get_busy(), "เปิดหน้าสร้างตัวละครใหม่ได้")
	var started := [false]
	town.hud.life_started.connect(func() -> void: started[0] = true)
	Game.start_life("ทดสอบ", "ชาย", 1, "heirloom_rose", "farmer")
	Game.time_paused = true
	town.hud.close_modal()
	_check(Game.created and Game.player_name == "ทดสอบ", "สร้างชีวิตใหม่สำเร็จ")
	_check(Game.age == 6 and Game.zone_id == "home", "ชีวิตใหม่เริ่มอายุ 6 ที่บ้าน")
	_check(Game.parent_trait == "farmer" and Game.karma_id == "grounded",
		"สร้างชีวิตใหม่พร้อมกรรมพันที่เลือก")
	_check(Game.outfit == "heirloom_rose", "สร้างชีวิตใหม่สวมผ้าห่อตัวที่เลือก")
	_check(not town.hud.get_busy(), "ปิดหน้าสร้างตัวละครได้")


# ============================================================
#  ตัวละคร v6 — ปรับแต่งหน้าตา / สีหน้า / ท่านั่ง / NPC เดิน
# ============================================================

func _test_character_v6() -> void:
	_check(Game.SKIN_TONES.size() == 5, "มีสีผิว 5 แบบ")
	_check(Game.HAIR_COLORS.size() == 8, "มีสีผม 8 แบบ")
	_check(Game.HAIR_STYLES.size() == 8, "มีทรงผม 8 แบบ")

	Game.start_life("มีนา", "หญิง", 2, "heirloom_rose", "artist", "dark", "rose", "curly")
	_check(Game.created, "สร้างชีวิตพร้อมปรับหน้าตาได้")
	_check(Game.skin_tone == "dark" and Game.hair_color == "rose"
		and Game.hair_style == "curly", "บันทึกสีผิว/สีผม/ทรงผมตอนสร้าง")
	_check(Game.skin_tone_hex() == "#8a5a3a", "สีผิวเข้มได้รหัสถูก")
	_check(Game.hair_color_hex() == "#d88a9a", "สีผมชมพูอ่อนได้รหัสถูก")
	_check(Game.skin_tone_name() != "" and Game.hair_style_name() != "", "มีชื่อสีผิว/ทรงผมอ่านได้")

	var look := Game.character_look()
	_check(String(look.get("skin", "")) == "#8a5a3a", "character_look ส่งสีผิว")
	_check(String(look.get("hair", "")) == "#d88a9a", "character_look ส่งสีผม")
	_check(String(look.get("hair_style", "")) == "curly", "character_look ส่งทรงผม")
	_check(look.has("expression"), "character_look มีสีหน้า")

	# พาเลตต์ชุดยังใช้สีหน้าตาที่เลือก
	var pal := TownArt.player_palette("casual", look)
	_check(String(pal.get("skin", "")) == "#8a5a3a", "พาเลตต์รับสีผิวที่เลือก")
	_check(String(pal.get("hair", "")) == "#d88a9a", "พาเลตต์รับสีผมที่เลือก")
	_check(String(pal.get("hair_style", "")) == "curly", "พาเลตต์รับทรงผมที่เลือก")
	var sit_pal := TownArt.player_palette("casual", {"pose": "sit"})
	_check(String(sit_pal.get("pose", "")) == "sit", "พาเลตต์ส่งท่านั่งได้")

	# สีหน้าตามสถานะ
	_fresh(20)
	Game.sick = false
	Game.stress = 10
	Game.energy = 80
	Game.happy = 55
	_check(Game.mood_expression() == "neutral", "สุขภาพดีได้สีหน้าปกติ")
	Game.happy = 85
	_check(Game.mood_expression() == "happy", "ความสุขสูงได้สีหน้ายิ้ม")
	Game.happy = 55
	Game.sick = true
	_check(Game.mood_expression() == "sick", "ป่วยได้สีหน้าป่วย")
	Game.sick = false
	Game.stress = 90
	_check(Game.mood_expression() == "stressed", "เครียดสูงได้สีหน้าเครียด")
	Game.stress = 10
	Game.energy = 10
	_check(Game.mood_expression() == "tired", "พลังงานต่ำได้สีหน้าเหนื่อย")
	Game.energy = 80
	Game.happy = 10
	_check(Game.mood_expression() == "sad", "ความสุขต่ำได้สีหน้าเศร้า")

	# ค่าเริ่มต้นเมื่อไม่ระบุหน้าตา
	Game.start_life("ต้น", "ชาย", 1)
	_check(Game.skin_tone == "warm" and Game.hair_color == "black"
		and Game.hair_style == "short", "ค่าเริ่มต้นผิวอุ่น/ผมดำ/ผมสั้น")
	Game.time_paused = true


func _test_npc_walking() -> void:
	_fresh(20)
	Game.zone_id = "park"
	Game.time_min = 17 * 60
	Game.weekday = 1
	town.hud.close_all()
	town._load_zone("park", TownData.spawn_of("park"))
	await get_tree().process_frame
	_check(town.npcs.size() >= 2, "สวนสาธารณะตอนเย็นมี NPC ให้เดิน")
	var before := {}
	for n in town.npcs:
		var nid := String(n.get("id", ""))
		before[nid] = n.get("pos", Vector2.ZERO)
		_check(n.has("home") and n.has("target") and n.has("face"),
			"NPC %s มีสถานะเดิน" % nid)
	for i in 80:
		town._update_npcs(0.1)
	var moved := 0
	for n in town.npcs:
		var nid2 := String(n.get("id", ""))
		var p0: Vector2 = before.get(nid2, Vector2.ZERO)
		var p1: Vector2 = n.get("pos", Vector2.ZERO)
		if p0.distance_to(p1) > 2.0:
			moved += 1
	_check(moved >= 1, "NPC เดินไปมาได้จริง (%d คน)" % moved)
	Game.time_paused = true


# ============================================================
#  v7 — ฟาร์ม / งานอดิเรก / ธุรกิจ / บ้าน / รางวัล / ครอบครัว
# ============================================================

func _test_v7_farm() -> void:
	_fresh(18)
	Game.money = 5000
	Game.karma_id = "warm"
	Game.harvest_total = 0
	_check(Game.farm_plots.size() == Game.FARM_PLOT_COUNT, "มีแปลงผัก 6 แปลง")
	_check(Game.farm_stage(0) == "empty", "แปลงเริ่มต้นว่าง")

	var plant := Game.farm_plant(0, "lettuce")
	_check(bool(plant.get("ok", false)), "ปลูกผักกาดหอมได้")
	_check(Game.farm_crop(0) == "lettuce", "แปลง 1 มีผักกาดหอม")
	_check(Game.money == 5000 - 50, "ค่าเมล็ดผักกาดหอม ฿50")
	_check(not bool(Game.farm_plant(0, "tomato").get("ok", true)), "ปลูกทับแปลงเดิมไม่ได้")
	_check(not bool(Game.farm_harvest(0).get("ok", true)), "เก็บเกี่ยวก่อนสุกไม่ได้")

	var water := Game.farm_water(0)
	_check(bool(water.get("ok", false)), "รดน้ำแปลงได้")
	_check(not bool(Game.farm_water(0).get("ok", true)), "รดน้ำซ้ำวันเดิมไม่ได้")
	_check(bool(Game.farm_plot_data(0).get("watered", false)), "แปลงถูกมาร์คว่ารดน้ำแล้ว")

	# 4 วัน: รดน้ำวันแรก 3 วัน แล้วโตครบ 3 วัน
	for i in 4:
		Game._farm_new_day()
		if i < 3:
			Game.farm_water(0)
	_check(Game.farm_stage(0) == "ready", "ผักโตครบ 3 วันพร้อมเก็บ")
	_check(Game.farm_ready_count() == 1, "นับจำนวนแปลงพร้อมเก็บได้")

	var before := Game.money
	var harvest := Game.farm_harvest(0)
	_check(bool(harvest.get("ok", false)), "เก็บเกี่ยวผักได้")
	_check(Game.money == before + 150, "ขายผักกาดหอมได้ ฿150")
	_check(Game.harvest_total == 1, "นับจำนวนเก็บเกี่ยวได้")
	_check(Game.farm_stage(0) == "empty", "เก็บเกี่ยวแล้วแปลงว่าง")
	_check(Game.achievement_unlocked("first_harvest"), "ปลดล็อกความสำเร็จเก็บเกี่ยวครั้งแรก")

	var money0 := Game.money
	var claim := Game.claim_achievement("first_harvest")
	_check(bool(claim.get("ok", false)), "รับรางวัลความสำเร็จได้")
	_check(Game.money == money0 + 500, "รางวัลเก็บเกี่ยวครั้งแรก ฿500")
	_check(not bool(Game.claim_achievement("first_harvest").get("ok", true)), "รับรางวัลซ้ำไม่ได้")

	Game.money = 5000
	Game.farm_plant(1, "corn")
	Game.farm_water(1)
	Game.farm_water(3)
	var all := Game.farm_water_all()
	_check(not bool(all.get("ok", true)), "รดน้ำทั้งหมดเมื่อไม่มีแปลงค้างไม่ได้")


func _test_v7_hobby() -> void:
	_fresh(18)
	Game.money = 5000
	Game.energy = 100
	Game.fish_actions = 0
	Game.fish_total = 0
	Game.fish_catches = {}
	Game.bug_actions = 0
	Game.bug_total = 0
	Game.bug_catches = {}
	Game.achievements = {}
	Game.achievement_claimed = {}

	var fish := Game.fish_result(true, 2)
	_check(bool(fish.get("ok", false)) and String(fish.get("caught", "")) != "", "ตกปลาสำเร็จได้ปลา 1 ตัว")
	_check(Game.fish_total == 1, "นับจำนวนปลาที่ตกได้")
	_check(Game.fish_caught_kinds() >= 1, "นับชนิดปลาที่สะสมได้")
	_check(Game.fish_actions == 1, "นับครั้งตกปลา")
	_check(Game.fish_result(false).get("caught", "x") == "", "ตกปลาพลาดได้")
	_check(Game.fish_total == 1, "ตกปลาพลาดไม่เพิ่มสถิติ")
	_check(Game.achievement_unlocked("first_fish"), "ปลดล็อกความสำเร็จตกปลาตัวแรก")

	Game.fish_actions = 5
	_check(not bool(Game.fish_result(true).get("ok", true)), "ตกปลาครบ 5 ครั้งต่อวันไม่ได้")

	var bug := Game.bug_result(true, 1)
	_check(bool(bug.get("ok", false)) and String(bug.get("caught", "")) != "", "จับแมลงสำเร็จได้ 1 ตัว")
	_check(Game.bug_total == 1, "นับจำนวนแมลงที่จับได้")
	Game.bug_actions = 5
	_check(not bool(Game.bug_result(true).get("ok", true)), "จับแมลงครบ 5 ครั้งต่อวันไม่ได้")

	# ชมรม
	Game.money = 5000
	Game.club_id = ""
	Game.club_level = 1
	Game.club_points = 0
	Game.club_day = -1
	var join := Game.join_club("art")
	_check(bool(join.get("ok", false)), "สมัครชมรมศิลปะได้")
	_check(Game.club_id == "art" and Game.club_name() == "ชมรมศิลปะ", "ชมรมปัจจุบันคือศิลปะ")
	_check(Game.money == 5000 - 300, "ค่าสมาชิกชมรมศิลปะ ฿300")
	var act := Game.club_activity()
	_check(bool(act.get("ok", false)), "ทำกิจกรรมชมรมได้")
	_check(Game.club_points >= 2, "กิจกรรมชมรมได้คะแนน")
	_check(not bool(Game.club_activity().get("ok", true)), "ทำกิจกรรมชมรมซ้ำวันเดิมไม่ได้")
	Game.club_points = 100
	Game.club_day = -1
	Game.club_activity()
	_check(Game.club_level >= 3, "คะแนนครบชมรมเลเวลอัปได้")

	# เรียนพิเศษ
	Game.course_day = -1
	Game.money = 5000
	var acad0 := Game.skill_of("academics")
	var course := Game.take_course("academics")
	_check(bool(course.get("ok", false)), "เรียนพิเศษวิชาการได้")
	_check(Game.money == 5000 - 600, "ค่าเรียนพิเศษ ฿600")
	_check(Game.skill_of("academics") > acad0, "เรียนพิเศษเพิ่มทักษะ")
	_check(not bool(Game.take_course("academics").get("ok", true)), "เรียนพิเศษซ้ำวันเดิมไม่ได้")


func _test_v7_business() -> void:
	_fresh(18)
	Game.money = 20000
	Game.energy = 100
	Game.business_level = 0
	Game.business_stock = 0
	Game.business_sales_total = 0
	Game.business_day = -1

	var open := Game.open_business("ร้านขนมปัง")
	_check(bool(open.get("ok", false)), "เปิดร้านของตัวเองได้")
	_check(Game.business_level == 1, "ร้านเริ่มเลเวล 1")
	_check(Game.business_name == "ร้านขนมปัง", "ตั้งชื่อร้านได้")
	_check(Game.money == 20000 - Game.BUSINESS_OPEN_COST, "ค่าเปิดร้าน ฿12,000")
	_check(Game.business_stock == Game.BUSINESS_STOCK_PER_RESTOCK, "ร้านเริ่มมีสต็อก 30 ชิ้น")
	_check(not bool(Game.open_business().get("ok", true)), "เปิดร้านซ้ำไม่ได้")

	var run := Game.run_business_day()
	_check(bool(run.get("ok", false)), "เปิดร้านขายของได้")
	_check(Game.business_sales_total > 0, "มียอดขายสะสม")
	_check(not bool(Game.run_business_day().get("ok", true)), "เปิดร้านซ้ำวันเดิมไม่ได้")

	var stock0 := Game.business_stock
	_check(bool(Game.restock_business().get("ok", false)), "เติมสต็อกได้")
	_check(Game.business_stock == stock0 + Game.BUSINESS_STOCK_PER_RESTOCK, "สต็อกเพิ่ม 30 ชิ้น")

	Game.money = 20000
	var lvl0 := Game.business_level
	_check(bool(Game.upgrade_business().get("ok", false)), "อัปเกรดร้านได้")
	_check(Game.business_level == lvl0 + 1, "ระดับร้านเพิ่มขึ้น")
	_check(Game.business_capacity() > Game.BUSINESS_DAILY_BASE, "ร้านเลเวลสูงขายได้ต่อวันมากขึ้น")

	Game.money = 0
	_check(not bool(Game.restock_business().get("ok", true)), "เงินไม่พอเติมสต็อกไม่ได้")


func _test_v7_home_social() -> void:
	_fresh(18)
	Game.money = 50000
	Game.home_level = 1
	var cozy0 := Game.home_cozy()
	var up := Game.upgrade_home()
	_check(bool(up.get("ok", false)), "อัปเกรดบ้านได้")
	_check(Game.home_level == 2, "บ้านเลเวล 2")
	_check(Game.home_cozy() > cozy0, "บ้านเลเวลสูงขึ้นอบอุ่นขึ้น")

	# แมว
	Game.pet_name = "ส้ม"
	Game.pet_happy = 50
	Game.money = 5000
	Game.cat_feed_day = -1
	_check(bool(Game.cat_feed().get("ok", false)), "ให้อาหารแมวได้")
	_check(Game.pet_happy == 60, "ให้อาหารแมวแล้วความสุขแมว +10")
	_check(not bool(Game.cat_feed().get("ok", true)), "ให้อาหารแมวซ้ำวันเดิมไม่ได้")
	Game.cat_toy_owned = false
	_check(bool(Game.buy_cat_toy().get("ok", false)), "ซื้อของเล่นแมวได้")
	_check(Game.cat_toy_owned, "มีของเล่นแมวแล้ว")
	Game.cat_toy_day = -1
	_check(bool(Game.cat_play_toy().get("ok", false)), "เล่นของเล่นกับแมวได้")
	_check(not bool(Game.cat_play_toy().get("ok", true)), "เล่นของเล่นซ้ำวันเดิมไม่ได้")

	# ปาร์ตี้
	Game.money = 5000
	Game.party_week = -1
	Game.party_count = 0
	Game.npc_friendship["gun"] = 40
	Game.npc_friendship["nan"] = 35
	Game.npc_friendship["fah"] = 12
	var party := Game.host_party()
	_check(bool(party.get("ok", false)), "จัดปาร์ตี้ที่บ้านได้")
	_check(Game.party_count == 1, "นับจำนวนปาร์ตี้")
	_check(Game.money == 5000 - Game.PARTY_COST, "ค่าปาร์ตี้ ฿1,000")
	_check(not bool(Game.host_party().get("ok", true)), "จัดปาร์ตี้ซ้ำสัปดาห์เดิมไม่ได้")

	# สังคม
	Game.npc_friendship["gun"] = 70
	Game.npc_friendship["nan"] = 65
	_check(Game.close_friend_count(60) >= 2, "นับเพื่อนสนิทใจ 60+ ได้")
	Game.group_day = -1
	Game.money = 5000
	var night := Game.hangout_group()
	_check(bool(night.get("ok", false)), "ออกไปสังสรรค์กลุ่มได้")
	_check(Game.money == 5000 - 300, "ค่าสังสรรค์กลุ่ม ฿300")
	_check(not bool(Game.hangout_group().get("ok", true)), "สังสรรค์กลุ่มซ้ำวันเดิมไม่ได้")


func _test_v7_awards_family() -> void:
	_fresh(30)
	Game.money = 50000
	Game.achievements = {}
	Game.achievement_claimed = {}
	Game.fame = 0
	Game.add_fame(75, "ทดสอบ")
	_check(Game.fame == 75, "เพิ่มชื่อเสียงได้")
	_check(Game.fame_title() == "ดาวเด่นของเมือง", "ชื่อเสียง 75 ได้ตำแหน่งดาวเด่น")
	Game.check_achievements()
	_check(Game.achievement_unlocked("famous"), "ปลดล็อกความสำเร็จคนดัง")
	var m0 := Game.money
	Game.claim_achievement("famous")
	_check(Game.money == m0 + 2500, "รางวัลคนดัง ฿2,500")

	Game.rumor_today = ""
	Game._rumor_new_day()
	_check(Game.rumor_text() != "", "มีข้อความข่าวลือให้อ่านเสมอ")

	# ครอบครัว
	Game.married = true
	Game.partner_name = "แนน"
	Game.partner_love = 50
	Game.honeymoon_done = false
	Game.money = 50000
	var honey := Game.honeymoon()
	_check(bool(honey.get("ok", false)), "ไปฮันนีมูนได้")
	_check(Game.honeymoon_done and Game.partner_love == 70, "ฮันนีมูนเพิ่มความรัก +20")
	_check(Game.money == 50000 - Game.HONEYMOON_COST, "ค่าฮันนีมูน ฿6,000")
	_check(not bool(Game.honeymoon().get("ok", true)), "ฮันนีมูนซ้ำไม่ได้")

	Game.family_outing_week = -1
	Game.money = 5000
	var trip := Game.family_outing()
	_check(bool(trip.get("ok", false)), "ทริปครอบครัวได้")
	_check(Game.money == 5000 - Game.FAMILY_OUTING_COST, "ค่าทริปครอบครัว ฿700")
	_check(not bool(Game.family_outing().get("ok", true)), "ทริปครอบครัวซ้ำสัปดาห์เดิมไม่ได้")

	Game.children.append({"name": "น้องฝน", "age": 2})
	Game.check_achievements()
	_check(Game.achievement_unlocked("parent_proud"), "มีลูกแล้วปลดล็อกความสำเร็จพ่อแม่")

	# บูธเทศกาล
	Game.money = 1000
	Game.booth_day = -1
	Game.booth_plays = 0
	var booth := Game.play_festival_booth(true, 2)
	_check(bool(booth.get("ok", false)), "เล่นบูธเทศกาลชนะได้")
	_check(int(booth.get("prize", 0)) == 350, "บูธคะแนนเต็มได้รางวัล ฿350")
	Game.play_festival_booth(false)
	Game.play_festival_booth(true, 0)
	_check(Game.booth_plays == 3, "เล่นบูธได้ 3 ครั้ง")
	_check(not bool(Game.play_festival_booth(true).get("ok", true)), "เล่นบูธครบ 3 ครั้งต่อวันไม่ได้")


# ============================================================
#  v8 — เควสต์ / เป้าหมายชีวิต
# ============================================================

func _test_v8_quests() -> void:
	_fresh(22)
	Game.money = 1000
	Game.quest_week = -1
	Game.quests = []
	Game.quest_counts = {}
	Game.quest_total_done = 0
	Game.quest_certificates = []
	Game._ensure_quest_week()
	_check(Game.quests.size() == Game.QUEST_WEEK_COUNT, "สุ่มภารกิจรายสัปดาห์ 3 อย่าง")
	var stats := {}
	for i in Game.quests.size():
		stats[Game.quest_stat(i)] = true
	_check(stats.size() == Game.quests.size(), "ภารกิจในสัปดาห์มีประเภทต่างกัน")

	# ตั้งภารกิจที่รู้ผลแน่นอน แล้วตรวจว่าการกระทำนับความคืบหน้า
	Game.quest_week = Game.quest_week_index()
	Game.quests = [
		{"id": "harvest3", "claimed": false},
		{"id": "fish2", "claimed": false},
		{"id": "talk4", "claimed": false},
	]
	Game.quest_counts = {}
	Game.farm_plots[0] = {"crop": "lettuce", "growth": 3, "watered": false}
	Game.farm_harvest(0)
	_check(int(Game.quest_counts.get("harvest", 0)) == 1, "เก็บเกี่ยวนับเป็นความคืบหน้าภารกิจ")
	_check(Game.quest_progress(0) == 1, "อ่านความคืบหน้าภารกิจได้")
	Game.fish_result(true, 0)
	_check(int(Game.quest_counts.get("fish", 0)) >= 1, "ตกปลานับเป็นความคืบหน้าภารกิจ")
	var npc: Dictionary = TownData.NPCS["nan"].duplicate(true)
	npc["id"] = "nan"
	Game.zone_id = "park"
	Game.npc_talk(npc)
	_check(int(Game.quest_counts.get("talk", 0)) >= 1, "คุยกับ NPC นับเป็นความคืบหน้าภารกิจ")

	# รับรางวัล + ใบประกาศทองแดง
	Game.quests = [{"id": "fish2", "claimed": false}]
	Game.quest_counts = {"fish": 2}
	Game.quest_total_done = 4
	Game.quest_certificates = []
	var before := Game.money
	var res := Game.claim_quest(0)
	_check(bool(res.get("ok", false)), "รับรางวัลภารกิจที่ทำครบได้")
	_check(Game.money == before + 400 + 800, "ได้เงินรางวัลภารกิจและใบประกาศทองแดง")
	_check(Game.quest_total_done == 5, "นับภารกิจที่ทำสำเร็จเพิ่ม")
	_check(Game.has_quest_certificate("bronze"), "ทำครบ 5 ภารกิจได้ใบประกาศทองแดง")
	_check(not bool(Game.claim_quest(0).get("ok", true)), "รับรางวัลภารกิจซ้ำไม่ได้")

	# สัปดาห์ใหม่ล้างตัวนับและสุ่มภารกิจใหม่
	Game.day = 8
	Game._ensure_quest_week()
	_check(Game.quest_week == Game.quest_week_index(), "เข้าสัปดาห์ใหม่แล้วรีเซ็ตภารกิจ")
	_check(Game.quest_counts.is_empty(), "ตัวนับภารกิจรายสัปดาห์ถูกล้าง")
	_check(Game.quests.size() == Game.QUEST_WEEK_COUNT, "สัปดาห์ใหม่มีภารกิจครบ 3 อย่าง")


func _test_v8_goals() -> void:
	_fresh(30)
	Game.life_goal = "family"
	Game.parent_love = 100
	Game.partner_love = 100
	Game.married = true
	Game.children = [{"name": "อา", "age": 4}, {"name": "บี", "age": 2}]
	Game.happy = 100
	Game.home_level = Game.HOME_MAX_LEVEL
	Game.pet_name = "ส้ม"
	Game.social = 100
	_check(Game.goal_progress() == 100, "เป้าหมายครอบครัวเต็ม 100")
	_check(Game.goal_tier() == 4 and Game.goal_tier_name() == "สมบูรณ์แบบ",
		"เป้าหมายครอบครัวถึงระดับสูงสุด")

	Game.life_goal = "career"
	Game.edu = 100
	Game.job_id = "doctor"
	Game.job_level = 3
	Game.performance = 100
	Game.money = 50000
	Game.bank = 50000
	Game.business_level = 4
	for sk in Game.SKILL_KEYS:
		Game.skills[String(sk)] = 100
	Game.graduated = true
	_check(Game.goal_progress() == 100, "เป้าหมายอาชีพเต็ม 100")

	Game.life_goal = "legend"
	Game.fame = 100
	Game.achievements = {}
	for a in Game.ACHIEVEMENTS:
		Game.achievements[String(a["id"])] = true
	Game.collections = {}
	for cid in Game.COLLECTIBLES.keys():
		Game.collections[String(cid)] = 1
	Game.festival_wins = 5
	Game.quest_total_done = 20
	Game.fish_total = 10
	Game.bug_total = 10
	Game.social = 100
	_check(Game.goal_progress() == 100, "เป้าหมายตำนานเมืองเต็ม 100")

	var ending := Game.life_ending()
	_check(String(ending.get("rank", "")) == "S", "คะแนนเต็มได้ฉากจบอันดับ S")
	_check(String(ending.get("id", "")) == "legend_eternal", "ฉากจบตำนานเมืองแบบสมบูรณ์")

	Game.fame = 0
	Game.achievements = {}
	Game.collections = {}
	Game.festival_wins = 0
	Game.quest_total_done = 0
	Game.fish_total = 0
	Game.bug_total = 0
	Game.social = 0
	_check(Game.goal_progress() == 0, "เป้าหมายที่ยังไม่เริ่มได้ 0")
	_check(String(Game.life_ending().get("id", "")) == "legend_quiet",
		"คะแนนต่ำได้ฉากจบเริ่มต้น")

	# การเลือกเป้าหมายในหน้า création ส่งค่าถึง start_life
	Game.start_life("นี", "หญิง", 1, "heirloom_rose", "kind",
		"warm", "black", "short", "career")
	_check(Game.life_goal == "career", "สร้างตัวละครพร้อมเลือกเป้าหมายชีวิตได้")
	_check(Game.quests.size() == Game.QUEST_WEEK_COUNT, "เริ่มชีวิตแล้วมีภารกิจประจำสัปดาห์")
