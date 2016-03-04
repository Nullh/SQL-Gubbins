SELECT 'GRANT ' + dp.permission_name collate latin1_general_cs_as
    + ' ON ' + s.name + '.' + o.name + ' TO ' + dpr.name 
    FROM sys.database_permissions AS dp
    INNER JOIN sys.objects AS o ON dp.major_id=o.object_id
    INNER JOIN sys.schemas AS s ON o.schema_id = s.schema_id
    INNER JOIN sys.database_principals AS dpr ON dp.grantee_principal_id=dpr.principal_id
    WHERE dpr.name NOT IN ('public','guest')
    -- AND permission_name='EXECUTE'