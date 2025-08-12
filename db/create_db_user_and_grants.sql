CREATE USER "OCI_GENAI_BOT" DEFAULT COLLATION "USING_NLS_COMP" 
   DEFAULT TABLESPACE "DATA"
   TEMPORARY TABLESPACE "TEMP"
   IDENTIFIED BY &1;
ALTER USER "OCI_GENAI_BOT" QUOTA UNLIMITED ON "DATA";
GRANT "CONNECT" TO "OCI_GENAI_BOT";
GRANT "RESOURCE" TO "OCI_GENAI_BOT";
GRANT "DATAPUMP_CLOUD_EXP" TO "OCI_GENAI_BOT";
GRANT "DATAPUMP_CLOUD_IMP" TO "OCI_GENAI_BOT";
GRANT "DWROLE" TO "OCI_GENAI_BOT";
GRANT "CONSOLE_DEVELOPER" TO "OCI_GENAI_BOT";
GRANT "OML_DEVELOPER" TO "OCI_GENAI_BOT";
GRANT EXECUTE ON "DBMS_CLOUD_PIPELINE" TO "OCI_GENAI_BOT";
GRANT EXECUTE ON "DBMS_CLOUD_AI" TO "OCI_GENAI_BOT";
GRANT EXECUTE ON "DBMS_CLOUD" TO "OCI_GENAI_BOT";
GRANT EXECUTE ON DBMS_RESULT_CACHE TO OCI_GENAI_BOT;
-- ADD ROLES
ALTER USER OCI_GENAI_BOT DEFAULT ROLE CONSOLE_DEVELOPER,DWROLE,OML_DEVELOPER,CONNECT,RESOURCE;
-- REST ENABLE
BEGIN
    ORDS_ADMIN.ENABLE_SCHEMA(
        p_enabled => TRUE,
        p_schema => 'OCI_GENAI_BOT',
        p_url_mapping_type => 'BASE_PATH',
        p_url_mapping_pattern => 'oci_genai_bot',
        p_auto_rest_auth=> FALSE
    );
    -- ENABLE DATA SHARING
    C##ADP$SERVICE.DBMS_SHARE.ENABLE_SCHEMA(
            SCHEMA_NAME => 'OCI_GENAI_BOT',
            ENABLED => TRUE
    );
    commit;
END;
/
ALTER PROFILE "DEFAULT"
    LIMIT 
         PASSWORD_LIFE_TIME UNLIMITED;

EXEC DBMS_AUTO_INDEX.CONFIGURE('AUTO_INDEX_MODE','IMPLEMENT');
EXEC DBMS_AUTO_INDEX.CONFIGURE('AUTO_INDEX_SCHEMA','OCI_GENAI_BOT', TRUE);
EXEC DBMS_CLOUD_ADMIN.DISABLE_RESOURCE_PRINCIPAL();
EXEC DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL();
EXEC DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL(username => 'OCI_GENAI_BOT');
EXEC DBMS_CLOUD_ADMIN.DISABLE_RESOURCE_PRINCIPAL();
EXEC DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL();
EXEC DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL(username => 'OCI_GENAI_BOT');
GRANT EXECUTE ON "ADMIN"."OCI$RESOURCE_PRINCIPAL" TO "OCI_GENAI_BOT";
BEGIN
  -- Create the scheduler job.
  DBMS_SCHEDULER.CREATE_JOB (
    job_name          => 'GATHER_OCI_GENAI_BOT_STATS',
    job_type          => 'PLSQL_BLOCK',
    job_action        => 'BEGIN
                            DBMS_STATS.GATHER_SCHEMA_STATS(
                              ownname             => ''OCI_GENAI_BOT'',
                              estimate_percent  => DBMS_STATS.AUTO_SAMPLE_SIZE,  -- Let Oracle determine sample size
                              method_opt          => ''FOR ALL COLUMNS SIZE AUTO'',    -- Gather histograms as needed
                              degree              => NULL,         -- Use the default degree of parallelism
                              no_invalidate       => FALSE,       -- Invalidates dependent cursors
                              granularity         => ''AUTO''       -- Gather stats at appropriate level
                            );
                          END;',
    --start_date        => '04/19/2025 1:00:00', -- Example: Runs daily at 01:00 AM
    repeat_interval   => 'FREQ=DAILY;BYHOUR=01',  -- Can be DAILY, WEEKLY, MONTHLY, etc.  See DBMS_SCHEDULER documentation.
    end_date          => NULL,          -- No end date.  Change if needed.
    enabled           => TRUE,          -- The job is enabled and will run.
    comments          => 'Gather statistics for the OCI_GENAI_BOT schema.'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Scheduler job "GATHER_OCI_GENAI_BOT_STATS" created and enabled.');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error creating scheduler job: ' || SQLERRM);
    ROLLBACK;
END;
/
EXIT