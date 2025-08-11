import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class HospitalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Türkiye'deki iller listesi
  static List<String> getProvinces() {
    return [
      'Adana',
      'Adıyaman',
      'Afyonkarahisar',
      'Ağrı',
      'Amasya',
      'Ankara',
      'Antalya',
      'Artvin',
      'Aydın',
      'Balıkesir',
      'Bilecik',
      'Bingöl',
      'Bitlis',
      'Bolu',
      'Burdur',
      'Bursa',
      'Çanakkale',
      'Çankırı',
      'Çorum',
      'Denizli',
      'Diyarbakır',
      'Edirne',
      'Elazığ',
      'Erzincan',
      'Erzurum',
      'Eskişehir',
      'Gaziantep',
      'Giresun',
      'Gümüşhane',
      'Hakkâri',
      'Hatay',
      'Isparta',
      'Mersin',
      'İstanbul',
      'İzmir',
      'Kars',
      'Kastamonu',
      'Kayseri',
      'Kırklareli',
      'Kırşehir',
      'Kocaeli',
      'Konya',
      'Kütahya',
      'Malatya',
      'Manisa',
      'Kahramanmaraş',
      'Mardin',
      'Muğla',
      'Muş',
      'Nevşehir',
      'Niğde',
      'Ordu',
      'Rize',
      'Sakarya',
      'Samsun',
      'Siirt',
      'Sinop',
      'Sivas',
      'Tekirdağ',
      'Tokat',
      'Trabzon',
      'Tunceli',
      'Şanlıurfa',
      'Uşak',
      'Van',
      'Yozgat',
      'Zonguldak',
      'Aksaray',
      'Bayburt',
      'Karaman',
      'Kırıkkale',
      'Batman',
      'Şırnak',
      'Bartın',
      'Ardahan',
      'Iğdır',
      'Yalova',
      'Karabük',
      'Kilis',
      'Osmaniye',
      'Düzce',
    ];
  }

  // İlçeler
  static Map<String, List<String>> getDistricts() {
    return {
      'İstanbul': ['Şişli', 'Kadıköy', 'Beşiktaş', 'Fatih', 'Üsküdar'],
      'Ankara': ['Çankaya', 'Keçiören', 'Mamak', 'Altındağ', 'Yenimahalle'],
      'İzmir': ['Konak', 'Karşıyaka', 'Bornova', 'Buca', 'Bayraklı'],
      'Adana': ['Seyhan', 'Yüreğir', 'Çukurova'],
      'Adıyaman': ['Merkez', 'Kahta'],
      'Afyonkarahisar': ['Merkez', 'Sandıklı'],
      'Ağrı': ['Merkez', 'Doğubayazıt'],
      'Amasya': ['Merkez', 'Merzifon'],
      'Antalya': ['Muratpaşa', 'Kepez', 'Konyaaltı'],
      'Artvin': ['Merkez', 'Hopa'],
      'Aydın': ['Merkez', 'Kuşadası', 'Nazilli'],
      'Balıkesir': ['Merkez', 'Bandırma'],
      'Bilecik': ['Merkez', 'Bozüyük'],
      'Bingöl': ['Merkez', 'Genç'],
      'Bitlis': ['Merkez', 'Tatvan'],
      'Bolu': ['Merkez', 'Düzce'],
      'Burdur': ['Merkez', 'Bucak'],
      'Bursa': ['Osmangazi', 'Nilüfer', 'Yıldırım'],
      'Çanakkale': ['Merkez', 'Gelibolu'],
      'Çankırı': ['Merkez', 'Çerkeş'],
      'Çorum': ['Merkez', 'Sungurlu'],
      'Denizli': ['Merkez', 'Pamukkale'],
      'Diyarbakır': ['Merkez', 'Bismil'],
      'Edirne': ['Merkez', 'Uzunköprü'],
      'Elazığ': ['Merkez', 'Sivrice'],
      'Erzincan': ['Merkez', 'Üzümlü'],
      'Erzurum': ['Yakutiye', 'Aziziye'],
      'Eskişehir': ['Odunpazarı', 'Tepebaşı'],
      'Gaziantep': ['Şahinbey', 'Şehitkamil'],
      'Giresun': ['Merkez', 'Bulancak'],
      'Gümüşhane': ['Merkez', 'Kelkit'],
      'Hakkâri': ['Merkez', 'Yüksekova'],
      'Hatay': ['Antakya', 'İskenderun'],
      'Isparta': ['Merkez', 'Yalvaç'],
      'Mersin': ['Mezitli', 'Yenişehir', 'Toroslar'],
      'Kars': ['Merkez', 'Sarıkamış'],
      'Kastamonu': ['Merkez', 'Sinop'],
      'Kayseri': ['Kocasinan', 'Melikgazi'],
      'Kırklareli': ['Merkez', 'Lüleburgaz'],
      'Kırşehir': ['Merkez', 'Kaman'],
      'Kocaeli': ['İzmit', 'Gebze'],
      'Konya': ['Selçuklu', 'Meram'],
      'Kütahya': ['Merkez', 'Tavşanlı'],
      'Malatya': ['Battalgazi', 'Yeşilyurt'],
      'Manisa': ['Merkez', 'Akhisar'],
      'Kahramanmaraş': ['Dulkadiroğlu', 'Onikişubat'],
      'Mardin': ['Merkez', 'Kızıltepe'],
      'Muğla': ['Merkez', 'Bodrum', 'Marmaris'],
      'Muş': ['Merkez', 'Bulanık'],
      'Nevşehir': ['Merkez', 'Avanos'],
      'Niğde': ['Merkez', 'Bor'],
      'Ordu': ['Merkez', 'Fatsa'],
      'Rize': ['Merkez', 'Ardeşen'],
      'Sakarya': ['Serdivan', 'Adapazarı'],
      'Samsun': ['İlkadım', 'Canik'],
      'Siirt': ['Merkez', 'Pervari'],
      'Sinop': ['Merkez', 'Boyabat'],
      'Sivas': ['Merkez', 'Suşehri'],
      'Tekirdağ': ['Süleymanpaşa', 'Çorlu'],
      'Tokat': ['Merkez', 'Turhal'],
      'Trabzon': ['Ortahisar', 'Akçaabat'],
      'Tunceli': ['Merkez', 'Mazgirt'],
      'Şanlıurfa': ['Haliliye', 'Eyyübiye'],
      'Uşak': ['Merkez', 'Banaz'],
      'Van': ['İpekyolu', 'Tuşba'],
      'Yozgat': ['Merkez', 'Sorgun'],
      'Zonguldak': ['Merkez', 'Ereğli'],
      'Aksaray': ['Merkez', 'Ortaköy'],
      'Bayburt': ['Merkez', 'Aydıntepe'],
      'Karaman': ['Merkez', 'Ermenek'],
      'Kırıkkale': ['Merkez', 'Delice'],
      'Batman': ['Merkez', 'Kozluk'],
      'Şırnak': ['Merkez', 'Cizre'],
      'Bartın': ['Merkez', 'Amasra'],
      'Ardahan': ['Merkez', 'Göle'],
      'Iğdır': ['Merkez', 'Tuzluca'],
      'Yalova': ['Merkez', 'Çiftlikköy'],
      'Karabük': ['Merkez', 'Safranbolu'],
      'Kilis': ['Merkez', 'Elbeyli'],
      'Osmaniye': ['Merkez', 'Kadirli'],
      'Düzce': ['Merkez', 'Akçakoca'],
    };
  }

  // Hastaneler listesi (örnek veri)
  static List<Map<String, dynamic>> getHospitalsByLocation(
    String province,
    String district,
  ) {
    final List<Map<String, dynamic>> allHospitals = [
      // İstanbul hastaneleri
      {
        'id': 'ist_sisli_1',
        'name': 'Şişli Etfal Eğitim ve Araştırma Hastanesi',
        'province': 'İstanbul',
        'district': 'Şişli',
        'address': 'Halaskargazi Cad. Etfal Sk.',
        'phone': '+90 212 373 50 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 35,
        'capacity': 80,
      },
      {
        'id': 'ist_sisli_2',
        'name': 'Memorial Şişli Hastanesi',
        'province': 'İstanbul',
        'district': 'Şişli',
        'address': 'Piyale Paşa Bulvarı',
        'phone': '+90 212 314 66 66',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 20,
        'capacity': 75,
      },
      {
        'id': 'ist_kadikoy_1',
        'name': 'Dr. Sadi Konuk Eğitim ve Araştırma Hastanesi',
        'province': 'İstanbul',
        'district': 'Kadıköy',
        'address': 'Tevfik Sağlam Cad.',
        'phone': '+90 216 542 20 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 40,
        'capacity': 85,
      },
      {
        'id': 'ist_kadikoy_2',
        'name': 'Acıbadem Kadıköy Hastanesi',
        'province': 'İstanbul',
        'district': 'Kadıköy',
        'address': 'Tekin Sok.',
        'phone': '+90 216 544 44 44',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 25,
        'capacity': 70,
      },
      {
        'id': 'ist_besiktas_1',
        'name': 'Beşiktaş Sait Çiftçi Devlet Hastanesi',
        'province': 'İstanbul',
        'district': 'Beşiktaş',
        'address': 'Ortabahçe Cad.',
        'phone': '+90 212 227 40 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 30,
        'capacity': 78,
      },
      {
        'id': 'ist_besiktas_2',
        'name': 'American Hospital',
        'province': 'İstanbul',
        'district': 'Beşiktaş',
        'address': 'Güzelbahçe Sok.',
        'phone': '+90 212 444 37 77',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 15,
        'capacity': 65,
      },
      {
        'id': 'ist_fatih_1',
        'name': 'İstanbul Üniversitesi Cerrahpaşa Tıp Fakültesi',
        'province': 'İstanbul',
        'district': 'Fatih',
        'address': 'Koca Mustafa Paşa Cad.',
        'phone': '+90 212 414 30 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 45,
        'capacity': 90,
      },
      {
        'id': 'ist_fatih_2',
        'name': 'Haseki Eğitim ve Araştırma Hastanesi',
        'province': 'İstanbul',
        'district': 'Fatih',
        'address': 'Millet Cad.',
        'phone': '+90 212 529 44 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 38,
        'capacity': 82,
      },
      {
        'id': 'ist_uskudar_1',
        'name': 'Üsküdar Devlet Hastanesi',
        'province': 'İstanbul',
        'district': 'Üsküdar',
        'address': 'Selami Ali Efendi Cad.',
        'phone': '+90 216 391 40 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 42,
        'capacity': 88,
      },
      {
        'id': 'ist_uskudar_2',
        'name': 'NPİSTANBUL Beyin Hastanesi',
        'province': 'İstanbul',
        'district': 'Üsküdar',
        'address': 'Çamlıca Cad.',
        'phone': '+90 216 444 05 00',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 18,
        'capacity': 60,
      },

      // Ankara hastaneleri
      {
        'id': 'ank_cankaya_1',
        'name': 'Ankara Şehir Hastanesi',
        'province': 'Ankara',
        'district': 'Çankaya',
        'address': 'Üniversiteler Mahallesi',
        'phone': '+90 312 552 60 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 40,
        'capacity': 95,
      },
      {
        'id': 'ank_cankaya_2',
        'name': 'Medicana International Ankara',
        'province': 'Ankara',
        'district': 'Çankaya',
        'address': 'Söğütözü Mahallesi',
        'phone': '+90 312 444 77 33',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 22,
        'capacity': 72,
      },
      {
        'id': 'ank_kecioren_1',
        'name': 'Keçiören Eğitim ve Araştırma Hastanesi',
        'province': 'Ankara',
        'district': 'Keçiören',
        'address': 'Pınar Mahallesi',
        'phone': '+90 312 569 20 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 35,
        'capacity': 83,
      },
      {
        'id': 'ank_kecioren_2',
        'name': 'Özel Güven Hastanesi',
        'province': 'Ankara',
        'district': 'Keçiören',
        'address': 'Yukarı Bahçelievler',
        'phone': '+90 312 457 80 00',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 28,
        'capacity': 68,
      },
      {
        'id': 'ank_mamak_1',
        'name': 'Mamak Devlet Hastanesi',
        'province': 'Ankara',
        'district': 'Mamak',
        'address': 'Akdere Mahallesi',
        'phone': '+90 312 552 30 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 38,
        'capacity': 80,
      },
      {
        'id': 'ank_altindag_1',
        'name': 'Hacettepe Üniversitesi Hastanesi',
        'province': 'Ankara',
        'district': 'Altındağ',
        'address': 'Sıhhiye Kampüsü',
        'phone': '+90 312 305 10 01',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 30,
        'capacity': 85,
      },
      {
        'id': 'ank_yenimahalle_1',
        'name': 'Ankara Eğitim ve Araştırma Hastanesi',
        'province': 'Ankara',
        'district': 'Yenimahalle',
        'address': 'Sükriye Mahallesi',
        'phone': '+90 312 595 30 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 33,
        'capacity': 87,
      },

      // İzmir hastaneleri
      {
        'id': 'izm_konak_1',
        'name':
            'İzmir Katip Çelebi Üniversitesi Atatürk Eğitim ve Araştırma Hastanesi',
        'province': 'İzmir',
        'district': 'Konak',
        'address': 'Basın Sitesi',
        'phone': '+90 232 244 44 44',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 42,
        'capacity': 89,
      },
      {
        'id': 'izm_konak_2',
        'name': 'Medicana İzmir Hastanesi',
        'province': 'İzmir',
        'district': 'Konak',
        'address': 'Limontepe Mahallesi',
        'phone': '+90 232 399 19 19',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 25,
        'capacity': 70,
      },
      {
        'id': 'izm_karsiyaka_1',
        'name': 'Karşıyaka Devlet Hastanesi',
        'province': 'İzmir',
        'district': 'Karşıyaka',
        'address': 'Çınar Mahallesi',
        'phone': '+90 232 461 40 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 36,
        'capacity': 79,
      },
      {
        'id': 'izm_karsiyaka_2',
        'name': 'Özel Kent Hastanesi',
        'province': 'İzmir',
        'district': 'Karşıyaka',
        'address': 'Mavişehir',
        'phone': '+90 232 461 60 00',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 20,
        'capacity': 65,
      },
      {
        'id': 'izm_bornova_1',
        'name': 'Ege Üniversitesi Tıp Fakültesi Hastanesi',
        'province': 'İzmir',
        'district': 'Bornova',
        'address': 'Kazımdirik Mahallesi',
        'phone': '+90 232 390 40 40',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 35,
        'capacity': 80,
      },
      {
        'id': 'izm_buca_1',
        'name': 'Buca Seyfi Demirsoy Devlet Hastanesi',
        'province': 'İzmir',
        'district': 'Buca',
        'address': 'Kozağaç Mahallesi',
        'phone': '+90 232 494 20 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 40,
        'capacity': 85,
      },
      {
        'id': 'izm_bayrakli_1',
        'name': 'Bayraklı Devlet Hastanesi',
        'province': 'İzmir',
        'district': 'Bayraklı',
        'address': 'Alparslan Mahallesi',
        'phone': '+90 232 435 20 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 38,
        'capacity': 77,
      },

      // Adana hastaneleri
      {
        'id': 'ada_seyhan_1',
        'name': 'Adana Şehir Hastanesi',
        'province': 'Adana',
        'district': 'Seyhan',
        'address': 'Kışla Mahallesi',
        'phone': '+90 322 344 60 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 45,
        'capacity': 92,
      },
      {
        'id': 'ada_seyhan_2',
        'name': 'Memorial Adana Hastanesi',
        'province': 'Adana',
        'district': 'Seyhan',
        'address': 'Reşatbey Mahallesi',
        'phone': '+90 322 444 07 29',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 28,
        'capacity': 73,
      },
      {
        'id': 'ada_yuregir_1',
        'name': 'Başkent Üniversitesi Adana Hastanesi',
        'province': 'Adana',
        'district': 'Yüreğir',
        'address': 'Dadaloglu Mahallesi',
        'phone': '+90 322 327 27 27',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 25,
        'capacity': 68,
      },
      {
        'id': 'ada_cukurova_1',
        'name': 'Çukurova Üniversitesi Balcalı Hastanesi',
        'province': 'Adana',
        'district': 'Çukurova',
        'address': 'Balcalı Kampüsü',
        'phone': '+90 322 338 60 60',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 35,
        'capacity': 88,
      },

      // Bursa hastaneleri
      {
        'id': 'bur_osmangazi_1',
        'name': 'Bursa Şehir Hastanesi',
        'province': 'Bursa',
        'district': 'Osmangazi',
        'address': 'Doburca Mahallesi',
        'phone': '+90 224 975 00 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 40,
        'capacity': 90,
      },
      {
        'id': 'bur_osmangazi_2',
        'name': 'Özel Bursa Hastanesi',
        'province': 'Bursa',
        'district': 'Osmangazi',
        'address': 'Çekirge Mahallesi',
        'phone': '+90 224 272 50 00',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 22,
        'capacity': 68,
      },
      {
        'id': 'bur_nilufer_1',
        'name': 'Uludağ Üniversitesi Tıp Fakültesi Hastanesi',
        'province': 'Bursa',
        'district': 'Nilüfer',
        'address': 'Görükle Kampüsü',
        'phone': '+90 224 295 00 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 35,
        'capacity': 85,
      },
      {
        'id': 'bur_yildirim_1',
        'name': 'Yıldırım Devlet Hastanesi',
        'province': 'Bursa',
        'district': 'Yıldırım',
        'address': 'Mimar Sinan Mahallesi',
        'phone': '+90 224 360 40 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 42,
        'capacity': 82,
      },

      // Antalya hastaneleri
      {
        'id': 'ant_muratpasa_1',
        'name': 'Antalya Eğitim ve Araştırma Hastanesi',
        'province': 'Antalya',
        'district': 'Muratpaşa',
        'address': 'Kazım Karabekir Cad.',
        'phone': '+90 242 249 44 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 38,
        'capacity': 86,
      },
      {
        'id': 'ant_muratpasa_2',
        'name': 'Memorial Antalya Hastanesi',
        'province': 'Antalya',
        'district': 'Muratpaşa',
        'address': 'Zafer Mahallesi',
        'phone': '+90 242 999 40 00',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 24,
        'capacity': 71,
      },
      {
        'id': 'ant_kepez_1',
        'name': 'Kepez Devlet Hastanesi',
        'province': 'Antalya',
        'district': 'Kepez',
        'address': 'Yavuz Selim Mahallesi',
        'phone': '+90 242 249 20 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 44,
        'capacity': 79,
      },
      {
        'id': 'ant_konyaalti_1',
        'name': 'Akdeniz Üniversitesi Hastanesi',
        'province': 'Antalya',
        'district': 'Konyaaltı',
        'address': 'Dumlupınar Bulvarı',
        'phone': '+90 242 249 60 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 32,
        'capacity': 84,
      },

      // Diğer iller için temel hastaneler - Her il için en az 2 hastane
      // Adıyaman
      {
        'id': 'adiyaman_merkez_1',
        'name': 'Adıyaman Üniversitesi Eğitim ve Araştırma Hastanesi',
        'province': 'Adıyaman',
        'district': 'Merkez',
        'address': 'Yunus Emre Mahallesi',
        'phone': '+90 416 223 38 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 35,
        'capacity': 78,
      },
      {
        'id': 'adiyaman_merkez_2',
        'name': 'Adıyaman Devlet Hastanesi',
        'province': 'Adıyaman',
        'district': 'Merkez',
        'address': 'Siteler Mahallesi',
        'phone': '+90 416 216 10 19',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 40,
        'capacity': 72,
      },
      {
        'id': 'adiyaman_kahta_1',
        'name': 'Kahta Devlet Hastanesi',
        'province': 'Adıyaman',
        'district': 'Kahta',
        'address': 'Yeni Mahalle',
        'phone': '+90 416 725 10 55',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 42,
        'capacity': 65,
      },

      // Afyonkarahisar
      {
        'id': 'afyon_merkez_1',
        'name': 'Afyonkarahisar Sağlık Bilimleri Üniversitesi Hastanesi',
        'province': 'Afyonkarahisar',
        'district': 'Merkez',
        'address': 'Ali Çetinkaya Kampüsü',
        'phone': '+90 272 444 03 03',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 38,
        'capacity': 80,
      },
      {
        'id': 'afyon_merkez_2',
        'name': 'Özel Afyon Hastanesi',
        'province': 'Afyonkarahisar',
        'district': 'Merkez',
        'address': 'Mareşal Fevzi Çakmak Cad.',
        'phone': '+90 272 214 54 54',
        'emergencyAvailable': true,
        'type': 'Özel',
        'waitingTime': 28,
        'capacity': 68,
      },
      {
        'id': 'afyon_sandikli_1',
        'name': 'Sandıklı Devlet Hastanesi',
        'province': 'Afyonkarahisar',
        'district': 'Sandıklı',
        'address': 'Cumhuriyet Mahallesi',
        'phone': '+90 272 512 30 09',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 45,
        'capacity': 60,
      },

      // Ağrı
      {
        'id': 'agri_merkez_1',
        'name': 'Ağrı Eğitim ve Araştırma Hastanesi',
        'province': 'Ağrı',
        'district': 'Merkez',
        'address': 'Yeni Mahalle',
        'phone': '+90 472 215 42 96',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 40,
        'capacity': 75,
      },
      {
        'id': 'agri_merkez_2',
        'name': 'Ağrı Devlet Hastanesi',
        'province': 'Ağrı',
        'district': 'Merkez',
        'address': 'Kasımpaşa Mahallesi',
        'phone': '+90 472 215 10 15',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 45,
        'capacity': 70,
      },
      {
        'id': 'agri_dogubayazit_1',
        'name': 'Doğubayazıt Devlet Hastanesi',
        'province': 'Ağrı',
        'district': 'Doğubayazıt',
        'address': 'Merkez Mahallesi',
        'phone': '+90 472 312 10 94',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 50,
        'capacity': 65,
      },
    ];

    // Eğer listede belirtilen il/ilçe için hastane yoksa, otomatik hastane oluştur
    var filteredHospitals = allHospitals
        .where(
          (hospital) =>
              hospital['province'] == province &&
              hospital['district'] == district &&
              hospital['emergencyAvailable'] == true,
        )
        .toList();

    // Eğer hiç hastane bulunamadıysa, otomatik hastaneler oluştur
    if (filteredHospitals.isEmpty) {
      filteredHospitals = _generateDefaultHospitals(province, district);
    }

    return filteredHospitals;
  }

  // Otomatik hastane oluşturma metodu
  static List<Map<String, dynamic>> _generateDefaultHospitals(
    String province,
    String district,
  ) {
    final List<Map<String, dynamic>> defaultHospitals = [];

    // Her il/ilçe için 2-3 varsayılan hastane oluştur
    final hospitalTypes = ['Devlet', 'Özel'];
    final baseWaitingTimes = [35, 25];
    final baseCapacities = [75, 65];

    for (int i = 0; i < 2; i++) {
      final hospitalId =
          '${province.toLowerCase()}_${district.toLowerCase()}_${i + 1}';
      final hospitalName = i == 0
          ? '$district ${hospitalTypes[i]} Hastanesi'
          : '$province ${hospitalTypes[i]} Hastanesi';

      defaultHospitals.add({
        'id': hospitalId,
        'name': hospitalName,
        'province': province,
        'district': district,
        'address': '$district Merkez, $province',
        'phone': '+90 312 000 00 ${i.toString().padLeft(2, '0')}',
        'emergencyAvailable': true,
        'type': hospitalTypes[i],
        'waitingTime': baseWaitingTimes[i] + (i * 5),
        'capacity': baseCapacities[i] + (i * 10),
      });
    }

    // Üçüncü hastane (sadece büyük şehirlerde)
    final bigCities = [
      'İstanbul',
      'Ankara',
      'İzmir',
      'Bursa',
      'Adana',
      'Antalya',
      'Konya',
      'Gaziantep',
    ];
    if (bigCities.contains(province)) {
      final hospitalId =
          '${province.toLowerCase()}_${district.toLowerCase()}_3';
      defaultHospitals.add({
        'id': hospitalId,
        'name': '$district Üniversite Hastanesi',
        'province': province,
        'district': district,
        'address': '$district Üniversite Kampüsü, $province',
        'phone': '+90 312 000 03 00',
        'emergencyAvailable': true,
        'type': 'Devlet',
        'waitingTime': 30,
        'capacity': 85,
      });
    }

    return defaultHospitals;
  }

  // Hastane ekleme
  static Future<String?> addHospital(Map<String, dynamic> hospitalData) async {
    try {
      final docRef = await _firestore.collection('hospitals').add({
        ...hospitalData,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'currentPatients': 0,
      });

      if (kDebugMode) {
        print('✅ Hastane eklendi: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Hastane ekleme hatası: $e');
      }
      return null;
    }
  }

  // Static hastane verilerini Firestore'a yükle
  static Future<void> importStaticHospitalsToFirestore() async {
    try {
      if (kDebugMode) {
        print('🏥 Static hastane verileri Firestore\'a yükleniyor...');
      }

      // Örnek il-ilçeler için static verileri al
      final provinces = ['İstanbul', 'Ankara', 'İzmir', 'Adana'];
      final districts = {
        'İstanbul': ['Şişli', 'Kadıköy', 'Beşiktaş', 'Fatih', 'Üsküdar'],
        'Ankara': ['Çankaya', 'Keçiören', 'Mamak', 'Altındağ', 'Yenimahalle'],
        'İzmir': ['Konak', 'Karşıyaka', 'Bornova', 'Buca', 'Bayraklı'],
        'Adana': ['Seyhan', 'Yüreğir', 'Çukurova'],
      };

      int totalAdded = 0;

      for (String province in provinces) {
        if (districts.containsKey(province)) {
          for (String district in districts[province]!) {
            final hospitalsForLocation = getHospitalsByLocation(
              province,
              district,
            );

            for (var hospital in hospitalsForLocation) {
              // Firestore'da aynı hastane var mı kontrol et
              final existingQuery = await _firestore
                  .collection('hospitals')
                  .where('name', isEqualTo: hospital['name'])
                  .where('city', isEqualTo: province)
                  .where('district', isEqualTo: district)
                  .get();

              if (existingQuery.docs.isEmpty) {
                // Yeni hastane ekle
                await _firestore.collection('hospitals').add({
                  'name': hospital['name'],
                  'city': province, // Admin panel 'city' field'ı kullanıyor
                  'province': province, // Hem province hem city ekle
                  'district': district,
                  'address': hospital['address'],
                  'phone': hospital['phone'],
                  'emergencyAvailable': hospital['emergencyAvailable'],
                  'type': hospital['type'],
                  'waitingTime': hospital['waitingTime'],
                  'emergencyCapacity': hospital['capacity'],
                  'currentPatients': 0,
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                  'importedFromStatic':
                      true, // Bu verilerin static'den geldiğini işaretle
                });
                totalAdded++;
              }
            }
          }
        }
      }

      if (kDebugMode) {
        print('✅ Toplam $totalAdded hastane Firestore\'a eklendi');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Static hastane verileri yükleme hatası: $e');
      }
    }
  }

  // Hastane güncelleme
  static Future<bool> updateHospital(
    String hospitalId,
    Map<String, dynamic> hospitalData,
  ) async {
    try {
      await _firestore.collection('hospitals').doc(hospitalId).update({
        ...hospitalData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Hastane güncellendi: $hospitalId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Hastane güncelleme hatası: $e');
      }
      return false;
    }
  }

  // Hastane durumu güncelleme
  static Future<bool> updateHospitalStatus(
    String hospitalId,
    bool isActive,
  ) async {
    try {
      await _firestore.collection('hospitals').doc(hospitalId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Hastane durumu güncellendi: $hospitalId -> $isActive');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Hastane durum güncelleme hatası: $e');
      }
      return false;
    }
  }

  // Hastane silme
  static Future<bool> deleteHospital(String hospitalId) async {
    try {
      await _firestore.collection('hospitals').doc(hospitalId).delete();

      if (kDebugMode) {
        print('✅ Hastane silindi: $hospitalId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Hastane silme hatası: $e');
      }
      return false;
    }
  }

  // Aktif hastaneleri getir
  static Future<List<Map<String, dynamic>>> getActiveHospitals() async {
    try {
      final snapshot = await _firestore
          .collection('hospitals')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Aktif hastaneler getirme hatası: $e');
      }
      return [];
    }
  }

  // Tüm hastaneleri getir
  static Future<List<Map<String, dynamic>>> getAllHospitals() async {
    try {
      final snapshot = await _firestore.collection('hospitals').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Tüm hastaneler getirme hatası: $e');
      }
      return [];
    }
  }

  // Hastane bilgisi getir
  static Future<Map<String, dynamic>?> getHospital(String hospitalId) async {
    try {
      final doc = await _firestore
          .collection('hospitals')
          .doc(hospitalId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Hastane bilgisi getirme hatası: $e');
      }
      return null;
    }
  }

  // Örnek hastaneleri başlat
  static Future<void> initializeHospitals() async {
    try {
      // Mevcut hastane sayısını kontrol et
      final snapshot = await _firestore.collection('hospitals').get();

      if (snapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          print('ℹ️ Hastaneler zaten mevcut, örnek veri eklenmedi');
        }
        return;
      }

      // Örnek hastaneler
      final sampleHospitals = [
        {
          'name': 'Ankara Şehir Hastanesi',
          'address': 'Üniversiteler Mah. 1604. Cad. No:9 Çankaya/Ankara',
          'phone': '0312 552 60 00',
          'city': 'Ankara',
          'district': 'Çankaya',
          'totalBeds': 2500,
          'emergencyCapacity': 100,
          'currentPatients': 23,
          'coordinates': {'lat': 39.9208, 'lng': 32.8541},
        },
        {
          'name': 'Hacettepe Üniversitesi Hastanesi',
          'address': 'Sıhhiye Mah. Hacettepe Üniversitesi Ankara',
          'phone': '0312 305 10 00',
          'city': 'Ankara',
          'district': 'Sıhhiye',
          'totalBeds': 1000,
          'emergencyCapacity': 80,
          'currentPatients': 45,
          'coordinates': {'lat': 39.9334, 'lng': 32.8597},
        },
        {
          'name': 'Memorial Şişli Hastanesi',
          'address': 'Piyale Paşa Bulvarı Okmeydanı Şişli/İstanbul',
          'phone': '0212 314 66 66',
          'city': 'İstanbul',
          'district': 'Şişli',
          'totalBeds': 400,
          'emergencyCapacity': 80,
          'currentPatients': 32,
          'coordinates': {'lat': 41.0082, 'lng': 28.9784},
        },
      ];

      // Hastaneleri ekle
      for (final hospital in sampleHospitals) {
        await addHospital(hospital);
      }

      if (kDebugMode) {
        print('✅ ${sampleHospitals.length} örnek hastane eklendi');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Örnek hastaneler ekleme hatası: $e');
      }
    }
  }

  /// Firebase'deki mevcut hastaneleri kontrol et ve statik data ile birleştir
  static Future<void> syncExistingFirebaseHospitals() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Firebase\'deki mevcut hastaneler kontrol ediliyor...');
      }

      // Firebase'deki tüm aktif hastaneleri getir
      final existingSnapshot = await _firestore
          .collection('hospitals')
          .where('isActive', isEqualTo: true)
          .get();

      if (kDebugMode) {
        debugPrint('📊 Firebase\'de ${existingSnapshot.docs.length} aktif hastane bulundu');
      }

      // Mevcut hastaneleri listele
      for (final doc in existingSnapshot.docs) {
        final data = doc.data();
        if (kDebugMode) {
          debugPrint('   - ${data['name']} (${data['province']}/${data['district']}) - ID: ${doc.id}');
        }
      }

      // Eğer hiç hastane yoksa örnek hastaneleri ekle
      if (existingSnapshot.docs.isEmpty) {
        await initializeHospitals();
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firebase hastane senkronizasyon hatası: $e');
      }
    }
  }

  /// Tüm aktif hastaneleri getir (Admin paneli için)
  static Future<List<Map<String, dynamic>>> getAllActiveHospitals() async {
    try {
      if (kDebugMode) {
        debugPrint('🏥 Tüm aktif hastaneler getiriliyor...');
      }

      // Mevcut hastaneleri kontrol et ve gerekirse başlat
      await syncExistingFirebaseHospitals();

      // Firebase'den tüm aktif hastaneleri getir
      final snapshot = await _firestore
          .collection('hospitals')
          .where('isActive', isEqualTo: true)
          .orderBy('province')
          .orderBy('district')
          .orderBy('name')
          .get();

      final hospitals = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'province': data['province'],
          'district': data['district'],
          'address': data['address'] ?? '',
          'phone': data['phone'] ?? '',
          'type': data['type'] ?? 'Devlet',
          'emergencyAvailable': data['emergencyAvailable'] ?? true,
          'waitingTime': data['waitingTime'] ?? 30,
          'capacity': data['capacity'] ?? 75,
          'currentPatients': data['currentPatients'] ?? 0,
          'totalBeds': data['totalBeds'] ?? 200,
          'emergencyCapacity': data['emergencyCapacity'] ?? 50,
          'coordinates': data['coordinates'] ?? {},
        };
      }).toList();

      if (kDebugMode) {
        debugPrint('✅ ${hospitals.length} aktif hastane bulundu');
        for (final hospital in hospitals) {
          debugPrint('   - ${hospital['name']} (${hospital['province']}/${hospital['district']}) - ID: ${hospital['id']}');
        }
      }

      // Eğer hala hiç hastane yoksa zorla örnek hastaneler ekle
      if (hospitals.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Hala hiç hastane yok, zorla örnek hastaneler ekleniyor...');
        }
        await _addSampleHospitals();
        
        // Tekrar sorguyu çalıştır
        final retrySnapshot = await _firestore
            .collection('hospitals')
            .where('isActive', isEqualTo: true)
            .get();
            
        return retrySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'],
            'province': data['province'],
            'district': data['district'],
            'address': data['address'] ?? '',
            'phone': data['phone'] ?? '',
            'type': data['type'] ?? 'Devlet',
            'emergencyAvailable': data['emergencyAvailable'] ?? true,
            'waitingTime': data['waitingTime'] ?? 30,
            'capacity': data['capacity'] ?? 75,
            'currentPatients': data['currentPatients'] ?? 0,
            'totalBeds': data['totalBeds'] ?? 200,
            'emergencyCapacity': data['emergencyCapacity'] ?? 50,
            'coordinates': data['coordinates'] ?? {},
          };
        }).toList();
      }

      return hospitals;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Tüm hastaneleri getirme hatası: $e');
      }
      return [];
    }
  }

  /// Zorla örnek hastaneler ekle
  static Future<void> _addSampleHospitals() async {
    try {
      final sampleHospitals = [
        {
          'name': 'Ankara Şehir Hastanesi',
          'province': 'Ankara',
          'district': 'Çankaya',
          'address': 'Üniversiteler Mah. 1604. Cad. No:9 Çankaya/Ankara',
          'phone': '0312 552 60 00',
          'type': 'Devlet',
          'totalBeds': 2500,
          'emergencyCapacity': 100,
          'emergencyAvailable': true,
          'waitingTime': 25,
          'capacity': 85,
          'coordinates': {'lat': 39.9208, 'lng': 32.8541},
          'isActive': true,
          'currentPatients': 45,
        },
        {
          'name': 'Hacettepe Üniversitesi Hastanesi',
          'province': 'Ankara', 
          'district': 'Sıhhiye',
          'address': 'Sıhhiye Mah. Hacettepe Üniversitesi Ankara',
          'phone': '0312 305 10 00',
          'type': 'Üniversite',
          'totalBeds': 1000,
          'emergencyCapacity': 80,
          'emergencyAvailable': true,
          'waitingTime': 30,
          'capacity': 70,
          'coordinates': {'lat': 39.9334, 'lng': 32.8597},
          'isActive': true,
          'currentPatients': 32,
        },
        {
          'name': 'Konak Devlet Hastanesi',
          'province': 'İzmir',
          'district': 'Konak',
          'address': 'Konak Meydanı İzmir',
          'phone': '0232 000 00 00',
          'type': 'Devlet',
          'totalBeds': 800,
          'emergencyCapacity': 60,
          'emergencyAvailable': true,
          'waitingTime': 35,
          'capacity': 80,
          'coordinates': {'lat': 38.4237, 'lng': 27.1428},
          'isActive': true,
          'currentPatients': 28,
        },
        {
          'name': 'Bayrampaşa Devlet Hastanesi',
          'province': 'İstanbul',
          'district': 'Bayrampaşa',
          'address': 'Bayrampaşa İstanbul',
          'phone': '0212 000 00 00',
          'type': 'Devlet',
          'totalBeds': 600,
          'emergencyCapacity': 70,
          'emergencyAvailable': true,
          'waitingTime': 40,
          'capacity': 75,
          'coordinates': {'lat': 41.0370, 'lng': 28.9017},
          'isActive': true,
          'currentPatients': 38,
        },
      ];

      for (final hospital in sampleHospitals) {
        await _firestore.collection('hospitals').add({
          ...hospital,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (kDebugMode) {
        debugPrint('✅ ${sampleHospitals.length} örnek hastane eklendi');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Örnek hastane ekleme hatası: $e');
      }
    }
  }

  // Hastane hasta sayısını güncelle
  static Future<bool> updatePatientCount(
    String hospitalId,
    int currentPatients,
  ) async {
    try {
      await _firestore.collection('hospitals').doc(hospitalId).update({
        'currentPatients': currentPatients,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print(
          '✅ Hastane hasta sayısı güncellendi: $hospitalId -> $currentPatients',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Hasta sayısı güncelleme hatası: $e');
      }
      return false;
    }
  }

  // Şehre göre hastaneleri getir
  static Future<List<Map<String, dynamic>>> getHospitalsByCity(
    String city,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('hospitals')
          .where('city', isEqualTo: city)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Şehir hastaneleri getirme hatası: $e');
      }
      return [];
    }
  }
}
