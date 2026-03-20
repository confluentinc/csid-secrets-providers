/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

interface CyberArkClientFactory {
  CyberArkClient create(CyberArkConfigProviderConfig config);
}
