---
title: Use ThingWorx with InfluxDB Cloud
description: >
  Connect [ThingWorx](https://www.ptc.com/en/products/thingworx) with your **InfluxDB Cloud** instance.
menu:
  influxdb_cloud:
    name: Use ThingWorx
    parent: Tools & integrations
weight: 109
influxdb/cloud/tags: [thingworx, ptc, iiot, persistence provider]
---

{{% note %}}
InfluxDB Cloud is a built-in component of ThingWorx on PTC Cloud in Azure. Therefore, PTC recommends using ThingWorx on [PTC Cloud](https://www.ptc.com/en/customer-success/cloud). Alternatively, use this guide to configure self-managed ThingWorx to use InfluxDB Cloud as a persistence provider.
{{% /note %}}

**To use InfluxDB Cloud as a persistence provider in ThingWorx**

1. Set up an [InfluxDB Cloud account compatible with ThingWorx](#set-up-an-influxdb-cloud-account-compatible-with-thingworx)
2. [Set up PTC ThingWorx](#set-up-ptc-thingworx)
3. [Use the InfluxDB 1.x compatibility API on InfluxDB Cloud](#use-the-influxdb-1x-compatibility-api-on-influxdb-cloud)

## Set up an InfluxDB Cloud account compatible with ThingWorx

1. [Sign up for a Cloud account](/influxdb/cloud/sign-up/), and do the following when signing up:
   - Select an AWS or Google region to store your data. To deploy on Azure region, see [use PTC Cloud](https://www.ptc.com/en/customer-success/cloud).
   - Select a Usage-based plan by entering credit card information.
2. [Create a bucket](/influxdb/cloud/organizations/buckets/create-bucket/) with an infinite retention period (select **Never** for when to **Delete Data**), and then copy the new bucket ID and save for step 4.
{{% note %}}
**Tip:** We recommend naming your bucket “thingworx”. In ThingWorx, this bucket name becomes the database name selected for the InfluxDB persistence provider configuration.
{{% /note %}}
3. [Create an All-Access token](/influxdb/cloud/security/tokens/create-token/) in InfluxDB Cloud, and save the token string for step 4. To access this string in the UI, double-clicking the new token name, and copy the string at the top of the dialog.
4. Create a DBRP mapping for your bucket by sending an HTTP `POST` request to the `/api/v2/dbrps/` InfluxDB API endpoint.

    ```sh
    curl --request POST "${influxdb-cloud-url}/api/v2/dbrps" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Token ${INFLUX_API_TOKEN}" \
    --data-raw "{
        \"bucketID\": \"${INFLUX_BUCKET_ID}\",
        \"orgID\": \"${INFLUX_ORG_ID}\",
        \"database\": \"${INFLUX_BUCKET}\",
        \"retention_policy\": \"${INFLUX_RETENTION_PERIOD}\",
        \"default\": true
    }"
    ```

    Replace the following:
    - *`INFLUX_BUCKET_ID`*: your [InfluxDB bucket](/influxdb/cloud/reference/glossary/#bucket) ID, created in step 2
    - *`INFLUX_API_TOKEN`*: your [InfluxDB API token](/influxdb/cloud/reference/glossary/#token), created in step 3
    - *`INFLUX_ORG_ID`*: your [InfluxDB organization ID](/influxdb/v2/organizations/view-orgs/#view-your-organization-id)
    - *`INFLUX_BUCKET`*: your [InfluxDB bucket](/influxdb/cloud/reference/glossary/#bucket) name (`thingworx`), created in step 2
    - *`INFLUX_RETENTION_PERIOD`*: your [InfluxDB retention period](/influxdb/cloud/reference/glossary/#retention-period), typically `autogen`

5. (Optional) We recommend [creating a new Read/Write token](/influxdb/cloud/security/tokens/create-token/) with read/write access to the bucket that you set up in step 2. A read/write token is useful for non-admin users to access configuration settings in ThingWorx. Copy and save the new token string to [set up PTC ThingWorx](#set-up-ptc-thingworx). (To do this, double-click the token in the UI, and copy the string at the top of the dialog.)

## Set up PTC ThingWorx

1. If you haven't already, [start at step 4 in Using InfluxDB as the Persistence Provider](https://support.ptc.com/help/thingworx_hc/thingworx_8_hc/en/index.html#page/ThingWorx%2FHelp%2FComposer%2FDataStorage%2FPersistenceProviders%2Fusing_influxdb_as_the_persistence_provider.html). (Steps 1-3 are covered in [Set up an InfluxDB Cloud account compatible with ThingWorx](#set-up-an-influxdb-cloud-account-compatible-with-thingworx).)
2. For the persistence provider configuration settings, enter the following values:

    - **Connection URL**: Your [InfluxDB Cloud region URL](/influxdb/cloud/reference/regions)
    - **Database Schema**: Database name in the DBRP mapping set up in step 4 above.
    - **Username**: Login email address for your InfluxDB Cloud account.
    - **Password**: Token string--either All-Access created in step 3 or Read/Write created in step 5.

## ThingWorx API requests

ThingWorx uses the [InfluxDB 1.x compatibility API](/influxdb/cloud/reference/api/influxdb-1x/) to access the InfluxDB v2 API on InfluxDB Cloud. ThingWorx includes the InfluxDB persistence provider configuration settings that you set up for PTC ThingWorx in your API requests.

{{% note %}}
**Deleting data:** The InfluxDB v1 API in InfluxDB Cloud supports a subset of delete operations, namely DROP MEASUREMENT and DELETE statements. In some edge cases, deletes take longer to appear in query results from InfluxDB Cloud (than InfluxDB open source). To delete specific fields, delete data from ThingWorx directly in InfluxDB Cloud using the InfluxDB v2 API.
{{% /note %}}
