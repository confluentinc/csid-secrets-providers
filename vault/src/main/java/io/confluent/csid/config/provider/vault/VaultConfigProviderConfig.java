/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.vault;


import com.bettercloud.vault.EnvironmentLoader;
import com.bettercloud.vault.SslConfig;
import com.bettercloud.vault.VaultConfig;
import com.bettercloud.vault.VaultException;
import io.confluent.csid.config.provider.common.AbstractConfigProviderConfig;
import io.confluent.csid.config.provider.common.config.ConfigKeyBuilder;
import io.confluent.csid.config.provider.common.config.ConfigUtils;
import io.confluent.csid.config.provider.common.config.Validators;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.ConfigException;
import org.apache.kafka.common.config.types.Password;

import java.util.Map;
import java.util.Objects;

import static io.confluent.csid.config.provider.common.config.ConfigUtils.getEnum;
import static io.confluent.csid.config.provider.common.util.Utils.isNullOrEmpty;

class VaultConfigProviderConfig extends AbstractConfigProviderConfig {
  public static final String ADDRESS_CONFIG = "vault.address";
  static final String ADDRESS_DOC = "Sets the address (URL) of the Vault server instance to which API calls should be sent. " +
      "If no address is explicitly set, the object will look to the `VAULT_ADDR` If you do not supply it explicitly AND no " +
      "environment variable value is found, then initialization may fail.";

  public static final String NAMESPACE_CONFIG = "vault.namespace";
  static final String NAMESPACE_DOC = "Sets a global namespace to the Vault server instance, if desired.";
  public static final String TOKEN_CONFIG = "vault.auth.token";
  static final String TOKEN_DOC = "Sets the token used to access Vault. If no token is explicitly set " +
      "then the `VAULT_TOKEN` environment variable will be used. ";

  public static final String AUTH_METHOD_CONFIG = "vault.auth.method";
  static final String AUTH_METHOD_DOC = "The login method to use. " + ConfigUtils.enumDescription(AuthMethod.class);

  public static final String SSL_VERIFY_ENABLED_CONFIG = "vault.ssl.verify.enabled";
  static final String SSL_VERIFY_ENABLED_DOC = "Flag to determine if the configProvider should verify the SSL Certificate " +
      "of the Vault server. Outside of development this should never be enabled.";

  public static final String USERNAME_CONFIG = "vault.auth.username";
  static final String USERNAME_DOC = "The username to authenticate with.";
  public static final String PASSWORD_CONFIG = "vault.auth.password";
  static final String PASSWORD_DOC = "The password to authenticate with.";

  public static final String MOUNT_CONFIG = "vault.auth.mount";
  static final String MOUNT_DOC = "Location of the mount to use for authentication.";

  public static final String ROLE_CONFIG = "vault.auth.role";
  static final String ROLE_DOC = "The role to use for authentication.";
  public static final String SECRET_CONFIG = "vault.auth.secret";
  static final String SECRET_DOC = "The secret to use for authentication.";

  public final boolean sslVerifyEnabled;
  public final AuthMethod authMethod;

  public final String username;
  public final String password;
  public final String mount;

  public final String role;
  public final String secret;

  void checkNotDefault(String item) {
    ConfigDef config = config();
    Object currentValue = get(item);
    ConfigDef.ConfigKey configKey = config.configKeys().get(item);
    if (Objects.equals(configKey.defaultValue, currentValue)) {
      throw new ConfigException(
          item,
          currentValue,
          "Value must be specified"
      );
    }
  }

