extends Control
## Minigames.gd — มินิเกมสั้น ๆ สำหรับเรียน/ทำงาน/ออกกำลังกาย
## 4 แบบ: timing (กดจังหวะ) / math (ตอบเลข) / sequence (จำลำดับ) / catch (คลิกลูกค้า)
## signal finished(score 0-100)

signal finished(score: int)
signal cancelled

const FONT_NAMES := ["Segoe UI", "Noto Sans Thai", "Leelawadee UI", "Tahoma"]
const PW := 660.0
const PH := 226.0

var active := false
var kind := "timing"
var title_text := ""
var rounds := 4
var _round := 0
var _total := 0.0

var _panel: PanelContainer
var _title: Label
var _hint: Label
var _play: Control
var _score_label: Label
var _action_btn: Button

# timing
var _timing_pos := 0.0
var _timing_dir := 1.0
var _timing_speed := 0.85
var _target_center := 0.5
var _target_width := 0.20
var _locked := false

# math
var _answer_buttons: Array[Button] = []
var _math_answer := 0

# sequence
var _seq: Array[int] = []
var _seq_state := "show"
var _seq_show_i := 0
var _seq_timer := 0.0
var _seq_input_i := 0
var _seq_buttons: Array[Button] = []

# catch
var _catch_left := 0
var _catch_hits := 0
var _catch_timer := 0.0
var _catch_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func start(p_kind: String, p_title: String, p_rounds: int = 4) -> void:
	kind = p_kind
	title_text = p_title
	rounds = maxi(1, p_rounds)
	_round = 0
	_total = 0.0
	active = true
	visible = true
	_build_base()


func _build_base() -> void:
	for ch in get_children():
		ch.queue_free()

	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.08, 0.05, 0.66)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_panel = PanelContainer.new()
	_panel.position = Vector2(130, 64)
	_panel.size = Vector2(700, 412)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#f6ecd8")
	sb.border_color = Color("#8a5a3a")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	sb.shadow_color = Color(0.10, 0.06, 0.03, 0.42)
	sb.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_panel.add_child(col)

	_title = Label.new()
	_title.text = title_text
	_title.add_theme_font_override("font", _font())
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color("#5a3a24"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	_hint = Label.new()
	_hint.add_theme_font_override("font", _font())
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color("#8a7458"))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_hint)

	_play = Control.new()
	_play.custom_minimum_size = Vector2(PW, PH)
	_play.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_play.mouse_filter = Control.MOUSE_FILTER_PASS
	col.add_child(_play)
	_play.draw.connect(_draw_play)

	_score_label = Label.new()
	_score_label.add_theme_font_override("font", _font())
	_score_label.add_theme_font_size_override("font_size", 14)
	_score_label.add_theme_color_override("font_color", Color("#4a7a4a"))
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_score_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)

	_action_btn = Button.new()
	_action_btn.text = "กด!"
	_action_btn.custom_minimum_size = Vector2(180, 44)
	_action_btn.add_theme_font_override("font", _font())
	_action_btn.add_theme_font_size_override("font_size", 18)
	_action_btn.add_theme_color_override("font_color", Color("#f6ecd8"))
	_action_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_action_btn.add_theme_stylebox_override("normal", _button_box(Color("#7a4e32")))
	_action_btn.add_theme_stylebox_override("hover", _button_box(Color("#96603c")))
	_action_btn.add_theme_stylebox_override("pressed", _button_box(Color("#5e3a24")))
	_action_btn.pressed.connect(_on_action)
	row.add_child(_action_btn)

	var cancel := Button.new()
	cancel.text = "ออก"
	cancel.custom_minimum_size = Vector2(96, 44)
	cancel.add_theme_font_override("font", _font())
	cancel.add_theme_font_size_override("font_size", 14)
	cancel.add_theme_color_override("font_color", Color("#f6ecd8"))
	cancel.add_theme_stylebox_override("normal", _button_box(Color("#8a4a3a")))
	cancel.add_theme_stylebox_override("hover", _button_box(Color("#a05a46")))
	cancel.add_theme_stylebox_override("pressed", _button_box(Color("#6e3628")))
	cancel.pressed.connect(_cancel)
	row.add_child(cancel)

	match kind:
		"timing":
			_hint.text = "กดปุ่มเมื่อแถบอยู่กลางช่องสว่าง — ยิ่งใกล้กลางยิ่งคะแนนสูง"
			_action_btn.text = "กดตอนนี้!"
			_reset_timing_round()
		"math":
			_hint.text = "เลือกคำตอบที่ถูกต้อง"
			_action_btn.visible = false
			_build_math()
		"sequence":
			_hint.text = "จำลำดับสี แล้วกดตามให้ครบ"
			_action_btn.visible = false
			_build_sequence()
		"catch":
			_hint.text = "คลิกลูกค้าที่โผล่ขึ้นมาให้ทันเวลา"
			_action_btn.visible = false
			_catch_left = 6
			_catch_hits = 0
			_catch_timer = 0.8
			_update_catch_hint()


