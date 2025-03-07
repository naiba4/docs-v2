---
title: Slack event handler
list_title: Slack
description: >
  The Slack event handler allows you to send Kapacitor alerts to Slack. This page includes configuration options and usage examples.
menu:
  kapacitor_v1:
    name: Slack
    weight: 1600
    parent: Event handlers
aliases:
  - /kapacitor/v1/event_handlers/slack/
---

[Slack](https://slack.com) is a widely used "digital workspace" that facilitates
communication among team members.
Kapacitor can be configured to send alert messages to Slack.

## Configuration
Configuration as well as default [option](#options) values for the Slack event
handler are set in your `kapacitor.conf`.
Below is an example configuration:

```toml
[[slack]]
  enabled = true
  default = true
  workspace = "example.slack.com"
  url = "https://slack.com/api/chat.postMessage"
  token = "mY5uP3Rs3CrE7t0keN"
  channel = "#alerts"
  username = "kapacitor"
  global = false
  state-changes-only = false
  ssl-ca = "/path/to/ca.crt"
  ssl-cert = "/path/to/cert.crt"
  ssl-key = "/path/to/private-key.key"
  insecure-skip-verify = false
```

{{% note %}}
Multiple Slack clients may be configured by repeating `[[slack]]` sections.
The `workspace` acts as a unique identifier for each configured Slack client.
{{% /note %}}

#### enabled
Set to `true` to enable the Slack event handler.

#### default
Identify one of the Slack configurations as the default if there are multiple
Slack configurations.

#### workspace
Slack workspace ID.
This can be any string that identifies this particular Slack configuration.
A logical choice is the name of the Slack workspace, e.g. `<workspace>.slack.com`.

#### url
Slack webhook URL.
For [new Slack apps](#new-slack-apps),
use `https://slack.com/api/chat.postMessage`.
For legacy Slack Incoming Webhooks, [add a new webhook](https://slack.com/services/new/incoming-webhook)
for Kapacitor and Slack will provide the webhook URL.

#### token
Slack OAuth token used with [new Slack apps](#new-slack-apps).
For legacy Incoming Webhooks, leave `token` as an empty string (`""`).

#### channel
Default channel for messages.

#### username
Slack bot username.

#### global
If true all the alerts will be sent to Slack without explicitly specifying Slack
in the TICKscript.

#### state-changes-only
Sets all alerts in state-changes-only mode, meaning alerts will only be sent if
the alert state changes.
_Only applies if `global` is `true`._

#### ssl-ca
Path to certificate authority file.

#### ssl-cert
Path to host certificate file.

#### ssl-key
Path to certificate private key file.

#### insecure-skip-verify
Use SSL but skip chain and host verification.
_This is necessary if using a self-signed certificate._

## Options
The following Slack event handler options can be set in a
[handler file](/kapacitor/v1/reference/event_handlers/#create-a-topic-handler-with-a-handler-file) or when using
`.slack()` in a TICKscript.

| Name       | Type   | Description                                                                                                                   |
| ----       | ----   | -----------                                                                                                                   |
| workspace  | string | Specifies which Slack configuration to use when there are multiple.                                                           |
| channel    | string | Slack channel in which to post messages. If empty uses the channel from the configuration.                                    |
| username   | string | Username of the Slack bot. If empty uses the username from the configuration.                                                 |
| icon-emoji | string | IconEmoji is an emoji name surrounded in ':' characters. The emoji image will replace the normal user icon for the slack bot. |

### Example: handler file
```yaml
id: handler-id
topic: topic-name
kind: slack
options:
  workspace: 'workspace.slack.com'
  channel: '#alerts'
  username: 'kapacitor'
  icon-emoji: ':smile:'
```

### Example: TICKscript
```js
|alert()
  // ...
  .slack()
    .workspace('workspace.slack.com')
    .channel('#alerts')
    .username('kapacitor')
    .iconEmoji(':smile:')
```

## Slack Setup

### Legacy Slack apps
To send alerts from Kapacitor to Slack using Slack's legacy incoming webhooks:

1. Log into to your Slack workspace
2. [Create a new incoming webhook](https://slack.com/services/new/incoming-webhook )
for Kapacitor.
3. Add the generated webhook URL as the `url` in the `[[slack]]`
configuration section of your `kapacitor.conf`.

### New Slack apps
To send alerts from Kapacitor to Slack using a [new Slack app](https://api.slack.com/authentication/basics):

1. Visit <https://api.slack.com/apps>.
2. Create a new app or click on an existing app.
3. Click **OAuth & Permissions** to find the token.
    
{{% note %}}
Ensure your app has 'chat:write' and 'chat:write.public' permissions.
{{% /note %}}


## Using the Slack event handler
With one or more Slack event handlers enabled and configured in your
`kapacitor.conf`, use the `.slack()` attribute in your TICKscripts to send
alerts to Slack or define a Slack handler that subscribes to a topic and sends
published alerts to Slack.

{{% note %}}
To avoid posting a message every alert interval, use
[AlertNode.StateChangesOnly](/kapacitor/v1/reference/nodes/alert_node/#statechangesonly)
so only events where the alert changed state are sent to Slack.
{{% /note %}}

The examples below use the following Slack configurations defined in the `kapacitor.conf`:

###### Slack settings in kapacitor.conf
```toml
[[slack]]
  enabled = true
  default = true
  workspace = "alerts"
  url = "https://slack.com/api/chat.postMessage"
  token = "mY5uP3Rs3CrE7t0keN1"
  channel = "#alerts"
  username = "AlertBot"
  global = false
  state-changes-only = false

[[slack]]
  enabled = true
  default = false
  workspace = "error-reports"
  url = "https://slack.com/api/chat.postMessage"
  token = "mY5uP3Rs3CrE7t0keN2"
  channel = "#error-reports"
  username = "StatsBot"
  global = false
  state-changes-only = false
```

### Send alerts to Slack from a TICKscript
The following TICKscript uses the `.slack()` event handler to send the message,
"Hey, check your CPU", to the `#alerts` Slack channel whenever idle CPU usage
drops below 20%.

###### slack-cpu-alert.tick
```js
stream
  |from()
    .measurement('cpu')
  |alert()
    .warn(lambda: "usage_idle" < 20)
    .stateChangesOnly()
    .message('Hey, check your CPU')
    .slack()   
      .iconEmoji(':exclamation:')  
```

### Send alerts to Slack from a defined handler

The following setup sends an alert to the `cpu` topic with the message,
"Hey, check your CPU".
A Slack handler is added that subscribes to the `cpu` topic and publishes all
alert messages to Slack.

Create a TICKscript that publishes alert messages to a topic.
The TICKscript below sends an critical alert message to the `cpu` topic any time
idle CPU usage drops below 5%.

###### cpu\_alert.tick
```js
stream
  |from()
    .measurement('cpu')
  |alert()
    .crit(lambda: "usage_idle" < 5)
    .stateChangesOnly()
    .message('Hey, check your CPU')
    .topic('cpu')
```

Add and enable the TICKscript:

```bash
kapacitor define cpu_alert -tick cpu_alert.tick
kapacitor enable cpu_alert
```

Create a handler file that subscribes to the `cpu` topic and uses the Slack
event handler to send alerts to Slack. This handler using the non-default Slack
handler, "critical-alerts", which sends messages to the #critical-alerts channel
in Slack.

###### slack\_cpu\_handler.yaml
```yaml
id: slack-cpu-alert
topic: cpu
kind: slack
options:
  workspace: 'alerts'
  icon-emoji: ':fire:'
```

Add the handler:

```bash
kapacitor define-topic-handler slack_cpu_handler.yaml
```

### Using multiple Slack configurations
Kapacitor can use multiple Slack integrations, each identified by the value of
the [`workspace`](#workspace) config. The TICKscript below illustrates how
multiple Slack integrations can be used.

In the `kapacitor.conf` [above](#using-the-slack-event-handler), there are two
Slack configurations; one for alerts and the other for daily stats. The
`workspace` configuration for each Slack configuration act as a unique identifiers.

The following TICKscript sends alerts to the `alerts` Slack workspace.

###### slack-cpu-alert.tick
```js
stream
  |from()
    .measurement('cpu')
  |alert()
    .crit(lambda: "usage_idle" < 5)
    .stateChangesOnly()
    .message('Hey, I think the machine is on fire.')
    .slack()
      .workspace('alerts')
      .iconEmoji(':fire:')
```

Error rates are also being stored in the same InfluxDB instance and we want to
send daily reports of `500` errors to the `error-reports` Slack workspace.
The following TICKscript collects `500` error occurances and publishes them to
the `500-errors` topic.

###### 500_errors.tick
```js
stream
  |from()
    .measurement('errors')
    .groupBy('500')
  |alert()
    .info(lamda: 'count' > 0)
    .noRecoveries()
    .topic('500-errors')  
```

Below is an [aggregate](/kapacitor/v1/reference/event_handlers/aggregate/) handler that
subscribes to the `500-errors` topic, aggregates the number of 500 errors over a
24 hour period, then publishes an aggregate message to the `500-errors-24h` topic.

###### 500\_errors\_24h.yaml
```yaml
id: 500-errors-24h
topic: 500-errors
kind: aggregate
options:
  interval: 24h
  topic: 500-errors-24h
  message: '{{ .Count }} 500 errors last 24 hours.'
```

Last, but not least, a Slack handler that subscribes to the `500-errors-24h`
topic and publishes aggregated count messages to the `error-reports` Slack workspace:

###### slack\_500\_errors\_daily.yaml
```yaml
id: slack-500-errors-daily
topic: 500-errors-24h
kind: slack
options:
  workspace: error-reports
```
