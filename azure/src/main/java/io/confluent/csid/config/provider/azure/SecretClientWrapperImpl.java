package io.confluent.csid.config.provider.azure;

import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.models.KeyVaultSecret;

public class SecretClientWrapperImpl implements SecretClientWrapper {
  SecretClient secretClient;
  SecretClientWrapperImpl(SecretClient secretClient) {
    this.secretClient = secretClient;
  }
  @Override
  public KeyVaultSecret getSecret(String name, String version) {
    return secretClient.getSecret(name, version);
  }

  @Override
  public void createSecret(String name, String value) {
    secretClient.setSecret(name, value);
  }

  @Override
  public void deleteSecret(String name) {
    secretClient.beginDeleteSecret(name);
  }

}
