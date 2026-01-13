WITH datamart_list AS (
    SELECT
        UPPER('MARD_' || SOL_PROD_TOKEN) AS datamart_name
    FROM
        mard_mdna.v_all_solutions_mdna
    WHERE
        SOL_PROD_TOKEN IS NOT NULL
),
-- Pre-filter SQL to only those containing 'MARD_'
filtered_sql AS (
    SELECT 
        sa.sql_id,
        sa.last_active_time,
        sa.parsing_schema_name,
        sa.sql_text,
        UPPER(sa.sql_text) AS sql_text_upper,
        sa.executions
    FROM 
        gv$sqlarea sa
    WHERE 
        LENGTH(sa.sql_text) <= 1000
        AND sa.last_active_time >= SYSDATE - 7
        AND sa.parsing_schema_name IS NOT NULL
        AND UPPER(sa.sql_text) LIKE '%MARD_%'  -- Pre-filter
),
results AS (
    SELECT DISTINCT
        fs.sql_id,
        fs.last_active_time,
        u.username,
        dm.datamart_name,
        LENGTH(fs.sql_text) AS stmt_length,
        SUBSTR(fs.sql_text, 1, 500) AS stmt_sample,
        fs.executions,
        fs.parsing_schema_name
    FROM 
        filtered_sql fs
    INNER JOIN
        all_users u ON fs.parsing_schema_name = u.username
    CROSS JOIN
        datamart_list dm
    WHERE 
        INSTR(fs.sql_text_upper, dm.datamart_name || '.') > 0
)
SELECT 
    sql_id AS QueryID,
    TO_CHAR(last_active_time, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP,
    username AS USER_ID,
    datamart_name AS Datamart,
    stmt_length AS Statement_Length,
    stmt_sample AS Statement_Sample,
    executions AS Execution_Count,
    parsing_schema_name AS Parsing_Schema
FROM results
ORDER BY 
    last_active_time DESC, sql_id, datamart_name;