/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.vault;

import java.util.concurrent.ScheduledExecutorService;

class VaultClientFactoryImpl implements VaultClientFactory {
  @Override
  public VaultClient create(VaultConfigProviderConfig config, ScheduledExecutorService executorService) {
    return new VaultClientImpl(config, executorService);
  }
}
