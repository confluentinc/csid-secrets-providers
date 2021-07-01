package io.confluent.csid.config.provider.common;

import org.apache.kafka.common.config.AbstractConfig;
import org.apache.kafka.common.config.ConfigDef;

import java.util.Map;

public class AbstractConfigProviderConfig extends AbstractConfig {

  public static final String POLLING_INTERVAL_CONFIG = "polling.interval.seconds";
  static final String POLLING_INTERVAL_DOC = "The number of seconds to wait between polling intervals.";

  public static final String POLLING_ENABLED_CONFIG = "polling.enabled";
  static final String POLLING_ENABLED_DOC = "Determines if the config provider supports polling the " +
      "upstream secret stores for changes. If disabled the methods `subscribe`, `unsubscribe`, and `unsubscribeAll` " +
      "will throw a UnsupportedOperationException.";

  public static final String THREAD_COUNT_CONFIG = "thread.count";
  static final String THREAD_COUNT_DOC = "The number of threads to use when retrieving secrets and executing subscription callbacks.";

  public static final String RETRY_COUNT_CONFIG = "retry.count";
  static final String RETRY_COUNT_DOC = "The number of attempts to retrieve a secret from the upstream secret store.";

  public static final String RETRY_INTERVAL_SECONDS_CONFIG = "retry.interval.seconds";
  static final String RETRY_INTERVAL_SECONDS_DOC = "The amount of time in seconds to wait between each attempt to retrieve a secret form the upstream secret store.";


  public static final String TIMEOUT_SECONDS_CONFIG = "timeout.seconds";
  static final String TIMEOUT_SECONDS_DOC = "The amount of time in seconds to wait before timing out a call to retrieve a secret from the upstream secret store. The " +
      "total timeout of `get(path)` and `get(path, keys)` will be `" + RETRY_COUNT_CONFIG + " * " + TIMEOUT_SECONDS_CONFIG + "`. For example if `" + TIMEOUT_SECONDS_CONFIG +
      " = 30` and `" + RETRY_COUNT_CONFIG + " = 3` then `get(path)` and `get(path, keys)` will block for 90 seconds.";


  public final int threadCount;
  public final long pollingIntervalSeconds;
  public final boolean pollingEnabled;
  public final int retryCount;
  public final long retryIntervalSeconds;
  public final long timeoutSeconds;

  public AbstractConfigProviderConfig(ConfigDef definition, Map<?, ?> originals) {
    super(definition, originals);
    this.threadCount = getInt(THREAD_COUNT_CONFIG);
    this.pollingEnabled = getBoolean(POLLING_ENABLED_CONFIG);
    this.pollingIntervalSeconds = getLong(POLLING_INTERVAL_CONFIG);
    this.retryCount = getInt(RETRY_COUNT_CONFIG);
    this.retryIntervalSeconds = getLong(RETRY_INTERVAL_SECONDS_CONFIG);
    this.timeoutSeconds = getLong(TIMEOUT_SECONDS_CONFIG);
  }

  public static ConfigDef config() {
    return new ConfigDef()
        .define(THREAD_COUNT_CONFIG, ConfigDef.Type.INT, 3, ConfigDef.Importance.LOW, THREAD_COUNT_DOC)
        .define(POLLING_ENABLED_CONFIG, ConfigDef.Type.BOOLEAN, true, ConfigDef.Importance.MEDIUM, POLLING_ENABLED_DOC)
        .define(POLLING_INTERVAL_CONFIG, ConfigDef.Type.LONG, 300L, ConfigDef.Importance.MEDIUM, POLLING_INTERVAL_DOC)
        .define(RETRY_COUNT_CONFIG, ConfigDef.Type.INT, 3, ConfigDef.Importance.LOW, RETRY_COUNT_DOC)
        .define(RETRY_INTERVAL_SECONDS_CONFIG, ConfigDef.Type.LONG, 10L, ConfigDef.Importance.LOW, RETRY_INTERVAL_SECONDS_DOC)
        .define(TIMEOUT_SECONDS_CONFIG, ConfigDef.Type.LONG, 30L, ConfigDef.Importance.LOW, TIMEOUT_SECONDS_DOC);
  }
}
