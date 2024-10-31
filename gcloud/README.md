# Google Secret Manager Config Provider

```bash
confluent-hub install confluentinc/csid-secrets-provider-gcloud:latest
```

This plugin provides integration with the Google Secret Manager service.

## SecretManagerConfigProvider

This config provider is used to retrieve secrets from the Google Cloud Secret Manager service.

### Secret Value

The value for the secret must be formatted as a JSON object. This allows multiple keys of data to be stored in a single secret. The name of the secret in Google Cloud Secret Manager will correspond to the path that is requested by the config provider.

```json
{
  "username" : "db101",
  "password" : "superSecretPassword"
}
```
### Secret Retrieval

The ConfigProvider will use the name of the secret and the project id to build the Resource ID for the secret. For example assuming you configured the ConfigProvider with `config.providers.secretsManager.param.project.id=1234` and requested the secret with `${secretsManager:test-secret}`, the ConfigProvider will build a Resource ID of `projects/1234/secrets/test-secret/versions/latest`. Some behaviors can be overridden by query string parameters. More than one query string parameter can be used. For example `${secretsManager:test-secret?ttl=30000&version=1}`


### Configuration


#### General

```properties
credential.file
```
Location on the local filesystem to load the credentials.

* Type: STRING
* Default: 
* Valid Values: 
* Importance: HIGH

```properties
credential.inline
```
The content of the credentials file embedded as a string.

* Type: STRING
* Default: 
* Valid Values: 
* Importance: HIGH

```properties
credential.location
```
The location to retrieve the credentials used to access the Google Services. `ApplicationDefault` - Credentials are retrieved by calling `GoogleCredentials.getApplicationDefault()`, `File` - Credentials file is read from the file system in the location specified by `credential.file`, `Inline` - The contents of the credentials file are embedded in `credential.inline`

* Type: STRING
* Default: ApplicationDefault
* Valid Values: Matches: ``ApplicationDefault, File, Inline``
* Importance: HIGH

```properties
retry.count
```
The number of attempts to retrieve a secret from the upstream secret store.

* Type: INT
* Default: 3
* Valid Values: 
* Importance: LOW

```properties
retry.interval.seconds
```
The amount of time in seconds to wait between each attempt to retrieve a secret form the upstream secret store.

* Type: LONG
* Default: 10
* Valid Values: 
* Importance: LOW

```properties
thread.count
```
The number of threads to use when retrieving secrets and executing subscription callbacks.

* Type: INT
* Default: 3
* Valid Values: 
* Importance: LOW

```properties
timeout.seconds
```
The amount of time in seconds to wait before timing out a call to retrieve a secret from the upstream secret store. The total timeout of `get(path)` and `get(path, keys)` will be `retry.count * timeout.seconds`. For example if `timeout.seconds = 30` and `retry.count = 3` then `get(path)` and `get(path, keys)` will block for 90 seconds.

* Type: LONG
* Default: 30
* Valid Values: 
* Importance: LOW

```properties
polling.enabled
```
Determines if the config provider supports polling the upstream secret stores for changes. If disabled the methods `subscribe`, `unsubscribe`, and `unsubscribeAll` will throw a UnsupportedOperationException.

* Type: BOOLEAN
* Default: true
* Valid Values: 
* Importance: MEDIUM

```properties
polling.interval.seconds
```
The number of seconds to wait between polling intervals.

* Type: LONG
* Default: 300
* Valid Values: 
* Importance: MEDIUM

```properties
use.json
```
Whether the secret is a json object. If true, the secret will be parsed as a json object and the keys will be used as the config keys.

* Type: BOOLEAN
* Default: true
* Valid Values: 
* Importance: MEDIUM

```properties
project.id
```
The project that owns the credentials.

* Type: STRING
* Default: java.lang.Object@9f46d94
* Valid Values: 
* Importance: HIGH

### Examples


