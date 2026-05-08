# VTYS-1 Dönem Projesi — Çevrimiçi Yemek Sipariş Platformu Veritabanı

## Proje Özeti
3NF uyumlu, SQL Server (T-SQL) tabanlı ilişkisel veritabanı tasarımı.  
Klasik yemek sipariş akışı + **"Askıda Yemek"** hayır modülü içerir.

## Dosya Yapısı

| Dosya | Açıklama |
|---|---|
| `yemek_siparis_veritabani.sql` | DDL + DML + Trigger + View + Index + Analitik Sorgular |
| `er_diyagrami.md` | Varlık-İlişki diyagramı (Mermaid ERD) |
| `is_kurallari.md` | Tüm iş kuralları listesi |

## Veritabanı Nesneleri

- **20 Tablo** (3NF uyumlu)
- **3 View** (`vw_AktifRestoranMenuleri`, `vw_AskidaYemekHavuzDurumu`, `vw_SiparisFisi`)
- **2 Trigger** (`trg_BagisAfterInsert`, `trg_SiparisAfterUpdate`)
- **4 Index** (PK dışında, performans odaklı)
- **5+ CHECK kısıtlaması**

## Askıda Yemek Modülü
Hayırsever müşteriler anonim veya açık bağış yapabilir.  
Onaylı ihtiyaç sahipleri bu havuzdan ücretsiz sipariş verebilir.  
Tüm bakiye hareketleri trigger ile otomatik yönetilir.

## Kullanım
```sql
-- SQL Server Management Studio veya sqlcmd ile çalıştır:
sqlcmd -S .\SQLEXPRESS -i yemek_siparis_veritabani.sql
```

## Teknoloji
- **Veritabanı:** Microsoft SQL Server Express (T-SQL)
- **Tasarım:** 3. Normal Form (3NF)
