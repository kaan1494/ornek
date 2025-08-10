# my_new

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



✅ Başarıyla Tamamlandı
🎯 Eklenen Özellikler:
Dashboard'a Yeni Butonlar Eklendi:
🩺 "Doktor Ata" - Acil hastanelere doktor atama
🏥 "Hastane Nöbetleri" - Nöbetçi doktorları görüntüleme
📋 "Planlarım" - Yeşil alan hastalarının doktor görüşmeleri
🏥 Doktor Ata Ekranı:
Acil başvuru yapabilen tüm hastaneleri listeler
Her hastaneye mevcut doktorlardan birini atayabilir
Atama durumunu görsel olarak gösterir
Firebase'de hospital_doctor_assignments koleksiyonunda saklar
👨‍⚕️ Hastane Nöbetleri Ekranı:
Tüm acil hastaneleri ve nöbetçi doktor durumlarını gösterir
Hangi hastanede nöbetçi doktor var/yok bilgisini verir
Doktor iletişim bilgilerini gösterir
📅 Planlarım Ekranı:
Yeşil alan hastalarını listeler (Triaj skoru 30-50 arası)
Her hastanın atandığı hastaneyi gösterir
Eğer o hastaneye nöbetçi doktor atanmışsa:
Nöbetçi doktor bilgilerini gösterir
"Doktor Görüşmesi Başlat" butonu aktif olur
Hasta doktor görüşmesi yapabilir
🔄 İş Akışı:
Admin "Doktor Ata" ile hastanelere doktor atar
Hastalar acil başvuru yapar ve yeşil alana düşer
"Planlarım" ekranında yeşil alan hastaları görünür
Eğer hastanede nöbetçi doktor varsa → Doktor görüşmesi yapılabilir
Eğer hastanede nöbetçi doktor yoksa → Önce doktor atanması gerekir
🎯 Sistem Entegrasyonu:
Acil başvuru sistemindeki hastaneler kullanılır
Mevcut doktor kayıtları kullanılır
Triaj sonuçları ile entegre çalışır
Firebase Firestore ile gerçek zamanlı güncelleme
Bu sistem sayesinde artık:

✅ Acil hastanelerdeki nöbetçi doktorlar görülebilir
✅ Yeşil alan hastları nöbetçi doktorlarla görüşebilir
✅ Admin hastanelere doktor atayabilir
✅ Tüm sistem entegre çalışır
Dashboard'da yeni butonlar görünecek ve kullanıcılar bu özelliklerden faydalanabilecek!
