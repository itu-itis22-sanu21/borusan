/*==========================================================================
  CLK_YTK_RULE002
  --------------------------------------------------------------------------
  Bu dosya toplu runner ile (Borcelik_Yetkilendirme_RunAll.sas) çalıştığında
  RULE / OUTLIB / BATCH_ID makro değişkenleri bir önceki dosyadan KALMAMALI.
  Bu yüzden hepsi burada, dosyanın kendi içinde tanımlanıyor.
==========================================================================*/

/* 0) PARAMETRELER ------------------------------------------------------- */
%let RULE   = CLK_YTK_RULE002;   /* Eskiden rule001'den kalan değer kullanılıyordu */
%let OUTLIB = BCCIKTI;

/* BATCH_ID: rule001'de nasıl üretiliyorsa AYNISINI buraya koyun.
   Tanımlı değilse yedek olarak datetime() (sayısal) kullanılır; böylece
   "&BATCH_ID." çözülmeden SQL'e girip ERROR 22-322 vermez.
   NOT: RESULT tablosunda BATCH_ID karakter ise değeri tırnakla verin:
        "&BATCH_ID." as BATCH_ID                                         */
%global BATCH_ID;
%if %superq(BATCH_ID) = %then %do;
  %let BATCH_ID = %sysfunc(datetime(), 16.);
%end;
%put NOTE: &RULE çalışıyor. BATCH_ID=&BATCH_ID;

/* 2) ALERTED ROWS: Sadece riskli bulguları ara tabloya taşıyoruz */
data WORK.&RULE._ALERTED_ROWS;
    set WORK.&RULE._ANALYSIS;
run;

/* 3) VERİ TEMİZLİĞİ: Mevcut RESULT tablosunu drop etmeden içini truncate ediyoruz */
proc sql;
    delete from &OUTLIB..&RULE._RESULT;
quit;

/* 4) FINAL RESULT: Standart MD5 Hashing fonksiyonuyla hedef tabloyu besliyoruz */
proc sql;
    insert into &OUTLIB..&RULE._RESULT
    (RULE_HASH, BATCH_ID, Calisan_Adi, Kullanici_Kodu, Kullanici_Yaratma_Tarihi,
     Sifre_Degisiklik_Tarihi, Son_Giris_Tarihi, KILITLENME_DURUMU,
     SIFRE_DEGISIM_DURUMU, GIRIS_YAPILMA_DURUMU, FLAG_RISKLI, ACIKLAMA)
    select distinct
        put(md5(strip(Kullanici_Kodu) || strip(put(Kullanici_Yaratma_Tarihi, yymmddn8.))), $hex32.) as RULE_HASH length=32,
        &BATCH_ID. as BATCH_ID,
        Calisan_Adi,
        Kullanici_Kodu,
        Kullanici_Yaratma_Tarihi,
        Sifre_Degisiklik_Tarihi,
        Son_Giris_Tarihi,
        KILITLENME_DURUMU,
        SIFRE_DEGISIM_DURUMU,
        GIRIS_YAPILMA_DURUMU,
        FLAG_RISKLI,
        ACIKLAMA
    from WORK.&RULE._ALERTED_ROWS;
quit;
