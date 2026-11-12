# 🎓 EduPulse — Kapsamlı Proje Sunum Kılavuzu & Konuşmacı Notları

Bu rehber, **EduPulse (Akıllı Kampüs ve Akademik Yönetim Sistemi)** projenizin jüriye, akademisyenlere veya Demo Day izleyicilerine sunulurken en etkili, kendinden emin ve profesyonel şekilde aktarılması için hazırlanmıştır.

Sunum süresince hangi ekranda ne söyleyeceğiniz, hangi teknik terimleri vurgulayacağınız, canlı demoda hangi adımları izleyeceğiniz ve gelebilecek zor sorulara vereceğiniz yanıtlar adım adım modellenmiştir.

---

## ⏱️ Sunum Zaman Planı (Örnek: 12-15 Dakika)

- **Giriş ve Problem Tanımı (2 Dk):** Neden EduPulse? Mevcut sistemlerin eksikleri.
- **Ekip ve Rol Dağılımı (1.5 Dk):** 6 kişilik ekibin Clean Architecture uyumu.
- **Mimari ve Teknoloji Yığını (2.5 Dk):** Clean Architecture, BLoC/Cubit, Firebase & Donanım Entegrasyonu.
- **5 Altın İş Kuralı (3 Dk):** Şartnamenin omurgasını oluşturan Kural 1-5.
- **Canlı Demo (Live Demo) (4 Dk):** Öğretmen ve Öğrenci rolleriyle canlı senaryo.
- **Test ve Kalite Güvencesi (1 Dk):** 472/472 Test başarısı ve sıfır taşma (overflow-free UI).
- **Soru & Cevap (Q&A):** Savunma ve kapanış.

---

## 📑 BÖLÜM BÖLÜM SUNUM AKIŞI VE KONUŞMACI REHBERİ

---

### 1. BÖLÜM: Açılış, Vizyon ve Çıkış Noktası

#### 🖥️ Ekranda Ne Olmalı?
- Proje Logosu, Başlık: **"EduPulse — Geleceğin Akıllı Akademik ve Kampüs Ekosistemi"**
- Ekip üyelerinin isimleri: *Merve Kedersiz, Ayberk Erdem, Meltem Jülide Taşkıran, Fahri Faruk Sonat, Ahmet Eroğlu, Alaaddin Odabaşı*.

#### 🗣️ Ne Konuşacaksınız? (Birebir İfade Önerisi)
> *"Sayın hocalarım ve değerli konuklar, bugün sizlere sadece bir mobil uygulama değil; üniversite kampüslerindeki iletişimsizliği, kağıt israfını, yoklama sahtekarlıklarını ve ödev teslim karmaşasını kökten çözen **EduPulse** ekosistemini sunmaktan büyük heyecan duyuyoruz.*
>
> *Geleneksel üniversite otomasyon sistemlerine baktığımızda; mobille uyumsuz arayüzler, öğrencilerin son anda öğrendiği devamsızlık kalma riskleri, arka sıralardan birbirinin yerine imza atılan yoklama kağıtları ve geciken ödevlerde yaşanan adaletsizlikler en büyük problemlerdir.*
>
> *EduPulse; gerçek zamanlı (real-time) Firebase altyapısı, 60 saniyede bir kendini imha eden dinamik QR kalkanı, otomatik ceza hesaplayan ödev motoru ve mimari olarak 472 otomatik testle korunan kurumsal seviyede bir Flutter çözümüdür."*

---

### 2. BÖLÜM: Ekip Organizasyonu ve 6 Rolün Senfonisi

#### 🖥️ Ekranda Ne Olmalı?
- 6 Rolün yer aldığı organizasyon şeması (Clean Architecture katmanlarıyla eşleştirilmiş tablo).

