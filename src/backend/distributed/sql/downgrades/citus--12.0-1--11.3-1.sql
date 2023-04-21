-- citus--12.0-1--11.3-1
DROP SCHEMA citus_catalog CASCADE;

DROP FUNCTION pg_catalog.execute_command_on_all_nodes(text);
DROP FUNCTION pg_catalog.execute_command_on_other_nodes(text);
DROP FUNCTION pg_catalog.regenerate_pgbouncer_database_file();
