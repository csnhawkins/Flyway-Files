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

declare @catalog nvarchar(250);
declare @schema nvarchar(250);
declare @tbl nvarchar(250);
DECLARE i CURSOR LOCAL FAST_FORWARD FOR select
                                        TABLE_CATALOG,
                                        TABLE_SCHEMA,
                                        TABLE_NAME
                                        from INFORMATION_SCHEMA.TABLES
                                        where
                                        TABLE_TYPE = 'BASE TABLE'
                                        AND TABLE_NAME != 'sysdiagrams'
                                        AND TABLE_NAME != '__RefactorLog'

OPEN i;
FETCH NEXT FROM i INTO @catalog, @schema, @tbl;
WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql NVARCHAR(MAX) = N'DELETE FROM [' + @catalog + '].[' + @schema + '].[' + @tbl + '];'
        /* Make sure these are the commands you want to execute before executing */
        PRINT 'Executing statement: ' + @sql
        -- EXECUTE sp_executesql @sql
        FETCH NEXT FROM i INTO @catalog, @schema, @tbl;
    END
CLOSE i;
DEALLOCATE i;

-- Re-enable all constraints again
EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"