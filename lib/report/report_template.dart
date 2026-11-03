// Elektrik İç Tesisatı Gözle Kontrol ve Fonksiyon Testleri raporunun şablonu.
// Etiketler, seçenekler ve sabit metinler burada; ekranlar ve PDF bu tanımları okur.
// Şablonu değiştirmek için yalnızca bu dosyayı düzenlemek yeterlidir.

class TextFieldDef {
  final String id;
  final String label;
  final String? hint;
  const TextFieldDef(this.id, this.label, {this.hint});
}

class ChoiceFieldDef {
  final String id;
  final String label;
  final List<String> options;
  final bool multi;
  const ChoiceFieldDef(this.id, this.label, this.options, {this.multi = false});
}

class CriterionDef {
  final String id;
  final String label;
  const CriterionDef(this.id, this.label);
}

class CriteriaGroupDef {
  final String title;
  final List<CriterionDef> items;
  const CriteriaGroupDef(this.title, this.items);
}

class ReportTemplate {
  static const String headerLine1 = 'ELEKTRİK İÇ TESİSATI';
  static const String headerLine2 = 'GÖZLE KONTROL VE FONKSİYON TESTLERİ';
  static const String headerLine3 = 'Periyodik Kontrol Raporu';

  // ---- 1. FİRMA BİLGİLERİ ----
  static const firmaFields = [
    TextFieldDef('firmaAdi', 'Firma Adı'),
    TextFieldDef('adres', 'Periyodik Kontrol Adresi'),
    TextFieldDef('sgkSicil', 'SGK Sicil Numarası'),
    TextFieldDef('isgKatipId', 'İSG-KÂTİP Sözleşme ID'),
  ];

  static const String kontrolKapsami =
      '●TS HD 60364-4-43 Alçak Gerilim Elektrik Tesisatları-Bölüm 4: Güvenlik İçin Koruma-Grup 43: '
      'Aşırı Akıma Karşı Koruma, ●TS HD 60364-6 Alçak Gerilim Elektrik Tesisatları-Bölüm 6: Doğrulama, '
      '●İş Ekipmanlarının Kullanımında Sağlık ve Güvenlik Şartları Yönetmeliği, ●Elektrik İç Tesisleri '
      'Yönetmeliği ●Elektrik Tesislerinde Topraklamalar Yönetmeliği.';

  // ---- 2. EKİPMAN BİLGİLERİ ----
  static const yapiCinsi = ChoiceFieldDef('yapiCinsi', 'Yapı Cinsi', ['EV', 'TİCARİ', 'ENDÜSTRİ', 'DİĞER']);
  static const topraklayiciTipi =
      ChoiceFieldDef('topraklayiciTipi', 'Topraklayıcı Tipi', ['RİNG', 'TEMEL', 'YÜZEYSEL', 'BELİRLENEMEDİ', 'DERİN']);
  static const projeVar = ChoiceFieldDef('projeVar', 'Tesise Ait Proje Var Mı?', ['VAR', 'YOK']);
  static const kontrolNedeni = ChoiceFieldDef('kontrolNedeni', 'Kontrol Nedeni', ['PERİYODİK', 'İLK KONTROL']);
  static const tekHatVar = ChoiceFieldDef('tekHatVar', 'Tek Hat Şeması Var Mı?', ['VAR', 'YOK']);
  static const fazIletken = ChoiceFieldDef(
      'fazIletken',
      'Faz İletkenlerinin Sayısı ve Tipi',
      [
        'AA',
        '1 FAZ-2 TEL',
        '1 FAZ-3 TEL',
        '2 FAZ-3 TEL',
        '3 FAZ-3 TEL',
        '3 FAZ-4 TEL',
        'DA',
        '2 KUTUP',
        '3 KUTUP',
        'DİĞER'
      ],
      multi: true);
  static const sebekeTipi =
      ChoiceFieldDef('sebekeTipi', 'Şebeke Tipi', ['TT', 'IT', 'TN', 'TN-C-S', 'TN-C', 'TN-S'], multi: true);

