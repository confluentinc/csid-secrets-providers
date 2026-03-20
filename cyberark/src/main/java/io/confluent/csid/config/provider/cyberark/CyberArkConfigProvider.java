/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

import io.confluent.csid.config.provider.annotations.ConfigProviderKey;
import io.confluent.csid.config.provider.annotations.Description;
import io.confluent.csid.config.provider.annotations.DocumentationTip;
import io.confluent.csid.config.provider.common.AbstractConfigProvider;
import io.confluent.csid.config.provider.common.SecretRequest;
import org.apache.kafka.common.config.ConfigDef;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;

@Description("This config provider is used to retrieve secrets from CyberArk Conjur.")
@DocumentationTip("Config providers can be used with anything that supports the "
    + "AbstractConfig base class that is shipped with Apache Kafka.")
@ConfigProviderKey("cyberark")
public class CyberArkConfigProvider extends AbstractConfigProvider<CyberArkConfigProviderConfig> {
  private static final Logger log = LoggerFactory.getLogger(CyberArkConfigProvider.class);

  CyberArkClientFactory clientFactory = new CyberArkClientFactoryImpl();
  CyberArkClient client;

  @Override
  protected CyberArkConfigProviderConfig config(Map<String, ?> settings) {
    return new CyberArkConfigProviderConfig(settings);
  }

  @Override
  protected void configure() {
    this.client = this.clientFactory.create(this.config);
  }

  @Override
  protected Map<String, String> getSecret(SecretRequest secretRequest) throws Exception {
    log.info("getSecret() - request = '{}'", secretRequest);
    return this.client.getSecret(secretRequest);
  }

  @Override
  public ConfigDef config() {
    return CyberArkConfigProviderConfig.config();
  }
}
