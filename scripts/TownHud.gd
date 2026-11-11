class_name TownHud
extends Control
## TownHud.gd — HUD แนวนอน 960x540 สำหรับ v4
## top bar + การ์ดสถานะ + จอย + ปุ่ม interact + แผงสรุป + บทสนทนา + รถเมล์ + มินิเกม

signal interact_pressed
signal travel_requested(zone_id: String)
signal life_started

const FONT_NAMES := ["Segoe UI", "Noto Sans Thai", "Leelawadee UI", "Tahoma"]
const BG := Color("#241a12")
const PANEL := Color("#f6ecd8")
const BORDER := Color("#8a5a3a")
const GOLD := Color("#a86a24")
const TEXT := Color("#4a3626")
const DIM_TEXT := Color("#8a7458")
const CREAM := Color("#f6ecd8")
const PAPER_DARK := Color("#e6d6b8")
const WOOD := Color("#3a2a1e")
const WOOD_LIGHT := Color("#5a4030")
const BRASS := Color("#c89a4a")
const LEAF := Color("#557044")

const BAR_DEFS := [
	{"key": "health", "label": "สุขภาพ", "color": Color("#c85a52")},
	{"key": "happy", "label": "ความสุข", "color": Color("#d0a03a")},
	{"key": "energy", "label": "พลังงาน", "color": Color("#5a88b8")},
	{"key": "hunger", "label": "ความอิ่ม", "color": Color("#c87a42")},
	{"key": "stress", "label": "ความเครียด", "color": Color("#8a6aa8")},
]
const TAB_DEFS := [
	["overview", "ภาพรวม"], ["career", "อาชีพ"], ["money", "เงิน"],
	["skills", "ทักษะ"], ["home", "บ้าน"], ["farm", "ฟาร์ม"],
	["hobby", "งานอดิเรก"], ["awards", "รางวัล"], ["quests", "ภารกิจ"],
	["business", "ธุรกิจ"], ["social", "สังคม"], ["festival", "เทศกาล"],
	["health", "สุขภาพ"], ["love", "ความรัก"], ["life", "ชีวิต"], ["outfits", "ชุด"],
]
const BUS_ZONES := ["home_street", "school_district", "downtown", "park"]

var _font_regular: Font
var _font_bold: Font

var _zone_label: Label
var _date_label: Label
var _weather_label: Label
var _money_label: Label
var _bars := {}
var _prompt_label: Label
var _run_label: Label
var _interact_btn: Button
var _menu_btn: Button
var _joy

var _modal: Control
var _dialog: Control
var _portrait_ctl: Control
var _minigame: Control
var _toast_label: Label
var _toast_timer: Timer
var _ui_tick := 0.0
var _prompt_text := ""
var _restart_armed := false
var _gameover_shown := false
var _summary_tab := "overview"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font_regular = Fonts.regular()
	_font_bold = Fonts.bold()
	_build_top_bar()
	_build_needs_card()
	_build_controls()
	_build_toast()
	Game.changed.connect(_on_game_changed)
	Game.day_changed.connect(_on_day_changed)
	_sync_pause()
	refresh()


func _process(delta: float) -> void:
	_ui_tick += delta
	if _ui_tick >= 0.2:
		_ui_tick = 0.0
		refresh()
		if _portrait_ctl != null:
			_portrait_ctl.queue_redraw()
	if _prompt_label != null:
		_prompt_label.visible = (not busy) and _prompt_text != ""
	if not Game.alive and not _gameover_shown:
		show_game_over()


func _on_game_changed() -> void:
	refresh()


func _on_day_changed() -> void:
	_restart_armed = false


# ============================================================
#  พื้นฐาน UI
# ============================================================
func _stylebox(color: Color, border: Color = Color.TRANSPARENT, radius: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = border
	sb.set_border_width_all(2 if border.a > 0.0 else 0)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(8)
	return sb


func _label(parent: Node, text: String, size: int, color: Color = TEXT, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font_bold if bold else _font_regular)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _btn(parent: Node, text: String, cb: Callable, color: Color = Color(0.42, 0.3, 0.2), min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _font_regular)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("#fff4d8"))
	var sb := _stylebox(color.darkened(0.10), color.lightened(0.38), 7)
	b.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate()
	hover.bg_color = color.lightened(0.14)
	hover.border_color = Color("#f2d8a8")
	b.add_theme_stylebox_override("hover", hover)
	var pressed := sb.duplicate()
	pressed.bg_color = color.darkened(0.24)
	b.add_theme_stylebox_override("pressed", pressed)
	var disabled := sb.duplicate()
	disabled.bg_color = Color(0.52, 0.46, 0.38)
	disabled.border_color = Color(0.62, 0.55, 0.45)
	b.add_theme_stylebox_override("disabled", disabled)
	if min_w > 0.0:
		b.custom_minimum_size = Vector2(min_w, 30)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _bar_style(bg: Color, fill: Color) -> void:
	pass


# ============================================================
#  HUD หลัก
# ============================================================
func _build_top_bar() -> void:
	var panel := Panel.new()
	panel.position = Vector2(0, 0)
	panel.size = Vector2(960, 46)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#3a2a1e")
	sb.border_color = Color("#8a5a3a")
	sb.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	_zone_label = _label(row, "บ้านของเรา", 16, Color("#f2d8a8"), true)
	_zone_label.custom_minimum_size = Vector2(180, 0)
	_zone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_date_label = _label(row, "", 13, CREAM)
	_date_label.custom_minimum_size = Vector2(226, 0)
	_date_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_weather_label = _label(row, "", 13, Color("#d8c8a8"))
	_weather_label.custom_minimum_size = Vector2(200, 0)
	_weather_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_money_label = _label(row, "฿0", 17, Color("#f2c85a"), true)
	_money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var summary_btn := _btn(row, "สรุป", _on_summary_pressed, Color(0.42, 0.3, 0.18), 58)
	summary_btn.custom_minimum_size.y = 30
	var bus_btn := _btn(row, "รถเมล์", _on_bus_pressed, Color(0.36, 0.28, 0.16), 64)
	bus_btn.custom_minimum_size.y = 30


func _build_needs_card() -> void:
	var panel := Panel.new()
	panel.position = Vector2(10, 54)
	panel.size = Vector2(206, 114)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",
		_stylebox(Color("#f4e8d0"), Color("#8a5a3a"), 9))
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	margin.add_child(col)

	for def in BAR_DEFS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		col.add_child(row)
		var name_l := _label(row, String(def["label"]), 10, Color("#7a6244"))
		name_l.custom_minimum_size = Vector2(54, 0)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = 50
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(92, 9)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("#dccbaa")
		bg.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background", bg)
		var fill := StyleBoxFlat.new()
		fill.bg_color = def["color"]
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill)
		row.add_child(bar)
		var val := _label(row, "50", 9, Color("#6a5438"))
		val.custom_minimum_size = Vector2(23, 0)
		_bars[String(def["key"])] = {"bar": bar, "label": val}


