/* ============================================================
   HOOROF (حروف) — Arabic Letter Adventure — data
   ============================================================ */

// Each letter: g glyph, nm Arabic name, tr translit name, snd sound,
// w example word (Arabic), wtr word translit, e emoji, base dotless form, dots
const HRF = [
  { g:'ا', nm:'أَلِف', tr:'Alif', snd:'a',   w:'أَرْنَب', wtr:'arnab (rabbit)',   e:'🐰' },
  { g:'ب', nm:'بَاء',  tr:'Baa',  snd:'b',   w:'بَطَّة',  wtr:'batta (duck)',      e:'🦆', base:'ٮ', dots:'1b' },
  { g:'ت', nm:'تَاء',  tr:'Taa',  snd:'t',   w:'تُفَّاحَة',wtr:'tuffaha (apple)',  e:'🍎', base:'ٮ', dots:'2a' },
  { g:'ث', nm:'ثَاء',  tr:'Thaa', snd:'th',  w:'ثَعْلَب', wtr:"tha'lab (fox)",     e:'🦊', base:'ٮ', dots:'3a' },
  { g:'ج', nm:'جِيم',  tr:'Jeem', snd:'j',   w:'جَمَل',   wtr:'jamal (camel)',     e:'🐪', base:'ح', dots:'1b' },
  { g:'ح', nm:'حَاء',  tr:'Haa',  snd:'H',   w:'حُوت',    wtr:'hoot (whale)',      e:'🐋' },
  { g:'خ', nm:'خَاء',  tr:'Khaa', snd:'kh',  w:'خَرُوف',  wtr:'kharoof (sheep)',   e:'🐑', base:'ح', dots:'1a' },
  { g:'د', nm:'دَال',  tr:'Daal', snd:'d',   w:'دُبّ',    wtr:'dubb (bear)',       e:'🐻' },
  { g:'ذ', nm:'ذَال',  tr:'Dhaal',snd:'dh',  w:'ذِئْب',   wtr:"dhi'b (wolf)",      e:'🐺', base:'د', dots:'1a' },
  { g:'ر', nm:'رَاء',  tr:'Raa',  snd:'r',   w:'رِيشَة',  wtr:'reesha (feather)',  e:'🪶' },
  { g:'ز', nm:'زَاي',  tr:'Zaay', snd:'z',   w:'زَرَافَة',wtr:'zaraafa (giraffe)', e:'🦒', base:'ر', dots:'1a' },
  { g:'س', nm:'سِين',  tr:'Seen', snd:'s',   w:'سَمَكَة', wtr:'samaka (fish)',     e:'🐟' },
  { g:'ش', nm:'شِين',  tr:'Sheen',snd:'sh',  w:'شَمْس',   wtr:'shams (sun)',       e:'☀️', base:'س', dots:'3a' },
  { g:'ص', nm:'صَاد',  tr:'Saad', snd:'S',   w:'صَقْر',   wtr:'saqr (falcon)',     e:'🦅' },
  { g:'ض', nm:'ضَاد',  tr:'Daad', snd:'D',   w:'ضِفْدَع', wtr:"dofda' (frog)",     e:'🐸', base:'ص', dots:'1a' },
  { g:'ط', nm:'طَاء',  tr:'Taa',  snd:'T',   w:'طَائِر',  wtr:"taa'ir (bird)",     e:'🐦' },
  { g:'ظ', nm:'ظَاء',  tr:'Zaa',  snd:'Z',   w:'ظَبْي',   wtr:'dhabi (gazelle)',   e:'🦌', base:'ط', dots:'1a' },
  { g:'ع', nm:'عَيْن',  tr:'Ayn',  snd:'a3',  w:'عِنَب',   wtr:"'inab (grapes)",    e:'🍇' },
  { g:'غ', nm:'غَيْن',  tr:'Ghayn',snd:'gh',  w:'غُرَاب',  wtr:'ghuraab (crow)',    e:'🐦‍⬛', base:'ع', dots:'1a' },
  { g:'ف', nm:'فَاء',  tr:'Faa',  snd:'f',   w:'فِيل',    wtr:'feel (elephant)',   e:'🐘', base:'ڡ', dots:'1a' },
  { g:'ق', nm:'قَاف',  tr:'Qaaf', snd:'q',   w:'قِطَّة',  wtr:'qitta (cat)',       e:'🐱', base:'ٯ', dots:'2a' },
  { g:'ك', nm:'كَاف',  tr:'Kaaf', snd:'k',   w:'كَلْب',   wtr:'kalb (dog)',        e:'🐶' },
  { g:'ل', nm:'لَام',  tr:'Laam', snd:'l',   w:'لَيْمُون', wtr:'laymoon (lemon)',   e:'🍋' },
  { g:'م', nm:'مِيم',  tr:'Meem', snd:'m',   w:'مَوْز',   wtr:'mawz (banana)',     e:'🍌' },
  { g:'ن', nm:'نُون',  tr:'Noon', snd:'n',   w:'نَحْلَة',  wtr:'nahla (bee)',       e:'🐝', base:'ٮ', dots:'1a' },
  { g:'ه', nm:'هَاء',  tr:'Haa',  snd:'h',   w:'هِلَال',  wtr:'hilaal (crescent)', e:'🌙' },
  { g:'و', nm:'وَاو',  tr:'Waw',  snd:'w',   w:'وَرْدَة',  wtr:'warda (flower)',    e:'🌹' },
  { g:'ي', nm:'يَاء',  tr:'Yaa',  snd:'y',   w:'يَد',     wtr:'yad (hand)',        e:'✋', base:'ى', dots:'2b' },
];

