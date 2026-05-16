/*

    ADVENTUREWORKS2022 VERITABANINDA 
    VERİTABANI YEDEKLEME VE FELAKETTEN KURTARMA PLANI
    Ağ Tabanlı Paralel Dağıtım Sistemi Projesi

*/

USE master
GO

-- *** 1. HAFTA: YEDEKLEME ALTYAPISI KURULUMU VE TEMEL YEDEKLEME STRATEJİLERİ


-- 1.1 Yedekleme Dizinlerinin Oluşturulması
EXEC xp_cmdshell 'md C:\SQLBackups'
EXEC xp_cmdshell 'md C:\SQLBackups\Full'
EXEC xp_cmdshell 'md C:\SQLBackups\Differential'
EXEC xp_cmdshell 'md C:\SQLBackups\TransactionLog'
EXEC xp_cmdshell 'md C:\SQLBackups\PointInTime'
GO

-- 1.2 Veritabanı Yedekleme Modunun Ayarlanması
USE AdventureWorks2022
GO

-- Tam Kurtarma Moduna Geçişi (Transaction Log Yedekleri için gerekli)
ALTER DATABASE AdventureWorks2022 SET RECOVERY FULL
GO

-- Veritabanı durumunun kontrol edilmesi
SELECT 
    name AS DatabaseName,
    recovery_model_desc AS RecoveryMode,
    state_desc AS DatabaseState,
    create_date AS CreatedDate
FROM sys.databases
WHERE name = 'AdventureWorks2022'
GO

-- 1.3 TAM YEDEKLEME (Full Backup) - Hafta 1, Gün 1
-- Veritabanının tam bir yedeklemesini alıyor
BACKUP DATABASE AdventureWorks2022
TO DISK = 'C:\SQLBackups\Full\AdventureWorks2022_Full_Week1_Day1.bak'
WITH 
    DESCRIPTION = 'Full Backup - Week 1 Day 1',
    INIT,
    COMPRESSION,
    STATS = 10
GO

-- 1.4 İŞLEM GÜNLÜĞÜ YEDEKLEMESI (Transaction Log Backup) - Hafta 1, Gün 2
-- İşlemleri kaydeden günlüğün yedeklemesi, point-in-time restore için gerekli
BACKUP LOG AdventureWorks2022
TO DISK = 'C:\SQLBackups\TransactionLog\AdventureWorks2022_Log_Week1_Day2.trn'
WITH 
    DESCRIPTION = 'Transaction Log Backup - Week 1 Day 2',
    COMPRESSION,
    STATS = 10
GO

-- 1.5 ARTIK YEDEKLEME (Differential Backup) - Hafta 1, Gün 3
-- Son tam yedeklemeden bu yana değişen verilerin yedeklemesi
BACKUP DATABASE AdventureWorks2022
TO DISK = 'C:\SQLBackups\Differential\AdventureWorks2022_Diff_Week1_Day3.bak'
WITH 
    DIFFERENTIAL,
    DESCRIPTION = 'Differential Backup - Week 1 Day 3',
    COMPRESSION,
    STATS = 10
GO

-- 1.6 İŞLEM GÜNLÜĞÜ YEDEKLEMESI - Hafta 1, Gün 4
BACKUP LOG AdventureWorks2022
TO DISK = 'C:\SQLBackups\TransactionLog\AdventureWorks2022_Log_Week1_Day4.trn'
WITH 
    DESCRIPTION = 'Transaction Log Backup - Week 1 Day 4',
    COMPRESSION,
    STATS = 10
GO

-- 1.7 HAFTALIK YEDEKLEME İSTATİSTİKLERİ
-- Hafta 1'de alınan yedeklerin bilgisini sorgulama
SELECT 
    database_name,
    backup_type,
    backup_start_date,
    backup_finish_date,
    expiration_date,
    media_set_id,
    media_count
FROM backupset
WHERE database_name = 'AdventureWorks2022'
    AND backup_start_date >= DATEADD(WEEK, -1, GETDATE())
ORDER BY backup_start_date DESC
GO

-- 1.8 YEDEKLEME FİZİKSEL DOSYA BİLGİLERİ
-- Yedekleme dosyalarının içeriğini sorgulama
RESTORE FILELISTONLY 
FROM DISK = 'C:\SQLBackups\Full\AdventureWorks2022_Full_Week1_Day1.bak'
GO

-- 1.9 YEDEKLEME İŞ TABLOSUNUN OLUŞTURULMASI
-- Hafta 1 yedeklemelerinin kayıtlarını tutmak için
CREATE TABLE dbo.BackupHistory (
    BackupID INT PRIMARY KEY IDENTITY(1,1),
    DatabaseName NVARCHAR(128) NOT NULL,
    BackupType NVARCHAR(50) NOT NULL, -- Full, Differential, Log
    BackupFilePath NVARCHAR(512) NOT NULL,
    BackupStartTime DATETIME NOT NULL,
    BackupEndTime DATETIME NOT NULL,
    BackupSizeGB DECIMAL(10,2),
    VerificationStatus BIT DEFAULT 0, -- 0 = Unverified, 1 = Verified
    Week INT NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE()
)
GO

-- 1.10 HAFTA 1 YEDEKLEME KAYITLARININ EKLENMESI
INSERT INTO dbo.BackupHistory 
    (DatabaseName, BackupType, BackupFilePath, BackupStartTime, BackupEndTime, BackupSizeGB, Week)
VALUES
    ('AdventureWorks2022', 'Full', 'C:\SQLBackups\Full\AdventureWorks2022_Full_Week1_Day1.bak', 
     DATEADD(DAY, -6, GETDATE()), DATEADD(DAY, -6, GETDATE()), 150.50, 1),
    ('AdventureWorks2022', 'Log', 'C:\SQLBackups\TransactionLog\AdventureWorks2022_Log_Week1_Day2.trn', 
     DATEADD(DAY, -5, GETDATE()), DATEADD(DAY, -5, GETDATE()), 12.25, 1),
    ('AdventureWorks2022', 'Differential', 'C:\SQLBackups\Differential\AdventureWorks2022_Diff_Week1_Day3.bak', 
     DATEADD(DAY, -4, GETDATE()), DATEADD(DAY, -4, GETDATE()), 35.75, 1),
    ('AdventureWorks2022', 'Log', 'C:\SQLBackups\TransactionLog\AdventureWorks2022_Log_Week1_Day4.trn', 
     DATEADD(DAY, -3, GETDATE()), DATEADD(DAY, -3, GETDATE()), 15.30, 1)
GO

