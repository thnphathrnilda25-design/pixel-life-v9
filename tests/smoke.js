/* Pixel Life — smoke test (Node)
 * ตรวจว่าระบบหลักทำงานได้โดยไม่ throw และค่าสถานะอยู่ในขอบเขต
 * รัน: node tests/smoke.js
 */
'use strict';
const path = require('path');

const store = new Map();
global.localStorage = {
  getItem: (k) => (store.has(k) ? store.get(k) : null),
  setItem: (k, v) => store.set(k, String(v)),
  removeItem: (k) => store.delete(k),
};

require(path.join(__dirname, '..', 'js', 'data.js'));
require(path.join(__dirname, '..', 'js', 'state.js'));

const D = globalThis.PLData;
const G = globalThis.PLGame;
const S = G.S;

let pass = 0, fail = 0;
const ok = (cond, label, extra) => {
  if (cond) { pass++; }
  else { fail++; console.log(`  ✗ ${label}${extra !== undefined ? ' → ' + JSON.stringify(extra) : ''}`); }
};
const section = (t) => console.log(`\n== ${t} ==`);

/* ---------- creation ---------- */
section('สร้างตัวละคร');
const cfg = {
  name: '테스트', gender: 'หญิง', wealth: 1, trait: 'merchant',
  goal: 'career', outfit: 'heirloom_rose', skin: 'warm', hairColor: 'black', hairStyle: 'long',
};
G.startLife(cfg);
ok(S.created, 'created = true');
ok(S.name === '테스트', 'ชื่อถูกบันทึก');
ok(S.age === 6, 'เริ่มอายุ 6', S.age);
ok(S.money === 500 + 1500 + 2000, 'เงินเริ่มต้นรวม trait พ่อค้า', S.money);
ok(S.karma === 'lucky', 'กรรมพันตาม trait', S.karma);
ok(S.ownedOutfits.includes('heirloom_rose'), 'มีผ้าห่อตัว');
ok(S.quests.length === 3, 'มีเควสต์ 3 อย่าง', S.quests.length);

/* ---------- calendar ---------- */
section('เวลาและปฏิทิน');
S.timeMin = 6 * 60;
G.advance(60);
ok(S.timeMin === 7 * 60, 'advance 60 นาที', S.timeMin);
ok(G.timeString() === '07:00', 'รูปแบบเวลา', G.timeString());
ok(G.dayPhase() === 'เช้า', 'ช่วงเช้า');

/* ---------- plan ---------- */
section('แผนวัน');
S.timeMin = 8 * 60;
ok(G.setPlan('morning', 'school').ok, 'วางแผนเช้า = ไปโรงเรียน');
ok(G.setPlan('afternoon', 'study').ok, 'วางแผนบ่าย = เรียน');
ok(G.setPlan('morning', 'work').ok === false, 'เด็กวางแผนทำงานไม่ได้');
const att = G.attendSchool(85);
ok(att.ok, 'ไปโรงเรียนได้', att.message);
ok(S.schoolAttendedToday, 'ติดธงเรียนแล้ว');
ok(S.edu > 0, 'ความรู้เพิ่ม', S.edu);
ok(S.planState.morning === 'done', 'แผนเช้าถูกทำเครื่องหมายสำเร็จ', S.planState);

/* ---------- farm ---------- */
section('ฟาร์ม');
const c0 = D.CROPS[0];
ok(G.farmPlant(0, c0.id).ok, 'ปลูกผักแปลงแรก');
ok(G.farmPlot(0).crop === c0.id, 'แปลงมีพืช');
ok(!G.farmWater(0).ok === false, 'รดน้ำได้');
ok(G.farmReady(0) === false, 'ยังไม่สุกในวันแรก');
for (let d = 0; d < c0.days; d++) {
  S.timeMin = 19 * 60;
  const r = G.farmWater(0);
  if (!r.ok) { /* รดไปแล้ว */ }
  G.sleepNow(6 * 60);
}
ok(G.farmReady(0), 'พืชสุกหลังผ่านหลายวัน', G.farmPlot(0));
const beforeHarvest = S.money;
ok(G.farmHarvest(0).ok, 'เก็บเกี่ยวได้');
ok(S.money === beforeHarvest + c0.sell, 'ได้เงินตามราคาขาย', S.money - beforeHarvest);
ok(S.farmHarvested >= 1, 'นับจำนวนเก็บเกี่ยว', S.farmHarvested);
ok(S.achievements.first_harvest, 'ปลดล็อกความสำเร็จเก็บเกี่ยวครั้งแรก');

