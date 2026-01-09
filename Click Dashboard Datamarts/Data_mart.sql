SELECT DISTINCT
    v_users.username AS User_Name,
    CASE 
        WHEN UPPER(v_sql.sql_text) LIKE '%MARD_FSP.%' THEN 'MARD_FSP'
        WHEN UPPER(v_sql.sql_text) LIKE '%MARD_MDNA.%' THEN 'MARD_MDNA'
        ELSE TRIM(REPLACE(REGEXP_SUBSTR(UPPER(v_sql.sql_text), '[A-Z0-9_]+\.', 1, 1), '.', ''))
    END AS Schema_Name,
    v_hist.session_id AS Session_ID,
    v_hist.max_sample_time AS Time_Stamp,
    v_hist.sql_id AS SQL_Query_ID,
    SUBSTR(v_sql.sql_text, 1, 500) AS SQL_Preview,  -- Limited to 500 characters
    LENGTH(v_sql.sql_text) AS SQL_Text_Length       -- NEW COLUMN: Total character count
FROM 
(
    SELECT 
        sql_id, 
        SQL_OPCODE, 
        user_id,
        session_id,
        MAX(sample_time) AS max_sample_time
    FROM gv$ACTIVE_SESSION_HISTORY
    WHERE sql_id IS NOT NULL
        AND SQL_OPCODE = 3
        AND sample_time > SYSDATE - 2/24  -- Last 2 hours
    GROUP BY
        sql_id, 
        SQL_OPCODE,
        user_id,
        session_id
) v_hist
INNER JOIN (
    SELECT user_id, username 
    FROM all_users
    WHERE username NOT LIKE 'BUSV%' 
        AND username NOT LIKE 'HRMZ%' 
        AND username NOT LIKE 'MARD%' 
        AND username NOT LIKE 'MARS%' 
        AND username NOT LIKE 'RAWB%' 
        AND username NOT LIKE 'RAWO%'  
        AND username NOT LIKE 'RAWV%' 
        AND username NOT LIKE 'REDL%' 
        AND username NOT LIKE 'REFM%'   
        AND username NOT LIKE 'STAG%' 
        AND username NOT LIKE 'SYS%'
) v_users ON v_hist.user_id = v_users.user_id
LEFT JOIN (    
    SELECT DISTINCT sql_id, sql_text
    FROM gv$sqlarea
    WHERE sql_id IS NOT NULL 
        AND COMMAND_TYPE = 3
        AND (UPPER(sql_text) LIKE '%MARD_FSP.%' 
             OR UPPER(sql_text) LIKE '%MARD\_FSP.%' ESCAPE '\')
) v_sql ON v_sql.sql_id = v_hist.sql_id
WHERE v_sql.sql_text IS NOT NULL
ORDER BY v_hist.max_sample_time DESC;

SELECT  a.*, 'MARD_'a.SL_PROD_TOKEN AS MARD_FILTER
FROM    mard_mdna.v_all_solutions_mdna a;

Select * from mard_mdna.v_all_solutions_mdna;

SELECT
    column_id,
    column_name,
    data_type,
    data_length,
    data_precision,
    data_scale,
    nullable
FROM   all_tab_columns
WHERE  owner      = 'MARD_MDNA'
AND    table_name = 'V_ALL_SOLUTIONS_MDNA'
ORDER  BY column_id;


SELECT
    b.MARD_FILTER
FROM
    (
        SELECT
            'MARD_' || SOL_PROD_TOKEN AS MARD_FILTER
        FROM
            mard_mdna.v_all_solutions_mdna
    ) b;

SELECT
    'MARD_' || SOL_PROD_TOKEN AS MARD_FILTER
FROM
    mard_mdna.v_all_solutions_mdna
order by MARD_FILTER;