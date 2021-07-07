/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.azure;

import com.azure.core.credential.TokenCredential;
import com.azure.identity.ClientCertificateCredential;
import com.azure.identity.ClientSecretCredential;
import com.azure.identity.DefaultAzureCredential;
import com.azure.identity.UsernamePasswordCredential;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class KeyVaultConfigProviderConfigTest {

  final String TENANT_ID = "27e831e4-5cff-4143-b612-64de151b2f3e";

  KeyVaultConfigProviderConfig create(String... args) {
    assertTrue(args.length % 2 == 0, "args should be pairs of 2");
    Map<String, String> settings = new LinkedHashMap<>();
    settings.put(KeyVaultConfigProviderConfig.VAULT_URL_CONFIG, "https://example.vault.azure.net");
    for (int i = 0; i < args.length; i += 2) {
      String key = args[i];
      String value = args[i + 1];
      settings.put(key, value);
    }

    return new KeyVaultConfigProviderConfig(settings);
  }

  @Test
  public void buildCredentialDefaultAzure() throws IOException {
    KeyVaultConfigProviderConfig config = create();
    TokenCredential credential = config.buildCredential();
    assertNotNull(credential, "credential should not be null");
    assertTrue(credential instanceof DefaultAzureCredential, "credential should not be null");
  }

  @Test
  public void buildCredentialClientSecret() throws IOException {
    KeyVaultConfigProviderConfig config = create(
        KeyVaultConfigProviderConfig.CREDENTIAL_TYPE_CONFIG, KeyVaultConfigProviderConfig.CredentialLocation.ClientSecret.name(),
        KeyVaultConfigProviderConfig.TENANT_ID_CONFIG, TENANT_ID,
        KeyVaultConfigProviderConfig.CLIENT_SECRET_CONFIG, "asdfasdfas"
    );
    TokenCredential credential = config.buildCredential();
    assertNotNull(credential, "credential should not be null");
    assertTrue(credential instanceof ClientSecretCredential, "credential should not be null");
  }

  @Test
  public void buildCredentialClientCertificatePEM() throws IOException {
    KeyVaultConfigProviderConfig config = create(
        KeyVaultConfigProviderConfig.CREDENTIAL_TYPE_CONFIG, KeyVaultConfigProviderConfig.CredentialLocation.ClientCertificate.name(),
        KeyVaultConfigProviderConfig.CERTIFICATE_TYPE_CONFIG, KeyVaultConfigProviderConfig.ClientCertificateType.PEM.name(),
        KeyVaultConfigProviderConfig.TENANT_ID_CONFIG, TENANT_ID,
        KeyVaultConfigProviderConfig.CERTIFICATE_PATH_CONFIG, "/tmp/path"
    );
    TokenCredential credential = config.buildCredential();
    assertNotNull(credential, "credential should not be null");
    assertTrue(credential instanceof ClientCertificateCredential, "credential should not be null");
  }

  @Test
  public void buildCredentialClientCertificatePFX() throws IOException {
    KeyVaultConfigProviderConfig config = create(
        KeyVaultConfigProviderConfig.CREDENTIAL_TYPE_CONFIG, KeyVaultConfigProviderConfig.CredentialLocation.ClientCertificate.name(),
        KeyVaultConfigProviderConfig.CERTIFICATE_TYPE_CONFIG, KeyVaultConfigProviderConfig.ClientCertificateType.PFX.name(),
        KeyVaultConfigProviderConfig.TENANT_ID_CONFIG, TENANT_ID,
        KeyVaultConfigProviderConfig.CERTIFICATE_PATH_CONFIG, "/tmp/path"
    );
    TokenCredential credential = config.buildCredential();
    assertNotNull(credential, "credential should not be null");
    assertTrue(credential instanceof ClientCertificateCredential, "credential should not be null");
  }

  @Test
  public void buildCredentialUsernamePassword() throws IOException {
    KeyVaultConfigProviderConfig config = create(
        KeyVaultConfigProviderConfig.CREDENTIAL_TYPE_CONFIG, KeyVaultConfigProviderConfig.CredentialLocation.UsernamePassword.name(),
        KeyVaultConfigProviderConfig.TENANT_ID_CONFIG, TENANT_ID,
        KeyVaultConfigProviderConfig.USERNAME_CONF, "foo",
        KeyVaultConfigProviderConfig.PASSWORD_CONF, "bar"
    );
    TokenCredential credential = config.buildCredential();
    assertNotNull(credential, "credential should not be null");
    assertTrue(credential instanceof UsernamePasswordCredential, "credential should not be null");


  }

}
