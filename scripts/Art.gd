class_name Art
## Art.gd — วาดกราฟิกพิกเซลทั้งหมดจากโค้ด (ไม่มีไฟล์รูป)
## ตัวละครใช้ ASCII art, เฟอร์นิเจอร์วาดด้วยสี่เหลี่ยม

const HERO_PALETTE := {
	"h": Color("#3a2a1a"), # ผม
	"s": Color("#f2c39b"), # ผิว
	"e": Color("#14141c"), # ตา
	"m": Color("#b0604a"), # ปาก
	"b": Color("#4aa3ff"), # เสื้อ
	"p": Color("#2e3a59"), # กางเกง
	"k": Color("#14141c"), # รองเท้า
}

# สีของคนรัก (เสื้อชมพู) — ใช้ ASCII ตัวเดียวกับพระเอก
const PARTNER_PALETTE := {
	"h": Color("#2e2016"),
	"s": Color("#f2c39b"),
	"e": Color("#14141c"),
	"m": Color("#c0604a"),
	"b": Color("#e86fa0"),
	"p": Color("#5a3a5e"),
	"k": Color("#14141c"),
}

# ---------- ชุดแต่ละชุด (สีเสื้อ/กางเกง/รองเท้า) ----------
# id ต้องตรงกับ OUTFITS ใน GameState.gd
const OUTFIT_PALETTES := {
	"casual": HERO_PALETTE,
	"school": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#f2f2f2"), "p": Color("#23304f"), "k": Color("#14141c"),
	},
	"sleep": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#9aa7c7"), "p": Color("#4a5a8a"), "k": Color("#6b6f80"),
	},
	"sport": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#2fbf71"), "p": Color("#1f2430"), "k": Color("#e8e8ee"),
	},
	"work": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#e8e8ee"), "p": Color("#232a3a"), "k": Color("#14141c"),
	},
	"party": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#a05ad0"), "p": Color("#1b1e28"), "k": Color("#14141c"),
	},
	"luxury": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#e0b64a"), "p": Color("#1b1e28"), "k": Color("#14141c"),
	},
	"cozy": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#e8cf9a"), "p": Color("#8a5a3a"), "k": Color("#6b4a32"),
	},
	"raincoat": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#f2d05a"), "p": Color("#2e3a59"), "k": Color("#3a3a44"),
	},
	"winter": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#6a8ab0"), "p": Color("#2e3a59"), "k": Color("#3a3a44"),
	},
	"thai": {
		"h": Color("#2a1a16"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#e0b64a"), "p": Color("#7a2e3a"), "k": Color("#b08a4a"),
	},
	"heirloom_blue": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#a8c8e8"), "p": Color("#8aa8c8"), "k": Color("#c8d8e8"),
	},
	"heirloom_rose": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#e8b0c0"), "p": Color("#c890a0"), "k": Color("#f0d0d8"),
	},
	"heirloom_green": {
		"h": Color("#3a2a1a"), "s": Color("#f2c39b"), "e": Color("#14141c"),
		"m": Color("#b0604a"), "b": Color("#b0d0a0"), "p": Color("#8aa878"), "k": Color("#d0e0c0"),
	},
}

# ตัวละคร 12x18 พิกเซล — "." โปร่งใส, ตัวอักษรอื่นคือสีใน OUTFIT_PALETTES / PARTNER_PALETTE
const HERO_ROWS := [
	"....hhhh....",
	"...hhhhhh...",
	"..hhsssshh..",
	"..hssssssh..",
	"..sesssses..",
	"..ssssssss..",
	"...ssmmss...",
	"....ssss....",
	"..bbbbbbbb..",
	".sbbbbbbbbs.",
	".sbbbbbbbbs.",
	".sbbbbbbbbs.",
	"..bbbbbbbb..",
	"..pppppppp..",
	"..ppp..ppp..",
	"..ppp..ppp..",
	"..kkk..kkk..",
	"..kkk..kkk..",
]


## สร้าง texture ทั้งหมด คืนค่าเป็น Dictionary {ชื่อ: Texture2D}
static func build() -> Dictionary:
	var textures := {}
	for id in OUTFIT_PALETTES:
		textures["hero_" + String(id)] = ascii_texture(HERO_ROWS, OUTFIT_PALETTES[id])
	textures["hero"] = textures["hero_casual"] # เผื่อโค้ดเก่าเรียกใช้
	textures["partner"] = ascii_texture(HERO_ROWS, PARTNER_PALETTE)
	textures["shadow"] = shadow()
	textures["bed"] = bed()
	textures["desk"] = desk()
	textures["bookshelf"] = bookshelf()
	textures["fridge"] = fridge()
	textures["sofa"] = sofa()
	textures["plant"] = plant()
	textures["dumbbell"] = dumbbell()
	return textures


## แปลง ASCII art เป็น texture
static func ascii_texture(rows: Array, palette: Dictionary) -> ImageTexture:
	var height := rows.size()
	var width: int = (rows[0] as String).length()
	var img := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in height:
		var row: String = rows[y]
		assert(row.length() == width, "แถวที่ %d ยาวไม่เท่ากัน" % (y + 1))
		for x in width:
			var ch := row[x]
			if ch == ".":
				continue
			img.set_pixel(x, y, palette[ch])
	return ImageTexture.create_from_image(img)


