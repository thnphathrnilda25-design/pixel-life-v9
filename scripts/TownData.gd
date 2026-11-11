class_name TownData
## TownData.gd — ข้อมูลเมือง v4 ทั้งหมด (โซน/ประตู/เฟอร์นิเจอร์/NPC/ตารางเวลา)
## แก้ตรงไฟล์นี้ไฟล์เดียวเพื่อย้ายบ้าน เพิ่มร้าน หรือเปลี่ยนเส้นทางเดิน

const W := 960.0
const H := 540.0

const OUTDOOR_ZONES := ["home_street", "school_district", "downtown", "park"]

## ตำแหน่งเฟอร์นิเจอร์ที่ซื้อจากแผง "บ้าน" — วาดในบ้านเมื่อมีของชิ้นนั้น
const FURNITURE_SLOTS := {
	"cozy_lamp": Vector2(395, 210),
	"bookshelf": Vector2(250, 210),
	"plant": Vector2(40, 478),
	"fish_tank": Vector2(905, 230),
	"cat_bed": Vector2(655, 420),
	"wall_clock": Vector2(400, 92),
	"picture": Vector2(640, 96),
}

## ------------------------------------------------------------
##  โซนทั้งหมด
##  outdoor  : มีหญ้า/ถนน/ต้นไม้/อาคาร
##  interior : ห้องภายใน มีผนังด้านบน + พื้นกระเบื้อง
##  exits    : ทางออกขอบจอ (edge = left/right/top/bottom)
##  doors    : ประตู/ทางเข้าอาคาร
##  props    : เฟอร์นิเจอร์ + จุดกดใช้ (action)
## ------------------------------------------------------------
const ZONES := {
	# ============================== บ้าน ==============================
	"home": {
		"name": "บ้านของเรา",
		"outdoor": false,
		"theme": "home",
		"spawn": Vector2(480, 440),
		"wall": "#d8b98f",
		"floor": "#b07c4f",
		"exits": [],
		"props": [
			{"type": "bed", "pos": Vector2(130, 245), "action": "sleep",
				"label": "เข้านอน (ต้องหลัง 18:00)"},
			{"type": "desk", "pos": Vector2(320, 250), "action": "homework",
				"label": "ทำการบ้าน"},
			{"type": "fridge", "pos": Vector2(810, 230), "action": "eat_home",
				"label": "กินข้าวที่บ้าน ฿120"},
			{"type": "tv", "pos": Vector2(560, 205), "action": "watch_tv",
				"label": "ดูทีวีพักผ่อน"},
			{"type": "rug", "pos": Vector2(470, 340), "w": 240},
			{"type": "sofa", "pos": Vector2(470, 300), "action": "sit_rest",
				"label": "นั่งพักบนโซฟา"},
			{"type": "table", "pos": Vector2(710, 350), "w": 150, "action": "dinner",
				"label": "กินข้าวเย็นกับครอบครัว"},
			{"type": "easel", "pos": Vector2(858, 390), "action": "practice_art",
				"label": "วาดรูปฝึกฝน"},
			{"type": "kitchen", "pos": Vector2(660, 176), "action": "cook_meal",
				"label": "ทำกับข้าวเอง ฿60"},
			{"type": "workbench", "pos": Vector2(64, 338), "action": "craft_item",
				"label": "ประดิษฐ์ของขาย"},
			{"type": "plant", "pos": Vector2(70, 430)},
			{"type": "plant", "pos": Vector2(900, 430)},
			{"type": "window", "pos": Vector2(250, 130)},
			{"type": "window", "pos": Vector2(680, 130)},
			{"type": "picture", "pos": Vector2(520, 96)},
			{"type": "door_mat", "pos": Vector2(880, 505)},
			{"type": "back_door", "pos": Vector2(58, 505)},
		],
		"doors": [
			{"pos": Vector2(58, 505), "zone": "backyard", "spawn": Vector2(480, 470),
				"label": "ไปสวนหลังบ้าน"},
		],
		"door_zone": "home_street",
		"door_spawn": Vector2(200, 390),
	},

	"home_street": {
		"name": "ถนนบ้านเรา",
		"outdoor": true,
		"theme": "suburb",
		"spawn": Vector2(480, 430),
		"buildings": [
			{"x": 80, "y": 145, "w": 240, "h": 195, "wall": "#e7c69c", "roof": "#b94e3f", "door_x": 200},
			{"x": 365, "y": 165, "w": 195, "h": 175, "wall": "#cfe2b8", "roof": "#4f7d5d", "door_x": 462},
			{"x": 610, "y": 155, "w": 185, "h": 185, "wall": "#d9c7ea", "roof": "#6b5686", "door_x": 702},
		],
		"paths": [
			{"x": 0, "y": 345, "w": 960, "h": 54, "kind": "walk"},
			{"x": 0, "y": 399, "w": 960, "h": 62, "kind": "road"},
			{"x": 172, "y": 330, "w": 56, "h": 24, "kind": "walk"},
			{"x": 434, "y": 330, "w": 56, "h": 24, "kind": "walk"},
			{"x": 674, "y": 330, "w": 56, "h": 24, "kind": "walk"},
		],
		"trees": [[45, 260, 1.0], [600, 300, 0.9], [830, 250, 1.1], [55, 500, 1.0], [905, 510, 1.0]],
		"flowers": [[320, 480, "#f2a0b8"], [760, 470, "#f2d05a"], [180, 505, "#9ec8ff"]],
		"lamps": [[340, 360], [620, 360]],
		"benches": [[525, 470]],
		"fences": [
			{"x": 60, "y": 338, "w": 130, "color": "#f2ead8"},
			{"x": 585, "y": 338, "w": 130, "color": "#e8d8b8"},
			{"x": 735, "y": 338, "w": 120, "color": "#f2ead8"},
		],
		"bushes": [[285, 300, 0.9], [565, 305, 0.9], [875, 300, 1.0], [130, 480, 0.8]],
		"stones": [[250, 470], [280, 465], [520, 505], [860, 490]],
		"mailboxes": [[222, 330], [486, 330]],
		"planters": [[150, 333], [700, 333]],
		"bicycles": [[505, 300]],
		"props": [
			{"type": "sparkle", "pos": Vector2(690, 470), "action": "collect",
				"label": "เก็บของสะสมตามฤดู"},
		],
		"doors": [
			{"pos": Vector2(200, 345), "zone": "home", "spawn": Vector2(480, 440),
				"label": "เข้าบ้านของเรา"},
			{"pos": Vector2(462, 345), "zone": "neighbor_home", "spawn": Vector2(480, 440),
				"label": "เข้าบ้านเพื่อน"},
		],
		"bus": Vector2(820, 350),
		"exits": [
			{"edge": "left", "zone": "park", "spawn": Vector2(905, 320), "label": "ไปสวนสาธารณะ"},
			{"edge": "right", "zone": "school_district", "spawn": Vector2(55, 430), "label": "ไปย่านโรงเรียน"},
		],
	},

	# ============================== สวนหลังบ้าน (v7) ==============================
	"backyard": {
		"name": "สวนหลังบ้าน",
		"outdoor": true,
		"theme": "backyard",
		"spawn": Vector2(480, 470),
		"buildings": [],
		"paths": [
			{"x": 60, "y": 452, "w": 840, "h": 58, "kind": "walk"},
			{"x": 110, "y": 300, "w": 300, "h": 140, "kind": "soil"},
		],
		"trees": [[64, 225, 1.0], [905, 235, 1.05], [935, 420, 0.9]],
		"flowers": [[430, 470, "#f2a0b8"], [560, 462, "#f2d05a"], [400, 505, "#c8a0f2"]],
		"lamps": [[512, 355]],
		"benches": [[770, 470]],
		"fences": [
			{"x": 30, "y": 478, "w": 110, "color": "#f2ead8"},
			{"x": 820, "y": 478, "w": 110, "color": "#e8d8b8"},
		],
		"bushes": [[215, 505, 0.9], [620, 500, 0.8]],
		"stones": [[355, 490], [700, 490]],
		"pond": Vector2(742, 348),
		"props": [
			{"type": "coop", "pos": Vector2(150, 238)},
			{"type": "farm_sign", "pos": Vector2(418, 302)},
			{"type": "farm_plot", "pos": Vector2(150, 330), "index": 0, "action": "farm_plot",
				"label": "แปลงผัก 1"},
			{"type": "farm_plot", "pos": Vector2(235, 330), "index": 1, "action": "farm_plot",
				"label": "แปลงผัก 2"},
			{"type": "farm_plot", "pos": Vector2(320, 330), "index": 2, "action": "farm_plot",
				"label": "แปลงผัก 3"},
			{"type": "farm_plot", "pos": Vector2(150, 400), "index": 3, "action": "farm_plot",
				"label": "แปลงผัก 4"},
			{"type": "farm_plot", "pos": Vector2(235, 400), "index": 4, "action": "farm_plot",
				"label": "แปลงผัก 5"},
			{"type": "farm_plot", "pos": Vector2(320, 400), "index": 5, "action": "farm_plot",
				"label": "แปลงผัก 6"},
			{"type": "pier", "pos": Vector2(742, 386), "action": "fish",
				"label": "ตกปลาที่ท่าเรือ"},
			{"type": "bug_spot", "pos": Vector2(858, 250), "action": "catch_bug",
				"label": "จับแมลง"},
			{"type": "sparkle", "pos": Vector2(255, 478), "action": "collect",
				"label": "เก็บของสะสมตามฤดู"},
		],
		"doors": [
			{"pos": Vector2(480, 505), "zone": "home", "spawn": Vector2(480, 440),
				"label": "เข้าบ้าน"},
		],
	},

	"neighbor_home": {
		"name": "บ้านของแนน",
		"outdoor": false,
		"theme": "neighbor",
		"spawn": Vector2(480, 440),
		"wall": "#cdb6e2",
		"floor": "#9c6c4f",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "rug", "pos": Vector2(450, 350), "w": 200},
			{"type": "sofa", "pos": Vector2(300, 280)},
			{"type": "tv", "pos": Vector2(300, 190)},
			{"type": "table", "pos": Vector2(600, 300), "w": 150},
			{"type": "chair", "pos": Vector2(520, 330)},
			{"type": "chair", "pos": Vector2(680, 330)},
			{"type": "plant", "pos": Vector2(850, 260)},
			{"type": "window", "pos": Vector2(150, 120)},
			{"type": "window", "pos": Vector2(760, 120)},
			{"type": "door_mat", "pos": Vector2(480, 505)},
		],
		"door_zone": "home_street",
		"door_spawn": Vector2(462, 390),
	},

	# ============================== โรงเรียน ==============================
	"classroom": {
		"name": "ห้องเรียน ป.1",
		"outdoor": false,
		"theme": "classroom",
		"spawn": Vector2(480, 440),
		"wall": "#cfe0d2",
		"floor": "#b98b5e",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "board", "pos": Vector2(480, 205), "action": "school",
				"label": "เริ่มคาบเรียน"},
			{"type": "desk", "pos": Vector2(300, 300)},
			{"type": "desk", "pos": Vector2(430, 300)},
			{"type": "desk", "pos": Vector2(560, 300)},
			{"type": "desk", "pos": Vector2(300, 370)},
			{"type": "desk", "pos": Vector2(430, 370)},
			{"type": "desk", "pos": Vector2(560, 370)},
			{"type": "plant", "pos": Vector2(860, 240)},
			{"type": "window", "pos": Vector2(120, 120)},
			{"type": "window", "pos": Vector2(840, 120)},
			{"type": "door_mat", "pos": Vector2(110, 505)},
		],
		"door_zone": "school_district",
		"door_spawn": Vector2(250, 390),
	},

	"university": {
		"name": "มหาวิทยาลัย",
		"outdoor": false,
		"theme": "university",
		"spawn": Vector2(480, 440),
		"wall": "#d7d2c4",
		"floor": "#8f7a5c",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "board", "pos": Vector2(480, 205), "action": "university",
				"label": "เรียนมหาวิทยาลัย ฿800"},
			{"type": "desk", "pos": Vector2(260, 320), "action": "work",
				"label": "เริ่มกะสอน"},
			{"type": "desk", "pos": Vector2(400, 320)},
			{"type": "desk", "pos": Vector2(540, 320)},
			{"type": "desk", "pos": Vector2(680, 320)},
			{"type": "bookshelf", "pos": Vector2(850, 260)},
			{"type": "plant", "pos": Vector2(100, 260)},
			{"type": "window", "pos": Vector2(160, 120)},
			{"type": "window", "pos": Vector2(800, 120)},
			{"type": "door_mat", "pos": Vector2(860, 505)},
		],
		"door_zone": "school_district",
		"door_spawn": Vector2(695, 390),
	},

	"school_district": {
		"name": "ย่านโรงเรียน",
		"outdoor": true,
		"theme": "school",
		"spawn": Vector2(480, 440),
		"buildings": [
			{"x": 90, "y": 80, "w": 330, "h": 260, "wall": "#e9d7a8", "roof": "#a84b3e", "door_x": 250},
			{"x": 545, "y": 100, "w": 310, "h": 240, "wall": "#d7d2c4", "roof": "#4e5f7a", "door_x": 695},
		],
		"paths": [
			{"x": 0, "y": 340, "w": 960, "h": 200, "kind": "plaza"},
			{"x": 220, "y": 325, "w": 70, "h": 20, "kind": "walk"},
			{"x": 660, "y": 325, "w": 70, "h": 20, "kind": "walk"},
		],
		"trees": [[40, 310, 0.9], [910, 300, 1.0], [70, 500, 0.8], [900, 500, 0.9]],
		"flowers": [[380, 480, "#e98aa8"], [620, 480, "#f2d05a"], [150, 460, "#b6e08a"], [830, 470, "#c0a8f0"]],
		"lamps": [[360, 380], [620, 380], [80, 390], [870, 390]],
		"benches": [[480, 470], [760, 470]],
		"fences": [
			{"x": 95, "y": 332, "w": 110, "color": "#e8d8b8"},
			{"x": 500, "y": 332, "w": 110, "color": "#f2ead8"},
			{"x": 800, "y": 332, "w": 90, "color": "#e8d8b8"},
		],
		"bushes": [[190, 320, 0.9], [830, 320, 0.8], [520, 505, 0.9]],
		"stones": [[240, 500], [270, 495], [700, 500]],
		"mailboxes": [[180, 330], [790, 330]],
		"planters": [[420, 335], [560, 335]],
		"bicycles": [[320, 470]],
		"doors": [
			{"pos": Vector2(250, 340), "zone": "classroom", "spawn": Vector2(480, 440),
				"label": "เข้าโรงเรียน"},
			{"pos": Vector2(695, 340), "zone": "university", "spawn": Vector2(480, 440),
				"label": "เข้ามหาวิทยาลัย"},
		],
		"bus": Vector2(60, 430),
		"exits": [
			{"edge": "left", "zone": "home_street", "spawn": Vector2(900, 430), "label": "กลับถนนบ้าน"},
			{"edge": "right", "zone": "downtown", "spawn": Vector2(55, 470), "label": "ไปดาวน์ทาวน์"},
		],
		"props": [
			{"type": "sparkle", "pos": Vector2(720, 470), "action": "collect",
				"label": "เก็บของสะสมตามฤดู"},
		],
	},

	# ============================== ดาวน์ทาวน์ ==============================
	"downtown": {
		"name": "ดาวน์ทาวน์",
		"outdoor": true,
		"theme": "downtown",
		"spawn": Vector2(60, 480),
		"buildings": [
			{"x": 20, "y": 70, "w": 200, "h": 180, "wall": "#c9d3df", "roof": "#3f4d63", "door_x": 120},
			{"x": 250, "y": 85, "w": 190, "h": 165, "wall": "#e8d3a9", "roof": "#a85a42", "door_x": 345},
			{"x": 470, "y": 75, "w": 190, "h": 175, "wall": "#e8c3c8", "roof": "#8b4552", "door_x": 565},
			{"x": 690, "y": 65, "w": 250, "h": 185, "wall": "#d5e2e8", "roof": "#4f7d86", "door_x": 815},
			{"x": 40, "y": 300, "w": 160, "h": 120, "wall": "#d9d0ba", "roof": "#6e6650", "door_x": 120},
			{"x": 240, "y": 300, "w": 160, "h": 120, "wall": "#e3c7dd", "roof": "#7d4b72", "door_x": 320},
			{"x": 440, "y": 300, "w": 160, "h": 120, "wall": "#c9b7a8", "roof": "#5a3f37", "door_x": 520},
			{"x": 640, "y": 300, "w": 170, "h": 120, "wall": "#bdd3c2", "roof": "#44664c", "door_x": 725},
		],
		"paths": [
			{"x": 0, "y": 250, "w": 960, "h": 50, "kind": "walk"},
			{"x": 0, "y": 420, "w": 960, "h": 120, "kind": "walk"},
			{"x": 0, "y": 250, "w": 20, "h": 170, "kind": "walk"},
			{"x": 940, "y": 250, "w": 20, "h": 170, "kind": "walk"},
		],
		"trees": [[915, 260, 0.8], [30, 500, 0.9], [930, 500, 0.9]],
		"flowers": [[210, 470, "#f2a0b8"], [430, 500, "#f2d05a"], [640, 480, "#9ec8ff"], [120, 500, "#c0e89a"]],
		"lamps": [[220, 270], [470, 270], [690, 270], [200, 440], [620, 440], [860, 300]],
		"benches": [[860, 460], [250, 460]],
		"bushes": [[180, 500, 0.9], [760, 470, 0.8], [900, 400, 0.9]],
		"stones": [[100, 480], [130, 485], [690, 500]],
		"planters": [[300, 440], [760, 440]],
		"stalls": [[400, 505], [560, 505]],
		"bicycles": [[70, 470]],
		"doors": [
			{"pos": Vector2(120, 252), "zone": "office", "spawn": Vector2(480, 440), "label": "เข้าออฟฟิศ"},
			{"pos": Vector2(345, 252), "zone": "store", "spawn": Vector2(480, 440), "label": "เข้าร้านสะดวกซื้อ"},
			{"pos": Vector2(565, 252), "zone": "cafe", "spawn": Vector2(480, 440), "label": "เข้าคาเฟ่"},
			{"pos": Vector2(815, 252), "zone": "hospital", "spawn": Vector2(480, 440), "label": "เข้าโรงพยาบาล"},
			{"pos": Vector2(120, 422), "zone": "bank", "spawn": Vector2(480, 440), "label": "เข้าธนาคาร"},
			{"pos": Vector2(320, 422), "zone": "mall", "spawn": Vector2(480, 440), "label": "เข้าห้าง/ร้านเสื้อผ้า"},
			{"pos": Vector2(520, 422), "zone": "bar", "spawn": Vector2(480, 440), "label": "เข้าบาร์"},
			{"pos": Vector2(725, 422), "zone": "gym", "spawn": Vector2(480, 440), "label": "เข้าโรงยิม"},
		],
		"bus": Vector2(855, 460),
		"exits": [
			{"edge": "left", "zone": "school_district", "spawn": Vector2(900, 430), "label": "กลับย่านโรงเรียน"},
		],
		"props": [
			{"type": "sparkle", "pos": Vector2(800, 470), "action": "collect",
				"label": "เก็บของสะสมตามฤดู"},
			{"type": "bicycle", "pos": Vector2(900, 480)},
			{"type": "stall", "pos": Vector2(640, 460), "action": "festival_booth",
				"label": "เล่นบูธเกม ฿50"},
		],
	},

	# ============================== สวนสาธารณะ ==============================
	"park": {
		"name": "สวนสาธารณะ",
		"outdoor": true,
		"theme": "park",
		"spawn": Vector2(480, 500),
		"buildings": [],
		"paths": [
			{"x": 120, "y": 160, "w": 720, "h": 40, "kind": "track"},
			{"x": 120, "y": 440, "w": 720, "h": 40, "kind": "track"},
			{"x": 120, "y": 160, "w": 40, "h": 320, "kind": "track"},
			{"x": 800, "y": 160, "w": 40, "h": 320, "kind": "track"},
			{"x": 380, "y": 300, "w": 200, "h": 120, "kind": "plaza"},
		],
		"trees": [[60, 120, 1.2], [300, 110, 0.9], [640, 100, 1.0], [890, 110, 1.1],
			[60, 360, 1.0], [900, 360, 1.0], [250, 500, 0.9], [740, 500, 0.9]],
		"flowers": [[200, 330, "#f2a0b8"], [730, 330, "#f2d05a"], [420, 250, "#b6e08a"], [560, 470, "#9ec8ff"],
			[300, 250, "#f2a0b8"], [660, 250, "#c0a8f0"], [170, 480, "#f2d05a"], [780, 490, "#f2a0b8"]],
		"lamps": [[380, 180], [580, 180], [380, 440], [580, 440], [180, 300], [780, 300]],
		"benches": [[340, 350], [620, 350], [430, 480], [530, 480]],
		"fences": [
			{"x": 170, "y": 300, "w": 130, "color": "#f2ead8"},
			{"x": 660, "y": 300, "w": 130, "color": "#e8d8b8"},
			{"x": 170, "y": 470, "w": 90, "color": "#f2ead8"},
			{"x": 700, "y": 470, "w": 90, "color": "#e8d8b8"},
		],
		"bushes": [[230, 300, 0.9], [730, 300, 0.9], [120, 400, 1.0], [840, 400, 1.0], [480, 510, 0.8]],
		"stones": [[280, 420], [310, 415], [660, 420], [690, 415]],
		"planters": [[330, 300], [630, 300]],
		"picnic": [[740, 400]],
		"fountain": Vector2(480, 280),
		"bus": Vector2(850, 110),
		"checkpoints": [Vector2(480, 180), Vector2(820, 320), Vector2(480, 460), Vector2(140, 320)],
		"doors": [],
		"exits": [
			{"edge": "right", "zone": "home_street", "spawn": Vector2(55, 430), "label": "กลับถนนบ้าน"},
		],
		"props": [
			{"type": "sparkle", "pos": Vector2(300, 400), "action": "collect",
				"label": "เก็บของสะสมตามฤดู"},
			{"type": "stall", "pos": Vector2(860, 350), "action": "festival_booth",
				"label": "เล่นบูธเกม ฿50"},
		],
	},

	# ============================== ภายในอาคาร ==============================
	"office": {
		"name": "ออฟฟิศ",
		"outdoor": false,
		"theme": "office",
		"spawn": Vector2(480, 440),
		"wall": "#c3ccd8",
		"floor": "#6e7b8c",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "desk", "pos": Vector2(480, 255), "w": 110, "action": "work",
				"label": "เริ่มกะทำงาน"},
			{"type": "desk", "pos": Vector2(250, 320)},
			{"type": "desk", "pos": Vector2(680, 320)},
			{"type": "computer", "pos": Vector2(480, 230)},
			{"type": "plant", "pos": Vector2(90, 260)},
			{"type": "water", "pos": Vector2(870, 250)},
			{"type": "window", "pos": Vector2(180, 120)},
			{"type": "window", "pos": Vector2(780, 120)},
			{"type": "door_mat", "pos": Vector2(110, 505)},
		],
		"door_zone": "downtown",
		"door_spawn": Vector2(120, 292),
	},

	"store": {
		"name": "ร้านสะดวกซื้อ",
		"outdoor": false,
		"theme": "store",
		"spawn": Vector2(480, 440),
		"wall": "#d8e0c4",
		"floor": "#cfd6d8",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "shelf", "pos": Vector2(260, 280), "action": "work",
				"label": "เริ่มกะทำงาน (จัดของ)"},
			{"type": "shelf", "pos": Vector2(430, 280)},
			{"type": "shelf", "pos": Vector2(600, 280)},
			{"type": "counter", "pos": Vector2(760, 300), "w": 160, "action": "shop_store",
				"label": "ซื้อของที่ร้าน"},
			{"type": "plant", "pos": Vector2(80, 260)},
			{"type": "window", "pos": Vector2(200, 120)},
			{"type": "window", "pos": Vector2(740, 120)},
			{"type": "door_mat", "pos": Vector2(110, 505)},
		],
		"door_zone": "downtown",
		"door_spawn": Vector2(345, 292),
	},

	"cafe": {
		"name": "คาเฟ่",
		"outdoor": false,
		"theme": "cafe",
		"spawn": Vector2(480, 440),
		"wall": "#e7d3b8",
		"floor": "#a8794f",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "counter", "pos": Vector2(720, 280), "w": 170, "action": "shop_cafe",
				"label": "สั่งอาหาร/กาแฟ"},
			{"type": "table", "pos": Vector2(300, 330), "w": 130, "action": "work",
				"label": "เริ่มกะทำงาน (เสิร์ฟ)"},
			{"type": "chair", "pos": Vector2(230, 360)},
			{"type": "chair", "pos": Vector2(370, 360)},
			{"type": "table", "pos": Vector2(550, 350), "w": 130},
			{"type": "chair", "pos": Vector2(480, 380)},
			{"type": "chair", "pos": Vector2(620, 380)},
			{"type": "plant", "pos": Vector2(80, 260)},
			{"type": "window", "pos": Vector2(200, 120)},
			{"type": "window", "pos": Vector2(520, 120)},
			{"type": "door_mat", "pos": Vector2(110, 505)},
		],
		"door_zone": "downtown",
		"door_spawn": Vector2(565, 292),
	},

	"hospital": {
		"name": "โรงพยาบาล",
		"outdoor": false,
		"theme": "hospital",
		"spawn": Vector2(480, 440),
		"wall": "#d9e8ea",
		"floor": "#c4d4d6",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "counter", "pos": Vector2(700, 280), "w": 170, "action": "hospital",
				"label": "ติดต่อเจ้าหน้าที่"},
			{"type": "bed", "pos": Vector2(250, 300), "action": "work",
				"label": "เริ่มกะทำงาน"},
			{"type": "bed", "pos": Vector2(250, 420)},
			{"type": "medcross", "pos": Vector2(480, 200)},
			{"type": "plant", "pos": Vector2(80, 260)},
			{"type": "window", "pos": Vector2(180, 120)},
			{"type": "window", "pos": Vector2(780, 120)},
			{"type": "door_mat", "pos": Vector2(110, 505)},
		],
		"door_zone": "downtown",
		"door_spawn": Vector2(815, 292),
	},

	"bank": {
		"name": "ธนาคาร",
		"outdoor": false,
		"theme": "bank",
		"spawn": Vector2(480, 440),
		"wall": "#d7d0be",
		"floor": "#8c8270",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "atm", "pos": Vector2(760, 280), "action": "bank",
				"label": "ใช้ ATM / ฝาก-ถอน"},
			{"type": "counter", "pos": Vector2(480, 280), "w": 180},
			{"type": "plant", "pos": Vector2(80, 260)},
			{"type": "plant", "pos": Vector2(890, 260)},
			{"type": "window", "pos": Vector2(200, 120)},
			{"type": "window", "pos": Vector2(700, 120)},
			{"type": "door_mat", "pos": Vector2(110, 505)},
		],
		"door_zone": "downtown",
		"door_spawn": Vector2(120, 460),
	},

	"mall": {
		"name": "ห้าง / ร้านเสื้อผ้า",
		"outdoor": false,
		"theme": "mall",
		"spawn": Vector2(480, 440),
		"wall": "#e5d3e2",
		"floor": "#c9b8c8",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "rack", "pos": Vector2(250, 280)},
			{"type": "rack", "pos": Vector2(430, 280)},
			{"type": "rack", "pos": Vector2(610, 280)},
			{"type": "desk", "pos": Vector2(140, 330), "action": "work",
				"label": "เริ่มกะทำงาน (ออกแบบ)"},
			{"type": "counter", "pos": Vector2(790, 320), "w": 130, "action": "shop_mall",
				"label": "เลือกซื้อ/เปลี่ยนชุด"},
			{"type": "mirror", "pos": Vector2(450, 130)},
			{"type": "plant", "pos": Vector2(80, 260)},
			{"type": "plant", "pos": Vector2(900, 260)},
			{"type": "window", "pos": Vector2(200, 120)},
			{"type": "window", "pos": Vector2(740, 120)},
			{"type": "door_mat", "pos": Vector2(110, 505)},
		],
		"door_zone": "downtown",
		"door_spawn": Vector2(320, 460),
	},

	"bar": {
		"name": "บาร์ / ไนต์คลับ",
		"outdoor": false,
		"theme": "bar",
		"spawn": Vector2(480, 440),
		"wall": "#3d3550",
		"floor": "#4a3d55",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "bar", "pos": Vector2(730, 270), "w": 190, "action": "bar",
				"label": "สั่งเครื่องดื่ม ฿200"},
			{"type": "dancefloor", "pos": Vector2(330, 340)},
			{"type": "speaker", "pos": Vector2(180, 220)},
			{"type": "speaker", "pos": Vector2(540, 220)},
			{"type": "table", "pos": Vector2(260, 440), "w": 120},
			{"type": "door_mat", "pos": Vector2(880, 505)},
		],
		"door_zone": "downtown",
		"door_spawn": Vector2(520, 460),
	},

	"gym": {
		"name": "โรงยิม",
		"outdoor": false,
		"theme": "gym",
		"spawn": Vector2(480, 440),
		"wall": "#cfd6d2",
		"floor": "#818c8a",
		"doors": [],
		"exits": [],
		"props": [
			{"type": "treadmill", "pos": Vector2(280, 290), "action": "gym",
				"label": "ออกกำลังกาย ฿80"},
			{"type": "treadmill", "pos": Vector2(470, 290)},
			{"type": "weights", "pos": Vector2(680, 290)},
			{"type": "mirror", "pos": Vector2(480, 130)},
			{"type": "benchpress", "pos": Vector2(680, 400)},
			{"type": "plant", "pos": Vector2(80, 260)},
			{"type": "window", "pos": Vector2(200, 120)},
			{"type": "window", "pos": Vector2(780, 120)},
			{"type": "door_mat", "pos": Vector2(110, 505)},
		],
		"door_zone": "downtown",
		"door_spawn": Vector2(725, 460),
	},
}

