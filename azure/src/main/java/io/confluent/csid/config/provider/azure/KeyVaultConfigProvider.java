/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.azure;

import com.azure.security.keyvault.secrets.models.KeyVaultSecret;
import io.confluent.csid.config.provider.common.AbstractJacksonConfigProvider;
import io.confluent.csid.config.provider.common.SecretRequest;
import io.confluent.csid.config.provider.common.docs.Description;
import io.confluent.csid.config.provider.common.docs.DocumentationSection;
import io.confluent.csid.config.provider.common.docs.DocumentationSections;
import io.confluent.csid.config.provider.common.docs.DocumentationTip;
import org.apache.kafka.common.config.ConfigDef;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;

@Description("This config provider is used to retrieve secrets from the Microsoft Azure Key Vault service.")
@DocumentationTip("Config providers can be used with anything that supports the AbstractConfig base class that is shipped with Apache Kafka.")
@DocumentationSections(
    sections = {
        @DocumentationSection(title = "Secret Value", text = "The value for the secret must be formatted as a JSON object. " +
            "This allows multiple keys of data to be stored in a single secret. The name of the secret in Microsoft Azure Key Vault " +
            "will correspond to the path that is requested by the config provider.\n" +
            "\n" +
            ".. code-block:: json\n" +
            "    :caption: Example Secret Value\n" +
            "\n" +
            "    {\n" +
            "      \"username\" : \"db101\",\n" +
            "      \"password\" : \"superSecretPassword\"\n" +
            "    }\n" +
            ""),
        @DocumentationSection(title = "Secret Retrieval", text = "The ConfigProvider will use the name of the secret to build the request to the Key Vault service. " +
            "This behavior can be overridden by setting `config.providers.keyVault.param.prefix=staging-` and requested the secret with `${keyVault:test-secret}`, " +
            "the ConfigProvider will build a request for `staging-test-secret`. Some behaviors can be overridden by query string parameters. More than one query string parameter " +
            "can be used. For example `${keyVault:test-secret?ttl=30000&version=1}` would return the secret named `test-secret` version `1` with a TTL of 30 seconds. " +
            "After the TTL has expired the ConfigProvider will request an updated credential. If you're using this with Kafka Connect, your tasks will be reconfigured if one of the values " +
            "have changed." +
            "\n\n" +
            "+-----------+------------------------------------------------+--------------------------------------------------------------------+------------------------------------------+\n" +
            "| Parameter | Description                                    | Default                                                            | Example                                  |\n" +
            "+===========+================================================+====================================================================+==========================================+\n" +
            "| ttl       | Used to override the TTL for the secret.       | Value specified by `config.providers.keyVault.param.secret.ttl.ms` | `${keyVault:test-secret?ttl=60000}`      |\n" +
            "+-----------+------------------------------------------------+--------------------------------------------------------------------+------------------------------------------+\n" +
            "| version   | Used to override the version of the secret.    | latest                                                             | `${keyVault:test-secret?version=1}`      |\n" +
            "+-----------+------------------------------------------------+--------------------------------------------------------------------+------------------------------------------+\n")
    }
)
public class KeyVaultConfigProvider extends AbstractJacksonConfigProvider<KeyVaultConfigProviderConfig> {
  private static final Logger log = LoggerFactory.getLogger(KeyVaultConfigProvider.class);
  KeyVaultConfigProviderConfig config;
  KeyVaultFactory keyVaultFactory = new KeyVaultFactoryImpl();

  SecretClientWrapper secretClient;

  @Override
  protected KeyVaultConfigProviderConfig config(Map<String, ?> settings) {
    return new KeyVaultConfigProviderConfig(settings);
  }

  @Override
  protected void configure() {
    super.configure();
    this.secretClient = this.keyVaultFactory.create(this.config);
  }

  @Override
  protected Map<String, String> getSecret(SecretRequest secretRequest) throws Exception {
    KeyVaultSecret response = secretClient.getSecret(secretRequest.path(), secretRequest.version().orElse(null));
    return readJsonValue(response.getValue());
  }


  @Override
  public ConfigDef config() {
    return KeyVaultConfigProviderConfig.config();
  }
}
