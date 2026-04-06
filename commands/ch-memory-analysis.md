---
description: Investigate memory usage in ClickHouse events database and diagnose high memory consumption issues
---

Analyze memory usage in the ClickHouse `events` database.

**IMPORTANT: You MUST use the `mcp__clickhouse__run_select_query` MCP tool to execute ALL SQL queries below. Do NOT just display the SQL - actually run each query and analyze the results.**

For each step below, use the MCP tool to run the query, then analyze and summarize the results before moving to the next step.

## Step 1: Check Overall Database Size

Query the total disk and memory usage for each table in the events database:

```sql
SELECT
    table,
    formatReadableSize(sum(bytes_on_disk)) as disk_size,
    formatReadableSize(sum(data_uncompressed_bytes)) as uncompressed_size,
    formatReadableSize(sum(primary_key_bytes_in_memory)) as pk_memory,
    formatReadableSize(sum(primary_key_bytes_in_memory_allocated)) as pk_memory_allocated,
    formatReadableSize(sum(marks_bytes)) as marks_memory,
    sum(rows) as total_rows,
    count() as parts
FROM system.parts
WHERE database = 'events' AND active
GROUP BY table
ORDER BY sum(bytes_on_disk) DESC
```

## Step 2: Check Memory Allocation by Component

Query memory usage by different ClickHouse components:

```sql
SELECT
    metric,
    formatReadableSize(value) as size
FROM system.metrics
WHERE metric LIKE '%Memory%'
   OR metric LIKE '%Cache%'
ORDER BY value DESC
```

## Step 3: Analyze Current Queries Memory Usage

Check if any running queries are consuming excessive memory:

```sql
SELECT
    query_id,
    user,
    formatReadableSize(memory_usage) as memory,
    elapsed,
    query
FROM system.processes
ORDER BY memory_usage DESC
LIMIT 20
```

## Step 4: Check Dictionary Memory Usage

Since the events database has dictionaries (geoip2_city_dict, ip_blacklist_trie), check their memory usage:

```sql
SELECT
    database,
    name,
    formatReadableSize(bytes_allocated) as memory_used,
    element_count,
    status,
    loading_duration
FROM system.dictionaries
WHERE database = 'events'
```

## Step 5: Analyze Large Tables

For the largest tables found in Step 1, provide detailed column-level analysis:

```sql
SELECT
    table,
    column,
    formatReadableSize(sum(column_data_compressed_bytes)) as compressed,
    formatReadableSize(sum(column_data_uncompressed_bytes)) as uncompressed,
    round(sum(column_data_compressed_bytes) / sum(column_data_uncompressed_bytes) * 100, 2) as compression_ratio
FROM system.parts_columns
WHERE database = 'events' AND active
GROUP BY table, column
ORDER BY sum(column_data_uncompressed_bytes) DESC
LIMIT 30
```

## Step 6: Check MergeTree Parts Status

Too many parts can cause memory issues:

```sql
SELECT
    table,
    count() as parts,
    sum(rows) as total_rows,
    sum(marks) as total_marks,
    formatReadableSize(sum(bytes_on_disk)) as disk_size
FROM system.parts
WHERE database = 'events' AND active
GROUP BY table
HAVING parts > 10
ORDER BY parts DESC
```

## Step 7: Report Findings

Based on the analysis, provide a summary:
1. List tables by memory consumption (highest first)
2. Identify any abnormal memory usage patterns
3. Highlight potential issues:
   - Too many parts (needs OPTIMIZE TABLE)
   - Large dictionaries consuming memory
   - Inefficient column types
   - Missing compression
4. Provide recommendations for optimization if issues are found

## Common High Memory Causes

- **Too many parts**: Run `OPTIMIZE TABLE events.table_name FINAL`
- **Large dictionaries**: Consider reducing dictionary scope or using disk-based storage
- **JSON columns**: events.events has JSON columns which can be memory-intensive
- **Materialized views**: Check if MVs are causing duplicate storage
- **Primary key too large**: Review if primary key columns can be optimized
