/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

import io.confluent.csid.config.provider.common.AbstractConfigProviderConfig;
import io.confluent.csid.config.provider.common.config.ConfigKeyBuilder;
import org.apache.kafka.common.config.ConfigDef;

import java.util.Map;

public class CyberArkConfigProviderConfig extends AbstractConfigProviderConfig {

  public static final String URL_CONFIG = "cyberark.url";
  static final String URL_DOC = "The URL of the CyberArk Conjur server. "
      + "For example `https://conjur.example.com`.";

  public static final String ACCOUNT_CONFIG = "cyberark.account";
  static final String ACCOUNT_DOC = "The CyberArk Conjur account name.";

  public static final String USERNAME_CONFIG = "cyberark.auth.username";
  static final String USERNAME_DOC = "The username (login) to authenticate with CyberArk Conjur.";

  public static final String API_KEY_CONFIG = "cyberark.auth.apikey";
  static final String API_KEY_DOC = "The API key used to authenticate with CyberArk Conjur.";

  public static final String SSL_VERIFY_ENABLED_CONFIG = "cyberark.ssl.verify.enabled";
  static final String SSL_VERIFY_ENABLED_DOC = "Flag to determine if the provider should verify "
      + "the SSL certificate of the CyberArk Conjur server. "
      + "Outside of development this should never be disabled.";

  public final String url;
  public final String account;
  public final String username;
  public final String apiKey;
  public final boolean sslVerifyEnabled;

  public CyberArkConfigProviderConfig(Map<String, ?> originals) {
    super(config(), originals);
    this.url = getString(URL_CONFIG);
    this.account = getString(ACCOUNT_CONFIG);
    this.username = getString(USERNAME_CONFIG);
    this.apiKey = getPassword(API_KEY_CONFIG).value();
    this.sslVerifyEnabled = getBoolean(SSL_VERIFY_ENABLED_CONFIG);
  }

  public static ConfigDef config() {
    return AbstractConfigProviderConfig.config()
        .define(
            ConfigKeyBuilder.of(URL_CONFIG, ConfigDef.Type.STRING)
                .documentation(URL_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(ACCOUNT_CONFIG, ConfigDef.Type.STRING)
                .documentation(ACCOUNT_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(USERNAME_CONFIG, ConfigDef.Type.STRING)
                .documentation(USERNAME_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(API_KEY_CONFIG, ConfigDef.Type.PASSWORD)
                .documentation(API_KEY_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(SSL_VERIFY_ENABLED_CONFIG, ConfigDef.Type.BOOLEAN)
                .documentation(SSL_VERIFY_ENABLED_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue(true)
                .build()
        );
  }
}
