# Ağ Tabanlı Paralel Dağıtım Sistemleri Projesi
## AdventureWorks2022 Veritabanında Yedekleme ve Felaketten Kurtarma Planı

---

## 1. HAFTA: YEDEKLEME ALTYAPISI KURULUMU VE TEMEL YEDEKLEMELERi

### 1.1 Proje Hazırlığı ve Yedekleme Dizin Yapısının Oluşturulması
C:\SQLBackups dizini altında Full, Differential, TransactionLog ve PointInTime alt dizinleri oluşturulmuştur.

### 1.2 Veritabanı Kurtarma Modunun Ayarlanması (RECOVERY FULL)
AdventureWorks2022 veritabanı FULL RECOVERY moduna geçirilmiştir. Bu mod, point-in-time restore gibi ileri kurtarma tekniklerini mümkün kılmıştır.

### 1.3 İlk Tam Yedekleme (Full Backup) - Gün 1
AdventureWorks2022'nin tam yedeklemesi alınmıştır (AdventureWorks2022_Full_Week1_Day1.bak). Sıkıştırma aktif edilmiştir.

### 1.4 İşlem Günlüğü Yedeklemesi (Transaction Log Backup) - Gün 2
İşlem günlüğü yedeklemesi alınmıştır. Point-in-time restore için kritik öneme sahiptir.

### 1.5 Artık (Fark) Yedekleme (Differential Backup) - Gün 3
Son tam yedeklemeden sonraki değişiklikler yedeklenmiştir (AdventureWorks2022_Diff_Week1_Day3.bak). Alan tasarrufu sağlamıştır.

### 1.6 Periyodik İşlem Günlüğü Yedekleri (Hafta Boyunca)
Her 24 saatte bir işlem günlüğü yedekleri alınmıştır. Veri kaybı riskini minimize etmektedir.

### 1.7 Yedekleme İstatistiklerinin Kayıt Altına Alınması
Tüm yedekleme işlemleri BackupHistory tablosuna kaydedilmiştir. Yedekleme türü, yolu, zamanları ve boyutu içermektedir.

### 1.8 Yedekleme Dosya İçeriğinin Sorgulanması (RESTORE FILELISTONLY)
Tam yedekleme dosyasının içeriği RESTORE FILELISTONLY komutu ile sorgulanmıştır. Veri ve günlük dosyaları doğrulanmıştır.

### 1.9 Yedekleme İş Tanımlarının Veritabanında Yapılandırılması
BackupHistory tablosu oluşturulmuştur. Audit kaydı ve geçmiş yedekleme faaliyetlerini izlemeyi sağlamıştır.

### 1.10 Zamanlayıcılarla Yedekleme - SQL Agent Jobs Başlatılması
**SQL Server Agent Jobs** kurulmuştur: Günlük Tam Yedekleme (saat 02:00), Günlük Artık Yedekleme (saat 14:00), Saatlik İşlem Günlüğü Yedekleri. Yedeklemeler artık tamamen otomatik hale getirilmiştir.

---

## 2. HAFTA: İLERİ KURTARMA SENARYOLARI VE FELAKETTEN KURTARMA PLANI

### 2.1 Yedekleme Dosyalarının Doğrulması (RESTORE VERIFYONLY)
Hafta 1 yedekleme dosyaları RESTORE VERIFYONLY komutu ile doğrulanmıştır. Tüm dosyalar başarıyla tamamlanmıştır.

### 2.2 Doğrulanan Yedeklerin Statusunun Güncellenmesi
BackupHistory tablosunda VerificationStatus sütunu güncellenmmiştir. Doğrulanmış yedekler işaretlenmiştir.

### 2.3 Point-in-Time Restore Planlaması ve Senaryosu
Belirli zaman noktasına geri yükleme senaryosu planlanmıştır. Kaza ile silinen verilerin kurtarılmasında kritik rol oynar.

### 2.4 Kazayla Silinen Verilerin Kurtarma Senaryosu
Sales.SalesOrderDetail tablosu kurtarma senaryosu hazırlanmıştır. Yedek veritabanına geri yükleme yapılmıştır.

### 2.5 Database Mirroring Yapılandırması - Yüksek Erişilebilirlik
Mirroring uç noktası oluşturulmuştur. 5022 portu ve AES şifrelemesi ile güvenli bağlantı sağlanmıştır.

### 2.6 Test Veritabanı Ortamının Oluşturulması
Yedeklemelerden test veritabanı (AdventureWorks2022_Restore_Test) oluşturulmuştur. Kurtarma prosedürleri test edilmektedir.

### 2.7 Geri Yükleme Simülasyon Tablosunun Oluşturulması ve Kaydedilmesi
RestoreSimulation tablosu oluşturulmuştur. Geri yükleme detayları kaydedilmektedir.

### 2.8 Geri Yüklenen Veritabanının Veri Bütünlüğü Kontrolü
Veri bütünlüğü kontrolleri yapılmıştır. DBCC CHECKDB ile fiziksel bütünlük doğrulanmıştır.

### 2.9 Felaketten Kurtarma Planları ve Senaryolarının Dokümantasyonu
DisasterRecoveryPlan tablosu oluşturulmuş, beş kritik kurtarma senaryosu tanımlanmıştır: Tam Sistem Başarısızlığı, Kısmi Veri Kaybı, İşlem Günlüğü Hatası, Database Mirroring, Uzun Vadeli Arşivleme.

### 2.10 Hafta 2 Tamamlama: Zamanlanmış Yedeklemelerin Kontrolü ve Raporlaması
Hafta 1'de tanımlanan üç SQL Agent Job'ın performansı izlenmiştir. ScheduledBackupHistory tablosu ile otomatik yedeklemelerin başarısı/başarısızlığı raporlanmıştır. Sistem otomatik yedekleme ile çalışmaya başlamıştır.

Gerekli Video Linkim:
[Final 2. Proje(Proje 2: Veritabanı Yedekleme ve Felaketten Kurtarma Planı)](https://drive.google.com/file/d/14ujq7h2Zjk3VbWHKZvuqzuGiSfyVydCH/view?usp=drive_link)


