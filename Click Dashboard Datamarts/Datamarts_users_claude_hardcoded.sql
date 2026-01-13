WITH datamart_list AS (
    SELECT 'MARD_PROMACO' AS datamart_name FROM DUAL
    UNION ALL
    SELECT 'MARD_FSP' FROM DUAL
)
SELECT DISTINCT
    sa.sql_id AS QueryID,
    TO_CHAR(sa.last_active_time, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP,
    u.username AS USER_ID,
    dm.datamart_name AS Datamart,
    LENGTH(sa.sql_text) AS Statement_Length,
    SUBSTR(sa.sql_text, 1, 500) AS Statement_Sample,
    sa.executions AS Execution_Count,
    sa.parsing_schema_name AS Parsing_Schema
FROM 
    gv$sqlarea sa
INNER JOIN
    all_users u ON sa.parsing_schema_name = u.username
CROSS JOIN
    datamart_list dm
WHERE 
    UPPER(sa.sql_text) LIKE '%' || dm.datamart_name || '.%'
    AND LENGTH(sa.sql_text) <= 1000
    AND sa.last_active_time >= SYSDATE - 7
ORDER BY TIMESTAMP desc;