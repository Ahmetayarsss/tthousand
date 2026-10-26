#!/usr/bin/env bash
set -u
PAKET=io.github.ahmetayarsss.thousand
APK="$1"; CIKTI="$2"; mkdir -p "$CIKTI"
ekran() { adb shell uiautomator dump /sdcard/ui.xml > /dev/null 2>&1; adb exec-out cat /sdcard/ui.xml; }
yer() {
  ekran | python3 -c '
import re, sys, html
x = sys.stdin.read(); aranan = sys.argv[1]
for n in re.finditer(r"<node ([^>]*)>", x):
    oz = dict((k, html.unescape(v)) for k, v in re.findall(r"([\w-]+)=\"([^\"]*)\"", n.group(1)))
    if aranan in (oz.get("text"), oz.get("content-desc")):
        a, b, c, d = map(int, re.findall(r"\d+", oz["bounds"])); print((a + c) // 2, (b + d) // 2); break
' "$1"
}
var() { [ -n "$(yer "$1")" ]; }
bekle() { for _ in $(seq 1 "${2:-10}"); do var "$1" && return 0; sleep 1; done; return 1; }
dokun() { local p; p=$(yer "$1"); [ -n "$p" ] && adb shell input tap $p; }
read -r W H < <(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1 | tr x ' ')
sola() { adb shell input swipe $((W * 85 / 100)) $((H / 2)) $((W * 20 / 100)) $((H / 2 + 10)) 250; sleep 1.5; }
saga() { adb shell input swipe $((W * 15 / 100)) $((H / 2)) $((W * 80 / 100)) $((H / 2 + 10)) 250; sleep 1.5; }
asagi() { adb shell input swipe $((W / 2)) $((H * 30 / 100)) $((W / 2)) $((H * 60 / 100)) 250; sleep 1.5; }
yukari() { adb shell input swipe $((W / 2)) $((H * 65 / 100)) $((W / 2)) $((H * 35 / 100)) 250; sleep 1.5; }
metinler() { echo "--- $1:"; ekran | python3 -c '
import re, sys, html
x = sys.stdin.read()
print(" | ".join(html.unescape(t) for t in re.findall(r" text=\"([^\"]+)\"", x))[:600])'; }
firlat() { for _ in 1 2 3; do adb shell input swipe $((W / 2)) $((H * 80 / 100)) $((W / 2)) $((H * 20 / 100)) 120; sleep 0.3; done; sleep 2.5; }

for a in window_animation_scale transition_animation_scale animator_duration_scale; do adb shell settings put global $a 1; done
adb install -r "$APK" || exit 1
adb logcat -c
adb shell monkey -p "$PAKET" -c android.intent.category.LAUNCHER 1 > /dev/null
sleep 8
bekle "Sonra" 15 && dokun "Sonra"
bekle "Anladım" 12 && dokun "Anladım"
sleep 1
sola; bekle "Aç" 10 || echo "Kartlar açılmadı"
sleep 2
adb shell dumpsys gfxinfo "$PAKET" reset > /dev/null
for i in $(seq 1 ${CEVIRME:-12}); do
  dokun "Aç"; sleep 1.6
  dokun "Biliyorum"; sleep 1.6
done
adb shell dumpsys gfxinfo "$PAKET" > "$CIKTI/gfxinfo.txt"
adb exec-out screencap -p > "$CIKTI/kartlar.png"

metinler kartlar; saga; metinler "saga1"; saga; metinler "saga2"; asagi; metinler "asagi"
adb exec-out screencap -p > "$CIKTI/ayarlar.png"
BASARI=0; ALTTA=0
asagi_firlat() { for _ in 1 2 3; do adb shell input swipe $((W / 2)) $((H * 25 / 100)) $((W / 2)) $((H * 85 / 100)) 120; sleep 0.4; done; sleep 2; }
for i in 1 2 3 4 5 6 7 8; do
  var "Sonra" && { dokun "Sonra"; sleep 1; }
  if ! var "GİZLİLİK"; then var "Sözlük" || asagi; asagi; fi
  asagi_firlat
  adb shell input swipe $((W / 2)) $((H * 90 / 100)) $((W / 2)) $((H * 8 / 100)) 80; sleep 3
  if var "Telefon ayarları" || var "Bildirim izni kapalı"; then ALTTA=$((ALTTA + 1)); A=1; else A=0; fi
  yukari
  if bekle "Sözlükte ara (İngilizce ya da Türkçe)" 3; then BASARI=$((BASARI + 1)); S=1; asagi; else S=0; fi
  echo "tur $i: en altta=$A sozluk=$S"
done
echo "AYARLAR_SOZLUK $BASARI/8 (en alta inilen tur: $ALTTA)" | tee "$CIKTI/ayarlar.txt"
adb logcat -d > "$CIKTI/logcat.txt"
grep -o "OLCUM .*" "$CIKTI/logcat.txt" > "$CIKTI/olcum.txt"
python3 - "$CIKTI" <<'PY'
import sys, re, statistics as st, pathlib
K = pathlib.Path(sys.argv[1]); L = (K / "olcum.txt").read_text().splitlines()
basla = [int(x.split()[2]) for x in L if x.startswith("OLCUM BASLA")]
cevir = [list(map(int, x.split()[2:5])) for x in L if x.startswith("OLCUM CEVIR")]
bosta = [int(x.split()[2]) for x in L if x.startswith("OLCUM BOSTA")]
g = (K / "gfxinfo.txt").read_text()
al = lambda k: (re.search(k + r"[^\n]*", g) or [""])[0]
out = [
  f"dokunuş→başlama ms: medyan {st.median(basla) if basla else '-'}, en çok {max(basla) if basla else '-'} ({len(basla)} çevirme)",
  f"çevirme başına kare: ort {st.mean(c[0] for c in cevir):.1f}" if cevir else "çevirme yok",
  f"çevirmede en uzun kare aralığı ms: medyan {st.median(c[1] for c in cevir)}, en çok {max(c[1] for c in cevir)}" if cevir else "",
  f"çevirmede >34 ms kare toplam: {sum(c[2] for c in cevir)}" if cevir else "",
  f"boşta >50 ms takılma: {len(bosta)} kez, en uzun {max(bosta) if bosta else 0} ms, toplam {sum(bosta)} ms",
  al("Total frames rendered"), al("Janky frames"), al("50th percentile"), al("90th percentile"), al("99th percentile"), al("Number Slow UI thread"),
  (K / "ayarlar.txt").read_text().strip(),
]
print("\n".join(out)); (K / "ozet.txt").write_text("\n".join(out) + "\n")
PY
