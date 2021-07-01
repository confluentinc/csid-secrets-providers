/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.azure;

import com.azure.security.keyvault.secrets.models.KeyVaultSecret;

interface SecretClientWrapper {
  KeyVaultSecret getSecret(String name, String version);
}
