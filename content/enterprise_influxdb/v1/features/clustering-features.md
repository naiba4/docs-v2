---
title: InfluxDB Enterprise cluster features
description: Overview of features related to InfluxDB Enterprise clustering. 
aliases:
    - /enterprise/v1.8/features/clustering-features/
menu:
  enterprise_influxdb_v1:
    name: Cluster features
    weight: 20
    parent: Enterprise features
---

{{% note %}}
_For an overview of InfluxDB Enterprise security features,
see ["InfluxDB Enterprise features - Security"](/enterprise_influxdb/v1/features/#security).
To secure your InfluxDB Enterprise cluster, see
["Configure security"](/enterprise_influxdb/v1/administration/configure/security/).
{{% /note %}}

## Entitlements

A valid license key is required in order to start `influxd-meta` or `influxd`.
License keys restrict the number of data nodes that can be added to a cluster as well as the number of CPU cores a data node can use.
Without a valid license, the process will abort startup.

Access your license expiration date with the `/debug/vars` endpoint.

{{< keep-url >}}
```sh
$ curl http://localhost:8086/debug/vars | jq '.entitlements'
{
  "name": "entitlements",
  "tags": null,
  "values": {
    "licenseExpiry": "2022-02-15T00:00:00Z",
    "licenseType": "license-key"
  }
}
```
{{% caption %}}
This examples uses `curl` and [`jq`](https://stedolan.github.io/jq/).
{{% /caption %}}

## Query management

Query management works cluster wide. Specifically, `SHOW QUERIES` and `KILL QUERY <ID>` on `"<host>"` can be run on any data node. `SHOW QUERIES` will report all queries running across the cluster and the node which is running the query.
`KILL QUERY` can abort queries running on the local node or any other remote data node. For details on using the `SHOW QUERIES` and `KILL QUERY` on InfluxDB Enterprise clusters,
see [Query Management](/enterprise_influxdb/v1/troubleshooting/query_management/).

## Subscriptions

Subscriptions used by Kapacitor work in a cluster. Writes to any node will be forwarded to subscribers across all supported subscription protocols.

## Continuous queries

### Configuration and operational considerations on a cluster

It is important to understand how to configure InfluxDB Enterprise and how this impacts the continuous queries (CQ) engine’s behavior:

- **Data node configuration** `[continuous queries]`
[run-interval](/enterprise_influxdb/v1/administration/configure/config-data-nodes/#run-interval)
-- The interval at which InfluxDB checks to see if a CQ needs to run. Set this option to the lowest interval
at which your CQs run. For example, if your most frequent CQ runs every minute, set run-interval to 1m.
- **Meta node configuration** `[meta]`
[lease-duration](/enterprise_influxdb/v1/administration/configure/config-meta-nodes/#lease-duration)
-- The default duration of the leases that data nodes acquire from the meta nodes. Leases automatically expire after the
lease-duration is met.  Leases ensure that only one data node is running something at a given time. For example, Continuous
Queries use a lease so that all data nodes aren’t running the same CQs at once.
- **Execution time of CQs** – CQs are sequentially executed. Depending on the amount of work that they need to accomplish
in order to complete, the configuration parameters mentioned above can have an impact on the observed behavior of CQs.

The CQ service is running on every node, but only a single node is granted exclusive access to execute CQs at any one time.
However, every time the `run-interval` elapses (and assuming a node isn't currently executing CQs), a node attempts to
acquire the CQ lease. By default the `run-interval` is one second – so the data nodes are aggressively checking to see
if they can acquire the lease. On clusters where all CQs execute in an amount of time less than `lease-duration`
(default is 1m), there's a good chance that the first data node to acquire the lease will still hold the lease when
the `run-interval` elapses. Other nodes will be denied the lease and when the node holding the lease requests it again,
the lease is renewed with the expiration extended to `lease-duration`.  So in a typical situation, we observe that a
single data node acquires the CQ lease and holds on to it. It effectively becomes the executor of CQs until it is
recycled (for any reason).

Now consider the the following case, CQs take longer to execute than the `lease-duration`, so when the lease expires,
~1 second later another data node requests and is granted the lease.  The original holder of the lease is busily working
on sequentially executing the list of CQs it was originally handed and the data node now holding the lease begins
executing CQs from the top of the list.

Based on this scenario, it may appear that CQs are “executing in parallel” because multiple data nodes are
essentially “rolling” sequentially through the registered CQs and the lease is rolling from node to node.
The “long pole” here is effectively your most complex CQ – and it likely means that at some point all nodes
are attempting to execute that same complex CQ (and likely competing for resources as they overwrite points
generated by that query on each node that is executing it --- likely with some phased offset).

To avoid this behavior, and this is desirable because it reduces the overall load on your cluster,
you should set the lease-duration to a value greater than the aggregate execution time for ALL the CQs that you are running.

Based on the current way in which CQs are configured to execute, the way to address parallelism is by using
Kapacitor for the more complex CQs that you are attempting to run.
[See Kapacitor as a continuous query engine](/kapacitor/v1/guides/continuous_queries/).
However, you can keep the more simplistic and highly performant CQs within the database –
but ensure that the lease duration is greater than their aggregate execution time to ensure that
“extra” load is not being unnecessarily introduced on your cluster.


## PProf endpoints

Meta nodes expose the `/debug/pprof` endpoints for profiling and troubleshooting.

## Shard movement

* [Copy shard](/enterprise_influxdb/v1/tools/influxd-ctl/copy-shard/) support - copy a shard from one node to another
* [Copy shard status](/enterprise_influxdb/v1/tools/influxd-ctl/copy-shard-status/) - query the status of a copy shard request
* [Kill copy shard](/enterprise_influxdb/v1/tools/influxd-ctl/kill-copy-shard/) - kill a running shard copy
* [Remove shard](/enterprise_influxdb/v1/tools/influxd-ctl/remove-shard/) - remove a shard from a node (this deletes data)
* [Truncate shards](/enterprise_influxdb/v1/tools/influxd-ctl/truncate-shards/) - truncate all active shard groups and start new shards immediately (This is useful when adding nodes or changing replication factors.)

This functionality is exposed via an API on the meta service and through [`influxd-ctl` sub-commands](/enterprise_influxdb/v1/tools/influxd-ctl/).

## OSS conversion

Importing a OSS single server as the first data node is supported.

See [OSS to cluster migration](/enterprise_influxdb/v1/guides/migration/) for
step-by-step instructions.

## Query routing

The query engine skips failed nodes that hold a shard needed for queries.
If there is a replica on another node, it will retry on that node.

## Backup and restore

InfluxDB Enterprise clusters support backup and restore functionality starting with
version 0.7.1.
See [Backup and restore](/enterprise_influxdb/v1/administration/backup-and-restore/) for
more information.

## Passive node setup (experimental)

Passive nodes act as load balancers--they accept write calls, perform shard lookup and RPC calls (on active data nodes), and distribute writes to active data nodes. They do not own shards or accept writes.

Use this feature when you have a replication factor (RF) of 2 or more and your CPU usage is consistently above 80 percent. Using the passive feature lets you scale a cluster when you can no longer vertically scale. Especially useful if you experience a large amount of hinted handoff growth. The passive node writes the hinted handoff queue to its own disk, and then communicates periodically with the appropriate node until it can send the queue contents there.  

Best practices when using an active-passive node setup: 
  - Use when you have a large cluster setup, generally 8 or more nodes.
  - Keep the ratio of active to passive nodes between 1:1 and 2:1.
  - Passive nodes should receive all writes.  

For more inforrmation, see how to [add a passive node to a cluster](/enterprise_influxdb/v1/tools/influxd-ctl/add-data/#add-a-passive-data-node-to-a-cluster).

{{% note %}}
**Note:**  This feature is experimental and available only in InfluxDB Enterprise.
{{% /note %}}
