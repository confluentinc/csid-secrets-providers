/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.azure;

import com.azure.core.exception.ResourceNotFoundException;
import com.azure.security.keyvault.secrets.models.KeyVaultSecret;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableSet;
import org.apache.kafka.common.config.ConfigData;
import org.apache.kafka.common.config.ConfigException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

public class KeyVaultConfigProviderTest {
  KeyVaultConfigProvider provider;
  Map<String, String> settings;
  SecretClientWrapper secretClientWrapper;
  ObjectMapper mapper;

  @BeforeEach
  public void beforeEach() {
    this.secretClientWrapper = mock(SecretClientWrapper.class);
    this.provider = new KeyVaultConfigProvider();
    this.provider.keyVaultFactory = mock(KeyVaultFactory.class);
    when(this.provider.keyVaultFactory.create(any())).thenReturn(this.secretClientWrapper);
    this.settings = new LinkedHashMap<>();
    this.settings.put(KeyVaultConfigProviderConfig.VAULT_URL_CONFIG, "https://example.vault.azure.net/");
    this.provider.configure(this.settings);

    this.mapper = new ObjectMapper();
    this.mapper.configure(SerializationFeature.INDENT_OUTPUT, true);
  }

  @AfterEach
  public void afterEach() throws IOException {
    this.provider.close();
  }

  @Test
  public void getNotFound() {
    Throwable expected = new ResourceNotFoundException("Resource 'not/found' was not found.", null);
    when(this.secretClientWrapper.getSecret(any(), any())).thenThrow(expected);
    ConfigException configException = assertThrows(ConfigException.class, () -> {
      this.provider.get("not/found");
    });
    assertEquals(expected, configException.getCause());
  }

  void getSecret(Map<String, String> payload, String expectedName, String expectedVersion) throws IOException {
    String data = this.mapper.writeValueAsString(payload);
    when(this.secretClientWrapper.getSecret(any(), any())).thenAnswer(invocationOnMock -> {
      String actualName = invocationOnMock.getArgument(0);
      String version = invocationOnMock.getArgument(1);
      assertEquals(expectedName, actualName);
      assertEquals(expectedVersion, version);
      return new KeyVaultSecret(expectedName, data);
    });
  }

  @Test
  public void get() throws IOException {
    final String expectedRequestName = "test-secret";
    final String secretName = "test-secret";
    final Map<String, String> expectedData = ImmutableMap.of(
        "username", "asdf",
        "password", "asdf"
    );

    getSecret(expectedData, expectedRequestName, null);

    ConfigData configData = this.provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expectedData, configData.data());
  }

  @Test
  public void getVersioned() throws IOException {
    final String expectedRequestName = "test-secret";
    final String secretName = "test-secret?version=1234";
    final Map<String, String> expectedData = ImmutableMap.of(
        "username", "asdf",
        "password", "asdf"
    );

    getSecret(expectedData, expectedRequestName, "1234");

    ConfigData configData = this.provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expectedData, configData.data());
  }


//  @Test
//  public void getPrefixed() throws IOException {
//    this.settings.put(KeyVaultConfigProviderConfig.PREFIX_CONFIG, "staging-");
//    this.provider.configure(this.settings);
//    final String expectedRequestName = "staging-test-secret";
//    final String secretName = "test-secret";
//    final String responseSecretName = "staging-test-secret";
//
//    Map<String, String> expected = ImmutableMap.of(
//        "username", "asdf",
//        "password", "asdf"
//    );
//    getSecret(expected, expectedRequestName, null);
//
//    ConfigData configData = this.provider.get(secretName, ImmutableSet.of());
//    assertNotNull(configData);
//    assertEquals(expected, configData.data());
//  }

//  @Test
//  public void getTTLOverride() throws IOException {
//    this.provider.configure(this.settings);
//    final Long expectedTTL = 60000L;
//    final String expectedRequestName = "test-secret";
//    final String secretName = "test-secret?ttl=" + expectedTTL;
//
//    Map<String, String> expected = ImmutableMap.of(
//        "username", "asdf",
//        "password", "asdf"
//    );
//    getSecret(expected, expectedRequestName, null);
//
//    ConfigData configData = this.provider.get(secretName, ImmutableSet.of());
//    assertNotNull(configData);
//    assertEquals(expected, configData.data());
//    assertEquals(expectedTTL, configData.ttl());
//  }
}
