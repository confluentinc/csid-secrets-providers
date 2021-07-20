/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.gcloud;

import com.google.api.gax.core.CredentialsProvider;
import com.google.auth.oauth2.GoogleCredentials;
import io.confluent.csid.config.provider.annotations.Description;
import io.confluent.csid.config.provider.common.AbstractConfigProviderConfig;
import io.confluent.csid.config.provider.common.config.ConfigKeyBuilder;
import io.confluent.csid.config.provider.common.config.ConfigUtils;
import io.confluent.csid.config.provider.common.config.Validators;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.ConfigException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;

class SecretManagerConfigProviderConfig extends AbstractConfigProviderConfig {
  private static final Logger log = LoggerFactory.getLogger(SecretManagerConfigProviderConfig.class);

  public static final String CREDENTIAL_LOCATION_CONFIG = "credential.location";
  static final String CREDENTIAL_LOCATION_DOC = "The location to retrieve the credentials used to access the Google Services. " + ConfigUtils.enumDescription(CredentialLocation.class);

  public static final String CREDENTIAL_FILE_CONFIG = "credential.file";
  static final String CREDENTIAL_FILE_DOC = "Location on the local filesystem to load the credentials.";

  public static final String CREDENTIAL_INLINE_CONFIG = "credential.inline";
  static final String CREDENTIAL_INLINE_DOC = "The content of the credentials file embedded as a string.";
  public static final String PROJECT_ID_CONFIG = "project.id";
  static final String PROJECT_ID_DOC = "The project that owns the credentials.";

  public final CredentialLocation credentialLocation;
  public final Long projectId;

  public SecretManagerConfigProviderConfig(Map<String, ?> settings) {
    super(config(), settings);

    this.credentialLocation = ConfigUtils.getEnum(CredentialLocation.class, this, CREDENTIAL_LOCATION_CONFIG);
    this.projectId = getLong(PROJECT_ID_CONFIG);
  }

  public static ConfigDef config() {
    return AbstractConfigProviderConfig.config()
        .define(
            ConfigKeyBuilder.of(CREDENTIAL_LOCATION_CONFIG, ConfigDef.Type.STRING)
                .documentation(CREDENTIAL_LOCATION_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue(CredentialLocation.ApplicationDefault.name())
                .validator(Validators.validEnum(CredentialLocation.class))
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
    @Description("Credentials are retrieved by calling `GoogleCredentials.getApplicationDefault()`")
    ApplicationDefault,
    @Description("Credentials file is read from the file system in the location specified by `" + CREDENTIAL_FILE_CONFIG + "`")
    File,
    @Description("The contents of the credentials file are embedded in `" + CREDENTIAL_INLINE_CONFIG + "`")
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
