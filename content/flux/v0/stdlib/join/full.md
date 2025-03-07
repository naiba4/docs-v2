---
title: join.full() function
description: >
  `join.full()` performs a full outer join on two table streams.
menu:
  flux_v0_ref:
    name: join.full
    parent: join
    identifier: join/full
weight: 101
flux/v0.x/tags: [transformations]
introduced: 0.172.0
---

<!------------------------------------------------------------------------------

IMPORTANT: This page was generated from comments in the Flux source code. Any
edits made directly to this page will be overwritten the next time the
documentation is generated. 

To make updates to this documentation, update the function comments above the
function definition in the Flux source code:

https://github.com/influxdata/flux/blob/master/stdlib/join/join.flux#L392-L399

Contributing to Flux: https://github.com/influxdata/flux#contributing
Fluxdoc syntax: https://github.com/influxdata/flux/blob/master/docs/fluxdoc.md

------------------------------------------------------------------------------->

`join.full()` performs a full outer join on two table streams.

The function calls `join.tables()` with the `method` parameter set to `"full"`.

##### Function type signature

```js
(<-left: stream[A], as: (l: A, r: B) => C, on: (l: A, r: B) => bool, right: stream[B]) => stream[C] where A: Record, B: Record, C: Record
```

{{% caption %}}For more information, see [Function type signatures](/flux/v0/function-type-signatures/).{{% /caption %}}

## Parameters

### left

Left input stream. Default is piped-forward data (<-).



### right
({{< req >}})
Right input stream.



### on
({{< req >}})
Function that takes a left and right record (`l`, and `r` respectively), and returns a boolean.

The body of the function must be a single boolean expression, consisting of one
or more equality comparisons between a property of `l` and a property of `r`,
each chained together by the `and` operator.

### as
({{< req >}})
Function that takes a left and a right record (`l` and `r` respectively), and returns a record.
The returned record is included in the final output.




## Examples

### Perform a full outer join

In a full outer join, either `l` or `r` could be a default record, but they will
never both be a default record at the same time.

To get non-null values for the output record, check both `l` and `r` to see which contains
the desired values.

The example below defines a function for the `as` parameter that appropriately handles
the uncertainty of a full outer join.

`v_left` and `v_right` still use values from `l` and `r` directly, because we expect
them to sometimes be null in the output table.

For more information about the behavior of outer joins, see the [Outer joins](/flux/v0/stdlib/join/#outer-joins)
section in the `join` package documentation.

```js
import "array"
import "join"

left =
    array.from(
        rows: [
            {_time: 2022-01-01T00:00:00Z, _value: 1, label: "a"},
            {_time: 2022-01-01T00:00:00Z, _value: 2, label: "b"},
            {_time: 2022-01-01T00:00:00Z, _value: 3, label: "d"},
        ],
    )
right =
    array.from(
        rows: [
            {_time: 2022-01-01T00:00:00Z, _value: 0.4, id: "a"},
            {_time: 2022-01-01T00:00:00Z, _value: 0.5, id: "c"},
            {_time: 2022-01-01T00:00:00Z, _value: 0.6, id: "d"},
        ],
    )

join.full(
    left: left,
    right: right,
    on: (l, r) => l.label == r.id and l._time == r._time,
    as: (l, r) => {
        time = if exists l._time then l._time else r._time
        label = if exists l.label then l.label else r.id

        return {_time: time, label: label, v_left: l._value, v_right: r._value}
    },
)

```

{{< expand-wrapper >}}
{{% expand "View example output" %}}

#### Output data

| _time                | label  | v_left  | v_right  |
| -------------------- | ------ | ------- | -------- |
| 2022-01-01T00:00:00Z | a      | 1       | 0.4      |
| 2022-01-01T00:00:00Z | b      | 2       |          |
| 2022-01-01T00:00:00Z | c      |         | 0.5      |
| 2022-01-01T00:00:00Z | d      | 3       | 0.6      |

{{% /expand %}}
{{< /expand-wrapper >}}
