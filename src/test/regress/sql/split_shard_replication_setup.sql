CREATE SCHEMA citus_split_shard_by_split_points;
SET search_path TO citus_split_shard_by_split_points;
SET citus.shard_replication_factor TO 1;
SET citus.shard_count TO 1;
SET citus.next_shard_id TO 1;

-- Add two additional nodes to cluster.
SELECT 1 FROM citus_add_node('localhost', :worker_1_port);
SELECT 1 FROM citus_add_node('localhost', :worker_2_port);

-- Create distributed table (non co-located)
CREATE TABLE table_to_split (id bigserial PRIMARY KEY, value char);
SELECT create_distributed_table('table_to_split','id');

-- slotName_table is used to persist replication slot name.
-- It is only used for testing as the worker2 needs to create subscription over the same replication slot.
CREATE TABLE slotName_table (name text, id int primary key);
SELECT create_distributed_table('slotName_table','id');

-- Shard with id '1' of table table_to_split is undergoing a split into two new shards 
-- with id '2' and '3' respectively. table_to_split_1 is placed on worker1(NodeId 16) and
-- new child shards, table_to_split_2 and table_to_split_3 are placed on worker2(NodeId 18).
-- TODO(saawasek): make it parameterized
CREATE OR REPLACE FUNCTION SplitShardReplicationSetup() RETURNS text AS $$
DECLARE
    memoryId bigint := 0;
    memoryIdText text;
begin
	SELECT * into memoryId from split_shard_replication_setup(ARRAY[ARRAY[1,2,-2147483648,-1,18], ARRAY[1,3,0,2147483647,18]]);
    SELECT FORMAT('%s', memoryId) into memoryIdText;
    return memoryIdText;
end
$$ LANGUAGE plpgsql;

-- Sets up split shard information and returns Slot Name in format : DestinationNodeId_SlotType_SharedMemoryId
-- TODO(saawasek): make it parameterized
CREATE OR REPLACE FUNCTION CreateReplicationSlot() RETURNS text AS $$
DECLARE
    replicationSlotName text;
    createdSlotName text;
    sharedMemoryId text;
    derivedSlotName text;
begin
    SELECT * into sharedMemoryId from SplitShardReplicationSetup();
    -- '18' is nodeId of worker2
    SELECT FORMAT('18_0_%s', sharedMemoryId) into derivedSlotName;
    SELECT slot_name into replicationSlotName from pg_create_logical_replication_slot(derivedSlotName, 'logical_decoding_plugin');
    INSERT INTO slotName_table values(replicationSlotName, 1);
    return replicationSlotName;
end
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION CreateSubscription() RETURNS text AS $$
DECLARE
    replicationSlotName text;
    nodeportLocal int;
    subname text;
begin
    SELECT name into replicationSlotName from slotName_table;
    EXECUTE FORMAT($sub$create subscription subforID1 connection 'host=localhost port=57637 user=postgres dbname=regression' publication PUB1 with(create_slot=false, enabled=true, slot_name='%s', copy_data=false)$sub$, replicationSlotName);
    return 'a';
end
$$ LANGUAGE plpgsql;

-- Test scenario starts from here
-- 1. table_to_split is a citus distributed table
-- 2. Shard table_to_split_1 is located on worker1.
-- 3. table_to_split_1 is split into table_to_split_2 and table_to_split_3.
--    table_to_split_2/3 are located on worker2
-- 4. execute UDF split_shard_replication_setup on worker1 with below
--    params:
--    split_shard_replication_setup
--        (
--          ARRAY[
--                ARRAY[1 /*source shardId */, 2 /* new shardId */,-2147483648 /* minHashValue */, -1 /* maxHasValue */ , 18 /* nodeId where new shard is placed */ ], 
--                ARRAY[1, 3 , 0 , 2147483647, 18 ]
--               ]
--         );
-- 5. Create Replication slot with 'logical_decoding_plugin'
-- 6. Setup Pub/Sub
-- 7. Insert into table_to_split_1 at source worker1
-- 8. Expect the results in either table_to_split_2 or table_to_split_2 at worker2

\c - - - :worker_2_port
SET search_path TO citus_split_shard_by_split_points;
CREATE TABLE table_to_split_1(id bigserial PRIMARY KEY, value char);
CREATE TABLE table_to_split_2(id bigserial PRIMARY KEY, value char);
CREATE TABLE table_to_split_3(id bigserial PRIMARY KEY, value char);

-- Create dummy shard tables(table_to_split_2/3) at worker1
-- This is needed for Pub/Sub framework to work.
\c - - - :worker_1_port
SET search_path TO citus_split_shard_by_split_points;
BEGIN;
    CREATE TABLE table_to_split_2(id bigserial PRIMARY KEY, value char);
    CREATE TABLE table_to_split_3(id bigserial PRIMARY KEY, value char);
COMMIT;

-- Create publication at worker1
BEGIN;
    CREATE PUBLICATION PUB1 for table table_to_split_1, table_to_split_2, table_to_split_3;
COMMIT;

-- Create replication slot and setup shard split information at worker1
BEGIN;
select 1 from CreateReplicationSlot();
COMMIT;

\c - - - :worker_2_port
SET search_path TO citus_split_shard_by_split_points;

-- Create subscription at worker2 with copy_data to 'false' and derived replication slot name
BEGIN;
SELECT 1 from CreateSubscription();
COMMIT;

-- No data is present at this moment in all the below tables at worker2
SELECT * from table_to_split_1;
SELECT * from table_to_split_2;
SELECT * from table_to_split_3;
select pg_sleep(10);

-- Insert data in table_to_split_1 at worker1 
\c - - - :worker_1_port
SET search_path TO citus_split_shard_by_split_points;
INSERT into table_to_split_1 values(100, 'a');
INSERT into table_to_split_1 values(400, 'a');
INSERT into table_to_split_1 values(500, 'a');
SELECT * from table_to_split_1;
select pg_sleep(10);

-- Expect data to be present in shard 2 and shard 3 based on the hash value.
\c - - - :worker_2_port
select pg_sleep(10);
SET search_path TO citus_split_shard_by_split_points;
SELECT * from table_to_split_1; -- should alwasy have zero rows
SELECT * from table_to_split_2;
SELECT * from table_to_split_3;