func _process(delta: float) -> void:
	if not active:
		return
	match kind:
		"timing":
			if not _locked:
				_timing_pos += _timing_dir * _timing_speed * delta
				if _timing_pos >= 1.0:
					_timing_pos = 1.0
					_timing_dir = -1.0
				elif _timing_pos <= 0.0:
					_timing_pos = 0.0
					_timing_dir = 1.0
				_play.queue_redraw()
		"sequence":
			if _seq_state == "show":
				_seq_timer -= delta
				if _seq_timer <= 0.0:
					_seq_show_i += 1
					_seq_timer = 0.5 if _seq_show_i < _seq.size() else 0.25
					if _seq_show_i >= _seq.size():
						_seq_state = "input"
						_seq_input_i = 0
						_hint.text = "ถึงตาเธอแล้ว — กดตามลำดับ"
						_highlight_seq(-1)
					else:
						_highlight_seq(_seq[_seq_show_i])
				else:
					_highlight_seq(_seq[_seq_show_i])
		"catch":
			_catch_timer -= delta
			if _catch_btn != null and is_instance_valid(_catch_btn):
				if _catch_timer <= 0.0:
					# ลูกค้าออกจากคิวก่อน
					_catch_btn.queue_free()
					_catch_btn = null
					_catch_timer = 0.55
					if _catch_left <= 0:
						_finish()
			elif _catch_timer <= 0.0:
				if _catch_left <= 0:
					_finish()
				else:
					_spawn_customer()


func _draw_play() -> void:
	if kind == "timing":
		var w := _play.size.x
		var h := _play.size.y
		var bar := Rect2(20, h * 0.52 - 26, w - 40, 52)
		_play.draw_rect(Rect2(bar.position.x - 4, bar.position.y - 4, bar.size.x + 8, bar.size.y + 8),
			Color("#d8c6a2"))
		_play.draw_rect(bar, Color("#4a3423"))
		_play.draw_rect(Rect2(bar.position.x, bar.position.y, bar.size.x, 3), Color("#8a6a3a"))
		_play.draw_rect(Rect2(bar.position.x, bar.end.y - 3, bar.size.x, 3), Color("#8a6a3a"))
		var zx := bar.position.x + bar.size.x * _target_center
		var zw := bar.size.x * _target_width
		_play.draw_rect(Rect2(zx - zw * 0.5, bar.position.y + 4, zw, bar.size.y - 8),
			Color(0.55, 0.72, 0.42, 0.55))
		var zw2 := bar.size.x * _target_width * 0.35
		_play.draw_rect(Rect2(zx - zw2 * 0.5, bar.position.y + 4, zw2, bar.size.y - 8),
			Color(0.78, 0.9, 0.58, 0.8))
		var mx := bar.position.x + bar.size.x * _timing_pos
		_play.draw_rect(Rect2(mx - 3, bar.position.y - 10, 6, bar.size.y + 20), Color("#c89a4a"))
		_play.draw_rect(Rect2(mx - 1, bar.position.y - 10, 2, bar.size.y + 20), Color("#fff4d0"))
		# เส้นบอกคะแนน
		_play.draw_rect(Rect2(20, h * 0.78, w - 40, 8), Color("#dccbaa"))
		_play.draw_rect(Rect2(20, h * 0.78, (w - 40) * clampf(_total / float(maxi(rounds, 1)) / 100.0, 0.0, 1.0), 8),
			Color("#6a9a5a"))
		_play.draw_rect(Rect2(20, h * 0.88, w - 40, 8), Color("#dccbaa"))
		_play.draw_rect(Rect2(20, h * 0.88, (w - 40) * float(_round) / float(maxi(rounds, 1)), 8),
			Color("#c89a4a"))
	else:
		_play.draw_rect(Rect2(0, 0, _play.size.x, _play.size.y), Color("#efe0c4"))


func _on_action() -> void:
	if not active:
		return
	match kind:
		"timing":
			_lock_timing()
		"math":
			pass


