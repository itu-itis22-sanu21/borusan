/*==========================================================================
  Borcelik - 05Yetkilendirme : Tüm input ve kural kodlarını toplu çalıştırır
  --------------------------------------------------------------------------
  Çalışma sırası:
    1) /sasdata/Borcelik/05Yetkilendirme/inputs/rule001_input.sas ... rule0NN_input.sas
    2) /sasdata/Borcelik/05Yetkilendirme/rules/rule001.sas        ... rule0NN.sas

  Dosya sayısı değişirse sadece &INPUT_COUNT / &RULE_COUNT değerlerini güncelleyin.

  GEÇ ÇALIŞAN INPUT'LAR (&LATE_INPUTS):
    Bazı input'lar başka kuralların RESULT tablolarını okur (örn. rule022_input,
    RULE014 ve RULE019 sonuçlarını birleştirir). Bunlar input fazında çalışırsa
    henüz güncellenmemiş (eski çalıştırmadan kalan) tabloları okur. Bu yüzden
    listedeki input'lar input fazında atlanır ve kendi kuralından HEMEN ÖNCE
    çalıştırılır.
==========================================================================*/

/* ---- Ayarlar ---------------------------------------------------------- */
%let BASE_DIR    = /sasdata/Borcelik/05Yetkilendirme;
%let INPUT_DIR   = &BASE_DIR./inputs;
%let RULE_DIR    = &BASE_DIR./rules;
%let INPUT_COUNT = 22;
%let RULE_COUNT  = 22;
%let LATE_INPUTS = 022;   /* boşlukla ayırın, örn: 022 025 */

/* Varsa ortak autoexec dosyasını buraya ekleyebilirsiniz:
%include "&BASE_DIR./autoexec.sas";
*/

/* ---- Hata izolasyonu --------------------------------------------------
  SAS Studio (Viya) kodu batch modunda çalıştırır. Bu modda ilk ERROR'dan
  sonra SAS "syntax check" moduna geçer: OBS=0 + NOREPLACE olur, sonraki
  TÜM adımlar 0 satırla çalışır ve tablolar yazılmaz. Bir kuraldaki hata
  diğer kuralları da bozmasın diye bunu kapatıyoruz.
------------------------------------------------------------------------*/
options nosyntaxcheck obs=max replace;

/* Hata veren dosyaların listesi (en sonda özet olarak basılır) */
%global _failed_list;
%let _failed_list = ;

/* ---- Genel sayaç başlat ---------------------------------------------- */
%let _timer_start = %sysfunc(datetime());


/*--------------------------------------------------------------------------
  %run_one : Tek bir dosyayı %include eder; süresini ve hata durumunu yazar.
             Dosya yoksa çağıran makronun &missing sayacını artırır.

  Not: Süre ölçümü ve durum kontrolü DATA _NULL_ adımlarıyla yapılıyor;
  böylece include edilen koddaki adımlarla aynı sırada çalıştıkları kesin.
  Zaman damgası metne 20.3 formatıyla yazılıyor; varsayılan dönüşüm
  kesirli saniyeyi yuvarladığı için negatif süreler çıkıyordu.
--------------------------------------------------------------------------*/
%macro run_one(file=, tag=);
  %if %sysfunc(fileexist(&file)) %then %do;
    /* Her dosya temiz bir durumla başlasın: önceki dosyanın hatası
       buna taşınmasın ve SYSCC sadece bu dosyanın sonucunu göstersin */
    options nosyntaxcheck obs=max replace;
    %let syscc = 0;

    data _null_;
      call symputx('_file_start', put(datetime(), 20.3), 'G');
    run;

    %put NOTE: >>> Çalıştırılıyor: &file;
    %include "&file";

    /* Önceki adım RUN/QUIT ile kapanmamışsa burada kapansın */
    run; quit;

    data _null_;
      length failed $2000;
      dur = datetime() - input(symget('_file_start'), best32.);
      rc  = input(symget('SYSCC'), best32.);
      if rc > 4 then do;
        put "WARNING: <<< &tag HATA ile bitti (SYSCC=" rc +(-1) "). Süre: " dur time13.2;
        failed = catx(' ', symget('_failed_list'), "&tag");
        call symputx('_failed_list', failed, 'G');
      end;
      else
        put "NOTE: <<< &tag bitti. Süre: " dur time13.2;
    run;
  %end;
  %else %do;
    %let missing = %eval(&missing + 1);   /* çağıranın (%run_batch) sayacı */
    %put WARNING: Dosya bulunamadı, atlanıyor: &file;
  %end;
