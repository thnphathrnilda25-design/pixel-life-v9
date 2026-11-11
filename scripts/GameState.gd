extends Node
## GameState.gd — สมองของเกม (autoload ชื่อ Game)
##
## v4 "เมืองเดินได้":
##  - เริ่มอายุ 6 ขวบ เดินไปโรงเรียน/ทำงาน/นอน/ออกกำลังกายในเมืองจริง
##  - 1 วันจริง ~6 นาที (4 นาทีเกม/วินาทีจริง), 28 วัน = 1 ปี, 4 ฤดู
##  - หลายโซน: บ้าน / ถนน / ย่านโรงเรียน / สวนสาธารณะ / ดาวน์ทาวน์
##  - เงิน/อาชีพ/สุขภาพ/ครอบครัว/ชุด ยังใช้ระบบ v3 เป็นแผงสรุป
##
## ตัวเลขปรับได้ที่ส่วน "ค่าคงที่สมดุลเกม" ด้านล่าง

signal changed
signal time_changed
signal day_changed
signal passed_out

const SAVE_PATH := "user://pixel_life.save"
const SAVE_VERSION := 9
const EVENT_CHANCE := 0.22        # โอกาสเจอเหตุการณ์ต่อสัปดาห์ (วัยผู้ใหญ่)
const CHILD_EVENT_CHANCE := 0.35  # โอกาสเจอเหตุการณ์ต่อปี (วัยเด็ก)
const ADULT_AGE := 18

# ---------- ทักษะชีวิต (v5) ----------
const SKILL_DEFS := {
	"communication": {"name": "การสื่อสาร", "color": "#e0a05a", "desc": "คุยเก่ง เจรจา และสร้างมิตรภาพ"},
	"academics": {"name": "วิชาการ", "color": "#7aa8e0", "desc": "อ่านเขียน คำนวณ และเรียนรู้ไว"},
	"craft": {"name": "งานฝีมือ", "color": "#c08a5a", "desc": "ซ่อมของ ประดิษฐ์ และทำงานช่าง"},
	"cooking": {"name": "ทำอาหาร", "color": "#e08a6a", "desc": "ทำกับข้าวและเบเกอรีอร่อย ๆ"},
	"art": {"name": "ศิลปะ", "color": "#c07ad0", "desc": "วาดรูป ดนตรี และจินตนาการ"},
	"athletics": {"name": "กีฬา", "color": "#6ac08a", "desc": "พละกำลัง ความอดทน และสุขภาพ"},
	"tech": {"name": "เทคโนโลยี", "color": "#6ab8d8", "desc": "คอมพิวเตอร์ เครื่องจักร และโค้ด"},
}
const SKILL_KEYS := ["communication", "academics", "craft", "cooking", "art", "athletics", "tech"]
const TRAIN_COST := 300

# ---------- พ่อแม่ / กรรมพันตอนเกิด (v5) ----------
const PARENT_TRAITS := [
	{"id": "kind", "name": "ใจดีอบอุ่น", "karma": "warm",
		"desc": "พ่อแม่ใจดี เพื่อน ๆ รักใคร่ เริ่มต้นด้วยความรักครอบครัวสูง",
		"parent_love": 12, "happy": 5, "skills": {"communication": 6}},
	{"id": "strict", "name": "เข้มงวดขยัน", "karma": "diligent",
		"desc": "วินัยดี เรียนเก่ง ทำงานขยัน แต่เครียดง่ายกว่าเดิม",
		"academics": 8, "stress": 6, "skills": {"academics": 4}},
	{"id": "artist", "name": "ศิลปินอิสระ", "karma": "dreamer",
		"desc": "บ้านเต็มไปด้วยสีและเสียงเพลง จินตนาการแรงกล้า",
		"happy": 6, "skills": {"art": 8}},
	{"id": "merchant", "name": "ครอบครัวพ่อค้า", "karma": "lucky",
		"desc": "มีเงินติดตัวและเจรจาเก่ง โชคดีเรื่องเงินทอง",
		"money": 2000, "skills": {"communication": 5}},
	{"id": "farmer", "name": "ครอบครัวชาวสวน", "karma": "grounded",
		"desc": "สุขภาพแข็งแรง ใจเย็น ใกล้ชิดธรรมชาติ",
		"health": 5, "skills": {"athletics": 7}},
]
const KARMA_DEFS := {
	"warm": {"name": "กรรมพันแห่งความอบอุ่น", "color": "#e08a9a",
		"desc": "คนรอบข้างใจดีด้วย — คุยกับ NPC ได้ใจเพิ่ม และพ่อแม่รักมาก"},
	"diligent": {"name": "กรรมพันแห่งความขยัน", "color": "#e0b05a",
		"desc": "ทำงานได้ประสิทธิภาพเพิ่ม และเรียนได้เกรดดีขึ้นเล็กน้อย"},
	"dreamer": {"name": "กรรมพันแห่งความฝัน", "color": "#c07ad0",
		"desc": "ฝึกศิลปะได้เร็วกว่า และความสุขเพิ่มง่าย"},
	"lucky": {"name": "กรรมพันแห่งโชคลาภ", "color": "#8ac86a",
		"desc": "สมัครงานและเก็บของสะสมได้โชคดีกว่า"},
	"grounded": {"name": "กรรมพันแห่งแผ่นดิน", "color": "#8ab87a",
		"desc": "ออกกำลังกายได้ผลดี และฟื้นตัวจากการนอนไว"},
}
const BIRTH_OUTFITS := [
	{"id": "heirloom_blue", "name": "ผ้าห่อตัวฟ้า", "desc": "ผ้าฝ้ายฟ้าอ่อน ปักดาวเล็ก ๆ"},
	{"id": "heirloom_rose", "name": "ผ้าห่อตัวชมพู", "desc": "ผ้าไหมชมพูอ่อน เย็บขอบด้วยมือ"},
	{"id": "heirloom_green", "name": "ผ้าห่อตัวเขียว", "desc": "ผ้าทอเขียวใบไม้ กลิ่นหญ้าอ่อน ๆ"},
]

# ---------- ของแต่งบ้าน (v5) ----------
const FURNITURE := [
	{"id": "cozy_lamp", "name": "โคมไฟอบอุ่น", "price": 900, "cozy": 6, "desc": "แสงนวลอุ่นในห้องนอน"},
	{"id": "bookshelf", "name": "ชั้นหนังสือไม้", "price": 1500, "cozy": 8, "desc": "มุมอ่านหนังสือเงียบ ๆ"},
	{"id": "plant", "name": "มุมต้นไม้", "price": 600, "cozy": 5, "desc": "ต้นไม้เล็ก ๆ ริมหน้าต่าง"},
	{"id": "fish_tank", "name": "ตู้ปลา", "price": 2500, "cozy": 10, "happy": 2, "desc": "ปลาหางนกยูงว่ายวนช้า ๆ"},
	{"id": "easel", "name": "ขาตั้งวาดรูป", "price": 1800, "cozy": 7, "skill": "art", "desc": "ฝึกศิลปะที่บ้านได้"},
	{"id": "kitchen", "name": "ครัวไม้", "price": 3200, "cozy": 12, "skill": "cooking", "desc": "ทำอาหารเองได้อร่อยขึ้น"},
	{"id": "cat_bed", "name": "ที่นอนแมว", "price": 1200, "cozy": 6, "pet": true, "desc": "รับแมวน้อยมาเป็นเพื่อน"},
	{"id": "wall_clock", "name": "นาฬิกาไม้", "price": 700, "cozy": 4, "desc": "เสียงติ๊กต็อกอบอุ่น"},
	{"id": "picture", "name": "ภาพครอบครัว", "price": 1000, "cozy": 5, "parent_love": 2, "desc": "ความทรงจำวันดี ๆ"},
	{"id": "rug", "name": "พรมขนนุ่ม", "price": 1400, "cozy": 6, "desc": "เดินเท้าเปล่าแล้วสบาย"},
]
const CAT_NAMES := ["ส้ม", "มะนาว", "ถั่ว", "ขนุน", "ปุย", "เจ้าเหมียว"]

# ---------- ของสะสมตามฤดู (v5) ----------
const COLLECTIBLES := {
	"sakura": {"name": "กลีบซากุระ", "season": 0, "zone": "park"},
	"clover": {"name": "ใบโคลเวอร์", "season": 0, "zone": "downtown"},
	"butterfly": {"name": "ผีเสื้อฤดูใบไม้ผลิ", "season": 0, "zone": "home_street"},
	"shell": {"name": "เปลือกหอย", "season": 1, "zone": "park"},
	"dragonfly": {"name": "แมลงปอ", "season": 1, "zone": "home_street"},
	"sunstone": {"name": "หินสีทอง", "season": 1, "zone": "school_district"},
	"maple": {"name": "ใบเมเปิล", "season": 2, "zone": "park"},
	"acorn": {"name": "ลูกโอ๊ก", "season": 2, "zone": "home_street"},
	"mushroom": {"name": "เห็ดสีส้ม", "season": 2, "zone": "downtown"},
	"snowflake": {"name": "เกล็ดหิมะ", "season": 3, "zone": "park"},
	"icicle": {"name": "น้ำแข็งใส", "season": 3, "zone": "school_district"},
	"postcard": {"name": "โปสการ์ดฤดูหนาว", "season": 3, "zone": "downtown"},
}
const COLLECTION_MILESTONES := [4, 8, 12]

# ---------- เทศกาลประจำฤดู (v5) ----------
const FESTIVALS := [
	{"id": "blossom", "name": "เทศกาลดอกไม้บาน", "season": 0, "day": 5,
		"zone": "park", "kind": "sequence", "reward": 1800,
		"desc": "โคมกระดาษริมสระน้ำ ดนตรีเบา ๆ และดอกไม้ทั้งสวน"},
	{"id": "summer_market", "name": "ตลาดน้ำหน้าร้อน", "season": 1, "day": 6,
		"zone": "downtown", "kind": "catch", "reward": 2200,
		"desc": "แผงอาหาร เครื่องดื่มเย็น และเกมจับของรางวัล"},
	{"id": "harvest", "name": "เทศกาลเก็บเกี่ยว", "season": 2, "day": 5,
		"zone": "park", "kind": "timing", "reward": 2000,
		"desc": "ผลไม้เต็มโต๊ะ การแข่งขันเก็บเกี่ยว และไฟรอบกองฟาง"},
	{"id": "winter_lights", "name": "เทศกาลโคมไฟเหมันต์", "season": 3, "day": 6,
		"zone": "downtown", "kind": "math", "reward": 2600,
		"desc": "โคมไฟหลากสี ของขวัญ และเสียงเพลงกลางหิมะ"},
]

# ---------- v7: ฟาร์มหลังบ้าน ----------
const FARM_PLOT_COUNT := 6
const CROPS := [
	{"id": "lettuce", "name": "ผักกาดหอม", "seed": 50, "days": 3, "sell": 150, "skill": "cooking", "color": "#8ac86a"},
	{"id": "tomato", "name": "มะเขือเทศ", "seed": 80, "days": 4, "sell": 240, "skill": "cooking", "color": "#e0624a"},
	{"id": "corn", "name": "ข้าวโพด", "seed": 110, "days": 5, "sell": 360, "skill": "cooking", "color": "#f2c84a"},
	{"id": "pumpkin", "name": "ฟักทอง", "seed": 160, "days": 6, "sell": 560, "skill": "cooking", "color": "#e8903a"},
	{"id": "strawberry", "name": "สตรอว์เบอร์รี", "seed": 200, "days": 4, "sell": 500, "skill": "cooking", "color": "#e05a7a"},
]
const FARM_PLOT_POSITIONS := [
	Vector2(150, 330), Vector2(235, 330), Vector2(320, 330),
	Vector2(150, 400), Vector2(235, 400), Vector2(320, 400),
]

# ---------- v7: ตกปลา / จับแมลง ----------
const FISH_TABLE := {
	"carp": {"name": "ปลาไน", "value": 90, "rarity": 0},
	"silver": {"name": "ปลาตะเพียนเงิน", "value": 130, "rarity": 0},
	"catfish": {"name": "ปลาดุก", "value": 230, "rarity": 1},
	"koi": {"name": "ปลาคาร์ฟ", "value": 480, "rarity": 2},
	"gold": {"name": "ปลาเงินปลาทอง", "value": 650, "rarity": 2},
	"moon": {"name": "ปลาพระจันทร์", "value": 1400, "rarity": 3},
}
const BUG_TABLE := {
	"butterfly": {"name": "ผีเสื้อลายจุด", "value": 80, "rarity": 0},
	"grasshopper": {"name": "ตั๊กแตนเขียว", "value": 110, "rarity": 0},
	"firefly": {"name": "หิ่งห้อย", "value": 240, "rarity": 1},
	"beetle": {"name": "ด้วงกว่าง", "value": 380, "rarity": 2},
	"gold_dragonfly": {"name": "แมลงปอทอง", "value": 800, "rarity": 3},
}

# ---------- v7: ชมรม / เรียนพิเศษ ----------
const CLUBS := [
	{"id": "art", "name": "ชมรมศิลปะ", "skill": "art", "fee": 300, "color": "#c07ad0",
		"desc": "วาดภาพ ปั้นดิน และจัดนิทรรศการเล็ก ๆ ของชมรม"},
	{"id": "music", "name": "ชมรมดนตรี", "skill": "art", "fee": 400, "color": "#8a7ad0",
		"desc": "ร้องเพลง เล่นกีตาร์ และขึ้นแสดงในงานโรงเรียน"},
	{"id": "sport", "name": "ชมรมกีฬา", "skill": "athletics", "fee": 250, "color": "#6ac08a",
		"desc": "ซ้อมวิ่ง บาสเกตบอล และแข่งกระชับมิตร"},
	{"id": "cooking", "name": "ชมรมทำอาหาร", "skill": "cooking", "fee": 350, "color": "#e08a6a",
		"desc": "ทดลองสูตรขนมและอาหารท้องถิ่น"},
	{"id": "tech", "name": "ชมรมเทคโนโลยี", "skill": "tech", "fee": 450, "color": "#6ab8d8",
		"desc": "หุ่นยนต์เล็ก ๆ เกม และการเขียนโค้ด"},
	{"id": "garden", "name": "ชมรมทำสวน", "skill": "craft", "fee": 200, "color": "#8ab87a",
		"desc": "ดูแลสวนโรงเรียน ปลูกผักและดอกไม้"},
]
const CLUB_LEVEL_POINTS := [0, 9, 22, 40]
const COURSE_COST := 600
const COURSE_MIN_AGE := 10

# ---------- v7: ธุรกิจ ----------
const BUSINESS_OPEN_COST := 12000
const BUSINESS_RESTOCK_COST := 600
const BUSINESS_STOCK_PER_RESTOCK := 30
const BUSINESS_STOCK_PER_DAY := 10

# ---------- v7: บ้าน / ปาร์ตี้ / แมว ----------
const HOME_UPGRADE_COSTS := [0, 6000, 15000, 30000]
const HOME_MAX_LEVEL := 4
const PARTY_COST := 1000
const HONEYMOON_COST := 6000
const FAMILY_OUTING_COST := 700
const CAT_FEED_COST := 60
const CAT_TOY_COST := 450

# ---------- v7: ความสำเร็จ ----------
const ACHIEVEMENTS := [
	{"id": "first_harvest", "name": "มือใหม่หัดปลูก", "desc": "เก็บเกี่ยวพืชผลครั้งแรก", "reward": 500},
	{"id": "green_thumb", "name": "มือเกษตรตัวจริง", "desc": "เก็บเกี่ยวพืชผลครบ 10 ครั้ง", "reward": 1500},
	{"id": "first_fish", "name": "ตกปลาตัวแรก", "desc": "ตกปลาได้อย่างน้อย 1 ตัว", "reward": 500},
	{"id": "master_angler", "name": "นักตกปลาแห่งเมือง", "desc": "ตกปลาครบ 10 ตัว", "reward": 1800},
	{"id": "bug_hunter", "name": "นักล่าแมลง", "desc": "จับแมลงครบ 10 ตัว", "reward": 1200},
	{"id": "collector", "name": "นักสะสมตัวยง", "desc": "สะสมของครบ 12 ชนิด", "reward": 3000},
	{"id": "festival_star", "name": "ดาวเด่นเทศกาล", "desc": "ชนะรางวัลเทศกาลครบ 5 ครั้ง", "reward": 2500},
	{"id": "social_butterfly", "name": "ผีเสื้อสังคม", "desc": "มีเพื่อนสนิท (ใจ 60+) 5 คน", "reward": 1500},
	{"id": "club_master", "name": "หัวหน้าชมรม", "desc": "ชมรมเลเวล 3", "reward": 2000},
	{"id": "business_owner", "name": "เจ้าของร้าน", "desc": "เปิดร้านของตัวเอง", "reward": 1000},
	{"id": "business_tycoon", "name": "นักธุรกิจรุ่นใหม่", "desc": "ยอดขายร้านรวม ฿50,000", "reward": 4000},
	{"id": "home_sweet_home", "name": "บ้านในฝัน", "desc": "อัปเกรดบ้านถึงเลเวล 3", "reward": 2000},
	{"id": "party_animal", "name": "เจ้าของปาร์ตี้", "desc": "จัดปาร์ตี้ที่บ้านครบ 3 ครั้ง", "reward": 1500},
	{"id": "married_life", "name": "คู่ชีวิต", "desc": "แต่งงานกับคนที่รัก", "reward": 1000},
	{"id": "honeymooner", "name": "ฮันนีมูนหวาน", "desc": "ไปฮันนีมูนหลังแต่งงาน", "reward": 1500},
	{"id": "parent_proud", "name": "คุณพ่อคุณแม่", "desc": "มีลูกคนแรก", "reward": 2000},
	{"id": "rich", "name": "เศรษฐีน้อย", "desc": "มีทรัพย์สินเงินสด+ธนาคาร ฿100,000", "reward": 3000},
	{"id": "famous", "name": "คนดังแห่งเมือง", "desc": "ชื่อเสียงถึง 70", "reward": 2500},
	{"id": "all_rounder", "name": "รอบรู้ทุกด้าน", "desc": "ทุกทักษะถึง 50", "reward": 3000},
]

# ---------- v8: เควสต์รายสัปดาห์ / เป้าหมายชีวิต ----------
const QUEST_WEEK_COUNT := 3
const QUEST_POOL := [
	{"id": "harvest3", "name": "เก็บผักให้ครัว", "stat": "harvest", "target": 3, "reward": 420,
		"desc": "เก็บเกี่ยวพืชผลจากแปลงหลังบ้าน 3 ครั้ง"},
	{"id": "harvest6", "name": "สวนขาจร", "stat": "harvest", "target": 6, "reward": 780,
		"desc": "เก็บเกี่ยวพืชผลให้ได้ 6 ครั้งในสัปดาห์นี้"},
	{"id": "fish2", "name": "มื้อปลาเย็นนี้", "stat": "fish", "target": 2, "reward": 400,
		"desc": "ตกปลาให้ได้ 2 ตัว"},
	{"id": "fish4", "name": "นักตกปลาหน้าฝน", "stat": "fish", "target": 4, "reward": 760,
		"desc": "ตกปลาให้ได้ 4 ตัว"},
	{"id": "bug3", "name": "ตามล่าผีเสื้อ", "stat": "bug", "target": 3, "reward": 380,
		"desc": "จับแมลงให้ได้ 3 ตัว"},
	{"id": "school2", "name": "ห้องเรียนขยัน", "stat": "school", "target": 2, "reward": 360,
		"desc": "ไปโรงเรียน 2 วัน"},
	{"id": "school4", "name": "สัปดาห์แห่งความรู้", "stat": "school", "target": 4, "reward": 700,
		"desc": "ไปโรงเรียน 4 วัน"},
	{"id": "work2", "name": "กะพิเศษ", "stat": "work", "target": 2, "reward": 520,
		"desc": "ทำงาน 2 กะ"},
	{"id": "work4", "name": "คนขยันประจำสัปดาห์", "stat": "work", "target": 4, "reward": 980,
		"desc": "ทำงาน 4 กะ"},
	{"id": "talk4", "name": "เพื่อนบ้านทักทาย", "stat": "talk", "target": 4, "reward": 300,
		"desc": "คุยกับผู้คนในเมือง 4 ครั้ง"},
	{"id": "talk7", "name": "ผีเสื้อสังคม", "stat": "talk", "target": 7, "reward": 620,
		"desc": "คุยกับผู้คนในเมือง 7 ครั้ง"},
	{"id": "business1", "name": "เปิดร้านสักวัน", "stat": "business", "target": 1, "reward": 600,
		"desc": "เปิดร้านขายของ 1 วัน"},
	{"id": "club2", "name": "กิจกรรมชมรม", "stat": "club", "target": 2, "reward": 420,
		"desc": "ทำกิจกรรมชมรม 2 ครั้ง"},
	{"id": "collect2", "name": "ของสะสมตามฤดู", "stat": "collect", "target": 2, "reward": 360,
		"desc": "เก็บของสะสมตามฤดู 2 ชิ้น"},
]
const QUEST_CERTIFICATES := [
	{"id": "bronze", "name": "ใบประกาศทองแดง", "need": 5, "reward": 800},
	{"id": "silver", "name": "ใบประกาศเงิน", "need": 12, "reward": 2000},
	{"id": "gold", "name": "ใบประกาศทอง", "need": 24, "reward": 5000},
]
const LIFE_GOALS := [
	{"id": "family", "name": "ครอบครัวอบอุ่น", "icon": "🏡", "color": "#e08a9a",
		"desc": "สร้างบ้านที่เต็มไปด้วยเสียงหัวเราะ ดูแลคนที่รัก และโตไปพร้อมกัน"},
	{"id": "career", "name": "อาชีพมั่นคง", "icon": "💼", "color": "#7aa8e0",
		"desc": "สร้างเนื้อสร้างตัว เก่งงาน เก็บเงิน และมีธุรกิจเป็นของตัวเอง"},
	{"id": "legend", "name": "ตำนานเมือง", "icon": "🌟", "color": "#e0b05a",
		"desc": "เป็นที่รู้จักทั้งเมือง สะสมความสำเร็จ และสร้างเรื่องเล่าให้คนจดจำ"},
]
const GOAL_TIER_NAMES := [
	"เริ่มต้นเส้นทาง", "เส้นทางเริ่มชัด", "ก้าวหน้าอย่างมั่นคง", "ใกล้ถึงความฝัน", "สมบูรณ์แบบ",
]
const LIFE_ENDINGS := {
	"family": [
		{"id": "family_quiet", "title": "บ้านเล็ก ๆ ที่ยังอบอุ่น",
			"desc": "ชีวิตไม่ได้สมบูรณ์แบบทุกอย่าง แต่ทุกมื้อข้าวยังมีคนรออยู่"},
		{"id": "family_warm", "title": "ครอบครัวที่เต็มไปด้วยเสียงหัวเราะ",
			"desc": "ความรักในบ้านค่อย ๆ เติบโตเป็นความทรงจำที่อบอุ่น"},
		{"id": "family_legend", "title": "บ้านหลังใหญ่แห่งความรัก",
			"desc": "ทุกคนในบ้านเติบโตมาพร้อมความรัก และเรื่องเล่านี้จะถูกส่งต่อ"},
	],
	"career": [
		{"id": "career_quiet", "title": "คนทำงานที่ยังเดินต่อไป",
			"desc": "เส้นทางยังอีกไกล แต่ทุกก้าวที่เดินมาล้วนมีความหมาย"},
		{"id": "career_solid", "title": "ชีวิตที่สร้างด้วยมือตัวเอง",
			"desc": "ความมั่นคงที่ได้มาไม่ใช่โชค แต่คือความพยายามทุกวัน"},
		{"id": "career_legend", "title": "เจ้าของตำนานนักสร้าง",
			"desc": "จากมือเปล่าสู่สิ่งที่สร้างขึ้นด้วยตัวเอง — เป็นแรงบันดาลใจให้คนรุ่นหลัง"},
	],
	"legend": [
		{"id": "legend_quiet", "title": "ชื่อเล็ก ๆ ในความทรงจำ",
			"desc": "ยังมีคนจำเรื่องราวของคุณได้ในมุมหนึ่งของเมือง"},
		{"id": "legend_known", "title": "คนที่เมืองจดจำ",
			"desc": "เรื่องเล่าเล็ก ๆ ของคุณถูกพูดถึงในร้านกาแฟและใต้ต้นไม้ใหญ่"},
		{"id": "legend_eternal", "title": "ตำนานที่ไม่มีวันจาง",
			"desc": "ชื่อของคุณกลายเป็นส่วนหนึ่งของเมือง และจะถูกเล่าต่อไปอีกนาน"},
	],
}

# ---------- เวลา / ปฏิทิน v4 ----------
const GAME_MINUTES_PER_REAL_SECOND := 4.0  # 1 วัน (1440 นาที) = 6 นาทีจริง
const DAY_START_MIN := 6 * 60               # ตื่น 06:00
const DAY_END_MIN := 24 * 60                # 24:00 หมดวัน
const DEFAULT_ALARM := 6 * 60
const SCHOOL_START := 8 * 60
const SCHOOL_END := 15 * 60
const WORK_START := 8 * 60
const WORK_END := 17 * 60
const DAYS_PER_SEASON := 7
const SEASONS := ["spring", "summer", "autumn", "winter"]
const SEASON_NAMES := ["ฤดูใบไม้ผลิ", "ฤดูร้อน", "ฤดูใบไม้ร่วง", "ฤดูหนาว"]
const WEEKDAY_NAMES := ["จันทร์", "อังคาร", "พุธ", "พฤหัสบดี", "ศุกร์", "เสาร์", "อาทิตย์"]
const WEATHER_NAMES := {"sun": "แดดออก", "rain": "ฝนตก", "snow": "หิมะตก", "cloud": "เมฆมาก"}

