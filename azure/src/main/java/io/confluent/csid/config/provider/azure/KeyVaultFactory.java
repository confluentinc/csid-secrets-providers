/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.azure;

interface KeyVaultFactory {
  SecretClientWrapper create(KeyVaultConfigProviderConfig config);
}
