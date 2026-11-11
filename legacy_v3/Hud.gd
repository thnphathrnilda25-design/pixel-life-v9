extends Control
## Hud.gd — แถบสถานะ + ปุ่มกิจกรรม + เมนูอาชีพ/ความรัก/ชีวิต + หน้าต่างเหตุการณ์
## สร้าง UI จากโค้ดทั้งหมด (ไม่มีไฟล์ scene ย่อย)

signal action_pressed(action: String)
signal restart_pressed
signal job_apply_requested(job_id: String)
signal job_quit_requested
signal date_requested
signal propose_requested
signal child_requested
signal breakup_requested
signal event_choice(index: int)
signal creation_confirmed(player_name: String, gender: String, wealth: int)
signal bank_deposit_requested
signal bank_withdraw_requested
signal loan_requested
signal repay_requested
signal insurance_requested
signal medicine_requested
signal doctor_requested
signal checkup_requested
signal outfit_buy_requested(outfit_id: String)
signal outfit_equip_requested(outfit_id: String)

const FONT_NAMES := ["Segoe UI", "Noto Sans Thai", "Leelawadee UI", "Tahoma"]
const BG_COLOR := Color("#12121a")
const BORDER_COLOR := Color("#2a2a3a")
const PANEL_BG := Color("#181b26")

const BAR_DEFS := [
	{"key": "health", "label": "สุขภาพ", "color": Color("#4ade80"), "y": 550.0},
	{"key": "happy", "label": "ความสุข", "color": Color("#fbbf24"), "y": 568.0},
	{"key": "energy", "label": "พลังงาน", "color": Color("#60a5fa"), "y": 586.0},
	{"key": "hunger", "label": "ความอิ่ม", "color": Color("#f472b6"), "y": 604.0},
	{"key": "stress", "label": "ความเครียด", "color": Color("#f87171"), "y": 622.0},
]

var date_label: Label
var money_label: Label
var footer_label: Label
var bars := {}
var buttons := {}
var button_labels := {}
var cost_labels := {}
var menu_buttons := {}

var active_toasts: Array[Control] = []
var game_over_layer: Control = null
var panel_layer: Control = null
var event_layer: Control = null
var creation_layer: Control = null
var creation_name := ""
var creation_gender := "ชาย"
var creation_wealth := 1
var restart_armed := false
var restart_button: Button = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_theme()
	_build()


func _setup_theme() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(FONT_NAMES)
	font.allow_system_fallback = true

	var hud_theme := Theme.new()
	hud_theme.default_font = font
	hud_theme.default_font_size = 14
	theme = hud_theme


# ============================================================
#  สร้างหน้าจอ
# ============================================================

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.position = Vector2(0, 520)
	bg.size = Vector2(480, 334)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var border := ColorRect.new()
	border.color = BORDER_COLOR
	border.position = Vector2(0, 520)
	border.size = Vector2(480, 2)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

	date_label = _make_label(Vector2(14, 526), Vector2(300, 20), 13, Color("#e8e8f0"))
	money_label = _make_label(Vector2(258, 523), Vector2(208, 24), 16, Color("#ffd166"))
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_build_bars()
	_build_actions()
	_build_menu()

	footer_label = _make_label(Vector2(14, 809), Vector2(452, 20), 10, Color("#8b93a7"))


func _make_label(pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _build_bars() -> void:
	for def in BAR_DEFS:
		var y: float = def["y"]
		var name_label := _make_label(Vector2(14, y - 6), Vector2(70, 18), 11, Color("#9aa0b4"))
		name_label.text = def["label"]

		var bar := ProgressBar.new()
		bar.position = Vector2(88, y)
		bar.size = Vector2(334, 8)
		bar.max_value = 100
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = Color("#232735")
		bg_style.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background", bg_style)

		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = def["color"]
		fill_style.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill_style)

		add_child(bar)

		var value_label := _make_label(Vector2(428, y - 6), Vector2(44, 18), 11, Color("#c8ccdc"))
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		bars[def["key"]] = {"bar": bar, "value": value_label}