  static const ekipmanFields = [
    TextFieldDef('sebekeGerilimi', 'Şebeke Gerilimi', hint: '380 V / 220 V'),
    TextFieldDef('enerjiKurulusu', 'Enerji Sağlayan Kuruluş'),
    TextFieldDef('sonKontrolTarihi', 'Son Kontrol Tarihi'),
    TextFieldDef('kullanimAmaci', 'Ekipmanın Kullanım Amacı'),
    TextFieldDef('sistemTopraklama', 'Sistem Topraklama İletkeni ve Kesiti (mm2)'),
    TextFieldDef('ilaveElektrot', 'İlave Topraklama Elektrodu Detayları'),
    TextFieldDef('anaEspotansiyel', 'Ana Eşpotansiyel İletkeni ve Kesiti (mm2)'),
    TextFieldDef('temelTopraklamaDirenci', 'Temel Topraklama Direnci (Ω)'),
    TextFieldDef('anaRcdTest', 'TT-TNS Şebeke İçin Ana RCD (Artık Akım Anahtarı) Test Akımı (mA) ve Test Süresi (ms)'),
    TextFieldDef('anaRcdAnma', 'TT-TNS Şebeke İçin Ana RCD (Artık Akım Anahtarı) Anma Akımı (A)'),
    TextFieldDef('anaKesiciNominal', 'Nominal Akımı (A)'),
    TextFieldDef('anaKesiciTipi', 'Tipi'),
    TextFieldDef('beslemeGerilim', 'Nominal Gerilimi U/U0 (kV)', hint: '0,40 / 0,23'),
    TextFieldDef('beslemeFrekans', 'Nominal Frekansı f(1) (Hz)', hint: '50'),
    TextFieldDef('hataAkimi', 'Hata Akım Olasılığı IF (kA)'),
    TextFieldDef('disCevrimEmpedansi', 'Dış Çevrim Empedansı ZE (Ω)'),
  ];

  static const dokunmaOnlemleri = ChoiceFieldDef(
      'dokunmaOnlemleri',
      'Tespit Edilen Bilgiler (Doğrudan Dokunmaya Karşı Koruma Önlemleri)',
      [
        'MAHFAZA (IPXY, PANO KİLİDİ, TEHLİKE İŞARETİ VB.)',
        'EL ULAŞMA UZAKLIĞI DIŞINA YERLEŞTİRME',
        '30 mA ARTIK AKIM ANAHTARI (5XI İÇİN 40 MS AÇMA ZAMANI); DEVRE KESİCİSİ <32 A DEVRELER İÇİN (TS HD 60364-4-41)',
        'GERİLİM ALTINDAKİ BÖLÜMLERİN YALITILMASI (İÇ KAPAK VEYA PLEKSİ KORUMA)',
        'İLAVE KORUMA',
        'ENGEL',
      ],
      multi: true);
  static const oncekiEtiket =
      ChoiceFieldDef('oncekiEtiket', 'Bir Önceki Periyodik Kontrol Etiketi Var Mı?', ['VAR', 'YOK']);
  static const kapsamliDegisiklik =
      ChoiceFieldDef('kapsamliDegisiklik', 'Tesisatta Kapsamlı Değişiklik Var Mı? (>%20)', ['VAR', 'YOK']);
  static const spdVar =
      ChoiceFieldDef('spdVar', 'Tesisatta Aşırı Gerilim Koruma Cihazları (DKD/SPD) Kullanılmış Mı?', ['EVET', 'HAYIR']);

  static const allChoiceFields = [
    yapiCinsi,
    topraklayiciTipi,
    projeVar,
    kontrolNedeni,
    tekHatVar,
    fazIletken,
    sebekeTipi,
    dokunmaOnlemleri,
    oncekiEtiket,
    kapsamliDegisiklik,
    spdVar,
  ];

