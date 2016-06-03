--Enable CDC on instance
USE AdventureWorks2012
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_databases 
               WHERE database_id = DB_ID())
BEGIN
     ALTER DATABASE AdventureWorks2012
     SET CHANGE_TRACKING = ON
     (CHANGE_RETENTION = 5 DAYS, AUTO_CLEANUP = ON);
END

--Enable tables for CDC tracking
USE AdventureWorks2012
GO

IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables 
               WHERE object_id = OBJECT_ID('Sales.SalesOrderDetail'))
BEGIN
     ALTER TABLE Sales.SalesOrderDetail
     ENABLE CHANGE_TRACKING
     WITH (TRACK_COLUMNS_UPDATED = OFF)
END

IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables 
               WHERE object_id = OBJECT_ID('Sales.SalesOrderHeader'))
BEGIN
     ALTER TABLE Sales.SalesOrderHeader
     ENABLE CHANGE_TRACKING
     WITH (TRACK_COLUMNS_UPDATED = OFF)
END

--Start the CDC job
EXEC sys.sp_cdc_start_job
	@job_type = N'capture'

--Verify that CDC is active
SELECT OBJECT_NAME(object_id) [TABLE_NAME]
FROM sys.change_tracking_tables;
