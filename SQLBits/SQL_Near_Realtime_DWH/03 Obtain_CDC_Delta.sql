use AdventureWorks2012;
GO
/* Obtain the current synchronization version. 
This will be used the next time CHANGETABLE(CHANGES...) is called. */
DECLARE @synchronization_version BIGINT
	  , @last_synchronization_version BIGINT = 360
SET @synchronization_version = CHANGE_TRACKING_CURRENT_VERSION();

/* Obtain incremental changes by using the synchronization version obtained 
the last time the data was synchronized.*/
SELECT
    SOH.*,
    CT.SYS_CHANGE_OPERATION,
	@synchronization_version as Synchronization_version 
FROM
    Sales.SalesOrderHeader AS SOH
RIGHT OUTER JOIN
    CHANGETABLE(CHANGES Sales.SalesOrderHeader, @last_synchronization_version) AS CT
ON
    SOH.SalesOrderID = CT.SalesOrderID

print @synchronization_version