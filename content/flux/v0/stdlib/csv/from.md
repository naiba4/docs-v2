---
title: csv.from() function
description: >
  `csv.from()` retrieves data from a comma separated value (CSV) data source and
  returns a stream of tables.
menu:
  flux_v0_ref:
    name: csv.from
    parent: csv
    identifier: csv/from
weight: 101
flux/v0.x/tags: [csv, inputs]
---

<!------------------------------------------------------------------------------

IMPORTANT: This page was generated from comments in the Flux source code. Any
edits made directly to this page will be overwritten the next time the
documentation is generated. 

To make updates to this documentation, update the function comments above the
function definition in the Flux source code:

https://github.com/influxdata/flux/blob/master/stdlib/csv/csv.flux#L94-L94

Contributing to Flux: https://github.com/influxdata/flux#contributing
Fluxdoc syntax: https://github.com/influxdata/flux/blob/master/docs/fluxdoc.md

------------------------------------------------------------------------------->

`csv.from()` retrieves data from a comma separated value (CSV) data source and
returns a stream of tables.



##### Function type signature

```js
(?csv: string, ?file: string, ?mode: string) => stream[A] where A: Record
```

{{% caption %}}For more information, see [Function type signatures](/flux/v0/function-type-signatures/).{{% /caption %}}

## Parameters

### csv

CSV data.

Supports anonotated CSV or raw CSV. Use `mode` to specify the parsing mode.

### file

File path of the CSV file to query.

The path can be absolute or relative.
If relative, it is relative to the working directory of the `fluxd` process.
The CSV file must exist in the same file system running the `fluxd` process.

### mode

is the CSV parsing mode. Default is `annotations`.

**Available annotation modes**
- **annotations**: Use CSV notations to determine column data types.
- **raw**: Parse all columns as strings and use the first row as the
header row and all subsequent rows as data.


## Examples

- [Query annotated CSV data from file](#query-annotated-csv-data-from-file)
- [Query raw data from CSV file](#query-raw-data-from-csv-file)
- [Query an annotated CSV string](#query-an-annotated-csv-string)
- [Query a raw CSV string](#query-a-raw-csv-string)

### Query annotated CSV data from file

```js
import "csv"

csv.from(file: "path/to/data-file.csv")

```


### Query raw data from CSV file

```js
import "csv"

csv.from(file: "/path/to/data-file.csv", mode: "raw")

```


### Query an annotated CSV string

```js
import "csv"

csvData =
    "
#datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,string,string,double
#group,false,false,false,false,false,true,true,false
#default,,,,,,,,
,result,table,_start,_stop,_time,region,host,_value
,mean,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,east,A,15.43
,mean,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:51:00Z,east,A,65.15
,mean,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,east,B,59.25
,mean,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:51:20Z,east,B,18.67
,mean,2,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,east,C,52.62
,mean,2,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:51:40Z,east,C,82.16
"

csv.from(csv: csvData)

```

{{< expand-wrapper >}}
{{% expand "View example output" %}}

#### Output data

| _start               | _stop                | _time                | *region | *host | _value  |
| -------------------- | -------------------- | -------------------- | ------- | ----- | ------- |
| 2018-05-08T20:50:00Z | 2018-05-08T20:51:00Z | 2018-05-08T20:50:00Z | east    | A     | 15.43   |
| 2018-05-08T20:50:00Z | 2018-05-08T20:51:00Z | 2018-05-08T20:51:00Z | east    | A     | 65.15   |

| _start               | _stop                | _time                | *region | *host | _value  |
| -------------------- | -------------------- | -------------------- | ------- | ----- | ------- |
| 2018-05-08T20:50:00Z | 2018-05-08T20:51:00Z | 2018-05-08T20:50:20Z | east    | B     | 59.25   |
| 2018-05-08T20:50:00Z | 2018-05-08T20:51:00Z | 2018-05-08T20:51:20Z | east    | B     | 18.67   |

| _start               | _stop                | _time                | *region | *host | _value  |
| -------------------- | -------------------- | -------------------- | ------- | ----- | ------- |
| 2018-05-08T20:50:00Z | 2018-05-08T20:51:00Z | 2018-05-08T20:50:40Z | east    | C     | 52.62   |
| 2018-05-08T20:50:00Z | 2018-05-08T20:51:00Z | 2018-05-08T20:51:40Z | east    | C     | 82.16   |

{{% /expand %}}
{{< /expand-wrapper >}}

### Query a raw CSV string

```js
import "csv"

csvData =
    "
_start,_stop,_time,region,host,_value
2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,east,A,15.43
2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,east,B,59.25
2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,east,C,52.62
"

csv.from(csv: csvData, mode: "raw")

```

{{< expand-wrapper >}}
{{% expand "View example output" %}}

#### Output data

| _start               | _stop                | _time                | region  | host  | _value  |
| -------------------- | -------------------- | -------------------- | ------- | ----- | ------- |
| 2018-05-08T20:50:00Z | 2018-05-08T20:51:00Z | 2018-05-08T20:50:00Z | east    | A     | 15.43   |
| 2018-05-08T20:50:00Z | 2018-05-08T20:51:00Z | 2018-05-08T20:50:20Z | east    | B     | 59.25   |
| 2018-05-08T20:50:00Z | 2018-05-08T20:51:00Z | 2018-05-08T20:50:40Z | east    | C     | 52.62   |

{{% /expand %}}
{{< /expand-wrapper >}}