#### 🗣️ Ne Konuşacaksınız?
> *"Projemizi geliştirirken 'herkes her şeyi yapar' mantığından uzak durduk. Kurumsal yazılım şirketlerinin benimsediği katmanlı görev dağılımı şartnamesini harfiyen uyguladık:*
>
> 1. **Geliştirici 1 (Team Lead & Core Arch):** Bağımlılık enjeksiyonu (`get_it`), yönlendirme (`go_router`), hata/istisna sınıfları ve projenin omurgasını kurdu.
> 2. **Geliştirici 2 (UI/UX & Design Lead):** Material 3 tasarım dilini, Dark/Light temayı, CustomPainter ile matematiksel Çan Eğrisi grafiğini ve tüm atomik widget bileşenlerini tasarladı.
> 3. **Geliştirici 3 (Network & Firebase Lead):** Cloud Firestore, Storage, Firebase Auth, mikrofon ses kayıt servisi, dosya seçiciler ve arka uç güvenlik kurallarını (`firestore.rules`) yazdı.
> 4. **Geliştirici 4 (Data Models & DTO Lead):** Clean Architecture prensiplerine sadık kalarak Entity ve DTO modellerini ayrıştırdı; `fromFirestore`/`toJson` veri dönüşümlerini tip güvenli hale getirdi.
> 5. **Geliştirici 5 (State & Logic Lead):** Use Case'leri, BLoC/Cubit durum makinelerini, 60 saniyelik reaktif zamanlayıcıları ve Firestore canlı dinleme akışlarını (Streams) geliştirdi.
> 6. **Geliştirici 6 (Feature Screens & QA Lead):** 13 ana ekran sayfasını, form doğrulayıcılarını (`validators.dart`) yazdı ve projedeki 472 otomatik testin tamamını yeşilde tutarak kaliteyi garanti altına aldı.*
>
> *Bu sayede hiçbir arkadaşımız bir diğerinin kodunu ezmeden, çakışma (merge conflict) yaşamadan modüler bir şekilde çalıştı."*

---

### 3. BÖLÜM: Mimari Tasarım — Clean Architecture & Feature-First

#### 🖥️ Ekranda Ne Olmalı?
- Presentation -> Domain -> Data -> Core katmanlarını gösteren Clean Architecture diyagramı.

#### 🗣️ Ne Konuşacaksınız?
> *"EduPulse'un kod tabanına baktığınızda klasik 'spagetti Flutter' projelerinden çok farklı bir disiplin görürsünüz:*
>
> * **Domain Katmanı:** Saf Dart ile yazılmıştır. Hiçbir Flutter veya Firebase bağımlılığı barındırmaz. İş kurallarımız dış dünyadan tamamen izoledir.
> * **Data Katmanı:** Firebase Firestore veya REST servisleri değişse bile Domain katmanı bundan etkilenmez; Repository Pattern ile gevşek bağlıdır (loosely coupled).
> * **Presentation Katmanı:** Reaktif BLoC/Cubit mimarisiyle çalışır. Sayfalarımız (Pages) sadece UI'ı render eder; tüm mantık Cubit ve Use Case'lerdedir.
> * **Dependency Injection:** `get_it` Service Locator ile tüm katmanlar merkezi bir noktadan ayağa kaldırılır. Bu sayede her bir sınıf %100 mock'lanabilir ve test edilebilir durumdadır."*

---

### 4. BÖLÜM: Projenin 5 Altın İş Kuralı (The 5 Golden Business Rules)

> 💡 **SUNUMUN EN ÖNEMLİ KISMI:** Jüri üyeleri bu kuralları şartnamede gördü; bunların kodda nasıl hayata geçtiğini duymak isterler!

#### 🗣️ Ne Konuşacaksınız?

#### 1️⃣ Kural 1: 60 Saniye Dinamik Yoklama Kalkanı
> *"Üniversitelerde arka sıradan imza atma veya QR kodun ekran görüntüsünü alıp WhatsApp grubundan sınıfta olmayan arkadaşına atma dönemi EduPulse ile kapandı!*
>
> *Öğretmen tahtada yoklamayı başlattığında bir sayaç 60'tan geriye sayar. QR kod ve yanındaki 6 haneli PIN kodu her 60 saniyede bir kriptografik olarak yeniden üretilir. Ekran görüntüsü alan bir öğrenci bunu arkadaşına atana kadar kodun süresi dolar. Firestore Security Rules ve Data Source seviyesinde milisaniyelik zaman damgası kontrolü yapılır; süresi geçmiş kodlar anında reddedilir."*