func _build_actions() -> void:
	var keys: Array = Game.ACTIONS.keys()
	var btn_w := 144.0
	var btn_h := 54.0
	var gap_x := 8.0
	var start_y := 640.0
	var row_gap := 6.0

	for index in keys.size():
		var key: String = keys[index]
		var col := index % 3
		var row := index / 3
		var x := 12.0 + col * (btn_w + gap_x)
		var y := start_y + row * (btn_h + row_gap)

		var btn := Button.new()
		btn.position = Vector2(x, y)
		btn.size = Vector2(btn_w, btn_h)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_action_button.bind(key))
		add_child(btn)
		buttons[key] = btn

		var name_label := Label.new()
		name_label.text = Game.action_label(key)
		name_label.position = Vector2(0, 9)
		name_label.size = Vector2(btn_w, 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(name_label)
		button_labels[key] = name_label

		var cost := Label.new()
		cost.position = Vector2(0, 31)
		cost.size = Vector2(btn_w, 16)
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost.add_theme_font_size_override("font_size", 10)
		cost.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(cost)
		cost_labels[key] = cost


func _build_menu() -> void:
	var defs := [
		{"id": "jobs", "text": "อาชีพ"},
		{"id": "love", "text": "ความรัก"},
		{"id": "life", "text": "ชีวิต"},
		{"id": "finance", "text": "เงิน"},
		{"id": "health", "text": "สุขภาพ"},
		{"id": "wardrobe", "text": "แต่งตัว"},
	]
	var w := 72.0
	var h := 42.0
	var gap := 4.0
	var y := 762.0

	for i in defs.size():
		var def: Dictionary = defs[i]
		var btn := Button.new()
		btn.text = def["text"]
		btn.position = Vector2(12.0 + i * (w + gap), y)
		btn.size = Vector2(w, h)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", Color("#cfd6e6"))
		btn.pressed.connect(_on_menu_button.bind(def["id"]))
		add_child(btn)
		menu_buttons[def["id"]] = btn
		_style_menu_button(btn)


func _on_action_button(key: String) -> void:
	action_pressed.emit(key)


func _on_menu_button(menu_id: String) -> void:
	match menu_id:
		"jobs":
			open_jobs()
		"love":
			open_love()
		"life":
			open_life()
		"finance":
			open_finance()
		"health":
			open_health()
		"wardrobe":
			open_wardrobe()


# ============================================================
#  อัปเดตข้อมูล
# ============================================================

func refresh() -> void:
	date_label.text = Game.date_label()
	money_label.text = "฿" + Game.fmt_money(Game.money)
	money_label.add_theme_color_override(
		"font_color", Color("#ff8a8a") if Game.money < 0 else Color("#ffd166")
	)

	for key in bars:
		var value: int = int(Game.get(key))
		bars[key]["bar"].value = value
		bars[key]["value"].text = str(value)

	for key in buttons:
		var blocked: bool = Game.can_check(key) != ""
		_style_action(buttons[key], Game.ACTIONS[key]["color"], blocked)
		button_labels[key].text = Game.action_label(key)
		cost_labels[key].text = Game.action_cost_text(key)
		cost_labels[key].modulate.a = 0.35 if blocked else 0.8

	footer_label.text = Game.income_text()


func _style_action(btn: Button, color: Color, blocked: bool) -> void:
	var base: Color = Color("#2b2f3d") if blocked else color

	var normal := StyleBoxFlat.new()
	normal.bg_color = base
	normal.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = base.lightened(0.12)
	hover.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = base.darkened(0.22)
	pressed.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled := StyleBoxFlat.new()
	disabled.bg_color = base
	disabled.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.modulate.a = 0.55 if blocked else 1.0


func _style_menu_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#232838")
	normal.set_corner_radius_all(8)
	normal.border_color = Color("#38405a")
	normal.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#2d3448")
	hover.set_corner_radius_all(8)
	hover.border_color = Color("#4a5474")
	hover.set_border_width_all(1)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color("#1b1f2c")
	pressed.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("pressed", pressed)


# ============================================================
#  ข้อความเด้ง / จอจบเกม
# ============================================================

func toast(text: String, color := Color.WHITE) -> void:
	for old in active_toasts:
		if is_instance_valid(old):
			old.queue_free()
	active_toasts.clear()

	var holder := Panel.new()
	holder.position = Vector2(24, 166)
	holder.size = Vector2(432, 56)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.05, 0.82)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(4)
	holder.add_theme_stylebox_override("panel", style)
	add_child(holder)

	var label := Label.new()
	label.text = text
	label.position = Vector2.ZERO
	label.size = holder.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(label)
	active_toasts.append(holder)

	var tween := create_tween()
	tween.tween_property(holder, "position:y", holder.position.y - 18.0, 2.2)
	tween.parallel().tween_property(holder, "modulate:a", 0.0, 0.6).set_delay(1.6)
	tween.chain().tween_callback(holder.queue_free)


func show_game_over() -> void:
	if game_over_layer != null:
		return
	if panel_layer != null:
		close_panel()

	game_over_layer = Control.new()
	game_over_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(game_over_layer)
	game_over_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := _game_over_label("จบชีวิต", 34, Color.WHITE, 250)
	title.position.y = 250

	var cause := "จากไปในวัย %d" % Game.age
	if Game.death_cause != "":
		cause = Game.death_cause
	var subtitle := _game_over_label(cause, 15, Color("#c8ccdc"), 296)
	subtitle.position.y = 296

	var summary := "อาชีพ: %s\nคู่ครอง: %s • ลูก %d คน\nเงินเหลือ ฿%s" % [
		Game.job_title(), Game.partner_status(), Game.children.size(),
		Game.fmt_money(Game.money),
	]
	var line := _game_over_label(summary, 14, Color("#e8e8f0"), 336)
	line.position.y = 336
	line.size = Vector2(480, 80)

	var btn := Button.new()
	btn.text = "เริ่มชีวิตใหม่"
	btn.position = Vector2(130, 450)
	btn.size = Vector2(220, 56)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2f6fd0")
	style.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color("#3d80e8")
	btn.add_theme_stylebox_override("hover", hover)
	btn.pressed.connect(func() -> void: restart_pressed.emit())
	game_over_layer.add_child(btn)


