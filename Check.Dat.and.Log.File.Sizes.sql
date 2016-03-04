--==================================================--
-- Script to find the total size and free space of	--
-- data and log files.								--
-- Neil Holmes 20/04/2011							--
--==================================================--

--Set the database to be checked
use ss_fwuatest
go

declare @datasize int
declare @datafree int
declare @logsize int
declare @logfree float
declare @database nvarchar(100)
declare @datafilename nvarchar(100)
set @database = db_name()


set @datafilename = N'chconfig_data' 

-- Get the used data file space
create table #dataspace
(	[Fileid] smallint,
	[FileGroup] smallint,
	[TotalExtents] int,
	[UsedExtents] int,
	[Name] nvarchar(100),
	[FileName] nvarchar(100))

insert into #dataspace 
exec ('dbcc showfilestats')

set @datasize = (select (TotalExtents *64) 
	from #dataspace where Name like @datafilename)
set @datafree = (select ((TotalExtents - UsedExtents) *64) 
	from #dataspace where Name like @datafilename)

drop table #dataspace

-- Get the used log file space
create table #logspace
(	[Database Name] nvarchar(100),
	[Log Size (MB)] float,
	[Log Space Used (%)] float,
	[Status] bit)

insert into #logspace 
exec ('dbcc sqlperf(logspace)')

set @logsize = (select ([Log Size (MB)] * 1024) 
	from #logspace where [Database Name] like @database)
set @logfree = (select (([Log Size (MB)]-(([Log Size (MB)]/100)*[Log Space Used (%)]))*1024) 
	from #logspace where [Database Name] like @database)

drop table #logspace

-- Select the results
select @datasize as [Data File Size (KB)], 
	@datafree as [Data File Free Space (KB)], 
	@logsize as [Log File Size (KB)], 
	@logfree as [Log File Free Space (KB)]

-- Alternative text output	
--select 'Data file size is ' + convert(nvarchar(100),@datasize) + 'KB with ' 
--	+ convert(nvarchar(100),@datafree) + 'KB free.' + CHAR(13) +
--	'Log file is ' + convert(nvarchar(100),@logsize) + 'KB with ' 
--	+ convert(nvarchar(100),@logfree) + 'KB free.'