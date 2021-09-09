/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common;

import org.apache.kafka.common.config.ConfigChangeCallback;
import org.immutables.value.Value;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.ScheduledFuture;

@Value.Immutable
interface Subscription {

  @Value.Immutable
  interface Key {
    Set<String> keys();
  }

  @Value.Immutable
  interface State {
    Set<ConfigChangeCallback> callbacks();
  }

  ScheduledFuture<?> future();

  String path();

  Map<Key, State> states();
}
