-- WARNING: This script WILL DELETE ALL DATA from the target database. Use with caution. Do not run if you're unsure the reprocussions

/* 
   This script will do the following:
      1. Disable all table constraints
      2. Create a list of all tables, across all schemas (Apart from system tables and diagrams)
      3. Cycle through all tables above, using DELETE FROM to remove all data (This is to avoid constraint issues)
      4. Re-Enable Table Constraints 
*/
USE <DB name>; -- Update <DB Name> to match the name of the target database to remove data from
GO

-- Disable all constraints in the database
EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"

DECLARE @catalog NVARCHAR(250);
DECLARE @schema NVARCHAR(250);
DECLARE @tbl NVARCHAR(250);
DECLARE @rowCount INT;
DECLARE @totalRows INT;

DECLARE i CURSOR LOCAL FAST_FORWARD FOR
SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
AND TABLE_NAME NOT IN ('sysdiagrams', '__RefactorLog');

OPEN i;
FETCH NEXT FROM i INTO @catalog, @schema, @tbl;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Get the total number of rows in the current table
    DECLARE @countSQL NVARCHAR(MAX) = N'SELECT @totalRows = COUNT(*) FROM [' + @catalog + '].[' + @schema + '].[' + @tbl + '];';
    EXEC sp_executesql @countSQL, N'@totalRows INT OUTPUT', @totalRows OUTPUT;
    
    PRINT 'Starting deletion for table [' + @tbl + ']. Total rows to delete: ' + CAST(@totalRows AS NVARCHAR(20));
    
    -- Execute deletion in batches to avoid transaction log issues (adjust batch size as needed)
    DECLARE @batchSize INT = 100000;  -- Define batch size
    DECLARE @deletedRows INT = 0;   -- Track total deleted rows
    
    WHILE 1 = 1
    BEGIN
        DECLARE @innerSQL NVARCHAR(MAX) = N'DELETE TOP (' + CAST(@batchSize AS NVARCHAR(10)) + ') FROM [' + @catalog + '].[' + @schema + '].[' + @tbl + '];';
        EXEC sp_executesql @innerSQL;

        SET @rowCount = @@ROWCOUNT;  -- Get the number of rows deleted in the last batch
        SET @deletedRows = @deletedRows + @rowCount;  -- Accumulate the deleted row count
        
        IF @rowCount = 0 BREAK;  -- Exit loop if no more rows are deleted
        
        PRINT 'Deleted ' + CAST(@deletedRows AS NVARCHAR(10)) + ' out of ' + CAST(@totalRows AS NVARCHAR(20)) + ' rows from [' + @tbl + ']...';
    END
    
    PRINT 'Finished deleting data from table: [' + @tbl + ']';
    
    FETCH NEXT FROM i INTO @catalog, @schema, @tbl;
END;

CLOSE i;
DEALLOCATE i;

-- Re-enable all constraints again
EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";