func _game_over_label(text: String, font_size: int, color: Color, y: float) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, y)
	label.size = Vector2(480, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_layer.add_child(label)
	return label


func hide_game_over() -> void:
	if game_over_layer != null:
		game_over_layer.queue_free()
		game_over_layer = null


# ============================================================
#  สร้างตัวละคร (เกิดใหม่)
# ============================================================

func show_creation() -> void:
	creation_gender = Game.gender
	creation_wealth = Game.family_wealth
	creation_name = Game.player_name
	if creation_name == "":
		creation_name = Game.suggest_name(creation_gender)
	_build_creation()


func _build_creation() -> void:
	if creation_layer != null:
		creation_layer.queue_free()
		creation_layer = null

	creation_layer = Control.new()
	creation_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(creation_layer)
	creation_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.9)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	creation_layer.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := Panel.new()
	box.position = Vector2(18, 64)
	box.size = Vector2(444, 726)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.set_corner_radius_all(14)
	style.border_color = Color("#3a4260")
	style.set_border_width_all(2)
	box.add_theme_stylebox_override("panel", style)
	creation_layer.add_child(box)

	var title := _child_label(box, "สร้างชีวิตใหม่", Vector2(24, 14), Vector2(300, 34), 24, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_child_label(
		box, "เลือกชื่อ เพศ และฐานะครอบครัว แล้วเริ่มชีวิตตั้งแต่วัยแรกเกิด",
		Vector2(24, 48), Vector2(392, 26), 11, Color("#9aa0b4")
	)

	_child_label(box, "ชื่อ", Vector2(24, 82), Vector2(100, 18), 11, Color("#9aa0b4"))
	_child_label(box, creation_name, Vector2(24, 102), Vector2(260, 34), 21, Color("#ffd166"))
	_creation_button(box, "สุ่มชื่อใหม่", Vector2(300, 102), Vector2(116, 36), false, _on_reroll_name)

	_child_label(box, "เพศ", Vector2(24, 150), Vector2(100, 18), 11, Color("#9aa0b4"))
	_creation_button(
		box, "ชาย", Vector2(24, 170), Vector2(150, 40),
		creation_gender == "ชาย", func() -> void: _on_pick_gender("ชาย")
	)
	_creation_button(
		box, "หญิง", Vector2(190, 170), Vector2(150, 40),
		creation_gender == "หญิง", func() -> void: _on_pick_gender("หญิง")
	)

	_child_label(box, "ฐานะครอบครัว", Vector2(24, 226), Vector2(200, 18), 11, Color("#9aa0b4"))
	var descriptions := [
		"พ่อแม่ลำบาก • เงินใช้ปีละ ฿%s • เงินก้อนตอน 18 ฿%s" % [
			Game.fmt_money(int(Game.WEALTH_ALLOWANCE[0])),
			Game.fmt_money(int(Game.WEALTH_GIFT[0])),
		],
		"อยู่ได้สบาย ๆ • เงินใช้ปีละ ฿%s • เงินก้อนตอน 18 ฿%s" % [
			Game.fmt_money(int(Game.WEALTH_ALLOWANCE[1])),
			Game.fmt_money(int(Game.WEALTH_GIFT[1])),
		],
		"พ่อแม่รวย • เงินใช้ปีละ ฿%s • เงินก้อนตอน 18 ฿%s" % [
			Game.fmt_money(int(Game.WEALTH_ALLOWANCE[2])),
			Game.fmt_money(int(Game.WEALTH_GIFT[2])),
		],
	]
	for w in 3:
		_creation_card(box, w, String(Game.WEALTH_NAMES[w]), descriptions[w], 252 + w * 74)

	_creation_button(
		box, "เริ่มชีวิต", Vector2(24, 486), Vector2(392, 54), true, _on_creation_start
	)
	_child_label(
		box,
		"วัยเด็ก (0–17 ปี) 1 การกระทำ = 1 ปี • วัยผู้ใหญ่ (18+) 1 สัปดาห์",
		Vector2(24, 552), Vector2(392, 40), 10, Color("#8b93a7")
	)
	_child_label(
		box,
		"พ่อแม่จะเลี้ยงดูจนอายุ 18 • ถ้าสุขภาพหมดเกมจบ",
		Vector2(24, 584), Vector2(392, 24), 10, Color("#8b93a7")
	)


func _child_label(
	parent: Control, text: String, pos: Vector2, size: Vector2, font_size: int, color: Color
) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _creation_button(
	parent: Control, text: String, pos: Vector2, size: Vector2,
	highlight: bool, cb: Callable
) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = size
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#2f6fd0") if highlight else Color("#232838")
	normal.set_corner_radius_all(8)
	normal.border_color = Color("#6fa8ff") if highlight else Color("#38405a")
	normal.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.12)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.18)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.pressed.connect(cb)
	parent.add_child(btn)
	return btn


