---
description: Analyze slow queries and resource-intensive queries in ClickHouse, provide optimization recommendations
---

Analyze slow queries and resource-intensive queries in ClickHouse database.

**IMPORTANT: You MUST use the `mcp__clickhouse__run_select_query` MCP tool to execute ALL SQL queries below. Do NOT just display the SQL - actually run each query and analyze the results.**

## Step 1: Identify Slow Queries (Last 24 Hours)

Query the slowest queries from the query log (excluding system monitoring users):

```sql
SELECT
    type,
    query_start_time,
    query_duration_ms / 1000 as duration_seconds,
    formatReadableSize(read_bytes) as read_size,
    formatReadableSize(memory_usage) as memory_used,
    read_rows,
    result_rows,
    user,
    normalized_query_hash,
    substring(query, 1, 200) as query_preview
FROM system.query_log
WHERE type = 'QueryFinish'
    AND query_start_time > now() - INTERVAL 24 HOUR
    AND query_kind = 'Select'
    AND query_duration_ms > 1000
    AND user NOT IN ('monitoring-internal', 'observability-internal')
ORDER BY query_duration_ms DESC
LIMIT 20
```

## Step 2: Identify Memory-Intensive Queries

Find queries that consume the most memory (excluding system monitoring users):

```sql
SELECT
    query_start_time,
    query_duration_ms / 1000 as duration_seconds,
    formatReadableSize(memory_usage) as memory_used,
    formatReadableSize(read_bytes) as read_size,
    user,
    substring(query, 1, 200) as query_preview
FROM system.query_log
WHERE type = 'QueryFinish'
    AND query_start_time > now() - INTERVAL 24 HOUR
    AND memory_usage > 100000000
    AND user NOT IN ('monitoring-internal', 'observability-internal')
ORDER BY memory_usage DESC
LIMIT 20
```

## Step 3: Identify CPU-Intensive Queries

Find queries with high CPU time (excluding system monitoring users):

```sql
SELECT
    query_start_time,
    query_duration_ms / 1000 as duration_seconds,
    ProfileEvents['OSCPUVirtualTimeMicroseconds'] / 1000000 as cpu_seconds,
    ProfileEvents['RealTimeMicroseconds'] / 1000000 as real_seconds,
    round(ProfileEvents['OSCPUVirtualTimeMicroseconds'] / ProfileEvents['RealTimeMicroseconds'] * 100, 2) as cpu_utilization_pct,
    formatReadableSize(read_bytes) as read_size,
    user,
    substring(query, 1, 200) as query_preview
FROM system.query_log
WHERE type = 'QueryFinish'
    AND query_start_time > now() - INTERVAL 24 HOUR
    AND ProfileEvents['OSCPUVirtualTimeMicroseconds'] > 1000000
    AND user NOT IN ('monitoring-internal', 'observability-internal')
ORDER BY ProfileEvents['OSCPUVirtualTimeMicroseconds'] DESC
LIMIT 20
```

## Step 4: Analyze Query Patterns (Repeated Slow Queries)

Group queries by pattern to find recurring performance issues (excluding system monitoring users):

```sql
SELECT
    normalized_query_hash,
    count() as execution_count,
    avg(query_duration_ms) / 1000 as avg_duration_seconds,
    max(query_duration_ms) / 1000 as max_duration_seconds,
    formatReadableSize(avg(memory_usage)) as avg_memory,
    formatReadableSize(avg(read_bytes)) as avg_read_size,
    any(user) as user,
    any(substring(query, 1, 200)) as query_sample
FROM system.query_log
WHERE type = 'QueryFinish'
    AND query_start_time > now() - INTERVAL 24 HOUR
    AND query_kind = 'Select'
    AND user NOT IN ('monitoring-internal', 'observability-internal')
GROUP BY normalized_query_hash
HAVING avg_duration_seconds > 1
ORDER BY execution_count * avg_duration_seconds DESC
LIMIT 20
```

## Step 5: Check Currently Running Long Queries

```sql
SELECT
    query_id,
    user,
    elapsed as running_seconds,
    formatReadableSize(memory_usage) as memory_used,
    formatReadableSize(read_bytes) as read_size,
    read_rows,
    total_rows_approx,
    round(read_rows / total_rows_approx * 100, 2) as progress_pct,
    substring(query, 1, 200) as query_preview
FROM system.processes
WHERE is_cancelled = 0
ORDER BY elapsed DESC
```

## Step 6: EXPLAIN Analysis for Problematic Queries

For the slowest query identified above, run EXPLAIN to understand execution plan:

```sql
EXPLAIN PLAN
SELECT ... -- Replace with the problematic query
```

Also check the query pipeline:

```sql
EXPLAIN PIPELINE
SELECT ... -- Replace with the problematic query
```

## Step 7: Check Index Usage

Analyze if queries are using primary key efficiently:

```sql
SELECT
    table,
    formatReadableSize(sum(primary_key_bytes_in_memory)) as pk_memory,
    sum(marks) as total_marks,
    sum(rows) as total_rows,
    round(sum(rows) / sum(marks), 0) as rows_per_mark
FROM system.parts
WHERE database = 'events' AND active
GROUP BY table
ORDER BY sum(primary_key_bytes_in_memory) DESC
```

## Step 8: Check Partition Pruning Effectiveness

```sql
SELECT
    event_time,
    query_duration_ms / 1000 as duration_seconds,
    ProfileEvents['SelectedParts'] as parts_selected,
    ProfileEvents['SelectedMarks'] as marks_selected,
    ProfileEvents['SelectedRanges'] as ranges_selected,
    read_rows,
    user,
    substring(query, 1, 150) as query_preview
FROM system.query_log
WHERE type = 'QueryFinish'
    AND query_start_time > now() - INTERVAL 24 HOUR
    AND query_kind = 'Select'
    AND ProfileEvents['SelectedParts'] > 100
    AND user NOT IN ('monitoring-internal', 'observability-internal')
ORDER BY ProfileEvents['SelectedParts'] DESC
LIMIT 20
```

## Step 9: Generate Optimization Report

Based on all analysis above, provide:

### Summary
1. **Top 5 slowest queries** with their characteristics
2. **Top 5 memory-intensive queries**
3. **Recurring slow query patterns** that need attention

### Optimization Recommendations

For each problematic query pattern, analyze and suggest:

1. **Index Optimization**
   - Is the query using the primary key efficiently?
   - Would adding a secondary index (MATERIALIZED or SKIPPING INDEX) help?
   - Example: `ALTER TABLE t ADD INDEX idx_name (column) TYPE bloom_filter GRANULARITY 4`

2. **Partition Pruning**
   - Is the query filtering on partition key?
   - Are too many partitions being scanned?

3. **Query Rewriting**
   - Can the query use PREWHERE instead of WHERE for heavy filters?
   - Should aggregations be pre-computed in materialized views?
   - Are there unnecessary columns being selected?

4. **Resource Settings**
   - Suggest appropriate `max_memory_usage` settings
   - Consider `max_threads` adjustments

5. **Schema Optimization**
   - Column type improvements (LowCardinality, Nullable removal)
   - Compression codec recommendations

## Common Optimization Patterns

| Issue | Solution |
|-------|----------|
| Full table scan | Add filter on partition/primary key |
| High memory usage | Use streaming aggregation, reduce GROUP BY columns |
| Slow JOIN | Use JOIN with smaller table on right, consider dictionary |
| Too many parts scanned | Add PREWHERE for selective filters |
| String operations slow | Use LowCardinality or materialized column |
