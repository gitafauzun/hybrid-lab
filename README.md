📝Ne Yapar?
Tarar: Belirlediğin ağ bloğundaki tüm IP'leri yoklar.
Analiz Eder: Kim kimdir (Sunucu mu, Router mı, PC mi?) port üzerinden tespit eder.
Belgeler: Hem terminale renkli çıktı verir hem de yöneticiye sunulacak kalitede HTML Dashboard ve Markdown raporu üretir.
🛡️ 1. Akıllı Rol Tespiti 
Sadece cihazın açık olup olmadığını kontrol etmiyor, açık olan portlara göre o cihazın "kimliğini" belirliyor:
Port 53: DNS trafiğini yakalayıp "🔍 Domain Controller" etiketini yapıştırıyor.
Port 445: SMB trafiğinden "📁 File Server" olduğunu anlıyor.
Port 3389/22: Windows (RDP) veya Linux (SSH) yönetim portlarını ayırıyor.
Gateway: .1 ile biten IP'yi otomatik olarak "🛡️ Router" olarak işaretliyor.
💻 2. Donanım ve DNS Denetimi
Kod, cihazların sadece IP'sini değil, "fiziksel" izlerini de sürüyor:
MAC OUI Analizi: nmap üzerinden cihazın ağ kartı üreticisini çekiyor (VMware, Dell, Cisco vb.). Bu, ağdaki yabancı cihazları bulmak için kritiktir.
Reverse DNS (dig): IP adresinden hostname çözümlüyor (dig -x), böylece ağdaki isimlendirme standartlarını kontrol ediyor.
📊 3. Profesyonel HTML Dashboard
Raporlama kısmı, sıradan bir metin dosyasının çok ötesinde. cat <<EOF bloğu ile oluşturulan HTML raporu:
GitHub Dark Theme: Modern, koyu modda ve göz yormayan bir tasarım sunuyor.
İstatistik Kartları: Aktif/Pasif node sayılarını ve taranan subneti en üstte özetliyor.
Dinamik Renklendirme: sed komutlarıyla ONLINE olanları yeşil, OFFLINE olanları kırmızı yaparak görsel bir hiyerarşi sağlıyor.
⚙️ 4. Güvenli ve Temiz Çalışma Mantığı
Trap & Cleanup: Script hata alsa veya aniden kapansa bile /tmp klasöründeki geçici dosyaları temizliyor (trap cleanup EXIT).
Sudo User Handling: Script sudo ile çalışsa bile oluşturulan raporların sahipliğini asıl kullanıcıya (REAL_USER) geri veriyor. Bu sayede rapor dosyalarında "kilit" ikonu görmüyorsun.