%mend run_one;


/*--------------------------------------------------------------------------
  %run_batch : Aynı isim kalıbındaki dosyaları 001'den N'e kadar sırayla
               çalıştırır. Numara 3 haneye (001, 002, ...) tamamlanır.

    dir    = dosyaların bulunduğu klasör
    prefix = numaradan önceki kısım   (örn. rule)
    suffix = numaradan sonraki kısım  (örn. _input)  - boş olabilir
    n      = dosya sayısı
    label  = log'da görünecek grup adı
    skip   = bu fazda atlanacak numaralar (örn. 022)
    pre_dir, pre_suffix, pre_list
           = pre_list'teki numaralar için, asıl dosyadan hemen önce
             &pre_dir/&prefix.NNN&pre_suffix..sas dosyası çalıştırılır
--------------------------------------------------------------------------*/
%macro run_batch(dir=, prefix=, suffix=, n=, label=,
                 skip=, pre_dir=, pre_suffix=, pre_list=);
  %local i num missing;
  %let missing = 0;

  %put NOTE: ================= &label BAŞLIYOR (&n dosya) =================;

  data _null_;
    call symputx('_grp_start', put(datetime(), 20.3), 'G');
  run;

  %do i = 1 %to &n;
    %let num = %sysfunc(putn(&i, z3.));

    %if %index(%str( )&skip%str( ), %str( )&num%str( )) %then
      %put NOTE: --- &prefix.&num.&suffix ertelendi (kendi kuralından önce çalışacak);
    %else %do;
      %if %index(%str( )&pre_list%str( ), %str( )&num%str( )) %then
        %run_one(file=&pre_dir./&prefix.&num.&pre_suffix..sas, tag=&prefix.&num.&pre_suffix);
      %run_one(file=&dir./&prefix.&num.&suffix..sas, tag=&prefix.&num.&suffix);
    %end;
  %end;

  data _null_;
    dur = datetime() - input(symget('_grp_start'), best32.);
    put 50*'-' / " &label toplam süresi: " dur time13.2
               / " Bulunamayan dosya sayısı: &missing" / 50*'-';
  run;
%mend run_batch;


/* ---- 1) Önce tüm INPUT kodları (geç çalışanlar hariç) ------------------ */
%run_batch(dir=&INPUT_DIR, prefix=rule, suffix=_input, n=&INPUT_COUNT,
           label=INPUT KODLARI, skip=&LATE_INPUTS);

/* ---- 2) Sonra tüm KURAL kodları (geç input'lar kendi kuralından önce) -- */
%run_batch(dir=&RULE_DIR, prefix=rule, suffix=, n=&RULE_COUNT,
           label=KURAL KODLARI,
           pre_dir=&INPUT_DIR, pre_suffix=_input, pre_list=&LATE_INPUTS);


/* ---- Genel sayaç durdur + hata özeti ---------------------------------- */
options obs=max replace;
data _null_;
  length failed $2000;
  dur    = datetime() - &_timer_start;
  failed = symget('_failed_list');
  put 50*'-' / ' Input + Rule Jobların Toplam Süresi:' dur time13.2;
  if missing(failed) then put ' Tüm dosyalar hatasız çalıştı.';
  else put 'WARNING: Hata veren dosyalar: ' failed;
  put 50*'-';
run;
