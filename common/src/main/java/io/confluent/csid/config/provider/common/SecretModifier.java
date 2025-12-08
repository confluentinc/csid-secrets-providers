/**
 * Copyright Confluent 2025
 */
package io.confluent.csid.config.provider.common;

public interface SecretModifier {

  void createSecret(PutSecretRequest putSecretRequest) throws Exception;

  void updateSecret(PutSecretRequest putSecretRequest) throws Exception;

  void deleteSecret(SecretRequest secretRequest) throws Exception;
}