  // ---- 5. KONTROL KRİTERLERİ VE TESTLER ----
  static const criteriaGroups = [
    CriteriaGroupDef('Pano ve Diğer Donanımlara Girişin Uygunluğu', [
      CriterionDef('kabloSebeke', 'Kablo şebeke tarafı'),
      CriterionDef('kabloDonanim', 'Kablo donanım tarafı'),
      CriterionDef('panoSabitleme', 'Pano sabitlenmesi (depreme dayanıklılık)'),
      CriterionDef('yabanciMalzeme', 'Elektrik panosu etrafında yabancı malzemeler'),
      CriterionDef('disDarbe', 'Dış darbelere karşı koruma önlemi'),
      CriterionDef('zeminIzolasyonu', 'Zemin izolasyonu'),
    ]),
    CriteriaGroupDef(
        'Topraklanmış Potansiyel Dengeleme ve Beslemenin Otomatik Kesilmesi, Elektrik Çarpmasına (Dolaylı Dokunmaya) Karşı Koruma',
        [
          CriterionDef('topraklamaIletkeni', 'Topraklama iletkeni'),
          CriterionDef('kapakBaglantisi', 'Pano kapak bağlantısı kontrolü 6 mm2'),
          CriterionDef('anaPotansiyel', 'Ana potansiyel dengeleme iletkeni'),
          CriterionDef('ekPotansiyel', 'Ek potansiyel dengeleme iletkeni (tamamlayıcı potansiyel dengeleme)'),
        ]),
    CriteriaGroupDef('Karşılıklı Zararlı Etkilerin Önlenmesi', [
      CriterionDef('guvenlikAyrilmasi', 'Güvenlik devre ayrılması'),
      CriterionDef('elektrikselOlmayan', 'Elektriksel olmayan tesislere yaklaşma ve diğer etkilerin kontrolü'),
      CriterionDef('bantAyrilmasi', 'Bant I ve bant II ayrılması, bant II yalıtımı'),
      CriterionDef('icKapak', 'Pano iç kapak, faza erişim engeli veya pleksi koruma'),
    ]),
    CriteriaGroupDef('Tanımlama', [
      CriterionDef('semalar', 'Şemalar, talimatlar, devre çizimleri ve kısa bilgiler'),
      CriterionDef('etiketler', 'Koruma cihaz ve terminal etiket'),
      CriterionDef('tehlikeIsaretleri', 'Tehlike işaretleri ve diğer uyarı işaretleri'),
      CriterionDef('eked', 'EKED iletişim bilgileri'),
    ]),
    CriteriaGroupDef('Kablo ve İletkenler', [
      CriterionDef('tesisatYontemi', 'Tesisat yöntemi'),
      CriterionDef('renkKodlari', 'Kablo renk kodları nötr: mavi, toprak: sarı/yeşil'),
      CriterionDef('kabloYollari', 'Kablo yollarının uygunluğu ve mekanik koruma'),
      CriterionDef('yanginEngeli', 'Yangın engeli, uygun kilitleme ve sıcaklık etkisine karşı koruma'),
    ]),
    CriteriaGroupDef('Termal Kamera', [
      CriterionDef('kontakGevsekligi', 'Kontak gevşekliği ısınması'),
      CriterionDef('asiriYuk', 'Aşırı yük ısınması PVC kablolar için > 70 derece'),
    ]),
    CriteriaGroupDef('Genel Değerlendirmeler', [
      CriterionDef('temizlik', 'Ekipman temizlik/bakım durumu'),
      CriterionDef('yanginSondurme', 'Ekipman yakınında elektriksel ekipman yangın söndürme tertibatı'),
      CriterionDef('korozyon', 'Pano içi ve bağlantılarının korozyon kontrolü'),
      CriterionDef('acilAydinlatma', 'Ekipman içi veya yakınında acil durum aydınlatma tertibatı'),
    ]),
  ];

