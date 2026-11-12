/* Pixel Life — render.js
 * วาดเมือง ตัวละคร เฟอร์นิเจอร์ และสภาพอากาศด้วย Canvas 2D ล้วน
 * Cozy 16-bit countryside: layered pixel characters, warm light and hand-painted scenery.
 */
(function (root) {
  'use strict';
  const D = root.PLData;
  const W = 960, H = 540;

  const R = {
    W, H, canvas: null, ctx: null, scale: 1, t: 0,
    weatherParticles: [], activeProp: null, decorMode: false, decorSelected: null,
  };

  /* ================= utils ================= */
  function hash(n) { const s = Math.sin(n * 127.1) * 43758.5453; return s - Math.floor(s); }
  function hexNum(hex) { const h = String(hex || '#000000').replace('#', ''); return parseInt(h.length === 3 ? h.split('').map((c) => c + c).join('') : h, 16); }
  function shade(hex, f) {
    if (typeof hex !== 'string' || hex[0] !== '#') return hex;
    const n = hexNum(hex);
    let r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
    r = Math.max(0, Math.min(255, Math.round(r * f)));
    g = Math.max(0, Math.min(255, Math.round(g * f)));
    b = Math.max(0, Math.min(255, Math.round(b * f)));
    return `rgb(${r},${g},${b})`;
  }
  function mix(a, b, t) {
    const na = hexNum(a), nb = hexNum(b);
    const ar = (na >> 16) & 255, ag = (na >> 8) & 255, ab = na & 255;
    const br = (nb >> 16) & 255, bg = (nb >> 8) & 255, bb = nb & 255;
    return `rgb(${Math.round(ar + (br - ar) * t)},${Math.round(ag + (bg - ag) * t)},${Math.round(ab + (bb - ab) * t)})`;
  }
  function alpha(hex, a) {
    const n = hexNum(hex);
    return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`;
  }
  function toneHex(id, list, fallback) {
    if (!id) return fallback;
    if (String(id)[0] === '#') return id;
    const t = (list || []).find((x) => x.id === id);
    return t ? t.hex : fallback;
  }

  const px = (x, y, w, h, color) => {
    R.ctx.fillStyle = color;
    R.ctx.fillRect(Math.round(x), Math.round(y), Math.round(w), Math.round(h));
  };
  const OUTLINE = '#3a3029';
  const INK = '#463832';
  const CREAM = '#fff7df';
  const GOLD = '#efca68';
  const FONT = '"Noto Sans Thai", "Leelawadee UI", "Segoe UI", sans-serif';

  R.init = (canvas) => {
    R.canvas = canvas;
    R.ctx = canvas.getContext('2d');
    R.ctx.imageSmoothingEnabled = false;
    R.resize();
    window.addEventListener('resize', R.resize);
  };
  R.resize = () => {
    const c = R.canvas;
    if (!c) return;
    const availW = c.parentElement.clientWidth, availH = c.parentElement.clientHeight;
    const scale = Math.min(availW / W, availH / H);
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    c.width = Math.round(W * scale * dpr);
    c.height = Math.round(H * scale * dpr);
    c.style.width = `${W * scale}px`;
    c.style.height = `${H * scale}px`;
    R.scale = scale * dpr;
    R.ctx.setTransform(R.scale, 0, 0, R.scale, 0, 0);
    R.ctx.imageSmoothingEnabled = false;
  };
  R.toWorld = (clientX, clientY) => {
    const r = R.canvas.getBoundingClientRect();
    return { x: (clientX - r.left) / (r.width / W), y: (clientY - r.top) / (r.height / H) };
  };

  /* ================= palettes ================= */
  const SKY = {
    suburb:   ['#78b8ce', '#c7e3d7', '#f4dfb0'],
    city:     ['#83b5c8', '#e5c9a7', '#f5e3bf'],
    park:     ['#78b9cb', '#c8e4ce', '#f6e7bd'],
    market:   ['#3c3449', '#8a5961', '#e0a16e'],
    harbor:   ['#72b9c9', '#c4e3dc', '#f4dfae'],
    farm:     ['#76b9d0', '#cee5c1', '#f7e5b3'],
    backyard: ['#79b7c8', '#c6e3c6', '#f6e8bd'],
    school:   ['#81bcd1', '#d2e7db', '#f3e3b9'],
    ranch:    ['#79b9cd', '#d0e5bf', '#f3e0ad'],
    underground: ['#51465b', '#71627a', '#9c806f'],
    metro:    ['#52535a', '#777873', '#a5a08b'],
  };
  const GROUND = {
    suburb: ['#80b76c', '#639a5a'], city: ['#a9a595', '#8d8978'],
    park: ['#79b267', '#5c9455'], market: ['#87765f', '#6d604e'],
    harbor: ['#d5bd91', '#b89c70'], farm: ['#88b75d', '#6e994c'],
    backyard: ['#82b66b', '#639b58'], school: ['#83b66e', '#659956'],
    ranch: ['#8db765', '#719653'],
    underground: ['#756777', '#5c5365'],
    metro: ['#77766d', '#62625b'],
  };
  const ROOF_TRIM = '#6a2f2b';

  /* ================= sprite system =================
   * วาดลงออฟสกรีน 32×32 แบบพิกเซลแท้ แล้วขยายด้วย nearest-neighbor
   */
  const SPRITE = 32;
  const spriteCache = new Map();

  const ROLE_STYLE = {
    teacher: 'teacher', doctor: 'doctor', nurse: 'nurse', boss: 'suit', banker: 'suit',
    shopkeeper: 'apron', barista: 'apron', clerk: 'apron', vendor: 'apron', florist: 'florist',
    athlete: 'athlete', coach: 'athlete', chef: 'chef', scholar: 'scholar', police: 'police',
    captain: 'captain', fisher: 'fisher', farmer: 'farmer', gardener: 'farmer',
    musician: 'musician', tourist: 'tourist', office: 'office', home: 'home', elder: 'elder',
    student: 'student', designer: 'designer', programmer: 'programmer',
    idol: 'idol', model: 'model', mechanic: 'mechanic', tailor: 'tailor',
    vampire: 'vampire', witch: 'witch', beast: 'beast', goblin: 'goblin',
    demon: 'demon', fairy: 'fairy', mage: 'mage', knight: 'knight',
    crystal_vendor: 'crystal_vendor', guildmaster: 'guildmaster',
    trainer: 'trainer', breeder: 'breeder',
  };
  const STYLE_CFG = {
    casual:    { sleeve: 'short', legs: 'pants', casual: true },
    student:   { sleeve: 'short', legs: 'skirt', collar: true, tie: true },
    sleep:     { sleeve: 'long', legs: 'pants', stripes: true },
    sport:     { sleeve: 'short', legs: 'shorts', stripe: true, headband: true },
    cozy:      { sleeve: 'long', legs: 'pants', knit: true, scarf: true },
    raincoat:  { sleeve: 'long', legs: 'pants', coat: true, hood: true },
    suit:      { sleeve: 'long', legs: 'pants', suit: true, tie: true },
    winter:    { sleeve: 'long', legs: 'pants', coat: true, scarf: true },
    thai:      { sleeve: 'long', legs: 'pants', sash: true },
    party:     { sleeve: 'short', legs: 'dress', bow: true },
    luxury:    { sleeve: 'long', legs: 'pants', suit: true, gold: true },
    baby:      { sleeve: 'short', legs: 'onesie', onesie: true },
    teacher:   { sleeve: 'long', legs: 'skirt', collar: true, glasses: true },
    doctor:    { sleeve: 'long', legs: 'pants', coat: true, white: true, stetho: true },
    nurse:     { sleeve: 'short', legs: 'pants', scrubs: true, nurseCap: true },
    chef:      { sleeve: 'long', legs: 'pants', white: true, chefHat: true, necker: true },
    apron:     { sleeve: 'long', legs: 'pants', apron: true },
    athlete:   { sleeve: 'short', legs: 'shorts', stripe: true, headband: true },
    police:    { sleeve: 'long', legs: 'pants', uniform: true, badge: true, policeCap: true },
    captain:   { sleeve: 'long', legs: 'pants', coat: true, uniform: true, captainHat: true },
    fisher:    { sleeve: 'long', legs: 'pants', coat: true, bucketHat: true },
    farmer:    { sleeve: 'long', legs: 'pants', overalls: true, strawHat: true },
    musician:  { sleeve: 'long', legs: 'pants', jacket: true, beanie: true },
    tourist:   { sleeve: 'short', legs: 'shorts', pattern: true, camera: true },
    office:    { sleeve: 'long', legs: 'pants', suit: true, tie: true },
    home:      { sleeve: 'long', legs: 'pants', cardigan: true },
    elder:     { sleeve: 'long', legs: 'pants', cardigan: true, glasses: true },
    scholar:   { sleeve: 'long', legs: 'pants', jacket: true, glasses: true },
    designer:  { sleeve: 'long', legs: 'pants', turtleneck: true, beret: true },
    programmer:{ sleeve: 'long', legs: 'pants', hoodie: true },
    florist:   { sleeve: 'long', legs: 'skirt', apron: true, flowerPin: true },
    // ---- สายแฟชั่น / แฟนตาซี ----
    idol:      { sleeve: 'short', legs: 'skirt', glitter: true, star: true, mic: true },
    goth:      { sleeve: 'long', legs: 'dress', goth: true, collar: true },
    punk:      { sleeve: 'short', legs: 'pants', spikes: true, stripe: true },
    mage:      { sleeve: 'long', legs: 'robe', robe: true, stars: true, wizardHat: true },
    knight:    { sleeve: 'long', legs: 'pants', armor: true, helmet: true },
    kimono:    { sleeve: 'long', legs: 'robe', obi: true, wideSleeve: true },
    crystal:   { sleeve: 'long', legs: 'dress', glitter: true, shimmer: true, tiara: true },
    mechanic:  { sleeve: 'long', legs: 'pants', overalls: true, cap: true, tape: false },
    tailor:    { sleeve: 'long', legs: 'pants', apron: true, tape: true },
    vampire:   { sleeve: 'long', legs: 'pants', suit: true, cape: true, collarHigh: true },
    witch:     { sleeve: 'long', legs: 'dress', goth: true, witchHat: true },
    beast:     { sleeve: 'short', legs: 'shorts', fur: true, ears: true },
    goblin:    { sleeve: 'short', legs: 'pants', goblin: true, ears: true },
    demon:     { sleeve: 'long', legs: 'pants', demon: true, horns: true, cape: true },
    fairy:     { sleeve: 'short', legs: 'dress', wings: true, glitter: true },
    model:     { sleeve: 'long', legs: 'dress', glitter: true, shades: true },
    guildmaster:{ sleeve: 'long', legs: 'robe', robe: true, gold: true, stars: true },
    crystal_vendor: { sleeve: 'long', legs: 'skirt', apron: true, glitter: true },
    trainer:   { sleeve: 'long', legs: 'pants', uniform: true, cap: true },
    breeder:   { sleeve: 'long', legs: 'pants', overalls: true, strawHat: true },
  };

  function resolveSpriteOpts(o) {
    const outfitId = o.outfit || (o.role ? '' : 'casual');
    const outfitCols = D.OUTFIT_COLORS[outfitId] || D.OUTFIT_COLORS.casual;
    const skin = toneHex(o.skin, D.SKIN_TONES, '#f2c39b');
    const hair = toneHex(o.hair || o.hairColor, D.HAIR_COLORS, '#3a2a1a');
    const styleId = o.role ? (ROLE_STYLE[o.role] || 'casual') : (D.OUTFIT_STYLE[outfitId] || 'casual');
    const cfg = STYLE_CFG[styleId] || STYLE_CFG.casual;
    const shirt = o.shirt || outfitCols[0];
    const pants = o.pants || outfitCols[1];
    const accent = o.accent || shade(shirt, .72);
    return {
      skin, hair, shirt, pants, accent,
      hairStyle: o.hairStyle || o.style || 'short',
      styleId, cfg,
      accessory: o.accessory || 'none',
      frame: (((o.frame | 0) % 4) + 4) % 4,
      moving: !!o.moving,
      blink: !!o.blink,
      gender: o.gender || '',
      scale: o.scale || 1.55,
      facing: o.facing === 'left' ? -1 : 1,
    };
  }

  function makeSprite(o) {
    const cv = document.createElement('canvas');
    cv.width = SPRITE; cv.height = SPRITE;
    const c = cv.getContext('2d');
    c.imageSmoothingEnabled = false;
    const P = (x, y, w, h, col) => { if (!col) return; c.fillStyle = col; c.fillRect(Math.round(x), Math.round(y), Math.round(w), Math.round(h)); };
    const ctx = { P, o };
    drawSpriteLayers(ctx);
    return cv;
  }

  function spriteFor(o) {
    const key = [o.skin, o.hair, o.hairStyle, o.shirt, o.pants, o.styleId, o.accessory, o.frame, o.blink ? 1 : 0, o.gender].join('~');
    if (spriteCache.has(key)) return spriteCache.get(key);
    const cv = makeSprite(o);
    spriteCache.set(key, cv);
    if (spriteCache.size > 420) {
      const first = spriteCache.keys().next().value;
      spriteCache.delete(first);
    }
    return cv;
  }

  function drawSpriteLayers(g) {
    const o = g.o, P = g.P;
    const cfg = o.cfg;
    const skin = o.skin, skinD = shade(skin, .84), skinL = shade(skin, 1.07);
    const hair = o.hair, hairD = shade(hair, .68), hairL = shade(hair, 1.2);
    const shirt = o.shirt, shirtD = shade(shirt, .78), shirtL = shade(shirt, 1.18);
    const pants = o.pants, pantsD = shade(pants, .76);
    const accent = o.accent;
    const shoe = '#3a2632';
    const frame = o.frame;
    const walking = o.moving;
    const bob = walking && (frame === 1 || frame === 3) ? -1 : 0;
    const legShift = walking ? [1, 0, -1, 0][frame] : 0;
    const armShift = walking ? [-1, 0, 1, 0][frame] : 0;

    // ---- hair / hood behind body ----
    drawBackHair(P, o, hair, hairD);
    if (cfg.cape) drawCape(P, o, cfg, shirtD, accent);
    if (cfg.wings || o.accessory === 'wings') drawWings(P, o, cfg);
    if (cfg.hood || cfg.hoodie) drawHoodBack(P, cfg, shirt, shirtD);

    // ---- legs ----
    drawLegs(P, o, cfg, { pants, pantsD, skin, skinD, shoe, legShift });

    // ---- torso ----
    drawTorso(P, o, cfg, {
      shirt, shirtD, shirtL, pants, pantsD, accent, skin, skinD, hairD,
    });

    // ---- arms ----
    drawArms(P, o, cfg, { shirt, shirtD, skin, skinD, armShift, sleeve: cfg.sleeve });

    // ---- head ----
    // neck
    P(14, 15, 4, 3, skinD);
    P(14, 16, 4, 2, skin);
    // head outline + skin
    P(9, 5, 14, 12, OUTLINE);
    P(10, 6, 12, 10, skin);
    // jaw shade
    P(10, 14, 12, 2, skinD);
    P(11, 15, 10, 1, skin);
    // ears
    P(8, 10, 2, 4, OUTLINE); P(22, 10, 2, 4, OUTLINE);
    P(8, 11, 2, 3, skin); P(22, 11, 2, 3, skin);
    // cheeks / nose
    P(11, 13, 2, 1, shade(skin, .92));
    P(19, 13, 2, 1, shade(skin, .92));
    P(15, 12, 2, 1, skinD);
    // mouth
    P(15, 14, 2, 1, '#a85a62');

    // eyes
    if (o.blink) {
      P(12, 11, 3, 1, INK); P(17, 11, 3, 1, INK);
    } else {
      P(12, 10, 3, 3, INK); P(17, 10, 3, 3, INK);
      P(12, 10, 1, 1, '#fffdf0'); P(17, 10, 1, 1, '#fffdf0');
      P(14, 12, 1, 1, '#6f8171'); P(19, 12, 1, 1, '#6f8171');
      P(13, 11, 1, 1, '#a7c6bb'); P(18, 11, 1, 1, '#a7c6bb');
    }
    // gentle cheek color and a tiny smile make the portrait read clearly at game scale
    P(10, 13, 2, 1, '#df9b87'); P(20, 13, 2, 1, '#df9b87');
    P(14, 15, 1, 1, '#c87973'); P(16, 15, 1, 1, '#c87973');
    // eyebrows
    P(12, 8, 3, 1, hairD); P(17, 8, 3, 1, hairD);

    // ---- front hair ----
    drawFrontHair(P, o, hair, hairD, hairL);
    if (cfg.ears) drawBeastEars(P, o, hair, hairD);
    if (cfg.horns) drawHorns(P, o);

    // ---- clothes details / accessories ----
    drawAccessories(P, o, cfg, { shirt, shirtD, shirtL, pants, pantsD, accent, skin, hairD, skinD });
    drawWornAccessory(P, o, cfg, { shirt, shirtD, shirtL, pants, pantsD, accent, skin, hairD, skinD, hair, hairL });

    // ---- hat ----
    drawHat(P, o, cfg, { shirt, shirtD, pants, accent, hairD });
    void bob;
  }

  /* ================= sprite layers ================= */
  function drawBackHair(P, o, hair, hairD) {
    const s = o.hairStyle;
    if (s === 'long') {
      P(8, 8, 4, 17, hairD);
      P(21, 8, 4, 17, hairD);
      P(9, 10, 2, 13, hair);
      P(22, 10, 2, 13, hair);
    } else if (s === 'bob') {
      P(8, 8, 3, 9, hairD);
      P(21, 8, 3, 9, hairD);
    } else if (s === 'ponytail') {
      P(22, 8, 4, 8, hairD);
      P(24, 13, 3, 6, hairD);
    } else if (s === 'curly') {
      P(8, 8, 3, 6, hairD);
      P(21, 8, 3, 6, hairD);
    } else if (s === 'braids') {
      P(6, 9, 4, 8, hairD);
      P(22, 9, 4, 8, hairD);
      P(6, 15, 4, 4, hairD); P(22, 15, 4, 4, hairD);
      P(7, 18, 3, 4, hairD); P(22, 18, 3, 4, hairD);
      P(7, 22, 3, 2, '#ffd24a'); P(22, 22, 3, 2, '#ffd24a');
    } else if (s === 'twintails') {
      P(5, 9, 4, 7, hairD);
      P(23, 9, 4, 7, hairD);
      P(4, 14, 5, 9, hairD);
      P(23, 14, 5, 9, hairD);
      P(5, 21, 4, 3, shade(hairD, .9));
      P(23, 21, 4, 3, shade(hairD, .9));
      P(6, 9, 2, 2, '#e85a9a'); P(24, 9, 2, 2, '#e85a9a');
    } else if (s === 'wavy') {
      P(7, 9, 4, 11, hairD);
      P(21, 9, 4, 11, hairD);
      P(6, 17, 5, 5, hairD);
      P(21, 17, 5, 5, hairD);
      P(7, 21, 4, 4, hairD);
      P(21, 21, 4, 4, hairD);
      P(8, 23, 3, 2, shade(hairD, .82));
      P(21, 23, 3, 2, shade(hairD, .82));
    } else if (s === 'afro') {
      P(5, 3, 22, 8, hairD);
      P(3, 6, 26, 9, hairD);
      P(6, 4, 6, 5, hairD);
      P(13, 1, 7, 4, hairD);
      P(20, 3, 6, 5, hairD);
    } else if (s === 'pixie') {
      P(8, 8, 3, 5, hairD);
      P(21, 8, 3, 5, hairD);
      P(10, 6, 12, 3, hairD);
    } else if (s === 'mohawk') {
      P(13, 0, 7, 8, hairD);
      P(15, 0, 3, 5, hairD);
    } else if (s === 'side') {
      P(7, 8, 4, 13, hairD);
      P(8, 18, 3, 4, hairD);
    }
  }

  function drawHoodBack(P, cfg, shirt, shirtD) {
    if (!cfg.hood && !cfg.hoodie) return;
    P(6, 5, 20, 12, OUTLINE);
    P(7, 6, 18, 10, shirtD);
    P(8, 6, 16, 3, shade(shirt, .9));
    P(6, 15, 20, 3, shirtD);
  }

  /* ---- ผ้าคลุม / ปีก / หูสัตว์ / เขา ---- */
  function drawCape(P, o, cfg, shirtD, accent) {
    const col = cfg.demon ? '#2e1a2e' : cfg.vampire ? '#7a1e32' : shade(shirtD, .7);
    P(6, 16, 20, 3, col);
    P(5, 18, 4, 12, col);
    P(23, 18, 4, 12, col);
    P(7, 29, 18, 2, shade(col, .82));
    P(5, 18, 2, 12, shade(col, 1.18));
    P(25, 18, 2, 12, shade(col, .85));
    if (cfg.collarHigh) {
      P(11, 15, 10, 3, '#241a2a');
      P(12, 14, 8, 1, '#3a2a34');
      P(14, 17, 4, 1, accent);
    }
    void o;
  }

  function drawWings(P, o, cfg) {
    const col = cfg.fairy ? '#e8faff' : '#f6f0ff';
    const edge = cfg.fairy ? '#a8e8f0' : '#d8c8f0';
    P(5, 15, 4, 10, OUTLINE); P(5, 16, 3, 8, col); P(6, 17, 1, 3, edge);
    P(3, 20, 4, 7, OUTLINE); P(4, 21, 2, 5, col);
    P(23, 15, 4, 10, OUTLINE); P(24, 16, 3, 8, col); P(25, 17, 1, 3, edge);
    P(25, 20, 4, 7, OUTLINE); P(26, 21, 2, 5, col);
    void o;
  }

  function drawBeastEars(P, o, hair, hairD) {
    const goblin = o.styleId === 'goblin';
    const col = goblin ? shade(o.skin, .92) : hair;
    const dark = shade(col, .68);
    const inner = o.styleId === 'beast' ? '#ffb0c8' : shade(o.skin, .82);
    P(8, 0, 6, 7, OUTLINE); P(9, 1, 4, 5, col); P(10, 2, 2, 3, inner); P(9, 5, 2, 2, dark);
    P(18, 0, 6, 7, OUTLINE); P(19, 1, 4, 5, col); P(20, 2, 2, 3, inner); P(21, 5, 2, 2, dark);
  }

  function drawHorns(P, o) {
    const col = o.styleId === 'demon' ? '#e8d8c8' : '#d8c8a8';
    P(8, 0, 4, 5, OUTLINE); P(9, 0, 2, 4, col); P(8, 3, 3, 2, shade(col, .8));
    P(20, 0, 4, 5, OUTLINE); P(21, 0, 2, 4, col); P(21, 3, 3, 2, shade(col, .8));
    P(9, 0, 1, 2, '#fff6e0'); P(21, 0, 1, 2, '#fff6e0');
  }

  /* ---- เครื่องประดับที่ผู้เล่นเลือก ---- */
  function drawWornAccessory(P, o, cfg) {
    const id = o.accessory;
    if (!id || id === 'none' || id === 'wings') return;
    const hasHat = !!(cfg.wizardHat || cfg.witchHat || cfg.helmet || cfg.strawHat || cfg.cap ||
      cfg.policeCap || cfg.chefHat || cfg.nurseCap || cfg.beanie || cfg.beret ||
      cfg.bucketHat || cfg.captainHat || cfg.headband);
    if (id === 'glasses') {
      P(11, 10, 4, 3, '#2a1a24'); P(17, 10, 4, 3, '#2a1a24');
      P(12, 11, 2, 1, '#bfe8ff'); P(18, 11, 2, 1, '#bfe8ff');
      P(15, 11, 2, 1, '#2a1a24'); P(9, 11, 2, 1, '#2a1a24'); P(21, 11, 2, 1, '#2a1a24');
    } else if (id === 'eyepatch') {
      P(17, 9, 4, 4, '#2a1a24'); P(18, 10, 2, 2, '#1a1018');
      P(9, 9, 8, 1, '#2a1a24'); P(21, 9, 3, 1, '#2a1a24');
    } else if (id === 'mask') {
      P(11, 11, 4, 3, '#f6f0e0'); P(17, 11, 4, 3, '#f6f0e0');
      P(15, 12, 2, 2, '#e8dcc8'); P(12, 14, 8, 2, '#f6f0e0'); P(13, 15, 6, 1, '#d8ccb8');
    } else if (id === 'scarf') {
      P(10, 16, 12, 2, '#e05a7a'); P(10, 17, 12, 1, shade('#e05a7a', .8));
      P(18, 18, 3, 6, '#e05a7a'); P(18, 23, 3, 1, shade('#e05a7a', .75));
      P(11, 16, 4, 1, shade('#e05a7a', 1.25));
    } else if (id === 'headphones') {
      P(8, 4, 2, 8, '#3a3a4a'); P(22, 4, 2, 8, '#3a3a4a');
      P(9, 2, 14, 2, '#3a3a4a');
      P(7, 9, 4, 5, '#5a5a6a'); P(21, 9, 4, 5, '#5a5a6a');
      P(8, 10, 2, 3, '#8a8a9a'); P(22, 10, 2, 3, '#8a8a9a');
    } else if (id === 'catEars' || id === 'wolfEars') {
      const col = id === 'catEars' ? '#3a2a3a' : '#6a6a7a';
      const inner = id === 'catEars' ? '#ff9ac8' : '#c8c8d8';
      P(8, 1, 5, 6, OUTLINE); P(9, 2, 3, 4, col); P(10, 3, 1, 2, inner);
      P(19, 1, 5, 6, OUTLINE); P(20, 2, 3, 4, col); P(21, 3, 1, 2, inner);
    } else if (id === 'horns') {
      P(9, 0, 3, 5, OUTLINE); P(10, 0, 1, 4, '#a81e3a'); P(9, 3, 2, 2, '#7a1028');
      P(20, 0, 3, 5, OUTLINE); P(21, 0, 1, 4, '#a81e3a'); P(21, 3, 2, 2, '#7a1028');
    } else if (id === 'halo') {
      P(10, 0, 12, 2, '#ffd24a'); P(11, 1, 10, 1, '#fff6c0');
      P(9, 1, 1, 1, '#ffd24a'); P(22, 1, 1, 1, '#ffd24a');
    } else if (!hasHat && id === 'cap') {
      P(9, 2, 14, 5, OUTLINE); P(10, 3, 12, 3, '#3a6ac8');
      P(8, 6, 17, 2, '#2a4a9a'); P(11, 3, 4, 1, '#6a9ae8');
    } else if (!hasHat && id === 'beanie') {
      P(9, 1, 14, 7, OUTLINE); P(10, 2, 12, 5, '#d86a8a');
      P(10, 6, 12, 2, '#b84a6a'); P(14, 0, 4, 2, '#e88aa8');
    } else if (!hasHat && id === 'witchHat') {
      P(4, 5, 24, 4, OUTLINE); P(5, 6, 22, 2, '#2a1a3a');
      P(10, 0, 12, 6, OUTLINE); P(11, 1, 10, 5, '#2a1a3a');
      P(13, 5, 6, 2, '#7a3aa8'); P(15, 5, 2, 2, '#ffd24a');
      P(12, 2, 3, 1, '#4a2a5a');
    } else if (id === 'crown') {
      P(9, 1, 14, 4, OUTLINE); P(10, 2, 12, 2, '#ffd24a');
      P(10, 0, 2, 3, '#ffd24a'); P(15, 0, 2, 4, '#ffd24a'); P(20, 0, 2, 3, '#ffd24a');
      P(13, 2, 1, 1, '#e04a5a'); P(16, 2, 1, 1, '#4ac8e8'); P(19, 2, 1, 1, '#8ae06a');
    }
  }

  function drawLegs(P, o, cfg, col) {
    const { pants, pantsD, skin, skinD, shoe } = col;
    const shift = col.legShift || 0;
    const kind = cfg.legs;
    const legY = 25;
    const leftX = 12 + (shift > 0 ? 1 : 0);
    const rightX = 17 + (shift < 0 ? -1 : 0);

    const putLeg = (x, colr, shoeY) => {
      P(x - 1, legY - 1, 5, 7, OUTLINE);
      P(x, legY, 3, 4, colr);
      P(x, legY + 4, 3, 2, colr);
      P(x - 1, shoeY, 5, 2, shoe);
      P(x, shoeY, 4, 1, shade(shoe, 1.4));
    };

    if (kind === 'shorts' || kind === 'onesie') {
      const legCol = kind === 'onesie' ? (o.cfg.onesie ? o.shirt : pants) : skin;
      putLeg(leftX, legCol, shift > 0 ? 29 : 30);
      putLeg(rightX, legCol, shift < 0 ? 29 : 30);
      if (kind === 'shorts') {
        P(11, 25, 10, 1, OUTLINE);
        P(11, 24, 10, 2, pants);
        P(11, 25, 4, 2, pantsD);
        P(17, 25, 4, 2, pantsD);
      }
    } else if (kind === 'skirt' || kind === 'dress') {
      putLeg(leftX, skin, shift > 0 ? 29 : 30);
      putLeg(rightX, skin, shift < 0 ? 29 : 30);
      P(11, 24, 4, 2, skinD);
      P(17, 24, 4, 2, skinD);
    } else if (kind === 'robe') {
      putLeg(leftX, skin, shift > 0 ? 29 : 30);
      putLeg(rightX, skin, shift < 0 ? 29 : 30);
      P(11, 24, 4, 2, skinD);
      P(17, 24, 4, 2, skinD);
      P(11, 26, 4, 1, shade(pants, .9));
      P(17, 26, 4, 1, shade(pants, .9));
    } else {
      putLeg(leftX, pants, shift > 0 ? 29 : 30);
      putLeg(rightX, pants, shift < 0 ? 29 : 30);
      P(11, 24, 10, 1, OUTLINE);
      P(11, 24, 4, 1, pantsD);
      P(17, 24, 4, 1, pantsD);
    }
  }

  function drawTorso(P, o, cfg, col) {
    const { shirt, shirtD, shirtL, pants, pantsD, accent, skin, hairD } = col;
    // base body
    P(10, 17, 12, 8, OUTLINE);
    P(11, 18, 10, 7, shirt);
    P(11, 18, 10, 1, shirtL);
    P(19, 18, 2, 7, shirtD);
    // collar / neck
    P(14, 17, 4, 1, shade(shirt, .62));

    if (cfg.onesie) {
      P(11, 18, 10, 7, shirt);
      P(13, 24, 1, 1, CREAM); P(16, 24, 1, 1, CREAM); P(19, 24, 1, 1, CREAM);
      P(13, 18, 6, 2, shade(shirt, 1.14));
    }

    if (cfg.stripes) {
      P(12, 20, 8, 1, shade(shirt, 1.28));
      P(12, 22, 8, 1, shade(shirt, 1.28));
      P(12, 24, 8, 1, shade(shirt, .86));
    }
    if (cfg.stripe) {
      P(11, 20, 10, 2, accent);
      P(11, 20, 10, 1, shade(accent, 1.2));
      P(15, 23, 2, 2, CREAM);
    }
    if (cfg.knit) {
      P(12, 21, 8, 1, shade(shirt, .82));
      P(12, 23, 8, 1, shade(shirt, 1.12));
    }
    if (cfg.pattern) {
      const dots = [[12, 20], [16, 22], [19, 20], [14, 24], [18, 24]];
      dots.forEach(([x, y], i) => P(x, y, 1, 1, i % 2 ? '#ffd24a' : '#ff7aa8'));
    }
    if (cfg.suit || cfg.jacket || cfg.cardigan || cfg.uniform || cfg.turtleneck) {
      P(15, 19, 1, 6, shade(shirt, .62));
      P(12, 18, 2, 2, shirtL); P(18, 18, 2, 2, shirtL);
      P(14, 18, 4, 2, CREAM);
      P(15, 20, 2, 2, accent);
      if (cfg.suit || cfg.jacket) {
        P(11, 24, 10, 1, shade(shirt, .58));
      }
      if (cfg.cardigan) {
        P(16, 20, 1, 1, GOLD); P(16, 22, 1, 1, GOLD); P(16, 24, 1, 1, GOLD);
      }
      if (cfg.turtleneck) {
        P(13, 17, 6, 2, shirt);
        P(13, 17, 6, 1, shade(shirt, 1.25));
      }
    }
    if (cfg.apron) {
      P(12, 18, 1, 3, accent);
      P(19, 18, 1, 3, accent);
      P(12, 20, 8, 6, accent);
      P(13, 22, 6, 1, shade(accent, 1.22));
      P(14, 24, 4, 2, shade(accent, .78));
    }
    if (cfg.overalls) {
      P(12, 18, 2, 2, pants);
      P(18, 18, 2, 2, pants);
      P(13, 19, 6, 6, pants);
      P(13, 19, 6, 1, shade(pants, 1.18));
      P(13, 20, 1, 1, GOLD); P(18, 20, 1, 1, GOLD);
    }
    if (cfg.coat) {
      P(10, 18, 2, 8, shirtD);
      P(20, 18, 2, 8, shirtD);
      P(15, 22, 1, 4, shade(shirt, .58));
      P(14, 20, 1, 1, GOLD); P(17, 21, 1, 1, GOLD); P(14, 23, 1, 1, GOLD);
    }
    if (cfg.legs === 'skirt') {
      P(9, 24, 14, 2, pants);
      P(8, 26, 16, 2, pants);
      P(11, 27, 10, 1, pantsD);
      P(9, 24, 14, 1, shade(pants, 1.18));
    }
    if (cfg.legs === 'dress') {
      P(10, 23, 12, 2, shirt);
      P(9, 25, 14, 2, shirt);
      P(10, 27, 12, 1, shade(shirt, .82));
      P(9, 26, 14, 1, accent);
      P(12, 23, 2, 1, shade(shirt, 1.22));
    }
    if (cfg.robe || cfg.legs === 'robe') {
      const robeD = shade(shirt, .8);
      P(9, 22, 14, 3, shirt);
      P(8, 25, 16, 3, shirt);
      P(9, 27, 14, 1, robeD);
      P(8, 28, 16, 1, shade(shirt, .7));
      P(15, 18, 2, 9, robeD);
      if (cfg.robe) {
        P(10, 23, 2, 1, GOLD); P(13, 24, 2, 1, GOLD); P(19, 23, 3, 1, GOLD);
        P(10, 26, 3, 1, shade(GOLD, .82)); P(18, 26, 3, 1, shade(GOLD, .82));
      }
      if (cfg.stars) {
        [[11, 22], [18, 23], [13, 26], [20, 26], [9, 24]].forEach(([x, y], i) => {
          P(x, y, 1, 1, i % 2 ? '#fff6c0' : GOLD);
        });
      }
    }
    if (cfg.obi) {
      P(10, 19, 12, 3, accent);
      P(10, 19, 12, 1, shade(accent, 1.25));
      P(10, 21, 12, 1, shade(accent, .78));
      P(15, 18, 4, 2, shade(accent, .85));
      P(15, 21, 4, 1, shade(accent, .7));
      P(16, 22, 2, 2, shade(accent, .9));
    }
    if (cfg.armor) {
      P(10, 17, 12, 7, OUTLINE);
      P(11, 18, 10, 5, '#c8d8e8');
      P(11, 18, 10, 1, '#eef6ff');
      P(15, 19, 1, 5, '#8a9aa8');
      P(12, 20, 3, 1, '#9aaaba'); P(18, 20, 3, 1, '#9aaaba');
      P(9, 17, 4, 3, OUTLINE); P(9, 17, 4, 2, '#a8b8c8');
      P(19, 17, 4, 3, OUTLINE); P(19, 17, 4, 2, '#a8b8c8');
      P(12, 17, 1, 1, GOLD); P(19, 17, 1, 1, GOLD);
      P(14, 22, 4, 1, GOLD);
    }
    if (cfg.spikes) {
      P(9, 15, 2, 3, '#c8c8d8'); P(12, 14, 2, 3, '#c8c8d8');
      P(18, 14, 2, 3, '#c8c8d8'); P(21, 15, 2, 3, '#c8c8d8');
      P(10, 16, 1, 2, '#5a5a6a'); P(13, 15, 1, 2, '#5a5a6a');
      P(19, 15, 1, 2, '#5a5a6a'); P(22, 16, 1, 2, '#5a5a6a');
      P(16, 18, 2, 5, '#8a8a9a'); P(17, 18, 1, 5, '#c8c8d8');
    }
    if (cfg.glitter) {
      [[11, 19], [14, 21], [18, 19], [20, 23], [12, 24], [17, 24]].forEach(([x, y], i) => {
        P(x, y, 1, 1, i % 2 ? '#fff6c0' : '#ffd24a');
      });
      P(21, 20, 1, 1, '#ffe8ff');
    }
    if (cfg.goth) {
      P(11, 18, 1, 5, '#2a1a2e');
      P(19, 18, 1, 5, '#2a1a2e');
      P(12, 18, 8, 1, '#2a1a2e');
      P(14, 19, 4, 3, '#2a1a2e');
      P(15, 19, 2, 2, accent);
      P(11, 22, 10, 1, '#3a2a3e');
      P(13, 23, 6, 1, '#2a1a2e');
      P(18, 24, 2, 2, '#2a1a2e');
    }
    if (cfg.star) {
      P(15, 19, 2, 1, GOLD);
      P(14, 20, 4, 1, GOLD);
      P(13, 21, 6, 1, GOLD);
      P(14, 22, 4, 1, GOLD);
      P(13, 23, 2, 1, '#fff2a0'); P(17, 23, 2, 1, '#fff2a0');
      P(15, 20, 1, 1, '#fffbe0');
    }
    if (cfg.goblin) {
      P(11, 19, 10, 5, '#6a7a3a');
      P(11, 19, 10, 1, '#8a9a4a');
      P(13, 21, 1, 1, '#c8b86a'); P(16, 22, 1, 1, '#c8b86a'); P(19, 21, 1, 1, '#c8b86a');
      P(11, 23, 10, 1, '#4a3a24');
      P(15, 23, 2, 1, GOLD);
      P(10, 24, 2, 2, '#5a4a2a'); P(19, 24, 2, 2, '#5a4a2a');
    }
    if (cfg.demon) {
      P(10, 18, 12, 7, '#3a1a2e');
      P(11, 18, 10, 1, '#5a2a3e');
      P(13, 20, 2, 2, '#e04a5a'); P(17, 20, 2, 2, '#e04a5a');
      P(14, 23, 4, 1, '#e04a5a');
      P(12, 22, 1, 1, '#ff8a6a'); P(19, 22, 1, 1, '#ff8a6a');
      P(15, 19, 2, 1, '#ffd24a');
    }
    if (cfg.tape) {
      P(11, 18, 10, 2, '#ffe08a');
      P(11, 19, 10, 1, '#e8c86a');
      P(14, 20, 4, 5, '#ffe08a');
      P(15, 20, 2, 5, '#e8c86a');
      P(14, 22, 4, 1, '#c8a84a');
      P(14, 24, 4, 1, '#c8a84a');
    }
    if (cfg.fur) {
      P(10, 16, 12, 3, hairD);
      P(11, 17, 10, 1, shade(hairD, 1.28));
      P(9, 17, 2, 5, hairD);
      P(21, 17, 2, 5, hairD);
      P(12, 18, 8, 1, shade(hairD, 1.12));
    }
    if (cfg.shimmer) {
      P(12, 19, 1, 6, 'rgba(255,255,255,.45)');
      P(18, 20, 1, 5, 'rgba(180,240,255,.4)');
      P(11, 23, 10, 1, 'rgba(255,255,255,.3)');
      P(20, 21, 1, 1, '#ffffff');
      P(11, 20, 1, 1, '#eaffff');
    }
    if (cfg.sash) {
      P(11, 19, 4, 1, GOLD);
      P(14, 20, 4, 1, GOLD);
      P(17, 21, 3, 1, GOLD);
      P(11, 22, 10, 1, shade(GOLD, .8));
    }
    if (cfg.scrubs) {
      P(14, 18, 4, 2, CREAM);
      P(15, 20, 2, 1, shade(shirt, .7));
      P(12, 23, 2, 1, CREAM);
    }
    if (cfg.chef) {
      P(12, 19, 1, 1, '#5a5a6a'); P(16, 19, 1, 1, '#5a5a6a'); P(18, 21, 1, 1, '#5a5a6a');
    }
    if (cfg.doctor) {
      P(11, 18, 3, 8, CREAM);
      P(18, 18, 3, 8, CREAM);
      P(14, 18, 4, 1, shirt);
      P(12, 22, 3, 1, shade(CREAM, .9));
    }
    // belt
    if (cfg.uniform) {
      P(11, 23, 10, 1, '#2a2030');
      P(15, 23, 2, 1, GOLD);
    }
    void hairD; void skin; void shirtL;
  }

  function drawArms(P, o, cfg, col) {
    const { shirt, shirtD, skin, skinD } = col;
    const shift = col.armShift || 0;
    if (cfg.wideSleeve) {
      // แขนเสื้อกว้างแบบกิโมโน
      const la = 17 + shift, ra = 17 - shift;
      P(4, la, 8, 11, OUTLINE);
      P(5, la + 1, 6, 9, shirt);
      P(5, la + 1, 2, 9, shade(shirt, 1.18));
      P(9, la + 2, 2, 8, shade(shirt, .82));
      P(6, la + 8, 4, 2, shade(shirt, .72));
      P(6, la + 10, 3, 2, skin);
      P(6, la + 11, 3, 1, skinD);
      P(20, ra, 8, 11, OUTLINE);
      P(21, ra + 1, 6, 9, shirt);
      P(21, ra + 1, 2, 9, shade(shirt, 1.1));
      P(25, ra + 2, 2, 8, shirtD);
      P(22, ra + 8, 4, 2, shade(shirt, .72));
      P(23, ra + 10, 3, 2, skin);
      P(23, ra + 11, 3, 1, skinD);
      return;
    }
    const long = cfg.sleeve === 'long';
    const la = 18 + shift;
    const ra = 18 - shift;
    const armH = long ? 7 : 4;
    // left
    P(7, la - 1, 4, armH + 2, OUTLINE);
    P(8, la, 3, armH, shirt);
    P(8, la, 1, armH, shade(shirt, 1.15));
    P(8, la + armH, 3, long ? 2 : 4, skin);
    if (!long) P(8, la + 2, 3, 1, shirtD);
    // right
    P(21, ra - 1, 4, armH + 2, OUTLINE);
    P(21, ra, 3, armH, shirt);
    P(22, ra, 1, armH, shirtD);
    P(21, ra + armH, 3, long ? 2 : 4, skin);
    if (!long) P(21, ra + 2, 3, 1, shirtD);
    // hands
    P(8, la + armH + (long ? 2 : 4), 3, 1, skinD);
    P(21, ra + armH + (long ? 2 : 4), 3, 1, skinD);
  }

  function drawFrontHair(P, o, hair, hairD, hairL) {
    const s = o.hairStyle;
    // cap base
    P(9, 4, 14, 5, hairD);
    P(10, 4, 12, 4, hair);
    P(11, 4, 5, 1, hairL);

    if (s === 'short') {
      P(9, 7, 3, 4, hairD);
      P(20, 7, 3, 4, hairD);
      P(10, 8, 3, 2, hair);
      P(15, 8, 2, 1, hair);
      P(18, 8, 3, 2, hair);
      P(12, 4, 5, 1, hairL);
    } else if (s === 'bob') {
      P(8, 5, 16, 7, hairD);
      P(9, 5, 14, 5, hair);
      P(8, 9, 4, 8, hairD); P(20, 9, 4, 8, hairD);
      P(9, 9, 2, 7, hair); P(21, 9, 2, 7, hair);
      P(10, 9, 12, 1, hairD);
      P(11, 5, 5, 1, hairL);
    } else if (s === 'long') {
      P(8, 5, 16, 7, hairD);
      P(9, 5, 14, 5, hair);
      P(8, 9, 4, 11, hairD); P(20, 9, 4, 11, hairD);
      P(9, 9, 2, 10, hair); P(21, 9, 2, 10, hair);
      P(10, 9, 12, 1, hairD);
      P(12, 5, 6, 1, hairL);
    } else if (s === 'ponytail') {
      P(9, 5, 14, 3, hairD);
      P(10, 5, 12, 2, hair);
      P(9, 7, 3, 4, hairD); P(20, 7, 3, 4, hairD);
      P(10, 8, 5, 1, hair); P(16, 8, 4, 1, hair);
      // ponytail
      P(22, 7, 5, 9, OUTLINE);
      P(23, 8, 3, 7, hair);
      P(24, 9, 1, 4, hairL);
      P(22, 14, 4, 2, accentHairTie(o));
      P(12, 5, 4, 1, hairL);
    } else if (s === 'bun') {
      P(9, 7, 14, 3, hairD);
      P(10, 7, 12, 2, hair);
      P(9, 8, 2, 3, hairD); P(21, 8, 2, 3, hairD);
      P(11, 8, 3, 1, hair); P(17, 8, 3, 1, hair);
      // bun
      P(11, 0, 10, 7, OUTLINE);
      P(12, 1, 8, 5, hair);
      P(13, 1, 3, 2, hairL);
      P(12, 5, 8, 1, shade(hair, .72));
    } else if (s === 'curly') {
      P(8, 3, 6, 5, hairD); P(13, 2, 7, 5, hairD); P(19, 3, 5, 5, hairD);
      P(9, 4, 4, 3, hair); P(13, 3, 6, 3, hair); P(19, 4, 4, 3, hair);
      P(8, 7, 3, 5, hairD); P(21, 7, 3, 5, hairD);
      P(9, 8, 2, 3, hair); P(21, 8, 2, 3, hair);
      P(12, 8, 2, 1, hair); P(18, 8, 3, 1, hair);
      P(14, 3, 3, 1, hairL);
    } else if (s === 'messy') {
      P(9, 4, 14, 4, hairD);
      P(10, 4, 12, 3, hair);
      P(9, 2, 4, 4, hairD); P(14, 3, 3, 3, hairD); P(18, 2, 4, 4, hairD);
      P(10, 3, 2, 2, hair); P(15, 4, 2, 2, hair); P(19, 3, 2, 2, hair);
      P(9, 7, 2, 4, hair); P(21, 7, 2, 4, hair);
      P(11, 5, 4, 1, hairL);
    } else if (s === 'bald') {
      P(9, 7, 2, 3, hairD); P(21, 7, 2, 3, hairD);
      P(11, 5, 7, 1, shade(o.skin, 1.18));
      P(12, 4, 5, 1, shade(o.skin, 1.08));
    } else if (s === 'braids') {
      P(8, 5, 16, 7, hairD);
      P(9, 5, 14, 5, hair);
      P(9, 9, 2, 5, hair); P(21, 9, 2, 5, hair);
      P(10, 9, 12, 1, hairD);
      P(12, 5, 6, 1, hairL);
      P(12, 3, 1, 2, hairD); P(19, 3, 1, 2, hairD);
    } else if (s === 'twintails') {
      P(9, 5, 14, 6, hairD);
      P(10, 5, 12, 4, hair);
      P(9, 7, 3, 3, hairD); P(20, 7, 3, 3, hairD);
      P(10, 8, 4, 1, hair); P(17, 8, 4, 1, hair);
      P(11, 4, 5, 1, hairL);
    } else if (s === 'wavy') {
      P(8, 5, 16, 8, hairD);
      P(9, 5, 14, 6, hair);
      P(8, 8, 3, 5, hairD); P(21, 8, 3, 5, hairD);
      P(9, 10, 2, 3, hair); P(21, 10, 2, 3, hair);
      P(10, 9, 12, 1, hairD);
      P(12, 5, 6, 1, hairL);
    } else if (s === 'afro') {
      P(7, 2, 18, 6, hairD);
      P(9, 3, 14, 4, hair);
      P(6, 4, 4, 6, hairD); P(22, 4, 4, 6, hairD);
      P(9, 8, 2, 3, hair); P(21, 8, 2, 3, hair);
      P(12, 3, 5, 1, hairL);
    } else if (s === 'pixie') {
      P(9, 4, 14, 4, hairD);
      P(10, 4, 12, 3, hair);
      P(9, 6, 3, 3, hairD); P(20, 6, 3, 3, hairD);
      P(10, 6, 3, 1, hair); P(17, 6, 3, 1, hair);
      P(12, 4, 4, 1, hairL); P(17, 4, 3, 1, hairL);
    } else if (s === 'mohawk') {
      P(13, 0, 7, 9, hairD);
      P(14, 0, 5, 8, hair);
      P(15, 1, 1, 5, hairL);
      P(10, 8, 1, 2, hairD); P(21, 8, 1, 2, hairD);
    } else if (s === 'side') {
      P(8, 4, 16, 6, hairD);
      P(9, 4, 14, 4, hair);
      P(8, 7, 6, 7, hairD);
      P(9, 7, 4, 6, hair);
      P(19, 6, 3, 3, hairD);
      P(12, 4, 4, 1, hairL);
    }
  }

  function accentHairTie(o) { return o.styleId === 'student' ? '#e04a5a' : '#ffd24a'; }

  /* ================= accessories & hats ================= */
  function drawAccessories(P, o, cfg, col) {
    const { accent, shirtD } = col;
    if (cfg.tie) {
      P(15, 19, 2, 4, accent);
      P(14, 19, 4, 1, shade(accent, 1.25));
      P(16, 22, 1, 2, shade(accent, .82));
    }
    if (cfg.bow) {
      P(17, 19, 2, 1, accent); P(20, 18, 2, 3, accent);
      P(19, 19, 1, 1, GOLD);
    }
    if (cfg.scarf) {
      P(10, 17, 12, 2, '#fff2e0');
      P(10, 18, 12, 1, shade('#fff2e0', .86));
      P(18, 19, 3, 5, '#fff2e0');
      P(18, 23, 3, 1, shade('#fff2e0', .8));
    }
    if (cfg.necker) {
      P(13, 17, 6, 1, accent);
      P(15, 18, 2, 2, accent);
    }
    if (cfg.stetho) {
      P(12, 19, 1, 4, '#4a5a6a');
      P(19, 19, 1, 4, '#4a5a6a');
      P(13, 22, 6, 1, '#4a5a6a');
      P(18, 22, 2, 2, '#c8d8e0');
      P(19, 23, 1, 1, '#7a8a9a');
    }
    if (cfg.badge) {
      P(12, 20, 2, 2, GOLD);
      P(12, 20, 1, 1, '#fff2a0');
      P(18, 20, 3, 1, '#e8e8f0');
    }
    if (cfg.camera) {
      P(12, 19, 7, 1, '#5a3a2a');
      P(17, 21, 4, 3, '#3a2a2a');
      P(18, 22, 2, 1, '#8ac8e8');
    }
    if (cfg.glasses) {
      P(11, 11, 4, 2, INK);
      P(17, 11, 4, 2, INK);
      P(15, 11, 2, 1, INK);
      P(9, 11, 2, 1, INK);
      P(21, 11, 2, 1, INK);
      P(12, 11, 2, 1, 'rgba(180,230,255,.55)');
      P(18, 11, 2, 1, 'rgba(180,230,255,.55)');
    }
    if (cfg.flowerPin) {
      P(19, 19, 3, 3, '#ff8ab0');
      P(20, 20, 1, 1, GOLD);
    }
    if (o.gender === 'หญิง' && !cfg.glasses) {
      P(8, 13, 1, 1, GOLD);
    }
    void shirtD;
  }

  function drawHat(P, o, cfg, col) {
    const { shirtD, pants, accent } = col;
    if (cfg.policeCap) {
      P(8, 3, 16, 6, OUTLINE);
      P(9, 3, 14, 4, '#2a3a5e');
      P(7, 7, 18, 2, '#1a2038');
      P(10, 2, 12, 2, '#3a4a6e');
      P(14, 4, 4, 2, GOLD);
      P(15, 4, 2, 1, '#fff2a0');
      return;
    }
    if (cfg.captainHat) {
      P(7, 3, 18, 4, OUTLINE);
      P(8, 3, 16, 3, '#f6f1e2');
      P(7, 6, 18, 2, '#2a3a5e');
      P(8, 6, 16, 1, GOLD);
      P(14, 4, 4, 2, GOLD);
      return;
    }
    if (cfg.strawHat) {
      P(4, 6, 24, 3, OUTLINE);
      P(5, 6, 22, 2, '#e8c46a');
      P(10, 1, 12, 6, OUTLINE);
      P(11, 2, 10, 4, '#f2d888');
      P(11, 4, 10, 2, '#b05a3a');
      P(12, 2, 5, 1, '#fff0b0');
      return;
    }
    if (cfg.chefHat) {
      P(10, 0, 12, 7, OUTLINE);
      P(10, 0, 12, 6, '#fffaf0');
      P(9, 1, 3, 4, '#fffaf0'); P(20, 1, 3, 4, '#fffaf0');
      P(11, 5, 10, 2, '#e8dcc8');
      return;
    }
    if (cfg.nurseCap) {
      P(12, 3, 8, 4, OUTLINE);
      P(13, 3, 7, 3, '#f6f6ff');
      P(15, 4, 3, 1, '#e04a5a');
      P(16, 3, 1, 3, '#e04a5a');
      return;
    }
    if (cfg.beanie) {
      P(9, 2, 14, 6, OUTLINE);
      P(10, 3, 12, 4, accent);
      P(10, 6, 12, 2, shade(accent, .78));
      P(14, 0, 4, 3, shade(accent, 1.2));
      P(11, 3, 3, 1, shade(accent, 1.32));
      return;
    }
    if (cfg.beret) {
      P(9, 2, 14, 4, OUTLINE);
      P(10, 2, 13, 3, accent);
      P(17, 0, 2, 2, shade(accent, .8));
      P(8, 5, 16, 1, shade(accent, .7));
      return;
    }
    if (cfg.bucketHat) {
      P(7, 3, 18, 3, OUTLINE);
      P(8, 3, 16, 2, '#6a8a6a');
      P(5, 6, 22, 2, '#4a6a4a');
      return;
    }
    if (cfg.headband) {
      P(9, 7, 14, 2, accent);
      P(9, 7, 14, 1, shade(accent, 1.25));
      return;
    }
    if (cfg.wizardHat) {
      P(4, 5, 24, 3, OUTLINE);
      P(5, 5, 22, 2, '#3a3ac8');
      P(5, 5, 22, 1, '#6a6ae8');
      P(11, 0, 10, 6, OUTLINE);
      P(12, 0, 8, 5, '#4a4ae8');
      P(14, 1, 3, 4, '#8a8aff');
      P(14, 4, 4, 1, GOLD);
      P(13, 5, 6, 1, '#2a2a9a');
      P(18, 2, 1, 1, '#fff6c0');
      return;
    }
    if (cfg.witchHat) {
      P(4, 6, 24, 3, OUTLINE);
      P(5, 6, 22, 2, '#2a1a3a');
      P(10, 0, 9, 7, OUTLINE);
      P(11, 1, 7, 5, '#3a2a4a');
      P(13, 0, 3, 2, '#3a2a4a');
      P(12, 5, 7, 2, '#7a3aa8');
      P(15, 5, 2, 2, GOLD);
      P(12, 2, 1, 2, '#5a3a6a');
      return;
    }
    if (cfg.helmet) {
      P(8, 2, 16, 6, OUTLINE);
      P(9, 3, 14, 5, '#b8c8d8');
      P(9, 3, 14, 1, '#e8f2fc');
      P(7, 5, 3, 6, OUTLINE); P(7, 5, 3, 5, '#8a9aa8');
      P(22, 5, 3, 6, OUTLINE); P(22, 5, 3, 5, '#8a9aa8');
      P(13, 0, 2, 4, '#e04a5a');
      P(15, 1, 2, 2, '#ff8a9a');
      P(9, 6, 14, 1, '#6a7a8a');
      P(10, 4, 4, 1, GOLD);
      return;
    }
    if (cfg.tiara) {
      P(9, 3, 14, 2, GOLD);
      P(10, 1, 2, 3, GOLD); P(15, 0, 2, 4, GOLD); P(20, 1, 2, 3, GOLD);
      P(11, 2, 1, 1, '#e04a5a'); P(15, 1, 1, 1, '#4ac8e8'); P(19, 2, 1, 1, '#8ae06a');
      P(10, 2, 1, 1, '#fff2a0');
      return;
    }
    if (cfg.cap) {
      P(9, 2, 14, 5, OUTLINE);
      P(10, 3, 12, 3, '#3a6ac8');
      P(8, 6, 17, 2, '#2a4a9a');
      P(11, 3, 4, 1, '#6a9ae8');
      P(15, 2, 2, 1, '#ffd24a');
      return;
    }
    if (cfg.shades) {
      P(10, 10, 12, 3, '#1a1020');
      P(11, 10, 4, 2, '#4a4a6a'); P(17, 10, 4, 2, '#4a4a6a');
      P(11, 10, 1, 1, '#9ab8d8'); P(17, 10, 1, 1, '#9ab8d8');
      P(9, 10, 1, 1, '#1a1020'); P(22, 10, 1, 1, '#1a1020');
      return;
    }
    if (cfg.mic) {
      P(22, 9, 2, 4, '#3a3a4a');
      P(20, 12, 3, 1, '#3a3a4a');
      P(18, 12, 2, 3, '#8a8a9a');
      P(18, 13, 1, 1, '#c8c8d8');
      P(11, 2, 2, 1, '#ffd24a');
      return;
    }
    if (cfg.hood) {
      P(7, 5, 3, 9, shirtD);
      P(22, 5, 3, 9, shirtD);
      P(8, 5, 2, 3, shade(shirtD, 1.1));
      P(22, 5, 2, 3, shade(shirtD, 1.1));
      return;
    }
    if (o.styleId === 'luxury') {
      P(11, 2, 10, 2, GOLD);
      P(12, 1, 2, 2, GOLD); P(15, 0, 2, 3, GOLD); P(18, 1, 2, 2, GOLD);
      return;
    }
    if (o.hairStyle === 'bald' && o.gender === 'หญิง') {
      P(19, 5, 3, 1, GOLD);
      return;
    }
    void pants;
  }

  /* ================= public sprite draw ================= */
  R.drawSprite = (ctx, x, y, opts) => {
    const o = resolveSpriteOpts(opts || {});
    const spr = spriteFor(o);
    const sc = o.scale;
    ctx.save();
    ctx.imageSmoothingEnabled = false;
    ctx.translate(Math.round(x), Math.round(y));
    // shadow
    ctx.globalAlpha = .22;
    ctx.fillStyle = '#1a1020';
    ctx.beginPath();
    ctx.ellipse(0, 0, 9 * (sc / 1.55), 3 * (sc / 1.55), 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;
    // idle breathing
    const t = opts.t === undefined ? R.t : opts.t;
    const idleBob = o.moving ? 0 : Math.sin(t * 2.2 + (x % 7)) * .55;
    const idleSway = o.moving ? 0 : Math.sin(t * 1.25 + (x % 11)) * .28;
    const stepBob = o.moving && (o.frame === 1 || o.frame === 3) ? -1 : 0;
    ctx.scale(o.facing * sc, sc);
    ctx.drawImage(spr, -16 + idleSway, -31 + idleBob + stepBob);
    ctx.restore();
  };

  /* ================= scenery ================= */
  function drawCloud(x, y, s) {
    const w = 'rgba(255,250,229,.96)', sh = 'rgba(167,205,198,.76)';
    px(x - 1 * s, y + 5 * s, 27 * s, 4 * s, sh);
    px(x + 3 * s, y - 2 * s, 18 * s, 8 * s, w);
    px(x + 9 * s, y - 7 * s, 10 * s, 7 * s, w);
    px(x - 5 * s, y + 1 * s, 11 * s, 5 * s, w);
    px(x + 5 * s, y - 2 * s, 12 * s, 2 * s, 'rgba(255,255,255,.78)');
  }

  function drawTree(x, y, s = 1) {
    const dark = '#426843', leaf = '#6d9d58', leafL = '#a5c979', leafD = '#54804a';
    px(x - 10 * s, y - 52 * s, 20 * s, 52 * s, OUTLINE);
    px(x - 7 * s, y - 50 * s, 14 * s, 50 * s, '#896344');
    px(x - 7 * s, y - 50 * s, 4 * s, 50 * s, '#b28455');
    // canopy silhouette
    px(x - 32 * s, y - 78 * s, 64 * s, 38 * s, OUTLINE);
    px(x - 38 * s, y - 66 * s, 18 * s, 20 * s, OUTLINE);
    px(x + 20 * s, y - 66 * s, 18 * s, 20 * s, OUTLINE);
    px(x - 16 * s, y - 96 * s, 34 * s, 26 * s, OUTLINE);
    // canopy fill
    px(x - 28 * s, y - 74 * s, 56 * s, 30 * s, dark);
    px(x - 32 * s, y - 64 * s, 14 * s, 14 * s, dark);
    px(x + 18 * s, y - 64 * s, 14 * s, 14 * s, dark);
    px(x - 14 * s, y - 90 * s, 28 * s, 20 * s, dark);
    px(x - 24 * s, y - 72 * s, 44 * s, 22 * s, leafD);
    px(x - 26 * s, y - 62 * s, 12 * s, 10 * s, leafD);
    px(x + 16 * s, y - 62 * s, 12 * s, 10 * s, leafD);
    px(x - 20 * s, y - 77 * s, 30 * s, 16 * s, leaf);
    px(x - 12 * s, y - 86 * s, 22 * s, 14 * s, leaf);
    px(x - 16 * s, y - 80 * s, 10 * s, 6 * s, leafL);
    px(x - 4 * s, y - 88 * s, 10 * s, 4 * s, leafL);
    px(x + 4 * s, y - 72 * s, 8 * s, 4 * s, leafL);
    // small leaf clusters catch the afternoon light
    px(x - 20 * s, y - 69 * s, 5 * s, 3 * s, '#bdd58a');
    px(x + 9 * s, y - 81 * s, 4 * s, 3 * s, '#b7d184');
    px(x + 19 * s, y - 61 * s, 4 * s, 3 * s, '#99bd70');
  }

  function drawBush(x, y, s = 1) {
    px(x - 22 * s, y - 18 * s, 44 * s, 20 * s, OUTLINE);
    px(x - 18 * s, y - 16 * s, 36 * s, 16 * s, '#54804a');
    px(x - 14 * s, y - 20 * s, 14 * s, 10 * s, '#6d9d58');
    px(x + 2 * s, y - 18 * s, 12 * s, 9 * s, '#82ad62');
    px(x - 6 * s, y - 12 * s, 8 * s, 4 * s, '#b0cc7c');
    px(x - 12 * s, y - 13 * s, 2 * s, 2 * s, '#d97867');
    px(x + 8 * s, y - 11 * s, 2 * s, 2 * s, '#e7c16c');
  }

  function drawBench(x, y) {
    px(x - 30, y - 20, 60, 7, OUTLINE);
    px(x - 28, y - 18, 56, 5, '#c88a4a');
    px(x - 26, y - 16, 52, 2, '#e8aa62');
    px(x - 28, y - 34, 56, 5, OUTLINE);
    px(x - 26, y - 32, 52, 3, '#c88a4a');
    px(x - 24, y - 14, 4, 14, '#5a3a2a');
    px(x + 20, y - 14, 4, 14, '#5a3a2a');
    px(x - 26, y - 30, 4, 16, '#5a3a2a');
    px(x + 22, y - 30, 4, 16, '#5a3a2a');
  }

  function drawLamp(x, y, style) {
    px(x - 3, y - 74, 6, 74, OUTLINE);
    px(x - 1, y - 72, 2, 72, '#4a4a5e');
    px(x - 9, y - 84, 18, 12, OUTLINE);
    px(x - 7, y - 82, 14, 8, style === 'warm' ? '#ffe08a' : '#f6e4a8');
    px(x - 5, y - 80, 5, 3, '#fff8d0');
    R.ctx.globalAlpha = .16;
    R.ctx.fillStyle = '#ffe08a';
    R.ctx.beginPath(); R.ctx.arc(x, y - 78, 36, 0, Math.PI * 2); R.ctx.fill();
    R.ctx.globalAlpha = 1;
    px(x - 7, y - 2, 14, 2, '#3a3a4a');
  }

  function drawFlowers(x, y) {
    const cols = ['#df8f91', '#efcd72', '#8eacc8', '#e99b73', '#bf93c4'];
    for (let i = 0; i < 8; i++) {
      const fx = x - 28 + i * 8, fy = y - (i % 3) * 6;
      px(fx, fy - 9, 2, 9, '#3f8a42');
      px(fx - 2, fy - 13, 6, 5, cols[i % cols.length]);
      px(fx - 1, fy - 14, 4, 2, '#fff0b0');
    }
  }

  function drawButterfly(x, y, phase) {
    const wing = Math.sin(R.t * 12 + phase) > 0 ? 3 : 2;
    const cols = ['#e5a0a0', '#eacb74', '#9ec4bb'];
    const c = cols[Math.abs(Math.floor(phase)) % cols.length];
    px(x - wing - 1, y, wing, 2, c);
    px(x + 2, y, wing, 2, c);
    px(x, y - 1, 2, 5, '#665549');
    if (wing === 3) { px(x - 2, y - 1, 2, 1, '#fff4d2'); px(x + 3, y - 1, 2, 1, '#fff4d2'); }
  }

  function drawFence(x1, x2, y, col) {
    const c = col || '#e8e0c8';
    px(x1, y - 26, x2 - x1, 3, shade(c, .82));
    for (let x = x1; x <= x2; x += 16) {
      px(x, y - 30, 5, 30, OUTLINE);
      px(x + 1, y - 28, 3, 27, c);
      px(x + 1, y - 28, 1, 26, shade(c, 1.1));
    }
  }

  function drawBuilding(b) {
    const ctx = R.ctx;
    const x = b.x, y = b.y, w = b.w, h = b.h;
    const roof = b.roof || '#b94e3f';
    const wall = b.wall || '#e8d0a8';
    const isShop = b.type === 'shop' || !!(b.door && ['store', 'cafe', 'hospital', 'bank', 'mall', 'bar'].includes(b.door.zone));
    const isHome = b.type === 'home';

    // ground shadow
    ctx.globalAlpha = .18; ctx.fillStyle = '#2a1a24';
    ctx.beginPath(); ctx.ellipse(x + w / 2, y + h + 4, w * .55, 11, 0, 0, Math.PI * 2); ctx.fill();
    ctx.globalAlpha = 1;

    // body
    px(x - 3, y - 3, w + 6, h + 6, OUTLINE);
    px(x, y, w, h, wall);
    px(x, y, 7, h, shade(wall, 1.1));
    px(x + w - 10, y, 10, h, shade(wall, .86));
    for (let yy = y + 28; yy < y + h - 10; yy += 26) px(x + 4, yy, w - 8, 1, shade(wall, .94));

    // stepped roof
    const bands = 5;
    for (let i = 0; i < bands; i++) {
      const bw = w + 28 - i * Math.max(6, Math.round(w * .07));
      const bx = x + (w + 28 - bw) / 2 - 14;
      const by = y - 8 - i * 8;
      px(bx - 2, by - 2, bw + 4, 10, OUTLINE);
      px(bx, by, bw, 8, i === bands - 1 ? shade(roof, .9) : roof);
      px(bx, by, bw, 2, shade(roof, 1.18));
    }
    // ridge
    px(x + w / 2 - 18, y - 52, 36, 6, shade(roof, 1.12));
    px(x + w / 2 - 12, y - 56, 24, 5, shade(roof, 1.24));
    // eaves
    px(x - 18, y - 12, w + 36, 5, shade(roof, .7));

    if (isHome) {
      // chimney
      px(x + w * .72, y - 78, 20, 34, OUTLINE);
      px(x + w * .72 + 2, y - 76, 16, 30, '#b06a4a');
      px(x + w * .72, y - 82, 22, 8, '#8a4a32');
      // little smoke
      const sm = (R.t * 8) % 40;
      R.ctx.globalAlpha = .35;
      px(x + w * .72 + 8, y - 92 - sm, 5, 5, '#ffffff');
      px(x + w * .72 + 12, y - 104 - sm, 7, 6, '#ffffff');
      R.ctx.globalAlpha = 1;
    }

    // windows
    const winCount = Math.max(1, Math.floor((w - 40) / 74));
    for (let i = 0; i < winCount; i++) {
      const wx = x + 22 + i * ((w - 44) / winCount);
      const wy = y + 34;
      px(wx - 2, wy - 2, 34, 32, OUTLINE);
      px(wx, wy, 30, 28, '#a8e0f8');
      px(wx, wy, 30, 4, '#fff6dc');
      px(wx + 14, wy, 3, 28, '#fff6dc');
      px(wx, wy + 12, 30, 3, '#fff6dc');
      // curtains
      px(wx, wy, 6, 28, 'rgba(255,255,255,.55)');
      px(wx + 24, wy, 6, 28, 'rgba(255,255,255,.55)');
      // flower box
      if (isHome) {
        px(wx - 3, wy + 28, 36, 6, '#8a5a32');
        for (let k = 0; k < 4; k++) px(wx + 1 + k * 8, wy + 24, 4, 4, ['#ff6a9a', '#ffd24a', '#ff8a5a', '#d88aff'][k]);
      }
    }

    // entrance (interactive door or decorative shopfront)
    const dh = 44, dw = 30;
    const dx = b.door ? b.door.x : x + w / 2;
    px(dx - dw / 2 - 2, y + h - dh - 2, dw + 4, dh + 2, OUTLINE);
    px(dx - dw / 2, y + h - dh, dw, dh, b.door ? '#7a4a2a' : '#5a4038');
    px(dx - dw / 2 + 2, y + h - dh + 2, dw - 4, dh - 2, b.door ? '#a86a38' : '#80604e');
    px(dx - dw / 2 + 2, y + h - dh + 2, 6, dh - 2, b.door ? '#c88a4a' : '#a0806a');
    px(dx + 7, y + h - 22, 3, 3, GOLD);
    // step
    px(dx - 22, y + h, 44, 5, '#c8b8a0');
    px(dx - 19, y + h + 5, 38, 4, '#a89880');
    // awning
    if (isShop && (!b.door || b.door.zone !== 'bar')) {
      for (let i = 0; i < 6; i++) px(dx - 30 + i * 10, y + h - dh - 14, 10, 10, i % 2 ? '#fff6e0' : shade(roof, 1.05));
      px(dx - 32, y + h - dh - 16, 64, 3, shade(roof, .8));
    }
    // shop display window
    if (isShop) {
      px(dx + 28, y + h - 60, 44, 38, OUTLINE);
      px(dx + 31, y + h - 57, 38, 32, '#a8e0f8');
      px(dx + 31, y + h - 57, 38, 5, '#fff6dc');
      px(dx + 34, y + h - 48, 10, 12, '#ffd24a');
      px(dx + 48, y + h - 52, 8, 16, '#ff8a8a');
      px(dx + 58, y + h - 44, 8, 8, '#8ae0a0');
    }
    // sign
    const label = b.name || '';
    ctx.font = `700 11px ${FONT}`;
    const tw = Math.min(w - 12, ctx.measureText(label).width + 18);
    px(dx - tw / 2 - 2, y + h - dh - 34, tw + 4, 20, OUTLINE);
    px(dx - tw / 2, y + h - dh - 32, tw, 16, '#3a2a34');
    px(dx - tw / 2 + 3, y + h - dh - 30, tw - 6, 1, '#7a5a4a');
    ctx.fillStyle = '#ffe8a8';
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText(label, dx, y + h - dh - 24);
    ctx.textAlign = 'left'; ctx.textBaseline = 'alphabetic';

    // hospital cross
    if (b.door && b.door.zone === 'hospital') {
      px(x + w - 42, y + 22, 22, 6, '#e04a5a');
      px(x + w - 34, y + 14, 6, 22, '#e04a5a');
    }
    // school clock
    if (b.door && (b.door.zone === 'classroom' || b.door.zone === 'university')) {
      ctx.fillStyle = '#fff6dc';
      ctx.beginPath(); ctx.arc(x + w / 2, y - 30, 13, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = OUTLINE; ctx.lineWidth = 3; ctx.stroke();
      px(x + w / 2 - 1, y - 38, 2, 9, INK);
      px(x + w / 2, y - 30, 6, 2, INK);
    }
    // mall banner
    if (b.door && b.door.zone === 'mall') {
      px(x + 14, y + 18, 28, 44, '#e04a7a');
      px(x + 18, y + 24, 20, 4, '#fff6dc');
      px(x + 18, y + 32, 20, 4, '#fff6dc');
      px(x + 18, y + 40, 14, 4, '#fff6dc');
    }
  }

  function drawDoor(d, zone) {
    const x = d.x, y = d.y;
    if (zone.indoor && y > 480 && x > 400 && x < 560) {
      // exit at bottom
      px(x - 40, y - 16, 80, 16, '#c8a878');
      px(x - 36, y - 12, 72, 12, '#a8784a');
      R.ctx.globalAlpha = .35;
      R.ctx.fillStyle = '#fff2b0';
      R.ctx.beginPath(); R.ctx.ellipse(x, y - 20, 34, 12, 0, 0, Math.PI * 2); R.ctx.fill();
      R.ctx.globalAlpha = 1;
      px(x - 22, y - 34, 44, 18, OUTLINE);
      px(x - 20, y - 32, 40, 14, '#4a3a44');
      R.ctx.fillStyle = '#ffe8a8';
      R.ctx.font = `700 10px ${FONT}`; R.ctx.textAlign = 'center';
      R.ctx.fillText('ออก', x, y - 22);
      R.ctx.textAlign = 'left';
      return;
    }
    // side / outdoor door
    const w = 42, h = 82;
    px(x - w / 2 - 3, y - h - 3, w + 6, h + 6, OUTLINE);
    px(x - w / 2, y - h, w, h, '#5a3a24');
    px(x - w / 2 + 3, y - h + 3, w - 6, h - 3, '#9a6236');
    px(x - w / 2 + 3, y - h + 3, 7, h - 3, '#c08a4a');
    px(x + 10, y - 40, 4, 4, GOLD);
    px(x - w / 2 - 6, y - 5, w + 12, 5, '#c8b8a0');
  }

  function drawEdgeSign(edge, label) {
    const x = edge === 'left' ? 54 : 906;
    const y = 450;
    px(x - 3, y - 60, 6, 60, OUTLINE);
    px(x - 1, y - 58, 2, 58, '#8a5a32');
    px(x - 34, y - 78, 68, 22, OUTLINE);
    px(x - 32, y - 76, 64, 18, '#3a2a34');
    R.ctx.fillStyle = '#ffe8a8';
    R.ctx.font = `700 10px ${FONT}`; R.ctx.textAlign = 'center';
    const arrow = edge === 'left' ? '◀ ' : '';
    R.ctx.fillText(arrow + label, x, y - 63);
    R.ctx.textAlign = 'left';
  }

  function drawStringLights(x1, y1, x2, y2, n) {
    const ctx = R.ctx;
    ctx.strokeStyle = 'rgba(40,26,36,.65)'; ctx.lineWidth = 2;
    ctx.beginPath();
    for (let i = 0; i <= n; i++) {
      const t = i / n;
      const x = x1 + (x2 - x1) * t;
      const y = y1 + (y2 - y1) * t + Math.sin(t * Math.PI) * 26;
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    ctx.stroke();
    const cols = ['#ffd24a', '#ff8a6a', '#8ae0ff', '#ff9ac8'];
    for (let i = 1; i < n; i++) {
      const t = i / n;
      const x = x1 + (x2 - x1) * t;
      const y = y1 + (y2 - y1) * t + Math.sin(t * Math.PI) * 26 + 3;
      px(x - 1, y, 3, 2, '#3a2a34');
      px(x - 2, y + 2, 5, 5, cols[i % cols.length]);
      ctx.globalAlpha = .22; ctx.fillStyle = cols[i % cols.length];
      ctx.beginPath(); ctx.arc(x, y + 4, 10, 0, Math.PI * 2); ctx.fill();
      ctx.globalAlpha = 1;
    }
  }

  function drawSky(theme) {
    const ctx = R.ctx;
    const S = root.PLGame ? root.PLGame.S : null;
    const m = S ? S.timeMin : 720;
    const hour = m / 60;
    const pal = SKY[theme] || SKY.suburb;
    const night = hour < 6 || hour >= 19.5;
    const g = ctx.createLinearGradient(0, 0, 0, 330);
    if (theme === 'market' || night) {
      g.addColorStop(0, night ? '#141034' : (theme === 'market' ? pal[0] : '#2a2a5e'));
      g.addColorStop(.55, night ? '#2a2454' : pal[1]);
      g.addColorStop(1, night ? '#5a4a6e' : pal[2]);
    } else {
      g.addColorStop(0, pal[0]); g.addColorStop(.6, pal[1]); g.addColorStop(1, pal[2]);
    }
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, 360);

    // stars
    if (night || theme === 'market') {
      for (let i = 0; i < 46; i++) {
        const sx = hash(i * 3.7) * W, sy = hash(i * 9.1) * 210;
        const tw = (Math.sin(R.t * 1.8 + i) + 1) / 2;
        ctx.globalAlpha = .35 + tw * .55;
        px(sx, sy, i % 5 === 0 ? 2 : 1, i % 5 === 0 ? 2 : 1, '#fff6d0');
      }
      ctx.globalAlpha = 1;
    }

    if (theme === 'underground') {
      // เพดานถ้ำ
      for (let i = 0; i < 18; i++) {
        const sx = i * 58 + hash(i * 3.1) * 20;
        const h = 22 + hash(i * 7.7) * 54;
        px(sx, 0, 30, h, '#1a1228');
        px(sx + 8, h - 12, 14, 18, '#241a34');
      }
      // ผลึกเรืองแสงบนเพดาน
      for (let i = 0; i < 7; i++) {
        const cx = 70 + i * 132, cy = 26 + hash(i * 5.3) * 60;
        const tw = (Math.sin(R.t * 2 + i) + 1) / 2;
        ctx.globalAlpha = .35 + tw * .45;
        px(cx - 12, cy, 24, 26, ['#b87ae8', '#7ae8ff', '#e87ae8'][i % 3]);
        ctx.globalAlpha = 1;
        px(cx - 4, cy + 4, 8, 16, '#f0d8ff');
      }
      return;
    }

    if (!night) {
      // sun
      const dayT = Math.max(0, Math.min(1, (m - 360) / (20 * 60 - 360)));
      const sx = 110 + dayT * 740;
      const sy = 245 - Math.sin(dayT * Math.PI) * 185;
      const glow = ctx.createRadialGradient(sx, sy, 8, sx, sy, 60);
      glow.addColorStop(0, 'rgba(255,229,142,.27)');
      glow.addColorStop(1, 'rgba(255,229,142,0)');
      ctx.fillStyle = glow; ctx.fillRect(sx - 62, sy - 62, 124, 124);
      px(sx - 20, sy - 18, 40, 36, '#efc96d');
      px(sx - 15, sy - 23, 30, 5, '#efc96d');
      px(sx - 15, sy + 18, 30, 5, '#efc96d');
      px(sx - 25, sy - 12, 5, 24, '#efc96d');
      px(sx + 20, sy - 12, 5, 24, '#efc96d');
      px(sx - 15, sy - 16, 26, 26, '#ffe795');
      px(sx - 10, sy - 13, 14, 7, '#fff4c8');
      px(sx + 7, sy + 4, 7, 7, '#f3d47c');
      const ray = (Math.floor(R.t * 2) % 2) ? '#f7dc8c' : '#ffe9aa';
      px(sx - 2, sy - 31, 4, 5, ray); px(sx - 2, sy + 26, 4, 5, ray);
      px(sx - 31, sy - 2, 5, 4, ray); px(sx + 26, sy - 2, 5, 4, ray);
    } else {
      // moon
      const mt = ((hour + 6) % 24) / 24;
      const mx = 100 + mt * 760, my = 96 + Math.sin(mt * Math.PI * 2) * 16;
      ctx.fillStyle = '#fff6d8'; ctx.beginPath(); ctx.arc(mx, my, 22, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = night ? '#514663' : '#9a706e';
      ctx.beginPath(); ctx.arc(mx + 9, my - 5, 18, 0, Math.PI * 2); ctx.fill();
      ctx.globalAlpha = .12; ctx.fillStyle = '#fff6d8';
      ctx.beginPath(); ctx.arc(mx, my, 40, 0, Math.PI * 2); ctx.fill();
      ctx.globalAlpha = 1;
    }

    // clouds
    if (theme !== 'market') {
      ctx.globalAlpha = night ? .3 : .9;
      for (let i = 0; i < 5; i++) {
        const cx = ((R.t * (6 + i * 2) + i * 240) % 1160) - 100;
        drawCloud(cx, 42 + (i % 3) * 38, .8 + (i % 2) * .4);
      }
      ctx.globalAlpha = 1;
    }

    // theme backgrounds
    if (theme === 'city') {
      ctx.globalAlpha = .5;
      for (let i = 0; i < 14; i++) {
        const bw = 46 + hash(i * 2.3) * 46;
        const bh = 44 + hash(i * 5.1) * 92;
        px(i * 76 - 6, 322 - bh, bw, bh, i % 2 ? '#6a7a9a' : '#7a8aa6');
        for (let wy = 322 - bh + 10; wy < 318; wy += 16) {
          for (let wx = i * 76 + 6; wx < i * 76 + bw - 8; wx += 12) {
            if (hash(wx + wy) > .45) px(wx, wy, 5, 6, night ? '#ffe08a' : 'rgba(255,246,220,.65)');
          }
        }
      }
      ctx.globalAlpha = 1;
    } else if (theme === 'harbor') {
      // ocean
      const sea = ctx.createLinearGradient(0, 258, 0, 340);
      sea.addColorStop(0, night ? '#1a3a6e' : '#3ab0e0');
      sea.addColorStop(1, night ? '#224a7e' : '#6ad8e8');
      ctx.fillStyle = sea; ctx.fillRect(0, 262, W, 80);
      for (let i = 0; i < 16; i++) {
        const wy = 272 + i * 5;
        px((i * 79 + R.t * 12) % W, wy, 30, 2, 'rgba(255,255,255,.35)');
        px((i * 53 - R.t * 8 + W) % W, wy + 2, 16, 1, 'rgba(255,255,255,.22)');
      }
      // gulls
      for (let i = 0; i < 3; i++) {
        const gx = ((R.t * 22 + i * 300) % 1100) - 60, gy = 110 + i * 28;
        px(gx, gy, 6, 2, '#fff6e0'); px(gx + 6, gy - 2, 6, 2, '#fff6e0');
      }
    } else if (theme === 'park' || theme === 'farm' || theme === 'suburb' || theme === 'backyard') {
      // rolling hills
      const hill = night ? '#2a4a44' : (theme === 'farm' ? '#8ab84e' : '#6ab85a');
      const hill2 = night ? '#22403c' : (theme === 'farm' ? '#b0d46a' : '#8ed06a');
      ctx.fillStyle = hill2;
      ctx.beginPath(); ctx.moveTo(-40, 320);
      for (let x = -40; x <= W + 40; x += 40) ctx.lineTo(x, 296 - Math.sin(x * .012 + 1) * 22);
      ctx.lineTo(W + 40, 340); ctx.lineTo(-40, 340); ctx.fill();
      ctx.fillStyle = hill;
      ctx.beginPath(); ctx.moveTo(-40, 330);
      for (let x = -40; x <= W + 40; x += 34) ctx.lineTo(x, 318 - Math.sin(x * .018 + 3) * 14);
      ctx.lineTo(W + 40, 350); ctx.lineTo(-40, 350); ctx.fill();
      if (theme === 'farm') {
        for (let i = 0; i < 10; i++) px(i * 100 + 30, 316, 44, 3, night ? '#38583a' : '#a8d060');
      }
    } else if (theme === 'market') {
      drawStringLights(-40, 56, 500, 44, 12);
      drawStringLights(460, 44, 1000, 62, 12);
      drawStringLights(-40, 128, 500, 112, 10);
    }

    if (theme === 'school') {
      ctx.globalAlpha = .35;
      px(0, 300, W, 30, '#8ac86a');
      ctx.globalAlpha = 1;
    }
  }

  function drawGroundBase(theme) {
    const g = GROUND[theme] || GROUND.suburb;
    const base = g[0], dark = g[1];
    px(0, 300, W, H - 300, base);
    px(0, 300, W, 6, shade(base, 1.12));
    px(0, 300, W, 2, shade(base, 1.25));
    // softly dappled meadow texture
    for (let i = 0; i < 90; i++) {
      const gx = hash(i * 3.1) * W;
      const gy = 306 + hash(i * 7.7) * (H - 310);
      px(gx, gy, i % 4 === 0 ? 4 : 2, i % 3 === 0 ? 2 : 1, i % 2 ? shade(base, 1.07) : shade(base, .93));
    }
    if (['park', 'farm', 'ranch', 'backyard', 'suburb', 'school'].includes(theme)) {
      const season = root.PLGame ? (root.PLGame.S.season || 0) : 0;
      const blooms = ['#e6a4a0', '#f2d27e', '#d7b1d8', '#e7eee0'];
      for (let i = 0; i < 34; i++) {
        const gx = 14 + hash(i * 14.7 + 2) * (W - 28);
        const gy = 332 + hash(i * 8.1 + 1) * 185;
        const c = i % 8 === 0 ? blooms[season % blooms.length] : (i % 2 ? '#5d9854' : '#a1c471');
        px(gx, gy, 2, 3, c);
        if (i % 3 === 0) { px(gx - 2, gy + 1, 2, 1, '#b6ce7b'); px(gx + 2, gy, 2, 1, '#6b9f5a'); }
      }
    }
    px(0, H - 26, W, 26, shade(base, .9));

    if (theme === 'city') {
      px(0, 352, W, 128, '#b8b0c0');
      px(0, 352, W, 4, '#d8d0dc');
      px(0, 476, W, 6, '#8a8294');
      // sidewalk lines
      for (let i = 0; i < 13; i++) px(i * 76, 352, 3, 128, '#a49aac');
      // crosswalk
      for (let i = 0; i < 6; i++) px(410 + i * 26, 480, 16, 34, '#f2ecda');
      px(0, 512, W, 28, '#7a7286');
    } else if (theme === 'suburb') {
      px(0, 360, W, 68, '#d8ccb0');
      px(0, 360, W, 4, '#f0e4c8');
      px(0, 424, W, 56, '#8a8094');
      px(0, 424, W, 4, '#a89cb0');
      px(0, 478, W, 4, '#6a6078');
      for (let i = 0; i < 15; i++) px(i * 68 + 12, 450, 34, 4, '#f2e8c8');
      px(0, 482, W, 58, base);
      for (let i = 0; i < 6; i++) drawBush(60 + i * 180, 512, .7);
    } else if (theme === 'park') {
      // winding path
      R.ctx.fillStyle = '#e8d4a8';
      R.ctx.beginPath();
      R.ctx.moveTo(390, 540); R.ctx.bezierCurveTo(430, 470, 520, 440, 480, 390);
      R.ctx.bezierCurveTo(450, 350, 520, 330, 560, 310);
      R.ctx.lineTo(620, 310); R.ctx.bezierCurveTo(590, 340, 520, 360, 560, 410);
      R.ctx.bezierCurveTo(610, 470, 540, 500, 520, 540); R.ctx.closePath(); R.ctx.fill();
      R.ctx.strokeStyle = '#c8b088'; R.ctx.lineWidth = 4; R.ctx.stroke();
      for (let i = 0; i < 22; i++) {
        const gx = hash(i * 8.3) * W, gy = 330 + hash(i * 4.1) * 200;
        px(gx, gy, 3, 2, i % 2 ? '#8ee06a' : '#4a9a4a');
      }
    } else if (theme === 'market') {
      px(0, 348, W, 192, '#9a7f92');
      for (let yy = 348; yy < H; yy += 32) {
        px(0, yy, W, 2, '#8a6f82');
        for (let xx = (yy / 32 % 2) * 32; xx < W; xx += 64) px(xx, yy, 2, 32, '#8a6f82');
      }
      // warm light pools
      for (let i = 0; i < 4; i++) {
        const lx = 120 + i * 240, ly = 420;
        const rg = R.ctx.createRadialGradient(lx, ly, 10, lx, ly, 120);
        rg.addColorStop(0, 'rgba(255,190,90,.22)'); rg.addColorStop(1, 'rgba(255,190,90,0)');
        R.ctx.fillStyle = rg; R.ctx.fillRect(lx - 120, ly - 120, 240, 240);
      }
    } else if (theme === 'harbor') {
      // boardwalk
      px(0, 336, W, H - 336, '#c8a06a');
      for (let yy = 336; yy < H; yy += 22) {
        px(0, yy, W, 2, '#9a7448');
        for (let xx = (yy / 22 % 2) * 60; xx < W; xx += 120) px(xx, yy, 2, 22, '#9a7448');
      }
      px(0, 336, W, 5, '#e8c890');
      // posts
      for (let i = 0; i < 6; i++) px(60 + i * 170, 326, 8, 18, '#7a5534');
    } else if (theme === 'farm') {
      // field rows
      for (let i = 0; i < 5; i++) {
        const yy = 340 + i * 40;
        px(0, yy, W, 22, i % 2 ? '#8cb963' : '#7da957');
        px(0, yy + 19, W, 4, '#a77d4e');
        for (let x = 10; x < W; x += 40) {
          px(x, yy + 6, 18, 8, '#61834d');
          px(x + 2, yy + 5, 2, 5, '#b3cb74');
          px(x + 9, yy + 3, 3, 7, '#78a45a');
          if ((x / 40 + i) % 5 === 0) px(x + 12, yy + 2, 3, 3, '#f3d27a');
        }
      }
      px(0, 500, W, 40, '#c8a878');
      px(0, 500, W, 4, '#e0c898');
    } else if (theme === 'backyard') {
      drawFence(0, W, 330, '#e8e0c8');
      px(0, 330, W, 4, '#c8c0a8');
    } else if (theme === 'ranch') {
      // โคลนทางเดิน
      R.ctx.fillStyle = '#c8a878';
      R.ctx.beginPath();
      R.ctx.moveTo(360, 540); R.ctx.bezierCurveTo(400, 480, 560, 470, 520, 410);
      R.ctx.bezierCurveTo(500, 380, 540, 350, 560, 320);
      R.ctx.lineTo(610, 320); R.ctx.bezierCurveTo(590, 350, 560, 380, 590, 410);
      R.ctx.bezierCurveTo(640, 470, 500, 490, 480, 540); R.ctx.closePath(); R.ctx.fill();
      R.ctx.strokeStyle = '#b08f62'; R.ctx.lineWidth = 3; R.ctx.stroke();
      for (let i = 0; i < 26; i++) {
        const gx = hash(i * 7.3) * W, gy = 330 + hash(i * 2.9) * 200;
        px(gx, gy, 3, 2, i % 3 ? '#a1c471' : '#e8d28b');
      }
      for (let i = 0; i < 10; i++) {
        const sx = 80 + i * 86, sy = 370 + (i % 3) * 38;
        px(sx, sy, 8, 3, '#a9845c'); px(sx + 3, sy + 4, 7, 2, '#b89368');
      }
      // รั้วไม้ด้านหลัง
      drawFence(0, W, 336, '#c8a878');
    } else if (theme === 'underground') {
      // ทางหินโค้ง
      px(0, 360, W, 180, '#443a5c');
      for (let i = 0; i < 10; i++) {
        const yy = 360 + i * 18;
        px(0, yy, W, 2, '#382f4c');
        for (let xx = (i % 2) * 40; xx < W; xx += 80) px(xx, yy, 2, 18, '#382f4c');
      }
      for (let i = 0; i < 16; i++) {
        const gx = hash(i * 4.7) * W, gy = 366 + hash(i * 9.1) * 160;
        px(gx, gy, 4, 3, i % 3 ? '#5a4e72' : '#6a5a82');
      }
      // รอยแตกเรืองแสง
      for (let i = 0; i < 5; i++) {
        const gx = 90 + i * 190;
        const tw = (Math.sin(R.t * 1.5 + i) + 1) / 2;
        R.ctx.globalAlpha = .25 + tw * .35;
        px(gx, 430, 3, 12, '#b87ae8');
        px(gx + 3, 438, 10, 3, '#b87ae8');
        px(gx + 10, 426, 3, 12, '#7ae8ff');
        R.ctx.globalAlpha = 1;
      }
    }
  }

  function drawOutdoor(zone) {
    const theme = zone.theme || 'suburb';
    drawSky(theme);
    drawGroundBase(theme);
    const props = (zone.props || []).slice();
    // background props
    props.filter((p) => p.y < 320).sort((a, b) => a.y - b.y).forEach((p) => {
      const q = (p.type === 'tree' || p.type === 'bush') ? { ...p, y: Math.max(p.y, 320) } : p;
      drawProp(q, p === R.activeProp);
    });
    (zone.buildings || []).forEach(drawBuilding);
    // foreground props
    props.filter((p) => p.y >= 320).sort((a, b) => a.y - b.y).forEach((p) => drawProp(p, p === R.activeProp));
    // edge exits
    (zone.exits || []).forEach((e) => drawEdgeSign(e.edge, `ไป${(D.ZONES[e.zone] || {}).name || ''}`));
    // ambient
    if (theme === 'market') {
      R.ctx.globalAlpha = .5;
      for (let i = 0; i < 8; i++) {
        const fx = (hash(i * 5.1) * W + R.t * (6 + i)) % W;
        const fy = 360 + hash(i * 7.3) * 140 + Math.sin(R.t * 1.5 + i) * 6;
        px(fx, fy, 2, 2, '#ffe08a');
      }
      R.ctx.globalAlpha = 1;
    }
    if (theme === 'park' && (root.PLGame ? root.PLGame.S.timeMin : 720) > 17 * 60) {
      for (let i = 0; i < 10; i++) {
        const fx = (hash(i * 3.3) * W + Math.sin(R.t + i) * 30) % W;
        const fy = 380 + hash(i * 9.7) * 120;
        R.ctx.globalAlpha = .4 + Math.sin(R.t * 2 + i) * .3;
        px(fx, fy, 2, 2, '#d8ff8a');
      }
      R.ctx.globalAlpha = 1;
    }
    if (theme === 'ranch') {
      for (let i = 0; i < 7; i++) {
        const fx = (hash(i * 4.1) * W + Math.sin(R.t * .8 + i) * 40) % W;
        const fy = 350 + hash(i * 6.7) * 110 + Math.cos(R.t * 1.4 + i) * 10;
        drawButterfly(fx, fy, i * 1.7);
      }
    }
    if (theme === 'park' || theme === 'backyard' || theme === 'farm') {
      for (let i = 0; i < 3; i++) {
        const fx = (hash(i * 11.7) * W + Math.sin(R.t * .55 + i * 2) * 35 + R.t * (5 + i)) % W;
        const fy = 370 + hash(i * 9.2) * 90 + Math.sin(R.t + i) * 8;
        drawButterfly(fx, fy, i * 2.2);
      }
    }
    if (theme === 'underground') {
      for (let i = 0; i < 14; i++) {
        const fx = (hash(i * 5.9) * W + Math.sin(R.t * .5 + i) * 26) % W;
        const fy = (hash(i * 8.3) * H + R.t * (8 + i)) % H;
        R.ctx.globalAlpha = .25 + (Math.sin(R.t * 2 + i) + 1) * .2;
        px(fx, fy, 2, 2, i % 3 ? '#b87ae8' : '#7ae8ff');
      }
      R.ctx.globalAlpha = 1;
    }
  }

  /* ================= interior ================= */
  function drawIndoor(zone) {
    const ctx = R.ctx;
    const theme = zone.theme || 'home';
    const wall = zone.wall || '#d8b98f';
    const floor = zone.bg || '#b07c4f';
    const S = root.PLGame ? root.PLGame.S : null;
    const home = S && S.zone === 'home';

    // floor with a warm pool of daylight near the wall
    const floorLight = ctx.createLinearGradient(0, 300, 0, H);
    floorLight.addColorStop(0, shade(floor, 1.08));
    floorLight.addColorStop(.48, floor);
    floorLight.addColorStop(1, shade(floor, .9));
    ctx.fillStyle = floorLight; ctx.fillRect(0, 300, W, H - 300);
    if (theme === 'school' || theme === 'shop' || theme === 'hospital' || theme === 'bank' || theme === 'mall' || theme === 'office' || theme === 'gym' || theme === 'metro') {
      for (let y = 300; y < H; y += 40) {
        px(0, y, W, 2, shade(floor, .88));
        for (let x = ((y / 40) % 2) * 60; x < W; x += 120) px(x, y, 2, 40, shade(floor, .9));
      }
      px(0, 300, W, 6, shade(floor, 1.12));
    } else {
      for (let y = 304; y < H; y += 24) {
        px(0, y, W, 2, shade(floor, .86));
        for (let x = ((y / 24) % 2) * 90; x < W; x += 180) px(x, y, 2, 24, shade(floor, .9));
      }
      for (let i = 0; i < 40; i++) px(hash(i * 4.7) * W, 306 + hash(i * 8.1) * 220, 24, 1, shade(floor, 1.05));
    }

    // softly lit plaster wall
    const wallLight = ctx.createLinearGradient(0, 0, 0, 302);
    wallLight.addColorStop(0, shade(wall, 1.07));
    wallLight.addColorStop(.76, wall);
    wallLight.addColorStop(1, shade(wall, .91));
    ctx.fillStyle = wallLight; ctx.fillRect(0, 0, W, 302);
    px(0, 0, W, 14, shade(wall, 1.08));
    // wallpaper stripes
    for (let x = 0; x < W; x += 48) px(x, 14, 20, 210, shade(wall, 1.035));
    for (let x = 24; x < W; x += 48) px(x, 14, 2, 210, shade(wall, .94));
    if (theme === 'home') {
      // ลายเพชรจาง ๆ ให้ผนังดูอบอุ่น
      for (let y = 40; y < 200; y += 28) {
        for (let x = 12; x < W; x += 48) {
          px(x, y, 3, 3, shade(wall, 1.07));
          px(x + 24, y + 14, 3, 3, shade(wall, .93));
        }
      }
    }
    // wainscot + baseboard
    px(0, 224, W, 8, shade(wall, .86));
    px(0, 232, W, 68, shade(wall, .8));
    for (let x = 0; x < W; x += 60) px(x, 232, 2, 68, shade(wall, .72));
    px(0, 296, W, 10, shade(wall, .62));
    px(0, 296, W, 3, shade(wall, .5));

    // window light
    ctx.globalAlpha = .09;
    ctx.fillStyle = '#fff6d8';
    ctx.beginPath(); ctx.moveTo(230, 40); ctx.lineTo(340, 40); ctx.lineTo(540, 540); ctx.lineTo(300, 540); ctx.closePath(); ctx.fill();
    ctx.globalAlpha = 1;

    // theme wall decor
    drawIndoorTheme(theme, wall, floor, S);

    // backdrop props
    const props = (zone.props || []).slice();
    const backTypes = ['window', 'picture', 'board', 'bookshelf', 'clock', 'fishtank', 'neon_sign', 'potion_shelf'];
    props.filter((p) => backTypes.includes(p.type)).forEach((p) => drawProp(p, p === R.activeProp));

    // home furniture
    if (home && root.PLGame) {
      const list = root.PLGame.homeProps ? root.PLGame.homeProps() : [];
      list.filter((p) => !backTypes.includes(p.type)).sort((a, b) => a.y - b.y)
        .forEach((p) => {
          const ap = R.activeProp;
          const act = !!(ap && (ap === p || (ap.type === p.type && Math.abs((ap.x || 0) - p.x) < 3 && Math.abs((ap.y || 0) - p.y) < 3)));
          drawProp(p, act);
        });
      if (R.decorMode) drawDecorGrid();
    }

    // other props
    props.filter((p) => !backTypes.includes(p.type)).sort((a, b) => a.y - b.y)
      .forEach((p) => drawProp(p, p === R.activeProp));

    // doors
    (zone.doors || []).forEach((d) => drawDoor(d, zone));
  }

  function drawIndoorTheme(theme, wall, floor, S) {
    const ctx = R.ctx;
    if (theme === 'home') {
      // framed wall shelf
      px(700, 205, 120, 6, '#8a5a32');
      px(710, 187, 22, 20, '#ffe8b0');
      px(742, 179, 26, 30, '#c8e8ff');
      px(778, 191, 18, 18, '#ffd8e8');
      // clock
      px(596, 160, 44, 44, OUTLINE);
      px(600, 164, 36, 36, '#8a5a32');
      px(603, 167, 30, 30, '#fff6dc');
      px(616, 168, 3, 3, INK); px(616, 193, 3, 3, INK);
      px(604, 180, 3, 3, INK); px(629, 180, 3, 3, INK);
      // เข็มบอกเวลา 10:10
      ctx.strokeStyle = INK; ctx.lineWidth = 2; ctx.beginPath();
      ctx.moveTo(618, 182); ctx.lineTo(610, 175);
      ctx.moveTo(618, 182); ctx.lineTo(625, 175);
      ctx.stroke();
      px(616, 181, 4, 4, '#e05a4a');
    } else if (theme === 'school') {
      // clock
      px(640, 30, 40, 40, OUTLINE);
      px(644, 34, 32, 32, '#fff6dc');
      px(660, 38, 3, 14, INK); px(662, 50, 10, 2, INK);
      // poster
      px(780, 60, 80, 100, '#fff6dc');
      px(786, 68, 68, 44, '#8ae0c8');
      px(786, 118, 68, 6, '#e05a5a');
      px(786, 130, 50, 5, '#5a8ac0');
    } else if (theme === 'shop') {
      px(50, 60, 120, 80, '#3a2a34');
      px(56, 66, 108, 30, '#ffd24a');
      ctx.fillStyle = '#3a2a34'; ctx.font = `700 18px ${FONT}`; ctx.textAlign = 'center';
      ctx.fillText('OPEN', 110, 90); ctx.textAlign = 'left';
      px(56, 104, 44, 30, '#8ae0a0');
      px(108, 104, 44, 30, '#ff8a8a');
    } else if (theme === 'cafe') {
      for (let i = 0; i < 4; i++) {
        const lx = 140 + i * 220;
        px(lx - 1, 0, 2, 44, '#3a2a34');
        px(lx - 9, 40, 18, 12, OUTLINE);
        px(lx - 7, 42, 14, 8, '#ffe08a');
        ctx.globalAlpha = .14; ctx.fillStyle = '#ffe08a';
        ctx.beginPath(); ctx.arc(lx, 46, 34, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1;
      }
      px(70, 70, 90, 110, '#3a2a34');
      px(76, 76, 78, 96, '#4a5a44');
      px(82, 86, 50, 5, '#e8e0c8'); px(82, 102, 60, 5, '#e8e0c8'); px(82, 118, 40, 5, '#e8e0c8');
    } else if (theme === 'hospital') {
      px(430, 40, 100, 12, '#7ab8a8');
      px(0, 170, W, 8, '#7ab8a8');
      px(120, 70, 26, 8, '#e04a5a'); px(129, 61, 8, 26, '#e04a5a');
      px(820, 62, 60, 76, '#fff6dc');
      px(826, 68, 48, 20, '#8ae0c8');
      px(826, 94, 48, 4, '#8a8a9a'); px(826, 104, 38, 4, '#8a8a9a');
    } else if (theme === 'bank') {
      for (let i = 0; i < 4; i++) {
        const cx = 170 + i * 210;
        px(cx - 16, 40, 32, 184, '#e8e4d8');
        px(cx - 20, 34, 40, 10, '#d8d2c4');
        px(cx - 8, 48, 4, 172, '#fffaf0');
        px(cx + 4, 48, 4, 172, '#c8c2b4');
      }
      px(430, 40, 100, 40, '#3a3a4a');
      px(440, 50, 80, 20, '#ffd24a');
    } else if (theme === 'mall') {
      for (let i = 0; i < 5; i++) {
        const bx = 90 + i * 190;
        px(bx, 24, 60, 100, ['#e05a7a', '#5aa8e0', '#ffd24a', '#8ae0a0', '#c88ae0'][i]);
        px(bx + 8, 40, 44, 6, '#fff6dc');
        px(bx + 8, 54, 44, 6, '#fff6dc');
        px(bx + 8, 68, 30, 6, '#fff6dc');
      }
    } else if (theme === 'office') {
      px(60, 44, 300, 140, OUTLINE);
      px(66, 50, 288, 128, '#8ac8e8');
      px(66, 50, 288, 8, '#b8e8f8');
      for (let i = 0; i < 6; i++) {
        const bw = 32 + hash(i * 3.7) * 28;
        px(78 + i * 46, 168 - bw, 34, bw, '#6a82a8');
        for (let wy = 174 - bw; wy < 164; wy += 12) px(84 + i * 46, wy, 6, 5, '#ffe08a');
      }
      px(66, 114, 288, 4, '#fff6dc'); px(206, 50, 4, 128, '#fff6dc');
    } else if (theme === 'gym') {
      px(60, 50, 360, 150, OUTLINE);
      px(66, 56, 348, 138, '#a8d8e8');
      px(70, 60, 8, 130, '#d8f4fa');
      for (let i = 0; i < 4; i++) {
        px(100 + i * 76, 84, 40, 8, '#4a4a5a');
        px(110 + i * 76, 70, 20, 42, '#5a5a6a');
      }
      px(500, 60, 100, 66, '#3a2a34');
      px(506, 66, 88, 22, '#ffd24a');
      ctx.fillStyle = '#3a2a34'; ctx.font = `700 16px ${FONT}`; ctx.textAlign = 'center';
      ctx.fillText('GYM', 550, 84); ctx.textAlign = 'left';
    } else if (theme === 'bar') {
      // neon sign
      ctx.shadowColor = '#ff5aa8'; ctx.shadowBlur = 16;
      ctx.fillStyle = '#ff8ac8'; ctx.font = `700 34px ${FONT}`; ctx.textAlign = 'center';
      ctx.fillText('BAR', 480, 80);
      ctx.shadowBlur = 0; ctx.textAlign = 'left';
      for (let i = 0; i < 3; i++) {
        const lx = 200 + i * 260;
        px(lx - 1, 0, 2, 40, '#2a2030');
        px(lx - 10, 36, 20, 14, OUTLINE);
        px(lx - 8, 38, 16, 10, '#ffd08a');
        ctx.globalAlpha = .15; ctx.fillStyle = '#ffd08a';
        ctx.beginPath(); ctx.arc(lx, 44, 40, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1;
      }
    } else if (theme === 'metro') {
      // กระเบื้องผนัง
      for (let x = 0; x < W; x += 44) {
        px(x, 60, 2, 160, '#6a6a86');
        px(x + 2, 60, 40, 2, '#8a8aa4');
      }
      // ป้ายสถานี
      px(340, 24, 280, 46, OUTLINE);
      px(344, 28, 272, 38, '#1a2a44');
      ctx.fillStyle = '#7ae8ff';
      ctx.font = `700 22px ${FONT}`;
      ctx.textAlign = 'center';
      ctx.fillText('สถานีกลาง · CENTRAL', 480, 55);
      ctx.textAlign = 'left';
      // แผนที่เส้นทาง
      px(690, 82, 226, 110, OUTLINE);
      px(694, 86, 218, 102, '#101a2e');
      const lines = ['#e05a7a', '#5ac8e0', '#ffd24a'];
      lines.forEach((c, i) => {
        px(708, 108 + i * 26, 190, 4, c);
        for (let d = 0; d < 5; d++) px(716 + d * 44, 105 + i * 26, 10, 10, '#fff6dc');
      });
      // ป้ายเวลา
      px(70, 90, 180, 60, OUTLINE);
      px(74, 94, 172, 52, '#141422');
      ctx.fillStyle = '#ffd24a'; ctx.font = `700 14px ${FONT}`;
      ctx.fillText('ขบวนถัดไป', 84, 114);
      const mm = (root.PLGame ? root.PLGame.S.timeMin : 720) + 5;
      ctx.fillStyle = '#8ae0ff'; ctx.font = `700 20px ${FONT}`;
      ctx.fillText(`${String(Math.floor(mm / 60) % 24).padStart(2, '0')}:${String(mm % 60).padStart(2, '0')}`, 84, 138);
      // หลอดไฟเพดาน
      for (let i = 0; i < 4; i++) {
        px(110 + i * 240, 6, 80, 8, '#fff6dc');
        px(104 + i * 240, 14, 92, 4, '#c8d8e8');
      }
      // แถบขอบชานชาลา
      px(0, 302, W, 8, '#ffd24a');
      px(0, 310, W, 3, '#2a2a3a');
      for (let i = 0; i < 20; i++) px(12 + i * 48, 304, 24, 4, '#3a2a2a');
    }
    void wall; void floor; void S;
  }

  function drawDecorGrid() {
    const ctx = R.ctx;
    const G = root.PLGame;
    if (!G || !G.HOME_SLOTS) return;
    ctx.save();
    ctx.setLineDash([5, 5]);
    ctx.strokeStyle = 'rgba(255,220,110,.45)';
    ctx.lineWidth = 1;
    G.HOME_SLOTS.forEach((s) => {
      ctx.strokeRect(s.x - 42, s.y - 40, 84, 46);
    });
    ctx.setLineDash([]);
    const sel = R.decorSelected ? ((G.S.homeLayout || {})[R.decorSelected]) : null;
    if (sel) {
      ctx.strokeStyle = 'rgba(255,224,120,.95)';
      ctx.lineWidth = 2;
      ctx.strokeRect(sel.x - 48, sel.y - 56, 96, 70);
      ctx.fillStyle = 'rgba(255,224,120,.9)';
      [[-48, -56], [48, -56], [-48, 14], [48, 14]].forEach(([dx, dy]) => {
        ctx.fillRect(sel.x + dx - 3, sel.y + dy - 3, 6, 6);
      });
    }
    ctx.restore();
  }

  /* ================= props ================= */
  function drawProp(p, active) {
    const ctx = R.ctx;
    const doRotate = !!p.rot;
    if (doRotate) {
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate((p.rot * Math.PI) / 180);
      ctx.translate(-p.x, -p.y);
    }
    if (active) {
      ctx.globalAlpha = .22;
      ctx.fillStyle = '#ffe08a';
      ctx.beginPath(); ctx.ellipse(p.x, p.y - 4, 46, 12, 0, 0, Math.PI * 2); ctx.fill();
      ctx.globalAlpha = 1;
    }
    const wide = ['train', 'pen', 'pet_shop', 'sofa', 'bed', 'table', 'portal'].includes(p.type) ? 42 : 22;
    ctx.globalAlpha = .12;
    ctx.fillStyle = '#413b2d';
    ctx.beginPath(); ctx.ellipse(p.x, p.y - 1, wide, 6, 0, 0, Math.PI * 2); ctx.fill();
    ctx.globalAlpha = 1;
    drawPropBody(p);
    if (doRotate) ctx.restore();
    if (active) {
      const tall = ['windmill', 'building', 'stage', 'stall'].includes(p.type);
      const bob = Math.sin(R.t * 4) * 3;
      const ay = p.y - (tall ? 130 : 64) + bob;
      ctx.fillStyle = GOLD;
      ctx.strokeStyle = OUTLINE;
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(p.x, ay + 12); ctx.lineTo(p.x - 8, ay); ctx.lineTo(p.x + 8, ay); ctx.closePath();
      ctx.fill(); ctx.stroke();
    }
  }

  function drawPropBody(p) {
    const ctx = R.ctx;
    const x = p.x, y = p.y;
    switch (p.type) {
      case 'window': {
        px(x - 31, y - 46, 62, 50, OUTLINE);
        px(x - 28, y - 43, 56, 44, '#8ad8f8');
        px(x - 28, y - 43, 56, 12, '#c8f0ff');
        px(x - 20, y - 34, 12, 8, '#ffffff');
        px(x + 4, y - 38, 16, 7, '#ffffff');
        px(x - 1, y - 43, 3, 44, '#fff6dc');
        px(x - 28, y - 22, 56, 3, '#fff6dc');
        px(x - 34, y + 2, 68, 6, '#8a5a32');
        px(x - 34, y + 2, 68, 2, '#c88a4a');
        // curtains
        px(x - 34, y - 48, 10, 52, '#e8a0b8');
        px(x + 24, y - 48, 10, 52, '#e8a0b8');
        px(x - 34, y - 48, 10, 4, '#ffc0d4');
        px(x + 24, y - 48, 10, 4, '#ffc0d4');
        break;
      }
      case 'picture': {
        px(x - 21, y - 25, 42, 30, OUTLINE);
        px(x - 18, y - 22, 36, 24, '#c88a4a');
        px(x - 14, y - 18, 28, 16, '#ffe8a0');
        px(x - 14, y - 10, 28, 8, '#8ac86a');
        px(x - 8, y - 16, 8, 6, '#8ac8f8');
        px(x + 2, y - 16, 8, 6, '#ff9a6a');
        px(x + 8, y - 8, 10, 4, '#5a9a4a');
        break;
      }
      case 'plant': {
        px(x - 12, y - 18, 24, 18, OUTLINE);
        px(x - 10, y - 16, 20, 15, '#b86a3a');
        px(x - 10, y - 16, 20, 3, '#e88a4a');
        px(x - 3, y - 18, 6, 2, '#6a4a2a');
        px(x - 4, y - 40, 8, 24, '#3f8a42');
        px(x - 16, y - 34, 14, 10, '#54a84e');
        px(x + 2, y - 36, 14, 10, '#6ac45a');
        px(x - 12, y - 42, 8, 8, '#7ed46a');
        px(x + 4, y - 44, 8, 8, '#8ee06a');
        px(x - 1, y - 30, 2, 12, '#2f6e36');
        break;
      }
      case 'bed': {
        px(x - 40, y - 44, 80, 44, OUTLINE);
        px(x - 38, y - 22, 74, 20, '#8a5a3a');
        px(x - 36, y - 20, 70, 16, '#a86a42');
        px(x - 36, y - 34, 70, 14, '#fff6dc');
        px(x - 33, y - 40, 24, 10, '#ffffff');
        px(x - 33, y - 40, 24, 3, '#e8e0d0');
        px(x + 6, y - 32, 28, 14, '#e05a7a');
        px(x + 6, y - 32, 28, 3, '#ff8aa0');
        px(x - 40, y - 52, 6, 52, '#6a3a24');
        px(x + 34, y - 46, 6, 46, '#6a3a24');
        px(x - 40, y - 52, 6, 3, '#a86a42');
        break;
      }
      case 'desk': {
        px(x - 34, y - 28, 68, 7, OUTLINE);
        px(x - 32, y - 26, 64, 4, '#a86a3a');
        px(x - 30, y - 22, 5, 20, '#6a4a2a');
        px(x + 25, y - 22, 5, 20, '#6a4a2a');
        px(x - 8, y - 42, 22, 15, '#e8e0d0');
        px(x - 10, y - 44, 26, 3, '#c8b8a0');
        px(x + 16, y - 36, 7, 10, '#5aa8e0');
        px(x + 17, y - 35, 5, 7, '#8ad8f8');
        px(x - 24, y - 12, 22, 3, '#e8d8b8');
        break;
      }
      case 'fridge': {
        px(x - 21, y - 64, 42, 64, OUTLINE);
        px(x - 19, y - 62, 38, 60, '#eef4f4');
        px(x - 19, y - 62, 8, 60, '#ffffff');
        px(x - 19, y - 38, 38, 3, '#b8c4c8');
        px(x + 11, y - 56, 3, 12, '#8a969a');
        px(x + 11, y - 32, 3, 12, '#8a969a');
        px(x - 14, y - 30, 12, 10, '#8ac8e8');
        px(x - 12, y - 28, 8, 6, '#ffd24a');
        break;
      }
      case 'tv': {
        px(x - 38, y - 50, 76, 46, OUTLINE);
        px(x - 35, y - 47, 70, 40, '#2a2a3a');
        px(x - 31, y - 43, 62, 32, '#5a9ac8');
        px(x - 31, y - 43, 62, 10, '#8ad8f8');
        px(x - 24, y - 36, 18, 8, '#ffffff');
        px(x - 2, y - 4, 10, 4, '#2a2a3a');
        px(x - 14, y + 1, 34, 3, '#2a2a3a');
        px(x - 35, y - 47, 70, 3, '#4a4a5e');
        break;
      }
      case 'sofa': {
        px(x - 47, y - 38, 94, 38, OUTLINE);
        px(x - 45, y - 30, 90, 22, '#c85a6a');
        px(x - 45, y - 36, 90, 12, '#e87a8a');
        px(x - 42, y - 34, 38, 8, '#ff9aaa');
        px(x + 4, y - 34, 38, 8, '#ff9aaa');
        px(x - 45, y - 10, 90, 8, '#a84a5a');
        px(x - 45, y - 6, 8, 8, '#5a3a44');
        px(x + 37, y - 6, 8, 8, '#5a3a44');
        px(x - 20, y - 26, 40, 16, '#f2d0a0');
        break;
      }
      case 'table': {
        px(x - 44, y - 26, 88, 8, OUTLINE);
        px(x - 42, y - 24, 84, 5, '#c88a4a');
        px(x - 36, y - 19, 6, 19, '#8a5a32');
        px(x + 30, y - 19, 6, 19, '#8a5a32');
        px(x - 10, y - 38, 20, 9, '#fff6dc');
        px(x - 8, y - 36, 16, 5, '#e8d8b8');
        px(x + 12, y - 34, 7, 8, '#5aa8e0');
        px(x - 24, y - 24, 12, 3, '#e8d8b8');
        break;
      }
      case 'easel': {
        px(x - 2, y - 58, 4, 58, '#8a5a3a');
        px(x - 18, y - 54, 36, 34, OUTLINE);
        px(x - 15, y - 51, 30, 28, '#fff6dc');
        px(x - 11, y - 47, 22, 20, '#c8e8ff');
        px(x - 11, y - 34, 22, 7, '#8ac86a');
        px(x - 5, y - 42, 7, 7, '#ffd24a');
        px(x - 16, y - 18, 32, 4, '#8a5a3a');
        px(x - 12, y - 14, 4, 14, '#6a4a2a');
        px(x + 8, y - 14, 4, 14, '#6a4a2a');
        break;
      }
      case 'kitchen': {
        px(x - 48, y - 34, 96, 34, OUTLINE);
        px(x - 46, y - 32, 92, 30, '#d8b888');
        px(x - 46, y - 36, 92, 5, '#8a6a4a');
        px(x - 24, y - 40, 48, 6, '#5a5a6a');
        px(x - 18, y - 38, 10, 3, '#8a8a9a');
        px(x + 8, y - 38, 10, 3, '#8a8a9a');
        px(x + 22, y - 20, 16, 16, '#b89a6a');
        px(x + 24, y - 18, 12, 10, '#8a6a4a');
        // pot + steam
        px(x - 32, y - 44, 18, 8, OUTLINE);
        px(x - 30, y - 42, 14, 6, '#8a8a9a');
        px(x - 26, y - 46, 4, 3, '#c8c8d8');
        ctx.globalAlpha = .45;
        px(x - 26, y - 54 - (Math.sin(R.t * 3) * 3 + 3), 3, 4, '#ffffff');
        ctx.globalAlpha = 1;
        break;
      }
      case 'workbench': {
        px(x - 36, y - 30, 72, 8, OUTLINE);
        px(x - 34, y - 28, 68, 5, '#a86a3a');
        px(x - 32, y - 22, 6, 22, '#6a4a2a');
        px(x + 26, y - 22, 6, 22, '#6a4a2a');
        px(x - 22, y - 42, 14, 12, '#8a969a');
        px(x - 24, y - 44, 18, 4, '#c8d0d4');
        px(x + 4, y - 40, 8, 10, '#e0b05a');
        px(x + 14, y - 34, 12, 4, '#8a969a');
        px(x - 6, y - 36, 4, 8, '#5a3a2a');
        break;
      }
      case 'catbed': {
        px(x - 26, y - 16, 52, 16, OUTLINE);
        px(x - 24, y - 14, 48, 12, '#d8a06a');
        px(x - 18, y - 18, 36, 8, '#f2c890');
        px(x - 10, y - 24, 22, 12, '#e8a04a');
        px(x + 10, y - 26, 10, 8, '#e8a04a');
        px(x - 4, y - 20, 3, 2, '#3a2a2a');
        px(x + 6, y - 22, 2, 2, '#3a2a2a');
        px(x - 1, y - 26, 2, 2, '#c87a3a');
        px(x + 16, y - 22, 2, 2, '#3a2a2a');
        break;
      }
      case 'bookshelf': {
        px(x - 30, y - 74, 60, 74, OUTLINE);
        px(x - 27, y - 71, 54, 68, '#8a5a3a');
        for (let i = 0; i < 3; i++) {
          px(x - 25, y - 64 + i * 21, 50, 17, '#6a4a2a');
          px(x - 25, y - 47 + i * 21, 50, 2, '#a86a42');
          for (let j = 0; j < 6; j++) px(x - 22 + j * 8, y - 62 + i * 21, 6, 14, ['#e05a5a', '#5a8ac8', '#e8b04a', '#6ab85a', '#c88ae0'][j % 5]);
        }
        break;
      }
      case 'fishtank': {
        px(x - 42, y - 36, 84, 6, '#5a3a2a');
        px(x - 36, y - 30, 6, 30, '#6a4a2a');
        px(x + 30, y - 30, 6, 30, '#6a4a2a');
        px(x - 38, y - 74, 76, 40, OUTLINE);
        px(x - 35, y - 71, 70, 34, 'rgba(140,220,248,.85)');
        px(x - 35, y - 71, 70, 6, 'rgba(255,255,255,.5)');
        px(x - 30, y - 42, 60, 4, '#8a6a4a');
        px(x - 24, y - 50, 8, 10, '#4a9a5a');
        px(x - 14, y - 48, 6, 8, '#5ab86a');
        px(x + 10, y - 52, 8, 8, '#e07a5a');
        // fish
        const f1 = x - 20 + Math.sin(R.t * 1.6) * 12;
        const f2 = x + 12 + Math.sin(R.t * 1.2 + 2) * 10;
        px(f1, y - 58, 8, 4, '#ffd24a'); px(f1 - 3, y - 57, 3, 2, '#ffd24a');
        px(f2, y - 64, 7, 3, '#ff7aa8'); px(f2 + 7, y - 63, 2, 2, '#ff7aa8');
        break;
      }
      case 'clock': {
        px(x - 18, y - 70, 36, 36, OUTLINE);
        px(x - 15, y - 67, 30, 30, '#fff6dc');
        px(x - 15, y - 67, 30, 3, '#e8d8b8');
        px(x - 1, y - 63, 2, 11, INK);
        const S2 = root.PLGame ? root.PLGame.S : null;
        const mins = S2 ? S2.timeMin : 720;
        const ang = ((mins % 720) / 720) * Math.PI * 2;
        px(x + Math.sin(ang) * 8, y - 52 + Math.cos(ang) * 8, 2, 2, '#e05a5a');
        px(x - 2, y - 74, 4, 3, '#8a5a32');
        break;
      }
      case 'rug': {
        px(x - 50, y - 18, 100, 18, OUTLINE);
        px(x - 47, y - 15, 94, 12, '#c85a7a');
        px(x - 42, y - 13, 84, 8, '#e88aa0');
        px(x - 30, y - 11, 60, 4, '#ffd24a');
        break;
      }
      case 'farm_plot': {
        const G = root.PLGame;
        const plot = (p.index !== undefined && G && G.S.farm[p.index]) ? G.S.farm[p.index] : (p.plot || { crop: '', growth: 0, watered: false });
        px(x - 38, y - 18, 76, 40, OUTLINE);
        px(x - 35, y - 15, 70, 34, '#8a5a32');
        px(x - 32, y - 12, 64, 28, '#6a4024');
        for (let i = 0; i < 4; i++) px(x - 30 + i * 17, y - 10, 12, 25, '#7a4a2a');
        if (plot.crop) {
          const c = (D.CROPS || []).find((k) => k.id === plot.crop) || { color: '#6aa85a', days: 3 };
          const grow = Math.min(1, plot.growth / c.days);
          const hgt = 8 + grow * 24;
          for (let i = 0; i < 3; i++) {
            const cx2 = x - 20 + i * 20;
            px(cx2, y - hgt, 7, hgt, shade(c.color, .8));
            px(cx2 + 7, y - hgt + 2, 3, hgt - 2, c.color);
            px(cx2 - 2, y - hgt - 5, 12, 7, shade(c.color, 1.15));
            px(cx2 + 1, y - hgt - 8, 6, 4, shade(c.color, 1.3));
          }
          if (plot.growth >= c.days) {
            px(x + 28, y - 34 + Math.sin(R.t * 4) * 2, 4, 4, GOLD);
            px(x + 30, y - 38 + Math.sin(R.t * 4) * 2, 2, 10, GOLD);
          }
        } else {
          px(x - 22, y - 8, 12, 3, '#9a6a3a');
          px(x + 8, y - 4, 14, 3, '#9a6a3a');
        }
        if (plot.crop && plot.watered) {
          ctx.globalAlpha = .38;
          px(x - 32, y - 6, 64, 4, '#8ad8f8');
          ctx.globalAlpha = 1;
        }
        break;
      }
      case 'pond': {
        const rg = ctx.createRadialGradient(x - 12, y - 8, 8, x, y, 74);
        rg.addColorStop(0, '#8ae0f8'); rg.addColorStop(.6, '#4aa8d8'); rg.addColorStop(1, '#2a7aa8');
        ctx.fillStyle = '#3a8a5a';
        ctx.beginPath(); ctx.ellipse(x, y, 78, 30, 0, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = rg;
        ctx.beginPath(); ctx.ellipse(x, y - 2, 72, 26, 0, 0, Math.PI * 2); ctx.fill();
        // ripples
        for (let i = 0; i < 3; i++) {
          ctx.globalAlpha = .35;
          ctx.strokeStyle = '#c8f4ff'; ctx.lineWidth = 2;
          ctx.beginPath(); ctx.ellipse(x - 20 + i * 18, y - 6 + i * 4, 14 + i * 4, 4, 0, 0, Math.PI * 2); ctx.stroke();
          ctx.globalAlpha = 1;
        }
        // lily pads
        px(x + 22, y - 10, 16, 5, '#4aa84a');
        px(x + 26, y - 12, 8, 3, '#6ac45a');
        px(x - 36, y + 2, 12, 4, '#4aa84a');
        px(x + 6, y + 6, 5, 5, '#ff9ac8');
        break;
      }
      case 'tree': drawTree(x, y, p.s || 1); break;
      case 'bench': drawBench(x, y); break;
      case 'lamp': drawLamp(x, y, 'warm'); break;
      case 'flowers': drawFlowers(x, y); break;
      case 'sparkle': {
        const tw = (Math.sin(R.t * 3 + x) + 1) / 2;
        ctx.globalAlpha = .22 + tw * .35;
        ctx.fillStyle = '#fff2a0';
        ctx.beginPath(); ctx.arc(x, y - 18, 20 + tw * 8, 0, Math.PI * 2); ctx.fill();
        ctx.globalAlpha = 1;
        px(x - 2, y - 30, 4, 22, GOLD);
        px(x - 10, y - 22, 20, 4, GOLD);
        px(x - 6, y - 26, 12, 12, '#fff6c8');
        px(x - 2, y - 22, 4, 4, '#ffffff');
        break;
      }
      case 'bugspot': {
        drawBush(x, y, .9);
        const bx = x - 8 + Math.sin(R.t * 1.8) * 12;
        const by = y - 32 + Math.cos(R.t * 2.1) * 6;
        px(bx - 4, by, 4, 4, '#ffd24a');
        px(bx + 2, by, 4, 4, '#ff9a4a');
        px(bx - 1, by - 2, 2, 2, '#fff6c8');
        break;
      }
      case 'bus': {
        px(x - 52, y - 40, 104, 40, OUTLINE);
        px(x - 49, y - 37, 98, 34, '#e05a4a');
        px(x - 49, y - 37, 98, 6, '#ff8a6a');
        px(x - 49, y - 14, 98, 4, '#fff6dc');
        for (let i = 0; i < 4; i++) {
          px(x - 42 + i * 22, y - 31, 17, 14, '#8ad8f8');
          px(x - 42 + i * 22, y - 31, 17, 3, '#c8f0ff');
        }
        px(x - 46, y - 40, 24, 8, '#3a2a34');
        px(x - 43, y - 38, 18, 4, '#ffd24a');
        px(x - 40, y - 12, 18, 10, '#2a2a34');
        px(x + 22, y - 12, 18, 10, '#2a2a34');
        px(x - 36, y - 9, 10, 4, '#8a8a9a');
        px(x + 26, y - 9, 10, 4, '#8a8a9a');
        px(x + 44, y - 28, 5, 8, '#fff2a0');
        px(x - 52, y - 10, 6, 6, '#ffd24a');
        break;
      }
      case 'board': {
        px(x - 74, y - 56, 148, 60, OUTLINE);
        px(x - 71, y - 53, 142, 54, '#2f5a44');
        px(x - 66, y - 47, 132, 42, '#2a6a4a');
        px(x - 56, y - 38, 64, 3, '#e8f0e0');
        px(x - 56, y - 28, 98, 3, '#e8f0e0');
        px(x - 56, y - 18, 80, 3, '#e8f0e0');
        px(x + 34, y - 34, 20, 14, '#fff6dc');
        px(x - 70, y - 2, 140, 5, '#8a5a32');
        break;
      }
      case 'shelf': {
        px(x - 44, y - 60, 88, 60, OUTLINE);
        px(x - 41, y - 57, 82, 54, '#c8a878');
        for (let i = 0; i < 3; i++) {
          px(x - 38, y - 51 + i * 18, 76, 14, '#a88858');
          px(x - 38, y - 38 + i * 18, 76, 2, '#8a6a3a');
          for (let j = 0; j < 7; j++) {
            px(x - 34 + j * 11, y - 49 + i * 18, 8, 11, ['#e8d8b8', '#e05a5a', '#5a8ac8', '#ffd24a', '#6ab86a'][j % 5]);
            px(x - 33 + j * 11, y - 48 + i * 18, 6, 3, 'rgba(255,255,255,.45)');
          }
        }
        px(x - 44, y - 3, 88, 3, '#8a6a3a');
        break;
      }
      case 'counter': {
        px(x - 52, y - 30, 104, 30, OUTLINE);
        px(x - 50, y - 27, 100, 25, '#b87a4a');
        px(x - 54, y - 36, 108, 8, '#e8b87a');
        px(x - 54, y - 36, 108, 3, '#ffd0a0');
        for (let i = 0; i < 3; i++) px(x - 42 + i * 32, y - 24, 24, 3, '#d89a5a');
        // register
        px(x - 14, y - 50, 26, 15, '#3a3a4a');
        px(x - 11, y - 47, 20, 8, '#8ae0c0');
        px(x - 4, y - 42, 8, 2, '#2a2a3a');
        break;
      }
      case 'festival': {
        px(x - 52, y - 24, 104, 24, '#8a5a3a');
        px(x - 48, y - 26, 96, 6, '#c88a4a');
        px(x - 42, y - 66, 6, 42, '#6a4a2a');
        px(x + 36, y - 66, 6, 42, '#6a4a2a');
        px(x - 52, y - 76, 104, 12, '#e04a5a');
        for (let i = 0; i < 5; i++) px(x - 50 + i * 21, y - 88, 18, 14, ['#ffd24a', '#8ae0c8', '#ff8ac8', '#8ac8ff', '#ffd24a'][i]);
        for (let i = 0; i < 6; i++) {
          const fx = x - 42 + i * 17;
          px(fx, y - 74, 2, 22, '#3a2a34');
          px(fx - 2, y - 54, 6, 5, ['#ffd24a', '#ff8a6a', '#8ae0ff'][i % 3]);
        }
        break;
      }
      case 'stall': {
        const isFood = p.action === 'street_food';
        const awning = isFood ? '#e05a4a' : '#5a8ac8';
        px(x - 50, y - 58, 6, 58, '#6a3a24');
        px(x + 44, y - 58, 6, 58, '#6a3a24');
        px(x - 52, y - 36, 104, 10, '#8a5a32');
        px(x - 50, y - 28, 100, 28, '#a86a3a');
        px(x - 50, y - 28, 100, 3, '#d89a5a');
        // awning
        for (let i = 0; i < 6; i++) {
          px(x - 56 + i * 19, y - 70, 19, 12, i % 2 ? '#fff2dc' : awning);
          px(x - 56 + i * 19, y - 70, 19, 3, i % 2 ? '#ffffff' : shade(awning, 1.18));
          px(x - 56 + i * 19, y - 58, 19, 3, shade(i % 2 ? '#fff2dc' : awning, .82));
        }
        px(x - 58, y - 72, 116, 4, shade(awning, .7));
        // sign
        px(x - 30, y - 84, 60, 14, '#3a2a34');
        ctx.fillStyle = '#ffe8a8'; ctx.font = `700 10px ${FONT}`; ctx.textAlign = 'center';
        ctx.fillText(isFood ? 'ของกิน' : 'ของฝาก', x, y - 73);
        ctx.textAlign = 'left';
        // goods
        for (let i = 0; i < 5; i++) {
          px(x - 42 + i * 18, y - 44, 12, 8, ['#ffd24a', '#ff8a6a', '#8ae0c8', '#ff9ac8', '#c8f06a'][i]);
          px(x - 41 + i * 18, y - 43, 4, 2, '#fff6dc');
        }
        // steam / lantern
        ctx.globalAlpha = .4;
        px(x - 16, y - 92 - (Math.sin(R.t * 2.6) * 4 + 4), 4, 6, '#ffffff');
        px(x + 2, y - 100 - (Math.cos(R.t * 2.2) * 4 + 4), 5, 6, '#ffffff');
        ctx.globalAlpha = 1;
        break;
      }
      case 'stage': {
        px(x - 70, y - 8, 140, 14, OUTLINE);
        px(x - 66, y - 22, 132, 16, '#a86a3a');
        px(x - 66, y - 22, 132, 4, '#d89a5a');
        px(x - 66, y - 6, 132, 6, '#7a4a2a');
        // back wall + speakers
        px(x - 58, y - 70, 26, 50, '#3a2a34');
        px(x - 54, y - 66, 18, 18, '#2a2030');
        px(x - 54, y - 44, 18, 18, '#2a2030');
        px(x + 32, y - 70, 26, 50, '#3a2a34');
        px(x + 36, y - 66, 18, 18, '#2a2030');
        px(x + 36, y - 44, 18, 18, '#2a2030');
        // lights
        const lc = ['#ff6a9a', '#ffd24a', '#6ae0ff', '#9aff8a'];
        for (let i = 0; i < 4; i++) {
          const lx = x - 30 + i * 20;
          px(lx, y - 80, 5, 5, lc[i]);
          ctx.globalAlpha = .18 + Math.sin(R.t * 3 + i) * .08;
          ctx.fillStyle = lc[i];
          ctx.beginPath(); ctx.arc(lx + 2, y - 78, 18, 0, Math.PI * 2); ctx.fill();
          ctx.globalAlpha = 1;
        }
        // mic
        px(x - 2, y - 34, 3, 18, '#3a3a4a');
        px(x - 4, y - 40, 7, 7, '#4a4a5a');
        // notes
        ctx.fillStyle = '#ffe8a8'; ctx.font = `700 16px ${FONT}`; ctx.textAlign = 'center';
        ctx.fillText('♪', x + 22, y - 46 + Math.sin(R.t * 2) * 3);
        ctx.fillText('♫', x - 26, y - 40 + Math.cos(R.t * 2) * 3);
        ctx.textAlign = 'left';
        break;
      }
      case 'lantern': {
        px(x - 2, y - 92, 4, 92, OUTLINE);
        px(x - 1, y - 90, 2, 90, '#5a3a2a');
        px(x - 10, y - 92, 20, 4, '#5a3a2a');
        px(x - 8, y - 86, 16, 4, '#3a2a34');
        px(x - 12, y - 82, 24, 20, OUTLINE);
        px(x - 10, y - 80, 20, 16, '#ff8a4a');
        px(x - 10, y - 80, 20, 4, '#ffd24a');
        px(x - 10, y - 68, 20, 4, '#e05a3a');
        px(x - 2, y - 80, 4, 16, '#ffd24a');
        ctx.globalAlpha = .22 + Math.sin(R.t * 2 + x) * .04;
        ctx.fillStyle = '#ff9a4a';
        ctx.beginPath(); ctx.arc(x, y - 72, 46, 0, Math.PI * 2); ctx.fill();
        ctx.globalAlpha = 1;
        px(x - 6, y - 62, 12, 3, '#3a2a34');
        px(x - 5, y - 59, 2, 5, '#e05a3a');
        px(x + 3, y - 59, 2, 5, '#e05a3a');
        break;
      }
      case 'pier': {
        px(x - 190, y - 26, 380, 46, OUTLINE);
        px(x - 186, y - 22, 372, 38, '#b88a52');
        for (let i = 0; i < 12; i++) px(x - 184 + i * 31, y - 22, 2, 38, '#8a6238');
        px(x - 186, y - 22, 372, 4, '#e0b878');
        px(x - 186, y + 12, 372, 4, '#7a5228');
        // posts
        for (let i = 0; i < 5; i++) {
          const px2 = x - 170 + i * 85;
          px(px2, y - 26, 9, 62, '#6a4a2a');
          px(px2 + 2, y - 26, 3, 62, '#8a6238');
          px(px2 - 3, y - 34, 15, 8, '#5a3a1a');
        }
        break;
      }
      case 'boat': {
        const bob = Math.sin(R.t * 1.4 + x) * 2;
        px(x - 48, y - 18 + bob, 96, 18, OUTLINE);
        px(x - 44, y - 16 + bob, 88, 12, '#a85a2a');
        px(x - 38, y - 14 + bob, 76, 4, '#e8a05a');
        px(x - 30, y - 10 + bob, 60, 4, '#8a441a');
        px(x - 30, y - 26 + bob, 60, 10, OUTLINE);
        px(x - 28, y - 24 + bob, 56, 7, '#e8c890');
        px(x - 18, y - 22 + bob, 10, 4, '#8a5a32');
        px(x + 10, y - 22 + bob, 10, 4, '#8a5a32');
        px(x - 2, y - 46 + bob, 4, 22, '#8a5a32');
        px(x - 10, y - 50 + bob, 20, 7, '#fff2d8');
        px(x - 2, y - 48 + bob, 4, 5, '#e05a4a');
        // oar
        px(x + 28, y - 30 + bob, 4, 22, '#c88a4a');
        px(x + 34, y - 12 + bob, 10, 3, '#c88a4a');
        break;
      }
      case 'crate': {
        px(x - 20, y - 34, 40, 34, OUTLINE);
        px(x - 17, y - 31, 34, 28, '#c88a4a');
        px(x - 17, y - 31, 34, 4, '#e8a862');
        px(x - 17, y - 16, 34, 3, '#a86a32');
        px(x - 15, y - 29, 3, 26, '#a86a32');
        px(x + 12, y - 29, 3, 26, '#a86a32');
        px(x - 6, y - 24, 12, 8, '#8a5a2a');
        break;
      }
      case 'field': {
        for (let r = 0; r < 4; r++) {
          const yy = y - 16 + r * 8;
          px(x - 62, yy, 124, 6, r % 2 ? '#7a4a2a' : '#8a5a32');
          for (let i = 0; i < 9; i++) {
            const fx = x - 56 + i * 14;
            px(fx, yy - 8, 3, 8, '#4a9a3a');
            px(fx - 2, yy - 10, 7, 4, ['#7ed46a', '#a8e86a', '#ffd24a'][(i + r) % 3]);
          }
        }
        break;
      }
      case 'scarecrow': {
        px(x - 2, y - 74, 4, 74, '#6a4a2a');
        px(x - 30, y - 54, 60, 4, '#6a4a2a');
        // shirt
        px(x - 20, y - 68, 40, 26, OUTLINE);
        px(x - 17, y - 65, 34, 20, '#5a8ac8');
        px(x - 17, y - 65, 34, 4, '#7aa8e0');
        px(x - 17, y - 48, 34, 3, '#4a6a9a');
        // straw hands
        px(x - 34, y - 58, 8, 3, '#e8c46a'); px(x + 26, y - 58, 8, 3, '#e8c46a');
        // head
        px(x - 14, y - 92, 28, 26, OUTLINE);
        px(x - 11, y - 89, 22, 20, '#e8d0a0');
        px(x - 6, y - 84, 4, 4, '#3a2a2a');
        px(x + 3, y - 84, 4, 4, '#3a2a2a');
        px(x - 4, y - 76, 8, 3, '#8a5a3a');
        // hat
        px(x - 20, y - 98, 40, 4, OUTLINE);
        px(x - 18, y - 98, 36, 3, '#e8c46a');
        px(x - 10, y - 106, 20, 9, '#f2d888');
        px(x - 10, y - 102, 20, 3, '#b05a3a');
        // birds
        px(x + 34, y - 76 + Math.sin(R.t * 2) * 2, 8, 3, '#3a2a2a');
        px(x + 42, y - 74 + Math.sin(R.t * 2) * 2, 4, 2, '#3a2a2a');
        break;
      }
      case 'pen': {
        const pw = 100, ph = 56;
        // พื้นคอก
        px(x - pw / 2, y - 12, pw, 12, '#c8a45a');
        px(x - pw / 2, y - 12, pw, 2, '#e0c070');
        for (let i = 0; i < 7; i++) px(x - pw / 2 + 6 + i * 13, y - 8, 7, 2, i % 2 ? '#e0c070' : '#b89048');
        // รั้วหลัง
        px(x - pw / 2, y - ph, pw, 3, '#a87444');
        px(x - pw / 2, y - ph, 3, ph - 10, '#8a5a32');
        px(x + pw / 2 - 3, y - ph, 3, ph - 10, '#8a5a32');
        for (let i = 0; i < 4; i++) {
          px(x - pw / 2 + 12 + i * 24, y - ph + 3, 3, ph - 15, '#a87444');
        }
        // สัตว์ในคอก
        drawAnimal(p.animal || 'chicken', x, y - 12, 1.25, R.t + x * .1, false);
        // รั้วหน้า (เว้นช่องตรงกลาง)
        const seg = (pw - 26) / 2;
        for (const side of [-1, 1]) {
          const sx = side < 0 ? x - pw / 2 : x + 13;
          px(sx, y - 14, seg, 3, '#b8844a');
          px(sx, y - 14, seg, 1, '#d8a868');
          px(sx + (side < 0 ? 0 : seg - 3), y - 16, 3, 12, '#8a5a32');
          px(sx + (side < 0 ? 11 : seg - 14), y - 16, 3, 12, '#a87444');
        }
        // อาหารในราง
        px(x - 15, y - 4, 30, 4, '#8a5a32');
        px(x - 12, y - 5, 24, 2, '#d8b060');
        break;
      }
      case 'trough': {
        px(x - 34, y - 22, 68, 22, OUTLINE);
        px(x - 31, y - 19, 62, 18, '#8a5a32');
        px(x - 31, y - 19, 62, 4, '#a87444');
        px(x - 27, y - 15, 28, 10, '#d8b060');
        for (let i = 0; i < 4; i++) px(x - 25 + i * 7, y - 13, 4, 2, '#f0d080');
        px(x + 3, y - 15, 24, 10, '#5a8ac8');
        px(x + 5, y - 13, 20, 2, '#8ab8e8');
        px(x - 38, y - 20, 5, 20, '#6a4a2a'); px(x + 33, y - 20, 5, 20, '#6a4a2a');
        break;
      }
      case 'pet_house': {
        px(x - 34, y - 46, 68, 46, OUTLINE);
        px(x - 31, y - 43, 62, 43, '#c88a4a');
        px(x - 31, y - 43, 62, 5, '#e0a45a');
        // roof
        px(x - 42, y - 52, 84, 8, OUTLINE);
        px(x - 38, y - 54, 76, 8, '#8a5a32');
        px(x - 34, y - 58, 68, 6, '#a86a3a');
        // door
        px(x - 15, y - 30, 30, 30, OUTLINE);
        px(x - 12, y - 27, 24, 27, '#4a2a1a');
        px(x - 9, y - 24, 18, 24, '#5a3420');
        // heart sign
        px(x - 5, y - 38, 3, 3, '#ff8ab0'); px(x + 2, y - 38, 3, 3, '#ff8ab0');
        px(x - 6, y - 36, 12, 3, '#ff8ab0'); px(x - 4, y - 33, 8, 2, '#ff8ab0');
        px(x - 1, y - 31, 2, 1, '#ff8ab0');
        // bowl
        px(x + 24, y - 6, 12, 6, '#8ac8e8'); px(x + 26, y - 5, 8, 2, '#e8f8ff');
        break;
      }
      case 'metro_entry': {
        if (p.up) {
          // บันไดขึ้นสู่ผิวดิน
          px(x - 40, y - 24, 80, 24, OUTLINE);
          for (let i = 0; i < 5; i++) {
            px(x - 38 + i * 4, y - 22 - i * 8, 76 - i * 8, 8, i % 2 ? '#8a8aa4' : '#9a9ab4');
            px(x - 38 + i * 4, y - 22 - i * 8, 76 - i * 8, 2, '#c8c8dc');
          }
          px(x - 32, y - 26, 10, 20, '#6a6a86');
          px(x + 22, y - 26, 10, 20, '#6a6a86');
          // ลูกศรขึ้น
          px(x - 4, y - 56, 8, 8, '#8ae06a');
          px(x - 8, y - 50, 16, 6, '#8ae06a');
          px(x - 2, y - 48, 4, 18, '#8ae06a');
          px(x - 18, y - 94, 36, 20, OUTLINE);
          px(x - 16, y - 92, 32, 16, '#2a6a3a');
          px(x - 12, y - 86, 24, 4, '#b8ff9a');
          px(x - 6, y - 80, 12, 4, '#b8ff9a');
          break;
        }
        px(x - 46, y - 28, 92, 28, '#2a2a3a');
        for (let i = 0; i < 4; i++) {
          px(x - 38 + i * 4, y - 24 + i * 5, 76 - i * 8, 4, i % 2 ? '#5a5a6e' : '#494959');
        }
        px(x - 48, y - 36, 6, 36, OUTLINE); px(x - 47, y - 35, 4, 34, '#8a9ab0');
        px(x + 42, y - 36, 6, 36, OUTLINE); px(x + 43, y - 35, 4, 34, '#8a9ab0');
        px(x - 48, y - 38, 96, 4, '#a8b8c8');
        px(x - 20, y - 66, 40, 22, OUTLINE);
        px(x - 18, y - 64, 36, 18, '#e04a5a');
        px(x - 18, y - 64, 36, 3, '#ff7a8a');
        // M
        px(x - 10, y - 59, 3, 10, '#fff6dc');
        px(x - 7, y - 56, 3, 3, '#fff6dc');
        px(x - 4, y - 59, 3, 10, '#fff6dc');
        // light
        const glow = (Math.sin(R.t * 2.4) + 1) / 2;
        ctx.globalAlpha = .35 + glow * .35;
        px(x - 12, y - 42, 24, 6, '#ffe08a');
        ctx.globalAlpha = 1;
        break;
      }
      case 'turnstile': {
        px(x - 18, y - 30, 36, 30, OUTLINE);
        px(x - 15, y - 27, 30, 27, '#8a8a9a');
        px(x - 15, y - 27, 30, 4, '#b8b8c8');
        px(x - 8, y - 22, 16, 8, '#5a5a6a');
        px(x - 4, y - 20, 8, 3, '#8ae06a');
        ctx.save();
        ctx.translate(x, y - 42);
        ctx.rotate(R.t * 1.4);
        for (let i = 0; i < 3; i++) {
          ctx.save();
          ctx.rotate((i * Math.PI * 2) / 3);
          px(-2, -24, 4, 24, OUTLINE);
          px(-1, -23, 2, 22, '#e8eef4');
          ctx.restore();
        }
        px(-6, -8, 12, 12, '#c8d0d8');
        px(-3, -5, 6, 6, '#8a9ab0');
        ctx.restore();
        break;
      }
      case 'ticket_machine': {
        px(x - 20, y - 62, 40, 62, OUTLINE);
        px(x - 17, y - 59, 34, 59, '#4a6ac8');
        px(x - 17, y - 59, 34, 5, '#6a8ae8');
        px(x - 12, y - 52, 24, 18, '#1a2a4a');
        px(x - 10, y - 50, 20, 14, '#7ae8d8');
        px(x - 8, y - 47, 12, 2, '#1a4a4a');
        px(x - 8, y - 43, 8, 2, '#1a4a4a');
        px(x - 10, y - 28, 20, 6, '#e8c86a');
        px(x - 6, y - 26, 12, 2, '#8a6a2a');
        px(x - 8, y - 16, 16, 3, '#2a2a3a');
        px(x - 14, y - 8, 8, 3, '#8ae06a');
        break;
      }
      case 'train': {
        const bx = x - 150, by = y - 116;
        px(x - 152, y - 8, 304, 8, 'rgba(0,0,0,.28)');
        px(bx, by, 300, 104, OUTLINE);
        px(bx + 4, by + 4, 292, 96, '#e8eef4');
        px(bx + 4, by + 4, 292, 10, '#b8c8d8');
        px(bx + 4, by + 58, 292, 16, '#3a6ac8');
        px(bx + 4, by + 74, 292, 4, '#2a4a9a');
        px(bx + 250, by + 10, 44, 84, OUTLINE);
        px(bx + 254, by + 14, 36, 76, '#d8e4ee');
        px(bx + 258, by + 26, 28, 24, '#6ac8f0');
        px(bx + 262, by + 30, 20, 16, '#a8e8ff');
        px(bx + 262, by + 60, 20, 8, '#ffe08a');
        for (let i = 0; i < 5; i++) {
          px(bx + 18 + i * 46, by + 22, 34, 26, OUTLINE);
          px(bx + 21 + i * 46, by + 25, 28, 20, '#8ae0ff');
          px(bx + 23 + i * 46, by + 27, 10, 6, '#e8fbff');
          px(bx + 21 + i * 46, by + 41, 28, 3, '#c8eefa');
        }
        px(bx + 246, by + 30, 2, 36, '#9ab0c0');
        [bx + 60, bx + 120, bx + 200, bx + 258].forEach((wx) => {
          px(wx - 12, y - 26, 24, 24, OUTLINE);
          px(wx - 8, y - 22, 16, 16, '#5a5a6e');
          px(wx - 3, y - 17, 6, 6, '#9a9ab0');
        });
        px(bx + 292, by + 66, 8, 10, '#ffe08a');
        px(bx + 20, by - 16, 84, 16, OUTLINE);
        px(bx + 22, by - 14, 80, 12, '#e04a5a');
        px(bx + 30, by - 11, 64, 6, '#fff6dc');
        break;
      }
      case 'guild_board': {
        px(x - 46, y - 84, 92, 60, OUTLINE);
        px(x - 42, y - 80, 84, 52, '#6a4a2a');
        px(x - 38, y - 76, 76, 44, '#c8a45a');
        [[-30, -70, 18, 12, '#fff6dc'], [-7, -72, 20, 14, '#ffe8c0'], [16, -68, 16, 12, '#e8f0ff']].forEach(([ox, oy, w, h, c]) => {
          px(x + ox, y + oy, w, h, c);
          px(x + ox + 2, y + oy + 3, w - 4, 2, '#8a6a4a');
          px(x + ox + 2, y + oy + 7, w - 8, 1, '#b89a6a');
        });
        px(x - 10, y - 58, 4, 4, '#b87ae8');
        px(x + 6, y - 54, 3, 3, '#7ae8d8');
        px(x - 44, y - 25, 6, 25, '#8a5a32');
        px(x + 38, y - 25, 6, 25, '#8a5a32');
        px(x - 30, y - 90, 60, 6, OUTLINE);
        px(x - 28, y - 89, 56, 4, '#a86a3a');
        break;
      }
      case 'crystal_rock': {
        px(x - 26, y - 10, 52, 10, OUTLINE);
        px(x - 22, y - 8, 44, 8, '#4a3e62');
        const crCols = ['#e87ae8', '#7ae8ff', '#b89aff'];
        [[-16, -30, 12, 30], [0, -44, 14, 44], [14, -24, 10, 24]].forEach(([ox, oy, w, h], i) => {
          px(x + ox - 1, y + oy, w + 2, h, OUTLINE);
          px(x + ox, y + oy + 1, w, h - 1, crCols[i % 3]);
          px(x + ox + 2, y + oy + 3, w - 6, h - 6, shade(crCols[i % 3], 1.2));
          px(x + ox + 1, y + oy + 1, 2, h - 3, '#ffffff');
        });
        const tw = (Math.sin(R.t * 3 + 1) + 1) / 2;
        ctx.globalAlpha = .4 + tw * .6;
        px(x - 24, y - 36, 3, 3, '#ffffff');
        px(x + 24, y - 40, 3, 3, '#e8fbff');
        ctx.globalAlpha = 1;
        break;
      }
      case 'portal': {
        const cy2 = y - 60;
        ctx.save();
        ctx.globalAlpha = .32;
        ctx.fillStyle = '#b87ae8';
        ctx.beginPath(); ctx.ellipse(x, cy2, 46, 58, 0, 0, Math.PI * 2); ctx.fill();
        ctx.globalAlpha = 1;
        ctx.restore();
        px(x - 36, y - 122, 12, 122, OUTLINE);
        px(x - 32, y - 118, 8, 118, '#5a4a6a');
        px(x + 24, y - 122, 12, 122, OUTLINE);
        px(x + 24, y - 118, 8, 118, '#5a4a6a');
        px(x - 38, y - 130, 76, 12, OUTLINE);
        px(x - 34, y - 128, 68, 8, '#6a5a7a');
        px(x - 12, y - 136, 24, 8, '#8a6ab0');
        ctx.save();
        ctx.translate(x, cy2);
        const pg = ctx.createRadialGradient(0, 0, 4, 0, 0, 32);
        pg.addColorStop(0, 'rgba(255,255,255,.95)');
        pg.addColorStop(.4, 'rgba(184,122,232,.9)');
        pg.addColorStop(1, 'rgba(88,42,158,.12)');
        ctx.fillStyle = pg;
        ctx.beginPath(); ctx.ellipse(0, 0, 30, 42, 0, 0, Math.PI * 2); ctx.fill();
        for (let i = 0; i < 5; i++) {
          const a = R.t * 1.6 + i * 1.25;
          px(Math.cos(a) * 20, Math.sin(a) * 28, 3, 3, '#f0d8ff');
        }
        ctx.restore();
        break;
      }
      case 'cauldron': {
        for (let i = 0; i < 4; i++) {
          const fh = 6 + Math.sin(R.t * 5 + i) * 3;
          px(x - 18 + i * 10, y - fh, 7, fh, i % 2 ? '#ff9a3a' : '#ffd24a');
        }
        px(x - 26, y - 34, 52, 28, OUTLINE);
        px(x - 23, y - 31, 46, 24, '#3a3a4a');
        px(x - 23, y - 31, 46, 3, '#5a5a6e');
        px(x - 18, y - 28, 6, 18, '#5a5a6e');
        px(x - 22, y - 36, 44, 6, '#8ae86a');
        px(x - 18, y - 38, 36, 3, '#b8ff8a');
        const bb = (Math.sin(R.t * 2) + 1) / 2;
        px(x - 10 + bb * 14, y - 41, 4, 4, '#c8ff9a');
        px(x + 4 - bb * 10, y - 45, 3, 3, '#a8f27a');
        px(x - 30, y - 28, 4, 14, '#2a2a34');
        px(x + 26, y - 28, 4, 14, '#2a2a34');
        break;
      }
      case 'potion_shelf': {
        px(x - 34, y - 94, 68, 8, OUTLINE);
        px(x - 34, y - 58, 68, 6, '#8a5a32');
        px(x - 34, y - 20, 68, 6, '#8a5a32');
        px(x - 32, y - 94, 4, 94, '#6a4a2a');
        px(x + 28, y - 94, 4, 94, '#6a4a2a');
        const potions = [
          [-26, -92, '#ff6a8a'], [-14, -90, '#6ac8ff'], [-2, -92, '#8ae06a'], [10, -90, '#ffd24a'],
          [-24, -56, '#b87ae8'], [-10, -54, '#ff8a3a'], [4, -56, '#7ae8d8'], [16, -54, '#e86ae8'],
        ];
        potions.forEach(([ox, oy, c], i) => {
          px(x + ox, y + oy + 6, 10, 16, OUTLINE);
          px(x + ox + 1, y + oy + 8, 8, 13, c);
          px(x + ox + 2, y + oy + 9, 3, 8, shade(c, 1.3));
          px(x + ox + 3, y + oy, 4, 7, '#d8e8f0');
          px(x + ox + 2, y + oy - 2, 6, 3, '#8a5a32');
          if (i % 3 === 0) px(x + ox + 4, y + oy + 12, 2, 2, '#ffffff');
        });
        break;
      }
      case 'neon_sign': {
        const flick = Math.sin(R.t * 7) > -.85 ? 1 : .35;
        ctx.globalAlpha = flick;
        px(x - 46, y - 34, 92, 34, '#241a34');
        px(x - 42, y - 30, 84, 26, '#3a2450');
        ctx.shadowColor = '#b87ae8';
        ctx.shadowBlur = 12;
        px(x - 38, y - 27, 76, 4, '#e87ae8');
        px(x - 38, y - 12, 76, 4, '#7ae8ff');
        ctx.shadowBlur = 0;
        // rune
        px(x - 8, y - 25, 4, 12, '#f0d8ff');
        px(x - 4, y - 21, 8, 4, '#f0d8ff');
        px(x + 2, y - 25, 4, 12, '#f0d8ff');
        ctx.globalAlpha = 1;
        px(x - 44, y - 2, 88, 3, '#3a2450');
        break;
      }
      case 'pet_shop': {
        px(x - 58, y - 48, 116, 48, OUTLINE);
        px(x - 55, y - 45, 110, 45, '#c8a46a');
        px(x - 55, y - 45, 110, 6, '#e0c08a');
        // awning
        for (let i = 0; i < 6; i++) {
          px(x - 62 + i * 21, y - 62, 21, 16, i % 2 ? '#e87aa8' : '#fff2e0');
        }
        px(x - 64, y - 64, 128, 4, OUTLINE);
        // cages
        [[-40, -38], [-14, -38], [12, -38]].forEach(([ox, oy], i) => {
          px(x + ox, y + oy, 24, 30, OUTLINE);
          px(x + ox + 2, y + oy + 2, 20, 26, '#4a3a2a');
          px(x + ox + 3, y + oy + 3, 18, 24, '#6a5a4a');
          for (let b = 0; b < 4; b++) px(x + ox + 3 + b * 5, y + oy + 3, 1, 24, '#8a7a6a');
          drawAnimal(['cat', 'slime', 'owl'][i], x + ox + 12, y + oy + 26, .7, R.t + i, false);
        });
        // sign
        px(x - 26, y - 80, 52, 18, OUTLINE);
        px(x - 24, y - 78, 48, 14, '#8a5ac8');
        px(x - 16, y - 74, 5, 5, '#fff6dc');
        px(x - 14, y - 76, 2, 2, '#fff6dc'); px(x - 10, y - 76, 2, 2, '#fff6dc');
        px(x - 2, y - 74, 5, 5, '#fff6dc');
        px(x, y - 76, 2, 2, '#fff6dc'); px(x + 4, y - 76, 2, 2, '#fff6dc');
        break;
      }
      case 'petbed': {
        const nb = Math.sin(R.t * 2) * 1;
        px(x - 20, y - 10 + nb, 40, 10, OUTLINE);
        px(x - 18, y - 9 + nb, 36, 8, '#e88ab0');
        px(x - 20, y - 14 + nb, 6, 8, '#e88ab0');
        px(x + 14, y - 14 + nb, 6, 8, '#e88ab0');
        px(x - 14, y - 8 + nb, 28, 5, '#ffd8e8');
        px(x - 14, y - 14 + nb, 28, 6, '#f2a8c8');
        px(x - 12, y - 12 + nb, 24, 2, '#ffd8e8');
        break;
      }
      case 'altar': {
        px(x - 26, y - 16, 52, 16, OUTLINE);
        px(x - 23, y - 14, 46, 14, '#8a8aa0');
        px(x - 23, y - 14, 46, 3, '#b8b8cc');
        px(x - 18, y - 30, 36, 16, OUTLINE);
        px(x - 15, y - 28, 30, 14, '#9a9ab0');
        px(x - 15, y - 28, 30, 2, '#c8c8dc');
        const ag = (Math.sin(R.t * 2.2) + 1) / 2;
        ctx.globalAlpha = .35 + ag * .4;
        px(x - 22, y - 56, 44, 26, '#b87ae8');
        ctx.globalAlpha = 1;
        px(x - 7, y - 52, 14, 22, OUTLINE);
        px(x - 5, y - 50, 10, 20, '#e8a8ff');
        px(x - 3, y - 48, 4, 14, '#ffffff');
        px(x - 10, y - 54, 20, 3, '#7ae8ff');
        break;
      }
      case 'crystal_lamp': {
        px(x - 3, y - 34, 6, 34, OUTLINE);
        px(x - 2, y - 33, 4, 33, '#5a4a6a');
        px(x - 12, y - 4, 24, 4, '#3a2a4a');
        const lg = (Math.sin(R.t * 2) + 1) / 2;
        ctx.globalAlpha = .3 + lg * .35;
        ctx.fillStyle = '#e8a8ff';
        ctx.beginPath(); ctx.ellipse(x, y - 44, 18, 18, 0, 0, Math.PI * 2); ctx.fill();
        ctx.globalAlpha = 1;
        px(x - 8, y - 54, 16, 14, OUTLINE);
        px(x - 6, y - 52, 12, 10, '#f0c8ff');
        px(x - 3, y - 50, 4, 6, '#ffffff');
        px(x - 10, y - 40, 20, 3, '#7ae8ff');
        break;
      }
      case 'wardrobe': {
        px(x - 22, y - 56, 44, 56, OUTLINE);
        px(x - 19, y - 53, 40, 53, '#a86a3a');
        px(x - 19, y - 53, 40, 4, '#c88a4a');
        px(x - 1, y - 50, 2, 47, '#6a4a2a');
        px(x - 17, y - 48, 14, 24, '#8a5a2a');
        px(x + 3, y - 48, 14, 24, '#8a5a2a');
        px(x - 5, y - 30, 3, 6, GOLD);
        px(x + 2, y - 30, 3, 6, GOLD);
        px(x - 17, y - 18, 14, 14, '#8a5a2a');
        px(x + 3, y - 18, 14, 14, '#8a5a2a');
        px(x - 24, y - 58, 48, 3, '#6a4a2a');
        break;
      }
      case 'vanity': {
        px(x - 26, y - 26, 52, 26, OUTLINE);
        px(x - 23, y - 23, 46, 23, '#c88a5a');
        px(x - 23, y - 23, 46, 3, '#e8aa7a');
        px(x - 14, y - 34, 28, 10, '#8a5a2a');
        px(x - 16, y - 40, 32, 6, '#a86a3a');
        // mirror
        px(x - 16, y - 72, 32, 32, OUTLINE);
        px(x - 13, y - 69, 26, 26, '#c8e8f0');
        px(x - 11, y - 67, 10, 18, '#e8fbff');
        px(x - 13, y - 69, 26, 3, '#8ae0e8');
        // items
        px(x - 24, y - 30, 5, 5, '#e87aa8');
        px(x + 18, y - 30, 6, 5, '#b87ae8');
        break;
      }
      case 'banner': {
        px(x - 16, y - 96, 32, 3, '#8a5a32');
        px(x - 16, y - 93, 32, 62, OUTLINE);
        px(x - 13, y - 90, 26, 56, '#6a3a9a');
        px(x - 13, y - 90, 26, 4, '#8a5aba');
        px(x - 13, y - 38, 26, 3, GOLD);
        px(x - 16, y - 38, 6, 8, '#6a3a9a'); px(x + 10, y - 38, 6, 8, '#6a3a9a');
        px(x - 4, y - 78, 8, 8, GOLD);
        px(x - 1, y - 84, 2, 6, GOLD);
        px(x - 7, y - 70, 14, 2, GOLD);
        px(x - 8, y - 58, 16, 2, '#d8c8f0');
        px(x - 5, y - 54, 10, 2, '#d8c8f0');
        break;
      }
      case 'windmill': {
        // tower
        px(x - 28, y - 106, 56, 106, OUTLINE);
        px(x - 24, y - 102, 48, 102, '#e8d8b8');
        px(x - 20, y - 102, 8, 102, '#f6ecd8');
        px(x + 4, y - 102, 10, 102, '#c8b898');
        for (let i = 0; i < 5; i++) px(x - 22, y - 90 + i * 18, 44, 2, '#c8b898');
        px(x - 9, y - 34, 18, 34, '#6a4a2a');
        px(x - 6, y - 31, 12, 28, '#8a5a32');
        // cap
        px(x - 32, y - 120, 64, 18, OUTLINE);
        px(x - 28, y - 118, 56, 14, '#5a7a5a');
        px(x - 28, y - 118, 56, 4, '#7a9a7a');
        // blades
        ctx.save();
        ctx.translate(x, y - 114);
        ctx.rotate(R.t * .55);
        for (let i = 0; i < 4; i++) {
          ctx.save();
          ctx.rotate((i * Math.PI) / 2);
          px(-3, -62, 6, 62, OUTLINE);
          px(-2, -60, 4, 58, '#d8c8a8');
          px(-1, -58, 2, 52, '#f6ecd8');
          px(-9, -58, 9, 22, '#fff6dc');
          px(-8, -56, 6, 18, '#e8d8b8');
          ctx.restore();
        }
        px(-6, -6, 12, 12, '#5a3a2a');
        ctx.restore();
        break;
      }
      default:
        px(x - 14, y - 14, 28, 14, OUTLINE);
        px(x - 12, y - 12, 24, 11, '#b89a6a');
        px(x - 12, y - 12, 24, 3, '#e8c88a');
    }
    void ctx;
  }

  /* ================= สัตว์เลี้ยง / ปศุสัตว์ ================= */
  function drawAnimal(type, x, y, sc, t, flip) {
    const ctx = R.ctx;
    const tm = t === undefined ? R.t : t;
    const q = (a, b, w, h, c) => { ctx.fillStyle = c; ctx.fillRect(a, b, w, h); };
    ctx.save();
    ctx.translate(Math.round(x), Math.round(y));
    ctx.scale((flip ? -1 : 1) * sc, sc);
    const bob = Math.sin(tm * 3.2 + x * .05) * .7;

    if (type === 'cat') {
      q(-16, -18 + bob, 3, 6, OUTLINE); q(-15, -19 + bob, 3, 5, '#e08a3a');
      q(-12, -12 + bob, 13, 9, OUTLINE);
      q(-11, -11 + bob, 12, 7, '#f2a54a');
      q(-11, -11 + bob, 12, 2, '#ffc06a');
      q(-8, -10 + bob, 2, 5, '#d87a2a'); q(-4, -10 + bob, 2, 5, '#d87a2a');
      q(-10, -4, 3, 4, OUTLINE); q(-10, -4, 2, 3, '#e0943a');
      q(-6, -4, 3, 4, OUTLINE); q(-6, -4, 2, 3, '#e0943a');
      q(2, -4, 3, 4, OUTLINE); q(2, -4, 2, 3, '#e0943a');
      q(-3, -18 + bob, 10, 9, OUTLINE);
      q(-2, -17 + bob, 8, 7, '#f2a54a');
      q(-2, -21 + bob, 3, 4, OUTLINE); q(-2, -21 + bob, 2, 3, '#f2a54a');
      q(3, -21 + bob, 3, 4, OUTLINE); q(3, -21 + bob, 2, 3, '#f2a54a');
      q(0, -14 + bob, 2, 2, INK); q(4, -14 + bob, 2, 2, INK);
      q(2, -12 + bob, 2, 1, '#e88a9a');
      q(-2, -17 + bob, 3, 1, '#ffc06a');
    } else if (type === 'dog') {
      q(-15, -17 + bob, 4, 3, OUTLINE); q(-15, -16 + bob, 4, 2, '#8a5a2a');
      q(-12, -12 + bob, 14, 9, OUTLINE);
      q(-11, -11 + bob, 13, 7, '#c88a4a');
      q(-11, -11 + bob, 13, 2, '#e8aa6a');
      q(-10, -4, 3, 4, OUTLINE); q(-10, -4, 2, 3, '#b87a3a');
      q(-5, -4, 3, 4, OUTLINE); q(-5, -4, 2, 3, '#b87a3a');
      q(2, -4, 3, 4, OUTLINE); q(2, -4, 2, 3, '#b87a3a');
      q(-1, -19 + bob, 10, 10, OUTLINE);
      q(0, -18 + bob, 8, 8, '#c88a4a');
      q(-3, -18 + bob, 3, 7, OUTLINE); q(-2, -17 + bob, 2, 6, '#8a5a2a');
      q(7, -18 + bob, 3, 6, OUTLINE); q(7, -17 + bob, 2, 5, '#8a5a2a');
      q(2, -15 + bob, 2, 2, INK); q(6, -15 + bob, 2, 2, INK);
      q(4, -12 + bob, 3, 2, '#3a2a3a');
      q(4, -10 + bob, 2, 2, '#e86a7a');
      q(6, -11 + bob, 2, 1, '#e86a7a');
    } else if (type === 'fox') {
      q(-18, -16 + bob, 5, 8, OUTLINE); q(-17, -17 + bob, 4, 7, '#e87a3a');
      q(-17, -18 + bob, 2, 5, '#fff0e0');
      q(-12, -11 + bob, 13, 8, OUTLINE);
      q(-11, -10 + bob, 12, 6, '#f28a3a');
      q(-11, -8 + bob, 12, 3, '#ffe8d0');
      q(-10, -4, 3, 4, OUTLINE); q(-10, -4, 2, 3, '#3a2a2a');
      q(-5, -4, 3, 4, OUTLINE); q(-5, -4, 2, 3, '#3a2a2a');
      q(2, -4, 3, 4, OUTLINE); q(2, -4, 2, 3, '#3a2a2a');
      q(-2, -18 + bob, 10, 9, OUTLINE);
      q(-1, -17 + bob, 8, 7, '#f28a3a');
      q(-1, -21 + bob, 3, 4, OUTLINE); q(-1, -21 + bob, 2, 3, '#f28a3a');
      q(4, -21 + bob, 3, 4, OUTLINE); q(4, -21 + bob, 2, 3, '#f28a3a');
      q(0, -15 + bob, 2, 2, INK); q(4, -15 + bob, 2, 2, INK);
      q(5, -13 + bob, 2, 1, '#3a2a2a');
      q(-1, -13 + bob, 8, 2, '#fff4e4');
    } else if (type === 'slime') {
      const squash = Math.sin(tm * 4) * 1.5;
      q(-12, -10 + bob - squash, 24, 10 + squash, OUTLINE);
      q(-11, -9 + bob - squash, 22, 9 + squash, '#8ae06a');
      q(-9, -8 + bob - squash, 18, 4, '#b8f29a');
      q(-8, -12 + bob - squash, 4, 4, '#d8ffc0');
      q(-4, -6 + bob - squash, 3, 3, INK);
      q(3, -6 + bob - squash, 3, 3, INK);
      q(-1, -3 + bob - squash, 3, 1, '#4a8a3a');
      q(-13, -2, 4, 2, '#6ac84a'); q(9, -2, 4, 2, '#6ac84a');
    } else if (type === 'owl') {
      q(-10, -19 + bob, 20, 19, OUTLINE);
      q(-9, -18 + bob, 18, 17, '#b8986a');
      q(-9, -18 + bob, 18, 5, '#d8b888');
      q(-7, -12 + bob, 14, 9, '#e8d0a8');
      q(-11, -14 + bob, 4, 9, '#9a7a4a');
      q(7, -14 + bob, 4, 9, '#9a7a4a');
      q(-8, -21 + bob, 4, 4, OUTLINE); q(-8, -21 + bob, 3, 3, '#b8986a');
      q(4, -21 + bob, 4, 4, OUTLINE); q(4, -21 + bob, 3, 3, '#b8986a');
      q(-6, -14 + bob, 4, 4, '#fff6dc'); q(2, -14 + bob, 4, 4, '#fff6dc');
      q(-5, -13 + bob, 2, 2, INK); q(3, -13 + bob, 2, 2, INK);
      q(-2, -10 + bob, 3, 3, '#e8a83a');
      q(-4, -1, 2, 3, '#e8a83a'); q(2, -1, 2, 3, '#e8a83a');
    } else if (type === 'chicken') {
      q(-9, -12 + bob, 15, 10, OUTLINE);
      q(-8, -11 + bob, 14, 8, '#fff6e8');
      q(-8, -11 + bob, 14, 3, '#ffffff');
      q(-4, -9 + bob, 8, 5, '#f0e0c8');
      q(-3, -18 + bob, 9, 8, OUTLINE);
      q(-2, -17 + bob, 7, 7, '#fff6e8');
      q(-1, -21 + bob, 2, 3, '#e04a4a'); q(1, -22 + bob, 2, 4, '#e04a4a'); q(3, -21 + bob, 2, 3, '#e04a4a');
      q(5, -14 + bob, 4, 2, '#e8a83a');
      q(1, -14 + bob, 2, 2, INK);
      q(-6, -18 + bob, 3, 3, '#e04a4a');
      q(-6, -2, 2, 3, '#e8a83a'); q(-1, -2, 2, 3, '#e8a83a'); q(4, -2, 2, 3, '#e8a83a');
    } else if (type === 'cow') {
      q(-15, -16 + bob, 3, 5, OUTLINE); q(-14, -18 + bob, 2, 4, '#e8d8c8');
      q(-14, -74 + bob, 2, 5, '#e8d8c8'); // (unused tall)
      q(-14, -14 + bob, 20, 12, OUTLINE);
      q(-13, -13 + bob, 18, 10, '#f6f0e8');
      q(-11, -12 + bob, 6, 5, '#3a2a2a');
      q(-2, -9 + bob, 5, 4, '#3a2a2a');
      q(-13, -4, 4, 4, OUTLINE); q(-13, -4, 3, 3, '#3a2a2a');
      q(-6, -4, 4, 4, OUTLINE); q(-6, -4, 3, 3, '#3a2a2a');
      q(5, -4, 4, 4, OUTLINE); q(5, -4, 3, 3, '#3a2a2a');
      q(4, -20 + bob, 10, 9, OUTLINE);
      q(5, -19 + bob, 8, 7, '#f6f0e8');
      q(4, -22 + bob, 2, 3, '#e8d8c8'); q(12, -22 + bob, 2, 3, '#e8d8c8');
      q(7, -13 + bob, 4, 3, '#e8a0b0');
      q(8, -12 + bob, 2, 1, '#8a5a6a');
      q(7, -16 + bob, 2, 2, INK); q(11, -16 + bob, 2, 2, INK);
      q(1, -12 + bob, 4, 2, '#e8a0b0');
    } else if (type === 'sheep') {
      q(-12, -14 + bob, 22, 10, OUTLINE);
      for (let i = 0; i < 7; i++) q(-11 + i * 3, -17 + bob + (i % 2) * 2, 5, 6, '#fff6e8');
      q(-11, -12 + bob, 20, 7, '#fff6e8');
      q(-13, -12 + bob, 4, 5, '#e8dcc8');
      q(-13, -4, 3, 4, OUTLINE); q(-13, -4, 2, 3, '#3a2a2a');
      q(-5, -4, 3, 4, OUTLINE); q(-5, -4, 2, 3, '#3a2a2a');
      q(4, -4, 3, 4, OUTLINE); q(4, -4, 2, 3, '#3a2a2a');
      q(5, -19 + bob, 8, 9, OUTLINE);
      q(6, -18 + bob, 6, 7, '#4a3a3a');
      q(6, -20 + bob, 2, 2, '#2a1a1a'); q(10, -20 + bob, 2, 2, '#2a1a1a');
      q(7, -16 + bob, 2, 2, '#fff6dc'); q(10, -16 + bob, 2, 2, '#fff6dc');
      q(8, -13 + bob, 3, 2, '#2a1a1a');
    } else if (type === 'goat') {
      q(-15, -16 + bob, 3, 4, OUTLINE); q(-14, -15 + bob, 2, 3, '#c8b088');
      q(-12, -13 + bob, 19, 10, OUTLINE);
      q(-11, -12 + bob, 17, 8, '#d8c09a');
      q(-11, -12 + bob, 17, 2, '#e8d4b0');
      q(-11, -4, 3, 4, OUTLINE); q(-11, -4, 2, 3, '#b8a078');
      q(-5, -4, 3, 4, OUTLINE); q(-5, -4, 2, 3, '#b8a078');
      q(3, -4, 3, 4, OUTLINE); q(3, -4, 2, 3, '#b8a078');
      q(3, -20 + bob, 9, 9, OUTLINE);
      q(4, -19 + bob, 7, 7, '#d8c09a');
      q(3, -24 + bob, 2, 5, '#8a7a5a'); q(4, -25 + bob, 2, 3, '#8a7a5a');
      q(11, -24 + bob, 2, 5, '#8a7a5a'); q(10, -25 + bob, 2, 3, '#8a7a5a');
      q(7, -16 + bob, 2, 2, INK); q(10, -16 + bob, 2, 2, INK);
      q(8, -12 + bob, 3, 1, '#8a6a4a');
      q(8, -10 + bob, 2, 4, '#e8dcc8');
    }
    ctx.restore();
  }
  R.drawAnimal = drawAnimal;

  R.homeItemAt = (x, y) => {
    const G = root.PLGame;
    if (G && G.homePropAt) return G.homePropAt(x, y);
    return null;
  };


  /* ================= weather / time ================= */
  function timeTint(m, indoor) {
    if (m < 7 * 60) return indoor ? 'rgba(40,40,90,.18)' : 'rgba(34,40,92,.36)';
    if (m < 9 * 60) return 'rgba(255,200,120,.08)';
    if (m < 17 * 60) return null;
    if (m < 19 * 60) return 'rgba(255,150,80,.10)';
    if (m < 21 * 60) return indoor ? 'rgba(40,40,90,.12)' : 'rgba(46,44,96,.24)';
    return indoor ? 'rgba(24,26,64,.2)' : 'rgba(20,24,62,.4)';
  }

  function drawWeather(zone, dt) {
    const ctx = R.ctx;
    const S = root.PLGame ? root.PLGame.S : null;
    const m = S ? S.timeMin : 720;
    const tint = timeTint(m, !!zone.indoor);
    if (tint) { ctx.fillStyle = tint; ctx.fillRect(0, 0, W, H); }
    if (zone.indoor) return;

    const weather = S ? S.weather : 'sun';
    if (weather === 'rain' || weather === 'snow') {
      if (!R.weatherParticles.length) {
        for (let i = 0; i < 120; i++) R.weatherParticles.push({ x: Math.random() * W, y: Math.random() * H, s: .5 + Math.random() });
      }
      ctx.fillStyle = weather === 'rain' ? 'rgba(160,200,230,.7)' : '#ffffff';
      R.weatherParticles.forEach((p) => {
        p.y += (weather === 'rain' ? 420 : 60) * p.s * dt;
        p.x += (weather === 'rain' ? -60 : Math.sin(R.t + p.y)) * p.s * dt;
        if (p.y > H) { p.y = -10; p.x = Math.random() * W; }
        if (weather === 'rain') ctx.fillRect(p.x, p.y, 2, 8 * p.s);
        else ctx.fillRect(p.x, p.y, 3 * p.s, 3 * p.s);
      });
      if (weather === 'rain') { ctx.fillStyle = 'rgba(40,60,80,.10)'; ctx.fillRect(0, 0, W, H); }
    }
    if (weather === 'cloud') { ctx.fillStyle = 'rgba(90,100,110,.06)'; ctx.fillRect(0, 0, W, H); }
    // night fireflies
    if (m > 19 * 60 || m < 6 * 60) {
      const theme = zone.theme;
      if (theme === 'park' || theme === 'farm' || theme === 'backyard') {
        for (let i = 0; i < 12; i++) {
          const fx = (hash(i * 7.1) * W + Math.sin(R.t * .7 + i) * 24) % W;
          const fy = 340 + hash(i * 3.9) * 170 + Math.cos(R.t * .9 + i) * 8;
          ctx.globalAlpha = .3 + (Math.sin(R.t * 2 + i) + 1) * .25;
          px(fx, fy, 2, 2, '#e8ff8a');
        }
        ctx.globalAlpha = 1;
      }
    }
  }

  function ageScale(age) {
    if (age < 3) return .56;
    if (age < 6) return .68;
    if (age < 10) return .78;
    if (age < 14) return .88;
    if (age < 18) return .95;
    if (age >= 65) return .94;
    return 1;
  }

  function blinkFor(phase) {
    return ((R.t + phase * .73) % 4.6) < .13;
  }

  function drawNameTag(x, y, text) {
    if (!text) return;
    const ctx = R.ctx;
    ctx.font = `700 11px ${FONT}`;
    ctx.textAlign = 'center';
    const tw = ctx.measureText(text).width;
    px(x - tw / 2 - 6, y - 15, tw + 12, 18, 'rgba(36,24,36,.72)');
    px(x - tw / 2 - 4, y - 13, tw + 8, 14, 'rgba(36,24,36,.7)');
    ctx.fillStyle = '#fff2d0';
    ctx.textBaseline = 'middle';
    ctx.fillText(text, x, y - 6);
    ctx.textBaseline = 'alphabetic';
    ctx.textAlign = 'left';
  }

  /* ================= main draw ================= */
  R.draw = (game, dt, player, npcs, activeProp) => {
    const S = game.S;
    R.t += dt;
    R.activeProp = activeProp || null;
    const ctx = R.ctx;
    const zone = D.ZONES[S.zone] || D.ZONES.home;
    ctx.save();
    ctx.clearRect(0, 0, W, H);
    if (zone.outdoor) drawOutdoor(zone); else drawIndoor(zone);

    // gather characters for depth sorting
    const chars = [];
    (npcs || []).forEach((n) => {
      const def = D.NPCS[n.id] || {};
      chars.push({
        kind: 'npc', y: n.y, x: n.x, n, def,
        opts: {
          skin: def.skin, hair: def.hair, hairStyle: def.style,
          shirt: def.shirt, pants: def.pants, role: D.NPC_ROLE[n.id] || '',
          moving: n.moving, frame: Math.floor(n.walk * 2.2) % 4,
          facing: n.facing, blink: blinkFor(n.phase || 0), scale: 1.55,
        },
      });
    });

    if (S.zone === 'home') {
      if (S.partnerName && S.partnerId) {
        const def = D.NPCS[S.partnerId] || { name: S.partnerName, skin: '#f2c39b', hair: '#3a2418', shirt: '#e88a9a', pants: '#5a3a4a', style: 'long' };
        const px2 = 640 + Math.sin(R.t * .45) * 16;
        chars.push({
          kind: 'partner', y: 486, x: px2, def,
          opts: {
            skin: def.skin, hair: def.hair, hairStyle: def.style,
            shirt: def.shirt, pants: def.pants, role: D.NPC_ROLE[S.partnerId] || '',
            moving: true, frame: Math.floor(R.t * 2.2) % 4,
            facing: 'left', blink: blinkFor(3), scale: 1.55,
          },
        });
      }
      (S.children || []).forEach((c, i) => {
        const cxp = (i === 0 ? 300 : 690) + Math.sin(R.t * .6 + i * 2) * 22;
        const cyp = 480 + Math.cos(R.t * .5 + i) * 8;
        chars.push({
          kind: 'child', y: cyp, x: cxp, c,
          opts: {
            skin: c.skin, hair: c.hairColor, hairStyle: c.hairStyle,
            shirt: i === 0 ? '#7ac0e0' : '#e0a0c0', pants: '#4a5a7a',
            role: '', gender: c.gender,
            moving: true, frame: Math.floor(R.t * 2.6 + i) % 4,
            facing: Math.sin(R.t * .6 + i * 2) > 0 ? 'left' : 'right',
            blink: blinkFor(i * 2 + 1), scale: 1.55 * ageScale(c.age || 0),
          },
        });
      });
    }

    if (player && S.alive) {
      chars.push({
        kind: 'player', y: player.y, x: player.x,
        opts: {
          skin: S.skin, hair: S.hairColor, hairStyle: S.hairStyle,
          outfit: S.outfit, gender: S.gender, accessory: S.accessory,
          moving: player.moving, frame: Math.floor(player.walk * 2.2) % 4,
          facing: player.facing, blink: blinkFor(1.7),
          scale: 1.68 * ageScale(S.age || 6),
        },
      });
      // สัตว์เลี้ยงเดินตามเจ้าของ
      (S.pets || []).slice(0, 3).forEach((pet, i) => {
        const off = [
          { x: -52, y: 6 }, { x: 52, y: 2 }, { x: -26, y: 18 },
        ][i];
        chars.push({
          kind: 'pet', y: player.y + off.y, x: player.x + off.x + Math.sin(R.t * 2 + i * 2.1) * 5,
          pet, idx: i,
        });
      });
    }

    chars.sort((a, b) => a.y - b.y).forEach((ch) => {
      if (ch.kind === 'pet') {
        ctx.save();
        ctx.globalAlpha = .18;
        ctx.fillStyle = '#1a1020';
        ctx.beginPath();
        ctx.ellipse(ch.x, ch.y, 12, 3.4, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
        drawAnimal(ch.pet.id, ch.x, ch.y, 1.15, R.t + ch.idx * 1.7, ch.x > (player ? player.x : ch.x));
      } else {
        R.drawSprite(ctx, ch.x, ch.y, ch.opts);
      }
    });

    // NPC name tags after sprites
    (npcs || []).forEach((n) => {
      const def = D.NPCS[n.id] || {};
      drawNameTag(n.x, n.y - 56, def.name || '');
    });

    drawWeather(zone, dt);

    // soft vignette (light so the palette stays bright)
    const vg = ctx.createRadialGradient(W / 2, H / 2, 300, W / 2, H / 2, 660);
    vg.addColorStop(0, 'rgba(0,0,0,0)'); vg.addColorStop(1, 'rgba(30,16,30,.22)');
    ctx.fillStyle = vg; ctx.fillRect(0, 0, W, H);
    ctx.restore();
  };

  R.drawProp = drawProp;
  R.shade = shade;
  R.mix = mix;
  R.ageScale = ageScale;
  root.PLRender = R;
})(window);