#### 2️⃣ Kural 2: Ödev Zaman Kalkanı ve -10 Puan Ceza Mekanizması
> *"Öğrenci dostu ama disiplinli bir sistem kurduk. Geleneksel sistemler süre bittiğinde yükleme butonunu kapatır ve öğrencinin tüm emeği çöpe gider.*
>
> *EduPulse'ta teslim tarihi geçse bile yükleme engellenmez! Ancak Kural 2 devreye girer: Sistem gecikmeyi otomatik tespit eder, ödeve 'Gecikmeli Teslim' damgası vurur ve öğretmenin değerlendirme ekranına Kural 2 cezasını yansıtır. Öğretmen 100 üzerinden 85 verdiğinde, sistem otomatik olarak 10 puan ceza keserek öğrencinin nihai notunu 75 olarak kaydeder. Sayfadaki yükleme masası ise opak kart tasarımıyla her ortamda net okunur."*

#### 3️⃣ Kural 3: %20 Devamsızlık Erken Uyarı Motoru
> *"Öğrencilerin 'Hocam benim devamsızlığım kaç oldu, kaldım mı?' sorusuna son verdik.*
>
> *Kural 3 uyarınca, toplam ders saatinin %20'si aşıldığı an sistem otomatik olarak 'Kritik Risk' durumuna geçer. Firebase Cloud Messaging (FCM) servisi öğrencinin telefonuna anında push bildirim fırlatır: '⚠️ Kritik Devamsızlık Uyarısı: Kalma riski altındasınız!'. Öğretmen panelinde ise bu öğrenciler en tepede 'Kritik Risk Kırmızı Listesi'nde listelenerek öğretmenin erken müdahale etmesi sağlanır."*

#### 4️⃣ Kural 4: Not Ağırlıklandırma, Gauss Çan Eğrisi ve Not Simülatörü
> *"Notlama modülümüzde ham not yerine standart akademik ağırlıklandırma çalışır: `Vize %40 + Final %60 + Varsa Öğretmen Bonusu`. Tavan değer mutlak suretle 100'dür.*
>
> *Bununla da yetinmedik: Öğrenci için **'GPA Simülatörü'** geliştirdik. Öğrenci vizeden 60 aldıysa ve hedefi 'BA' ise, simülatör slider'ını oynatarak 'Finalden en az 82 almalısın' sonucunu anında görür. Ayrıca `CustomPainter` kullanarak sınıf dağılımını matematiksel Gauss eğrisiyle (Çan Eğrisi) ekrana canlı çizdirdik."*

#### 5️⃣ Kural 5: 3 Kademeli Mutlak Rol Güvenliği (RBAC)
> *"Güvenlik sadece arayüzde bir butonu gizlemek değildir. EduPulse 3 katmanlı savunma hattına sahiptir:*
> 1. **UI Katmanı:** `RoleVisibilityGuard` ile yetkisiz butonlar çizilmez bile.
> 2. **Router Katmanı:** `RoleGuard` ile öğrenci URL'den veya derin linkle `/grade/entry` veya `/attendance/qr-generator` sayfasına gitmeye kalkarsa kapıdan geri çevrilir.
> 3. **Veritabanı Katmanı:** `firestore.rules` ile öğrencinin token'ı yetkisiz bir yazma isteği gönderirse Firestore sunucu seviyesinde isteği anında bloke eder."*

---

### 5. BÖLÜM: Canlı Demo (Live Demo) Senaryosu (Adım Adım)

> 💡 **ÖNERİ:** Mümkünse iki emülatör/cihaz açın (biri Öğretmen, biri Öğrenci) veya Login sayfasından tek tıkla rol değiştirerek gösterin.

