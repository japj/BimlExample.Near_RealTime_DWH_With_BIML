use AdventureWorksStaging2012;
GO

--Create meta table
CREATE TABLE [dbo].[TableNames](
       [TableName] [nvarchar](256) NOT NULL
)


-- add tablename 
insert into tablenames (tableName)
values ('Currency')


/*
DROP TABLE [dbo].[TableNames]
*/
