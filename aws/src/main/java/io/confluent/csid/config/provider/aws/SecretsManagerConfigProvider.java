/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.aws;

import com.amazonaws.services.secretsmanager.AWSSecretsManager;
import com.amazonaws.services.secretsmanager.model.GetSecretValueRequest;
import com.amazonaws.services.secretsmanager.model.GetSecretValueResult;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.confluent.csid.config.provider.common.AbstractConfigProvider;
import io.confluent.csid.config.provider.common.SecretRequest;
import io.confluent.csid.config.provider.common.docs.Description;
import io.confluent.csid.config.provider.common.docs.DocumentationSection;
import io.confluent.csid.config.provider.common.docs.DocumentationSections;
import io.confluent.csid.config.provider.common.docs.DocumentationTip;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.ConfigException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.Map;

@Description("This config provider is used to retrieve secrets from the AWS Secrets Manager service.")
@DocumentationTip("Config providers can be used with anything that supports the AbstractConfig base class that is shipped with Apache Kafka.")
@DocumentationSections(
    sections = {
        @DocumentationSection(title = "Secret Value", text = "The value for the secret must be formatted as a JSON object. " +
            "This allows multiple keys of data to be stored in a single secret. The name of the secret in AWS Secrets Manager " +
            "will correspond to the path that is requested by the config provider.\n" +
            "\n" +
            ".. code-block:: json\n" +
            "    :caption: Example Secret Value\n" +
            "\n" +
            "    {\n" +
            "      \"username\" : \"${secretManager:secret/test/some/connector:username}\",\n" +
            "      \"password\" : \"${secretManager:secret/test/some/connector:password}\"\n" +
            "    }\n" +
            "")
    }
)
public class SecretsManagerConfigProvider extends AbstractConfigProvider<SecretsManagerConfigProviderConfig> {
  private static final Logger log = LoggerFactory.getLogger(SecretsManagerConfigProvider.class);
  SecretsManagerConfigProviderConfig config;
  SecretsManagerFactory secretsManagerFactory = new SecretsManagerFactoryImpl();
  AWSSecretsManager secretsManager;
  ObjectMapper mapper = new ObjectMapper();

  @Override
  protected SecretsManagerConfigProviderConfig config(Map<String, ?> settings) {
    return new SecretsManagerConfigProviderConfig(settings);
  }

  @Override
  protected void configure() {
    this.secretsManager = this.secretsManagerFactory.create(this.config);
  }

  @Override
  protected Map<String, String> getSecret(SecretRequest secretRequest) throws Exception {
    GetSecretValueRequest request = new GetSecretValueRequest()
        .withSecretId(secretRequest.path());
    secretRequest.version().ifPresent(request::withVersionId);

    GetSecretValueResult result = this.secretsManager.getSecretValue(request);

    if (null != result.getSecretString()) {
      return mapper.readValue(result.getSecretString(), Map.class);
    } else if (null != result.getSecretBinary()) {
      byte[] arr = new byte[result.getSecretBinary().remaining()];
      result.getSecretBinary().get(arr);
      return mapper.readValue(arr, Map.class);
    } else {
      throw new ConfigException("");
    }
  }

  @Override
  public void close() throws IOException {
    if (null != this.secretsManager) {
      this.secretsManager.shutdown();
    }
    super.close();
  }

  public static ConfigDef config() {
    return SecretsManagerConfigProviderConfig.config();
  }
}