func _lock_timing() -> void:
	if _locked:
		return
	_locked = true
	var dist := absf(_timing_pos - _target_center)
	var half := _target_width * 0.5
	var acc := 0.0
	if dist <= half:
		acc = 1.0 - (dist / maxf(half, 0.001)) * 0.35
	else:
		acc = clampf(0.55 - (dist - half) * 1.6, 0.0, 0.55)
	var sc := int(round(acc * 100.0))
	_total += float(sc)
	_round += 1
	_score_label.text = "รอบ %d/%d • ได้ %d คะแนน" % [_round, rounds, sc]
	await get_tree().create_timer(0.45).timeout
	if _round >= rounds:
		_finish()
	else:
		_locked = false
		_reset_timing_round()


func _reset_timing_round() -> void:
	_timing_pos = 0.0
	_timing_dir = 1.0
	_timing_speed = 0.75 + float(_round) * 0.12
	_target_center = randf_range(0.25, 0.75)
	_target_width = maxf(0.20 - float(_round) * 0.02, 0.11)
	_locked = false
	_action_btn.disabled = false
	_play.queue_redraw()


# ---------- math ----------
func _build_math() -> void:
	_clear_play()
	_math_answer = _new_math_question()
	_play.queue_redraw()


func _clear_play() -> void:
	for ch in _play.get_children():
		ch.queue_free()


func _new_math_question() -> int:
	var a := randi_range(3, 9 + _round * 3)
	var b := randi_range(2, 9 + _round * 2)
	var op := "+" if _round % 2 == 0 else "−"
	var ans := a + b if op == "+" else a - b
	if op == "−" and b > a:
		var tmp := a
		a = b
		b = tmp
		ans = a - b
	var q := Label.new()
	q.text = "%d %s %d = ?" % [a, op, b]
	q.add_theme_font_override("font", _font())
	q.add_theme_font_size_override("font_size", 40)
	q.add_theme_color_override("font_color", Color("#4a3626"))
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.position = Vector2(0, 24)
	q.size = Vector2(PW, 60)
	_play.add_child(q)

	var opts: Array[int] = [ans]
	while opts.size() < 4:
		var v := ans + randi_range(-9, 9)
		if v == ans or opts.has(v):
			continue
		opts.append(v)
	opts.shuffle()

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	grid.position = Vector2(PW * 0.5 - 230, 100)
	_play.add_child(grid)
	_answer_buttons.clear()
	for v in opts:
		var btn := Button.new()
		btn.text = str(v)
		btn.custom_minimum_size = Vector2(220, 44)
		btn.add_theme_font_override("font", _font())
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", Color("#4a3626"))
		btn.add_theme_color_override("font_hover_color", Color("#3a2414"))
		btn.add_theme_stylebox_override("normal", _button_box(Color("#fff8e8")))
		btn.add_theme_stylebox_override("hover", _button_box(Color("#f2e4c8")))
		btn.add_theme_stylebox_override("pressed", _button_box(Color("#e6d4b0")))
		btn.add_theme_color_override("font_disabled_color", Color("#9a8a70"))
		btn.add_theme_stylebox_override("disabled", _button_box(Color("#e8dcc4")))
		btn.pressed.connect(_on_math_answer.bind(v))
		grid.add_child(btn)
		_answer_buttons.append(btn)
	return ans


func _on_math_answer(v: int) -> void:
	for b in _answer_buttons:
		b.disabled = true
	var correct := v == _math_answer
	var sc := 100 if correct else 0
	_total += float(sc)
	_round += 1
	_score_label.text = "ตอบ%s • รอบ %d/%d" % ["ถูก" if correct else "ผิด", _round, rounds]
	await get_tree().create_timer(0.4).timeout
	if _round >= rounds:
		_finish()
	else:
		_build_math()