| Adım | Yapılacak İşlem | Ekranda Gösterilecek Detay | Ne Söylenecek? |
|---|---|---|---|
| **1** | **Giriş (Login)** | Rol butonundan "Öğretmen" seçip giriş yapın. | *"Giriş ekranımızda rol seçimiyle hızlı geçiş yapabiliyoruz. Öğretmen olarak giriyoruz."* |
| **2** | **Ders Programı** | Menüden "Ders Programı"na girin. | *"Öğretmen haftalık akışta amfi bilgilerini ve bir sonraki derse kalan geri sayım sayacını görüyor. 'Yeni Ders Ekle' butonu öğretmen için aktif."* |
| **3** | **Yoklama Başlatma** | "Yoklama Merkezi"ne gidin ve oturum başlatın. | *"İşte Kural 1: 60 saniyelik QR kod ve 6 haneli PIN! Sayaç geriye sayıyor, süre bittiğinde kod otomatik yenilenecek. Anlık katılan öğrenci sayısı canlı akıyor."* |
| **4** | **Rol Değiştirme** | Çıkış yapıp "Öğrenci" olarak girin. | *"Şimdi aynı dersteki öğrencinin gözünden bakalım."* |
| **5** | **Yoklamaya Katılma** | "QR Tara / PIN Gir" butonuna tıklayıp PIN girin. | *"Öğrenci kamerayla okutabilir veya 6 haneli PIN'i girer. Doğrulandığı an yeşil onay rozetiyle derse kaydedilir."* |
| **6** | **Devamsızlık Raporu** | "Devamsızlıklarım" sekmesini açın. | *"Kural 3: Devamsızlık %20 eşiğini aştığı için kart kırmızı yanıyor ve 'Kritik Risk' uyarısı veriyor."* |
| **7** | **Ödev Teslim Masası** | Ödevler sayfasına girip süresi geçmiş bir ödeve tıklayın. | *"Kural 2: Süresi geçmiş olsa da teslim engellenmedi! 'Geç Teslim (-10 Puan)' uyarısı net şekilde görülüyor. Dosya yükleme masamız opak tasarımıyla yüksek kontrastta açılıyor."* |
| **8** | **Notlar & Çan Eğrisi** | Notlarım sayfasına girin. | *"Kural 4: Vize %40, Final %60 motoru. Aşağıda CustomPainter ile çizdiğimiz Çan Eğrisi sınıf ortalamasını gösteriyor. Not Simülatörü ile hedef harf notuna göre gereken final notunu hesaplayabiliyoruz."* |
| **9** | **Akademik Forum & Ses** | Forum detayında sesli yanıt oynatıcısına tıklayın. | *"Öğretmen öğrencisine sadece metin değil, mikrofon servisiyle kaydettiği sesli geri bildirimi bırakabiliyor."* |

---

### 6. BÖLÜM: Kalite Güvencesi ve Test Otomasyonu (472/472)

#### 🖥️ Ekranda Ne Olmalı?
- Terminalden alınmış `472/472 All tests passed!` çıktısı ve test klasör ağacı.

#### 🗣️ Ne Konuşacaksınız?
> *"Yazılım dünyasında test edilmemiş kod, çalışmayan koddur. EduPulse projesinde geliştirdiğimiz her bir fonksiyon, use case ve ekran için test yazdık:*
>
> * **Birim Testleri (Unit Tests):** Not hesaplama algoritması, 60 sn sayaç sınır testleri (59. saniye geçerli, 61. saniye geçersiz), form doğrulayıcılar.
> * **State Testleri (`bloc_test`):** Tüm Cubit'lerin yaydığı durumlar (States) simüle edildi.
> * **Arayüz Testleri (Widget Tests):** Yetkisiz butonların görünmemesi, yükleme iskeletleri (Shimmer), hata ekranları.
> * **Taşma ve Düzen Testleri (Layout Tests):** Uygulama en dar ekranda ve en büyük yazı boyutunda (Accessibility) dahi çalıştırıldı; tek bir sarı-siyah taşma hatası (A RenderFlex overflowed) dahi yoktur!
>
> *Şu an projemizde tam **472 adet otomatik testin tamamı yeşildir**."*

---

## 🛡️ JÜRİDEN GELEBİLECEK ZOR SORULAR VE SAVUNMA REHBERİ (Q&A)