# ---------- ค่าใช้จ่าย v4 ----------
const COST_GYM := 80          # ค่าเข้าโรงยิม/ครั้ง
const COST_SNACK := 60        # ขนม/น้ำดื่มร้านสะดวกซื้อ
const COST_HOME_MEAL := 120   # ข้าวที่บ้าน
const COST_BUS := 15          # ค่ารถเมล์ (ผู้ใหญ่)
const COST_BUS_CHILD := 8     # ค่ารถเมล์ (เด็ก)
const COST_GIFT := 150        # ของขวัญให้ NPC
const COST_DATE_NPC := 300    # เดทกับ NPC
const SHIFT_MINUTES := 8 * 60 # เวลาทำงานต่อกะ (เกม)
const CLASS_MINUTES := 6 * 60 # เวลาเรียนต่อวัน (เกม)
const GYM_MINUTES := 90
const PARK_MINUTES := 60

const MONTHS := [
	"ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.",
	"ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค.",
]

# ---------- ค่าคงที่สมดุลเกม (แก้ตรงนี้ = เกมเปลี่ยน) ----------
const COST_STUDY := 800      # ค่าเล่าเรียน/หนังสือ ต่อสัปดาห์ (วัยผู้ใหญ่)
const COST_EAT := 250        # ค่ากับข้าวต่อสัปดาห์
const COST_SOCIAL := 400     # ออกไปสังสรรค์
const COST_DATE := 300       # ออกเดท
const COST_RING := 5000      # แหวนแต่งงาน
const COST_CHILD := 3000     # ค่าใช้จ่ายเตรียมมีลูก
const COST_RENT := 1800      # ค่าเช่าห้อง/เดือน
const COST_UTIL := 400       # ค่าน้ำค่าไฟ/เดือน
const COST_PHONE := 200      # ค่าโทรศัพท์/เดือน
const COST_TRANSPORT := 600  # ค่าเดินทาง/เดือน
const COST_INSURANCE := 600  # เบี้ยประกันสุขภาพ/เดือน
const COST_PER_CHILD := 700  # ค่าเลี้ยงลูก/เดือน (คนแรก)
const COST_CHILD_SCHOOL := 300  # เพิ่มเมื่อลูกอายุ 6+
const COST_CHILD_TEEN := 400    # เพิ่มเมื่อลูกอายุ 12+
const COST_SHARED := 800     # ค่าใช้จ่ายร่วมเมื่อแต่งงาน
const DAILY_WAGE := 450      # รับจ้างรายวันเมื่อไม่มีงานประจำ
const COST_MEDICINE := 200   # ซื้อยาเอง
const COST_DOCTOR := 800     # หาหมอ
const COST_CHECKUP := 500    # ตรวจสุขภาพ
const WORK_ENERGY := 22
const WORK_STRESS := 12
const PROMO_WEEKS := 16      # ทำงานกี่สัปดาห์ถึงมีสิทธิ์เลื่อนตำแหน่ง
const RETIRE_AGE := 65
const PENSION_RATE := 0.4
const TAX_FREE := 15000      # รายได้/เดือนที่ไม่ต้องเสียภาษี
const TAX_RATE := 0.05       # ภาษี 5% ของส่วนที่เกิน
const LOAN_RATE := 0.015     # ดอกเบี้ยเงินกู้ 1.5%/เดือน
const SAVINGS_RATE := 0.02   # ดอกเบี้ยเงินออม 2%/ปี
const OVERDRAFT_RATE := 0.03 # ดอกเบี้ยเงินสดติดลบ 3%/เดือน

# ---------- ฐานะครอบครัวตอนเกิด ----------
const WEALTH_NAMES := ["ฐานะยากจน", "ฐานะปานกลาง", "ฐานะร่ำรวย"]
const WEALTH_ALLOWANCE := [300, 1500, 6000]     # เงินพ่อแม่ให้ต่อปี
const WEALTH_GIFT := [2000, 20000, 100000]      # เงินก้อนจากพ่อแม่ตอนอายุ 18
const WEALTH_INHERIT := [10000, 150000, 600000] # มรดกตอนพ่อแม่จากไป

# ---------- อาชีพ: เงินเดือน/สัปดาห์ (ระดับ 1) + ทักษะที่ต้องมี ----------
var JOBS := [
	{"id": "store", "title": "พนักงานร้านสะดวกซื้อ", "salary": 1500, "edu": 0,
		"skill": "communication", "skill_req": 0},
	{"id": "waiter", "title": "พนักงานเสิร์ฟ", "salary": 1600, "edu": 5,
		"skill": "communication", "skill_req": 5},
	{"id": "seller", "title": "พนักงานขาย", "salary": 1900, "edu": 10,
		"skill": "communication", "skill_req": 8},
	{"id": "chef", "title": "พ่อครัว", "salary": 2400, "edu": 10,
		"skill": "cooking", "skill_req": 20},
	{"id": "tech", "title": "ช่างเทคนิค", "salary": 2300, "edu": 20,
		"skill": "craft", "skill_req": 12},
	{"id": "designer", "title": "นักออกแบบ", "salary": 3000, "edu": 25,
		"skill": "art", "skill_req": 25},
	{"id": "account", "title": "พนักงานบัญชี", "salary": 2900, "edu": 30,
		"skill": "academics", "skill_req": 15},
	{"id": "nurse", "title": "พยาบาล", "salary": 3400, "edu": 35,
		"skill": "academics", "skill_req": 20},
	{"id": "programmer", "title": "โปรแกรมเมอร์", "salary": 3600, "edu": 30,
		"skill": "tech", "skill_req": 30},
	{"id": "engineer", "title": "วิศวกร", "salary": 3800, "edu": 40,
		"skill": "craft", "skill_req": 22},
	{"id": "vet", "title": "สัตวแพทย์", "salary": 4200, "edu": 45,
		"skill": "academics", "skill_req": 35},
	{"id": "manager", "title": "ผู้จัดการ", "salary": 5500, "edu": 55,
		"skill": "communication", "skill_req": 30},
	{"id": "doctor", "title": "หมอ", "salary": 7000, "edu": 70,
		"skill": "academics", "skill_req": 40},
	{"id": "professor", "title": "อาจารย์มหาวิทยาลัย", "salary": 7500, "edu": 85,
		"skill": "academics", "skill_req": 55},
]

# ---------- ปุ่มกิจกรรมหลัก (คีย์คงที่ 6 ปุ่ม ใช้ทั้งเด็กและผู้ใหญ่) ----------
var ACTIONS := {
	"work": {"label": "ทำงาน", "color": Color("#2f6fd0")},
	"study": {"label": "เรียน", "color": Color("#7a5ad0")},
	"eat": {"label": "กินข้าว", "color": Color("#d08a2f")},
	"rest": {"label": "พักผ่อน", "color": Color("#5b6a92")},
	"gym": {"label": "ออกกำลัง", "color": Color("#2f9e6b")},
	"social": {"label": "สังคม", "color": Color("#d04f7a")},
}

# ---------- ปุ่มactivities ของเด็ก: เด็ก 1 ปีเลือก 1 อย่าง ----------
const CHILD_ACTIONS := {
	"baby": {
		"work": {"label": "ฝึกพูด", "hint": "ฟรี"},
		"study": {"label": "ฟังนิทาน", "hint": "ฟรี"},
		"eat": {"label": "กินนม", "hint": "ฟรี"},
		"rest": {"label": "นอน", "hint": "ฟรี"},
		"gym": {"label": "คลานเล่น", "hint": "ฟรี"},
		"social": {"label": "กอดพ่อแม่", "hint": "ฟรี"},
	},
	"toddler": {
		"work": {"label": "ไปอนุบาล", "hint": "พ่อแม่จ่าย"},
		"study": {"label": "วาดรูป", "hint": "ฟรี"},
		"eat": {"label": "กินข้าว", "hint": "พ่อแม่จ่าย"},
		"rest": {"label": "นอนกลางวัน", "hint": "ฟรี"},
		"gym": {"label": "วิ่งเล่น", "hint": "ฟรี"},
		"social": {"label": "เล่นกับเพื่อน", "hint": "ฟรี"},
	},
	"child": {
		"work": {"label": "ไปโรงเรียน", "hint": "ฟรี"},
		"study": {"label": "ทำการบ้าน", "hint": "ฟรี"},
		"eat": {"label": "กินข้าว", "hint": "พ่อแม่จ่าย"},
		"rest": {"label": "พักผ่อน", "hint": "ฟรี"},
		"gym": {"label": "เล่นกีฬา", "hint": "ฟรี"},
		"social": {"label": "เล่นกับเพื่อน", "hint": "ฟรี"},
	},
	"teen": {
		"work": {"label": "ไปโรงเรียน", "hint": "ฟรี"},
		"study": {"label": "อ่านหนังสือสอบ", "hint": "ฟรี"},
		"eat": {"label": "กินข้าว", "hint": "พ่อแม่จ่าย"},
		"rest": {"label": "พักผ่อน", "hint": "ฟรี"},
		"gym": {"label": "ออกกำลังกาย", "hint": "ฟรี"},
		"social": {"label": "สังสรรค์", "hint": "ฟรี"},
	},
}

# ---------- ชุดแต่งตัว: charm = เสน่ห์, formal = ความเป็นทางการ ----------
const OUTFITS := [
	{"id": "casual", "name": "ชุดลำลอง", "price": 0, "charm": 0, "formal": 0, "desc": "สบาย ๆ ใส่ได้ทุกวัน"},
	{"id": "school", "name": "ชุดนักเรียน", "price": 800, "charm": 2, "formal": 2, "desc": "ดูเรียบร้อย เหมาะกับเรียน"},
	{"id": "sleep", "name": "ชุดนอน", "price": 0, "charm": -2, "formal": -2, "desc": "สบายสุด ๆ แต่ไม่เหมาะออกงาน"},
	{"id": "sport", "name": "ชุดออกกำลัง", "price": 1200, "charm": 3, "formal": 0, "desc": "คล่องตัว ใส่ไปฟิตเนส"},
	{"id": "cozy", "name": "ชุดไหมพรมอบอุ่น", "price": 1800, "charm": 4, "formal": 1, "desc": "ถักหนานุ่ม สีครีมน้ำผึ้ง"},
	{"id": "raincoat", "name": "เสื้อกันฝน", "price": 2200, "charm": 3, "formal": 1, "desc": "กันฝนได้ แถมดูน่ารัก"},
	{"id": "work", "name": "ชุดทำงาน", "price": 2500, "charm": 6, "formal": 6, "desc": "ดูมืออาชีพ สมัครงานผ่านง่ายขึ้น"},
	{"id": "winter", "name": "ชุดกันหนาว", "price": 3200, "charm": 5, "formal": 3, "desc": "อบอุ่นทั้งตัวสำหรับฤดูหิมะ"},
	{"id": "thai", "name": "ชุดไทยประยุกต์", "price": 4500, "charm": 9, "formal": 7, "desc": "ผ้าไหมสีทอง งามสง่าในงานเทศกาล"},
	{"id": "party", "name": "ชุดออกงาน", "price": 6000, "charm": 10, "formal": 3, "desc": "เด่นในงานสังสรรค์"},
	{"id": "luxury", "name": "ชุดแบรนด์เนม", "price": 20000, "charm": 18, "formal": 8, "desc": "หรูหรา มีเสน่ห์มาก"},
	{"id": "heirloom_blue", "name": "ผ้าห่อตัวฟ้า", "price": 0, "charm": 1, "formal": 0, "desc": "ชุดแรกเกิดจากพ่อแม่ — เก็บไว้เป็นความทรงจำ"},
	{"id": "heirloom_rose", "name": "ผ้าห่อตัวชมพู", "price": 0, "charm": 1, "formal": 0, "desc": "ชุดแรกเกิดจากพ่อแม่ — เก็บไว้เป็นความทรงจำ"},
	{"id": "heirloom_green", "name": "ผ้าห่อตัวเขียว", "price": 0, "charm": 1, "formal": 0, "desc": "ชุดแรกเกิดจากพ่อแม่ — เก็บไว้เป็นความทรงจำ"},
]

# ---------- v6: ปรับแต่งหน้าตาตัวละคร ----------
const SKIN_TONES := [
	{"id": "light", "name": "ผิวขาวนวล", "hex": "#f6d5b6"},
	{"id": "warm", "name": "ผิวอุ่น", "hex": "#f2c39b"},
	{"id": "tan", "name": "ผิวสองสี", "hex": "#dca578"},
	{"id": "deep", "name": "ผิวน้ำผึ้ง", "hex": "#b87a52"},
	{"id": "dark", "name": "ผิวเข้ม", "hex": "#8a5a3a"},
]

const HAIR_COLORS := [
	{"id": "black", "name": "ดำธรรมชาติ", "hex": "#3a2a1a"},
	{"id": "brown", "name": "น้ำตาลเข้ม", "hex": "#4a3020"},
	{"id": "chestnut", "name": "เกาลัด", "hex": "#6a3a24"},
	{"id": "honey", "name": "น้ำผึ้ง", "hex": "#a06a3a"},
	{"id": "blonde", "name": "บลอนด์", "hex": "#d8b06a"},
	{"id": "auburn", "name": "แดงทอง", "hex": "#8a3a2a"},
	{"id": "silver", "name": "เงิน", "hex": "#a8a8a8"},
	{"id": "rose", "name": "ชมพูอ่อน", "hex": "#d88a9a"},
]

const HAIR_STYLES := [
	{"id": "short", "name": "ผมสั้น"},
	{"id": "bob", "name": "ผมบ๊อบ"},
	{"id": "long", "name": "ผมยาว"},
	{"id": "ponytail", "name": "หางม้า"},
	{"id": "bun", "name": "มวยผม"},
	{"id": "curly", "name": "ผมหยิก"},
	{"id": "messy", "name": "ผมยุ่ง"},
	{"id": "bald", "name": "หัวโล้น"},
]

# ---------- สถานะชีวิต ----------
var created := false
var player_name := ""
var gender := "ชาย"
var family_wealth := 1

var age := 0
var month := 1
var week := 1
var money := 0
var bank := 0
var loan := 0
var insurance := false
var health := 85
var happy := 75
var energy := 90
var hunger := 80
var stress := 10
var edu := 0
var social := 20
var alive := true
var death_cause := ""
var last_message := ""

# สุขภาพ
var sick := false
var illness := ""
var sick_weeks := 0

# อาชีพ
var job_id := ""
var job_level := 1
var job_weeks := 0
var performance := 50
var retired := false
var last_salary := 0

# ความสัมพันธ์ / ครอบครัว
var partner_name := ""
var partner_love := 0
var married := false
var children: Array = []
var partner_npc_id := ""
var partner_look: Dictionary = {}
var partner_genes: Dictionary = {}
var player_genes: Dictionary = {}
var parent_love := 70
var friend_name := ""
var friend_love := 0
var inherited := false
var rent_extra := 0  # ค่าเช่าที่เพิ่มขึ้นจากเหตุการณ์ (0 = ราคาปกติ)

# แต่งตัว
var outfit := "casual"
var owned_outfits: Array[String] = ["casual", "sleep"]
# v6: หน้าตาที่ปรับแต่งได้ (ค่าว่าง = ใช้สีจากชุดตามเดิม)
var skin_tone := ""
var hair_color := ""
var hair_style := ""

var tax_paid := 0
var life_log: Array[String] = []
var pending_event := {}

# ---------- สถานะโลก v4 ----------
var time_min := DAY_START_MIN
var day := 1
var weekday := 1                  # 1 = จันทร์ ... 7 = อาทิตย์
var season := 0                   # 0 ใบไม้ผลิ, 1 ร้อน, 2 ใบไม้ร่วง, 3 หนาว
var season_day := 1               # วันที่ 1-7 ของฤดู
var days_played := 0
var weather := "sun"
var alarm_min := DEFAULT_ALARM
var time_paused := false
var sleeping := false
var zone_id := "home"
var player_pos := Vector2(480, 420)

# ---------- โรงเรียน ----------
var grades := 50
var school_absences := 0
var school_attended_today := false
var school_days := 0
var graduated := false

# ---------- งาน / ฟิตเนส ----------
var worked_today := false
var work_absences := 0
var job_shifts := 0
var fitness := 30

# ---------- NPC / ครอบครัว ----------
var npc_friendship := {}
var npc_talked := {}
var npc_gifted := {}
var parent_talked := {}
var allowance_week := -1
var dinner_day := -1
var adult_gift := false
var last_sleep_hours := 0.0

# ---------- v5: ทักษะ / เกิด / บ้าน / สะสม / เทศกาล ----------
var skills := {}
var birth_outfit := "heirloom_blue"
var parent_trait := "kind"
var karma_id := "warm"
var home_items: Array[String] = []
var pet_name := ""
var pet_happy := 0
var pet_day := -1
var collections := {}
var collect_day := -1
var collection_milestone := 0
var festival_attended := {}
var festival_wins := 0
var train_day := -1
var bench_day := -1

# ---------- v7: ฟาร์ม / งานอดิเรก / ธุรกิจ / ชมรม / ชื่อเสียง / บ้าน ----------
var farm_plots: Array = []
var harvest_total := 0
var fish_catches := {}
var bug_catches := {}
var fish_total := 0
var bug_total := 0
var fish_actions := 0
var bug_actions := 0
var fame := 0
var rumor_today := ""
var club_id := ""
var club_level := 1
var club_points := 0
var club_day := -1
var course_day := -1
var business_level := 0
var business_name := "ร้านเล็ก ๆ ของฉัน"
var business_stock := 0
var business_day := -1
var business_sales_total := 0
var achievements := {}
var achievement_claimed := {}
var home_level := 1
var party_week := -1
var party_count := 0
var cat_feed_day := -1
var cat_toy_owned := false
var cat_toy_day := -1
var group_day := -1
var honeymoon_done := false
var family_outing_week := -1
var booth_day := -1
var booth_plays := 0

# ---------- v8: เควสต์ / เป้าหมายชีวิต ----------
var life_goal := "family"
var quest_week := -1
var quests: Array = []
var quest_counts := {}
var quest_total_done := 0
var quest_certificates: Array[String] = []


var _time_accum := 0.0
var _minute_count := 0


func _ready() -> void:
	load_game()
	if not created:
		new_game()


func _process(delta: float) -> void:
	if not created or not alive or time_paused or sleeping:
		return
	_time_accum += delta * GAME_MINUTES_PER_REAL_SECOND
	var steps := int(_time_accum)
	if steps <= 0:
		return
	_time_accum -= float(steps)
	advance_minutes(steps)


# ============================================================
#  เวลา / ปฏิทิน / การนอน
# ============================================================

## เดินเวลาแบบกำหนดเอง (ใช้ทั้งเกมจริงและเทสต์)
func advance_minutes(minutes: int) -> void:
	if minutes <= 0 or not alive:
		return
	for i in minutes:
		time_min += 1
		_minute_count += 1
		_tick_needs_minute()
		if time_min >= DAY_END_MIN:
			_pass_out()
			return
		if _minute_count % 15 == 0:
			time_changed.emit()
			changed.emit()
	_clamp_stats()
	time_changed.emit()


func advance_minutes_to(target: int, notes: Array[String] = []) -> void:
	var delta := target - time_min
	if delta <= 0:
		return
	advance_minutes(delta)


func _tick_needs_minute() -> void:
	# ความอิ่ม/พลังงานลดตามเวลา (ช้า ๆ พอให้ทันกิน/นอน)
	# ใช้ตัวนับนาทีเพื่อลดแบบจำนวนเต็ม (1 อิ่ม ต่อ ~45 นาที, 1 พลังงาน ต่อ ~83 นาที)
	if _minute_count % 45 == 0:
		hunger = maxi(hunger - 1, 0)
	if _minute_count % 83 == 0:
		energy = maxi(energy - 1, 0)
	if weather == "rain" and zone_id != "home" and _minute_count % 60 == 0:
		happy = clampi(happy - 1, 0, 100)

	# ทุกชั่วโมง: ผลจากหิว/เครียดสะสม
	if time_min % 60 == 0:
		if hunger < 25:
			health = clampi(health - 1, 0, 100)
		if stress > 80:
			health = clampi(health - 1, 0, 100)
		if fitness > 60:
			health = clampi(health + 0, 0, 100)


## 24:00 ยังไม่นอน -> สลบ แล้วตื่นเช้า
func _pass_out() -> void:
	if not alive:
		return
	time_min = DAY_END_MIN
	var notes: Array[String] = ["😵 หมดแรงสลบกลางคืน"]
	energy = clampi(energy - 10, 0, 100)
	health = clampi(health - 5, 0, 100)
	happy = clampi(happy - 5, 0, 100)
	stress = clampi(stress + 8, 0, 100)
	_end_day(notes, 5.0)
	time_min = DAY_START_MIN
	energy = maxi(energy, 55)
	last_sleep_hours = 5.0
	_clamp_stats()
	_check_death(notes)
	last_message = _join(notes)
	log_event("สลบหมดแรงกลางคืน")
	save_game()
	changed.emit()
	passed_out.emit()
	day_changed.emit()


## นอนหลับถึงเวลาที่ตั้งปลุก (ปลุก 06:00 / 07:00 / 08:00)
func sleep_now(wake_min: int) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if not created:
		return {"ok": false, "message": "ยังไม่ได้สร้างตัวละคร"}
	if time_min >= 6 * 60 and time_min < 18 * 60:
		return {"ok": false, "message": "ยังไม่ถึงเวลานอน (นอนได้หลัง 18:00)"}
	var wake := clampi(wake_min, 5 * 60, 9 * 60)
	var hours := float((wake - time_min + 1440) % 1440) / 60.0
	if hours < 1.0:
		hours += 24.0
	hours = minf(hours, 12.0)
	var notes: Array[String] = ["😴 นอนหลับ %.0f ชั่วโมง" % hours]

	energy = 100
	hunger = clampi(hunger - int(hours * 5.0), 0, 100)
	var stress_heal := int(hours * 4.0) + (2 if has_karma("grounded") else 0)
	stress = clampi(stress - stress_heal, 0, 100)
	health = clampi(health + int(hours / 3.0), 0, 100)
	last_sleep_hours = hours

	if sick and randf() < 0.35:
		_cure_sick()
		notes.append("ตื่นมาอาการป่วยดีขึ้นมาก")

	_end_day(notes, hours)
	time_min = wake
	alarm_min = wake
	_clamp_stats()
	_check_death(notes)
	last_message = _join(notes)
	log_event("นอนหลับ %.0f ชั่วโมง" % hours)
	save_game()
	changed.emit()
	day_changed.emit()
	return {"ok": true, "message": last_message}


## ปิดวัน: ตรวจขาดเรียน/ขาดงาน -> เลื่อนปฏิทิน -> รีเซ็ตธงรายวัน
func _end_day(notes: Array[String], sleep_hours: float) -> void:
	if is_school_day() and not school_attended_today:
		school_absences += 1
		grades = clampi(grades - 2, 0, 100)
		parent_love = clampi(parent_love - 1, 0, 100)
		notes.append("🏫 ขาดเรียน 1 วัน (ขาดแล้ว %d วัน)" % school_absences)
		if school_absences == 5:
			notes.append("⚠️ ครูโทรหาพ่อแม่แล้ว!")
		log_event("ขาดเรียน")

	if not is_child() and job_id != "" and is_workday() and not worked_today and not sick:
		work_absences += 1
		performance = clampi(performance - 6, 0, 100)
		notes.append("💼 ไม่ได้ไปทำงาน (ขาด %d ครั้ง)" % work_absences)
		log_event("ขาดงาน")
		if work_absences >= 5:
			var old := job_title()
			job_id = ""
			job_level = 1
			job_weeks = 0
			performance = 50
			notes.append("❌ ถูกเลิกจ้างเพราะขาดงานบ่อย (%s)" % old)
			log_event("ถูกเลิกจ้างเพราะขาดงาน")

	_advance_calendar(notes)
	_birthday_check(notes)
	school_attended_today = false
	worked_today = false
	npc_talked.clear()
	npc_gifted.clear()
	parent_talked.clear()


func _advance_calendar(notes: Array[String]) -> void:
	day += 1
	days_played += 1
	weekday = (weekday % 7) + 1
	season_day += 1
	if season_day > DAYS_PER_SEASON:
		season_day = 1
		season = (season + 1) % 4
	# v4: 28 วัน = 1 เดือน, 4 สัปดาห์ = 1 เดือน (เก็บไว้โชว์ในแผงสรุป)
	week = int((day - 1) / 7) % 4 + 1
	month = int((day - 1) / 28) % 12 + 1
	if (day - 1) % 28 == 0:
		_pay_bills(notes)
	weather = _roll_weather()
	_farm_new_day()
	fish_actions = 0
	bug_actions = 0
	booth_day = -1
	booth_plays = 0
	_rumor_new_day()
	_ensure_quest_week()
	check_achievements()
	notes.append("🌅 วันที่ %d • %s • %s" % [day, weekday_name(), weather_name()])


