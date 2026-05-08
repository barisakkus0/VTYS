# İş Kuralları — Yemek Sipariş Platformu

## Kullanıcı
- IK-01: Tüm aktörler tek `Kullanicilar` tablosunda, `KullaniciTipi` ile ayrılır.
- IK-02: E-posta ve telefon UNIQUE + NOT NULL.
- IK-03: Soft Delete: `IsActive = 0`.

## Restoran & Menü
- IK-04: Ürün fiyatı > 0 (CHECK).
- IK-05: Kaldırılan ürün `IsActive = 0` yapılır, silinmez.

## Sipariş
- IK-06: Durum akışı: Beklemede→Onaylandi→Hazirlaniyor→YoldaKurye→TeslimEdildi.
- IK-07: ToplamTutar > 0 (CHECK), Adet > 0 (CHECK).
- IK-08: Her durum değişikliği `SiparisDurumGecmisi`'ne loglanır.

## Askıda Yemek
- IK-09: Tek global havuz (`AskidaYemekHavuzu`), bakiye < 0 olamaz.
- IK-10: Bağış tutarı > 0 (CHECK). Anonim bağış desteklenir.
- IK-11: Bağış anında T2 trigger havuz bakiyesini artırır.
- IK-12: Kullanım için `IhtiyacSahibiDogrulamasi.OnayDurumu = 'Onaylandi'` şarttır.
- IK-13: Sipariş TeslimEdildi→T1 trigger bakiyeyi düşürür + AskidaKullanimi kaydı oluşturur.

## Ödeme
- IK-14: Yöntemler: KrediKarti, NakitKapida, CuzzdanBakiyesi, AskidaYemek.
