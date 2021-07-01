/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.vault;

import java.util.concurrent.ScheduledExecutorService;

interface VaultClientFactory {
  VaultClient create(VaultConfigProviderConfig config, ScheduledExecutorService executorService);
}