func _birthday_check(notes: Array[String]) -> void:
	# ครบ 4 ฤดู = 1 ปี (28 วัน)
	if season_day == 1 and season == 0 and day > 1:
		_birthday(notes)
		if age == ADULT_AGE and not adult_gift:
			adult_gift = true
			var gift := family_gift()
			money += gift
			graduated = true
			notes.append("🎓 จบมัธยมแล้ว! พ่อแม่ให้เงินก้อน ฿%s" % fmt_money(gift))
			log_event("อายุ 18 ได้เงินก้อนจากพ่อแม่ ฿%s" % fmt_money(gift))


func _roll_weather() -> String:
	var r := randf()
	match season_id():
		"spring":
			if r < 0.35:
				return "rain"
			if r < 0.5:
				return "cloud"
		"summer":
			if r < 0.12:
				return "rain"
			if r < 0.25:
				return "cloud"
		"autumn":
			if r < 0.28:
				return "rain"
			if r < 0.45:
				return "cloud"
		"winter":
			if r < 0.3:
				return "snow"
			if r < 0.5:
				return "cloud"
	return "sun"


func travel_fare() -> int:
	return COST_BUS_CHILD if is_child() else COST_BUS


## ขึ้นรถเมล์ไปโซนอื่น (ตัดเงิน + เวลา 20 นาที)
func travel_to(dest_zone: String, dest_pos := Vector2.INF) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	var fare := travel_fare()
	if money < fare:
		return {"ok": false, "message": "เงินไม่พอค่ารถเมล์ ฿%s" % fmt_money(fare)}
	money -= fare
	advance_minutes(20)
	zone_id = dest_zone
	if dest_pos != Vector2.INF:
		player_pos = dest_pos
	log_event("นั่งรถเมล์ไป %s" % dest_zone)
	save_game()
	changed.emit()
	return {"ok": true, "message": "นั่งรถเมล์ไป %s • ค่าโดยสาร ฿%s" % [dest_zone, fmt_money(fare)]}


# ============================================================
#  เริ่มชีวิต / สร้างตัวละคร
# ============================================================

func new_game() -> void:
	created = false
	player_name = _random_name()
	gender = "ชาย"
	family_wealth = 1
	age = 6
	month = 1
	week = 1
	money = 0
	bank = 0
	loan = 0
	insurance = false
	health = 85
	happy = 75
	energy = 90
	hunger = 80
	stress = 10
	edu = 4
	social = 20
	alive = true
	death_cause = ""
	last_message = ""
	sick = false
	illness = ""
	sick_weeks = 0
	job_id = ""
	job_level = 1
	job_weeks = 0
	performance = 50
	retired = false
	last_salary = 0
	partner_name = ""
	partner_love = 0
	married = false
	children = []
	partner_npc_id = ""
	partner_look = {}
	partner_genes = {}
	player_genes = {}
	parent_love = 70
	friend_name = ""
	friend_love = 0
	inherited = false
	rent_extra = 0
	outfit = "school"
	owned_outfits = ["casual", "school", "sleep"]
	tax_paid = 0
	life_log = []
	pending_event = {}
	# v4
	time_min = DAY_START_MIN
	day = 1
	weekday = 1
	season = 0
	season_day = 1
	days_played = 0
	weather = "sun"
	alarm_min = DEFAULT_ALARM
	time_paused = false
	sleeping = false
	zone_id = "home"
	player_pos = Vector2(480, 420)
	grades = 50
	school_absences = 0
	school_attended_today = false
	school_days = 0
	graduated = false
	worked_today = false
	work_absences = 0
	job_shifts = 0
	fitness = 30
	npc_friendship = {}
	npc_talked = {}
	npc_gifted = {}
	parent_talked = {}
	allowance_week = -1
	dinner_day = -1
	adult_gift = false
	last_sleep_hours = 0.0
	# v5
	skills = {}
	for sk in SKILL_KEYS:
		skills[sk] = 5
	birth_outfit = "heirloom_blue"
	parent_trait = "kind"
	karma_id = "warm"
	skin_tone = "warm"
	hair_color = "black"
	hair_style = "short"
	home_items = []
	pet_name = ""
	pet_happy = 0
	pet_day = -1
	collections = {}
	collect_day = -1
	collection_milestone = 0
	festival_attended = {}
	festival_wins = 0
	train_day = -1
	bench_day = -1
	farm_plots = []
	for i in FARM_PLOT_COUNT:
		farm_plots.append({"crop": "", "growth": 0, "watered": false})
	harvest_total = 0
	fish_catches = {}
	bug_catches = {}
	fish_total = 0
	bug_total = 0
	fish_actions = 0
	bug_actions = 0
	fame = 0
	rumor_today = ""
	club_id = ""
	club_level = 1
	club_points = 0
	club_day = -1
	course_day = -1
	business_level = 0
	business_name = "ร้านเล็ก ๆ ของฉัน"
	business_stock = 0
	business_day = -1
	business_sales_total = 0
	achievements = {}
	achievement_claimed = {}
	home_level = 1
	party_week = -1
	party_count = 0
	cat_feed_day = -1
	cat_toy_owned = false
	cat_toy_day = -1
	group_day = -1
	honeymoon_done = false
	family_outing_week = -1
	booth_day = -1
	booth_plays = 0
	# v8
	life_goal = "family"
	quest_week = -1
	quests = []
	quest_counts = {}
	quest_total_done = 0
	quest_certificates = []
	_time_accum = 0.0
	_minute_count = 0
	save_game()
	changed.emit()


## เรียกหลังผู้เล่นเลือกชื่อ/เพศ/ฐานะครอบครัวในหน้า "สร้างชีวิต"
func start_life(pname: String, pgender: String, wealth: int,
		p_birth_outfit := "heirloom_blue", p_parent_trait := "kind",
		p_skin := "warm", p_hair_color := "black", p_hair_style := "short",
		p_life_goal := "family") -> void:
	new_game()
	player_name = pname.strip_edges()
	if player_name == "":
		player_name = _random_name()
	gender = pgender
	family_wealth = clampi(wealth, 0, 2)
	birth_outfit = String(p_birth_outfit)
	if _birth_outfit_data(birth_outfit).is_empty():
		birth_outfit = "heirloom_blue"
	parent_trait = String(p_parent_trait)
	if parent_trait_data().is_empty():
		parent_trait = "kind"
	karma_id = String(parent_trait_data().get("karma", "warm"))
	_apply_parent_trait()
	if not owned_outfits.has(birth_outfit):
		owned_outfits.append(birth_outfit)
	outfit = birth_outfit
	skin_tone = String(p_skin)
	if _skin_tone_data(skin_tone).is_empty():
		skin_tone = "warm"
	hair_color = String(p_hair_color)
	if _hair_color_data(hair_color).is_empty():
		hair_color = "black"
	hair_style = String(p_hair_style)
	if _hair_style_data(hair_style).is_empty():
		hair_style = "short"
	player_genes = _default_genes(player_appearance())
	life_goal = String(p_life_goal)
	if not life_goal_exists(life_goal):
		life_goal = "family"
	_ensure_quest_week()
	created = true
	log_event("เริ่มชีวิตวัยประถมในครอบครัว%s • %s" % [family_wealth_name(), parent_trait_name()])
	save_game()
	changed.emit()


func _skin_tone_data(id: String) -> Dictionary:
	for t in SKIN_TONES:
		if String(t.get("id", "")) == id:
			return t
	return {}


func _hair_color_data(id: String) -> Dictionary:
	for h in HAIR_COLORS:
		if String(h.get("id", "")) == id:
			return h
	return {}


func _hair_style_data(id: String) -> Dictionary:
	for s in HAIR_STYLES:
		if String(s.get("id", "")) == id:
			return s
	return {}


func skin_tone_name() -> String:
	return String(_skin_tone_data(skin_tone).get("name", "ผิวอุ่น"))


func hair_color_name() -> String:
	return String(_hair_color_data(hair_color).get("name", "ดำธรรมชาติ"))


func hair_style_name() -> String:
	return String(_hair_style_data(hair_style).get("name", "ผมสั้น"))


func skin_tone_hex() -> String:
	return String(_skin_tone_data(skin_tone).get("hex", "#f2c39b"))


func hair_color_hex() -> String:
	return String(_hair_color_data(hair_color).get("hex", "#3a2a1a"))


## สีหน้าตามสถานะชีวิต ใช้กับตัวละครในเมือง/บทสนทนา
func mood_expression() -> String:
	if not alive:
		return "sad"
	if sick:
		return "sick"
	if stress >= 70:
		return "stressed"
	if energy <= 25:
		return "tired"
	if happy >= 70:
		return "happy"
	if happy <= 25:
		return "sad"
	return "neutral"


## ชุดข้อมูลหน้าตาสำหรับ renderer (ไม่ใส่ hair_style ถ้าใช้ค่าอัตโนมัติของชุด)
func character_look() -> Dictionary:
	var look := {"expression": mood_expression()}
	if skin_tone != "":
		look["skin"] = skin_tone_hex()
	if hair_color != "":
		look["hair"] = hair_color_hex()
	if hair_style != "":
		look["hair_style"] = hair_style
	return look


func player_appearance() -> Dictionary:
	return {
		"skin": skin_tone_hex(),
		"hair": hair_color_hex(),
		"hair_style": hair_style if hair_style != "" else "short",
	}


func _default_genes(look: Dictionary) -> Dictionary:
	var genes := {}
	for key in ["skin", "hair", "hair_style"]:
		var allele := String(look.get(key, ""))
		genes[key] = [allele, allele]
	return genes


func _normalize_appearance(raw: Dictionary, fallback: Dictionary = {}) -> Dictionary:
	var base := {
		"skin": String(fallback.get("skin", "#f2c39b")),
		"hair": String(fallback.get("hair", "#3a2a1a")),
		"hair_style": String(fallback.get("hair_style", "short")),
	}
	for key in ["skin", "hair", "hair_style"]:
		var value := String(raw.get(key, ""))
		if value != "":
			base[key] = value
	return base


func _normalize_genes(raw: Dictionary, look: Dictionary) -> Dictionary:
	var genes := {}
	for key in ["skin", "hair", "hair_style"]:
		var fallback := String(look.get(key, ""))
		var raw_pair = raw.get(key, [])
		if typeof(raw_pair) == TYPE_ARRAY and raw_pair.size() >= 2:
			var first := String(raw_pair[0])
			var second := String(raw_pair[1])
			genes[key] = [first if first != "" else fallback, second if second != "" else fallback]
		else:
			genes[key] = [fallback, fallback]
	return genes


func _appearance_from_npc(npc: Dictionary) -> Dictionary:
	var look := _normalize_appearance(npc, {
		"skin": "#f2c39b", "hair": "#3a2a1a", "hair_style": "short",
	})
	for key in ["shirt", "pants", "shoes", "style", "accessory", "outfit"]:
		if npc.has(key):
			look[key] = String(npc[key])
	return look


func _normalize_person_look(raw: Dictionary) -> Dictionary:
	var look := _normalize_appearance(raw)
	for key in ["shirt", "pants", "shoes", "style", "accessory", "outfit"]:
		if raw.has(key):
			look[key] = String(raw[key])
	return look


func _partner_profile_for_name() -> Dictionary:
	if partner_npc_id != "" and TownData.NPCS.has(partner_npc_id):
		return _appearance_from_npc(TownData.NPCS[partner_npc_id])
	for npc_id in TownData.NPCS.keys():
		var npc: Dictionary = TownData.NPCS[npc_id]
		if String(npc.get("name", "")) == partner_name and String(npc.get("dateable", "yes")) != "no":
			partner_npc_id = String(npc_id)
			return _appearance_from_npc(npc)
	return {"skin": "#f2c39b", "hair": "#3a2a1a", "hair_style": "short"}


func _ensure_partner_genetics() -> void:
	if partner_name == "":
		partner_look = {}
		partner_genes = {}
		return
	if partner_look.is_empty():
		partner_look = _partner_profile_for_name()
	partner_look = _normalize_person_look(partner_look)
	partner_genes = _normalize_genes(partner_genes, partner_look)
	player_genes = _normalize_genes(player_genes, player_appearance())


func _random_partner_appearance() -> Dictionary:
	var skin: Dictionary = SKIN_TONES[randi() % SKIN_TONES.size()]
	var hair: Dictionary = HAIR_COLORS[randi() % HAIR_COLORS.size()]
	var style: Dictionary = HAIR_STYLES[randi() % HAIR_STYLES.size()]
	return {"skin": String(skin["hex"]), "hair": String(hair["hex"]),
		"hair_style": String(style["id"])}


func _inherit_child_appearance() -> Dictionary:
	_ensure_partner_genetics()
	var inherited_genes := {}
	var appearance := {}
	var sources := {}
	for key in ["skin", "hair", "hair_style"]:
		var player_pair: Array = player_genes.get(key, [player_appearance().get(key, "")])
		var partner_pair: Array = partner_genes.get(key, [partner_look.get(key, "")])
		var from_player := String(player_pair[randi() % player_pair.size()])
		var from_partner := String(partner_pair[randi() % partner_pair.size()])
		inherited_genes[key] = [from_player, from_partner]
		if randi() % 2 == 0:
			appearance[key] = from_player
			sources[key] = "ผู้เล่น"
		else:
			appearance[key] = from_partner
			sources[key] = partner_name
	return {"appearance": appearance, "genes": inherited_genes, "traits_from": sources}


func parent_trait_data() -> Dictionary:
	for t in PARENT_TRAITS:
		if String(t.get("id", "")) == parent_trait:
			return t
	return {}


func parent_trait_name() -> String:
	var t := parent_trait_data()
	return String(t.get("name", "ใจดีอบอุ่น"))


func parent_trait_desc() -> String:
	var t := parent_trait_data()
	return String(t.get("desc", ""))


func karma_data() -> Dictionary:
	return KARMA_DEFS.get(karma_id, KARMA_DEFS["warm"])


func karma_name() -> String:
	return String(karma_data().get("name", "กรรมพันแห่งความอบอุ่น"))


func karma_desc() -> String:
	return String(karma_data().get("desc", ""))


func has_karma(id: String) -> bool:
	return karma_id == id


func _birth_outfit_data(id: String) -> Dictionary:
	for o in BIRTH_OUTFITS:
		if String(o.get("id", "")) == id:
			return o
	return {}


func birth_outfit_name() -> String:
	return String(_birth_outfit_data(birth_outfit).get("name", "ผ้าห่อตัว"))


func _apply_parent_trait() -> void:
	var t := parent_trait_data()
	if t.is_empty():
		return
	parent_love = clampi(parent_love + int(t.get("parent_love", 0)), 0, 100)
	happy = clampi(happy + int(t.get("happy", 0)), 0, 100)
	health = clampi(health + int(t.get("health", 0)), 0, 100)
	stress = clampi(stress + int(t.get("stress", 0)), 0, 100)
	money += int(t.get("money", 0))
	var bonuses: Dictionary = t.get("skills", {})
	for sk in bonuses.keys():
		add_skill(String(sk), int(bonuses[sk]))
	add_skill("academics", int(t.get("academics", 0)))


# ============================================================
#  ทักษะชีวิต (v5)
# ============================================================

func skill_of(id: String) -> int:
	return int(skills.get(id, 0))


func skill_name(id: String) -> String:
	return String(SKILL_DEFS.get(id, {}).get("name", id))


func skill_color(id: String) -> Color:
	return Color(String(SKILL_DEFS.get(id, {}).get("color", "#e0a05a")))


func skill_desc(id: String) -> String:
	return String(SKILL_DEFS.get(id, {}).get("desc", ""))


func skill_tier(id: String) -> String:
	var v := skill_of(id)
	if v >= 85:
		return "ระดับอาจารย์"
	if v >= 65:
		return "เชี่ยวชาญ"
	if v >= 45:
		return "ชำนาญ"
	if v >= 25:
		return "ฝึกฝน"
	return "มือใหม่"


func add_skill(id: String, amount: int) -> int:
	if amount == 0 or not skills.has(id):
		return skill_of(id)
	var mult := 1.0
	if id == "art" and has_karma("dreamer"):
		mult += 0.25
	if id == "athletics" and has_karma("grounded"):
		mult += 0.25
	var gained := int(round(float(amount) * mult))
	skills[id] = clampi(skill_of(id) + gained, 0, 100)
	return skill_of(id)


func skill_average() -> int:
	if SKILL_KEYS.is_empty():
		return 0
	var total := 0
	for sk in SKILL_KEYS:
		total += skill_of(String(sk))
	return int(round(float(total) / float(SKILL_KEYS.size())))


## ฝึกทักษะแบบใช้เงิน/เวลา (จากแผงทักษะ)
func train_skill(id: String) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if not SKILL_DEFS.has(id):
		return {"ok": false, "message": "ไม่รู้จักทักษะนี้"}
	if train_day == day:
		return {"ok": false, "message": "วันนี้ฝึกพิเศษแล้ว — พรุ่งนี้ค่อยฝึกใหม่"}
	if money < TRAIN_COST:
		return {"ok": false, "message": "เงินไม่พอค่าอุปกรณ์ ฿%s" % fmt_money(TRAIN_COST)}
	money -= TRAIN_COST
	train_day = day
	var gain := 2 + (1 if has_karma("dreamer") and id == "art" else 0)
	add_skill(id, gain)
	happy = clampi(happy + 2, 0, 100)
	energy = clampi(energy - 10, 0, 100)
	stress = clampi(stress + 2, 0, 100)
	var notes: Array[String] = ["🎯 ฝึก%s: +%d • ฿-%s" % [
		skill_name(id), gain, fmt_money(TRAIN_COST)
	]]
	advance_minutes(60)
	_finish(notes)
	return {"ok": true, "message": last_message}


# ============================================================
#  บ้าน / ของสะสม / เทศกาล (v5)
# ============================================================

func furniture_data(id: String) -> Dictionary:
	for f in FURNITURE:
		if String(f.get("id", "")) == id:
			return f
	return {}


func owns_furniture(id: String) -> bool:
	return home_items.has(id)


func home_cozy() -> int:
	var cozy := 8 + (home_level - 1) * 7
	for id in home_items:
		cozy += int(furniture_data(String(id)).get("cozy", 0))
	return mini(cozy, 100)


func buy_furniture(id: String) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	var f := furniture_data(id)
	if f.is_empty():
		return {"ok": false, "message": "ไม่พบเฟอร์นิเจอร์ชิ้นนี้"}
	if owns_furniture(id):
		return {"ok": false, "message": "มี%sอยู่แล้ว" % String(f["name"])}
	var price := int(f["price"])
	if money < price:
		return {"ok": false, "message": "เงินไม่พอซื้อ%s (฿%s)" % [String(f["name"]), fmt_money(price)]}
	money -= price
	home_items.append(id)
	happy = clampi(happy + int(f.get("happy", 0)) + 2, 0, 100)
	parent_love = clampi(parent_love + int(f.get("parent_love", 0)), 0, 100)
	var sk := String(f.get("skill", ""))
	if sk != "":
		add_skill(sk, 1)
	var notes: Array[String] = ["🪑 ซื้อ%sมาตกแต่งบ้าน • ความอบอุ่น +%d • ฿-%s" % [
		String(f["name"]), home_cozy(), fmt_money(price)
	]]
	if bool(f.get("pet", false)) and pet_name == "":
		pet_name = CAT_NAMES[randi() % CAT_NAMES.size()]
		pet_happy = 60
		notes.append("🐈 แมวชื่อ “%s” มาอยู่ด้วยแล้ว!" % pet_name)
	log_event("ซื้อเฟอร์นิเจอร์ %s" % String(f["name"]))
	_instant(notes)
	return {"ok": true, "message": last_message}


func pet_cat() -> Dictionary:
	if pet_name == "":
		return {"ok": false, "message": "ยังไม่มีแมว — ซื้อที่นอนแมวจากร้านตกแต่งก่อน"}
	if pet_day == day:
		return {"ok": false, "message": "วันนี้เล่นกับ%sแล้ว" % pet_name}
	pet_day = day
	pet_happy = clampi(pet_happy + 12, 0, 100)
	happy = clampi(happy + 4, 0, 100)
	stress = clampi(stress - 4, 0, 100)
	var notes: Array[String] = ["🐈 เล่นกับ%sจนพอใจ • ความสุข +4" % pet_name]
	if pet_happy >= 100:
		notes.append("เสียงครางเบา ๆ ดังขึ้น — %s มีความสุขมาก" % pet_name)
	advance_minutes(30)
	_finish(notes)
	return {"ok": true, "message": last_message}


func collection_count() -> int:
	var n := 0
	for id in collections.keys():
		if int(collections[id]) > 0:
			n += 1
	return n


func collection_total() -> int:
	return COLLECTIBLES.size()


func collectible_name(id: String) -> String:
	return String(COLLECTIBLES.get(id, {}).get("name", id))


func collect_find(zone_id: String) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if collect_day == day:
		return {"ok": false, "message": "วันนี้เก็บของสะสมแล้ว — พรุ่งนี้ค่อยหาต่อ"}
	var pools: Array[String] = []
	for id in COLLECTIBLES.keys():
		var c: Dictionary = COLLECTIBLES[id]
		if int(c.get("season", -1)) != season:
			continue
		if String(c.get("zone", "")) == zone_id:
			pools.append(String(id))
	if pools.is_empty():
		for id in COLLECTIBLES.keys():
			var c2: Dictionary = COLLECTIBLES[id]
			if int(c2.get("season", -1)) == season:
				pools.append(String(id))
	if pools.is_empty():
		return {"ok": false, "message": "ฤดูนี้ยังไม่มีของสะสมแถวนี้"}
	collect_day = day
	var pick := pools[randi() % pools.size()]
	collections[pick] = int(collections.get(pick, 0)) + 1
	_quest_bump("collect")
	add_skill("academics", 1)
	happy = clampi(happy + 2, 0, 100)
	social = clampi(social + 1, 0, 100)
	var money_gain := 120 + (60 if has_karma("lucky") else 0)
	money += money_gain
	var notes: Array[String] = ["🍂 เก็บ%sได้! • ฿+%s" % [collectible_name(pick), fmt_money(money_gain)]]
	var count := collection_count()
	for milestone in COLLECTION_MILESTONES:
		if count >= milestone and collection_milestone < milestone:
			collection_milestone = milestone
			var bonus: int = 500 * int(milestone)
			money += bonus
			happy = clampi(happy + 5, 0, 100)
			notes.append("🏅 สะสมครบ %d ชนิด! โบนัส ฿%s" % [milestone, fmt_money(bonus)])
			log_event("สะสมของครบ %d ชนิด" % milestone)
			break
	advance_minutes(15)
	_finish(notes)
	return {"ok": true, "message": last_message}


func festival_today() -> Dictionary:
	for f in FESTIVALS:
		if int(f.get("season", -1)) == season and int(f.get("day", -1)) == season_day:
			return f
	return {}


func festival_key() -> String:
	var year := int((day - 1) / 28) + 1
	return "%d-%d" % [year, season]


func festival_attended_today() -> bool:
	var f := festival_today()
	if f.is_empty():
		return false
	return bool(festival_attended.get("%s-%s" % [festival_key(), String(f["id"])], false))


func festival_name(id: String) -> String:
	for f in FESTIVALS:
		if String(f.get("id", "")) == id:
			return String(f.get("name", id))
	return id


func join_festival(score: int) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	var f := festival_today()
	if f.is_empty():
		return {"ok": false, "message": "วันนี้ไม่มีเทศกาล"}
	if String(f.get("zone", "")) != zone_id:
		return {"ok": false, "message": "เทศกาลอยู่ที่%s" % TownData.zone_name(String(f["zone"]))}
	if festival_attended_today():
		return {"ok": false, "message": "วันนี้ร่วมเทศกาลแล้ว"}
	score = clampi(score, 0, 100)
	festival_attended["%s-%s" % [festival_key(), String(f["id"])]] = true
	festival_wins += 1
	var reward := int(f.get("reward", 1000)) + score * 8
	money += reward
	happy = clampi(happy + 10 + int(score / 20.0), 0, 100)
	social = clampi(social + 6, 0, 100)
	stress = clampi(stress - 8, 0, 100)
	add_skill("communication", 2)
	add_skill("art", 2)
	var notes: Array[String] = ["🎪 ร่วม%s • คะแนน %d • ฿+%s" % [
		String(f["name"]), score, fmt_money(reward)
	]]
	var collect := collect_find(String(f["zone"]))
	if bool(collect.get("ok", false)):
		notes.append("🎁 ของที่ระลึกจากเทศกาล: " + String(collect.get("message", "")))
	advance_minutes(180)
	_finish(notes)
	log_event("ร่วมเทศกาล %s" % String(f["name"]))
	return {"ok": true, "message": last_message}


func family_wealth_name() -> String:
	return WEALTH_NAMES[clampi(family_wealth, 0, 2)]


func annual_allowance() -> int:
	return WEALTH_ALLOWANCE[clampi(family_wealth, 0, 2)]


func family_gift() -> int:
	return WEALTH_GIFT[clampi(family_wealth, 0, 2)]


# ============================================================
#  คำถามเกี่ยวกับสถานะ (ให้ HUD เอาไปแสดง)
# ============================================================

func is_child() -> bool:
	return age < ADULT_AGE


func stage_key() -> String:
	if age < 3:
		return "baby"
	if age < 6:
		return "toddler"
	if age < 12:
		return "child"
	if age < 18:
		return "teen"
	return "adult"


