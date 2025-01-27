# Hashicorp Vault Config Provider

```bash
confluent-hub install confluentinc/csid-secrets-provider-vault:latest
```

This plugin provides integration with [Hashicorp Vault](https://www.hashicorp.com/products/vault/secrets-management).

## VaultConfigProvider

This config provider is used to retrieve secrets from the Hashicorp Vault.

### Configuration

#### General

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
vault.namespace
```
Sets a global namespace to the Vault server instance, if desired.

* Type: STRING
* Default:
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
vault.address
```
Sets the address (URL) of the Vault server instance to which API calls should be sent. If no address is explicitly set, the object will look to the `VAULT_ADDR` If you do not supply it explicitly AND no environment variable value is found, then initialization may fail.

* Type: STRING
* Default:
* Valid Values:
* Importance: HIGH

```properties
vault.auth.method
```
The login method to use. `AppRole` - Authentication via the `ldap
<https://www.vaultproject.io/docs/auth/token>`_. endpoint., `Certificate` - Authentication via the `ldap
<https://www.vaultproject.io/docs/auth/token>`_. endpoint., `LDAP` - Authentication via the `ldap
<https://www.vaultproject.io/docs/auth/token>`_. endpoint., `Token` - Authentication via the `token
<https://www.vaultproject.io/docs/auth/token>`_. endpoint., `UserPass` - Authentication via the `ldap
<https://www.vaultproject.io/docs/auth/token>`_. endpoint.

* Type: STRING
* Default: Token
* Valid Values: Matches: ``Token, LDAP, UserPass, Certificate, AppRole``
* Importance: HIGH

```properties
vault.auth.mount
```
Location of the mount to use for authentication.

* Type: STRING
* Default:
* Valid Values:
* Importance: HIGH

```properties
vault.auth.password
```
The password to authenticate with.

* Type: PASSWORD
* Default: [hidden]
* Valid Values:
* Importance: HIGH

```properties
vault.auth.role
```
The role to use for authentication.

* Type: STRING
* Default:
* Valid Values:
* Importance: HIGH

```properties
vault.auth.secret
```
The secret to use for authentication.

* Type: PASSWORD
* Default: [hidden]
* Valid Values:
* Importance: HIGH

```properties
vault.auth.token
```
Sets the token used to access Vault. If no token is explicitly set then the `VAULT_TOKEN` environment variable will be used.

* Type: PASSWORD
* Default: [hidden]
* Valid Values:
* Importance: HIGH

```properties
vault.auth.username
```
The username to authenticate with.

* Type: STRING
* Default:
* Valid Values:
* Importance: HIGH

```properties
vault.url.logging.enabled
```
Flag to copy java.util.logging messages for "sun.net.www.protocol.http.HttpURLConnection" to the providers logger. Warning this will log all of the traffic for ANY Vault client that is in the current JVM. This could also receive any log message for other code that uses java.net.UrlConnection.

* Type: BOOLEAN
* Default: false
* Valid Values:
* Importance: LOW

```properties
vault.prefixpath
```
Path prefix of the secret. Used to compute the path depth at which "/data" is inserted for kv v2 secrets. A placeholder may be used as only its depth is considered.

* Type: STRING
* Default:
* Valid Values:
* Importance: MEDIUM

```properties
vault.secrets.version
```
The secrets engine version (1 or 2) to use.

* Type: INT
* Default: 2
* Valid Values:
* Importance: MEDIUM

```properties
vault.ssl.verify.enabled
```
Flag to determine if the configProvider should verify the SSL Certificate of the Vault server. Outside of development this should never be enabled.

* Type: BOOLEAN
* Default: true
* Valid Values:
* Importance: HIGH

### Examples

#### LDAP

The following example uses a ldap username and password to authenticate to vault.

```properties
config.providers=vault
config.providers.vault.class=io.confluent.csid.config.provider.vault.VaultConfigProvider
config.providers.vault.param.vault.auth.token=sdifgnabdifgasbffvasdfasdfadf
config.providers.vault.param.vault.address=https://vault.example.com
config.providers.vault.param.vault.auth.method=LDAP
```

#### Token

The following example uses a token to authenticate to vault.

```properties
config.providers=vault
config.providers.vault.class=io.confluent.csid.config.provider.vault.VaultConfigProvider
config.providers.vault.param.vault.auth.token=sdifgnabdifgasbffvasdfasdfadf
config.providers.vault.param.vault.address=https://vault.example.com
config.providers.vault.param.vault.auth.method=Token
```

#### Token, using kv store Version 1

The following example uses a token to authenticate to vault.

```properties
config.providers=vault
config.providers.vault.class=io.confluent.csid.config.provider.vault.VaultConfigProvider
config.providers.vault.param.vault.auth.token=sdifgnabdifgasbffvasdfasdfadf
config.providers.vault.param.vault.address=https://vault.example.com
config.providers.vault.param.vault.auth.method=Token
config.providers.vault.param.secrets.version=1
```
