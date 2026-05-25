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
    type AS backup_type,
    backup_start_date,
    backup_finish_date,
    expiration_date,
    media_set_id
FROM msdb.dbo.backupset
WHERE database_name = 'AdventureWorks2022'
    AND backup_start_date >= DATEADD(WEEK, -1, GETDATE())
ORDER BY backup_start_date DESC;
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
SELECT * FROM dbo.BackupHistory
-- ================================================================================
-- *** 2. HAFTA: İLERİ KURTARMA SENARYOLARI VE FELAKETTEN KURTARMA
-- ================================================================================

-- 2.1 YEDEKLEME DOĞRULAMA (Backup Verification)
-- Yedek dosyalarının bütünlüğünün kontrol edilmesi
RESTORE VERIFYONLY 
FROM DISK = 'C:\SQLBackups\Full\AdventureWorks2022_Full_Week1_Day1.bak'
GO

-- 2.2 YEDEKLEMESİ DOĞRULANMIŞ DOSYALARIN SORGULANMASI
-- Hafta 2'de doğrulama sonuçları güncellemesi
UPDATE dbo.BackupHistory
SET VerificationStatus = 1
WHERE BackupType = 'Full' AND Week = 1
GO
SELECT * FROM dbo.BackupHistory

-- 2.3 POINT-IN-TIME RESTORE SENARYOSU HAFTA 2 BAŞLANGIÇ
-- Veritabanını belirli bir zamana geri yükleme işleminin hazırlanması
-- Önce tam yedeklemeden geri yükleme simülasyonu
/*
-- 2.3 POINT-IN-TIME RESTORE SENARYOSU

RESTORE DATABASE AdventureWorks2022_TestRestore
FROM DISK = 'C:\SQLBackups\Full\AdventureWorks2022_Full_Week1_Day1.bak'
WITH 
    NORECOVERY,
    REPLACE,
    MOVE 'AdventureWorks2022' TO 'C:\SQLBackups\AdventureWorks2022_TestRestore.mdf',
    MOVE 'AdventureWorks2022_log' TO 'C:\SQLBackups\AdventureWorks2022_TestRestore_log.ldf';
GO

RESTORE DATABASE AdventureWorks2022_TestRestore
FROM DISK = 'C:\SQLBackups\Differential\AdventureWorks2022_Diff_Week1_Day3.bak'
WITH NORECOVERY;
GO

RESTORE LOG AdventureWorks2022_TestRestore
FROM DISK = 'C:\SQLBackups\TransactionLog\AdventureWorks2022_Log_Week1_Day4.trn'
WITH RECOVERY;
GO
*/

