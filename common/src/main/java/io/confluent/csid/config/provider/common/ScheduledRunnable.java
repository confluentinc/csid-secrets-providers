/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common;

import org.immutables.value.Value;

import java.util.concurrent.ScheduledFuture;

@Value.Immutable
interface ScheduledRunnable {
  ScheduledFuture<?> future();

  Runnable runnable();
}