/* ---------- fishing ---------- */
section('ตกปลา');
S.energy = 100;
const fishBefore = S.fishTotal;
ok(G.fish().ok, 'ตกปลาได้');
ok(S.fishTotal === fishBefore + 1, 'นับปลา', S.fishTotal);
const sellFish = G.sellCatch('fish');
ok(sellFish.ok, 'ขายปลาได้', sellFish.message);

/* ---------- economy ---------- */
section('เศรษฐกิจ');
S.money = 10000;
ok(G.deposit(3000).ok, 'ฝากเงิน');
ok(S.bank === 3000, 'เงินในบัญชี', S.bank);
ok(G.withdraw(1000).ok, 'ถอนเงิน');
ok(S.bank === 2000, 'ยอดคงเหลือ', S.bank);
ok(G.borrow(5000).ok, 'กู้เงิน');
ok(S.loan === 5000, 'หนี้', S.loan);
ok(G.repay(2000).ok, 'ชำระหนี้');
ok(S.loan === 3000, 'หนี้คงเหลือ', S.loan);
ok(G.deposit(-5).ok === false, 'ฝากค่าติดลบไม่ได้');

/* ---------- jobs ---------- */
section('อาชีพ');
S.age = 18;
S.timeMin = 9 * 60;
S.weekday = 2;
S.edu = 20;
S.skills.communication = 30;
S.skills.craft = 20;
const apply = G.applyJob('store');
ok(apply.ok, 'สมัครงานร้านสะดวกซื้อ', apply.message);
ok(S.jobId === 'store', 'มีงานแล้ว');
const shift = G.workShift(80);
ok(shift.ok, 'ทำงานได้', shift.message);
ok(S.workedToday, 'ติดธงทำงานแล้ว');
ok(S.planState && typeof S.planState === 'object', 'planState ยังเป็นอ็อบเจกต์');

/* ---------- attributes ---------- */
section('ค่าสถานะ');
['health', 'happy', 'energy', 'hunger', 'stress'].forEach((k) => {
  ok(S[k] >= 0 && S[k] <= 100, `${k} อยู่ใน 0..100`, S[k]);
});
ok(Object.values(S.skills).every((v) => v >= 0 && v <= 100), 'ทักษะอยู่ในช่วง');

/* ---------- NPC ---------- */
section('ความสัมพันธ์');
S.age = 20;
S.timeMin = 16 * 60;
S.zone = 'park';
G.travelTo('park');
const here = G.npcsHere();
ok(Array.isArray(here), 'npcsHere คืน array');
if (here.length) {
  const id = here[0];
  const t = G.talkNpc(id);
  ok(t.ok, 'คุยกับ NPC ได้', t.message);
  ok(!G.talkNpc(id).ok, 'คุยซ้ำในวันเดียวกันไม่ได้');
  S.money = 5000;
  ok(G.giftNpc(id).ok, 'ให้ของขวัญได้');
  ok(G.friendship(id) > 0, 'ความสัมพันธ์เพิ่ม', G.friendship(id));
} else {
  console.log('  (ข้าม: ไม่มี NPC ในย่านนี้ตอน 16:00)');
}

/* ---------- shop ---------- */
section('ร้านค้า');
S.money = 50000;
ok(G.buyFurniture('cozy_lamp').ok, 'ซื้อเฟอร์นิเจอร์');
ok(S.homeItems.includes('cozy_lamp'), 'มีเฟอร์นิเจอร์ในบ้าน');
ok(G.buyOutfit('work').ok, 'ซื้อชุดทำงาน');
ok(G.wearOutfit('work').ok, 'สวมชุดทำงาน');
ok(S.outfit === 'work', 'ชุดที่ใส่อยู่', S.outfit);
ok(G.upgradeHome().ok, 'อัปเกรดบ้าน');
ok(S.homeLevel === 2, 'บ้านระดับ 2', S.homeLevel);

