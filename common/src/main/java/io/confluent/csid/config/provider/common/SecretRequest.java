/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common;

import org.immutables.value.Value;

import java.util.Optional;

@Value.Immutable
public interface SecretRequest {
  String raw();
  String path();

  Optional<String> version();
}
