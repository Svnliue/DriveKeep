// server.js (GÜNCELLENMİŞ VERSİYON: Şema Hataları Giderildi)
const express = require('express');
const cors = require('cors');
const path = require('path');
const db = require('./db'); 
const app = express();
const port = 3000;

app.use(cors()); 
app.use(express.json());
app.use(express.static(path.join(__dirname))); 

// 1. Uç Nokta: TÜM ARAÇLARIN KONUMLARINI GETİRME
app.get('/api/araclar/konum', async (req, res) => {
  const sqlQuery = `SELECT 
        A.arac_id, 
        A.model, 
        AT.tur_adi, 
        A.batarya_seviyesi, 
        A.durum, 
        public.ST_X(KT.geometri) AS boylam, 
        public.ST_Y(KT.geometri) AS enlem
    FROM public.arac A
    INNER JOIN public.aracturu AT ON A.tur_id = AT.tur_id
    INNER JOIN LATERAL (SELECT geometri FROM public.konumtakip WHERE arac_id = A.arac_id ORDER BY zaman_damgasi DESC LIMIT 1) AS KT ON TRUE
    WHERE A.durum IN ('bos', 'kiralandi', 'bakim');
  `;
  try {
    const { rows } = await db.query(sqlQuery);
    res.json(rows); 
  } catch (err) {
    console.error('Konum sorgusunda hata:', err);
    res.status(500).send({ message: 'Sunucu hatası.' });
  }
});

// 2. Uç Nokta: Kullanıcıya En Yakın 3 Müsait Aracı Bulma
app.get('/api/araclar/yakin', async (req, res) => {
    const { lat, lon } = req.query; 
    if (!lat || !lon) { return res.status(400).send({ message: 'Enlem ve Boylam gereklidir.' }); }

    const sqlQuery = `WITH user_location AS (SELECT public.ST_SetSRID(public.ST_MakePoint($1, $2), 4326) AS user_geom)
        SELECT 
            A.arac_id, 
            A.model, 
            AT.tur_adi, 
            A.batarya_seviyesi, 
            ROUND(public.ST_Distance(KT.geometri::geography, (SELECT user_geom FROM user_location)::geography)::NUMERIC, 2) AS mesafe_metre,
            public.ST_Y(KT.geometri) AS enlem,  
            public.ST_X(KT.geometri) AS boylam  
        FROM public.arac A
        JOIN public.aracturu AT ON A.tur_id = AT.tur_id
        INNER JOIN LATERAL (
            SELECT geometri 
            FROM public.konumtakip 
            WHERE arac_id = A.arac_id 
            ORDER BY zaman_damgasi DESC LIMIT 1
        ) AS KT ON TRUE
        WHERE A.durum = 'bos'
        ORDER BY KT.geometri <-> (SELECT user_geom FROM user_location)  
        LIMIT 3;
    `;

    try {
        const { rows } = await db.query(sqlQuery, [lon, lat]); 
        res.json(rows); 
    } catch (err) {
        console.error('Yakın araç sorgusunda hata:', err);
        res.status(500).send({ message: 'Sunucu hatası.' });
    }
});

// 4. Uç Nokta: Aktif Kiralamaları Listeleme (Artık View kullanıyoruz!)
app.get('/api/kiralamalar/aktif', async (req, res) => {
    try {
        // SQL sorgumuz tek bir tabloya bakıyormuş kadar basit hale geldi
        const { rows } = await db.query('SELECT * FROM aktif_kiralama_ozet');
        
        // Fiyat hesabı zaten veritabanında yapıldığı için map() işlemine gerek kalmadı!
        const result = rows.map(rental => ({
            ...rental,
            tahmini_fiyat: rental.tahmini_fiyat + ' TL',
            sure_dakika: Math.ceil(rental.sure_saniye / 60)
        }));

        res.json(result); 
    } catch (err) {
        console.error('Aktif kiralama sorgusunda hata:', err);
        res.status(500).send({ message: 'Aktif kiralama verisi alınamadı.' });
    }
});

// 5. Uç Nokta: Şarj Gerektiren Araçları Bulma
app.get('/api/bakim/dusuk-batarya', async (req, res) => {
  const sqlQuery = `SELECT A.arac_id, A.model, A.batarya_seviyesi
    FROM public.arac A
    WHERE A.tur_id = 1 AND A.durum = 'bos' AND A.batarya_seviyesi <= 20.00;
  `;
  try {
    const { rows } = await db.query(sqlQuery);
    res.json(rows); 
  } catch (err) {
    res.status(500).send({ message: 'Düşük batarya verisi alınamadı.' });
  }
});