func stage_name() -> String:
	if age < 3:
		return "ทารก"
	if age < 6:
		return "เด็กเล็ก"
	if age < 12:
		return "เด็ก"
	if age < 18:
		return "วัยรุ่น"
	if retired:
		return "วัยเกษียณ"
	return "วัยทำงาน"


func date_label() -> String:
	return "วัน%s • %s วันที่ %d" % [
		weekday_name(), season_name(), season_day
	]


func calendar_label() -> String:
	return "%s • %s วันที่ %d • %s" % [
		weekday_name(), season_name(), season_day, time_string()
	]


func time_string() -> String:
	var h := int(time_min) / 60
	var m := int(time_min) % 60
	return "%02d:%02d" % [h, m]


func weekday_name() -> String:
	return WEEKDAY_NAMES[clampi(weekday - 1, 0, 6)]


func season_name() -> String:
	return SEASON_NAMES[clampi(season, 0, 3)]


func season_id() -> String:
	return SEASONS[clampi(season, 0, 3)]


func weather_name() -> String:
	return String(WEATHER_NAMES.get(weather, "แดดออก"))


func is_weekend() -> bool:
	return weekday >= 6


func is_school_day() -> bool:
	return age >= 6 and age < ADULT_AGE and weekday <= 5


func is_workday() -> bool:
	return weekday <= 5


func is_school_open() -> bool:
	return is_school_day() and time_min >= SCHOOL_START and time_min < SCHOOL_END


func is_work_open() -> bool:
	return is_workday() and time_min >= WORK_START and time_min < WORK_END


func day_phase() -> String:
	if time_min < 12 * 60:
		return "เช้า"
	if time_min < 17 * 60:
		return "บ่าย"
	if time_min < 20 * 60:
		return "เย็น"
	return "กลางคืน"


func is_home_time() -> bool:
	return time_min >= 18 * 60 and time_min <= 21 * 60


func education_level() -> int:
	if edu >= 85:
		return 3
	if edu >= 60:
		return 2
	if edu >= 30:
		return 1
	return 0


func education_title() -> String:
	if age < 6:
		return "ยังไม่เข้าเรียน"
	if age < 12:
		return "ประถมศึกษา"
	if age < 18:
		return "มัธยมศึกษา"
	match education_level():
		1:
			return "ปริญญาตรี"
		2:
			return "ปริญญาโท"
		3:
			return "ปริญญาเอก"
	return "มัธยมปลาย"


func job_data() -> Dictionary:
	for j in JOBS:
		if j["id"] == job_id:
			return j
	return {}


func job_title() -> String:
	if is_child():
		return "นักเรียน"
	if retired:
		return "เกษียณแล้ว"
	if job_id == "":
		return "ว่างงาน"
	return String(job_data()["title"])


## เงินเดือนต่อสัปดาห์ (ระดับงานยิ่งสูง ยิ่งได้เยอะ)
func salary() -> int:
	var j := job_data()
	if j.is_empty():
		return 0
	return int(round(float(j["salary"]) * pow(1.4, job_level - 1)))


func spouse_income() -> int:
	if not married:
		return 0
	return 6000 + job_level * 500


func living_breakdown() -> Dictionary:
	var child_cost := 0
	for c in children:
		var a := int(c.get("age", 0))
		child_cost += COST_PER_CHILD
		if a >= 6:
			child_cost += COST_CHILD_SCHOOL
		if a >= 12:
			child_cost += COST_CHILD_TEEN
	var shared := COST_SHARED if married else 0
	var ins := COST_INSURANCE if insurance else 0
	var rent := COST_RENT + rent_extra
	var total := rent + COST_UTIL + COST_PHONE + COST_TRANSPORT + child_cost + shared + ins
	return {
		"rent": rent, "util": COST_UTIL, "phone": COST_PHONE,
		"transport": COST_TRANSPORT, "children": child_cost,
		"shared": shared, "insurance": ins, "total": total,
	}


func living_cost() -> int:
	return int(living_breakdown()["total"])


func monthly_income() -> int:
	var income := salary() * 4 + spouse_income()
	if retired:
		income += pension_amount()
	return income


func pension_amount() -> int:
	if not retired:
		return 0
	return int(round(last_salary * 4 * PENSION_RATE))


func monthly_tax() -> int:
	var taxable := monthly_income() - TAX_FREE
	if taxable <= 0:
		return 0
	return int(round(taxable * TAX_RATE))


func net_worth() -> int:
	return money + bank - loan


func partner_status() -> String:
	if partner_name == "":
		return "โสด"
	if married:
		return "แต่งงานกับ %s" % partner_name
	return "คบกับ %s" % partner_name


func friend_status() -> String:
	if friend_name == "":
		return "ยังไม่มีเพื่อนสนิท"
	return "%s (ความสนิท %d)" % [friend_name, friend_love]


func income_text() -> String:
	if is_child():
		return "นักเรียน • พ่อแม่ให้ปีละ ฿%s" % fmt_money(annual_allowance())
	if retired:
		return "เงินบำนาญ ~฿%s/เดือน" % fmt_money(pension_amount())
	if job_id == "":
		return "ว่างงาน • รับจ้างรายวัน ฿%s/สัปดาห์" % fmt_money(DAILY_WAGE)
	return "%s • ฿%s/สัปดาห์" % [job_title(), fmt_money(salary())]


func status_text() -> String:
	if sick:
		return "🤒 ป่วยเป็น%s" % illness
	if is_child():
		return "%s • %s" % [stage_name(), education_title()]
	if job_id != "":
		return "%s • ประสิทธิภาพ %d%%" % [job_title(), performance]
	return "ว่างงาน"


func action_keys() -> Array:
	return ACTIONS.keys()


func action_label(key: String) -> String:
	if is_child():
		var band: Dictionary = CHILD_ACTIONS[stage_key()]
		if band.has(key):
			return String(band[key]["label"])
	return String(ACTIONS[key]["label"])


## ข้อความค่าตอบแทน/ค่าใช้จ่ายบนปุ่มกิจกรรม
func action_cost_text(key: String) -> String:
	if is_child():
		var band: Dictionary = CHILD_ACTIONS[stage_key()]
		if band.has(key):
			return String(band[key]["hint"])
		return "ฟรี"
	match key:
		"work":
			if job_id != "":
				return "+฿%s" % fmt_money(salary())
			return "+฿%s (รายวัน)" % fmt_money(DAILY_WAGE)
		"study":
			return "฿%s" % fmt_money(COST_STUDY)
		"eat":
			return "฿%s" % fmt_money(COST_EAT)
		"social":
			return "฿%s" % fmt_money(COST_SOCIAL)
	return "ฟรี"


func can_check(key: String) -> String:
	if not alive:
		return "เกมจบแล้ว กดเริ่มใหม่ก่อน"
	if is_child():
		return ""
	match key:
		"work":
			if energy < 18:
				return "ไม่มีแรงพอ ต้องพักผ่อนก่อน"
		"study":
			if energy < 15:
				return "ไม่มีแรงพอที่จะอ่านหนังสือ"
			if money < COST_STUDY:
				return "เงินไม่พอจ่ายค่าเล่าเรียน"
		"eat":
			if money < COST_EAT:
				return "เงินไม่พอซื้อข้าว"
		"gym":
			if energy < 15:
				return "เหนื่อยเกินไป ไปไม่ไหว"
		"social":
			if money < COST_SOCIAL:
				return "เงินไม่พอออกไปสังสรรค์"
	return ""


func fmt_money(v: int) -> String:
	var digits := str(absi(v))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if v < 0 else "") + out


# ============================================================
#  การกระทำหลัก (แยกวัยเด็ก / วัยผู้ใหญ่)
# ============================================================

func run_action(key: String) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว กดเริ่มใหม่ก่อน"}
	if not created:
		return {"ok": false, "message": "สร้างตัวละครก่อนเริ่มชีวิต"}
	if is_child():
		return _run_child_action(key)
	return _run_adult_action(key)


# ---------- วัยเด็ก: 1 การกระทำ = 1 ปี ----------

func _run_child_action(key: String) -> Dictionary:
	var band: Dictionary = CHILD_ACTIONS[stage_key()]
	if not band.has(key):
		return {"ok": false, "message": "กิจกรรมนี้ยังทำไม่ได้ในวัยนี้"}

	var notes: Array[String] = []
	_apply_child_focus(key, notes)
	_child_year(notes)
	_clamp_stats()
	_check_death(notes)
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


func _apply_child_focus(key: String, notes: Array[String]) -> void:
	var age_before := age
	match key:
		"work":
			if age < 3:
				edu = clampi(edu + 1, 0, 100)
				happy = clampi(happy + 2, 0, 100)
				notes.append("ฝึกพูดคำใหม่ ๆ ได้หลายคำ 👶")
			elif age < 6:
				edu = clampi(edu + 2, 0, 100)
				social = clampi(social + 1, 0, 100)
				notes.append("ไปโรงเรียนอนุบาล ได้เพื่อนใหม่")
			else:
				edu = clampi(edu + 2, 0, 100)
				social = clampi(social + 1, 0, 100)
				stress = clampi(stress + 2, 0, 100)
				notes.append("ตั้งใจเรียนที่โรงเรียน")
		"study":
			if age < 3:
				edu = clampi(edu + 1, 0, 100)
				happy = clampi(happy + 1, 0, 100)
				notes.append("ฟังนิทานก่อนนอน")
			elif age < 6:
				edu = clampi(edu + 2, 0, 100)
				happy = clampi(happy + 1, 0, 100)
				notes.append("วาดรูปและหัดอ่านหนังสือ")
			elif age < 12:
				edu = clampi(edu + 3, 0, 100)
				happy = clampi(happy - 2, 0, 100)
				stress = clampi(stress + 3, 0, 100)
				notes.append("ทำการบ้านอย่างหนัก")
			else:
				edu = clampi(edu + 3, 0, 100)
				happy = clampi(happy - 3, 0, 100)
				stress = clampi(stress + 4, 0, 100)
				notes.append("อ่านหนังสือสอบจนดึก")
		"eat":
			health = clampi(health + (3 if age < 3 else 2), 0, 100)
			happy = clampi(happy + 1, 0, 100)
			notes.append("กินอาหารครบมื้อ สุขภาพดี")
		"rest":
			var recover := 2 if age < 3 else 4
			stress = clampi(stress - recover, 0, 100)
			health = clampi(health + 1, 0, 100)
			notes.append("ได้พักผ่อนเต็มที่")
		"gym":
			health = clampi(health + 3, 0, 100)
			happy = clampi(happy + 2, 0, 100)
			if age >= 6:
				social = clampi(social + 1, 0, 100)
			notes.append("ได้ออกกำลังกายและวิ่งเล่น")
		"social":
			happy = clampi(happy + 4, 0, 100)
			social = clampi(social + 2, 0, 100)
			stress = clampi(stress - 1, 0, 100)
			if age < 6:
				parent_love = clampi(parent_love + 4, 0, 100)
			notes.append("ได้ใช้เวลากับคนที่รัก")
	if age_before < 6:
		parent_love = clampi(parent_love + 1, 0, 100)


func _child_year(notes: Array[String]) -> void:
	# พ่อแม่ให้เงินใช้ทุกปี
	var allowance := annual_allowance()
	money += allowance
	notes.append("พ่อแม่ให้เงินใช้ปีละ ฿%s" % fmt_money(allowance))

	# โรงเรียนสอนพื้นฐานให้ทุกปี
	if age >= 6 and edu < 29:
		edu = clampi(edu + 1, 0, 29)
	stress = clampi(stress - 1, 0, 100)
	hunger = 80
	energy = 85

	age += 1
	log_event("อายุ %d ปี" % age)
	notes.append("🎂 อายุ %d ปี" % age)

	# ได้ชุดนักเรียนตอนเข้า ป.1
	if age == 6 and not owns_outfit("school"):
		owned_outfits.append("school")
		notes.append("พ่อแม่ซื้อชุดนักเรียนให้")

	# ป่วยเล็ก ๆ น้อย ๆ ตอนเด็ก
	if randf() < 0.06:
		health = clampi(health - 4, 0, 100)
		notes.append("🤒 ป่วยเล็กน้อย พ่อแม่พาไปหาหมอ")
		log_event("ป่วยตอนอายุ %d" % age)

	if age >= ADULT_AGE:
		_become_adult(notes)
		return

	if health <= 0:
		alive = false
		death_cause = "สุขภาพทรุดโทรมตั้งแต่ยังเด็ก"
		notes.append("💀 สุขภาพหมดตั้งแต่ยังเด็ก")
		return

	if randf() < CHILD_EVENT_CHANCE:
		var ev: Dictionary = LifeEvents.pick(self)
		if not ev.is_empty():
			pending_event = ev


func _become_adult(notes: Array[String]) -> void:
	edu = clampi(edu, 0, 29)
	var gift := family_gift()
	money += gift
	month = 1
	week = 1
	health = clampi(health + 2, 0, 100)
	energy = 90
	hunger = 80
	log_event("โตเป็นผู้ใหญ่ เริ่มชีวิตวัยทำงาน")
	notes.append("🎉 อายุ 18 แล้ว! เริ่มชีวิตวัยทำงาน")
	notes.append("พ่อแม่ให้เงินก้อน ฿%s" % fmt_money(gift))
	pending_event = {}


# ---------- วัยผู้ใหญ่: 1 การกระทำ = 1 สัปดาห์ ----------

func _run_adult_action(key: String) -> Dictionary:
	if not ACTIONS.has(key):
		return {"ok": false, "message": "ไม่รู้จักแอ็กชันนี้"}

	var blocked := can_check(key)
	if blocked != "":
		return {"ok": false, "message": blocked}

	var notes: Array[String] = []
	match key:
		"work":
			notes.append(_do_work())
		"study":
			notes.append(_do_study())
		"eat":
			notes.append(_do_eat())
		"rest":
			notes.append(_do_rest())
		"gym":
			notes.append(_do_gym())
		"social":
			notes.append(_do_social())

	return _finish(notes)


func _do_work() -> String:
	energy = clampi(energy - WORK_ENERGY, 0, 100)
	stress = clampi(stress + WORK_STRESS, 0, 100)
	happy = clampi(happy - 4, 0, 100)

	var perf_gain := 8
	if outfit_formal() >= 6:
		perf_gain += 1
	if sick:
		health = clampi(health - 3, 0, 100)
		perf_gain = maxi(perf_gain - 4, 1)

	performance = clampi(performance + perf_gain, 0, 100)

	if job_id == "":
		money += DAILY_WAGE
		return "รับจ้างรายวัน: +฿%s • พลังงาน -%d • เครียด +%d" % [
			fmt_money(DAILY_WAGE), WORK_ENERGY, WORK_STRESS
		]

	job_weeks += 1
	var pay := salary()
	money += pay
	last_salary = pay
	var msg := "ทำงาน: +฿%s • พลังงาน -%d • เครียด +%d" % [
		fmt_money(pay), WORK_ENERGY, WORK_STRESS
	]
	if sick:
		msg += "\n🤒 ทำงานทั้งที่ป่วย สุขภาพลดอีก"

	# เลื่อนตำแหน่ง
	if job_level < 3 and performance >= 100 and job_weeks >= PROMO_WEEKS:
		job_level += 1
		performance = 50
		msg += "\nเลื่อนตำแหน่ง! เงินเดือนขึ้นเป็น ฿%s/สัปดาห์ 🎉" % fmt_money(salary())
		log_event("เลื่อนตำแหน่งเป็น %s ระดับ %d" % [job_title(), job_level])

	return msg


func _do_study() -> String:
	money -= COST_STUDY
	energy = clampi(energy - 18, 0, 100)
	stress = clampi(stress + 8, 0, 100)
	happy = clampi(happy - 3, 0, 100)

	var before := education_level()
	edu = clampi(edu + 5, 0, 100)
	var msg := "เรียน: ความรู้ +5 • ฿-%s" % fmt_money(COST_STUDY)

	if education_level() > before:
		msg += "\nจบการศึกษา: %s 🎓" % education_title()
		log_event("จบการศึกษา: %s" % education_title())

	return msg


func _do_eat() -> String:
	money -= COST_EAT
	hunger = clampi(hunger + 35, 0, 100)
	happy = clampi(happy + 4, 0, 100)
	health = clampi(health + 1, 0, 100)
	return "กินข้าว: ความอิ่ม +35 • ฿-%s" % fmt_money(COST_EAT)


func _do_rest() -> String:
	energy = clampi(energy + 40, 0, 100)
	stress = clampi(stress - 15, 0, 100)
	health = clampi(health + 2, 0, 100)
	happy = clampi(happy + 3, 0, 100)
	return "พักผ่อน: พลังงาน +40 • เครียด -15"


func _do_gym() -> String:
	energy = clampi(energy - 20, 0, 100)
	stress = clampi(stress - 10, 0, 100)
	health = clampi(health + 6, 0, 100)
	happy = clampi(happy + 4, 0, 100)
	return "ออกกำลัง: สุขภาพ +6 • เครียด -10"


func _do_social() -> String:
	money -= COST_SOCIAL
	energy = clampi(energy - 8, 0, 100)
	stress = clampi(stress - 12, 0, 100)
	happy = clampi(happy + 10, 0, 100)
	social = clampi(social + 6, 0, 100)
	var msg := "สังคม: ความสุข +10 • เครียด -12 • ฿-%s" % fmt_money(COST_SOCIAL)

	if friend_name == "":
		if randf() < 0.3 + float(social) / 300.0:
			friend_name = _random_name()
			friend_love = 50
			msg += "\nได้เพื่อนสนิทชื่อ %s 🫂" % friend_name
			log_event("ได้เพื่อนสนิท %s" % friend_name)
	else:
		friend_love = clampi(friend_love + 4, 0, 100)
		msg += "\nความสนิทกับ %s +4" % friend_name

	if partner_name != "":
		partner_love = clampi(partner_love + 4, 0, 100)
		msg += "\nความรัก +4"
	return msg


## ปิดการกระทำแบบ v4: ไม่ข้ามสัปดาห์ แค่สรุปผล/บันทึก
func _finish(notes: Array[String]) -> Dictionary:
	_clamp_stats()
	_check_death(notes)
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


func _week_passive(notes: Array[String]) -> void:
	hunger = clampi(hunger - 10, 0, 100)

	# ไม่ได้ทำงาน = ประสิทธิภาพค่อย ๆ ตก
	if job_id != "" and performance > 0:
		performance = clampi(performance - 1, 0, 100)

	_maybe_get_sick(notes)

	if sick:
		sick_weeks += 1
		health = clampi(health - 2, 0, 100)
		happy = clampi(happy - 2, 0, 100)
		energy = clampi(energy - 3, 0, 100)
		if sick_weeks >= 5:
			health = clampi(health - 3, 0, 100)
			notes.append("🤒 ป่วยเรื้อรัง! สุขภาพแย่ลง")
		if sick_weeks >= 3 and randf() < 0.25:
			sick = false
			sick_weeks = 0
			notes.append("หายป่วยจาก%sแล้ว" % illness)
			illness = ""

	if hunger < 25:
		health = clampi(health - 3, 0, 100)
		happy = clampi(happy - 2, 0, 100)
		notes.append("⚠️ หิวเกินไป! สุขภาพ -3")
	if stress > 75:
		health = clampi(health - 3, 0, 100)
		happy = clampi(happy - 3, 0, 100)
		notes.append("⚠️ เครียดเกินไป! สุขภาพ -3")

	# ประสิทธิภาพต่ำมากมีโอกาสถูกเลิกจ้าง
	if job_id != "" and performance < 15 and randf() < 0.05:
		var old := job_title()
		job_id = ""
		job_level = 1
		job_weeks = 0
		performance = 50
		notes.append("❌ ถูกเลิกจ้างจากตำแหน่ง %s" % old)
		log_event("ถูกเลิกจ้างจาก %s" % old)


func _maybe_get_sick(notes: Array[String]) -> void:
	if sick:
		return
	var chance := 0.03
	if stress > 60:
		chance += 0.03
	if hunger < 30:
		chance += 0.03
	if age >= 60:
		chance += 0.02
	chance -= float(health) / 2000.0
	if insurance:
		chance -= 0.01
	if randf() < chance:
		var pool := ["หวัด", "อาหารเป็นพิษ", "ไข้หวัดใหญ่"]
		illness = pool[randi() % pool.size()]
		sick = true
		sick_weeks = 0
		notes.append("🤒 ป่วยเป็น%s" % illness)
		log_event("ป่วยเป็น%s" % illness)


func _clamp_stats() -> void:
	health = clampi(health, 0, 100)
	happy = clampi(happy, 0, 100)
	energy = clampi(energy, 0, 100)
	hunger = clampi(hunger, 0, 100)
	stress = clampi(stress, 0, 100)
	# วัยเด็กเรียนรู้ได้ถึงระดับมัธยมปลายเท่านั้น (29) — ต้องไปเรียนต่อเองตอนเป็นผู้ใหญ่
	if is_child():
		edu = clampi(edu, 0, 29)
	else:
		edu = clampi(edu, 0, 100)
	social = clampi(social, 0, 100)
	partner_love = clampi(partner_love, 0, 100)
	parent_love = clampi(parent_love, 0, 100)
	friend_love = clampi(friend_love, 0, 100)
	grades = clampi(grades, 0, 100)
	fitness = clampi(fitness, 0, 100)


# ============================================================
#  เวลา / ค่าใช้จ่าย / วันเกิด
# ============================================================

func _advance_week(notes: Array[String]) -> void:
	week += 1
	if week <= 4:
		return
	week = 1
	month += 1
	_pay_bills(notes)

	if month > 12:
		month = 1
		_birthday(notes)


func _pay_bills(notes: Array[String]) -> void:
	var cost := living_cost()
	money -= cost
	notes.append("ค่าใช้จ่ายเดือนนี้: -฿%s" % fmt_money(cost))

	var spouse := spouse_income()
	if spouse > 0:
		money += spouse
		notes.append("คู่สมรสช่วยจ่าย: +฿%s" % fmt_money(spouse))

	var tax := monthly_tax()
	if tax > 0:
		money -= tax
		tax_paid += tax
		notes.append("ภาษีเงินได้: -฿%s" % fmt_money(tax))

	if retired:
		var pension := pension_amount()
		money += pension
		notes.append("เงินบำนาญ: +฿%s" % fmt_money(pension))

	if loan > 0:
		var interest := int(ceil(float(loan) * LOAN_RATE))
		loan += interest
		notes.append("ดอกเบี้ยหนี้: +฿%s (ยอดหนี้ ฿%s)" % [
			fmt_money(interest), fmt_money(loan)
		])

	if bank > 0:
		var interest := int(floor(float(bank) * SAVINGS_RATE / 12.0))
		if interest > 0:
			bank += interest
			notes.append("ดอกเบี้ยเงินออม: +฿%s" % fmt_money(interest))

	if money < 0:
		var interest := int(ceil(float(-money) * OVERDRAFT_RATE))
		money -= interest
		notes.append("ดอกเบี้ยหนี้บัตร: -฿%s" % fmt_money(interest))


func _birthday(notes: Array[String]) -> void:
	age += 1
	var decline := 0
	if age >= 75:
		decline = 5
	elif age >= 65:
		decline = 3
	elif age >= 55:
		decline = 2
	elif age >= 45:
		decline = 1
	health = clampi(health - decline, 0, 100)

	for c in children:
		c["age"] = int(c["age"]) + 1
	if partner_name != "":
		partner_love = clampi(partner_love - 3, 0, 100)
	parent_love = clampi(parent_love - 2, 0, 100)

	notes.append("🎂 อายุ %d ปี" % age)
	log_event("อายุ %d ปี" % age)

	# โบนัสประจำปี
	if job_id != "" and performance >= 80:
		var bonus := salary() * 4
		money += bonus
		notes.append("โบนัสประจำปี: +฿%s 🎁" % fmt_money(bonus))
		log_event("ได้โบนัสประจำปี ฿%s" % fmt_money(bonus))

	# มรดกจากพ่อแม่ (อายุ 50+)
	if not inherited and age >= 50:
		var chance := 0.25
		if age >= 60:
			chance = 1.0
		elif age >= 55:
			chance = 0.5
		if randf() < chance:
			var base: int = WEALTH_INHERIT[clampi(family_wealth, 0, 2)]
			var amount := int(round(float(base) * (0.5 + float(parent_love) / 200.0)))
			money += amount
			inherited = true
			notes.append("🕯️ ได้รับมรดกจากพ่อแม่ ฿%s" % fmt_money(amount))
			log_event("ได้รับมรดก ฿%s" % fmt_money(amount))

	if age == RETIRE_AGE and job_id != "":
		last_salary = salary()
		job_id = ""
		job_level = 1
		job_weeks = 0
		retired = true
		notes.append("เกษียณอายุแล้ว 🎉")
		log_event("เกษียณอายุ")

	# โอกาสจากไปตามวัย
	var death_chance := 0.0
	if age >= 85:
		death_chance = 0.25
	elif age >= 75:
		death_chance = 0.12
	elif age >= 65:
		death_chance = 0.05
	elif age >= 55:
		death_chance = 0.02
	if death_chance > 0.0 and randf() < death_chance:
		alive = false
		death_cause = "จากไปอย่างสงบในวัย %d" % age
		notes.append("🕯️ %s" % death_cause)


func _check_death(notes: Array[String]) -> void:
	if health <= 0 and alive:
		alive = false
		death_cause = "สุขภาพทรุดโทรม"
		notes.append("💀 สุขภาพหมด เกมจบ")


