/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common;

import org.apache.kafka.common.config.ConfigDef;

import java.util.Map;

class MockConfigProviderConfig extends AbstractConfigProviderConfig {
  public MockConfigProviderConfig(Map<?, ?> originals) {
    super(config(), originals);
  }

  public static ConfigDef config() {
    return AbstractConfigProviderConfig.config();
  }
}
