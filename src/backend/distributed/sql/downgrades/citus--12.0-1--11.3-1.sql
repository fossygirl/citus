-- citus--12.0-1--11.3-1
DROP SCHEMA citus_catalog CASCADE;

DROP FUNCTION pg_catalog.execute_command_on_all_nodes(text);
DROP FUNCTION pg_catalog.execute_command_on_other_nodes(text);
DROP FUNCTION pg_catalog.citus_internal_database_command(text);
DROP FUNCTION pg_catalog.citus_internal_add_database_shard(text,int);
DROP FUNCTION pg_catalog.citus_internal_start_migration_monitor(text,text);
