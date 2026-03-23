/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

import io.confluent.csid.config.provider.common.SecretRequest;

import java.util.Map;

interface CyberArkClient {
  Map<String, String> getSecret(SecretRequest request) throws Exception;
}
