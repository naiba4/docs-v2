---
title: Manage tokens
seotitle: Manage tokens in InfluxDB Clustered
description: >
  Manage database tokens in your InfluxDB cluster.
  Database tokens grant read and write permissions to one or more databases and
  allow for actions like writing and querying data.
menu:
  influxdb_clustered:
    parent: Administer InfluxDB Clustered
weight: 101
influxdb/clustered/tags: [tokens]
---

InfluxDB uses token authentication to authorize access to data in your InfluxDB
cluster. Each token grants read and write permissions to one or
more databases and allows for actions like writing and querying data.

All read and write actions performed against time series data in your InfluxDB
cluster must be authorized using a token. Administrative actions
such as managing tokens and databases are authorized using **management tokens**
issued by **Auth0**. Management tokens allow clients, such as the `influxctl` CLI,
to perform administrative actions.

{{% note %}}
#### Store secure tokens in a secret store

Token strings are returned _only_ on token creation.
We recommend storing database tokens in a **secure secret store**.
For example, see how to [authenticate Telegraf using tokens in your OS secret store](https://github.com/influxdata/telegraf/tree/master/plugins/secretstores/os).

#### Tokens cannot be updated

Once created, token permissions cannot be updated.
If you need a token with different permissions, create a token with the
appropriate permissions.
{{% /note %}}

---

{{< children hlevel="h2" readmore=true hr=true >}}
