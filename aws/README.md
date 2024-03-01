# AWS Secrets Manager Config Provider

```bash
confluent-hub install confluentinc/kafka-config-provider-aws:latest
```

This plugin provides integration with the AWS Secrets Manager service.

## SecretsManagerConfigProvider

This config provider is used to retrieve secrets from the AWS Secrets Manager service.  This uses the SDK2 from AWS.

### Secret Value

The value for the secret must be formatted as a JSON object. This allows multiple keys of data to be stored in a single secret. The name of the secret in AWS Secrets Manager will correspond to the path that is requested by the config provider.

```json
{
  "username" : "appdbsecret",
  "password" : "u$3@b3tt3rp@$$w0rd"
}
```

### Configuration


#### General

```properties
aws.access.key
```
AWS access key ID to connect with. If this value is not set the `DefaultCredentialsProvider <https://sdk.amazonaws.com/java/api/latest/software/amazon/awssdk/auth/credentials/DefaultCredentialsProvider.html>`_ will be used to attempt loading the credentials from several default locations.

* Type: STRING
* Default: 
* Valid Values: 
* Importance: HIGH

```properties
aws.region
```
Sets the region to be used by the client. For example `us-west-2`

* Type: STRING
* Default: 
* Valid Values: 
* Importance: HIGH

```properties
aws.secret.key
```
AWS secret access key to connect with.

* Type: PASSWORD
* Default: [hidden]
* Valid Values: 
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
secret.prefix
```
Sets a prefix that will be added to all paths. For example you can use `staging` or `production` and all of the calls to Secrets Manager will be prefixed with that path. This allows the same configuration settings to be used across multiple environments.

* Type: STRING
* Default: 
* Valid Values: 
* Importance: LOW
* 
```properties
endpoint.override
```
The value to override the service address used by Secrets Manager Client.  Defaults to the inbuilt value from the AWS SDK if blank.

* Type: STRING
* Default:
* Valid Values:
* Importance: LOW

```properties
secret.ttl.ms
```
The minimum amount of time that a secret should be used. After this TTL has expired Secrets Manager will be queried again in case there is an updated configuration.

* Type: LONG
* Default: 300000
* Valid Values: [1000,...]
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

### Examples

#### Loading from environment variables

The following example uses us-west-2 as the region but relies on the DefaultCredentialsProvider to find the credentials.

```properties
config.providers=secretsManager
config.providers.secretsManager.class=io.confluent.csid.config.provider.aws.SecretsManagerConfigProvider
config.providers.secretsManager.param.aws.region=us-west-2
```

#### Access Key and Secret

The following example uses an AWS Access key and Secret to connect to the us-west-2 region.

```properties
config.providers=secretsManager
config.providers.secretsManager.class=io.confluent.csid.config.provider.aws.SecretsManagerConfigProvider
config.providers.secretsManager.param.aws.region=us-west-2
config.providers.secretsManager.param.aws.access.key=qadfoadsfaweasdafsd
config.providers.secretsManager.param.aws.secret.key=asdifbasidvcasdadsfasd
```


