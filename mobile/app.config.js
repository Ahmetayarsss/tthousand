// app.json'un üstüne derleme numarası: CI'da GITHUB_RUN_NUMBER (build-apk.yml) her derlemede artar,
// Android yeni APK'yı "güncelleme" sayar (öncekinin üstüne kurulur, veri kalır). Sürüm kodu hiç küçülmemeli
// (küçülürse telefondaki uygulamanın üstüne kurulmaz): telefondaki 1000'in altında, sayaç 1000'den sayar.
module.exports = ({ config }) => {
  const n = 1000 + (parseInt(process.env.GITHUB_RUN_NUMBER || "1", 10) || 1);
  return {
    ...config,
    version: "2." + n,
    android: { ...config.android, versionCode: n },
    ios: { ...config.ios, buildNumber: String(n) },
  };
};
