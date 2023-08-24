# File Config Provider

```bash
confluent-hub install confluentinc/kafka-config-provider-common:latest
```

This plugin provides integration with files.

## FileProvider

This config provider is used to retrieve secrets from a file.


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

```properties
config.providers=file
config.providers.file.class=io.confluent.kafka.config.providers.FileConfigProvider
```

```
${file:/opt/secret/credentials:credentials}
```

