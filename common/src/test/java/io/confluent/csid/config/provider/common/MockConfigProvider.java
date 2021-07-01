package io.confluent.csid.config.provider.common;

import java.util.Map;

public abstract class MockConfigProvider extends AbstractConfigProvider<MockConfigProviderConfig> {
  @Override
  protected MockConfigProviderConfig config(Map<String, ?> settings) {
    return new MockConfigProviderConfig(settings);
  }
}
