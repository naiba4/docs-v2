---
title: influxctl user
description: >
  The `influxctl user` command and its subcommands manage users in InfluxDB clusters.
menu:
  influxdb_clustered:
    parent: influxctl
weight: 201
cascade:
  draft: true
---

The `influxctl user` command and its subcommands manage users in
{{< product-name omit="Clustered" >}} clusters.

## Usage

```sh
influxctl user [subcommand] [subcommand options] [arguments...]
```

## Subcommands

| Subcommand                                                               | Description         |
| :----------------------------------------------------------------------- | :------------------ |
| [delete](/influxdb/clustered/reference/cli/influxctl/user/delete/) | Delete a user       |
| [invite](/influxdb/clustered/reference/cli/influxctl/user/invite/) | Invite a user       |
| [list](/influxdb/clustered/reference/cli/influxctl/user/list/)     | List all users      |
| help, h                                                                  | Output command help |

## Flags

| Flag |          | Description         |
| :--- | :------- | :------------------ |
| `-h` | `--help` | Output command help |