  public VaultConfigProviderConfig(Map<?, ?> originals) {
    super(config(), originals);
    this.sslVerifyEnabled = getBoolean(SSL_VERIFY_ENABLED_CONFIG);
    this.authMethod = getEnum(AuthMethod.class, this, AUTH_METHOD_CONFIG);
    this.username = getString(USERNAME_CONFIG);
    this.password = getPassword(PASSWORD_CONFIG).value();
    this.mount = getString(MOUNT_CONFIG);
    this.role = getString(ROLE_CONFIG);
    this.secret = getPassword(SECRET_CONFIG).value();

    switch (this.authMethod) {
      case LDAP:
      case UserPass:
        checkNotDefault(USERNAME_CONFIG);
        checkNotDefault(PASSWORD_CONFIG);
        break;
      case AppRole:
        checkNotDefault(ROLE_CONFIG);
        checkNotDefault(SECRET_CONFIG);
        break;
      default:
    }

  }

  public static ConfigDef config() {
    return AbstractConfigProviderConfig.config()
        .define(
            ConfigKeyBuilder.of(ADDRESS_CONFIG, ConfigDef.Type.STRING)
                .documentation(ADDRESS_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        )
        .define(
            ConfigKeyBuilder.of(AUTH_METHOD_CONFIG, ConfigDef.Type.STRING)
                .documentation(AUTH_METHOD_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue(AuthMethod.Token.name())
                .validator(Validators.validEnum(AuthMethod.class))
                .build()
        )

        .define(
            ConfigKeyBuilder.of(TOKEN_CONFIG, ConfigDef.Type.PASSWORD)
                .documentation(TOKEN_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        )
        .define(
            ConfigKeyBuilder.of(NAMESPACE_CONFIG, ConfigDef.Type.STRING)
                .documentation(NAMESPACE_DOC)
                .importance(ConfigDef.Importance.LOW)
                .defaultValue("")
                .build()
        )
        .define(
            ConfigKeyBuilder.of(SSL_VERIFY_ENABLED_CONFIG, ConfigDef.Type.BOOLEAN)
                .documentation(SSL_VERIFY_ENABLED_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue(true)
                .build()
        ).define(
            ConfigKeyBuilder.of(USERNAME_CONFIG, ConfigDef.Type.STRING)
                .documentation(USERNAME_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(PASSWORD_CONFIG, ConfigDef.Type.PASSWORD)
                .documentation(PASSWORD_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(MOUNT_CONFIG, ConfigDef.Type.STRING)
                .documentation(MOUNT_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(ROLE_CONFIG, ConfigDef.Type.STRING)
                .documentation(ROLE_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(SECRET_CONFIG, ConfigDef.Type.PASSWORD)
                .documentation(SECRET_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        );
  }

  public VaultConfig createConfig() {
    return createConfig(null);
  }

  /**
   * Method is used to create a VaultConfig.
   *
   * @param environmentLoader Used for configuration testing. Null most of the time
   * @return
   */
  VaultConfig createConfig(EnvironmentLoader environmentLoader) {
    SslConfig sslConfig = new SslConfig()
        .verify(this.sslVerifyEnabled);

    VaultConfig result = new VaultConfig();
    if (null != environmentLoader) {
      result = result.environmentLoader(environmentLoader);
    }

    try {
      result = result.sslConfig(sslConfig.build());
    } catch (VaultException e) {
      ConfigException configException = new ConfigException("Exception thrown while configuring ssl");
      configException.initCause(e);
      throw configException;
    }

    String address = getString(ADDRESS_CONFIG);
    if (!isNullOrEmpty(address)) {
      result = result.address(address);
    }
    Password token = getPassword(TOKEN_CONFIG);
    if (!isNullOrEmpty(token.value())) {
      result = result.token(token.value());
    }
    String namespace = getString(NAMESPACE_CONFIG);
    if (!isNullOrEmpty(namespace)) {
      try {
        result = result.nameSpace(namespace);
      } catch (VaultException e) {
        ConfigException configException = new ConfigException(NAMESPACE_CONFIG, namespace, "Exception thrown setting namespace");
        configException.initCause(e);
        throw configException;
      }
    }

    try {
      result = result.build();
    } catch (VaultException e) {
      ConfigException configException = new ConfigException("Exception thrown while configuring vault");
      configException.initCause(e);
      throw configException;
    }

    return result;
  }
}
