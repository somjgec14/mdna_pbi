This PL/SQL procedure, REDL_DAX_LOG_QUERY_DATA, is designed to collect and log information about SQL queries that have recently executed on an Oracle database. It gathers data from gv$ACTIVE_SESSION_HISTORY and gv$sqlarea, processes it, and then inserts the combined information into a permanent table T_DAX_REDL_SEL_PATHS. It uses temporary tables (temp_table_hist and temp_table_sql) for intermediate storage.

Let's break down the procedure step-by-step:

Preamble:

set define off;: This command prevents SQL*Plus from prompting for substitution variables if any are encountered in the script.
CREATE OR REPLACE EDITIONABLE PROCEDURE "REDL_DAX_DATA"."REDL_DAX_LOG_QUERY_DATA" AS: This declares the creation or replacement of a stored procedure named REDL_DAX_LOG_QUERY_DATA within the schema REDL_DAX_DATA. EDITIONABLE means it can be part of an edition-based redefinition.
Variable Declarations:sql_temp_hist VARCHAR2(32767);: A string variable to hold the SQL statement for inserting data into temp_table_hist.
sql_temp_sql VARCHAR2(32767);: Although declared, this variable is not used to store a SQL string in the provided code. It seems like a placeholder or was intended for a different approach.
sql_insert_temp VARCHAR2(32767);: Similar to sql_temp_sql, this variable is declared but not used.
sql_join VARCHAR2(32767);: A string variable to hold the SQL statement for joining and inserting data into T_DAX_REDL_SEL_PATHS.
sql_temp_del VARCHAR2(32767);: A string variable to hold the SQL statement for truncating temporary tables.
Cursor Declaration (c_sql_loop): This cursor is defined to select distinct sql_id values from temp_table_hist where the sql_to_short flag is 'Y'. This suggests it's looking for SQL statements that were initially identified as potentially "shortened" and might need their full text later.
Nested Table Type and Variable:TYPE sqlid_tab_type IS TABLE OF c_sql_loop%ROWTYPE;: Defines a PL/SQL collection (nested table) type to hold rows fetched by c_sql_loop.
v_sqlid sqlid_tab_type;: Declares a variable of the sqlid_tab_type to store batches of sql_ids.

Procedure Body (BEGIN...END):

Start Logging:

