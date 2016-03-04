--Reindex and Reorganise Indexes on a Single Table.sql
--Asseses the level of fragmentation on all indices
--and rebuild the index if over 30% fragmented
--reorganise if more than 10% but less than 30%

--Neil Holmes 28/07/2010

--Decleare the variables
declare @indexname varchar(50)
declare @fragpercent float

declare @tableName varchar(50)
declare @databaseName varchar(50)

-- Set the table to reindex
set @tableName = 'case_notes'
set @databaseName = 'ss_fwprod_copy'

exec('use ' + @databaseName)


--Setup the cursor
declare table_indices cursor for 
select idx.name, phys.avg_fragmentation_in_percent
from
sys.dm_db_index_physical_stats(db_id(@databaseName), object_id(@tableName), null, null, null) phys
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
	--Check if the table is heavily fragmented
	if @fragpercent >= 30 
	begin
		--If over 30% fragmented rebuild the index
		print 'Index ' + @indexname + ' is ' + cast(@fragpercent as varchar(50)) + '% fragmented, attempting to rebuild'
		exec('alter index ' + @indexname + ' on ' + @tableName + ' rebuild;')
	end
	else
	begin 
		--If less than 30% (but more than 10% - from the select in the cursor) reorganise the index
		print 'Index ' + @indexname + ' is ' + cast(@fragpercent as varchar(50)) + '% fragmented, attempting to reorganize'
		exec('alter index ' + @indexname + ' on ' + @tableName + ' reorganize;')
	end

	--Next entry in the cursor
	fetch next from table_indices into @indexname, @fragpercent
end

--Clean up the cursor
close table_indices
deallocate table_indices