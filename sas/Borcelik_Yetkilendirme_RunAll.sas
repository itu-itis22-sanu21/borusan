/*==========================================================================
  Borcelik - 05Yetkilendirme : Tüm input ve kural kodlarını toplu çalıştırır
  --------------------------------------------------------------------------
  Çalışma sırası:
    1) /sasdata/Borcelik/05Yetkilendirme/inputs/rule001_input.sas ... rule021_input.sas
    2) /sasdata/Borcelik/05Yetkilendirme/rules/rule001.sas        ... rule021.sas

  Dosya sayısı değişirse sadece &INPUT_COUNT / &RULE_COUNT değerlerini güncelleyin.
==========================================================================*/

/* ---- Ayarlar ---------------------------------------------------------- */
%let BASE_DIR    = /sasdata/Borcelik/05Yetkilendirme;
%let INPUT_DIR   = &BASE_DIR./inputs;
%let RULE_DIR    = &BASE_DIR./rules;
%let INPUT_COUNT = 21;
%let RULE_COUNT  = 21;

/* Varsa ortak autoexec dosyasını buraya ekleyebilirsiniz:
%include "&BASE_DIR./autoexec.sas";
*/

/* ---- Genel sayaç başlat ---------------------------------------------- */
%let _timer_start = %sysfunc(datetime());


/*--------------------------------------------------------------------------
  %run_batch : Aynı isim kalıbındaki dosyaları 001'den N'e kadar sırayla
               %include eder. Numara 3 haneye (001, 002, ...) tamamlanır.

    dir    = dosyaların bulunduğu klasör
    prefix = numaradan önceki kısım   (örn. rule)
    suffix = numaradan sonraki kısım  (örn. _input)  - boş olabilir
    n      = dosya sayısı
    label  = log'da görünecek grup adı

  Not: Süre ölçümü ve durum kontrolü bilerek DATA _NULL_ adımlarıyla
  yapılıyor. %sysfunc(datetime()) gibi makro-seviyesi komutlar, include
  edilen koddaki DATA/PROC adımları henüz çalışmadan değerlendirilebilir;
  DATA _NULL_ ise include edilen koddan sonra, sırası gelince çalışır.
--------------------------------------------------------------------------*/
%macro run_batch(dir=, prefix=, suffix=, n=, label=);
  %local i num file missing;
  %let missing = 0;

  %put NOTE: ================= &label BAŞLIYOR (&n dosya) =================;

  data _null_;
    call symputx('_grp_start', datetime(), 'G');
  run;

  %do i = 1 %to &n;
    %let num  = %sysfunc(putn(&i, z3.));
    %let file = &dir./&prefix.&num.&suffix..sas;

    %if %sysfunc(fileexist(&file)) %then %do;
      /* Dosya başlangıç zamanı */
      data _null_;
        call symputx('_file_start', datetime(), 'G');
      run;

      %put NOTE: >>> Çalıştırılıyor: &file;
      %include "&file";

      /* Önceki adım RUN/QUIT ile kapanmamışsa burada kapansın */
      run; quit;

      /* Dosya süresi + hata kontrolü */
      data _null_;
        dur = datetime() - input(symget('_file_start'), best32.);
        rc  = input(symget('SYSCC'), best32.);
        if rc > 4 then
          put "WARNING: <<< &prefix.&num.&suffix bitti ama SYSCC=" rc "(hata olabilir). Süre: " dur time13.2;
        else
          put "NOTE: <<< &prefix.&num.&suffix bitti. Süre: " dur time13.2;
      run;
    %end;
    %else %do;
      %let missing = %eval(&missing + 1);
      %put WARNING: Dosya bulunamadı, atlanıyor: &file;
    %end;
  %end;

  data _null_;
    dur = datetime() - input(symget('_grp_start'), best32.);
    put 50*'-' / " &label toplam süresi: " dur time13.2
               / " Bulunamayan dosya sayısı: &missing" / 50*'-';
  run;
%mend run_batch;


/* ---- 1) Önce tüm INPUT kodları ---------------------------------------- */
%run_batch(dir=&INPUT_DIR, prefix=rule, suffix=_input, n=&INPUT_COUNT, label=INPUT KODLARI);

/* ---- 2) Sonra tüm KURAL kodları --------------------------------------- */
%run_batch(dir=&RULE_DIR,  prefix=rule, suffix=,       n=&RULE_COUNT,  label=KURAL KODLARI);


/* ---- Genel sayaç durdur ----------------------------------------------- */
data _null_;
  dur = datetime() - &_timer_start;
  put 30*'-' / ' Input + Rule Jobların Toplam Süresi:' dur time13.2 / 30*'-';
run;