// learning clusters (3–4 letters each)
const HRF_CLUSTERS = [
  { id:0, letters:['ا','ب','ت'] },
  { id:1, letters:['ث','ج','ح'] },
  { id:2, letters:['خ','د','ذ'] },
  { id:3, letters:['ر','ز','س'] },
  { id:4, letters:['ش','ص','ض'] },
  { id:5, letters:['ط','ظ','ع'] },
  { id:6, letters:['غ','ف','ق'] },
  { id:7, letters:['ك','ل','م'] },
  { id:8, letters:['ن','ه','و','ي'] },
];

const HRF_BY_G = {};
HRF.forEach(h => HRF_BY_G[h.g] = h);

// confusable families (for Hear&Match / Shape Builder distractors)
const HRF_FAMILIES = [
  ['ب','ت','ث','ن','ي'], ['ج','ح','خ'], ['د','ذ'], ['ر','ز'],
  ['س','ش'], ['ص','ض'], ['ط','ظ'], ['ع','غ'], ['ف','ق'],
];
function hrfFamily(g) {
  const fam = HRF_FAMILIES.find(f => f.includes(g));
  return fam ? fam.filter(x => x !== g) : HRF.map(h => h.g).filter(x => x !== g);
}

// ---- Arabic speech ----
function pickArabicVoice() {
  try {
    const vs = window.speechSynthesis.getVoices();
    return vs.find(v => /ar(-|_)/i.test(v.lang)) || vs.find(v => /arabic/i.test(v.name)) || null;
  } catch (e) { return null; }
}
// speak Arabic text; fall back to English translit if no Arabic voice
function speakArabic(arabic, fallback) {
  if (!window.__soundOn) return;
  try {
    const synth = window.speechSynthesis; if (!synth) return;
    synth.cancel();
    const v = pickArabicVoice();
    const u = new SpeechSynthesisUtterance(arabic);
    u.lang = 'ar-SA'; u.rate = 0.8; u.pitch = 1.05;
    if (v) u.voice = v;
    // if no arabic voice and we have a fallback, speak the english name instead
    if (!v && fallback) { const f = new SpeechSynthesisUtterance(fallback); f.rate = 0.85; f.pitch = 1.1; synth.speak(f); return; }
    synth.speak(u);
  } catch (e) {}
}
// say a letter: its name (+ optional "... word")
function sayLetter(h, withWord) {
  const txt = withWord ? `${h.nm}. ${h.w}` : h.nm;
  const fb = withWord ? `${h.tr}. ${h.wtr.split(' ')[0]}` : h.tr;
  speakArabic(txt, fb);
}
// warm up voices list
try { window.speechSynthesis && window.speechSynthesis.getVoices(); window.speechSynthesis.onvoiceschanged = () => {}; } catch (e) {}

Object.assign(window, { HRF, HRF_CLUSTERS, HRF_BY_G, HRF_FAMILIES, hrfFamily, speakArabic, sayLetter, pickArabicVoice });
