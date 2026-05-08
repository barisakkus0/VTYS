# ER Diyagramı — Çevrimiçi Yemek Sipariş Platformu

## Tablo İlişkileri (Mermaid ERD)

```mermaid
erDiagram
    Kullanicilar {
        int KullaniciId PK
        nvarchar Ad
        nvarchar Soyad
        nvarchar Eposta UK
        nvarchar Telefon UK
        nvarchar KullaniciTipi
        bit IsActive
    }
    Adresler {
        int AdresId PK
        int KullaniciId FK
        nvarchar AdresSatiri
        bit IsActive
    }
    KullaniciBakiyeleri {
        int BakiyeId PK
        int KullaniciId FK
        decimal BakiyeTL
    }
    RestoranKategorileri {
        int KategoriId PK
        nvarchar KategoriAdi UK
    }
    Restoranlar {
        int RestoranId PK
        int SahibiId FK
        nvarchar RestoranAdi
        decimal Puan
        decimal ToplamCiro
        bit IsActive
    }
    RestoranKategoriEslestirme {
        int RestoranId FK
        int KategoriId FK
    }
    MenuKategorileri {
        int MenuKategoriId PK
        int RestoranId FK
        nvarchar KategoriAdi
    }
    UrunlerMenusler {
        int UrunId PK
        int RestoranId FK
        int MenuKategoriId FK
        nvarchar UrunAdi
        decimal Fiyat
        bit IsActive
    }
    Siparisler {
        int SiparisId PK
        int MusteriId FK
        int RestoranId FK
        int TeslimatAdresId FK
        nvarchar Durum
        decimal ToplamTutar
        nvarchar OdemeTipi
    }
    SiparisKalemleri {
        int KalemId PK
        int SiparisId FK
        int UrunId FK
        int Adet
        decimal BirimFiyat
    }
    SiparisDurumGecmisi {
        int GecmisId PK
        int SiparisId FK
        nvarchar EskiDurum
        nvarchar YeniDurum
        datetime DegisimZamani
    }
    Odemeler {
        int OdemeId PK
        int SiparisId FK
        nvarchar OdemeTipi
        decimal Tutar
    }
    Kuryeler {
        int KuryeId PK
        int KullaniciId FK
        nvarchar AracTipi
        bit IsActive
    }
    KuryeAtamalari {
        int AtamaId PK
        int SiparisId FK
        int KuryeId FK
        datetime TeslimZamani
    }
    AskidaYemekHavuzu {
        int HavuzId PK
        decimal BakiyeTL
        decimal ToplamBagis
        decimal ToplamKullanim
    }
    AskidaBagislar {
        int BagisId PK
        int HavuzId FK
        int BagisciKullaniciId FK
        decimal BagistuTL
        bit AnonymMu
    }
    IhtiyacSahibiDogrulamasi {
        int DogrulamaId PK
        int KullaniciId FK
        nvarchar OnayDurumu
        int OnaylayanAdminId FK
    }
    AskidaKullanimi {
        int KullanimId PK
        int HavuzId FK
        int KullananKullaniciId FK
        int SiparisId FK
        decimal KullanilanTL
    }
    Degerlendirmeler {
        int DegerlendirmeId PK
        int SiparisId FK
        int MusteriId FK
        int RestoranId FK
        int Puan
    }

    Kullanicilar ||--o{ Adresler : "sahip olur"
    Kullanicilar ||--|| KullaniciBakiyeleri : "sahip olur"
    Kullanicilar ||--o{ Siparisler : "verir"
    Kullanicilar ||--o{ AskidaBagislar : "bagis yapar"
    Kullanicilar ||--o{ IhtiyacSahibiDogrulamasi : "basvurur"
    Kullanicilar ||--o| Kuryeler : "kurye profili"
    Kullanicilar ||--o{ Restoranlar : "sahip olur"

    Restoranlar ||--o{ UrunlerMenusler : "icerir"
    Restoranlar ||--o{ Siparisler : "alir"
    Restoranlar ||--o{ MenuKategorileri : "duzenlenir"
    Restoranlar }o--o{ RestoranKategorileri : "kategorilenir"
    RestoranKategoriEslestirme }o--|| Restoranlar : ""
    RestoranKategoriEslestirme }o--|| RestoranKategorileri : ""

    MenuKategorileri ||--o{ UrunlerMenusler : "gruplar"

    Siparisler ||--o{ SiparisKalemleri : "icerenir"
    Siparisler ||--o{ SiparisDurumGecmisi : "loglanir"
    Siparisler ||--|| Odemeler : "odeme"
    Siparisler ||--o| KuryeAtamalari : "atanir"
    Siparisler ||--o| AskidaKullanimi : "AskidaYemek"
    Siparisler ||--o| Degerlendirmeler : "puanlanir"

    SiparisKalemleri }o--|| UrunlerMenusler : "urun"
    KuryeAtamalari }o--|| Kuryeler : "kurye"

    AskidaYemekHavuzu ||--o{ AskidaBagislar : "alir"
    AskidaYemekHavuzu ||--o{ AskidaKullanimi : "saglar"
```

## İlişki Kardinaliteleri Açıklaması

| İlişki | Tür | Açıklama |
|---|---|---|
| Kullanicilar → Adresler | 1:N | Müşterinin birden fazla adresi olabilir |
| Kullanicilar → KullaniciBakiyeleri | 1:1 | Her kullanıcının tek cüzdanı |
| Restoranlar ↔ RestoranKategorileri | M:N | Köprü: RestoranKategoriEslestirme |
| Siparisler → SiparisKalemleri | 1:N | Sepette birden fazla ürün |
| Siparisler → KuryeAtamalari | 1:1 | Bir siparişe tek kurye |
| AskidaYemekHavuzu → AskidaBagislar | 1:N | Havuz birden fazla bağış alır |
| AskidaKullanimi → Siparisler | 1:1 | Bir sipariş max 1 kez askıda kullanılır |

## 3NF Uyumluluk Notu

- **1NF**: Tüm kolonlar atomik değer tutar, tekrarlayan grup yoktur.
- **2NF**: Tüm non-key kolonlar tam PK'ya bağımlıdır (bileşik PK olan `RestoranKategoriEslestirme` dahil).
- **3NF**: Geçişli bağımlılık yoktur — örneğin `Restoranlar.Puan`, `RestoranId`'ye bağlıdır, başka bir non-key kolona değil.