/* ---------- business ---------- */
section('ธุรกิจ');
S.money = 40000;
ok(G.openBusiness().ok, 'เปิดร้าน');
ok(G.restockBusiness().ok, 'เติมสต็อก');
ok(G.runBusiness().ok, 'เปิดร้านขายของ');
ok(S.businessSales > 0, 'มียอดขาย', S.businessSales);
ok(S.achievements.business_owner, 'ความสำเร็จเจ้าของร้าน');

/* ---------- quests ---------- */
section('ภารกิจ');
const doneQ = S.quests.find((q) => q.done && !q.claimed);
if (doneQ) {
  const r = G.claimQuest(doneQ.id);
  ok(r.ok, 'รับรางวัลเควสต์ได้', r.message);
} else {
  ok(true, 'ยังไม่มีเควสต์สำเร็จ (ข้าม)');
}

/* ---------- festival ---------- */
section('เทศกาล');
S.zone = 'park';
S.season = 0; S.seasonDay = 5; S.timeMin = 12 * 60; S.festivalDone = -1;
const f = G.festivalToday();
ok(!!f, 'มีเทศกาลวันนี้', f && f.name);
if (f && f.zone === 'park') {
  const fr = G.attendFestival(90);
  ok(fr.ok, 'ร่วมเทศกาลได้', fr.message);
  ok(S.festivalWins >= 1, 'ชนะเทศกาล', S.festivalWins);
}

/* ---------- family ---------- */
section('ครอบครัว');
S.money = 100000;
S.age = 24;
S.partnerName = 'แนน'; S.partnerId = 'nan'; S.partnerLove = 70; S.married = false;
ok(G.propose().ok, 'ขอแต่งงาน');
ok(S.married, 'แต่งงานแล้ว');
ok(G.honeymoon().ok, 'ฮันนีมูน');
ok(S.honeymoonDone, 'ไปฮันนีมูนแล้ว');
ok(G.haveChild().ok, 'มีลูก');
ok(S.children.length === 1, 'ลูก 1 คน');
ok(S.achievements.parent_proud, 'ความสำเร็จมีลูก');

/* ---------- pets & livestock ---------- */
section('สัตว์เลี้ยงและปศุสัตว์');
S.age = 24;
S.money = 100000;
S.pets = [];
S.livestock = [];
S.produce = {};
const adopt = G.adoptPet('cat');
ok(adopt.ok, 'รับแมวมาเลี้ยง', adopt.message);
ok(S.pets.length === 1, 'มีสัตว์เลี้ยง 1 ตัว', S.pets.length);
ok(G.feedPet(0).ok, 'ให้อาหารสัตว์เลี้ยง');
ok(G.playPet(0).ok, 'เล่นกับสัตว์เลี้ยง');
ok(G.renamePet(0, 'ส้ม').ok, 'ตั้งชื่อสัตว์เลี้ยง');
ok(S.pets[0].name === 'ส้ม', 'ชื่อใหม่ถูกบันทึก', S.pets[0].name);
const buyCow = G.buyLivestock('cow');
ok(buyCow.ok, 'ซื้อวัวเข้าคอก', buyCow.message);
ok(S.livestock.length === 1, 'มีวัว 1 ตัว');
ok(G.feedLivestock(0).ok, 'ให้อาหารวัว');
S.livestock[0].ready = true;
ok(G.collectProduce(0).ok, 'เก็บนมจากวัว');
ok(G.produceCount('milk') >= 1, 'มีนมในตู้', S.produce);
const sellProduce = G.sellProduce();
ok(sellProduce.ok, 'ขายผลิตผลได้', sellProduce.message);

/* ---------- metro ---------- */
section('รถไฟใต้ดิน');
S.money = 100000;
S.metroCard = false;
S.metroTrips = 0;
const buyCard = G.buyMetroCard();
ok(buyCard.ok, 'ซื้อบัตรโดยสาร', buyCard.message);
ok(S.metroCard, 'มีบัตรโดยสาร');
const metro = G.metroTravel('downtown');
ok(metro.ok, 'นั่งรถไฟไปดาวน์ทาวน์', metro.message);
ok(S.zone === 'downtown', 'ย้ายโซนสำเร็จ', S.zone);
ok(S.metroTrips === 1, 'นับเที่ยวรถไฟ', S.metroTrips);
ok(G.metroTravel('downtown').ok === false, 'ไปสถานีเดิมซ้ำไม่ได้');

