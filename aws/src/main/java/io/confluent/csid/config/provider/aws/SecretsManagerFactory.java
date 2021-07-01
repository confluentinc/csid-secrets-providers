/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.aws;

import com.amazonaws.services.secretsmanager.AWSSecretsManager;

interface SecretsManagerFactory {
  AWSSecretsManager create(SecretsManagerConfigProviderConfig config);
}
