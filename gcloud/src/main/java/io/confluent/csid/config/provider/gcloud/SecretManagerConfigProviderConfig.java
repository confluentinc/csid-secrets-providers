/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.gcloud;

import com.google.api.gax.core.CredentialsProvider;
import com.google.auth.oauth2.GoogleCredentials;
import io.confluent.csid.config.provider.common.AbstractConfigProviderConfig;
import io.confluent.csid.config.provider.common.config.ConfigKeyBuilder;
import io.confluent.csid.config.provider.common.config.ConfigUtils;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.ConfigException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Map;

class SecretManagerConfigProviderConfig extends AbstractConfigProviderConfig {
  private static final Logger log = LoggerFactory.getLogger(SecretManagerConfigProviderConfig.class);
  public static final String PREFIX_CONFIG = "secret.prefix";
  static final String PREFIX_DOC = "Sets a prefix that will be added to all paths. For example you can use `staging` or `production` " +
      "and all of the calls to Secrets Manager will be prefixed with that path. This allows the same configuration settings to be used across " +
      "multiple environments.";

  public static final String MIN_TTL_MS_CONFIG = "secret.ttl.ms";
  static final String MIN_TTL_MS_DOC = "The minimum amount of time that a secret should be used. " +
      "After this TTL has expired Secrets Manager will be queried again in case there is an updated configuration.";

  public static final String CREDENTIAL_LOCATION_CONFIG = "credential.location";
  public static final String CREDENTIAL_LOCATION_DOC = "asdfasdfasdfasd";

  public static final String CREDENTIAL_FILE_CONFIG = "credential.file";
  public static final String CREDENTIAL_FILE_DOC = "credential.file";

  public static final String CREDENTIAL_INLINE_CONFIG = "credential.inline";
  public static final String CREDENTIAL_INLINE_DOC = "credential.inline";
  public static final String PROJECT_ID_CONFIG = "project.id";
  public static final String PROJECT_ID_DOC = "project.id";

  public final long minimumSecretTTL;
  public final String prefix;
  public final CredentialLocation credentialLocation;
  public final Long projectId;

  public SecretManagerConfigProviderConfig(Map<String, ?> settings) {
    super(config(), settings);
    this.minimumSecretTTL = getLong(MIN_TTL_MS_CONFIG);
    this.prefix = getString(PREFIX_CONFIG);
    this.credentialLocation = ConfigUtils.getEnum(CredentialLocation.class, this, CREDENTIAL_LOCATION_CONFIG);
    this.projectId = getLong(PROJECT_ID_DOC);
  }

  public static ConfigDef config() {
    return AbstractConfigProviderConfig.config()
        .define(
            ConfigKeyBuilder.of(PREFIX_CONFIG, ConfigDef.Type.STRING)
                .documentation(PREFIX_DOC)
                .importance(ConfigDef.Importance.LOW)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(MIN_TTL_MS_CONFIG, ConfigDef.Type.LONG)
                .documentation(MIN_TTL_MS_DOC)
                .importance(ConfigDef.Importance.LOW)
                .defaultValue(Duration.ofMinutes(5L).toMillis())
                .validator(ConfigDef.Range.atLeast(1000L))
                .build()
        ).define(
            ConfigKeyBuilder.of(CREDENTIAL_LOCATION_CONFIG, ConfigDef.Type.STRING)
                .documentation(CREDENTIAL_LOCATION_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue(CredentialLocation.ApplicationDefault.name())
//                .validator(Validators.validEnum(CredentialLocation.class))
                .build()
        ).define(
            ConfigKeyBuilder.of(CREDENTIAL_FILE_CONFIG, ConfigDef.Type.STRING)
                .documentation(CREDENTIAL_FILE_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(CREDENTIAL_INLINE_CONFIG, ConfigDef.Type.STRING)
                .documentation(CREDENTIAL_INLINE_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(PROJECT_ID_CONFIG, ConfigDef.Type.LONG)
                .documentation(PROJECT_ID_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .build()
        );
  }

  public enum CredentialLocation {
    ApplicationDefault,
    File,
    Inline
  }

  String getRequiredString(String name) {
    String result = getString(name);

    if (result == null || result.isEmpty()) {
      throw new ConfigException(name, result, "Cannot be null or blank.");
    }

    return result;
  }

  public CredentialsProvider credentialsProvider() {
    return () -> {
      GoogleCredentials result;

      switch (credentialLocation) {
        case File:
          String credentialsFile = getRequiredString(CREDENTIAL_LOCATION_CONFIG);
          log.info("Loading credentials file '{}'", credentialsFile);
          try (InputStream inputStream = new FileInputStream(credentialsFile)) {
            result = GoogleCredentials.fromStream(inputStream);
          }
          break;
        case Inline:
          String inlineCredentials = getRequiredString(CREDENTIAL_INLINE_CONFIG);
          byte[] buffer = inlineCredentials.getBytes(StandardCharsets.UTF_8);
          try (InputStream inputStream = new ByteArrayInputStream(buffer)) {
            result = GoogleCredentials.fromStream(inputStream);
          }
          break;
        case ApplicationDefault:
          result = GoogleCredentials.getApplicationDefault();
          break;
        default:
          throw new ConfigException(CREDENTIAL_LOCATION_CONFIG, credentialLocation, "Unsupported ConfigLocation");
      }

      return result;
    };
  }

}