static func _blank(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


## เงาใต้ตัวละคร (วงรีดำจาง)
static func shadow() -> ImageTexture:
	var w := 32
	var h := 12
	var img := _blank(w, h)
	var cx := (w - 1) / 2.0
	var cy := (h - 1) / 2.0
	for y in h:
		for x in w:
			var dx := (x - cx) / cx
			var dy := (y - cy) / cy
			var d := dx * dx + dy * dy
			if d <= 1.0:
				# ขอบนุ่มขึ้นเล็กน้อยตรงปลาย
				var alpha := 0.30 * (1.0 - 0.45 * d)
				img.set_pixel(x, y, Color(0, 0, 0, alpha))
	return ImageTexture.create_from_image(img)


static func _rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), color)


static func bed() -> ImageTexture:
	var img := _blank(44, 32)
	_rect(img, 2, 20, 40, 10, Color("#2a1d14")) # โครงเตียง
	_rect(img, 0, 17, 44, 7, Color("#6b4a2f")) # ขอบเตียง
	_rect(img, 3, 8, 38, 11, Color("#e8e3d8")) # ที่นอน
	_rect(img, 5, 9, 10, 8, Color("#ffffff")) # หมอน
	_rect(img, 19, 9, 20, 10, Color("#4a7bd0")) # ผ้าห่ม
	_rect(img, 19, 9, 20, 2, Color("#5f92e6"))
	_rect(img, 1, 27, 4, 5, Color("#6b4a2f")) # ขา
	_rect(img, 39, 27, 4, 5, Color("#6b4a2f"))
	return ImageTexture.create_from_image(img)


static func desk() -> ImageTexture:
	var img := _blank(38, 34)
	_rect(img, 0, 20, 38, 6, Color("#8a5a33")) # ท็อปโต๊ะ
	_rect(img, 2, 26, 4, 8, Color("#6b4526"))
	_rect(img, 32, 26, 4, 8, Color("#6b4526"))
	_rect(img, 9, 2, 20, 15, Color("#2a2d3a")) # จอ
	_rect(img, 11, 4, 16, 11, Color("#6fe3a1"))
	_rect(img, 17, 17, 4, 3, Color("#1b1e28"))
	return ImageTexture.create_from_image(img)


static func bookshelf() -> ImageTexture:
	var img := _blank(30, 48)
	_rect(img, 0, 0, 30, 48, Color("#6b4526"))
	_rect(img, 2, 2, 26, 44, Color("#3a2a1a"))
	var colors := [
		Color("#d05a5a"), Color("#5a8fd0"), Color("#e0c15a"),
		Color("#6fc07a"), Color("#b06fc0"),
	]
	for row in 4:
		var x := 4
		for i in 5:
			var w := 3 + ((row + i) % 2)
			var h := 6 + ((row * 2 + i) % 3)
			var c: Color = colors[(row + i) % colors.size()]
			_rect(img, x, 6 + row * 11 + (8 - h), w, h, c)
			x += w + 1
		_rect(img, 2, 4 + row * 11, 26, 2, Color("#6b4526"))
	return ImageTexture.create_from_image(img)


static func fridge() -> ImageTexture:
	var img := _blank(24, 42)
	_rect(img, 0, 0, 24, 42, Color("#b9c2cc"))
	_rect(img, 2, 2, 20, 17, Color("#dfe6ec"))
	_rect(img, 2, 21, 20, 19, Color("#dfe6ec"))
	_rect(img, 17, 8, 2, 7, Color("#7d8790"))
	_rect(img, 17, 26, 2, 7, Color("#7d8790"))
	_rect(img, 5, 5, 6, 6, Color("#8fd0e8"))
	return ImageTexture.create_from_image(img)


static func sofa() -> ImageTexture:
	var img := _blank(48, 30)
	_rect(img, 0, 6, 48, 18, Color("#8c3f3f"))
	_rect(img, 3, 12, 42, 10, Color("#a34d4d"))
	_rect(img, 3, 12, 42, 3, Color("#c25c5c"))
	_rect(img, 0, 8, 5, 16, Color("#8c3f3f"))
	_rect(img, 43, 8, 5, 16, Color("#8c3f3f"))
	_rect(img, 3, 25, 4, 5, Color("#3a2a1a"))
	_rect(img, 41, 25, 4, 5, Color("#3a2a1a"))
	return ImageTexture.create_from_image(img)


static func plant() -> ImageTexture:
	var img := _blank(20, 30)
	_rect(img, 7, 2, 6, 14, Color("#2f8f5b"))
	_rect(img, 2, 4, 6, 6, Color("#3fbf74"))
	_rect(img, 12, 6, 6, 6, Color("#3fbf74"))
	_rect(img, 0, 2, 4, 4, Color("#2f8f5b"))
	_rect(img, 14, 1, 5, 5, Color("#3fbf74"))
	_rect(img, 3, 16, 14, 12, Color("#b5713f"))
	_rect(img, 3, 16, 14, 3, Color("#8f562f"))
	return ImageTexture.create_from_image(img)


static func dumbbell() -> ImageTexture:
	var img := _blank(26, 12)
	_rect(img, 2, 2, 5, 8, Color("#9aa4b0"))
	_rect(img, 4, 4, 3, 4, Color("#7d8790"))
	_rect(img, 19, 2, 5, 8, Color("#9aa4b0"))
	_rect(img, 19, 4, 3, 4, Color("#7d8790"))
	_rect(img, 7, 5, 12, 2, Color("#5a6470"))
	return ImageTexture.create_from_image(img)