func _maybe_event() -> void:
	if randf() >= EVENT_CHANCE:
		return
	var ev: Dictionary = LifeEvents.pick(self)
	if ev.is_empty():
		return
	pending_event = ev


# ============================================================
#  โรงเรียน / มหาวิทยาลัย (v4 — ต้องเดินไปเรียนจริง)
# ============================================================

func school_block_reason() -> String:
	if not alive:
		return "เกมจบแล้ว"
	if not is_child():
		return "จบมัธยมแล้ว ไปเรียนมหาวิทยาลัยแทน"
	if not is_school_day():
		return "วันนี้เป็นวันหยุด ไม่มีเรียน"
	if not is_school_open():
		return "โรงเรียนเปิด 08:00-15:00"
	if school_attended_today:
		return "วันนี้เรียนแล้ว"
	return ""


## จบหนึ่งวันเรียน — score 0-100 จากมินิเกม
func attend_school(score: int) -> Dictionary:
	var blocked := school_block_reason()
	if blocked != "":
		return {"ok": false, "message": blocked}
	score = clampi(score, 0, 100)
	var notes: Array[String] = []
	var gain := 1 + int(score / 22.0)
	edu = clampi(edu + gain, 0, 29)
	var grade_delta := int(round((float(score) - 45.0) / 12.0))
	if has_karma("diligent"):
		grade_delta += 1
	grades = clampi(grades + grade_delta, 0, 100)
	add_skill("academics", 2)
	add_skill("communication", 1)
	add_skill("art", 1)
	social = clampi(social + 2, 0, 100)
	energy = clampi(energy - 15, 0, 100)
	stress = clampi(stress + 5, 0, 100)
	happy = clampi(happy + (2 if score >= 60 else -3), 0, 100)
	school_attended_today = true
	school_days += 1
	_quest_bump("school")
	notes.append("🏫 เรียนวันนี้: ความรู้ +%d • เกรด %d/100" % [gain, grades])
	if score >= 80:
		notes.append("ครูชมว่าตั้งใจเรียนมาก")
	elif score < 35:
		notes.append("วันนี้เรียนไม่ค่อยรู้เรื่อง")
	advance_minutes_to(SCHOOL_END, notes)
	_clamp_stats()
	last_message = _join(notes)
	log_event("ไปโรงเรียน (เกรด %d)" % grades)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


## เรียนมหาวิทยาลัย/อ่านหนังสือ (วัยผู้ใหญ่)
func study_lecture(score: int) -> Dictionary:
	if is_child():
		return {"ok": false, "message": "ยังต้องเรียนมัธยมก่อน"}
	if money < COST_STUDY:
		return {"ok": false, "message": "เงินไม่พอค่าเล่าเรียน ฿%s" % fmt_money(COST_STUDY)}
	money -= COST_STUDY
	score = clampi(score, 0, 100)
	var before := education_level()
	var gain := 3 + int(score / 20.0)
	edu = clampi(edu + gain, 0, 100)
	add_skill("academics", 3)
	add_skill("communication", 1)
	energy = clampi(energy - 16, 0, 100)
	stress = clampi(stress + 7, 0, 100)
	happy = clampi(happy - 2, 0, 100)
	var notes: Array[String] = ["📚 เรียนมหาลัย: ความรู้ +%d • ฿-%s" % [gain, fmt_money(COST_STUDY)]]
	if education_level() > before:
		notes.append("🎓 จบการศึกษา: %s" % education_title())
		log_event("จบการศึกษา: %s" % education_title())
	advance_minutes(120)
	_clamp_stats()
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


func do_homework() -> Dictionary:
	if not is_child():
		return {"ok": false, "message": "ไม่มีการบ้านแล้ว"}
	edu = clampi(edu + 1, 0, 29)
	grades = clampi(grades + 1, 0, 100)
	add_skill("academics", 2)
	add_skill("art", 1)
	energy = clampi(energy - 8, 0, 100)
	stress = clampi(stress + 3, 0, 100)
	var notes: Array[String] = ["📝 ทำการบ้าน: ความรู้ +1 • เกรด +1 • วิชาการ +2"]
	advance_minutes(60)
	_clamp_stats()
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


## ฝึกศิลปะที่บ้าน/สวนสาธารณะ
func practice_art() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if zone_id != "home" and zone_id != "park":
		return {"ok": false, "message": "ต้องอยู่บ้านหรือสวนสาธารณะจึงจะวาดรูปได้"}
	energy = clampi(energy - 10, 0, 100)
	stress = clampi(stress - 5, 0, 100)
	happy = clampi(happy + 4, 0, 100)
	add_skill("art", 2)
	var notes: Array[String] = ["🎨 ฝึกวาดรูป: ศิลปะ +2 • ความเครียดลดลง"]
	if has_karma("dreamer"):
		notes.append("✨ จินตนาการไหลลื่นเป็นพิเศษ")
	advance_minutes(60)
	_finish(notes)
	return {"ok": true, "message": last_message}


## ทำอาหารที่บ้าน
func cook_meal() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if zone_id != "home":
		return {"ok": false, "message": "ต้องอยู่บ้านก่อน"}
	if money < 60:
		return {"ok": false, "message": "ไม่มีวัตถุดิบพอ (ต้อง ฿60)"}
	if hunger >= 98:
		return {"ok": false, "message": "ยังไม่อิ่มเกินไป"}
	money -= 60
	hunger = clampi(hunger + 28, 0, 100)
	happy = clampi(happy + 4, 0, 100)
	add_skill("cooking", 2)
	var notes: Array[String] = ["🍳 ทำกับข้าวเอง: อิ่ม +28 • ทำอาหาร +2 • ฿-60"]
	advance_minutes(45)
	_finish(notes)
	return {"ok": true, "message": last_message}


## ประดิษฐ์ของที่บ้าน
func craft_item() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if zone_id != "home":
		return {"ok": false, "message": "ต้องอยู่บ้านก่อน"}
	if energy < 15:
		return {"ok": false, "message": "พลังงานไม่พอทำงานฝีมือ"}
	energy = clampi(energy - 15, 0, 100)
	stress = clampi(stress + 2, 0, 100)
	add_skill("craft", 2)
	var pay := 70 + skill_of("craft") * 3
	money += pay
	var notes: Array[String] = ["🔨 ประดิษฐ์ของเล็ก ๆ ขายได้ ฿%s • งานฝีมือ +2" % fmt_money(pay)]
	advance_minutes(90)
	_finish(notes)
	return {"ok": true, "message": last_message}


# ============================================================
#  งานกะจริง (v4 — ต้องเดินไปที่ทำงาน)
# ============================================================

const JOB_WORKPLACES := {
	"store": "store", "waiter": "cafe", "seller": "store", "chef": "cafe",
	"tech": "office", "designer": "mall", "account": "office", "nurse": "hospital",
	"programmer": "office", "engineer": "office", "vet": "hospital",
	"manager": "office", "doctor": "hospital", "professor": "university",
}


func current_workplace() -> String:
	if job_id == "":
		return ""
	return String(JOB_WORKPLACES.get(job_id, "office"))


func work_block_reason() -> String:
	if not alive:
		return "เกมจบแล้ว"
	if is_child():
		return "ยังเรียนอยู่ ทำงานประจำไม่ได้"
	if retired:
		return "เกษียณแล้ว"
	if not is_workday():
		return "วันหยุด ทำงานไม่ได้"
	if time_min < WORK_START:
		return "ยังไม่ถึงเวลาเข้างาน (08:00)"
	if time_min >= WORK_END:
		return "เลยเวลาเข้างานแล้ว (08:00-17:00)"
	if worked_today:
		return "วันนี้ทำงานแล้ว"
	if sick:
		return "ป่วยอยู่ ควรพักผ่อน"
	return ""


## จบกะทำงาน — score 0-100 จากมินิเกม
func work_shift(score: int) -> Dictionary:
	var blocked := work_block_reason()
	if blocked != "":
		return {"ok": false, "message": blocked}
	score = clampi(score, 0, 100)
	var notes: Array[String] = []
	var pay := 0
	if job_id == "":
		pay = int(round(float(DAILY_WAGE) * (0.6 + float(score) / 250.0)))
		money += pay
		notes.append("💼 รับจ้างรายวัน: +฿%s" % fmt_money(pay))
		performance = clampi(performance + int(score / 20.0), 0, 100)
		add_skill("communication", 1)
		add_skill("craft", 1)
	else:
		pay = int(round(float(salary()) / 5.0 * (0.6 + float(score) / 250.0)))
		money += pay
		last_salary = salary()
		performance = clampi(performance + int(round(float(score) / 12.0)) - 2, 0, 100)
		if has_karma("diligent"):
			performance = clampi(performance + 2, 0, 100)
		job_shifts += 1
		var job_skill := String(job_data().get("skill", "communication"))
		add_skill(job_skill, 2)
		add_skill("communication", 1)
		if job_shifts % 5 == 0:
			job_weeks += 1
		notes.append("💼 ทำงาน %s: +฿%s • ประสิทธิภาพ %d%%" % [
			job_title(), fmt_money(pay), performance
		])
		# เลื่อนตำแหน่ง
		if job_level < 3 and performance >= 100 and job_weeks >= PROMO_WEEKS:
			job_level += 1
			performance = 50
			notes.append("🎉 เลื่อนตำแหน่ง! เงินเดือน ฿%s/สัปดาห์" % fmt_money(salary()))
			log_event("เลื่อนตำแหน่งเป็น %s ระดับ %d" % [job_title(), job_level])
		if score < 30:
			notes.append("⚠️ วันนี้ทำงานแย่ หัวหน้าจดจำไว้")
	worked_today = true
	work_absences = 0
	_quest_bump("work")
	energy = clampi(energy - WORK_ENERGY, 0, 100)
	stress = clampi(stress + WORK_STRESS, 0, 100)
	happy = clampi(happy - 4, 0, 100)
	if outfit_formal() >= 6:
		performance = clampi(performance + 1, 0, 100)
	advance_minutes_to(WORK_END, notes)
	_clamp_stats()
	last_message = _join(notes)
	log_event("ทำงาน (%s)" % job_title())
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


# ============================================================
#  ฟิตเนส / สวนสาธารณะ
# ============================================================

func gym_session(score: int) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if age < 10:
		return {"ok": false, "message": "อายุ 10 ปีขึ้นไปจึงใช้ฟิตเนสได้"}
	if money < COST_GYM:
		return {"ok": false, "message": "เงินไม่พอค่าเข้า gym ฿%s" % fmt_money(COST_GYM)}
	money -= COST_GYM
	score = clampi(score, 0, 100)
	var fit_gain := 2 + int(score / 22.0)
	fitness = clampi(fitness + fit_gain, 0, 100)
	add_skill("athletics", 2)
	health = clampi(health + 3 + int(score / 30.0), 0, 100)
	energy = clampi(energy - 20, 0, 100)
	stress = clampi(stress - 10, 0, 100)
	happy = clampi(happy + 4, 0, 100)
	var notes: Array[String] = ["💪 ออกกำลังกาย: ฟิตเนส +%d • สุขภาพดีขึ้น" % fit_gain]
	advance_minutes(GYM_MINUTES)
	_clamp_stats()
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


## วิ่งในสวนสาธารณะ — ต้องวิ่งผ่านจุดครบ 3 รอบด้วยตัวเอง
func park_run(laps: int) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if laps < 3:
		return {"ok": false, "message": "ต้องวิ่งให้ครบ 3 รอบก่อน"}
	var fit_gain := 1 + laps
	fitness = clampi(fitness + fit_gain, 0, 100)
	add_skill("athletics", 1)
	health = clampi(health + 2, 0, 100)
	energy = clampi(energy - 15, 0, 100)
	stress = clampi(stress - 8, 0, 100)
	happy = clampi(happy + 5, 0, 100)
	var notes: Array[String] = ["🏃 วิ่งสวนสาธารณะ %d รอบ: ฟิตเนส +%d" % [laps, fit_gain]]
	advance_minutes(PARK_MINUTES)
	_clamp_stats()
	last_message = _join(notes)
	log_event("วิ่งสวนสาธารณะ %d รอบ" % laps)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


# ============================================================
#  พ่อแม่ / ครอบครัว (v4 — พ่อแม่มีตารางเวลา)
# ============================================================

func ask_allowance() -> Dictionary:
	if not is_child():
		return {"ok": false, "message": "โตแล้ว ต้องหาเงินเอง"}
	var key := month * 10 + week
	if allowance_week == key:
		return {"ok": false, "message": "ขอเงินไปแล้วสัปดาห์นี้"}
	allowance_week = key
	var amount := maxi(50, int(round(float(annual_allowance()) / 4.0)))
	money += amount
	parent_love = clampi(parent_love + 1, 0, 100)
	happy = clampi(happy + 2, 0, 100)
	var notes: Array[String] = ["👨‍👩‍👧 พ่อแม่ให้เงินใช้ ฿%s" % fmt_money(amount)]
	advance_minutes(10)
	last_message = _join(notes)
	log_event("ขอเงินพ่อแม่ ฿%s" % fmt_money(amount))
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


func family_dinner() -> Dictionary:
	if zone_id != "home":
		return {"ok": false, "message": "ต้องอยู่บ้านก่อน"}
	if not is_home_time():
		return {"ok": false, "message": "มื้อเย็นอยู่ช่วง 18:00-21:00"}
	if dinner_day == day:
		return {"ok": false, "message": "วันนี้กินข้าวกับครอบครัวแล้ว"}
	dinner_day = day
	hunger = clampi(hunger + 30, 0, 100)
	happy = clampi(happy + 6, 0, 100)
	parent_love = clampi(parent_love + 3, 0, 100)
	stress = clampi(stress - 3, 0, 100)
	var notes: Array[String] = ["🍚 กินข้าวเย็นกับพ่อแม่ • ความรักพ่อแม่ +3"]
	advance_minutes(45)
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


func talk_parent(which: String) -> Dictionary:
	var key := "%s-%d" % [which, day]
	if parent_talked.has(key):
		return {"ok": false, "message": "วันนี้คุยกับท่านแล้ว"}
	parent_talked[key] = true
	parent_love = clampi(parent_love + 2, 0, 100)
	add_skill("communication", 1)
	happy = clampi(happy + 2, 0, 100)
	social = clampi(social + 1, 0, 100)
	var lines := {
		"dad": ["พ่อบอกให้ตั้งใจเรียน แล้วอย่าลืมกินข้าว", "พ่อเล่าเรื่องวันทำงานให้ฟัง"],
		"mom": ["แม่ถามว่าวันนี้เป็นอย่างไรบ้าง", "แม่บอกว่าห้องนอนควรเก็บกวาดบ้าง"],
	}
	var pool: Array = lines.get(which, ["ครอบครัวคุยกันอย่างอบอุ่น"])
	var text := String(pool[randi() % pool.size()])
	var notes: Array[String] = ["💬 %s • ความรักพ่อแม่ +2" % text]
	advance_minutes(15)
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


# ============================================================
#  NPC ในเมือง (v4 — คุย/ให้ของ/เดท)
# ============================================================

func friendship_of(npc_id: String) -> int:
	return int(npc_friendship.get(npc_id, 0))


func friendship_rank(npc_id: String) -> String:
	var v := friendship_of(npc_id)
	if v >= 80:
		return "สนิทมาก"
	if v >= 50:
		return "เพื่อนสนิท"
	if v >= 25:
		return "เพื่อน"
	if v >= 10:
		return "คนรู้จัก"
	return "คนแปลกหน้า"


func npc_talk(npc: Dictionary) -> Dictionary:
	var npc_id := String(npc.get("id", ""))
	if npc_id == "":
		return {"ok": false, "message": "ไม่พบคนคนนี้"}
	var key := "%s-%d" % [npc_id, day]
	if npc_talked.has(key):
		return {"ok": false, "message": "วันนี้คุยกับ%sแล้ว" % String(npc.get("name", "เขา"))}
	npc_talked[key] = true
	_quest_bump("talk")
	var gain := 4
	if String(npc.get("zone", "")) == zone_id:
		gain += 1
	if has_karma("warm"):
		gain += 1
	npc_friendship[npc_id] = clampi(friendship_of(npc_id) + gain, 0, 100)
	add_skill("communication", 1)
	social = clampi(social + 1, 0, 100)
	happy = clampi(happy + 1, 0, 100)
	var lines: Array = npc.get("lines", ["สวัสดี!"])
	var text := String(lines[randi() % lines.size()])
	var notes: Array[String] = ["💬 %s: “%s” • ใจ +%d" % [
		String(npc.get("name", "?")), text, gain
	]]
	advance_minutes(10)
	last_message = _join(notes)
	log_event("คุยกับ%s" % String(npc.get("name", "?")))
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


func npc_gift(npc: Dictionary) -> Dictionary:
	var npc_id := String(npc.get("id", ""))
	if npc_id == "":
		return {"ok": false, "message": "ไม่พบคนคนนี้"}
	if money < COST_GIFT:
		return {"ok": false, "message": "เงินไม่พอซื้อของขวัญ (฿%s)" % fmt_money(COST_GIFT)}
	var key := "%s-%d" % [npc_id, day]
	if npc_gifted.has(key):
		return {"ok": false, "message": "วันนี้ให้ของขวัญ%sแล้ว" % String(npc.get("name", "เขา"))}
	npc_gifted[key] = true
	money -= COST_GIFT
	npc_friendship[npc_id] = clampi(friendship_of(npc_id) + 12, 0, 100)
	add_skill("communication", 1)
	happy = clampi(happy + 3, 0, 100)
	var notes: Array[String] = ["🎁 ให้ของขวัญ%s • ใจ +12 • ฿-%s" % [
		String(npc.get("name", "?")), fmt_money(COST_GIFT)
	]]
	advance_minutes(15)
	last_message = _join(notes)
	log_event("ให้ของขวัญ%s" % String(npc.get("name", "?")))
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


func npc_date(npc: Dictionary) -> Dictionary:
	var npc_id := String(npc.get("id", ""))
	if is_child():
		return {"ok": false, "message": "โตก่อนค่อยเดทนะ"}
	if String(npc.get("dateable", "yes")) == "no":
		return {"ok": false, "message": "%s ไม่ใช่คนที่เดทได้" % String(npc.get("name", "เขา"))}
	if friendship_of(npc_id) < 30:
		return {"ok": false, "message": "ใจยังไม่ถึง 30 — คุย/ให้ของก่อน"}
	if money < COST_DATE_NPC:
		return {"ok": false, "message": "เงินไม่พอออกเดท (฿%s)" % fmt_money(COST_DATE_NPC)}
	if partner_name != "" and partner_name != String(npc.get("name", "")):
		return {"ok": false, "message": "มีคนรักอยู่แล้ว (%s)" % partner_name}
	money -= COST_DATE_NPC
	var chance := 0.35 + float(friendship_of(npc_id)) / 200.0 + float(social) / 400.0
	var notes: Array[String] = []
	if partner_name == "":
		if randf() < chance:
			partner_name = String(npc.get("name", "?"))
			partner_love = clampi(friendship_of(npc_id), 30, 100)
			partner_npc_id = npc_id
			partner_look = _appearance_from_npc(npc)
			partner_genes = _default_genes(partner_look)
			player_genes = _normalize_genes(player_genes, player_appearance())
			notes.append("💗 %s ตอบรับเป็นคนรัก! • ฿-%s" % [partner_name, fmt_money(COST_DATE_NPC)])
			log_event("เริ่มคบกับ%s" % partner_name)
		else:
			npc_friendship[npc_id] = clampi(friendship_of(npc_id) + 5, 0, 100)
			notes.append("🍰 เดทกับ%s สนุกดี แต่ยังเป็นแค่เพื่อน • ฿-%s" % [
				String(npc.get("name", "?")), fmt_money(COST_DATE_NPC)
			])
	else:
		partner_love = clampi(partner_love + 6, 0, 100)
		happy = clampi(happy + 8, 0, 100)
		notes.append("💕 เดทกับ%s หวานมาก • ความรัก +6 • ฿-%s" % [
			partner_name, fmt_money(COST_DATE_NPC)
		])
	energy = clampi(energy - 10, 0, 100)
	happy = clampi(happy + 6, 0, 100)
	add_skill("communication", 1)
	advance_minutes(120)
	_clamp_stats()
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


# ============================================================
#  อาหาร / ร้านค้า / บาร์ (v4)
# ============================================================

## ซื้ออาหารกินทั่วไป — price, hunger ที่เพิ่ม, ความสุข, เวลาที่ใช้
func eat_food(price: int, hunger_gain: int, happy_gain: int, minutes: int, label: String) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if money < price:
		return {"ok": false, "message": "เงินไม่พอ (ต้อง ฿%s)" % fmt_money(price)}
	if hunger >= 98:
		return {"ok": false, "message": "อิ่มเต็มที่แล้ว"}
	money -= price
	hunger = clampi(hunger + hunger_gain, 0, 100)
	happy = clampi(happy + happy_gain, 0, 100)
	energy = clampi(energy + 4, 0, 100)
	var notes: Array[String] = ["🍽️ %s • อิ่ม +%d • ฿-%s" % [
		label, hunger_gain, fmt_money(price)
	]]
	advance_minutes(maxi(minutes, 5))
	_clamp_stats()
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


## ดูทีวีที่บ้าน — พักผ่อนคลายเครียด
func watch_tv() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	stress = clampi(stress - 7, 0, 100)
	happy = clampi(happy + 3, 0, 100)
	energy = clampi(energy + 2, 0, 100)
	var notes: Array[String] = ["📺 ดูทีวีที่บ้าน • เครียด -7 • สุข +3"]
	advance_minutes(30)
	_clamp_stats()
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


## นั่งพักบนม้านั่งสาธารณะ — ผ่อนคลายวันละครั้ง
func rest_bench() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if bench_day == day:
		return {"ok": false, "message": "วันนี้นั่งพักม้านั่งแล้ว — เดินเล่นต่อดีกว่า"}
	bench_day = day
	stress = clampi(stress - 9, 0, 100)
	happy = clampi(happy + 3, 0, 100)
	energy = clampi(energy + 8, 0, 100)
	var notes: Array[String] = ["🪑 นั่งพักบนม้านั่ง • เครียด -9 • พลังงาน +8 • สุข +3"]
	if weather == "rain":
		notes.append("ฝนโปรยเบา ๆ กลิ่นดินหอม")
	advance_minutes(25)
	_clamp_stats()
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


func bar_drink() -> Dictionary:
	if is_child():
		return {"ok": false, "message": "ยังเด็ก เข้าบาร์ไม่ได้"}
	if money < 200:
		return {"ok": false, "message": "เงินไม่พอ (ต้อง ฿200)"}
	money -= 200
	happy = clampi(happy + 8, 0, 100)
	social = clampi(social + 3, 0, 100)
	energy = clampi(energy - 6, 0, 100)
	stress = clampi(stress - 6, 0, 100)
	var notes: Array[String] = ["🍻 สั่งเครื่องดื่มที่บาร์ • ความสุข +8 • สังคม +3 • ฿-200"]
	advance_minutes(90)
	_clamp_stats()
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


# ============================================================
#  อาชีพ
# ============================================================

func _job_by_id(id: String) -> Dictionary:
	for j in JOBS:
		if j["id"] == id:
			return j
	return {}


## คืน "" ถ้าสมัครได้ หรือข้อความเหตุผลที่สมัครไม่ได้
func apply_block_reason(id: String) -> String:
	if not alive:
		return "เกมจบแล้ว"
	if is_child():
		return "ต้องอายุ 18 ก่อน"
	var j := _job_by_id(id)
	if j.is_empty():
		return "ไม่มีตำแหน่งนี้"
	if id == job_id:
		return "ทำงานนี้อยู่แล้ว"
	if edu < int(j["edu"]):
		return "ต้องมีความรู้ %d (ตอนนี้ %d)" % [int(j["edu"]), edu]
	var req_skill := String(j.get("skill", ""))
	var req_value := int(j.get("skill_req", 0))
	if req_skill != "" and req_value > 0 and skill_of(req_skill) < req_value:
		return "ต้องมีทักษะ%s %d (ตอนนี้ %d)" % [
			skill_name(req_skill), req_value, skill_of(req_skill)
		]
	return ""


func apply_chance(id: String) -> float:
	var j := _job_by_id(id)
	if j.is_empty():
		return 0.0
	var c := 0.35 + float(edu) / 220.0 + float(social) / 500.0
	c += float(edu - int(j["edu"])) / 400.0
	var req_skill := String(j.get("skill", ""))
	if req_skill != "":
		c += float(skill_of(req_skill)) / 500.0
	c += float(outfit_charm()) / 100.0
	if outfit_formal() >= 6:
		c += 0.04
	if job_id != "":
		c += 0.05
	if has_karma("lucky"):
		c += 0.03
	return clampf(c, 0.1, 0.95)


func apply_job(id: String) -> Dictionary:
	var blocked := apply_block_reason(id)
	if blocked != "":
		return {"ok": false, "message": blocked}

	var j := _job_by_id(id)
	var notes: Array[String] = []
	energy = clampi(energy - 8, 0, 100)

	if randf() < apply_chance(id):
		job_id = id
		job_level = 1
		job_weeks = 0
		performance = 50
		retired = false
		notes.append("ได้งาน %s! ฿%s/สัปดาห์" % [j["title"], fmt_money(salary())])
		log_event("เริ่มงาน %s" % j["title"])
	else:
		happy = clampi(happy - 3, 0, 100)
		notes.append("สมัคร %s ไม่ผ่าน..." % j["title"])

	return _finish(notes)


