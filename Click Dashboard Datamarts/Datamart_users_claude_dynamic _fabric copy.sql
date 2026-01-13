SELECT DISTINCT
    fs.sql_id AS QueryID,
    TO_CHAR(fs.last_active_time, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP,
    u.username AS USER_ID,
    dm.datamart_name AS Datamart,
    CAST(LENGTH(fs.sql_text) AS INTEGER) AS Statement_Length,
    SUBSTR(fs.sql_text, 1, 500) AS Statement_Sample,
    CAST(fs.executions AS INTEGER) AS Execution_Count,
    fs.parsing_schema_name AS Parsing_Schema
FROM
    (
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
            AND UPPER(sa.sql_text) LIKE '%MARD_%'
    ) fs
INNER JOIN
    all_users u ON fs.parsing_schema_name = u.username
CROSS JOIN
    (
        SELECT
            UPPER('MARD_' || SOL_PROD_TOKEN) AS datamart_name
        FROM
            mard_mdna.v_all_solutions_mdna
        WHERE
            SOL_PROD_TOKEN IS NOT NULL
    ) dm
WHERE
    INSTR(fs.sql_text_upper, dm.datamart_name || '.') > 0