func _creation_card(
	parent: Control, wealth: int, title: String, desc: String, y: float
) -> void:
	var selected := creation_wealth == wealth
	var btn := Button.new()
	btn.position = Vector2(24, y)
	btn.size = Vector2(392, 66)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func() -> void: _on_pick_wealth(wealth))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#1f2740") if selected else Color("#20242f")
	normal.set_corner_radius_all(10)
	normal.border_color = Color("#6fa8ff") if selected else Color("#313849")
	normal.set_border_width_all(2 if selected else 1)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.12)
	btn.add_theme_stylebox_override("pressed", pressed)

	var t := _child_label(
		btn, title, Vector2(16, 8), Vector2(340, 24), 14,
		Color("#9fd0ff") if selected else Color.WHITE
	)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var d := _child_label(btn, desc, Vector2(16, 32), Vector2(364, 28), 10, Color("#9aa0b4"))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(btn)


func _on_reroll_name() -> void:
	creation_name = Game.suggest_name(creation_gender)
	_build_creation()


func _on_pick_gender(g: String) -> void:
	creation_gender = g
	creation_name = Game.suggest_name(g)
	_build_creation()


func _on_pick_wealth(w: int) -> void:
	creation_wealth = w
	_build_creation()


func _on_creation_start() -> void:
	var n := creation_name
	var g := creation_gender
	var w := creation_wealth
	close_creation()
	creation_confirmed.emit(n, g, w)


func close_creation() -> void:
	if creation_layer != null:
		creation_layer.queue_free()
		creation_layer = null


# ============================================================
#  หน้าต่างเหตุการณ์ (เลือกตอบ)
# ============================================================

func show_event(ev: Dictionary) -> void:
	close_event()

	event_layer = Control.new()
	event_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(event_layer)
	event_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.75)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	event_layer.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var options: Array = ev.get("options", [])
	var box_h := 154.0 + options.size() * 58.0
	var box := Panel.new()
	box.position = Vector2(28, (854.0 - box_h) / 2.0)
	box.size = Vector2(424, box_h)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.set_corner_radius_all(14)
	style.border_color = Color("#3a4260")
	style.set_border_width_all(2)
	box.add_theme_stylebox_override("panel", style)
	event_layer.add_child(box)

	var head := Label.new()
	head.text = "เรื่องที่เกิดขึ้น"
	head.position = Vector2(20, 14)
	head.size = Vector2(384, 24)
	head.add_theme_font_size_override("font_size", 13)
	head.add_theme_color_override("font_color", Color("#9aa0b4"))
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)

	var text_label := Label.new()
	text_label.text = String(ev.get("text", ""))
	text_label.position = Vector2(20, 42)
	text_label.size = Vector2(384, 76)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 15)
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(text_label)

	for i in options.size():
		var opt: Dictionary = options[i]
		var cost := int(opt.get("cost", 0))
		var label := String(opt.get("label", "เลือก"))
		var poor := cost > Game.money
		if poor:
			label += " (เงินไม่พอ)"

		var btn := Button.new()
		btn.text = label
		btn.position = Vector2(20, 124 + i * 58)
		btn.size = Vector2(384, 48)
		btn.focus_mode = Control.FOCUS_NONE
		btn.disabled = poor
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
		var bstyle := StyleBoxFlat.new()
		bstyle.bg_color = Color("#2f6fd0") if not poor else Color("#2b2f3d")
		bstyle.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("normal", bstyle)
		var bhover := bstyle.duplicate()
		bhover.bg_color = Color("#3d80e8")
		btn.add_theme_stylebox_override("hover", bhover)
		var bpressed := bstyle.duplicate()
		bpressed.bg_color = Color("#24589f")
		btn.add_theme_stylebox_override("pressed", bpressed)
		var bdisabled := bstyle.duplicate()
		bdisabled.bg_color = Color("#222634")
		btn.add_theme_stylebox_override("disabled", bdisabled)
		btn.pressed.connect(_on_event_option.bind(i))
		box.add_child(btn)


func _on_event_option(index: int) -> void:
	close_event()
	event_choice.emit(index)


func close_event() -> void:
	if event_layer != null:
		event_layer.queue_free()
		event_layer = null


# ============================================================
#  แผงเมนู (อาชีพ / ความรัก / ชีวิต)
# ============================================================

func close_panel() -> void:
	if panel_layer != null:
		panel_layer.queue_free()
		panel_layer = null
	restart_armed = false
	restart_button = null