### ❓ Soru 1: "Öğrenci QR kodun fotoğrafını çekip sınıfta olmayan arkadaşına atarsa ne olacak?"
> **Cevabınız:** *"Hocam tam olarak bu açığı kapatmak için **Kural 1: 60 Saniye Dinamik Yoklama Kalkanı**'nı tasarladık. Tahtadaki QR kod ve PIN statik değildir; her 60 saniyede bir kriptografik olarak değişir. Fotoğraf çekilip WhatsApp'tan arkadaşına gönderilene kadar geçen sürede kodun ömrü tükenmiş olur. Ayrıca sunucu tarafında milisaniyelik Firestore time-window kontrolü yapıldığından geçersiz token'lar kesinlikle kabul edilmez."*

### ❓ Soru 2: "İnternet koparsa veya öğrencinin şarjı biterse ödev teslimi ne olacak?"
> **Cevabınız:** *"Projemizde `ConnectivityPlus` ile ağ durumunu dinleyen `NetworkInfo` mekanizması vardır. Ayrıca **Kural 2** gereğince sistem teslim saatinde kapıyı kapatmaz. Öğrenci interneti geldiğinde veya gecikmeli olarak yüklediğinde sistem yüklemeyi kabul eder, sadece adil olmak adına -10 ceza puanı uygulayarak teslimi tamamlar."*

### ❓ Soru 3: "Akıllı bir öğrenci Flutter kodunu decompile edip doğrudan Firestore'a öğretmen gibi istek atamaz mı?"
> **Cevabınız:** *"Harika bir soru hocam! Biz güvenliği asla sadece mobil arayüzde (Client-side) bırakmadık. Hazırladığımız `firestore.rules` güvenlik kurallarında `getUserRole() == 'teacher'` şartı sunucu düzeyinde kontrol edilir. İstemci kodunu değiştirip doğrudan veritabanına istek atılsa bile Firestore kuralları isteği yetkisiz bularak (Permission Denied) engeller."*

### ❓ Soru 4: "Neden BLoC / Cubit tercih ettiniz? Provider veya GetX kullansaydınız ne fark ederdi?"
> **Cevabınız:** *"GetX hızlı prototipleme için cazip görünse de büyük ve kurumsal projelerde katmanları birbirine karıştırır ve birim test yazmayı zorlaştırır. `flutter_bloc` ise durumları (States) tamamen öngörülebilir ve mühürlü (sealed) sınıflar olarak tanımlamamızı sağlar. Bu sayede `bloc_test` kütüphanesiyle tüm iş mantığımızı bağımsızca test edebildik."*

### ❓ Soru 5: "Çan eğrisini çizdirirken harici bir grafik kütüphanesi (fl_chart vb.) mi kullandınız?"
> **Cevabınız:** *"Hayır hocam, harici grafik paketlerinin getirdiği paket yükünden ve özelleştirme kısıtlarından kaçınmak için Flutter'ın çekirdek çizim motoru olan `CustomPainter` kullandık. `BellCurveChartPainter` sınıfımız matematiksel normal dağılım (Gauss) formülünü doğrudan piksel koordinatlarına dönüştürerek çizmektedir."*

---

## 🎯 Sunumu Bitirirken Söylenecek Kapanış Cümlesi

> *"EduPulse; disiplinli mimarisi, 472 testle garanti altına alınmış güvenilirliği ve üniversite kampüslerinin gerçek ihtiyaçlarına odaklanan 5 kritik kuralıyla geleceğin akademik yönetim vizyonudur.*
>
> *Dinlediğiniz için çok teşekkür ederiz. Şimdi sorularınızı yanıtlamaktan memnuniyet duyarız!"*

---

> 📌 **Not:** Bu rehber dosyasını [`docs/EDUPULSE_SUNUM_KILAVUZU.md`](file:///c:/Users/FAHRIASUS/Desktop/itogram_edupulse/docs/EDUPULSE_SUNUM_KILAVUZU.md) olarak her zaman açıp sunum provası yapabilirsiniz!

