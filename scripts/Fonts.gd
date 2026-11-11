extends Node
## Fonts.gd — แหล่งฟอนต์กลางของเกม
## เดสก์ท็อปใช้ฟอนต์ระบบเดิม ส่วนเว็บใช้ฟอนต์ที่ฝังมากับเกม
## เพราะเบราว์เซอร์ไม่เปิดให้ Godot อ่านรายชื่อฟอนต์ในเครื่อง
##
## ฟอนต์ที่ฝังมี 4 ตัว:
##   NotoSansThai     — ไทย + อังกฤษ + ตัวเลข + เครื่องหมายวรรคตอน
##   NotoEmoji        — อีโมจิที่เกมใช้ (ขาวดำ)
##   NotoSansSymbols2 — สัญลักษณ์ที่ฟอนต์อื่นไม่มี (☰, ✕)
##   NotoSansSC       — อักษรจีน 4 ตัวในบทพูดของแต๋ว

const SYSTEM_FONT_NAMES := ["Segoe UI", "Noto Sans Thai", "Leelawadee UI", "Tahoma"]
const REGULAR_PATH := "res://assets/fonts/NotoSansThai-Regular.ttf"
const BOLD_PATH := "res://assets/fonts/NotoSansThai-Bold.ttf"
const FALLBACK_PATHS := [
	"res://assets/fonts/NotoEmoji-Subset.ttf",
	"res://assets/fonts/NotoSansSymbols2-Subset.ttf",
	"res://assets/fonts/NotoSansSC-Subset.ttf",
]

var _regular: Font
var _bold: Font


func _ready() -> void:
	_regular = _make_regular()
	_bold = _make_bold()


func regular() -> Font:
	if _regular == null:
		_regular = _make_regular()
	return _regular


func bold() -> Font:
	if _bold == null:
		_bold = _make_bold()
	return _bold


func _make_regular() -> Font:
	if _use_bundled():
		return _bundled(REGULAR_PATH)
	var f := SystemFont.new()
	f.font_names = PackedStringArray(SYSTEM_FONT_NAMES)
	f.font_weight = 400
	return f


func _make_bold() -> Font:
	if _use_bundled():
		return _bundled(BOLD_PATH)
	var f := SystemFont.new()
	f.font_names = PackedStringArray(SYSTEM_FONT_NAMES)
	f.font_weight = 700
	return f


func _use_bundled() -> bool:
	return OS.has_feature("web") or OS.get_environment("PIXEL_FONT_TEST") == "1"


func _bundled(path: String) -> Font:
	var f: Font = load(path)
	if f == null:
		return null
	var fallbacks: Array[Font] = []
	for p in FALLBACK_PATHS:
		var extra: Font = load(p)
		if extra != null:
			fallbacks.append(extra)
	f.fallbacks = fallbacks
	return f