  static List<CriterionDef> get allCriteria => [for (final g in criteriaGroups) ...g.items];

  // ---- 6. FONKSİYON TESTLERİ ----
  static const olcumMetodu = ChoiceFieldDef(
      'olcumMetodu', 'Ölçüm ve Doğrulama Metodu', ['ÜÇ UÇLU TOPRAKLAMA', 'ÇEVRİM EMPEDANSI', 'KLAMP METODU']);

  static const curveOptions = ['B', 'C', 'D', 'K', 'Z', 'TMŞ', 'NH', 'ŞALTER'];
  static const poleOptions = ['1', '2', '3', '4'];

  // ---- 9. NOTLAR ----
  static const String notlar =
      'Elektrik tesisatının projesinin ve uygulamasının, ilgili yönetmelik ve standartlara asgari uygunluğunun '
      'denetimi için hazırlanan bu rapor; açık adresi yukarıda belirtilen firmanın bulunduğu binalar ve ek '
      'bileşenler kısmını kapsamakta olup, proje müellifine ait sorumlulukları kapsamaz. Kanal ve borular '
      'içindeki kablolar, döşenme, tavan boşluklarındaki, bina bünyesindeki, toprak altındaki kablolar ve '
      'borular gözlenmemiştir. İzolasyon halısının en elverişsiz yerlerine 270 mm x 270 mm\'lik bir ıslak bez '
      'serildi. Bu bez üzerine 250 mm x 250 mm x 2 mm boyutlu bir metal levha kondu üstüne tahta levha ve '
      'yaklaşık 75 kg\'lık bir ağırlıkla yüklendi ve zemin izolasyonunun testi gerçekleştirildi. Hesaplanan 3 '
      'fazlı kısa devre akımı (Ik) projede hesaplanmadığı kısımlarda faz-faz arası çevrim empedansı kısa devre '
      'ölçümü ile tespit edilmiştir.';

  // ---- 10. SONUÇ VE KANAAT ----
  static String sonucMetni({required bool uygun, required String sonrakiTarih}) =>
      'Periyodik kontrol tarihi itibari ile yukarıda teknik özellikleri belirtilen ELEKTRİK TESİSATI’nın GÖZLE '
      'KONTROL VE FONKSİYON TESTLERİ muayenesi sonrasında mevcut şartlar altında kullanımı '
      '${uygun ? 'UYGUNDUR' : 'UYGUN DEĞİLDİR'}. Normal şartlarda bir sonraki periyodik kontrol tarihi '
      '$sonrakiTarih’dir.';

