WITH mard_filters AS (
    -- Step 1: Dynamically generate the list of filters to search for.
    SELECT
        'MARD_' || SOL_PROD_TOKEN AS MARD_FILTER
    FROM
        mard_mdna.v_all_solutions_mdna
), 
filtered_sql AS (
    -- Step 2: Find all SQL statements that match any of the dynamic filters.
    -- The matched filter is also selected to be used as the Schema_Name.
    SELECT DISTINCT
        g.sql_id,
        g.sql_text,
        mf.MARD_FILTER AS matched_schema
    FROM 
        gv$sqlarea g,
        mard_filters mf
    WHERE 
        g.sql_id IS NOT NULL
        AND g.COMMAND_TYPE = 3
        -- The join condition dynamically checks for each filter in the sql_text.
        -- The underscore in the filter name is properly escaped.
        AND UPPER(g.sql_text) LIKE '%' || REPLACE(mf.MARD_FILTER, '_', '\_') || '.%' ESCAPE '\'
)
-- Step 3: Main query now joins against the pre-filtered SQL statements.
SELECT DISTINCT
    v_users.username AS User_Name,
    v_sql.matched_schema AS Schema_Name, -- The hardcoded CASE is replaced with the matched schema.
    v_hist.session_id AS Session_ID,
    v_hist.max_sample_time AS Time_Stamp,
    v_hist.sql_id AS SQL_Query_ID,
    SUBSTR(v_sql.sql_text, 1, 500) AS SQL_Preview,
    LENGTH(v_sql.sql_text) AS SQL_TEXT_LENGTH
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
-- Use a LEFT JOIN to our new filtered_sql CTE.
LEFT JOIN filtered_sql v_sql ON v_hist.sql_id = v_sql.sql_id
-- Ensure we only get results that had a matching SQL statement.
WHERE v_sql.sql_id IS NOT NULL
ORDER BY v_hist.max_sample_time DESC;