/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.azure;

import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;
import org.apache.kafka.common.config.ConfigException;

class KeyVaultFactoryImpl implements KeyVaultFactory {
  @Override
  public SecretClientWrapper create(KeyVaultConfigProviderConfig config) {
    try {
      SecretClientBuilder builder = new SecretClientBuilder()
          .vaultUrl(config.vaultUrl)
          .httpClient(config.httpClient)
          .credential(config.buildCredential());
      final SecretClient secretClient = builder.buildClient();
      return secretClient::getSecret;
    } catch (Exception ex) {
      ConfigException exception = new ConfigException("Exception during configuration");
      exception.initCause(exception);
      throw exception;
    }
  }
}