func quit_job() -> Dictionary:
	if job_id == "":
		return {"ok": false, "message": "ไม่มีงานให้ลาออก"}
	var old := job_title()
	job_id = ""
	job_level = 1
	job_weeks = 0
	performance = 50
	log_event("ลาออกจาก %s" % old)
	_instant(["ลาออกจาก %s แล้ว ตอนนี้ว่างงาน" % old])
	return {"ok": true, "message": last_message}


# ============================================================
#  ความสัมพันธ์ / ครอบครัว
# ============================================================

func date_night() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if is_child():
		return {"ok": false, "message": "ยังเด็กเกินไปสำหรับออกเดท"}
	if money < COST_DATE:
		return {"ok": false, "message": "เงินไม่พอออกเดท (ต้อง ฿%s)" % fmt_money(COST_DATE)}

	money -= COST_DATE
	energy = clampi(energy - 8, 0, 100)
	var notes: Array[String] = []

	if partner_name == "":
		var chance := 0.40 + float(social) / 300.0 + float(happy) / 600.0
		chance += float(outfit_charm()) / 200.0
		if randf() < chance:
			partner_name = _random_name()
			partner_love = 55
			partner_npc_id = ""
			partner_look = _random_partner_appearance()
			partner_genes = _default_genes(partner_look)
			player_genes = _normalize_genes(player_genes, player_appearance())
			notes.append("ได้รู้จัก %s เริ่มคบกันแล้ว 💕" % partner_name)
			log_event("เริ่มคบกับ %s" % partner_name)
		else:
			happy = clampi(happy - 4, 0, 100)
			notes.append("ออกเดทแต่ยังไม่เจอคนถูกใจ")
	else:
		partner_love = clampi(partner_love + 12, 0, 100)
		happy = clampi(happy + 6, 0, 100)
		notes.append("เดทกับ %s ความรัก +12 💕" % partner_name)

	return _finish(notes)


func propose() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if partner_name == "":
		return {"ok": false, "message": "ยังไม่มีคนรัก"}
	if married:
		return {"ok": false, "message": "แต่งงานแล้ว"}
	if money < COST_RING:
		return {"ok": false, "message": "เงินไม่พอซื้อแหวน (ต้อง ฿%s)" % fmt_money(COST_RING)}
	if partner_love < 70:
		return {"ok": false, "message": "ความรักยังไม่พอ (ต้อง 70)"}

	money -= COST_RING
	var notes: Array[String] = []
	var chance := 0.5 + float(partner_love) / 300.0 + float(outfit_charm()) / 300.0
	if randf() < chance:
		married = true
		partner_love = clampi(partner_love + 10, 0, 100)
		happy = clampi(happy + 20, 0, 100)
		notes.append("แต่งงานกับ %s! 🎉" % partner_name)
		log_event("แต่งงานกับ %s" % partner_name)
	else:
		partner_love = clampi(partner_love - 15, 0, 100)
		happy = clampi(happy - 10, 0, 100)
		notes.append("%s ยังไม่พร้อม... ความรัก -15" % partner_name)

	return _finish(notes)


func have_child() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if partner_name == "":
		return {"ok": false, "message": "ต้องมีคนรักและตกลงสร้างครอบครัวด้วยกันก่อน"}
	if age < ADULT_AGE:
		return {"ok": false, "message": "ต้องเป็นผู้ใหญ่ก่อนจึงวางแผนครอบครัวได้"}
	if age > 45:
		return {"ok": false, "message": "อายุมากเกินไปสำหรับการมีลูก"}
	if children.size() >= 3:
		return {"ok": false, "message": "มีลูกเต็มที่แล้ว (3 คน)"}
	if money < COST_CHILD:
		return {"ok": false, "message": "เงินไม่พอเตรียมตัวมีลูก (ต้อง ฿%s)" % fmt_money(COST_CHILD)}

	money -= COST_CHILD
	stress = clampi(stress + 6, 0, 100)
	var notes: Array[String] = []
	if randf() < 0.7:
		var kid_name := _random_name()
		var inheritance := _inherit_child_appearance()
		children.append({
			"name": kid_name,
			"age": 0,
			"appearance": inheritance["appearance"],
			"genes": inheritance["genes"],
			"traits_from": inheritance["traits_from"],
			"other_parent": partner_name,
		})
		happy = clampi(happy + 15, 0, 100)
		notes.append("มีลูกแล้ว! %s 👶 ลักษณะถ่ายทอดจากคุณและ%s" % [kid_name, partner_name])
		log_event("มีลูก: %s" % kid_name)
	else:
		happy = clampi(happy - 3, 0, 100)
		notes.append("ยังไม่มีข่าวดี...")

	return _finish(notes)


func break_up() -> Dictionary:
	if partner_name == "":
		return {"ok": false, "message": "ยังไม่มีคนรัก"}
	var name := partner_name
	partner_name = ""
	partner_love = 0
	married = false
	partner_npc_id = ""
	partner_look = {}
	partner_genes = {}
	happy = clampi(happy - 15, 0, 100)
	log_event("เลิกกับ %s" % name)
	_instant(["เลิกกับ %s แล้ว" % name])
	return {"ok": true, "message": last_message}


# ============================================================
#  การเงิน: ออม / กู้ / ประกัน
# ============================================================

func borrow_limit() -> int:
	var limit := 10000 + bank / 2
	if job_id != "":
		limit += salary() * 12
	return mini(limit, 150000)


func deposit(v: int) -> Dictionary:
	if is_child():
		return {"ok": false, "message": "เด็กยังจัดการเงินเองไม่ได้"}
	if v <= 0 or money < v:
		return {"ok": false, "message": "เงินสดไม่พอ"}
	money -= v
	bank += v
	_instant(["ฝากเงิน ฿%s เข้าบัญชี (ออม ฿%s)" % [fmt_money(v), fmt_money(bank)]])
	return {"ok": true, "message": last_message}


func withdraw(v: int) -> Dictionary:
	if is_child():
		return {"ok": false, "message": "เด็กยังจัดการเงินเองไม่ได้"}
	if v <= 0 or bank < v:
		return {"ok": false, "message": "เงินในบัญชีไม่พอ"}
	bank -= v
	money += v
	_instant(["ถอนเงิน ฿%s จากบัญชี" % fmt_money(v)])
	return {"ok": true, "message": last_message}


func borrow(v: int) -> Dictionary:
	if is_child():
		return {"ok": false, "message": "เด็กยังกู้เงินไม่ได้"}
	if v <= 0:
		return {"ok": false, "message": "จำนวนเงินไม่ถูกต้อง"}
	if loan + v > borrow_limit():
		return {"ok": false, "message": "วงเงินกู้ไม่พอ (กู้ได้อีก ฿%s)" % fmt_money(borrow_limit() - loan)}
	loan += v
	money += v
	_instant(["กู้เงิน ฿%s (หนี้รวม ฿%s)" % [fmt_money(v), fmt_money(loan)]])
	return {"ok": true, "message": last_message}


func repay(v: int) -> Dictionary:
	if loan <= 0:
		return {"ok": false, "message": "ไม่มีหนี้ต้องจ่าย"}
	var pay := mini(mini(v, loan), money)
	if pay <= 0:
		return {"ok": false, "message": "เงินสดไม่พอจ่ายหนี้"}
	money -= pay
	loan -= pay
	_instant(["จ่ายหนี้ ฿%s (เหลือ ฿%s)" % [fmt_money(pay), fmt_money(loan)]])
	return {"ok": true, "message": last_message}


func toggle_insurance() -> Dictionary:
	if is_child():
		return {"ok": false, "message": "พ่อแม่ดูแลประกันให้อยู่แล้ว"}
	if insurance:
		insurance = false
		_instant(["ยกเลิกประกันสุขภาพแล้ว"])
		return {"ok": true, "message": last_message}
	if money < COST_INSURANCE:
		return {"ok": false, "message": "เงินไม่พอจ่ายเบี้ยประกัน ฿%s" % fmt_money(COST_INSURANCE)}
	money -= COST_INSURANCE
	insurance = true
	_instant(["ซื้อประกันสุขภาพแล้ว (เบี้ย ฿%s/เดือน)" % fmt_money(COST_INSURANCE)])
	return {"ok": true, "message": last_message}


# ============================================================
#  สุขภาพ: ยา / หมอ / ตรวจสุขภาพ
# ============================================================

func medical_cost(base: int) -> int:
	if insurance:
		return int(round(float(base) * 0.3))
	return base


func buy_medicine() -> Dictionary:
	if is_child():
		return {"ok": false, "message": "พ่อแม่พาไปหาหมออยู่แล้ว"}
	if not sick:
		return {"ok": false, "message": "ตอนนี้ไม่ได้ป่วย"}
	var cost := medical_cost(COST_MEDICINE)
	if money < cost:
		return {"ok": false, "message": "เงินไม่พอซื้อยา"}
	money -= cost
	var notes: Array[String] = ["ซื้อยามากินเอง ฿%s" % fmt_money(cost)]
	if randf() < 0.6:
		_cure_sick()
		health = clampi(health + 2, 0, 100)
		notes.append("อาการดีขึ้น หายป่วยแล้ว")
	else:
		health = clampi(health + 1, 0, 100)
		notes.append("ยังไม่หายดี ต้องพักต่อ")
	_instant(notes)
	return {"ok": true, "message": last_message}


func see_doctor() -> Dictionary:
	if is_child():
		return {"ok": false, "message": "พ่อแม่พาไปหาหมออยู่แล้ว"}
	var cost := medical_cost(COST_DOCTOR)
	if money < cost:
		return {"ok": false, "message": "เงินไม่พอค่าหมอ"}
	money -= cost
	var notes: Array[String] = ["ไปหาหมอ ฿%s" % fmt_money(cost)]
	if sick:
		_cure_sick()
		notes.append("หมอรักษาให้ หายป่วยแล้ว")
	health = clampi(health + 10, 0, 100)
	_instant(notes)
	return {"ok": true, "message": last_message}


func checkup() -> Dictionary:
	if is_child():
		return {"ok": false, "message": "พ่อแม่พาไปตรวจอยู่แล้ว"}
	var cost := medical_cost(COST_CHECKUP)
	if money < cost:
		return {"ok": false, "message": "เงินไม่พอค่าตรวจสุขภาพ"}
	money -= cost
	health = clampi(health + 4, 0, 100)
	var notes: Array[String] = ["ตรวจสุขภาพประจำปี ฿%s" % fmt_money(cost)]
	if sick:
		notes.append("ตรวจพบ%s — ควรไปหาหมอ" % illness)
	else:
		notes.append("ผลตรวจปกติดี สุขภาพ +4")
	_instant(notes)
	return {"ok": true, "message": last_message}


func _cure_sick() -> void:
	sick = false
	illness = ""
	sick_weeks = 0


# ============================================================
#  แต่งตัว
# ============================================================

func outfit_data(id: String) -> Dictionary:
	for o in OUTFITS:
		if o["id"] == id:
			return o
	return {}


func owns_outfit(id: String) -> bool:
	return owned_outfits.has(id)


func outfit_charm() -> int:
	return int(outfit_data(outfit).get("charm", 0))


func outfit_formal() -> int:
	return int(outfit_data(outfit).get("formal", 0))


func buy_outfit(id: String) -> Dictionary:
	var data := outfit_data(id)
	if data.is_empty():
		return {"ok": false, "message": "ไม่มีชุดนี้"}
	if owns_outfit(id):
		return {"ok": false, "message": "มีชุดนี้แล้ว"}
	var price := int(data["price"])
	if money < price:
		return {"ok": false, "message": "เงินไม่พอซื้อชุด (ต้อง ฿%s)" % fmt_money(price)}
	money -= price
	owned_outfits.append(id)
	outfit = id
	_instant(["ซื้อ %s แล้ว สวมให้เลย ✨" % data["name"]])
	return {"ok": true, "message": last_message}


func equip_outfit(id: String) -> Dictionary:
	if not owns_outfit(id):
		return {"ok": false, "message": "ยังไม่ได้เป็นเจ้าของชุดนี้"}
	outfit = id
	_instant(["เปลี่ยนเป็น %s แล้ว" % outfit_data(id)["name"]])
	return {"ok": true, "message": last_message}


# ============================================================
#  เหตุการณ์ชีวิต
# ============================================================

func resolve_event(index: int) -> Dictionary:
	if pending_event.is_empty():
		return {"ok": false, "message": "ไม่มีเหตุการณ์ค้างอยู่"}
	var options: Array = pending_event.get("options", [])
	if index < 0 or index >= options.size():
		return {"ok": false, "message": "ตัวเลือกไม่ถูกต้อง"}

	var opt: Dictionary = options[index]
	var cost := int(opt.get("cost", 0))
	if cost > money:
		return {"ok": false, "message": "เงินไม่พอสำหรับตัวเลือกนี้"}

	money -= cost
	var effects: Dictionary = opt.get("effects", {})
	var text := String(opt.get("text", opt.get("label", "")))

	if opt.has("chance"):
		var success: Dictionary = opt.get("success", {})
		var fail: Dictionary = opt.get("fail", {})
		if randf() < float(opt["chance"]):
			effects = success.get("effects", {})
			text = String(success.get("text", text))
		else:
			effects = fail.get("effects", {})
			text = String(fail.get("text", text))

	_apply_effects(effects)
	pending_event = {}

	var notes: Array[String] = [text]
	_check_death(notes)
	_clamp_stats()
	log_event(text)
	last_message = _join(notes)
	save_game()
	changed.emit()
	return {"ok": true, "message": last_message}


func _apply_effects(e: Dictionary) -> void:
	for k in e:
		var v := int(e[k])
		match String(k):
			"money":
				money += v
			"bank":
				bank = maxi(bank + v, 0)
			"loan":
				loan = maxi(loan + v, 0)
			"health":
				health = clampi(health + v, 0, 100)
			"happy":
				happy = clampi(happy + v, 0, 100)
			"energy":
				energy = clampi(energy + v, 0, 100)
			"hunger":
				hunger = clampi(hunger + v, 0, 100)
			"stress":
				stress = clampi(stress + v, 0, 100)
			"edu":
				edu = clampi(edu + v, 0, 100)
			"social":
				social = clampi(social + v, 0, 100)
			"performance":
				performance = clampi(performance + v, 0, 100)
			"parent_love":
				parent_love = clampi(parent_love + v, 0, 100)
			"friend_love":
				friend_love = clampi(friend_love + v, 0, 100)
			"love":
				if partner_name != "":
					partner_love = clampi(partner_love + v, 0, 100)
			"fired":
				if v > 0 and job_id != "":
					job_id = ""
					job_level = 1
					job_weeks = 0
					performance = 50
					retired = false
			"partner":
				if v > 0 and partner_name == "":
					partner_name = _random_name()
					partner_love = 55
			"rent":
				rent_extra = clampi(rent_extra + v, 0, 2000)


# ============================================================
#  ช่วยเหลือ / บันทึก / โหลด
# ============================================================

const NAMES_M := [
	"โอ๊ต", "ภูมิ", "เจมส์", "กัน", "บีม", "เจ", "พี", "ต้น", "บอส", "เติ้ล",
]
const NAMES_F := [
	"นุ่น", "มิ้นท์", "เฟิร์น", "ปลา", "ข้าว", "จูน", "ต้า", "แนน", "แพร", "ฝน",
]
const NAMES_ANY := [
	"นุ่น", "มิ้นท์", "เฟิร์น", "ปลา", "ข้าว", "จูน", "ต้า", "แนน",
	"โอ๊ต", "ภูมิ", "เจมส์", "กัน", "แพร", "บีม", "เจ", "พี",
]


func suggest_name(g: String) -> String:
	var pool: Array = NAMES_F if g == "หญิง" else NAMES_M
	return String(pool[randi() % pool.size()])


func _random_name() -> String:
	return String(NAMES_ANY[randi() % NAMES_ANY.size()])


func _join(notes: Array[String]) -> String:
	var text := ""
	for n in notes:
		if text != "":
			text += "\n"
		text += n
	return text


## ใช้กับการกระทำที่ไม่เดินเวลา (การเงิน/ยา/แต่งตัว)
func _instant(notes: Array[String]) -> void:
	_clamp_stats()
	last_message = _join(notes)
	save_game()
	changed.emit()


func log_event(text: String) -> void:
	life_log.push_front("อายุ %d • %s" % [age, text])
	if life_log.size() > 40:
		life_log.resize(40)


# ============================================================
#  v7 — ฟาร์มหลังบ้าน
# ============================================================

func crop_data(id: String) -> Dictionary:
	for cr in CROPS:
		if String(cr.get("id", "")) == id:
			return cr
	return {}


func farm_plot_data(index: int) -> Dictionary:
	if index < 0 or index >= farm_plots.size():
		return {}
	var p = farm_plots[index]
	if typeof(p) != TYPE_DICTIONARY:
		return {}
	return p


func farm_crop(index: int) -> String:
	return String(farm_plot_data(index).get("crop", ""))


func farm_stage(index: int) -> String:
	var p := farm_plot_data(index)
	if p.is_empty() or String(p.get("crop", "")) == "":
		return "empty"
	var c := crop_data(String(p.get("crop", "")))
	var need := maxi(int(c.get("days", 1)), 1)
	var growth := int(p.get("growth", 0))
	if growth >= need:
		return "ready"
	var ratio := float(growth) / float(need)
	if ratio >= 0.55:
		return "grown"
	if ratio >= 0.2:
		return "sprout"
	return "seed"


func farm_ready_count() -> int:
	var n := 0
	for i in farm_plots.size():
		if farm_stage(i) == "ready":
			n += 1
	return n


func farm_watered_count() -> int:
	var n := 0
	for i in farm_plots.size():
		if bool(farm_plot_data(i).get("watered", false)):
			n += 1
	return n


## ปลูกผักในแปลง — ใช้เงินค่าเมล็ด + เวลา 20 นาที
func farm_plant(index: int, crop_id: String) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if index < 0 or index >= farm_plots.size():
		return {"ok": false, "message": "ไม่มีแปลงปลูกนี้"}
	var p := farm_plot_data(index)
	if String(p.get("crop", "")) != "":
		return {"ok": false, "message": "แปลงนี้มี%sอยู่แล้ว" % String(crop_data(String(p["crop"])).get("name", "พืช"))}
	var c := crop_data(crop_id)
	if c.is_empty():
		return {"ok": false, "message": "ไม่รู้จักเมล็ดพันธุ์นี้"}
	var price := int(c["seed"])
	if money < price:
		return {"ok": false, "message": "เงินไม่พอซื้อเมล็ด (ต้อง ฿%s)" % fmt_money(price)}
	money -= price
	farm_plots[index] = {"crop": crop_id, "growth": 0, "watered": false}
	add_skill("cooking", 1)
	add_skill("craft", 1)
	advance_minutes(20)
	_finish(["🌱 ปลูก%sในแปลง %d • ฿-%s • อีก %d วันรดน้ำให้ครบแล้วเก็บได้" % [
		String(c["name"]), index + 1, fmt_money(price), int(c["days"])
	]])
	return {"ok": true, "message": last_message}


## รดน้ำแปลงเดียว
func farm_water(index: int) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	var p := farm_plot_data(index)
	if String(p.get("crop", "")) == "":
		return {"ok": false, "message": "แปลงนี้ยังว่างอยู่"}
	if bool(p.get("watered", false)):
		return {"ok": false, "message": "วันนี้รดน้ำแปลงนี้แล้ว"}
	p["watered"] = true
	farm_plots[index] = p
	advance_minutes(10)
	_finish(["💧 รดน้ำแปลง %d แล้ว" % (index + 1)])
	return {"ok": true, "message": last_message}


## รดน้ำทุกแปลงที่ยังไม่ได้รด
func farm_water_all() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	var n := 0
	for i in farm_plots.size():
		var p := farm_plot_data(i)
		if String(p.get("crop", "")) == "":
			continue
		if bool(p.get("watered", false)):
			continue
		p["watered"] = true
		farm_plots[i] = p
		n += 1
	if n == 0:
		return {"ok": false, "message": "ไม่มีแปลงที่ต้องรดน้ำ"}
	add_skill("craft", 1)
	advance_minutes(10 + n * 5)
	_finish(["💧 รดน้ำ %d แปลง • มือเปื้อนดินนิด ๆ" % n])
	return {"ok": true, "message": last_message}


## เก็บเกี่ยวแล้วขายผลผลิตทันที
func farm_harvest(index: int) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	var p := farm_plot_data(index)
	var crop_id := String(p.get("crop", ""))
	if crop_id == "":
		return {"ok": false, "message": "แปลงนี้ว่างอยู่"}
	var c := crop_data(crop_id)
	var need := maxi(int(c.get("days", 1)), 1)
	if int(p.get("growth", 0)) < need:
		return {"ok": false, "message": "%sยังไม่สุก (โต %d/%d วัน)" % [
			String(c.get("name", "พืช")), int(p.get("growth", 0)), need
		]}
	var sell := int(c.get("sell", 0))
	var bonus := int(round(float(sell) * 0.15)) if has_karma("grounded") else 0
	money += sell + bonus
	harvest_total += 1
	_quest_bump("harvest")
	farm_plots[index] = {"crop": "", "growth": 0, "watered": false}
	add_skill("cooking", 2)
	add_skill("craft", 1)
	add_fame(1, "ขายผลผลิตจากสวน")
	var notes: Array[String] = ["🥬 เก็บ%sขายได้ ฿%s" % [String(c.get("name", "พืช")), fmt_money(sell + bonus)]]
	if bonus > 0:
		notes.append("🌿 กรรมพันสายดินช่วยให้ปลูกง่ายและขายได้ราคาดี +15%")
	notes.append("เก็บเกี่ยวสะสม %d ครั้ง" % harvest_total)
	check_achievements()
	advance_minutes(20)
	_finish(notes)
	return {"ok": true, "message": last_message}


func _farm_new_day() -> void:
	for i in farm_plots.size():
		var p := farm_plot_data(i)
		if p.is_empty():
			continue
		var crop_id := String(p.get("crop", ""))
		if crop_id != "" and bool(p.get("watered", false)):
			var c := crop_data(crop_id)
			var need := maxi(int(c.get("days", 1)), 1)
			p["growth"] = mini(int(p.get("growth", 0)) + 1, need)
		p["watered"] = false
		farm_plots[i] = p


# ============================================================
#  v7 — ตกปลา / จับแมลง
# ============================================================

func fish_available() -> bool:
	return alive and fish_actions < 5 and energy >= 8


func bug_available() -> bool:
	return alive and bug_actions < 5 and energy >= 6


func _pick_by_rarity(table: Dictionary, tier: int) -> String:
	var pool: Array[String] = []
	for id in table.keys():
		if int(table[id].get("rarity", 0)) == tier:
			pool.append(String(id))
	if pool.is_empty():
		if tier <= 0:
			return String(table.keys()[0]) if not table.is_empty() else ""
		return _pick_by_rarity(table, tier - 1)
	return pool[randi() % pool.size()]


func _roll_tier(quality: int) -> int:
	var q := clampi(quality, 0, 2)
	var r := randf()
	if r < 0.03 + q * 0.05:
		return 3
	if r < 0.14 + q * 0.09:
		return 2
	if r < 0.45 + q * 0.08:
		return 1
	return 0


## ผลตกปลา — success มาจากมินิเกม, quality 0..2 (ยิ่งดีโอกาสปลาหายากสูง)
func fish_result(success: bool, quality: int = 0) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว", "caught": ""}
	if fish_actions >= 5:
		return {"ok": false, "message": "วันนี้ตกปลาครบ 5 ครั้งแล้ว", "caught": ""}
	if energy < 8:
		return {"ok": false, "message": "เหนื่อยเกินไปสำหรับตกปลา", "caught": ""}
	fish_actions += 1
	energy = clampi(energy - 8, 0, 100)
	add_skill("athletics", 1)
	if not success:
		advance_minutes(25)
		_finish(["🎣 ปลากินเหยื่อแล้วว่ายหนีไปเสียก่อน..."])
		return {"ok": true, "caught": "", "name": "", "value": 0, "message": last_message}
	var tier := _roll_tier(quality)
	var fish_id := _pick_by_rarity(FISH_TABLE, tier)
	var f: Dictionary = FISH_TABLE.get(fish_id, {})
	var value := int(f.get("value", 0))
	money += value
	fish_total += 1
	_quest_bump("fish")
	fish_catches[fish_id] = int(fish_catches.get(fish_id, 0)) + 1
	var notes: Array[String] = ["🎣 ตกได้%s! ขายได้ ฿%s" % [String(f.get("name", fish_id)), fmt_money(value)]]
	if int(f.get("rarity", 0)) >= 2:
		notes.append("✨ ปลาหายาก! คนแถวนั้นพากันมอง")
		add_fame(2, "ตกปลาหายากได้")
	add_skill("cooking", 1)
	check_achievements()
	advance_minutes(30)
	_finish(notes)
	return {"ok": true, "caught": fish_id, "name": String(f.get("name", fish_id)),
		"value": value, "message": last_message}


