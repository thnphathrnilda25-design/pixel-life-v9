/* Pixel Life — data.js
 * ข้อมูลคงที่ทั้งหมดของเกม (ค่าสมดุล อาชีพ พืช NPC โซน ฯลฯ)
 * ทำงานได้ทั้งเบราว์เซอร์และ Node (สำหรับเทสต์)
 */
(function (root) {
  'use strict';

  const SKILL_DEFS = {
    communication: { name: 'การสื่อสาร', color: '#e0a05a', desc: 'คุยเก่ง เจรจา และสร้างมิตรภาพ' },
    academics:     { name: 'วิชาการ',   color: '#7aa8e0', desc: 'อ่านเขียน คำนวณ และเรียนรู้ไว' },
    craft:         { name: 'งานฝีมือ',  color: '#c08a5a', desc: 'ซ่อมของ ประดิษฐ์ และทำงานช่าง' },
    cooking:       { name: 'ทำอาหาร',   color: '#e08a6a', desc: 'ทำกับข้าวและเบเกอรีอร่อย ๆ' },
    art:           { name: 'ศิลปะ',     color: '#c07ad0', desc: 'วาดรูป ดนตรี และจินตนาการ' },
    athletics:     { name: 'กีฬา',      color: '#6ac08a', desc: 'พละกำลัง ความอดทน และสุขภาพ' },
    tech:          { name: 'เทคโนโลยี', color: '#6ab8d8', desc: 'คอมพิวเตอร์ เครื่องจักร และโค้ด' },
  };
  const SKILL_KEYS = Object.keys(SKILL_DEFS);

  const PARENT_TRAITS = [
    { id: 'kind',     name: 'ใจดีอบอุ่น',      karma: 'warm',     desc: 'พ่อแม่ใจดี เพื่อน ๆ รักใคร่ เริ่มต้นด้วยความรักครอบครัวสูง', parent_love: 12, happy: 5, skills: { communication: 6 } },
    { id: 'strict',   name: 'เข้มงวดขยัน',     karma: 'diligent', desc: 'วินัยดี เรียนเก่ง ทำงานขยัน แต่เครียดง่ายกว่าเดิม', academics: 8, stress: 6, skills: { academics: 4 } },
    { id: 'artist',   name: 'ศิลปินอิสระ',      karma: 'dreamer',  desc: 'บ้านเต็มไปด้วยสีและเสียงเพลง จินตนาการแรงกล้า', happy: 6, skills: { art: 8 } },
    { id: 'merchant', name: 'ครอบครัวพ่อค้า',   karma: 'lucky',    desc: 'มีเงินติดตัวและเจรจาเก่ง โชคดีเรื่องเงินทอง', money: 2000, skills: { communication: 5 } },
    { id: 'farmer',   name: 'ครอบครัวชาวสวน',  karma: 'grounded', desc: 'สุขภาพแข็งแรง ใจเย็น ใกล้ชิดธรรมชาติ', health: 5, skills: { athletics: 7 } },
  ];

  const KARMA_DEFS = {
    warm:     { name: 'กรรมพันแห่งความอบอุ่น', color: '#e08a9a', desc: 'คุยกับ NPC ได้ใจเพิ่ม และพ่อแม่รักมาก' },
    diligent: { name: 'กรรมพันแห่งความขยัน',   color: '#e0b05a', desc: 'ทำงานได้ประสิทธิภาพเพิ่ม และเกรดดีขึ้นเล็กน้อย' },
    dreamer:  { name: 'กรรมพันแห่งความฝัน',    color: '#c07ad0', desc: 'ฝึกศิลปะได้เร็วกว่า และความสุขเพิ่มง่าย' },
    lucky:    { name: 'กรรมพันแห่งโชคลาภ',     color: '#8ac86a', desc: 'สมัครงานและเก็บของสะสมได้โชคดีกว่า' },
    grounded: { name: 'กรรมพันแห่งแผ่นดิน',    color: '#8ab87a', desc: 'ออกกำลังกายได้ผลดี และฟื้นตัวจากการนอนไว' },
  };

  const BIRTH_OUTFITS = [
    { id: 'heirloom_blue',  name: 'ผ้าห่อตัวฟ้า',   desc: 'ผ้าฝ้ายฟ้าอ่อน ปักดาวเล็ก ๆ' },
    { id: 'heirloom_rose',  name: 'ผ้าห่อตัวชมพู',  desc: 'ผ้าไหมชมพูอ่อน เย็บขอบด้วยมือ' },
    { id: 'heirloom_green', name: 'ผ้าห่อตัวเขียว', desc: 'ผ้าทอเขียวใบไม้ กลิ่นหญ้าอ่อน ๆ' },
  ];

  const FURNITURE = [
    { id: 'cozy_lamp',   name: 'โคมไฟอบอุ่น',   price: 900,  cozy: 6,  type: 'lamp',     desc: 'แสงนวลอุ่นในห้องนอน' },
    { id: 'bookshelf',   name: 'ชั้นหนังสือไม้', price: 1500, cozy: 8,  type: 'bookshelf',desc: 'มุมอ่านหนังสือเงียบ ๆ' },
    { id: 'plant',       name: 'มุมต้นไม้',      price: 600,  cozy: 5,  type: 'plant',    desc: 'ต้นไม้เล็ก ๆ ริมหน้าต่าง' },
    { id: 'fish_tank',   name: 'ตู้ปลา',         price: 2500, cozy: 10, type: 'fishtank', happy: 2, desc: 'ปลาหางนกยูงว่ายวนช้า ๆ' },
    { id: 'easel',       name: 'ขาตั้งวาดรูป',   price: 1800, cozy: 7,  type: 'easel',    skill: 'art', desc: 'ฝึกศิลปะที่บ้านได้' },
    { id: 'kitchen',     name: 'ครัวไม้',        price: 3200, cozy: 12, type: 'kitchen',  skill: 'cooking', desc: 'ทำอาหารเองได้อร่อยขึ้น' },
    { id: 'cat_bed',     name: 'ที่นอนแมว',      price: 1200, cozy: 6,  type: 'catbed',   pet: true, desc: 'รับแมวน้อยมาเป็นเพื่อน' },
    { id: 'wall_clock',  name: 'นาฬิกาไม้',      price: 700,  cozy: 4,  type: 'clock',    desc: 'เสียงติ๊กต็อกอบอุ่น' },
    { id: 'picture',     name: 'ภาพครอบครัว',    price: 1000, cozy: 5,  type: 'picture',  parent_love: 2, desc: 'ความทรงจำวันดี ๆ' },
    { id: 'rug',         name: 'พรมขนนุ่ม',      price: 1400, cozy: 6,  type: 'rug',      desc: 'เดินเท้าเปล่าแล้วสบาย' },
    { id: 'sofa',        name: 'โซฟานุ่ม',        price: 2600, cozy: 9,  type: 'sofa',     desc: 'นั่งพักได้ทั้งครอบครัว' },
    { id: 'bed_double',  name: 'เตียงคู่',        price: 4200, cozy: 11, type: 'bed',      desc: 'นอนหลับสบายขึ้น' },
    { id: 'dining',      name: 'โต๊ะอาหาร',       price: 2200, cozy: 8,  type: 'table',    desc: 'มุมกินข้าวพร้อมหน้า' },
    { id: 'tv_set',      name: 'ทีวีจอใหญ่',      price: 3000, cozy: 9,  type: 'tv',       desc: 'ดูหนังหลังเลิกงาน' },
    { id: 'desk_set',    name: 'โต๊ะทำงานไม้',    price: 1900, cozy: 7,  type: 'desk',     desc: 'ทำงาน/อ่านหนังสือที่บ้าน' },
    { id: 'aquarium_wall', name: 'ภาพวิวทะเล',     price: 1200, cozy: 5,  type: 'picture',  desc: 'ภาพพิมพ์วิวทะเลสีฟ้า' },
    { id: 'pet_bed',     name: 'ที่นอนสัตว์เลี้ยง', price: 1600, cozy: 7,  type: 'petbed',   happy: 2, desc: 'หมอนนุ่มสีพาสเทลสำหรับเพื่อนขนฟู' },
    { id: 'magic_altar', name: 'แท่นบูชาเวท',     price: 4800, cozy: 9,  type: 'altar',    mana: 20, desc: 'เพิ่มพลังเวทสูงสุด +20 และฟื้นเร็วขึ้น' },
    { id: 'crystal_lamp',name: 'โคมคริสตัล',      price: 3600, cozy: 10, type: 'crystal_lamp', happy: 3, desc: 'แสงคริสตัลเปลี่ยนสีตอนกลางคืน' },
    { id: 'wardrobe',    name: 'ตู้เสื้อผ้าใหญ่',  price: 2800, cozy: 8,  type: 'wardrobe', desc: 'เก็บชุดได้ทุกคอลเลกชัน' },
    { id: 'vanity',      name: 'โต๊ะเครื่องแป้ง',  price: 3400, cozy: 8,  type: 'vanity',   charm: 2, desc: 'แต่งหน้าทำผมก่อนออกงาน' },
    { id: 'guild_banner',name: 'ธงกิลด์นักเวท',   price: 2600, cozy: 6,  type: 'banner',   fame: 4, desc: 'ประกาศว่าบ้านนี้เป็นของนักเวท' },
    { id: 'pet_house',   name: 'บ้านสัตว์เลี้ยง',  price: 5200, cozy: 11, type: 'pet_house',happy: 4, desc: 'บ้านหลังเล็กพร้อมที่นอนและชามอาหาร' },
  ];
  const CAT_NAMES = ['ส้ม', 'มะนาว', 'ถั่ว', 'ขนุน', 'ปุย', 'เจ้าเหมียว'];

  const COLLECTIBLES = {
    sakura:    { name: 'กลีบซากุระ',        season: 0, zone: 'park' },
    clover:    { name: 'ใบโคลเวอร์',        season: 0, zone: 'downtown' },
    butterfly: { name: 'ผีเสื้อฤดูใบไม้ผลิ', season: 0, zone: 'home_street' },
    shell:     { name: 'เปลือกหอย',         season: 1, zone: 'park' },
    dragonfly: { name: 'แมลงปอ',            season: 1, zone: 'home_street' },
    sunstone:  { name: 'หินสีทอง',          season: 1, zone: 'school_district' },
    maple:     { name: 'ใบเมเปิล',          season: 2, zone: 'park' },
    acorn:     { name: 'ลูกโอ๊ก',           season: 2, zone: 'home_street' },
    mushroom:  { name: 'เห็ดสีส้ม',         season: 2, zone: 'downtown' },
    snowflake: { name: 'เกล็ดหิมะ',         season: 3, zone: 'park' },
    icicle:    { name: 'น้ำแข็งใส',         season: 3, zone: 'school_district' },
    postcard:  { name: 'โปสการ์ดฤดูหนาว',   season: 3, zone: 'downtown' },
  };
  const COLLECTION_MILESTONES = [4, 8, 12];

  const FESTIVALS = [
    { id: 'blossom',       name: 'เทศกาลดอกไม้บาน',   season: 0, day: 5, zone: 'park',     kind: 'sequence', reward: 1800, desc: 'โคมกระดาษริมสระน้ำ ดนตรีเบา ๆ และดอกไม้ทั้งสวน' },
    { id: 'summer_market', name: 'ตลาดน้ำหน้าร้อน',    season: 1, day: 6, zone: 'downtown', kind: 'catch',    reward: 2200, desc: 'แผงอาหาร เครื่องดื่มเย็น และเกมจับของรางวัล' },
    { id: 'harvest',       name: 'เทศกาลเก็บเกี่ยว',   season: 2, day: 5, zone: 'park',     kind: 'timing',   reward: 2000, desc: 'ผลไม้เต็มโต๊ะ การแข่งขันเก็บเกี่ยว และไฟรอบกองฟาง' },
    { id: 'winter_lights', name: 'เทศกาลโคมไฟเหมันต์', season: 3, day: 6, zone: 'downtown', kind: 'math',     reward: 2600, desc: 'โคมไฟหลากสี ของขวัญ และเสียงเพลงกลางหิมะ' },
  ];

  const CROPS = [
    { id: 'lettuce',    name: 'ผักกาดหอม',    seed: 50,  days: 3, sell: 150, skill: 'cooking', color: '#8ac86a' },
    { id: 'tomato',     name: 'มะเขือเทศ',     seed: 80,  days: 4, sell: 240, skill: 'cooking', color: '#e0624a' },
    { id: 'corn',       name: 'ข้าวโพด',      seed: 110, days: 5, sell: 360, skill: 'cooking', color: '#f2c84a' },
    { id: 'pumpkin',    name: 'ฟักทอง',       seed: 160, days: 6, sell: 560, skill: 'cooking', color: '#e8903a' },
    { id: 'strawberry', name: 'สตรอว์เบอร์รี', seed: 200, days: 4, sell: 500, skill: 'cooking', color: '#e05a7a' },
  ];
  const FARM_PLOT_COUNT = 6;

  const FISH_TABLE = {
    carp:   { name: 'ปลาไน',        value: 90,   rarity: 0 },
    silver: { name: 'ปลาตะเพียนเงิน', value: 130,  rarity: 0 },
    catfish:{ name: 'ปลาดุก',       value: 230,  rarity: 1 },
    koi:    { name: 'ปลาคาร์ฟ',      value: 480,  rarity: 2 },
    gold:   { name: 'ปลาเงินปลาทอง', value: 650,  rarity: 2 },
    moon:   { name: 'ปลาพระจันทร์',  value: 1400, rarity: 3 },
  };
  const BUG_TABLE = {
    butterfly:      { name: 'ผีเสื้อลายจุด', value: 80,  rarity: 0 },
    grasshopper:    { name: 'ตั๊กแตนเขียว',  value: 110, rarity: 0 },
    firefly:        { name: 'หิ่งห้อย',      value: 240, rarity: 1 },
    beetle:         { name: 'ด้วงกว่าง',     value: 380, rarity: 2 },
    gold_dragonfly: { name: 'แมลงปอทอง',    value: 800, rarity: 3 },
  };

  const CLUBS = [
    { id: 'art',     name: 'ชมรมศิลปะ',     skill: 'art',       fee: 300, color: '#c07ad0', desc: 'วาดภาพ ปั้นดิน และจัดนิทรรศการเล็ก ๆ ของชมรม' },
    { id: 'music',   name: 'ชมรมดนตรี',     skill: 'art',       fee: 400, color: '#8a7ad0', desc: 'ร้องเพลง เล่นกีตาร์ และขึ้นแสดงในงานโรงเรียน' },
    { id: 'sport',   name: 'ชมรมกีฬา',      skill: 'athletics', fee: 250, color: '#6ac08a', desc: 'ซ้อมวิ่ง บาสเกตบอล และแข่งกระชับมิตร' },
    { id: 'cooking', name: 'ชมรมทำอาหาร',   skill: 'cooking',   fee: 350, color: '#e08a6a', desc: 'ทดลองสูตรขนมและอาหารท้องถิ่น' },
    { id: 'tech',    name: 'ชมรมเทคโนโลยี', skill: 'tech',      fee: 450, color: '#6ab8d8', desc: 'หุ่นยนต์เล็ก ๆ เกม และการเขียนโค้ด' },
    { id: 'garden',  name: 'ชมรมทำสวน',     skill: 'craft',     fee: 200, color: '#8ab87a', desc: 'ดูแลสวนโรงเรียน ปลูกผักและดอกไม้' },
  ];
  const CLUB_LEVEL_POINTS = [0, 9, 22, 40];

  const ACHIEVEMENTS = [
    { id: 'first_harvest',    name: 'มือใหม่หัดปลูก',      desc: 'เก็บเกี่ยวพืชผลครั้งแรก', reward: 500 },
    { id: 'green_thumb',      name: 'มือเกษตรตัวจริง',     desc: 'เก็บเกี่ยวพืชผลครบ 10 ครั้ง', reward: 1500 },
    { id: 'first_fish',       name: 'ตกปลาตัวแรก',         desc: 'ตกปลาได้อย่างน้อย 1 ตัว', reward: 500 },
    { id: 'master_angler',    name: 'นักตกปลาแห่งเมือง',   desc: 'ตกปลาครบ 10 ตัว', reward: 1800 },
    { id: 'bug_hunter',       name: 'นักล่าแมลง',          desc: 'จับแมลงครบ 10 ตัว', reward: 1200 },
    { id: 'collector',        name: 'นักสะสมตัวยง',        desc: 'สะสมของครบ 12 ชนิด', reward: 3000 },
    { id: 'festival_star',    name: 'ดาวเด่นเทศกาล',       desc: 'ชนะรางวัลเทศกาลครบ 5 ครั้ง', reward: 2500 },
    { id: 'social_butterfly', name: 'ผีเสื้อสังคม',        desc: 'มีเพื่อนสนิท (ใจ 60+) 5 คน', reward: 1500 },
    { id: 'club_master',      name: 'หัวหน้าชมรม',         desc: 'ชมรมเลเวล 3', reward: 2000 },
    { id: 'business_owner',   name: 'เจ้าของร้าน',         desc: 'เปิดร้านของตัวเอง', reward: 1000 },
    { id: 'business_tycoon',  name: 'นักธุรกิจรุ่นใหม่',    desc: 'ยอดขายร้านรวม ฿50,000', reward: 4000 },
    { id: 'home_sweet_home',  name: 'บ้านในฝัน',           desc: 'อัปเกรดบ้านถึงเลเวล 3', reward: 2000 },
    { id: 'party_animal',     name: 'เจ้าของปาร์ตี้',       desc: 'จัดปาร์ตี้ที่บ้านครบ 3 ครั้ง', reward: 1500 },
    { id: 'married_life',     name: 'คู่ชีวิต',            desc: 'แต่งงานกับคนที่รัก', reward: 1000 },
    { id: 'honeymooner',      name: 'ฮันนีมูนหวาน',        desc: 'ไปฮันนีมูนหลังแต่งงาน', reward: 1500 },
    { id: 'parent_proud',     name: 'คุณพ่อคุณแม่',        desc: 'มีลูกคนแรก', reward: 2000 },
    { id: 'rich',             name: 'เศรษฐีน้อย',          desc: 'มีทรัพย์สินเงินสด+ธนาคาร ฿100,000', reward: 3000 },
    { id: 'famous',           name: 'คนดังแห่งเมือง',      desc: 'ชื่อเสียงถึง 70', reward: 2500 },
    { id: 'all_rounder',      name: 'รอบรู้ทุกด้าน',        desc: 'ทุกทักษะถึง 50', reward: 3000 },
  ];

  const QUEST_WEEK_COUNT = 3;
  const QUEST_POOL = [
    { id: 'harvest3',  name: 'เก็บผักให้ครัว',       stat: 'harvest', target: 3, reward: 420, desc: 'เก็บเกี่ยวพืชผลจากแปลงหลังบ้าน 3 ครั้ง' },
    { id: 'harvest6',  name: 'สวนขาจร',              stat: 'harvest', target: 6, reward: 780, desc: 'เก็บเกี่ยวพืชผลให้ได้ 6 ครั้งในสัปดาห์นี้' },
    { id: 'fish2',     name: 'มื้อปลาเย็นนี้',        stat: 'fish',    target: 2, reward: 400, desc: 'ตกปลาให้ได้ 2 ตัว' },
    { id: 'fish4',     name: 'นักตกปลาหน้าฝน',       stat: 'fish',    target: 4, reward: 760, desc: 'ตกปลาให้ได้ 4 ตัว' },
    { id: 'bug3',      name: 'ตามล่าผีเสื้อ',         stat: 'bug',     target: 3, reward: 380, desc: 'จับแมลงให้ได้ 3 ตัว' },
    { id: 'school2',   name: 'ห้องเรียนขยัน',         stat: 'school',  target: 2, reward: 360, desc: 'ไปโรงเรียน 2 วัน' },
    { id: 'school4',   name: 'สัปดาห์แห่งความรู้',     stat: 'school',  target: 4, reward: 700, desc: 'ไปโรงเรียน 4 วัน' },
    { id: 'work2',     name: 'กะพิเศษ',               stat: 'work',    target: 2, reward: 520, desc: 'ทำงาน 2 กะ' },
    { id: 'work4',     name: 'คนขยันประจำสัปดาห์',     stat: 'work',    target: 4, reward: 980, desc: 'ทำงาน 4 กะ' },
    { id: 'talk4',     name: 'เพื่อนบ้านทักทาย',       stat: 'talk',    target: 4, reward: 300, desc: 'คุยกับผู้คนในเมือง 4 ครั้ง' },
    { id: 'talk7',     name: 'ผีเสื้อสังคม',          stat: 'talk',    target: 7, reward: 620, desc: 'คุยกับผู้คนในเมือง 7 ครั้ง' },
    { id: 'business1', name: 'เปิดร้านสักวัน',        stat: 'business',target: 1, reward: 600, desc: 'เปิดร้านขายของ 1 วัน' },
    { id: 'club2',     name: 'กิจกรรมชมรม',           stat: 'club',    target: 2, reward: 420, desc: 'ทำกิจกรรมชมรม 2 ครั้ง' },
    { id: 'collect2',  name: 'ของสะสมตามฤดู',         stat: 'collect', target: 2, reward: 360, desc: 'เก็บของสะสมตามฤดู 2 ชิ้น' },
  ];
  const QUEST_CERTIFICATES = [
    { id: 'bronze', name: 'ใบประกาศทองแดง', need: 5,  reward: 800 },
    { id: 'silver', name: 'ใบประกาศเงิน',   need: 12, reward: 2000 },
    { id: 'gold',   name: 'ใบประกาศทอง',    need: 24, reward: 5000 },
  ];

  const LIFE_GOALS = [
    { id: 'family', name: 'ครอบครัวอบอุ่น', icon: '🏡', color: '#e08a9a', desc: 'สร้างบ้านที่เต็มไปด้วยเสียงหัวเราะ ดูแลคนที่รัก และโตไปพร้อมกัน' },
    { id: 'career', name: 'อาชีพมั่นคง',    icon: '💼', color: '#7aa8e0', desc: 'สร้างเนื้อสร้างตัว เก่งงาน เก็บเงิน และมีธุรกิจเป็นของตัวเอง' },
    { id: 'legend', name: 'ตำนานเมือง',     icon: '🌟', color: '#e0b05a', desc: 'เป็นที่รู้จักทั้งเมือง สะสมความสำเร็จ และสร้างเรื่องเล่าให้คนจดจำ' },
  ];
  const GOAL_TIER_NAMES = ['เริ่มต้นเส้นทาง', 'เส้นทางเริ่มชัด', 'ก้าวหน้าอย่างมั่นคง', 'ใกล้ถึงความฝัน', 'สมบูรณ์แบบ'];
  const LIFE_ENDINGS = {
    family: [
      { id: 'family_quiet',  title: 'บ้านเล็ก ๆ ที่ยังอบอุ่น', desc: 'ชีวิตไม่ได้สมบูรณ์แบบทุกอย่าง แต่ทุกมื้อข้าวยังมีคนรออยู่' },
      { id: 'family_warm',   title: 'ครอบครัวที่เต็มไปด้วยเสียงหัวเราะ', desc: 'ความรักในบ้านค่อย ๆ เติบโตเป็นความทรงจำที่อบอุ่น' },
      { id: 'family_legend', title: 'บ้านหลังใหญ่แห่งความรัก', desc: 'ทุกคนในบ้านเติบโตมาพร้อมความรัก และเรื่องเล่านี้จะถูกส่งต่อ' },
    ],
    career: [
      { id: 'career_quiet',  title: 'คนทำงานที่ยังเดินต่อไป', desc: 'เส้นทางยังอีกไกล แต่ทุกก้าวที่เดินมาล้วนมีความหมาย' },
      { id: 'career_solid',  title: 'ชีวิตที่สร้างด้วยมือตัวเอง', desc: 'ความมั่นคงที่ได้มาไม่ใช่โชค แต่คือความพยายามทุกวัน' },
      { id: 'career_legend', title: 'เจ้าของตำนานนักสร้าง', desc: 'จากมือเปล่าสู่สิ่งที่สร้างขึ้นด้วยตัวเอง — เป็นแรงบันดาลใจให้คนรุ่นหลัง' },
    ],
    legend: [
      { id: 'legend_quiet',  title: 'ชื่อเล็ก ๆ ในความทรงจำ', desc: 'ยังมีคนจำเรื่องราวของคุณได้ในมุมหนึ่งของเมือง' },
      { id: 'legend_known',  title: 'คนที่เมืองจดจำ', desc: 'เรื่องเล่าเล็ก ๆ ของคุณถูกพูดถึงในร้านกาแฟและใต้ต้นไม้ใหญ่' },
      { id: 'legend_eternal',title: 'ตำนานที่ไม่มีวันจาง', desc: 'ชื่อของคุณกลายเป็นส่วนหนึ่งของเมือง และจะถูกเล่าต่อไปอีกนาน' },
    ],
  };

  const JOBS = [
    { id: 'store',      title: 'พนักงานร้านสะดวกซื้อ', salary: 1500, edu: 0,  skill: 'communication', skill_req: 0 },
    { id: 'waiter',     title: 'พนักงานเสิร์ฟ',       salary: 1600, edu: 5,  skill: 'communication', skill_req: 5 },
    { id: 'seller',     title: 'พนักงานขาย',          salary: 1900, edu: 10, skill: 'communication', skill_req: 8 },
    { id: 'chef',       title: 'พ่อครัว',              salary: 2400, edu: 10, skill: 'cooking',       skill_req: 20 },
    { id: 'tech_job',   title: 'ช่างเทคนิค',           salary: 2300, edu: 20, skill: 'craft',         skill_req: 12 },
    { id: 'designer',   title: 'นักออกแบบ',            salary: 3000, edu: 25, skill: 'art',           skill_req: 25 },
    { id: 'account',    title: 'พนักงานบัญชี',         salary: 2900, edu: 30, skill: 'academics',     skill_req: 15 },
    { id: 'nurse',      title: 'พยาบาล',               salary: 3400, edu: 35, skill: 'academics',     skill_req: 20 },
    { id: 'programmer', title: 'โปรแกรมเมอร์',         salary: 3600, edu: 30, skill: 'tech',          skill_req: 30 },
    { id: 'engineer',   title: 'วิศวกร',               salary: 3800, edu: 40, skill: 'craft',         skill_req: 22 },
    { id: 'vet',        title: 'สัตวแพทย์',            salary: 4200, edu: 45, skill: 'academics',     skill_req: 35 },
    { id: 'manager',    title: 'ผู้จัดการ',             salary: 5500, edu: 55, skill: 'communication', skill_req: 30 },
    { id: 'doctor',     title: 'หมอ',                  salary: 7000, edu: 70, skill: 'academics',     skill_req: 40 },
    { id: 'professor',  title: 'อาจารย์มหาวิทยาลัย',    salary: 7500, edu: 85, skill: 'academics',     skill_req: 55 },
  ];
  const JOB_WORKPLACES = {
    store: 'store', waiter: 'cafe', seller: 'mall', chef: 'cafe', tech_job: 'office',
    designer: 'mall', account: 'office', nurse: 'hospital', programmer: 'office',
    engineer: 'office', vet: 'hospital', manager: 'office', doctor: 'hospital', professor: 'university',
  };

  const OUTFITS = [
    { id: 'casual',        name: 'ชุดลำลอง',          price: 0,     charm: 0,  formal: 0,  desc: 'สบาย ๆ ใส่ได้ทุกวัน' },
    { id: 'school',        name: 'ชุดนักเรียน',        price: 800,   charm: 2,  formal: 2,  desc: 'ดูเรียบร้อย เหมาะกับเรียน' },
    { id: 'sleep',         name: 'ชุดนอน',            price: 0,     charm: -2, formal: -2, desc: 'สบายสุด ๆ แต่ไม่เหมาะออกงาน' },
    { id: 'sport',         name: 'ชุดออกกำลัง',        price: 1200,  charm: 3,  formal: 0,  desc: 'คล่องตัว ใส่ไปฟิตเนส' },
    { id: 'cozy',          name: 'ชุดไหมพรมอบอุ่น',    price: 1800,  charm: 4,  formal: 1,  desc: 'ถักหนานุ่ม สีครีมน้ำผึ้ง' },
    { id: 'raincoat',      name: 'เสื้อกันฝน',         price: 2200,  charm: 3,  formal: 1,  desc: 'กันฝนได้ แถมดูน่ารัก' },
    { id: 'work',          name: 'ชุดทำงาน',           price: 2500,  charm: 6,  formal: 6,  desc: 'ดูมืออาชีพ สมัครงานผ่านง่ายขึ้น' },
    { id: 'winter',        name: 'ชุดกันหนาว',         price: 3200,  charm: 5,  formal: 3,  desc: 'อบอุ่นทั้งตัวสำหรับฤดูหิมะ' },
    { id: 'thai',          name: 'ชุดไทยประยุกต์',     price: 4500,  charm: 9,  formal: 7,  desc: 'ผ้าไหมสีทอง งามสง่าในงานเทศกาล' },
    { id: 'party',         name: 'ชุดออกงาน',          price: 6000,  charm: 10, formal: 3,  desc: 'เด่นในงานสังสรรค์' },
    { id: 'luxury',        name: 'ชุดแบรนด์เนม',       price: 20000, charm: 18, formal: 8,  desc: 'หรูหรา มีเสน่ห์มาก' },
    { id: 'idol',          name: 'ชุดไอดอล',           price: 9000,  charm: 14, formal: 4,  desc: 'ประกายแวววาวสำหรับขึ้นเวที' },
    { id: 'goth',          name: 'ชุดโกธิค',           price: 3800,  charm: 7,  formal: 2,  desc: 'ดำลึก ลึกลับ มีสไตล์' },
    { id: 'punk',          name: 'ชุดพังก์',           price: 3200,  charm: 6,  formal: 0,  desc: 'ซิ่ง ๆ ดิบ ๆ ใส่แล้วดูเถื่อน' },
    { id: 'mage',          name: 'ชุดจอมเวท',          price: 7500,  charm: 12, formal: 4,  desc: 'คลุมยาวปักดาว เรืองแสงจาง ๆ' },
    { id: 'knight',        name: 'ชุดอัศวิน',          price: 12000, charm: 10, formal: 6,  desc: 'เกราะเบา ๆ ดูองอาจ' },
    { id: 'kimono',        name: 'ชุดกิโมโน',          price: 8000,  charm: 14, formal: 8,  desc: 'ผ้าไหมลายดอก งดงาม' },
    { id: 'crystal',       name: 'ชุดคริสตัล',          price: 25000, charm: 22, formal: 10, desc: 'ชุดในตำนาน ประกายเหมือนเพชร' },
    { id: 'heirloom_blue', name: 'ผ้าห่อตัวฟ้า',       price: 0,     charm: 1,  formal: 0,  desc: 'ชุดแรกเกิดจากพ่อแม่ — เก็บไว้เป็นความทรงจำ' },
    { id: 'heirloom_rose', name: 'ผ้าห่อตัวชมพู',      price: 0,     charm: 1,  formal: 0,  desc: 'ชุดแรกเกิดจากพ่อแม่ — เก็บไว้เป็นความทรงจำ' },
    { id: 'heirloom_green',name: 'ผ้าห่อตัวเขียว',     price: 0,     charm: 1,  formal: 0,  desc: 'ชุดแรกเกิดจากพ่อแม่ — เก็บไว้เป็นความทรงจำ' },
  ];
  const OUTFIT_COLORS = {
    casual: ['#7aa8e0', '#3a4a6b'], school: ['#f4f4f4', '#2e3a5e'], sleep: ['#b8a8d8', '#4a3a5e'],
    sport: ['#e05a5a', '#2e3a4e'], cozy: ['#e8c88a', '#7a5a3a'], raincoat: ['#f2d05a', '#4a5a6b'],
    work: ['#4a5a6b', '#2a2a34'], winter: ['#8a6ab0', '#3a3a4e'], thai: ['#e0b05a', '#8a5a2a'],
    party: ['#c85a7a', '#4a2a3a'], luxury: ['#2a2a34', '#c8a84a'],
    idol: ['#ffd24a', '#e85a9a'], goth: ['#3a2a44', '#241a2a'], punk: ['#e04a3a', '#2a2a34'],
    mage: ['#5a4ac8', '#2a2a4e'], knight: ['#b8c8d8', '#6a7a8a'], kimono: ['#d86a8a', '#f2e0c0'],
    crystal: ['#6ae0e8', '#2a4a6a'],
    heirloom_blue: ['#a8c8e8', '#e8f0f8'], heirloom_rose: ['#e8a8b8', '#f8e8ee'], heirloom_green: ['#a8c8a0', '#e8f0e0'],
  };

  const SKIN_TONES = [
    { id: 'light', name: 'ผิวขาวนวล', hex: '#f6d5b6' },
    { id: 'warm',  name: 'ผิวอุ่น',     hex: '#f2c39b' },
    { id: 'tan',   name: 'ผิวสองสี',    hex: '#dca578' },
    { id: 'deep',  name: 'ผิวน้ำผึ้ง',   hex: '#b87a52' },
    { id: 'dark',  name: 'ผิวเข้ม',     hex: '#8a5a3a' },
    { id: 'porcelain', name: 'ผิวขาวจัด', hex: '#ffe6cf' },
    { id: 'olive', name: 'ผิวโอลีฟ',    hex: '#d2ab72' },
    { id: 'mint',  name: 'ผิวเขียวมิ้นต์', hex: '#a8d8b8' },
    { id: 'sky',   name: 'ผิวฟ้าคราม',   hex: '#a8c8e8' },
    { id: 'lilac', name: 'ผิวม่วงลาเวนเดอร์', hex: '#c8b0d8' },
    { id: 'ash',   name: 'ผิวเทาหมอก',  hex: '#b8b0a8' },
  ];
  const HAIR_COLORS = [
    { id: 'black',    name: 'ดำธรรมชาติ', hex: '#3a2a1a' },
    { id: 'brown',    name: 'น้ำตาลเข้ม',  hex: '#4a3020' },
    { id: 'chestnut', name: 'เกาลัด',      hex: '#6a3a24' },
    { id: 'honey',    name: 'น้ำผึ้ง',      hex: '#a06a3a' },
    { id: 'blonde',   name: 'บลอนด์',      hex: '#d8b06a' },
    { id: 'auburn',   name: 'แดงทอง',      hex: '#8a3a2a' },
    { id: 'silver',   name: 'เงิน',        hex: '#a8a8a8' },
    { id: 'rose',     name: 'ชมพูอ่อน',    hex: '#d88a9a' },
    { id: 'white',    name: 'ขาวหิมะ',     hex: '#e8e8e8' },
    { id: 'teal',     name: 'เขียวมรกต',    hex: '#3a9a9a' },
    { id: 'violet',   name: 'ม่วงไวโอเล็ต', hex: '#7a3aa8' },
    { id: 'blue',     name: 'น้ำเงินสด',    hex: '#3a5ac8' },
    { id: 'pink',     name: 'ชมพูจัด',     hex: '#e87aa8' },
    { id: 'mint',     name: 'เขียวมิ้นต์',  hex: '#7ad8b8' },
    { id: 'orange',   name: 'ส้ม fiery',   hex: '#e07a2a' },
    { id: 'crimson',  name: 'แดงชาด',      hex: '#a81e3a' },
  ];
  const HAIR_STYLES = [
    { id: 'short',    name: 'ผมสั้น' },
    { id: 'bob',      name: 'ผมบ๊อบ' },
    { id: 'long',     name: 'ผมยาว' },
    { id: 'ponytail', name: 'หางม้า' },
    { id: 'bun',      name: 'มวยผม' },
    { id: 'curly',    name: 'ผมหยิก' },
    { id: 'messy',    name: 'ผมยุ่ง' },
    { id: 'bald',     name: 'หัวโล้น' },
    { id: 'braids',   name: 'ผมเปียคู่' },
    { id: 'twintails',name: 'ผมทวินเทล' },
    { id: 'wavy',     name: 'ผมลอนคลื่น' },
    { id: 'afro',     name: 'ผมหยิกฟู' },
    { id: 'pixie',    name: 'ผมพิกซี่' },
    { id: 'mohawk',   name: 'ผมโมฮอว์ก' },
    { id: 'side',     name: 'ผมปัดข้าง' },
  ];
  const ACCESSORIES = [
    { id: 'none',      name: 'ไม่ใส่' },
    { id: 'glasses',   name: 'แว่นตา' },
    { id: 'cap',       name: 'หมวกแก๊ป' },
    { id: 'beanie',    name: 'หมวกไหมพรม' },
    { id: 'headphones',name: 'หูฟัง' },
    { id: 'scarf',     name: 'ผ้าพันคอ' },
    { id: 'catEars',   name: 'หูแมว' },
    { id: 'wolfEars',  name: 'หูหมาป่า' },
    { id: 'horns',     name: 'เขาปีศาจ' },
    { id: 'halo',      name: 'วงแหวนเทวทูต' },
    { id: 'witchHat',  name: 'หมวกแม่มด' },
    { id: 'crown',     name: 'มงกุฎ' },
    { id: 'eyepatch',  name: 'ผ้าปิดตา' },
    { id: 'mask',      name: 'หน้ากาก' },
    { id: 'wings',     name: 'ปีกน้อย' },
  ];

  const PLAN_SLOTS = [
    { id: 'morning',   name: 'เช้า', start: 6 * 60,  end: 12 * 60, emoji: '🌅' },
    { id: 'afternoon', name: 'บ่าย', start: 12 * 60, end: 18 * 60, emoji: '☀️' },
    { id: 'evening',   name: 'เย็น', start: 18 * 60, end: 24 * 60, emoji: '🌙' },
  ];
  const PLAN_OPTIONS = {
    work:     { label: 'ทำงาน',        hint: 'ได้เงิน • ประสิทธิภาพ', tags: ['work'] },
    school:   { label: 'ไปโรงเรียน',    hint: 'เกรด • ความรู้',      tags: ['school'] },
    study:    { label: 'เรียน/อ่านหนังสือ', hint: 'ทักษะ • เกรด',    tags: ['study'] },
    farm:     { label: 'ดูแลสวน',      hint: 'ปลูก • รดน้ำ • เก็บเกี่ยว', tags: ['farm'] },
    social:   { label: 'พบผู้คน',       hint: 'ความสัมพันธ์ • ความสุข', tags: ['social'] },
    exercise: { label: 'ออกกำลังกาย',   hint: 'สุขภาพ • ลดเครียด',   tags: ['exercise'] },
    rest:     { label: 'พักผ่อน',       hint: 'ฟื้นพลังงาน',          tags: ['rest'] },
  };
  const PLAN_ADULT_OPTIONS = ['work', 'study', 'farm', 'social', 'exercise', 'rest'];
  const PLAN_CHILD_OPTIONS = ['school', 'study', 'social', 'rest'];

  const SEASONS = ['spring', 'summer', 'autumn', 'winter'];
  const SEASON_NAMES = ['ฤดูใบไม้ผลิ', 'ฤดูร้อน', 'ฤดูใบไม้ร่วง', 'ฤดูหนาว'];
  const WEEKDAY_NAMES = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
  const WEATHER_NAMES = { sun: 'แดดออก', rain: 'ฝนตก', snow: 'หิมะตก', cloud: 'เมฆมาก' };
  const MONTHS = ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];

  const RUMORS = [
    'ได้ยินว่ามีคนเห็นปลาตัวใหญ่ในสระสวนสาธารณะ',
    'ป้าแต๋วเล่าว่าร้านขนมจะลดราคาสัปดาห์หน้า',
    'ใครบางคนกำลังตามหาคนช่วยทำสวน',
  ];
  const RUMORS_FAME = [
    'ชื่อของคุณเริ่มถูกพูดถึงในร้านกาแฟ',
    'เด็ก ๆ ในเมืองรู้จักคุณแล้ว',
    'มีคนอยากขอถ่ายรูปด้วยที่สวนสาธารณะ',
  ];

  const NAMES_M = ['กัน', 'ภูมิ', 'ที', 'อาร์น', 'แบงค์', 'สอน', 'ข้าว'];
  const NAMES_F = ['แนน', 'มิ้นท์', 'ฟ้า', 'พลอย', 'เจน', 'หวาน', 'นานา'];

  /* ---------------- โซน / แผนที่ ---------------- */
  // prop: {type, x, y, action, label, ...}
  const ZONES = {
    home: {
      name: 'บ้านของเรา', indoor: true, theme: 'home',
      bg: '#b07c4f', wall: '#d8b98f', spawn: { x: 470, y: 430 },
      props: [
        { type: 'window', x: 250, y: 195 },
        { type: 'picture', x: 520, y: 190 },
        { type: 'plant', x: 70, y: 430 },
      ],
      doors: [
        { x: 895, y: 470, zone: 'home_street', spawn: { x: 205, y: 360 }, label: 'ออกไปถนนบ้านเรา' },
        { x: 55, y: 470, zone: 'backyard', spawn: { x: 480, y: 470 }, label: 'ไปสวนหลังบ้าน' },
      ],
      exits: [], npcs: ['dad', 'mom'],
    },
    backyard: {
      name: 'สวนหลังบ้าน', outdoor: true, theme: 'backyard',
      bg: '#8ab86a', spawn: { x: 480, y: 470 },
      props: [
        { type: 'farm_plot', x: 150, y: 330, index: 0, action: 'farm_plot', label: 'แปลงผัก 1' },
        { type: 'farm_plot', x: 235, y: 330, index: 1, action: 'farm_plot', label: 'แปลงผัก 2' },
        { type: 'farm_plot', x: 320, y: 330, index: 2, action: 'farm_plot', label: 'แปลงผัก 3' },
        { type: 'farm_plot', x: 150, y: 405, index: 3, action: 'farm_plot', label: 'แปลงผัก 4' },
        { type: 'farm_plot', x: 235, y: 405, index: 4, action: 'farm_plot', label: 'แปลงผัก 5' },
        { type: 'farm_plot', x: 320, y: 405, index: 5, action: 'farm_plot', label: 'แปลงผัก 6' },
        { type: 'pond', x: 742, y: 350, action: 'fish', label: 'ตกปลาในบ่อ' },
        { type: 'tree', x: 70, y: 230 }, { type: 'tree', x: 900, y: 240, s: 1.05 }, { type: 'tree', x: 930, y: 420, s: .9 },
        { type: 'bench', x: 780, y: 470 },
      ],
      doors: [{ x: 480, y: 505, zone: 'home', spawn: { x: 120, y: 460 }, label: 'กลับเข้าบ้าน' }],
      exits: [], npcs: ['sorn'],
    },
    home_street: {
      name: 'ถนนบ้านเรา', outdoor: true, theme: 'suburb',
      bg: '#8ab86a', spawn: { x: 480, y: 430 },
      buildings: [
        { x: 80, y: 145, w: 240, h: 195, wall: '#e7c69c', roof: '#b94e3f', name: 'บ้านของเรา', door: { x: 200, zone: 'home', spawn: { x: 470, y: 430 } }, type: 'home' },
        { x: 365, y: 165, w: 195, h: 175, wall: '#cfe2b8', roof: '#4f7d5d', name: 'บ้านแนน', door: { x: 462, zone: 'neighbor_home', spawn: { x: 470, y: 430 } }, type: 'home' },
        { x: 610, y: 155, w: 185, h: 185, wall: '#d9c7ea', roof: '#6b5686', name: 'บ้านย่าใหญ่', type: 'home' },
      ],
      props: [
        { type: 'sparkle', x: 690, y: 470, action: 'collect', label: 'เก็บของสะสมตามฤดู' },
        { type: 'bugspot', x: 330, y: 500, action: 'bug', label: 'จับแมลง' },
        { type: 'bench', x: 525, y: 480 },
        { type: 'tree', x: 45, y: 265 }, { type: 'tree', x: 600, y: 300, s: .9 }, { type: 'tree', x: 830, y: 250, s: 1.1 },
        { type: 'tree', x: 55, y: 505 }, { type: 'tree', x: 905, y: 512 },
        { type: 'lamp', x: 340, y: 360 }, { type: 'lamp', x: 620, y: 360 },
        { type: 'bus', x: 820, y: 450 },
        { type: 'metro_entry', x: 400, y: 505, action: 'metro', label: 'ลงสถานีรถไฟใต้ดิน' },
      ],
      exits: [
        { edge: 'left', zone: 'park', spawn: { x: 905, y: 330 } },
        { edge: 'right', zone: 'night_market', spawn: { x: 55, y: 430 } },
      ],
      npcs: [], doors: [],
    },
    neighbor_home: {
      name: 'บ้านเพื่อน', indoor: true, theme: 'home',
      bg: '#a8784e', wall: '#e0c8a0', spawn: { x: 470, y: 430 },
      props: [
        { type: 'sofa', x: 420, y: 320, action: 'sit_rest', label: 'นั่งเล่นที่บ้านเพื่อน' },
        { type: 'tv', x: 700, y: 210, action: 'watch_tv', label: 'ดูทีวีด้วยกัน' },
        { type: 'table', x: 620, y: 380 },
        { type: 'plant', x: 70, y: 300 }, { type: 'window', x: 300, y: 105 },
      ],
      doors: [{ x: 480, y: 505, zone: 'home_street', spawn: { x: 462, y: 375 }, label: 'ออกไปถนน' }],
      exits: [], npcs: ['nan'],
    },
    classroom: {
      name: 'ห้องเรียน', indoor: true, theme: 'school',
      bg: '#c8b888', wall: '#e8dcc0', spawn: { x: 480, y: 450 },
      props: [
        { type: 'desk', x: 470, y: 300, action: 'school', label: 'เรียนในคาบ (08:00–15:00)' },
        { type: 'board', x: 480, y: 120 },
        { type: 'desk', x: 250, y: 380 }, { type: 'desk', x: 690, y: 380 },
      ],
      doors: [{ x: 480, y: 505, zone: 'school_district', spawn: { x: 250, y: 400 }, label: 'ออกไปย่านโรงเรียน' }],
      exits: [], npcs: ['teacher', 'gun', 'khao'],
    },
    university: {
      name: 'มหาวิทยาลัย', indoor: true, theme: 'school',
      bg: '#b8b0a0', wall: '#ded8c8', spawn: { x: 480, y: 450 },
      props: [
        { type: 'desk', x: 470, y: 285, action: 'lecture', label: 'เรียนมหาวิทยาลัย ฿800' },
        { type: 'board', x: 480, y: 120 },
        { type: 'bookshelf', x: 120, y: 260 },
      ],
      doors: [{ x: 480, y: 505, zone: 'school_district', spawn: { x: 700, y: 400 }, label: 'ออกไปย่านโรงเรียน' }],
      exits: [], npcs: ['fah', 'nok', 'nana'],
    },
    school_district: {
      name: 'ย่านโรงเรียน', outdoor: true, theme: 'suburb',
      bg: '#8ab86a', spawn: { x: 480, y: 430 },
      buildings: [
        { x: 110, y: 140, w: 250, h: 190, wall: '#e8d8b0', roof: '#8a5a3a', name: 'โรงเรียน', door: { x: 235, zone: 'classroom', spawn: { x: 480, y: 450 } } },
        { x: 560, y: 130, w: 280, h: 200, wall: '#ded8c8', roof: '#5a6a7a', name: 'มหาวิทยาลัย', door: { x: 700, zone: 'university', spawn: { x: 480, y: 450 } } },
      ],
      props: [
        { type: 'sparkle', x: 850, y: 480, action: 'collect', label: 'เก็บของสะสมตามฤดู' },
        { type: 'bench', x: 450, y: 480 },
        { type: 'tree', x: 40, y: 260 }, { type: 'tree', x: 900, y: 300 },
        { type: 'lamp', x: 400, y: 360 }, { type: 'lamp', x: 560, y: 360 },
        { type: 'metro_entry', x: 330, y: 505, action: 'metro', label: 'ลงสถานีรถไฟใต้ดิน' },
      ],
      exits: [
        { edge: 'left', zone: 'night_market', spawn: { x: 905, y: 430 } },
        { edge: 'right', zone: 'downtown', spawn: { x: 55, y: 430 } },
      ],
      npcs: [], doors: [],
    },
    downtown: {
      name: 'ย่านดาวน์ทาวน์', outdoor: true, theme: 'city',
      bg: '#a89880', spawn: { x: 480, y: 440 },
      buildings: [
        { x: 30, y: 130, w: 150, h: 180, wall: '#e8d0a8', roof: '#a05a3a', name: 'ร้านสะดวกซื้อ', door: { x: 105, zone: 'store', spawn: { x: 470, y: 450 } } },
        { x: 200, y: 120, w: 150, h: 190, wall: '#e0c8a8', roof: '#7a5a3a', name: 'คาเฟ่', door: { x: 275, zone: 'cafe', spawn: { x: 470, y: 450 } } },
        { x: 370, y: 130, w: 150, h: 180, wall: '#f0f0f0', roof: '#6a8a9a', name: 'โรงพยาบาล', door: { x: 445, zone: 'hospital', spawn: { x: 470, y: 450 } } },
        { x: 540, y: 120, w: 150, h: 190, wall: '#d8d8e8', roof: '#5a5a7a', name: 'ธนาคาร', door: { x: 615, zone: 'bank', spawn: { x: 470, y: 450 } } },
        { x: 710, y: 130, w: 150, h: 180, wall: '#e8d8e8', roof: '#8a5a7a', name: 'ห้างสรรพสินค้า', door: { x: 785, zone: 'mall', spawn: { x: 470, y: 450 } } },
        { x: 880, y: 140, w: 70, h: 170, wall: '#c8a888', roof: '#5a3a2a', name: 'บาร์', door: { x: 915, zone: 'bar', spawn: { x: 470, y: 450 } } },
      ],
      props: [
        { type: 'sparkle', x: 500, y: 500, action: 'collect', label: 'เก็บของสะสมตามฤดู' },
        { type: 'bugspot', x: 170, y: 505, action: 'bug', label: 'จับแมลง' },
        { type: 'lamp', x: 250, y: 375 }, { type: 'lamp', x: 690, y: 375 },
        { type: 'bench', x: 340, y: 480 },
        { type: 'bus', x: 800, y: 505 },
        { type: 'metro_entry', x: 640, y: 505, action: 'metro', label: 'ลงสถานีรถไฟใต้ดิน' },
      ],
      exits: [
        { edge: 'left', zone: 'school_district', spawn: { x: 905, y: 430 } },
        { edge: 'right', zone: 'park', spawn: { x: 55, y: 430 } },
      ],
      npcs: ['palee', 'taew', 'wan', 'mek'], doors: [],
    },
    park: {
      name: 'สวนสาธารณะ', outdoor: true, theme: 'park',
      bg: '#7ab860', spawn: { x: 470, y: 440 },
      props: [
        { type: 'bench', x: 300, y: 470, action: 'rest_bench', label: 'นั่งพักบนม้านั่ง' },
        { type: 'pond', x: 700, y: 460, action: 'fish', label: 'ตกปลาที่สระ' },
        { type: 'sparkle', x: 560, y: 520, action: 'collect', label: 'เก็บของสะสมตามฤดู' },
        { type: 'bugspot', x: 180, y: 350, action: 'bug', label: 'จับแมลง' },
        { type: 'festival', x: 850, y: 330, action: 'festival', label: 'เวทีเทศกาล' },
        { type: 'tree', x: 60, y: 230 }, { type: 'tree', x: 240, y: 210 }, { type: 'tree', x: 430, y: 230, s: .9 },
        { type: 'tree', x: 620, y: 215, s: 1.05 }, { type: 'tree', x: 900, y: 230 },
        { type: 'lamp', x: 380, y: 380 }, { type: 'lamp', x: 620, y: 380 },
        { type: 'flowers', x: 350, y: 510 }, { type: 'flowers', x: 780, y: 510 },
      ],
      doors: [],
      exits: [
        { edge: 'left', zone: 'harbor', spawn: { x: 905, y: 430 } },
        { edge: 'right', zone: 'farm_district', spawn: { x: 55, y: 430 } },
      ],
      npcs: ['gun', 'lungchai', 'grandma', 'wan', 'lungdoo', 'morkae'], doors: [],
    },
    night_market: {
      name: 'ตลาดกลางคืน', outdoor: true, theme: 'market',
      bg: '#8a7a68', spawn: { x: 470, y: 440 },
      buildings: [
        { x: 40, y: 150, w: 210, h: 175, wall: '#f2c84a', roof: '#d94b4b', name: 'ร้านก๋วยเตี๋ยว', type: 'shop' },
        { x: 300, y: 135, w: 190, h: 190, wall: '#8ad0e8', roof: '#2b6fb8', name: 'ร้านขนม', type: 'shop' },
        { x: 700, y: 140, w: 220, h: 185, wall: '#f2a0b8', roof: '#b83a6a', name: 'ร้านดอกไม้', type: 'shop' },
      ],
      props: [
        { type: 'stall', x: 540, y: 360, action: 'street_food', label: 'กินของอร่อยในตลาด ฿90' },
        { type: 'stall', x: 810, y: 360, action: 'buy_gift', label: 'ซื้อของขวัญจากตลาด ฿120' },
        { type: 'stage', x: 640, y: 470, action: 'busker', label: 'ฟังดนตรีเปิดหมวก' },
        { type: 'lantern', x: 180, y: 350 }, { type: 'lantern', x: 420, y: 350 }, { type: 'lantern', x: 760, y: 350 },
        { type: 'sparkle', x: 890, y: 500, action: 'collect', label: 'เก็บของสะสมตามฤดู' },
        { type: 'bugspot', x: 120, y: 500, action: 'bug', label: 'จับแมลง' },
        { type: 'bench', x: 380, y: 490 },
        { type: 'bus', x: 190, y: 520 },
        { type: 'tree', x: 55, y: 505 }, { type: 'tree', x: 920, y: 300 },
      ],
      doors: [],
      exits: [
        { edge: 'left', zone: 'home_street', spawn: { x: 905, y: 430 } },
        { edge: 'right', zone: 'school_district', spawn: { x: 55, y: 430 } },
      ],
      npcs: ['palee', 'taew', 'vendor', 'busker', 'tourist'], doors: [],
    },
    harbor: {
      name: 'ท่าเรือ', outdoor: true, theme: 'harbor',
      bg: '#5ab8c8', spawn: { x: 470, y: 440 },
      buildings: [
        { x: 60, y: 150, w: 240, h: 180, wall: '#e8d8b0', roof: '#2b6fb8', name: 'โรงเก็บเรือ', type: 'shop' },
        { x: 660, y: 150, w: 230, h: 180, wall: '#f2e0c0', roof: '#2b8a8a', name: 'ร้านอาหารทะเล', type: 'shop' },
      ],
      props: [
        { type: 'pier', x: 470, y: 430 },
        { type: 'boat', x: 470, y: 470, action: 'boat_trip', label: 'นั่งเรือออกทะเล ฿400' },
        { type: 'crate', x: 260, y: 470 }, { type: 'crate', x: 300, y: 490 },
        { type: 'pond', x: 180, y: 360, action: 'fish', label: 'ตกปลาที่ท่าเรือ' },
        { type: 'sparkle', x: 780, y: 500, action: 'collect', label: 'เก็บของสะสมตามฤดู' },
        { type: 'bugspot', x: 880, y: 470, action: 'bug', label: 'จับแมลง' },
        { type: 'bench', x: 640, y: 500 },
        { type: 'bus', x: 140, y: 520 },
        { type: 'metro_entry', x: 820, y: 430, action: 'metro', label: 'ลงสถานีรถไฟใต้ดิน' },
        { type: 'tree', x: 40, y: 505 }, { type: 'tree', x: 930, y: 360 },
        { type: 'lamp', x: 360, y: 380 }, { type: 'lamp', x: 620, y: 380 },
      ],
      doors: [],
      exits: [
        { edge: 'left', zone: 'downtown', spawn: { x: 905, y: 430 } },
        { edge: 'right', zone: 'park', spawn: { x: 55, y: 430 } },
      ],
      npcs: ['captain', 'fisher', 'lungchai', 'tourist'], doors: [],
    },
    farm_district: {
      name: 'ทุ่งนา', outdoor: true, theme: 'farm',
      bg: '#8ac85a', spawn: { x: 470, y: 450 },
      buildings: [
        { x: 80, y: 145, w: 250, h: 180, wall: '#e8d0a8', roof: '#b85a3a', name: 'โรงนา', type: 'shop' },
        { x: 720, y: 135, w: 190, h: 190, wall: '#f2e8c8', roof: '#8a5a2a', name: 'บ้านชาวนา', type: 'shop' },
      ],
      props: [
        { type: 'field', x: 300, y: 470 },
        { type: 'field', x: 460, y: 470 },
        { type: 'scarecrow', x: 380, y: 470 },
        { type: 'windmill', x: 660, y: 330 },
        { type: 'farm_plot', x: 180, y: 460, action: 'farm_work', label: 'รับจ้างเก็บเกี่ยว' },
        { type: 'pond', x: 850, y: 470, action: 'fish', label: 'ตกปลาในคลอง' },
        { type: 'sparkle', x: 560, y: 510, action: 'collect', label: 'เก็บของสะสมตามฤดู' },
        { type: 'bugspot', x: 90, y: 500, action: 'bug', label: 'จับแมลง' },
        { type: 'bench', x: 700, y: 500 },
        { type: 'bus', x: 820, y: 555 },
        { type: 'metro_entry', x: 880, y: 420, action: 'metro', label: 'ลงสถานีรถไฟใต้ดิน' },
        { type: 'tree', x: 60, y: 330 }, { type: 'tree', x: 930, y: 330 },
        { type: 'flowers', x: 820, y: 360 }, { type: 'flowers', x: 620, y: 360 },
      ],
      doors: [],
      exits: [
        { edge: 'left', zone: 'park', spawn: { x: 905, y: 430 } },
        { edge: 'right', zone: 'ranch', spawn: { x: 55, y: 470 } },
      ],
      npcs: ['farmhand', 'sorn', 'grandma', 'khao'], doors: [],
    },
    ranch: {
      name: 'ทุ่งเลี้ยงสัตว์', outdoor: true, theme: 'ranch',
      bg: '#8ac85a', spawn: { x: 470, y: 480 },
      buildings: [
        { x: 50, y: 140, w: 240, h: 180, wall: '#e8c8a0', roof: '#a85a3a', name: 'โรงนาใหญ่', type: 'shop' },
        { x: 760, y: 150, w: 170, h: 170, wall: '#f2e0c0', roof: '#7a5a2a', name: 'บ้านคนเลี้ยง', type: 'shop' },
      ],
      props: [
        { type: 'pen', x: 360, y: 390, animal: 'chicken', slot: 0, action: 'livestock', label: 'คอกไก่' },
        { type: 'pen', x: 600, y: 390, animal: 'cow',     slot: 1, action: 'livestock', label: 'คอกวัว' },
        { type: 'pen', x: 360, y: 490, animal: 'sheep',   slot: 2, action: 'livestock', label: 'คอกแกะ' },
        { type: 'pen', x: 600, y: 490, animal: 'goat',    slot: 3, action: 'livestock', label: 'คอกแพะ' },
        { type: 'pet_house', x: 830, y: 460, action: 'pet_care', label: 'บ้านสัตว์เลี้ยง' },
        { type: 'trough', x: 470, y: 430, action: 'feed_all', label: 'ให้อาหารสัตว์ทั้งหมด' },
        { type: 'windmill', x: 700, y: 320 },
        { type: 'scarecrow', x: 140, y: 420 },
        { type: 'sparkle', x: 480, y: 520, action: 'collect', label: 'เก็บของสะสมตามฤดู' },
        { type: 'bench', x: 900, y: 500 },
        { type: 'tree', x: 40, y: 330 }, { type: 'tree', x: 930, y: 330 },
        { type: 'flowers', x: 820, y: 400 }, { type: 'flowers', x: 250, y: 530 },
      ],
      doors: [],
      exits: [
        { edge: 'left', zone: 'farm_district', spawn: { x: 905, y: 430 } },
        { edge: 'right', zone: 'home_street', spawn: { x: 55, y: 430 } },
      ],
      npcs: ['nid', 'tom'], doors: [],
    },
    metro_station: {
      name: 'สถานีรถไฟใต้ดิน', indoor: true, theme: 'metro',
      bg: '#565668', wall: '#7c7c96', spawn: { x: 470, y: 470 },
      props: [
        { type: 'train', x: 480, y: 310, action: 'metro_ride', label: 'ขึ้นรถไฟใต้ดิน' },
        { type: 'turnstile', x: 520, y: 380, action: 'metro_gate', label: 'ผ่านประตูตรวจบัตร' },
        { type: 'ticket_machine', x: 760, y: 380, action: 'metro_card', label: 'ซื้อบัตรโดยสาร ฿500' },
        { type: 'board', x: 470, y: 120 },
        { type: 'bench', x: 230, y: 420, action: 'rest_bench', label: 'นั่งพักที่สถานี' },
        { type: 'neon_sign', x: 160, y: 160 },
        { type: 'metro_entry', x: 60, y: 470, up: true, action: 'metro_up', label: 'ขึ้นไปดาวน์ทาวน์' },
      ],
      doors: [
        { x: 895, y: 470, zone: 'underground', spawn: { x: 470, y: 470 }, label: 'ลงไปเมืองใต้ดิน' },
      ],
      exits: [], npcs: ['tom'],
    },
    underground: {
      name: 'เมืองใต้ดิน', outdoor: true, theme: 'underground',
      bg: '#3a3450', spawn: { x: 470, y: 470 },
      buildings: [
        { x: 40, y: 130, w: 200, h: 180, wall: '#5a4a6a', roof: '#3a2a4a', name: 'กิลด์นักเวท', type: 'shop' },
        { x: 720, y: 130, w: 210, h: 180, wall: '#4a3a5a', roof: '#2a1a3a', name: 'ร้านขายคริสตัล', type: 'shop' },
      ],
      props: [
        { type: 'guild_board', x: 460, y: 400, action: 'guild', label: 'กระดานประกาศกิลด์' },
        { type: 'potion_shelf', x: 240, y: 370, action: 'magic_shop', label: 'ร้านเวทมนตร์' },
        { type: 'crystal_rock', x: 150, y: 470, action: 'crystal', label: 'เก็บคริสตัลวิเศษ' },
        { type: 'cauldron', x: 640, y: 440, action: 'meditate', label: 'นั่งสมาธิหน้อปรุงเวท' },
        { type: 'portal', x: 860, y: 400, action: 'boss', label: 'ประตูมิติ · ท้าบอส' },
        { type: 'pet_shop', x: 360, y: 500, action: 'pet_shop', label: 'ร้านสัตว์วิเศษ' },
        { type: 'neon_sign', x: 480, y: 150 },
        { type: 'lantern', x: 300, y: 330 }, { type: 'lantern', x: 700, y: 330 },
        { type: 'sparkle', x: 540, y: 520, action: 'collect', label: 'เก็บของสะสมตามฤดู' },
        { type: 'bench', x: 470, y: 500 },
      ],
      doors: [],
      exits: [
        { edge: 'left', zone: 'metro_station', spawn: { x: 860, y: 470 } },
      ],
      npcs: ['mira', 'luna', 'gob', 'onyx', 'faye', 'hana', 'kla', 'ploynoi', 'sorn2', 'vlad'], doors: [],
    },
    store: {
      name: 'ร้านสะดวกซื้อ', indoor: true, theme: 'shop',
      bg: '#d8ccb0', wall: '#efe6d4', spawn: { x: 470, y: 450 },
      props: [
        { type: 'shelf', x: 300, y: 240, action: 'buy_snack', label: 'ซื้อขนม/น้ำ ฿60' },
        { type: 'counter', x: 700, y: 300, action: 'buy_food', label: 'ซื้ออาหารกล่อง ฿120' },
        { type: 'shelf', x: 550, y: 220 },
      ],
      doors: [{ x: 480, y: 505, zone: 'downtown', spawn: { x: 105, y: 380 }, label: 'ออกไปดาวน์ทาวน์' }],
      exits: [], npcs: ['pataew', 'arn'],
    },
    cafe: {
      name: 'คาเฟ่', indoor: true, theme: 'cafe',
      bg: '#a87a52', wall: '#d8b88f', spawn: { x: 470, y: 450 },
      props: [
        { type: 'table', x: 470, y: 300, action: 'eat_cafe', label: 'กินอาหารที่คาเฟ่ ฿250' },
        { type: 'counter', x: 760, y: 240, action: 'coffee', label: 'ดื่มกาแฟ ฿80' },
        { type: 'table', x: 300, y: 380 }, { type: 'plant', x: 80, y: 260 },
      ],
      doors: [{ x: 480, y: 505, zone: 'downtown', spawn: { x: 275, y: 380 }, label: 'ออกไปดาวน์ทาวน์' }],
      exits: [], npcs: ['mint', 'ploy', 'tee', 'arn', 'nana', 'fah'],
    },
    hospital: {
      name: 'โรงพยาบาล', indoor: true, theme: 'hospital',
      bg: '#cfd8d8', wall: '#eef4f4', spawn: { x: 470, y: 450 },
      props: [
        { type: 'desk', x: 500, y: 280, action: 'hospital', label: 'ตรวจสุขภาพ / รักษา' },
        { type: 'bed', x: 180, y: 300 }, { type: 'bed', x: 800, y: 300 },
      ],
      doors: [{ x: 480, y: 505, zone: 'downtown', spawn: { x: 445, y: 380 }, label: 'ออกไปดาวน์ทาวน์' }],
      exits: [], npcs: ['doctor', 'jane', 'morkae'],
    },
    bank: {
      name: 'ธนาคาร', indoor: true, theme: 'bank',
      bg: '#b8b8c8', wall: '#e2e2ec', spawn: { x: 470, y: 450 },
      props: [
        { type: 'counter', x: 480, y: 270, action: 'bank', label: 'ฝาก/ถอน/กู้เงิน' },
        { type: 'plant', x: 600, y: 300 },
      ],
      doors: [{ x: 480, y: 505, zone: 'downtown', spawn: { x: 615, y: 380 }, label: 'ออกไปดาวน์ทาวน์' }],
      exits: [], npcs: ['banker'],
    },
    mall: {
      name: 'ห้างสรรพสินค้า', indoor: true, theme: 'mall',
      bg: '#d8c8d8', wall: '#f0e8f0', spawn: { x: 470, y: 450 },
      props: [
        { type: 'shelf', x: 280, y: 260, action: 'shop_outfit', label: 'ร้านเสื้อผ้า' },
        { type: 'shelf', x: 660, y: 260, action: 'shop_furniture', label: 'ร้านเฟอร์นิเจอร์' },
        { type: 'tree', x: 480, y: 240 },
      ],
      doors: [{ x: 480, y: 505, zone: 'downtown', spawn: { x: 785, y: 380 }, label: 'ออกไปดาวน์ทาวน์' }],
      exits: [], npcs: ['ploy', 'seller', 'june', 'ada', 'kim'],
    },
    office: {
      name: 'ออฟฟิศ', indoor: true, theme: 'office',
      bg: '#a0a8b0', wall: '#d8dde2', spawn: { x: 470, y: 450 },
      props: [
        { type: 'desk', x: 470, y: 290, action: 'work', label: 'ทำงาน (08:00–17:00)' },
        { type: 'bookshelf', x: 740, y: 250 },
        { type: 'desk', x: 260, y: 380 }, { type: 'desk', x: 690, y: 380 },
      ],
      doors: [{ x: 480, y: 505, zone: 'downtown', spawn: { x: 470, y: 400 }, label: 'ออกไปดาวน์ทาวน์' }],
      exits: [], npcs: ['boss', 'tee', 'dad'],
    },
    gym: {
      name: 'โรงยิม', indoor: true, theme: 'gym',
      bg: '#b0a8a0', wall: '#d8d0c8', spawn: { x: 470, y: 450 },
      props: [
        { type: 'counter', x: 470, y: 300, action: 'gym', label: 'ออกกำลังกาย ฿80' },
        { type: 'shelf', x: 760, y: 260 },
        { type: 'bench', x: 280, y: 380 },
      ],
      doors: [{ x: 480, y: 505, zone: 'downtown', spawn: { x: 900, y: 420 }, label: 'ออกไปดาวน์ทาวน์' }],
      exits: [], npcs: ['poom', 'coach'],
    },
    bar: {
      name: 'บาร์กลางคืน', indoor: true, theme: 'bar',
      bg: '#4a3a44', wall: '#5a4a54', spawn: { x: 470, y: 450 },
      props: [
        { type: 'counter', x: 470, y: 280, action: 'drink', label: 'สั่งเครื่องดื่ม ฿150' },
        { type: 'table', x: 250, y: 380 }, { type: 'table', x: 700, y: 380 },
      ],
      doors: [{ x: 480, y: 505, zone: 'downtown', spawn: { x: 915, y: 400 }, label: 'ออกไปดาวน์ทาวน์' }],
      exits: [], npcs: ['mint', 'banker', 'lungdoo', 'vlad'],
    },
  };

  // ทางออกของโซนที่ใช้ประตูอาคาร
  const BUILDING_LABELS = {
    store: 'ร้านสะดวกซื้อ', cafe: 'คาเฟ่', hospital: 'โรงพยาบาล', bank: 'ธนาคาร',
    mall: 'ห้างสรรพสินค้า', bar: 'บาร์', office: 'ออฟฟิศ', gym: 'โรงยิม',
  };

  /* ---------------- NPC ---------------- */
  // spot: [zone, fromMin, toMin, days(all|school|weekend)]
  const NPCS = {
    gun:      { name: 'กัน',        dateable: true,  skin: '#f2c39b', hair: '#2a2118', shirt: '#e05a5a', pants: '#3d4a6b', style: 'messy', lines: ['วันนี้เรียนอะไรบ้าง?', 'ไปวิ่งที่สวนกันไหม', 'ฉันว่าจะลองสมัครงานพาร์ทไทม์'], spots: [['classroom', 480, 900, 'school'], ['park', 900, 1200, 'all'], ['home_street', 1200, 1320, 'all']] },
    nan:      { name: 'แนน',        dateable: true,  skin: '#f2c39b', hair: '#3a2418', shirt: '#f29ac0', pants: '#5a3a5e', style: 'long', lines: ['บ้านฉันอยู่ติดบ้านเธอเอง', 'อยากไปคาเฟ่ด้วยกันไหม', 'ฉันชอบอ่านนิยายมาก'], spots: [['neighbor_home', 420, 1320, 'all'], ['cafe', 600, 900, 'weekend']] },
    pataew:   { name: 'ป้าแต๋ว',     dateable: false, skin: '#e8b98a', hair: '#4a3a2a', shirt: '#f2c05a', pants: '#6b4a3a', style: 'bun', lines: ['ขนมเพิ่งมาใหม่นะลูก', 'วันนี้ลูกค้าเยอะจัง', 'อย่าลืมกินข้าวด้วยนะ'], spots: [['store', 420, 1260, 'all']] },
    mint:     { name: 'มิ้นท์',      dateable: true,  skin: '#f2c39b', hair: '#5a2e3a', shirt: '#9a7ad0', pants: '#3d3550', style: 'bob', lines: ['กาแฟแก้วโปรดของฉันคือลาเต้', 'กลางคืนฉันทำงานที่บาร์', 'เธอดูเครียด ๆ นะ พักบ้าง'], spots: [['cafe', 540, 1020, 'all'], ['bar', 1080, 1380, 'all']] },
    boss:     { name: 'บอส',        dateable: false, skin: '#d9a97a', hair: '#1f1a16', shirt: '#3f4d63', pants: '#2a2a2a', style: 'short', lines: ['งานเสร็จหรือยัง?', 'ขยันแบบนี้ได้เลื่อนตำแหน่งแน่', 'อย่าลืมส่งรายงานก่อนเลิกงาน'], spots: [['office', 480, 1020, 'school']] },
    poom:     { name: 'ภูมิ',        dateable: true,  skin: '#d9a97a', hair: '#2a2118', shirt: '#4aa3ff', pants: '#2e3a59', style: 'short', lines: ['วอร์มก่อนเล่นเวทด้วยนะ', 'วันนี้เล่นกล้ามเนื้อส่วนไหน?', 'วิ่งสามรอบแล้วยัง?'], spots: [['gym', 420, 1260, 'all']] },
    lungchai: { name: 'ลุงชัย',      dateable: false, skin: '#d9a97a', hair: '#b8b8b8', shirt: '#8a9a6a', pants: '#4a4a4a', style: 'short', lines: ['เมื่อก่อนแถวนี้มีแต่ทุ่งนา', 'เดินเล่นทุกวันร่างกายแข็งแรงนะ', 'ดูนกตัวนั้นสิ'], spots: [['park', 360, 1080, 'all']] },
    fah:      { name: 'ฟ้า',        dateable: true,  skin: '#f2c39b', hair: '#1f1a16', shirt: '#7ad0c0', pants: '#3a4a5e', style: 'ponytail', lines: ['วิชานี้ยากจัง', 'ฉันเรียนสถาปัตย์อยู่', 'เย็นนี้ไปเดินสวนไหม'], spots: [['university', 540, 960, 'school'], ['park', 960, 1140, 'all']] },
    teacher:  { name: 'ครูสมศรี',    dateable: false, skin: '#e8b98a', hair: '#3a2a1a', shirt: '#8a6ab0', pants: '#4a3a5e', style: 'bun', lines: ['ตั้งใจเรียนนะจ๊ะ', 'การบ้านส่งหรือยัง?', 'วันนี้เราจะเรียนเรื่องใหม่'], spots: [['classroom', 480, 900, 'school']] },
    doctor:   { name: 'หมออนันต์',   dateable: false, skin: '#d9a97a', hair: '#2a2118', shirt: '#f2f2f2', pants: '#4a5a6b', style: 'short', lines: ['พักผ่อนให้เพียงพอนะ', 'ออกกำลังกายสม่ำเสมอดีมาก', 'มีอะไรให้ช่วยไหม'], spots: [['hospital', 480, 1020, 'school']] },
    dad:      { name: 'พ่อสมชาย',   dateable: false, skin: '#d9a97a', hair: '#2a2118', shirt: '#5a7a5a', pants: '#3a3a4a', style: 'short', lines: ['พ่อต้องไปทำงานแล้วนะ', 'ตั้งใจเรียนนะลูก', 'เย็นนี้กินข้าวด้วยกันไหม'], spots: [['home', 360, 510, 'all'], ['office', 510, 1020, 'school'], ['home', 1020, 1320, 'all']] },
    mom:      { name: 'แม่สมหญิง',  dateable: false, skin: '#f2c39b', hair: '#3a2418', shirt: '#e88a9a', pants: '#5a3a4a', style: 'bun', lines: ['แม่ทำกับข้าวไว้ให้นะ', 'อย่านอนดึกเกินไป', 'การบ้านเสร็จหรือยังลูก'], spots: [['home', 360, 540, 'all'], ['hospital', 540, 900, 'school'], ['home', 900, 1320, 'all']] },
    ploy:     { name: 'พลอย',       dateable: true,  skin: '#f2c39b', hair: '#4a2a1e', shirt: '#d86a8a', pants: '#3a3048', style: 'long', lines: ['ดีไซน์ชุดใหม่เสร็จแล้วนะ', 'ห้างนี้มีมุมถ่ายรูปสวย ๆ เยอะ', 'ชอบสีเอิร์ธโทนเหมือนกันไหม'], spots: [['mall', 540, 1020, 'school'], ['cafe', 1020, 1140, 'all']] },
    tee:      { name: 'ที',          dateable: true,  skin: '#e8b98a', hair: '#1f1a16', shirt: '#5a8ac0', pants: '#2a3040', style: 'short', lines: ['โค้ดชุดนี้เพิ่งผ่านเทสต์', 'กาแฟคือเชื้อเพลิงของโปรแกรมเมอร์', 'อยากลองเขียนเกมบ้างไหม'], spots: [['office', 540, 1020, 'school'], ['cafe', 1080, 1260, 'all']] },
    jane:     { name: 'เจน',        dateable: true,  skin: '#f2c39b', hair: '#2a2118', shirt: '#6ac0b8', pants: '#e8eef0', style: 'ponytail', lines: ['วันนี้คนไข้เยอะมาก', 'ล้างมือบ่อย ๆ นะ', 'พักผ่อนให้พอร่างกายจะได้แข็งแรง'], spots: [['hospital', 420, 900, 'school'], ['park', 960, 1080, 'all']] },
    arn:      { name: 'อาร์น',       dateable: true,  skin: '#d9a97a', hair: '#2a2118', shirt: '#f2f2f2', pants: '#4a4038', style: 'short', lines: ['ซุปวันนี้หอมมาก', 'อยากลองทำขนมปังไหม', 'ครัวคือที่ที่ฉันมีความสุขที่สุด'], spots: [['cafe', 360, 840, 'school'], ['store', 900, 1020, 'all']] },
    nok:      { name: 'นก',          dateable: false, skin: '#e8b98a', hair: '#3a2418', shirt: '#9a8ac0', pants: '#4a4050', style: 'bun', lines: ['หนังสือเล่มนี้สนุกมากเลย', 'ห้องสมุดเงียบ ๆ คือสวรรค์', 'ยืมหนังสือไปอ่านได้นะ'], spots: [['university', 480, 960, 'school'], ['park', 990, 1140, 'all']] },
    banker:   { name: 'แบงค์',       dateable: true,  skin: '#d9a97a', hair: '#2a2118', shirt: '#e8e8f0', pants: '#3a4050', style: 'short', lines: ['ออมเงินตั้งแต่วันนี้ดีกว่านะ', 'ดอกเบี้ยก็นับเป็นรายได้เหมือนกัน', 'วันนี้ตลาดหุ้นเงียบจัง'], spots: [['bank', 540, 1020, 'school'], ['bar', 1140, 1320, 'all']] },
    wan:      { name: 'หวาน',       dateable: true,  skin: '#f2c39b', hair: '#5a3a2a', shirt: '#e8a0b8', pants: '#5a4a5a', style: 'long', lines: ['ดอกไม้ช่อนี้เพิ่งตัดมาเช้านี้', 'กลิ่นดอกไม้ทำให้ใจสงบนะ', 'เลือกดอกไม้ให้คนพิเศษหรือยัง'], spots: [['park', 420, 900, 'all'], ['downtown', 930, 1080, 'all']] },
    grandma:  { name: 'ย่าใหญ่',     dateable: false, skin: '#e0b098', hair: '#d8d8d8', shirt: '#b08a9a', pants: '#5a4a4a', style: 'bun', lines: ['ย่าเดินออกกำลังกายทุกเช้าเลยนะ', 'อาหารบ้าน ๆ นี่แหละอร่อยที่สุด', 'เด็ก ๆ สมัยนี้รีบกันจัง'], spots: [['park', 360, 600, 'all'], ['home_street', 960, 1080, 'all']] },
    khao:     { name: 'น้องข้าว',    dateable: false, skin: '#f2c39b', hair: '#2a2118', shirt: '#f2d05a', pants: '#4a5a8a', style: 'messy', lines: ['พี่ ๆ เล่นอะไรกันเหรอ', 'วันนี้ครูให้ดาวด้วยแหละ', 'ขอเล่นด้วยคนได้ไหม'], spots: [['classroom', 480, 900, 'school'], ['home_street', 960, 1140, 'all'], ['park', 900, 1020, 'weekend']] },
    palee:    { name: 'ป้าลี',       dateable: false, skin: '#e0a98a', hair: '#3a2a1a', shirt: '#e08a5a', pants: '#5a4030', style: 'bun', lines: ['ผักผลไม้สด ๆ จากสวนเลยนะ', 'ลองชิมมะม่วงหน่อยไหม', 'ขายดีจนแทบไม่มีเวลานั่ง'], spots: [['downtown', 480, 1080, 'all']] },
    lungdoo:  { name: 'ลุงดนตรี',    dateable: false, skin: '#d9a97a', hair: '#c8c8c8', shirt: '#6a7a9a', pants: '#3a3a4a', style: 'long', lines: ['เสียงกีตาร์นี้เพราะไหม', 'ดนตรีทำให้คนเข้าใจกันมากขึ้น', 'กลางคืนฉันเล่นที่บาร์นะ'], spots: [['park', 1020, 1200, 'all'], ['bar', 1200, 1380, 'all']] },
    morkae:   { name: 'หมอแก้ว',     dateable: true,  skin: '#f2c39b', hair: '#3a2418', shirt: '#8ac8b8', pants: '#e8f0ee', style: 'long', lines: ['แมวที่บ้านฉันก็ดื้อเหมือนกัน', 'สัตว์เลี้ยงต้องการความรักมากนะ', 'พาสัตว์มาให้ตรวจได้ตลอด'], spots: [['hospital', 540, 960, 'school'], ['park', 990, 1110, 'all']] },
    coach:    { name: 'โค้ชอาร์ท',    dateable: false, skin: '#c98f62', hair: '#1f1a16', shirt: '#e05a4a', pants: '#2a3444', style: 'short', lines: ['วอร์มก่อนยกเวทดัวยนะ', 'วันนี้วิ่งกี่รอบแล้ว?', 'ออกกำลังกายแล้วกินให้พอด้วย'], spots: [['gym', 360, 1080, 'all']] },
    nana:     { name: 'นานา',       dateable: true,  skin: '#f2c39b', hair: '#4a2a3a', shirt: '#b09ad8', pants: '#3a3a50', style: 'bob', lines: ['สอบใกล้เข้ามาแล้ว เครียดจัง', 'ไปนั่งคาเฟ่หลังเลิกเรียนกันไหม', 'ฉันกำลังหัดวาดรูปอยู่'], spots: [['university', 480, 900, 'school'], ['cafe', 930, 1080, 'all']] },
    taew:     { name: 'แต๋ว',       dateable: true,  skin: '#e8b98a', hair: '#2a1a16', shirt: '#f2a0c0', pants: '#3a3048', style: 'ponytail', lines: ['我第一次มาเมืองนี้ น่ารักจัง', 'กาแฟที่นี่อร่อยกว่าในเมืองใหญ่', 'ขอถามหน่อย สถานีรถเมล์ไปทางไหน'], spots: [['downtown', 600, 1080, 'weekend'], ['park', 600, 960, 'weekend']] },
    sorn:     { name: 'สอน',         dateable: false, skin: '#c98f62', hair: '#3a2a1a', shirt: '#7a9a5a', pants: '#4a4030', style: 'short', lines: ['ต้นไม้ต้นนี้ฉันปลูกเองนะ', 'รดน้ำตอนเช้าดีที่สุด', 'ธรรมชาติใจดีกับคนใจเย็น'], spots: [['park', 360, 900, 'all'], ['home_street', 930, 1050, 'all'], ['backyard', 960, 1080, 'all']] },
    seller:   { name: 'นภา',        dateable: false, skin: '#e8b98a', hair: '#3a2418', shirt: '#c88a5a', pants: '#4a3a30', style: 'bob', lines: ['ลองชุดนี้ไหมคะ', 'ลดราคาพอดีเลยวันนี้', 'สีนี้เข้ากับคุณมาก'], spots: [['mall', 480, 1080, 'all']] },
    vendor:   { name: 'ป้าเหมียว',  dateable: false, skin: '#e8b98a', hair: '#5a3a2a', shirt: '#f2803a', pants: '#5a2a2a', style: 'bun', lines: ['ลูกค้าเยอะตั้งแต่หัวค่ำเลย', 'ลองชิมขนม freshly made ไหม', 'ตลาดคืนนี้ครึกครื้นจัง'], spots: [['night_market', 1020, 1380, 'all']] },
    busker:   { name: 'เอก',         dateable: true,  skin: '#d9a97a', hair: '#2a2118', shirt: '#6a4a8a', pants: '#2a2a34', style: 'messy', lines: ['เพลงนี้แต่งตอนฝนตก', 'หยอดเหรียญแล้วขอเพลงได้นะ', 'กลางคืนเมืองนี้มีเสน่ห์'], spots: [['night_market', 1080, 1380, 'all']] },
    tourist:  { name: 'ลิซ่า',       dateable: true,  skin: '#f2c39b', hair: '#d8b06a', shirt: '#4ac8b8', pants: '#2e3a4e', style: 'long', lines: ['เมืองนี้สวยกว่าที่คิด', 'ช่วยถ่ายรูปให้หน่อยได้ไหม', 'ฉันเพิ่งมาถึงท่าเรือเมื่อเช้า'], spots: [['night_market', 960, 1200, 'all'], ['harbor', 720, 1020, 'all']] },
    captain:  { name: 'กัปตันสมุทร', dateable: false, skin: '#c98f62', hair: '#d8d8d8', shirt: '#2b4a7a', pants: '#1f2a3a', style: 'short', lines: ['ทะเลวันนี้สงบดี', 'อยากออกรอบไหมล่ะ', 'ลมตะวันออกพัดแรงช่วงนี้'], spots: [['harbor', 360, 1080, 'all']] },
    fisher:   { name: 'ลุงหอย',     dateable: false, skin: '#b87a52', hair: '#b8b8b8', shirt: '#4a8a8a', pants: '#3a4a4a', style: 'short', lines: ['ปลาเยอะตอนน้ำขึ้น', 'อวนนี้ซ่อมมาสองวันแล้ว', 'ทะเลเลี้ยงคนได้ทั้งเมือง'], spots: [['harbor', 360, 900, 'all']] },
    farmhand: { name: 'น้าจันทร์',   dateable: false, skin: '#c98f62', hair: '#3a2a1a', shirt: '#8a9a4a', pants: '#5a4a2a', style: 'bun', lines: ['ข้าวใกล้ออกรวงแล้ว', 'อยากลองเกี่ยวข้าวไหม', 'แดดแรง อย่าลืมดื่มน้ำ'], spots: [['farm_district', 360, 1080, 'all']] },
    june:     { name: 'จูน',        dateable: true,  skin: '#ffe6cf', hair: '#e87aa8', shirt: '#ffd24a', pants: '#e85a9a', style: 'twintails', role: 'idol', lines: ['พรุ่งนี้มีคอนเสิร์ตที่ห้างนะ', 'ร้องเพลงด้วยกันไหม', 'ฉันซ้อมเต้นทุกวันเลย'], spots: [['mall', 540, 1020, 'all'], ['night_market', 1080, 1260, 'all']] },
    ada:      { name: 'อาดา',       dateable: true,  skin: '#b87a52', hair: '#241a2a', shirt: '#c8a8ff', pants: '#3a2a4a', style: 'afro', role: 'model', lines: ['วันนี้มีถ่ายแบบตอนบ่าย', 'เดินแบบต้องหลังตรงนะ', 'สีนี้เข้ากับเธอมาก'], spots: [['mall', 480, 960, 'all'], ['cafe', 960, 1140, 'all']] },
    mek:      { name: 'เมฆ',        dateable: true,  skin: '#dca578', hair: '#3a2a1a', shirt: '#4a8a9a', pants: '#3a4030', style: 'mohawk', role: 'mechanic', lines: ['รถคันนี้ซ่อมทั้งวันเลย', 'มือเปื้อน grease แต่ใจสะอาดนะ', 'อยากลองขับรถไฟไหมล่ะ'], spots: [['downtown', 420, 1080, 'all'], ['harbor', 480, 720, 'all']] },
    kim:      { name: 'คิม',        dateable: false, skin: '#f6d5b6', hair: '#3a2a1a', shirt: '#d86a8a', pants: '#f2e0c0', style: 'bun', role: 'tailor', lines: ['ชุดกิโมโนผืนนี้ทอจากไหมแท้', 'ลองให้ฉันวัดตัวไหม', 'สีชมพูอ่อนเหมาะกับงานฤดูใบไม้ผลิ'], spots: [['mall', 420, 1020, 'all']] },
    vlad:     { name: 'วลาด',       dateable: true,  skin: '#c8b0d8', hair: '#241a2a', shirt: '#3a2a44', pants: '#241a2a', style: 'side', role: 'vampire', lines: ['กลางคืนคือเวลาของฉัน', 'กลิ่นเลือด... เอ่อ ลืมไป', 'อย่ากลัวไปเลย ฉันแค่ชอบสีดำ'], spots: [['bar', 1140, 1380, 'all'], ['underground', 1020, 1320, 'all']] },
    mira:     { name: 'มิรา',       dateable: true,  skin: '#c8b0d8', hair: '#7a3aa8', shirt: '#5a4ac8', pants: '#3a2a5e', style: 'wavy', role: 'witch', lines: ['หม้อต้มของฉันเดือดตลอดเวลา', 'อยากเรียนคาถาใหม่ไหม', 'คริสตัลก้อนนั้นเปล่งแสงนะ'], spots: [['underground', 360, 1020, 'all']] },
    luna:     { name: 'ลูน่า',      dateable: true,  skin: '#d2ab72', hair: '#a06a3a', shirt: '#8a6ab0', pants: '#4a3a5e', style: 'long', role: 'beast', lines: ['หางฉันขยับเองตอนดีใจ', 'คืนพระจันทร์เต็มดวงฉันจะตื่นเต้นเป็นพิเศษ', 'ดมกลิ่นอาหารจากตลาดได้เลย'], spots: [['underground', 540, 1140, 'all'], ['park', 900, 1080, 'all']] },
    gob:      { name: 'ก๊อบ',       dateable: false, skin: '#a8d8b8', hair: '#3a5a3a', shirt: '#8a9a4a', pants: '#5a4030', style: 'pixie', role: 'goblin', lines: ['ของวิเศษราคาถูกที่สุดในเมือง!', 'ซื้อสามชิ้นลดอีกนิดนะ', 'อย่าบอกใครนะ ฉันขโมยมาบางส่วน'], spots: [['underground', 300, 1200, 'all']] },
    onyx:     { name: 'โอนิกซ์',    dateable: false, skin: '#8a5a3a', hair: '#241a2a', shirt: '#a81e3a', pants: '#241a2a', style: 'mohawk', role: 'demon', lines: ['ข้ามักจะยืนอยู่ตรงมุมมืด', 'สัญญากับปีศาจไหม? ดอกเบี้ยถูกนะ', 'พลังของเจ้ายังอ่อนนัก'], spots: [['underground', 1200, 1380, 'all']] },
    faye:     { name: 'เฟย์',       dateable: true,  skin: '#c8b0d8', hair: '#7ad8b8', shirt: '#a8e86a', pants: '#c8f0ff', style: 'pixie', role: 'fairy', lines: ['ปีกฉันเล็ก แต่บินได้นะ', 'เกสรดอกไม้คือของหวานที่อร่อยที่สุด', 'กลางคืนสวนสาธารณะสวยมาก'], spots: [['park', 360, 960, 'all'], ['underground', 600, 900, 'all']] },
    hana:     { name: 'ฮานะ',       dateable: true,  skin: '#f6d5b6', hair: '#3a5ac8', shirt: '#6ae0e8', pants: '#2a4a6a', style: 'braids', role: 'mage', lines: ['คาถาไฟต้องเริ่มจากใจที่สงบ', 'ฉันสอบผ่านระดับสามแล้วนะ', 'อยากเป็นจอมเวทที่เก่งที่สุด'], spots: [['university', 480, 960, 'school'], ['underground', 480, 780, 'all']] },
    kla:      { name: 'กล้า',       dateable: true,  skin: '#dca578', hair: '#a06a3a', shirt: '#b8c8d8', pants: '#6a7a8a', style: 'side', role: 'knight', lines: ['เกราะนี้หนัก แต่ใจฉันเบา', 'ฝึกดาบทุกเช้าที่ลานเมือง', 'ข้าจะปกป้องเมืองนี้เอง'], spots: [['underground', 660, 1080, 'all'], ['downtown', 600, 780, 'all']] },
    ploynoi:  { name: 'พลอยน้อย',   dateable: false, skin: '#c8b0d8', hair: '#6ae0e8', shirt: '#2a4a6a', pants: '#4a3a5e', style: 'bob', role: 'crystal_vendor', lines: ['คริสตัลแท้จากเหมืองใต้ดิน', 'เม็ดนี้เปล่งแสงสีฟ้าเวลาโดนน้ำ', 'ขายเม็ดละหนึ่งร้อยยี่สิบนะ'], spots: [['underground', 300, 1260, 'all']] },
    sorn2:    { name: 'ซอร์น',      dateable: false, skin: '#b87a52', hair: '#e8e8e8', shirt: '#5a4ac8', pants: '#3a2a5e', style: 'long', role: 'guildmaster', lines: ['กิลด์ยินดีต้อนรับนักเวทใหม่', 'ค่าสมาชิกสองพัน ใช้ได้ตลอดชีพ', 'บอสประจำเมืองรออยู่ข้างล่าง'], spots: [['underground', 660, 1200, 'all']] },
    tom:      { name: 'ทอม',        dateable: false, skin: '#d9a97a', hair: '#5a3a2a', shirt: '#4a5a6b', pants: '#2a2a34', style: 'short', role: 'trainer', lines: ['รถไฟขบวนต่อไปในห้านาที', 'อย่าลืมแตะบัตรก่อนผ่านประตู', 'สถานีนี้เชื่อมทั้งเมืองเลยนะ'], spots: [['metro_station', 360, 1320, 'all'], ['ranch', 600, 900, 'all']] },
    nid:      { name: 'นิด',         dateable: true,  skin: '#dca578', hair: '#6a3a24', shirt: '#8ac85a', pants: '#5a4a2a', style: 'ponytail', role: 'breeder', lines: ['ไก่ของฉันออกไข่ทุกเช้า', 'วัวตัวนี้อารมณ์ดีมาก', 'ลองเลี้ยงแพะไหม ขายชีสได้ราคาดี'], spots: [['ranch', 360, 1140, 'all']] },
  };

  const ZONE_ACTIVITIES = {
    home: [
      ['sleep', 'เข้านอน'], ['study_desk', 'อ่านหนังสือ'], ['eat_home', 'กินข้าวที่บ้าน ฿120'],
      ['dinner', 'มื้อเย็นครอบครัว'], ['watch_tv', 'ดูทีวี'], ['cook_meal', 'ทำกับข้าว ฿60'],
      ['craft_item', 'ประดิษฐ์ของ'], ['practice_art', 'วาดรูป'], ['cat', 'เล่นกับแมว'],
    ],
    backyard: [['fish', 'ตกปลา'], ['farm_all', 'ดูแลสวนทั้งหมด']],
    home_street: [['collect', 'เก็บของสะสม'], ['bug', 'จับแมลง']],
    school_district: [['collect', 'เก็บของสะสม']],
    downtown: [['collect', 'เก็บของสะสม'], ['bug', 'จับแมลง']],
    park: [['fish', 'ตกปลา'], ['bug', 'จับแมลง'], ['collect', 'เก็บของสะสม'], ['rest_bench', 'นั่งพัก'], ['festival', 'เทศกาล']],
    classroom: [['school', 'เรียน']],
    university: [['lecture', 'เรียนมหาวิทยาลัย']],
    office: [['work', 'ทำงาน']],
    gym: [['gym', 'ออกกำลังกาย']],
    hospital: [['hospital', 'ตรวจสุขภาพ']],
    bank: [['bank', 'ธนาคาร']],
    mall: [['shop_outfit', 'ร้านเสื้อผ้า'], ['shop_furniture', 'ร้านเฟอร์นิเจอร์']],
    store: [['buy_snack', 'ซื้อขนม'], ['buy_food', 'ซื้ออาหาร']],
    cafe: [['eat_cafe', 'กินอาหาร'], ['coffee', 'ดื่มกาแฟ']],
    bar: [['drink', 'สั่งเครื่องดื่ม']],
    neighbor_home: [['sit_rest', 'นั่งเล่น']],
    night_market: [['street_food', 'กินของอร่อย ฿90'], ['buy_gift', 'ซื้อของขวัญ ฿120'], ['busker', 'ฟังดนตรี'], ['collect', 'เก็บของสะสม'], ['bug', 'จับแมลง']],
    harbor: [['fish', 'ตกปลา'], ['boat_trip', 'นั่งเรือ ฿400'], ['collect', 'เก็บของสะสม'], ['bug', 'จับแมลง'], ['rest_bench', 'นั่งพัก']],
    farm_district: [['farm_work', 'รับจ้างเก็บเกี่ยว'], ['fish', 'ตกปลา'], ['collect', 'เก็บของสะสม'], ['bug', 'จับแมลง']],
    ranch: [['livestock', 'ดูแลสัตว์'], ['feed_all', 'ให้อาหารทั้งหมด'], ['pet_care', 'เล่นกับสัตว์เลี้ยง'], ['collect', 'เก็บของสะสม']],
    metro_station: [['metro_ride', 'ขึ้นรถไฟ'], ['metro_card', 'ซื้อบัตรโดยสาร'], ['rest_bench', 'นั่งพัก']],
    underground: [['guild', 'กิลด์นักเวท'], ['magic_shop', 'ร้านเวทมนตร์'], ['crystal', 'เก็บคริสตัล'], ['meditate', 'นั่งสมาธิ'], ['boss', 'ท้าบอส'], ['pet_shop', 'ร้านสัตว์วิเศษ'], ['collect', 'เก็บของสะสม']],
  };

  /* ---------------- สไตล์ตัวละคร / บทบาท ---------------- */
  const OUTFIT_STYLE = {
    casual: 'casual', school: 'student', sleep: 'pajamas', sport: 'sport', cozy: 'cozy',
    raincoat: 'raincoat', work: 'suit', winter: 'winter', thai: 'thai', party: 'party',
    luxury: 'luxury', idol: 'idol', goth: 'goth', punk: 'punk', mage: 'mage',
    knight: 'knight', kimono: 'kimono', crystal: 'crystal',
    heirloom_blue: 'baby', heirloom_rose: 'baby', heirloom_green: 'baby',
  };
  const NPC_ROLE = {
    teacher: 'teacher', doctor: 'doctor', boss: 'boss', pataew: 'shopkeeper', mint: 'barista',
    poom: 'athlete', coach: 'coach', jane: 'nurse', morkae: 'nurse', arn: 'chef', nok: 'scholar',
    banker: 'banker', seller: 'clerk', police: 'police', captain: 'captain', fisher: 'fisher',
    farmhand: 'farmer', sorn: 'gardener', busker: 'musician', vendor: 'vendor', tourist: 'tourist',
    taew: 'tourist', dad: 'office', mom: 'home', grandma: 'elder', grandpa: 'elder',
    gun: 'student', nan: 'student', fah: 'student', khao: 'student', ploy: 'designer',
    tee: 'programmer', wan: 'florist', palee: 'vendor', lungchai: 'elder', lungdoo: 'musician',
    bank: 'banker',
    june: 'idol', ada: 'model', mek: 'mechanic', kim: 'tailor', vlad: 'vampire',
    mira: 'witch', luna: 'beast', gob: 'goblin', onyx: 'demon', faye: 'fairy',
    hana: 'mage', kla: 'knight', ploynoi: 'crystal_vendor', sorn2: 'guildmaster',
    tom: 'trainer', nid: 'breeder',
  };
  const CHILD_TRAITS = [
    { id: 'curious', name: 'ช่างสงสัย', desc: 'เรียนเก่งขึ้น', skill: 'academics' },
    { id: 'artistic', name: 'หัวศิลป์', desc: 'ศิลปะและจินตนาการสูง', skill: 'art' },
    { id: 'active', name: 'ซนและแข็งแรง', desc: 'สุขภาพและกีฬาดี', skill: 'athletics' },
    { id: 'social', name: 'เข้ากับคนง่าย', desc: 'สังคมเก่งและมีความสุขง่าย', skill: 'communication' },
    { id: 'handy', name: 'มือไม้ประณีต', desc: 'งานฝีมือและงานช่างเก่ง', skill: 'craft' },
  ];

  /* ---------------- รถเมล์ / ธุรกิจ ---------------- */
  const BUS_ROUTES = [
    { zone: 'home_street', label: 'ถนนบ้านเรา' },
    { zone: 'night_market', label: 'ตลาดกลางคืน' },
    { zone: 'school_district', label: 'ย่านโรงเรียน' },
    { zone: 'downtown', label: 'ดาวน์ทาวน์' },
    { zone: 'harbor', label: 'ท่าเรือ' },
    { zone: 'park', label: 'สวนสาธารณะ' },
    { zone: 'farm_district', label: 'ทุ่งนา' },
    { zone: 'ranch', label: 'ทุ่งเลี้ยงสัตว์' },
  ];
  // รถไฟใต้ดิน: สถานี → ทางออกบนผิวจริง + เมืองใต้ดิน
  const METRO_ROUTES = [
    { zone: 'metro_station', label: 'สถานีกลาง', spawn: { x: 470, y: 470 } },
    { zone: 'underground', label: 'เมืองใต้ดิน', spawn: { x: 470, y: 470 } },
    { zone: 'downtown', label: 'ดาวน์ทาวน์', spawn: { x: 640, y: 505 } },
    { zone: 'home_street', label: 'ถนนบ้านเรา', spawn: { x: 400, y: 505 } },
    { zone: 'school_district', label: 'ย่านโรงเรียน', spawn: { x: 330, y: 505 } },
    { zone: 'harbor', label: 'ท่าเรือ', spawn: { x: 820, y: 430 } },
    { zone: 'farm_district', label: 'ทุ่งนา', spawn: { x: 880, y: 420 } },
  ];
  const BUSINESS = {
    branchCost: 12000,
    upgradeCosts: [0, 8000, 18000, 35000],
    staffHireCost: 3000,
    staffWage: 180,
    restockCost: 600,
    restockAmount: 30,
    basePrice: 120,
    priceStep: 20,
  };

  /* ---------------- เหตุการณ์ชีวิต ---------------- */
  const EVENTS = [
    { id: 'first_words', text: 'ลูกน้อยเริ่มส่งเสียงอ้อแอ้ พ่อแม่รอฟังคำแรก', max_age: 3,
      options: [
        { label: "พูดคำว่า 'แม่'", effects: { happy: 6, parent_love: 8 } },
        { label: "พูดคำว่า 'พ่อ'", effects: { happy: 4, parent_love: 6 } },
      ] },
    { id: 'kindergarten', text: 'ถึงเวลาเลือกโรงเรียนอนุบาลให้ลูก', min_age: 3, max_age: 5,
      options: [
        { label: 'โรงเรียนเอกชน ฿1,000', cost: 1000, effects: { edu: 2, happy: 3, social: 2 } },
        { label: 'อยู่บ้านกับพ่อแม่', effects: { happy: 4, parent_love: 4 } },
      ] },
    { id: 'bully', text: 'มีเพื่อนร่วมชั้นแกล้งคุณที่โรงเรียน', min_age: 6, max_age: 12,
      options: [
        { label: 'บอกคุณครู', chance: .7,
          success: { text: 'ครูจัดการให้ เพื่อนหยุดแกล้ง', effects: { happy: 4, social: 3, stress: -4 } },
          fail: { text: 'ครูไม่ทันเห็น ยังโดนแกล้งต่อ', effects: { happy: -6, stress: 5 } } },
        { label: 'สู้กลับ', chance: .5,
          success: { text: 'ปกป้องตัวเองได้ เพื่อน ๆ ยอมรับ', effects: { happy: 5, social: 4, stress: 4 } },
          fail: { text: 'เจ็บตัวและโดนทำโทษ', effects: { health: -6, happy: -5, stress: 8 } } },
      ] },
    { id: 'pocket_money', text: 'พ่อแม่ให้เงินค่าขนมเพิ่มขึ้น แต่ต้องช่วยงานบ้าน', min_age: 7, max_age: 15,
      options: [
        { label: 'รับข้อเสนอ ช่วยงานบ้าน', effects: { money: 300, parent_love: 4, energy: -8 } },
        { label: 'ขอใช้เวลาอ่านหนังสือแทน', effects: { edu: 2, academics: 2, energy: -4 } },
      ] },
    { id: 'stray_cat', text: 'มีแมวตัวเล็กเดินตามคุณกลับบ้าน', min_age: 6,
      options: [
        { label: 'เลี้ยงไว้', cost: 200, effects: { happy: 8, stress: -4 }, flag: 'cat' },
        { label: 'ให้อาหารแล้วปล่อยไป', effects: { happy: 3, stress: -2 } },
      ] },
    { id: 'lost_wallet', text: 'คุณเจอกระเป๋าสตางค์ตกอยู่ริมถนน', min_age: 10,
      options: [
        { label: 'ตามหาเจ้าของ', chance: .8,
          success: { text: 'เจ้าของขอบคุณและให้รางวัล', effects: { money: 250, happy: 5, fame: 2 } },
          fail: { text: 'หาเจ้าของไม่เจอ ต้องส่งตำรวจ', effects: { happy: 2 } } },
        { label: 'เก็บไว้เอง', effects: { money: 600, happy: -4, stress: 4 } },
      ] },
    { id: 'exam_week', text: 'สัปดาห์สอบใกล้เข้ามา เพื่อนชวนไปเที่ยว', min_age: 12, max_age: 22,
      options: [
        { label: 'อ่านหนังสือก่อน', effects: { grades: 4, academics: 3, stress: 5, happy: -2 } },
        { label: 'ไปเที่ยวกับเพื่อน', effects: { happy: 7, social: 4, grades: -3 } },
      ] },
    { id: 'overtime', text: 'หัวหน้าขอให้ทำโอทีเพิ่ม tonight', min_age: 18, need_job: true,
      options: [
        { label: 'รับโอที', effects: { money: 900, energy: -18, stress: 10, performance: 8 } },
        { label: 'ปฏิเสธ ขอกลับบ้าน', effects: { happy: 4, stress: -3, performance: -4 } },
      ] },
    { id: 'investment', text: 'เพื่อนร่วมงานชวนลงทุนในร้านเล็ก ๆ ด้วยกัน', min_age: 18, min_money: 1500,
      options: [
        { label: 'ลงทุน ฿1,500', cost: 1500, chance: .55,
          success: { text: 'ร้านไปได้ดี เงินปันผลกลับมาเท่าตัว', effects: { money: 3200, happy: 6, fame: 2 } },
          fail: { text: 'ร้านปิดตัว เงินหายไป', effects: { happy: -8, stress: 8 } } },
        { label: 'ขอคิดดูก่อน', effects: { stress: 3 } },
      ] },
    { id: 'flu', text: 'คุณตื่นมาแล้วรู้สึกไม่สบาย คอแห้งและปวดหัว', min_age: 5,
      options: [
        { label: 'ซื้อMedicine ฿200', cost: 200, effects: { health: 10, energy: 8, sick: false } },
        { label: 'อดทน นอนพัก', chance: .6,
          success: { text: 'พักผ่อนแล้วดีขึ้นเอง', effects: { energy: 10, health: 2 } },
          fail: { text: 'แย่ลง ต้องไปหาหมอ', effects: { health: -10, sick: true } } },
      ] },
    { id: 'old_friend', text: 'เพื่อนเก่าจากโรงเรียนโทรมา ชวนไปกินข้าว', min_age: 15,
      options: [
        { label: 'ไปเจอกัน', cost: 250, effects: { happy: 8, social: 5, stress: -5 } },
        { label: 'ขอโทษ ติดธุระ', effects: { social: -2, stress: 1 } },
      ] },
    { id: 'promotion_offer', text: 'มีบริษัทอื่นเสนอตำแหน่งที่ดีกว่า แต่ต้องเริ่มใหม่', min_age: 20, need_job: true,
      options: [
        { label: 'รับข้อเสนอ', chance: .65,
          success: { text: 'ได้งานใหม่ เงินเดือนขึ้น', effects: { money: 2500, performance: 10, happy: 6 } },
          fail: { text: 'งานใหม่ไม่ใช่ ต้องกลับมาเริ่มใหม่', effects: { performance: -10, stress: 10 } } },
        { label: 'อยู่ที่เดิม', effects: { performance: 4, happy: -2 } },
      ] },
    { id: 'family_dinner_event', text: 'พ่อแม่ชวนกินข้าวเย็นพร้อมหน้า แต่คุณมีงานค้าง', min_age: 18,
      options: [
        { label: 'กลับบ้านกินข้าว', effects: { happy: 7, parent_love: 6, stress: -4, performance: -2 } },
        { label: 'ทำงานต่อ', effects: { performance: 5, energy: -8, parent_love: -4 } },
      ] },
    { id: 'rain_walk', text: 'ฝนตกหนักตอนคุณเดินกลับบ้าน มีร่มคันเดียว', min_age: 8,
      options: [
        { label: 'แบ่งร่มให้คนข้าง ๆ', effects: { social: 4, happy: 4, health: -2 } },
        { label: 'วิ่งกลับบ้านคนเดียว', effects: { health: -5, energy: -5 } },
      ] },
    { id: 'lottery', text: 'เพื่อนชวนซื้อหวยใต้ดิน ใบละ ฿100', min_age: 18,
      options: [
        { label: 'ซื้อ 1 ใบ', cost: 100, chance: .12,
          success: { text: 'ถูกรางวัล!', effects: { money: 5000, happy: 20 } },
          fail: { text: 'ไม่ถูกเลย', effects: { happy: -3 } } },
        { label: 'ไม่เสี่ยงดีกว่า', effects: { happy: 1 } },
      ] },
    { id: 'volunteer', text: 'ชุมชนขออาสาสมัครทำความสะอาดสวนสาธารณะ', min_age: 12,
      options: [
        { label: 'ไปช่วย', effects: { fame: 4, social: 4, happy: 4, energy: -10 } },
        { label: 'พักผ่อนอยู่บ้าน', effects: { energy: 5, happy: 1 } },
      ] },
    { id: 'rent_hike', text: 'เจ้าของห้องแจ้งขึ้นค่าเช่า', min_age: 18,
      options: [
        { label: 'ยอมจ่ายเพิ่ม', effects: { money: -500, stress: 3 } },
        { label: 'ย้ายไปอยู่ถูกกว่า', effects: { money: -800, stress: 6, happy: -2 } },
      ] },
    { id: 'art_contest', text: 'มีประกาศจัดการประกวดวาดภาพในเมือง', min_age: 10,
      options: [
        { label: 'ส่งผลงานเข้าประกวด', chance: .45,
          success: { text: 'ได้รางวัลที่ 1!', effects: { money: 1500, fame: 8, happy: 12 } },
          fail: { text: 'ไม่ได้รางวัล แต่ได้ประสบการณ์', effects: { art: 4, happy: 2 } } },
        { label: 'ข้ามไป', effects: { happy: 0 } },
      ] },
    { id: 'health_check', text: 'ถึงเวลาตรวจสุขภาพประจำปี', min_age: 30,
      options: [
        { label: 'ตรวจ ฿500', cost: 500, effects: { health: 8, stress: -3 } },
        { label: 'ข้ามปีนี้', effects: { health: -3 } },
      ] },
    { id: 'child_school', text: 'ลูกถึงวัยเข้าโรงเรียน ต้องเลือก', min_age: 25, need_child: true,
      options: [
        { label: 'โรงเรียนรัฐใกล้บ้าน', effects: { money: -500, happy: 3 } },
        { label: 'โรงเรียนเอกชน', cost: 3000, effects: { money: -3000, happy: 7, fame: 2 } },
      ] },
  ];

  /* ---------------- สัตว์เลี้ยง / ฟาร์มเลี้ยงสัตว์ / เวทมนตร์ / รถไฟ ---------------- */
  const PETS = [
    { id: 'cat',   name: 'แมวส้ม',        price: 1500, color: '#e8a04a', desc: 'อ้อนเก่ง นอนเก่ง ชอบตามไปทุกที่' },
    { id: 'dog',   name: 'หมาสีน้ำตาล',   price: 1800, color: '#b87a52', desc: 'ซื่อสัตย์ เดินตามตลอด เฝ้าบ้านเก่ง' },
    { id: 'fox',   name: 'จิ้งจอกไฟ',     price: 4500, color: '#e07a2a', fantasy: true, desc: 'สัตว์วิเศษขี้เล่น หางเป็นประกาย' },
    { id: 'slime', name: 'สไลม์',         price: 3200, color: '#7ae8b8', fantasy: true, desc: 'เพื่อนสีเขียวยืดหยุ่น น่ารักผิดปกติ' },
    { id: 'owl',   name: 'นกฮูกดวงจันทร์', price: 5200, color: '#8a8ac8', fantasy: true, desc: 'ฉลาดและเงียบ ชอบคาบของวิเศษมาให้' },
  ];
  const LIVESTOCK = [
    { id: 'chicken', name: 'ไก่',       price: 1500, produce: 'egg',   productName: 'ไข่ไก่', sell: 90,  color: '#f2d05a', desc: 'ออกไข่ทุกวัน กินอาหารไม่เยอะ' },
    { id: 'cow',     name: 'วัว',       price: 4500, produce: 'milk',  productName: 'นมสด',  sell: 200, color: '#e8d8c8', desc: 'ให้นมทุกวัน ถ้าอารมณ์ดีจะได้เพิ่ม' },
    { id: 'sheep',   name: 'แกะ',       price: 3800, produce: 'wool',  productName: 'ขนแกะ', sell: 260, color: '#f2f0e8', desc: 'ขนนุ่มฟู ตัดขายได้ทุกวัน' },
    { id: 'goat',    name: 'แพะภูเขา',  price: 5200, produce: 'cheese', productName: 'ชีส',  sell: 340, color: '#d8c8a8', desc: 'ปีนเก่ง ผลิตชีสหอม ๆ' },
  ];
  const SPELLS = [
    { id: 'heal',   name: 'เวทรักษา',          cost: 20, level: 1, color: '#8ae8a0', desc: 'ฟื้นพลังกาย +12 และพลังงาน +10' },
    { id: 'charm',  name: 'เวทเสน่ห์',          cost: 15, level: 1, color: '#ff9ac8', desc: 'เพิ่มความสัมพันธ์กับคนใกล้ตัว +8' },
    { id: 'bloom',  name: 'เวทเร่งดอกผล',       cost: 25, level: 2, color: '#a8e86a', desc: 'เร่งการเติบโตของแปลงผักทุกแปลง' },
    { id: 'spark',  name: 'เวทประกายคริสตัล',   cost: 30, level: 3, color: '#8ae8f8', desc: 'รวบรวมคริสตัลวิเศษ 2-4 เม็ด' },
    { id: 'shield', name: 'เวทเกราะใจ',         cost: 18, level: 3, color: '#c8a8ff', desc: 'ลดความเครียด -18 และเพิ่มความสุข +4' },
    { id: 'summon', name: 'เวทอัญเชิญเพื่อน',   cost: 35, level: 4, color: '#ffd24a', desc: 'เรียกสัตว์วิเศษมาช่วยฟาร์ม' },
  ];
  const METRO_COST = 25;
  const GUILD_FEE = 2000;
  const CRYSTAL_SELL = 120;
  const EXAM_COOLDOWN_DAYS = 7;

  root.PLData = {
    SKILL_DEFS, SKILL_KEYS, PARENT_TRAITS, KARMA_DEFS, BIRTH_OUTFITS, FURNITURE, CAT_NAMES,
    COLLECTIBLES, COLLECTION_MILESTONES, FESTIVALS, CROPS, FARM_PLOT_COUNT, FISH_TABLE, BUG_TABLE,
    CLUBS, CLUB_LEVEL_POINTS, ACHIEVEMENTS, QUEST_WEEK_COUNT, QUEST_POOL, QUEST_CERTIFICATES,
    LIFE_GOALS, GOAL_TIER_NAMES, LIFE_ENDINGS, JOBS, JOB_WORKPLACES, OUTFITS, OUTFIT_COLORS,
    SKIN_TONES, HAIR_COLORS, HAIR_STYLES, ACCESSORIES, PLAN_SLOTS, PLAN_OPTIONS, PLAN_ADULT_OPTIONS, PLAN_CHILD_OPTIONS,
    SEASONS, SEASON_NAMES, WEEKDAY_NAMES, WEATHER_NAMES, MONTHS, RUMORS, RUMORS_FAME, NAMES_M, NAMES_F,
    ZONES, NPCS, ZONE_ACTIVITIES, BUILDING_LABELS, EVENTS,
    OUTFIT_STYLE, NPC_ROLE, CHILD_TRAITS, BUS_ROUTES, BUSINESS, METRO_ROUTES,
    PETS, LIVESTOCK, SPELLS, METRO_COST, GUILD_FEE, CRYSTAL_SELL, EXAM_COOLDOWN_DAYS,
  };
})(typeof window !== 'undefined' ? window : globalThis);
