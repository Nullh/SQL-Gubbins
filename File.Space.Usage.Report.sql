USE ss_fwuatest

SELECT
    a.FILEID,
    CONVERT(decimal(12,2),ROUND(a.size/128.000,2)) as [FILESIZEINMB] ,
    CONVERT(decimal(12,2),ROUND(fileproperty(a.name,'SpaceUsed')/128.000,2)) as [SPACEUSEDINMB],
    CONVERT(decimal(12,2),ROUND((a.size-fileproperty(a.name,'SpaceUsed'))/128.000,2)) as [FREESPACEINMB],
    a.name as [DATABASENAME],
    a.FILENAME as [FILENAME]
FROM dbo.sysfiles a