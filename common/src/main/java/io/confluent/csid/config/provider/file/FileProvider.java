/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.file;

import io.confluent.csid.config.provider.annotations.ConfigProviderKey;
import io.confluent.csid.config.provider.annotations.Description;
import io.confluent.csid.config.provider.annotations.DocumentationTip;
import io.confluent.csid.config.provider.common.AbstractConfigProvider;
import io.confluent.csid.config.provider.common.SecretRequest;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.LinkedHashMap;
import java.util.Map;
import org.apache.kafka.common.config.ConfigDef;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Description("This config provider is used to retrieve secrets from a file.")
@DocumentationTip("Config providers can be used with anything that supports the AbstractConfig base class that is shipped with Apache Kafka.")
@ConfigProviderKey("file")
public class FileProvider extends AbstractConfigProvider<FileProviderConfig> {

  private static final Logger log = LoggerFactory.getLogger(FileProvider.class);

  @Override
  protected FileProviderConfig config(final Map<String, ?> settings) {
    return new FileProviderConfig(settings);
  }

  @Override
  protected void configure() {

  }

  @Override
  protected Map<String, String> getSecret(final SecretRequest secretRequest) throws Exception {

    log.info("getSecret() - request = '{}'", secretRequest);
    try {
      final File file = new File(secretRequest.path());
      Map<String, String> result = new LinkedHashMap<>();
      result.put(file.getName(), new String(Files.readAllBytes(file.toPath())));
      log.debug("getSecret() - result = '{}'", result);
      return result;
    } catch (IOException e) {
      log.error("Error reading file", e);
      throw new RuntimeException(e);
    }
  }

  @Override
  public ConfigDef config() {
    return FileProviderConfig.config();
  }
}
