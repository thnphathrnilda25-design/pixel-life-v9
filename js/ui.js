/* Pixel Life — ui.js
 * HUD, แผง 5 กลุ่ม, dialog, มินิเกม, หน้าสร้างตัวละคร และหน้าจบชีวิต
 */
(function (root) {
  'use strict';
  const D = root.PLData;
  const G = root.PLGame;
  const R = root.PLRender;

  const UI = {};
  let el = {};
  let currentTab = 'today';
  let toastTimer = null;
  let pendingPlot = -1;
  let lastRefresh = 0;

  const TABS = [
    { id: 'today', label: 'วันนี้' },
    { id: 'character', label: 'ตัวละคร' },
    { id: 'pets', label: 'สัตว์เลี้ยง' },
    { id: 'magic', label: 'เวทมนตร์' },
    { id: 'work', label: 'งาน–เงิน' },
    { id: 'home', label: 'บ้าน–สวน' },
    { id: 'life', label: 'ชีวิต' },
  ];

  const money = (n) => '฿' + G.fmt(n);

  /* ================= init ================= */
  UI.init = () => {
    el = {
      stage: document.getElementById('stage'),
      canvas: document.getElementById('game'),
      zoneName: document.getElementById('zone-name'),
      dateLine: document.getElementById('date-line'),
      weather: document.getElementById('weather-line'),
      planChip: document.getElementById('plan-chip'),
      ageLine: document.getElementById('age-line'),
      moneyLine: document.getElementById('money-line'),
      needs: document.getElementById('needs'),
      prompt: document.getElementById('prompt'),
      promptText: document.querySelector('#prompt span'),
      dock: document.getElementById('dock'),
      btnAct: document.getElementById('btn-act'),
      btnList: document.getElementById('btn-list'),
      btnSleep: document.getElementById('btn-sleep'),
      btnSummary: document.getElementById('btn-summary'),
      toast: document.getElementById('toast'),
      wrap: document.getElementById('modal-wrap'),
      modalTitle: document.getElementById('modal-title'),
      tabs: document.getElementById('modal-tabs'),
      body: document.getElementById('modal-body'),
      foot: document.getElementById('modal-foot'),
      close: document.getElementById('modal-close'),
      start: document.getElementById('start-screen'),
      create: document.getElementById('create-screen'),
      decorBar: document.getElementById('decor-bar'),
      decorRotate: document.getElementById('decor-rotate'),
      decorClear: document.getElementById('decor-clear'),
      decorDone: document.getElementById('decor-done'),
    };

    el.close.addEventListener('click', UI.close);
    el.wrap.addEventListener('click', (e) => { if (e.target === el.wrap) UI.close(); });
    el.tabs.addEventListener('click', (e) => {
      const b = e.target.closest('[data-tab]');
      if (b) UI.open(b.dataset.tab);
    });
    el.body.addEventListener('click', onClick);
    el.foot.addEventListener('click', onClick);
    el.body.addEventListener('change', onChange);
    el.btnList.addEventListener('click', () => UI.open('today'));
    el.btnSummary.addEventListener('click', () => UI.open('today'));
    el.btnSleep.addEventListener('click', () => {
      const res = G.sleepNow(6 * 60);
      UI.feedback(res);
    });

    if (el.decorDone) el.decorDone.addEventListener('click', () => { if (UI.onDecorDone) UI.onDecorDone(); });
    if (el.decorRotate) el.decorRotate.addEventListener('click', () => { if (UI.onDecorRotate) UI.onDecorRotate(); });
    if (el.decorClear) el.decorClear.addEventListener('click', () => { if (UI.onDecorClear) UI.onDecorClear(); });

    document.addEventListener('keydown', (e) => {
      if (e.code === 'Escape') { if (!el.wrap.classList.contains('hidden')) UI.close(); }
      if (e.code === 'KeyM' || e.code === 'KeyB') {
        if (el.wrap.classList.contains('hidden') && !el.create.classList.contains('hidden') === false) return;
      }
    });

    UI.fillCreateForm();
  };

  /* ================= HUD ================= */
  UI.refresh = (force) => {
    if (!G.S.created) return;
    const now = performance.now();
    if (!force && now - lastRefresh < 180) return;
    lastRefresh = now;
    const S = G.S;

    el.zoneName.textContent = G.zoneName(S.zone);
    el.dateLine.textContent = `${G.weekdayName()} • ${D.SEASON_NAMES[S.season]} วันที่ ${S.seasonDay} • ${G.timeString()}`;
    el.weather.textContent = G.weatherName();
    el.ageLine.textContent = `อายุ ${S.age} ปี`;
    el.moneyLine.textContent = money(S.money);

    // plan chip: นับช่องที่ทำครบ
    let planned = 0, done = 0;
    D.PLAN_SLOTS.forEach((s) => {
      if (S.dayPlan[s.id]) { planned++; if (S.planState[s.id] === 'done') done++; }
    });
    el.planChip.textContent = planned ? `แผน ${done}/${planned}` : 'แผน -';
    el.planChip.classList.toggle('done', planned > 0 && done >= planned);

    // needs
    const map = { health: 'สุขภาพ', happy: 'ความสุข', energy: 'พลังงาน', hunger: 'ความอิ่ม', stress: 'เครียด' };
    el.needs.querySelectorAll('.need').forEach((n) => {
      const k = n.dataset.k;
      const v = Math.round(S[k]);
      n.querySelector('i').style.width = Math.max(2, v) + '%';
      n.querySelector('b').textContent = v;
      n.classList.toggle('low', k !== 'stress' && v < 25);
      n.classList.toggle('high', k === 'stress' && v > 75);
      n.title = map[k];
    });
  };

  UI.toast = (msg, ms = 2600) => {
    if (!msg) return;
    el.toast.textContent = msg;
    el.toast.classList.remove('hidden');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.toast.classList.add('hidden'), ms);
  };

  UI.feedback = (res) => {
    if (!res) return;
    if (res.message) UI.toast(res.message, res.ok === false ? 2200 : 3000);
    if (res.ok === false) {
      el.toast.style.borderColor = '#b0483c';
      setTimeout(() => { if (el.toast) el.toast.style.borderColor = ''; }, 600);
    }
    UI.refresh(true);
    if (UI.isOpen()) UI.render(currentTab);
    if (!G.S.alive) UI.showGameOver();
  };

  /* ================= prompt / dock ================= */
  UI.setPrompt = (text) => {
    if (!text) { el.prompt.classList.add('hidden'); el.btnAct.disabled = true; el.btnAct.textContent = 'ใช้ E'; return; }
    el.prompt.classList.remove('hidden');
    el.promptText.textContent = text;
    el.btnAct.disabled = false;
    el.btnAct.textContent = 'ใช้ E';
  };

  /* ================= decorate mode UI ================= */
  UI.setDecorUI = (on, selectedId) => {
    if (!el.decorBar) return;
    el.decorBar.classList.toggle('hidden', !on);
    if (on) {
      const f = selectedId ? (D.FURNITURE.find((x) => x.id === selectedId) || {}) : null;
      el.decorBar.querySelector('.decor-label').textContent = f && f.name
        ? `🛋 ${f.name} — ลากในห้อง หรือกดหมุน/เก็บ`
        : '🛋 โหมดจัดบ้าน — แตะเฟอร์นิเจอร์เพื่อเลือก';
    }
    el.stage.classList.toggle('decorating', !!on);
  };

  /* ================= modal ================= */
  UI.isOpen = () => !el.wrap.classList.contains('hidden');

  UI.open = (tab) => {
    currentTab = tab || currentTab;
    if (!G.S.created) return;
    el.wrap.classList.remove('hidden');
    el.tabs.innerHTML = TABS.map((t) =>
      `<button class="tab ${t.id === currentTab ? 'active' : ''}" data-tab="${t.id}">${t.label}</button>`).join('');
    el.modalTitle.textContent = (TABS.find((t) => t.id === currentTab) || {}).label || 'สมุดชีวิต';
    UI.render(currentTab);
  };

  UI.close = () => {
    el.wrap.classList.add('hidden');
    el.body.innerHTML = '';
    el.foot.innerHTML = '';
    pendingPlot = -1;
    UI.refresh(true);
  };

  UI.render = (tab) => {
    currentTab = tab || currentTab;
    const renderers = {
      today: renderToday, character: renderCharacter, pets: renderPets, magic: renderMagic,
      work: renderWork, home: renderHome, life: renderLife,
    };
    el.tabs.querySelectorAll('.tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === currentTab));
    el.modalTitle.textContent = (TABS.find((t) => t.id === currentTab) || {}).label || 'สมุดชีวิต';
    el.body.innerHTML = (renderers[currentTab] || renderToday)();
    el.body.scrollTop = 0;
    el.foot.innerHTML = '';
  };

  /* ================= helper snippets ================= */
  const bar = (pct, cls) => `<div class="bar-wide ${cls || ''}"><i style="width:${Math.max(2, Math.min(100, pct))}%"></i></div>`;
  const tag = (txt, cls) => `<span class="tag ${cls || ''}">${txt}</span>`;
  const btn = (label, action, cls = 'btn-brown', disabled = false) =>
    `<button class="btn sm ${cls}" data-action="${action}" ${disabled ? 'disabled' : ''}>${label}</button>`;

  /* ================= TAB: วันนี้ ================= */
  function renderToday() {
    const S = G.S;
    const steps = G.nextSteps();
    const slotNow = G.currentSlot();
    const billsIn = 28 - ((S.day - 1) % 28);

    let h = '';
    h += `<div class="note"><b>ควรทำอะไรต่อ</b><div class="list" style="margin-top:4px">` +
      steps.map((s) => `<div>• ${s.text}</div>`).join('') + `</div></div>`;

    if (S.pendingEvent) {
      h += `<div class="card" style="border-color:#b0483c;background:#fff2ec">
        <div class="card-title">❗ มีเหตุการณ์รออยู่</div>
        <div class="dim">${S.pendingEvent.text}</div>
        <div class="row">${btn('ดูทางเลือก', 'show-event', 'btn-red')}</div></div>`;
    }

    h += `<div class="section">แผนวันนี้</div>`;
    h += `<div class="plan-slots">`;
    D.PLAN_SLOTS.forEach((slot) => {
      const opt = S.dayPlan[slot.id];
      const st = S.planState[slot.id];
      const isNow = slotNow === slot.id;
      const passed = S.timeMin >= slot.end;
      const status = st === 'done' ? '<span class="slot-status done">✅ ทำแล้ว</span>'
        : st === 'miss' ? '<span class="slot-status miss">❌ ผิดแผน</span>'
        : st === 'empty' ? '<span class="slot-status">— ไม่ได้วาง</span>'
        : passed ? '<span class="slot-status miss">เลยเวลา</span>'
        : opt ? '<span class="slot-status chosen">วางไว้</span>' : '<span class="slot-status">ยังว่าง</span>';

      h += `<div class="plan-slot" style="${isNow ? 'border-color:#d8a63e;background:#fff4d8' : ''}">
        <h4>${slot.emoji} ${slot.name} ${status}</h4>
        <div class="time">${String(slot.start / 60).padStart(2, '0')}:00–${String(slot.end / 60 >= 24 ? 0 : slot.end / 60).padStart(2, '0')}:00</div>
        <div class="plan-opts">`;
      if (st) {
        h += `<span class="dim">${st === 'done' ? 'สำเร็จแล้ว' : st === 'miss' ? 'พลาดเป้า' : 'ไม่ได้วางแผน'}</span>`;
      } else if (passed) {
        h += `<span class="dim">ช่วงนี้ผ่านไปแล้ว</span>`;
      } else if (opt) {
        h += `<div style="font-size:12px;font-weight:700">${D.PLAN_OPTIONS[opt].label}</div>
              <div class="dim" style="width:100%">${D.PLAN_OPTIONS[opt].hint}</div>
              ${btn('เปลี่ยน', `plan-open:${slot.id}`, 'btn-ghost')}
              ${btn('ล้าง', `plan-clear:${slot.id}`, 'btn-ghost')}`;
      } else {
        h += btn('เลือกกิจกรรม', `plan-open:${slot.id}`, 'btn-gold');
      }
      h += `</div></div>`;
    });
    h += `</div>`;

    if (pendingPlot >= 100 && pendingPlot < 200) { /* crop picker handled in home tab */ }

    h += `<div class="section">ภาพรวมวันนี้</div>
      <div class="kv">
        <div><span>เวลา</span><b>${G.timeString()} (${G.dayPhase()})</b></div>
        <div><span>สภาพอากาศ</span><b>${G.weatherName()}</b></div>
        <div><span>บิลรอบถัดไป</span><b>อีก ${billsIn} วัน</b></div>
        <div><span>ทำแผนต่อเนื่อง</span><b>${S.planStreak} วัน (ดีที่สุด ${S.planBest})</b></div>
        <div><span>เงินสด</span><b>${money(S.money)}</b></div>
        <div><span>เงินในบัญชี</span><b>${money(S.bank)}</b></div>
      </div>`;

    if (S.log.length) {
      h += `<div class="section">บันทึกล่าสุด</div><div class="list">` +
        S.log.slice(0, 6).map((l) => `<div class="entry"><div class="grow"><div class="s">${l}</div></div></div>`).join('') +
        `</div>`;
    }
    return h;
  }

  /* ================= TAB: ตัวละคร ================= */
  function renderCharacter() {
    const S = G.S;
    const goal = D.LIFE_GOALS.find((g) => g.id === S.goal) || D.LIFE_GOALS[0];
    const karma = D.KARMA_DEFS[S.karma] || {};

    let h = '';
    h += `<div class="card">
      <div class="card-title"><span>${S.name} • อายุ ${S.age} ปี</span>${tag(S.gender)}</div>
      <div class="dim">${G.educationTitle()} • ${G.jobTitle()} ${S.jobId ? `ระดับ ${S.jobLevel}` : ''}</div>
      <div class="row" style="margin-top:6px">
        ${tag(karma.name || '', 'ok')} ${S.retired ? tag('เกษียณ', 'ok') : ''} ${S.sick ? tag('ป่วย', 'bad') : ''}
      </div>
      <div class="dim" style="margin-top:6px">${karma.desc || ''}</div>
    </div>`;

    h += `<div class="section">เป้าหมายชีวิต</div>
      <div class="card">
        <div class="card-title"><span>${goal.icon} ${goal.name}</span><b>${Math.round(G.goalProgress())}%</b></div>
        <div class="dim">${goal.desc}</div>
        <div style="margin-top:6px">${bar(G.goalProgress())}</div>
      </div>`;

    h += `<div class="section">ค่าสถานะ</div><div class="kv">
      <div><span>สุขภาพ</span><b>${Math.round(S.health)}</b></div>
      <div><span>ความสุข</span><b>${Math.round(S.happy)}</b></div>
      <div><span>พลังงาน</span><b>${Math.round(S.energy)}</b></div>
      <div><span>ความอิ่ม</span><b>${Math.round(S.hunger)}</b></div>
      <div><span>ความเครียด</span><b>${Math.round(S.stress)}</b></div>
      <div><span>เกรด</span><b>${Math.round(S.grades)}</b></div>
      <div><span>ความรู้</span><b>${Math.round(S.edu)}</b></div>
      <div><span>ชื่อเสียง</span><b>${Math.round(S.fame)}</b></div>
      <div><span>สังคม</span><b>${Math.round(S.social)}</b></div>
      <div><span>ฟิตเนส</span><b>${Math.round(S.fitness)}</b></div>
      <div><span>ความรักพ่อแม่</span><b>${Math.round(S.parentLove)}</b></div>
      <div><span>ความรักคู่</span><b>${Math.round(S.partnerLove)}</b></div>
    </div>`;

    h += `<div class="section">ทักษะ <span class="dim" style="text-transform:none;font-weight:400">— ฝึกได้ ฿${G.COST.train}/ครั้ง</span></div><div class="list">`;
    D.SKILL_KEYS.forEach((k) => {
      const def = D.SKILL_DEFS[k];
      h += `<div class="entry">
        <div class="grow">
          <div class="t" style="color:${def.color}">${def.name} <span class="dim">${S.skills[k]}/100</span></div>
          ${bar(S.skills[k])}
          <div class="s">${def.desc}</div>
        </div>
        ${btn('ฝึก +3', `train:${k}`, 'btn-blue')}
      </div>`;
    });
    h += `</div>`;

    h += `<div class="section">ลักษณะที่ได้รับจากพ่อแม่</div><div class="card">
      <div class="card-title">${(D.PARENT_TRAITS.find((t) => t.id === S.trait) || {}).name || '-'}</div>
      <div class="dim">${(D.PARENT_TRAITS.find((t) => t.id === S.trait) || {}).desc || ''}</div>
    </div>`;

    h += `<div class="section">ชุดที่ใส่</div><div class="list">`;
    S.ownedOutfits.forEach((id) => {
      const o = D.OUTFITS.find((x) => x.id === id);
      if (!o) return;
      h += `<div class="entry"><div class="grow"><div class="t">${o.name}${S.outfit === id ? ' (ใส่อยู่)' : ''}</div>
        <div class="s">เสน่ห์ +${o.charm} • เป็นทางการ +${o.formal}</div></div>
        ${S.outfit === id ? tag('ใส่อยู่', 'ok') : btn('สวม', `wear:${id}`, 'btn-leaf')}</div>`;
    });
    h += `</div>`;

    h += `<div class="section">เครื่องประดับ <span class="dim" style="text-transform:none;font-weight:400">— ใส่ได้ตลอด ไม่มีค่าใช้จ่าย</span></div>
      <div class="acc-grid">`;
    D.ACCESSORIES.forEach((a) => {
      const on = S.accessory === a.id;
      h += `<button class="acc-chip ${on ? 'on' : ''}" data-action="accessory:${a.id}">
        <span class="acc-ico">${a.id === 'none' ? '∅' : '✦'}</span>${a.name}</button>`;
    });
    h += `</div>`;

    h += `<div class="section">การสอบเข้ามหาวิทยาลัย</div>
      <div class="card">
        <div class="card-title"><span>🎓 ${S.examPassed ? 'สอบผ่านแล้ว' : 'ยังไม่ผ่านการสอบ'}</span>
          ${S.examPassed ? tag('ผ่านเกณฑ์', 'ok') : tag('ยังไม่สอบ', 'bad')}</div>
        <div class="dim">ค่าสมัครสอบ ${money(G.COST.exam)} • สอบได้ทุก ${D.EXAM_COOLDOWN_DAYS} วัน • ใช้ความรู้ + ทักษะวิชาการ</div>
        <div class="kv" style="margin-top:6px">
          <div><span>คะแนนล่าสุด</span><b>${S.examScore || 0}/100</b></div>
          <div><span>รอบถัดไป</span><b>${G.examReady() ? 'สอบได้เลย' : `อีก ${G.examInDays()} วัน`}</b></div>
          <div><span>ใบรับรอง</span><b>${(S.examCerts || []).length} ใบ</b></div>
        </div>
        <div class="row" style="margin-top:6px">${btn('สมัครสอบ', 'exam-take', 'btn-gold', !G.examReady() || G.isChild())}</div>
      </div>`;
    return h;
  }

  /* ================= TAB: สัตว์เลี้ยง ================= */
  function renderPets() {
    const S = G.S;
    let h = '';

    h += `<div class="card">
      <div class="card-title"><span>🐾 สัตว์เลี้ยงของเรา</span><b>${S.pets.length}/3</b></div>
      <div class="dim">สัตว์เลี้ยงเดินตามคุณทุกที่ ให้อาหารและเล่นด้วยทุกวันเพื่อรักษาความสุข</div>
    </div>`;

    if (S.pets.length) {
      h += `<div class="section">เพื่อนขนฟู</div><div class="list">`;
      S.pets.forEach((p, i) => {
        const def = D.PETS.find((x) => x.id === p.id) || {};
        h += `<div class="card pet-card">
          <div class="card-title"><span>${p.id === 'cat' ? '🐱' : p.id === 'dog' ? '🐶' : p.id === 'fox' ? '🦊' : p.id === 'owl' ? '🦉' : '🟢'} ${p.name}</span>${tag(def.name || p.id)}</div>
          <div class="kv">
            <div><span>ความอิ่ม</span><b>${Math.round(p.hunger)}/100</b></div>
            <div><span>ความสุข</span><b>${Math.round(p.happy)}/100</b></div>
          </div>
          <div class="acc-bars">${bar(p.hunger)}${bar(p.happy, 'pink')}</div>
          <div class="row" style="margin-top:6px">
            ${btn(`ให้อาหาร ${money(G.COST.petFood)}`, `pet-feed:${i}`, 'btn-leaf')}
            ${btn('เล่นด้วย', `pet-play:${i}`, 'btn-blue')}
            ${btn('ตั้งชื่อ', `pet-rename:${i}`, 'btn-ghost')}
          </div>
        </div>`;
      });
      h += `</div>`;
    }

    h += `<div class="section">รับสัตว์เลี้ยงใหม่</div><div class="list">`;
    D.PETS.forEach((p) => {
      const own = S.pets.some((x) => x.id === p.id);
      h += `<div class="entry"><div class="grow">
        <div class="t">${p.fantasy ? '✦ ' : ''}${p.name} <span class="dim">${money(p.price)}</span></div>
        <div class="s">${p.desc}${p.fantasy ? ' • สัตว์วิเศษ' : ''}</div>
      </div>
        ${own ? tag('เลี้ยงอยู่', 'ok') : btn('รับมาเลี้ยง', `pet-adopt:${p.id}`, 'btn-gold', S.pets.length >= 3 || S.money < p.price)}</div>`;
    });
    h += `</div>`;

    h += `<div class="section">ฟาร์มปศุสัตว์</div>
      <div class="card">
        <div class="card-title"><span>🐄 คอกสัตว์</span><b>${S.livestock.length}/8</b></div>
        <div class="dim">ให้อาหารทุกวัน แล้วเก็บผลิตผลไปขายได้ที่ทุ่งเลี้ยงสัตว์หรือตรงนี้</div>
        <div class="row" style="margin-top:6px">
          ${btn('ให้อาหารทั้งหมด', 'live-feed-all', 'btn-leaf')}
          ${btn('เก็บผลิตผลทั้งหมด', 'live-collect-all', 'btn-blue')}
          ${btn('ขายผลิตผล', 'live-sell', 'btn-gold')}
        </div>
      </div>`;

    const produceKeys = D.LIVESTOCK.filter((l) => G.produceCount(l.produce) > 0);
    if (produceKeys.length) {
      h += `<div class="section">ผลิตผลในตู้</div><div class="kv">`;
      produceKeys.forEach((l) => {
        h += `<div><span>${l.productName}</span><b>${G.produceCount(l.produce)} หน่วย (${money(l.sell)}/หน่วย)</b></div>`;
      });
      h += `</div>`;
    }

    if (S.livestock.length) {
      h += `<div class="section">สัตว์ในคอก</div><div class="list">`;
      S.livestock.forEach((l, i) => {
        const def = G.livestockDef(l.type) || {};
        h += `<div class="entry"><div class="grow">
          <div class="t">${l.type === 'chicken' ? '🐔' : l.type === 'cow' ? '🐄' : l.type === 'sheep' ? '🐑' : '🐐'} ${l.name}
            ${l.ready ? tag('มีผลผลิต', 'ok') : tag('รอผลผลิต')}</div>
          <div class="s">${l.fedDay === S.day ? 'ให้อาหารแล้ววันนี้' : 'ยังไม่ได้ให้อาหารวันนี้'} • ผลิต${def.productName || ''} ขาย ${money(def.sell || 0)}</div>
        </div>
          ${btn('ให้อาหาร', `live-feed:${i}`, 'btn-leaf', l.fedDay === S.day)}
          ${btn('เก็บ', `live-collect:${i}`, 'btn-blue', !l.ready)}</div>`;
      });
      h += `</div>`;
    }

    h += `<div class="section">ซื้อสัตว์เข้าคอก</div><div class="list">`;
    D.LIVESTOCK.forEach((l) => {
      h += `<div class="entry"><div class="grow">
        <div class="t">${l.name} <span class="dim">${money(l.price)}</span></div>
        <div class="s">${l.desc} • ผลิต${l.productName} ขาย ${money(l.sell)}</div>
      </div>
        ${btn('ซื้อ', `live-buy:${l.id}`, 'btn-brown', S.livestock.length >= 8 || S.money < l.price)}</div>`;
    });
    h += `</div>
      <div class="row" style="margin-top:10px">
        ${btn('🚌 ไปทุ่งเลี้ยงสัตว์', 'goto:ranch', 'btn-gold')}
        ${btn('🚇 ขึ้นรถไฟ', 'metro-open', 'btn-blue')}
      </div>`;
    return h;
  }

  /* ================= TAB: เวทมนตร์ ================= */
  function renderMagic() {
    const S = G.S;
    const maxMana = G.maxMana();
    const need = (S.magicLevel || 1) * 100;
    let h = '';

    h += `<div class="card">
      <div class="card-title"><span>✦ ${G.magicLevelTitle()} · เลเวล ${S.magicLevel}</span>${tag(S.guild ? 'สมาชิกกิลด์' : 'นักเวทอิสระ', S.guild ? 'ok' : '')}</div>
      <div class="dim">พลังเวท · ${S.mana}/${maxMana}</div>
      <div style="margin-top:6px">${bar((S.mana / maxMana) * 100, 'blue')}</div>
      <div class="dim" style="margin-top:4px">ประสบการณ์เวท ${S.magicXp}/${need}</div>
      <div style="margin-top:4px">${bar((S.magicXp / need) * 100, 'purple')}</div>
      <div class="row" style="margin-top:8px">
        ${btn('🧘 นั่งสมาธิ (+25 มานา)', 'magic-meditate', 'btn-blue')}
        ${btn(`💎 ขายคริสตัล (${S.crystals} เม็ด)`, 'magic-sell', 'btn-gold', !S.crystals)}
      </div>
    </div>`;

    h += `<div class="section">คาถาที่รู้</div><div class="list">`;
    D.SPELLS.forEach((sp) => {
      const known = S.spells.includes(sp.id);
      const locked = S.magicLevel < sp.level;
      const price = 800 + sp.level * 900;
      h += `<div class="entry"><div class="grow">
        <div class="t" style="color:${sp.color}">${sp.name} ${locked ? '🔒' : known ? '✦' : ''} <span class="dim">มานา ${sp.cost}</span></div>
        <div class="s">${sp.desc} • ต้องเลเวล ${sp.level}</div>
      </div>
        ${known ? btn('ร่าย', `spell-cast:${sp.id}`, 'btn-blue', (S.mana || 0) < sp.cost)
          : btn(`เรียน ${money(price)}`, `spell-buy:${sp.id}`, 'btn-brown', locked || S.money < price)}</div>`;
    });
    h += `</div>`;

    h += `<div class="section">คริสตัลวิเศษ</div>
      <div class="card">
        <div class="kv">
          <div><span>คริสตัลในครอบครอง</span><b>${S.crystals} เม็ด</b></div>
          <div><span>ราคาขาย</span><b>${money(D.CRYSTAL_SELL)}/เม็ด</b></div>
          <div><span>ขุดล่าสุด</span><b>${S.crystalDay === S.day ? 'วันนี้แล้ว' : 'ยังไม่ได้ขุดวันนี้'}</b></div>
        </div>
        <div class="row" style="margin-top:6px">
          ${btn('ขุดหาคริสตัล', 'magic-gather', 'btn-blue')}
          ${btn('ขายทั้งหมด', 'magic-sell', 'btn-gold', !S.crystals)}
        </div>
      </div>`;

    h += `<div class="section">กิลด์นักเวท</div>
      <div class="card">
        <div class="card-title"><span>🔮 กิลด์นักเวทใต้ดิน</span>${S.guild ? tag('เป็นสมาชิก', 'ok') : tag('ยังไม่สมัคร', 'bad')}</div>
        <div class="dim">ค่าสมาชิก ${money(D.GUILD_FEE)} • ต้องเลเวลเวท 2 • เข้าถึงบอสประจำเมือง</div>
        <div class="kv" style="margin-top:6px">
          <div><span>ชนะบอส</span><b>${S.bossWins || 0} ครั้ง</b></div>
          <div><span>ท้าบอสวันนี้</span><b>${S.bossDay === S.day ? 'แล้ว' : 'ยัง'}</b></div>
        </div>
        <div class="row" style="margin-top:6px">
          ${S.guild ? tag('เข้าร่วมแล้ว', 'ok') : btn(`สมัครกิลด์ ${money(D.GUILD_FEE)}`, 'magic-guild', 'btn-gold', S.magicLevel < 2 || S.money < D.GUILD_FEE)}
          ${btn('🐲 ท้าบอส (มานา 30)', 'magic-boss', 'btn-red', !S.guild || S.magicLevel < 3 || (S.mana || 0) < 30 || S.bossDay === S.day)}
        </div>
      </div>`;

    h += `<div class="row" style="margin-top:10px">
      ${btn('🚇 ไปเมืองใต้ดิน', 'metro-open', 'btn-blue')}
      ${btn('🛒 ร้านสัตว์วิเศษ', 'goto:underground', 'btn-brown')}
    </div>`;
    return h;
  }
  function renderWork() {
    const S = G.S;
    const job = G.jobData();
    let h = '';

    h += `<div class="card">
      <div class="card-title"><span>${job ? job.title : (S.retired ? 'เกษียณแล้ว' : 'ว่างงาน')}</span>
        ${job ? tag(`ระดับ ${S.jobLevel}`, 'ok') : tag('ไม่มีงาน', 'bad')}</div>
      <div class="dim">${job ? `เงินเดือน ${money(G.salary())}/เดือน • ประสิทธิภาพ ${S.performance}/100` : 'อายุ 18 ขึ้นไปจึงสมัครงานได้'}</div>
      ${job ? `<div style="margin-top:6px">${bar(S.performance)}</div>` : ''}
      <div class="row" style="margin-top:6px">
        ${job ? btn('ไปทำงาน', 'go-work', 'btn-gold') : ''}
        ${job ? btn('ลาออก', 'quit-job', 'btn-ghost') : ''}
        ${!job && !G.isChild() ? btn('รับจ้างรายวัน', 'go-work', 'btn-gold') : ''}
      </div>
    </div>`;

    h += `<div class="section">อาชีพที่เปิดรับ</div><div class="list">`;
    D.JOBS.forEach((j) => {
      const eduOk = S.edu >= j.edu, skillOk = S.skills[j.skill] >= j.skill_req;
      const ok = eduOk && skillOk && !G.isChild();
      h += `<div class="entry">
        <div class="grow">
          <div class="t">${j.title} <span class="dim">${money(j.salary)}/เดือน</span></div>
          <div class="s">ต้องมีความรู้ ${j.edu} • ${D.SKILL_DEFS[j.skill].name} ${j.skill_req}
            ${eduOk ? '' : ' • <span style="color:#b0483c">ความรู้ไม่พอ</span>'}
            ${skillOk ? '' : ' • <span style="color:#b0483c">ทักษะไม่พอ</span>'}</div>
        </div>
        ${S.jobId === j.id ? tag('ทำอยู่', 'ok') : btn('สมัคร', `apply:${j.id}`, 'btn-blue', !ok || !!S.jobId)}
      </div>`;
    });
    h += `</div>`;

    h += `<div class="section">ธนาคาร</div><div class="card">
      <div class="kv">
        <div><span>เงินสด</span><b>${money(S.money)}</b></div>
        <div><span>เงินออม</span><b>${money(S.bank)}</b></div>
        <div><span>หนี้สิน</span><b>${money(S.loan)}</b></div>
        <div><span>ทรัพย์สินสุทธิ</span><b>${money(G.netWorth())}</b></div>
      </div>
      <div class="row">
        <input id="bank-amount" type="number" min="0" step="100" placeholder="จำนวนเงิน" value="1000"
          style="flex:1;min-width:120px;border:2px solid #c8b490;border-radius:8px;padding:6px 8px;background:#fffaf0" />
      </div>
      <div class="row">
        ${btn('ฝาก', 'bank-deposit', 'btn-leaf')} ${btn('ถอน', 'bank-withdraw', 'btn-blue')}
        ${btn('กู้', 'bank-borrow', 'btn-brown')} ${btn('ชำระหนี้', 'bank-repay', 'btn-brown')}
        ${S.insurance ? tag('มีประกันสุขภาพ', 'ok') : btn('ทำประกัน ฿3,000', 'buy-insurance', 'btn-brown')}
      </div>
    </div>`;

    h += `<div class="section">การเงินรายเดือน</div><div class="kv">
      <div><span>รายได้</span><b>${money(G.monthlyIncome())}</b></div>
      <div><span>ค่าใช้จ่าย</span><b>${money(G.livingCost())}</b></div>
      <div><span>บิลรอบถัดไป</span><b>อีก ${28 - ((S.day - 1) % 28)} วัน</b></div>
      <div><span>จ่ายภาษีสะสม</span><b>${money(S.taxPaid)}</b></div>
    </div>`;

    const BIZ = G.BUSINESS || {};
    const branches = S.businessBranches || [];
    if (S.businessLevel > 0) {
      h += `<div class="section">ธุรกิจร้านค้า</div><div class="card">
        <div class="card-title"><span>🏪 ${S.businessName || 'ร้านของเรา'}</span>${tag(`ระดับ ${S.businessLevel}`, 'ok')}${tag(`สาขา ${G.branchCount()} แห่ง`)}</div>
        <div class="kv">
          <div><span>สต็อกหลัก</span><b>${S.businessStock}</b></div>
          <div><span>ราคาขาย</span><b>฿${S.businessPrice || BIZ.basePrice}</b></div>
          <div><span>พนักงาน</span><b>${S.businessStaff || 0}/3</b></div>
          <div><span>ยอดขายรวม</span><b>${money(S.businessSales)}</b></div>
          <div><span>ขายอัตโนมัติ</span><b>${S.businessStaff ? `~${Math.round((S.businessStaff * 5 + S.businessLevel * 3) * 0.9)} ชิ้น/วัน` : 'จ้างพนักงานก่อน'}</b></div>
          <div><span>เปิดร้านวันนี้</span><b>${S.businessDay === S.day ? 'แล้ว' : 'ยัง'}</b></div>
        </div>
        <div class="row" style="margin-top:6px">
          ${btn('เปิดร้าน', 'biz-run', 'btn-gold')}
          ${btn(`เติมสต็อก ${money(BIZ.restockCost || 600)}`, 'biz-restock', 'btn-brown')}
          ${btn('อัปเกรดร้าน', 'biz-upgrade', 'btn-blue')}
        </div>
        <div class="row">
          ${btn('ราคา −', 'biz-price-down', 'btn-ghost')}
          ${btn('ราคา +', 'biz-price-up', 'btn-ghost')}
          ${btn(`จ้างพนักงาน ${money(BIZ.staffHireCost || 3000)}`, 'biz-hire', 'btn-blue')}
          ${btn('เลิกจ้าง', 'biz-fire', 'btn-ghost')}
        </div>
        <div class="dim" style="margin-top:4px">ค่าแรง ฿${BIZ.staffWage || 180}/คน/วัน • ขายอัตโนมัติทุกครั้งที่จบวัน</div>
      </div>`;

      branches.forEach((b, i) => {
        h += `<div class="card">
          <div class="card-title"><span>🏬 ${b.name}</span>${tag(`ระดับ ${b.level}`, 'ok')}${tag(G.zoneName(b.zone))}</div>
          <div class="kv">
            <div><span>สต็อก</span><b>${b.stock}</b></div>
            <div><span>ราคา</span><b>฿${b.price}</b></div>
            <div><span>พนักงาน</span><b>${b.staff}/3</b></div>
            <div><span>ยอดขายสาขา</span><b>${money(b.sales)}</b></div>
          </div>
          <div class="row" style="margin-top:6px">
            ${btn('เปิดขายที่สาขา', `biz-branch-run:${i}`, 'btn-gold')}
            ${btn('เติมสต็อก', `biz-branch-restock:${i}`, 'btn-brown')}
            ${btn('อัปเกรด', `biz-branch-upgrade:${i}`, 'btn-blue')}
          </div>
          <div class="row">
            ${btn('ราคา −', `biz-branch-pdown:${i}`, 'btn-ghost')}
            ${btn('ราคา +', `biz-branch-pup:${i}`, 'btn-ghost')}
            ${btn(`จ้าง ${money(BIZ.staffHireCost || 3000)}`, `biz-branch-hire:${i}`, 'btn-blue')}
            ${btn('เลิกจ้าง', `biz-branch-fire:${i}`, 'btn-ghost')}
          </div>
          <div class="dim" style="margin-top:4px">${b.staff ? `ขายอัตโนมัติ ~${Math.round((b.staff * 5 + b.level * 3) * 0.9)} ชิ้น/วัน` : 'ยังไม่มีพนักงาน — ต้องมาเปิดขายเอง'}</div>
        </div>`;
      });

      const openZones = (D.BUS_ROUTES || []).map((r) => r.zone).filter((z) => !G.branchAt(z));
      h += `<div class="section">เปิดสาขาใหม่</div><div class="card">
        <div class="dim">เปิดได้สูงสุด ${G.businessCapacity()} สาขา (อัปเกรดร้านหลักเพื่อเพิ่ม) • แห่งละ ${money(BIZ.branchCost || 12000)}</div>
        <div class="row" style="margin-top:6px">
          ${openZones.map((z) => btn(G.zoneName(z), `biz-branch:${z}`, 'btn-blue', S.money < (BIZ.branchCost || 12000))).join('')}
        </div>
      </div>`;
    } else {
      h += `<div class="section">ธุรกิจ</div><div class="card">
        <div class="card-title"><span>🏪 เปิดร้านของตัวเอง</span>${tag('ยังไม่มีร้าน', 'bad')}</div>
        <div class="dim">เปิดร้านได้เมื่อมีเงิน ${money(G.COST.businessOpen)} — จากนั้นขายของทุกวัน เปิดสาขาเพิ่ม และจ้างพนักงานขายอัตโนมัติ</div>
        <div class="row">${btn(`เปิดร้าน ${money(G.COST.businessOpen)}`, 'biz-open', 'btn-gold')}</div>
      </div>`;
    }

    h += `<div class="section">ของที่จับได้</div><div class="card">
      <div class="dim">ปลา ${S.fishTotal} ตัว • แมลง ${S.bugTotal} ตัว</div>
      <div class="row">
        ${btn('ขายปลาทั้งหมด', 'sell-fish', 'btn-leaf')}
        ${btn('ขายแมลงทั้งหมด', 'sell-bug', 'btn-leaf')}
      </div></div>`;

    return h;
  }

  /* ================= TAB: บ้าน–สวน ================= */
  function renderHome() {
    const S = G.S;
    let h = '';

    h += `<div class="card">
      <div class="card-title"><span>บ้านระดับ ${S.homeLevel}</span>${tag(`ความอบอุ่น ${G.homeCozy()}`)}</div>
      <div class="dim">${S.homeItems.length ? 'มีเฟอร์นิเจอร์ ' + S.homeItems.length + ' ชิ้น' : 'ยังไม่มีเฟอร์นิเจอร์'}</div>
      <div class="row">
        ${S.homeLevel < 4 ? btn(`อัปเกรดบ้าน ${money([0, 6000, 15000, 30000][S.homeLevel])}`, 'home-upgrade', 'btn-gold') : tag('บ้านเต็มระดับ', 'ok')}
        ${btn('จัดปาร์ตี้ ฿1,000', 'party', 'btn-blue')}
      </div>
    </div>`;

    // ---- จัดบ้าน ----
    const placed = G.layoutList();
    const unplaced = G.unplacedItems();
    h += `<div class="section">จัดบ้าน</div><div class="card">
      <div class="card-title"><span>🛋 แต่งห้องนั่งเล่น</span>${tag(`วางแล้ว ${placed.length}/${S.homeItems.length}`)}</div>
      <div class="dim">เปิดโหมดจัดบ้านแล้วลากเฟอร์นิเจอร์ในห้องได้เลย หรือเลือกชิ้นแล้วกดหมุน/เก็บ</div>
      <div class="row" style="margin-top:6px">
        ${btn('เปิดโหมดจัดบ้าน', 'decor-mode', 'btn-gold', !placed.length)}
        ${btn('จัดอัตโนมัติ', 'decor-auto', 'btn-blue', !S.homeItems.length)}
      </div>
    </div>`;

    if (placed.length) {
      h += `<div class="list">`;
      placed.forEach((it) => {
        h += `<div class="entry"><div class="grow">
          <div class="t">${it.def.name}</div>
          <div class="s">ตำแหน่ง ${Math.round(it.x)},${Math.round(it.y)} • หมุน ${it.rot || 0}° • อบอุ่น +${it.def.cozy || 0}</div>
        </div>
          ${btn('เลือก', `decor-select:${it.id}`, 'btn-leaf')}
          ${btn('หมุน', `decor-rotate:${it.id}`, 'btn-brown')}
          ${btn('เก็บ', `decor-clear:${it.id}`, 'btn-ghost')}
        </div>`;
      });
      h += `</div>`;
    }
    if (unplaced.length) {
      h += `<div class="section">เฟอร์นิเจอร์ที่ยังไม่ได้วาง</div><div class="list">`;
      unplaced.forEach((id) => {
        const f = D.FURNITURE.find((x) => x.id === id) || { name: id, cozy: 0 };
        h += `<div class="entry"><div class="grow">
          <div class="t">${f.name} <span class="dim">อบอุ่น +${f.cozy || 0}</span></div>
          <div class="s">ยังอยู่ในกล่อง — วางในห้องเพื่อใช้งาน</div>
        </div>${btn('วางในห้อง', `decor-place:${id}`, 'btn-gold')}</div>`;
      });
      h += `</div>`;
    }

    h += `<div class="section">แปลงผัก</div><div class="list">`;
    S.farm.forEach((p, i) => {
      const crop = p.crop ? G.cropData(p.crop) : null;
      const ready = G.farmReady(i);
      h += `<div class="entry">
        <div class="grow">
          <div class="t">แปลง ${i + 1} ${crop ? '— ' + crop.name : '— ว่าง'}</div>
          <div class="s">${crop ? `โต ${p.growth}/${crop.days} วัน • ${p.watered ? 'รดน้ำแล้ววันนี้' : 'ยังไม่ได้รดน้ำ'} • ขาย ${money(crop.sell)}` : 'ยังไม่ได้ปลูกอะไร'}</div>
          ${crop ? bar(Math.min(100, (p.growth / crop.days) * 100)) : ''}
        </div>
        ${!crop ? btn('ปลูก', `plant-pick:${i}`, 'btn-leaf') : ''}
        ${crop && !p.watered && !ready ? btn('รดน้ำ', `plant-water:${i}`, 'btn-blue') : ''}
        ${ready ? btn('เก็บเกี่ยว', `plant-harvest:${i}`, 'btn-gold') : ''}
      </div>`;
      if (pendingPlot === i) {
        h += `<div class="entry" style="background:#f2ecd8;flex-direction:column;align-items:stretch">
          <div class="s" style="margin-bottom:4px">เลือกเมล็ดที่จะปลูก</div>
          <div class="row">` +
          D.CROPS.map((c) => btn(`${c.name} ฿${c.seed} (${c.days} วัน)`, `plant:${i}:${c.id}`, 'btn-brown', S.money < c.seed)).join('') +
          `</div></div>`;
      }
    });
    h += `</div>`;
    h += `<div class="row">${btn('รดน้ำทั้งหมด', 'water-all', 'btn-blue')}</div>`;

    h += `<div class="section">ร้านเฟอร์นิเจอร์</div><div class="list">`;
    D.FURNITURE.forEach((f) => {
      const own = S.homeItems.includes(f.id);
      h += `<div class="entry"><div class="grow">
        <div class="t">${f.name} <span class="dim">${money(f.price)}</span></div>
        <div class="s">${f.desc} • อบอุ่น +${f.cozy}</div></div>
        ${own ? tag('มีแล้ว', 'ok') : btn('ซื้อ', `furn:${f.id}`, 'btn-brown', S.money < f.price)}</div>`;
    });
    h += `</div>`;

    h += `<div class="section">ร้านเสื้อผ้า</div><div class="list">`;
    D.OUTFITS.filter((o) => o.price > 0).forEach((o) => {
      const own = S.ownedOutfits.includes(o.id);
      h += `<div class="entry"><div class="grow">
        <div class="t">${o.name} <span class="dim">${money(o.price)}</span></div>
        <div class="s">${o.desc} • เสน่ห์ +${o.charm}</div></div>
        ${own ? (S.outfit === o.id ? tag('ใส่อยู่', 'ok') : btn('สวม', `wear:${o.id}`, 'btn-leaf')) : btn('ซื้อ', `outfit:${o.id}`, 'btn-brown', S.money < o.price)}</div>`;
    });
    h += `</div>`;

    h += `<div class="section">ของสะสม</div><div class="card">
      <div class="dim">สะสมแล้ว ${Object.keys(S.collections).length}/12 ชนิด • ฤดูนี้เก็บได้ในย่านที่กำหนด</div>
      <div class="row" style="margin-top:6px">`;
    Object.keys(D.COLLECTIBLES).forEach((k) => {
      const c = D.COLLECTIBLES[k];
      h += `<span class="tag ${S.collections[k] ? 'ok' : ''}" title="${c.zone} • ${D.SEASON_NAMES[c.season]}">${S.collections[k] ? '✓ ' : '· '}${c.name}</span>`;
    });
    h += `</div></div>`;

    if (S.petName) {
      h += `<div class="section">แมว</div><div class="card">
        <div class="card-title"><span>🐱 ${S.petName}</span>${tag(`ความสุข ${S.catHappy}`)}</div>
        <div class="row">${btn('เล่นด้วย', 'cat-play', 'btn-leaf')} ${btn('ให้อาหาร ฿60', 'cat-feed', 'btn-brown')}</div>
      </div>`;
    }
    return h;
  }

  /* ================= TAB: ชีวิต ================= */
  function renderLife() {
    const S = G.S;
    let h = '';

    // ความสัมพันธ์
    h += `<div class="section">ความสัมพันธ์</div>`;
    if (S.partnerName) {
      h += `<div class="card">
        <div class="card-title"><span>💕 ${S.partnerName}</span>${tag(S.married ? 'แต่งงานแล้ว' : 'คนรัก', 'ok')}</div>
        <div class="dim">ความรัก ${Math.round(S.partnerLove)}/100</div>${bar(S.partnerLove)}
        <div class="row" style="margin-top:6px">
          ${!S.married ? btn('ขอแต่งงาน ฿5,000', 'propose', 'btn-gold', S.partnerLove < 60) : ''}
          ${S.married && !S.honeymoonDone ? btn('ฮันนีมูน ฿6,000', 'honeymoon', 'btn-gold') : ''}
          ${S.children.length < 2 ? btn('มีลูก ฿3,000', 'have-child', 'btn-blue') : ''}
          ${btn('ทริปครอบครัว ฿700', 'outing', 'btn-brown')}
        </div>
      </div>`;
    }

    h += `<div class="list">`;
    const here = G.npcsHere();
    if (here.length) {
      here.forEach((id) => {
        const n = D.NPCS[id];
        const fr = G.friendship(id);
        h += `<div class="entry"><div class="grow">
          <div class="t">${n.name} <span class="dim">ใจ ${fr}/100</span></div>
          ${bar(fr)}
          <div class="s">${n.dateable ? 'เดทได้' : 'เพื่อน/คนรู้จัก'}</div>
        </div>
          ${btn('คุย', `talk:${id}`, 'btn-leaf')}
          ${btn('ของขวัญ ฿150', `gift:${id}`, 'btn-brown')}
          ${n.dateable && !G.isChild() ? btn('เดท ฿300', `date:${id}`, 'btn-blue', fr < 30) : ''}
        </div>`;
      });
    } else {
      h += `<div class="entry"><div class="grow"><div class="s">ไม่มีคนรู้จักในย่านนี้ตอนนี้ — ลองไปสวนสาธารณะ คาเฟ่ หรือถนนบ้านเรา</div></div></div>`;
    }
    h += `</div>`;

    // ครอบครัว
    if (S.children.length) {
      h += `<div class="section">ลูกของเรา</div>`;
      S.children.forEach((c, i) => {
        const trait = D.CHILD_TRAITS.find((t) => t.id === c.trait) || D.CHILD_TRAITS[0];
        const stage = G.childStage(c);
        const emoji = stage === 'baby' ? '👶' : stage === 'kid' ? '🧒' : stage === 'teen' ? '🧑' : '🎓';
        const skinName = (D.SKIN_TONES.find((s) => s.id === c.skin) || {}).name || c.skin || '-';
        const hairName = (D.HAIR_STYLES.find((s) => s.id === c.hairStyle) || {}).name || c.hairStyle || '-';
        const happy = Math.round(c.happy === undefined ? 72 : c.happy);
        h += `<div class="card">
          <div class="card-title"><span>${emoji} ${c.name}</span>${tag(G.childStageName(c), 'ok')}${tag(c.gender)}</div>
          <div class="dim">อายุ ${c.age} ปี • นิสัย${trait.name} — ${trait.desc}</div>
          <div class="kv" style="margin-top:6px">
            <div><span>ความสุข</span><b>${happy}</b></div>
            <div><span>ทักษะ</span><b>${Math.round(c.skill || 0)}</b></div>
            <div><span>สีผิว</span><b>${skinName}</b></div>
            <div><span>ทรงผม</span><b>${hairName}</b></div>
            ${c.job ? `<div><span>อาชีพ</span><b>${c.job}</b></div>` : ''}
          </div>
          <div style="margin-top:6px">${bar(happy)}</div>
          <div class="row" style="margin-top:6px">
            ${btn('คุย', `child-talk:${i}`, 'btn-leaf')}
            ${btn('เล่นด้วย', `child-play:${i}`, 'btn-blue')}
            ${btn('ของขวัญ ฿150', `child-gift:${i}`, 'btn-brown')}
            ${btn('สอนการบ้าน', `child-study:${i}`, 'btn-gold', c.age < 5)}
          </div>
        </div>`;
      });
    }

    // ชมรม
    h += `<div class="section">ชมรมและเรียนพิเศษ</div>`;
    const club = D.CLUBS.find((c) => c.id === S.clubId);
    if (club) {
      h += `<div class="card">
        <div class="card-title"><span>${club.name}</span>${tag(`เลเวล ${S.clubLevel}`, 'ok')}</div>
        <div class="dim">แต้มชมรม ${S.clubPoints} • ทักษะ ${D.SKILL_DEFS[club.skill].name}</div>
        <div class="row">${btn('ทำกิจกรรม', 'club-activity', 'btn-gold')} ${btn('ออกจากชมรม', 'club-quit', 'btn-ghost')}</div>
      </div>`;
    } else {
      h += `<div class="list">` + D.CLUBS.map((c) => `<div class="entry">
        <div class="grow"><div class="t">${c.name} <span class="dim">฿${c.fee}</span></div><div class="s">${c.desc}</div></div>
        ${btn('เข้าร่วม', `club-join:${c.id}`, 'btn-blue', S.money < c.fee)}</div>`).join('') + `</div>`;
    }
    h += `<div class="row">${btn('เรียนพิเศษ ฿600', 'course', 'btn-brown', S.money < 600 || S.age < 10)}</div>`;

    // เทศกาล
    const fest = G.festivalToday();
    h += `<div class="section">เทศกาล</div><div class="card">
      <div class="card-title"><span>${fest ? fest.name : 'ยังไม่มีเทศกาลวันนี้'}</span>${fest ? tag(G.zoneName(fest.zone)) : ''}</div>
      <div class="dim">${fest ? fest.desc : `เทศกาลจัดทุกฤดู — ${D.FESTIVALS.map((f) => `${f.name} (${D.SEASON_NAMES[f.season]} วันที่ ${f.day})`).join(' • ')}`}</div>
      ${fest ? `<div class="row">${btn('ร่วมเทศกาล', 'festival', 'btn-gold')} ${btn('เล่นบูธ ฿50', 'booth', 'btn-brown')}</div>` : ''}
      <div class="dim" style="margin-top:6px">ชนะรางวัลแล้ว ${S.festivalWins} ครั้ง</div>
    </div>`;

    // เควสต์
    h += `<div class="section">ภารกิจสัปดาห์นี้</div><div class="list">`;
    S.quests.forEach((q) => {
      const c = S.questCounts[q.stat] || 0;
      h += `<div class="entry"><div class="grow">
        <div class="t">${q.name} <span class="dim">${Math.min(c, q.target)}/${q.target}</span></div>
        <div class="s">${q.desc} • รางวัล ${money(q.reward)}</div>
        ${bar(Math.min(100, (c / q.target) * 100))}
      </div>
        ${q.claimed ? tag('รับแล้ว', 'ok') : q.done ? btn('รับรางวัล', `quest:${q.id}`, 'btn-gold') : tag('กำลังทำ')}
      </div>`;
    });
    h += `</div>`;
    if (S.questCertificates.length) {
      h += `<div class="dim" style="margin-top:4px">ใบประกาศ: ${S.questCertificates.map((id) => (D.QUEST_CERTIFICATES.find((c) => c.id === id) || {}).name).join(', ')}</div>`;
    }

    // ความสำเร็จ
    const achDone = D.ACHIEVEMENTS.filter((a) => S.achievements[a.id]).length;
    h += `<div class="section">ความสำเร็จ ${achDone}/${D.ACHIEVEMENTS.length}</div><div class="list">`;
    D.ACHIEVEMENTS.forEach((a) => {
      const got = !!S.achievements[a.id];
      const claimed = !!(S.achievementClaimed || {})[a.id];
      h += `<div class="entry"><div class="grow">
        <div class="t">${got ? '🏆' : '🔒'} ${a.name}</div>
        <div class="s">${a.desc} • ${money(a.reward)}</div>
      </div>
        ${claimed ? tag('รับแล้ว', 'ok') : got ? btn('รับรางวัล', `ach:${a.id}`, 'btn-gold') : tag('ยังไม่ปลด')}
      </div>`;
    });
    h += `</div>`;

    // ตอนจบ
    const ending = G.lifeEnding();
    h += `<div class="section">ปลายทางชีวิต</div><div class="card">
      <div class="card-title"><span>${ending.title}</span><b>${Math.round(G.goalProgress())}%</b></div>
      <div class="dim">${ending.desc}</div>
      <div class="row" style="margin-top:6px">
        ${btn('บันทึกเกม', 'save', 'btn-leaf')}
        ${btn('เริ่มชีวิตใหม่', 'rebirth', 'btn-red')}
      </div>
    </div>`;

    return h;
  }

  /* ================= ตัวจัดการ action ================= */
  const ACT = {
    // แผนวัน
    'end-day': () => UI.feedback(G.sleepNow(6 * 60)),
    'show-event': () => UI.showEvent(),
    'save': () => { G.save(); UI.toast('💾 บันทึกแล้ว'); },

    // งาน/เรียน
    'go-work': () => startWork(),
    'quit-job': () => UI.feedback(G.quitJob()),
    'go-school': () => startSchool(),

    // บ้าน
    'home-upgrade': () => UI.feedback(G.upgradeHome()),
    'party': () => UI.feedback(G.throwParty()),
    'water-all': () => UI.feedback(G.farmWaterAll()),
    'cat-play': () => UI.feedback(G.playWithCat()),
    'cat-feed': () => UI.feedback(G.feedCat()),

    // เงิน
    'bank-deposit': () => UI.feedback(G.deposit(amount())),
    'bank-withdraw': () => UI.feedback(G.withdraw(amount())),
    'bank-borrow': () => UI.feedback(G.borrow(amount())),
    'bank-repay': () => UI.feedback(G.repay(amount())),
    'buy-insurance': () => UI.feedback(G.buyInsurance()),
    'sell-fish': () => UI.feedback(G.sellCatch('fish')),
    'sell-bug': () => UI.feedback(G.sellCatch('bug')),

    // ธุรกิจ
    'biz-open': () => UI.feedback(G.openBusiness()),
    'biz-run': () => UI.feedback(G.runBusiness()),
    'biz-restock': () => UI.feedback(G.restockBusiness()),
    'biz-upgrade': () => UI.feedback(G.upgradeBusiness()),
    'biz-price-up': () => UI.feedback(G.setBusinessPrice(20)),
    'biz-price-down': () => UI.feedback(G.setBusinessPrice(-20)),
    'biz-hire': () => UI.feedback(G.hireStaff()),
    'biz-fire': () => UI.feedback(G.fireStaff()),

    // ชีวิต
    'propose': () => UI.feedback(G.propose()),
    'honeymoon': () => UI.feedback(G.honeymoon()),
    'have-child': () => UI.feedback(G.haveChild()),
    'outing': () => UI.feedback(G.familyOuting()),
    'club-activity': () => UI.feedback(G.clubActivity()),
    'club-quit': () => { const r = G.quitClub ? G.quitClub() : { ok: true, message: 'ออกจากชมรมแล้ว' }; UI.feedback(r); },
    'course': () => UI.feedback(G.takeCourse()),
    'festival': () => startFestival(),
    'booth': () => UI.feedback(G.playBooth()),
    'rebirth': () => { if (confirm('เริ่มชีวิตใหม่? เซฟปัจจุบันจะถูกลบ')) { G.rebirth(); location.reload(); } },

    // สัตว์เลี้ยง / ฟาร์มปศุสัตว์
    'live-feed-all': () => { UI.feedback(G.feedAllLivestock()); UI.render('pets'); },
    'live-collect-all': () => { UI.feedback(G.collectAllProduce()); UI.render('pets'); },
    'live-sell': () => { UI.feedback(G.sellProduce()); UI.render('pets'); },

    // เวทมนตร์
    'magic-meditate': () => { UI.feedback(G.meditate()); UI.render('magic'); },
    'magic-sell': () => { UI.feedback(G.sellCrystals()); UI.render('magic'); },
    'magic-gather': () => { UI.feedback(G.gatherCrystal()); UI.render('magic'); },
    'magic-guild': () => { UI.feedback(G.joinGuild()); UI.render('magic'); },
    'magic-boss': () => { UI.feedback(G.challengeBoss()); UI.render('magic'); },
    'metro-open': () => { UI.openMetro(); },
  };

  function amount() {
    const i = document.getElementById('bank-amount');
    return i ? Number(i.value) : 0;
  }

  function onClick(e) {
    const b = e.target.closest('[data-action]');
    if (!b) return;
    const raw = b.dataset.action;
    const [action, a1, a2] = raw.split(':');

    // ---- plan ----
    if (action === 'plan-open') { openPlanPicker(a1); return; }
    if (action === 'plan-set') { UI.feedback(G.setPlan(a1, a2)); UI.render('today'); return; }
    if (action === 'plan-clear') { UI.feedback(G.setPlan(a1, null)); UI.render('today'); return; }

    // ---- dynamic ----
    if (action === 'train') { UI.feedback(G.trainSkill(a1)); return; }
    if (action === 'apply') { UI.feedback(G.applyJob(a1)); return; }
    if (action === 'wear') { UI.feedback(G.wearOutfit(a1)); return; }
    if (action === 'outfit') { UI.feedback(G.buyOutfit(a1)); return; }
    if (action === 'furn') { UI.feedback(G.buyFurniture(a1)); return; }
    if (action === 'plant-pick') { pendingPlot = Number(a1); UI.render('home'); return; }
    if (action === 'plant') { pendingPlot = -1; UI.feedback(G.farmPlant(Number(a1), a2)); return; }
    if (action === 'plant-water') { UI.feedback(G.farmWater(Number(a1))); return; }
    if (action === 'plant-harvest') { UI.feedback(G.farmHarvest(Number(a1))); return; }
    if (action === 'talk') { UI.feedback(G.talkNpc(a1)); return; }
    if (action === 'gift') { UI.feedback(G.giftNpc(a1)); return; }
    if (action === 'date') { UI.feedback(G.dateNpc(a1)); return; }
    if (action === 'child-talk') { UI.feedback(G.talkChild(Number(a1))); return; }
    if (action === 'child-play') { UI.feedback(G.playChild(Number(a1))); return; }
    if (action === 'child-gift') { UI.feedback(G.childGift(Number(a1))); return; }
    if (action === 'child-study') { UI.feedback(G.helpChildStudy(Number(a1))); return; }
    if (action === 'quest') { UI.feedback(G.claimQuest(a1)); return; }
    if (action === 'ach') { UI.feedback(G.claimAchievement(a1)); return; }
    if (action === 'club-join') { UI.feedback(G.joinClub(a1)); return; }
    if (action === 'accessory') { UI.feedback(G.wearAccessory(a1)); UI.render('character'); return; }
    if (action === 'exam-take') {
      UI.feedback(G.takeExam());
      UI.render('character');
      return;
    }

    // ---- pets ----
    if (action === 'pet-adopt') { UI.feedback(G.adoptPet(a1)); UI.render('pets'); return; }
    if (action === 'pet-feed') { UI.feedback(G.feedPet(Number(a1))); UI.render('pets'); return; }
    if (action === 'pet-play') { UI.feedback(G.playPet(Number(a1))); UI.render('pets'); return; }
    if (action === 'pet-rename') {
      const p = G.S.pets[Number(a1)];
      if (!p) return;
      const nm = prompt('ตั้งชื่อสัตว์เลี้ยง', p.name);
      if (nm) { UI.feedback(G.renamePet(Number(a1), nm)); UI.render('pets'); }
      return;
    }
    if (action === 'live-buy') { UI.feedback(G.buyLivestock(a1)); UI.render('pets'); return; }
    if (action === 'live-feed') { UI.feedback(G.feedLivestock(Number(a1))); UI.render('pets'); return; }
    if (action === 'live-collect') { UI.feedback(G.collectProduce(Number(a1))); UI.render('pets'); return; }

    // ---- magic ----
    if (action === 'spell-buy') { UI.feedback(G.buySpell(a1)); UI.render('magic'); return; }
    if (action === 'spell-cast') { UI.feedback(G.castSpell(a1)); UI.render('magic'); return; }

    // ---- เดินทางด่วน ----
    if (action === 'goto') {
      const r = G.travelTo(a1);
      UI.feedback(r);
      if (r.ok) UI.close();
      return;
    }

    // ---- metro ----
    if (action === 'metro-go') {
      const r = G.metroTravel(a1);
      UI.feedback(r);
      if (r.ok) UI.close();
      return;
    }
    if (action === 'metro-card') {
      UI.feedback(G.buyMetroCard());
      UI.openMetro();
      return;
    }
    if (action === 'metro-back') { UI.close(); return; }

    // ---- business branches ----
    if (action === 'biz-branch') { UI.feedback(G.openBranch(a1)); return; }
    if (action === 'biz-branch-run') { UI.feedback(G.branchAction(Number(a1), 'run')); return; }
    if (action === 'biz-branch-restock') { UI.feedback(G.branchAction(Number(a1), 'restock')); return; }
    if (action === 'biz-branch-hire') { UI.feedback(G.branchAction(Number(a1), 'hire')); return; }
    if (action === 'biz-branch-fire') { UI.feedback(G.branchAction(Number(a1), 'fire')); return; }
    if (action === 'biz-branch-upgrade') { UI.feedback(G.branchAction(Number(a1), 'upgrade')); return; }
    if (action === 'biz-branch-pup') { UI.feedback(G.branchAction(Number(a1), 'price-up')); return; }
    if (action === 'biz-branch-pdown') { UI.feedback(G.branchAction(Number(a1), 'price-down')); return; }

    // ---- home decor ----
    if (action === 'decor-mode') {
      if (UI.setDecorMode) { UI.close(); UI.setDecorMode(true); }
      else UI.toast('เปิดโหมดจัดบ้านได้ในตัวเกม');
      return;
    }
    if (action === 'decor-auto') { UI.feedback(G.autoLayoutHome()); return; }
    if (action === 'decor-select') {
      if (UI.setDecorMode) { UI.close(); UI.setDecorMode(true); UI.selectFurniture(a1); }
      return;
    }
    if (action === 'decor-rotate') { UI.feedback(G.rotateFurniture(a1)); return; }
    if (action === 'decor-clear') { UI.feedback(G.clearFurniture(a1)); return; }
    if (action === 'decor-place') {
      const spot = G.freeLayoutSpot();
      const r = G.placeFurniture(a1, spot.x, spot.y, 0);
      UI.feedback(r);
      if (UI.setDecorMode) { UI.close(); UI.setDecorMode(true); UI.selectFurniture(a1); }
      return;
    }

    // ---- bus ----
    if (action === 'bus-go') {
      const r = G.busTravel(a1);
      UI.feedback(r);
      if (r.ok) UI.close();
      return;
    }
    if (action === 'bus-back') { UI.close(); return; }

    const fn = ACT[raw];
    if (fn) { fn(); return; }
  }

  function onChange(e) {
    // ไม่มี select ในแผงตอนนี้
  }

  /* ================= รถเมล์ ================= */
  UI.openBus = () => {
    if (!G.S.created) return;
    el.wrap.classList.remove('hidden');
    el.modalTitle.textContent = '🚌 รถเมล์ประจำเมือง';
    el.tabs.innerHTML = '';
    const fare = G.isChild() ? G.COST.busChild : G.COST.bus;
    const zoneNow = G.S.zone;
    el.body.innerHTML = `<div class="section">ค่าโดยสาร ${money(fare)} • จาก${G.zoneName(zoneNow)}</div>
      <div class="list">` + G.busRoutes().map((r) => {
        const here = r.zone === zoneNow;
        return `<div class="entry"><div class="grow">
          <div class="t">${r.label}</div>
          <div class="s">${here ? 'คุณอยู่ย่านนี้แล้ว' : `นั่งรถเมล์ไป${r.label}`}</div>
        </div>${here ? tag('อยู่ที่นี่', 'ok') : btn('ไป', `bus-go:${r.zone}`, 'btn-gold', G.S.money < fare)}</div>`;
      }).join('') + `</div>`;
    el.foot.innerHTML = `<button class="btn btn-blue" data-action="metro-open">🚇 รถไฟใต้ดิน</button>
      <button class="btn btn-ghost" data-action="bus-back">ปิด</button>`;
  };

  /* ================= รถไฟใต้ดิน ================= */
  UI.openMetro = () => {
    if (!G.S.created) return;
    el.wrap.classList.remove('hidden');
    el.modalTitle.textContent = '🚇 รถไฟใต้ดิน';
    el.tabs.innerHTML = '';
    const S = G.S;
    const fare = S.metroCard ? 0 : (G.COST.metro || D.METRO_COST);
    const zoneNow = S.zone;
    const routes = G.metroRoutes();
    el.body.innerHTML = `<div class="card">
      <div class="card-title"><span>🎫 บัตรโดยสาร</span>${S.metroCard ? tag('มีบัตรแล้ว', 'ok') : tag('ยังไม่มีบัตร', 'bad')}</div>
      <div class="dim">${S.metroCard
        ? 'นั่งรถไฟได้ฟรีทุกเที่ยวตลอดชีพ'
        : `ค่าโดยสารเที่ยวละ ${money(fare)} หรือซื้อบัตร ${money(G.COST.metroCard || 500)} ใช้ได้ตลอดชีพ`}</div>
      <div class="kv" style="margin-top:6px">
        <div><span>เที่ยวที่นั่งแล้ว</span><b>${S.metroTrips || 0} เที่ยว</b></div>
        <div><span>ค่าโดยสารตอนนี้</span><b>${S.metroCard ? 'ฟรี' : money(fare)}</b></div>
      </div>
      ${S.metroCard ? '' : `<div class="row" style="margin-top:6px">${btn(`ซื้อบัตร ${money(G.COST.metroCard || 500)}`, 'metro-card', 'btn-gold', S.money < (G.COST.metroCard || 500))}</div>`}
    </div>
    <div class="section">สายสีน้ำเงิน · ทุกสถานี</div>
    <div class="list">` + routes.map((r) => {
      const here = r.zone === zoneNow;
      const metroHere = zoneNow === 'metro_station';
      return `<div class="entry"><div class="grow">
        <div class="t">${r.label}</div>
        <div class="s">${here ? 'คุณอยู่ที่นี่แล้ว' : `นั่งรถไฟไป${r.label}`}</div>
      </div>${here ? tag('อยู่ที่นี่', 'ok') : btn('ไป', `metro-go:${r.zone}`, 'btn-blue', S.money < fare && !metroHere)}</div>`;
    }).join('') + `</div>`;
    el.foot.innerHTML = `<button class="btn btn-ghost" data-action="metro-back">ปิด</button>`;
  };

  function openPlanPicker(slotId) {
    const slot = D.PLAN_SLOTS.find((s) => s.id === slotId);
    const child = G.isChild();
    const opts = child ? D.PLAN_CHILD_OPTIONS : D.PLAN_ADULT_OPTIONS;
    el.modalTitle.textContent = `เลือกกิจกรรม — ${slot.name}`;
    el.body.innerHTML = `<div class="section">ช่วง ${slot.name} (${String(slot.start / 60).padStart(2, '0')}:00–${slot.end / 60 >= 24 ? '24' : slot.end / 60}:00)</div>
      <div class="list">` + opts.map((id) => {
        const o = D.PLAN_OPTIONS[id];
        const reason = G.planBlockReason(slotId, id);
        return `<div class="entry"><div class="grow">
          <div class="t">${o.label}</div><div class="s">${o.hint}${reason ? ' • <span style="color:#b0483c">' + reason + '</span>' : ''}</div>
        </div>${btn('เลือก', `plan-set:${slotId}:${id}`, 'btn-gold', !!reason)}</div>`;
      }).join('') + `</div>`;
    el.foot.innerHTML = `<button class="btn btn-ghost" data-action="plan-back">ย้อนกลับ</button>`;
    el.foot.querySelector('[data-action]').addEventListener('click', () => UI.render('today'));
  }

  /* ================= มินิเกม ================= */
  function minigame({ title, subtitle, onDone }) {
    const overlay = document.createElement('div');
    overlay.className = 'mini-overlay';
    overlay.innerHTML = `<div class="mini-card">
      <h3>${title}</h3>
      <p>${subtitle || 'กดปุ่มเมื่อแถบเลื่อนอยู่กลางเป้า'}</p>
      <div class="mini-track"><div class="mini-zone"></div><div class="mini-cursor"></div></div>
      <div class="mini-result">—</div>
      <button class="btn btn-gold big mini-stop">หยุด!</button>
    </div>`;
    el.stage.appendChild(overlay);

    const cursor = overlay.querySelector('.mini-cursor');
    const result = overlay.querySelector('.mini-result');
    let pos = 6, dir = 1, speed = 78, running = true, score = 0, raf = 0, last = performance.now();

    const loop = (t) => {
      if (!running) return;
      const dt = Math.min(0.05, (t - last) / 1000); last = t;
      pos += dir * speed * dt;
      if (pos >= 100) { pos = 100; dir = -1; }
      if (pos <= 0) { pos = 0; dir = 1; }
      cursor.style.left = pos + '%';
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);

    const stop = () => {
      if (!running) return;
      running = false; cancelAnimationFrame(raf);
      const dist = Math.abs(pos - 50);
      score = Math.max(5, Math.round(100 - dist * 2.1));
      result.textContent = score >= 80 ? `✨ ${score} — สุดยอด!` : score >= 55 ? `${score} — ทำได้ดี` : `${score} — พอใช้`;
      overlay.querySelector('.mini-stop').textContent = 'ตกลง';
      overlay.querySelector('.mini-stop').addEventListener('click', finish, { once: true });
      setTimeout(finish, 900);
    };
    const finish = () => {
      overlay.remove();
      document.removeEventListener('keydown', key, true);
      onDone(score);
    };
    const key = (e) => {
      if (e.code === 'Space' || e.code === 'Enter') { e.preventDefault(); if (running) stop(); else finish(); }
    };
    document.addEventListener('keydown', key, true);
    overlay.querySelector('.mini-stop').addEventListener('click', stop, { once: true });
  }

  function startWork() {
    const blocked = G.workBlockReason();
    if (blocked) { UI.feedback({ ok: false, message: blocked }); return; }
    UI.close();
    minigame({
      title: 'กะทำงานวันนี้',
      subtitle: 'หยุดแถบให้อยู่กลางเป้า เพื่อเพิ่มประสิทธิภาพการทำงาน',
      onDone: (score) => UI.feedback(G.workShift(score)),
    });
  }
  function startSchool() {
    const blocked = G.schoolBlockReason();
    if (blocked) { UI.feedback({ ok: false, message: blocked }); return; }
    UI.close();
    minigame({
      title: 'ตั้งใจเรียน',
      subtitle: 'หยุดแถบกลางเป้าเพื่อทำเกรดให้ดีขึ้น',
      onDone: (score) => UI.feedback(G.attendSchool(score)),
    });
  }
  function startFestival() {
    const f = G.festivalToday();
    if (!f) { UI.feedback({ ok: false, message: 'วันนี้ไม่มีเทศกาล' }); return; }
    if (G.S.zone !== f.zone) { UI.feedback({ ok: false, message: `เทศกาลอยู่ที่${G.zoneName(f.zone)}` }); return; }
    if (G.S.festivalDone === G.S.day) { UI.feedback({ ok: false, message: 'วันนี้ร่วมเทศกาลแล้ว' }); return; }
    UI.close();
    minigame({
      title: f.name,
      subtitle: 'หยุดแถบให้อยู่กลางเป้าให้ได้คะแนน 65 ขึ้นไปเพื่อรับรางวัล',
      onDone: (score) => UI.feedback(G.attendFestival(score)),
    });
  }

  /* ================= กิจกรรมจากพร็อพ ================= */
  const PROP_FN = {
    sleep: () => G.sleepNow(6 * 60),
    study_desk: () => G.doHomework(),
    eat_home: () => G.eatHome(),
    dinner: () => G.familyDinner(),
    watch_tv: () => G.watchTv(),
    cook_meal: () => G.cookMeal(),
    craft_item: () => G.craftItem(),
    practice_art: () => G.practiceArt(),
    cat: () => G.playWithCat(),
    snow: () => G.sleepNow(6 * 60),
    fish: () => G.fish(),
    farm_plot: (p) => {
      const i = p.index;
      const plot = G.farmPlot(i);
      if (!plot.crop) { UI.open('home'); pendingPlot = i; UI.render('home'); return { ok: true, message: `เลือกเมล็ดที่จะปลูกในแปลง ${i + 1}` }; }
      if (G.farmReady(i)) return G.farmHarvest(i);
      return G.farmWater(i);
    },
    collect: () => G.collect(),
    bug: () => G.bug(),
    rest_bench: () => G.restBench(),
    festival: () => { UI.open('life'); return { ok: true, message: 'เปิดเทศกาล' }; },
    school: () => { startSchool(); return { ok: true, message: '' }; },
    lecture: () => G.studyLecture(),
    work: () => { startWork(); return { ok: true, message: '' }; },
    gym: () => G.gym(),
    hospital: () => { UI.open('character'); return { ok: true, message: 'เปิดแผงตัวละคร' }; },
    bank: () => { UI.open('work'); return { ok: true, message: 'เปิดธนาคาร' }; },
    shop_outfit: () => { UI.open('home'); return { ok: true, message: 'เปิดร้านเสื้อผ้า' }; },
    shop_furniture: () => { UI.open('home'); return { ok: true, message: 'เปิดร้านเฟอร์นิเจอร์' }; },
    buy_snack: () => G.buySnack(),
    buy_food: () => G.buyFood(),
    eat_cafe: () => G.eatCafe(),
    coffee: () => G.drinkCoffee(),
    drink: () => G.barDrink(),
    sit_rest: () => G.sitRest(),
    // ย่านใหม่
    street_food: () => G.streetFood(),
    buy_gift: () => G.buyGiftMarket(),
    busker: () => G.buskerTip(),
    boat_trip: () => G.boatTrip(),
    farm_work: () => G.farmWork(),
    bus: () => { UI.openBus(); return { ok: true, message: '', noFeedback: true }; },

    // ---- สถานีรถไฟ / ใต้ดิน ----
    metro_ride: () => { UI.openMetro(); return { ok: true, message: '', noFeedback: true }; },
    metro_gate: () => {
      if (G.S.metroCard) return { ok: true, message: '🎫 บัตรผ่านประตูได้เลย' };
      return { ok: false, message: 'ต้องมีบัตรโดยสารก่อน — ซื้อที่ตู้จำหน่ายบัตร' };
    },
    metro_card: () => G.buyMetroCard(),
    metro_up: () => {
      const r = G.travelTo('downtown');
      return r.ok ? { ok: true, message: 'ขึ้นบันไดไปดาวน์ทาวน์แล้ว' } : r;
    },

    // ---- ฟาร์มปศุสัตว์ / สัตว์เลี้ยง ----
    feed_all: () => G.feedAllLivestock(),
    livestock: () => { UI.open('pets'); return { ok: true, message: '', noFeedback: true }; },
    pet_care: () => { UI.open('pets'); return { ok: true, message: '', noFeedback: true }; },
    pet_shop: () => { UI.open('pets'); return { ok: true, message: '', noFeedback: true }; },

    // ---- เวทมนตร์ ----
    magic_shop: () => { UI.open('magic'); return { ok: true, message: '', noFeedback: true }; },
    crystal: () => G.gatherCrystal(),
    meditate: () => G.meditate(),
    boss: () => G.challengeBoss(),
    guild: () => G.joinGuild(),
  };

  UI.doProp = (action, prop) => {
    const fn = PROP_FN[action];
    if (!fn) return;
    const res = fn(prop);
    if (res) {
      if (res.noFeedback) { UI.refresh(true); return; }
      UI.feedback(res);
    }
  };

  /* ================= เหตุการณ์ ================= */
  UI.checkEvent = () => {
    if (!G.S.pendingEvent) return;
    if (!UI.isOpen()) UI.showEvent();
  };

  UI.showEvent = () => {
    const ev = G.S.pendingEvent;
    if (!ev) return;
    el.wrap.classList.remove('hidden');
    el.modalTitle.textContent = 'เหตุการณ์';
    el.tabs.innerHTML = '';
    el.body.innerHTML = `<div class="card" style="border-color:#b0483c;background:#fff6ee">
      <div class="card-title">❗ ${ev.text}</div>
      <div class="list" style="margin-top:8px">` +
      ev.options.map((o, i) => {
        const afford = (o.cost || 0) <= G.S.money;
        return `<div class="entry"><div class="grow">
          <div class="t">${o.label}</div>
          <div class="s">${o.cost ? `ใช้ ${money(o.cost)}` : 'ไม่มีค่าใช้จ่าย'}${o.chance !== undefined ? ` • โอกาสสำเร็จ ${Math.round(o.chance * 100)}%` : ''}${afford ? '' : ' • <span style="color:#b0483c">เงินไม่พอ</span>'}</div>
        </div><button class="btn sm btn-gold" data-evt="${i}" ${afford ? '' : 'disabled'}>เลือก</button></div>`;
      }).join('') + `</div></div>`;
    el.foot.innerHTML = '';
    el.body.querySelectorAll('[data-evt]').forEach((b) => {
      b.addEventListener('click', () => {
        const res = G.resolveEvent(Number(b.dataset.evt));
        el.tabs.innerHTML = TABS.map((t) => `<button class="tab" data-tab="${t.id}">${t.label}</button>`).join('');
        UI.feedback(res);
        UI.close();
      });
    });
  };

  /* ================= จบชีวิต ================= */
  UI.showGameOver = () => {
    if (!G.S.alive) {
      const end = G.lifeEnding();
      el.wrap.classList.remove('hidden');
      el.modalTitle.textContent = 'ชีวิตจบลง';
      el.tabs.innerHTML = '';
      el.body.innerHTML = `<div class="card" style="text-align:center">
        <div style="font-size:40px">🕯️</div>
        <h3 style="margin:6px 0">ชีวิตของ ${G.S.name}</h3>
        <div class="dim">${G.S.deathCause || 'จากไปอย่างสงบ'}</div>
        <div class="section" style="margin-top:14px">${end.title}</div>
        <div class="dim">${end.desc}</div>
        <div class="kv" style="margin-top:12px">
          <div><span>อายุ</span><b>${G.S.age} ปี</b></div>
          <div><span>วันที่เล่น</span><b>${G.S.daysPlayed} วัน</b></div>
          <div><span>ทรัพย์สินสุทธิ</span><b>${money(G.netWorth())}</b></div>
          <div><span>ความสำเร็จ</span><b>${D.ACHIEVEMENTS.filter((a) => G.S.achievements[a.id]).length}/${D.ACHIEVEMENTS.length}</b></div>
        </div>
        <div class="row" style="justify-content:center;margin-top:14px">
          <button class="btn btn-gold big" id="btn-rebirth2">เริ่มชีวิตใหม่</button>
        </div>
      </div>`;
      el.foot.innerHTML = '';
      document.getElementById('btn-rebirth2').addEventListener('click', () => {
        G.rebirth(); location.reload();
      });
    }
  };

  /* ================= หน้าสร้างตัวละคร ================= */
  UI.fillCreateForm = () => {
    const t = document.getElementById('c-trait');
    if (!t) return;
    t.innerHTML = D.PARENT_TRAITS.map((p) => `<option value="${p.id}">${p.name} — ${(D.KARMA_DEFS[p.karma] || {}).name || ''}</option>`).join('');
    document.getElementById('c-goal').innerHTML = D.LIFE_GOALS.map((g) => `<option value="${g.id}">${g.icon} ${g.name}</option>`).join('');
    document.getElementById('c-outfit').innerHTML = D.BIRTH_OUTFITS.map((o) => `<option value="${o.id}">${o.name}</option>`).join('');
    document.getElementById('c-skin').innerHTML = D.SKIN_TONES.map((s) => `<option value="${s.id}" ${s.id === 'warm' ? 'selected' : ''}>${s.name}</option>`).join('');
    document.getElementById('c-hair').innerHTML = D.HAIR_COLORS.map((s) => `<option value="${s.id}" ${s.id === 'black' ? 'selected' : ''}>${s.name}</option>`).join('');
    document.getElementById('c-style').innerHTML = D.HAIR_STYLES.map((s) => `<option value="${s.id}" ${s.id === 'long' ? 'selected' : ''}>${s.name}</option>`).join('');
    const accSel = document.getElementById('c-accessory');
    if (accSel) accSel.innerHTML = D.ACCESSORIES.map((a) => `<option value="${a.id}">${a.name}</option>`).join('');
    const update = () => {
      const p = D.PARENT_TRAITS.find((x) => x.id === t.value) || D.PARENT_TRAITS[0];
      document.getElementById('trait-desc').textContent = p.desc;
      drawPreview();
    };
    ['c-skin', 'c-hair', 'c-style', 'c-trait', 'c-gender', 'c-outfit', 'c-accessory'].forEach((id) => {
      const n = document.getElementById(id);
      if (n) n.addEventListener('change', update);
    });
    update();
  };

  function drawPreview() {
    const c = document.getElementById('preview');
    if (!c) return;
    const ctx = c.getContext('2d');
    const val = (id, fb) => { const n = document.getElementById(id); return n ? n.value : fb; };
    const skin = (D.SKIN_TONES.find((s) => s.id === val('c-skin', 'warm')) || D.SKIN_TONES[1]).hex;
    const hair = (D.HAIR_COLORS.find((s) => s.id === val('c-hair', 'black')) || D.HAIR_COLORS[0]).hex;
    const style = val('c-style', 'long');
    const gender = val('c-gender', 'หญิง');
    const outfit = val('c-outfit', 'casual') || 'casual';
    const accessory = val('c-accessory', 'none') || 'none';

    ctx.imageSmoothingEnabled = false;
    ctx.clearRect(0, 0, c.width, c.height);
    const g = ctx.createLinearGradient(0, 0, 0, c.height);
    g.addColorStop(0, '#bfe8ff');
    g.addColorStop(0.55, '#efe2c8');
    g.addColorStop(1, '#d8b98f');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, c.width, c.height);
    // little floor
    ctx.fillStyle = '#c8a878';
    ctx.fillRect(0, c.height - 18, c.width, 18);
    for (let i = 0; i < 6; i++) {
      ctx.fillStyle = i % 2 ? '#bfa070' : '#d4b888';
      ctx.fillRect(i * 22, c.height - 18, 12, 3);
    }
    R.drawSprite(ctx, c.width / 2, c.height - 14, {
      skin, hair, hairStyle: style, outfit, gender, scale: 2.9, frame: 0, t: 0, accessory,
    });
  }

  UI.collectCreate = () => {
    const val = (id) => { const n = document.getElementById(id); return n ? n.value : ''; };
    return {
      name: val('c-name') || 'โนเนม',
      gender: val('c-gender') || 'หญิง',
      wealth: Number(val('c-wealth')) || 0,
      trait: val('c-trait'),
      goal: val('c-goal'),
      outfit: val('c-outfit'),
      skin: val('c-skin'),
      hairColor: val('c-hair'),
      hairStyle: val('c-style'),
      accessory: val('c-accessory'),
    };
  };

  root.PLUI = UI;
})(window);
