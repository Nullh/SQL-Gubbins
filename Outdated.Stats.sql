-- Preferred version
SELECT 
  st.object_id                          AS [Table ID]
, OBJECT_NAME(st.object_id)             AS [Table Name]
, st.name                               AS [Index Name]
, STATS_DATE(st.object_id, st.stats_id) AS [LastUpdated]
, modification_counter                  AS [Rows Modified]
, sp.rows								AS [Total Rows]
FROM
sys.stats st 
CROSS APPLY
sys.dm_db_stats_properties(st.object_id, st.stats_id) AS sp 
WHERE
STATS_DATE(st.object_id, st.stats_id)<=DATEADD(MONTH,-1,GETDATE())  
AND modification_counter > (sp.rows-modification_counter)/5
AND OBJECTPROPERTY(st.object_id,'IsUserTable')=1
AND sp.rows > 1000
GO

---------------------------------------------------------------------
-- Legacy version fro Compat 90
SELECT
  id                    AS [Table ID]
, OBJECT_NAME(id)       AS [Table Name]
, name                  AS [Index Name]
, STATS_DATE(id, indid) AS [LastUpdated]
, rowmodctr             AS [Rows Modified]
, rows					AS [Total Rows]
FROM sys.sysindexes 
WHERE STATS_DATE(id, indid)<=DATEADD(MONTH,-1,GETDATE()) 
AND rows > 1000
AND rowmodctr > (rows-rowmodctr)/5
AND (OBJECTPROPERTY(id,'IsUserTable'))=1
GO