func _start_panel(title: String) -> VBoxContainer:
	close_panel()

	panel_layer = Control.new()
	panel_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel_layer)
	panel_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.82)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_layer.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := Panel.new()
	box.position = Vector2(20, 70)
	box.size = Vector2(440, 700)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.set_corner_radius_all(14)
	style.border_color = Color("#3a4260")
	style.set_border_width_all(2)
	box.add_theme_stylebox_override("panel", style)
	panel_layer.add_child(box)

	var head := Label.new()
	head.text = title
	head.position = Vector2(18, 12)
	head.size = Vector2(300, 34)
	head.add_theme_font_size_override("font_size", 19)
	head.add_theme_color_override("font_color", Color.WHITE)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)

	var close_btn := Button.new()
	close_btn.text = "ปิด"
	close_btn.position = Vector2(348, 12)
	close_btn.size = Vector2(74, 34)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_color_override("font_color", Color("#cfd6e6"))
	var cstyle := StyleBoxFlat.new()
	cstyle.bg_color = Color("#232838")
	cstyle.set_corner_radius_all(8)
	close_btn.add_theme_stylebox_override("normal", cstyle)
	close_btn.pressed.connect(close_panel)
	box.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16, 54)
	scroll.size = Vector2(408, 630)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(392, 0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)

	return body


func _section(body: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(0, 26)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("#ffd166"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(label)


func _info(body: VBoxContainer, title: String, sub: String) -> void:
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 1)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 14)
	t.add_theme_color_override("font_color", Color.WHITE)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(t)

	var s := Label.new()
	s.text = sub
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.add_theme_font_size_override("font_size", 11)
	s.add_theme_color_override("font_color", Color("#9aa0b4"))
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(s)

	body.add_child(holder)


func _panel_button(
	body: VBoxContainer, text: String, color: Color, disabled: bool, cb: Callable
) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 44)
	btn.disabled = disabled
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))

	var normal := StyleBoxFlat.new()
	normal.bg_color = color if not disabled else Color("#2b2f3d")
	normal.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled_style := normal.duplicate()
	disabled_style.bg_color = Color("#2b2f3d")
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.pressed.connect(cb)
	body.add_child(btn)
	return btn


# ---------- แผงอาชีพ ----------

func open_jobs() -> void:
	var body := _start_panel("อาชีพ")

	_section(body, "สถานะตอนนี้")
	if Game.is_child():
		_info(
			body, "ยังเรียนอยู่",
			"อายุ %d ปี • %s • สมัครงานได้เมื่ออายุ 18" % [Game.age, Game.education_title()]
		)
		var child_hint := Label.new()
		child_hint.text = "โตขึ้นอีก %d ปี ก็เริ่มทำงานได้แล้ว — ตอนนี้โฟกัสเรียนและใช้ชีวิตให้มีความสุข" % (18 - Game.age)
		child_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		child_hint.add_theme_font_size_override("font_size", 10)
		child_hint.add_theme_color_override("font_color", Color("#7f879b"))
		child_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(child_hint)
		return

	if Game.job_id == "":
		if Game.retired:
			_info(body, "เกษียณแล้ว", "มีเงินบำนาญรายเดือน • ทำงานเพิ่มไม่ได้")
		else:
			_info(body, "ว่างงาน", "ยังรับจ้างรายวันได้ ฿%s/สัปดาห์ (กดปุ่มทำงาน)" % Game.fmt_money(Game.DAILY_WAGE))
	else:
		_info(
			body,
			Game.job_title(),
			"ระดับ %d • ฿%s/สัปดาห์ • ประสิทธิภาพ %d%% • ทำงานมา %d สัปดาห์" % [
				Game.job_level, Game.fmt_money(Game.salary()),
				Game.performance, Game.job_weeks,
			]
		)
		_panel_button(
			body, "ลาออกจากงาน", Color("#7a3b3b"), false,
			func() -> void:
				close_panel()
				job_quit_requested.emit()
		)

	_section(body, "ตลาดงาน (สมัครแล้วเสียเวลา 1 สัปดาห์)")
	for job in Game.JOBS:
		_job_row(body, job)

	var hint := Label.new()
	hint.text = "งานที่ต้องใช้ความรู้สูงขึ้น จะได้เงินเดือนเยอะขึ้น — เรียนเพิ่มเพื่อปลดล็อก"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color("#7f879b"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(hint)


func _job_row(body: VBoxContainer, job: Dictionary) -> void:
	var reason := Game.apply_block_reason(String(job["id"]))
	var chance := int(round(Game.apply_chance(String(job["id"])) * 100.0))

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 50)
	row.add_theme_constant_override("separation", 8)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)

	var name_label := Label.new()
	name_label.text = String(job["title"])
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color("#e8e8f0"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_label)

	var sub := Label.new()
	if reason != "":
		sub.text = reason
		sub.add_theme_color_override("font_color", Color("#ff9a9a"))
	else:
		sub.text = "฿%s/สัปดาห์ • ใช้ความรู้ %d • โอกาส %d%%" % [
			Game.fmt_money(int(job["salary"])), int(job["edu"]), chance
		]
		sub.add_theme_color_override("font_color", Color("#8b93a7"))
	sub.add_theme_font_size_override("font_size", 10)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(sub)
	row.add_child(info)

	var btn := Button.new()
	btn.text = "สมัคร"
	btn.custom_minimum_size = Vector2(76, 40)
	btn.disabled = reason != ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.3))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#2f6fd0") if reason == "" else Color("#2b2f3d")
	normal.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("#3d80e8")
	btn.add_theme_stylebox_override("hover", hover)
	var disabled_style := normal.duplicate()
	disabled_style.bg_color = Color("#222634")
	btn.add_theme_stylebox_override("disabled", disabled_style)
	btn.pressed.connect(_on_job_apply.bind(String(job["id"])))
	row.add_child(btn)

	body.add_child(row)


