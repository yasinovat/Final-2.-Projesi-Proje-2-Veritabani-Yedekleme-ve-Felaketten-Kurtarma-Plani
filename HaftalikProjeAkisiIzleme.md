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




