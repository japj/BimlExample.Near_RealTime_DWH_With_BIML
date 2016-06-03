USE [AdventureWorks2012]
GO

/****** Object:  Index [NonClusteredColumnStoreIndex-20130926-125732]    Script Date: 08-11-2014 10:55:54 ******/
DROP INDEX [NonClusteredColumnStoreIndex-20130926-125732] ON [Sales].[SalesOrderDetail]
GO

sp_changedbowner 'sa'
GO

select * into sales.SalesOrderDetailBase from sales.SalesOrderDetail
GO

