# Microsoft Azure Key Vault Config Provider

```bash
confluent-hub install confluent/kafka-config-provider-azure:latest
```

This plugin provides integration with the Microsoft Azure Key Vault service.

## KeyVaultConfigProvider

This config provider is used to retrieve secrets from the Microsoft Azure Key Vault service.

### Secret Value

The value for the secret must be formatted as a JSON object. This allows multiple keys of data to be stored in a single secret. The name of the secret in Microsoft Azure Key Vault will correspond to the path that is requested by the config provider.

```json
{
  "username" : "db101",
  "password" : "superSecretPassword"
}
```
### Secret Retrieval

The ConfigProvider will use the name of the secret to build the request to the Key Vault service. This behavior can be overridden by setting `config.providers.keyVault.param.prefix=staging-` and requested the secret with `${keyVault:test-secret}`, the ConfigProvider will build a request for `staging-test-secret`. Some behaviors can be overridden by query string parameters. More than one query string parameter can be used. For example `${keyVault:test-secret?ttl=30000&version=1}` would return the secret named `test-secret` version `1` with a TTL of 30 seconds. After the TTL has expired the ConfigProvider will request an updated credential. If you're using this with Kafka Connect, your tasks will be reconfigured if one of the values have changed.

+-----------+------------------------------------------------+--------------------------------------------------------------------+------------------------------------------+
| Parameter | Description                                    | Default                                                            | Example                                  |
+===========+================================================+====================================================================+==========================================+
| ttl       | Used to override the TTL for the secret.       | Value specified by `config.providers.keyVault.param.secret.ttl.ms` | `${keyVault:test-secret?ttl=60000}`      |
+-----------+------------------------------------------------+--------------------------------------------------------------------+------------------------------------------+
| version   | Used to override the version of the secret.    | latest                                                             | `${keyVault:test-secret?version=1}`      |
+-----------+------------------------------------------------+--------------------------------------------------------------------+------------------------------------------+



### Configuration


#### Client Certificate

```properties
client.certificate.path
```
Location on the local filesystem for the client certificate that will be used to authenticate to Azure.

* Type: STRING
* Default: 
* Valid Values: 
* Importance: HIGH

```properties
client.certificate.pfx.password
```
The password protecting the PFX file.

* Type: PASSWORD
* Default: [hidden]
* Valid Values: 
* Importance: HIGH

```properties
client.certificate.send.certificate.chain.enabled
```
Flag to indicate if certificate chain should be sent as part of authentication request.

* Type: BOOLEAN
* Default: false
* Valid Values: 
* Importance: HIGH

```properties
client.certificate.type
```
The type of encoding used on the file specified in `client.certificate.path`. `PEM` - Certificate is formatted using PEM encoding., `PFX` - Certificate is formatted using PFX encoding. `client.certificate.pfx.password` is required.

* Type: STRING
* Default: PEM
* Valid Values: Matches: ``PEM, PFX``
* Importance: HIGH


#### General

```properties
client.id
```
The client ID of the application.

* Type: STRING
* Default: 
* Valid Values: 
* Importance: HIGH

```properties
credential.type
```
The type of credentials to use. `ClientCertificate` - Uses the ClientCertificateCredential., `ClientSecret` - Uses the ClientSecretCredential., `DefaultAzure` - Uses the DefaultAzureCredential., `UsernamePassword` - Uses the UsernamePasswordCredential.

* Type: STRING
* Default: DefaultAzure
* Valid Values: Matches: ``DefaultAzure, ClientSecret, ClientCertificate, UsernamePassword``
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
tenant.id
```
The tenant ID of the application.

* Type: STRING
* Default: 
* Valid Values: 
* Importance: HIGH

```properties
vault.url
```
The vault url to connect to. For example `https://example.vault.azure.net/`

* Type: STRING
* Default: java.lang.Object@65a4798f
* Valid Values: 
* Importance: HIGH


#### Username and Password

```properties
password
```
The password to authenticate with.

* Type: PASSWORD
* Default: [hidden]
* Valid Values: 
* Importance: HIGH

```properties
username
```
The username to authenticate with.

* Type: STRING
* Default: 
* Valid Values: 
* Importance: HIGH


#### Client Secret

```properties
client.secret
```
The client secret for the authentication.

* Type: PASSWORD
* Default: [hidden]
* Valid Values: 
* Importance: HIGH

### Examples

#### Default Credentials

The following example uses the DefaultAzureCredential to load the credentials.

```properties
config.providers=keyVault
config.providers.keyVault.class=io.confluent.csid.config.provider.azure.KeyVaultConfigProvider
config.providers.keyVault.param.vault.url=https://example.vault.azure.net/
```

#### Client Certificate - PEM

The following example uses the ClientCertificateCredential to load the credentials.

```properties
config.providers=keyVault
config.providers.keyVault.class=io.confluent.csid.config.provider.azure.KeyVaultConfigProvider
config.providers.keyVault.param.vault.url=https://example.vault.azure.net/
config.providers.keyVault.param.client.certificate.type=PEM
config.providers.keyVault.param.credential.type=ClientCertificate
config.providers.keyVault.param.client.certificate.path=/path/to/certificate.pem
config.providers.keyVault.param.tenant.id=27e831e4-5cff-4143-b612-64de151b2f3e
```

#### Client Secret

The following example uses the ClientSecretCredential to load the credentials.

```properties
config.providers=keyVault
config.providers.keyVault.class=io.confluent.csid.config.provider.azure.KeyVaultConfigProvider
config.providers.keyVault.param.vault.url=https://example.vault.azure.net/
config.providers.keyVault.param.credential.type=ClientSecret
config.providers.keyVault.param.client.secret=asdonfasodfasd
config.providers.keyVault.param.tenant.id=27e831e4-5cff-4143-b612-64de151b2f3e
```

#### Client Certificate - PFX

The following example uses the ClientCertificateCredential to load the credentials.

```properties
config.providers=keyVault
config.providers.keyVault.class=io.confluent.csid.config.provider.azure.KeyVaultConfigProvider
config.providers.keyVault.param.vault.url=https://example.vault.azure.net/
config.providers.keyVault.param.client.certificate.type=PFX
config.providers.keyVault.param.credential.type=ClientCertificate
config.providers.keyVault.param.client.certificate.path=/path/to/certificate.pfx
config.providers.keyVault.param.tenant.id=27e831e4-5cff-4143-b612-64de151b2f3e
```

#### Username and Password

The following example uses the UsernamePasswordCredential to load the credentials.

```properties
config.providers=keyVault
config.providers.keyVault.class=io.confluent.csid.config.provider.azure.KeyVaultConfigProvider
config.providers.keyVault.param.vault.url=https\://example.vault.azure.net/
config.providers.keyVault.param.credential.type=UsernamePassword
config.providers.keyVault.param.username=foo
config.providers.keyVault.param.password=bar
config.providers.keyVault.param.tenant.id=27e831e4-5cff-4143-b612-64de151b2f3e
```


