---
title: Common variable queries
description: Useful queries to use to populate values in common dashboard variable use cases.
menu:
  influxdb_cloud:
    parent: Use and manage variables
    name: Common variable queries
weight: 208
influxdb/cloud/tags: [variables]
---

## List buckets
List all buckets in the current organization.

_**Flux functions:**
[buckets()](/flux/v0/stdlib/influxdata/influxdb/buckets/),
[rename()](/flux/v0/stdlib/universe/rename/),
[keep()](/flux/v0/stdlib/universe/keep/)_

```js
buckets()
    |> rename(columns: {"name": "_value"})
    |> keep(columns: ["_value"])
```

## List measurements
List all measurements in a specified bucket.

_**Flux package:** [InfluxDB v1](/flux/v0/stdlib/influxdata/influxdb/v1/)  
**Flux functions:** [v1.measurements()](/flux/v0/stdlib/influxdata/influxdb/v1/measurements/)_

```js
import "influxdata/influxdb/v1"

v1.measurements(bucket: "bucket-name")
```

## List fields in a measurement
List all fields in a specified bucket and measurement.

_**Flux package:** [InfluxDB v1](/flux/v0/stdlib/influxdata/influxdb/v1/)  
**Flux functions:** [v1.measurementTagValues()](/flux/v0/stdlib/influxdata/influxdb/v1/measurementtagvalues/)_

```js
import "influxdata/influxdb/v1"

v1.measurementTagValues(
    bucket: "bucket-name",
    measurement: "measurment-name",
    tag: "_field",
)
```

## List unique tag values
List all unique tag values for a specific tag in a specified bucket.
The example below lists all unique values of the `host` tag.

_**Flux package:** [InfluxDB v1](/flux/v0/stdlib/influxdata/influxdb/v1/)_  
_**Flux functions:** [v1.tagValues()](/flux/v0/stdlib/influxdata/influxdb/v1/tagvalues/)_  

```js
import "influxdata/influxdb/v1"

v1.tagValues(bucket: "bucket-name", tag: "host")
```

## List Docker containers
List all Docker containers when using the Docker Telegraf plugin.

_**Telegraf plugin:** [Docker](/telegraf/v1/plugins/#input-docker)_  
_**Flux package:** [InfluxDB v1](/flux/v0/stdlib/influxdata/influxdb/v1/)_  
_**Flux functions:** [v1.tagValues()](/flux/v0/stdlib/influxdata/influxdb/v1/tagvalues/)_

```js
import "influxdata/influxdb/v1"

v1.tagValues(bucket: "bucket-name", tag: "container_name")
```

## List Kubernetes pods
List all Kubernetes pods when using the Kubernetes Telegraf plugin.

_**Telegraf plugin:** [Kubernetes](/telegraf/v1/plugins/#input-kubernetes)_  
_**Flux package:** [InfluxDB v1](/flux/v0/stdlib/influxdata/influxdb/v1/)_  
_**Flux functions:** [v1.measurementTagValues()](/flux/v0/stdlib/influxdata/influxdb/v1/measurementtagvalues/)_

```js
import "influxdata/influxdb/v1"

v1.measurementTagValues(
    bucket: "bucket-name",
    measurement: "kubernetes_pod_container",
    tag: "pod_name",
)
```

## List Kubernetes nodes
List all Kubernetes nodes when using the Kubernetes Telegraf plugin.

_**Telegraf plugin:** [Kubernetes](/telegraf/v1/plugins/#input-kubernetes)_  
_**Flux package:** [InfluxDB v1](/flux/v0/stdlib/influxdata/influxdb/v1/)_  
_**Flux functions:** [v1.measurementTagValues()](/flux/v0/stdlib/influxdata/influxdb/v1/measurementtagvalues/)_

```js
import "influxdata/influxdb/v1"

v1.measurementTagValues(
    bucket: "bucket-name",
    measurement: "kubernetes_node",
    tag: "node_name",
)
```
