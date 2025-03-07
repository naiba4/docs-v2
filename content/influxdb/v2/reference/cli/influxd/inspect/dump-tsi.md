---
title: influxd inspect dump-tsi
description: >
  The `influxd inspect dump-tsi` command outputs low-level information about `tsi1` files.
influxdb/v2/tags: [tsi, inspect]
menu:
  influxdb_v2_ref:
    parent: influxd inspect
weight: 301
---

The `influxd inspect dump-tsi` command outputs low-level information about
Time Series Index (`tsi1`) files.

## Usage
```sh
influxd inspect dump-tsi [flags]
```

## Flags
| Flag |                        | Description                            | Input Type |
| :--- | :--------------------- | :------------------------------------- | :--------: |
| `-h` | `--help`               | Help for the `dump-tsi` command.       |            |
|      | `--measurement-filter` | Regular expression measurement filter. |   string   |
|      | `--measurements`       | Show raw measurement data.             |            |
|      | `--series`             | Show raw series data.                  |            |
|      | `--series-file`        | Path to series file.                   |   string   |
|      | `--tag-key-filter`     | Regular expression tag key filter.     |   string   |
|      | `--tag-keys`           | Show raw tag key data.                 |            |
|      | `--tag-value-filter`   | Regular expression tag value filter.   |   string   |
|      | `--tag-value-series`   | Show raw series data for each value.   |            |
|      | `--tag-values`         | Show raw tag value data.               |            |
