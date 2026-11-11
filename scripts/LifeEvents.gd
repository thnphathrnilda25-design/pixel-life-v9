class_name LifeEvents
## LifeEvents.gd — คลังเหตุการณ์ชีวิตแบบเลือกตอบ
##
## v3: เพิ่มเหตุการณ์วัยเด็ก (แรกเกิด–17 ปี) และเหตุการณ์การเงิน/ครอบครัว
##
## โครงสร้างเหตุการณ์:
##   id, text, เงื่อนไข (min_age / max_age / min_money / need_job / ...)
##   options: [ {label, cost?, effects?, chance?, success?, fail?} ]
##
## เพิ่มเหตุการณ์ใหม่ = เติมใน EVENTS ได้เลย (ไม่ต้องแก้ที่อื่น)


static var EVENTS := [
	# ================= วัยเด็ก =================
	{
		"id": "first_words",
		"text": "ลูกน้อยเริ่มส่งเสียงอ้อแอ้ พ่อแม่รอฟังคำแรก",
		"max_age": 3,
		"options": [
			{
				"label": "พูดคำว่า 'แม่'",
				"effects": {"happy": 6, "parent_love": 8},
			},
			{
				"label": "พูดคำว่า 'พ่อ'",
				"effects": {"happy": 4, "parent_love": 6},
			},
		],
	},
	{
		"id": "kindergarten",
		"text": "ถึงเวลาเลือกโรงเรียนอนุบาลให้ลูก",
		"min_age": 3,
		"max_age": 5,
		"options": [
			{
				"label": "โรงเรียนเอกชน ฿1,000",
				"cost": 1000,
				"effects": {"edu": 2, "happy": 3, "social": 2},
			},
			{
				"label": "อยู่บ้านกับพ่อแม่",
				"effects": {"happy": 4, "parent_love": 4},
			},
		],
	},
	{
		"id": "bully",
		"text": "มีเพื่อนร่วมชั้นแกล้งคุณที่โรงเรียน",
		"min_age": 6,
		"max_age": 12,
		"options": [
			{
				"label": "บอกคุณครู",
				"chance": 0.7,
				"success": {
					"text": "ครูจัดการให้ เพื่อนหยุดแกล้ง",
					"effects": {"happy": 4, "social": 3, "stress": -4},
				},
				"fail": {
					"text": "ครูไม่ทันเห็น ยังโดนแกล้งต่อ",
					"effects": {"happy": -6, "stress": 5},
				},
			},
			{
				"label": "สู้กลับ",
				"chance": 0.5,
				"success": {
					"text": "ปกป้องตัวเองได้ เพื่อน ๆ ยอมรับ",
					"effects": {"happy": 5, "social": 4, "stress": 4},
				},
				"fail": {
					"text": "บาดเจ็บและถูกทำโทษ",
					"effects": {"health": -5, "happy": -8, "stress": 6},
				},
			},
		],
	},
	{
		"id": "school_trip",
		"text": "โรงเรียนจัดทัศนศึกษาต่างจังหวัด ใช้เงิน ฿500",
		"min_age": 8,
		"max_age": 15,
		"options": [
			{
				"label": "ไปกับเพื่อน ๆ ฿500",
				"cost": 500,
				"effects": {"happy": 8, "social": 4, "stress": -3},
			},
			{
				"label": "ไม่ไป ประหยัดเงิน",
				"effects": {"happy": -4},
			},
		],
	},
	{
		"id": "exam",
		"text": "ใกล้สอบเข้ามัธยม/มหาวิทยาลัยแล้ว",
		"min_age": 14,
		"max_age": 17,
		"options": [
			{
				"label": "อ่านหนังสือหนัก",
				"effects": {"edu": 4, "stress": 8, "happy": -4},
			},
			{
				"label": "ทำตามสบาย",
				"effects": {"happy": 4, "edu": -1, "stress": -2},
			},
		],
	},
	{
		"id": "first_love",
		"text": "คุณเริ่มมีคนที่แอบชอบในโรงเรียน",
		"min_age": 12,
		"max_age": 17,
		"options": [
			{
				"label": "สารภาพรัก",
				"chance": 0.5,
				"success": {
					"text": "เขาก็ชอบคุณเหมือนกัน!",
					"effects": {"happy": 10, "social": 4, "stress": -4},
				},
				"fail": {
					"text": "ถูกปฏิเสธ แต่ยังเป็นเพื่อนกัน",
					"effects": {"happy": -6, "stress": 3},
				},
			},
			{
				"label": "เก็บไว้ในใจ",
				"effects": {"happy": -1, "stress": 2},
			},
		],
	},
	{
		"id": "part_time",
		"text": "มีร้านใกล้บ้านรับเด็กโตไปช่วยงานช่วงปิดเทอม",
		"min_age": 15,
		"max_age": 17,
		"options": [
			{
				"label": "รับงานพิเศษ",
				"effects": {"money": 3000, "energy": -8, "happy": -2, "social": 2},
			},
			{
				"label": "โฟกัสเรียน",
				"effects": {"edu": 2, "happy": 1},
			},
		],
	},

	# ================= วัยผู้ใหญ่ =================
	{
		"id": "invest",
		"text": "เพื่อนเก่าชวนลงทุนเปิดร้านกาแฟ ใช้เงิน ฿3,000",
		"min_age": 20,
		"min_money": 3000,
		"options": [
			{
				"label": "ลงทุน ฿3,000",
				"cost": 3000,
				"chance": 0.45,
				"success": {
					"text": "ร้านกาแฟไปได้ดี! ได้เงินคืน ฿9,000 ☕",
					"effects": {"money": 9000, "happy": 8},
				},
				"fail": {
					"text": "ร้านเจ๊ง เงินหายไป ฿3,000 😢",
					"effects": {"happy": -10, "stress": 5},
				},
			},
			{"label": "ไม่ลงทุน", "effects": {"happy": 2}},
		],
	},
	{
		"id": "overtime",
		"text": "หัวหน้าขอให้ทำโอทีสัปดาห์นี้",
		"need_job": true,
		"options": [
			{
				"label": "รับโอที (+฿1,500)",
				"effects": {"money": 1500, "energy": -15, "stress": 12, "happy": -4},
			},
			{
				"label": "ปฏิเสธ ขอพัก",
				"effects": {"happy": 3, "performance": -5},
			},
		],
	},
	{
		"id": "partner_trip",
		"text": "คนรักชวนไปเที่ยวทะเล ใช้เงิน ฿2,000",
		"need_partner": true,
		"options": [
			{
				"label": "ไปด้วยกัน ฿2,000",
				"cost": 2000,
				"effects": {"happy": 12, "love": 15, "stress": -10},
			},
			{
				"label": "ขอทำงานก่อน",
				"effects": {"love": -12, "happy": -5, "performance": 5},
			},
		],
	},
	{
		"id": "sick",
		"text": "เป็นไข้หนักจนต้องหยุดพัก",
		"options": [
			{
				"label": "ไปหาหมอ ฿800",
				"cost": 800,
				"effects": {"health": 12, "happy": -2},
			},
			{
				"label": "อดทน กินยาเอง",
				"chance": 0.5,
				"success": {"text": "ร่างกายสู้ไหว หายป่วยเอง 💪", "effects": {"health": -4}},
				"fail": {"text": "อาการหนักขึ้น ต้องพักยาว", "effects": {"health": -12, "energy": -15}},
			},
		],
	},
	{
		"id": "lottery",
		"text": "มีคนขายหวยเลขเด็ดในซอย",
		"min_age": 20,
		"options": [
			{
				"label": "ซื้อ ฿100",
				"cost": 100,
				"chance": 0.08,
				"success": {"text": "ถูกรางวัล! +฿20,000 🎉", "effects": {"money": 20000, "happy": 20}},
				"fail": {"text": "ไม่ถูกเลย เสีย ฿100", "effects": {"happy": -3}},
			},
			{"label": "ไม่ซื้อ", "effects": {}},
		],
	},
	{
		"id": "family_ask",
		"text": "น้องขอเงินไปจ่ายค่าเทอม ฿1,500",
		"min_age": 18,
		"options": [
			{
				"label": "ให้ไป ฿1,500",
				"cost": 1500,
				"effects": {"happy": 8, "social": 6, "parent_love": 4},
			},
			{"label": "ปฏิเสธ", "effects": {"happy": -8, "social": -5, "parent_love": -6}},
		],
	},
	{
		"id": "gym_friend",
		"text": "เพื่อนชวนไปฟิตเนสด้วยกัน ฿200",
		"min_age": 10,
		"options": [
			{
				"label": "ไปด้วย ฿200",
				"cost": 200,
				"effects": {"health": 6, "happy": 5, "stress": -6},
			},
			{"label": "ขี้เกียจ", "effects": {"happy": -2}},
		],
	},
	{
		"id": "layoff",
		"text": "บริษัทประกาศปลดพนักงาน ลำดับถัดไปอาจเป็นคุณ",
		"need_job": true,
		"options": [
			{
				"label": "ยอมรับเงื่อนไข รับเงินชดเชย",
				"chance": 0.9,
				"success": {
					"text": "ได้เงินชดเชย ฿8,000 แต่ต้องหางานใหม่",
					"effects": {"money": 8000, "happy": -12, "fired": 1},
				},
				"fail": {"text": "ไม่ได้อะไรเลย ยังต้องหางานใหม่", "effects": {"happy": -5, "fired": 1}},
			},
			{
				"label": "ต่อรองกับหัวหน้า",
				"chance": 0.45,
				"success": {"text": "หัวหน้าช่วยไว้ ได้ทำงานต่อ", "effects": {"happy": 6, "performance": 10}},
				"fail": {"text": "โดนเลิกจ้าง ไม่มีชดเชย", "effects": {"happy": -18, "stress": 10, "fired": 1}},
			},
		],
	},
	{
		"id": "scholarship",
		"text": "อาจารย์เสนอทุนเรียนต่อให้",
		"min_age": 15,
		"max_age": 30,
		"options": [
			{
				"label": "รับทุน",
				"effects": {"edu": 8, "happy": 8, "stress": 5},
			},
			{"label": "ขอทำงานก่อน", "effects": {"happy": -2}},
		],
	},
	{
		"id": "child_school",
		"text": "ลูกขอไปเรียนพิเศษ ฿3,000",
		"need_child": true,
		"options": [
			{
				"label": "จ่ายให้ ฿3,000",
				"cost": 3000,
				"effects": {"happy": 6, "stress": 2},
			},
			{"label": "ยังไม่จ่าย", "effects": {"happy": -6}},
		],
	},
	{
		"id": "car_deal",
		"text": "มีคนขายรถมือสองราคาถูก ฿60,000",
		"min_age": 22,
		"min_money": 60000,
		"options": [
			{
				"label": "ซื้อ ฿60,000",
				"cost": 60000,
				"effects": {"happy": 15, "stress": -6},
			},
			{"label": "ไม่ซื้อ เก็บเงินดีกว่า", "effects": {"happy": 2}},
		],
	},
	{
		"id": "health_check",
		"text": "ถึงเวลาตรวจสุขภาพประจำปี",
		"min_age": 35,
		"options": [
			{
				"label": "ตรวจ ฿800",
				"cost": 800,
				"effects": {"health": 5, "happy": 2},
			},
			{"label": "ไม่ตรวจ", "effects": {"health": -3}},
		],
	},

	{
		"id": "friend_loan",
		"text": "เพื่อนสนิทขอยืมเงิน ฿2,000",
		"min_age": 18,
		"min_money": 2000,
		"options": [
			{
				"label": "ให้ยืม ฿2,000",
				"cost": 2000,
				"chance": 0.6,
				"success": {
					"text": "เพื่อนคืนเงินพร้อมขอบคุณ 🙏",
					"effects": {"money": 2200, "happy": 5, "friend_love": 8},
				},
				"fail": {
					"text": "เพื่อนหายเงียบ ไม่ได้เงินคืน",
					"effects": {"happy": -10, "friend_love": -8},
				},
			},
			{"label": "ปฏิเสธ", "effects": {"happy": -3, "friend_love": -4}},
		],
	},
	{
		"id": "blind_date",
		"text": "เพื่อนจัดเดทให้ ลองไปเจอหน่อยไหม?",
		"min_age": 18,
		"need_no_partner": true,
		"options": [
			{
				"label": "ไปเจอ ฿300",
				"cost": 300,
				"chance": 0.55,
				"success": {"text": "ถูกใจกัน! เริ่มคบกันแล้ว 💕", "effects": {"happy": 12, "partner": 1}},
				"fail": {"text": "ไม่ถูกใจกัน แต่ก็ได้เพื่อนใหม่", "effects": {"happy": -2, "social": 3}},
			},
			{"label": "ไม่ไป", "effects": {}},
		],
	},
	{
		"id": "burnout",
		"text": "ร่างกายส่งสัญญาณเตือน เครียดสะสมมานาน",
		"min_age": 18,
		"min_stress": 70,
		"options": [
			{
				"label": "ลาพักร้อน 1 สัปดาห์",
				"effects": {"stress": -25, "energy": 20, "happy": 6, "performance": -4},
			},
			{
				"label": "ฝืนทำงานต่อ",
				"chance": 0.5,
				"success": {"text": "พอไหวอยู่", "effects": {"stress": 6}},
				"fail": {"text": "ร่างกายพัง ต้องหยุดยาว", "effects": {"health": -14, "energy": -25}},
			},
		],
	},
	{
		"id": "tax_audit",
		"text": "สรรพากรส่งหนังสือตรวจสอบภาษีย้อนหลัง",
		"min_age": 22,
		"need_job": true,
		"options": [
			{
				"label": "จ่ายเพิ่ม ฿2,000",
				"cost": 2000,
				"effects": {"stress": -4, "happy": -2},
			},
			{
				"label": "โต้แย้งกับเจ้าหน้าที่",
				"chance": 0.5,
				"success": {
					"text": "เอกสารครบ จ่ายแค่ ฿500",
					"effects": {"money": -500, "happy": 4},
				},
				"fail": {
					"text": "โดนปรับเพิ่ม ฿4,000",
					"effects": {"money": -4000, "stress": 10, "happy": -6},
				},
			},
		],
	},
	{
		"id": "car_repair",
		"text": "รถที่ใช้อยู่มีเสียงแปลก ๆ ต้องซ่อม",
		"min_age": 22,
		"min_money": 3000,
		"options": [
			{
				"label": "ซ่อมให้เรียบร้อย ฿3,000",
				"cost": 3000,
				"effects": {"happy": 3, "stress": -3},
			},
			{
				"label": "ปล่อยไว้ก่อน",
				"chance": 0.5,
				"success": {"text": "ยังพอวิ่งได้อีกสักพัก", "effects": {"stress": 3}},
				"fail": {"text": "รถเสียกลางทาง เสียทั้งเวลาและเงิน", "effects": {"money": -5000, "stress": 10}},
			},
		],
	},
	{
		"id": "rent_increase",
		"text": "เจ้าของห้องแจ้งขึ้นค่าเช่า ฿500/เดือน",
		"min_age": 20,
		"options": [
			{
				"label": "ยอมจ่ายเพื่ออยู่ต่อ",
				"effects": {"rent": 500, "stress": 4, "happy": -3},
			},
			{
				"label": "ย้ายห้องใหม่ ฿5,000",
				"cost": 5000,
				"chance": 0.7,
				"success": {"text": "ได้ห้องใหม่ถูกกว่าเดิม", "effects": {"rent": -500, "happy": 5, "stress": -5}},
				"fail": {"text": "ห้องใหม่ไม่ถูกใจ ต้องย้ายอีก", "effects": {"happy": -8, "stress": 8}},
			},
		],
	},
	{
		"id": "anniversary",
		"text": "ครบรอบแต่งงานกับคนรัก",
		"need_married": true,
		"options": [
			{
				"label": "ฉลองหรู ฿3,000",
				"cost": 3000,
				"effects": {"love": 15, "happy": 10},
			},
			{
				"label": "ลืมวันครบรอบ",
				"effects": {"love": -15, "happy": -5},
			},
		],
	},
	{
		"id": "child_trouble",
		"text": "ลูกมีปัญหาที่โรงเรียนและไม่ยอมเล่าให้ฟัง",
		"need_child": true,
		"options": [
			{
				"label": "นั่งคุยและให้กำลังใจ",
				"effects": {"happy": 5, "stress": 3},
			},
			{
				"label": "ดุและลงโทษ",
				"chance": 0.4,
				"success": {"text": "ลูกเข้าใจและปรับตัว", "effects": {"happy": 2, "stress": 2}},
				"fail": {"text": "ลูกปิดใจมากขึ้น", "effects": {"happy": -8, "stress": 5}},
			},
		],
	},
	{
		"id": "old_friend",
		"text": "เพื่อนสนิทโทรมาชวนไปกินข้าว",
		"min_age": 18,
		"need_friend": true,
		"options": [
			{
				"label": "ไปเจอกัน ฿500",
				"cost": 500,
				"effects": {"happy": 6, "friend_love": 10, "stress": -5},
			},
			{
				"label": "ไม่ว่าง",
				"effects": {"friend_love": -5, "happy": -2},
			},
		],
	},
	{
		"id": "business_offer",
		"text": "หุ้นส่วนชวนลงทุนธุรกิจใหม่ ฿50,000",
		"min_age": 28,
		"min_money": 50000,
		"options": [
			{
				"label": "ลงทุน ฿50,000",
				"cost": 50000,
				"chance": 0.4,
				"success": {
					"text": "ธุรกิจไปได้ดี! ได้กำไร ฿150,000 🚀",
					"effects": {"money": 150000, "happy": 20},
				},
				"fail": {
					"text": "ธุรกิจเจ๊ง ขาดทุนทั้งหมด",
					"effects": {"happy": -20, "stress": 15},
				},
			},
			{"label": "ปฏิเสธ", "effects": {"happy": 2}},
		],
	},
	{
		"id": "promotion_offer",
		"text": "หัวหน้าเสนอตำแหน่งใหม่ แต่ต้องรับผิดชอบมากขึ้น",
		"need_job": true,
		"min_age": 20,
		"options": [
			{
				"label": "รับตำแหน่ง",
				"effects": {"performance": 10, "stress": 10, "money": 5000},
			},
			{
				"label": "ปฏิเสธ ขอสมดุลชีวิต",
				"effects": {"happy": 4, "performance": -5, "stress": -4},
			},
		],
	},
	{
		"id": "sick_leave",
		"text": "อาการป่วยหนักขึ้นจนต้องตัดสินใจว่าจะลางานหรือฝืนต่อ",
		"need_sick": true,
		"min_age": 18,
		"options": [
			{
				"label": "ลางานไปหาหมอ",
				"cost": 800,
				"effects": {"health": 10, "energy": 8, "performance": -6, "happy": -2},
			},
			{
				"label": "ฝืนทำงานต่อ",
				"chance": 0.55,
				"success": {
					"text": "พอประคองไหว แต่ยังไม่หายดี",
					"effects": {"health": -4, "energy": -8, "money": 900},
				},
				"fail": {
					"text": "ล้มลงกลางกะ ต้องหยุดยาว",
					"effects": {"health": -15, "energy": -20, "happy": -6},
				},
			},
		],
	},
	{
		"id": "debt_call",
		"text": "เจ้าหนี้โทรมาเตือนเรื่องยอดหนี้ที่ค้างอยู่",
		"need_loan": true,
		"min_age": 18,
		"options": [
			{
				"label": "จ่ายคืนบางส่วน ฿2,000",
				"cost": 2000,
				"effects": {"loan": -2500, "stress": -4, "happy": 2},
			},
			{
				"label": "ขอเลื่อนนัด",
				"chance": 0.5,
				"success": {
					"text": "เจ้าหนี้ยอมให้เลื่อนอีกเดือน",
					"effects": {"stress": 4},
				},
				"fail": {
					"text": "ถูกคิดค่าปรับเพิ่ม",
					"effects": {"loan": 1500, "stress": 10, "happy": -4},
				},
			},
		],
	},
	{
		"id": "insurance_offer",
		"text": "บริษัทประกันโทรเสนอแพ็กเกจเสริมสุขภาพ",
		"need_insured": true,
		"min_age": 18,
		"options": [
			{
				"label": "อัปเกรดความคุ้มครอง ฿1,200",
				"cost": 1200,
				"effects": {"health": 4, "happy": 2, "stress": -2},
			},
			{
				"label": "ไม่สนใจ",
				"effects": {},
			},
		],
	},
]