-- 2.4 KAZAYLA SİLİNEN VERİLERİN KURTARMA SENARYOSUı
-- Örnek: Sales.SalesOrderDetail tablosundaki verilerin kurtarılması
-- Yedek veritabanında geri yükleme simülasyonu
/*
USE AdventureWorks2022;
GO

SELECT COUNT(*) AS OncekiKayitSayisi
FROM Sales.SalesOrderDetail;
GO

DELETE TOP (5)
FROM Sales.SalesOrderDetail;
GO

SELECT COUNT(*) AS SonrakiKayitSayisi
FROM Sales.SalesOrderDetail;
GO

RESTORE DATABASE AdventureWorks2022_Recovery
FROM DISK = 'C:\SQLBackups\Full\AdventureWorks2022_Full_Week1_Day1.bak'
WITH 
    RECOVERY,
    REPLACE,
    MOVE 'AdventureWorks2022' TO 'C:\SQLBackups\AdventureWorks2022_Recovery.mdf',
    MOVE 'AdventureWorks2022_log' TO 'C:\SQLBackups\AdventureWorks2022_Recovery_log.ldf';
GO

USE AdventureWorks2022_Recovery;
GO

SELECT COUNT(*) AS RecoveryKayitSayisi
FROM Sales.SalesOrderDetail;
GO

SET IDENTITY_INSERT AdventureWorks2022.Sales.SalesOrderDetail ON;
GO

INSERT INTO AdventureWorks2022.Sales.SalesOrderDetail
(
    SalesOrderID,
    SalesOrderDetailID,
    CarrierTrackingNumber,
    OrderQty,
    ProductID,
    SpecialOfferID,
    UnitPrice,
    UnitPriceDiscount,
    rowguid,
    ModifiedDate
)
SELECT
    r.SalesOrderID,
    r.SalesOrderDetailID,
    r.CarrierTrackingNumber,
    r.OrderQty,
    r.ProductID,
    r.SpecialOfferID,
    r.UnitPrice,
    r.UnitPriceDiscount,
    r.rowguid,
    r.ModifiedDate
FROM AdventureWorks2022_Recovery.Sales.SalesOrderDetail r
WHERE NOT EXISTS (
    SELECT 1
    FROM AdventureWorks2022.Sales.SalesOrderDetail a
    WHERE a.SalesOrderID = r.SalesOrderID
      AND a.SalesOrderDetailID = r.SalesOrderDetailID
);
GO

SET IDENTITY_INSERT AdventureWorks2022.Sales.SalesOrderDetail OFF;
GO

USE AdventureWorks2022;
GO

SELECT COUNT(*) AS KurtarmaSonrasiKayitSayisi
FROM Sales.SalesOrderDetail;
GO
*/

-- 2.5 DATABASE MIRRORING HAZIRLANMASI - Hafta 2
-- Asenkron mirroring için uç noktaların oluşturulması
USE master
GO

-- Mirroring uç noktasının oluşturulması (Principal Server)
/*
CREATE ENDPOINT Mirroring_Endpoint
    STATE = STARTED
    AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
    FOR DATABASE_MIRRORING (
        AUTHENTICATION = WINDOWS NTLM,
        ENCRYPTION = REQUIRED ALGORITHM AES,
        ROLE = ALL
    )
GO

-- Mirror Server üzerinde yapılacak işlemler
-- Principal sunucu özelliklerinin ayarlanması
ALTER DATABASE AdventureWorks2022 SET PARTNER = 'TCP://MirrorServerName:5022'
GO
*/

-- 2.6 SİMÜLASYON YEDEK VERİTABANI OLUŞTURMA - Hafta 2
-- Test amaçlı yedeklerden geri yükleme yapısı
-- Bu, üretim veritabanını etkilemeden test edilebilir
USE master
GO

-- Yedek geri yükleme simulasyonu 
CREATE TABLE dbo.RestoreSimulation (
    SimulationID INT PRIMARY KEY IDENTITY(1,1),
    OriginalDatabase NVARCHAR(128) NOT NULL,
    RestoredDatabase NVARCHAR(128) NOT NULL,
    RestoreType NVARCHAR(50) NOT NULL, -- Full, Differential, PointInTime
    RestoreStartTime DATETIME NOT NULL,
    RestoreEndTime DATETIME,
    RestoreStatus NVARCHAR(50) NOT NULL DEFAULT 'In Progress',
    Week INT NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE()
)
GO

-- 2.7 HAFTA 2 GERİ YÜKLEME KAYITLARININ BAŞLATILMASI
INSERT INTO dbo.RestoreSimulation 
    (OriginalDatabase, RestoredDatabase, RestoreType, RestoreStartTime, Week)
VALUES
    ('AdventureWorks2022', 'AdventureWorks2022_Restore_Test', 'Full', GETDATE(), 2)
GO

-- 2.8 SÜREKLİ GERİ YÜKLEME ESNASINDA VERİ KONTROLÜ
-- Geri yükleme sonrası verilerin doğrulanması
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    COUNT(*) AS RecordCount
FROM AdventureWorks2022.sys.indexes i
INNER JOIN AdventureWorks2022.sys.partitions p ON i.object_id = p.object_id
WHERE i.index_id IN (0, 1)
GROUP BY i.object_id
ORDER BY RecordCount DESC
GO

