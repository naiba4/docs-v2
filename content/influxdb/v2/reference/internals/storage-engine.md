---
title: InfluxDB storage engine
description: >
  An overview of the InfluxDB storage engine architecture.
weight: 101
menu:
  influxdb_v2_ref:
    name: Storage engine
    parent: InfluxDB internals
influxdb/v2/tags: [storage, internals]
products: [oss]
related:
  - /resources/videos/tsm-engine/
  - /influxdb/v2/admin/internals/
---

The InfluxDB storage engine ensures that:

- Data is safely written to disk
- Queried data is returned complete and correct
- Data is accurate (first) and performant (second)

This document outlines the internal workings of the storage engine.
This information is presented both as a reference and to aid those looking to maximize performance.

The storage engine includes the following components:

* [Write Ahead Log (WAL)](#write-ahead-log-wal)
* [Cache](#cache)
* [Time-Structed Merge Tree (TSM)](#time-structured-merge-tree-tsm)
* [Time Series Index (TSI)](#time-series-index-tsi)

## Writing data from API to disk

The storage engine handles data from the point an API write request is received through writing data to the physical disk.
Data is written to InfluxDB using [line protocol](/influxdb/v2/reference/syntax/line-protocol/) sent via HTTP POST request to the `/api/v2/write` endpoint or the [`/write` 1.x compatibility endpoint](/influxdb/v2/reference/api/influxdb-1x/).
Batches of [points](/influxdb/v2/reference/glossary/#point) are sent to InfluxDB, compressed, and written to a WAL for immediate durability.
Points are also written to an in-memory cache and become immediately queryable.
The in-memory cache is periodically written to disk in the form of [TSM](#time-structured-merge-tree-tsm) files.
As TSM files accumulate, the storage engine combines and compacts accumulated them into higher level TSM files.

{{% note %}}
While points can be sent individually, for efficiency, most applications send points in batches.
Points in a POST body can be from an arbitrary number of series, measurements, and tag sets.
Points in a batch do not have to be from the same measurement or tagset.
{{% /note %}}

## Write Ahead Log (WAL)

The **Write Ahead Log** (WAL) retains InfluxDB data when the storage engine restarts.
The WAL ensures data is durable in case of an unexpected failure.

When the storage engine receives a write request, the following steps occur:

1. The write request is appended to the end of the WAL file.
2. Data is written to disk using `fsync()`.
3. The in-memory cache is updated.
4. When data is successfully written to disk, a response confirms the write request was successful.

`fsync()` takes the file and pushes pending writes all the way to the disk.
As a system call, `fsync()` has a kernel context switch that's computationally expensive, but guarantees that data is safe on disk.

When the storage engine restarts, the WAL file is read back into the in-memory database.
InfluxDB then answers requests to the `/read` endpoint.

## Cache

The **cache** is an in-memory copy of data points currently stored in the WAL.
The [WAL](#write-ahead-log-wal) and cache are separate entities and do not interact with each other.  The storage engine coordinates writes to both.

The cache:

- Organizes points by key (measurement, tag set, and unique field).
  Each field is stored in its own time-ordered range.
- Stores uncompressed data.
- Gets updates from the WAL each time the storage engine restarts.
  The cache is queried at runtime and merged with the data stored in TSM files.
- Uses a maximum `maxSize` bytes of memory.

Cache snapshots are cache objects currently being written to TSM files.
They're kept in memory while flushing so they can be queried along with the cache.
Queries to the storage engine merge data from the cache with data from the TSM files.
Queries execute on a copy of the data that is made from the cache at query processing time.
This way writes that come in while a query is running do not affect the result.
Deletes sent to the cache clear the specified key or time range for a specified key.

## Time-Structured Merge Tree (TSM)

To efficiently compact and store data,
the storage engine groups field values by series key, and then orders those field values by time.
(A [series key](/influxdb/v2/reference/glossary/#series-key) is defined by measurement, tag key and value, and field key.)

The storage engine uses a **Time-Structured Merge Tree** (TSM) data format.
TSM files store compressed series data in a columnar format.
To improve efficiency, the storage engine only stores differences (or *deltas*) between values in a series.
Column-oriented storage lets the engine read by series key and omit extraneous data.

After fields are stored safely in TSM files, the WAL is truncated and the cache is cleared.
The **compaction** process creates read-optimized TSM files. The TSM compaction code is quite complex.
However, the high-level goal is quite simple:
organize values for a series together into long runs to best optimize compression and scanning queries.

For more information on the TSM engine, watch the video below:

{{< youtube C5sv0CtuMCw >}}

## Time Series Index (TSI)

As data cardinality (the number of series) grows, queries read more series keys and become slower.
The **Time Series Index** ensures queries remain fast as data cardinality grows.
The TSI stores series keys grouped by measurement, tag, and field.
This allows the database to answer two questions well:

- What measurements, tags, fields exist?
  (This happens in meta queries.)
- Given a measurement, tags, and fields, what series keys exist?
