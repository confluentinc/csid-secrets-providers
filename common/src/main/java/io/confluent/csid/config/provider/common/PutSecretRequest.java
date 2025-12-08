/**
 * Copyright Confluent 2025
 */
package io.confluent.csid.config.provider.common;

import org.immutables.value.Value;

@Value.Immutable
public interface PutSecretRequest extends SecretRequest {

  String key();

  String value();
}