func _build_controls() -> void:
	# จอยสติ๊ก
	_joy = load("res://scripts/JoyPad.gd").new()
	_joy.position = Vector2(22, 382)
	_joy.size = Vector2(136, 136)
	add_child(_joy)
	_joy.changed.connect(_on_joy_changed)

	# ปุ่ม interact
	_interact_btn = Button.new()
	_interact_btn.text = "E\nใช้"
	_interact_btn.position = Vector2(854, 414)
	_interact_btn.custom_minimum_size = Vector2(86, 86)
	_interact_btn.size = Vector2(86, 86)
	_interact_btn.add_theme_font_override("font", _font_bold)
	_interact_btn.add_theme_font_size_override("font_size", 18)
	_interact_btn.add_theme_color_override("font_color", Color("#1f1a10"))
	_interact_btn.add_theme_color_override("font_hover_color", Color("#1f1a10"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#e8c05a")
	sb.set_corner_radius_all(43)
	sb.border_color = Color("#fff0b0")
	sb.set_border_width_all(3)
	_interact_btn.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate()
	hover.bg_color = Color("#f2d070")
	_interact_btn.add_theme_stylebox_override("hover", hover)
	var pressed := sb.duplicate()
	pressed.bg_color = Color("#c8a040")
	_interact_btn.add_theme_stylebox_override("pressed", pressed)
	_interact_btn.pressed.connect(func() -> void: interact_pressed.emit())
	add_child(_interact_btn)

	# ปุ่มเมนู
	_menu_btn = _btn(self, "☰ เมนู", func() -> void: open_summary("overview"),
		Color(0.2, 0.24, 0.34), 86)
	_menu_btn.position = Vector2(850, 366)
	_menu_btn.custom_minimum_size = Vector2(90, 38)
	_menu_btn.size = Vector2(90, 38)
	_menu_btn.add_theme_font_size_override("font_size", 14)

	# Prompt
	_prompt_label = Label.new()
	_prompt_label.position = Vector2(300, 490)
	_prompt_label.custom_minimum_size = Vector2(360, 34)
	_prompt_label.size = Vector2(360, 34)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_override("font", _font_regular)
	_prompt_label.add_theme_font_size_override("font_size", 13)
	_prompt_label.add_theme_color_override("font_color", TEXT)
	var psb := _stylebox(Color("#f6ecd8"), Color("#8a5a3a"), 16)
	psb.content_margin_left = 12
	psb.content_margin_right = 12
	_prompt_label.add_theme_stylebox_override("normal", psb)
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_label.visible = false
	add_child(_prompt_label)

	_run_label = Label.new()
	_run_label.position = Vector2(330, 454)
	_run_label.custom_minimum_size = Vector2(300, 28)
	_run_label.size = Vector2(300, 28)
	_run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_run_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_run_label.add_theme_font_override("font", _font_regular)
	_run_label.add_theme_font_size_override("font_size", 12)
	_run_label.add_theme_color_override("font_color", Color("#8a4a24"))
	var rsb := _stylebox(Color("#f6ecd8"), Color("#8a5a3a"), 12)
	_run_label.add_theme_stylebox_override("normal", rsb)
	_run_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_run_label.visible = false
	add_child(_run_label)


func _build_toast() -> void:
	_toast_label = Label.new()
	_toast_label.position = Vector2(220, 52)
	_toast_label.custom_minimum_size = Vector2(520, 38)
	_toast_label.size = Vector2(520, 38)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_override("font", _font_regular)
	_toast_label.add_theme_font_size_override("font_size", 13)
	_toast_label.add_theme_color_override("font_color", TEXT)
	var sb := _stylebox(Color("#f6ecd8"), Color("#8a5a3a"), 10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	_toast_label.add_theme_stylebox_override("normal", sb)
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label.visible = false
	add_child(_toast_label)

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.wait_time = 3.2
	_toast_timer.timeout.connect(func() -> void: _toast_label.visible = false)
	add_child(_toast_timer)


func _on_joy_changed(v: Vector2) -> void:
	# ส่งต่อไปยัง Player ผ่าน Town
	var town := get_parent().get_parent()
	if town != null and town.has_method("set_joystick"):
		town.set_joystick(v)


func _on_summary_pressed() -> void:
	open_summary(_summary_tab)


func _on_bus_pressed() -> void:
	open_bus()


# ============================================================
#  สถานะ / prompt / toast
# ============================================================
func refresh() -> void:
	if _zone_label == null:
		return
	_zone_label.text = "%s   •   อายุ %d" % [TownData.zone_name(Game.zone_id), Game.age]
	_date_label.text = "%s • %s %d • %s" % [
		Game.weekday_name(), Game.season_name(), Game.season_day, Game.time_string()
	]
	_weather_label.text = "%s • %s" % [Game.weather_name(), Game.day_phase()]
	var fest := Game.festival_today()
	if not fest.is_empty():
		_weather_label.text += " • %s" % String(fest.get("name", "เทศกาล"))
	_money_label.text = "฿%s" % Game.fmt_money(Game.money)
	for def in BAR_DEFS:
		var key := String(def["key"])
		if _bars.has(key):
			var entry: Dictionary = _bars[key]
			var v := float(Game.get(key))
			entry["bar"].value = v
			entry["label"].text = str(int(v))
	_sync_controls()


func _sync_controls() -> void:
	if _interact_btn == null:
		return
	var show := not busy
	_interact_btn.visible = show
	_menu_btn.visible = show
	if _joy != null:
		_joy.visible = show
	if busy and _joy != null:
		_on_joy_changed(Vector2.ZERO)
	if _prompt_label != null and busy:
		_prompt_label.visible = false
	if _run_label != null and busy:
		_run_label.visible = false


func set_prompt(text: String) -> void:
	_prompt_text = text
	if _prompt_label != null:
		_prompt_label.text = text
		_prompt_label.visible = (not busy) and text != ""


func set_run_status(text: String) -> void:
	if _run_label == null:
		return
	_run_label.text = text
	_run_label.visible = (not busy) and text != ""


func toast(text: String) -> void:
	if text.strip_edges() == "":
		return
	_toast_label.text = text
	_toast_label.visible = true
	_toast_timer.start()


func _show_result(res: Dictionary) -> void:
	toast(String(res.get("message", "")))
	refresh()


func _sync_pause() -> void:
	Game.time_paused = busy
	_sync_controls()


func get_busy() -> bool:
	return busy


var busy: bool:
	get:
		return _modal != null or _dialog != null or _minigame != null


# ============================================================
#  Modal / Dialog
# ============================================================
func _open_modal(title: String, w: float = 820.0, h: float = 460.0) -> VBoxContainer:
	close_modal()
	_modal = Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal)

	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.08, 0.05, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2((960.0 - w) * 0.5, (540.0 - h) * 0.5)
	panel.size = Vector2(w, h)
	var panel_sb := _stylebox(PANEL, BORDER, 12)
	panel_sb.set_border_width_all(3)
	panel_sb.shadow_color = Color(0.10, 0.06, 0.03, 0.45)
	panel_sb.shadow_size = 8
	panel.add_theme_stylebox_override("panel", panel_sb)
	_modal.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	col.add_child(header)
	var t := _label(header, title, 20, GOLD, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var x := _btn(header, "✕", close_modal, Color(0.4, 0.16, 0.16), 40)
	x.custom_minimum_size = Vector2(40, 32)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 18)
	scroll.add_child(pad)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	pad.add_child(body)
	_sync_pause()
	return body


func close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null
		_sync_pause()


func close_dialog() -> void:
	if _dialog != null:
		_dialog.queue_free()
		_dialog = null
	_portrait_ctl = null
	_sync_pause()


func close_all() -> void:
	close_modal()
	close_dialog()


func _section(parent: Node, text: String) -> void:
	var l := _label(parent, text, 15, Color("#7a4a24"), true)
	l.custom_minimum_size = Vector2(0, 24)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _sep(parent: Node) -> void:
	var line := ColorRect.new()
	line.color = Color("#c8b48e")
	line.custom_minimum_size = Vector2(0, 1)
	parent.add_child(line)


func _kv_grid(parent: Node, pairs: Array) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	for pair in pairs:
		var k := _label(grid, String(pair[0]), 12, DIM_TEXT)
		k.custom_minimum_size = Vector2(150, 0)
		var v := _label(grid, String(pair[1]), 13, TEXT)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


# ============================================================
#  แผงสรุป
# ============================================================
func open_summary(tab: String = "overview") -> void:
	_summary_tab = tab
	var body := _open_modal("ชีวิตของ %s" % Game.player_name, 840, 486)
	var tab_grid := GridContainer.new()
	tab_grid.columns = 8
	tab_grid.add_theme_constant_override("h_separation", 4)
	tab_grid.add_theme_constant_override("v_separation", 4)
	body.add_child(tab_grid)
	for def in TAB_DEFS:
		var id := String(def[0])
		var b := _btn(tab_grid, String(def[1]), _on_tab_pressed.bind(id), Color(0.42, 0.3, 0.2), 88)
		b.custom_minimum_size = Vector2(90, 26)
		b.add_theme_font_size_override("font_size", 11)
		if id == tab:
			b.modulate = Color(1.3, 1.18, 0.92)
	_sep(body)
	match tab:
		"overview":
			_summary_overview(body)
		"career":
			_summary_career(body)
		"money":
			_summary_money(body)
		"skills":
			_summary_skills(body)
		"home":
			_summary_home(body)
		"farm":
			_summary_farm(body)
		"hobby":
			_summary_hobby(body)
		"awards":
			_summary_awards(body)
		"quests":
			_summary_quests(body)
		"business":
			_summary_business(body)
		"social":
			_summary_social(body)
		"festival":
			_summary_festival(body)
		"health":
			_summary_health(body)
		"love":
			_summary_love(body)
		"life":
			_summary_life(body)
		"outfits":
			_summary_outfits(body)


func _on_tab_pressed(id: String) -> void:
	_restart_armed = false
	open_summary(id)


func _summary_overview(body: VBoxContainer) -> void:
	_section(body, "สถานะวันนี้")
	var goals: Array[String] = []
	if Game.is_school_day() and not Game.school_attended_today:
		goals.append("ไปโรงเรียนก่อน 15:00")
	if not Game.is_child() and Game.job_id != "" and Game.is_workday() and not Game.worked_today:
		goals.append("ไปทำงานที่ %s ก่อน 17:00" % TownData.zone_name(Game.current_workplace()))
	if Game.is_home_time():
		goals.append("กลับบ้านกินข้าวกับพ่อแม่")
	var fest := Game.festival_today()
	if not fest.is_empty() and not Game.festival_attended_today():
		goals.append("วันนี้มี%s ที่%s" % [String(fest["name"]), TownData.zone_name(String(fest["zone"]))])
	if goals.is_empty():
		goals.append("เดินเล่น ทำธุระ หรือออกกำลังกาย")
	for g in goals:
		_label(body, "• " + g, 13, Color("#8a4a24"))

	_kv_grid(body, [
		["ชื่อ", "%s (%s)" % [Game.player_name, Game.gender]],
		["อายุ", "%d ปี • %s" % [Game.age, Game.stage_name()]],
		["การศึกษา", "%d/100 • %s" % [Game.edu, Game.education_title()]],
		["เกรดโรงเรียน", "%d/100" % Game.grades],
		["ทักษะเฉลี่ย", "%d/100" % Game.skill_average()],
		["กรรมพัน", Game.karma_name()],
		["ความอบอุ่นบ้าน", "%d/100" % Game.home_cozy()],
		["ฟิตเนส", "%d/100" % Game.fitness],
		["สุขภาพ", "%d/100" % Game.health],
		["ความสุข", "%d/100" % Game.happy],
		["พลังงาน", "%d/100" % Game.energy],
		["ความอิ่ม", "%d/100" % Game.hunger],
		["ความเครียด", "%d/100" % Game.stress],
		["ความรักพ่อแม่", "%d/100" % Game.parent_love],
		["คนรัก", Game.partner_name if Game.partner_name != "" else "ยังไม่มี"],
		["เข้าเรียน", "%d วัน • ขาด %d วัน" % [Game.school_days, Game.school_absences]],
		["ทำงาน", "%d กะ • ขาด %d ครั้ง" % [Game.job_shifts, Game.work_absences]],
		["ฤดูกาล", "%s วันที่ %d • %s" % [Game.season_name(), Game.season_day, Game.weather_name()]],
		["วันเกิดถัดไป", "อีก %d วัน" % (29 - ((Game.day - 1) % 28 + 1))],
	])


func _summary_career(body: VBoxContainer) -> void:
	_section(body, "งานปัจจุบัน")
	if Game.job_id == "":
		_label(body, "ยังไม่มีงานประจำ — ไปสมัครงานด้านล่าง หรือรับจ้างรายวันตามร้าน/ออฟฟิศ", 13, DIM_TEXT)
	else:
		_kv_grid(body, [
			["ตำแหน่ง", "%s (ระดับ %d)" % [Game.job_title(), Game.job_level]],
			["เงินเดือน", "฿%s/สัปดาห์" % Game.fmt_money(Game.salary())],
			["ประสิทธิภาพ", "%d%%" % Game.performance],
			["ที่ทำงาน", TownData.zone_name(Game.current_workplace())],
			["กะที่ทำ", "%d กะ" % Game.job_shifts],
		])
		_btn(body, "ลาออกจากงาน", _on_quit_job, Color(0.45, 0.2, 0.2), 160)

	_sep(body)
	_section(body, "ตลาดงาน (สมัครได้ทันที)")
	for job in Game.JOBS:
		var jid := String(job["id"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var info := _label(row, "%s • ฿%s/สัปดาห์ • ความรู้ %d" % [
			String(job["title"]), Game.fmt_money(int(job["salary"])), int(job["edu"])
		], 12, TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var blocked := Game.apply_block_reason(jid)
		var chance := int(round(Game.apply_chance(jid) * 100.0))
		var b := _btn(row, "สมัคร (%d%%)" % chance, _on_apply_job.bind(jid), Color(0.3, 0.36, 0.2), 116)
		b.disabled = blocked != ""
		if blocked != "":
			b.tooltip_text = blocked
	_label(body, "หมายเหตุ: สมัครงานไม่กินเวลา แต่ต้องเดินไปทำงานที่ที่ทำงานจริงในวันจันทร์-ศุกร์ 08:00-17:00", 11, DIM_TEXT)


func _on_apply_job(id: String) -> void:
	_show_result(Game.apply_job(id))
	open_summary("career")


func _on_quit_job() -> void:
	_show_result(Game.quit_job())
	open_summary("career")


func _summary_money(body: VBoxContainer) -> void:
	_section(body, "การเงิน")
	_kv_grid(body, [
		["เงินสด", "฿%s" % Game.fmt_money(Game.money)],
		["บัญชีออมทรัพย์", "฿%s" % Game.fmt_money(Game.bank)],
		["หนี้สิน", "฿%s" % Game.fmt_money(Game.loan)],
		["มูลค่าสุทธิ", "฿%s" % Game.fmt_money(Game.net_worth())],
		["รายได้/เดือน", Game.income_text()],
		["ประกันสุขภาพ", "มี" if Game.insurance else "ไม่มี"],
	])
	_sep(body)
	_section(body, "ATM")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	body.add_child(row)
	_btn(row, "ฝาก ฿500", _on_deposit.bind(500), Color(0.2, 0.4, 0.3), 100)
	_btn(row, "ถอน ฿500", _on_withdraw.bind(500), Color(0.35, 0.3, 0.2), 100)
	_btn(row, "ฝาก ฿2,000", _on_deposit.bind(2000), Color(0.2, 0.4, 0.3), 110)
	_btn(row, "ถอน ฿2,000", _on_withdraw.bind(2000), Color(0.35, 0.3, 0.2), 110)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	body.add_child(row2)
	_btn(row2, "กู้ ฿1,000", _on_borrow.bind(1000), Color(0.4, 0.25, 0.2), 100)
	_btn(row2, "จ่ายหนี้ ฿1,000", _on_repay.bind(1000), Color(0.32, 0.34, 0.2), 120)
	_btn(row2, "เปิด/ปิดประกัน", _on_insurance, Color(0.36, 0.3, 0.2), 120)
	_label(body, "สามารถใช้ ATM ที่ธนาคารในดาวน์ทาวน์ได้ด้วย", 11, DIM_TEXT)


func _on_deposit(v: int) -> void:
	_show_result(Game.deposit(v))
	open_summary("money")


func _on_withdraw(v: int) -> void:
	_show_result(Game.withdraw(v))
	open_summary("money")


func _on_borrow(v: int) -> void:
	_show_result(Game.borrow(v))
	open_summary("money")


func _on_repay(v: int) -> void:
	_show_result(Game.repay(v))
	open_summary("money")


func _on_insurance() -> void:
	_show_result(Game.toggle_insurance())
	open_summary("money")


func _progress(parent: Node, value: int, color: Color, width: float = 170.0, height: float = 10.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = clampi(value, 0, 100)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, height)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#dccbaa")
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar


func _summary_skills(body: VBoxContainer) -> void:
	_section(body, "ทักษะชีวิต")
	_label(body, "ยิ่งฝึกยิ่งเก่ง • ฝึกพิเศษได้วันละ 1 ครั้ง ฿%d" % Game.TRAIN_COST, 12, DIM_TEXT)
	var trained := Game.train_day == Game.day
	for sk in Game.SKILL_KEYS:
		var key := String(sk)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var nm := _label(row, Game.skill_name(key), 12, TEXT, true)
		nm.custom_minimum_size = Vector2(84, 0)
		_progress(row, Game.skill_of(key), Game.skill_color(key), 166, 10)
		var tier := _label(row, Game.skill_tier(key), 11, DIM_TEXT)
		tier.custom_minimum_size = Vector2(86, 0)
		var v := _label(row, "%d" % Game.skill_of(key), 12, TEXT)
		v.custom_minimum_size = Vector2(28, 0)
		var b := _btn(row, "ฝึก", _on_train_skill.bind(key), Color(0.32, 0.42, 0.28), 58)
		b.disabled = trained or Game.money < Game.TRAIN_COST
		b.tooltip_text = Game.skill_desc(key)
	_label(body, "ทักษะยังเพิ่มได้จากการเรียน ทำงาน ออกกำลังกาย ทำอาหาร วาดรูป และคุยกับผู้คน", 11, DIM_TEXT)

	_sep(body)
	_section(body, "กรรมพันจากพ่อแม่")
	_kv_grid(body, [
		["ครอบครัว", Game.parent_trait_name()],
		["ลักษณะที่ได้รับ", Game.parent_trait_desc()],
		["กรรมพัน", Game.karma_name()],
		["คำอธิบาย", Game.karma_desc()],
		["ผ้าห่อตัวแรกเกิด", Game.birth_outfit_name()],
		["ทักษะเฉลี่ย", "%d/100" % Game.skill_average()],
	])


func _on_train_skill(id: String) -> void:
	_show_result(Game.train_skill(id))
	open_summary("skills")


func _summary_home(body: VBoxContainer) -> void:
	_section(body, "บ้านอบอุ่น")
	_label(body, "ความอบอุ่นบ้าน %d/100 • เฟอร์นิเจอร์ %d ชิ้น" % [Game.home_cozy(), Game.home_items.size()], 13, TEXT)
	_label(body, "ซื้อของแต่งบ้านแล้วเดินดูของจริงในบ้านได้เลย", 11, DIM_TEXT)
	for f in Game.FURNITURE:
		var fid := String(f["id"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		_label(col, "%s • อบอุ่น +%d" % [String(f["name"]), int(f["cozy"])], 12, TEXT, true)
		var desc := _label(col, String(f["desc"]), 10, DIM_TEXT)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if Game.owns_furniture(fid):
			var tag := _label(row, "มีแล้ว", 12, Color("#557044"), true)
			tag.custom_minimum_size = Vector2(64, 0)
			tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		else:
			_btn(row, "ซื้อ ฿%s" % Game.fmt_money(int(f["price"])),
				_on_buy_furniture.bind(fid), Color(0.38, 0.3, 0.18), 106)

	_sep(body)
	_section(body, "อัปเกรดบ้าน")
	_kv_grid(body, [
		["ระดับบ้าน", "เลเวล %d/%d" % [Game.home_level, Game.HOME_MAX_LEVEL]],
		["ความอบอุ่น", "%d/100" % Game.home_cozy()],
	])
	if Game.home_level < Game.HOME_MAX_LEVEL:
		_btn(body, "อัปเกรดบ้าน ฿%s" % Game.fmt_money(
			int(Game.HOME_UPGRADE_COSTS[Game.home_level])),
			_on_upgrade_home, Color(0.34, 0.3, 0.2), 200)
	else:
		_label(body, "บ้านหลังนี้ดีที่สุดแล้ว", 11, Color("#557044"), true)

	_sep(body)
	_section(body, "แมวน้อย")
	if Game.pet_name == "":
		_label(body, "ยังไม่มีแมว — ซื้อ “ที่นอนแมว” เพื่อรับเพื่อนขนฟูมาอยู่ด้วย", 12, DIM_TEXT)
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var info := _label(row, "%s • ความสุข %d/100" % [Game.pet_name, Game.pet_happy], 12, TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_progress(row, Game.pet_happy, Color("#d89a5a"), 130, 10)
		var b := _btn(row, "เล่นด้วย", _on_pet_cat, Color(0.4, 0.32, 0.18), 90)
		b.disabled = Game.pet_day == Game.day
		var row2 := HBoxContainer.new()
		row2.add_theme_constant_override("separation", 8)
		body.add_child(row2)
		var fb := _btn(row2, "ให้อาหาร ฿%s" % Game.fmt_money(Game.CAT_FEED_COST),
			_on_cat_feed, Color(0.34, 0.3, 0.2), 120)
		fb.disabled = Game.cat_feed_day == Game.day
		if not Game.cat_toy_owned:
			_btn(row2, "ซื้อของเล่น ฿%s" % Game.fmt_money(Game.CAT_TOY_COST),
				_on_buy_cat_toy, Color(0.36, 0.28, 0.3), 130)
		else:
			var tb := _btn(row2, "เล่นของเล่น", _on_cat_play_toy, Color(0.3, 0.36, 0.3), 100)
			tb.disabled = Game.cat_toy_day == Game.day

	_sep(body)
	_section(body, "ของสะสมตามฤดู")
	_label(body, "สะสมแล้ว %d/%d ชนิด • โบนัสทุก 4/8/12 ชนิด" % [
		Game.collection_count(), Game.collection_total()
	], 12, TEXT)
	for season in 4:
		var found := 0
		var total := 0
		var names: Array[String] = []
		for cid in Game.COLLECTIBLES.keys():
			var c: Dictionary = Game.COLLECTIBLES[cid]
			if int(c.get("season", -1)) != season:
				continue
			total += 1
			if int(Game.collections.get(String(cid), 0)) > 0:
				found += 1
				names.append(Game.collectible_name(String(cid)))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var nm := _label(row, Game.SEASON_NAMES[season], 12, TEXT, true)
		nm.custom_minimum_size = Vector2(110, 0)
		_label(row, "%d/%d • %s" % [found, total,
			", ".join(PackedStringArray(names)) if not names.is_empty() else "ยังไม่พบ"], 11, DIM_TEXT)
	_label(body, "เดินหาจุดประกายในแต่ละโซนเพื่อเก็บของสะสมวันละ 1 ครั้ง", 11, DIM_TEXT)


func _on_buy_furniture(id: String) -> void:
	_show_result(Game.buy_furniture(id))
	open_summary("home")


func _on_pet_cat() -> void:
	_show_result(Game.pet_cat())
	open_summary("home")


func _on_upgrade_home() -> void:
	_show_result(Game.upgrade_home())
	open_summary("home")


func _on_cat_feed() -> void:
	_show_result(Game.cat_feed())
	open_summary("home")


func _on_buy_cat_toy() -> void:
	_show_result(Game.buy_cat_toy())
	open_summary("home")


func _on_cat_play_toy() -> void:
	_show_result(Game.cat_play_toy())
	open_summary("home")


# ============================================================
#  แผง v7 — ฟาร์ม / งานอดิเรก / รางวัล / ธุรกิจ / สังคม
# ============================================================
func _summary_farm(body: VBoxContainer) -> void:
	_section(body, "สวนหลังบ้าน")
	_kv_grid(body, [
		["พืชพร้อมเก็บ", "%d แปลง" % Game.farm_ready_count()],
		["รดน้ำแล้ววันนี้", "%d/%d แปลง" % [Game.farm_watered_count(), Game.FARM_PLOT_COUNT]],
		["เก็บเกี่ยวสะสม", "%d ครั้ง" % Game.harvest_total],
		["ชื่อเสียง", "%d/100 • %s" % [Game.fame, Game.fame_title()]],
	])
	_label(body, "เดินเข้าสวนหลังบ้านผ่านประตูไม้ด้านซ้ายในบ้าน • ปลูกแล้วต้องรดน้ำทุกวัน พรุ่งนี้จึงโตขึ้น", 11, DIM_TEXT)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	body.add_child(top_row)
	_btn(top_row, "รดน้ำทุกแปลง", _on_water_all, Color(0.28, 0.38, 0.32), 140)

	_sep(body)
	_section(body, "แปลงผัก")
	var stage_names := {
		"empty": "ว่าง", "seed": "เพิ่งหว่าน", "sprout": "แตกใบอ่อน",
		"grown": "กำลังโต", "ready": "พร้อมเก็บ",
	}
	for i in Game.FARM_PLOT_COUNT:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		body.add_child(row)
		var crop_id := Game.farm_crop(i)
		var stage := Game.farm_stage(i)
		var text := "แปลง %d • ว่าง" % (i + 1)
		if crop_id != "":
			var c := Game.crop_data(crop_id)
			var need := maxi(int(c.get("days", 1)), 1)
			text = "แปลง %d • %s (%d/%d วัน)" % [
				i + 1, String(c.get("name", crop_id)),
				int(Game.farm_plot_data(i).get("growth", 0)), need
			]
		var name_l := _label(row, text, 12, TEXT, crop_id != "")
		name_l.custom_minimum_size = Vector2(230, 0)
		var st := _label(row, String(stage_names.get(stage, stage)), 11, DIM_TEXT)
		st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if crop_id != "":
			var watered := bool(Game.farm_plot_data(i).get("watered", false))
			var wb := _btn(row, "รดน้ำ", _on_water_plot.bind(i), Color(0.26, 0.36, 0.42), 68)
			wb.disabled = watered or stage == "ready"
			var hb := _btn(row, "เก็บเกี่ยว", _on_harvest_plot.bind(i), Color(0.32, 0.4, 0.24), 84)
			hb.disabled = stage != "ready"

	_sep(body)
	_section(body, "เมล็ดพันธุ์")
	for cr in Game.CROPS:
		var cid := String(cr["id"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var info := _label(row, "%s • ฿%s • %d วัน • ขาย ฿%s" % [
			String(cr["name"]), Game.fmt_money(int(cr["seed"])), int(cr["days"]),
			Game.fmt_money(int(cr["sell"])),
		], 12, TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_btn(row, "ปลูก", _on_plant_crop.bind(cid), Color(0.36, 0.28, 0.16), 68)


func _on_plant_crop(crop_id: String) -> void:
	var idx := -1
	for i in Game.FARM_PLOT_COUNT:
		if Game.farm_crop(i) == "":
			idx = i
			break
	if idx < 0:
		toast("แปลงเต็มทุกแปลงแล้ว — เก็บเกี่ยวก่อน")
		return
	_show_result(Game.farm_plant(idx, crop_id))
	open_summary("farm")


func _on_water_plot(index: int) -> void:
	_show_result(Game.farm_water(index))
	open_summary("farm")


func _on_water_all() -> void:
	_show_result(Game.farm_water_all())
	open_summary("farm")


func _on_harvest_plot(index: int) -> void:
	_show_result(Game.farm_harvest(index))
	open_summary("farm")


func _summary_hobby(body: VBoxContainer) -> void:
	_section(body, "งานอดิเรก")
	_kv_grid(body, [
		["ตกปลาสะสม", "%d ตัว • %d ชนิด" % [Game.fish_total, Game.fish_caught_kinds()]],
		["ตกปลาวันนี้", "%d/5 ครั้ง" % Game.fish_actions],
		["จับแมลงสะสม", "%d ตัว • %d ชนิด" % [Game.bug_total, Game.bug_caught_kinds()]],
		["จับแมลงวันนี้", "%d/5 ครั้ง" % Game.bug_actions],
	])
	_label(body, "ท่าเรือและจุดจับแมลงอยู่ในสวนหลังบ้าน • ยิ่งมินิเกมได้คะแนนดี ยิ่งมีโอกาสเจอของหายาก", 11, DIM_TEXT)

	_sep(body)
	_section(body, "ชมรมของโรงเรียน")
	if Game.club_id == "":
		_label(body, "ยังไม่ได้เข้าชมรม — เลือกชมรมที่ถูกใจด้านล่าง", 12, DIM_TEXT)
	else:
		var need := Game.club_next_need()
		_kv_grid(body, [
			["ชมรม", Game.club_name()],
			["เลเวล", "%d/4" % Game.club_level],
			["คะแนนชมรม", str(Game.club_points)],
			["เป้าถัดไป", "สูงสุดแล้ว" if need < 0 else "%d คะแนน" % need],
			["กิจกรรมวันนี้", "ทำแล้ว" if Game.club_day == Game.day else "ยังไม่ได้ทำ"],
		])
		var ab := _btn(body, "ทำกิจกรรมชมรม (+ทักษะ/+คะแนน)", _on_club_activity,
			Color(0.36, 0.28, 0.4), 260)
		ab.disabled = Game.club_day == Game.day
	for c in Game.CLUBS:
		var cid := String(c["id"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		_label(col, "%s • %s" % [String(c["name"]), Game.skill_name(String(c["skill"]))], 12, TEXT, true)
		var desc := _label(col, String(c.get("desc", "")), 10, DIM_TEXT)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if Game.club_id == cid:
			_label(row, "อยู่แล้ว", 11, Color("#557044"), true)
		else:
			_btn(row, "สมัคร ฿%s" % Game.fmt_money(int(c["fee"])),
				_on_join_club.bind(cid), Color(0.32, 0.3, 0.24), 108)

	_sep(body)
	_section(body, "เรียนพิเศษ")
	_label(body, "วันละครั้ง • ครั้งละ ฿%s • อายุ %d ปีขึ้นไป" % [
		Game.fmt_money(Game.COURSE_COST), Game.COURSE_MIN_AGE
	], 11, DIM_TEXT)
	for sk in ["academics", "art", "tech"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var info := _label(row, "%s • ตอนนี้ %d/100" % [Game.skill_name(String(sk)), Game.skill_of(String(sk))],
			12, TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cb := _btn(row, "เรียน ฿%s" % Game.fmt_money(Game.COURSE_COST),
			_on_take_course.bind(String(sk)), Color(0.28, 0.34, 0.42), 104)
		cb.disabled = Game.course_day == Game.day


func _on_join_club(id: String) -> void:
	_show_result(Game.join_club(id))
	open_summary("hobby")


func _on_club_activity() -> void:
	_show_result(Game.club_activity())
	open_summary("hobby")


func _on_take_course(skill_id: String) -> void:
	_show_result(Game.take_course(skill_id))
	open_summary("hobby")


func _summary_awards(body: VBoxContainer) -> void:
	_section(body, "ชื่อเสียงและข่าวลือ")
	_kv_grid(body, [
		["ชื่อเสียง", "%d/100 • %s" % [Game.fame, Game.fame_title()]],
		["ข่าวลือวันนี้", Game.rumor_text()],
		["ความสำเร็จ", "%d/%d ปลดล็อก" % [Game.unlocked_achievement_count(), Game.ACHIEVEMENTS.size()]],
		["รางวัลรอรับ", "%d รายการ" % Game.achievement_ready_count()],
	])

	_sep(body)
	_section(body, "ความสำเร็จ")
	for a in Game.ACHIEVEMENTS:
		var aid := String(a["id"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		var unlocked := Game.achievement_unlocked(aid)
		var nm := _label(col, "%s %s" % ["🏆" if unlocked else "🔒", String(a["name"])],
			12, TEXT if unlocked else DIM_TEXT, true)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var desc := _label(col, String(a["desc"]), 10, DIM_TEXT)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if not unlocked:
			_label(row, "ยังไม่ปลดล็อก", 10, DIM_TEXT)
		elif Game.achievement_is_claimed(aid):
			_label(row, "รับแล้ว", 11, Color("#557044"), true)
		else:
			_btn(row, "รับ ฿%s" % Game.fmt_money(int(a["reward"])),
				_on_claim_achievement.bind(aid), Color(0.4, 0.32, 0.18), 108)


func _on_claim_achievement(id: String) -> void:
	_show_result(Game.claim_achievement(id))
	open_summary("awards")


func _summary_quests(body: VBoxContainer) -> void:
	_section(body, "เป้าหมายชีวิต")
	var goal := Game.life_goal_data()
	_label(body, "%s %s" % [String(goal.get("icon", "")), String(goal.get("name", ""))],
		16, Game.life_goal_color(), true)
	var grow := HBoxContainer.new()
	grow.add_theme_constant_override("separation", 8)
	body.add_child(grow)
	_progress(grow, Game.goal_progress(), Game.life_goal_color(), 320, 12)
	var gv := _label(grow, "%d/100 • %s" % [Game.goal_progress(), Game.goal_tier_name()],
		12, TEXT, true)
	gv.custom_minimum_size = Vector2(220, 0)
	var gh := _label(body, Game.goal_hint(), 11, DIM_TEXT)
	gh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_sep(body)
	_section(body, "ภารกิจประจำสัปดาห์")
	for i in Game.quests.size():
		var q := Game.quest_info(i)
		if q.is_empty():
			continue
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 2)
		body.add_child(card)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)
		card.add_child(top)
		var nm := _label(top, "%s — %s" % [
			String(q.get("name", "")), String(q.get("desc", ""))
		], 12, TEXT, true)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label(top, "รางวัล ฿%s" % Game.fmt_money(int(q.get("reward", 0))),
			12, GOLD, true)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		var target := maxi(int(q.get("target", 1)), 1)
		var pct := int(round(float(int(q.get("progress", 0))) / float(target) * 100.0))
		_progress(row, pct, Game.life_goal_color(), 250, 10)
		_label(row, "%d/%d" % [int(q.get("progress", 0)), target], 12, TEXT)
		if bool(q.get("claimed", false)):
			_label(row, "รับแล้ว", 12, Color("#557044"), true)
		elif bool(q.get("complete", false)):
			_btn(row, "รับรางวัล", _on_claim_quest.bind(i), Color(0.36, 0.42, 0.24), 92)
		else:
			_label(row, "กำลังทำ", 11, DIM_TEXT)

	_sep(body)
	_section(body, "ใบประกาศภารกิจ")
	_kv_grid(body, [
		["ภารกิจที่ทำสำเร็จ", "%d ครั้ง" % Game.quest_total_done],
		["ใบประกาศ", "%d/%d ใบ" % [Game.quest_certificate_count(), Game.QUEST_CERTIFICATES.size()]],
	])
	for c in Game.QUEST_CERTIFICATES:
		var cid := String(c.get("id", ""))
		var got := Game.has_quest_certificate(cid)
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 8)
		body.add_child(crow)
		_label(crow, "%s %s" % ["🎖" if got else "🔒", String(c.get("name", ""))],
			12, TEXT if got else DIM_TEXT, true)
		var need := _label(crow, "ทำครบ %d ภารกิจ • รางวัล ฿%s" % [
			int(c.get("need", 0)), Game.fmt_money(int(c.get("reward", 0)))
		], 11, DIM_TEXT)
		need.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if got:
			_label(crow, "ได้รับแล้ว", 11, Color("#557044"), true)


func _on_claim_quest(index: int) -> void:
	_show_result(Game.claim_quest(index))
	open_summary("quests")


func _summary_business(body: VBoxContainer) -> void:
	_section(body, "ร้านของฉัน")
	if Game.business_level <= 0:
		_label(body, "ยังไม่มีร้านเป็นของตัวเอง • เปิดร้านได้เมื่อเป็นผู้ใหญ่และมีเงิน ฿%s" % [
			Game.fmt_money(Game.BUSINESS_OPEN_COST)
		], 12, TEXT)
		_label(body, "ตั้งชื่อร้านแล้วเปิดเลย — จากนั้นเติมสต็อกและเปิดขายรายวัน", 11, DIM_TEXT)
		var name_edit := LineEdit.new()
		name_edit.text = Game.business_name
		name_edit.placeholder_text = "ชื่อร้านของฉัน"
		name_edit.custom_minimum_size = Vector2(320, 30)
		body.add_child(name_edit)
		_btn(body, "เปิดร้าน ฿%s" % Game.fmt_money(Game.BUSINESS_OPEN_COST),
			func() -> void: _on_open_business(name_edit.text), Color(0.36, 0.28, 0.16), 200)
		return

	_label(body, Game.business_name, 16, Color("#8a4a24"), true)
	_kv_grid(body, [
		["ระดับร้าน", "%s (เลเวล %d/4)" % [Game.business_title(), Game.business_level]],
		["สต็อกคงเหลือ", "%d ชิ้น" % Game.business_stock],
		["ราคาขาย", "฿%s/ชิ้น" % Game.fmt_money(Game.business_price())],
		["ขายได้สูงสุด", "%d ชิ้น/วัน" % Game.business_capacity()],
		["ยอดขายรวม", "฿%s" % Game.fmt_money(Game.business_sales_total)],
		["เปิดร้านวันนี้", "แล้ว" if Game.business_day == Game.day else "ยังไม่ได้เปิด"],
	])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	body.add_child(row)
	var run := _btn(row, "เปิดร้านวันนี้", _on_run_business, Color(0.3, 0.4, 0.28), 128)
	run.disabled = Game.business_day == Game.day or Game.business_stock <= 0
	_btn(row, "เติมสต็อก ฿%s" % Game.fmt_money(Game.BUSINESS_RESTOCK_COST),
		_on_restock_business, Color(0.34, 0.3, 0.2), 132)
	if Game.business_level < 4:
		_btn(row, "อัปเกรดร้าน ฿%s" % Game.fmt_money(
			int(Game.BUSINESS_UPGRADE_COSTS[Game.business_level])),
			_on_upgrade_business, Color(0.38, 0.26, 0.32), 148)
	else:
		_label(row, "ร้านระดับสูงสุดแล้ว", 11, Color("#557044"), true)


func _on_open_business(biz_name: String) -> void:
	_show_result(Game.open_business(biz_name))
	open_summary("business")


func _on_restock_business() -> void:
	_show_result(Game.restock_business())
	open_summary("business")


func _on_run_business() -> void:
	_show_result(Game.run_business_day())
	open_summary("business")


func _on_upgrade_business() -> void:
	_show_result(Game.upgrade_business())
	open_summary("business")


func _summary_social(body: VBoxContainer) -> void:
	_section(body, "เพื่อนและสังคม")
	_kv_grid(body, [
		["เพื่อนสนิท (ใจ 60+)", "%d คน" % Game.close_friend_count(60)],
		["เพื่อนคุ้นเคย (ใจ 40+)", "%d คน" % Game.close_friend_count(40)],
		["สังคม", "%d/100" % Game.social],
		["ชื่อเสียง", "%d/100 • %s" % [Game.fame, Game.fame_title()]],
		["ออกไปสังสรรค์วันนี้", "แล้ว" if Game.group_day == Game.day else "ยังไม่ได้"],
	])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	body.add_child(row)
	var gb := _btn(row, "ออกไปสังสรรค์กลุ่ม ฿300", _on_hangout_group, Color(0.34, 0.28, 0.4), 200)
	gb.disabled = Game.group_day == Game.day

	_sep(body)
	_section(body, "ปาร์ตี้ที่บ้าน")
	_kv_grid(body, [
		["จัดปาร์ตี้แล้ว", "%d ครั้ง" % Game.party_count],
		["สัปดาห์นี้", "จัดแล้ว" if Game.party_week == Game.week else "ยังไม่ได้จัด"],
		["ค่าใช้จ่าย", "฿%s" % Game.fmt_money(Game.PARTY_COST)],
	])
	var pb := _btn(body, "จัดปาร์ตี้ที่บ้าน ฿%s" % Game.fmt_money(Game.PARTY_COST),
		_on_host_party, Color(0.4, 0.28, 0.3), 220)
	pb.disabled = Game.party_week == Game.week

	_sep(body)
	_section(body, "คนในเมืองที่สนิทที่สุด")
	var ids: Array = Game.npc_friendship.keys()
	ids.sort_custom(func(a, b) -> bool:
		return int(Game.npc_friendship.get(a, 0)) > int(Game.npc_friendship.get(b, 0))
	)
	var shown := 0
	for npc_id in ids:
		if shown >= 8:
			break
		var val := int(Game.npc_friendship.get(npc_id, 0))
		if val <= 0:
			continue
		shown += 1
		var row2 := HBoxContainer.new()
		row2.add_theme_constant_override("separation", 8)
		body.add_child(row2)
		var npc: Dictionary = TownData.NPCS.get(String(npc_id), {})
		var name_l := _label(row2, String(npc.get("name", npc_id)), 12, TEXT, true)
		name_l.custom_minimum_size = Vector2(130, 0)
		var rank := _label(row2, Game.friendship_rank(String(npc_id)), 11, DIM_TEXT)
		rank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_progress(row2, val, Color("#e08ab0"), 150, 10)
		_label(row2, str(val), 11, DIM_TEXT)


func _on_hangout_group() -> void:
	_show_result(Game.hangout_group())
	open_summary("social")


func _on_host_party() -> void:
	_show_result(Game.host_party())
	open_summary("social")


func _summary_festival(body: VBoxContainer) -> void:
	var fest := Game.festival_today()
	if not fest.is_empty():
		_section(body, "เทศกาลวันนี้")
		_label(body, String(fest["name"]), 17, Color("#8a4a24"), true)
		_label(body, String(fest.get("desc", "")), 12, TEXT)
		_kv_grid(body, [
			["สถานที่", TownData.zone_name(String(fest["zone"]))],
			["รางวัลพื้นฐาน", "฿%s" % Game.fmt_money(int(fest.get("reward", 0)))],
			["เข้าร่วมแล้ว", "ใช่" if Game.festival_attended_today() else "ยังไม่ได้"],
			["รางวัลสะสม", "%d ครั้ง" % Game.festival_wins],
		])
		if not Game.festival_attended_today():
			if String(fest["zone"]) == Game.zone_id:
				_btn(body, "ร่วมเทศกาล + มินิเกม", _on_join_festival, Color(0.45, 0.32, 0.18), 220)
			else:
				_btn(body, "นั่งรถเมล์ไป%s" % TownData.zone_name(String(fest["zone"])),
					_on_festival_go.bind(String(fest["zone"])), Color(0.32, 0.38, 0.26), 220)
		else:
			_label(body, "วันนี้สนุกแล้ว! กลับมาอีกครั้งในฤดูหน้า", 12, Color("#557044"))
	else:
		_section(body, "เทศกาลประจำฤดู")
		_label(body, "ยังไม่ถึงวันเทศกาล — เตรียมตัวไว้แล้วไปร่วมสนุกกับชาวเมือง", 12, DIM_TEXT)
		_label(body, "เทศกาลจัดปีละ 4 ครั้ง ตามฤดูกาล • รางวัลสะสม %d ครั้ง" % Game.festival_wins, 12, TEXT)

	_sep(body)
	_section(body, "ปฏิทินเทศกาล")
	for f in Game.FESTIVALS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var nm := _label(row, "%s %d" % [Game.SEASON_NAMES[int(f["season"])], int(f["day"])], 11, DIM_TEXT)
		nm.custom_minimum_size = Vector2(98, 0)
		var info := _label(row, "%s • %s" % [String(f["name"]), TownData.zone_name(String(f["zone"]))], 12, TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if Game.season == int(f["season"]) and Game.season_day == int(f["day"]):
			_label(row, "วันนี้!", 12, Color("#8a4a24"), true)

	_sep(body)
	_section(body, "บูธเกม")
	_kv_grid(body, [
		["ค่าเล่น", "฿50/ครั้ง"],
		["เล่นวันนี้", "%d/3 ครั้ง" % Game.booth_plays],
		["รางวัล", "฿150–350 ตามคะแนน"],
	])
	_label(body, "บูธเกมอยู่ที่สวนสาธารณะและดาวน์ทาวน์ หรือกดเล่นจากตรงนี้ได้เลย", 11, DIM_TEXT)
	var bb := _btn(body, "เล่นบูธเกม ฿50", _on_booth, Color(0.42, 0.3, 0.2), 170)
	bb.disabled = not Game.can_play_booth()


func _on_booth() -> void:
	if not Game.can_play_booth():
		toast("วันนี้เล่นบูธครบ 3 ครั้งแล้ว")
		return
	if Game.money < 50:
		toast("เงินไม่พอค่าเล่นบูธ (ต้อง ฿50)")
		return
	start_minigame("timing", "บูธเกมเทศกาล", 4, func(score: int) -> void:
		var good := score >= 50
		var quality := 2 if score >= 85 else (1 if score >= 70 else 0)
		_show_result(Game.play_festival_booth(good, quality))
	)


func _on_join_festival() -> void:
	var fest := Game.festival_today()
	if fest.is_empty():
		toast("วันนี้ไม่มีเทศกาล")
		return
	start_minigame(String(fest["kind"]), "เทศกาล • %s" % String(fest["name"]), 4,
		func(score: int) -> void:
			_show_result(Game.join_festival(score))
	)


func _on_festival_go(zone_id: String) -> void:
	close_all()
	travel_requested.emit(zone_id)


func _summary_health(body: VBoxContainer) -> void:
	_section(body, "ร่างกาย")
	_kv_grid(body, [
		["สุขภาพ", "%d/100" % Game.health],
		["ความสุข", "%d/100" % Game.happy],
		["พลังงาน", "%d/100" % Game.energy],
		["ความอิ่ม", "%d/100" % Game.hunger],
		["ความเครียด", "%d/100" % Game.stress],
		["ฟิตเนส", "%d/100" % Game.fitness],
		["อาการป่วย", "%s" % Game.illness if Game.sick else "ปกติ"],
		["ประกัน", "มี" if Game.insurance else "ไม่มี"],
	])
	_sep(body)
	_section(body, "รักษาพยาบาล")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	body.add_child(row)
	_btn(row, "ซื้อยา ฿%d" % Game.COST_MEDICINE, _on_medicine, Color(0.34, 0.32, 0.22), 120)
	_btn(row, "หาหมอ ฿%d" % Game.COST_DOCTOR, _on_doctor, Color(0.2, 0.4, 0.35), 120)
	_btn(row, "ตรวจสุขภาพ ฿%d" % Game.COST_CHECKUP, _on_checkup, Color(0.34, 0.28, 0.22), 130)
	_label(body, "หรือเดินไปโรงพยาบาลในดาวน์ทาวน์เพื่อรักษา", 11, DIM_TEXT)


func _on_medicine() -> void:
	_show_result(Game.buy_medicine())
	open_summary("health")


func _on_doctor() -> void:
	_show_result(Game.see_doctor())
	open_summary("health")


func _on_checkup() -> void:
	_show_result(Game.checkup())
	open_summary("health")


func _summary_love(body: VBoxContainer) -> void:
	_section(body, "ครอบครัว")
	_kv_grid(body, [
		["ความรักพ่อแม่", "%d/100" % Game.parent_love],
		["คนรัก", Game.partner_name if Game.partner_name != "" else "ยังไม่มี"],
		["ความรักคู่", "%d/100" % Game.partner_love],
		["สถานะ", "แต่งงานแล้ว" if Game.married else ("มีคนรัก" if Game.partner_name != "" else "โสด")],
		["ลูก", "%d/3 คน" % Game.children.size()],
	])
	_section(body, "ภาพครอบครัวและลักษณะที่ถ่ายทอด")
	var family_row := HBoxContainer.new()
	family_row.add_theme_constant_override("separation", 8)
	body.add_child(family_row)
	var player_visual := TownArt.player_palette(Game.outfit, Game.character_look())
	_add_family_member_card(family_row, Game.player_name, "คุณ", player_visual, {})
	if Game.partner_name != "":
		Game._ensure_partner_genetics()
		_add_family_member_card(family_row, Game.partner_name,
			"คู่ชีวิต" if Game.married else "คนรัก", Game.partner_look, {})
	for child in Game.children:
		var kid: Dictionary = child
		_add_family_member_card(family_row, String(kid.get("name", "ลูก")),
			"ลูก • อายุ %d" % int(kid.get("age", 0)),
			kid.get("appearance", {}) if typeof(kid.get("appearance", {})) == TYPE_DICTIONARY else {},
			kid.get("traits_from", {}) if typeof(kid.get("traits_from", {})) == TYPE_DICTIONARY else {})
	if Game.children.is_empty():
		_label(body, "ลูกจะได้รับสีผิว สีผม และทรงผมจากยีนของคุณกับคนรัก", 11, DIM_TEXT)
	if Game.partner_name != "":
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		body.add_child(row)
		_btn(row, "ออกเดท ฿%d" % Game.COST_DATE, _on_date_night, Color(0.42, 0.25, 0.36), 120)
		if not Game.married:
			_btn(row, "ขอแต่งงาน ฿%d" % Game.COST_RING, _on_propose, Color(0.45, 0.32, 0.2), 140)
		if Game.age >= Game.ADULT_AGE and Game.age <= 45 and Game.children.size() < 3:
			_btn(row, "วางแผนมีลูก ฿%d" % Game.COST_CHILD, _on_have_child, Color(0.3, 0.4, 0.3), 150)
		elif Game.children.size() >= 3:
			_label(row, "มีลูกครบ 3 คนแล้ว", 11, DIM_TEXT)
		_btn(row, "เลิก", _on_breakup, Color(0.4, 0.2, 0.2), 60)

	if Game.married or not Game.children.is_empty():
		var fam_row := HBoxContainer.new()
		fam_row.add_theme_constant_override("separation", 6)
		body.add_child(fam_row)
		if Game.married and not Game.honeymoon_done:
			_btn(fam_row, "ฮันนีมูน ฿%s" % Game.fmt_money(Game.HONEYMOON_COST),
				_on_honeymoon, Color(0.36, 0.28, 0.26), 156)
		elif Game.honeymoon_done:
			_label(fam_row, "ไปฮันนีมูนกันแล้ว", 11, Color("#557044"), true)
		var ob := _btn(fam_row, "ทริปครอบครัว ฿%s" % Game.fmt_money(Game.FAMILY_OUTING_COST),
			_on_family_outing, Color(0.3, 0.36, 0.3), 168)
		ob.disabled = Game.family_outing_week == Game.week

	_sep(body)
	_section(body, "คนในเมือง")
	for npc_id in TownData.NPCS.keys():
		var npc: Dictionary = TownData.NPCS[npc_id]
		if String(npc.get("kind", "npc")) != "npc":
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var name_l := _label(row, String(npc["name"]), 13, TEXT, true)
		name_l.custom_minimum_size = Vector2(110, 0)
		var rank := _label(row, Game.friendship_rank(npc_id), 12, DIM_TEXT)
		rank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = Game.friendship_of(npc_id)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(160, 10)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("#0c0e14")
		bg.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background", bg)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("#e08ab0")
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill)
		row.add_child(bar)
		var v := _label(row, str(Game.friendship_of(npc_id)), 11, DIM_TEXT)
		v.custom_minimum_size = Vector2(28, 0)
	_label(body, "เดินไปคุย/ให้ของขวัญกับ NPC ในเมืองเพื่อเพิ่มความสัมพันธ์", 11, DIM_TEXT)


func _add_family_member_card(parent: HBoxContainer, person_name: String, role: String,
		look: Dictionary, traits_from: Dictionary) -> void:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(104, 0)
	card.add_theme_constant_override("separation", 2)
	parent.add_child(card)
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(100, 104)
	portrait.size = Vector2(100, 104)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(portrait)
	var palette := {
		"skin": String(look.get("skin", "#f2c39b")),
		"hair": String(look.get("hair", "#3a2a1a")),
		"hair_style": String(look.get("hair_style", "short")),
		"shirt": String(look.get("shirt", "#e8a06a")),
		"pants": String(look.get("pants", "#3d4a6b")),
		"shoes": String(look.get("shoes", "#2a2018")),
		"style": String(look.get("style", "normal")),
		"accessory": String(look.get("accessory", "none")),
		"outfit": String(look.get("outfit", "casual")),
		"expression": "happy",
	}
	portrait.draw.connect(func() -> void:
		portrait.draw_rect(Rect2(1, 2, 98, 100), Color("#d5bd95"))
		portrait.draw_rect(Rect2(3, 1, 94, 98), Color("#f8efd8"))
		portrait.draw_rect(Rect2(6, 4, 88, 92), Color("#e7d5b1"))
		portrait.draw_circle(Vector2(77, 23), 9.0, Color(1.0, 0.88, 0.60, 0.55))
		portrait.draw_circle(Vector2(21, 17), 1.8, Color("#fff9e8"))
		portrait.draw_circle(Vector2(78, 39), 1.4, Color("#fff9e8"))
		TownArt.draw_person(portrait, Vector2(50, 91), palette, 0.88, 0.0, 1, 0.4)
	)
	var name_label := _label(card, person_name, 11, TEXT, true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size.x = 104
	var role_label := _label(card, role, 10, DIM_TEXT)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.custom_minimum_size.x = 104
	if not traits_from.is_empty():
		var source_labels: Array[String] = []
		for pair in [["skin", "ผิว"], ["hair", "สีผม"], ["hair_style", "ทรงผม"]]:
			var source := String(traits_from.get(String(pair[0]), ""))
			if source != "":
				var short_source := "คุณ" if source == "ผู้เล่น" else ("คนรัก" if source == Game.partner_name else source)
				source_labels.append("%s←%s" % [String(pair[1]), short_source])
		var trait_label := _label(card, "\n".join(source_labels), 8, Color("#75634e"))
		trait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trait_label.custom_minimum_size = Vector2(104, 0)


func _on_date_night() -> void:
	_show_result(Game.date_night())
	open_summary("love")


func _on_propose() -> void:
	_show_result(Game.propose())
	open_summary("love")


func _on_have_child() -> void:
	_show_result(Game.have_child())
	open_summary("love")


func _on_breakup() -> void:
	_show_result(Game.break_up())
	open_summary("love")


func _on_honeymoon() -> void:
	_show_result(Game.honeymoon())
	open_summary("love")


func _on_family_outing() -> void:
	_show_result(Game.family_outing())
	open_summary("love")


func _summary_life(body: VBoxContainer) -> void:
	_section(body, "บันทึกชีวิต")
	var count := 0
	for line in Game.life_log:
		if count >= 14:
			break
		_label(body, "• " + String(line), 12, Color("#6a5438"))
		count += 1
	if count == 0:
		_label(body, "ยังไม่มีบันทึก — เริ่มใช้ชีวิตในเมืองได้เลย", 12, DIM_TEXT)
	_sep(body)
	_section(body, "เริ่มใหม่")
	_label(body, "การเริ่มใหม่จะลบชีวิตปัจจุบันทั้งหมด", 12, Color("#a04a3a"))
	var b := _btn(body, "เริ่มชีวิตใหม่", _on_restart, Color(0.45, 0.2, 0.2), 160)
	if _restart_armed:
		b.text = "กดอีกครั้งเพื่อยืนยัน"


func _on_restart() -> void:
	if not _restart_armed:
		_restart_armed = true
		open_summary("life")
		return
	_restart_armed = false
	close_all()
	Game.new_game()
	_gameover_shown = false
	show_creation()


func _summary_outfits(body: VBoxContainer) -> void:
	_section(body, "ตู้เสื้อผ้า")
	for o in Game.OUTFITS:
		var oid := String(o["id"])
		var owned := Game.owns_outfit(oid)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var info := _label(row, "%s • เสน่ห์ %+d • %s" % [
			String(o["name"]), int(o["charm"]), String(o["desc"])
		], 12, TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if Game.outfit == oid:
			var tag := _label(row, "ใส่อยู่", 12, Color("#4a7a4a"))
			tag.custom_minimum_size = Vector2(60, 0)
		elif owned:
			_btn(row, "สวมใส่", _on_equip.bind(oid), Color(0.2, 0.35, 0.3), 76)
		else:
			_btn(row, "ซื้อ ฿%s" % Game.fmt_money(int(o["price"])), _on_buy_outfit.bind(oid),
				Color(0.35, 0.32, 0.2), 110)


func _on_equip(id: String) -> void:
	_show_result(Game.equip_outfit(id))
	open_summary("outfits")


func _on_buy_outfit(id: String) -> void:
	_show_result(Game.buy_outfit(id))
	open_summary("outfits")


# ============================================================
#  รถเมล์
# ============================================================
func open_bus() -> void:
	var body := _open_modal("รถเมล์ • ค่าโดยสาร ฿%d (เด็ก ฿%d)" % [Game.COST_BUS, Game.COST_BUS_CHILD], 560, 380)
	_label(body, "ขึ้นรถเมล์ใช้เวลา 20 นาทีในเกม — เลือกป้ายที่ต้องการ", 12, DIM_TEXT)
	for zid in BUS_ZONES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var nm := _label(row, TownData.zone_name(zid), 14, TEXT, true)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var here: bool = String(zid) == Game.zone_id
		var b := _btn(row, "อยู่ที่นี่" if here else "ไป • ฿%d" % Game.travel_fare(),
			_on_bus_choice.bind(zid), Color(0.36, 0.28, 0.16), 120)
		b.disabled = here
	_label(body, "หรือเดินออกขอบแผนที่เพื่อไปโซนที่ติดกัน", 11, DIM_TEXT)


func _on_bus_choice(zid: String) -> void:
	close_modal()
	travel_requested.emit(zid)


# ============================================================
#  นาฬิกาปลุก / การนอน
# ============================================================
func open_alarm() -> void:
	var body := _open_modal("เข้านอน", 520, 360)
	_label(body, "ตอนนี้ %s • พลังงาน %d/100" % [Game.time_string(), Game.energy], 14, TEXT)
	_label(body, "ตั้งนาฬิกาปลุกแล้วเข้านอนทันที — นอนน้อยจะมีผลกับวันถัดไป", 12, DIM_TEXT)
	for h in [6, 7, 8]:
		var wake: int = int(h) * 60
		var hours := float((wake - Game.time_min + 1440) % 1440) / 60.0
		if hours < 1.0:
			hours += 24.0
		hours = minf(hours, 12.0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		var info := _label(row, "ปลุก %02d:00 • ได้นอน %.1f ชั่วโมง" % [h, hours], 13, TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_btn(row, "นอน", _on_alarm_choice.bind(wake), Color(0.4, 0.3, 0.2), 80)
	var warn := _label(body, "ถ้าเลยเที่ยงคืนจะสลบและมีบทลงโทษ", 11, Color("#a04a3a"))


func _on_alarm_choice(wake: int) -> void:
	close_modal()
	var res := Game.sleep_now(wake)
	toast(String(res.get("message", "")))
	refresh()


# ============================================================
#  บทสนทนา NPC / พ่อแม่
# ============================================================
func _open_dialog(title: String, text: String, buttons: Array, portrait: Dictionary = {}) -> void:
	close_dialog()
	_dialog = Control.new()
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dialog)

	var has_portrait := not portrait.is_empty()
	var panel_h := 202.0 if has_portrait else 176.0
	var panel := PanelContainer.new()
	panel.position = Vector2(60, 528.0 - panel_h)
	panel.size = Vector2(840, panel_h)
	var dsb := _stylebox(Color("#f6ecd8"), Color("#8a5a3a"), 12)
	dsb.set_border_width_all(3)
	dsb.shadow_color = Color(0.10, 0.06, 0.03, 0.35)
	dsb.shadow_size = 6
	panel.add_theme_stylebox_override("panel", dsb)
	_dialog.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	if has_portrait:
		var pv := Control.new()
		pv.custom_minimum_size = Vector2(150, 0)
		pv.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.clip_contents = true
		outer.add_child(pv)
		var ppal: Dictionary = portrait.get("pal", {})
		var pexpr := String(portrait.get("expression", "neutral"))
		var pface := int(portrait.get("face", 1))
		pv.draw.connect(func() -> void:
			var pr := Rect2(Vector2.ZERO, pv.size)
			if pr.size.x < 20.0 or pr.size.y < 20.0:
				pr.size = Vector2(150, 182)
			TownArt.draw_portrait_card(pv, pr, ppal, pexpr,
				Time.get_ticks_msec() / 1000.0, pface)
		)
		_portrait_ctl = pv

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(col)
	_label(col, title, 18, GOLD, true)
	var body := _label(col, text, 14, TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	col.add_child(row)
	for b in buttons:
		var text_b := String(b.get("text", "?"))
		var cb: Callable = b.get("cb", func() -> void: pass)
		var col_b: Color = b.get("color", Color(0.22, 0.26, 0.35))
		var btn := _btn(row, text_b, cb, col_b, 0)
		btn.custom_minimum_size.y = 32
		if bool(b.get("disabled", false)):
			btn.disabled = true
	_close_btn_row(row)
	_sync_pause()


func _close_btn_row(row: HBoxContainer) -> void:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_btn(row, "ปิด", close_dialog, Color(0.34, 0.26, 0.2), 64)


func open_npc_dialog(npc: Dictionary) -> void:
	var npc_id := String(npc.get("id", ""))
	var nm := String(npc.get("name", "?"))
	var lines: Array = npc.get("lines", ["สวัสดี!"])
	var line := String(lines[randi() % lines.size()])
	var rank := Game.friendship_rank(npc_id)
	var text := "“%s”\nใจ: %d/100 • %s" % [line, Game.friendship_of(npc_id), rank]
	var npc_pal := {
		"skin": String(npc.get("skin", "#f2c39b")),
		"hair": String(npc.get("hair", "#2a2118")),
		"shirt": String(npc.get("shirt", "#4aa3ff")),
		"pants": String(npc.get("pants", "#2e3a59")),
		"shoes": "#2a2018",
		"hair_style": String(npc.get("hair_style", "short")),
		"style": String(npc.get("style", "normal")),
		"accessory": String(npc.get("accessory", "none")),
	}
	var f0 := Game.friendship_of(npc_id)
	var npc_expr := "neutral"
	if f0 >= 60 and String(npc.get("dateable", "yes")) == "yes" and not Game.is_child():
		npc_expr = "love"
	elif f0 >= 25:
		npc_expr = "happy"
	var buttons: Array = [
		{"text": "คุย (+ใจ)", "cb": _npc_talk.bind(npc), "color": Color(0.2, 0.35, 0.45)},
		{"text": "ให้ของขวัญ ฿%d" % Game.COST_GIFT, "cb": _npc_gift.bind(npc), "color": Color(0.4, 0.3, 0.22)},
	]
	if String(npc.get("dateable", "yes")) == "yes" and not Game.is_child():
		var date_ok := Game.friendship_of(npc_id) >= 30
		buttons.append({
			"text": "ชวนเดท ฿%d" % Game.COST_DATE_NPC,
			"cb": _npc_date.bind(npc),
			"color": Color(0.42, 0.25, 0.36),
			"disabled": not date_ok,
		})
	_open_dialog(nm, text, buttons, {"pal": npc_pal, "expression": npc_expr})


func _npc_talk(npc: Dictionary) -> void:
	_show_result(Game.npc_talk(npc))
	open_npc_dialog(npc)


func _npc_gift(npc: Dictionary) -> void:
	_show_result(Game.npc_gift(npc))
	open_npc_dialog(npc)


func _npc_date(npc: Dictionary) -> void:
	_show_result(Game.npc_date(npc))
	open_npc_dialog(npc)


func open_parent_dialog(which: String) -> void:
	var is_dad := which == "dad"
	var nm := "พ่อสมชาย" if is_dad else "แม่สมหญิง"
	var lines := ["พ่อบอกให้ตั้งใจเรียน แล้วอย่าลืมกินข้าว", "พ่อเล่าเรื่องวันทำงานให้ฟัง"] if is_dad else [
		"แม่ถามว่าวันนี้เป็นอย่างไรบ้าง", "แม่บอกว่าห้องนอนควรเก็บกวาดบ้าง"
	]
	var line: String = lines[randi() % lines.size()]
	var text := "“%s”\nความรักพ่อแม่: %d/100" % [line, Game.parent_love]
	var buttons: Array = [
		{"text": "คุยด้วย", "cb": _parent_talk.bind(which), "color": Color(0.2, 0.35, 0.45)},
		{"text": "ขอเงินใช้", "cb": _parent_allowance, "color": Color(0.4, 0.35, 0.2)},
		{"text": "กินข้าวเย็นด้วยกัน", "cb": _parent_dinner, "color": Color(0.35, 0.3, 0.22)},
	]
	var pexpr := "happy" if Game.parent_love >= 45 else "neutral"
	_open_dialog(nm, text, buttons, {"pal": _parent_portrait_pal(which), "expression": pexpr})


func _parent_portrait_pal(which: String) -> Dictionary:
	if which == "dad":
		return {
			"skin": "#e8b88a", "hair": "#2a2118", "shirt": "#7a9a7a",
			"pants": "#3a3a48", "shoes": "#4a3a2a", "hair_style": "short",
			"style": "formal", "accessory": "tie", "outfit": "",
		}
	return {
		"skin": "#f2c8a8", "hair": "#4a3020", "shirt": "#c07a8a",
		"pants": "#5a3a5e", "shoes": "#5a3a3a", "hair_style": "bob",
		"style": "chic", "accessory": "earring", "outfit": "",
	}


func _parent_talk(which: String) -> void:
	_show_result(Game.talk_parent(which))
	open_parent_dialog(which)


func _parent_allowance() -> void:
	_show_result(Game.ask_allowance())
	close_dialog()


func _parent_dinner() -> void:
	_show_result(Game.family_dinner())
	close_dialog()


# ============================================================
#  ร้านค้า / บริการ
# ============================================================
func open_shop(kind: String) -> void:
	match kind:
		"store":
			_shop_store()
		"cafe":
			_shop_cafe()
		"mall":
			open_summary("outfits")
		"bank":
			open_summary("money")
		"hospital":
			open_summary("health")
		"gym":
			_shop_gym()
		"bar":
			_shop_bar()
		_:
			open_summary("overview")


func _shop_store() -> void:
	var body := _open_modal("ร้านสะดวกซื้อ", 560, 330)
	_label(body, "ซื้อของกินเติมความอิ่ม — เงินสด ฿%s" % Game.fmt_money(Game.money), 13, DIM_TEXT)
	_shop_row(body, "ขนม/น้ำดื่ม", "อิ่ม +18", Game.COST_SNACK,
		_on_food.bind(Game.COST_SNACK, 18, 2, 15, "ขนมจากร้านสะดวกซื้อ"))
	_shop_row(body, "ข้าวกล่อง", "อิ่ม +32", 120,
		_on_food.bind(120, 32, 3, 20, "ข้าวกล่อง"))
	_shop_row(body, "เครื่องดื่มชูกำลัง", "พลังงาน +? อิ่ม +5", 90,
		_on_food.bind(90, 5, 4, 10, "เครื่องดื่มชูกำลัง"))


func _shop_cafe() -> void:
	var body := _open_modal("คาเฟ่", 560, 330)
	_label(body, "นั่งพักผ่อนหรือสั่งของกิน — เงินสด ฿%s" % Game.fmt_money(Game.money), 13, DIM_TEXT)
	_shop_row(body, "กาแฟลาเต้", "อิ่ม +6 • สุข +3", 80,
		_on_food.bind(80, 6, 3, 30, "กาแฟลาเต้"))
	_shop_row(body, "เค้กสตรอว์เบอร์รี", "อิ่ม +15 • สุข +6", 120,
		_on_food.bind(120, 15, 6, 45, "เค้กสตรอว์เบอร์รี"))
	_shop_row(body, "มื้อกลางวัน", "อิ่ม +35 • สุข +4", 200,
		_on_food.bind(200, 35, 4, 60, "มื้อกลางวันที่คาเฟ่"))


func _shop_row(parent: Node, title: String, desc: String, price: int, cb: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var info := _label(row, "%s • %s" % [title, desc], 13, TEXT)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn(row, "ซื้อ ฿%d" % price, cb, Color(0.25, 0.35, 0.28), 110)


func _on_food(price: int, hunger: int, happy: int, minutes: int, label: String) -> void:
	_show_result(Game.eat_food(price, hunger, happy, minutes, label))
	refresh()


func _shop_gym() -> void:
	var body := _open_modal("โรงยิม", 560, 300)
	if Game.age < 10:
		_label(body, "อายุ 10 ปีขึ้นไปจึงใช้โรงยิมได้ (ตอนนี้อายุ %d)" % Game.age, 14, Color("#a04a3a"))
		return
	_label(body, "ค่าเข้า ฿%d • ฟิตเนส %d/100" % [Game.COST_GYM, Game.fitness], 14, TEXT)
	_label(body, "เล่นมินิเกมกดจังหวะเพื่อออกกำลัง — คะแนนยิ่งสูงยิ่งได้ฟิตเนส", 12, DIM_TEXT)
	_btn(body, "เริ่มออกกำลังกาย ฿%d" % Game.COST_GYM, _start_gym, Color(0.2, 0.45, 0.35), 200)


func _start_gym() -> void:
	if Game.money < Game.COST_GYM:
		toast("เงินไม่พอค่าเข้า gym ฿%d" % Game.COST_GYM)
		return
	close_modal()
	start_minigame("timing", "ออกกำลังกายที่โรงยิม", 4, func(score: int) -> void:
		_show_result(Game.gym_session(score))
	)


func _shop_bar() -> void:
	var body := _open_modal("บาร์ / ไนต์คลับ", 560, 300)
	if Game.is_child():
		_label(body, "ยังเด็กเกินไป — บาร์เปิดสำหรับผู้ใหญ่", 14, Color("#a04a3a"))
		return
	_label(body, "บรรยากาศกลางคืน • ความสุข %d • สังคม %d" % [Game.happy, Game.social], 14, TEXT)
	_btn(body, "สั่งเครื่องดื่ม ฿200", _on_bar_drink, Color(0.4, 0.25, 0.42), 200)


func _on_bar_drink() -> void:
	_show_result(Game.bar_drink())
	refresh()


# ============================================================
#  มินิเกม
# ============================================================
func start_minigame(kind: String, title: String, rounds: int, on_done: Callable) -> void:
	close_all()
	var mg = load("res://scripts/Minigames.gd").new()
	add_child(mg)
	_minigame = mg
	mg.finished.connect(_on_minigame_finished.bind(on_done))
	mg.cancelled.connect(_on_minigame_cancelled)
	mg.start(kind, title, rounds)
	_sync_pause()


func _on_minigame_finished(score: int, on_done: Callable) -> void:
	_minigame = null
	_sync_pause()
	on_done.call(score)
	refresh()


func _on_minigame_cancelled() -> void:
	_minigame = null
	_sync_pause()
	toast("ยกเลิกมินิเกมแล้ว")


# ============================================================
#  สร้างตัวละคร / เกมจบ
# ============================================================
func show_creation() -> void:
	_close_game_over_if_any()
	var body := _open_modal("สร้างชีวิตใหม่", 880, 500)
	_label(body, "เริ่มต้นชีวิตที่อายุ 6 ขวบ — ปรับหน้าตา เลือกผ้าห่อตัวและลักษณะครอบครัว", 13, DIM_TEXT)

	var state := {
		"outfit": "heirloom_blue", "trait": "kind",
		"skin": "warm", "hair": "black", "hair_style": "short",
	}

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)

	# ---------------- ฝั่งซ้าย: ตัวอย่างตัวละคร ----------------
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.custom_minimum_size = Vector2(282, 0)
	columns.add_child(left)

	var preview := Control.new()
	preview.custom_minimum_size = Vector2(276, 300)
	preview.size = Vector2(276, 300)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(preview)
	preview.draw.connect(func() -> void:
		_draw_creation_preview(preview, state)
	)

	var birth_caption := _label(left, "", 12, Color("#6a5438"))
	birth_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var look_caption := _label(left, "", 11, DIM_TEXT)
	look_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var trait_caption := _label(left, "", 11, DIM_TEXT)
	trait_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# ---------------- ฝั่งขวา: ฟอร์ม ----------------
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 7)
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(form)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	form.add_child(name_row)
	var name_l := _label(name_row, "ชื่อ", 14, TEXT)
	name_l.custom_minimum_size = Vector2(74, 0)
	var name_edit := LineEdit.new()
	name_edit.text = Game.suggest_name(Game.gender)
	name_edit.custom_minimum_size = Vector2(320, 34)
	name_edit.add_theme_font_override("font", _font_regular)
	name_edit.add_theme_font_size_override("font_size", 15)
	name_edit.add_theme_color_override("font_color", TEXT)
	name_edit.add_theme_color_override("caret_color", TEXT)
	name_edit.add_theme_stylebox_override("normal", _stylebox(Color("#fff8e8"), Color("#8a5a3a"), 7))
	name_edit.add_theme_stylebox_override("focus", _stylebox(Color("#fffdf4"), Color("#c89a4a"), 7))
	name_row.add_child(name_edit)

	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 7)
	form.add_child(identity_row)
	var gender_l := _label(identity_row, "เพศ", 13, TEXT)
	gender_l.custom_minimum_size = Vector2(38, 0)
	var gender_opt := _make_option(["ชาย", "หญิง", "อื่น ๆ"], 0, 160)
	identity_row.add_child(gender_opt)
	var id_gap := Control.new()
	id_gap.custom_minimum_size = Vector2(16, 0)
	identity_row.add_child(id_gap)
	var wealth_l := _label(identity_row, "ฐานะ", 13, TEXT)
	wealth_l.custom_minimum_size = Vector2(42, 0)
	var wealth_opt := _make_option(["ฐานะยากจน", "ฐานะปานกลาง", "ฐานะร่ำรวย"],
		clampi(Game.family_wealth, 0, 2), 186)
	identity_row.add_child(wealth_opt)

	var birth_row := HBoxContainer.new()
	birth_row.add_theme_constant_override("separation", 10)
	form.add_child(birth_row)
	var birth_l := _label(birth_row, "ผ้าห่อตัว", 13, TEXT)
	birth_l.custom_minimum_size = Vector2(74, 0)
	var birth_names: Array[String] = []
	for o in Game.BIRTH_OUTFITS:
		birth_names.append(String(o["name"]))
	var birth_opt := _make_option(birth_names, 0, 270)
	birth_row.add_child(birth_opt)

	var trait_row := HBoxContainer.new()
	trait_row.add_theme_constant_override("separation", 10)
	form.add_child(trait_row)
	var trait_l := _label(trait_row, "ครอบครัว", 13, TEXT)
	trait_l.custom_minimum_size = Vector2(74, 0)
	var trait_names: Array[String] = []
	for t in Game.PARENT_TRAITS:
		trait_names.append(String(t["name"]))
	var trait_opt := _make_option(trait_names, 0, 300)
	trait_row.add_child(trait_opt)

	var goal_row := HBoxContainer.new()
	goal_row.add_theme_constant_override("separation", 10)
	form.add_child(goal_row)
	var goal_l := _label(goal_row, "เป้าหมายชีวิต", 13, TEXT)
	goal_l.custom_minimum_size = Vector2(74, 0)
	var goal_names: Array[String] = []
	for g in Game.LIFE_GOALS:
		goal_names.append("%s %s" % [String(g.get("icon", "")), String(g.get("name", ""))])
	var goal_opt := _make_option(goal_names, 0, 300)
	goal_row.add_child(goal_opt)
	var goal_caption := _label(form, "", 11, DIM_TEXT)
	goal_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_section(form, "หน้าตา")

	var look_row := HBoxContainer.new()
	look_row.add_theme_constant_override("separation", 6)
	form.add_child(look_row)
	var skin_l := _label(look_row, "ผิว", 13, TEXT)
	skin_l.custom_minimum_size = Vector2(32, 0)
	var skin_names: Array[String] = []
	for t in Game.SKIN_TONES:
		skin_names.append(String(t["name"]))
	var skin_opt := _make_option(skin_names, 1, 136)
	look_row.add_child(skin_opt)
	var skin_sw := ColorRect.new()
	skin_sw.custom_minimum_size = Vector2(22, 22)
	skin_sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	skin_sw.color = Color("#f2c39b")
	look_row.add_child(skin_sw)
	var look_gap := Control.new()
	look_gap.custom_minimum_size = Vector2(12, 0)
	look_row.add_child(look_gap)
	var hair_l := _label(look_row, "สีผม", 13, TEXT)
	hair_l.custom_minimum_size = Vector2(42, 0)
	var hair_names: Array[String] = []
	for h in Game.HAIR_COLORS:
		hair_names.append(String(h["name"]))
	var hair_opt := _make_option(hair_names, 0, 136)
	look_row.add_child(hair_opt)
	var hair_sw := ColorRect.new()
	hair_sw.custom_minimum_size = Vector2(22, 22)
	hair_sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hair_sw.color = Color("#3a2a1a")
	look_row.add_child(hair_sw)

	var style_row := HBoxContainer.new()
	style_row.add_theme_constant_override("separation", 10)
	form.add_child(style_row)
	var style_l := _label(style_row, "ทรงผม", 13, TEXT)
	style_l.custom_minimum_size = Vector2(52, 0)
	var style_names: Array[String] = []
	for hs in Game.HAIR_STYLES:
		style_names.append(String(hs["name"]))
	var style_opt := _make_option(style_names, 0, 176)
	style_row.add_child(style_opt)
	var style_hint := _label(style_row, "เปลี่ยนได้ก่อนเริ่มชีวิต", 11, DIM_TEXT)
	style_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var refresh_look := func() -> void:
		var sid := String(state["skin"])
		var hid := String(state["hair"])
		var stid := String(state["hair_style"])
		skin_sw.color = Color(_skin_hex(sid))
		hair_sw.color = Color(_hair_hex(hid))
		look_caption.text = "ผิว%s • ผม%s • %s" % [
			_look_name(Game.SKIN_TONES, sid),
			_look_name(Game.HAIR_COLORS, hid),
			_look_name(Game.HAIR_STYLES, stid),
		]
		preview.queue_redraw()

	trait_caption.text = _trait_caption_text(Game.PARENT_TRAITS[0])
	birth_caption.text = "%s — %s" % [String(Game.BIRTH_OUTFITS[0]["name"]), String(Game.BIRTH_OUTFITS[0]["desc"])]
	goal_caption.text = _goal_caption_text(Game.LIFE_GOALS[0])

	birth_opt.item_selected.connect(func(idx: int) -> void:
		var o: Dictionary = Game.BIRTH_OUTFITS[idx]
		state["outfit"] = String(o["id"])
		birth_caption.text = "%s — %s" % [String(o["name"]), String(o["desc"])]
		preview.queue_redraw()
	)
	trait_opt.item_selected.connect(func(idx: int) -> void:
		var t: Dictionary = Game.PARENT_TRAITS[idx]
		state["trait"] = String(t["id"])
		trait_caption.text = _trait_caption_text(t)
	)
	goal_opt.item_selected.connect(func(idx: int) -> void:
		goal_caption.text = _goal_caption_text(Game.LIFE_GOALS[idx])
	)
	skin_opt.item_selected.connect(func(idx: int) -> void:
		state["skin"] = String(Game.SKIN_TONES[idx]["id"])
		refresh_look.call()
	)
	hair_opt.item_selected.connect(func(idx: int) -> void:
		state["hair"] = String(Game.HAIR_COLORS[idx]["id"])
		refresh_look.call()
	)
	style_opt.item_selected.connect(func(idx: int) -> void:
		state["hair_style"] = String(Game.HAIR_STYLES[idx]["id"])
		refresh_look.call()
	)

	var hint := _label(form, "ทักษะเริ่มต้นและกรรมพันติดตัวไปตลอดชีวิต — หน้าตาปรับได้ตามใจ", 11, DIM_TEXT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form.add_child(spacer)

	var start := _btn(form, "เริ่มชีวิต!", func() -> void:
		var g := "ชาย"
		match gender_opt.selected:
			1:
				g = "หญิง"
			2:
				g = "อื่น ๆ"
		Game.start_life(name_edit.text, g, wealth_opt.selected,
			String(state["outfit"]), String(state["trait"]),
			String(state["skin"]), String(state["hair"]), String(state["hair_style"]),
			String(Game.LIFE_GOALS[goal_opt.selected]["id"]))
		close_modal()
		toast("เริ่มชีวิตที่อายุ 6 ขวบแล้ว! เดินออกจากบ้านไปโรงเรียนได้เลย")
		life_started.emit()
	, Color(0.32, 0.42, 0.26), 200)
	start.custom_minimum_size.y = 44
	start.add_theme_font_size_override("font_size", 16)
	refresh_look.call()


func _look_name(defs: Array, id: String) -> String:
	for d in defs:
		if String(d.get("id", "")) == id:
			return String(d.get("name", id))
	return id


func _look_hex(defs: Array, id: String, fallback: String) -> String:
	for d in defs:
		if String(d.get("id", "")) == id:
			return String(d.get("hex", fallback))
	return fallback


func _skin_hex(id: String) -> String:
	return _look_hex(Game.SKIN_TONES, id, "#f2c39b")


func _hair_hex(id: String) -> String:
	return _look_hex(Game.HAIR_COLORS, id, "#3a2a1a")


func _trait_caption_text(t: Dictionary) -> String:
	var karma: Dictionary = Game.KARMA_DEFS.get(String(t.get("karma", "warm")), {})
	return "กรรมพัน: %s — %s" % [String(karma.get("name", "")), String(t.get("desc", ""))]


func _goal_caption_text(g: Dictionary) -> String:
	return "เป้าหมาย: %s — %s" % [String(g.get("desc", "")), "ฉากจบจะเปลี่ยนตามคะแนนเป้าหมาย"]


func _make_option(items: Array, selected: int, width: float) -> OptionButton:
	var opt := OptionButton.new()
	for it in items:
		opt.add_item(String(it))
	opt.selected = clampi(selected, 0, maxi(items.size() - 1, 0))
	opt.custom_minimum_size = Vector2(width, 34)
	opt.add_theme_font_override("font", _font_regular)
	opt.add_theme_font_size_override("font_size", 14)
	opt.add_theme_color_override("font_color", TEXT)
	opt.add_theme_color_override("font_hover_color", TEXT)
	opt.add_theme_stylebox_override("normal", _stylebox(Color("#fff8e8"), Color("#8a5a3a"), 7))
	opt.add_theme_stylebox_override("hover", _stylebox(Color("#fffdf4"), Color("#c89a4a"), 7))
	opt.add_theme_stylebox_override("pressed", _stylebox(Color("#f2e4c8"), Color("#8a5a3a"), 7))
	var popup := opt.get_popup()
	popup.add_theme_font_override("font", _font_regular)
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", TEXT)
	popup.add_theme_stylebox_override("panel", _stylebox(Color("#f6ecd8"), Color("#8a5a3a"), 8))
	return opt


func _draw_creation_preview(c: Control, state: Dictionary) -> void:
	var w := maxf(c.size.x, 276.0)
	var h := maxf(c.size.y, 300.0)
	c.draw_rect(Rect2(0, 0, w, h), Color("#e8d8b8"))
	c.draw_rect(Rect2(5, 5, w - 10, h - 10), Color("#f8efd8"))
	# หน้าต่างและแสงเช้า
	c.draw_rect(Rect2(24, 22, 94, 66), Color("#8a5a3a"))
	c.draw_rect(Rect2(29, 27, 84, 56), Color("#b8d8e8"))
	c.draw_rect(Rect2(29, 27, 84, 18), Color("#d8ecf4"))
	c.draw_circle(Vector2(92, 46), 9.0, Color("#f2e6a0"))
	c.draw_line(Vector2(71, 27), Vector2(71, 83), Color("#8a5a3a"), 3.0)
	c.draw_line(Vector2(29, 55), Vector2(113, 55), Color("#8a5a3a"), 3.0)
	# ชั้นวางของ
	c.draw_rect(Rect2(140, 26, 104, 58), Color("#8a5a3a"))
	c.draw_rect(Rect2(145, 31, 94, 48), Color("#f2ddba"))
	for i in 3:
		c.draw_circle(Vector2(163 + i * 28, 56), 7.0, Color(["#e88aa8", "#e8c05a", "#8ac86a"][i]))
	# พื้นไม้
	c.draw_rect(Rect2(5, 206, w - 10, h - 211), Color("#c89a6a"))
	for py in range(212, int(h) - 6, 22):
		c.draw_rect(Rect2(5, py, w - 10, 2), Color("#b0865a"))
	TownArt._ellipse(c, Vector2(w * 0.5, 266), 54.0, 12.0, Color("#e8d0a8"))
	TownArt._ellipse(c, Vector2(w * 0.5, 266), 44.0, 9.0, Color("#f2e0c0"))
	# ตัวละคร
	var outfit := String(state.get("outfit", "heirloom_blue"))
	var look := {
		"skin": _skin_hex(String(state.get("skin", "warm"))),
		"hair": _hair_hex(String(state.get("hair", "black"))),
		"hair_style": String(state.get("hair_style", "short")),
		"expression": "happy",
	}
	var pal := TownArt.player_palette(outfit, look)
	TownArt.draw_person(c, Vector2(w * 0.5, 276), pal, 3.8, 0.0, 1, 1.2)
	# ประกาย
	for i in 5:
		var a := float(i) * TAU / 5.0 + 0.4
		c.draw_circle(Vector2(w * 0.5 + cos(a) * 102.0, 152 + sin(a) * 62.0),
			2.2, Color(1.0, 0.92, 0.62, 0.55))
	c.draw_rect(Rect2(5, 5, w - 10, h - 10), Color(0.55, 0.42, 0.28, 0.0))


func show_game_over() -> void:
	if _gameover_shown:
		return
	_gameover_shown = true
	var ending := Game.life_ending()
	var body := _open_modal("ชีวิตจบแล้ว", 620, 440)
	_label(body, Game.death_cause, 18, Color("#8a3a2a"), true)
	_label(body, "🎖 ฉากจบ: %s" % String(ending.get("title", "")),
		17, Color("#7a4a24"), true)
	_label(body, "อันดับ %s • %s" % [
		String(ending.get("rank", "C")), String(ending.get("tier_name", ""))
	], 12, Game.life_goal_color(), true)
	var edesc := _label(body, String(ending.get("desc", "")), 12, TEXT)
	edesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var erow := HBoxContainer.new()
	erow.add_theme_constant_override("separation", 8)
	body.add_child(erow)
	_progress(erow, int(ending.get("progress", 0)), Game.life_goal_color(), 330, 12)
	_label(erow, "%d/100" % int(ending.get("progress", 0)), 12, TEXT, true)
	_sep(body)
	_kv_grid(body, [
		["เป้าหมายชีวิต", "%s %s" % [Game.life_goal_icon(), Game.life_goal_name()]],
		["ภารกิจสำเร็จ", "%d ครั้ง • ใบประกาศ %d ใบ" % [
			Game.quest_total_done, Game.quest_certificate_count()
		]],
		["อายุ", "%d ปี" % Game.age],
		["วันที่ใช้ชีวิต", "%d วัน" % Game.days_played],
		["เงินคงเหลือ", "฿%s" % Game.fmt_money(Game.money)],
	])
	_btn(body, "เริ่มชีวิตใหม่", func() -> void:
		close_modal()
		Game.new_game()
		_gameover_shown = false
		show_creation()
	, Color(0.4, 0.25, 0.22), 180)


func _close_game_over_if_any() -> void:
	_gameover_shown = false


# ============================================================
#  คีย์ลัด
# ============================================================
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _minigame != null:
				return
			if _dialog != null:
				close_dialog()
			elif _modal != null:
				close_modal()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M:
			if not busy:
				open_summary("overview")
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_B:
			if not busy:
				open_bus()
				get_viewport().set_input_as_handled()