// 6. Uç Nokta: Kiralama Başlatma (Stored Procedure + TCL Uygulaması)
app.post('/api/kiralamalar/baslat', async (req, res) => {
    const { aracId, userEmail, userName, userPhone } = req.body;

    if (!aracId || !userEmail) {
        return res.status(400).send({ message: 'Araç ID ve E-posta gereklidir.' });
    }

    try {
        // Önce kullanıcının ID'sini alalım (Yoksa oluşturalım)
        // Bu kısmı basit tutmak için önce kullanıcıyı kontrol ediyoruz
        let userResult = await db.query('SELECT kullanici_id FROM public.kullanici WHERE eposta = $1', [userEmail]);
        let kullaniciId;

        if (userResult.rows.length === 0) {
            const newUser = await db.query(
                'INSERT INTO public.kullanici (ad_soyad, eposta, telefon) VALUES ($1, $2, $3) RETURNING kullanici_id',
                [userName, userEmail, userPhone]
            );
            kullaniciId = newUser.rows[0].kullanici_id;
        } else {
            kullaniciId = userResult.rows[0].kullanici_id;
        }

        // --- ASIL PROFESYONEL KISIM BURASI ---
        // Veritabanında oluşturduğumuz prosedürü çağırıyoruz.
        // Bu prosedür hem kiralama kaydını açar hem de aracın durumunu 'pasif' yapar.
        await db.query('CALL kiralama_baslat_proseduru($1, $2)', [kullaniciId, aracId]);

        res.json({ 
            success: true, 
            message: 'Kiralama başarıyla başlatıldı (Stored Procedure kullanıldı).',
            kullaniciId: kullaniciId
        });

    } catch (err) {
        console.error('Kiralama başlatma hatası:', err.message);
        res.status(500).send({ message: 'Prosedür çalıştırılamadı: ' + err.message });
    }
});

// 7. Uç Nokta: Geçmiş Kiralamalar
app.get('/api/kiralamalar/gecmis', async (req, res) => {
    const sqlQuery = `
        SELECT 
            K.kiralama_id, 
            U.ad_soyad AS kiralayan_kullanici, 
            A.arac_id,                                   
            A.model AS kiralanan_arac,
            K.baslangic_zamani,
            K.bitis_zamani,
            EXTRACT(EPOCH FROM (K.bitis_zamani - K.baslangic_zamani)) AS sure_saniye,
            FM.dakika_ucreti, 
            FM.acilis_ucreti 
        FROM public.kiralama K 
        JOIN public.kullanici U ON K.kullanici_id = U.kullanici_id
        JOIN public.arac A ON K.arac_id = A.arac_id
        JOIN public.fiyatlandirmamodelleri FM ON A.fiyat_model_id = FM.model_id
        WHERE K.bitis_zamani IS NOT NULL
        ORDER BY K.bitis_zamani DESC;
    `;
    try {
        const { rows } = await db.query(sqlQuery);
        const completedRentals = rows.map(rental => {
            const sureDakika = Math.ceil(rental.sure_saniye / 60);
            const toplamFiyat = parseFloat(rental.acilis_ucreti) + (sureDakika * parseFloat(rental.dakika_ucreti));
            return {
                ...rental,
                sure_dakika: sureDakika,
                tahmini_fiyat: toplamFiyat.toFixed(2) + ' TL'
            };
        });
        res.json(completedRentals); 
    } catch (err) {
        console.error('Geçmiş kiralama sorgu hatası:', err);
        res.status(500).send({ message: 'Geçmiş veriler alınamadı.' });
    }
});

// 8. Uç Nokta: Kiralama Bitirme (Trigger ve TCL Mantığı ile Sadeleşti)
app.post('/api/kiralamalar/bitir', async (req, res) => {
  const { kiralamaId, aracId } = req.body;
  if (!kiralamaId || !aracId) {
    return res.status(400).send({ message: 'Kiralama ID ve Araç ID gereklidir.' });
  }
  try {
    // Sadece kiralamayı güncelliyoruz
    const updateRental = await db.query(
      'UPDATE public.kiralama SET bitis_zamani = CURRENT_TIMESTAMP WHERE kiralama_id = $1 RETURNING kiralama_id, baslangic_zamani, bitis_zamani',
      [kiralamaId]
    );
    
    if (updateRental.rows.length === 0) {
      return res.status(404).send({ message: 'Kiralama bulunamadı.' });
    }
    
    // DİKKAT: Eskiden burada olan 'UPDATE public.arac SET durum = ...' satırını sildik!
    // Çünkü artık veritabanındaki TRIGGER bu işi otomatik yapıyor.
    
    const rentalData = updateRental.rows[0];
    const sureSaniye = Math.floor((new Date(rentalData.bitis_zamani) - new Date(rentalData.baslangic_zamani)) / 1000);
    const sureDakika = Math.ceil(sureSaniye / 60);
    
    res.json({ 
      message: 'Kiralama başarıyla bitirildi (Araç durumu Trigger ile güncellendi).', 
      kiralamaId: rentalData.kiralama_id,
      sureDakika: sureDakika,
      baslangic_zamani: rentalData.baslangic_zamani,
      bitis_zamani: rentalData.bitis_zamani
    });
  } catch (err) {
    console.error('Kiralama bitirme hatası:', err.message);
    res.status(500).send({ message: 'Kiralama bitirilirken hata oluştu: ' + err.message });
  }
});

app.listen(port, () => {
  console.log(`Node.js API sunucusu http://localhost:${port} adresinde çalışıyor.`);
});