/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

class CyberArkClientFactoryImpl implements CyberArkClientFactory {
  @Override
  public CyberArkClient create(CyberArkConfigProviderConfig config) {
    return new CyberArkClientImpl(config);
  }
}