# ---------- sequence ----------
func _build_sequence() -> void:
	_clear_play()
	_seq.clear()
	for i in 4:
		_seq.append(randi_range(0, 3))
	_seq_state = "show"
	_seq_show_i = 0
	_seq_timer = 0.9
	_seq_input_i = 0
	_seq_buttons.clear()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.position = Vector2(PW * 0.5 - 230, 24)
	_play.add_child(row)
	var cols := [Color("#c85a52"), Color("#5a88b8"), Color("#d0a03a"), Color("#6a9a5a")]
	for i in 4:
		var btn := Button.new()
		btn.text = str(i + 1)
		btn.custom_minimum_size = Vector2(100, 64)
		btn.add_theme_font_override("font", _font())
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", Color("#fff4d0"))
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		var sb := StyleBoxFlat.new()
		sb.bg_color = cols[i].darkened(0.45)
		sb.set_corner_radius_all(8)
		sb.border_color = cols[i]
		sb.set_border_width_all(2)
		btn.add_theme_stylebox_override("normal", sb)
		var sb2 := sb.duplicate()
		sb2.bg_color = cols[i]
		btn.add_theme_stylebox_override("hover", sb2)
		btn.pressed.connect(_on_seq_button.bind(i))
		row.add_child(btn)
		_seq_buttons.append(btn)

	var dots := Label.new()
	dots.text = "ลำดับ ▶ " + "•".repeat(_seq.size())
	dots.add_theme_font_override("font", _font())
	dots.add_theme_font_size_override("font_size", 18)
	dots.add_theme_color_override("font_color", Color("#8a7458"))
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots.position = Vector2(0, 120)
	dots.size = Vector2(PW, 30)
	_play.add_child(dots)
	_highlight_seq(-1)


func _highlight_seq(idx: int) -> void:
	for i in _seq_buttons.size():
		if _seq_buttons[i] == null or not is_instance_valid(_seq_buttons[i]):
			continue
		_seq_buttons[i].modulate = Color(1, 1, 1, 1) if i == idx else Color(0.7, 0.7, 0.7, 1)


func _on_seq_button(i: int) -> void:
	if _seq_state != "input":
		return
	if i == _seq[_seq_input_i]:
		_seq_input_i += 1
		_score_label.text = "ถูก! %d/%d" % [_seq_input_i, _seq.size()]
		_highlight_seq(i)
		await get_tree().create_timer(0.18).timeout
		_highlight_seq(-1)
		if _seq_input_i >= _seq.size():
			_total += 100.0
			_finish()
	else:
		_total += float(_seq_input_i) / float(_seq.size()) * 100.0
		_score_label.text = "พลาดแล้ว!"
		_finish()


# ---------- catch ----------
func _update_catch_hint() -> void:
	_hint.text = "คลิกลูกค้าที่โผล่ขึ้นมาให้ทันเวลา • เหลือ %d คน" % _catch_left


func _spawn_customer() -> void:
	if _catch_left <= 0:
		_finish()
		return
	_catch_left -= 1
	_update_catch_hint()
	var btn := Button.new()
	btn.text = "🙂"
	btn.custom_minimum_size = Vector2(64, 64)
	btn.size = Vector2(64, 64)
	btn.add_theme_font_size_override("font_size", 26)
	btn.position = Vector2(randf_range(10, PW - 80), randf_range(10, PH - 80))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#f6e0c4")
	sb.set_corner_radius_all(32)
	sb.border_color = Color("#8a5a3a")
	sb.set_border_width_all(3)
	sb.shadow_color = Color(0.14, 0.08, 0.04, 0.3)
	sb.shadow_size = 4
	btn.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = Color("#f8ecd8")
	sbh.border_color = Color("#c89a4a")
	btn.add_theme_stylebox_override("hover", sbh)
	btn.pressed.connect(_on_customer_clicked)
	_play.add_child(btn)
	_catch_btn = btn
	_catch_timer = 1.8


func _on_customer_clicked() -> void:
	_catch_hits += 1
	_total += 100.0 / 6.0
	_score_label.text = "เสิร์ฟแล้ว %d คน" % _catch_hits
	if _catch_btn != null and is_instance_valid(_catch_btn):
		_catch_btn.queue_free()
		_catch_btn = null
	_catch_timer = 0.45
	if _catch_left <= 0:
		_finish()


# ---------- จบ ----------
func _finish() -> void:
	if not active:
		return
	active = false
	var avg := int(round(clampf(_total / float(maxi(rounds, 1)), 0.0, 100.0)))
	if kind == "sequence":
		avg = int(round(clampf(_total, 0.0, 100.0)))
	elif kind == "catch":
		avg = int(round(clampf(_total, 0.0, 100.0)))
	_title.text = "จบแล้ว!"
	_hint.text = "คะแนนรวม %d/100" % avg
	_score_label.text = ""
	await get_tree().create_timer(0.75).timeout
	finished.emit(avg)
	queue_free()


func _cancel() -> void:
	if not active:
		return
	active = false
	cancelled.emit()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if kind == "timing":
				_on_action()
				get_viewport().set_input_as_handled()


func _button_box(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = color.lightened(0.34)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(8)
	sb.shadow_color = Color(0.12, 0.07, 0.03, 0.32)
	sb.shadow_size = 3
	return sb


func _font() -> Font:
	return Fonts.regular()
