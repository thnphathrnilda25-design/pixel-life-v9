/* Pixel Life — main.js
 * บูตเกม ลูปวาดภาพ อินพุตเดิน (WASD/ลูกศร/คลิก/dpad) และการโต้ตอบกับโลก
 */
(function () {
  'use strict';
  const D = window.PLData;
  const G = window.PLGame;
  const R = window.PLRender;
  const UI = window.PLUI;
  const S = G.S;

  const WALK_OUTDOOR = { min: 348, max: 522 };
  const WALK_INDOOR = { min: 172, max: 522 };
  const SPEED = 132;
  const DOOR_DIST = 54;
  const PROP_DIST = 62;
  const NPC_DIST = 52;

  let canvas, running = false, lastT = 0, saveTimer = 0;
  let player = { x: 470, y: 430, walk: 0, moving: false, facing: 'right', target: null };
  let npcs = [];
  let interact = null; // {type:'prop'|'door'|'npc'|'exit', ...}
  let activeProp = null;
  let decorMode = false;
  let decorSelected = null;
  let decorDrag = null;
  const keys = new Set();
  const dpad = { up: false, down: false, left: false, right: false };
  const $ = (id) => document.getElementById(id);

  /* ================= boot ================= */
  function boot() {
    canvas = $('game');
    R.init(canvas);
    UI.init();
    bindStartScreen();
    bindInput();
    if (G.hasSave()) {
      const c = $('btn-continue');
      c.classList.remove('hidden');
    }
    requestAnimationFrame(loop);
  }

  function bindStartScreen() {
    $('btn-new').addEventListener('click', () => {
      $('start-screen').classList.add('hidden');
      $('create-screen').classList.remove('hidden');
    });
    $('btn-howto').addEventListener('click', () => {
      $('howto').classList.toggle('hidden');
    });
    $('btn-continue').addEventListener('click', () => {
      if (!G.load()) { UI.toast('โหลดเซฟไม่สำเร็จ'); return; }
      beginGame();
    });
    $('btn-create-back').addEventListener('click', () => {
      $('create-screen').classList.add('hidden');
      $('start-screen').classList.remove('hidden');
    });
    $('btn-create-go').addEventListener('click', () => {
      const cfg = UI.collectCreate();
      G.startLife(cfg);
      beginGame();
    });
  }

  function beginGame() {
    $('start-screen').classList.add('hidden');
    $('create-screen').classList.add('hidden');
    const sp = (D.ZONES[S.zone] || D.ZONES.home).spawn;
    player.x = S.pos.x || sp.x;
    player.y = S.pos.y || sp.y;
    player.target = null;
    spawnNpcs(true);
    running = true;
    UI.refresh(true);
    UI.setDecorMode = setDecorMode;
    UI.selectFurniture = selectFurniture;
    UI.onDecorDone = () => { setDecorMode(false); UI.open('home'); };
    UI.onDecorRotate = () => {
      if (!decorSelected) { UI.toast('เลือกเฟอร์นิเจอร์ก่อน'); return; }
      UI.feedback(G.rotateFurniture(decorSelected));
      UI.setDecorUI(true, decorSelected);
    };
    UI.onDecorClear = () => {
      if (!decorSelected) { UI.toast('เลือกเฟอร์นิเจอร์ก่อน'); return; }
      const id = decorSelected;
      UI.feedback(G.clearFurniture(id));
      decorSelected = null;
      R.decorSelected = null;
      UI.setDecorUI(true, null);
    };
    UI.toast(`ชีวิตของ ${S.name} เริ่มต้นแล้ว — วางแผนวันนี้ก่อนออกไปข้างนอก`, 4200);
    UI.checkEvent();
    if (!S.alive) UI.showGameOver();
  }

  /* ================= decorate mode ================= */
  function nearestSlot(x, y) {
    let best = null, bd = Infinity;
    (G.HOME_SLOTS || []).forEach((s) => {
      const d = Math.hypot(s.x - x, s.y - y);
      if (d < bd) { bd = d; best = s; }
    });
    return best;
  }

  function setDecorMode(on, silent) {
    if (on && S.zone !== 'home') { UI.toast('จัดบ้านได้เฉพาะในบ้าน'); return; }
    decorMode = !!on;
    R.decorMode = decorMode;
    if (!decorMode) {
      decorDrag = null;
      decorSelected = null;
      R.decorSelected = null;
      player.target = null;
    }
    UI.setDecorUI(decorMode, decorSelected);
    if (!silent) UI.toast(decorMode ? 'โหมดจัดบ้าน: ลากเฟอร์นิเจอร์ หรือแตะช่องเพื่อย้าย' : 'ออกจากโหมดจัดบ้านแล้ว');
  }

  function selectFurniture(id) {
    decorSelected = id;
    R.decorSelected = id;
    UI.setDecorUI(true, id);
  }

  /* ================= input ================= */
  function bindInput() {
    window.addEventListener('keydown', (e) => {
      if (e.repeat) return;
      const typing = document.activeElement && ['INPUT', 'SELECT', 'TEXTAREA'].includes(document.activeElement.tagName);
      if (typing) return;
      if (UI.isOpen()) return;
      if (!running) return;

      if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) e.preventDefault();
      keys.add(e.code);

      if (e.code === 'KeyE' || e.code === 'Enter') { tryInteract(); return; }
      if (e.code === 'KeyM' || e.code === 'KeyB' || e.code === 'Tab') { e.preventDefault(); UI.open('today'); return; }
      if (e.code === 'Escape') { if (decorMode) setDecorMode(false); else UI.close(); return; }
    });
    window.addEventListener('keyup', (e) => keys.delete(e.code));
    window.addEventListener('blur', () => { keys.clear(); Object.keys(dpad).forEach((k) => (dpad[k] = false)); });

    canvas.addEventListener('pointerdown', (e) => {
      if (!running || UI.isOpen()) return;
      const p = R.toWorld(e.clientX, e.clientY);

      if (decorMode) {
        const hit = G.homePropAt(p.x, p.y);
        if (hit) {
          decorSelected = hit.id;
          R.decorSelected = hit.id;
          const pos = G.S.homeLayout[hit.id] || { x: hit.x, y: hit.y, rot: 0 };
          decorDrag = { id: hit.id, dx: pos.x - p.x, dy: pos.y - p.y };
          try { canvas.setPointerCapture(e.pointerId); } catch (err) { /* ignore */ }
          UI.setDecorUI(true, decorSelected);
        } else if (decorSelected && G.S.homeLayout[decorSelected]) {
          const slot = nearestSlot(p.x, p.y);
          const cur = G.S.homeLayout[decorSelected];
          if (slot) G.placeFurniture(decorSelected, slot.x, slot.y, cur.rot, true);
          UI.setDecorUI(true, decorSelected);
        }
        e.preventDefault();
        return;
      }

      player.target = p;
      player.facing = p.x < player.x ? 'left' : 'right';
    });

    canvas.addEventListener('pointermove', (e) => {
      if (!decorMode || !decorDrag) return;
      const p = R.toWorld(e.clientX, e.clientY);
      const cur = G.S.homeLayout[decorDrag.id] || { rot: 0 };
      G.placeFurniture(decorDrag.id, p.x + decorDrag.dx, p.y + decorDrag.dy, cur.rot, true);
      e.preventDefault();
    });

    const endDrag = () => {
      if (!decorDrag) return;
      const id = decorDrag.id;
      decorDrag = null;
      const pos = G.S.homeLayout[id];
      if (pos) G.placeFurniture(id, pos.x, pos.y, pos.rot);
      if (id) UI.toast(`วาง${(D.FURNITURE.find((f) => f.id === id) || {}).name || 'เฟอร์นิเจอร์'}แล้ว`);
    };
    canvas.addEventListener('pointerup', endDrag);
    canvas.addEventListener('pointercancel', endDrag);

    canvas.addEventListener('pointerleave', () => {
      if (decorDrag) endDrag();
    });

    document.querySelectorAll('#dpad button').forEach((b) => {
      const dir = b.dataset.dir;
      const on = (e) => { e.preventDefault(); dpad[dir] = true; player.target = null; };
      const off = () => { dpad[dir] = false; };
      b.addEventListener('pointerdown', on);
      b.addEventListener('pointerup', off);
      b.addEventListener('pointerleave', off);
      b.addEventListener('pointercancel', off);
    });

    $('btn-act').addEventListener('click', tryInteract);

    if (window.ResizeObserver) {
      new ResizeObserver(() => R.resize()).observe($('stage'));
    }
  }

  /* ================= interaction ================= */
  function tryInteract() {
    if (!running || UI.isOpen() || !S.alive || decorMode) return;
    if (!interact) { UI.toast('เดินเข้าไปใกล้สิ่งที่น่าสนใจก่อน'); return; }
    if (interact.type === 'npc') {
      UI.feedback(G.talkNpc(interact.id));
    } else if (interact.type === 'door') {
      const r = G.travelTo(interact.zone, interact.spawn);
      if (r.ok) onZoneChange();
    } else if (interact.type === 'exit') {
      const r = G.travelTo(interact.zone, interact.spawn);
      if (r.ok) onZoneChange();
    } else if (interact.type === 'prop') {
      const action = interact.prop.action || (interact.prop.type === 'bus' ? 'bus' : '');
      if (action === 'sleep') {
        if (S.timeMin < 18 * 60) { UI.toast('ยังไม่ถึงเวลานอน (นอนได้หลัง 18:00) — หรือกด “จบวัน” เพื่อข้ามวัน'); return; }
        UI.feedback(G.sleepNow(6 * 60));
        return;
      }
      UI.doProp(action, interact.prop);
    }
    UI.refresh(true);
  }

  function onZoneChange() {
    if (decorMode && S.zone !== 'home') setDecorMode(false, true);
    const sp = (D.ZONES[S.zone] || D.ZONES.home).spawn;
    player.x = S.pos.x || sp.x;
    player.y = S.pos.y || sp.y;
    player.target = null;
    activeProp = null;
    interact = null;
    spawnNpcs(true);
    UI.refresh(true);
  }

  /* ================= NPC ================= */
  function spawnNpcs(force) {
    const zone = D.ZONES[S.zone];
    if (!zone) { npcs = []; return; }
    const ids = G.npcsHere();
    const count = Math.max(1, ids.length);
    const spread = count > 1 ? 540 / (count - 1) : 0;
    npcs = ids.map((id, i) => {
      const def = D.NPCS[id] || {};
      const spot = def.spots && def.spots[0];
      const seed = Array.from(id).reduce((a, c) => a + c.charCodeAt(0), 0);
      const jitterX = (seed % 25) - 12;
      return {
        id,
        x: count > 1 ? 210 + i * spread + jitterX : 470 + jitterX,
        y: 392 + ((seed * 53) % 42) + (i % 2) * 26,
        walk: 0, moving: false, facing: 'right',
        baseX: 0, baseY: 0,
        phase: seed,
      };
    });
    npcs.forEach((n) => { n.baseX = n.x; n.baseY = n.y; });
  }

  /* ================= world objects ================= */
  function doorsOf(zone) {
    const out = [];
    (zone.doors || []).forEach((d) => out.push({ type: 'door', x: d.x, y: d.y, zone: d.zone, spawn: d.spawn, label: d.label }));
    (zone.buildings || []).forEach((b) => {
      if (b.door) out.push({
        type: 'door', x: b.door.x, y: b.y + b.h + 10, zone: b.door.zone,
        spawn: b.door.spawn, label: `เข้า${D.BUILDING_LABELS[b.door.zone] || b.name || 'อาคาร'}`,
      });
    });
    return out;
  }

  function nearestThing(zone) {
    let best = null, bestD = Infinity;
    const consider = (obj, dist) => { if (dist < bestD) { bestD = dist; best = obj; } };

    // props
    (zone.props || []).forEach((p) => {
      const action = p.action || (p.type === 'bus' ? 'bus' : '');
      if (!action) return;
      const d = Math.hypot(player.x - p.x, player.y - p.y);
      if (d < PROP_DIST) consider({ type: 'prop', prop: p }, d);
    });
    // furniture placed in the home
    if (S.zone === 'home' && G.homeProps) {
      G.homeProps().forEach((p) => {
        if (!p.action) return;
        const d = Math.hypot(player.x - p.x, player.y - p.y);
        if (d < PROP_DIST + 6) consider({ type: 'prop', prop: p }, d);
      });
    }
    // doors
    doorsOf(zone).forEach((d) => {
      const dist = Math.hypot(player.x - d.x, player.y - d.y);
      if (dist < DOOR_DIST) consider(d, dist);
    });
    // NPCs
    npcs.forEach((n) => {
      const d = Math.hypot(player.x - n.x, player.y - n.y);
      if (d < NPC_DIST) consider({ type: 'npc', id: n.id }, d);
    });
    // exits
    if (player.x < 16 && (zone.exits || []).some((e) => e.edge === 'left')) {
      const e = zone.exits.find((x) => x.edge === 'left');
      consider({ type: 'exit', zone: e.zone, spawn: e.spawn, label: `ไป${G.zoneName(e.zone)}` }, 10 + player.x);
    }
    if (player.x > 944 && (zone.exits || []).some((e) => e.edge === 'right')) {
      const e = zone.exits.find((x) => x.edge === 'right');
      consider({ type: 'exit', zone: e.zone, spawn: e.spawn, label: `ไป${G.zoneName(e.zone)}` }, 10 + (960 - player.x));
    }
    return best;
  }

  function promptFor(it) {
    if (!it) return '';
    if (it.type === 'npc') return `คุยกับ ${(D.NPCS[it.id] || {}).name || 'คนนี้'}`;
    if (it.type === 'door' || it.type === 'exit') return it.label || 'เข้าประตู';
    if (it.type === 'prop') {
      if (it.prop.type === 'bus' && !it.prop.label) return 'ขึ้นรถเมล์ไปย่านอื่น';
      return it.prop.label || 'ใช้สิ่งนี้';
    }
    return '';
  }

  /* ================= movement ================= */
  function walkableY(zone) {
    return zone.outdoor ? WALK_OUTDOOR : WALK_INDOOR;
  }

  function updatePlayer(dt, zone) {
    if (decorMode) { player.moving = false; return; }
    let dx = 0, dy = 0;
    if (keys.has('KeyA') || keys.has('ArrowLeft') || dpad.left) dx -= 1;
    if (keys.has('KeyD') || keys.has('ArrowRight') || dpad.right) dx += 1;
    if (keys.has('KeyW') || keys.has('ArrowUp') || dpad.up) dy -= 1;
    if (keys.has('KeyS') || keys.has('ArrowDown') || dpad.down) dy += 1;
    const usingKeys = dx !== 0 || dy !== 0;
    if (usingKeys) player.target = null;

    if (usingKeys) {
      const len = Math.hypot(dx, dy) || 1;
      player.x += (dx / len) * SPEED * dt;
      player.y += (dy / len) * SPEED * dt;
      if (dx !== 0) player.facing = dx < 0 ? 'left' : 'right';
      player.moving = true;
    } else if (player.target) {
      const tx = player.target.x, ty = player.target.y;
      const dx2 = tx - player.x, dy2 = ty - player.y;
      const dist = Math.hypot(dx2, dy2);
      if (dist < 5) { player.target = null; player.moving = false; }
      else {
        const step = Math.min(dist, SPEED * dt);
        player.x += (dx2 / dist) * step;
        player.y += (dy2 / dist) * step;
        if (Math.abs(dx2) > 2) player.facing = dx2 < 0 ? 'left' : 'right';
        player.moving = true;
      }
    } else {
      player.moving = false;
    }

    const lim = walkableY(zone);
    player.x = Math.max(24, Math.min(936, player.x));
    player.y = Math.max(lim.min, Math.min(lim.max, player.y));
    if (player.target) {
      player.target.x = Math.max(24, Math.min(936, player.target.x));
      player.target.y = Math.max(lim.min, Math.min(lim.max, player.target.y));
    }
    if (player.moving) player.walk += dt * 3.2;

    S.pos.x = Math.round(player.x);
    S.pos.y = Math.round(player.y);
  }

  function updateNpcs(dt) {
    const t = performance.now() / 1000;
    npcs.forEach((n) => {
      n.moving = false;
      const nx = n.baseX + Math.sin(t * 0.6 + n.phase) * 18;
      const ny = n.baseY + Math.cos(t * 0.45 + n.phase) * 8;
      if (Math.abs(nx - n.x) > 0.4) {
        n.facing = nx < n.x ? 'left' : 'right';
        n.moving = true;
        n.walk += dt * 2.4;
      }
      n.x = nx; n.y = ny;
    });
  }

  /* ================= loop ================= */
  function loop(t) {
    requestAnimationFrame(loop);
    const now = t || performance.now();
    const dt = Math.min(0.05, (now - (lastT || now)) / 1000);
    lastT = now;
    if (!canvas) return;

    if (!running) return;

    const zone = D.ZONES[S.zone] || D.ZONES.home;
    const wasZone = zone;

    updatePlayer(dt, zone);
    updateNpcs(dt);

    interact = nearestThing(zone);
    activeProp = interact && interact.type === 'prop' ? interact.prop : null;
    UI.setPrompt(promptFor(interact));

    R.draw(G, dt, player, npcs, activeProp);
    UI.refresh();

    saveTimer += dt;
    if (saveTimer > 15) { saveTimer = 0; G.save(); }

    // ตรวจเหตุการณ์ที่ยังไม่ถูกแสดง
    if (S.pendingEvent && !UI.isOpen()) {
      // แสดงเฉพาะครั้งเดียวต่อวัน (กันการเด้งซ้ำ)
      const key = 'evt-' + S.day + '-' + (S.pendingEvent.id || '');
      if (!window.__shownEvents) window.__shownEvents = {};
      if (!window.__shownEvents[key]) {
        window.__shownEvents[key] = true;
        setTimeout(() => UI.checkEvent(), 300);
      }
    }

    if (!S.alive) { running = false; UI.showGameOver(); }
  }

  /* ================= start ================= */
  window.PLWorld = {
    teleport(zone, x, y) {
      if (!D.ZONES[zone]) return false;
      S.zone = zone;
      const sp = D.ZONES[zone].spawn || { x: 470, y: 430 };
      player.x = x || sp.x;
      player.y = y || sp.y;
      S.pos = { x: Math.round(player.x), y: Math.round(player.y) };
      player.target = null;
      spawnNpcs(true);
      UI.refresh(true);
      return true;
    },
    setTime(min) { S.timeMin = min; UI.refresh(true); },
    decor(on) {
      if (on && S.zone !== 'home') this.teleport('home');
      setDecorMode(!!on, true);
      return decorMode;
    },
    selectFurniture(id) { selectFurniture(id); },
    give(n) { S.money += Number(n) || 0; G.save(); UI.refresh(true); },
    openTab(tab) { UI.open(tab); },
    openBus() { UI.openBus(); },
    closeUI() { UI.close(); },
    patch(obj) { Object.assign(S, obj); G.save(); UI.refresh(true); },
    state() { return S; },
  };

  G.on((type, data) => {
    if (type === 'day' || type === 'travel') {
      window.__shownEvents = window.__shownEvents || {};
    }
    if (type === 'travel') { onZoneChange(); }
    if (type === 'achievement' && data) UI.toast(`🏆 ความสำเร็จ: ${data.name}`, 3400);
    if (type === 'death') { running = false; setTimeout(() => UI.showGameOver(), 400); }
  });

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
