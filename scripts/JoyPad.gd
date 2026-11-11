extends Control
## JoyPad.gd — จอยสติ๊กเสมือนสำหรับมือถือ/เมาส์

signal changed(vec: Vector2)

var active := false
var value := Vector2.ZERO
var deadzone := 0.12

var _touch_index := -1


func _ready() -> void:
	custom_minimum_size = Vector2(136, 136)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active = true
			_update(event.position)
			accept_event()
		else:
			_release()
			accept_event()
	elif event is InputEventMouseMotion and active:
		_update(event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			active = true
			_update(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update(event.position)
		accept_event()


func _update(p: Vector2) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 16.0
	var v := (p - center) / maxf(radius, 1.0)
	if v.length() > 1.0:
		v = v.normalized()
	if v.length() < deadzone:
		v = Vector2.ZERO
	value = v
	changed.emit(value)
	queue_redraw()


func _release() -> void:
	active = false
	value = Vector2.ZERO
	changed.emit(value)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 8.0
	# เงาอุ่นใต้จอย
	draw_circle(center + Vector2(0, 3), r, Color(0.14, 0.08, 0.04, 0.28))
	# ฐานไม้
	draw_circle(center, r, Color("#5a4030"))
	draw_circle(center, r - 3.0, Color("#6e4f38"))
	draw_arc(center, r - 1.5, 0, TAU, 44, Color("#3a2a1e"), 3.0, true)
	draw_arc(center, r - 9.0, 0, TAU, 44, Color("#c89a4a"), 2.0, true)
	# แผ่นกระดาษตรงกลาง
	draw_circle(center, r - 20.0, Color("#efe0c4"))
	draw_circle(center, r - 24.0, Color("#f6ecd8"))
	# ปุ่มไม้
	var knob := center + value * (r - 30.0)
	draw_circle(knob + Vector2(0, 2.5), 20.0, Color(0.16, 0.1, 0.05, 0.3))
	draw_circle(knob, 20.0, Color("#8a5a3a"))
	draw_circle(knob, 17.0, Color("#a06e46"))
	draw_arc(knob, 17.0, 0, TAU, 32, Color("#c89a4a"), 2.0, true)
	draw_circle(knob + Vector2(-5, -5), 5.0, Color(1.0, 0.93, 0.78, 0.5))
