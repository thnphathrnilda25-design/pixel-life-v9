/* Pixel Life · state.js
 * ตรรกะเกมทั้งหมด (เวลา/ความต้องการ/แผนวัน/อาชีพ/เงิน/ฟาร์ม/ความสัมพันธ์/เซฟ)
 */
(function (root) {
  'use strict';
  const D = root.PLData;
  const SAVE_KEY = 'pixel-life-save-v12';
  const LEGACY_KEYS = ['pixel-life-save-v11'];
  const VERSION = 12;

  const clamp = (v, a = 0, b = 100) => Math.max(a, Math.min(b, Math.round(v)));
  const rnd = (n) => Math.floor(Math.random() * n);
  const pick = (arr) => arr[rnd(arr.length)];
  const fmt = (n) => Math.round(n).toLocaleString('en-US');

  const COST = {
    gym: 80, snack: 60, homeMeal: 120, bus: 15, busChild: 8, gift: 150, date: 300,
    study: 800, eat: 250, social: 400, ring: 5000, child: 3000,
    rent: 2800, util: 700, phone: 300, transport: 800, insurance: 700,
    perChild: 700, childSchool: 300, childTeen: 400, shared: 800,
    wage: 450, medicine: 200, doctor: 800, checkup: 500,
    course: 600, party: 1000, honeymoon: 6000, outing: 700, catFeed: 60, catToy: 450,
    businessOpen: 12000, businessRestock: 600, train: 300,
    petFood: 80, livestockFeed: 60, metro: 25, metroCard: 500, exam: 500,
  };

  const S = {};
  const Game = { S, COST, VERSION, listeners: [] };

  /* ---------- helpers ---------- */
  Game.on = (fn) => Game.listeners.push(fn);
  Game.emit = (type, data) => { Game.listeners.forEach((f) => { try { f(type, data); } catch (e) { console.error(e); } }); };
  Game.fmt = fmt;
  Game.clamp = clamp;
  Game.rnd = rnd;
  Game.pick = pick;

  function baseState() {
    return {
      v: VERSION, created: false, name: '', gender: 'หญิง', wealth: 1, trait: 'kind', karma: 'warm',
      goal: 'family', outfit: 'casual', ownedOutfits: ['casual', 'school', 'sleep'],
      skin: 'warm', hairColor: 'black', hairStyle: 'long',
      age: 6, day: 1, weekday: 1, season: 0, seasonDay: 1, timeMin: 6 * 60, weather: 'sun', daysPlayed: 0,
      money: 500, bank: 0, loan: 0, insurance: false,
      health: 85, happy: 75, energy: 90, hunger: 80, stress: 10,
      edu: 0, social: 20, fitness: 30, fame: 0,
      skills: { communication: 0, academics: 0, craft: 0, cooking: 0, art: 0, athletics: 0, tech: 0 },
      alive: true, deathCause: '', sick: false, illness: '',
      jobId: '', jobLevel: 1, jobWeeks: 0, performance: 50, retired: false, lastSalary: 0,
      workedToday: false, workAbsences: 0, jobShifts: 0, taxPaid: 0,
      grades: 50, schoolAbsences: 0, schoolAttendedToday: false, schoolDays: 0, graduated: false,
      parentLove: 70, partnerName: '', partnerLove: 0, married: false, children: [],
      friendships: {}, talkedToday: {}, giftedToday: {}, parentTalked: {},
      farmHarvested: 0, partyCount: 0, honeymoonDone: false, collectedDay: {},
      dayPlan: {}, planState: {}, planStreak: 0, planBest: 0, planDoneTotal: 0, planMissTotal: 0,
      pendingEvent: null, eventDay: -1,
      log: [],
      homeLevel: 1, homeItems: ['bed_double', 'desk_set', 'kitchen', 'sofa'], homeLayout: {}, petName: '', petHappy: 0, catFeedDay: -1,
      collections: {}, collectionMilestone: 0,
      festivalWins: 0, festivalDone: -1, boothDay: -1, boothPlays: 0,
      questWeek: 0, quests: [], questCounts: {}, questTotalDone: 0, questCertificates: [],
      achievements: {}, achievementClaimed: {},
      farm: Array.from({ length: D.FARM_PLOT_COUNT }, () => ({ crop: '', growth: 0, watered: false })),
      fishCatches: {}, bugCatches: {}, fishTotal: 0, bugTotal: 0, fishActions: 0, bugActions: 0,
      businessLevel: 0, businessName: 'ร้านเล็ก ๆ ของฉัน', businessStock: 0, businessDay: -1, businessSales: 0,
      businessStaff: 0, businessPrice: 120, businessBranches: [],
      clubId: '', clubLevel: 1, clubPoints: 0, clubDay: -1, courseDay: -1,
      dinnerDay: -1, benchDay: -1, restDay: -1, rumor: '', lotteryDay: -1,
      zone: 'home', pos: { x: 470, y: 430 }, timePaused: true,
      noticed: {},
      traits: {},
      childTalk: {}, boatTrips: 0, marketGifts: 0,
      // ---- v12: สัตว์เลี้ยง / ฟาร์มปศุสัตว์ / เวทมนตร์ / รถไฟ / สอบ ----
      accessory: 'none',
      pets: [], livestock: [], produce: {},
      mana: 60, manaMax: 100, magicXp: 0, magicLevel: 1, spells: ['heal'],
      crystals: 0, crystalDay: -1, magicDay: -1,
      guild: false, guildDay: -1, bossDay: -1, bossWins: 0,
      examDay: -99, examScore: 0, examPassed: false, examCerts: [],
      metroCard: false, metroTrips: 0,
    };
  }

  Game.state = () => S;
  Game.reset = () => { Object.keys(S).forEach((k) => delete S[k]); Object.assign(S, baseState()); };

  /* ---------- derived ---------- */
  Game.isChild = () => S.age < 18;
  Game.isSchoolDay = () => S.weekday <= 5;
  Game.isWorkday = () => S.weekday <= 5;
  Game.zoneName = (id) => (D.ZONES[id] || {}).name || 'ที่ไหนสักแห่ง';
  Game.seasonName = () => D.SEASON_NAMES[S.season];
  Game.weatherName = () => D.WEATHER_NAMES[S.weather] || '';
  Game.weekdayName = () => D.WEEKDAY_NAMES[(S.weekday - 1) % 7];
  Game.timeString = () => { const m = S.timeMin % 1440; return `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`; };
  Game.dayPhase = () => S.timeMin < 12 * 60 ? 'เช้า' : S.timeMin < 18 * 60 ? 'บ่าย' : S.timeMin < 22 * 60 ? 'เย็น' : 'กลางคืน';
  Game.jobData = () => D.JOBS.find((j) => j.id === S.jobId) || null;
  Game.jobTitle = () => (Game.jobData() || {}).title || (S.retired ? 'เกษียณแล้ว' : 'ว่างงาน');
  Game.salary = () => {
    const j = Game.jobData();
    if (!j) return 0;
    return Math.round(j.salary * (1 + (S.jobLevel - 1) * 0.35) * (S.performance >= 80 ? 1.1 : 1));
  };
  Game.monthlyIncome = () => {
    let v = Game.salary();
    if (S.businessLevel > 0) v += S.businessLevel * 1800;
    return v;
  };
  Game.livingCost = () => {
    let v = COST.rent + COST.util + COST.phone + COST.transport + (S.insurance ? COST.insurance : 0);
    v += Math.max(0, S.homeLevel - 1) * 450;
    v += S.children.length * COST.perChild;
    return Math.round(v);
  };
  Game.netWorth = () => S.money + S.bank - S.loan;
  Game.friendshipOf = (id) => (S.friendships && S.friendships[id]) || 0;
  Game.karmaName = () => (D.KARMA_DEFS[S.karma] || {}).name || '';
  Game.educationTitle = () => S.edu >= 85 ? 'ปริญญาเอก' : S.edu >= 70 ? 'ปริญญาโท' : S.edu >= 40 ? 'ปริญญาตรี' : S.edu >= 20 ? 'มัธยมปลาย' : S.edu >= 8 ? 'มัธยมต้น' : 'ประถม';
  Game.homeCozy = () => {
    let v = 4 + (S.homeLevel - 1) * 8;
    S.homeItems.forEach((id) => { const f = D.FURNITURE.find((x) => x.id === id); if (f) v += f.cozy || 0; });
    return v;
  };

  /* ---------- log ---------- */
  Game.logEvent = (text) => {
    if (!text) return;
    S.log.unshift(`วันที่ ${S.day} · ${text}`);
    if (S.log.length > 80) S.log.pop();
  };

  /* ---------- save ---------- */
  Game.save = () => {
    try {
      const data = JSON.parse(JSON.stringify(S));
      data.v = VERSION;
      if (typeof localStorage !== 'undefined') localStorage.setItem(SAVE_KEY, JSON.stringify(data));
      return true;
    } catch (e) { console.warn('save failed', e); return false; }
  };
  Game.load = () => {
    try {
      if (typeof localStorage === 'undefined') return false;
      const keys = [SAVE_KEY].concat(LEGACY_KEYS);
      let raw = null;
      for (const k of keys) { raw = localStorage.getItem(k); if (raw) break; }
      if (!raw) return false;
      const data = JSON.parse(raw);
      if (!data || data.v > VERSION || !data.created) return false;
      const base = baseState();
      Object.keys(base).forEach((k) => { if (data[k] === undefined) data[k] = base[k]; });
      Object.keys(S).forEach((k) => delete S[k]);
      Object.assign(S, data);
      // sanitisations
      if (!Array.isArray(S.farm) || S.farm.length !== D.FARM_PLOT_COUNT) {
        S.farm = Array.from({ length: D.FARM_PLOT_COUNT }, () => ({ crop: '', growth: 0, watered: false }));
      }
      if (!S.skills) S.skills = base.skills;
      D.SKILL_KEYS.forEach((k) => { S.skills[k] = Number(S.skills[k]) || 0; });
      if (!Array.isArray(S.quests)) S.quests = [];
      if (!Array.isArray(S.children)) S.children = [];
      if (!Array.isArray(S.homeItems)) S.homeItems = [];
      if (!S.homeLayout || typeof S.homeLayout !== 'object') S.homeLayout = {};
      if (!Array.isArray(S.businessBranches)) S.businessBranches = [];
      if (!Array.isArray(S.pets)) S.pets = [];
      if (!Array.isArray(S.livestock)) S.livestock = [];
      if (!Array.isArray(S.spells) || !S.spells.length) S.spells = ['heal'];
      if (!Array.isArray(S.examCerts)) S.examCerts = [];
      if (!S.produce || typeof S.produce !== 'object') S.produce = {};
      if (!D.ACCESSORIES.some((a) => a.id === S.accessory)) S.accessory = 'none';
      S.pets = S.pets.filter((p) => p && D.PETS.some((d) => d.id === p.id));
      S.livestock = S.livestock.filter((l) => l && D.LIVESTOCK.some((d) => d.id === l.type));
      S.magicLevel = Math.max(1, Math.min(5, Number(S.magicLevel) || 1));
      S.mana = clamp(Number(S.mana) || 0, 0, Math.max(100, Number(S.manaMax) || 100));
      S.crystals = Math.max(0, Math.round(Number(S.crystals) || 0));
      S.children.forEach((c) => {
        if (c.ageDays === undefined) c.ageDays = (c.age || 0) * 7;
        if (!c.skin) c.skin = S.skin;
        if (!c.hairColor) c.hairColor = S.hairColor;
        if (!c.hairStyle) c.hairStyle = S.hairStyle;
        if (!c.trait) c.trait = 'curious';
        if (c.happy === undefined) c.happy = 72;
        if (c.skill === undefined) c.skill = 0;
      });
      if (!S.pos || typeof S.pos.x !== 'number') S.pos = { x: 470, y: 430 };
      if (!D.ZONES[S.zone]) S.zone = 'home';
      if (!Object.keys(S.homeLayout).length && S.homeItems.length) Game.autoLayoutHome();
      Game.emit('load');
      return true;
    } catch (e) { console.warn('load failed', e); return false; }
  };
  Game.hasSave = () => {
    try { return typeof localStorage !== 'undefined' && [SAVE_KEY].concat(LEGACY_KEYS).some((k) => !!localStorage.getItem(k)); } catch (e) { return false; }
  };
  Game.clearSave = () => { try { [SAVE_KEY].concat(LEGACY_KEYS).forEach((k) => localStorage.removeItem(k)); } catch (e) {} };

  /* ---------- creation ---------- */
  Game.startLife = (cfg) => {
    Game.reset();
    S.created = true;
    S.name = (cfg.name || 'โนเนม').slice(0, 16);
    S.gender = cfg.gender || 'หญิง';
    S.wealth = Number(cfg.wealth) || 0;
    S.skin = cfg.skin || 'warm';
    S.hairColor = cfg.hairColor || 'black';
    S.hairStyle = cfg.hairStyle || (S.gender === 'ชาย' ? 'short' : 'long');
    S.accessory = D.ACCESSORIES.some((a) => a.id === cfg.accessory) ? cfg.accessory : 'none';
    S.goal = cfg.goal || 'family';
    const trait = D.PARENT_TRAITS.find((t) => t.id === cfg.trait) || D.PARENT_TRAITS[0];
    S.trait = trait.id;
    S.karma = trait.karma;
    S.traits = trait;
    const birth = D.BIRTH_OUTFITS.find((o) => o.id === cfg.outfit) || D.BIRTH_OUTFITS[0];
    S.ownedOutfits = ['casual', 'school', 'sleep', birth.id];
    S.outfit = birth.id;
    S.money = 500 + [300, 1500, 6000][S.wealth] + (trait.money || 0);
    S.parentLove = clamp(70 + (trait.parent_love || 0));
    S.happy = clamp(75 + (trait.happy || 0));
    S.health = clamp(85 + (trait.health || 0));
    S.stress = clamp(10 + (trait.stress || 0));
    S.edu = clamp(0 + (trait.academics || 0));
    if (trait.skills) Object.keys(trait.skills).forEach((k) => { S.skills[k] = trait.skills[k]; });
    S.zone = 'home';
    S.pos = { x: 470, y: 430 };
    S.timeMin = 6 * 60;
    Game.autoLayoutHome();
    Game.ensureQuests(true);
    S.log = [`เริ่มชีวิตของ ${S.name} ในวัย 6 ขวบ`];
    Game.save();
    Game.emit('start');
    return { ok: true };
  };

  /* ---------- time / calendar ---------- */
  function clampStats() {
    ['health', 'happy', 'energy', 'hunger', 'stress', 'social', 'fitness', 'fame', 'grades', 'parentLove', 'partnerLove', 'performance'].forEach((k) => {
      if (typeof S[k] === 'number') S[k] = clamp(S[k]);
    });
    S.money = Math.max(0, Math.round(S.money));
    S.bank = Math.max(0, Math.round(S.bank));
    S.skills && D.SKILL_KEYS.forEach((k) => { S.skills[k] = clamp(S.skills[k]); });
  }
  Game.clampStats = clampStats;

  Game.advance = (minutes) => {
    if (!S.alive || minutes <= 0) return;
    for (let i = 0; i < minutes; i++) {
      S.timeMin++;
      if (i % 45 === 44) S.hunger = Math.max(0, S.hunger - 1);
      if (i % 60 === 59) S.energy = Math.max(0, S.energy - 1);
      if (S.weather === 'rain' && !(D.ZONES[S.zone] || {}).indoor && i % 60 === 59) S.happy = Math.max(0, S.happy - 1);
      if (S.timeMin % 60 === 0) {
        if (S.hunger < 25) S.health = Math.max(0, S.health - 1);
        if (S.stress > 80) S.health = Math.max(0, S.health - 1);
        if (S.energy <= 0) { S.health = Math.max(0, S.health - 2); S.stress = clamp(S.stress + 3); }
      }
      if (S.timeMin >= 24 * 60) { Game.passOut(); return; }
      if (S.health <= 0) { Game.die('ร่างกายอ่อนล้าเกินไป'); return; }
    }
    resolvePassedSlots();
    clampStats();
    Game.emit('time');
  };

  Game.passOut = () => {
    const notes = ['😵 หมดสติเพราะดึกเกินไป · ถูกพากลับบ้าน'];
    S.energy = Math.max(0, S.energy - 10);
    S.stress = clamp(S.stress + 8);
    Game.endDay(notes, 4);
    S.timeMin = 7 * 60;
    Game.logEvent('หมดสติหน้าดึก');
    Game.save();
    Game.emit('day');
    return { ok: true, message: notes.join('\n') };
  };

  function resolveSlot(slot, notes) {
    if (S.planState[slot.id]) return;
    const opt = S.dayPlan[slot.id];
    if (!opt) { S.planState[slot.id] = 'empty'; return; }
    S.planState[slot.id] = 'miss';
    S.planMissTotal++;
    S.stress = clamp(S.stress + 6);
    S.happy = clamp(S.happy - 5);
    S.money = Math.max(0, S.money - 50);
    if (opt === 'work' && S.jobId && Game.isWorkday()) S.performance = clamp(S.performance - 4);
    if (opt === 'school') S.grades = clamp(S.grades - 2);
    const msg = `❌ ผิดแผน${slot.name}: ${D.PLAN_OPTIONS[opt].label}`;
    notes.push(msg);
    Game.logEvent(msg);
    Game.emit('plan', msg);
  }

  function resolvePassedSlots(notes = []) {
    D.PLAN_SLOTS.forEach((slot) => { if (S.timeMin >= slot.end) resolveSlot(slot, notes); });
  }
  Game._resolvePassedSlots = resolvePassedSlots;
  Game._resolveSlot = resolveSlot;

  Game.planMark = (tag) => {
    if (!S.created) return;
    const cur = Game.currentSlot();
    const order = D.PLAN_SLOTS.map((s) => s.id);
    let idx = order.indexOf(cur);
    if (idx < 0) idx = 0;
    for (let step = 0; step < 2; step++) {
      const sid = order[(idx + step) % order.length];
      if (S.planState[sid]) continue;
      const opt = S.dayPlan[sid];
      if (!opt) continue;
      const def = D.PLAN_OPTIONS[opt];
      if (!def.tags.includes(tag)) continue;
      S.planState[sid] = 'done';
      S.planDoneTotal++;
      S.happy = clamp(S.happy + 4);
      S.stress = clamp(S.stress - 3);
      S.money += 60;
      const msg = `✅ ตามแผน${D.PLAN_SLOTS.find((s) => s.id === sid).name}: ${def.label} · +฿60`;
      Game.logEvent(msg);
      Game.emit('plan', msg);
      return;
    }
  };

  Game.finishDayPlan = (notes) => {
    D.PLAN_SLOTS.forEach((slot) => resolveSlot(slot, notes));
    let planned = 0, done = 0;
    D.PLAN_SLOTS.forEach((s) => {
      if (S.dayPlan[s.id]) { planned++; if (S.planState[s.id] === 'done') done++; }
    });
    if (planned >= 3 && done >= 3) {
      S.planStreak++; S.planBest = Math.max(S.planBest, S.planStreak);
      S.money += 250; S.fame = clamp(S.fame + 1);
      notes.push(`⭐ ทำครบทุกช่อง! +฿250 · ต่อเนื่อง ${S.planStreak} วัน`);
      Game.logEvent(`ทำแผนครบ 3 ช่อง ต่อเนื่อง ${S.planStreak} วัน`);
      Game.emit('plan', `⭐ ครบ 3 ช่อง! +฿250`);
    } else {
      S.planStreak = 0;
      if (planned > 0) notes.push(`📋 แผนวันนี้สำเร็จ ${done}/${planned} ช่อง`);
    }
  };

  Game.currentSlot = () => {
    for (const s of D.PLAN_SLOTS) if (S.timeMin >= s.start && S.timeMin < s.end) return s.id;
    return 'evening';
  };
  Game.planBlockReason = (slotId, opt) => {
    const slot = D.PLAN_SLOTS.find((s) => s.id === slotId);
    if (!slot) return 'ไม่รู้จักช่วงเวลา';
    if (S.timeMin >= slot.end) return 'ช่วงนี้ผ่านไปแล้ว';
    if (S.planState[slotId]) return 'ช่วงนี้จบแล้ว';
    if (opt === 'work') {
      if (Game.isChild()) return 'ยังไม่ถึงวัยทำงาน';
      if (S.retired) return 'เกษียณแล้ว';
      if (S.sick) return 'ป่วยอยู่ ต้องพัก';
      if (!Game.isWorkday()) return 'วันหยุด';
      if (S.workedToday) return 'วันนี้ทำงานแล้ว';
      if (slot.start >= 17 * 60) return 'เลยเวลางาน (ก่อน 17:00)';
    }
    if (opt === 'school') {
      if (!Game.isChild()) return 'ไม่ใช่นักเรียนแล้ว';
      if (!Game.isSchoolDay()) return 'โรงเรียนปิด';
      if (S.schoolAttendedToday) return 'วันนี้เรียนแล้ว';
      if (slot.start >= 15 * 60) return 'เลยเวลาเรียน (ก่อน 15:00)';
    }
    if (opt === 'exercise' && S.age < 10) return 'อายุ 10 ปีขึ้นไป';
    if (opt === 'study' && S.age < 6) return 'ยังเล็กเกินไป';
    return '';
  };
  Game.setPlan = (slotId, opt) => {
    if (!S.alive) return { ok: false, message: 'เกมจบแล้ว' };
    if (!S.created) return { ok: false, message: 'ยังไม่ได้เริ่มชีวิต' };
    const reason = opt ? Game.planBlockReason(slotId, opt) : (S.planState[slotId] ? 'ช่วงนี้จบแล้ว' : (S.timeMin >= (D.PLAN_SLOTS.find((s) => s.id === slotId) || {}).end ? 'ช่วงนี้ผ่านไปแล้ว' : ''));
    if (reason) return { ok: false, message: reason };
    if (opt) S.dayPlan[slotId] = opt; else delete S.dayPlan[slotId];
    const slot = D.PLAN_SLOTS.find((s) => s.id === slotId);
    const msg = opt ? `วางแผน${slot.name}: ${D.PLAN_OPTIONS[opt].label}` : `ปล่อย${slot.name}ว่าง`;
    S.noticed && (S.noticed.planTutorial = true);
    Game.save(); Game.emit('plan');
    return { ok: true, message: msg };
  };

  Game.endDay = (notes, sleepHours) => {
    if (Game.isSchoolDay() && !S.schoolAttendedToday && Game.isChild() && S.age >= 6) {
      S.schoolAbsences++; S.grades = clamp(S.grades - 2); S.parentLove = clamp(S.parentLove - 1);
      notes.push(`🏫 ขาดเรียน 1 วัน (ขาดแล้ว ${S.schoolAbsences} วัน)`);
      if (S.schoolAbsences === 5) notes.push('⚠️ ครูโทรหาพ่อแม่แล้ว!');
    }
    if (!Game.isChild() && S.jobId && Game.isWorkday() && !S.workedToday && !S.sick) {
      S.workAbsences++; S.performance = clamp(S.performance - 6);
      notes.push(`💼 ไม่ได้ไปทำงาน (ขาด ${S.workAbsences} ครั้ง)`);
      if (S.workAbsences >= 5) {
        notes.push(`❌ ถูกเลิกจ้างเพราะขาดงานบ่อย (${Game.jobTitle()})`);
        S.jobId = ''; S.jobLevel = 1; S.jobWeeks = 0; S.performance = 50;
      }
    }
    if (S.stress >= 90) { S.burnout = true; notes.push('🔥 หมดไฟ (เครียดมาก) · พรุ่งนี้เริ่มด้วยพลังงาน 65'); }
    Game.finishDayPlan(notes);
    advanceCalendar(notes);
    S.schoolAttendedToday = false; S.workedToday = false;
    return notes;
  };

  function advanceCalendar(notes) {
    S.day++; S.daysPlayed++; S.weekday = (S.weekday % 7) + 1; S.seasonDay++;
    if (S.seasonDay > 7) { S.seasonDay = 1; S.season = (S.season + 1) % 4; }
    if ((S.day - 1) % 28 === 0) payBills(notes);
    S.weather = rollWeather();
    farmNewDay();
    magicNewDay();
    ranchNewDay(notes);
    growChildren(notes);
    if (S.season === 0 && S.seasonDay === 1) birthday(notes);
    autoBusinessDay(notes);
    S.fishActions = 0; S.bugActions = 0; S.boothDay = -1; S.boothPlays = 0;
    S.festivalDone = -1;
    S.dinnerDay = -1; S.benchDay = -1; S.restDay = -1;
    S.collectedDay = {};
    ensureQuests();
    checkAchievements();
    if (S.day % 7 === 0) weeklyProgress(notes);
    S.dayPlan = {}; S.planState = {};
    rollDailyEvent();
    notes.push(`🌅 วันที่ ${S.day} · ${Game.weekdayName()} · ${D.SEASON_NAMES[S.season]} วันที่ ${S.seasonDay} · ${Game.weatherName()}`);
  }

  /* ---------- วันเกิด / ลูกโต ---------- */
  function birthday(notes) {
    S.age++;
    notes.push(`🎂 วันเกิด! อายุ ${S.age} ปี`);
    Game.logEvent(`วันเกิดอายุ ${S.age} ปี`);
    if (S.age === 18) {
      S.graduated = true;
      notes.push('🎓 บรรลุนิติภาวะแล้ว! สมัครงานและเรียนมหาวิทยาลัยได้');
    }
    if (S.age === 10) notes.push('🧒 โตขึ้นอีกก้าว — ออกกำลังกายได้แล้ว');
    if (S.age === 65 && !S.retired) {
      S.retired = true;
      notes.push('🎊 เกษียณแล้ว · ได้รับเงินบำนาญทุกเดือน');
    }
    S.happy = clamp(S.happy + 4);
    Game.emit('birthday');
  }

  Game.childStage = (c) => (c.age < 3 ? 'baby' : c.age < 13 ? 'kid' : c.age < 18 ? 'teen' : 'adult');
  Game.childStageName = (c) => ({ baby: 'ทารก', kid: 'เด็ก', teen: 'วัยรุ่น', adult: 'ผู้ใหญ่' })[Game.childStage(c)] || 'เด็ก';
  function growChildren(notes) {
    S.childTalk = S.childTalk || {};
    S.children.forEach((c) => {
      const before = Game.childStage(c);
      c.ageDays = (c.ageDays || 0) + 1;
      c.age = Math.min(60, Math.floor(c.ageDays / 7));
      c.happy = clamp((c.happy === undefined ? 72 : c.happy) + 1);
      c.skill = clamp(c.skill || 0);
      const after = Game.childStage(c);
      if (after !== before) {
        const msg = after === 'baby' ? `👶 ${c.name} เกิดมาแล้ว!`
          : after === 'kid' ? `🧒 ${c.name} เริ่มเดินได้แล้ว (${c.age} ปี)`
          : after === 'teen' ? `🧑 ${c.name} โตเป็นวัยรุ่นแล้ว (${c.age} ปี)`
          : `🎓 ${c.name} โตเป็นผู้ใหญ่แล้ว!`;
        notes.push(msg); Game.logEvent(msg);
        Game.emit('child');
      }
      if (c.age === 18) {
        c.job = c.trait === 'artistic' ? 'นักวาดภาพ' : c.trait === 'active' ? 'นักกีฬา' : c.trait === 'curious' ? 'นักวิจัย' : c.trait === 'social' ? 'พิธีกร' : 'ช่างฝีมือ';
        S.happy = clamp(S.happy + 6);
      }
    });
  }

  Game.talkChild = (i) => {
    const c = S.children[i];
    if (!c) return { ok: false, message: 'ไม่พบลูกคนนี้' };
    const key = `${i}-${S.day}`;
    S.childTalk = S.childTalk || {};
    if (S.childTalk[key]) return { ok: false, message: `วันนี้คุยกับ${c.name}แล้ว` };
    S.childTalk[key] = true;
    const trait = D.CHILD_TRAITS.find((t) => t.id === c.trait) || D.CHILD_TRAITS[0];
    c.happy = clamp((c.happy || 70) + 6);
    c.skill = clamp((c.skill || 0) + 2);
    S.parentLove = clamp(S.parentLove + 2);
    S.happy = clamp(S.happy + 2);
    Game.addSkill('communication', 1);
    Game.addSkill(trait.skill, 1);
    Game.planMark('social');
    Game.advance(15);
    const line = c.age < 3 ? 'กอดแน่น ๆ แล้วยิ้ม' : c.age < 13 ? 'เล่าเรื่องโรงเรียนให้ฟัง' : 'คุยเรื่องอนาคตและความฝัน';
    const msg = `👨‍👩‍👧 คุยกับ${c.name} · ${line} · ใจลูก +6 · ${trait.name}`;
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.playChild = (i) => {
    const c = S.children[i];
    if (!c) return { ok: false, message: 'ไม่พบลูกคนนี้' };
    if (S.energy < 8) return { ok: false, message: 'พลังงานไม่พอ' };
    S.energy = clamp(S.energy - 8);
    c.happy = clamp((c.happy || 70) + 10);
    S.happy = clamp(S.happy + 4); S.stress = clamp(S.stress - 4);
    S.parentLove = clamp(S.parentLove + 1);
    Game.planMark('rest');
    Game.advance(45);
    const msg = `🪁 เล่นกับ${c.name} · ความสุขลูก +10 · เครียด -4`;
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.childGift = (i) => {
    const c = S.children[i];
    if (!c) return { ok: false, message: 'ไม่พบลูกคนนี้' };
    if (S.money < 150) return { ok: false, message: 'เงินไม่พอ ฿150' };
    S.money -= 150;
    c.happy = clamp((c.happy || 70) + 14);
    S.happy = clamp(S.happy + 2);
    Game.advance(10);
    const msg = `🎁 ซื้อของขวัญให้${c.name} · ความสุขลูก +14`;
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.helpChildStudy = (i) => {
    const c = S.children[i];
    if (!c) return { ok: false, message: 'ไม่พบลูกคนนี้' };
    if (c.age < 5) return { ok: false, message: 'ลูกยังเล็กเกินไป' };
    if (S.energy < 10) return { ok: false, message: 'พลังงานไม่พอ' };
    S.energy = clamp(S.energy - 10);
    c.skill = clamp((c.skill || 0) + 4);
    S.edu = clamp(S.edu + 1);
    Game.addSkill('academics', 1);
    Game.planMark('study');
    Game.advance(60);
    const msg = `📚 สอนการบ้าน${c.name} · ทักษะลูก +4 · วิชาการเรา +1`;
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };

  function rollWeather() {
    const r = Math.random();
    if (S.season === 3) return r < .45 ? 'snow' : r < .7 ? 'cloud' : 'sun';
    if (S.season === 1) return r < .55 ? 'sun' : r < .8 ? 'cloud' : 'rain';
    return r < .5 ? 'sun' : r < .75 ? 'cloud' : 'rain';
  }

  function weeklyProgress(notes) {
    // ดอกเบี้ยเงินออม + ดอกเบี้ยหนี้ + ค่าเลี้ยงลูก
    if (S.bank > 0) { const i = Math.round(S.bank * 0.02); S.bank += i; }
    if (S.loan > 0) { const i = Math.round(S.loan * 0.015); S.loan += i; }
    if (S.jobId) {
      S.jobWeeks++;
      if (S.jobWeeks > 0 && S.jobWeeks % 16 === 0 && S.jobLevel < 5 && S.performance >= 65) {
        S.jobLevel++;
        notes.push(`🎉 เลื่อนตำแหน่ง! ตอนนี้เป็น ${Game.jobTitle()} ระดับ ${S.jobLevel}`);
        Game.logEvent('ได้เลื่อนตำแหน่ง');
      }
    }
    if (S.age === 65 && !S.retired) {
      S.retired = true;
      notes.push('🎊 เกษียณแล้ว · ได้รับเงินบำนาญทุกเดือน');
      Game.logEvent('เกษียณอายุ');
    }
    if (S.age >= 65 && S.retired) S.money += Math.round(S.lastSalary * 0.4);
  }

  function payBills(notes) {
    const cost = Game.livingCost();
    let paid = 0;
    if (S.money >= cost) { S.money -= cost; paid = cost; }
    else {
      paid = S.money; const rest = cost - paid; S.money = 0;
      if (S.bank >= rest) { S.bank -= rest; paid += rest; notes.push(`🏦 ใช้เงินออมจ่ายบิล ฿${fmt(rest)}`); }
      else {
        const need = rest - S.bank; S.bank = 0;
        S.loan += Math.round(need * 1.03);
        S.stress = clamp(S.stress + 10);
        notes.push(`⚠️ เงินไม่พอจ่ายบิล ต้องกู้เพิ่ม ฿${fmt(need)}`);
      }
    }
    S.taxPaid += Math.round(paid * 0.05);
    notes.push(`🧾 จ่ายบิลประจำเดือน ฿${fmt(cost)}`);
    Game.logEvent(`จ่ายบิล ฿${fmt(cost)}`);
    if (S.children.length) notes.push(`👨‍👩‍👧 ค่าใช้จ่ายลูก ${S.children.length} คนรวมอยู่ในบิลแล้ว`);
  }

  Game.sleepNow = (wakeMin = 6 * 60) => {
    if (!S.alive) return { ok: false, message: 'เกมจบแล้ว' };
    if (S.timeMin >= 6 * 60 && S.timeMin < 18 * 60) return { ok: false, message: 'ยังไม่ถึงเวลานอน (นอนได้หลัง 18:00)' };
    const wake = Math.min(9 * 60, Math.max(5 * 60, wakeMin));
    let hours = ((wake - S.timeMin + 1440) % 1440) / 60;
    if (hours < 1) hours += 24;
    hours = Math.min(12, hours);
    const notes = [`😴 นอนหลับ ${hours.toFixed(0)} ชั่วโมง`];
    Game.planMark('rest');
    S.energy = 100;
    if (S.burnout) { S.energy = 65; S.burnout = false; notes.push('ยังเพลียจากความเครียด · เริ่มด้วยพลังงาน 65'); }
    S.hunger = clamp(S.hunger - hours * 5);
    S.stress = clamp(S.stress - (hours * 4 + (S.karma === 'grounded' ? 2 : 0)));
    S.health = clamp(S.health + hours / 3);
    if (S.sick && Math.random() < .35) { S.sick = false; S.illness = ''; notes.push('ตื่นมาอาการป่วยดีขึ้นมาก'); }
    Game.endDay(notes, hours);
    S.timeMin = wake; S.alive && (S.zone = 'home');
    S.pos = { x: 470, y: 430 };
    clampStats();
    checkDeath(notes);
    Game.logEvent(`นอนหลับ ${hours.toFixed(0)} ชั่วโมง`);
    Game.save();
    Game.emit('day');
    return { ok: true, message: notes.join('\n'), notes };
  };

  Game.passDay = () => {
    // ปุ่มข้ามวันสำหรับผู้เล่นที่ไม่อยากเดินกลับบ้าน: ถือว่านอนดึก
    return Game.sleepNow(6 * 60);
  };

  function checkDeath(notes) {
    if (S.health <= 0) { die('สุขภาพทรุดโทรม'); notes.push('💀 ชีวิตจบลงแล้ว'); return true; }
    if (S.age >= 60) {
      const risk = (S.age - 60) * 0.004 + (S.health < 40 ? 0.02 : 0);
      if (Math.random() < risk) { die(`จากไปอย่างสงบในวัย ${S.age} ปี`); notes.push('💀 ชีวิตจบลงอย่างสงบ'); return true; }
    }
    return false;
  }
  function die(cause) {
    S.alive = false; S.deathCause = cause;
    Game.logEvent(`ชีวิตจบลง: ${cause}`);
    Game.save();
    Game.emit('death');
  }
  Game.die = die;

  /* ---------- daily event ---------- */
  function rollDailyEvent() {
    S.pendingEvent = null;
    if (!S.alive) return;
    const chance = Game.isChild() ? 0.18 : 0.30;
    if (Math.random() >= chance) return;
    const pool = D.EVENTS.filter((e) => {
      if (e.min_age && S.age < e.min_age) return false;
      if (e.max_age && S.age > e.max_age) return false;
      if (e.min_money && S.money < e.min_money) return false;
      if (e.need_job && !S.jobId) return false;
      if (e.need_child && !S.children.length) return false;
      return true;
    });
    if (!pool.length) return;
    const ev = JSON.parse(JSON.stringify(pick(pool)));
    S.pendingEvent = ev;
    S.eventDay = S.day;
    Game.logEvent(`เหตุการณ์: ${ev.text}`);
    Game.emit('event');
  }
  Game.resolveEvent = (index) => {
    if (!S.pendingEvent) return { ok: false, message: 'ไม่มีเหตุการณ์รออยู่' };
    const opt = S.pendingEvent.options[index];
    if (!opt) return { ok: false, message: 'ไม่พบตัวเลือกนี้' };
    if ((opt.cost || 0) > S.money) return { ok: false, message: `เงินไม่พอ (ต้อง ฿${fmt(opt.cost)})` };
    if (opt.cost) S.money -= opt.cost;
    let effects = opt.effects || {};
    let text = opt.text || opt.label;
    if (opt.chance !== undefined) {
      if (Math.random() < opt.chance) { effects = (opt.success || {}).effects || {}; text = (opt.success || {}).text || text; }
      else { effects = (opt.fail || {}).effects || {}; text = (opt.fail || {}).text || text; }
    }
    applyEffects(effects);
    if (opt.flag === 'cat' && !S.petName) { S.petName = pick(D.CAT_NAMES); S.petHappy = 60; if (!S.homeItems.includes('cat_bed')) S.homeItems.push('cat_bed'); }
    S.pendingEvent = null;
    checkDeath([text]);
    clampStats();
    Game.logEvent(text);
    Game.save(); Game.emit('event');
    return { ok: true, message: text };
  };

  function applyEffects(e) {
    Object.keys(e || {}).forEach((k) => {
      const v = e[k];
      if (k === 'money') S.money += v;
      else if (k === 'bank') S.bank += v;
      else if (k === 'sick') S.sick = !!v;
      else if (k === 'health' || k === 'happy' || k === 'energy' || k === 'hunger' || k === 'stress' ||
               k === 'social' || k === 'fame' || k === 'grades' || k === 'parent_love' || k === 'performance' || k === 'edu') {
        const key = k === 'parent_love' ? 'parentLove' : k;
        if (typeof S[key] === 'number') S[key] = clamp(S[key] + v, key === 'edu' ? 0 : 0, key === 'edu' ? 100 : 100);
      } else if (D.SKILL_KEYS.includes(k)) {
        S.skills[k] = clamp(S.skills[k] + v);
      }
    });
    clampStats();
  }
  Game.applyEffects = applyEffects;

  /* ---------- skills ---------- */
  Game.addSkill = (key, amount) => {
    if (!D.SKILL_KEYS.includes(key)) return;
    let amt = amount;
    if (S.karma === 'dreamer' && key === 'art') amt += 1;
    S.skills[key] = clamp(S.skills[key] + amt);
  };
  Game.trainSkill = (key) => {
    if (S.money < COST.train) return { ok: false, message: `เงินไม่พอ (ต้อง ฿${fmt(COST.train)})` };
    if (S.energy < 15) return { ok: false, message: 'พลังงานไม่พอพักผ่อนก่อน' };
    S.money -= COST.train; S.energy = clamp(S.energy - 12); S.stress = clamp(S.stress + 2);
    Game.addSkill(key, 3);
    const msg = `ฝึก${D.SKILL_DEFS[key].name} +3 · ใช้ ฿${fmt(COST.train)} · 60 นาที`;
    Game.advance(60); S.lastMessage = msg; Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };

  /* ---------- economy ---------- */
  Game.deposit = (amount) => {
    amount = Math.floor(Number(amount));
    if (!amount || amount <= 0) return { ok: false, message: 'จำนวนเงินไม่ถูกต้อง' };
    if (amount > S.money) return { ok: false, message: 'เงินสดไม่พอ' };
    S.money -= amount; S.bank += amount;
    Game.save(); Game.emit('change');
    return { ok: true, message: `ฝากเงิน ฿${fmt(amount)} เข้าธนาคาร` };
  };
  Game.withdraw = (amount) => {
    amount = Math.floor(Number(amount));
    if (!amount || amount <= 0) return { ok: false, message: 'จำนวนเงินไม่ถูกต้อง' };
    if (amount > S.bank) return { ok: false, message: 'เงินในบัญชีไม่พอ' };
    S.bank -= amount; S.money += amount;
    Game.save(); Game.emit('change');
    return { ok: true, message: `ถอนเงิน ฿${fmt(amount)}` };
  };
  Game.borrow = (amount) => {
    amount = Math.floor(Number(amount));
    if (!amount || amount <= 0) return { ok: false, message: 'จำนวนเงินไม่ถูกต้อง' };
    if (S.loan + amount > 60000) return { ok: false, message: 'วงเงินกู้ไม่พอ (สูงสุด ฿60,000)' };
    if (!Game.isWorkday() && !S.jobId) return { ok: false, message: 'ยังไม่มีรายได้ให้ธนาคารเชื่อถือ' };
    S.loan += amount; S.money += amount; S.stress = clamp(S.stress + 2);
    Game.save(); Game.emit('change');
    return { ok: true, message: `กู้เงิน ฿${fmt(amount)} (ดอกเบี้ย 1.5%/สัปดาห์)` };
  };
  Game.repay = (amount) => {
    amount = Math.floor(Number(amount));
    if (!amount || amount <= 0) return { ok: false, message: 'จำนวนเงินไม่ถูกต้อง' };
    if (!S.loan) return { ok: false, message: 'ไม่มีหนี้ค้าง' };
    amount = Math.min(amount, S.loan);
    if (S.money < amount) return { ok: false, message: 'เงินสดไม่พอ' };
    S.money -= amount; S.loan -= amount;
    Game.save(); Game.emit('change');
    return { ok: true, message: `ชำระหนี้ ฿${fmt(amount)}` };
  };
  Game.buyInsurance = () => {
    if (S.insurance) return { ok: false, message: 'มีประกันอยู่แล้ว' };
    if (S.money < 3000) return { ok: false, message: 'ต้องจ่ายเบี้ยแรก ฿3,000' };
    S.money -= 3000; S.insurance = true; S.happy = clamp(S.happy + 2);
    Game.save(); Game.emit('change');
    return { ok: true, message: 'ทำประกันสุขภาพแล้ว · ค่ารักษาถูกลงครึ่งหนึ่ง' };
  };

  /* ---------- jobs ---------- */
  Game.jobEligible = (job) => S.age >= 18 && S.edu >= job.edu && S.skills[job.skill] >= job.skill_req && (S.skills.communication >= 5 || job.skill_req === 0 || true);
  Game.applyJob = (id) => {
    const job = D.JOBS.find((j) => j.id === id);
    if (!job) return { ok: false, message: 'ไม่พบอาชีพนี้' };
    if (Game.isChild()) return { ok: false, message: 'ต้องอายุ 18 ก่อน' };
    if (S.edu < job.edu) return { ok: false, message: `ต้องมีความรู้ขั้นต่ำ ${job.edu}` };
    if (S.skills[job.skill] < job.skill_req) return { ok: false, message: `ต้องมี${D.SKILL_DEFS[job.skill].name} ${job.skill_req}` };
    if (S.jobId === id) return { ok: false, message: 'ทำงานนี้อยู่แล้ว' };
    if (S.jobId) return { ok: false, message: 'ลาออกจากงานเดิมก่อน (เมนูงาน)' };
    S.jobId = id; S.jobLevel = 1; S.jobWeeks = 0; S.performance = 55; S.workAbsences = 0;
    S.happy = clamp(S.happy + 5);
    const msg = `สมัครงานสำเร็จ: ${job.title} · เงินเดือน ฿${fmt(job.salary)}/เดือน`;
    Game.logEvent(msg); Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.quitJob = () => {
    if (!S.jobId) return { ok: false, message: 'ไม่มีงานให้ลาออก' };
    const t = Game.jobTitle();
    S.jobId = ''; S.jobLevel = 1; S.jobWeeks = 0; S.performance = 50;
    const msg = `ลาออกจาก ${t}`;
    Game.logEvent(msg); Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.workBlockReason = () => {
    if (!S.alive) return 'เกมจบแล้ว';
    if (Game.isChild()) return 'ยังไม่ถึงวัยทำงาน';
    if (S.retired) return 'เกษียณแล้ว';
    if (S.sick) return 'ป่วยอยู่ ต้องพัก';
    if (!Game.isWorkday()) return 'วันนี้เป็นวันหยุด';
    if (S.timeMin < 8 * 60) return 'เริ่มงาน 08:00';
    if (S.timeMin >= 17 * 60) return 'เลยเวลางานแล้ว';
    if (S.workedToday) return 'วันนี้ทำงานแล้ว';
    if (S.energy < 20) return 'พลังงานไม่พอ ต้องกินหรือพักก่อน';
    return '';
  };
  Game.workShift = (score = 60) => {
    const blocked = Game.workBlockReason();
    if (blocked) return { ok: false, message: blocked };
    Game.planMark('work');
    score = clamp(score);
    const daily = !S.jobId;
    let pay;
    if (daily) pay = Math.round(COST.wage * (0.6 + score / 250));
    else pay = Math.round(Game.salary() / 5 * (0.6 + score / 250));
    S.money += pay;
    S.workedToday = true; S.jobShifts++;
    S.energy = clamp(S.energy - 22); S.stress = clamp(S.stress + 12);
    S.performance = clamp(S.performance + (daily ? Math.round(score / 20) : Math.round(score / 12) - 2));
    if (!daily) {
      S.lastSalary = Game.salary();
      Game.addSkill(Game.jobData().skill, 2);
      Game.addSkill('communication', 1);
    } else { Game.addSkill('communication', 1); Game.addSkill('craft', 1); }
    S.hunger = clamp(S.hunger - 8);
    const notes = [`💼 ${daily ? 'รับจ้างรายวัน' : 'ทำงาน'}: +฿${fmt(pay)} · ประสิทธิภาพ ${S.performance}/100`];
    if (score >= 80) notes.push('หัวหน้าชมว่าทำได้ดีมาก');
    if (S.jobShifts % 5 === 0 && !daily) notes.push('📈 ผ่านงานครบ 5 กะ · มีโอกาสเลื่อนตำแหน่งเร็วขึ้น');
    Game.queueStat('work');
    Game.advance(300);
    S.lastMessage = notes.join('\n');
    Game.logEvent(daily ? 'รับจ้างรายวัน' : `ทำงาน (${S.jobId})`);
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };

  /* ---------- school ---------- */
  Game.schoolBlockReason = () => {
    if (!S.alive) return 'เกมจบแล้ว';
    if (!Game.isChild()) return 'ไม่ใช่นักเรียนแล้ว';
    if (!Game.isSchoolDay()) return 'วันนี้โรงเรียนปิด';
    if (S.timeMin < 8 * 60) return 'โรงเรียนเปิด 08:00';
    if (S.timeMin >= 15 * 60) return 'เลยเวลาเรียนแล้ว';
    if (S.schoolAttendedToday) return 'วันนี้เรียนแล้ว';
    if (S.sick) return 'ป่วยอยู่ ต้องพัก';
    return '';
  };
  Game.attendSchool = (score = 60) => {
    const blocked = Game.schoolBlockReason();
    if (blocked) return { ok: false, message: blocked };
    Game.planMark('school');
    score = clamp(score);
    const gain = 1 + Math.floor(score / 22);
    S.edu = clamp(S.edu + gain);
    let gd = Math.round((score - 45) / 12);
    if (S.karma === 'diligent') gd += 1;
    S.grades = clamp(S.grades + gd);
    Game.addSkill('academics', 2); Game.addSkill('communication', 1); Game.addSkill('art', 1);
    S.social = clamp(S.social + 2); S.energy = clamp(S.energy - 15); S.stress = clamp(S.stress + 5);
    S.happy = clamp(S.happy + (score >= 60 ? 2 : -3));
    S.schoolAttendedToday = true; S.schoolDays++;
    Game.queueStat('school');
    const notes = [`🏫 เรียนวันนี้: ความรู้ +${gain} · เกรด ${S.grades}/100`];
    if (score >= 80) notes.push('ครูชมว่าตั้งใจเรียนมาก');
    else if (score < 35) notes.push('วันนี้เรียนไม่ค่อยรู้เรื่อง');
    const target = Math.min(15 * 60, Math.max(S.timeMin + 240, 12 * 60));
    Game.advance(Math.max(60, target - S.timeMin));
    S.lastMessage = notes.join('\n');
    Game.logEvent(`ไปโรงเรียน (เกรด ${S.grades})`);
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.studyLecture = () => {
    if (S.alive === false) return { ok: false, message: 'เกมจบแล้ว' };
    if (Game.isChild()) return { ok: false, message: 'ยังต้องเรียนมัธยมก่อน' };
    if (S.money < COST.study) return { ok: false, message: `เงินไม่พอค่าเล่าเรียน ฿${fmt(COST.study)}` };
    if (S.energy < 15) return { ok: false, message: 'พลังงานไม่พอ' };
    S.money -= COST.study;
    Game.planMark('study');
    const before = Math.floor(S.edu / 20);
    S.edu = clamp(S.edu + 3);
    Game.addSkill('academics', 3); Game.addSkill(S.goal === 'career' ? 'tech' : 'art', 1);
    S.energy = clamp(S.energy - 12); S.stress = clamp(S.stress + 3); S.happy = clamp(S.happy + 2);
    const notes = ['🎓 เรียนมหาวิทยาลัย: ความรู้ +3 · วิชาการ +3 · ใช้ ฿800'];
    if (Math.floor(S.edu / 20) > before) { notes.push(`จบการศึกษา: ${Game.educationTitle()}`); Game.logEvent('จบการศึกษา'); }
    Game.advance(120);
    S.lastMessage = notes.join('\n'); Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.doHomework = () => {
    if (!Game.isChild()) return { ok: false, message: 'ไม่มีการบ้านแล้ว' };
    if (S.energy < 8) return { ok: false, message: 'พลังงานไม่พอ' };
    Game.planMark('study');
    S.edu = clamp(S.edu + 1); S.grades = clamp(S.grades + 1);
    Game.addSkill('academics', 2); Game.addSkill('art', 1);
    S.energy = clamp(S.energy - 8); S.stress = clamp(S.stress + 3);
    Game.advance(60);
    const msg = '📝 ทำการบ้าน: ความรู้ +1 · เกรด +1 · วิชาการ +2';
    S.lastMessage = msg; Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };

  /* ---------- home actions ---------- */
  function requireHome() {
    if (S.zone !== 'home' && S.zone !== 'backyard' && S.zone !== 'neighbor_home') return 'ต้องอยู่บ้านก่อน';
    return '';
  }
  Game.watchTv = () => {
    if (!S.alive) return { ok: false, message: 'เกมจบแล้ว' };
    Game.planMark('rest');
    S.stress = clamp(S.stress - 7); S.happy = clamp(S.happy + 3); S.energy = clamp(S.energy + 2);
    Game.advance(30);
    S.lastMessage = '📺 ดูทีวีที่บ้าน · เครียด -7 · สุข +3';
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.sitRest = () => {
    if (!S.alive) return { ok: false, message: 'เกมจบแล้ว' };
    Game.planMark('rest');
    S.energy = clamp(S.energy + 8); S.stress = clamp(S.stress - 4); S.happy = clamp(S.happy + 1);
    Game.advance(30);
    S.lastMessage = '🛋️ นั่งพัก · พลังงาน +8 · เครียด -4';
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.eatHome = () => {
    if (S.zone !== 'home') return { ok: false, message: 'ต้องอยู่บ้านก่อน' };
    if (S.money < COST.homeMeal) return { ok: false, message: 'เงินไม่พอ ฿120' };
    S.money -= COST.homeMeal;
    S.hunger = clamp(S.hunger + 30); S.happy = clamp(S.happy + 1);
    Game.advance(30);
    S.lastMessage = '🍚 กินข้าวที่บ้าน · อิ่ม +30 · ฿-120';
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.familyDinner = () => {
    if (S.zone !== 'home') return { ok: false, message: 'ต้องอยู่บ้านก่อน' };
    if (S.timeMin < 18 * 60 || S.timeMin > 21 * 60) return { ok: false, message: 'มื้อเย็นอยู่ช่วง 18:00–21:00' };
    if (S.dinnerDay === S.day) return { ok: false, message: 'วันนี้กินข้าวกับครอบครัวแล้ว' };
    S.dinnerDay = S.day;
    Game.planMark('social');
    S.hunger = clamp(S.hunger + 30); S.happy = clamp(S.happy + 6);
    S.parentLove = clamp(S.parentLove + 3); S.stress = clamp(S.stress - 3);
    Game.advance(45);
    S.lastMessage = '🍚 กินข้าวเย็นกับพ่อแม่ · ความรักพ่อแม่ +3';
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.practiceArt = () => {
    if (!S.homeItems.includes('easel')) return { ok: false, message: 'ต้องซื้อขาตั้งวาดรูปก่อน (ร้านเฟอร์นิเจอร์)' };
    if (S.energy < 10) return { ok: false, message: 'พลังงานไม่พอ' };
    S.stress = clamp(S.stress - 5); S.happy = clamp(S.happy + 3);
    Game.addSkill('art', 2);
    Game.advance(60);
    S.lastMessage = '🎨 วาดรูปที่บ้าน · ศิลปะ +2 · เครียด -5';
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.cookMeal = () => {
    if (!S.homeItems.includes('kitchen')) return { ok: false, message: 'ต้องซื้อครัวไม้ก่อน' };
    if (S.money < 60) return { ok: false, message: 'เงินไม่พอ ฿60' };
    S.money -= 60;
    S.hunger = clamp(S.hunger + 28); S.happy = clamp(S.happy + 3); S.stress = clamp(S.stress - 2);
    Game.addSkill('cooking', 2);
    Game.advance(60);
    S.lastMessage = '🍲 ทำกับข้าวเอง · อิ่ม +28 · ทำอาหาร +2 · ฿-60';
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.craftItem = () => {
    if (S.energy < 10) return { ok: false, message: 'พลังงานไม่พอ' };
    const gain = 40 + S.skills.craft * 6 + rnd(40);
    S.money += gain;
    Game.addSkill('craft', 2); S.stress = clamp(S.stress + 2); S.energy = clamp(S.energy - 8);
    Game.advance(60);
    S.lastMessage = `🔨 ประดิษฐ์ของขายได้ ฿${fmt(gain)} · งานฝีมือ +2`;
    Game.logEvent('ประดิษฐ์ของขาย');
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.playWithCat = () => {
    if (!S.petName) return { ok: false, message: 'ยังไม่มีแมว · ซื้อที่นอนแมวจากร้านเฟอร์นิเจอร์' };
    if (S.catFeedDay !== S.day) { S.catFeedDay = S.day; S.catHappy = clamp(S.catHappy + 12); }
    else S.catHappy = clamp(S.catHappy + 4);
    S.happy = clamp(S.happy + 3); S.stress = clamp(S.stress - 3);
    Game.advance(20);
    S.lastMessage = `🐱 เล่นกับ${S.petName} · ความสุขแมว ${S.catHappy}/100`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.feedCat = () => {
    if (!S.petName) return { ok: false, message: 'ยังไม่มีแมว' };
    if (S.money < COST.catFeed) return { ok: false, message: 'เงินไม่พอ ฿60' };
    S.money -= COST.catFeed; S.catHappy = clamp(S.catHappy + 20);
    S.lastMessage = `🐟 ให้อาหาร${S.petName} · ความสุขแมว +20`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };

  /* ---------- food / cafe / bar ---------- */
  Game.buySnack = () => { if (S.money < COST.snack) return { ok: false, message: 'เงินไม่พอ' }; S.money -= COST.snack; S.hunger = clamp(S.hunger + 12); S.happy = clamp(S.happy + 1); Game.advance(10); S.lastMessage = '🍪 ซื้อขนม/น้ำ · อิ่ม +12'; Game.save(); Game.emit('change'); return { ok: true, message: S.lastMessage }; };
  Game.buyFood = () => { if (S.money < 120) return { ok: false, message: 'เงินไม่พอ' }; S.money -= 120; S.hunger = clamp(S.hunger + 25); Game.advance(20); S.lastMessage = '🍱 ซื้ออาหารกล่อง · อิ่ม +25'; Game.save(); Game.emit('change'); return { ok: true, message: S.lastMessage }; };
  Game.eatCafe = () => { if (S.money < COST.eat) return { ok: false, message: `ต้องมี ฿${fmt(COST.eat)}` }; S.money -= COST.eat; S.hunger = clamp(S.hunger + 35); S.happy = clamp(S.happy + 3); S.stress = clamp(S.stress - 2); Game.advance(40); S.lastMessage = '🍰 กินอาหารที่คาเฟ่ · อิ่ม +35 · สุข +3'; Game.save(); Game.emit('change'); return { ok: true, message: S.lastMessage }; };
  Game.drinkCoffee = () => { if (S.money < 80) return { ok: false, message: 'เงินไม่พอ' }; S.money -= 80; S.energy = clamp(S.energy + 8); S.stress = clamp(S.stress - 2); Game.advance(20); S.lastMessage = '☕ ดื่มกาแฟ · พลังงาน +8'; Game.save(); Game.emit('change'); return { ok: true, message: S.lastMessage }; };
  Game.barDrink = () => {
    if (S.timeMin < 18 * 60) return { ok: false, message: 'บาร์เปิดหลัง 18:00' };
    if (S.money < 150) return { ok: false, message: 'เงินไม่พอ' };
    if (Game.isChild()) return { ok: false, message: 'ยังไม่ถึงวัยดื่ม' };
    S.money -= 150; S.stress = clamp(S.stress - 12); S.happy = clamp(S.happy + 4); S.energy = clamp(S.energy - 5);
    Game.advance(60);
    Game.planMark('social');
    S.lastMessage = '🍹 สั่งเครื่องดื่ม · เครียด -12 · สุข +4';
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.restBench = () => {
    if (S.benchDay === S.day) return { ok: false, message: 'วันนี้นั่งพักม้านั่งแล้ว · เดินเล่นต่อดีกว่า' };
    S.benchDay = S.day; Game.planMark('rest');
    S.stress = clamp(S.stress - 9); S.happy = clamp(S.happy + 3); S.energy = clamp(S.energy + 8);
    Game.advance(25);
    S.lastMessage = '🪑 นั่งพักบนม้านั่ง · เครียด -9 · พลังงาน +8';
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };

  /* ---------- gym / exercise ---------- */
  Game.gym = () => {
    if (Game.isChild() && S.age < 10) return { ok: false, message: 'อายุ 10 ปีขึ้นไป' };
    if (S.money < COST.gym) return { ok: false, message: 'เงินไม่พอ ฿80' };
    if (S.energy < 20) return { ok: false, message: 'พลังงานไม่พอ' };
    S.money -= COST.gym; Game.planMark('exercise');
    const gain = 1 + (S.karma === 'grounded' ? 1 : 0) + (S.skills.athletics > 40 ? 1 : 0);
    S.fitness = clamp(S.fitness + gain + 2); S.health = clamp(S.health + 2);
    S.stress = clamp(S.stress - 8); S.energy = clamp(S.energy - 18);
    Game.addSkill('athletics', 2);
    Game.advance(90);
    S.lastMessage = `🏋️ ออกกำลังกาย · ฟิตเนส +${gain + 2} · เครียด -8`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.runInPark = () => {
    if (S.energy < 15) return { ok: false, message: 'พลังงานไม่พอ' };
    Game.planMark('exercise');
    S.fitness = clamp(S.fitness + 2); S.stress = clamp(S.stress - 5); S.energy = clamp(S.energy - 12);
    Game.addSkill('athletics', 1); S.health = clamp(S.health + 1);
    Game.advance(45);
    S.lastMessage = '🏃 วิ่งเล่นในสวน · ฟิตเนส +2 · เครียด -5';
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };

  /* ---------- hospital ---------- */
  Game.medicine = () => { if (S.money < COST.medicine) return { ok: false, message: 'เงินไม่พอ' }; S.money -= COST.medicine; S.sick = false; S.health = clamp(S.health + 12); S.lastMessage = '💊 ซื้อยา · สุขภาพ +12 · หายป่วย'; Game.save(); Game.emit('change'); return { ok: true, message: S.lastMessage }; };
  Game.checkup = () => { if (S.money < COST.checkup) return { ok: false, message: 'เงินไม่พอ' }; S.money -= COST.checkup; S.health = clamp(S.health + 8); S.stress = clamp(S.stress - 3); S.lastMessage = '🩺 ตรวจสุขภาพ · สุขภาพ +8'; Game.save(); Game.emit('change'); return { ok: true, message: S.lastMessage }; };
  Game.seeDoctor = () => {
    const cost = S.insurance ? Math.round(COST.doctor / 2) : COST.doctor;
    if (S.money < cost) return { ok: false, message: `ต้องมี ฿${fmt(cost)}` };
    S.money -= cost; S.sick = false; S.health = clamp(S.health + 25); S.energy = clamp(S.energy + 10);
    Game.advance(60);
    S.lastMessage = `👨‍⚕️ พบหมอ · สุขภาพ +25 · ฿-${fmt(cost)}`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };

  /* ---------- farm ---------- */
  function farmPlot(i) { return S.farm[i] || { crop: '', growth: 0, watered: false }; }
  Game.farmPlot = farmPlot;
  Game.cropData = (id) => D.CROPS.find((c) => c.id === id) || null;
  Game.farmReady = (i) => {
    const p = farmPlot(i);
    const c = Game.cropData(p.crop);
    return !!(c && p.growth >= c.days);
  };
  Game.farmReadyCount = () => S.farm.filter((p, i) => Game.farmReady(i)).length;
  Game.farmPlant = (i, cropId) => {
    if (!S.alive) return { ok: false, message: 'เกมจบแล้ว' };
    const p = farmPlot(i); if (!p) return { ok: false, message: 'ไม่มีแปลงนี้' };
    if (p.crop) return { ok: false, message: 'แปลงนี้มีพืชอยู่แล้ว' };
    const c = Game.cropData(cropId); if (!c) return { ok: false, message: 'ไม่รู้จักเมล็ดนี้' };
    if (S.money < c.seed) return { ok: false, message: `เงินไม่พอซื้อเมล็ด (฿${fmt(c.seed)})` };
    S.money -= c.seed;
    S.farm[i] = { crop: cropId, growth: 0, watered: false };
    Game.addSkill('cooking', 1); Game.addSkill('craft', 1);
    Game.planMark('farm');
    Game.advance(20);
    S.lastMessage = `🌱 ปลูก${c.name}ในแปลง ${i + 1} · ฿-${fmt(c.seed)} · รดน้ำ ${c.days} วันแล้วเก็บได้`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.farmWater = (i) => {
    const p = farmPlot(i);
    if (!p || !p.crop) return { ok: false, message: 'แปลงนี้ยังว่าง' };
    if (p.watered) return { ok: false, message: 'วันนี้รดน้ำแล้ว' };
    p.watered = true; S.farm[i] = p;
    Game.addSkill('cooking', 1);
    Game.planMark('farm');
    S.lastMessage = `💧 รดน้ำแปลง ${i + 1} แล้ว`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.farmWaterAll = () => {
    let n = 0;
    S.farm.forEach((p, i) => { if (p.crop && !p.watered) { p.watered = true; n++; } });
    if (!n) return { ok: false, message: 'ไม่มีแปลงที่ต้องรดน้ำ' };
    Game.planMark('farm');
    Game.advance(15 * n);
    S.lastMessage = `💧 รดน้ำ ${n} แปลง`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.farmHarvest = (i) => {
    const p = farmPlot(i);
    const c = Game.cropData(p.crop);
    if (!c) return { ok: false, message: 'แปลงนี้ว่าง' };
    if (p.growth < c.days) return { ok: false, message: `ยังไม่สุก (${p.growth}/${c.days} วัน)` };
    S.money += c.sell;
    S.farm[i] = { crop: '', growth: 0, watered: false };
    S.farmHarvested = (S.farmHarvested || 0) + 1;
    Game.addSkill(c.skill, 2);
    S.happy = clamp(S.happy + 2);
    Game.queueStat('harvest');
    checkAchievements();
    Game.planMark('farm');
    Game.advance(15);
    S.lastMessage = `🌾 เก็บ${c.name}ขายได้ ฿${fmt(c.sell)} · ${D.SKILL_DEFS[c.skill].name} +2`;
    Game.logEvent(`เก็บเกี่ยว${c.name}`);
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  function farmNewDay() {
    S.farm.forEach((p) => {
      if (!p.crop) return;
      if (p.watered) p.growth = Math.min(99, p.growth + 1);
      p.watered = false;
    });
  }

  /* ---------- fishing / bugs ---------- */
  function rollCatch(table) {
    const luck = S.karma === 'lucky' ? 1 : 0;
    const roll = Math.random() * 100 - luck * 8;
    let rarity = 0;
    if (roll < 3) rarity = 3; else if (roll < 12) rarity = 2; else if (roll < 32) rarity = 1;
    const opts = Object.keys(table).filter((k) => table[k].rarity === rarity);
    const key = pick(opts.length ? opts : Object.keys(table));
    return { key, data: table[key] };
  }
  Game.fish = () => {
    if (!S.alive) return { ok: false, message: 'เกมจบแล้ว' };
    if (S.energy < 10) return { ok: false, message: 'พลังงานไม่พอ' };
    if ((S.fishActions || 0) >= 6) return { ok: false, message: 'วันนี้ตกปลาครบ 6 ครั้งแล้ว · พรุ่งนี้มาอีก' };
    S.fishActions = (S.fishActions || 0) + 1;
    S.energy = clamp(S.energy - 8); S.stress = clamp(S.stress - 3); S.happy = clamp(S.happy + 1);
    const { key, data } = rollCatch(D.FISH_TABLE);
    S.fishCatches[key] = (S.fishCatches[key] || 0) + 1;
    S.fishTotal++;
    Game.addSkill('athletics', 1);
    Game.queueStat('fish');
    checkAchievements();
    Game.planMark('farm');
    Game.advance(45);
    S.lastMessage = `🎣 ติด${data.name}! (ขายได้ ฿${fmt(data.value)})`;
    Game.logEvent(`ตกปลาได้${data.name}`);
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.bug = () => {
    if (!S.alive) return { ok: false, message: 'เกมจบแล้ว' };
    if (S.energy < 8) return { ok: false, message: 'พลังงานไม่พอ' };
    if ((S.bugActions || 0) >= 6) return { ok: false, message: 'วันนี้จับแมลงครบ 6 ครั้งแล้ว' };
    S.bugActions = (S.bugActions || 0) + 1;
    S.energy = clamp(S.energy - 6); S.stress = clamp(S.stress - 2); S.happy = clamp(S.happy + 1);
    const { key, data } = rollCatch(D.BUG_TABLE);
    S.bugCatches[key] = (S.bugCatches[key] || 0) + 1;
    S.bugTotal++;
    Game.addSkill('craft', 1);
    Game.queueStat('bug');
    checkAchievements();
    Game.planMark('farm');
    Game.advance(40);
    S.lastMessage = `🦋 จับ${data.name}ได้! (ขายได้ ฿${fmt(data.value)})`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.sellCatch = (kind) => {
    const table = kind === 'fish' ? D.FISH_TABLE : D.BUG_TABLE;
    const bag = kind === 'fish' ? S.fishCatches : S.bugCatches;
    let total = 0, count = 0;
    Object.keys(bag).forEach((k) => { if (table[k]) { total += table[k].value * bag[k]; count += bag[k]; } });
    if (!count) return { ok: false, message: kind === 'fish' ? 'ยังไม่มีปลาให้ขาย' : 'ยังไม่มีแมลงให้ขาย' };
    S.money += total;
    if (kind === 'fish') S.fishCatches = {}; else S.bugCatches = {};
    const msg = `💰 ขาย${kind === 'fish' ? 'ปลา' : 'แมลง'} ${count} ตัว ได้ ฿${fmt(total)}`;
    Game.logEvent(msg); Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };

  /* ---------- collections ---------- */
  Game.collect = () => {
    const zid = S.zone;
    const season = S.season;
    const list = Object.keys(D.COLLECTIBLES).filter((k) => D.COLLECTIBLES[k].season === season && D.COLLECTIBLES[k].zone === zid);
    if (!list.length) return { ok: false, message: 'ฤดูนี้ไม่มีของสะสมในย่านนี้' };
    const key = pick(list);
    S.collectedDay = S.collectedDay || {};
    const dayKey = `${zid}-${S.day}`;
    if (S.collectedDay[dayKey]) return { ok: false, message: 'วันนี้เก็บของสะสมย่านนี้แล้ว' };
    S.collectedDay[dayKey] = true;
    const before = Object.keys(S.collections).length;
    S.collections[key] = (S.collections[key] || 0) + 1;
    const after = Object.keys(S.collections).length;
    Game.queueStat('collect');
    S.happy = clamp(S.happy + 3); S.money += 40;
    Game.advance(10);
    let msg = `✨ เก็บ${D.COLLECTIBLES[key].name}ได้ · +฿40`;
    if (after > before) msg += ` · สะสมแล้ว ${after}/12 ชนิด`;
    if (D.COLLECTION_MILESTONES.includes(after) && after > (S.collectionMilestone || 0)) {
      S.collectionMilestone = after; S.money += 500;
      msg += `\n🏅 ครบ ${after} ชนิด! โบนัส ฿500`;
    }
    checkAchievements();
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };

  /* ---------- NPC ---------- */
  Game.npcSpot = (id) => {
    const npc = D.NPCS[id];
    if (!npc) return null;
    for (const [zone, from, to, days] of npc.spots) {
      if (S.timeMin < from || S.timeMin >= to) continue;
      const isWeekend = S.weekday >= 6;
      if (days === 'school' && isWeekend) continue;
      if (days === 'weekend' && !isWeekend) continue;
      return zone;
    }
    return null;
  };
  Game.npcsHere = () => {
    const zone = S.zone;
    const out = [];
    D.ZONES[zone] && (D.ZONES[zone].npcs || []).forEach((id) => {
      if (Game.npcSpot(id) === zone) out.push(id);
    });
    return out;
  };
  Game.friendship = (id) => (S.friendships && S.friendships[id]) || 0;
  Game.talkNpc = (id) => {
    const npc = D.NPCS[id];
    if (!npc) return { ok: false, message: 'ไม่พบคนคนนี้' };
    S.talkedToday = S.talkedToday || {};
    const key = `${id}-${S.day}`;
    if (S.talkedToday[key]) return { ok: false, message: `วันนี้คุยกับ${npc.name}แล้ว` };
    S.talkedToday[key] = true;
    S.friendships = S.friendships || {};
    let gain = 4 + (S.karma === 'warm' ? 1 : 0);
    S.friendships[id] = clamp((S.friendships[id] || 0) + gain);
    Game.addSkill('communication', 1);
    S.social = clamp(S.social + 1); S.happy = clamp(S.happy + 1);
    Game.queueStat('talk');
    Game.planMark('social');
    Game.advance(10);
    const line = pick(npc.lines);
    const msg = `💬 ${npc.name}: “${line}” · ใจ +${gain}`;
    Game.logEvent(`คุยกับ${npc.name}`);
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.giftNpc = (id) => {
    const npc = D.NPCS[id];
    if (!npc) return { ok: false, message: 'ไม่พบคนคนนี้' };
    if (S.money < COST.gift) return { ok: false, message: 'เงินไม่พอ ฿150' };
    S.friendships = S.friendships || {};
    S.giftedToday = S.giftedToday || {};
    const key = `${id}-${S.day}`;
    if (S.giftedToday[key]) return { ok: false, message: `วันนี้ให้ของ${npc.name}แล้ว` };
    S.giftedToday[key] = true;
    S.money -= COST.gift;
    S.friendships[id] = clamp((S.friendships[id] || 0) + 10);
    Game.planMark('social');
    Game.advance(15);
    S.lastMessage = `🎁 ให้ของขวัญ${npc.name} · ใจ +10`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.dateNpc = (id) => {
    const npc = D.NPCS[id];
    if (!npc) return { ok: false, message: 'ไม่พบคนคนนี้' };
    if (Game.isChild()) return { ok: false, message: 'โตก่อนค่อยเดทนะ' };
    if (!npc.dateable) return { ok: false, message: `${npc.name} ไม่ใช่คนที่เดทได้` };
    if (Game.friendship(id) < 30) return { ok: false, message: 'ใจยังไม่ถึง 30 · คุย/ให้ของก่อน' };
    if (S.money < COST.date) return { ok: false, message: 'เงินไม่พอออกเดท ฿300' };
    if (S.partnerName && S.partnerName !== npc.name) return { ok: false, message: `มีคนรักอยู่แล้ว (${S.partnerName})` };
    S.money -= COST.date;
    Game.planMark('social');
    const chance = 0.35 + Game.friendship(id) / 200 + S.social / 400;
    let msg;
    if (!S.partnerName) {
      if (Math.random() < chance) {
        S.partnerName = npc.name; S.partnerId = id; S.partnerLove = Math.max(30, Game.friendship(id));
        msg = `💕 ${npc.name} ตอบตกลงเป็นคนรักของคุณ!`;
        Game.logEvent(`เป็นคนรักกับ${npc.name}`);
      } else {
        S.happy = clamp(S.happy - 3);
        msg = `💔 ${npc.name} ขอเวลาทำความรู้ใจอีกหน่อย`;
      }
    } else {
      S.partnerLove = clamp(S.partnerLove + 6); S.happy = clamp(S.happy + 5);
      msg = `💞 เดทกับ${npc.name} · ความรัก +6`;
    }
    Game.advance(120);
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.propose = () => {
    if (!S.partnerName) return { ok: false, message: 'ยังไม่มีคนรัก' };
    if (S.married) return { ok: false, message: 'แต่งงานแล้ว' };
    if (Game.isChild()) return { ok: false, message: 'まだเด็กเกินไป' };
    if (S.partnerLove < 60) return { ok: false, message: 'ความรักต้องถึง 60 ก่อน' };
    if (S.money < COST.ring) return { ok: false, message: 'ต้องซื้อแหวน ฿5,000' };
    S.money -= COST.ring; S.married = true; S.happy = clamp(S.happy + 15); S.parentLove = clamp(S.parentLove + 5);
    S.marriedDay = S.day;
    Game.logEvent(`แต่งงานกับ${S.partnerName}`);
    checkAchievements();
    Game.save(); Game.emit('change');
    return { ok: true, message: `💍 แต่งงานกับ${S.partnerName}แล้ว!` };
  };
  Game.honeymoon = () => {
    if (!S.married) return { ok: false, message: 'ต้องแต่งงานก่อน' };
    if (S.honeymoonDone) return { ok: false, message: 'ไปฮันนีมูนแล้ว' };
    if (S.money < COST.honeymoon) return { ok: false, message: 'เงินไม่พอ ฿6,000' };
    S.money -= COST.honeymoon; S.honeymoonDone = true;
    S.happy = clamp(S.happy + 20); S.stress = clamp(S.stress - 20); S.partnerLove = clamp(S.partnerLove + 10);
    Game.advance(240);
    checkAchievements();
    Game.save(); Game.emit('change');
    return { ok: true, message: '🏝️ ฮันนีมูนสุดหวาน · ความสุข +20' };
  };
  function nearestToneId(hex, list) {
    if (!hex || !list || !list.length) return null;
    const target = parseInt(hex.replace('#', ''), 16);
    const tr = (target >> 16) & 255, tg = (target >> 8) & 255, tb = target & 255;
    let best = null, bestD = Infinity;
    list.forEach((t) => {
      const n = parseInt(t.hex.replace('#', ''), 16);
      const dr = ((n >> 16) & 255) - tr, dg = ((n >> 8) & 255) - tg, db = (n & 255) - tb;
      const d = dr * dr + dg * dg + db * db;
      if (d < bestD) { bestD = d; best = t.id; }
    });
    return best;
  }
  Game.haveChild = () => {
    if (!S.partnerName) return { ok: false, message: 'ต้องมีคนรักก่อน' };
    if (Game.isChild()) return { ok: false, message: 'ยังเด็กเกินไป' };
    if (S.children.length >= 2) return { ok: false, message: 'ดูแลลูก 2 คนก็พอแล้ว' };
    if (S.money < COST.child) return { ok: false, message: 'ต้องเตรียม ฿3,000' };
    S.money -= COST.child;
    const names = S.gender === 'หญิง' ? D.NAMES_M : D.NAMES_F;
    const partner = D.NPCS[S.partnerId] || null;
    const skinChoices = [S.skin, nearestToneId(partner && partner.skin, D.SKIN_TONES) || S.skin];
    const hairChoices = [S.hairColor, nearestToneId(partner && partner.hair, D.HAIR_COLORS) || S.hairColor];
    const styleChoices = [S.hairStyle, (partner && partner.style) || S.hairStyle];
    const trait = pick(D.CHILD_TRAITS);
    const child = {
      name: pick(names), age: 0, ageDays: 0, gender: S.gender === 'หญิง' ? 'ชาย' : 'หญิง',
      skin: pick(skinChoices), hairColor: pick(hairChoices), hairStyle: pick(styleChoices),
      trait: trait.id, skill: 0, happy: 75, birthDay: S.day, job: '',
    };
    S.children.push(child);
    S.happy = clamp(S.happy + 18); S.stress = clamp(S.stress + 6);
    Game.advance(240);
    checkAchievements();
    Game.logEvent(`มีลูกคนแรกชื่อ ${child.name} (${trait.name})`);
    Game.save(); Game.emit('change');
    return { ok: true, message: `👶 มีลูกแล้ว! ชื่อ ${child.name} · นิสัย${trait.name}` };
  };
  Game.familyOuting = () => {
    if (!S.children.length && !S.partnerName) return { ok: false, message: 'ยังไม่มีครอบครัวให้พาออกไปเที่ยว' };
    if (S.money < COST.outing) return { ok: false, message: 'เงินไม่พอ ฿700' };
    if (S.outingWeek === Math.floor((S.day - 1) / 7)) return { ok: false, message: 'ออกทริปไปแล้วสัปดาห์นี้' };
    S.outingWeek = Math.floor((S.day - 1) / 7);
    S.money -= COST.outing;
    S.happy = clamp(S.happy + 12); S.stress = clamp(S.stress - 8); S.parentLove = clamp(S.parentLove + 3);
    S.partnerLove = clamp(S.partnerLove + 5);
    Game.advance(180);
    Game.save(); Game.emit('change');
    return { ok: true, message: '🚗 ออกทริปครอบครัว · ความสุข +12' };
  };
  Game.talkParent = (which) => {
    S.parentTalked = S.parentTalked || {};
    const key = `${which}-${S.day}`;
    if (S.parentTalked[key]) return { ok: false, message: 'วันนี้คุยกับท่านแล้ว' };
    S.parentTalked[key] = true;
    S.parentLove = clamp(S.parentLove + 2); Game.addSkill('communication', 1);
    S.happy = clamp(S.happy + 2); S.stress = clamp(S.stress - 1);
    Game.planMark('social');
    Game.advance(15);
    S.lastMessage = `🏠 คุยกับ${which === 'dad' ? 'พ่อ' : 'แม่'} · ความรักพ่อแม่ +2`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };

  /* ---------- shopping ---------- */
  Game.buyOutfit = (id) => {
    const o = D.OUTFITS.find((x) => x.id === id);
    if (!o) return { ok: false, message: 'ไม่พบชุดนี้' };
    if (S.ownedOutfits.includes(id)) return { ok: false, message: 'มีชุดนี้แล้ว' };
    if (S.money < o.price) return { ok: false, message: 'เงินไม่พอ' };
    S.money -= o.price; S.ownedOutfits.push(id);
    Game.save(); Game.emit('change');
    return { ok: true, message: `👗 ซื้อ${o.name}แล้ว` };
  };
  Game.wearOutfit = (id) => {
    if (!S.ownedOutfits.includes(id)) return { ok: false, message: 'ยังไม่ได้เป็นเจ้าของชุดนี้' };
    S.outfit = id; Game.save(); Game.emit('change');
    return { ok: true, message: `สวม${(D.OUTFITS.find((o) => o.id === id) || {}).name}` };
  };
  Game.buyFurniture = (id) => {
    const f = D.FURNITURE.find((x) => x.id === id);
    if (!f) return { ok: false, message: 'ไม่พบเฟอร์นิเจอร์นี้' };
    if (S.homeItems.includes(id)) return { ok: false, message: 'มีชิ้นนี้แล้ว' };
    if (S.money < f.price) return { ok: false, message: 'เงินไม่พอ' };
    S.money -= f.price; S.homeItems.push(id);
    if (f.id === 'cat_bed' && !S.petName) { S.petName = pick(D.CAT_NAMES); S.petHappy = 60; }
    if (f.parent_love) S.parentLove = clamp(S.parentLove + f.parent_love);
    if (f.happy) S.happy = clamp(S.happy + f.happy);
    S.homeLayout = S.homeLayout || {};
    S.homeLayout[id] = Game.freeLayoutSpot();
    Game.save(); Game.emit('change');
    return { ok: true, message: `🪑 ซื้อ${f.name}แล้ว · ความอบอุ่นบ้าน +${f.cozy}` };
  };

  /* ---------- home layout (จัดบ้านลาก/วาง) ---------- */
  Game.HOME_SLOTS = (() => {
    const out = [];
    const cols = 6, rows = 3;
    for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) out.push({ x: 108 + c * 149, y: 402 + r * 56 });
    return out;
  })();
  Game.freeLayoutSpot = () => {
    S.homeLayout = S.homeLayout || {};
    const used = new Set(Object.values(S.homeLayout).map((p) => `${Math.round(p.x)},${Math.round(p.y)}`));
    const free = Game.HOME_SLOTS.find((p) => !used.has(`${p.x},${p.y}`));
    return free ? { x: free.x, y: free.y, rot: 0 } : { x: 190 + rnd(560), y: 380 + rnd(90), rot: 0 };
  };
  Game.placeFurniture = (id, x, y, rot, silent) => {
    if (!S.homeItems.includes(id)) return { ok: false, message: 'ยังไม่ได้เป็นเจ้าของชิ้นนี้' };
    S.homeLayout = S.homeLayout || {};
    const nx = Math.max(46, Math.min(914, Math.round(x)));
    const ny = Math.max(330, Math.min(520, Math.round(y)));
    S.homeLayout[id] = { x: nx, y: ny, rot: Number(rot) || 0 };
    if (!silent) Game.save();
    return { ok: true, message: `วาง${(D.FURNITURE.find((f) => f.id === id) || {}).name || 'เฟอร์นิเจอร์'}แล้ว` };
  };
  Game.clearFurniture = (id) => {
    if (!S.homeLayout || !S.homeLayout[id]) return { ok: false, message: 'ชิ้นนี้ไม่ได้วางอยู่' };
    delete S.homeLayout[id];
    Game.save(); Game.emit('change');
    return { ok: true, message: 'เก็บเฟอร์นิเจอร์ออกจากห้องแล้ว' };
  };
  Game.rotateFurniture = (id) => {
    const p = (S.homeLayout || {})[id];
    if (!p) return { ok: false, message: 'ยังไม่ได้วางชิ้นนี้' };
    p.rot = ((p.rot || 0) + 90) % 360;
    Game.save(); Game.emit('change');
    return { ok: true, message: `หมุนเฟอร์นิเจอร์ ${p.rot}°` };
  };
  Game.autoLayoutHome = () => {
    S.homeLayout = {};
    const slots = Game.HOME_SLOTS;
    const used = new Set();
    // ตำแหน่งที่ดูเป็นธรรมชาติต่อชนิดเฟอร์นิเจอร์ (index ใน HOME_SLOTS)
    const PREF = {
      bed: [0, 1], desk: [2, 3], kitchen: [4, 5], bookshelf: [10, 11],
      sofa: [7, 6], tv: [8, 9], rug: [9, 8], dining: [13, 12],
      easel: [3, 2], lamp: [12, 13], plant: [17, 16], catbed: [16, 17],
      fishtank: [11, 10], clock: [14, 15], picture: [15, 14],
    };
    const put = (id, idx) => {
      const sp = slots[idx];
      S.homeLayout[id] = { x: sp.x, y: sp.y, rot: 0 };
      used.add(idx);
    };
    const rest = [];
    S.homeItems.forEach((id) => {
      const f = D.FURNITURE.find((x) => x.id === id) || {};
      const prefs = PREF[f.type] || [];
      const idx = prefs.find((n) => !used.has(n));
      if (idx !== undefined) put(id, idx); else rest.push(id);
    });
    rest.forEach((id) => {
      const idx = slots.findIndex((_, i) => !used.has(i));
      if (idx >= 0) put(id, idx);
      else S.homeLayout[id] = { x: 190 + rnd(560), y: 380 + rnd(90), rot: 0 };
    });
    Game.save(); Game.emit('change');
    return { ok: true, message: '🪄 จัดบ้านอัตโนมัติแล้ว' };
  };
  Game.layoutList = () => {
    const L = S.homeLayout || {};
    return S.homeItems.filter((id) => L[id]).map((id) => ({
      id, ...L[id], def: D.FURNITURE.find((f) => f.id === id) || { name: id, type: 'generic', cozy: 0 },
    }));
  };
  Game.unplacedItems = () => S.homeItems.filter((id) => !(S.homeLayout || {})[id]);
  const FURN_ACTION = {
    bed: ['sleep', 'เข้านอน (หลัง 18:00)'],
    desk: ['study_desk', 'โต๊ะอ่านหนังสือ'],
    kitchen: ['cook_meal', 'ทำกับข้าวเอง ฿60'],
    table: ['dinner', 'กินข้าวเย็นกับครอบครัว'],
    sofa: ['sit_rest', 'นั่งพักบนโซฟา'],
    tv: ['watch_tv', 'ดูทีวีพักผ่อน'],
    easel: ['practice_art', 'วาดรูปฝึกฝน'],
    catbed: ['cat', 'เล่นกับแมว'],
    bookshelf: ['study_desk', 'อ่านหนังสือจากชั้นวาง'],
    fishtank: ['sit_rest', 'นั่งดูปลาในตู้'],
    clock: [null, ''],
    lamp: [null, ''],
    plant: [null, ''],
    rug: [null, ''],
    picture: [null, ''],
    generic: [null, ''],
  };
  Game.homeProps = () => {
    const list = Game.layoutList();
    return list.map((it) => {
      const act = FURN_ACTION[it.def.type] || [null, ''];
      return {
        type: it.def.type, x: it.x, y: it.y, rot: it.rot || 0,
        index: it.id, action: act[0], label: act[0] ? act[1] : '', own: true,
      };
    });
  };
  Game.homePropAt = (x, y) => {
    const items = Game.layoutList();
    for (let i = items.length - 1; i >= 0; i--) {
      const it = items[i];
      if (Math.abs(x - it.x) < 52 && y > it.y - 62 && y < it.y + 18) return it;
    }
    return null;
  };
  Game.upgradeHome = () => {
    if (S.homeLevel >= 4) return { ok: false, message: 'บ้านเต็มระดับแล้ว' };
    const cost = [0, 6000, 15000, 30000][S.homeLevel];
    if (S.money < cost) return { ok: false, message: `ต้องมี ฿${fmt(cost)}` };
    S.money -= cost; S.homeLevel++;
    S.happy = clamp(S.happy + 8);
    checkAchievements();
    Game.save(); Game.emit('change');
    return { ok: true, message: `🏠 อัปเกรดบ้านเป็นระดับ ${S.homeLevel}` };
  };
  Game.throwParty = () => {
    if (S.money < COST.party) return { ok: false, message: 'เงินไม่พอ ฿1,000' };
    if (S.partyWeek === Math.floor((S.day - 1) / 7)) return { ok: false, message: 'จัดปาร์ตี้แล้วสัปดาห์นี้' };
    S.partyWeek = Math.floor((S.day - 1) / 7);
    S.money -= COST.party; S.partyCount = (S.partyCount || 0) + 1;
    S.happy = clamp(S.happy + 15); S.social = clamp(S.social + 6); S.stress = clamp(S.stress - 10);
    Game.advance(180);
    checkAchievements();
    Game.save(); Game.emit('change');
    return { ok: true, message: `🎉 จัดปาร์ตี้ที่บ้าน · ความสุข +15 (ครั้งที่ ${S.partyCount})` };
  };

  /* ---------- business (หลายสาขา + จ้างพนักงาน) ---------- */
  const BIZ = D.BUSINESS || {
    branchCost: 12000, upgradeCosts: [0, 8000, 18000, 35000],
    staffHireCost: 3000, staffWage: 180, restockCost: 600, restockAmount: 30,
    basePrice: 120, priceStep: 20,
  };
  Game.BUSINESS = BIZ;
  const priceFactor = (price) => Math.max(0.35, Math.min(1.15, 1.45 - price / 260));

  Game.branchCount = () => (S.businessLevel ? 1 : 0) + (S.businessBranches || []).length;
  Game.branchAt = (zoneId) => (S.businessBranches || []).find((b) => b.zone === zoneId) || null;
  Game.businessCapacity = () => 2 + Math.floor((S.businessLevel || 0) / 2);
  Game.openBusiness = () => {
    if (S.businessLevel > 0) return { ok: false, message: 'มีร้านอยู่แล้ว' };
    if (S.money < COST.businessOpen) return { ok: false, message: `ต้องมี ฿${fmt(COST.businessOpen)}` };
    S.money -= COST.businessOpen;
    S.businessLevel = 1; S.businessStock = 30; S.businessDay = -1; S.businessStaff = 0;
    S.businessPrice = BIZ.basePrice;
    checkAchievements();
    Game.save(); Game.emit('change');
    return { ok: true, message: '🏪 เปิดร้านของตัวเองแล้ว! เติมสต็อกแล้วเปิดขายได้เลย' };
  };
  Game.restockBusiness = () => {
    if (!S.businessLevel) return { ok: false, message: 'ยังไม่มีร้าน' };
    if (S.money < BIZ.restockCost) return { ok: false, message: `เงินไม่พอ ฿${fmt(BIZ.restockCost)}` };
    S.money -= BIZ.restockCost;
    S.businessStock += BIZ.restockAmount;
    Game.save(); Game.emit('change');
    return { ok: true, message: `📦 เติมสต็อก +${BIZ.restockAmount} (คงเหลือ ${S.businessStock})` };
  };
  Game.runBusiness = () => {
    if (!S.businessLevel) return { ok: false, message: 'ยังไม่มีร้าน' };
    if (S.businessDay === S.day) return { ok: false, message: 'วันนี้เปิดร้านแล้ว' };
    if (S.businessStock <= 0) return { ok: false, message: 'สต็อกหมด เติมก่อน' };
    if (S.energy < 20) return { ok: false, message: 'พลังงานไม่พอ' };
    S.businessDay = S.day;
    const sold = Math.min(S.businessStock, Math.round((10 + S.businessLevel * 6 + rnd(8)) * priceFactor(S.businessPrice || BIZ.basePrice)));
    const revenue = sold * (S.businessPrice || BIZ.basePrice);
    S.businessStock -= sold;
    S.money += revenue;
    S.businessSales += revenue;
    S.energy = clamp(S.energy - 20); S.stress = clamp(S.stress + 8);
    Game.addSkill('communication', 2);
    Game.queueStat('business');
    Game.planMark('work');
    Game.advance(240);
    checkAchievements();
    S.lastMessage = `🏪 เปิดร้านขายได้ ${sold} ชิ้น · +฿${fmt(revenue)}`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.upgradeBusiness = () => {
    if (!S.businessLevel) return { ok: false, message: 'ยังไม่มีร้าน' };
    if (S.businessLevel >= 4) return { ok: false, message: 'ร้านใหญ่สุดแล้ว' };
    const cost = BIZ.upgradeCosts[S.businessLevel];
    if (S.money < cost) return { ok: false, message: `ต้องมี ฿${fmt(cost)}` };
    S.money -= cost; S.businessLevel++;
    Game.save(); Game.emit('change');
    return { ok: true, message: `🏬 อัปเกรดร้านเป็นระดับ ${S.businessLevel}` };
  };
  Game.hireStaff = () => {
    if (!S.businessLevel) return { ok: false, message: 'ยังไม่มีร้าน' };
    if (S.businessStaff >= 3) return { ok: false, message: 'สาขาหลักจ้างได้สูงสุด 3 คน' };
    if (S.money < BIZ.staffHireCost) return { ok: false, message: `ต้องมี ฿${fmt(BIZ.staffHireCost)}` };
    S.money -= BIZ.staffHireCost; S.businessStaff++;
    Game.save(); Game.emit('change');
    return { ok: true, message: `🧑‍🍳 จ้างพนักงานแล้ว (${S.businessStaff}/3) · ค่าแรง ฿${BIZ.staffWage}/วัน` };
  };
  Game.fireStaff = () => {
    if (!S.businessStaff) return { ok: false, message: 'ไม่มีพนักงานให้เลิกจ้าง' };
    S.businessStaff--;
    Game.save(); Game.emit('change');
    return { ok: true, message: 'เลิกจ้างพนักงาน 1 คน' };
  };
  Game.setBusinessPrice = (delta) => {
    if (!S.businessLevel) return { ok: false, message: 'ยังไม่มีร้าน' };
    const cur = S.businessPrice || BIZ.basePrice;
    const next = Math.max(60, Math.min(300, cur + delta));
    if (next === cur) return { ok: false, message: 'ปรับราคาไม่ได้แล้ว' };
    S.businessPrice = next;
    Game.save(); Game.emit('change');
    return { ok: true, message: `💰 ตั้งราคาสินค้า ฿${next}/ชิ้น` };
  };
  Game.openBranch = (zoneId) => {
    if (!S.businessLevel) return { ok: false, message: 'เปิดร้านหลักก่อน' };
    if ((S.businessBranches || []).length >= Game.businessCapacity()) return { ok: false, message: `เปิดได้สูงสุด ${Game.businessCapacity()} สาขา (อัปเกรดร้านหลักเพิ่ม)` };
    if (Game.branchAt(zoneId)) return { ok: false, message: 'มีย่านนี้อยู่แล้ว' };
    if (S.money < BIZ.branchCost) return { ok: false, message: `ต้องมี ฿${fmt(BIZ.branchCost)}` };
    S.money -= BIZ.branchCost;
    S.businessBranches = S.businessBranches || [];
    S.businessBranches.push({
      zone: zoneId, name: `สาขา${Game.zoneName(zoneId)}`, level: 1, stock: 24,
      staff: 0, price: BIZ.basePrice, sales: 0, day: -1,
    });
    Game.logEvent(`เปิดสาขา${Game.zoneName(zoneId)}`);
    checkAchievements();
    Game.save(); Game.emit('change');
    return { ok: true, message: `🏬 เปิดสาขา${Game.zoneName(zoneId)}แล้ว!` };
  };
  Game.branchAction = (i, kind) => {
    const b = (S.businessBranches || [])[i];
    if (!b) return { ok: false, message: 'ไม่พบสาขานี้' };
    if (kind === 'restock') {
      if (S.money < BIZ.restockCost) return { ok: false, message: `เงินไม่พอ ฿${fmt(BIZ.restockCost)}` };
      S.money -= BIZ.restockCost; b.stock += BIZ.restockAmount;
      Game.save(); Game.emit('change');
      return { ok: true, message: `📦 เติมสต็อกสาขา +${BIZ.restockAmount} (คงเหลือ ${b.stock})` };
    }
    if (kind === 'hire') {
      if (b.staff >= 3) return { ok: false, message: 'สาขานี้จ้างครบ 3 คนแล้ว' };
      if (S.money < BIZ.staffHireCost) return { ok: false, message: `ต้องมี ฿${fmt(BIZ.staffHireCost)}` };
      S.money -= BIZ.staffHireCost; b.staff++;
      Game.save(); Game.emit('change');
      return { ok: true, message: `🧑‍🍳 จ้างพนักงานสาขา (${b.staff}/3)` };
    }
    if (kind === 'fire') {
      if (!b.staff) return { ok: false, message: 'ไม่มีพนักงาน' };
      b.staff--;
      Game.save(); Game.emit('change');
      return { ok: true, message: 'เลิกจ้างพนักงานสาขา 1 คน' };
    }
    if (kind === 'upgrade') {
      if (b.level >= 4) return { ok: false, message: 'สาขานี้เต็มระดับ' };
      const cost = BIZ.upgradeCosts[b.level];
      if (S.money < cost) return { ok: false, message: `ต้องมี ฿${fmt(cost)}` };
      S.money -= cost; b.level++;
      Game.save(); Game.emit('change');
      return { ok: true, message: `🏬 อัปเกรดสาขาเป็นระดับ ${b.level}` };
    }
    if (kind === 'price-up' || kind === 'price-down') {
      const next = Math.max(60, Math.min(300, b.price + (kind === 'price-up' ? BIZ.priceStep : -BIZ.priceStep)));
      if (next === b.price) return { ok: false, message: 'ปรับราคาไม่ได้แล้ว' };
      b.price = next;
      Game.save(); Game.emit('change');
      return { ok: true, message: `💰 ตั้งราคาสาขา ฿${next}/ชิ้น` };
    }
    if (kind === 'run') {
      if (S.zone !== b.zone) return { ok: false, message: `ต้องไปที่${Game.zoneName(b.zone)}ก่อน` };
      if (b.day === S.day) return { ok: false, message: 'วันนี้เปิดสาขานี้แล้ว' };
      if (b.stock <= 0) return { ok: false, message: 'สต็อกหมด เติมก่อน' };
      if (S.energy < 15) return { ok: false, message: 'พลังงานไม่พอ' };
      b.day = S.day;
      const sold = Math.min(b.stock, Math.round((8 + b.level * 5 + rnd(7)) * priceFactor(b.price)));
      const revenue = sold * b.price;
      b.stock -= sold; b.sales += revenue;
      S.money += revenue; S.businessSales += revenue;
      S.energy = clamp(S.energy - 15); S.stress = clamp(S.stress + 6);
      Game.addSkill('communication', 2);
      Game.queueStat('business');
      Game.planMark('work');
      Game.advance(180);
      Game.save(); Game.emit('change');
      return { ok: true, message: `🏬 สาขา${Game.zoneName(b.zone)} ขายได้ ${sold} ชิ้น · +฿${fmt(revenue)}` };
    }
    return { ok: false, message: 'ไม่รู้จักคำสั่งนี้' };
  };
  Game.autoSales = (level, staff, stock, price) => {
    if (!staff || stock <= 0) return { sold: 0, revenue: 0 };
    const base = staff * 5 + level * 3;
    const sold = Math.min(stock, Math.round(base * priceFactor(price) * (0.8 + Math.random() * 0.45)));
    return { sold, revenue: sold * price };
  };
  function autoBusinessDay(notes) {
    if (!S.businessLevel) return;
    S.businessBranches = S.businessBranches || [];
    let total = 0, wages = 0;
    if (S.businessStaff > 0) {
      const r = Game.autoSales(S.businessLevel, S.businessStaff, S.businessStock, S.businessPrice || BIZ.basePrice);
      S.businessStock -= r.sold; total += r.revenue;
      wages += S.businessStaff * BIZ.staffWage;
    }
    S.businessBranches.forEach((b) => {
      if (b.staff > 0) {
        const r = Game.autoSales(b.level, b.staff, b.stock, b.price);
        b.stock -= r.sold; b.sales += r.revenue; total += r.revenue;
        wages += b.staff * BIZ.staffWage;
      }
    });
    if (total || wages) {
      S.money += total - wages;
      S.businessSales += total;
      notes.push(`🏪 รายได้ร้านอัตโนมัติ +฿${fmt(total)}${wages ? ` · ค่าแรง -฿${fmt(wages)}` : ''}`);
      Game.logEvent(`ร้านขายอัตโนมัติ +฿${fmt(total)}`);
    }
  }

  /* ---------- clubs / courses ---------- */
  Game.joinClub = (id) => {
    const club = D.CLUBS.find((c) => c.id === id);
    if (!club) return { ok: false, message: 'ไม่พบชมรมนี้' };
    if (S.clubId === id) return { ok: false, message: 'อยู่ชมรมนี้แล้ว' };
    if (S.money < club.fee) return { ok: false, message: `ค่าสมาชิก ฿${fmt(club.fee)}` };
    S.money -= club.fee; S.clubId = id; S.clubPoints = 0; S.clubLevel = 1; S.clubDay = -1;
    Game.logEvent(`เข้าชมรม ${club.name}`);
    Game.save(); Game.emit('change');
    return { ok: true, message: `🎭 เข้าร่วม${club.name}แล้ว` };
  };
  Game.quitClub = () => {
    if (!S.clubId) return { ok: false, message: 'ยังไม่ได้เข้าชมรม' };
    const name = (D.CLUBS.find((c) => c.id === S.clubId) || {}).name || 'ชมรม';
    S.clubId = ''; S.clubPoints = 0; S.clubLevel = 1; S.clubDay = -1;
    Game.save(); Game.emit('change');
    return { ok: true, message: `ออกจาก${name}แล้ว` };
  };
  Game.clubActivity = () => {    const club = D.CLUBS.find((c) => c.id === S.clubId);
    if (!club) return { ok: false, message: 'ยังไม่ได้เข้าชมรม' };
    if (S.clubDay === S.day) return { ok: false, message: 'วันนี้ทำกิจกรรมชมรมแล้ว' };
    if (S.energy < 12) return { ok: false, message: 'พลังงานไม่พอ' };
    S.clubDay = S.day;
    S.clubPoints += 5; S.energy = clamp(S.energy - 12); S.stress = clamp(S.stress - 3);
    Game.addSkill(club.skill, 2); S.happy = clamp(S.happy + 3);
    const level = D.CLUB_LEVEL_POINTS.filter((p) => S.clubPoints >= p).length;
    if (level > S.clubLevel) { S.clubLevel = level; Game.logEvent(`ชมรมเลเวล ${level}`); }
    Game.queueStat('club');
    Game.planMark('social');
    Game.advance(90);
    checkAchievements();
    S.lastMessage = `🎭 กิจกรรม${club.name} · ${D.SKILL_DEFS[club.skill].name} +2 · แต้ม ${S.clubPoints}`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };
  Game.takeCourse = () => {
    if (S.age < 10) return { ok: false, message: 'อายุ 10 ปีขึ้นไป' };
    if (S.money < COST.course) return { ok: false, message: 'เงินไม่พอ ฿600' };
    if (S.courseDay === S.day) return { ok: false, message: 'วันนี้เรียนพิเศษแล้ว' };
    S.courseDay = S.day; S.money -= COST.course;
    Game.addSkill('academics', 2);
    const key = S.goal === 'career' ? 'tech' : S.goal === 'legend' ? 'art' : 'communication';
    Game.addSkill(key, 2);
    S.energy = clamp(S.energy - 10); S.stress = clamp(S.stress + 2);
    Game.planMark('study');
    Game.advance(90);
    S.lastMessage = `📚 เรียนพิเศษ · วิชาการ +2 · ${D.SKILL_DEFS[key].name} +2 · ฿-600`;
    Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage };
  };

  /* ---------- festival ---------- */
  Game.festivalToday = () => D.FESTIVALS.find((f) => f.season === S.season && f.day === S.seasonDay) || null;
  Game.attendFestival = (score = 70) => {
    const f = Game.festivalToday();
    if (!f) return { ok: false, message: 'วันนี้ไม่มีเทศกาล' };
    if (S.zone !== f.zone) return { ok: false, message: `เทศกาลอยู่ที่${Game.zoneName(f.zone)}` };
    if (S.festivalDone === S.day) return { ok: false, message: 'วันนี้ร่วมเทศกาลแล้ว' };
    S.festivalDone = S.day;
    score = clamp(score);
    const win = score >= 65;
    const notes = [`🎪 ${f.name}`];
    if (win) {
      const prize = Math.round(f.reward * (0.6 + score / 250));
      S.money += prize; S.festivalWins++;
      S.happy = clamp(S.happy + 15); S.fame = clamp(S.fame + 5);
      notes.push(`🏆 ชนะรางวัล! +฿${fmt(prize)} · ชื่อเสียง +5`);
      Game.logEvent(`ชนะเทศกาล ${f.name}`);
    } else {
      S.happy = clamp(S.happy + 4); S.stress = clamp(S.stress - 4);
      notes.push('สนุกดี แต่ยังไม่ได้รางวัล · ลองใหม่ปีหน้า');
    }
    Game.addSkill('art', 1);
    Game.planMark('social');
    Game.advance(180);
    checkAchievements();
    Game.save(); Game.emit('change');
    return { ok: true, message: notes.join('\n') };
  };
  Game.playBooth = () => {
    if (S.boothDay === S.day && S.boothPlays >= 2) return { ok: false, message: 'วันนี้เล่นบูธครบ 2 ครั้งแล้ว' };
    if (S.money < 50) return { ok: false, message: 'ต้องมี ฿50' };
    S.boothDay = S.day; S.boothPlays = (S.boothPlays || 0) + 1;
    S.money -= 50;
    const win = Math.random() < 0.5;
    if (win) { S.money += 180; S.happy = clamp(S.happy + 4); }
    else S.happy = clamp(S.happy + 1);
    Game.advance(20);
    const msg = win ? '🎯 โยนห่วงเข้าล้มได้รางวัล! +฿180' : '😅 เกือบเข้าล่ะ ลองอีกครั้ง';
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };

  /* ---------- new districts activities ---------- */
  Game.streetFood = () => {
    if (S.zone !== 'night_market') return { ok: false, message: 'ต้องอยู่ที่ตลาดกลางคืน' };
    if (S.money < 90) return { ok: false, message: 'เงินไม่พอ ฿90' };
    S.money -= 90;
    S.hunger = clamp(S.hunger + 38); S.happy = clamp(S.happy + 5); S.stress = clamp(S.stress - 4);
    Game.addSkill('cooking', 1);
    Game.planMark('rest');
    Game.advance(45);
    const msg = '🍜 กินก๋วยเตี๋ยวตลาดกลางคืน · อิ่ม +38 · สุข +5';
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.buyGiftMarket = () => {
    if (S.zone !== 'night_market') return { ok: false, message: 'ต้องอยู่ที่ตลาดกลางคืน' };
    if (S.money < 120) return { ok: false, message: 'เงินไม่พอ ฿120' };
    if (S.marketGiftDay === S.day) return { ok: false, message: 'วันนี้ซื้อของขวัญที่ตลาดแล้ว' };
    S.marketGiftDay = S.day;
    S.money -= 120;
    S.marketGifts = (S.marketGifts || 0) + 1;
    S.happy = clamp(S.happy + 4); S.social = clamp(S.social + 2);
    const here = Game.npcsHere();
    let extra = '';
    if (here.length) {
      const id = pick(here);
      S.friendships = S.friendships || {};
      S.friendships[id] = clamp((S.friendships[id] || 0) + 6);
      extra = ` · ใจ ${D.NPCS[id].name} +6`;
    }
    Game.advance(20);
    const msg = `🎁 ซื้อของขวัญจากตลาด ฿120${extra}`;
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.buskerTip = () => {
    if (S.zone !== 'night_market') return { ok: false, message: 'ต้องอยู่ที่ตลาดกลางคืน' };
    if (S.money < 50) return { ok: false, message: 'ต้องมี ฿50' };
    if (S.buskerDay === S.day) return { ok: false, message: 'วันนี้ฟังดนตรีแล้ว' };
    S.buskerDay = S.day;
    S.money -= 50;
    S.happy = clamp(S.happy + 8); S.stress = clamp(S.stress - 8);
    S.fame = clamp(S.fame + 1);
    Game.addSkill('art', 1); Game.addSkill('communication', 1);
    Game.planMark('social');
    Game.advance(30);
    const msg = '🎸 ฟังดนตรีเปิดหมวก · หยอด ฿50 · สุข +8 · ศิลปะ +1';
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.boatTrip = () => {
    if (S.zone !== 'harbor') return { ok: false, message: 'ต้องอยู่ที่ท่าเรือ' };
    if (S.money < 400) return { ok: false, message: 'ค่าเรือ ฿400' };
    if (S.boatDay === S.day) return { ok: false, message: 'วันนี้ออกเรือแล้ว' };
    S.boatDay = S.day;
    S.money -= 400;
    S.boatTrips = (S.boatTrips || 0) + 1;
    S.happy = clamp(S.happy + 14); S.stress = clamp(S.stress - 16);
    S.energy = clamp(S.energy - 10);
    Game.addSkill('athletics', 1);
    Game.planMark('rest');
    Game.advance(150);
    const msg = '⛵ ออกเรือชมทะเล · สุข +14 · เครียด -16';
    Game.logEvent('นั่งเรือออกทะเล');
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.farmWork = () => {
    if (S.zone !== 'farm_district') return { ok: false, message: 'ต้องอยู่ที่ทุ่งนา' };
    if (S.energy < 20) return { ok: false, message: 'พลังงานไม่พอ' };
    if (S.farmWorkDay === S.day) return { ok: false, message: 'วันนี้รับจ้างแล้ว' };
    S.farmWorkDay = S.day;
    const pay = 240 + rnd(120) + Math.floor(S.skills.athletics * 2);
    S.money += pay;
    S.energy = clamp(S.energy - 25); S.stress = clamp(S.stress + 7);
    S.fitness = clamp(S.fitness + 3);
    Game.addSkill('athletics', 2); Game.addSkill('craft', 1);
    Game.queueStat('work');
    Game.planMark('work');
    Game.advance(180);
    const msg = `🌾 รับจ้างเก็บเกี่ยว · +฿${fmt(pay)} · ฟิตเนส +3`;
    Game.logEvent('รับจ้างที่ทุ่งนา');
    Game.save(); Game.emit('change');
    return { ok: true, message: msg };
  };
  Game.busRoutes = () => D.BUS_ROUTES || [];

  /* ---------- quests / achievements / goals ---------- */
  function ensureQuests(force) {
    const wk = Math.floor((S.day - 1) / 7);
    if (!force && S.questWeek === wk && S.quests.length) return;
    S.questWeek = wk;
    const pool = D.QUEST_POOL.slice();
    const chosen = [];
    const stats = new Set();
    while (chosen.length < D.QUEST_WEEK_COUNT && pool.length) {
      const idx = rnd(pool.length);
      const q = pool[idx];
      if (chosen.length && stats.has(q.stat) && pool.length > D.QUEST_WEEK_COUNT) { const moved = pool.splice(idx, 1)[0]; pool.push(moved); continue; }
      chosen.push(q); stats.add(q.stat); pool.splice(idx, 1);
    }
    S.quests = chosen.map((q) => ({ ...q, done: false, claimed: false }));
    S.questCounts = {};
    Game.save();
  }
  Game.ensureQuests = ensureQuests;
  Game.queueStat = (stat) => {
    S.questCounts[stat] = (S.questCounts[stat] || 0) + 1;
    S.quests.forEach((q) => {
      if (!q.done && q.stat === stat && (S.questCounts[stat] || 0) >= q.target) q.done = true;
    });
  };
  Game.claimQuest = (id) => {
    const q = S.quests.find((x) => x.id === id);
    if (!q) return { ok: false, message: 'ไม่พบภารกิจนี้' };
    if (!q.done) return { ok: false, message: 'ยังทำไม่ครบ' };
    if (q.claimed) return { ok: false, message: 'รับรางวัลแล้ว' };
    q.claimed = true; S.money += q.reward; S.questTotalDone++;
    const msg = `🏅 รับรางวัลภารกิจ “${q.name}” +฿${fmt(q.reward)}`;
    // certificates
    const certs = D.QUEST_CERTIFICATES.filter((c) => S.questTotalDone >= c.need && !S.questCertificates.includes(c.id));
    certs.forEach((c) => { S.questCertificates.push(c.id); S.money += c.reward; Game.logEvent(`ได้${c.name}`); });
    if (certs.length) S.lastMessage = msg + `\n🎖️ ได้${certs.map((c) => c.name).join(', ')}!`;
    checkAchievements(); Game.save(); Game.emit('change');
    return { ok: true, message: S.lastMessage || msg };
  };

  const ACH_CHECK = {
    first_harvest: () => S.farmHarvested >= 1,
    green_thumb: () => S.farmHarvested >= 10,
    first_fish: () => S.fishTotal >= 1,
    master_angler: () => S.fishTotal >= 10,
    bug_hunter: () => S.bugTotal >= 10,
    collector: () => Object.keys(S.collections).length >= 12,
    festival_star: () => S.festivalWins >= 5,
    social_butterfly: () => Object.keys(S.friendships || {}).filter((k) => S.friendships[k] >= 60).length >= 5,
    club_master: () => S.clubLevel >= 3,
    business_owner: () => S.businessLevel >= 1,
    business_tycoon: () => S.businessSales >= 50000,
    home_sweet_home: () => S.homeLevel >= 3,
    party_animal: () => (S.partyCount || 0) >= 3,
    married_life: () => !!S.married,
    honeymooner: () => !!S.honeymoonDone,
    parent_proud: () => S.children.length >= 1,
    rich: () => S.money + S.bank >= 100000,
    famous: () => S.fame >= 70,
    all_rounder: () => D.SKILL_KEYS.every((k) => S.skills[k] >= 50),
  };
  // harvest counter is a dedicated field, but keep farmHarvested synced in farmHarvest
  function checkAchievements() {
    S.achievements = S.achievements || {};
    D.ACHIEVEMENTS.forEach((a) => {
      if (!S.achievements[a.id] && ACH_CHECK[a.id] && ACH_CHECK[a.id]()) {
        S.achievements[a.id] = true;
        Game.logEvent(`ความสำเร็จ: ${a.name}`);
        Game.emit('achievement', a);
      }
    });
  }
  Game.checkAchievements = checkAchievements;
  Game.claimAchievement = (id) => {
    const a = D.ACHIEVEMENTS.find((x) => x.id === id);
    if (!a) return { ok: false, message: 'ไม่พบความสำเร็จนี้' };
    if (!S.achievements[id]) return { ok: false, message: 'ยังไม่ปลดล็อก' };
    S.achievementClaimed = S.achievementClaimed || {};
    if (S.achievementClaimed[id]) return { ok: false, message: 'รับรางวัลแล้ว' };
    S.achievementClaimed[id] = true; S.money += a.reward;
    Game.save(); Game.emit('change');
    return { ok: true, message: `🏆 รับรางวัล “${a.name}” +฿${fmt(a.reward)}` };
  };

  Game.goalProgress = () => {
    if (S.goal === 'family') {
      const a = S.parentLove, b = S.partnerLove || 0, c = Math.min(2, S.children.length) / 2 * 100;
      const d = (S.homeLevel - 1) / 3 * 100, e = S.happy;
      return clamp((a + b + c + d + e) / 5);
    }
    if (S.goal === 'career') {
      const a = S.jobId ? Math.min(100, (S.jobLevel - 1) * 25 + S.performance * 0.5) : 0;
      const b = Math.min(100, (S.money + S.bank) / 1000);
      const c = (S.businessLevel / 4) * 100;
      const d = D.SKILL_KEYS.reduce((s, k) => s + S.skills[k], 0) / (D.SKILL_KEYS.length * 100) * 100;
      const e = Math.min(100, S.edu);
      return clamp((a + b + c + d + e) / 5);
    }
    const a = S.fame;
    const b = Object.keys(S.achievements || {}).length / D.ACHIEVEMENTS.length * 100;
    const c = Math.min(100, S.festivalWins * 20);
    const d = Object.keys(S.collections).length / 12 * 100;
    const e = Math.min(100, S.questTotalDone * 5);
    return clamp((a + b + c + d + e) / 5);
  };
  Game.goalTier = () => Math.min(5, Math.floor(Game.goalProgress() / 20) + (Game.goalProgress() >= 20 ? 0 : 1));
  Game.lifeEnding = () => {
    const list = D.LIFE_ENDINGS[S.goal] || D.LIFE_ENDINGS.family;
    const p = Game.goalProgress();
    return p >= 80 ? list[2] : p >= 45 ? list[1] : list[0];
  };

  Game.nextSteps = () => {
    const out = [];
    if (!S.alive) return out;
    if (S.pendingEvent) out.push({ text: 'มีเหตุการณ์รอตัดสินใจ', tab: 'today' });
    let open = 0;
    D.PLAN_SLOTS.forEach((s) => { if (S.timeMin < s.end && !S.planState[s.id]) open++; });
    if (open > 0) out.push({ text: `วางแผนวันนี้ (เหลือ ${open} ช่อง)`, tab: 'today' });
    if (S.hunger < 30) out.push({ text: 'ความอิ่มต่ำ · หาอะไรกิน', tab: 'today' });
    if (S.energy < 25) out.push({ text: 'พลังงานใกล้หมด · พักผ่อนหรือนอน', tab: 'today' });
    if (S.stress > 80) out.push({ text: 'เครียดมาก · ผ่อนคลายก่อนป่วย', tab: 'character' });
    if (!Game.isChild() && S.jobId && Game.isWorkday() && !S.workedToday && !S.sick && S.timeMin < 17 * 60) {
      out.push({ text: `ยังไม่ได้เข้างาน · ไปที่${Game.zoneName(D.JOB_WORKPLACES[S.jobId] || 'office')} ก่อน 17:00`, tab: 'work' });
    }
    if (Game.isChild() && Game.isSchoolDay() && !S.schoolAttendedToday && S.timeMin < 15 * 60) {
      out.push({ text: 'ยังไม่ได้ไปโรงเรียน · ไปที่ย่านโรงเรียนก่อน 15:00', tab: 'today' });
    }
    if (Game.farmReadyCount() > 0) out.push({ text: `มีพืชพร้อมเก็บ ${Game.farmReadyCount()} แปลง`, tab: 'home' });
    const daysToBills = 28 - ((S.day - 1) % 28);
    if (daysToBills <= 3 && S.money < Game.livingCost()) out.push({ text: `บิลใกล้ถึง (อีก ${daysToBills} วัน) แต่เงินไม่พอ`, tab: 'work' });
    if (Game.isChild() && Game.isSchoolDay() && S.schoolAttendedToday && Math.min(...D.SKILL_KEYS.map((k) => S.skills[k])) < 5) {
      out.push({ text: 'ทำการบ้านที่โต๊ะในบ้าน', tab: 'home' });
    }
    if (!out.length) out.push({ text: 'ทำตามแผนของวันให้ครบ', tab: 'today' });
    return out.slice(0, 4);
  };

  /* ---------- สัตว์เลี้ยง / ฟาร์มปศุสัตว์ ---------- */
  Game.petDef = (id) => D.PETS.find((p) => p.id === id) || null;
  Game.livestockDef = (type) => D.LIVESTOCK.find((l) => l.id === type) || null;
  Game.produceCount = (key) => Math.max(0, Math.round((S.produce && S.produce[key]) || 0));

  Game.adoptPet = (id) => {
    const def = Game.petDef(id);
    if (!def) return { ok: false, message: 'ไม่พบสัตว์เลี้ยงชนิดนี้' };
    if (S.pets.length >= 3) return { ok: false, message: `เลี้ยงได้สูงสุด 3 ตัว (ตอนนี้ ${S.pets.length})` };
    if (S.money < def.price) return { ok: false, message: `ต้องมี ฿${fmt(def.price)}` };
    S.money -= def.price;
    S.pets.push({ id, name: def.name, hunger: 78, happy: 80, fedDay: 0, playDay: 0, since: S.day });
    S.happy = clamp(S.happy + 4);
    Game.logEvent(`รับ${def.name}มาเป็นสมาชิกครอบครัว`);
    Game.advance(30);
    Game.save(); Game.emit('pets');
    return { ok: true, message: `🐾 รับ${def.name}มาเลี้ยงแล้ว · ฿-${fmt(def.price)}` };
  };

  Game.renamePet = (i, name) => {
    const p = S.pets[i];
    if (!p) return { ok: false, message: 'ไม่พบสัตว์เลี้ยงตัวนี้' };
    const clean = String(name || '').trim().slice(0, 12);
    if (!clean) return { ok: false, message: 'ใส่ชื่อก่อนนะ' };
    p.name = clean;
    Game.save(); Game.emit('pets');
    return { ok: true, message: `ตั้งชื่อว่า ${clean} แล้ว` };
  };

  Game.feedPet = (i) => {
    const p = S.pets[i];
    if (!p) return { ok: false, message: 'ไม่พบสัตว์เลี้ยงตัวนี้' };
    if (p.fedDay === S.day) return { ok: false, message: `วันนี้ให้อาหาร${p.name}แล้ว` };
    if (S.money < COST.petFood) return { ok: false, message: `ต้องมี ฿${fmt(COST.petFood)}` };
    S.money -= COST.petFood;
    p.fedDay = S.day;
    p.hunger = clamp(p.hunger + 42);
    p.happy = clamp(p.happy + 5);
    S.happy = clamp(S.happy + 1);
    Game.advance(10);
    Game.save(); Game.emit('pets');
    return { ok: true, message: `🍖 ให้อาหาร${p.name} · อิ่ม ${p.hunger}/100 · ฿-${fmt(COST.petFood)}` };
  };

  Game.playPet = (i) => {
    const p = S.pets[i];
    if (!p) return { ok: false, message: 'ไม่พบสัตว์เลี้ยงตัวนี้' };
    if (p.playDay === S.day) return { ok: false, message: `วันนี้เล่นกับ${p.name}แล้ว` };
    p.playDay = S.day;
    p.happy = clamp(p.happy + 12);
    p.hunger = Math.max(0, p.hunger - 4);
    S.happy = clamp(S.happy + 4);
    S.stress = clamp(S.stress - 4);
    S.social = clamp(S.social + 2);
    Game.addSkill('communication', 1);
    Game.advance(20);
    Game.save(); Game.emit('pets');
    return { ok: true, message: `🎾 เล่นกับ${p.name} · ใจสัตว์ +12 · สุข +4` };
  };

  Game.buyLivestock = (type) => {
    const def = Game.livestockDef(type);
    if (!def) return { ok: false, message: 'ไม่พบสัตว์ชนิดนี้' };
    if (S.livestock.length >= 8) return { ok: false, message: 'คอกเต็มแล้ว (สูงสุด 8 ตัว)' };
    if (S.money < def.price) return { ok: false, message: `ต้องมี ฿${fmt(def.price)}` };
    S.money -= def.price;
    S.livestock.push({ type, name: def.name, fedDay: 0, ready: false, since: S.day });
    Game.logEvent(`ซื้อ${def.name}มาเลี้ยงในคอก`);
    Game.advance(20);
    Game.save(); Game.emit('ranch');
    return { ok: true, message: `🐄 รับ${def.name}เข้าคอก · ฿-${fmt(def.price)}` };
  };

  Game.feedLivestock = (i) => {
    const l = S.livestock[i];
    if (!l) return { ok: false, message: 'ไม่พบสัตว์ตัวนี้' };
    if (l.fedDay === S.day) return { ok: false, message: `วันนี้ให้อาหาร${l.name}แล้ว` };
    if (S.money < COST.livestockFeed) return { ok: false, message: `ต้องมี ฿${fmt(COST.livestockFeed)}` };
    S.money -= COST.livestockFeed;
    l.fedDay = S.day;
    Game.addSkill('cooking', 1);
    Game.advance(10);
    Game.save(); Game.emit('ranch');
    return { ok: true, message: `🌾 ให้อาหาร${l.name}แล้ว · พรุ่งนี้จะผลิตรอบใหม่ · ฿-${fmt(COST.livestockFeed)}` };
  };

  Game.feedAllLivestock = () => {
    const hungry = S.livestock.filter((l) => l.fedDay !== S.day);
    if (!hungry.length) return { ok: false, message: 'ให้อาหารครบทุกตัวแล้ววันนี้' };
    const cost = hungry.length * COST.livestockFeed;
    if (S.money < cost) return { ok: false, message: `ต้องมี ฿${fmt(cost)}` };
    S.money -= cost;
    hungry.forEach((l) => { l.fedDay = S.day; });
    Game.addSkill('cooking', 2);
    Game.advance(20);
    Game.save(); Game.emit('ranch');
    return { ok: true, message: `🌾 ให้อาหาร ${hungry.length} ตัว · ฿-${fmt(cost)}` };
  };

  Game.collectProduce = (i) => {
    const l = S.livestock[i];
    if (!l) return { ok: false, message: 'ไม่พบสัตว์ตัวนี้' };
    const def = Game.livestockDef(l.type);
    if (!l.ready) return { ok: false, message: `${l.name}ยังไม่มี${def.productName}ให้เก็บ — ให้อาหารแล้วรอพรุ่งนี้` };
    l.ready = false;
    S.produce[def.produce] = Game.produceCount(def.produce) + 1;
    Game.addSkill('cooking', 1);
    Game.advance(10);
    Game.save(); Game.emit('ranch');
    return { ok: true, message: `🧺 เก็บ${def.productName} 1 หน่วยจาก${l.name}` };
  };

  Game.collectAllProduce = () => {
    let n = 0;
    S.livestock.forEach((l) => {
      const def = Game.livestockDef(l.type);
      if (l.ready && def) { l.ready = false; S.produce[def.produce] = Game.produceCount(def.produce) + 1; n++; }
    });
    if (!n) return { ok: false, message: 'ยังไม่มีผลิตผลให้เก็บ' };
    Game.addSkill('cooking', 2);
    Game.advance(15);
    Game.save(); Game.emit('ranch');
    return { ok: true, message: `🧺 เก็บผลิตผล ${n} หน่วยแล้ว` };
  };

  Game.sellProduce = () => {
    let total = 0, count = 0;
    D.LIVESTOCK.forEach((def) => {
      const n = Game.produceCount(def.produce);
      if (n > 0) { total += n * def.sell; count += n; S.produce[def.produce] = 0; }
    });
    if (!count) return { ok: false, message: 'ไม่มีผลิตผลให้ขาย' };
    S.money += total;
    Game.logEvent(`ขายผลิตผล ${count} หน่วย ได้ ฿${fmt(total)}`);
    Game.advance(15);
    Game.save(); Game.emit('ranch');
    return { ok: true, message: `💰 ขายผลิตผล ${count} หน่วย · +฿${fmt(total)}` };
  };

  function ranchNewDay(notes) {
    S.pets.forEach((p) => {
      p.hunger = Math.max(0, p.hunger - 28);
      if (p.hunger < 25) p.happy = clamp(p.happy - 8);
      else if (p.hunger > 60) p.happy = clamp(p.happy + 2);
      if (p.hunger === 0) notes.push(`😿 ${p.name} หิวมาก ลืมให้อาหารหรือเปล่า?`);
    });
    S.livestock.forEach((l) => {
      const def = Game.livestockDef(l.type);
      l.ready = !!def && l.fedDay === S.day - 1;
    });
  }

  /* ---------- เวทมนตร์ / กิลด์ ---------- */
  Game.maxMana = () => 100 + ((S.homeItems || []).includes('magic_altar') ? 20 : 0);
  Game.spellDef = (id) => D.SPELLS.find((s) => s.id === id) || null;
  Game.magicLevelTitle = () => ['', 'มือใหม่', 'นักฝึกหัด', 'นักเวท', 'จอมเวท', 'มหาจอมเวท'][Math.min(5, S.magicLevel || 1)] || 'มือใหม่';

  Game.addMagicXp = (amount) => {
    S.magicXp = Math.max(0, (S.magicXp || 0) + Math.round(amount));
    let leveled = false;
    while (S.magicLevel < 5 && S.magicXp >= S.magicLevel * 100) {
      S.magicXp -= S.magicLevel * 100;
      S.magicLevel++;
      leveled = true;
    }
    S.manaMax = Game.maxMana();
    if (leveled) {
      Game.logEvent(`เลเวลเวทขึ้นเป็น ${S.magicLevel} (${Game.magicLevelTitle()})`);
      S.happy = clamp(S.happy + 6);
    }
    return leveled;
  };

  Game.buySpell = (id) => {
    const spell = Game.spellDef(id);
    if (!spell) return { ok: false, message: 'ไม่พบคาถานี้' };
    if (S.spells.includes(id)) return { ok: false, message: 'เรียนคาถานี้แล้ว' };
    if (S.magicLevel < spell.level) return { ok: false, message: `ต้องมีเลเวลเวท ${spell.level} (ตอนนี้ ${S.magicLevel})` };
    const price = 800 + spell.level * 900;
    if (S.money < price) return { ok: false, message: `ต้องมี ฿${fmt(price)}` };
    S.money -= price;
    S.spells.push(id);
    Game.advance(45);
    Game.logEvent(`เรียนคาถา${spell.name}`);
    Game.save(); Game.emit('magic');
    return { ok: true, message: `📖 เรียน${spell.name}สำเร็จ · ฿-${fmt(price)}` };
  };

  Game.castSpell = (id) => {
    const spell = Game.spellDef(id);
    if (!spell) return { ok: false, message: 'ไม่พบคาถานี้' };
    if (!S.spells.includes(id)) return { ok: false, message: 'ยังไม่ได้เรียนคาถานี้' };
    if (S.magicLevel < spell.level) return { ok: false, message: `ต้องมีเลเวลเวท ${spell.level}` };
    if ((S.mana || 0) < spell.cost) return { ok: false, message: `มานาไม่พอ (ต้องใช้ ${spell.cost})` };
    S.mana -= spell.cost;
    S.magicDay = S.day;
    let msg = '';
    if (id === 'heal') {
      S.health = clamp(S.health + 12); S.energy = clamp(S.energy + 10);
      msg = '✨ ฟื้นพลังกาย +12 · พลังงาน +10';
    } else if (id === 'charm') {
      S.social = clamp(S.social + 8); S.happy = clamp(S.happy + 4);
      if (S.married) S.partnerLove = clamp(S.partnerLove + 4);
      msg = '💗 เสน่ห์ +8 · ความสุข +4';
    } else if (id === 'bloom') {
      let n = 0;
      S.farm.forEach((p) => { if (p.crop) { p.growth = (p.growth || 0) + 1; n++; } });
      msg = n ? `🌱 เร่งการเติบโต ${n} แปลง` : '🌱 ยังไม่มีแปลงที่ปลูกพืช';
    } else if (id === 'spark') {
      const n = 2 + rnd(3);
      S.crystals = (S.crystals || 0) + n;
      msg = `💎 รวบรวมคริสตัลได้ ${n} เม็ด`;
    } else if (id === 'shield') {
      S.stress = clamp(S.stress - 18); S.happy = clamp(S.happy + 4);
      msg = '🛡 ความเครียด -18 · ความสุข +4';
    } else if (id === 'summon') {
      S.farm.forEach((p) => { if (p.crop) p.watered = true; });
      S.pets.forEach((p) => { p.happy = clamp(p.happy + 6); });
      msg = '🐾 สัตว์วิเศษช่วยรดน้ำทุกแปลงแล้ว';
    }
    const leveled = Game.addMagicXp(8);
    Game.advance(15);
    Game.save(); Game.emit('magic');
    return { ok: true, message: `${msg} · มานา -${spell.cost}${leveled ? ` · ⬆ เลเวลเวท ${S.magicLevel}!` : ''}` };
  };

  Game.meditate = () => {
    S.mana = Math.min(Game.maxMana(), (S.mana || 0) + 25);
    S.manaMax = Game.maxMana();
    S.stress = clamp(S.stress - 8);
    S.energy = clamp(S.energy + 3);
    const leveled = Game.addMagicXp(4);
    Game.advance(30);
    Game.save(); Game.emit('magic');
    return { ok: true, message: `🧘 นั่งสมาธิ · มานา +25 (${S.mana}/${S.manaMax}) · เครียด -8${leveled ? ` · ⬆ เลเวล ${S.magicLevel}` : ''}` };
  };

  Game.gatherCrystal = () => {
    if (S.crystalDay === S.day) return { ok: false, message: 'วันนี้เก็บคริสตัลแล้ว — กลับมาพรุ่งนี้' };
    S.crystalDay = S.day;
    const chance = Math.min(.95, .5 + (S.magicLevel || 1) * .08);
    Game.advance(25);
    if (Math.random() > chance) {
      Game.save(); Game.emit('magic');
      return { ok: true, message: '💎 ขุดดูแล้วยังไม่เจอคริสตัล — แต่ได้ประสบการณ์ +3' };
    }
    const n = 1 + rnd(1 + Math.min(3, S.magicLevel || 1));
    S.crystals = (S.crystals || 0) + n;
    Game.addMagicXp(3);
    Game.save(); Game.emit('magic');
    return { ok: true, message: `💎 เก็บคริสตัลได้ ${n} เม็ด (มีทั้งหมด ${S.crystals})` };
  };

  Game.sellCrystals = () => {
    const n = S.crystals || 0;
    if (!n) return { ok: false, message: 'ไม่มีคริสตัลให้ขาย' };
    const total = n * D.CRYSTAL_SELL;
    S.crystals = 0;
    S.money += total;
    Game.advance(10);
    Game.save(); Game.emit('magic');
    return { ok: true, message: `💰 ขายคริสตัล ${n} เม็ด · +฿${fmt(total)}` };
  };

  Game.joinGuild = () => {
    if (S.guild) return { ok: false, message: 'เป็นสมาชิกกิลด์อยู่แล้ว' };
    if ((S.magicLevel || 1) < 2) return { ok: false, message: 'ต้องมีเลเวลเวท 2 ขึ้นไปก่อนสมัครกิลด์' };
    if (S.money < D.GUILD_FEE) return { ok: false, message: `ค่าสมาชิก ฿${fmt(D.GUILD_FEE)}` };
    S.money -= D.GUILD_FEE;
    S.guild = true;
    S.guildDay = S.day;
    S.fame = clamp(S.fame + 6);
    S.social = clamp(S.social + 5);
    Game.logEvent('สมัครเข้าเป็นสมาชิกกิลด์นักเวท');
    Game.advance(45);
    Game.save(); Game.emit('magic');
    return { ok: true, message: `🔮 เข้าร่วมกิลด์นักเวทแล้ว · ฿-${fmt(D.GUILD_FEE)}` };
  };

  Game.challengeBoss = () => {
    if (!S.guild) return { ok: false, message: 'ต้องเป็นสมาชิกกิลด์ก่อน' };
    if (S.bossDay === S.day) return { ok: false, message: 'วันนี้ท้าบอสแล้ว — พักก่อน' };
    if ((S.magicLevel || 1) < 3) return { ok: false, message: 'ต้องมีเลเวลเวท 3 ขึ้นไป' };
    if ((S.mana || 0) < 30) return { ok: false, message: 'มานาไม่พอ (ต้องใช้ 30)' };
    S.bossDay = S.day;
    S.mana -= 30;
    Game.advance(60);
    const chance = Math.min(.92, .34 + (S.magicLevel || 1) * .1 + (S.spells.length * .02));
    if (Math.random() < chance) {
      S.bossWins = (S.bossWins || 0) + 1;
      const crystals = 4 + rnd(4);
      S.crystals = (S.crystals || 0) + crystals;
      S.money += 3000;
      S.fame = clamp(S.fame + 12);
      Game.addMagicXp(25);
      Game.logEvent(`เอาชนะบอสประจำเมืองครั้งที่ ${S.bossWins}`);
      Game.save(); Game.emit('magic');
      return { ok: true, message: `🐲 ชนะบอส! รับ ฿3,000 · คริสตัล ${crystals} เม็ด · ชื่อเสียง +12` };
    }
    S.health = clamp(S.health - 15);
    S.money = Math.max(0, S.money - 500);
    S.stress = clamp(S.stress + 10);
    Game.addMagicXp(8);
    Game.save(); Game.emit('magic');
    return { ok: true, message: '🐲 พ่ายแพ้บอส · สุขภาพ -15 · เสียค่ารักษา ฿500 · ได้ประสบการณ์ +8' };
  };

  /* ---------- สอบ / โรงเรียน ---------- */
  Game.examReady = () => (S.day - (S.examDay || -99)) >= D.EXAM_COOLDOWN_DAYS;
  Game.examInDays = () => Math.max(0, D.EXAM_COOLDOWN_DAYS - (S.day - (S.examDay || -99)));

  Game.takeExam = () => {
    if (Game.isChild()) return { ok: false, message: 'ต้องอายุ 18 ปีขึ้นไป' };
    if (!Game.examReady()) return { ok: false, message: `สอบได้อีกครั้งใน ${Game.examInDays()} วัน` };
    if (S.money < COST.exam) return { ok: false, message: `ค่าสมัครสอบ ฿${fmt(COST.exam)}` };
    S.money -= COST.exam;
    S.examDay = S.day;
    Game.advance(120);
    const score = clamp(S.edu * .55 + S.skills.academics * .35 + rnd(21));
    S.examScore = score;
    if (score >= 62) {
      S.examPassed = true;
      S.edu = clamp(S.edu + 6);
      S.fame = clamp(S.fame + 5);
      S.grades = clamp(S.grades + 4);
      S.examCerts.push({ day: S.day, score, name: score >= 85 ? 'เกียรตินิยม' : 'ผ่านเกณฑ์' });
      Game.logEvent(`สอบเข้ามหาวิทยาลัยผ่าน ด้วยคะแนน ${score}`);
      Game.save(); Game.emit('magic');
      return { ok: true, message: `🎓 สอบผ่าน! คะแนน ${score}/100 · ความรู้ +6 · ชื่อเสียง +5` };
    }
    S.stress = clamp(S.stress + 8);
    S.edu = clamp(S.edu + 2);
    Game.save(); Game.emit('magic');
    return { ok: true, message: `📝 สอบยังไม่ผ่าน (${score}/100) · ความรู้ +2 · เครียด +8` };
  };

  /* ---------- รถไฟใต้ดิน ---------- */
  Game.metroRoutes = () => D.METRO_ROUTES || [];
  Game.buyMetroCard = () => {
    if (S.metroCard) return { ok: false, message: 'มีบัตรโดยสารแล้ว' };
    if (S.money < COST.metroCard) return { ok: false, message: `บัตรราคา ฿${fmt(COST.metroCard)}` };
    S.money -= COST.metroCard;
    S.metroCard = true;
    Game.advance(10);
    Game.save(); Game.emit('magic');
    return { ok: true, message: `🎫 ซื้อบัตรโดยสารแล้ว · นั่งรถไฟฟรีตลอดชีพ · ฿-${fmt(COST.metroCard)}` };
  };

  Game.metroTravel = (zoneId) => {
    const route = Game.metroRoutes().find((r) => r.zone === zoneId);
    if (!route) return { ok: false, message: 'รถไฟไม่ผ่านที่นั่น' };
    if (S.zone === zoneId) return { ok: false, message: 'อยู่ที่นี่แล้ว' };
    const fare = S.metroCard ? 0 : D.METRO_COST;
    if (S.money < fare) return { ok: false, message: `ค่าโดยสาร ฿${fare} — เงินไม่พอ` };
    if (fare) S.money -= fare;
    S.metroTrips = (S.metroTrips || 0) + 1;
    Game.travelTo(zoneId, route.spawn);
    Game.advance(15);
    Game.save(); Game.emit('travel');
    return { ok: true, message: `🚇 นั่งรถไฟไป${route.label}${fare ? ` · ฿-${fare}` : ' · ใช้บัตรโดยสาร'}` };
  };

  Game.wearAccessory = (id) => {
    if (!D.ACCESSORIES.some((a) => a.id === id)) return { ok: false, message: 'ไม่พบเครื่องประดับนี้' };
    S.accessory = id;
    Game.advance(5);
    Game.save(); Game.emit('change');
    const def = D.ACCESSORIES.find((a) => a.id === id);
    return { ok: true, message: `✨ สวม${def.name}แล้ว` };
  };

  function magicNewDay() {
    S.manaMax = Game.maxMana();
    S.mana = Math.min(S.manaMax, (S.mana || 0) + 45);
    S.magicDay = -1;
    S.crystalDay = -1;
    S.bossDay = -1;
  }

  /* ---------- travel ---------- */
  Game.travelTo = (zoneId, spawn) => {
    if (!D.ZONES[zoneId]) return { ok: false, message: 'ไปที่นั่นไม่ได้' };
    if (!S.alive) return { ok: false, message: 'เกมจบแล้ว' };
    const fare = Game.isChild() ? COST.busChild : COST.bus;
    // walking inside the map is free; the bus button charges a fare
    S.zone = zoneId;
    const dp = spawn || D.ZONES[zoneId].spawn;
    S.pos = { x: dp.x, y: dp.y };
    S.visits = S.visits || {};
    S.visits[zoneId] = (S.visits[zoneId] || 0) + 1;
    Game.advance(5);
    Game.save(); Game.emit('travel');
    return { ok: true };
  };
  Game.busTravel = (zoneId) => {
    const fare = Game.isChild() ? COST.busChild : COST.bus;
    if (S.money < fare) return { ok: false, message: 'เงินไม่พอค่ารถ' };
    if (S.zone === zoneId) return { ok: false, message: 'อยู่ที่นี่แล้ว' };
    S.money -= fare;
    const res = Game.travelTo(zoneId);
    return { ok: true, message: `🚌 นั่งรถเมล์ไป${Game.zoneName(zoneId)} · ฿-${fare}` };
  };
  Game.zoneActions = () => D.ZONE_ACTIVITIES[S.zone] || [];
  Game.homeTime = () => S.timeMin >= 18 * 60 && S.timeMin <= 21 * 60;

  Game.rebirth = () => {
    // เริ่มชีวิตใหม่โดยเก็บกรรมพัน/เป้าหมายเดิมไว้เป็นค่าตั้งต้น
    const old = { name: S.name, gender: S.gender, wealth: S.wealth, trait: S.trait, outfit: S.outfit, skin: S.skin, hairColor: S.hairColor, hairStyle: S.hairStyle, accessory: S.accessory, goal: S.goal };
    Game.clearSave();
    Game.startLife(old);
    return { ok: true };
  };

  root.PLGame = Game;
  Game.reset();
})(typeof window !== 'undefined' ? window : globalThis);
