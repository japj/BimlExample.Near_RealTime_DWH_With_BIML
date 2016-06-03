set nocount on
drop table #tmp
create table #tmp ( TableName sysname, type varchar(10), updated varchar(3), selected varchar(3), columnName sysname)
insert into #tmp
exec sys.sp_depends Src_SalesOrderHeader

Select distinct 'Src_SalesOrderHeader' as Src, substring(TableName, charindex('.',TableName)+1, len(TableName)) as Component from #tmp where selected = 'yes'
union
select name, sourcetableName_name from [MDS].[mdm].[mdsDataMartTables] where sourcetableName_name is not null