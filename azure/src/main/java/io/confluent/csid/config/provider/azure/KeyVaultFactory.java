/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.azure;

interface KeyVaultFactory {
  SecretClientWrapper create(KeyVaultConfigProviderConfig config);
}
