// db.js
const { Pool } = require('pg');

// LÜTFEN KENDİ VERİTABANI BİLGİLERİNİZLE GÜNCELLEYİN
const pool = new Pool({
  user: 'postgres', 
  host: 'localhost', 
  database: 'drivekeep_db', // Veya DBeaver'da kullandığınız veritabanı adı //DCL ile kısıtlı kullanıcı oluşturduk onun şifresi
  password: 'az', 
  port: 5432,
});
/* 
// TAM YETKİLİ (Yedek olarak dursun)
user: 'postgres',
password: 'eski_sifren',
*/

module.exports = {
  query: (text, params) => pool.query(text, params),
};