## ------------------------------------------------------------
##  ประตูภายใน (จุดกลับออกไปข้างนอก) — เพิ่มอัตโนมัติจาก door_zone
## ------------------------------------------------------------

## ------------------------------------------------------------
##  NPC + ตารางเวลา
##  spots: from/to = นาทีในวัน, days = all/school/weekend
## ------------------------------------------------------------
const NPCS := {
	"gun": {
		"name": "กัน", "kind": "npc", "dateable": "yes",
		"skin": "#f2c39b", "hair": "#2a2118", "shirt": "#e05a5a", "pants": "#3d4a6b",
		"hair_style": "messy", "style": "student", "accessory": "none",
		"lines": ["วันนี้เรียนอะไรบ้าง?", "ไปวิ่งที่สวนกันไหม", "ฉันว่าจะลองสมัครงานพาร์ทไทม์"],
		"spots": [
			{"zone": "classroom", "pos": Vector2(600, 300), "from": 480, "to": 900, "days": "school"},
			{"zone": "park", "pos": Vector2(620, 350), "from": 900, "to": 1200, "days": "all"},
			{"zone": "home_street", "pos": Vector2(600, 450), "from": 1200, "to": 1320, "days": "all"},
		],
	},
	"nan": {
		"name": "แนน", "kind": "npc", "dateable": "yes",
		"skin": "#f2c39b", "hair": "#3a2418", "shirt": "#f29ac0", "pants": "#5a3a5e",
		"hair_style": "long", "style": "home", "accessory": "headband",
		"lines": ["บ้านฉันอยู่ติดบ้านเธอเอง", "อยากไปคาเฟ่ด้วยกันไหม", "ฉันชอบอ่านนิยายมาก"],
		"spots": [
			{"zone": "neighbor_home", "pos": Vector2(420, 330), "from": 420, "to": 1320, "days": "all"},
			{"zone": "cafe", "pos": Vector2(420, 330), "from": 600, "to": 900, "days": "weekend"},
		],
	},
	"pataew": {
		"name": "ป้าแต๋ว", "kind": "npc", "dateable": "no",
		"skin": "#e8b98a", "hair": "#4a3a2a", "shirt": "#f2c05a", "pants": "#6b4a3a",
		"hair_style": "bun", "style": "vendor", "accessory": "apron",
		"lines": ["ขนมเพิ่งมาใหม่นะลูก", "วันนี้ลูกค้าเยอะจัง", "อย่าลืมกินข้าวด้วยนะ"],
		"spots": [
			{"zone": "store", "pos": Vector2(780, 330), "from": 420, "to": 1260, "days": "all"},
		],
	},
	"mint": {
		"name": "มิ้นท์", "kind": "npc", "dateable": "yes",
		"skin": "#f2c39b", "hair": "#5a2e3a", "shirt": "#9a7ad0", "pants": "#3d3550",
		"hair_style": "bob", "style": "chic", "accessory": "earring",
		"lines": ["กาแฟแก้วโปรดของฉันคือลาเต้", "กลางคืนฉันทำงานที่บาร์", "เธอดูเครียด ๆ นะ พักบ้าง"],
		"spots": [
			{"zone": "cafe", "pos": Vector2(620, 340), "from": 540, "to": 1020, "days": "all"},
			{"zone": "bar", "pos": Vector2(620, 330), "from": 1080, "to": 1380, "days": "all"},
		],
	},
	"boss": {
		"name": "บอส", "kind": "npc", "dateable": "no",
		"skin": "#d9a97a", "hair": "#1f1a16", "shirt": "#3f4d63", "pants": "#2a2a2a",
		"hair_style": "short", "style": "formal", "accessory": "tie",
		"lines": ["งานเสร็จหรือยัง?", "ขยันแบบนี้ได้เลื่อนตำแหน่งแน่", "อย่าลืมส่งรายงานก่อนเลิกงาน"],
		"spots": [
			{"zone": "office", "pos": Vector2(720, 250), "from": 480, "to": 1020, "days": "school"},
		],
	},
	"poom": {
		"name": "ภูมิ", "kind": "npc", "dateable": "yes",
		"skin": "#d9a97a", "hair": "#2a2118", "shirt": "#4aa3ff", "pants": "#2e3a59",
		"hair_style": "short", "style": "sport", "accessory": "none",
		"lines": ["วอร์มก่อนเล่นเวทด้วยนะ", "วันนี้เล่นกล้ามเนื้อส่วนไหน?", "วิ่งสามรอบแล้วยัง?"],
		"spots": [
			{"zone": "gym", "pos": Vector2(600, 330), "from": 420, "to": 1260, "days": "all"},
		],
	},
	"lungchai": {
		"name": "ลุงชัย", "kind": "npc", "dateable": "no",
		"skin": "#d9a97a", "hair": "#b8b8b8", "shirt": "#8a9a6a", "pants": "#4a4a4a",
		"hair_style": "short", "style": "elder", "accessory": "hat",
		"lines": ["เมื่อก่อนแถวนี้มีแต่ทุ่งนา", "เดินเล่นทุกวันร่างกายแข็งแรงนะ", "ดูนกตัวนั้นสิ"],
		"spots": [
			{"zone": "park", "pos": Vector2(400, 330), "from": 360, "to": 1080, "days": "all"},
		],
	},
	"fah": {
		"name": "ฟ้า", "kind": "npc", "dateable": "yes",
		"skin": "#f2c39b", "hair": "#1f1a16", "shirt": "#7ad0c0", "pants": "#3a4a5e",
		"hair_style": "ponytail", "style": "student", "accessory": "none",
		"lines": ["วิชานี้ยากจัง", "ฉันเรียนสถาปัตย์อยู่", "เย็นนี้ไปเดินสวนไหม"],
		"spots": [
			{"zone": "university", "pos": Vector2(600, 330), "from": 540, "to": 960, "days": "school"},
			{"zone": "park", "pos": Vector2(520, 330), "from": 960, "to": 1140, "days": "all"},
		],
	},
	"teacher": {
		"name": "ครูสมศรี", "kind": "npc", "dateable": "no",
		"skin": "#e8b98a", "hair": "#3a2a1a", "shirt": "#8a6ab0", "pants": "#4a3a5e",
		"hair_style": "bun", "style": "scholar", "accessory": "glasses",
		"lines": ["ตั้งใจเรียนนะจ๊ะ", "การบ้านส่งหรือยัง?", "วันนี้เราจะเรียนเรื่องใหม่"],
		"spots": [
			{"zone": "classroom", "pos": Vector2(380, 240), "from": 480, "to": 900, "days": "school"},
		],
	},
	"doctor": {
		"name": "หมออนันต์", "kind": "npc", "dateable": "no",
		"skin": "#d9a97a", "hair": "#2a2118", "shirt": "#f2f2f2", "pants": "#4a5a6b",
		"hair_style": "short", "style": "work", "accessory": "glasses",
		"lines": ["พักผ่อนให้เพียงพอนะ", "ออกกำลังกายสม่ำเสมอดีมาก", "มีอะไรให้ช่วยไหม"],
		"spots": [
			{"zone": "hospital", "pos": Vector2(700, 330), "from": 480, "to": 1020, "days": "school"},
		],
	},
	"dad": {
		"name": "พ่อสมชาย", "kind": "parent", "dateable": "no",
		"skin": "#d9a97a", "hair": "#2a2118", "shirt": "#5a7a5a", "pants": "#3a3a4a",
		"hair_style": "short", "style": "work", "accessory": "none",
		"lines": ["พ่อต้องไปทำงานแล้วนะ", "ตั้งใจเรียนนะลูก", "เย็นนี้กินข้าวด้วยกันไหม"],
		"spots": [
			{"zone": "home", "pos": Vector2(400, 320), "from": 360, "to": 510, "days": "all"},
			{"zone": "office", "pos": Vector2(820, 300), "from": 510, "to": 1020, "days": "school"},
			{"zone": "home", "pos": Vector2(400, 320), "from": 1020, "to": 1320, "days": "all"},
		],
	},
	"mom": {
		"name": "แม่สมหญิง", "kind": "parent", "dateable": "no",
		"skin": "#f2c39b", "hair": "#3a2418", "shirt": "#e88a9a", "pants": "#5a3a4a",
		"hair_style": "bun", "style": "home", "accessory": "apron",
		"lines": ["แม่ทำกับข้าวไว้ให้นะ", "อย่านอนดึกเกินไป", "การบ้านเสร็จหรือยังลูก"],
		"spots": [
			{"zone": "home", "pos": Vector2(600, 340), "from": 360, "to": 540, "days": "all"},
			{"zone": "hospital", "pos": Vector2(620, 330), "from": 540, "to": 900, "days": "school"},
			{"zone": "home", "pos": Vector2(600, 340), "from": 900, "to": 1320, "days": "all"},
		],
	},

	# ============================== ผู้คนเพิ่มเติม (v5) ==============================
	"ploy": {
		"name": "พลอย", "kind": "npc", "dateable": "yes",
		"skin": "#f2c39b", "hair": "#4a2a1e", "shirt": "#d86a8a", "pants": "#3a3048",
		"hair_style": "long", "style": "chic", "accessory": "earring",
		"lines": ["ดีไซน์ชุดใหม่เสร็จแล้วนะ", "ห้างนี้มีมุมถ่ายรูปสวย ๆ เยอะ", "ชอบสีเอิร์ธโทนเหมือนกันไหม"],
		"spots": [
			{"zone": "mall", "pos": Vector2(620, 340), "from": 540, "to": 1020, "days": "school"},
			{"zone": "cafe", "pos": Vector2(600, 340), "from": 1020, "to": 1140, "days": "all"},
		],
	},
	"tee": {
		"name": "ที", "kind": "npc", "dateable": "yes",
		"skin": "#e8b98a", "hair": "#1f1a16", "shirt": "#5a8ac0", "pants": "#2a3040",
		"hair_style": "short", "style": "work", "accessory": "glasses",
		"lines": ["โค้ดชุดนี้เพิ่งผ่านเทสต์", "กาแฟคือเชื้อเพลิงของโปรแกรมเมอร์", "อยากลองเขียนเกมบ้างไหม"],
		"spots": [
			{"zone": "office", "pos": Vector2(350, 250), "from": 540, "to": 1020, "days": "school"},
			{"zone": "cafe", "pos": Vector2(540, 330), "from": 1080, "to": 1260, "days": "all"},
		],
	},
	"jane": {
		"name": "เจน", "kind": "npc", "dateable": "yes",
		"skin": "#f2c39b", "hair": "#2a2118", "shirt": "#6ac0b8", "pants": "#e8eef0",
		"hair_style": "ponytail", "style": "work", "accessory": "badge",
		"lines": ["วันนี้คนไข้เยอะมาก", "ล้างมือบ่อย ๆ นะ", "พักผ่อนให้พอร่างกายจะได้แข็งแรง"],
		"spots": [
			{"zone": "hospital", "pos": Vector2(560, 330), "from": 420, "to": 900, "days": "school"},
			{"zone": "park", "pos": Vector2(420, 420), "from": 960, "to": 1080, "days": "all"},
		],
	},
	"arn": {
		"name": "อาร์น", "kind": "npc", "dateable": "yes",
		"skin": "#d9a97a", "hair": "#2a2118", "shirt": "#f2f2f2", "pants": "#4a4038",
		"hair_style": "short", "style": "chef", "accessory": "chef_hat",
		"lines": ["ซุปวันนี้หอมมาก", "อยากลองทำขนมปังไหม", "ครัวคือที่ที่ฉันมีความสุขที่สุด"],
		"spots": [
			{"zone": "cafe", "pos": Vector2(760, 250), "from": 360, "to": 840, "days": "school"},
			{"zone": "store", "pos": Vector2(620, 340), "from": 900, "to": 1020, "days": "all"},
		],
	},
	"nok": {
		"name": "นก", "kind": "npc", "dateable": "no",
		"skin": "#e8b98a", "hair": "#3a2418", "shirt": "#9a8ac0", "pants": "#4a4050",
		"hair_style": "bun", "style": "scholar", "accessory": "glasses",
		"lines": ["หนังสือเล่มนี้สนุกมากเลย", "ห้องสมุดเงียบ ๆ คือสวรรค์", "ยืมหนังสือไปอ่านได้นะ"],
		"spots": [
			{"zone": "university", "pos": Vector2(700, 330), "from": 480, "to": 960, "days": "school"},
			{"zone": "park", "pos": Vector2(540, 380), "from": 990, "to": 1140, "days": "all"},
		],
	},
	"banker": {
		"name": "แบงค์", "kind": "npc", "dateable": "yes",
		"skin": "#d9a97a", "hair": "#2a2118", "shirt": "#e8e8f0", "pants": "#3a4050",
		"hair_style": "short", "style": "formal", "accessory": "tie",
		"lines": ["ออมเงินตั้งแต่วันนี้ดีกว่านะ", "ดอกเบี้ยก็นับเป็นรายได้เหมือนกัน", "วันนี้ตลาดหุ้นเงียบจัง"],
		"spots": [
			{"zone": "bank", "pos": Vector2(600, 330), "from": 540, "to": 1020, "days": "school"},
			{"zone": "bar", "pos": Vector2(700, 330), "from": 1140, "to": 1320, "days": "all"},
		],
	},
	"wan": {
		"name": "หวาน", "kind": "npc", "dateable": "yes",
		"skin": "#f2c39b", "hair": "#5a3a2a", "shirt": "#e8a0b8", "pants": "#5a4a5a",
		"hair_style": "long", "style": "floral", "accessory": "headband",
		"lines": ["ดอกไม้ช่อนี้เพิ่งตัดมาเช้านี้", "กลิ่นดอกไม้ทำให้ใจสงบนะ", "เลือกดอกไม้ให้คนพิเศษหรือยัง"],
		"spots": [
			{"zone": "park", "pos": Vector2(660, 400), "from": 420, "to": 900, "days": "all"},
			{"zone": "downtown", "pos": Vector2(600, 470), "from": 930, "to": 1080, "days": "all"},
		],
	},
	"grandma": {
		"name": "ย่าใหญ่", "kind": "npc", "dateable": "no",
		"skin": "#e0b098", "hair": "#d8d8d8", "shirt": "#b08a9a", "pants": "#5a4a4a",
		"hair_style": "bun", "style": "elder", "accessory": "shawl",
		"lines": ["ย่าเดินออกกำลังกายทุกเช้าเลยนะ", "อาหารบ้าน ๆ นี่แหละอร่อยที่สุด", "เด็ก ๆ สมัยนี้รีบกันจัง"],
		"spots": [
			{"zone": "park", "pos": Vector2(300, 380), "from": 360, "to": 600, "days": "all"},
			{"zone": "home_street", "pos": Vector2(300, 470), "from": 960, "to": 1080, "days": "all"},
		],
	},
	"khao": {
		"name": "น้องข้าว", "kind": "npc", "dateable": "no",
		"skin": "#f2c39b", "hair": "#2a2118", "shirt": "#f2d05a", "pants": "#4a5a8a",
		"hair_style": "messy", "style": "child", "accessory": "none",
		"lines": ["พี่ ๆ เล่นอะไรกันเหรอ", "วันนี้ครูให้ดาวด้วยแหละ", "ขอเล่นด้วยคนได้ไหม"],
		"spots": [
			{"zone": "classroom", "pos": Vector2(700, 370), "from": 480, "to": 900, "days": "school"},
			{"zone": "home_street", "pos": Vector2(520, 460), "from": 960, "to": 1140, "days": "all"},
			{"zone": "park", "pos": Vector2(520, 480), "from": 900, "to": 1020, "days": "weekend"},
		],
	},
	"palee": {
		"name": "ป้าลี", "kind": "npc", "dateable": "no",
		"skin": "#e0a98a", "hair": "#3a2a1a", "shirt": "#e08a5a", "pants": "#5a4030",
		"hair_style": "bun", "style": "vendor", "accessory": "apron",
		"lines": ["ผักผลไม้สด ๆ จากสวนเลยนะ", "ลองชิมมะม่วงหน่อยไหม", "ขายดีจนแทบไม่มีเวลานั่ง"],
		"spots": [
			{"zone": "downtown", "pos": Vector2(430, 490), "from": 480, "to": 1080, "days": "all"},
		],
	},
	"lungdoo": {
		"name": "ลุงดนตรี", "kind": "npc", "dateable": "no",
		"skin": "#d9a97a", "hair": "#c8c8c8", "shirt": "#6a7a9a", "pants": "#3a3a4a",
		"hair_style": "long", "style": "elder", "accessory": "hat",
		"lines": ["เสียงกีตาร์นี้เพราะไหม", "ดนตรีทำให้คนเข้าใจกันมากขึ้น", "กลางคืนฉันเล่นที่บาร์นะ"],
		"spots": [
			{"zone": "park", "pos": Vector2(560, 470), "from": 1020, "to": 1200, "days": "all"},
			{"zone": "bar", "pos": Vector2(420, 330), "from": 1200, "to": 1380, "days": "all"},
		],
	},
	"morkae": {
		"name": "หมอแก้ว", "kind": "npc", "dateable": "yes",
		"skin": "#f2c39b", "hair": "#3a2418", "shirt": "#8ac8b8", "pants": "#e8f0ee",
		"hair_style": "long", "style": "vet", "accessory": "badge",
		"lines": ["แมวที่บ้านฉันก็ดื้อเหมือนกัน", "สัตว์เลี้ยงต้องการความรักมากนะ", "พาสัตว์มาให้ตรวจได้ตลอด"],
		"spots": [
			{"zone": "hospital", "pos": Vector2(400, 330), "from": 540, "to": 960, "days": "school"},
			{"zone": "park", "pos": Vector2(700, 380), "from": 990, "to": 1110, "days": "all"},
		],
	},
	"coach": {
		"name": "โค้ชอาร์ท", "kind": "npc", "dateable": "no",
		"skin": "#c98f62", "hair": "#1f1a16", "shirt": "#e05a4a", "pants": "#2a3444",
		"hair_style": "short", "style": "sport", "accessory": "cap",
		"lines": ["วอร์มก่อนยกเวทดัวยนะ", "วันนี้วิ่งกี่รอบแล้ว?", "ออกกำลังกายแล้วกินให้พอด้วย"],
		"spots": [
			{"zone": "gym", "pos": Vector2(380, 330), "from": 360, "to": 1080, "days": "all"},
		],
	},
	"nana": {
		"name": "นานา", "kind": "npc", "dateable": "yes",
		"skin": "#f2c39b", "hair": "#4a2a3a", "shirt": "#b09ad8", "pants": "#3a3a50",
		"hair_style": "bob", "style": "student", "accessory": "headband",
		"lines": ["สอบใกล้เข้ามาแล้ว เครียดจัง", "ไปนั่งคาเฟ่หลังเลิกเรียนกันไหม", "ฉันกำลังหัดวาดรูปอยู่"],
		"spots": [
			{"zone": "university", "pos": Vector2(480, 330), "from": 480, "to": 900, "days": "school"},
			{"zone": "cafe", "pos": Vector2(480, 380), "from": 930, "to": 1080, "days": "all"},
		],
	},
	"taew": {
		"name": "แต๋ว", "kind": "npc", "dateable": "yes",
		"skin": "#e8b98a", "hair": "#2a1a16", "shirt": "#f2a0c0", "pants": "#3a3048",
		"hair_style": "ponytail", "style": "chic", "accessory": "glasses",
		"lines": ["我第一次มาเมืองนี้ น่ารักจัง", "กาแฟที่นี่อร่อยกว่าในเมืองใหญ่", "ขอถามหน่อย สถานีรถเมล์ไปทางไหน"],
		"spots": [
			{"zone": "downtown", "pos": Vector2(240, 470), "from": 600, "to": 1080, "days": "weekend"},
			{"zone": "park", "pos": Vector2(620, 470), "from": 600, "to": 960, "days": "weekend"},
		],
	},
	"sorn": {
		"name": "สอน", "kind": "npc", "dateable": "no",
		"skin": "#c98f62", "hair": "#3a2a1a", "shirt": "#7a9a5a", "pants": "#4a4030",
		"hair_style": "short", "style": "gardener", "accessory": "hat",
		"lines": ["ต้นไม้ต้นนี้ฉันปลูกเองนะ", "รดน้ำตอนเช้าดีที่สุด", "ธรรมชาติใจดีกับคนใจเย็น"],
		"spots": [
			{"zone": "park", "pos": Vector2(230, 450), "from": 360, "to": 900, "days": "all"},
			{"zone": "home_street", "pos": Vector2(760, 470), "from": 930, "to": 1050, "days": "all"},
			{"zone": "backyard", "pos": Vector2(430, 445), "from": 960, "to": 1080, "days": "all"},
		],
	},
}

