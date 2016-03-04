--Reindex and Reorganise Indexes.sql
--Asseses the level of fragmentation on all indices
--on all tables within a given database
--and rebuild the index if over 30% fragmented
--reorganise if more than 10% but less than 30%

--Neil Holmes 14/12/2010

--Declare the variables
declare @indexname varchar(50)
declare @fragpercent float
declare @tablename varchar(100)
declare @schemaname varchar(50)
declare @fulltablename varchar(150)

--declare @tableName varchar(50)
declare @databaseName varchar(50)

-- Set the table to reindex
set @tableName = 'case_notes'
set @databaseName = 'ss_fwprod_DB96'

exec('use ' + @databaseName)

--set a cursor to select the name of every table in the database
declare database_tables cursor for
select sch.name, tab.name from sys.tables as tab
join sys.schemas as sch on tab.schema_id = sch.schema_id

-- Run the cursor
open database_tables
fetch next from database_tables into @schemaname, @tablename

--run while we have data in the cursor
while @@fetch_status = 0
begin
	--Build the table name
	set @fulltablename = '[' + @schemaname + '].[' + @tablename + ']'
	--Setup the cursor
	declare table_indices cursor for 
	select idx.name, phys.avg_fragmentation_in_percent
	from
	sys.dm_db_index_physical_stats(db_id(@databaseName), object_id(@fulltablename), null, null, null) phys
	inner join sys.indexes idx
	on idx.object_id = phys.object_id
	and idx.index_id = phys.index_id
	where
	phys.avg_fragmentation_in_percent > 10
	order by 1

	--Open our cursor
	open table_indices
	fetch next from table_indices into @indexname, @fragpercent

	--While we have data in the cursor
	while @@fetch_status = 0
	begin
		--print 'Index is: ' + @indexname
		--print 'Table name is: ' + @fulltablename
		
		--Check we're not looking at at heap, if so skip
		if @indexname != ''
		begin
			--Check if the table is heavily fragmented
			if @fragpercent >= 30 
			begin
				--If over 30% fragmented rebuild the index
				print 'Index ' + @indexname + ' on ' + @fulltablename + ' is ' + cast(@fragpercent as varchar(50)) + '% fragmented, attempting to rebuild'
				exec('alter index ' + @indexname + ' on ' + @fulltablename + ' rebuild;')
			end
			else
			begin 
				--If less than 30% (but more than 10% - from the select in the cursor) reorganise the index
				print 'Index ' + @indexname + ' on ' + @fulltablename + ' is ' + cast(@fragpercent as varchar(50)) + '% fragmented, attempting to reorganize'
				exec('alter index ' + @indexname + ' on ' + @fulltablename + ' reorganize;')
			end
		end
		else
		begin
			print 'Index on ' + @fulltablename + ' is a heap. Skipping'
		end

		--Next entry in the cursor
		fetch next from table_indices into @indexname, @fragpercent
	end

	--Clean up the cursor
	close table_indices
	deallocate table_indices

	--grab the next table from the cursor
	fetch next from database_tables into @schemaname, @tablename
end
close database_tables
deallocate database_tables