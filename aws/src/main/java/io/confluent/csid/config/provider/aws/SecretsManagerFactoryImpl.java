/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.aws;

import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.services.secretsmanager.AWSSecretsManager;
import com.amazonaws.services.secretsmanager.AWSSecretsManagerClientBuilder;

class SecretsManagerFactoryImpl implements SecretsManagerFactory {
  @Override
  public AWSSecretsManager create(SecretsManagerConfigProviderConfig config) {
    AWSSecretsManagerClientBuilder builder = AWSSecretsManagerClientBuilder.standard();

    if (null != config.region && !config.region.isEmpty()) {
      builder = builder.withRegion(config.region);
    }
    if (null != config.credentials) {
      builder = builder.withCredentials(new AWSStaticCredentialsProvider(config.credentials));
    }

    return builder.build();
  }
}
