/* =========================================================
   CLK_YTK_RULE002 - TÜM KULLANICILAR İÇİN ŞİFRE KONTROLÜ
   Kaynak: BCETL.USR02
   Çıktı : WORK.CLK_YTK_RULE002_ANALYSIS
           (kural dosyası rules/rule002.sas bunu okuyup
            BCCIKTI.CLK_YTK_RULE002_RESULT tablosuna yazar)
   ========================================================= */

%let RULE=CLK_YTK_RULE002;
%let OUTLIB=BCCIKTI;
%let BATCH_ID=1;

/* 1) GİRDİ VE MANTIK: Veriyi çekip analiz ediyoruz */
data WORK.&RULE._ANALYSIS;
    set BCETL.USR02;

    /* Kolon Eşlemeleri */
    Calisan_Adi = BNAME;
    Kullanici_Kodu = BNAME;
    Kullanici_Yaratma_Tarihi = ERDAT;
    Sifre_Degisiklik_Tarihi = PWDCHGDATE;
    Son_Giris_Tarihi = TRDAT;

    /* Teknik Analiz Kolonları */
    KULLANICI_GECERLILIK_TARIHI = GLTGB;
    SIFRE_KILITLENME_TARIHI = PWDLOCKDATE;

    length KILITLENME_DURUMU $15 SIFRE_DEGISIM_DURUMU $50 GIRIS_YAPILMA_DURUMU $30 ACIKLAMA $200;

    /* A. Kilitlenme Durumu */
    if not missing(PWDLOCKDATE) then KILITLENME_DURUMU = "KILITLI";
    else KILITLENME_DURUMU = "AKTIF";

    /* B. Şifre Değişim Durumu */
    if not missing(PWDCHGDATE) and not missing(PWDLOCKDATE) and PWDCHGDATE >= PWDLOCKDATE then
        SIFRE_DEGISIM_DURUMU = "KİLİTLENDİKTEN SONRA ŞİFRE DEĞİŞTİ";
    else if not missing(PWDLOCKDATE) then
        SIFRE_DEGISIM_DURUMU = "KİLİTLENDİKTEN SONRA ŞİFRE DEĞİŞMEDİ";
    else
        SIFRE_DEGISIM_DURUMU = "KİLİT YOK";

    /* C. Giriş Yapılma Durumu */
    if not missing(TRDAT) and not missing(PWDLOCKDATE) and TRDAT >= PWDLOCKDATE then
        GIRIS_YAPILMA_DURUMU = "GİRİŞ YAPILDI";
    else if not missing(PWDLOCKDATE) then
        GIRIS_YAPILMA_DURUMU = "GİRİŞ YAPILMAMIŞ";
    else
        GIRIS_YAPILMA_DURUMU = "KİLİT YOK";

    /* D. RİSK ANALİZİ */
    FLAG_RISKLI = 0;
    ACIKLAMA = "";

    if KILITLENME_DURUMU = "KILITLI" and
       SIFRE_DEGISIM_DURUMU = "KİLİTLENDİKTEN SONRA ŞİFRE DEĞİŞMEDİ" and
       GIRIS_YAPILMA_DURUMU = "GİRİŞ YAPILDI" then do;
        FLAG_RISKLI = 1;
        ACIKLAMA = "Kilitli kullanıcı şifre değiştirmeden tekrar giriş yapmış.";
    end;
    else if missing(PWDCHGDATE) or PWDCHGDATE <= ERDAT then do;
        FLAG_RISKLI = 1;
        ACIKLAMA = "Jenerik kullanıcının şifresi hiç değiştirilmemiş veya varsayılan kalmış.";
    end;

    /* Formatlar */
    format Kullanici_Yaratma_Tarihi Sifre_Degisiklik_Tarihi Son_Giris_Tarihi date9.;

    keep Calisan_Adi Kullanici_Kodu Kullanici_Yaratma_Tarihi Sifre_Degisiklik_Tarihi
         Son_Giris_Tarihi KILITLENME_DURUMU SIFRE_DEGISIM_DURUMU GIRIS_YAPILMA_DURUMU
         FLAG_RISKLI ACIKLAMA;
run;