func _on_job_apply(id: String) -> void:
	close_panel()
	job_apply_requested.emit(id)


# ---------- แผงความรัก ----------

func open_love() -> void:
	var body := _start_panel("ความรัก")

	_section(body, "สถานะ")
	if Game.is_child():
		_info(
			body, "ยังเด็ก",
			"อายุ %d ปี • ยังไม่ถึงวัยออกเดท (18+) • ใช้เวลากับเพื่อนและครอบครัวก่อน" % Game.age
		)
		return

	if Game.partner_name == "":
		_info(body, "โสด", "ออกเดทเพื่อทำความรู้จักใครสักคน — โอกาสขึ้นกับความสุขและสังคม")
	else:
		_info(
			body, Game.partner_status(),
			"ความรัก %d/100 • %s" % [
				Game.partner_love,
				"แต่งงานแล้ว" if Game.married else "ยังไม่แต่งงาน",
			]
		)

	_section(body, "ทำอะไรดี")
	_panel_button(
		body, "ออกเดท (฿300)", Color("#d04f7a"), Game.money < 300,
		func() -> void:
			close_panel()
			date_requested.emit()
	)
	_panel_button(
		body, "ขอแต่งงาน (฿5,000)", Color("#a05ad0"),
		Game.partner_name == "" or Game.married or Game.partner_love < 70 or Game.money < 5000,
		func() -> void:
			close_panel()
			propose_requested.emit()
	)
	_panel_button(
		body, "มีลูก (฿3,000)", Color("#2f9e6b"),
		not Game.married or Game.age > 45 or Game.children.size() >= 3 or Game.money < 3000,
		func() -> void:
			close_panel()
			child_requested.emit()
	)
	if Game.partner_name != "":
		_panel_button(
			body, "เลิกกัน", Color("#5a3030"), false,
			func() -> void:
				close_panel()
				breakup_requested.emit()
		)

	if not Game.children.is_empty():
		_section(body, "ลูก")
		for kid in Game.children:
			_info(body, String(kid["name"]), "อายุ %d ปี" % int(kid["age"]))

	var hint := Label.new()
	hint.text = "แต่งงานต้องมีความรัก 70 ขึ้นไป • มีลูกได้ไม่เกิน 3 คน และต้องอายุไม่เกิน 45"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color("#7f879b"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(hint)


# ---------- แผงการเงิน ----------

func open_finance() -> void:
	var body := _start_panel("การเงิน")
	var child := Game.is_child()
	var b := Game.living_breakdown()

	_section(body, "ภาพรวม")
	_info(
		body, "เงินสด ฿%s" % Game.fmt_money(Game.money),
		"เงินออม ฿%s • หนี้ ฿%s • ทรัพย์สินสุทธิ ฿%s" % [
			Game.fmt_money(Game.bank), Game.fmt_money(Game.loan),
			Game.fmt_money(Game.net_worth()),
		]
	)
	if child:
		_info(
			body, "ยังเป็นเด็ก",
			"พ่อแม่ให้เงินใช้ปีละ ฿%s • รับเงินก้อนตอนอายุ 18 ฿%s" % [
				Game.fmt_money(Game.annual_allowance()),
				Game.fmt_money(Game.family_gift()),
			]
		)
		_section(body, "การเงินของครอบครัว")
		_info(
			body, Game.family_wealth_name(),
			"คุณยังจัดการเงินเองไม่ได้จนกว่าจะอายุ 18"
		)
		return

	_section(body, "รายรับ/เดือน")
	_info(
		body, "เงินเดือน ฿%s" % Game.fmt_money(Game.salary() * 4),
		"ทำงานสัปดาห์ละ ฿%s • โบนัสปีละ 1 เดือนถ้าประสิทธิภาพ 80%%+" % Game.fmt_money(Game.salary())
	)
	if Game.spouse_income() > 0:
		_info(body, "คู่สมรสช่วยจ่าย ฿%s" % Game.fmt_money(Game.spouse_income()), "รายได้ในบ้านเพิ่มขึ้น")
	if Game.retired:
		_info(body, "เงินบำนาญ ฿%s" % Game.fmt_money(Game.pension_amount()), "ได้รับทุกเดือนหลังเกษียณ")
	_info(
		body, "รายได้รวม ฿%s/เดือน" % Game.fmt_money(Game.monthly_income()),
		"เงินเดือน + คู่สมรส + เงินบำนาญ (ถ้ามี) ก่อนหักภาษี"
	)
	_info(
		body, "ภาษี ~฿%s/เดือน" % Game.fmt_money(Game.monthly_tax()),
		"รายได้เกิน ฿%s/เดือน เสีย 5%% ของส่วนที่เกิน" % Game.fmt_money(Game.TAX_FREE)
	)

	_section(body, "ค่าใช้จ่าย/เดือน")
	_info(
		body, "รวม ฿%s" % Game.fmt_money(int(b["total"])),
		"ค่าเช่า ฿%s • น้ำไฟ ฿%s • โทรศัพท์ ฿%s" % [
			Game.fmt_money(int(b["rent"])), Game.fmt_money(int(b["util"])),
			Game.fmt_money(int(b["phone"])),
		]
	)
	_info(
		body, "ค่าเดินทาง ฿%s" % Game.fmt_money(int(b["transport"])),
		"ค่าเลี้ยงลูก ฿%s • ค่าใช้จ่ายร่วม ฿%s • ประกัน ฿%s" % [
			Game.fmt_money(int(b["children"])), Game.fmt_money(int(b["shared"])),
			Game.fmt_money(int(b["insurance"])),
		]
	)

	_section(body, "จัดการเงิน")
	_panel_button(
		body, "ฝากเงิน ฿1,000", Color("#2f6fd0"), Game.money < 1000,
		func() -> void:
			close_panel()
			bank_deposit_requested.emit()
	)
	_panel_button(
		body, "ถอนเงิน ฿1,000", Color("#5b6a92"), Game.bank < 1000,
		func() -> void:
			close_panel()
			bank_withdraw_requested.emit()
	)
	_panel_button(
		body,
		"กู้เงิน ฿5,000 (วงเงินเหลือ ฿%s)" % Game.fmt_money(maxi(Game.borrow_limit() - Game.loan, 0)),
		Color("#a06a2f"), Game.loan + 5000 > Game.borrow_limit(),
		func() -> void:
			close_panel()
			loan_requested.emit()
	)
	_panel_button(
		body, "จ่ายหนี้ ฿5,000", Color("#2f8f5b"),
		Game.loan <= 0 or Game.money <= 0,
		func() -> void:
			close_panel()
			repay_requested.emit()
	)
	_panel_button(
		body,
		("ยกเลิกประกันสุขภาพ" if Game.insurance else "ซื้อประกันสุขภาพ ฿600/เดือน"),
		Color("#7a5ad0") if not Game.insurance else Color("#5a3030"), false,
		func() -> void:
			close_panel()
			insurance_requested.emit()
	)
	_info(
		body, "ประกันสุขภาพ",
		"จ่ายค่ารักษาเพียง 30% • ลดโอกาสป่วยเล็กน้อย" if Game.insurance else "ยังไม่มีประกัน — ค่ารักษาเต็มราคา"
	)
	_info(
		body, "หนี้สิน",
		"เงินกู้ดอกเบี้ย 1.5%/เดือน • เงินสดติดลบดอกเบี้ย 3%/เดือน"
	)


# ---------- แผงสุขภาพ ----------

func open_health() -> void:
	var body := _start_panel("สุขภาพ")
	var child := Game.is_child()

	_section(body, "สถานะร่างกาย")
	if Game.sick:
		_info(
			body, "ป่วยเป็น%s" % Game.illness,
			"ป่วยมา %d สัปดาห์ • กินยาหรือไปหาหมอเพื่อรักษา" % Game.sick_weeks
		)
	else:
		_info(body, "ไม่ป่วย", "ร่างกายแข็งแรงดี")
	_info(
		body, "สุขภาพ %d/100" % Game.health,
		"ความเครียด %d • ความอิ่ม %d • พลังงาน %d" % [
			Game.stress, Game.hunger, Game.energy
		]
	)

	_section(body, "ประกันสุขภาพ")
	_info(
		body, "มีประกัน" if Game.insurance else "ยังไม่มีประกัน",
		"ค่ารักษาเหลือ 30%" if Game.insurance else "จ่ายค่ารักษาเต็มจำนวน"
	)
	if not child:
		var med := Game.medical_cost(Game.COST_MEDICINE)
		var doc := Game.medical_cost(Game.COST_DOCTOR)
		var chk := Game.medical_cost(Game.COST_CHECKUP)
		_section(body, "รักษาตัว")
		_panel_button(
			body, "ซื้อยากินเอง ฿%s" % Game.fmt_money(med),
			Color("#a06a2f"), (not Game.sick) or Game.money < med,
			func() -> void:
				close_panel()
				medicine_requested.emit()
		)
		_panel_button(
			body, "ไปหาหมอ ฿%s" % Game.fmt_money(doc),
			Color("#2f6fd0"), Game.money < doc,
			func() -> void:
				close_panel()
				doctor_requested.emit()
		)
		_panel_button(
			body, "ตรวจสุขภาพประจำปี ฿%s" % Game.fmt_money(chk),
			Color("#2f8f5b"), Game.money < chk,
			func() -> void:
				close_panel()
				checkup_requested.emit()
		)
		_panel_button(
			body,
			("ยกเลิกประกันสุขภาพ" if Game.insurance else "ซื้อประกันสุขภาพ ฿600/เดือน"),
			Color("#7a5ad0") if not Game.insurance else Color("#5a3030"), false,
			func() -> void:
				close_panel()
				insurance_requested.emit()
		)
	else:
		_info(body, "ยังเป็นเด็ก", "พ่อแม่ดูแลเวลาป่วยให้จนกว่าจะอายุ 18")


# ---------- แผงแต่งตัว ----------

func open_wardrobe() -> void:
	var body := _start_panel("แต่งตัว")
	var current := Game.outfit_data(Game.outfit)

	_section(body, "ชุดที่ใส่อยู่")
	_info(
		body, String(current.get("name", "ชุดลำลอง")),
		"เสน่ห์ +%d • ความเป็นทางการ +%d • %s" % [
			int(current.get("charm", 0)), int(current.get("formal", 0)),
			String(current.get("desc", "")),
		]
	)
	_info(
		body, "ผลต่อชีวิต",
		"เสน่ห์ช่วยให้สมัครงานและออกเดทผ่านง่ายขึ้น • ชุดทำงานเพิ่มความมั่นใจในออฟฟิศ"
	)

	_section(body, "ตู้เสื้อผ้า")
	for o in Game.OUTFITS:
		_outfit_row(body, o)


func _outfit_row(body: VBoxContainer, o: Dictionary) -> void:
	var id := String(o["id"])
	var owned := Game.owns_outfit(id)
	var equipped := Game.outfit == id
	var price := int(o["price"])

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 54)
	row.add_theme_constant_override("separation", 8)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)

	var name_label := Label.new()
	name_label.text = String(o["name"])
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color("#9fd0ff") if equipped else Color("#e8e8f0"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_label)

	var sub := Label.new()
	sub.text = "%s • เสน่ห์ +%d • ทางการ +%d" % [
		String(o["desc"]), int(o["charm"]), int(o["formal"])
	]
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color("#8b93a7"))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(sub)
	row.add_child(info)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(92, 40)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))

	if equipped:
		btn.text = "ใส่อยู่"
		btn.disabled = true
	elif owned:
		btn.text = "สวม"
		btn.disabled = false
		btn.pressed.connect(func() -> void:
			close_panel()
			outfit_equip_requested.emit(id)
		)
	else:
		btn.text = "ซื้อ ฿%s" % Game.fmt_money(price)
		btn.disabled = Game.money < price
		btn.pressed.connect(func() -> void:
			close_panel()
			outfit_buy_requested.emit(id)
		)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#2f6fd0") if not btn.disabled else Color("#2b2f3d")
	normal.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.12)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.18)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled := normal.duplicate()
	disabled.bg_color = Color("#222634")
	btn.add_theme_stylebox_override("disabled", disabled)

	row.add_child(btn)
	body.add_child(row)


