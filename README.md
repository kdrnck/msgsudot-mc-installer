# MSGSU-DOT SMP Windows Kurulum Scripti

Bu proje, tek bir PowerShell scriptiyle Java 21 (Temurin), PolyMC ve MSGSU-DOT SMP PolyMC instance importunu otomatik yapar. Kullanıcıya yalnızca PolyMC içinde hesap eklemek kalır.

## Kullanım
- Windows'ta `Install-MsgsuSmp.ps1` dosyasına sağ tık → **Run with PowerShell**.
- Script Java ve PolyMC'yi kontrol eder, gerekirse winget ile kurar ve instance'ı PolyMC'ye import eder.
- PolyMC açıldığında:
  1) Accounts/Hesaplar bölümüne git.
  2) "Add Microsoft" ile normal giriş yap veya mümkünse "Add offline account" ile nick ekle.
  3) Sol menüde import edilen `MSGSU-DOT SMP` instance'ını seçip PLAY de.

## Geliştirici Notu (LLM ile çalışma)
- Patch tarzı istekler verebilirsin, örn:  
  - `Install-MsgsuSmp.ps1 içindeki Ensure-PolyMc fonksiyonuna X davranışını ekle`
- Yapı:
  - `config.json`: ayarlar
  - `banner.txt`: ASCII banner
  - `Install-MsgsuSmp.ps1`: ana script

