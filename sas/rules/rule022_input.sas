/* =======================================================
   YTK_RULE022 - INPUT (BORÇELİK)
   Amaç: Kural 14 ve Kural 19 RESULT tablolarının kesişimi
   Kaynak: BCCIKTI.CLK_YTK_RULE014_RESULT & BCCIKTI.CLK_YTK_RULE019_RESULT
   Çıktı: WORK.CLK_YTK_RULE022_INPUT

   DİKKAT: Bu input KURAL 14 ve 19'un sonuçlarını okur. Toplu runner'da
   &LATE_INPUTS listesinde olduğu için input fazında değil, rule022.sas'tan
   hemen önce (rule014 ve rule019 bittikten sonra) çalıştırılır.
   ======================================================= */

%let RULE=CLK_YTK_RULE022;
%let OUTLIB=BCCIKTI;
%let BATCH_ID=1;

proc sql;
  create table &RULE._INPUT as
  select distinct
      r14.UNAME,

      /* Kural 14 RESULT Tablosundan Gelenler */
      r14.TCODE        as TCODE_SU01 length=20,
      r14.ROL_SU01     length=50,
      r14.ROL_USER_AGR as ROL_K14_YETKI length=50,

      /* Kural 19 RESULT Tablosundan Gelenler */
      r19.TCODE        as TCODE_PFCG length=20,
      r19.ROL_PFCG     length=50,
      r19.ROL_YETKI    as ROL_K19_YETKI length=50,
      r19.OBJECT       as K19_OBJECT length=50

  from &OUTLIB..CLK_YTK_RULE014_RESULT as r14
  inner join &OUTLIB..CLK_YTK_RULE019_RESULT as r19
    on r14.UNAME = r19.UNAME;
quit;