## ------------------------------------------------------------
##  ตัวช่วย
## ------------------------------------------------------------
static func zone(id: String) -> Dictionary:
	if ZONES.has(id):
		return ZONES[id]
	return ZONES["home"]


static func zone_name(id: String) -> String:
	return String(zone(id).get("name", id))


static func is_outdoor(id: String) -> bool:
	return bool(zone(id).get("outdoor", false))


static func spawn_of(id: String) -> Vector2:
	return zone(id).get("spawn", Vector2(480, 430))


## NPC ที่อยู่ในโซนนี้ตามเวลา/วัน (วัน 1-5 = เรียน/ทำงาน, 6-7 = หยุด)
static func npcs_for(zone_id: String, time_min: int, weekday: int) -> Array:
	var out: Array = []
	var is_school := weekday <= 5
	for npc_id in NPCS.keys():
		var npc: Dictionary = NPCS[npc_id]
		var spots: Array = npc.get("spots", [])
		for spot in spots:
			if String(spot.get("zone", "")) != zone_id:
				continue
			var days := String(spot.get("days", "all"))
			if days == "school" and not is_school:
				continue
			if days == "weekend" and is_school:
				continue
			var from := int(spot.get("from", 0))
			var to := int(spot.get("to", 1440))
			if time_min < from or time_min >= to:
				continue
			var entry := npc.duplicate(true)
			entry["id"] = String(npc_id)
			entry["pos"] = spot.get("pos", Vector2(480, 400))
			out.append(entry)
			break
	return out


