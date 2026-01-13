SELECT
    s.sql_id AS QueryID,
    s.last_active_time AS "TIMESTAMP",
    u.username AS USER_ID,
    -- Converted to TO_CHAR for datatype consistency
    TO_CHAR(REGEXP_SUBSTR(s.sql_fulltext, '(?:FROM|JOIN|UPDATE|INTO)\s+([a-zA-Z0-9_]+)\.', 1, 1, 'i', 1)) AS Schema_Parsed,
    LENGTH(s.sql_fulltext) AS "Statement_Length",
    SUBSTR(s.sql_fulltext, 1, 500) AS Statement_Sample
FROM
    V$SQL s
JOIN
    DBA_USERS u ON s.parsing_user_id = u.user_id
WHERE
    REGEXP_LIKE(s.sql_fulltext, '(?:FROM|JOIN|UPDATE|INTO)\s+([a-zA-Z0-9_]+)\.', 'i')

    /*
    --vvv-- CORRECTED FILTER SECTION --vvv--
    -- Added TO_CHAR() to convert the CLOB result before passing it to UPPER()
    */
    AND UPPER(TO_CHAR(REGEXP_SUBSTR(s.sql_fulltext, '(?:FROM|JOIN|UPDATE|INTO)\s+([a-zA-Z0-9_]+)\.', 1, 1, 'i', 1))) IN ('MARD_FSP', 'MARD_PROMACO')
    /*
    --^^^-- END CORRECTED FILTER SECTION --^^^--
    */

    AND s.sql_fulltext NOT LIKE '%V$SQL%'
ORDER BY
    s.last_active_time DESC;

-- Diagnostic Query 1: Show any schemas being found
SELECT
    TO_CHAR(REGEXP_SUBSTR(s.sql_fulltext, '(?:FROM|JOIN|UPDATE|INTO)\s+([a-zA-Z0-9_]+)\.', 1, 1, 'i', 1)) AS Schema_Parsed,
    u.username AS USER_ID,
    SUBSTR(s.sql_fulltext, 1, 500) AS Statement_Sample,
    s.last_active_time
FROM
    V$SQL s
JOIN
    DBA_USERS u ON s.parsing_user_id = u.user_id
WHERE
    -- This condition finds statements that *should* contain a schema reference
    REGEXP_LIKE(s.sql_fulltext, '(?:FROM|JOIN|UPDATE|INTO)\s+([a-zA-Z0-9_]+)\.', 'i')
    AND s.sql_fulltext NOT LIKE '%V$SQL%'
-- Limit to the most recent 20 rows for a quick check
FETCH FIRST 20 ROWS ONLY;

