/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableSet;
import io.confluent.csid.config.provider.common.SecretRequest;
import org.apache.kafka.common.config.ConfigData;
import org.apache.kafka.common.config.ConfigException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.Collections;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

public class CyberArkConfigProviderTest {

  CyberArkClient client;
  CyberArkConfigProvider provider;

  @BeforeEach
  public void beforeEach() {
    this.client = mock(CyberArkClient.class);
    this.provider = new CyberArkConfigProvider();
    this.provider.clientFactory = mock(CyberArkClientFactory.class);
    when(this.provider.clientFactory.create(any())).thenAnswer(invocation -> {
      CyberArkConfigProviderConfig config = invocation.getArgument(0);
      assertNotNull(config, "config cannot be null.");
      return this.client;
    });
    this.provider.configure(ImmutableMap.of(
        CyberArkConfigProviderConfig.URL_CONFIG, "http://localhost:8080",
        CyberArkConfigProviderConfig.ACCOUNT_CONFIG, "testaccount",
        CyberArkConfigProviderConfig.USERNAME_CONFIG, "admin",
        CyberArkConfigProviderConfig.API_KEY_CONFIG, "test-api-key"
    ));
  }

  @AfterEach
  public void afterEach() throws IOException {
    this.provider.close();
  }

  @Test
  public void getSecret() throws Exception {
    final String secretPath = "test-secrets/username";
    Map<String, String> expected = ImmutableMap.of(secretPath, "kafka-user-1");
    when(client.getSecret(any(SecretRequest.class))).thenAnswer(invocation -> {
      SecretRequest request = invocation.getArgument(0);
      assertEquals(secretPath, request.path());
      return expected;
    });
    ConfigData configData = this.provider.get(secretPath, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expected, configData.data());
  }

  @Test
  public void getSecretNotFound() throws Exception {
    when(client.getSecret(any(SecretRequest.class)))
        .thenThrow(new Exception("Variable not found"));
    assertThrows(ConfigException.class, () -> this.provider.get("test-secrets/nonexistent"));
  }

  @Test
  public void getScramCredential() throws Exception {
    final String secretPath = "test-secrets/SCRAM_kafka-user-1";
    String scramJson = "{\"sha256\":{\"salt\":\"cEBzc3cwcmQ=\",\"storedKey\":\"abc=\",\"serverKey\":\"def=\",\"iterations\":4096}}";
    Map<String, String> expected = ImmutableMap.of(secretPath, scramJson);
    when(client.getSecret(any(SecretRequest.class))).thenReturn(expected);
    ConfigData configData = this.provider.get(secretPath, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(scramJson, configData.data().get(secretPath));
  }
}
