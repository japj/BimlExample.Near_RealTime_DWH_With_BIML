--Enable CDC on instance
USE AdventureWorks2012
GO
EXEC sys.sp_cdc_disable_db

--Add filegroup to hold CDC data (not required, but recommended)
USE master
GO
ALTER DATABASE AdventureWorks2012 ADD FILEGROUP CDC
GO

--Enable tables for CDC tracking
USE AdventureWorks2012
GO

EXEC sys.sp_cdc_enable_table
@source_schema = N'Sales',
@source_name   = N'SalesOrderDetail',
@role_name     = N'CDC_Readers',
@filegroup_name = N'CDC',
@supports_net_changes = 1 --returns only the latest state of the row