## ผลจับแมลง
func bug_result(success: bool, quality: int = 0) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว", "caught": ""}
	if bug_actions >= 5:
		return {"ok": false, "message": "วันนี้จับแมลงครบ 5 ครั้งแล้ว", "caught": ""}
	if energy < 6:
		return {"ok": false, "message": "เหนื่อยเกินไปสำหรับไล่จับแมลง", "caught": ""}
	bug_actions += 1
	energy = clampi(energy - 6, 0, 100)
	add_skill("craft", 1)
	if not success:
		advance_minutes(20)
		_finish(["🦋 แมลงตัวนั้นบินหนีไปแล้ว..."])
		return {"ok": true, "caught": "", "name": "", "value": 0, "message": last_message}
	var tier := _roll_tier(quality)
	var bug_id := _pick_by_rarity(BUG_TABLE, tier)
	var b: Dictionary = BUG_TABLE.get(bug_id, {})
	var value := int(b.get("value", 0))
	money += value
	bug_total += 1
	_quest_bump("bug")
	bug_catches[bug_id] = int(bug_catches.get(bug_id, 0)) + 1
	var notes: Array[String] = ["🦋 จับได้%s! ขายให้นักสะสมได้ ฿%s" % [
		String(b.get("name", bug_id)), fmt_money(value)
	]]
	if int(b.get("rarity", 0)) >= 2:
		notes.append("✨ แมลงหายาก! เก็บใส่กล่องอย่างดี")
		add_fame(2, "จับแมลงหายากได้")
	check_achievements()
	advance_minutes(25)
	_finish(notes)
	return {"ok": true, "caught": bug_id, "name": String(b.get("name", bug_id)),
		"value": value, "message": last_message}


func fish_caught_kinds() -> int:
	return fish_catches.size()


func bug_caught_kinds() -> int:
	return bug_catches.size()


# ============================================================
#  v7 — ชื่อเสียง / ข่าวลือ
# ============================================================

const RUMORS := [
	"ได้ยินว่า%sปลูกผักหลังบ้านเก่งขึ้นทุกวัน",
	"เมื่อวานเห็น%sเดินยิ้มอยู่แถวสวนสาธารณะ",
	"ใคร ๆ ก็พูดถึงรสชาติอาหารฝีมือ%s",
	"%sตกปลาได้ตัวเบ้อเริ่ม เล่าให้ใครฟังก็ไม่เชื่อ",
	"เด็กแถวนั้นบอกว่า%sใจดี แบ่งขนมให้ทุกครั้ง",
	"มีคนเห็น%sนั่งอ่านหนังสือใต้ต้นไม้ทั้งบ่าย",
	"ร้านกาแฟแถวบ้านบอกว่า%sเป็นลูกค้าขาประจำ",
	"เสียงลือเสียงเล่าอ้างว่า%sกำลังฝึกฝนอะไรบางอย่าง",
]

const RUMORS_FAME := [
	"ทั้งเมืองกำลังพูดถึง%s!",
	"ข่าวของ%sขึ้นป้ายประกาศหน้าศาลากลาง",
	"มีคนขอถ่ายรูปคู่กับ%sที่ตลาดเมื่อเช้า",
	"ชื่อของ%sถูกพูดถึงในรายการวิทยุท้องถิ่น",
]


func add_fame(amount: int, reason: String = "") -> void:
	if amount == 0:
		return
	var before := fame
	fame = clampi(fame + amount, 0, 100)
	if reason != "" and fame != before:
		log_event("ชื่อเสียง %+d • %s" % [amount, reason])


func fame_title() -> String:
	if fame >= 85:
		return "ตำนานแห่งเมือง"
	if fame >= 65:
		return "ดาวเด่นของเมือง"
	if fame >= 45:
		return "ชื่อเสียงในเมือง"
	if fame >= 25:
		return "คนรู้จักในละแวก"
	if fame >= 10:
		return "ข่าวซุบซิบในซอย"
	return "ยังไม่มีใครรู้จัก"


func rumor_text() -> String:
	if rumor_today != "":
		return rumor_today
	return "วันนี้เมืองเงียบสงบ... ยังไม่มีข่าวลืออะไร"


func _rumor_new_day() -> void:
	rumor_today = ""
	var chance := 0.45 + float(fame) / 200.0
	if randf() > chance:
		return
	var pool: Array = RUMORS
	if fame >= 45 and randf() < 0.6:
		pool = RUMORS_FAME
	var line := String(pool[randi() % pool.size()])
	rumor_today = "💬 " + (line % player_name)


# ============================================================
#  v7 — ความสำเร็จ / รางวัล
# ============================================================

func achievement_data(id: String) -> Dictionary:
	for a in ACHIEVEMENTS:
		if String(a.get("id", "")) == id:
			return a
	return {}


func achievement_unlocked(id: String) -> bool:
	return bool(achievements.get(id, false))


func achievement_is_claimed(id: String) -> bool:
	return bool(achievement_claimed.get(id, false))


func achievement_ready_count() -> int:
	var n := 0
	for a in ACHIEVEMENTS:
		var id := String(a["id"])
		if achievement_unlocked(id) and not achievement_is_claimed(id):
			n += 1
	return n


func unlocked_achievement_count() -> int:
	var n := 0
	for a in ACHIEVEMENTS:
		if achievement_unlocked(String(a["id"])):
			n += 1
	return n


func _achievement_met(id: String) -> bool:
	match id:
		"first_harvest":
			return harvest_total >= 1
		"green_thumb":
			return harvest_total >= 10
		"first_fish":
			return fish_total >= 1
		"master_angler":
			return fish_total >= 10
		"bug_hunter":
			return bug_total >= 10
		"collector":
			return collection_count() >= 12
		"festival_star":
			return festival_wins >= 5
		"social_butterfly":
			return close_friend_count(60) >= 5
		"club_master":
			return club_level >= 3
		"business_owner":
			return business_level >= 1
		"business_tycoon":
			return business_sales_total >= 50000
		"home_sweet_home":
			return home_level >= 3
		"party_animal":
			return party_count >= 3
		"married_life":
			return married
		"honeymooner":
			return honeymoon_done
		"parent_proud":
			return children.size() >= 1
		"rich":
			return money + bank >= 100000
		"famous":
			return fame >= 70
		"all_rounder":
			for sk in SKILL_KEYS:
				if skill_of(String(sk)) < 50:
					return false
			return true
	return false


func check_achievements() -> void:
	if not created:
		return
	for a in ACHIEVEMENTS:
		var id := String(a["id"])
		if achievement_unlocked(id):
			continue
		if _achievement_met(id):
			achievements[id] = true
			log_event("🏆 ปลดล็อกความสำเร็จ: %s" % String(a.get("name", id)))


func claim_achievement(id: String) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	var a := achievement_data(id)
	if a.is_empty():
		return {"ok": false, "message": "ไม่พบความสำเร็จนี้"}
	if not achievement_unlocked(id):
		return {"ok": false, "message": "ยังไม่ปลดล็อก %s" % String(a["name"])}
	if achievement_is_claimed(id):
		return {"ok": false, "message": "รับรางวัลไปแล้ว"}
	achievement_claimed[id] = true
	var reward := int(a.get("reward", 0))
	money += reward
	add_fame(2, "รับรางวัลความสำเร็จ")
	_instant(["🏆 รับรางวัล “%s” • ฿+%s" % [String(a["name"]), fmt_money(reward)]])
	return {"ok": true, "message": last_message}


# ============================================================
#  v7 — ชมรม / เรียนพิเศษ
# ============================================================

func club_data(id: String) -> Dictionary:
	for c in CLUBS:
		if String(c.get("id", "")) == id:
			return c
	return {}


func club_name() -> String:
	if club_id == "":
		return "ยังไม่เข้าร่วมชมรม"
	return String(club_data(club_id).get("name", club_id))


func club_need_points(level: int) -> int:
	var idx := clampi(level, 0, CLUB_LEVEL_POINTS.size() - 1)
	return int(CLUB_LEVEL_POINTS[idx])


func club_next_need() -> int:
	if club_level >= 4:
		return -1
	return club_need_points(club_level)


func join_club(id: String) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if age < 8:
		return {"ok": false, "message": "ต้องอายุ 8 ปีขึ้นไปจึงจะเข้าชมรมได้"}
	var c := club_data(id)
	if c.is_empty():
		return {"ok": false, "message": "ไม่พบชมรมนี้"}
	if club_id == id:
		return {"ok": false, "message": "อยู่ชมรม%sแล้ว" % String(c["name"])}
	var fee := int(c["fee"])
	if money < fee:
		return {"ok": false, "message": "เงินไม่พอค่าสมาชิก ฿%s" % fmt_money(fee)}
	money -= fee
	club_id = id
	club_level = 1
	club_points = 0
	add_skill(String(c["skill"]), 2)
	happy = clampi(happy + 5, 0, 100)
	social = clampi(social + 2, 0, 100)
	advance_minutes(45)
	check_achievements()
	_finish(["🎨 เข้าร่วม%sแล้ว! ค่าสมาชิก ฿%s" % [String(c["name"]), fmt_money(fee)]])
	return {"ok": true, "message": last_message}


func club_activity() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if club_id == "":
		return {"ok": false, "message": "ยังไม่ได้เข้าชมรม"}
	if club_day == day:
		return {"ok": false, "message": "วันนี้ทำกิจกรรมชมรมแล้ว"}
	if energy < 10:
		return {"ok": false, "message": "เหนื่อยเกินไปสำหรับกิจกรรมชมรม"}
	var c := club_data(club_id)
	club_day = day
	_quest_bump("club")
	energy = clampi(energy - 10, 0, 100)
	club_points += 2 + randi() % 2
	add_skill(String(c.get("skill", "communication")), 2)
	social = clampi(social + 2, 0, 100)
	happy = clampi(happy + 3, 0, 100)
	stress = clampi(stress - 3, 0, 100)
	var notes: Array[String] = ["🎨 กิจกรรม%s • คะแนนชมรม %d" % [String(c.get("name", club_id)), club_points]]
	var leveled := false
	while club_level < 4 and club_points >= club_need_points(club_level):
		club_level += 1
		leveled = true
	if leveled:
		notes.append("⭐ ชมรมเลเวล %d แล้ว! เพื่อน ๆ ปรบมือให้" % club_level)
		add_fame(2, "ชมรมเลเวล %d" % club_level)
	check_achievements()
	advance_minutes(60)
	_finish(notes)
	return {"ok": true, "message": last_message}


func take_course(skill_id: String = "academics") -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if age < COURSE_MIN_AGE:
		return {"ok": false, "message": "ต้องอายุ %d ปีขึ้นไป" % COURSE_MIN_AGE}
	if course_day == day:
		return {"ok": false, "message": "วันนี้เรียนพิเศษแล้ว"}
	if not SKILL_DEFS.has(skill_id):
		return {"ok": false, "message": "ไม่รู้จักวิชานี้"}
	if money < COURSE_COST:
		return {"ok": false, "message": "เงินไม่พอค่าเรียน ฿%s" % fmt_money(COURSE_COST)}
	money -= COURSE_COST
	course_day = day
	energy = clampi(energy - 12, 0, 100)
	stress = clampi(stress + 3, 0, 100)
	add_skill(skill_id, 4)
	add_skill("academics", 1)
	advance_minutes(120)
	check_achievements()
	_finish(["📚 เรียนพิเศษ%s • ทักษะ +5 • ฿-%s" % [
		skill_name(skill_id), fmt_money(COURSE_COST)
	]])
	return {"ok": true, "message": last_message}


# ============================================================
#  v7 — ธุรกิจ / ร้านของตัวเอง
# ============================================================

const BUSINESS_UPGRADE_COSTS := [0, 8000, 18000, 35000]
const BUSINESS_DAILY_BASE := 10
const BUSINESS_PRICE_BASE := 120


func business_title() -> String:
	match business_level:
		1:
			return "ร้านเล็ก ๆ"
		2:
			return "ร้านน่ารัก"
		3:
			return "ร้านชื่อดัง"
		4:
			return "ร้านระดับเมือง"
	return "ยังไม่มีร้าน"


func business_price() -> int:
	return BUSINESS_PRICE_BASE + business_level * 45


func business_capacity() -> int:
	return BUSINESS_DAILY_BASE + business_level * 5


func open_business(biz_name: String = "") -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if is_child():
		return {"ok": false, "message": "ต้องเป็นผู้ใหญ่ก่อนจึงจะเปิดร้านได้"}
	if business_level > 0:
		return {"ok": false, "message": "มีร้านอยู่แล้ว (%s)" % business_title()}
	if money < BUSINESS_OPEN_COST:
		return {"ok": false, "message": "เงินไม่พอเปิดร้าน (ต้อง ฿%s)" % fmt_money(BUSINESS_OPEN_COST)}
	money -= BUSINESS_OPEN_COST
	business_level = 1
	if biz_name.strip_edges() != "":
		business_name = biz_name.strip_edges()
	business_stock = BUSINESS_STOCK_PER_RESTOCK
	add_skill("communication", 3)
	add_skill("cooking", 1)
	add_fame(8, "เปิดร้านของตัวเอง")
	advance_minutes(120)
	check_achievements()
	_finish(["🏪 เปิด%s “%s” แล้ว! • ฿-%s • สต็อก %d ชิ้น" % [
		business_title(), business_name, fmt_money(BUSINESS_OPEN_COST), business_stock
	]])
	return {"ok": true, "message": last_message}


func restock_business() -> Dictionary:
	if business_level <= 0:
		return {"ok": false, "message": "ยังไม่มีร้าน"}
	if money < BUSINESS_RESTOCK_COST:
		return {"ok": false, "message": "เงินไม่พอเติมสต็อก ฿%s" % fmt_money(BUSINESS_RESTOCK_COST)}
	money -= BUSINESS_RESTOCK_COST
	business_stock += BUSINESS_STOCK_PER_RESTOCK
	advance_minutes(30)
	_finish(["📦 เติมสต็อก +%d ชิ้น • ฿-%s • ตอนนี้มี %d ชิ้น" % [
		BUSINESS_STOCK_PER_RESTOCK, fmt_money(BUSINESS_RESTOCK_COST), business_stock
	]])
	return {"ok": true, "message": last_message}


func run_business_day() -> Dictionary:
	if business_level <= 0:
		return {"ok": false, "message": "ยังไม่มีร้าน"}
	if business_day == day:
		return {"ok": false, "message": "วันนี้เปิดร้านแล้ว"}
	if business_stock <= 0:
		return {"ok": false, "message": "สินค้าหมดแล้ว — เติมสต็อกก่อน"}
	if energy < 15:
		return {"ok": false, "message": "เหนื่อยเกินไปสำหรับเปิดร้าน"}
	business_day = day
	_quest_bump("business")
	var sold := mini(business_stock, business_capacity())
	business_stock -= sold
	var income := sold * business_price()
	money += income
	business_sales_total += income
	energy = clampi(energy - 15, 0, 100)
	hunger = clampi(hunger - 8, 0, 100)
	happy = clampi(happy + 3, 0, 100)
	stress = clampi(stress + 3, 0, 100)
	add_skill("communication", 1)
	add_fame(1, "ขายของที่ร้าน")
	check_achievements()
	advance_minutes(180)
	_finish(["🏪 เปิดร้านขายได้ %d ชิ้น • รายได้ ฿%s • ยอดรวม ฿%s" % [
		sold, fmt_money(income), fmt_money(business_sales_total)
	]])
	return {"ok": true, "message": last_message}


func upgrade_business() -> Dictionary:
	if business_level <= 0:
		return {"ok": false, "message": "ยังไม่มีร้าน"}
	if business_level >= 4:
		return {"ok": false, "message": "ร้านพัฒนาถึงระดับสูงสุดแล้ว"}
	var cost := int(BUSINESS_UPGRADE_COSTS[business_level])
	if money < cost:
		return {"ok": false, "message": "เงินไม่พออัปเกรดร้าน (ต้อง ฿%s)" % fmt_money(cost)}
	money -= cost
	business_level += 1
	add_fame(4, "อัปเกรดร้าน")
	advance_minutes(90)
	check_achievements()
	_finish(["🏪 อัปเกรดเป็น%s • ขายได้วันละ %d ชิ้น • ฿-%s" % [
		business_title(), business_capacity(), fmt_money(cost)
	]])
	return {"ok": true, "message": last_message}


# ============================================================
#  v7 — บ้าน / ปาร์ตี้ / แมว
# ============================================================

func upgrade_home() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if home_level >= HOME_MAX_LEVEL:
		return {"ok": false, "message": "บ้านหลังนี้ดีที่สุดแล้ว"}
	var cost := int(HOME_UPGRADE_COSTS[home_level])
	if money < cost:
		return {"ok": false, "message": "เงินไม่พออัปเกรดบ้าน (ต้อง ฿%s)" % fmt_money(cost)}
	money -= cost
	home_level += 1
	happy = clampi(happy + 10, 0, 100)
	stress = clampi(stress - 6, 0, 100)
	add_fame(2, "อัปเกรดบ้าน")
	advance_minutes(60)
	check_achievements()
	_finish(["🏡 อัปเกรดบ้านเป็นเลเวล %d • ความอบอุ่น +%d • ฿-%s" % [
		home_level, home_cozy(), fmt_money(cost)
	]])
	return {"ok": true, "message": last_message}


func host_party() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if money < PARTY_COST:
		return {"ok": false, "message": "เงินไม่พอจัดปาร์ตี้ (ต้อง ฿%s)" % fmt_money(PARTY_COST)}
	if party_week == week:
		return {"ok": false, "message": "สัปดาห์นี้จัดปาร์ตี้แล้ว"}
	party_week = week
	party_count += 1
	money -= PARTY_COST
	var guests := 0
	for npc_id in npc_friendship.keys():
		if guests >= 4:
			break
		if int(npc_friendship[npc_id]) < 15:
			continue
		npc_friendship[npc_id] = clampi(int(npc_friendship[npc_id]) + 4, 0, 100)
		guests += 1
	happy = clampi(happy + 12 + guests * 2, 0, 100)
	stress = clampi(stress - 8, 0, 100)
	social = clampi(social + 4, 0, 100)
	add_skill("communication", 1)
	add_fame(4 + guests, "จัดปาร์ตี้ที่บ้าน")
	advance_minutes(180)
	check_achievements()
	_finish(["🎉 จัดปาร์ตี้ที่บ้าน! เพื่อนมา %d คน • ความสุข +%d • ฿-%s" % [
		guests, 12 + guests * 2, fmt_money(PARTY_COST)
	]])
	return {"ok": true, "message": last_message}


func cat_feed() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if pet_name == "":
		return {"ok": false, "message": "ยังไม่มีแมว"}
	if cat_feed_day == day:
		return {"ok": false, "message": "วันนี้ให้อาหาร%sแล้ว" % pet_name}
	if money < CAT_FEED_COST:
		return {"ok": false, "message": "เงินไม่พอซื้ออาหารแมว ฿%s" % fmt_money(CAT_FEED_COST)}
	money -= CAT_FEED_COST
	cat_feed_day = day
	pet_happy = clampi(pet_happy + 10, 0, 100)
	happy = clampi(happy + 2, 0, 100)
	advance_minutes(15)
	_finish(["🐟 ให้อาหาร%s • ความสุขแมว +10 • ฿-%s" % [pet_name, fmt_money(CAT_FEED_COST)]])
	return {"ok": true, "message": last_message}


func buy_cat_toy() -> Dictionary:
	if pet_name == "":
		return {"ok": false, "message": "ต้องมีแมวอยู่ที่บ้านก่อน"}
	if cat_toy_owned:
		return {"ok": false, "message": "มีของเล่นแมวอยู่แล้ว"}
	if money < CAT_TOY_COST:
		return {"ok": false, "message": "เงินไม่พอซื้อของเล่น ฿%s" % fmt_money(CAT_TOY_COST)}
	money -= CAT_TOY_COST
	cat_toy_owned = true
	pet_happy = clampi(pet_happy + 8, 0, 100)
	_instant(["🧶 ซื้อของเล่นแมวใหม่ • %s ตื่นเต้นมาก • ฿-%s" % [
		pet_name, fmt_money(CAT_TOY_COST)
	]])
	return {"ok": true, "message": last_message}


func cat_play_toy() -> Dictionary:
	if pet_name == "":
		return {"ok": false, "message": "ยังไม่มีแมว"}
	if not cat_toy_owned:
		return {"ok": false, "message": "ยังไม่มีของเล่นแมว"}
	if cat_toy_day == day:
		return {"ok": false, "message": "วันนี้เล่นของเล่นกับ%sแล้ว" % pet_name}
	cat_toy_day = day
	pet_happy = clampi(pet_happy + 8, 0, 100)
	happy = clampi(happy + 3, 0, 100)
	stress = clampi(stress - 3, 0, 100)
	advance_minutes(30)
	_finish(["🧶 เล่นของเล่นกับ%s • ความสุขแมว +8 • เครียด -3" % pet_name])
	return {"ok": true, "message": last_message}


# ============================================================
#  v7 — ครอบครัว / ฮันนีมูน / ทริปครอบครัว
# ============================================================

func honeymoon() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if not married:
		return {"ok": false, "message": "ต้องแต่งงานก่อนจึงจะไปฮันนีมูนได้"}
	if honeymoon_done:
		return {"ok": false, "message": "ไปฮันนีมูนกันแล้ว"}
	if money < HONEYMOON_COST:
		return {"ok": false, "message": "เงินไม่พอไปฮันนีมูน (ต้อง ฿%s)" % fmt_money(HONEYMOON_COST)}
	money -= HONEYMOON_COST
	honeymoon_done = true
	partner_love = clampi(partner_love + 20, 0, 100)
	happy = clampi(happy + 18, 0, 100)
	stress = clampi(stress - 20, 0, 100)
	energy = clampi(energy + 10, 0, 100)
	add_fame(4, "ไปฮันนีมูน")
	check_achievements()
	advance_minutes(300)
	_finish(["🌴 ฮันนีมูนกับ%sที่ริมทะเล • ความรัก +20 • ความสุข +18 • ฿-%s" % [
		partner_name, fmt_money(HONEYMOON_COST)
	]])
	return {"ok": true, "message": last_message}


func family_outing() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if partner_name == "" and children.is_empty():
		return {"ok": false, "message": "ยังไม่มีครอบครัวให้พาออกไปเที่ยว"}
	if family_outing_week == week:
		return {"ok": false, "message": "สัปดาห์นี้พาครอบครัวออกไปเที่ยวแล้ว"}
	if money < FAMILY_OUTING_COST:
		return {"ok": false, "message": "เงินไม่พอสำหรับทริปครอบครัว ฿%s" % fmt_money(FAMILY_OUTING_COST)}
	money -= FAMILY_OUTING_COST
	family_outing_week = week
	happy = clampi(happy + 10, 0, 100)
	stress = clampi(stress - 8, 0, 100)
	parent_love = clampi(parent_love + 2, 0, 100)
	var notes: Array[String] = ["🧺 ทริปครอบครัวที่สวนสาธารณะ • ความสุข +10 • ฿-%s" % fmt_money(FAMILY_OUTING_COST)]
	if partner_name != "":
		partner_love = clampi(partner_love + 6, 0, 100)
		notes.append("💞 %s ยิ้มทั้งวัน" % partner_name)
	if not children.is_empty():
		notes.append("👧 ลูก ๆ วิ่งเล่นจนเหนื่อย")
	check_achievements()
	advance_minutes(240)
	_finish(notes)
	return {"ok": true, "message": last_message}


# ============================================================
#  v7 — บูธเทศกาล / สังสรรค์กลุ่มเพื่อน
# ============================================================

func can_play_booth() -> bool:
	return alive and booth_plays < 3


func play_festival_booth(success: bool, quality: int = 0) -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว", "prize": 0}
	if booth_plays >= 3:
		return {"ok": false, "message": "วันนี้เล่นบูธครบ 3 ครั้งแล้ว", "prize": 0}
	if money < 50:
		return {"ok": false, "message": "เงินไม่พอค่าเล่นบูธ (ต้อง ฿50)", "prize": 0}
	if booth_day != day:
		booth_day = day
		booth_plays = 0
	money -= 50
	booth_plays += 1
	if not success:
		advance_minutes(15)
		_finish(["🎪 เล่นเกมบูธพลาดไปนิดเดียว • ฿-50"])
		return {"ok": true, "prize": 0, "message": last_message}
	var prize := 150 + clampi(quality, 0, 2) * 100
	money += prize
	happy = clampi(happy + 4, 0, 100)
	add_fame(1, "เล่นบูธเทศกาลชนะ")
	advance_minutes(15)
	_finish(["🎪 เล่นบูธชนะ! รับรางวัล ฿%s" % fmt_money(prize)])
	return {"ok": true, "prize": prize, "message": last_message}


func close_friend_count(threshold: int = 60) -> int:
	var n := 0
	for npc_id in npc_friendship.keys():
		if int(npc_friendship[npc_id]) >= threshold:
			n += 1
	return n


func hangout_group() -> Dictionary:
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	if group_day == day:
		return {"ok": false, "message": "วันนี้ออกไปสังสรรค์กับเพื่อนแล้ว"}
	var pals: Array[String] = []
	for npc_id in npc_friendship.keys():
		if int(npc_friendship[npc_id]) >= 20:
			pals.append(String(npc_id))
	if pals.size() < 2:
		return {"ok": false, "message": "ต้องมีเพื่อนใจ 20+ อย่างน้อย 2 คนก่อน"}
	if money < 300:
		return {"ok": false, "message": "เงินไม่พอออกไปสังสรรค์ (ต้อง ฿300)"}
	money -= 300
	group_day = day
	var joined := mini(pals.size(), 3)
	for i in joined:
		npc_friendship[pals[i]] = clampi(int(npc_friendship[pals[i]]) + 5, 0, 100)
	happy = clampi(happy + 8, 0, 100)
	stress = clampi(stress - 5, 0, 100)
	social = clampi(social + 3, 0, 100)
	add_skill("communication", 1)
	add_fame(1, "ออกไปสังสรรค์กับเพื่อน")
	advance_minutes(150)
	check_achievements()
	_finish(["👥 ออกไปกินข้าวกับเพื่อน %d คน • ใจเพื่อน +5 • ฿-300" % joined])
	return {"ok": true, "message": last_message}


