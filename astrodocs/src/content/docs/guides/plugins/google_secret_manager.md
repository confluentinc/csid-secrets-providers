---
title: Google Secret Manager Config Provider
tableOfContents:
    maxHeadingLevel: 4
---

```bash
confluent-hub install confluentinc/csid-secrets-provider-gcloud:latest
```

This plugin provides integration with the [Google Secret Manager service](https://cloud.google.com/secret-manager).

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

```java
credential.file
```
Location on the local filesystem to load the credentials.

* Type: STRING
* Default:
* Valid Values:
* Importance: HIGH

```java
credential.inline
```
The content of the credentials file embedded as a string.

* Type: STRING
* Default:
* Valid Values:
* Importance: HIGH

```java
credential.location
```
The location to retrieve the credentials used to access the Google Services. `ApplicationDefault` - Credentials are retrieved by calling `GoogleCredentials.getApplicationDefault()`, `File` - Credentials file is read from the file system in the location specified by `credential.file`, `Inline` - The contents of the credentials file are embedded in `credential.inline`

* Type: STRING
* Default: ApplicationDefault
* Valid Values: Matches: ``ApplicationDefault, File, Inline``
* Importance: HIGH

```java
retry.count
```
The number of attempts to retrieve a secret from the upstream secret store.

* Type: INT
* Default: 3
* Valid Values:
* Importance: LOW

```java
retry.interval.seconds
```
The amount of time in seconds to wait between each attempt to retrieve a secret form the upstream secret store.

* Type: LONG
* Default: 10
* Valid Values:
* Importance: LOW

```java
thread.count
```
The number of threads to use when retrieving secrets and executing subscription callbacks.

* Type: INT
* Default: 3
* Valid Values:
* Importance: LOW

```java
timeout.seconds
```
The amount of time in seconds to wait before timing out a call to retrieve a secret from the upstream secret store. The total timeout of `get(path)` and `get(path, keys)` will be `retry.count * timeout.seconds`. For example if `timeout.seconds = 30` and `retry.count = 3` then `get(path)` and `get(path, keys)` will block for 90 seconds.

* Type: LONG
* Default: 30
* Valid Values:
* Importance: LOW

```java
polling.enabled
```
Determines if the config provider supports polling the upstream secret stores for changes. If disabled the methods `subscribe`, `unsubscribe`, and `unsubscribeAll` will throw a UnsupportedOperationException.

* Type: BOOLEAN
* Default: true
* Valid Values:
* Importance: MEDIUM

```java
polling.interval.seconds
```
The number of seconds to wait between polling intervals.

* Type: LONG
* Default: 300
* Valid Values:
* Importance: MEDIUM

```java
project.id
```
The project that owns the credentials.

* Type: LONG
* Default: java.lang.Object@4fbda97b
* Valid Values:
* Importance: HIGH

### Examples


#### Credentials - File

The following example uses the Credentials File to load the credentials.

Location on the local filesystem to load the credentials.


```properties
config.providers=secretsManager

config.providers.secretsManager.class=io.confluent.csid.config.provider.gcloud.SecretManagerConfigProvider
config.providers.secretsManager.param.project.id=1234
config.providers.secretsManager.param.credential.location=File
config.providers.secretsManager.param.credential.file=/path/to/gcp_credentials.json
config.providers.secretsManager.param.retry.count=3
config.providers.secretsManager.param.retry.interval.seconds=10
config.providers.secretsManager.param.timeout.seconds=30
config.providers.secretsManager.param.polling.enabled=true
config.providers.secretsManager.param.polling.interval.seconds=300
```

#### Credentials - Inline

The following example uses the Credentials Inline to load the credentials as a String.

This is useful for environments where file-based credentials are impractical, such as containerized deployments or automated setups.

```properties
config.providers=secretsManager

config.providers.secretsManager.class=io.confluent.csid.config.provider.gcloud.SecretManagerConfigProvider
config.providers.secretsManager.param.project.id=1234
config.providers.secretsManager.param.credential.location=Inline
config.providers.secretsManager.param.credential.inline={
\"type\": \"service_account\",
\"project_id\": \"my-project-id\",
\"private_key_id\": \"123456789abcdef123456789abcdef123456789\",
\"private_key\": \"-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhki...TRUNCATED_KEY_BASE64...\\n-----END PRIVATE KEY-----\\n\",
\"client_email\": \"service-account-name@my-project-id.iam.gserviceaccount.com\",
\"client_id\": \"12345678901234567890\",
\"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\",
\"token_uri\": \"https://oauth2.googleapis.com/token\",
\"auth_provider_x509_cert_url\": \"https://www.googleapis.com/oauth2/v1/certs\",
\"client_x509_cert_url\": \"https://www.googleapis.com/robot/v1/metadata/x509/service-account-name%40my-project-id.iam.gserviceaccount.com\"
}
config.providers.secretsManager.param.retry.count=3
config.providers.secretsManager.param.retry.interval.seconds=10
config.providers.secretsManager.param.timeout.seconds=30
config.providers.secretsManager.param.polling.enabled=true
config.providers.secretsManager.param.polling.interval.seconds=300
```

