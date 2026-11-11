extends Node
## Screenshot.gd — ถ่ายภาพหน้าจอ v8 (แนวนอน 960x540) ไว้ตรวจหน้าตา
## รัน: godot --path . res://tests/Screenshot.tscn
##
## ภาพที่ได้ (screenshots/):
##   town_home.png / town_street.png / town_school.png / town_downtown.png
##   town_park.png / town_winter.png / town_rain_night.png / home_cozy.png
##   town_backyard.png / town_backyard_evening.png / home_sitting.png
##   interior_classroom.png / interior_store.png / interior_gym.png
##   interior_cafe.png / interior_mall.png
##   interior_hospital.png / interior_university.png
##   festival_blossom.png / festival_winter.png
##   summary.png / career.png / skills.png / home_panel.png
##   farm_panel.png / hobby_panel.png / awards_panel.png / quests_panel.png
##   business_panel.png / social_panel.png / festival_panel.png
##   bus.png / npc_dialog.png / alarm.png / minigame.png / creation.png / gameover.png

var town = null


func _ready() -> void:
	# กันการปิดหน้าต่างโดยไม่ตั้งใจระหว่างถ่ายภาพชุดยาว
	get_tree().auto_accept_quit = false
	if FileAccess.file_exists("user://pixel_life.save"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pixel_life.save"))

	Game.start_life("นุ่น", "หญิง", 1, "heirloom_rose", "kind")
	Game.age = 12
	Game.time_min = 8 * 60 + 30
	Game.weekday = 1
	Game.season = 0
	Game.season_day = 3
	Game.weather = "sun"
	Game.money = 5000
	Game.parent_love = 82
	Game.grades = 68
	Game.fitness = 45
	Game.skills = {
		"communication": 42, "academics": 55, "craft": 28,
		"cooking": 34, "art": 61, "athletics": 40, "tech": 22,
	}
	Game.home_items = ["cozy_lamp", "bookshelf", "plant", "cat_bed", "picture", "wall_clock"]
	Game.pet_name = "ส้ม"
	Game.pet_happy = 72
	Game.collections = {"sakura": 2, "clover": 1, "butterfly": 1, "maple": 1}
	Game.collection_milestone = 4
	Game.festival_wins = 2
	Game.npc_friendship["gun"] = 42
	Game.npc_friendship["nan"] = 55
	Game.time_paused = true

	var town_scene: PackedScene = load("res://scenes/Town.tscn")
	town = town_scene.instantiate()
	add_child(town)
	await _wait(6)
	Game.time_paused = true

	# ---------- เมืองกลางแจ้ง ----------
	await _zone_shot("home", Vector2(480, 430), 8, 0, "sun", "town_home.png")
	await _zone_shot("home_street", Vector2(330, 380), 9, 0, "sun", "town_street.png")
	await _zone_shot("school_district", Vector2(480, 400), 10, 0, "sun", "town_school.png")
	await _zone_shot("classroom", Vector2(480, 420), 10, 0, "sun", "interior_classroom.png")
	await _zone_shot("downtown", Vector2(480, 380), 19, 1, "sun", "town_downtown.png")
	await _zone_shot("park", Vector2(480, 380), 16, 1, "sun", "town_park.png")
	await _zone_shot("home_street", Vector2(480, 380), 11, 3, "snow", "town_winter.png")
	await _zone_shot("downtown", Vector2(480, 380), 21, 2, "rain", "town_rain_night.png")
	await _zone_shot("home", Vector2(480, 430), 19, 2, "cloud", "home_cozy.png")

	# ---------- สวนหลังบ้าน v7 ----------
	Game.farm_plots[0] = {"crop": "tomato", "growth": 3, "watered": true}
	Game.farm_plots[1] = {"crop": "corn", "growth": 5, "watered": false}
	Game.farm_plots[2] = {"crop": "lettuce", "growth": 1, "watered": true}
	Game.farm_plots[3] = {"crop": "pumpkin", "growth": 2, "watered": false}
	Game.harvest_total = 6
	Game.fish_total = 4
	Game.bug_total = 3
	Game.fish_catches = {"carp": 2, "catfish": 1, "koi": 1}
	Game.bug_catches = {"butterfly": 1, "grasshopper": 1, "firefly": 1}
	Game.fame = 38
	await _zone_shot("backyard", Vector2(480, 465), 10, 1, "sun", "town_backyard.png")
	await _zone_shot("backyard", Vector2(620, 430), 18, 2, "cloud", "town_backyard_evening.png")

	# ---------- ท่านั่งบนโซฟา ----------
	town._load_zone("home", Vector2(480, 420))
	town.player.sit_at(Vector2(470, 314))
	Game.time_min = 19 * 60
	Game.time_paused = true
	town.hud.refresh()
	await _wait(8)
	await _shot("home_sitting.png")
	town.player.stand_up()

	# ---------- ภายในร้าน ----------
	await _zone_shot("store", Vector2(430, 390), 14, 0, "sun", "interior_store.png")
	await _zone_shot("gym", Vector2(450, 390), 17, 0, "sun", "interior_gym.png")
	await _zone_shot("cafe", Vector2(430, 400), 15, 0, "sun", "interior_cafe.png")
	await _zone_shot("mall", Vector2(430, 390), 14, 0, "sun", "interior_mall.png")
	await _zone_shot("hospital", Vector2(430, 390), 10, 0, "sun", "interior_hospital.png")
	await _zone_shot("university", Vector2(430, 390), 10, 0, "sun", "interior_university.png")

	# ---------- บูธเทศกาล ----------
	Game.season_day = 5
	await _zone_shot("park", Vector2(480, 380), 17, 0, "sun", "festival_blossom.png")
	Game.season_day = 6
	await _zone_shot("downtown", Vector2(480, 360), 20, 3, "snow", "festival_winter.png")
	Game.season = 0
	Game.season_day = 3

	# ---------- ข้อมูลตัวอย่าง v7 สำหรับ HUD ----------
	Game.business_level = 2
	Game.business_name = "ร้านขนมปังนุ่นน้อย"
	Game.business_stock = 24
	Game.business_sales_total = 18600
	Game.business_day = -1
	Game.home_level = 2
	Game.party_count = 2
	Game.cat_toy_owned = true
	Game.club_id = "art"
	Game.club_level = 2
	Game.club_points = 140
	Game.club_day = -1
	Game.achievements = {
		"first_harvest": true, "first_fish": true,
		"business_owner": true, "club_master": true,
	}
	Game.achievement_claimed = {"first_harvest": true}
	Game.fame = 38
	Game.rumor_today = "💬 ได้ยินว่าคนแถวนี้แวะซื้อขนมปังร้านนุ่นทุกเช้า"
	Game.npc_friendship["fah"] = 74
	Game.npc_friendship["ploy"] = 68
	Game.npc_friendship["tee"] = 63
	Game.npc_friendship["jane"] = 61
	Game.npc_friendship["nok"] = 57

	# ---------- ข้อมูลตัวอย่าง v8 สำหรับแผงภารกิจ ----------
	Game.life_goal = "family"
	Game.parent_love = 82
	Game.partner_name = "ต้น"
	Game.partner_love = 76
	Game.married = true
	Game.children = [{"name": "น้องฝน", "age": 4}]
	Game.happy = 84
	Game.social = 63
	Game.quest_week = Game.quest_week_index()
	Game.quests = [
		{"id": "harvest3", "claimed": false},
		{"id": "fish2", "claimed": true},
		{"id": "talk4", "claimed": false},
	]
	Game.quest_counts = {"harvest": 2, "fish": 2, "talk": 4}
	Game.quest_total_done = 6
	Game.quest_certificates = ["bronze"]

	# ---------- HUD / แผง ----------
	town._load_zone("home_street", Vector2(480, 380))
	town.hud.refresh()
	town.hud.open_summary("overview")
	await _wait(10)
	await _shot("summary.png")
	town.hud.close_modal()

	town.hud.open_summary("career")
	await _wait(8)
	await _shot("career.png")
	town.hud.close_modal()

	town.hud.open_summary("skills")
	await _wait(8)
	await _shot("skills.png")
	town.hud.close_modal()

	town.hud.open_summary("home")
	await _wait(8)
	await _shot("home_panel.png")
	town.hud.close_modal()

	town.hud.open_summary("farm")
	await _wait(8)
	await _shot("farm_panel.png")
	town.hud.close_modal()

	town.hud.open_summary("hobby")
	await _wait(8)
	await _shot("hobby_panel.png")
	town.hud.close_modal()

	town.hud.open_summary("awards")
	await _wait(8)
	await _shot("awards_panel.png")
	town.hud.close_modal()

	town.hud.open_summary("quests")
	await _wait(8)
	await _shot("quests_panel.png")
	town.hud.close_modal()

	# โตเป็นผู้ใหญ่ก่อนถ่ายแผงธุรกิจ/สังคม
	Game.age = 24
	town.hud.refresh()

	town.hud.open_summary("business")
	await _wait(8)
	await _shot("business_panel.png")
	town.hud.close_modal()

	town.hud.open_summary("social")
	await _wait(8)
	await _shot("social_panel.png")
	town.hud.close_modal()

	Game.season_day = 5
	town.hud.open_summary("festival")
	await _wait(8)
	await _shot("festival_panel.png")
	town.hud.close_modal()
	Game.season_day = 3

	town.hud.open_bus()
	await _wait(8)
	await _shot("bus.png")
	town.hud.close_modal()

	var npc: Dictionary = TownData.NPCS["nan"].duplicate(true)
	npc["id"] = "nan"
	town.hud.open_npc_dialog(npc)
	await _wait(8)
	await _shot("npc_dialog.png")
	town.hud.close_dialog()

	Game.time_min = 21 * 60
	town.hud.open_alarm()
	await _wait(8)
	await _shot("alarm.png")
	town.hud.close_modal()

	town.hud.start_minigame("math", "คาบเรียนวันนี้", 4, func(_s: int) -> void: pass)
	await _wait(10)
	await _shot("minigame.png")
	town.hud._minigame._cancel()
	await _wait(3)

	# ---------- จบชีวิต / หน้าสร้างตัวละคร ----------
	Game.new_game()
	town.hud.close_all()
	Game.created = true
	Game.alive = false
	Game.age = 82
	Game.days_played = 2128
	Game.money = 125000
	Game.death_cause = "จากไปอย่างสงบในวัย 82"
	Game.life_goal = "legend"
	Game.fame = 92
	Game.social = 70
	Game.achievements = {}
	for a in Game.ACHIEVEMENTS:
		Game.achievements[String(a["id"])] = true
	Game.collections = {}
	for cid in Game.COLLECTIBLES.keys():
		Game.collections[String(cid)] = 1
	Game.festival_wins = 4
	Game.quest_total_done = 15
	Game.quest_certificates = ["bronze", "silver"]
	Game.fish_total = 8
	Game.bug_total = 6
	town.hud.show_game_over()
	await _wait(10)
	await _shot("gameover.png")
	town.hud.close_all()

	Game.new_game()
	town.hud.show_creation()
	await _wait(10)
	await _shot("creation.png")

	if FileAccess.file_exists("user://pixel_life.save"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pixel_life.save"))

	get_tree().quit()


func _zone_shot(zid: String, pos: Vector2, hour: int, season: int, weather: String, file: String) -> void:
	Game.time_min = hour * 60
	Game.season = season
	Game.weather = weather
	town._load_zone(zid, pos)
	Game.time_paused = true
	town.hud.refresh()
	await _wait(8)
	await _shot(file)


func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


func _shot(name: String) -> void:
	# บางเครื่อง ANGLE ไม่ส่ง frame_post_draw — บังคับวาดแล้วรอหนึ่งเฟรมแทน
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img == null:
		print("capture failed: ", name)
		return
	var path := ProjectSettings.globalize_path("res://screenshots/" + name)
	img.save_png(path)
	print("saved: ", path, " size=", img.get_size())
