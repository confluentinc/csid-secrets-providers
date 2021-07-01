/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.vault;

import com.bettercloud.vault.EnvironmentLoader;
import com.bettercloud.vault.VaultConfig;
import org.apache.kafka.common.config.ConfigException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class VaultConfigProviderConfigTests {
  private static final Logger log = LoggerFactory.getLogger(VaultConfigProviderConfigTests.class);

  Map<String, String> settings;

  @BeforeEach
  public void before() {
    this.settings = new LinkedHashMap<>();
  }


  @Test
  public void addressNotSet() {
    EnvironmentLoader environmentLoader = MockEnvironment.of();
    VaultConfigProviderConfig config = new VaultConfigProviderConfig(settings);
    assertThrows(ConfigException.class, () -> {
      VaultConfig vaultConfig = config.createConfig(environmentLoader);
    });
  }

  @Test
  public void addressSet() {
    settings.put(VaultConfigProviderConfig.ADDRESS_CONFIG, "https://vault.example.com");
    VaultConfigProviderConfig config = new VaultConfigProviderConfig(settings);
    VaultConfig vaultConfig = config.createConfig();
    assertNotNull(vaultConfig);
    assertEquals("https://vault.example.com", vaultConfig.getAddress());
  }

  @Test
  public void addressEnvironmentVariable() {
    VaultConfigProviderConfig config = new VaultConfigProviderConfig(settings);
    EnvironmentLoader environmentLoader = MockEnvironment.of("VAULT_ADDR", "https://vault.example.com");
    VaultConfig vaultConfig = config.createConfig(environmentLoader);
    assertNotNull(vaultConfig);
    assertEquals("https://vault.example.com", vaultConfig.getAddress());
  }

  @Test
  public void tokenSet() {
    settings.put(VaultConfigProviderConfig.ADDRESS_CONFIG, "https://vault.example.com");
    settings.put(VaultConfigProviderConfig.TOKEN_CONFIG, Constants.TOKEN);
    VaultConfigProviderConfig config = new VaultConfigProviderConfig(settings);
    VaultConfig vaultConfig = config.createConfig();
    assertNotNull(vaultConfig);
    assertEquals(Constants.TOKEN, vaultConfig.getToken());
  }

  @Test
  public void tokenNotSet() {
    settings.put(VaultConfigProviderConfig.ADDRESS_CONFIG, "https://vault.example.com");
    VaultConfigProviderConfig config = new VaultConfigProviderConfig(settings);
    EnvironmentLoader environmentLoader = MockEnvironment.of();
    VaultConfig vaultConfig = config.createConfig(environmentLoader);
    assertNotNull(vaultConfig);
  }

  @Test
  public void tokenEnvironmentVariable() {
    settings.put(VaultConfigProviderConfig.ADDRESS_CONFIG, "https://vault.example.com");
    VaultConfigProviderConfig config = new VaultConfigProviderConfig(settings);
    EnvironmentLoader environmentLoader = MockEnvironment.of("VAULT_TOKEN", Constants.TOKEN);
    VaultConfig vaultConfig = config.createConfig(environmentLoader);
    assertNotNull(vaultConfig);
    assertEquals(Constants.TOKEN, vaultConfig.getToken());
  }

  @ParameterizedTest
  @ValueSource(
      strings = {
          VaultConfigProviderConfig.USERNAME_CONFIG,
          VaultConfigProviderConfig.PASSWORD_CONFIG,
      }
  )
  public void authMethodLdapRequires(String config) {
    this.settings.put(VaultConfigProviderConfig.USERNAME_CONFIG, "user01");
    this.settings.put(VaultConfigProviderConfig.PASSWORD_CONFIG, "password");
    this.settings.put(VaultConfigProviderConfig.AUTH_METHOD_CONFIG, AuthMethod.LDAP.name());
    this.settings.remove(config);

    ConfigException exception = assertThrows(ConfigException.class, () -> {
      new VaultConfigProviderConfig(this.settings);
    });
    assertTrue(
        exception.getMessage().contains(config),
        String.format("Exception message should contain '%s'", config)
    );
  }
  @ParameterizedTest
  @ValueSource(
      strings = {
          VaultConfigProviderConfig.USERNAME_CONFIG,
          VaultConfigProviderConfig.PASSWORD_CONFIG,
      }
  )
  public void authMethodUserPassRequires(String config) {
    this.settings.put(VaultConfigProviderConfig.USERNAME_CONFIG, "user01");
    this.settings.put(VaultConfigProviderConfig.PASSWORD_CONFIG, "password");
    this.settings.put(VaultConfigProviderConfig.AUTH_METHOD_CONFIG, AuthMethod.UserPass.name());
    this.settings.remove(config);

    ConfigException exception = assertThrows(ConfigException.class, () -> {
      new VaultConfigProviderConfig(this.settings);
    });
    assertTrue(
        exception.getMessage().contains(config),
        String.format("Exception message should contain '%s'", config)
    );
  }
  @ParameterizedTest
  @ValueSource(
      strings = {
          VaultConfigProviderConfig.ROLE_CONFIG,
          VaultConfigProviderConfig.SECRET_CONFIG,
      }
  )
  public void authMethodAppRoleRequires(String config) {
    this.settings.put(VaultConfigProviderConfig.ROLE_CONFIG, "user01");
    this.settings.put(VaultConfigProviderConfig.SECRET_CONFIG, "password");
    this.settings.put(VaultConfigProviderConfig.AUTH_METHOD_CONFIG, AuthMethod.AppRole.name());
    this.settings.remove(config);

    ConfigException exception = assertThrows(ConfigException.class, () -> {
      new VaultConfigProviderConfig(this.settings);
    });
    assertTrue(
        exception.getMessage().contains(config),
        String.format("Exception message should contain '%s'", config)
    );
  }


  static class MockEnvironment extends EnvironmentLoader {
    private final Map<String, String> values;


    MockEnvironment(Map<String, String> values) {
      this.values = values;
    }

    @Override
    public String loadVariable(String name) {
      return this.values.get(name);
    }

    public static MockEnvironment of() {
      Map<String, String> result = new LinkedHashMap<>();
      return new MockEnvironment(result);
    }

    public static MockEnvironment of(String key, String value) {
      Map<String, String> result = new LinkedHashMap<>();
      result.put(key, value);
      return new MockEnvironment(result);
    }

    public static MockEnvironment of(String key0, String value0, String key1, String value1) {
      Map<String, String> result = new LinkedHashMap<>();
      result.put(key0, value0);
      result.put(key1, value1);
      return new MockEnvironment(result);
    }
  }
}
