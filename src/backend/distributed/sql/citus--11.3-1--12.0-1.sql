-- citus--11.3-1--12.0-1

CREATE SCHEMA citus_catalog;
GRANT USAGE ON SCHEMA citus_catalog TO public;

CREATE TABLE citus_catalog.database_shard (
	database_oid oid not null,
	node_group_id int not null,
	is_available bool not null,
	PRIMARY KEY (database_oid)
);

/*
 * execute_command_on_all_nodes runs a command on all nodes
 * in a 2PC.
 */
CREATE OR REPLACE FUNCTION pg_catalog.execute_command_on_all_nodes(
    command text)
 RETURNS void
 LANGUAGE C
 STRICT
AS 'MODULE_PATHNAME', $$execute_command_on_all_nodes$$;
COMMENT ON FUNCTION pg_catalog.execute_command_on_all_nodes(text) IS
 'run a command on all other nodes in a 2PC';

/*
 * execute_command_on_other_nodes runs a command on all other nodes
 * in a 2PC.
 */
CREATE OR REPLACE FUNCTION pg_catalog.execute_command_on_other_nodes(
    command text)
 RETURNS void
 LANGUAGE C
 STRICT
AS 'MODULE_PATHNAME', $$execute_command_on_other_nodes$$;
COMMENT ON FUNCTION pg_catalog.execute_command_on_other_nodes(text) IS
 'run a command on all other nodes in a 2PC';

/*
 * database_shard_assign assigns a database to a specific shard.
 */
CREATE OR REPLACE FUNCTION pg_catalog.database_shard_assign(database_name text)
 RETURNS int
 LANGUAGE C
 STRICT
AS 'MODULE_PATHNAME', $$database_shard_assign$$;
COMMENT ON FUNCTION pg_catalog.database_shard_assign(text) IS
 'run a command on all other nodes in a 2PC';


/*
 * regenerate_pgbouncer_database_file regenerates the pgbouncer
 * database configuration file.
 */
CREATE OR REPLACE FUNCTION pg_catalog.regenerate_pgbouncer_database_file()
 RETURNS void
 LANGUAGE C
 STRICT
AS 'MODULE_PATHNAME', $$regenerate_pgbouncer_database_file$$;
COMMENT ON FUNCTION pg_catalog.regenerate_pgbouncer_database_file() IS
 'run a command on all other nodes in a 2PC';