/* ---------- magic ---------- */
section('เวทมนตร์');
S.money = 100000;
S.magicLevel = 3;
S.magicXp = 0;
S.mana = 100;
S.spells = [];
S.guild = false;
S.bossDay = -1;
const spellBuy = G.buySpell('spark');
ok(spellBuy.ok, 'เรียนคาถา', spellBuy.message);
ok(S.spells.includes('spark'), 'รู้คาถาแล้ว');
const manaBefore = S.mana;
const cast = G.castSpell('spark');
ok(cast.ok, 'ร่ายคาถาได้', cast.message);
ok(S.mana < manaBefore, 'มานาลดลง', S.mana);
ok(G.meditate().ok, 'นั่งสมาธิ');
ok(G.gatherCrystal().ok, 'ขุดคริสตัล');
ok(S.crystals > 0, 'มีคริสตัล', S.crystals);
ok(G.sellCrystals().ok, 'ขายคริสตัล');
const guild = G.joinGuild();
ok(guild === true || (guild && guild.ok), 'เข้าร่วมกิลด์', guild);
ok(S.guild, 'เป็นสมาชิกกิลด์');
S.mana = 100;
const boss = G.challengeBoss();
ok(boss.ok, 'ท้าบอสได้', boss.message);

/* ---------- exam ---------- */
section('สอบเข้ามหาวิทยาลัย');
S.age = 25;
S.edu = 95;
S.skills.academics = 90;
S.examDay = -99;
S.examPassed = false;
S.examCerts = [];
S.money = 100000;
ok(G.examReady(), 'พร้อมสอบ');
const exam = G.takeExam();
ok(exam.ok, 'เข้าสอบได้', exam.message);
ok(S.examScore >= 62, 'คะแนนถึงเกณฑ์', S.examScore);
ok(S.examPassed, 'สอบผ่าน');
ok(S.examCerts.length === 1, 'มีใบรับรอง 1 ใบ', S.examCerts.length);
ok(G.examReady() === false, 'ต้องรอคูลดาวน์ก่อนสอบซ้ำ');

/* ---------- save / load ---------- */
section('เซฟและโหลด');
G.save();
const snapshot = { day: S.day, money: S.money, name: S.name, job: S.jobId };
ok(G.load(), 'โหลดเซฟได้');
ok(S.day === snapshot.day, 'วันตรงกัน', S.day);
ok(S.money === snapshot.money, 'เงินตรงกัน', S.money);
ok(S.name === snapshot.name, 'ชื่อตรงกัน');
ok(S.jobId === snapshot.job, 'อาชีพตรงกัน');

/* ---------- long run ---------- */
section('เล่นยาว 120 วัน');
let errors = 0;
for (let i = 0; i < 120; i++) {
  try {
    S.timeMin = 7 * 60;
    if (G.isChild()) {
      if (G.isSchoolDay()) G.attendSchool(60 + (i % 40));
    } else if (S.jobId && G.isWorkday() && G.workBlockReason() === '') {
      G.workShift(50 + (i % 50));
    }
    S.timeMin = 19 * 60;
    const r = G.sleepNow(6 * 60);
    if (r.notes) {
      r.notes.forEach((n) => {
        if (typeof n !== 'string') { errors++; console.log('  note ไม่ใช่ string:', n); }
      });
    }
    if (S.age < 18) S.age++;
    if (S.money < 0) { errors++; console.log('  เงินติดลบ!', S.money); }
  } catch (e) {
    errors++;
    console.log('  ✗ วันที่', S.day, 'error:', e.message);
    if (errors > 3) break;
  }
}
ok(errors === 0, 'เล่น 120 วันโดยไม่ error', errors);
ok(S.day > 120, 'วันเดินหน้า', S.day);
ok(S.alive !== undefined, 'สถานะชีวิตมีค่า');

console.log(`\n──────────────\nผ่าน ${pass} • ไม่ผ่าน ${fail}`);
process.exit(fail ? 1 : 0);