## ประตูภายในห้อง: กลับออกไปข้างนอกอัตโนมัติ
static func interior_door(zone_id: String) -> Dictionary:
	var z := zone(zone_id)
	if z.has("door_zone"):
		var door_pos := Vector2(100, 500)
		for p in z.get("props", []):
			if String(p.get("type", "")) == "door_mat":
				door_pos = p.get("pos", door_pos)
				break
		return {
			"pos": door_pos,
			"zone": String(z["door_zone"]),
			"spawn": z.get("door_spawn", Vector2(480, 420)),
			"label": "ออกไปข้างนอก",
		}
	return {}


## ตรวจความถูกต้องของข้อมูล (ใช้ในเทสต์)
static func validate() -> Array[String]:
	var errors: Array[String] = []
	for zid in ZONES.keys():
		var z: Dictionary = ZONES[zid]
		if not z.has("spawn"):
			errors.append("%s: ไม่มี spawn" % zid)
		var exits: Array = z.get("exits", [])
		for e in exits:
			if not ZONES.has(String(e.get("zone", ""))):
				errors.append("%s: exit ไปโซน %s ไม่มีจริง" % [zid, e.get("zone", "?")])
		var doors: Array = z.get("doors", [])
		for d in doors:
			if not ZONES.has(String(d.get("zone", ""))):
				errors.append("%s: door ไปโซน %s ไม่มีจริง" % [zid, d.get("zone", "?")])
		# เช็กว่ามีทางออกจริง
		var has_out := not exits.is_empty() or not doors.is_empty() or z.has("door_zone")
		if zid != "park" and not has_out:
			errors.append("%s: ไม่มีทางออก" % zid)
		if z.has("door_zone") and not ZONES.has(String(z["door_zone"])):
			errors.append("%s: door_zone %s ไม่มีจริง" % [zid, z["door_zone"]])
		for p in z.get("props", []):
			if not p.has("type") or not p.has("pos"):
				errors.append("%s: prop ไม่สมบูรณ์" % zid)
	for npc_id in NPCS.keys():
		var npc: Dictionary = NPCS[npc_id]
		for spot in npc.get("spots", []):
			if not ZONES.has(String(spot.get("zone", ""))):
				errors.append("NPC %s: ไปโซน %s ที่ไม่มีจริง" % [npc_id, spot.get("zone", "?")])
	return errors
