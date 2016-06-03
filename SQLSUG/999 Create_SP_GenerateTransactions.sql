ALTER PROCEDURE Sales.GenerateTransactions
(
	@SalesOrderID int OUTPUT,	
	@Comment nvarchar(128) = NULL
)
as

	  DECLARE @OrderDate datetime2 = sysdatetime()
	  DECLARE @DueDate datetime2 = dateadd(d,2, @OrderDate),
              @CustomerID int = (SELECT TOP 1 CustomerID from sales.Customer ORDER BY NEWID()), 
              @BillToAddressID int = (SELECT TOP 1 AddressID from Person.Address ORDER BY NEWID()), 
              @ShipToAddressID int = (SELECT TOP 1 AddressID from Person.Address ORDER BY NEWID()), 
              @ShipMethodID int = (SELECT TOP 1 ShipMethodID from Purchasing.ShipMethod ORDER BY NEWID()),
			  @OnlineOrderFlag bit = rand();  

	INSERT INTO Sales.SalesOrderHeader
	(	OrderDate,
		DueDate,
		OnlineOrderFlag,
		CustomerID,
		BillToAddressID,
		ShipToAddressID,
		ShipMethodID,
		Comment,
		ModifiedDate)
	VALUES
	( 	@OrderDate,
		@DueDate,
		@OnlineOrderFlag,
		@CustomerID,
		@BillToAddressID,
		@ShipToAddressID,
		@ShipMethodID,
		@Comment,
		getdate()
	)
	SELECT @SalesOrderID = @@IDENTITY

	INSERT INTO Sales.SalesOrderDetail
	(
		SalesOrderID,
		OrderQty,
		ProductID,
		SpecialOfferID,
		UnitPrice,
		UnitPriceDiscount,
		ModifiedDate
	)
    SELECT TOP 1
		@SalesOrderID,
		od.OrderQty,
		od.ProductID,
		od.SpecialOfferID,
		p.ListPrice,
		p.ListPrice * so.DiscountPct,
		@OrderDate
	FROM Sales.SalesOrderDetailBase od JOIN Sales.SpecialOffer so 
			on od.SpecialOfferID=so.SpecialOfferID
		JOIN Production.Product p 
			on od.ProductID=p.ProductID


	DECLARE @SubTotal money

	SELECT @SubTotal = ISNULL(SUM(UnitPrice - UnitPriceDiscount),0)
	FROM Sales.SalesOrderDetail
	WHERE SalesOrderID = @SalesOrderID

	UPDATE Sales.SalesOrderHeader
	Set SubTotal = @SubTotal
	WHERE SalesOrderID = @SalesOrderID

GO