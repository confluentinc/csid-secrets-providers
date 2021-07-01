/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.gcloud;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.secretmanager.v1.AccessSecretVersionRequest;
import com.google.cloud.secretmanager.v1.AccessSecretVersionResponse;
import com.google.cloud.secretmanager.v1.SecretManagerServiceClient;
import io.confluent.csid.config.provider.common.AbstractConfigProvider;
import io.confluent.csid.config.provider.common.SecretRequest;
import io.confluent.csid.config.provider.common.docs.Description;
import io.confluent.csid.config.provider.common.docs.DocumentationSection;
import io.confluent.csid.config.provider.common.docs.DocumentationSections;
import io.confluent.csid.config.provider.common.docs.DocumentationTip;
import org.apache.kafka.common.config.ConfigDef;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.Map;

@Description("This config provider is used to retrieve secrets from the Google Cloud Secret Manager service.")
@DocumentationTip("Config providers can be used with anything that supports the AbstractConfig base class that is shipped with Apache Kafka.")
@DocumentationSections(
    sections = {
        @DocumentationSection(title = "Secret Value", text = "The value for the secret must be formatted as a JSON object. " +
            "This allows multiple keys of data to be stored in a single secret. The name of the secret in Google Cloud Secret Manager " +
            "will correspond to the path that is requested by the config provider.\n" +
            "\n" +
            ".. code-block:: json\n" +
            "    :caption: Example Secret Value\n" +
            "\n" +
            "    {\n" +
            "      \"username\" : \"${secretManager:secret/test/some/connector:username}\",\n" +
            "      \"password\" : \"${secretManager:secret/test/some/connector:password}\"\n" +
            "    }\n" +
            ""),
        @DocumentationSection(title = "Secret Retrieval", text = "The ConfigProvider will use the name of the secret and the project id to " +
            "build the Resource ID for the secret. For example assuming you configured the ConfigProvider with `config.providers.secretsManager.param.project.id=1234` " +
            "and requested the secret with `${secretsManager:test-secret}`, the ConfigProvider will build a Resource ID of `projects/1234/secrets/test-secret/versions/latest`. " +
            "Some behaviors can be overridden by query string parameters. More than one query string parameter can be used. For example `${secretsManager:test-secret?ttl=30000&version=1}`" +
            "\n\n" +
            "+-----------+------------------------------------------------+--------------------------------------------------------------------------+------------------------------------------------+\n" +
            "| Parameter | Description                                    | Default                                                                  | Example                                        |\n" +
            "+===========+================================================+==========================================================================+================================================+\n" +
            "| ttl       | Used to override the TTL for the secret.       | Value specified by `config.providers.secretsManager.param.secret.ttl.ms` | `${secretsManager:test-secret?ttl=60000}`      |\n" +
            "+-----------+------------------------------------------------+--------------------------------------------------------------------------+------------------------------------------------+\n" +
            "| version   | Used to override the version of the secret.    | latest                                                                   | `${secretsManager:test-secret?version=1}`      |\n" +
            "+-----------+------------------------------------------------+--------------------------------------------------------------------------+------------------------------------------------+\n" +
            "| projectid | Used to override the project id of the secret. | Value specified by `config.providers.secretsManager.param.project.id`    | `${secretsManager:test-secret?projectid=4321}` |\n" +
            "+-----------+------------------------------------------------+--------------------------------------------------------------------------+------------------------------------------------+")
    }
)
public class SecretManagerConfigProvider extends AbstractConfigProvider<SecretManagerConfigProviderConfig> {
  private static final Logger log = LoggerFactory.getLogger(SecretManagerConfigProvider.class);
  SecretManagerConfigProviderConfig config;
  SecretManagerFactory secretManagerFactory = new SecretManagerFactoryImpl();

  SecretManagerServiceClient secretManager;

  ObjectMapper mapper = new ObjectMapper();

  @Override
  protected SecretManagerConfigProviderConfig config(Map<String, ?> settings) {
    return new SecretManagerConfigProviderConfig(settings);
  }

  @Override
  protected void configure() {
    this.secretManager = this.secretManagerFactory.create(this.config);
  }

  @Override
  protected Map<String, String> getSecret(SecretRequest request) throws Exception {
    log.info("get() - request = '{}'", request);

    AccessSecretVersionRequest accessSecretVersionRequest = AccessSecretVersionRequest.newBuilder()
        .setName(request.path())
        .build();
    AccessSecretVersionResponse response = this.secretManager.accessSecretVersion(accessSecretVersionRequest);
    return mapper.readValue(response.getPayload().getData().toByteArray(), Map.class);

  }

  @Override
  public void close() throws IOException {
    if (null != this.secretManager) {
      this.secretManager.close();
    }
    super.close();
  }

  public static ConfigDef config() {
    return SecretManagerConfigProviderConfig.config();
  }
}