dbms_output.put_line ('Start: ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));: Prints a timestamp indicating the start of the procedure execution.


STEP 1: Populate temp_table_hist

dbms_output.put_line ('Step1: ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));: Logs the start of Step 1.
sql_temp_hist := q'[...]';: A long SQL INSERT statement is constructed and assigned to sql_temp_hist. The q'[...]' syntax allows for easier handling of single quotes within the string.Purpose of this SQL: This statement populates the temp_table_hist with information about active SQL sessions from gv$ACTIVE_SESSION_HISTORY and their corresponding SQL text from gv$sqlarea.
gv$ACTIVE_SESSION_HISTORY filtering:sql_id is not null: Ensures only records with an associated SQL ID are considered.
SQL_OPCODE = 3: Filters for SELECT statements (opcode 3 usually corresponds to SELECT).
IN_SQL_EXECUTION = 'Y' and IS_SQLID_CURRENT = 'Y': Ensures the session was actively executing the SQL at the sample time.
max_sample_time BETWEEN TRUNC(SYSDATE-1/24,'HH24') AND TRUNC(SYSDATE,'HH24'): Crucially, it selects activity within the last hour. TRUNC(SYSDATE-1/24,'HH24') gets the beginning of the previous hour, and TRUNC(SYSDATE,'HH24') gets the beginning of the current hour.
It GROUP BY various session attributes to get aggregated information (min sql_exec_start, max sample_time).


User Filtering: It performs an INNER JOIN with all_users to exclude queries executed by specific system or internal users (e.g., BUSV%, HRMZ%, MARD%, SYS%). This indicates an interest in application or end-user initiated queries.
gv$sqlarea joining:A LEFT JOIN is performed with gv$sqlarea on sql_id. This means that even if gv$sqlarea doesn't have an entry for a sql_id (though unlikely if it's in ASH), the ASH data will still be included.
COMMAND_TYPE = 3: Again, filters for SELECT statements in gv$sqlarea.
case when length(sql_text) > 999 then 'Y' else 'N' end as sql_to_short: This is a very important part. It flags SQL statements as 'Y' in sql_to_short if their sql_text (from gv$sqlarea.SQL_TEXT) is longer than 999 characters. This suggests SQL_TEXT might be truncated in gv$sqlarea and the full text (SQL_FULLTEXT) might be needed.


execute immediate sql_temp_hist;: Executes the dynamically constructed SQL statement.
dbms_output.put_line ('Temp table history inserted! ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));: Logs the completion of Step 1.


STEP 2: Populate TEMP_TABLE_SQL with SQL_FULLTEXT

dbms_output.put_line ('Step2: ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));: Logs the start of Step 2.
Cursor Loop (c_sql_loop):OPEN c_sql_loop;: Opens the cursor, which identifies SQL IDs from temp_table_hist that have sql_to_short = 'Y'.
LOOP ... EXIT when v_sqlid.count = 0;: A loop to process SQL IDs in batches.
FETCH c_sql_loop BULK COLLECT INTO v_sqlid limit 200;: Fetches up to 200 sql_ids at a time into the v_sqlid collection for efficient processing (BULK COLLECT).
FORALL i IN 1 .. v_sqlid.COUNT ... insert into TEMP_TABLE_SQL ...: This is a FORALL statement, which is an optimized way to execute a DML statement multiple times with different values from a collection.For each sql_id in the batch, it inserts the sql_id and its sql_fulltext from gv$sqlarea into TEMP_TABLE_SQL. This is specifically done for queries whose sql_text was potentially truncated in gv$sqlarea as indicated by sql_to_short = 'Y'.


commit;: Commits the insertions after each batch.
dbms_output.put_line (v_sqlid.COUNT || ' inserted to temp table! ');: Logs the number of records inserted in the current batch.
CLOSE c_sql_loop;: Closes the cursor after all SQL IDs are processed.


dbms_output.put_line ('Sql_fulltext inserted to temp table! ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));: Logs the completion of Step 2.


STEP 3: Join and Insert into T_DAX_REDL_SEL_PATHS

dbms_output.put_line ('Step3: ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));: Logs the start of Step 3.
sql_join := q'[...]';: A SQL INSERT statement is constructed to combine data from temp_table_hist and TEMP_TABLE_SQL and insert it into the final destination table T_DAX_REDL_SEL_PATHS.Purpose of this SQL: This statement takes the historical session data and, for queries that had their full text stored, combines it with that full text.
It selects all relevant columns from temp_table_hist.
It performs a LEFT JOIN with TEMP_TABLE_SQL.The subquery for TEMP_TABLE_SQL uses row_number() over (partition by sql_id order by 1) as rank and then where rank = 1. This is to handle cases where a sql_id might somehow have multiple entries in TEMP_TABLE_SQL (though gv$sqlarea should ideally have unique sql_ids, this provides robustness). It ensures only one sql_fulltext is chosen per sql_id.


execute immediate sql_join;: Executes the dynamically constructed SQL statement.
dbms_output.put_line ('Join and insert completed. ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));: Logs the completion of Step 3.


STEP 4: Clean up Temporary Tables

dbms_output.put_line ('Step4: ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));: Logs the start of Step 4.
sql_temp_del := q'[truncate table temp_table_hist]';: Prepares the TRUNCATE statement for temp_table_hist.
execute immediate sql_temp_del;: Executes the TRUNCATE command. TRUNCATE is a DDL operation that quickly removes all rows from a table and resets high-water mark, it's faster than DELETE for full table removal.
sql_temp_del := q'[truncate table temp_table_sql]';: Prepares the TRUNCATE statement for temp_table_sql.
execute immediate sql_temp_del;: Executes the TRUNCATE command.
dbms_output.put_line ('Data in temp tables deleted. ' || to_char(sysdate, 'dd.mm.yyyy hh:mm:ss'));: Logs the completion of cleanup.
dbms_output.put_line ('End');: Logs the end of the procedure execution.

Post-Procedure:

GRANT EXECUTE ON "REDL_DAX_DATA"."REDL_DAX_LOG_QUERY_DATA" TO ...: These statements grant EXECUTE privileges on the newly created procedure to various database roles or users. This allows these entities to run the procedure.

In Summary:

The REDL_DAX_LOG_QUERY_DATA procedure serves as a data collection agent for SQL query performance and context. It systematically:

Collects recent session history for SELECT statements from gv$ACTIVE_SESSION_HISTORY, filtering out system users and focusing on the last hour. It also captures the initial sql_text from gv$sqlarea and flags queries with potentially truncated sql_text.
Retrieves the full SQL text (sql_fulltext) for those flagged queries from gv$sqlarea and stores it in a separate temporary table.
Combines the historical session data with the full SQL text (if available) and inserts this comprehensive record into a permanent logging table T_DAX_REDL_SEL_PATHS.
Cleans up the temporary tables to ensure the next execution starts with a fresh slate.

This process aims to provide a detailed log of important SQL SELECT statements that have been executed, including their full text, execution details, and associated session information, for analysis or auditing purposes.