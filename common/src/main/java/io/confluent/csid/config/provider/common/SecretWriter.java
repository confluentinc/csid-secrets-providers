/**
 * Copyright Confluent 2025
 */
package io.confluent.csid.config.provider.common;

public interface SecretWriter {

  void create(PutSecretRequest updatedSecret) throws Exception;

  void update(PutSecretRequest updatedSecret) throws Exception;

  void delete(SecretRequest secret) throws Exception;
}
