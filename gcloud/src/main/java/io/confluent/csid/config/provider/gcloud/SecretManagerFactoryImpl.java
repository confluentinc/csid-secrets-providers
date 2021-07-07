/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.gcloud;

import com.google.cloud.secretmanager.v1.SecretManagerServiceClient;
import com.google.cloud.secretmanager.v1.SecretManagerServiceSettings;
import org.apache.kafka.common.config.ConfigException;

import java.io.IOException;

class SecretManagerFactoryImpl implements SecretManagerFactory {
  @Override
  public SecretManagerServiceClient create(SecretManagerConfigProviderConfig config) {
    try {
      SecretManagerServiceSettings settings = SecretManagerServiceSettings.newBuilder()
          .setCredentialsProvider(config.credentialsProvider())
          .build();
      return SecretManagerServiceClient.create(settings);
    } catch (IOException ex) {
      ConfigException exception = new ConfigException("Exception during configuration");
      exception.initCause(exception);
      throw exception;
    }
  }
}
