--------------------------------------------------------
--  File created - Donnerstag-März-06-2025   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Procedure REDL_DAX_LOG_QUERY_DATA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "REDL_DAX_DATA"."REDL_DAX_LOG_QUERY_DATA" AS 

    sql_temp_hist  VARCHAR2(32767);
    
    sql_temp_sql  VARCHAR2(32767);
    
    sql_insert_temp  VARCHAR2(32767);
    
    sql_join  VARCHAR2(32767);
    
    sql_temp_del  VARCHAR2(32767);
    
    CURSOR c_sql_loop IS 
            select distinct sql_id
            from temp_table_hist
            where sql_to_short = 'Y';
     
     TYPE sqlid_tab_type IS TABLE OF c_sql_loop%ROWTYPE;
     v_sqlid sqlid_tab_type;

BEGIN

    dbms_output.put_line ('Start: ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));

---------------------------STEP 1-----------------------------------------------

    dbms_output.put_line ('Step1: ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));

    -- insert sql_text to temp
    sql_temp_hist := q'[
    
    insert into temp_table_hist
    select 
    v_hist.sql_id, 
    v_hist.SQL_OPCODE, 
    v_hist.sql_opname,
    v_hist.SQL_EXEC_ID, 
    v_hist.SESSION_TYPE, 
    v_sql.sql_text, 
    v_hist.MODULE,
    v_hist.ACTION,
    NVL(v_hist.min_sql_exec_start, sysdate) as min_sql_exec_start,
    v_hist.max_sample_time,
    trunc(sysdate) as data_collection_date, 
    sysdate as data_collection_time,
    v_sql.sql_to_short
    from 
    (
    select * from (
        -- select only records with max_sample_time = last 1 hour
        select * from (
            --  select from gv$ACTIVE_SESSION_HISTORY and group by
            select 
                SESSION_TYPE, sql_id, SQL_OPCODE, sql_opname,
                SQL_EXEC_ID, MODULE,ACTION, user_id,
                min(sql_exec_start) as min_sql_exec_start,
                max(sample_time) as max_sample_time
            from gv$ACTIVE_SESSION_HISTORY
            where sql_id is not null
                and SQL_OPCODE = 3 and IN_SQL_EXECUTION = 'Y' and IS_SQLID_CURRENT = 'Y'
            group by
                SESSION_TYPE, sql_id, SQL_OPCODE,sql_opname, 
                SQL_EXEC_ID, MODULE,ACTION, user_id
        )
        where  max_sample_time BETWEEN TRUNC(SYSDATE-1/24,'HH24') AND TRUNC(SYSDATE,'HH24')
        ) v_act_hist
        -- join with user to remove system queries
        INNER Join (
            (
            select user_id, username FROM all_users
            where username NOT LIKE 'BUSV%' and username NOT LIKE 'HRMZ%' and username NOT LIKE 'MARD%' 
                and username NOT LIKE 'MARS%' and username NOT LIKE 'RAWB%' and username NOT LIKE 'RAWO%'  
                and username NOT LIKE 'RAWV%' and username NOT LIKE 'REDL%' and username NOT LIKE 'REFM%'   
                and username NOT LIKE 'STAG%' and username NOT LIKE 'SYS%'
            ) v_users
    ) on v_act_hist.user_id = v_users.user_id
    
    ) v_hist
    -- LEFT join - only sql queries which run during last hour
    LEFT join
    (    
            select distinct(sql_id), sql_text, case when length(sql_text) > 999 then 'Y' else 'N' end as sql_to_short
            from gv$sqlarea
            -- restrict by SELECT only and last active time 
            where sql_id is not null and COMMAND_TYPE = 3 
    ) v_sql
    on v_sql.sql_id = v_hist.sql_id
    ]';    
    
    execute immediate sql_temp_hist;   
 
    dbms_output.put_line ('Temp table history inserted! ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss')); 

 -----------------------------STEP 2--------------------------------------------

    dbms_output.put_line ('Step2: ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss')); 

    -- insert sql_fulltext to temp table
        OPEN c_sql_loop; 
        
        LOOP
            FETCH c_sql_loop BULK COLLECT INTO v_sqlid limit 200;
            EXIT when v_sqlid.count = 0;
        
            FORALL i IN 1 .. v_sqlid.COUNT                 
                    insert into TEMP_TABLE_SQL
                    select sqlarea.sql_id, sqlarea.sql_fulltext
                    from gv$sqlarea sqlarea
                    where sql_id = v_sqlid(i).sql_id;
                    --DBMS_OUTPUT.PUT_LINE (v_sqlid(i).sql_id); 
            commit;   
            dbms_output.put_line (v_sqlid.COUNT || ' inserted to temp table! ');
        END LOOP;
        CLOSE c_sql_loop; 
        
    dbms_output.put_line ('Sql_fulltext inserted to temp table! ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));
 
 ---------------------------- STEP 3--------------------------------------------
    
    dbms_output.put_line ('Step3: ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));
  
   -- join hist with full text ans insert 
    sql_join := q'[ 
    
    insert into T_DAX_REDL_SEL_PATHS
    select 
    v_hist.sql_id, 
    v_hist.SQL_OPCODE, 
    v_hist.sql_opname,
    v_hist.SQL_EXEC_ID, 
    v_hist.SESSION_TYPE, 
    v_hist.sql_text, 
    v_sql.sql_fulltext,
    v_hist.MODULE,
    v_hist.ACTION,
    v_hist.min_sql_exec_start,
    v_hist.max_sample_time,
    v_hist.data_collection_date, 
    v_hist.data_collection_time,
    v_hist.sql_to_short
    from 
    (
        select sql_id, SQL_OPCODE, sql_opname, SQL_EXEC_ID, SESSION_TYPE, sql_text, MODULE, ACTION, min_sql_exec_start,
        max_sample_time, data_collection_date, data_collection_time, sql_to_short
        from temp_table_hist
    
    ) v_hist
    -- LEFT join - only sql queries which run during last hour
    LEFT join
    (   
        select * from (
            select sql_id, sql_fulltext,
            row_number() over (partition by sql_id order by 1) as rank
            from temp_table_sql
        ) where rank = 1
  
    ) v_sql
    on v_hist.sql_id = v_sql.sql_id
    ]';
    
    execute immediate sql_join;
    dbms_output.put_line ('Join and insert completed. ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));
    
    ------------------STEP 4--------------------------------------------------------
    
    dbms_output.put_line ('Step4: ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));
    
    -- delete records in temp tables
    sql_temp_del := q'[
        truncate table temp_table_hist
    ]';
    
    execute immediate sql_temp_del; 
    
    -- delete records in temp tables
    sql_temp_del := q'[
        truncate table temp_table_sql
    ]';
    
    execute immediate sql_temp_del; 
    
    dbms_output.put_line ('Data in temp tables deleted. ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));
    dbms_output.put_line ('End');

END REDL_DAX_LOG_QUERY_DATA;

/

  GRANT EXECUTE ON "REDL_DAX_DATA"."REDL_DAX_LOG_QUERY_DATA" TO "W_REDL_0_ADM_STAR_PF_EXECPROC";
  GRANT EXECUTE ON "REDL_DAX_DATA"."REDL_DAX_LOG_QUERY_DATA" TO "W_DAX_G_SUP_MAIN";
  GRANT EXECUTE ON "REDL_DAX_DATA"."REDL_DAX_LOG_QUERY_DATA" TO "W_REDL_0_ADM_REDL";
