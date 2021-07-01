/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common;

import org.immutables.value.Value;

import java.util.Optional;

@Value.Immutable
public interface SecretRequest {
  /**
   * The raw incoming path. This has not been altered.
   *
   * @return
   */
  String raw();

  /**
   * The file name part of the incoming request.
   *
   * @return
   */
  String path();

  /**
   * The parsed version of the incoming request
   *
   * @return version to retrieve. If null latest is assumed.
   */
  @Value.Default
  default Optional<String> version() {
    return Optional.empty();
  }
}
