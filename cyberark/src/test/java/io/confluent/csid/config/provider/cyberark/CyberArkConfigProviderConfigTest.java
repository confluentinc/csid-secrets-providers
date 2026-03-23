/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

import com.google.common.collect.ImmutableMap;
import org.apache.kafka.common.config.ConfigDef;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class CyberArkConfigProviderConfigTest {

  @Test
  public void testConfigParsing() {
    Map<String, Object> settings = ImmutableMap.of(
        CyberArkConfigProviderConfig.URL_CONFIG, "https://conjur.example.com",
        CyberArkConfigProviderConfig.ACCOUNT_CONFIG, "myaccount",
        CyberArkConfigProviderConfig.USERNAME_CONFIG, "admin",
        CyberArkConfigProviderConfig.API_KEY_CONFIG, "test-key"
    );
    CyberArkConfigProviderConfig config = new CyberArkConfigProviderConfig(settings);
    assertEquals("https://conjur.example.com", config.url);
    assertEquals("myaccount", config.account);
    assertEquals("admin", config.username);
    assertEquals("test-key", config.apiKey);
    assertTrue(config.sslVerifyEnabled);
  }

  @Test
  public void testSslVerifyDisabled() {
    Map<String, Object> settings = ImmutableMap.of(
        CyberArkConfigProviderConfig.URL_CONFIG, "https://conjur.example.com",
        CyberArkConfigProviderConfig.ACCOUNT_CONFIG, "myaccount",
        CyberArkConfigProviderConfig.USERNAME_CONFIG, "admin",
        CyberArkConfigProviderConfig.API_KEY_CONFIG, "test-key",
        CyberArkConfigProviderConfig.SSL_VERIFY_ENABLED_CONFIG, false
    );
    CyberArkConfigProviderConfig config = new CyberArkConfigProviderConfig(settings);
    assertFalse(config.sslVerifyEnabled);
  }

  @Test
  public void testDefaultValues() {
    CyberArkConfigProviderConfig config = new CyberArkConfigProviderConfig(ImmutableMap.of());
    assertEquals("", config.url);
    assertEquals("", config.account);
    assertEquals("", config.username);
    assertEquals("", config.apiKey);
    assertTrue(config.sslVerifyEnabled);
  }

  @Test
  public void testConfigDef() {
    ConfigDef configDef = CyberArkConfigProviderConfig.config();
    assertNotNull(configDef);
    assertTrue(configDef.names().contains(CyberArkConfigProviderConfig.URL_CONFIG));
    assertTrue(configDef.names().contains(CyberArkConfigProviderConfig.ACCOUNT_CONFIG));
    assertTrue(configDef.names().contains(CyberArkConfigProviderConfig.USERNAME_CONFIG));
    assertTrue(configDef.names().contains(CyberArkConfigProviderConfig.API_KEY_CONFIG));
    assertTrue(configDef.names().contains(CyberArkConfigProviderConfig.SSL_VERIFY_ENABLED_CONFIG));
  }
}
