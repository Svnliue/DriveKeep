# Amasya Akıllı Takip Kontrol Merkezi 🛴📍

Bu proje, şehir içi mikro-mobilite araçlarının (scooter, bisiklet vb.) anlık takibi, yönetimi ve analizi için geliştirilmiş bir **Full-Stack Coğrafi Bilgi Sistemi (GIS)** uygulamasıdır. Verimlilik, düşük batarya yönetimi ve mekansal veri analizi odaklanılarak tasarlanmıştır.

## 🚀 Öne Çıkan Özellikler

* **Mekansal Veri Yönetimi:** PostGIS eklentisi kullanılarak araç konumlarının koordinat bazlı (geodata) saklanması ve işlenmesi.
* **Anlık İzleme Paneli:** Leaflet.js entegrasyonu ile araçların harita üzerinde dinamik olarak görselleştirilmesi.
* **Batarya Yönetimi:** Şarj seviyesi %20'nin altına düşen araçların sistem tarafından otomatik olarak filtrelenmesi ve uyarı verilmesi.
* **Kiralama Analitiği:** Aktif kiralama sayısı ve araç durumlarının (boşta, kirada, bakımda) gerçek zamanlı takibi.
* **RESTful API:** Node.js ve Express.js ile geliştirilen, frontend ve veritabanı arasındaki iletişimi sağlayan sağlam backend mimarisi.

## 🛠 Teknoloji Yığını

| Katman | Kullanılan Teknolojiler |
| :--- | :--- |
| **Frontend** | HTML5, CSS3, JavaScript (ES6+), Leaflet.js |
| **Backend** | Node.js, Express.js |
| **Veritabanı** | PostgreSQL, PostGIS (Spatial Database) |
| **Araçlar** | DBeaver, VS Code, Git, GitHub |

## 🏗 İleri Seviye Veritabanı Mimarisi

Projenin kalbinde yer alan PostgreSQL yapısı, standart ilişkisel veri modelinin ötesine geçerek mekansal sorguları ve otomatik veritabanı işlemlerini barındırır:

* **Temel Tablolar:** `arac` (araç bilgileri ve batarya seviyeleri), `aracturu` (araç tiplerinin yönetimi), `kiralama` (kullanıcı ve araç eşleşmeleri).
* **Mekansal Veri (PostGIS):** Konum verilerinin `geometry(Point, 4326)` formatında işlenmesi.
* **Stored Procedures (Saklı Yordamlar):** Kiralama bitişi sonrası ücret hesaplama ve faturalandırma gibi karmaşık iş mantıklarının doğrudan veritabanı katmanında işlenmesi.
* **Triggers (Tetikleyiciler):** Kiralama başlatıldığında veya bitirildiğinde aracın durumunu ("kirada" veya "boşta") otomatik olarak güncelleyen olay dinleyicileri.
* **Views (Görünümler):** Dashboard ve analiz ekranları için sık kullanılan karmaşık "JOIN" sorgularının sanal tablolar halinde optimize edilmesi (Örn: aktif kiralamalar ve bataryası kritik olan araçlar).

## 💻 Kurulum ve Çalıştırma

Projeyi kendi bilgisayarınızda çalıştırmak için aşağıdaki adımları izleyebilirsiniz:

1. **Repoyu klonlayın:**
   ```bash
   git clone [https://github.com/Svnliue/DriveKeep.git](https://github.com/Svnliue/DriveKeep.git)
