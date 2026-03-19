/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

import org.apache.kafka.common.config.ConfigData;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Arrays;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;

public class CyberArkConfigProviderIT {

  static CyberArkConfigProvider provider;

  @BeforeAll
  static void setUp() {
    String url = System.getenv().getOrDefault("CONJUR_URL", "http://localhost:8080");
    String account = System.getenv().getOrDefault("CONJUR_ACCOUNT", "testaccount");
    String username = System.getenv().getOrDefault("CONJUR_USERNAME", "admin");
    String apiKey = System.getenv("CONJUR_API_KEY");

    if (apiKey == null || apiKey.isEmpty()) {
      throw new IllegalStateException(
          "CONJUR_API_KEY environment variable must be set. "
              + "Run setup-test-data.sh first to get the API key."
      );
    }

    Map<String, String> settings = new HashMap<>();
    settings.put(CyberArkConfigProviderConfig.URL_CONFIG, url);
    settings.put(CyberArkConfigProviderConfig.ACCOUNT_CONFIG, account);
    settings.put(CyberArkConfigProviderConfig.USERNAME_CONFIG, username);
    settings.put(CyberArkConfigProviderConfig.API_KEY_CONFIG, apiKey);
    settings.put(CyberArkConfigProviderConfig.SSL_VERIFY_ENABLED_CONFIG, "false");

    provider = new CyberArkConfigProvider();
    provider.configure(settings);
  }

  @AfterAll
  static void tearDown() throws Exception {
    if (provider != null) {
      provider.close();
    }
  }

  @Test
  void testGetSecretUsername() {
    ConfigData data = provider.get("test-secrets/username");
    assertNotNull(data);
    assertNotNull(data.data());
    assertFalse(data.data().isEmpty());
    assertEquals("kafka-user-1", data.data().get("test-secrets/username"));
  }

  @Test
  void testGetSecretPassword() {
    ConfigData data = provider.get("test-secrets/password");
    assertNotNull(data);
    assertNotNull(data.data());
    assertEquals("s3cur3-p@ssw0rd", data.data().get("test-secrets/password"));
  }

  @Test
  void testGetSecretDbHost() {
    ConfigData data = provider.get("test-secrets/db-host");
    assertNotNull(data);
    assertNotNull(data.data());
    assertEquals("db01.example.com", data.data().get("test-secrets/db-host"));
  }

  @Test
  void testGetScramCredential() {
    ConfigData data = provider.get("test-secrets/SCRAM_kafka-user-1");
    assertNotNull(data);
    assertNotNull(data.data());
    String json = data.data().get("test-secrets/SCRAM_kafka-user-1");
    assertNotNull(json);
    // Verify it contains SCRAM structure
    assert json.contains("\"sha256\"");
    assert json.contains("\"salt\"");
    assert json.contains("\"storedKey\"");
    assert json.contains("\"serverKey\"");
    assert json.contains("\"iterations\"");
  }

  @Test
  void testGetSecretWithKeys() {
    Set<String> keys = new HashSet<>(Arrays.asList("test-secrets/username"));
    ConfigData data = provider.get("test-secrets/username", keys);
    assertNotNull(data);
    assertEquals(1, data.data().size());
    assertEquals("kafka-user-1", data.data().get("test-secrets/username"));
  }
}
