import pathlib, sys
K = pathlib.Path(sys.argv[1])
def r(f, a, b):
    p = K / f; s = p.read_text()
    assert s.count(a) == 1, (f, a); p.write_text(s.replace(a, b))
c = "src/kartlar/Cevirme.js"
r(c, 'import { Easing, useDerivedValue, useSharedValue, withTiming } from "react-native-reanimated";',
  'import { Easing, useDerivedValue, useFrameCallback, useSharedValue, withTiming } from "react-native-reanimated";')
r(c, "const KIRP = 64;\n", 'const KIRP = 64;\nfunction olcYaz(m) { console.log("OLCUM " + m); }\n')
r(c, "  const surum = useRef(0);", """  const olcSon = useSharedValue(0), olcAktif = useSharedValue(0), olcN = useSharedValue(0), olcUzun = useSharedValue(0), olcBuyuk = useSharedValue(0);
  useFrameCallback((f) => {
    "worklet";
    const t = f.timestamp, d = olcSon.value ? t - olcSon.value : 0;
    olcSon.value = t;
    if (olcAktif.value) { olcN.value += 1; if (d > olcUzun.value) olcUzun.value = d; if (d > 34) olcBuyuk.value += 1; }
    else if (d > 50) scheduleOnRN(olcYaz, "BOSTA " + Math.round(d));
  });
  const surum = useRef(0);""")
r(c, """    p.value = withTiming(1, { duration: T, easing: Easing.linear }, (tamam) => { "worklet"; if (tamam) scheduleOnRN(son); });""",
  """    olcAktif.value = 1; olcN.value = 0; olcUzun.value = 0; olcBuyuk.value = 0;
    olcYaz("BASLA " + (Date.now() - (globalThis.__dokunma || 0)));
    p.value = withTiming(1, { duration: T, easing: Easing.linear }, (tamam) => {
      "worklet";
      olcAktif.value = 0;
      scheduleOnRN(olcYaz, "CEVIR " + olcN.value + " " + Math.round(olcUzun.value) + " " + olcBuyuk.value);
      if (tamam) scheduleOnRN(son);
    });""")
r("src/app/kartlar.js", "  function ac(rx) {\n", "  function ac(rx) {\n    globalThis.__dokunma = Date.now();\n")
print("yamandı")
