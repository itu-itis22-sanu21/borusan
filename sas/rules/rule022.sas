/* =======================================================
   YTK_RULE022 - FINAL CONSOLIDATED VERSION (BORÇELİK)
   INPUT : WORK.CLK_YTK_RULE022_INPUT
   OUTPUT: BCCIKTI.CLK_YTK_RULE022_RESULT
   ======================================================= */

/* 0) PARAMETRELER
   Toplu runner'da RULE bir önceki dosyadan (rule021) kalıyordu; bu yüzden
   aşağıdaki adımlar CLK_YTK_RULE021 tablolarını silip bozuyordu.
   Her kural dosyası kendi parametrelerini kendisi tanımlamalı. */
%let RULE   = CLK_YTK_RULE022;
%let OUTLIB = BCCIKTI;
%global BATCH_ID;
%if %superq(BATCH_ID) = %then %do;
  %let BATCH_ID = 1;              /* rule022_input.sas ile aynı değer */
%end;

/* 1) TABLOYU ZORLA TEMİZLE */
proc datasets lib=&OUTLIB. nolist;
   delete &RULE._RESULT;
run;
quit;

/* 2) INPUT VERİSİNİ HAZIRLA VE AÇIKLAMAYI YAZ */
data &RULE._ALERTED_ROWS;
  set &RULE._INPUT;

  FLAG_RISKLI = 1;
  length ACIKLAMA $400;

  ACIKLAMA = catx(' ',
      "KRİTİK SOD: Kullanıcı hem hesap açma (SU01) hem de",
      strip(K19_OBJECT),
      "objesi üzerinden rol/profil yönetimi (PFCG) yetkisine sahiptir."
  );
run;

/* 3) RESULT TABLOSUNU DOĞRU ŞABLONLA OLUŞTUR */
proc sql;
   create table &OUTLIB..&RULE._RESULT (
     RULE_HASH     char(32),
     BATCH_ID      num,
     UNAME         char(50),
     TCODE_SU01    char(20),
     TCODE_PFCG    char(20),
     ROL_SU01      char(50),
     ROL_PFCG      char(50),
     ROL_K14_YETKI char(50),
     ROL_K19_YETKI char(50),
     K19_OBJECT    char(50),
     FLAG_RISKLI   num,
     ACIKLAMA      char(400)
   );
quit;

/* 4) OUTPUT + HASH OLUŞTURMA
   catx('|', ...) : strip + birleştirme tek fonksiyonda; ayraç sayesinde
   "AB"+"C" ile "A"+"BC" aynı hash'i üretmez. */
proc sql;
  create table &RULE._OUTPUT as
  select distinct
      put(md5(catx('|', UNAME, ROL_SU01, ROL_PFCG, K19_OBJECT)), $hex32.) as RULE_HASH length=32,
      &BATCH_ID. as BATCH_ID,
      UNAME,
      TCODE_SU01,
      TCODE_PFCG,
      ROL_SU01,
      ROL_PFCG,
      ROL_K14_YETKI,
      ROL_K19_YETKI,
      K19_OBJECT,
      FLAG_RISKLI,
      ACIKLAMA
  from &RULE._ALERTED_ROWS;
quit;

/* 5) VERİYİ HEDEF TABLOYA GÜVENLİ ŞEKİLDE AKTAR */
proc sql;
  insert into &OUTLIB..&RULE._RESULT
    (RULE_HASH, BATCH_ID, UNAME, TCODE_SU01, TCODE_PFCG, ROL_SU01, ROL_PFCG,
     ROL_K14_YETKI, ROL_K19_YETKI, K19_OBJECT, FLAG_RISKLI, ACIKLAMA)
  select
    RULE_HASH, BATCH_ID, UNAME, TCODE_SU01, TCODE_PFCG, ROL_SU01, ROL_PFCG,
    ROL_K14_YETKI, ROL_K19_YETKI, K19_OBJECT, FLAG_RISKLI, ACIKLAMA
  from &RULE._OUTPUT;
quit;
