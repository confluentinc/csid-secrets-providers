/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

import io.confluent.csid.config.provider.annotations.CodeBlock;
import io.confluent.csid.config.provider.annotations.ConfigProviderKey;
import io.confluent.csid.config.provider.annotations.Description;
import io.confluent.csid.config.provider.annotations.DocumentationSection;
import io.confluent.csid.config.provider.annotations.DocumentationSections;
import io.confluent.csid.config.provider.annotations.DocumentationTip;
import io.confluent.csid.config.provider.common.AbstractConfigProvider;
import io.confluent.csid.config.provider.common.SecretRequest;
import org.apache.kafka.common.config.ConfigDef;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;

@Description("This config provider is used to retrieve secrets from CyberArk Conjur.")
@DocumentationSections(
    sections = {
        @DocumentationSection(title = "Secret Value", text = "The value for the secret is stored "
            + "as a variable in CyberArk Conjur. Variables are declared in a Conjur policy and "
            + "their values are set via the Conjur API or CLI. The path requested by the config "
            + "provider corresponds to the variable ID in Conjur.",
            codeblocks = {
                @CodeBlock(
                    title = "Example Secret Value",
                    language = "json",
                    text = "{\n"
                        + "  \"username\" : \"appdbsecret\",\n"
                        + "  \"password\" : \"u$3@b3tt3rp@$$w0rd\"\n"
                        + "}"
                    )
            }
          ),
        @DocumentationSection(title = "Secret Retrieval", text = "The ConfigProvider will use "
            + "the path of the secret to retrieve the variable value from Conjur. "
            + "For example, a path of 'app-secrets/db-password' will retrieve the variable "
            + "with ID 'app-secrets/db-password' from the configured Conjur account.")
    }
)
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
