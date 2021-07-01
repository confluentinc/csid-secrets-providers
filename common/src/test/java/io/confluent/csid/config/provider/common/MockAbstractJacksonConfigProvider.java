/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common;

import java.util.Map;

public abstract class MockAbstractJacksonConfigProvider extends AbstractJacksonConfigProvider<MockConfigProviderConfig> {
  @Override
  protected MockConfigProviderConfig config(Map<String, ?> settings) {
    return new MockConfigProviderConfig(settings);
  }
}