## สุ่มเหตุการณ์ที่เข้าเงื่อนไขตอนนี้
static func pick(g) -> Dictionary:
	var pool: Array = []
	for e in EVENTS:
		if _allowed(e, g):
			pool.append(e)
	if pool.is_empty():
		return {}

	var total := 0.0
	for e in pool:
		total += float(e.get("weight", 1.0))
	var roll := randf() * total
	for e in pool:
		roll -= float(e.get("weight", 1.0))
		if roll <= 0.0:
			return e
	return pool[pool.size() - 1]


static func by_id(id: String) -> Dictionary:
	for e in EVENTS:
		if e["id"] == id:
			return e
	return {}


static func _allowed(e: Dictionary, g) -> bool:
	if e.has("min_age") and g.age < int(e["min_age"]):
		return false
	if e.has("max_age") and g.age > int(e["max_age"]):
		return false
	if e.has("min_money") and g.money < int(e["min_money"]):
		return false
	if e.has("min_stress") and g.stress < int(e["min_stress"]):
		return false
	if e.get("need_job", false) and g.job_id == "":
		return false
	if e.get("need_partner", false) and g.partner_name == "":
		return false
	if e.get("need_no_partner", false) and g.partner_name != "":
		return false
	if e.get("need_married", false) and not g.married:
		return false
	if e.get("need_child", false) and g.children.is_empty():
		return false
	if e.get("need_sick", false) and not g.sick:
		return false
	if e.get("need_insured", false) and not g.insurance:
		return false
	if e.get("need_loan", false) and g.loan <= 0:
		return false
	if e.get("need_friend", false) and g.friend_name == "":
		return false
	return true

