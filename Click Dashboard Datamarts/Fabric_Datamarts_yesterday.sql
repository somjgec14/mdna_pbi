SELECT *
FROM (
    SELECT DISTINCT
        v_users.username AS User_Name,
        TRIM(REPLACE(
              REGEXP_SUBSTR(UPPER(v_sql.sql_text), '[A-Z0-9_]+\.', 1, 1),
              '.', ''
        )) AS Parsed_Schema,
        v_hist.session_id      AS Session_ID,
        v_hist.max_sample_time AS Time_Stamp,
        v_hist.sql_id          AS SQL_Query_ID,
        SUBSTR(v_sql.sql_text, 1, 500) AS SQL_Preview,
        LENGTH(v_sql.sql_text) AS SQL_Text_Length
    FROM (
        SELECT 
            sql_id, 
            SQL_OPCODE, 
            user_id,
            session_id,
            MAX(sample_time) AS max_sample_time
        FROM DBA_HIST_ACTIVE_SESS_HISTORY
        WHERE sql_id IS NOT NULL
          AND SQL_OPCODE = 3
          AND sample_time >= TRUNC(SYSDATE - 1)
          AND sample_time < TRUNC(SYSDATE)
        GROUP BY sql_id, SQL_OPCODE, user_id, session_id
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
    ) v_sql ON v_sql.sql_id = v_hist.sql_id
    WHERE v_sql.sql_text IS NOT NULL
) q
JOIN (
    SELECT 'MARD_ECQD' AS schema_name FROM dual UNION ALL
    SELECT 'MARD_PJRM' FROM dual UNION ALL
    SELECT 'MARD_CELBBM' FROM dual UNION ALL
    SELECT 'MARD_DRPINT' FROM dual UNION ALL
    SELECT 'MARD_CSI' FROM dual UNION ALL
    SELECT 'MARD_FSP' FROM dual UNION ALL
    SELECT 'MARD_XREF' FROM dual UNION ALL
    SELECT 'MARD_ETASPDB' FROM dual UNION ALL
    SELECT 'MARD_PROMACO' FROM dual UNION ALL
    SELECT 'MARD_PLCM' FROM dual UNION ALL
    SELECT 'MARD_ETASSC' FROM dual UNION ALL
    SELECT 'MARD_S4MPDM' FROM dual UNION ALL
    SELECT 'MARD_MDNACLOUD' FROM dual UNION ALL
    SELECT 'MARD_BBMEBOARDCPC' FROM dual UNION ALL
    SELECT 'MARD_ECMF' FROM dual UNION ALL
    SELECT 'MARD_MDNA' FROM dual UNION ALL
    SELECT 'MARD_SCDP' FROM dual UNION ALL
    SELECT 'MARD_BBMSP' FROM dual UNION ALL
    SELECT 'MARD_TCQ' FROM dual UNION ALL
    SELECT 'MARD_MINV' FROM dual UNION ALL
    SELECT 'MARD_PSLA' FROM dual UNION ALL
    SELECT 'MARD_QMAP' FROM dual UNION ALL
    SELECT 'MARD_ETASFNO' FROM dual UNION ALL
    SELECT 'MARD_8DAIINT' FROM dual UNION ALL
    SELECT 'MARD_MSMDNAOUTINT' FROM dual UNION ALL
    SELECT 'MARD_IDC' FROM dual UNION ALL
    SELECT 'MARD_S2C' FROM dual UNION ALL
    SELECT 'MARD_ELPC' FROM dual UNION ALL
    SELECT 'MARD_MGMC' FROM dual UNION ALL
    SELECT 'MARD_SARA' FROM dual UNION ALL
    SELECT 'MARD_SPREP' FROM dual UNION ALL
    SELECT 'MARD_EPLMNAV' FROM dual UNION ALL
    SELECT 'MARD_PLANTMD' FROM dual UNION ALL
    SELECT 'MARD_B2PS4INT' FROM dual UNION ALL
    SELECT 'MARD_ONEQ' FROM dual UNION ALL
    SELECT 'MARD_EBITNP' FROM dual UNION ALL
    SELECT 'MARD_ARDSOREP' FROM dual UNION ALL
    SELECT 'MARD_ETASDORA' FROM dual UNION ALL
    SELECT 'MARD_ETASQUAD' FROM dual UNION ALL
    SELECT 'MARD_MDNAREGR' FROM dual UNION ALL
    SELECT 'MARD_SALORMON' FROM dual UNION ALL
    SELECT 'MARD_CONCESSION' FROM dual UNION ALL
    SELECT 'MARD_INTERFACE_IGPM_ONEQ' FROM dual UNION ALL
    SELECT 'MARD_INTERFACE_GWA_S3_Cube' FROM dual UNION ALL
    SELECT 'MARD_INTERFACE_P31' FROM dual UNION ALL
    SELECT 'MARD_INTERFACE_RVT' FROM dual UNION ALL
    SELECT 'MARD_INTERFACE_FLATFILE_MDNA_F0' FROM dual UNION ALL
    SELECT 'MARD_INTERFACE_x8S' FROM dual
) a ON q.Parsed_Schema = a.schema_name;