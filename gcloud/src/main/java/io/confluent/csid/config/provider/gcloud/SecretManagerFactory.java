/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.gcloud;

import com.google.cloud.secretmanager.v1.SecretManagerServiceClient;

interface SecretManagerFactory {
  SecretManagerServiceClient create(SecretManagerConfigProviderConfig config);
}
