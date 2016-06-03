use AdventureWorks2012;
GO

DECLARE 
      @i int = 0, 
      @SalesOrderID int, 
      @Comment nvarchar(128) = 'Test trasaction'; 

WHILE (@i < 20) 
BEGIN; 
      EXEC Sales.GenerateTransactions @SalesOrderID OUTPUT, @Comment; 
      SET @i += 1 
END