  static const String agirKusurTanimlari =
      'Ağır kusur tanımları: Gözle Kontrol Bölümü 1. Faza erişim engeli IP2X koruma sınıfını sağlamıyorsa, 2. '
      'Kablo ek noktaları yalıtımlı değilse, pano içinde ucu açıkta iletken varsa, 3. Pano elemanları bağlantı '
      'noktalarında kontak gevşekliği (seri ark) tespit edilmişse, 4. PVC izoleli kablolarda ve pano '
      'elemanlarının dokunulabilen metal olmayan yüzeylerinde aşırı ısınma tespit edilmişse. Fonksiyon Testleri '
      'Bölümü 1. Hesaplanan 3 fazlı kısa devre akımı, pano içinde bulunan herhangi bir aşırı akım koruma cihazı '
      'etiketinde yazan kısa devre kesme kapasitesinden (Icu) fazla ise, 2. Aşırı akım koruma elemanı değerleri '
      'linye kesiti ile uyumsuz ise, 3. El ulaşma mesafesindeki metal bölümler, ekipmanın toprak barası veya '
      'toprak ucuyla eş potansiyel değilse, 4. AAA performans testi sonuçları yetersiz ise, 5. Kablo şalter '
      'koordinasyonunun aşağıdaki uygunsuzluğu; Devre Tasarım Akımı (Ib), Devre Kesici Akımı (In) ve Kablo Akım '
      'Taşıma Kapasitesi (Iz) için Ib<In<Iz sağlanmadıysa, 6. Zemin yalıtımının aşağıdaki uygunsuzlukları; a) El '
      'ulaşma mesafesinde bulunan zemin izolasyonu uygun boyutta değilse, (EİTY Md. 33d) b) Zemin izolasyon '
      'direnci 50 kΩ’dan büyük değilse, (EİTY Md. 48) 7. N/PEN iletkeni kesitinin ve kullanım yerinin aşağıdaki '
      'uygunsuzlukları; a) N/PEN kesiti ile faz iletkeni kesiti eşit değilse. (EİTY Md 57b3-ii-1) İstisna: N/PEN '
      'kesitinin faz iletkeninin kesitinden küçük olması durumunda (örneğin 3x70+35 mm2 gibi) faz iletkenlerini '
      'koruyan devre kesici anma akımının ve N/PEN iletkeni kesitine göre (örnekteki 35mm2’ye göre) belirlenmesi '
      'kuralı ihlal edildiyse, (EİTY Md 57b3-ii-2) b) PEN iletkeni kesiti >10 mm2 değilse, (EİTY Md 36) c) PEN '
      'iletkeni yangın tehlikesi olan yerlerden geçirilmemesi kuralı ihlal edildiyse, (EİTY Md 64) d) PEN '
      'iletkeni Exproof tehlikeli bölge sınırları içinden geçirilmemesi kuralı ihlal edildiyse, (IEC 60079-14) 8. '
      'PE koruma iletkeni kesitinin aşağıdaki uygunsuzluğu; Koruma iletkeni kesiti ETTY Md. 9e1i’de verilen '
      'formülle yapılan hesap sonucuna ve ETTY Çizelge 8’de verilen tabloya uygun değilse, 9. PD potansiyel '
      'dengeleme iletkeni kesitinin aşağıdaki uygunsuzluğu; 6 mm2 ≤ PD ≤ 25 mm2 değilse, 10. Tamamlayıcı '
      'potansiyel dengeleme: PD ≥ 4mm² değilse. Ağır kusur olarak değerlendirilir. TS HD 60364 standardına göre '
      'kullanımı uygun olmayan tesisatlar aşağıdaki şekilde işaretlenir: C1 - Tehlike mevcut. Yaralanma riski. '
      'Derhal düzeltici eylem gerekli. C2 - Potansiyel olarak tehlikeli - acil düzeltici eylem gerekli. C3 - '
      'İyileştirme önerilir. Bu rapor “Alçak Gerilim Topraklama Tesisatı Kontrol Raporu” ile birlikte geçerlidir.';

  /// Görev ayarlarında kontrol firması boş bırakılırsa altbilgide kullanılır (Word şablonundaki firma).
  static const String defaultKontrolFirmasiEkli = 'DİNAMİK MÜHENDİSLİK’in';

  // kontrolFirmasiEkli: firmanın ekli hali, örn. "DİNAMİK MÜHENDİSLİK’in" (Türkçe ek firmaya göre değişir).
  static String footerMetni(String kontrolFirmasiEkli) =>
      '“-”: Tespit edilemeyen bilgi anlamında kullanılmaktadır. Kusur derecesi “*” hafif kusurlu ve “**” ağır '
      'kusurlu anlamında kullanılmaktadır. Değerlendirme “UYGUN”, “UYGUN DEĞİL” ve “UYGULANAMAZ” olarak '
      'yapılmıştır. Bu rapor hizmet verilen işyerinde kontrolü yapılan ekipman için mevcut şartlar altında '
      'geçerlidir. Bu Rapor $kontrolFirmasiEkli yazılı izni olmadan kısmen veya tamamen kopyalanıp çoğaltılamaz.';

  static const String nushaMetni = 'Bu rapor bir (1) nüsha olarak hazırlanmıştır.';
}