-- 2.9 FELAKETTEN KURTARMA PLANI VE SENARYOLAR
-- Hafta 2 son aşama: Tüm yedekleme stratejilerinin dokümantasyonu
CREATE TABLE dbo.DisasterRecoveryPlan (
    PlanID INT PRIMARY KEY IDENTITY(1,1),
    ScenarioName NVARCHAR(256) NOT NULL,
    Description NVARCHAR(MAX),
    RTO_Minutes INT, -- Recovery Time Objective
    RPO_Minutes INT, -- Recovery Point Objective
    BackupStrategy NVARCHAR(512),
    EstimatedCost DECIMAL(10,2),
    Week INT,
    Status NVARCHAR(50),
    CreatedDate DATETIME DEFAULT GETDATE()
)
GO

-- 2.10 HAFTA 2 FELAKETTEN KURTARMA PLANLARININ EKLENMESI
INSERT INTO dbo.DisasterRecoveryPlan 
    (ScenarioName, Description, RTO_Minutes, RPO_Minutes, BackupStrategy, Week, Status)
VALUES
    ('Tam Sistem Başarısızlığı', 
     'Sunucunun tamamen çökmesi durumunda tam yedekten 2 saat içinde kurtarma', 
     120, 15, 'Full Backup + Differential + Log', 2, 'Active'),
    ('Kısmi Veri Kaybı', 
     'Kazayla silinen tablonun point-in-time restore ile kurtarılması', 
     30, 5, 'Full Backup + Log Backups', 2, 'Active'),
    ('İşlem Günlüğü Hatası', 
     'İşlem günlüğü dosyasının bozulması durumunda; yeni günlük oluşturma', 
     45, 10, 'Full Backup + Differential', 2, 'Active'),
    ('Mirroring ile Yüksek Erişilebilirlik', 
     'Database Mirroring ile anında yük devretme (failover)', 
     2, 0, 'Database Mirroring + Log Shipping', 2, 'Active'),
    ('Arşiv ve Uzun Vadeli Saklama', 
     'Haftalık tam yedeklerin ağ deposunda tutulması ve dış depolama alanında saklama', 
     300, 60, 'Full Backup + Archive', 2, 'Planning')
GO
SELECT * FROM dbo.DisasterRecoveryPlan;
-- ================================================================================
-- *** ZAMANLAYıCıLAR İLE YEDEKLEME: SQL AGENT JOBS YAPTIRILMASI (Hafta 1-2)
-- ================================================================================

-- KONU: Yedekleme işlerinin belirli aralıklarla otomatik hale getirilmesi
-- SQL Server Agent Jobs kullanarak, yedeklemeleri zamanlanmış görevler olarak tanımlama

USE msdb;
GO

-- 3.1 GÜNLÜK TAM YEDEKLEME İŞİ
EXEC sp_add_job 
    @job_name = 'DailyFullBackup_AdventureWorks2022',
    @enabled = 1,
    @description = 'Her gün saat 02:00''de tam yedekleme işi';
GO

EXEC sp_add_jobstep 
    @job_name = 'DailyFullBackup_AdventureWorks2022',
    @step_name = 'FullBackupStep',
    @subsystem = 'TSQL',
    @command = N'
BACKUP DATABASE AdventureWorks2022
TO DISK = ''C:\SQLBackups\Full\AdventureWorks2022_Full_Scheduled.bak''
WITH DESCRIPTION = ''Scheduled Daily Full Backup'', COMPRESSION, STATS = 10;
',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

-- 3.2 GÜNLÜK TAM YEDEKLEME ZAMANLAYICISI
EXEC sp_add_schedule 
    @schedule_name = 'DailyFullBackup_Schedule',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 020000;
GO

EXEC sp_attach_schedule 
    @job_name = 'DailyFullBackup_AdventureWorks2022',
    @schedule_name = 'DailyFullBackup_Schedule';
