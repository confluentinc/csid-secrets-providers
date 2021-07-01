/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common;

import java.util.concurrent.ScheduledExecutorService;

/**
 * Interface is mainly used to inject mocks for testing.
 */
interface ScheduledExecutorServiceFactory {
  /**
   * Method is used to create a ScheduledExecutorService.
   * @param config configuration
   * @return ScheduledExecutorService
   */
  ScheduledExecutorService create(AbstractConfigProviderConfig config);
}
