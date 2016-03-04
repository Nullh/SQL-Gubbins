create table #Jobs
(job_owner varchar(30), 
-- For SQL Server 2000 change job_name 
-- to varchar(100) or more
job_name varchar(MAX),
job_enabled tinyint);

insert into #Jobs
select SUSER_SNAME(sj.owner_sid) as job_owner,
name,
enabled
from msdb..sysjobs as sj
order by job_owner;

select * from #Jobs 
where job_owner like 'Derbyshire\A9360247'
or job_owner like 'Derbyshire\A9361939';

drop table #Jobs;
