# Arabic TTS Spike — Result & Decision

**Status:** needs-device-verification  
**Task:** Task 3 of Wonder Quest v1 plan  
**Spike screen:** `app/lib/features/spike/tts_spike_screen.dart`  
**Decision consumer:** Task 33 (Hoorof — Arabic Letters module)

---

## Test procedure

1. Build and run Wonder Quest on a **real iPad** in **landscape** orientation.
2. From the placeholder home screen, tap **"Arabic TTS Spike (Task 3)"**.
3. Enable **airplane mode** on the iPad (Settings → Airplane Mode ON).
4. Work through the checklist on the spike screen:

| Step | Action | What to note |
|------|--------|--------------|
| ① | Tap **"List ar-* Voices"** | Which `ar-*` voices appear in the log? Are any listed without network access? |
| ② | Tap **"Speak ب (Baa — letter)"** | Latency (ms feel?), pronunciation accuracy, child-appropriateness of voice |
| ③ | Tap **"Speak بَطَّة (Batta — Duck)"** | Diacritics honored? Natural prosody? |
| ④ | Tap **"Speak English Fallback"** | Confirm fallback path ("Letter Baa. Duck!") works offline |
| ⑤ | Re-enable WiFi; repeat ① | Any additional voices appear online? |

---

## Results

> **PENDING HUMAN VERIFICATION** — no iPad was attached to the dev machine
> during Task 3 implementation. Fill in this section after running the spike
> screen on a physical device in airplane mode.

### Offline ar-* voices found

```
[ fill in from "List ar-* Voices" log output ]
```

### Quality assessment

| Sample | Voice used | Pronunciation | Latency | Child-appropriate? |
|--------|-----------|---------------|---------|-------------------|
| ب (Baa — letter) | | | | |
| بَطَّة (Batta — Duck) | | | | |
| English fallback | en-US | — | — | ✅ |

### Notes

```
[ subjective observations, e.g. "voice sounds robotic", "diacritics ignored",
  "correct letter name", "good enough for prototype" ]
```

---

## Decision

> **PENDING HUMAN VERIFICATION** — complete after device test above.

Choose one:

- [ ] **A — TTS is good enough for Hoorof v1.**  
  _Proceed with `speakArabic()` via flutter_tts in Task 33. No bundled audio needed._

- [ ] **B — TTS quality is insufficient; bundle recorded audio.**  
  _Source: [ family recordings / CC0 clips / other — specify ]_  
  _Record chosen source and asset format here. Task 33 to implement audio asset map._

---

## Context for the decision

From `wiki/modules/hoorof.md`:
> Production needs **recorded native-speaker letter audio** (TTS quality/availability varies on device).

From `wiki/systems/audio-speech.md`:
> iOS has `AVSpeechSynthesizer` (Flutter: flutter_tts) — quality varies; prefer bundled recorded clips for core phonics.

The prototype used TTS as a placeholder. The spike confirms whether TTS is acceptable for v1 or whether Task 33 must include a bundled asset layer from the start.

---

*To close this doc: fill in Results + Decision above, change Status to `prototype-validated`, and append a line to `wiki/log.md`.*