GO

-- 3.3 GÜNLÜK FARK YEDEKLEME İŞİ
EXEC sp_add_job 
    @job_name = 'DailyDifferentialBackup_AdventureWorks2022',
    @enabled = 1,
    @description = 'Her gün saat 14:00''de fark yedekleme işi';
GO

EXEC sp_add_jobstep 
    @job_name = 'DailyDifferentialBackup_AdventureWorks2022',
    @step_name = 'DifferentialBackupStep',
    @subsystem = 'TSQL',
    @command = N'
BACKUP DATABASE AdventureWorks2022
TO DISK = ''C:\SQLBackups\Differential\AdventureWorks2022_Diff_Scheduled.bak''
WITH DIFFERENTIAL, DESCRIPTION = ''Scheduled Daily Differential Backup'', COMPRESSION, STATS = 10;
',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

-- 3.4 GÜNLÜK FARK YEDEKLEME ZAMANLAYICISI
EXEC sp_add_schedule 
    @schedule_name = 'DailyDifferentialBackup_Schedule',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 140000;
GO

EXEC sp_attach_schedule 
    @job_name = 'DailyDifferentialBackup_AdventureWorks2022',
    @schedule_name = 'DailyDifferentialBackup_Schedule';
GO

-- 3.5 SAATLİK LOG YEDEKLEME İŞİ
EXEC sp_add_job 
    @job_name = 'HourlyTransactionLogBackup_AdventureWorks2022',
    @enabled = 1,
    @description = 'Her saat başında transaction log yedeklemesi';
GO

EXEC sp_add_jobstep 
    @job_name = 'HourlyTransactionLogBackup_AdventureWorks2022',
    @step_name = 'TransactionLogBackupStep',
    @subsystem = 'TSQL',
    @command = N'
BACKUP LOG AdventureWorks2022
TO DISK = ''C:\SQLBackups\TransactionLog\AdventureWorks2022_Log_Scheduled.trn''
WITH DESCRIPTION = ''Scheduled Hourly Transaction Log Backup'', COMPRESSION, STATS = 10;
',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

-- 3.6 SAATLİK LOG YEDEKLEME ZAMANLAYICISI
EXEC sp_add_schedule 
    @schedule_name = 'HourlyTransactionLogBackup_Schedule',
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 8,
    @freq_subday_interval = 1;
GO

EXEC sp_attach_schedule 
    @job_name = 'HourlyTransactionLogBackup_AdventureWorks2022',
    @schedule_name = 'HourlyTransactionLogBackup_Schedule';
GO

-- 3.7 JOB'LARI SUNUCUYA BAĞLAMA
EXEC sp_add_jobserver 
    @job_name = 'DailyFullBackup_AdventureWorks2022',
    @server_name = @@SERVERNAME;
GO

EXEC sp_add_jobserver 
    @job_name = 'DailyDifferentialBackup_AdventureWorks2022',
    @server_name = @@SERVERNAME;
GO

EXEC sp_add_jobserver 
    @job_name = 'HourlyTransactionLogBackup_AdventureWorks2022',
    @server_name = @@SERVERNAME;
GO
-- 3.8 HAFTA 2: ZAMANLAYıCı İŞLERİN DURUMUNU İZLEME VE RAPORLAMA
-- Planlanmış yedekleme işlerinin durumu hakkında detaylı sorgu
-- 3.8 ZAMANLANMIŞ İŞLERİN DURUMU
SELECT 
    j.name AS JobName,
    j.enabled AS IsEnabled,
    s.name AS ScheduleName,
    s.freq_type,
    s.freq_interval,
    s.active_start_time
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules js 
    ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysschedules s 
    ON js.schedule_id = s.schedule_id
WHERE j.name LIKE '%AdventureWorks2022%'
ORDER BY j.name;
GO

