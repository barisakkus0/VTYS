-- ============================================================
-- VTYS-1 DÖNEM PROJESİ: Çevrimiçi Yemek Sipariş Platformu
-- Veritabanı: SQL Server (T-SQL)
-- ============================================================

USE master;
GO
IF DB_ID('YemekSiparisDB') IS NOT NULL
    DROP DATABASE YemekSiparisDB;
GO
CREATE DATABASE YemekSiparisDB;
GO
USE YemekSiparisDB;
GO

-- ============================================================
-- 1. KULLANICI KATMANI
-- ============================================================

CREATE TABLE Kullanicilar (
    KullaniciId   INT IDENTITY(1,1) PRIMARY KEY,
    Ad            NVARCHAR(50)  NOT NULL,
    Soyad         NVARCHAR(50)  NOT NULL,
    Eposta        NVARCHAR(100) NOT NULL UNIQUE,
    Telefon       NVARCHAR(20)  NOT NULL UNIQUE,
    SifreHash     NVARCHAR(256) NOT NULL,
    KullaniciTipi NVARCHAR(20)  NOT NULL  -- 'Musteri','Kurye','RestoranSahibi','Admin'
        CONSTRAINT chk_KullaniciTipi CHECK (KullaniciTipi IN ('Musteri','Kurye','RestoranSahibi','Admin')),
    IsActive      BIT           NOT NULL DEFAULT 1,
    OlusturmaTarihi DATETIME    NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE Adresler (
    AdresId       INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId   INT           NOT NULL FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    AdresBasligi  NVARCHAR(50)  NOT NULL,
    AdresSatiri   NVARCHAR(200) NOT NULL,
    Ilce          NVARCHAR(50)  NOT NULL,
    Sehir         NVARCHAR(50)  NOT NULL DEFAULT N'İstanbul',
    IsActive      BIT           NOT NULL DEFAULT 1
);
GO

CREATE TABLE KullaniciBakiyeleri (
    BakiyeId      INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId   INT           NOT NULL UNIQUE FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    BakiyeTL      DECIMAL(10,2) NOT NULL DEFAULT 0.00
        CONSTRAINT chk_BakiyeNegatif CHECK (BakiyeTL >= 0)
);
GO

-- ============================================================
-- 2. RESTORAN KATMANI
-- ============================================================

CREATE TABLE RestoranKategorileri (
    KategoriId    INT IDENTITY(1,1) PRIMARY KEY,
    KategoriAdi   NVARCHAR(50)  NOT NULL UNIQUE
);
GO

CREATE TABLE Restoranlar (
    RestoranId    INT IDENTITY(1,1) PRIMARY KEY,
    SahibiId      INT           NOT NULL FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    RestoranAdi   NVARCHAR(100) NOT NULL,
    Telefon       NVARCHAR(20)  NOT NULL,
    Adres         NVARCHAR(200) NOT NULL,
    Puan          DECIMAL(3,2)  NULL
        CONSTRAINT chk_RestoranPuan CHECK (Puan BETWEEN 1 AND 5),
    ToplamCiro    DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    MinSepetTutar DECIMAL(8,2)  NOT NULL DEFAULT 0.00,
    IsActive      BIT           NOT NULL DEFAULT 1,
    OlusturmaTarihi DATETIME    NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE RestoranKategoriEslestirme (
    RestoranId    INT NOT NULL FOREIGN KEY REFERENCES Restoranlar(RestoranId),
    KategoriId    INT NOT NULL FOREIGN KEY REFERENCES RestoranKategorileri(KategoriId),
    PRIMARY KEY (RestoranId, KategoriId)
);
GO

CREATE TABLE MenuKategorileri (
    MenuKategoriId INT IDENTITY(1,1) PRIMARY KEY,
    RestoranId     INT          NOT NULL FOREIGN KEY REFERENCES Restoranlar(RestoranId),
    KategoriAdi    NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE UrunlerMenusler (
    UrunId         INT IDENTITY(1,1) PRIMARY KEY,
    RestoranId     INT           NOT NULL FOREIGN KEY REFERENCES Restoranlar(RestoranId),
    MenuKategoriId INT           NULL     FOREIGN KEY REFERENCES MenuKategorileri(MenuKategoriId),
    UrunAdi        NVARCHAR(100) NOT NULL,
    Aciklama       NVARCHAR(300) NULL,
    Fiyat          DECIMAL(8,2)  NOT NULL
        CONSTRAINT chk_UrunFiyat CHECK (Fiyat > 0),
    IsActive       BIT           NOT NULL DEFAULT 1,
    OlusturmaTarihi DATETIME     NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- 3. SİPARİŞ KATMANI
-- ============================================================

CREATE TABLE Siparisler (
    SiparisId      INT IDENTITY(1,1) PRIMARY KEY,
    MusteriId      INT           NOT NULL FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    RestoranId     INT           NOT NULL FOREIGN KEY REFERENCES Restoranlar(RestoranId),
    TeslimatAdresId INT          NOT NULL FOREIGN KEY REFERENCES Adresler(AdresId),
    Durum          NVARCHAR(20)  NOT NULL DEFAULT 'Beklemede'
        CONSTRAINT chk_SiparisDurum CHECK (Durum IN ('Beklemede','Onaylandi','Hazirlaniyor','YoldaKurye','TeslimEdildi','Iptal')),
    ToplamTutar    DECIMAL(10,2) NOT NULL
        CONSTRAINT chk_ToplamTutar CHECK (ToplamTutar > 0),
    OdemeTipi      NVARCHAR(20)  NOT NULL
        CONSTRAINT chk_OdemeTipi CHECK (OdemeTipi IN ('KrediKarti','NakitKapida','CuzzdanBakiyesi','AskidaYemek')),
    Notlar         NVARCHAR(300) NULL,
    OlusturmaTarihi DATETIME     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE SiparisKalemleri (
    KalemId        INT IDENTITY(1,1) PRIMARY KEY,
    SiparisId      INT           NOT NULL FOREIGN KEY REFERENCES Siparisler(SiparisId),
    UrunId         INT           NOT NULL FOREIGN KEY REFERENCES UrunlerMenusler(UrunId),
    Adet           INT           NOT NULL
        CONSTRAINT chk_Adet CHECK (Adet > 0),
    BirimFiyat     DECIMAL(8,2)  NOT NULL
        CONSTRAINT chk_BirimFiyat CHECK (BirimFiyat > 0)
);
GO

CREATE TABLE SiparisDurumGecmisi (
    GecmisId       INT IDENTITY(1,1) PRIMARY KEY,
    SiparisId      INT          NOT NULL FOREIGN KEY REFERENCES Siparisler(SiparisId),
    EskiDurum      NVARCHAR(20) NULL,
    YeniDurum      NVARCHAR(20) NOT NULL,
    DegisimZamani  DATETIME     NOT NULL DEFAULT GETDATE(),
    DegistirenId   INT          NULL     FOREIGN KEY REFERENCES Kullanicilar(KullaniciId)
);
GO

CREATE TABLE Odemeler (
    OdemeId        INT IDENTITY(1,1) PRIMARY KEY,
    SiparisId      INT           NOT NULL UNIQUE FOREIGN KEY REFERENCES Siparisler(SiparisId),
    OdemeTipi      NVARCHAR(20)  NOT NULL,
    Tutar          DECIMAL(10,2) NOT NULL
        CONSTRAINT chk_OdemeTutar CHECK (Tutar > 0),
    OdemeTarihi    DATETIME      NOT NULL DEFAULT GETDATE(),
    DurumuBasarili BIT           NOT NULL DEFAULT 1
);
GO

-- ============================================================
-- 4. KURYE KATMANI
-- ============================================================

CREATE TABLE Kuryeler (
    KuryeId        INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId    INT          NOT NULL UNIQUE FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    AracTipi       NVARCHAR(30) NOT NULL DEFAULT 'Motorsiklet',
    IsActive       BIT          NOT NULL DEFAULT 1
);
GO

CREATE TABLE KuryeAtamalari (
    AtamaId        INT IDENTITY(1,1) PRIMARY KEY,
    SiparisId      INT      NOT NULL UNIQUE FOREIGN KEY REFERENCES Siparisler(SiparisId),
    KuryeId        INT      NOT NULL FOREIGN KEY REFERENCES Kuryeler(KuryeId),
    AtamaTarihi    DATETIME NOT NULL DEFAULT GETDATE(),
    TeslimZamani   DATETIME NULL
);
GO

-- ============================================================
-- 5. ASKIDA YEMEK MODÜLÜ
-- ============================================================

CREATE TABLE AskidaYemekHavuzu (
    HavuzId        INT IDENTITY(1,1) PRIMARY KEY,
    BakiyeTL       DECIMAL(12,2) NOT NULL DEFAULT 0.00
        CONSTRAINT chk_HavuzBakiye CHECK (BakiyeTL >= 0),
    ToplamBagis    DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    ToplamKullanim DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    SonGuncelleme  DATETIME      NOT NULL DEFAULT GETDATE()
);
GO

-- İlk havuz kaydını oluştur
INSERT INTO AskidaYemekHavuzu (BakiyeTL, ToplamBagis, ToplamKullanim) VALUES (0, 0, 0);
GO

CREATE TABLE AskidaBagislar (
    BagisId        INT IDENTITY(1,1) PRIMARY KEY,
    HavuzId        INT           NOT NULL FOREIGN KEY REFERENCES AskidaYemekHavuzu(HavuzId),
    BagisciKullaniciId INT       NULL     FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    BagistuTL      DECIMAL(10,2) NOT NULL
        CONSTRAINT chk_BagistuTL CHECK (BagistuTL > 0),
    AnonymMu       BIT           NOT NULL DEFAULT 0,
    Mesaj          NVARCHAR(200) NULL,
    BagisTarihi    DATETIME      NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE IhtiyacSahibiDogrulamasi (
    DogrulamaId    INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId    INT          NOT NULL FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    OnayDurumu     NVARCHAR(20) NOT NULL DEFAULT 'Beklemede'
        CONSTRAINT chk_OnayDurumu CHECK (OnayDurumu IN ('Beklemede','Onaylandi','Reddedildi')),
    OnaylayanAdminId INT        NULL     FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    BasvuruTarihi  DATETIME     NOT NULL DEFAULT GETDATE(),
    OnayTarihi     DATETIME     NULL,
    Aciklama       NVARCHAR(300) NULL
);
GO

CREATE TABLE AskidaKullanimi (
    KullanimId     INT IDENTITY(1,1) PRIMARY KEY,
    HavuzId        INT           NOT NULL FOREIGN KEY REFERENCES AskidaYemekHavuzu(HavuzId),
    KullananKullaniciId INT      NOT NULL FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    SiparisId      INT           NOT NULL UNIQUE FOREIGN KEY REFERENCES Siparisler(SiparisId),
    KullanilanTL   DECIMAL(10,2) NOT NULL
        CONSTRAINT chk_KullanilanTL CHECK (KullanilanTL > 0),
    KullanimTarihi DATETIME      NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- 6. DEĞERLENDİRME & BİLDİRİM
-- ============================================================

CREATE TABLE Degerlendirmeler (
    DegerlendirmeId INT IDENTITY(1,1) PRIMARY KEY,
    SiparisId       INT          NOT NULL UNIQUE FOREIGN KEY REFERENCES Siparisler(SiparisId),
    MusteriId       INT          NOT NULL FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    RestoranId      INT          NOT NULL FOREIGN KEY REFERENCES Restoranlar(RestoranId),
    Puan            INT          NOT NULL
        CONSTRAINT chk_Puan CHECK (Puan BETWEEN 1 AND 5),
    Yorum           NVARCHAR(500) NULL,
    OlusturmaTarihi DATETIME     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE Bildirimler (
    BildirimId      INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId     INT          NOT NULL FOREIGN KEY REFERENCES Kullanicilar(KullaniciId),
    Baslik          NVARCHAR(100) NOT NULL,
    Mesaj           NVARCHAR(300) NOT NULL,
    OkunduMu        BIT          NOT NULL DEFAULT 0,
    GonderimTarihi  DATETIME     NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- INDEKSLEMELEr (PK dışında)
-- ============================================================

-- I1: Restoran + Durum bazlı sipariş sorguları için
CREATE NONCLUSTERED INDEX idx_Siparisler_RestoranId_Durum
    ON Siparisler (RestoranId, Durum)
    INCLUDE (MusteriId, ToplamTutar, OlusturmaTarihi);
GO

-- I2: Aktif menü listeleme için
CREATE NONCLUSTERED INDEX idx_UrunlerMenusler_RestoranId_IsActive
    ON UrunlerMenusler (RestoranId, IsActive)
    INCLUDE (UrunAdi, Fiyat);
GO

-- I3: Bağış sorgularını hızlandırır
CREATE NONCLUSTERED INDEX idx_AskidaBagislar_BagisciId
    ON AskidaBagislar (BagisciKullaniciId)
    INCLUDE (BagistuTL, BagisTarihi);
GO

-- I4: Müşteri bazlı sipariş geçmişi için
CREATE NONCLUSTERED INDEX idx_Siparisler_MusteriId_Tarih
    ON Siparisler (MusteriId, OlusturmaTarihi DESC);
GO

-- ============================================================
-- TRIGGER 1: Bağış eklenince havuz bakiyesini artır
-- ============================================================

CREATE OR ALTER TRIGGER trg_BagisAfterInsert
ON AskidaBagislar
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE AskidaYemekHavuzu
    SET BakiyeTL       = BakiyeTL + i.BagistuTL,
        ToplamBagis    = ToplamBagis + i.BagistuTL,
        SonGuncelleme  = GETDATE()
    FROM inserted i
    WHERE AskidaYemekHavuzu.HavuzId = i.HavuzId;
END;
GO

-- ============================================================
-- TRIGGER 2: Sipariş TeslimEdildi → ciro güncelle + AskıdaYemek ise bakiye düş
-- ============================================================

CREATE OR ALTER TRIGGER trg_SiparisAfterUpdate
ON Siparisler
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Yalnızca TeslimEdildi durumuna geçenler
    IF NOT EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.SiparisId = d.SiparisId
        WHERE i.Durum = 'TeslimEdildi' AND d.Durum <> 'TeslimEdildi'
    ) RETURN;

    -- Durum geçmişi logu
    INSERT INTO SiparisDurumGecmisi (SiparisId, EskiDurum, YeniDurum)
    SELECT i.SiparisId, d.Durum, 'TeslimEdildi'
    FROM inserted i
    JOIN deleted d ON i.SiparisId = d.SiparisId
    WHERE i.Durum = 'TeslimEdildi' AND d.Durum <> 'TeslimEdildi';

    -- Restoran cirosunu artır
    UPDATE r
    SET r.ToplamCiro = r.ToplamCiro + i.ToplamTutar
    FROM Restoranlar r
    JOIN inserted i ON r.RestoranId = i.RestoranId
    JOIN deleted  d ON i.SiparisId  = d.SiparisId
    WHERE i.Durum = 'TeslimEdildi' AND d.Durum <> 'TeslimEdildi';

    -- AskıdaYemek ödeme tipi ise havuzdan düş
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.SiparisId = d.SiparisId
        WHERE i.Durum = 'TeslimEdildi' AND d.Durum <> 'TeslimEdildi'
          AND i.OdemeTipi = 'AskidaYemek'
    )
    BEGIN
        -- Bakiye yeterliliğini kontrol et
        DECLARE @Tutar DECIMAL(10,2);
        DECLARE @HavuzBakiye DECIMAL(12,2);
        SELECT @Tutar = i.ToplamTutar FROM inserted i JOIN deleted d ON i.SiparisId=d.SiparisId
            WHERE i.Durum='TeslimEdildi' AND d.Durum<>'TeslimEdildi' AND i.OdemeTipi='AskidaYemek';
        SELECT @HavuzBakiye = BakiyeTL FROM AskidaYemekHavuzu WHERE HavuzId = 1;

        IF @HavuzBakiye < @Tutar
            THROW 50001, 'Askıda Yemek havuzunda yeterli bakiye yok!', 1;

        UPDATE AskidaYemekHavuzu
        SET BakiyeTL       = BakiyeTL - @Tutar,
            ToplamKullanim = ToplamKullanim + @Tutar,
            SonGuncelleme  = GETDATE()
        WHERE HavuzId = 1;

        INSERT INTO AskidaKullanimi (HavuzId, KullananKullaniciId, SiparisId, KullanilanTL)
        SELECT 1, i.MusteriId, i.SiparisId, i.ToplamTutar
        FROM inserted i JOIN deleted d ON i.SiparisId=d.SiparisId
        WHERE i.Durum='TeslimEdildi' AND d.Durum<>'TeslimEdildi' AND i.OdemeTipi='AskidaYemek';
    END;
END;
GO

-- ============================================================
-- VIEW 1: Aktif restoran menüleri
-- ============================================================

CREATE OR ALTER VIEW vw_AktifRestoranMenuleri AS
SELECT
    r.RestoranId,
    r.RestoranAdi,
    mk.KategoriAdi       AS MenuKategorisi,
    u.UrunId,
    u.UrunAdi,
    u.Aciklama,
    u.Fiyat
FROM Restoranlar r
JOIN UrunlerMenusler u  ON r.RestoranId     = u.RestoranId
LEFT JOIN MenuKategorileri mk ON u.MenuKategoriId = mk.MenuKategoriId
WHERE r.IsActive = 1 AND u.IsActive = 1;
GO

-- VIEW 2: Askıda Yemek havuz durumu
CREATE OR ALTER VIEW vw_AskidaYemekHavuzDurumu AS
SELECT
    h.HavuzId,
    h.ToplamBagis,
    h.ToplamKullanim,
    h.BakiyeTL                          AS GuncelBakiye,
    COUNT(DISTINCT b.BagisId)           AS ToplamBagisSayisi,
    COUNT(DISTINCT k.KullanimId)        AS ToplamKullanimSayisi,
    h.SonGuncelleme
FROM AskidaYemekHavuzu h
LEFT JOIN AskidaBagislar b  ON h.HavuzId = b.HavuzId
LEFT JOIN AskidaKullanimi k ON h.HavuzId = k.HavuzId
GROUP BY h.HavuzId, h.ToplamBagis, h.ToplamKullanim, h.BakiyeTL, h.SonGuncelleme;
GO

-- VIEW 3: Detaylı sipariş fişi
CREATE OR ALTER VIEW vw_SiparisFisi AS
SELECT
    s.SiparisId,
    s.OlusturmaTarihi                               AS SiparisTarihi,
    s.Durum,
    s.ToplamTutar,
    s.OdemeTipi,
    m.Ad + ' ' + m.Soyad                            AS MusteriAdSoyad,
    m.Telefon                                       AS MusteriTelefon,
    r.RestoranAdi,
    r.Telefon                                       AS RestoranTelefon,
    u.UrunAdi,
    sk.Adet,
    sk.BirimFiyat,
    sk.Adet * sk.BirimFiyat                         AS KalemToplam,
    kk.Ad + ' ' + kk.Soyad                         AS KuryeAdSoyad,
    ka.AtamaTarihi                                  AS KuryeAtamaTarihi,
    ka.TeslimZamani
FROM Siparisler s
JOIN Kullanicilar m       ON s.MusteriId   = m.KullaniciId
JOIN Restoranlar r        ON s.RestoranId  = r.RestoranId
JOIN SiparisKalemleri sk  ON s.SiparisId   = sk.SiparisId
JOIN UrunlerMenusler u    ON sk.UrunId     = u.UrunId
LEFT JOIN KuryeAtamalari ka ON s.SiparisId = ka.SiparisId
LEFT JOIN Kuryeler ky       ON ka.KuryeId  = ky.KuryeId
LEFT JOIN Kullanicilar kk   ON ky.KullaniciId = kk.KullaniciId;
GO

-- ============================================================
-- DML: MOCK VERİLER
-- ============================================================

-- Admin
INSERT INTO Kullanicilar (Ad,Soyad,Eposta,Telefon,SifreHash,KullaniciTipi) VALUES
(N'Admin',N'Sistem','admin@platform.com','05000000000','hash_admin','Admin');

-- Restoran Sahipleri (2)
INSERT INTO Kullanicilar (Ad,Soyad,Eposta,Telefon,SifreHash,KullaniciTipi) VALUES
(N'Ahmet',N'Yılmaz','ahmet@rest.com','05311111111','hash1','RestoranSahibi'),
(N'Fatma',N'Kaya','fatma@rest.com','05312222222','hash2','RestoranSahibi'),
(N'Mehmet',N'Demir','mehmet@rest.com','05313333333','hash3','RestoranSahibi'),
(N'Zeynep',N'Çelik','zeynep@rest.com','05314444444','hash4','RestoranSahibi'),
(N'Ali',N'Şahin','ali@rest.com','05315555555','hash5','RestoranSahibi');

-- Kuryeler (3)
INSERT INTO Kullanicilar (Ad,Soyad,Eposta,Telefon,SifreHash,KullaniciTipi) VALUES
(N'Kemal',N'Arslan','kemal@kurye.com','05321111111','hash6','Kurye'),
(N'Hasan',N'Yıldız','hasan@kurye.com','05322222222','hash7','Kurye'),
(N'Murat',N'Güneş','murat@kurye.com','05323333333','hash8','Kurye');

-- Müşteriler (20)
INSERT INTO Kullanicilar (Ad,Soyad,Eposta,Telefon,SifreHash,KullaniciTipi) VALUES
(N'Ayşe',N'Türk','ayse@mail.com','05331000001','hashm1','Musteri'),
(N'Burak',N'Özkan','burak@mail.com','05331000002','hashm2','Musteri'),
(N'Ceren',N'Aydın','ceren@mail.com','05331000003','hashm3','Musteri'),
(N'Deniz',N'Kurt','deniz@mail.com','05331000004','hashm4','Musteri'),
(N'Emre',N'Polat','emre@mail.com','05331000005','hashm5','Musteri'),
(N'Gizem',N'Doğan','gizem@mail.com','05331000006','hashm6','Musteri'),
(N'Hande',N'Aksoy','hande@mail.com','05331000007','hashm7','Musteri'),
(N'İbrahim',N'Çetin','ibrahim@mail.com','05331000008','hashm8','Musteri'),
(N'Jale',N'Koç','jale@mail.com','05331000009','hashm9','Musteri'),
(N'Kamil',N'Erdoğan','kamil@mail.com','05331000010','hashm10','Musteri'),
(N'Lale',N'Özdemir','lale@mail.com','05331000011','hashm11','Musteri'),
(N'Mert',N'Yalçın','mert@mail.com','05331000012','hashm12','Musteri'),
(N'Nazlı',N'Şimşek','nazli@mail.com','05331000013','hashm13','Musteri'),
(N'Onur',N'Kılıç','onur@mail.com','05331000014','hashm14','Musteri'),
(N'Pınar',N'Avcı','pinar@mail.com','05331000015','hashm15','Musteri'),
(N'Rıza',N'Korkmaz','riza@mail.com','05331000016','hashm16','Musteri'),
(N'Selin',N'Yıldırım','selin@mail.com','05331000017','hashm17','Musteri'),
(N'Tolga',N'Bulut','tolga@mail.com','05331000018','hashm18','Musteri'),
(N'Ümit',N'Özcan','umit@mail.com','05331000019','hashm19','Musteri'),
(N'Vildan',N'Arslan','vildan@mail.com','05331000020','hashm20','Musteri');
GO

-- Bakiye kayıtları
INSERT INTO KullaniciBakiyeleri (KullaniciId, BakiyeTL)
SELECT KullaniciId, 50.00 FROM Kullanicilar WHERE KullaniciTipi = 'Musteri';
GO

-- Adresler (müşteri başına 1)
INSERT INTO Adresler (KullaniciId, AdresBasligi, AdresSatiri, Ilce, Sehir)
SELECT KullaniciId, N'Ev', N'Örnek Mah. No:'+ CAST(KullaniciId AS NVARCHAR), N'Kadıköy', N'İstanbul'
FROM Kullanicilar WHERE KullaniciTipi = 'Musteri';
GO

-- Restoran Kategorileri
INSERT INTO RestoranKategorileri (KategoriAdi) VALUES
(N'Pizza'),(N'Burger'),(N'Türk Mutfağı'),(N'Sushi'),(N'Döner');
GO

-- Restoranlar (5)
INSERT INTO Restoranlar (SahibiId, RestoranAdi, Telefon, Adres, Puan, MinSepetTutar) VALUES
(2, N'Pizza Palazzo',    '02121111111', N'Beşiktaş, İstanbul', 4.50, 50),
(3, N'Burger House',     '02122222222', N'Şişli, İstanbul',    4.20, 40),
(4, N'Türk Sofrası',     '02123333333', N'Fatih, İstanbul',    4.70, 60),
(5, N'Tokyo Sushi',      '02124444444', N'Beyoğlu, İstanbul',  4.30, 80),
(6, N'Döner Express',    '02125555555', N'Üsküdar, İstanbul',  4.10, 35);
GO

-- Restoran-Kategori eşleştirme
INSERT INTO RestoranKategoriEslestirme (RestoranId, KategoriId) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5);
GO

-- Menü Kategorileri
INSERT INTO MenuKategorileri (RestoranId, KategoriAdi) VALUES
(1,N'Pizzalar'),(1,N'İçecekler'),
(2,N'Burgerler'),(2,N'Soslar'),
(3,N'Ana Yemekler'),(3,N'Çorbalar'),
(4,N'Sushi Çeşitleri'),(4,N'Miso'),
(5,N'Dönerler'),(5,N'Yanlar');
GO

-- Ürünler (50+)
INSERT INTO UrunlerMenusler (RestoranId, MenuKategoriId, UrunAdi, Fiyat) VALUES
-- Pizza Palazzo (RestoranId=1, MenuKat 1=Pizzalar, 2=İçecekler)
(1,1,N'Margarita',        120),
(1,1,N'Karışık Pizza',    150),
(1,1,N'Vejeteryan Pizza', 130),
(1,1,N'Sucuklu Pizza',    145),
(1,1,N'4 Peynirli Pizza', 155),
(1,1,N'BBQ Tavuklu Pizza',160),
(1,1,N'Ton Balıklı Pizza',165),
(1,2,N'Kola',              25),
(1,2,N'Ayran',             15),
(1,2,N'Su',                10),
-- Burger House (RestoranId=2, MenuKat 3=Burgerler, 4=Soslar)
(2,3,N'Klasik Burger',    110),
(2,3,N'Çift Etli Burger', 145),
(2,3,N'Tavuk Burger',     105),
(2,3,N'Veggie Burger',    115),
(2,3,N'BBQ Burger',       130),
(2,3,N'Mantar Burger',    120),
(2,3,N'Füme Et Burger',   155),
(2,4,N'Patates Kızartması',50),
(2,4,N'Soğan Halkası',     45),
(2,4,N'Coleslaw',          35),
-- Türk Sofrası (RestoranId=3, MenuKat 5=Ana Yemekler, 6=Çorbalar)
(3,5,N'Karışık Izgara',   220),
(3,5,N'Köfte',            140),
(3,5,N'Tavuk Şiş',        155),
(3,5,N'Kuzu Tandır',      280),
(3,5,N'İskender',         180),
(3,5,N'Pide',             120),
(3,6,N'Mercimek Çorbası',  45),
(3,6,N'Ezogelin Çorbası',  45),
(3,6,N'Domates Çorbası',   40),
(3,6,N'Tavuk Suyu Çorbası',50),
-- Tokyo Sushi (RestoranId=4, MenuKat 7=Sushi, 8=Miso)
(4,7,N'Salmon Roll (8 parça)',  180),
(4,7,N'Tuna Roll (8 parça)',    190),
(4,7,N'California Roll',        165),
(4,7,N'Dragon Roll',            210),
(4,7,N'Rainbow Roll',           220),
(4,7,N'Ebi Tempura',            195),
(4,7,N'Sashimi Tabağı',         250),
(4,8,N'Miso Çorbası',            45),
(4,8,N'Edamame',                 55),
(4,8,N'Gyoza',                   85),
-- Döner Express (RestoranId=5, MenuKat 9=Dönerler, 10=Yanlar)
(5,9,N'Tavuk Döner Dürüm',     95),
(5,9,N'Et Döner Dürüm',       115),
(5,9,N'Karışık Döner Dürüm',  120),
(5,9,N'İskender Döner',       145),
(5,9,N'Tombik Pide',           90),
(5,9,N'Lahmacun',              65),
(5,10,N'Cacık',                30),
(5,10,N'Turşu',                20),
(5,10,N'Ayran',                15),
(5,10,N'Şalgam',               15);
GO

-- Kuryeler
INSERT INTO Kuryeler (KullaniciId, AracTipi) VALUES
(7, N'Motorsiklet'),
(8, N'Bisiklet'),
(9, N'Motorsiklet');
GO

-- İhtiyaç Sahibi Doğrulaması (müşteri 9,10 → ihtiyaç sahibi)
INSERT INTO IhtiyacSahibiDogrulamasi (KullaniciId, OnayDurumu, OnaylayanAdminId, OnayTarihi, Aciklama) VALUES
(18, 'Onaylandi', 1, DATEADD(DAY,-10,GETDATE()), N'Belgeleri doğrulandı'),
(19, 'Onaylandi', 1, DATEADD(DAY,-8,GETDATE()),  N'Sosyal hizmet onayı var'),
(20, 'Beklemede', NULL, NULL, N'Başvuru inceleniyor');
GO

-- Askıda Yemek Bağışları (trigger havuzu otomatik günceller)
INSERT INTO AskidaBagislar (HavuzId, BagisciKullaniciId, BagistuTL, AnonymMu, Mesaj) VALUES
(1, 9,  150.00, 0, N'Hayırlı olsun'),
(1, 10, 200.00, 1, NULL),
(1, 11, 100.00, 0, N'Herkese yardım'),
(1, 12, 250.00, 1, NULL),
(1, 13,  75.00, 0, N'Güzel bir platform'),
(1, 14, 300.00, 1, NULL),
(1, 15, 125.00, 0, N'İyi dileklerimle'),
(1, 16,  80.00, 1, NULL),
(1, 17,  50.00, 0, N'Küçük bir katkı'),
(1, 18, 170.00, 0, N'Başarılar');
GO

-- Siparişler: 100 kayıt (SET IDENTITY_INSERT kapalı, IDENTITY kullanılıyor)
-- Müşteriler: KullaniciId 9-28 (20 müşteri), Adresler de aynı sırayla oluştu
-- Restoranlar: 1-5, Ürünler: 1-50

DECLARE @i INT = 1;
DECLARE @musteriId INT, @restoranId INT, @urunId INT, @adresId INT;
DECLARE @durum NVARCHAR(20), @odemeTipi NVARCHAR(20), @tutar DECIMAL(10,2);
DECLARE @tarih DATETIME;

WHILE @i <= 100
BEGIN
    SET @musteriId  = 9 + ((@i-1) % 20);     -- KullaniciId 9..28
    SET @restoranId = 1 + ((@i-1) % 5);       -- RestoranId 1..5
    SET @urunId     = 1 + ((@i-1) % 50);      -- UrunId 1..50
    SET @adresId    = @musteriId - 8;          -- AdresId 1..20 (müşteri sırasıyla)
    SET @tarih      = DATEADD(DAY, -(@i % 45), GETDATE());

    SET @durum = CASE
        WHEN @i % 5 = 0 THEN 'TeslimEdildi'
        WHEN @i % 5 = 1 THEN 'TeslimEdildi'
        WHEN @i % 5 = 2 THEN 'Hazirlaniyor'
        WHEN @i % 5 = 3 THEN 'Onaylandi'
        ELSE 'Iptal'
    END;

    -- İhtiyaç sahipleri (KullaniciId 27,28 = @musteriId 27,28) AskidaYemek kullanır
    SET @odemeTipi = CASE
        WHEN @musteriId IN (27,28) AND @i % 10 = 0 THEN 'AskidaYemek'
        WHEN @i % 4 = 0 THEN 'KrediKarti'
        WHEN @i % 4 = 1 THEN 'NakitKapida'
        WHEN @i % 4 = 2 THEN 'CuzzdanBakiyesi'
        ELSE 'KrediKarti'
    END;

    SET @tutar = 80 + (@i % 15) * 10;  -- 80..220 arası

    INSERT INTO Siparisler (MusteriId, RestoranId, TeslimatAdresId, Durum, ToplamTutar, OdemeTipi, OlusturmaTarihi)
    VALUES (@musteriId, @restoranId, @adresId, @durum, @tutar, @odemeTipi, @tarih);

    -- Sipariş kalemi
    INSERT INTO SiparisKalemleri (SiparisId, UrunId, Adet, BirimFiyat)
    VALUES (SCOPE_IDENTITY(), @urunId, 1 + (@i % 3), @tutar / (1 + (@i % 3)));

    -- Ödeme kaydı
    INSERT INTO Odemeler (SiparisId, OdemeTipi, Tutar, OdemeTarihi)
    VALUES (SCOPE_IDENTITY()-1+1, @odemeTipi, @tutar, @tarih);

    SET @i = @i + 1;
END;
GO

-- Kurye atamaları (TeslimEdildi olanlar)
INSERT INTO KuryeAtamalari (SiparisId, KuryeId, AtamaTarihi, TeslimZamani)
SELECT s.SiparisId,
       1 + (s.SiparisId % 3),
       DATEADD(MINUTE, 10, s.OlusturmaTarihi),
       DATEADD(MINUTE, 45, s.OlusturmaTarihi)
FROM Siparisler s
WHERE s.Durum = 'TeslimEdildi';
GO

-- Değerlendirmeler (TeslimEdildi siparişlerin yarısı)
INSERT INTO Degerlendirmeler (SiparisId, MusteriId, RestoranId, Puan, Yorum)
SELECT TOP 30
    s.SiparisId, s.MusteriId, s.RestoranId,
    1 + (s.SiparisId % 5),
    N'Çok lezzetliydi!'
FROM Siparisler s
WHERE s.Durum = 'TeslimEdildi'
ORDER BY s.SiparisId;
GO

-- ============================================================
-- ANALİTİK SORGULAR
-- ============================================================

-- SORGU 1: JOIN - Detaylı Sipariş Fişi
-- 5 tablo birleştirilerek sipariş detayları listeleniyor
SELECT
    s.SiparisId,
    s.OlusturmaTarihi,
    m.Ad + ' ' + m.Soyad        AS Musteri,
    r.RestoranAdi,
    u.UrunAdi,
    sk.Adet,
    sk.BirimFiyat,
    sk.Adet * sk.BirimFiyat     AS SatirToplam,
    s.ToplamTutar,
    s.OdemeTipi,
    s.Durum,
    ISNULL(km.Ad + ' ' + km.Soyad, 'Atanmadı') AS KuryeAdi
FROM Siparisler s
INNER JOIN Kullanicilar m       ON s.MusteriId     = m.KullaniciId
INNER JOIN Restoranlar r        ON s.RestoranId     = r.RestoranId
INNER JOIN SiparisKalemleri sk  ON s.SiparisId      = sk.SiparisId
INNER JOIN UrunlerMenusler u    ON sk.UrunId        = u.UrunId
LEFT  JOIN KuryeAtamalari ka    ON s.SiparisId      = ka.SiparisId
LEFT  JOIN Kuryeler ky          ON ka.KuryeId       = ky.KuryeId
LEFT  JOIN Kullanicilar km      ON ky.KullaniciId   = km.KullaniciId
ORDER BY s.SiparisId;
GO

-- SORGU 2: AGREGASYON - Son 30 günde 5+ sipariş alan restoranların ort. sepet tutarı
SELECT
    r.RestoranAdi,
    COUNT(s.SiparisId)       AS ToplamSiparis,
    AVG(s.ToplamTutar)       AS OrtSepetTutar,
    SUM(s.ToplamTutar)       AS ToplamCiro,
    MIN(s.ToplamTutar)       AS MinSepet,
    MAX(s.ToplamTutar)       AS MaxSepet
FROM Siparisler s
INNER JOIN Restoranlar r ON s.RestoranId = r.RestoranId
WHERE s.OlusturmaTarihi >= DATEADD(DAY, -30, GETDATE())
  AND s.Durum <> 'Iptal'
GROUP BY r.RestoranId, r.RestoranAdi
HAVING COUNT(s.SiparisId) > 5
ORDER BY OrtSepetTutar DESC;
GO

-- SORGU 3: ALT SORGU (NOT EXISTS) - Platformu aktif kullanan ama hiç bağış yapmamış müşteriler
SELECT
    k.KullaniciId,
    k.Ad + ' ' + k.Soyad   AS AdSoyad,
    k.Eposta,
    COUNT(s.SiparisId)      AS ToplamSiparisSayisi
FROM Kullanicilar k
INNER JOIN Siparisler s ON k.KullaniciId = s.MusteriId
WHERE k.KullaniciTipi = 'Musteri'
  AND k.IsActive = 1
  AND NOT EXISTS (
      SELECT 1 FROM AskidaBagislar ab
      WHERE ab.BagisciKullaniciId = k.KullaniciId
  )
GROUP BY k.KullaniciId, k.Ad, k.Soyad, k.Eposta
HAVING COUNT(s.SiparisId) >= 3
ORDER BY ToplamSiparisSayisi DESC;
GO

-- SORGU 4: Askıda Yemek son 1 haftada yararlanan kullanıcılar
SELECT
    k.Ad + ' ' + k.Soyad   AS IhtiyacSahibi,
    ak.KullanimTarihi,
    ak.KullanilanTL,
    s.SiparisId,
    r.RestoranAdi
FROM AskidaKullanimi ak
INNER JOIN Kullanicilar k ON ak.KullananKullaniciId = k.KullaniciId
INNER JOIN Siparisler s   ON ak.SiparisId           = s.SiparisId
INNER JOIN Restoranlar r  ON s.RestoranId            = r.RestoranId
WHERE ak.KullanimTarihi >= DATEADD(DAY, -7, GETDATE())
ORDER BY ak.KullanimTarihi DESC;
GO

-- SORGU 5: IN kullanımı - Bağış yapan müşterilerin son siparişleri
SELECT s.SiparisId, s.OlusturmaTarihi, s.ToplamTutar, s.Durum
FROM Siparisler s
WHERE s.MusteriId IN (
    SELECT DISTINCT BagisciKullaniciId
    FROM AskidaBagislar
    WHERE BagisciKullaniciId IS NOT NULL
)
ORDER BY s.OlusturmaTarihi DESC;
GO

-- View'ları test et
SELECT * FROM vw_AktifRestoranMenuleri;
GO
SELECT * FROM vw_AskidaYemekHavuzDurumu;
GO
SELECT TOP 10 * FROM vw_SiparisFisi;
GO

-- ============================================================
-- YAPAY ZEKA (AI) BEYANI
-- ============================================================
-- Bu proje Antigravity (Google DeepMind) AI asistanı kullanılarak geliştirilmiştir.
-- Kullanım alanları:
--   1. Tablo şeması tasarımı ve 3NF uyumluluk doğrulaması
--   2. Trigger mantığının T-SQL sözdiziminde kodlanması
--   3. Mock veri üretimi için WHILE döngüsü tasarımı
--   4. Analitik sorgu optimizasyonu
-- Tüm iş kuralları, tablo isimleri ve ilişkiler öğrenci tarafından gözden geçirilmiş
-- ve savunmaya hazır hale getirilmiştir.
