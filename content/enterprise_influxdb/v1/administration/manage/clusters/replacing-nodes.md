---
title: Replace InfluxDB Enterprise cluster meta nodes and data nodes
description: Replace meta and data nodes in an InfluxDB Enterprise cluster.
aliases:
    - /enterprise_influxdb/v1/guides/replacing-nodes/
menu:
  enterprise_influxdb_v1:
    name: Replace nodes
    parent: Manage clusters
weight: 20
---

You may need to replace a node in your InfluxDB Enterprise cluster, for example, to update hardware. This guide describes how to replace both meta nodes and data nodes in a cluster:

- [Concepts](#concepts)
- [Scenarios](#scenarios)
  - [Replace a node in a cluster with security enable](#replace-a-node-in-a-cluster-with-security-enable)
  - [Replace a meta node in a functional cluster](#replace-a-meta-node-in-a-functional-cluster)
  - [Replace an unresponsive meta node](#replace-an-unresponsive-meta-node)
  - [Replace responsive and unresponsive data nodes in a cluster](#replace-responsive-and-unresponsive-data-nodes-in-a-cluster)
  - [Reconnect a data node with a failed disk](#reconnect-a-data-node-with-a-failed-disk)
- [Replace meta nodes in an InfluxDB Enterprise cluster](#replace-meta-nodes-in-an-influxdb-enterprise-cluster)
- [Replace data nodes in an InfluxDB Enterprise cluster](#replace-data-nodes-in-an-influxdb-enterprise-cluster)
- [Troubleshoot](#troubleshoot)
  - [Cluster commands result in timeout without error](#cluster-commands-result-in-timeout-without-error)

## Concepts

**Meta nodes** manage and monitor both the uptime of nodes in the cluster and
distribution of [shards](/influxdb/v2/reference/glossary/#shard) among nodes in
the cluster. Meta nodes hold information about which data nodes own which shards;
information that the [anti-entropy](/enterprise_influxdb/v1/administration/configure/anti-entropy/)
(AE) process depends on.

**Data nodes** hold raw time-series data and metadata. Data shards are both distributed and replicated across data nodes in the cluster. The AE process runs on data nodes and references the shard information stored in the meta nodes to ensure each data node has the shards they need.

`influxd-ctl` is a CLI included in each meta node and is used to manage your InfluxDB Enterprise cluster.

## Scenarios

### Replace a node in a cluster with security enable

Many InfluxDB Enterprise clusters are configured with security enabled, forcing
secure TLS encryption between all nodes in the cluster.
Both `influxd-ctl` and `curl`, the command line tools used when replacing nodes,
have options that facilitate the use of TLS.

#### `influxd-ctl -bind-tls`

To manage your cluster over TLS, pass the `-bind-tls` flag with any `influxd-ctl` commmand.

{{% note %}}
If using a self-signed certificate, pass the `-k` flag to skip certificate verification.
{{% /note %}}

```bash
# Syntax
influxd-ctl -bind-tls [-k] <command>

# Example
influxd-ctl -bind-tls remove-meta enterprise-meta-02:8091
```

#### `curl -k`

`curl` natively supports TLS/SSL connections, but if using a self-signed certificate,
pass the `-k`/`--insecure` flag to allow for "insecure" SSL connections.

{{% note %}}
Self-signed certificates are considered "insecure" due to their lack of a valid
chain of authority. However, data is still encrypted when using self-signed certificates.
{{% /note %}}

```bash
# Syntax
curl [-k, --insecure] <url>

# Example
curl -k https://localhost:8091/status
```

### Replace a meta node in a functional cluster

If all meta nodes in the cluster are fully functional, complete the following
steps to [replace meta nodes](#replace-meta-nodes-in-an-influxdb-enterprise-cluster).

### Replace an unresponsive meta node

If replacing a meta node that is either unreachable or unrecoverable, you must
forcefully remove the node from the meta cluster.
See [step 2.2](#22-remove-the-non-leader-meta-node) of the
[replace meta nodes](#replace-meta-nodes-in-an-influxdb-enterprise-cluster) process.

### Replace responsive and unresponsive data nodes in a cluster

The process of replacing both responsive and unresponsive data nodes is the same.
Follow the instructions for [replacing data nodes](#replace-a-data-node-in-an-influxdb-enterprise-cluster).

### Reconnect a data node with a failed disk

A disk drive failing is never a good thing, but it does happen, and when it does,
all shards on that node are lost.

Often in this scenario, rather than replacing the entire host, you just need to replace the disk.
Host information remains the same, but once started again, the `influxd` process doesn't know
to communicate with the meta nodes so the AE process can't start the shard-sync process.

To resolve this, sign in to a meta node and use the [`influxd-ctl update-data`](/enterprise_influxdb/v1/tools/influxd-ctl/update-data/) command
to [update the failed data node to itself](#2-replace-the-old-data-node-with-the-new-data-node).

```bash
# Syntax
influxd-ctl update-data <data-node-tcp-bind-address> <data-node-tcp-bind-address>

# Example
influxd-ctl update-data enterprise-data-01:8088 enterprise-data-01:8088
```

This connects the `influxd` process running on the newly replaced disk to the cluster.
The AE process detects the missing shards and begins to sync data from other
shards in the same shard group.

{{% note %}}
If the AE process is disabled, use [`influxd-ctl copy-shard`](/enterprise_influxdb/v1/tools/influxd-ctl/copy-shard/)
to manually copy shards from existing data nodes to the new data node.
{{% /note %}}

## Replace meta nodes in an InfluxDB Enterprise cluster

[Meta nodes](/enterprise_influxdb/v1/concepts/clustering/#meta-nodes) together
form a [Raft](https://raft.github.io/) cluster in which nodes elect a leader through consensus vote.
The leader oversees the management of the meta cluster, so it is important to
replace non-leader nodes before the leader node.
The process for replacing meta nodes is as follows:

1. [Identify the leader node](#1-identify-the-leader-node)  
2. [Replace all non-leader nodes](#2-replace-all-non-leader-nodes)  
    2.1.  [Provision a new meta node](#21-provision-a-new-meta-node)  
    2.2.  [Remove the non-leader meta node](#22-remove-the-non-leader-meta-node)  
    2.3.  [Add the new meta node](#23-add-the-new-meta-node)  
    2.4.  [Confirm the meta node was added](#24-confirm-the-meta-node-was-added)  
    2.5.  [Remove and replace all other non-leader meta nodes](#25-remove-and-replace-all-other-non-leader-meta-nodes)
3. [Replace the leader node](#3-replace-the-leader-node)  
    3.1.  [Kill the meta process on the leader node](#31-kill-the-meta-process-on-the-leader-node)  
    3.2.  [Remove and replace the old leader node](#32-remove-and-replace-the-old-leader-node)  

### 1. Identify the leader node

Log into any of your meta nodes and run the following:

```bash
curl -s localhost:8091/status | jq
```

{{% note %}}
Piping the command into `jq` is optional, but does make the JSON output easier to read.
{{% /note %}}

The output will include information about the current meta node, the leader of the meta cluster, and a list of "peers" in the meta cluster.

```json
{
  "nodeType": "meta",
  "leader": "enterprise-meta-01:8089",
  "httpAddr": "enterprise-meta-01:8091",
  "raftAddr": "enterprise-meta-01:8089",
  "peers": [
    "enterprise-meta-01:8089",
    "enterprise-meta-02:8089",
    "enterprise-meta-03:8089"
  ]
}
```

Identify the `leader` of the cluster. When replacing nodes in a cluster, non-leader nodes should be replaced _before_ the leader node.

### 2. Replace all non-leader nodes

#### 2.1. Provision a new meta node

[Provision and start a new meta node](/enterprise_influxdb/v1/installation/meta_node_installation/),
but **do not** add it to the cluster yet.
For this guide, the new meta node's hostname will be `enterprise-meta-04`.

#### 2.2. Remove the non-leader meta node

Now remove the non-leader node you are replacing by using the `influxd-ctl remove-meta` command and the TCP address of the meta node (ex. `enterprise-meta-02:8091`):

```bash
# Syntax
influxd-ctl remove-meta <meta-node-tcp-bind-address>

# Example
influxd-ctl remove-meta enterprise-meta-02:8091
```

{{% note %}}
Only use `remove-meta` if you want to permanently remove a meta node from a cluster.
{{% /note %}}

{{% note %}}
**For unresponsive or unrecoverable meta nodes:**

If the meta process is not running on the node you are trying to remove or the
node is neither reachable nor recoverable, use the `-force` flag.
When forcefully removing a meta node, you must also pass the `-tcpAddr` flag with
the TCP and HTTP bind addresses of the node you are removing.

```bash
# Syntax
influxd-ctl remove-meta -force -tcpAddr <meta-node-tcp-bind-address> <meta-node-http-bind-address>

# Example
influxd-ctl remove-meta -force -tcpAddr enterprise-meta-02:8089 enterprise-meta-02:8091
```
{{% /note %}}

#### 2.3. Add the new meta node

Once the non-leader meta node has been removed, on **one of the existing meta nodes**,
run `influxd-ctl add-meta` to replace the node removed with the new meta node:

```bash
# Syntax
influxd-ctl add-meta <meta-node-tcp-bind-address>

# Example
influxd-ctl add-meta enterprise-meta-04:8091
```

You can also add a meta node remotely through another meta node:

```bash
# Syntax
influxd-ctl -bind <remote-meta-node-bind-address> add-meta <meta-node-tcp-bind-address>

# Example
influxd-ctl -bind enterprise-meta-node-01:8091 add-meta enterprise-meta-node-04:8091
```

>This command contacts the meta node running at `cluster-meta-node-01:8091` and adds a meta node to that meta node’s cluster.
The added meta node has the hostname `cluster-meta-node-04` and runs on port `8091`.

#### 2.4. Confirm the meta node was added

Confirm the new meta-node has been added by running:

```bash
influxd-ctl show
```

The new meta node should appear in the output:

```bash
Data Nodes
==========
ID	TCP Address	Version
4	enterprise-data-01:8088	{{< latest-patch >}}-c{{< latest-patch >}}
5	enterprise-data-02:8088	{{< latest-patch >}}-c{{< latest-patch >}}

Meta Nodes
==========
TCP Address	Version
enterprise-meta-01:8091	{{< latest-patch >}}-c{{< latest-patch >}}
enterprise-meta-03:8091	{{< latest-patch >}}-c{{< latest-patch >}}
enterprise-meta-04:8091	{{< latest-patch >}}-c{{< latest-patch >}} # <-- The newly added meta node
```

#### 2.5. Remove and replace all other non-leader meta nodes

**If replacing only one meta node, no further action is required.**
If replacing others, repeat steps [2.1-2.4](#2-1-provision-a-new-meta-node) for all non-leader meta nodes one at a time.

### 3. Replace the leader node

As non-leader meta nodes are removed and replaced, the leader node oversees the replication of data to each of the new meta nodes.
Leave the leader up and running until at least two of the new meta nodes are up, running and healthy.

#### 3.1 - Kill the meta process on the leader node

Log into the leader meta node and kill the meta process.

```bash
# List the running processes and get the
# PID of the 'influx-meta' process
ps aux

# Kill the 'influx-meta' process
kill <PID>
```

Once killed, the meta cluster will elect a new leader using the [raft consensus algorithm](https://raft.github.io/).
Confirm the new leader by running:

```bash
curl localhost:8091/status | jq
```

#### 3.2 - Remove and replace the old leader node

Remove the old leader node and replace it by following steps [2.1-2.4](#2-1-provision-a-new-meta-node).
The minimum number of meta nodes you should have in your cluster is 3.

## Replace data nodes in an InfluxDB Enterprise cluster

[Data nodes](/enterprise_influxdb/v1/concepts/clustering/#data-nodes) house all raw time series data and metadata.
The process of replacing data nodes is as follows:

1. [Provision a new data node](#1-provision-a-new-data-node)
2. [Replace the old data node with the new data node](#2-replace-the-old-data-node-with-the-new-data-node)
3. [Confirm the data node was added](#3-confirm-the-data-node-was-added)
4. [Check the copy-shard-status](#4-check-the-copy-shard-status)

### 1. Provision a new data node

[Provision and start a new data node](/enterprise_influxdb/v1/installation/data_node_installation/), but **do not** add it to your cluster yet.

### 2. Replace the old data node with the new data node

Log into any of your cluster's meta nodes and use `influxd-ctl update-data` to replace the old data node with the new data node:

```bash
# Syntax
influxd-ctl update-data <old-node-tcp-bind-address> <new-node-tcp-bind-address>

# Example
influxd-ctl update-data enterprise-data-01:8088 enterprise-data-03:8088
```

### 3. Confirm the data node was added

Confirm the new data node has been added by running:

```bash
influxd-ctl show
```

The new data node should appear in the output:

```bash
Data Nodes
==========
ID	TCP Address	Version
4	enterprise-data-03:8088	{{< latest-patch >}}-c{{< latest-patch >}} # <-- The newly added data node
5	enterprise-data-02:8088	{{< latest-patch >}}-c{{< latest-patch >}}

Meta Nodes
==========
TCP Address	Version
enterprise-meta-01:8091	{{< latest-patch >}}-c{{< latest-patch >}}
enterprise-meta-02:8091	{{< latest-patch >}}-c{{< latest-patch >}}
enterprise-meta-03:8091	{{< latest-patch >}}-c{{< latest-patch >}}
```

Inspect your cluster's shard distribution with `influxd-ctl show-shards`.
Shards will immediately reflect the new address of the node.

```bash
influxd-ctl show-shards

Shards
==========
ID  Database   Retention Policy  Desired Replicas  Shard Group  Start                 End                   Expires               Owners
3   telegraf   autogen           2                 2            2018-03-19T00:00:00Z  2018-03-26T00:00:00Z                        [{5 enterprise-data-02:8088} {4 enterprise-data-03:8088}]
1   _internal  monitor           2                 1            2018-03-22T00:00:00Z  2018-03-23T00:00:00Z  2018-03-30T00:00:00Z  [{5 enterprise-data-02:8088}]
2   _internal  monitor           2                 1            2018-03-22T00:00:00Z  2018-03-23T00:00:00Z  2018-03-30T00:00:00Z  [{4 enterprise-data-03:8088}]
4   _internal  monitor           2                 3            2018-03-23T00:00:00Z  2018-03-24T00:00:00Z  2018-03-01T00:00:00Z  [{5 enterprise-data-02:8088}]
5   _internal  monitor           2                 3            2018-03-23T00:00:00Z  2018-03-24T00:00:00Z  2018-03-01T00:00:00Z  [{4 enterprise-data-03:8088}]
6   foo        autogen           2                 4            2018-03-19T00:00:00Z  2018-03-26T00:00:00Z                        [{5 enterprise-data-02:8088} {4 enterprise-data-03:8088}]
```

Within the duration defined by [`anti-entropy.check-interval`](/enterprise_influxdb/v1/administration/config-data-nodes#check-interval-10m),
the AE service begins copying shards from other shard owners to the new node.
The time it takes for copying to complete is determined by the number of shards
copied and how much data is stored in each.

{{% note %}}
**Tip:** If unexpected shard issues occur (for example, when AE is disabled or
causing unexpected results), use [`influxd-ctl copy-shard`](/enterprise_influxdb/v1/tools/influxd-ctl/copy-shard/)
to manually replace shards on a node.
{{% /note %}}

### 4. Check the `copy-shard-status`

Check on the status of the copy-shard process with:

```bash
influxd-ctl copy-shard-status
```

The output will show all currently running copy-shard processes.

```bash
Source                   Dest                     Database  Policy   ShardID  TotalSize  CurrentSize  StartedAt
enterprise-data-02:8088  enterprise-data-03:8088  telegraf  autogen  3        119624324  119624324    2018-04-17 23:45:09.470696179 +0000 UTC
```

{{% note %}}
**Important:** If replacing other data nodes in the cluster, make sure shards
are completely copied from nodes in the same shard group before replacing the other nodes.
View the [Anti-entropy documentation](/enterprise_influxdb/v1/administration/configure/anti-entropy/)
for important information regarding anti-entropy and your database's replication factor.
{{% /note %}}

## Troubleshoot

### Cluster commands result in timeout without error

In some cases, commands used to add or remove nodes from your cluster
timeout, but don't return an error.

```bash
add-data: operation timed out with error:
```

#### Check your InfluxDB user permissions

In order to add or remove nodes to or from a cluster, your user must have `AddRemoveNode` permissions.
Attempting to manage cluster nodes without the appropriate permissions results
in a timeout with no accompanying error.

To check user permissions, log in to one of your meta nodes and `curl` the `/user` API endpoint:

```bash
curl localhost:8091/user
```

You can also check the permissions of a specific user by passing the username with the `name` parameter:

```bash
# Syntax
curl localhost:8091/user?name=<username>

# Example
curl localhost:8091/user?name=bob
```

The JSON output will include user information and permissions:

```json
"users": [
  {
    "name": "bob",
    "hash": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "permissions": {
      "": [
        "ViewAdmin",
        "ViewChronograf",
        "CreateDatabase",
        "CreateUserAndRole",
        "DropDatabase",
        "DropData",
        "ReadData",
        "WriteData",
        "ManageShard",
        "ManageContinuousQuery",
        "ManageQuery",
        "ManageSubscription",
        "Monitor"
      ]
    }
  }
]
```

_In the output above, `bob` does not have the required `AddRemoveNode` permissions
and would not be able to add or remove nodes from the cluster._

#### Check the network connection between nodes

Something may be interrupting the network connection between nodes.
To check, `ping` the server or node you're trying to add or remove.
If the ping is unsuccessful, something in the network is preventing communication.

```bash
ping enterprise-data-03:8088
```

_If pings are unsuccessful, be sure to ping from other meta nodes as well to determine
if the communication issues are unique to specific nodes._
