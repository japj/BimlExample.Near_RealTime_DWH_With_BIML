use AdventureWorksStaging2012;
GO

set nocount on
IF OBJECT_ID('tempdb..#tmp') IS NOT NULL
  DROP TABLE #tmp

create table #tmp ( TableName sysname, type varchar(10), updated varchar(3), selected varchar(3), columnName sysname)
insert into #tmp
exec sys.sp_depends @objname = 'Src_SalesOrderHeader'

Select distinct 'Src_SalesOrderHeader' as Src, substring(TableName, charindex('.',TableName)+1, len(TableName)) as Component from #tmp where selected = 'yes'
union
select name, sourcetableName_name from [MDS].[mdm].[mdsDataMartTables] where sourcetableName_name is not null