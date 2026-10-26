/*
 * Kart çevirme katmanı (Skia): kartın iki yüzü resim olarak
 * yakalanır (yuzYakala), 64 sütunlu bir ağa doku olarak kaplanır, ağ her karede cevirmeGeometri'deki hesapla
 * (three.js ile birebir; tests/cevirme.test.js) eğilir ve döner. 90°'yi geçince arka yüz görünür.
 * Katman bütün ekranın üstünde çizer ama kartın 64 px çevresiyle kırpılır;
 * dokunuşları geçirir. ref.iptal(): süren çevirmeyi bırakır, bitti çağrılmaz (ör. sekme değişip yeni Test başlayınca).
 *
 * ref.hazirla(onRef, arkaRef) → { on, arka } ya da null: yüzler önceden yakalanır.
 * ref.oynat({ onRef, arkaRef, hazir, kart: {x, y, w, h}, s, yakalandi, ilkKare, bitti }):
 *   onRef/arkaRef: yakalanacak yüzler (çevresinde PAY kadar saydam pay; hazir verildiyse yakalanmaz), kart: katmandaki yeri,
 *   s: -1 sol kenar menteşe (sağa basıldı), 1 sağ kenar. yakalandi(): yüzler alındı (yakalama kopyaları kaldırılabilir),
 *   ilkKare(): katman ilk kez çizdi (asıl kart gizlenebilir).
 *   bitti(ok): ok=false → yakalanamadı (cevap hemen gösterilir).
 */
import { Canvas, FilterMode, Group, ImageShader, MipmapMode, rect, Vertices } from "@shopify/react-native-skia";
import { forwardRef, useEffect, useImperativeHandle, useRef, useState } from "react";
import { StyleSheet } from "react-native";
import { Easing, useDerivedValue, useSharedValue, withTiming } from "react-native-reanimated";
import { scheduleOnRN } from "react-native-worklets";
import { cevirmeKaresi, dokuNoktalari, NY, PAY, T } from "./cevirmeGeometri";
import { yuzYakala } from "./yuzYakala";

const ORNEKLEME = { filter: FilterMode.Linear, mipmap: MipmapMode.Linear };   // kıvrılan kenarda doku net kalsın
const KIRP = 64;

export default forwardRef(function Cevirme(_, ref) {
  const [is, setIs] = useState(null);
  const g = useSharedValue(null), p = useSharedValue(0);
  const surum = useRef(0);   // iptal edilen çevirmenin geç gelen adımları yok sayılır

  useImperativeHandle(ref, () => ({
    async hazirla(onRef, arkaRef) {
      try { const [on, arka] = await Promise.all([yuzYakala(onRef), yuzYakala(arkaRef)]); return on && arka ? { on, arka } : null; }
      catch (e) { return null; }
    },
    async oynat({ onRef, arkaRef, hazir, kart, s, yakalandi, ilkKare, bitti }) {
      const benim = ++surum.current;
      let on = null, arka = null;
      if (hazir) ({ on, arka } = hazir);
      else {
        try { [on, arka] = await Promise.all([yuzYakala(onRef), yuzYakala(arkaRef)]); }
        catch (e) { on = null; }
      }
      if (benim !== surum.current) return;
      yakalandi();
      if (!on || !arka) { bitti(false); return; }
      const G = { W: kart.w, H: kart.h, M: PAY, NY, s, ox: kart.x, oy: kart.y };
      p.value = 0; g.value = G;
      setIs({
        on, arka, ilkKare, bitti, ilk: cevirmeKaresi(G, 0), surum: benim,
        klip: rect(kart.x - KIRP, kart.y - KIRP, kart.w + 2 * KIRP, kart.h + 2 * KIRP),
        dokuOn: dokuNoktalari(NY, on.width(), on.height(), false),
        dokuArka: dokuNoktalari(NY, arka.width(), arka.height(), true),
      });
    },
    iptal() { surum.current++; setIs(null); },
  }), [g, p]);

  useEffect(() => {
    if (!is) return undefined;
    const r = requestAnimationFrame(() => is.ilkKare());
    const son = () => { if (is.surum !== surum.current) return; setIs(null); is.bitti(true); };
    p.value = withTiming(1, { duration: T, easing: Easing.linear }, (tamam) => { "worklet"; if (tamam) scheduleOnRN(son); });
    return () => cancelAnimationFrame(r);
  }, [is, p]);

  const ilk = is ? is.ilk : null;
  const kare = useDerivedValue(() => (g.value ? cevirmeKaresi(g.value, p.value) : ilk), [ilk]);
  const noktalar = useDerivedValue(() => (kare.value ? kare.value.noktalar : []));
  const sira = useDerivedValue(() => (kare.value ? kare.value.sira : []));
  const arkaMi = useDerivedValue(() => !!(kare.value && kare.value.arka));
  const dokuOn = is ? is.dokuOn : null, dokuArka = is ? is.dokuArka : null, resimOn = is ? is.on : null, resimArka = is ? is.arka : null;
  const doku = useDerivedValue(() => (arkaMi.value ? dokuArka : dokuOn), [dokuOn, dokuArka]);
  const resim = useDerivedValue(() => (arkaMi.value ? resimArka : resimOn), [resimOn, resimArka]);

  if (!is) return null;
  return (
    <Canvas style={StyleSheet.absoluteFill} pointerEvents="none">
      <Group clip={is.klip}>
        <Vertices vertices={noktalar} textures={doku} indices={sira} mode="triangles">
          <ImageShader image={resim} sampling={ORNEKLEME} />
        </Vertices>
      </Group>
    </Canvas>
  );
});
