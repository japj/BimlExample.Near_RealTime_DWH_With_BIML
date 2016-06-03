/*
EXEC Sales.CDC_SalesOrderDetail @last_synchronization_version=0
EXEC Sales.CDC_SalesOrderDetail @last_synchronization_version=0, @Incremental_Load = 0
*/

ALTER PROCEDURE Sales.CDC_SalesOrderDetail
(
 @Incremental_Load bit = 1,
 @last_synchronization_version BIGINT
)
AS
DECLARE @synchronization_version BIGINT
SET @synchronization_version = CHANGE_TRACKING_CURRENT_VERSION();

--Full load
IF (@Incremental_Load = 0)
 BEGIN
	SELECT
		SOD.*,
		'I' as SYS_CHANGE_OPERATION,
		0 as Synchronization_version 
	FROM
		Sales.SalesOrderDetail AS SOD
 END
ELSE
 BEGIN
-- Obtain incremental changes by using the synchronization version obtained the last time the data was synchronized.
	SELECT
		SOD.*,
		CT.SYS_CHANGE_OPERATION,
		@synchronization_version as Synchronization_version 
	FROM
		Sales.SalesOrderDetail AS SOD
	RIGHT OUTER JOIN
		CHANGETABLE(CHANGES Sales.SalesOrderDetail, @last_synchronization_version) AS CT
	ON
		SOD.SalesOrderID = CT.SalesOrderID
		AND SOD.SalesOrderDetailID = CT.SalesOrderDetailID
 END