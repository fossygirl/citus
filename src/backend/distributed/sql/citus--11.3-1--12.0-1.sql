-- citus--11.3-1--12.0-1

CREATE SCHEMA citus_catalog;
GRANT USAGE ON SCHEMA citus_catalog TO public;

CREATE TABLE citus_catalog.database_shard (
	database_oid oid not null,
	node_group_id int not null,
	is_available bool not null,
	PRIMARY KEY (database_oid)
);
GRANT SELECT ON TABLE citus_catalog.database_shard TO public;

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
 * citus_internal_database_command creates a database according to the given command.
 */
CREATE OR REPLACE FUNCTION pg_catalog.citus_internal_database_command(command text)
 RETURNS void
 LANGUAGE C
 STRICT
AS 'MODULE_PATHNAME', $$citus_internal_database_command$$;
COMMENT ON FUNCTION pg_catalog.citus_internal_database_command(text) IS
 'run a database command without transaction block restrictions';

/*
 * citus_internal_add_database_shard inserts a database shard
 * into the database shards metadata.
 */
CREATE OR REPLACE FUNCTION pg_catalog.citus_internal_add_database_shard(database_name text, node_group_id int)
 RETURNS void
 LANGUAGE C
 STRICT
AS 'MODULE_PATHNAME', $$citus_internal_add_database_shard$$;
COMMENT ON FUNCTION pg_catalog.citus_internal_add_database_shard(text,int) IS
 'add a database shard to the metadata';

/*
 * citus_internal_delete_database_shard deletes a database shard
 * from the metadata
 */
CREATE OR REPLACE FUNCTION pg_catalog.citus_internal_delete_database_shard(database_name text)
 RETURNS void
 LANGUAGE C
 STRICT
AS 'MODULE_PATHNAME', $$citus_internal_delete_database_shard$$;
COMMENT ON FUNCTION pg_catalog.citus_internal_delete_database_shard(text) IS
 'delete a database shard from the metadata';


CREATE FUNCTION pg_catalog.database_shard_move(
	database_name text,
	target_node_group_id int)
RETURNS void
LANGUAGE C STRICT
AS 'MODULE_PATHNAME', $$database_shard_move$$;
COMMENT ON FUNCTION pg_catalog.database_shard_move(text, int)
IS 'start a database shard move';

CREATE FUNCTION pg_catalog.database_shard_move_start(
	database_name text,
	target_node_group_id int)
RETURNS void
LANGUAGE C STRICT
AS 'MODULE_PATHNAME', $$database_shard_move_start$$;
COMMENT ON FUNCTION pg_catalog.database_shard_move_start(text, int)
IS 'start a database shard move';

CREATE FUNCTION pg_catalog.database_shard_move_finish(
	database_name text,
	target_node_group_id int)
 RETURNS void
 LANGUAGE C STRICT
 AS 'MODULE_PATHNAME', $$database_shard_move_finish$$;
COMMENT ON FUNCTION pg_catalog.database_shard_move_finish(text,int)
IS 'finish a database shard move';