# ============================================================
#  v8 — เควสต์รายสัปดาห์ / ใบประกาศ / เป้าหมายชีวิต
# ============================================================

func quest_week_index() -> int:
	return int((day - 1) / 7)


func quest_data(id: String) -> Dictionary:
	for q in QUEST_POOL:
		if String(q.get("id", "")) == id:
			return q
	return {}


func _roll_weekly_quests() -> void:
	quests = []
	var pool: Array = QUEST_POOL.duplicate(true)
	pool.shuffle()
	var used_stats := {}
	for q in pool:
		if quests.size() >= QUEST_WEEK_COUNT:
			break
		var stat := String(q.get("stat", ""))
		if used_stats.has(stat):
			continue
		used_stats[stat] = true
		quests.append({"id": String(q.get("id", "")), "claimed": false})


## เรียกทุกครั้งที่ขึ้นสัปดาห์ใหม่ — สุ่มภารกิจ 3 อย่างและล้างตัวนับรายสัปดาห์
func _ensure_quest_week() -> void:
	var idx := quest_week_index()
	if quest_week == idx and not quests.is_empty():
		return
	quest_week = idx
	quest_counts = {}
	_roll_weekly_quests()


func _quest_bump(stat: String, amount: int = 1) -> void:
	if not created:
		return
	quest_counts[stat] = int(quest_counts.get(stat, 0)) + amount


func quest_stat(index: int) -> String:
	if index < 0 or index >= quests.size():
		return ""
	var qid := String(quests[index].get("id", ""))
	return String(quest_data(qid).get("stat", ""))


func quest_target(index: int) -> int:
	if index < 0 or index >= quests.size():
		return 1
	var qid := String(quests[index].get("id", ""))
	return maxi(int(quest_data(qid).get("target", 1)), 1)


func quest_reward(index: int) -> int:
	if index < 0 or index >= quests.size():
		return 0
	var qid := String(quests[index].get("id", ""))
	return int(quest_data(qid).get("reward", 0))


func quest_claimed(index: int) -> bool:
	if index < 0 or index >= quests.size():
		return false
	return bool(quests[index].get("claimed", false))


func quest_progress(index: int) -> int:
	_ensure_quest_week()
	if index < 0 or index >= quests.size():
		return 0
	return mini(int(quest_counts.get(quest_stat(index), 0)), quest_target(index))


func quest_complete(index: int) -> bool:
	return quest_progress(index) >= quest_target(index)


func quest_info(index: int) -> Dictionary:
	_ensure_quest_week()
	if index < 0 or index >= quests.size():
		return {}
	var qid := String(quests[index].get("id", ""))
	var q := quest_data(qid)
	if q.is_empty():
		return {}
	var target := maxi(int(q.get("target", 1)), 1)
	var progress := mini(int(quest_counts.get(String(q.get("stat", "")), 0)), target)
	return {
		"index": index, "id": qid, "name": String(q.get("name", qid)),
		"desc": String(q.get("desc", "")), "stat": String(q.get("stat", "")),
		"target": target, "progress": progress, "reward": int(q.get("reward", 0)),
		"claimed": quest_claimed(index), "complete": progress >= target,
	}


func claim_quest(index: int) -> Dictionary:
	_ensure_quest_week()
	if not alive:
		return {"ok": false, "message": "เกมจบแล้ว"}
	var info := quest_info(index)
	if info.is_empty():
		return {"ok": false, "message": "ไม่พบภารกิจนี้"}
	if bool(info.get("claimed", false)):
		return {"ok": false, "message": "รับรางวัลภารกิจนี้แล้ว"}
	if int(info.get("progress", 0)) < int(info.get("target", 1)):
		return {"ok": false, "message": "ยังทำภารกิจไม่ครบ (%d/%d)" % [
			int(info.get("progress", 0)), int(info.get("target", 1))
		]}
	quests[index]["claimed"] = true
	quest_total_done += 1
	var reward := int(info.get("reward", 0))
	money += reward
	add_fame(3, "ทำภารกิจรายสัปดาห์สำเร็จ")
	var notes: Array[String] = ["📜 รับรางวัล “%s” • ฿+%s" % [
		String(info.get("name", "")), fmt_money(reward)
	]]
	var certs := _check_quest_certificates()
	for c in certs:
		notes.append("🎖 ได้%s! • ฿+%s" % [
			String(c.get("name", "")), fmt_money(int(c.get("reward", 0)))
		])
	log_event("ทำภารกิจ “%s” สำเร็จ" % String(info.get("name", "")))
	_instant(notes)
	return {"ok": true, "message": last_message, "certificates": certs, "reward": reward}


func _check_quest_certificates() -> Array:
	var earned: Array = []
	for c in QUEST_CERTIFICATES:
		var cid := String(c.get("id", ""))
		if has_quest_certificate(cid):
			continue
		if quest_total_done < int(c.get("need", 0)):
			continue
		quest_certificates.append(cid)
		money += int(c.get("reward", 0))
		add_fame(5, "ได้ใบประกาศภารกิจ")
		earned.append(c)
	return earned


func has_quest_certificate(id: String) -> bool:
	return quest_certificates.has(id)


func quest_certificate_count() -> int:
	return quest_certificates.size()


func next_quest_certificate() -> Dictionary:
	for c in QUEST_CERTIFICATES:
		if not has_quest_certificate(String(c.get("id", ""))):
			return c
	return {}


func life_goal_data() -> Dictionary:
	for g in LIFE_GOALS:
		if String(g.get("id", "")) == life_goal:
			return g
	return LIFE_GOALS[0]


func life_goal_exists(id: String) -> bool:
	for g in LIFE_GOALS:
		if String(g.get("id", "")) == id:
			return true
	return false


func life_goal_name() -> String:
	return String(life_goal_data().get("name", "ครอบครัวอบอุ่น"))


func life_goal_desc() -> String:
	return String(life_goal_data().get("desc", ""))


func life_goal_icon() -> String:
	return String(life_goal_data().get("icon", "🏡"))


func life_goal_color() -> Color:
	return Color(String(life_goal_data().get("color", "#e08a9a")))


## คะแนนเป้าหมายชีวิต 0-100 คิดจากสถานะจริงในเกม
func goal_progress() -> int:
	var score := 0.0
	if life_goal == "family":
		score += float(parent_love) * 0.15
		score += float(partner_love) * 0.15
		if married:
			score += 10.0
		score += minf(float(children.size()), 2.0) * 7.5
		score += float(happy) * 0.15
		score += float(home_level) * 5.0
		if pet_name != "":
			score += 5.0
		score += float(social) * 0.05
	elif life_goal == "career":
		score += minf(float(edu), 100.0) * 0.15
		if job_id != "":
			score += float(mini(job_level, 3)) * 5.0
			score += float(performance) * 0.10
		score += maxf(0.0, minf(float(money + bank), 100000.0)) / 100000.0 * 20.0
		score += float(business_level) * 5.0
		score += float(skill_average()) * 0.15
		if graduated:
			score += 5.0
	else:
		score += minf(float(fame), 100.0) * 0.25
		score += float(unlocked_achievement_count()) / float(ACHIEVEMENTS.size()) * 20.0
		score += float(collection_count()) / float(COLLECTIBLES.size()) * 10.0
		score += minf(float(festival_wins), 5.0) * 2.0
		score += minf(float(quest_total_done), 20.0)
		score += minf(float(fish_total + bug_total), 20.0) * 0.5
		score += float(social) * 0.05
	return clampi(int(round(score)), 0, 100)


func goal_tier() -> int:
	var p := goal_progress()
	if p >= 85:
		return 4
	if p >= 65:
		return 3
	if p >= 40:
		return 2
	if p >= 20:
		return 1
	return 0


func goal_tier_name() -> String:
	return String(GOAL_TIER_NAMES[clampi(goal_tier(), 0, GOAL_TIER_NAMES.size() - 1)])


func goal_hint() -> String:
	if life_goal == "family":
		return "พ่อแม่ %d • คู่ชีวิต %d • ลูก %d คน • บ้านเลเวล %d • ความสุข %d" % [
			parent_love, partner_love, children.size(), home_level, happy
		]
	if life_goal == "career":
		return "การศึกษา %d • งานระดับ %d • ประสิทธิภาพ %d%% • ทรัพย์สิน ฿%s • ธุรกิจเลเวล %d" % [
			edu, job_level if job_id != "" else 0, performance if job_id != "" else 0,
			fmt_money(money + bank), business_level
		]
	return "ชื่อเสียง %d • ความสำเร็จ %d/%d • ของสะสม %d/%d • ภารกิจ %d • เทศกาล %d" % [
		fame, unlocked_achievement_count(), ACHIEVEMENTS.size(),
		collection_count(), COLLECTIBLES.size(), quest_total_done, festival_wins
	]


## ฉากจบชีวิตหลายแบบตามเป้าหมายและคะแนนสะสม
func life_ending() -> Dictionary:
	var tier := goal_tier()
	var pool: Array = LIFE_ENDINGS.get(life_goal, LIFE_ENDINGS["family"])
	var idx := 0
	if tier >= 4:
		idx = 2
	elif tier >= 2:
		idx = 1
	var e: Dictionary = pool[mini(idx, pool.size() - 1)]
	var rank := "C"
	if tier >= 4:
		rank = "S"
	elif tier == 3:
		rank = "A"
	elif tier == 2:
		rank = "B"
	return {
		"id": String(e.get("id", "")), "title": String(e.get("title", "")),
		"desc": String(e.get("desc", "")), "rank": rank, "tier": tier,
		"tier_name": goal_tier_name(), "goal": life_goal_name(),
		"progress": goal_progress(),
	}


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"created": created, "player_name": player_name,
		"gender": gender, "family_wealth": family_wealth,
		"age": age, "month": month, "week": week,
		"money": money, "bank": bank, "loan": loan, "insurance": insurance,
		"health": health, "happy": happy,
		"energy": energy, "hunger": hunger, "stress": stress,
		"edu": edu, "social": social, "alive": alive,
		"sick": sick, "illness": illness, "sick_weeks": sick_weeks,
		"death_cause": death_cause, "last_message": last_message,
		"job_id": job_id, "job_level": job_level, "job_weeks": job_weeks,
		"performance": performance, "retired": retired, "last_salary": last_salary,
		"partner_name": partner_name, "partner_love": partner_love,
		"married": married, "children": children,
		"partner_npc_id": partner_npc_id, "partner_look": partner_look,
		"partner_genes": partner_genes, "player_genes": player_genes,
		"parent_love": parent_love, "friend_name": friend_name,
		"friend_love": friend_love, "inherited": inherited,
		"rent_extra": rent_extra,
		"outfit": outfit, "owned_outfits": owned_outfits,
		"skin_tone": skin_tone, "hair_color": hair_color, "hair_style": hair_style,
		"tax_paid": tax_paid, "life_log": life_log,
		# ---------- v4 ----------
		"time_min": time_min, "day": day, "weekday": weekday,
		"season": season, "season_day": season_day, "days_played": days_played,
		"weather": weather, "alarm_min": alarm_min,
		"zone_id": zone_id, "player_pos": [player_pos.x, player_pos.y],
		"grades": grades, "school_absences": school_absences,
		"school_attended_today": school_attended_today,
		"school_days": school_days, "graduated": graduated,
		"worked_today": worked_today, "work_absences": work_absences,
		"job_shifts": job_shifts, "fitness": fitness,
		"npc_friendship": npc_friendship, "npc_talked": npc_talked,
		"npc_gifted": npc_gifted, "parent_talked": parent_talked,
		"allowance_week": allowance_week, "dinner_day": dinner_day,
		"adult_gift": adult_gift, "last_sleep_hours": last_sleep_hours,
		# ---------- v5 ----------
		"skills": skills, "birth_outfit": birth_outfit,
		"parent_trait": parent_trait, "karma_id": karma_id,
		"home_items": home_items, "pet_name": pet_name, "pet_happy": pet_happy,
		"pet_day": pet_day, "collections": collections, "collect_day": collect_day,
		"collection_milestone": collection_milestone,
		"festival_attended": festival_attended, "festival_wins": festival_wins,
		"train_day": train_day, "bench_day": bench_day,
		# ---------- v7 ----------
		"farm_plots": farm_plots, "harvest_total": harvest_total,
		"fish_catches": fish_catches, "bug_catches": bug_catches,
		"fish_total": fish_total, "bug_total": bug_total,
		"fish_actions": fish_actions, "bug_actions": bug_actions,
		"fame": fame, "rumor_today": rumor_today,
		"club_id": club_id, "club_level": club_level, "club_points": club_points,
		"club_day": club_day, "course_day": course_day,
		"business_level": business_level, "business_name": business_name,
		"business_stock": business_stock, "business_day": business_day,
		"business_sales_total": business_sales_total,
		"achievements": achievements, "achievement_claimed": achievement_claimed,
		"home_level": home_level, "party_week": party_week, "party_count": party_count,
		"cat_feed_day": cat_feed_day, "cat_toy_owned": cat_toy_owned, "cat_toy_day": cat_toy_day,
		"group_day": group_day, "honeymoon_done": honeymoon_done,
		"family_outing_week": family_outing_week,
		"booth_day": booth_day, "booth_plays": booth_plays,
		# ---------- v8 ----------
		"life_goal": life_goal, "quest_week": quest_week,
		"quests": quests, "quest_counts": quest_counts,
		"quest_total_done": quest_total_done,
		"quest_certificates": quest_certificates,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var save_ver := int(parsed.get("version", 0))
	if save_ver < 5 or save_ver > SAVE_VERSION:
		return

	created = bool(parsed.get("created", false))
	player_name = String(parsed.get("player_name", player_name))
	gender = String(parsed.get("gender", "ชาย"))
	family_wealth = int(parsed.get("family_wealth", 1))
	age = int(parsed.get("age", age))
	month = int(parsed.get("month", month))
	week = int(parsed.get("week", week))
	money = int(parsed.get("money", money))
	bank = int(parsed.get("bank", 0))
	loan = int(parsed.get("loan", 0))
	insurance = bool(parsed.get("insurance", false))
	health = int(parsed.get("health", health))
	happy = int(parsed.get("happy", happy))
	energy = int(parsed.get("energy", energy))
	hunger = int(parsed.get("hunger", hunger))
	stress = int(parsed.get("stress", stress))
	edu = int(parsed.get("edu", edu))
	social = int(parsed.get("social", social))
	alive = bool(parsed.get("alive", alive))
	sick = bool(parsed.get("sick", false))
	illness = String(parsed.get("illness", ""))
	sick_weeks = int(parsed.get("sick_weeks", 0))
	death_cause = String(parsed.get("death_cause", ""))
	last_message = String(parsed.get("last_message", ""))
	job_id = String(parsed.get("job_id", ""))
	job_level = int(parsed.get("job_level", 1))
	job_weeks = int(parsed.get("job_weeks", 0))
	performance = int(parsed.get("performance", 50))
	retired = bool(parsed.get("retired", false))
	last_salary = int(parsed.get("last_salary", 0))
	partner_name = String(parsed.get("partner_name", ""))
	partner_love = int(parsed.get("partner_love", 0))
	married = bool(parsed.get("married", false))
	partner_npc_id = String(parsed.get("partner_npc_id", ""))
	partner_look = _dict_from(parsed.get("partner_look", {}))
	partner_genes = _dict_from(parsed.get("partner_genes", {}))
	parent_love = int(parsed.get("parent_love", 70))
	friend_name = String(parsed.get("friend_name", ""))
	friend_love = int(parsed.get("friend_love", 0))
	inherited = bool(parsed.get("inherited", false))
	rent_extra = int(parsed.get("rent_extra", 0))
	outfit = String(parsed.get("outfit", "casual"))
	skin_tone = String(parsed.get("skin_tone", ""))
	hair_color = String(parsed.get("hair_color", ""))
	hair_style = String(parsed.get("hair_style", ""))
	player_genes = _normalize_genes(_dict_from(parsed.get("player_genes", {})), player_appearance())
	if partner_name != "":
		if partner_look.is_empty():
			partner_look = _partner_profile_for_name()
		else:
			partner_look = _normalize_person_look(partner_look)
		partner_genes = _normalize_genes(partner_genes, partner_look)
	else:
		partner_npc_id = ""
		partner_look = {}
		partner_genes = {}
	tax_paid = int(parsed.get("tax_paid", 0))

	children = []
	var raw_children = parsed.get("children", [])
	if typeof(raw_children) == TYPE_ARRAY:
		for c in raw_children:
			if typeof(c) == TYPE_DICTIONARY:
				var child_look: Dictionary
				if typeof(c.get("appearance", {})) == TYPE_DICTIONARY and not c.get("appearance", {}).is_empty():
					child_look = _normalize_appearance(c.get("appearance", {}), player_appearance())
				else:
					child_look = player_appearance()
				var child_genes := _normalize_genes(_dict_from(c.get("genes", {})), child_look)
				children.append({
					"name": String(c.get("name", "?")),
					"age": int(c.get("age", 0)),
					"appearance": child_look,
					"genes": child_genes,
					"traits_from": _dict_from(c.get("traits_from", {})),
					"other_parent": String(c.get("other_parent", "")),
				})

	owned_outfits = []
	var raw_outfits = parsed.get("owned_outfits", [])
	if typeof(raw_outfits) == TYPE_ARRAY:
		for o in raw_outfits:
			owned_outfits.append(String(o))
	if owned_outfits.is_empty():
		owned_outfits = ["casual", "sleep"]
	if not owned_outfits.has(outfit):
		outfit = "casual"

	life_log = []
	var raw_log = parsed.get("life_log", [])
	if typeof(raw_log) == TYPE_ARRAY:
		for line in raw_log:
			life_log.append(String(line))

	# ---------- v4 ----------
	time_min = int(parsed.get("time_min", DAY_START_MIN))
	day = int(parsed.get("day", 1))
	weekday = clampi(int(parsed.get("weekday", 1)), 1, 7)
	season = clampi(int(parsed.get("season", 0)), 0, 3)
	season_day = clampi(int(parsed.get("season_day", 1)), 1, DAYS_PER_SEASON)
	days_played = int(parsed.get("days_played", 0))
	weather = String(parsed.get("weather", "sun"))
	alarm_min = clampi(int(parsed.get("alarm_min", DEFAULT_ALARM)), 5 * 60, 9 * 60)
	zone_id = String(parsed.get("zone_id", "home"))
	var raw_pos = parsed.get("player_pos", [480, 420])
	if typeof(raw_pos) == TYPE_ARRAY and raw_pos.size() >= 2:
		player_pos = Vector2(float(raw_pos[0]), float(raw_pos[1]))
	grades = clampi(int(parsed.get("grades", 50)), 0, 100)
	school_absences = int(parsed.get("school_absences", 0))
	school_attended_today = bool(parsed.get("school_attended_today", false))
	school_days = int(parsed.get("school_days", 0))
	graduated = bool(parsed.get("graduated", false))
	worked_today = bool(parsed.get("worked_today", false))
	work_absences = int(parsed.get("work_absences", 0))
	job_shifts = int(parsed.get("job_shifts", 0))
	fitness = clampi(int(parsed.get("fitness", 30)), 0, 100)
	npc_friendship = _dict_from(parsed.get("npc_friendship", {}))
	npc_talked = _dict_from(parsed.get("npc_talked", {}))
	npc_gifted = _dict_from(parsed.get("npc_gifted", {}))
	parent_talked = _dict_from(parsed.get("parent_talked", {}))
	allowance_week = int(parsed.get("allowance_week", -1))
	dinner_day = int(parsed.get("dinner_day", -1))
	adult_gift = bool(parsed.get("adult_gift", false))
	last_sleep_hours = float(parsed.get("last_sleep_hours", 0.0))
	# ---------- v5 ----------
	skills = {}
	for sk in SKILL_KEYS:
		skills[sk] = 5
	var raw_skills = parsed.get("skills", {})
	if typeof(raw_skills) == TYPE_DICTIONARY:
		for k in raw_skills.keys():
			if skills.has(String(k)):
				skills[String(k)] = clampi(int(raw_skills[k]), 0, 100)
	birth_outfit = String(parsed.get("birth_outfit", "heirloom_blue"))
	parent_trait = String(parsed.get("parent_trait", "kind"))
	karma_id = String(parsed.get("karma_id", "warm"))
	home_items = []
	var raw_home = parsed.get("home_items", [])
	if typeof(raw_home) == TYPE_ARRAY:
		for item in raw_home:
			home_items.append(String(item))
	pet_name = String(parsed.get("pet_name", ""))
	pet_happy = int(parsed.get("pet_happy", 0))
	pet_day = int(parsed.get("pet_day", -1))
	collections = _dict_from(parsed.get("collections", {}))
	collect_day = int(parsed.get("collect_day", -1))
	collection_milestone = int(parsed.get("collection_milestone", 0))
	festival_attended = _dict_from(parsed.get("festival_attended", {}))
	festival_wins = int(parsed.get("festival_wins", 0))
	train_day = int(parsed.get("train_day", -1))
	bench_day = int(parsed.get("bench_day", -1))
	# ---------- v7 ----------
	farm_plots = []
	var raw_plots = parsed.get("farm_plots", [])
	if typeof(raw_plots) == TYPE_ARRAY and raw_plots.size() == FARM_PLOT_COUNT:
		for item in raw_plots:
			if typeof(item) == TYPE_DICTIONARY:
				farm_plots.append({
					"crop": String(item.get("crop", "")),
					"growth": int(item.get("growth", 0)),
					"watered": bool(item.get("watered", false)),
				})
			else:
				farm_plots.append({"crop": "", "growth": 0, "watered": false})
	if farm_plots.size() != FARM_PLOT_COUNT:
		farm_plots = []
		for i in FARM_PLOT_COUNT:
			farm_plots.append({"crop": "", "growth": 0, "watered": false})
	harvest_total = int(parsed.get("harvest_total", 0))
	fish_catches = _dict_from(parsed.get("fish_catches", {}))
	bug_catches = _dict_from(parsed.get("bug_catches", {}))
	fish_total = int(parsed.get("fish_total", 0))
	bug_total = int(parsed.get("bug_total", 0))
	fish_actions = int(parsed.get("fish_actions", 0))
	bug_actions = int(parsed.get("bug_actions", 0))
	fame = int(parsed.get("fame", 0))
	rumor_today = String(parsed.get("rumor_today", ""))
	club_id = String(parsed.get("club_id", ""))
	club_level = int(parsed.get("club_level", 1))
	club_points = int(parsed.get("club_points", 0))
	club_day = int(parsed.get("club_day", -1))
	course_day = int(parsed.get("course_day", -1))
	business_level = int(parsed.get("business_level", 0))
	business_name = String(parsed.get("business_name", "ร้านเล็ก ๆ ของฉัน"))
	business_stock = int(parsed.get("business_stock", 0))
	business_day = int(parsed.get("business_day", -1))
	business_sales_total = int(parsed.get("business_sales_total", 0))
	achievements = _dict_from(parsed.get("achievements", {}))
	achievement_claimed = _dict_from(parsed.get("achievement_claimed", {}))
	home_level = int(parsed.get("home_level", 1))
	party_week = int(parsed.get("party_week", -1))
	party_count = int(parsed.get("party_count", 0))
	cat_feed_day = int(parsed.get("cat_feed_day", -1))
	cat_toy_owned = bool(parsed.get("cat_toy_owned", false))
	cat_toy_day = int(parsed.get("cat_toy_day", -1))
	group_day = int(parsed.get("group_day", -1))
	honeymoon_done = bool(parsed.get("honeymoon_done", false))
	family_outing_week = int(parsed.get("family_outing_week", -1))
	booth_day = int(parsed.get("booth_day", -1))
	booth_plays = int(parsed.get("booth_plays", 0))
	# ---------- v8 ----------
	life_goal = String(parsed.get("life_goal", "family"))
	if not life_goal_exists(life_goal):
		life_goal = "family"
	quest_week = int(parsed.get("quest_week", -1))
	quests = []
	var raw_quests = parsed.get("quests", [])
	if typeof(raw_quests) == TYPE_ARRAY:
		for item in raw_quests:
			if typeof(item) == TYPE_DICTIONARY:
				var qid := String(item.get("id", ""))
				if not quest_data(qid).is_empty():
					quests.append({"id": qid, "claimed": bool(item.get("claimed", false))})
	quest_counts = _dict_from(parsed.get("quest_counts", {}))
	quest_total_done = int(parsed.get("quest_total_done", 0))
	quest_certificates = []
	var raw_certs = parsed.get("quest_certificates", [])
	if typeof(raw_certs) == TYPE_ARRAY:
		for item in raw_certs:
			var cid := String(item)
			if not cid.is_empty() and not quest_certificates.has(cid):
				quest_certificates.append(cid)
	if created:
		_ensure_quest_week()
	time_paused = false
	sleeping = false
	_time_accum = 0.0
	_minute_count = 0


func _dict_from(raw) -> Dictionary:
	var out := {}
	if typeof(raw) == TYPE_DICTIONARY:
		for k in raw.keys():
			out[String(k)] = raw[k]
	return out