# ---------- แผงชีวิต ----------

func open_life() -> void:
	var body := _start_panel("ชีวิต")

	_section(body, "ภาพรวม")
	_info(
		body, "%s • อายุ %d ปี • %s" % [Game.player_name, Game.age, Game.stage_name()],
		"%s • %s" % [Game.gender, Game.family_wealth_name()]
	)
	_info(
		body, "การศึกษา", "%s • ความรู้ %d/100 • สังคม %d/100" % [
			Game.education_title(), Game.edu, Game.social
		]
	)
	_info(
		body, "การเงิน", "เงินสด ฿%s • ออม ฿%s • หนี้ ฿%s • สุทธิ ฿%s" % [
			Game.fmt_money(Game.money), Game.fmt_money(Game.bank),
			Game.fmt_money(Game.loan), Game.fmt_money(Game.net_worth()),
		]
	)
	_info(body, "อาชีพ", Game.income_text())
	_info(
		body, "ครอบครัว",
		"%s • ลูก %d คน • ความรักกับพ่อแม่ %d/100" % [
			Game.partner_status(), Game.children.size(), Game.parent_love
		]
	)
	_info(body, "เพื่อน", Game.friend_status())
	_info(
		body, "ชุดที่ใส่", "%s • เสน่ห์ +%d" % [
			Game.outfit_data(Game.outfit)["name"], Game.outfit_charm()
		]
	)

	_section(body, "บันทึกชีวิต")
	if Game.life_log.is_empty():
		_info(body, "ยังไม่มีเหตุการณ์", "ทำกิจกรรมไปเรื่อย ๆ แล้วเรื่องราวจะถูกบันทึกไว้")
	else:
		var count := 0
		for line in Game.life_log:
			if count >= 12:
				break
			var l := Label.new()
			l.text = "• " + String(line)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.add_theme_font_size_override("font_size", 10)
			l.add_theme_color_override("font_color", Color("#aab2c6"))
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body.add_child(l)
			count += 1

	_section(body, "เริ่มใหม่")
	restart_button = _panel_button(
		body, "เริ่มชีวิตใหม่", Color("#7a3b3b"), false, _on_restart_button
	)


func _on_restart_button() -> void:
	if not restart_armed:
		restart_armed = true
		if restart_button != null:
			restart_button.text = "กดอีกครั้งเพื่อยืนยัน"
		return
	restart_armed = false
	close_panel()
	restart_pressed.emit()


