![CI Workflow](https://github.com/harrykodden/scim-sample/actions/workflows/ci.yml/badge.svg) ![cov](https://raw.githubusercontent.com/HarryKodden/scim-sample/python-coverage-comment-action-data/badge.svg)

# SCIM

## Docker image

Public image available at:
<https://hub.docker.com/r/harrykodden/scim>

You do not need to build the docker image yourself. You can just pull the prepared image which is available for both **linux/amd** and **linux/arm** architectures.

```bash
docker pull harrykodden/scim
```

## Build the image

Alternatively, you can build the image yourself:

```bash
docker build -t scim .
```

## Starting the application

```bash
docker run -p 8000:8000 harrykodden/scim
```

or if you build it yourself:

```bash
docker run -p 8000:8000 scim
```

This will show like:

```log
INFO: Started server process [1]
INFO: Waiting for application startup.
INFO: Application startup complete.
INFO: Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

go to your browser and open window at:

```bash
http://localhost:8000
```

This will open the OpenAPI document interface. In this you can experiment and execute all the SCIM API Endpoints.

![OpenAPI Document](openapi.png)

## Data handling options

You have different options to handle the data. The simplest is the the flat files handling. You simply assign a (volume-) path to the location where you want to persist the data.
Other options include SQL and NoSQL database, JumpCloud and forwarding the data to an upstream SCIM Server.

![Data Handling Options](data.png)

The options can be activated by assiging environment variable values, see below.

The plugin methodology makes it very easy to add additional data backends, you simply have to subclass the **Plugin Class** (`code/data/plugins/__init__.py`) and provide logic for the base class methods.

```python
# code/data/plugins/__init__.py

from typing import Any
import uuid


class Plugin(object):
    """Base class that each plugin must inherit from. within this class
    you must define the methods that all of your plugins must implement
    """

    def __init__(self):
        self.description = 'UNKNOWN'

    def id(self) -> str:
        return str(uuid.uuid4())

    def __iter__(self) -> Any:
        raise NotImplementedError

    def __delete__(self, id: str) -> None:
        raise NotImplementedError

    def __getitem__(self, id: str) -> Any:
        raise NotImplementedError

    def __setitem__(self, id: str, details: Any) -> None:
        raise NotImplementedError

```

For inspiration on how to do that, please take a look at the provided implementation examples. If you do want to contribute with a nice additional backend, please do not hesitate to submit a Pull Request.

## Environment variables

This image uses environment variables for configuration.

| Available variables | Description | Example | Default |
| ------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| `LOGLEVEL` | The application logging level | ERROR | INFO |
| `API_KEY` | The API key to authenticate with | mysecret | secret |
| `PAGE_SIZE` | The maximum number of resources returned in 1 response. | 10 | 100 |
| `BASE_PATH` | The base path of all API endpoints | /api/v2 | / |
| `DATA_PATH` | File system path name | /mnt/scim | /tmp |
| `MONGO_DB` | Mongo connection string | mongodb://user:password@mongo_host | |
| `DATABASE_URL` | SQL Database connection string | postgresql://user:password@postrgres_host:5432/mydb<br />**or**<br /> mysql+pymysql://user:password@mysql_host/mydb | |
| `JUMPCLOUD_URL` | The API endpoint for JumpCloud | <https://console.jumpcloud.com> | |
| `JUMPCLOUD_KEY` | The API Key for your JumpCloud tenant | **value** of API key obtained from JumpCloud\_<br /><br />**Mandatory when JUMPCLOUD_URL is set** | |
| `FORWARD_SCIM_URL` | Forward SCIM request to upstream SCIM server | <https://example.com/v2/api> | |
| `FORWARD_SCIM_KEY` | API KEY for **FORWARD_SCIM_URL** scim server. if not provided, **API_KEY** will be used | my-secret-password | |
| `USER_MAPPING` | A JSON string that specify how attribute values should be mapped to different attributes | '{"userName": "sram_user_extension.eduPersonUniqueId"} | |
| `GROUP_MAPPING` | A JSON string that specify how attribute values should be mapped to different attributes | '{"id": "displanNameuser_extension.eduPersonUniqueId"} | |
| `USER_MODEL_NAME` | User model name | myUsers | Users |
| `GROUP_MODEL_NAME` | Group model name | myGroups | Groups |
| `AMQP` | (optional) the amqp address of the MQ Server to broadcast SCIM updates to | 'amqp://localhost' | |
| `QUEUE` | (optional) the amqp queue name to broadcast SCIM updates to | | 'SCIM' |


## Handling data

The data that is received by this SCIM server can be handled in different ways. Below is an example on how to pick up specific attributes from the received data.

### Example on MySQL

Suppose you have configured a MySQL database via the SQL Plugin configuration. Then your data will be persisted in 2 MySQL database tables **Users** and **Groups**.
The structure of both tables are alike and have only 2 columnns

| id | details |
| ---------------------------- | -------------------------------------------------------------------- |
| unique uuid of this resource | this is a JSON datatype holding the data attributes of this resource |

For example after a provisiong the data for **Users** contains:

| id | details  |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 613277a6-aa52-440e-b604-9bbd14343558 | {\"userName\": \"hkodden5\", \"active\": true, \"externalId\": \"<44cb3ba1-7a58-49af-961d-9a1253a26181@sram.surf.nl>\", \"name\": {\"familyName\": \"Kodden\", \"givenName\": \"Harry\"}, \"displayName\": \"Harry Kodden\", \"emails\": [{\"primary\": true, \"value\": \"harry.kodden@surf.nl\"}] ...} |

Then you would like to retrieve specific values out of the JSON data.
For example, we want to lookup the userName.

```sql
select id, details->'$.userName' as userName from Users where id = '613277a6-aa52-440e-b604-9bbd14343558';
```

will result in:

| id | userName |
| ------------------------------------ | ---------- |
| 613277a6-aa52-440e-b604-9bbd14343558 | "hkodden5" |

# AMQP

Optionally a AMQP endpoint can be configured to which incoming SCIM updates will be reported. The data to this notification mechanism consist of the following details:

## Incoming Create/Update operation

During successful creation of the SCIM resource, the notification consists of this payload

### Create of User Resource

```json
{
  "operation": "Create",
  "resourceType": "User",
  "id": "3ea25126-78a6-4d5e-9246-fa100e4cff10",
  "externalId": "c601d601-4a54-498a-9c45-f98882050733@sram.surf.nl"
}
```

### Create of Group Resource

```json
{
  "operation": "Create",
  "resourceType": "Group",
  "id": "3c7f1338-c131-425a-9a94-2a2f08440820",
  "externalId": "e46e388c-9362-4aaa-b23f-a855bf559598@sram.surf.nl",
  "members": [
    {
      "resourceType": "User",
      "id": "3ea25126-78a6-4d5e-9246-fa100e4cff10",
      "externalId": "c601d601-4a54-498a-9c45-f98882050733@sram.surf.nl"
    }
  ]
}
```

### Update of User Resource

```json
{
  "operation": "Update",
  "resourceType": "User",
  "id": "3ea25126-78a6-4d5e-9246-fa100e4cff10",
  "externalId": "c601d601-4a54-498a-9c45-f98882050733@sram.surf.nl"
}
```

### Update of Group Resource

```json
{
  "operation": "Update",
  "resourceType": "Group",
  "id": "3c7f1338-c131-425a-9a94-2a2f08440820",
  "externalId": "e46e388c-9362-4aaa-b23f-a855bf559598@sram.surf.nl",
  "members": [
    {
      "resourceType": "User",
      "id": "3ea25126-78a6-4d5e-9246-fa100e4cff10",
      "externalId": "c601d601-4a54-498a-9c45-f98882050733@sram.surf.nl"
    }
  ]
}
```

## Incoming Delete operation

During successful deletion of the SCIM resource, the notification consist of this payload.

Note: The reported **id** can not be read anymore, since it will no longer exists. The value of the **id** should only be used to inspect possible use as a foreign key value.

### Delete of User Resource

```json
{
  "operation": "Delete",
  "resourceType": "User",
  "id": "3ea25126-78a6-4d5e-9246-fa100e4cff10",
  "externalId": "c601d601-4a54-498a-9c45-f98882050733@sram.surf.nl"
}
```

### Delete of Group Resource

```json
{
  "operation": "Update",
  "resourceType": "Group",
  "id": "3c7f1338-c131-425a-9a94-2a2f08440820",
  "externalId": "e46e388c-9362-4aaa-b23f-a855bf559598@sram.surf.nl",
  "members": [
    {
      "resourceType": "User",
      "id": "3ea25126-78a6-4d5e-9246-fa100e4cff10",
      "externalId": "c601d601-4a54-498a-9c45-f98882050733@sram.surf.nl"
    }
  ]
}
```