-- 3.9 ZAMANLAYıCı YEDEKLEMELERİN GEÇMİŞ KAYITLARI
-- Hafta 2'de; otomatik yedeklemelerin başarısı/başarısızlığını izleme tablosu
CREATE TABLE dbo.ScheduledBackupHistory (
    ScheduledBackupID INT PRIMARY KEY IDENTITY(1,1),
    JobName NVARCHAR(128) NOT NULL,
    ExecutionDate DATETIME NOT NULL,
    ExecutionStatus NVARCHAR(50), -- Success / Failed
    ErrorMessage NVARCHAR(MAX),
    BackupFilePath NVARCHAR(512),
    Week INT,
    CreatedDate DATETIME DEFAULT GETDATE()
)
GO

-- 3.10 HAFTA 2: ZAMANLANMIŞ YEDEKLEME BAŞARISI RAPORU
-- Otomatik yedeklemelerin haftalık başarı durumu
INSERT INTO dbo.ScheduledBackupHistory 
    (JobName, ExecutionDate, ExecutionStatus, Week)
VALUES
    ('DailyFullBackup_AdventureWorks2022', DATEADD(DAY, -2, GETDATE()), 'Success', 2),
    ('DailyDifferentialBackup_AdventureWorks2022', DATEADD(DAY, -1, GETDATE()), 'Success', 2),
    ('HourlyTransactionLogBackup_AdventureWorks2022', GETDATE(), 'Success', 2)
GO
SELECT * FROM dbo.ScheduledBackupHistory;
-- ================================================================================
-- HAFTA 1 VE 2 ÖZET RAPORLAR
-- ================================================================================

-- Hafta 1 Yedekleme Özet Raporu
PRINT '========================================='
PRINT 'HAFTA 1: YEDEKLEME ÖZETİ'
PRINT '========================================='
SELECT 
    Week,
    COUNT(*) AS TotalBackups,
    SUM(BackupSizeGB) AS TotalBackupSizeGB,
    COUNT(CASE WHEN BackupType = 'Full' THEN 1 END) AS FullBackups,
    COUNT(CASE WHEN BackupType = 'Differential' THEN 1 END) AS DifferentialBackups,
    COUNT(CASE WHEN BackupType = 'Log' THEN 1 END) AS LogBackups
FROM dbo.BackupHistory
WHERE Week = 1
GROUP BY Week
GO

-- Hafta 2 Kurtarma Planı Özet Raporu
PRINT '========================================='
PRINT 'HAFTA 2: FELAKETTEN KURTARMA PLANI ÖZETI'
PRINT '========================================='
SELECT 
    ScenarioName,
    RTO_Minutes AS 'RTO (dakika)',
    RPO_Minutes AS 'RPO (dakika)',
    BackupStrategy,
    Status
FROM dbo.DisasterRecoveryPlan
WHERE Week = 2
ORDER BY RTO_Minutes ASC
GO

-- ================================================================================
-- BAKIMI VE MONİTÖRLÜ İŞLEMLER
-- ================================================================================

-- Yedekleme İşlerinin Durumu Kontrol Etme
SELECT 
    job_id,
    name AS JobName,
    enabled,
    date_created,
    date_modified
FROM msdb.dbo.sysjobs
WHERE name LIKE '%Backup%' OR name LIKE '%Restore%'
GO

-- Veritabanının Son Yedekleme Tarihleri
SELECT 
    d.name AS DatabaseName,
    MAX(CASE WHEN bs.type = 'D' THEN bs.backup_finish_date END) AS LastFullBackup,
    MAX(CASE WHEN bs.type = 'I' THEN bs.backup_finish_date END) AS LastDifferentialBackup,
    MAX(CASE WHEN bs.type = 'L' THEN bs.backup_finish_date END) AS LastLogBackup
FROM sys.databases d
LEFT JOIN msdb.dbo.backupset bs ON d.name = bs.database_name
WHERE d.name = 'AdventureWorks2022'
GROUP BY d.name
GO

