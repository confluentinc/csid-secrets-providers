/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.file;

import io.confluent.csid.config.provider.common.AbstractConfigProviderConfig;
import java.util.Map;
import org.apache.kafka.common.config.ConfigDef;

public class FileProviderConfig extends AbstractConfigProviderConfig {

  public FileProviderConfig(Map<?, ?> originals) {
    super(config(), originals);
  }

  public static ConfigDef config() {
    return AbstractConfigProviderConfig.config();
  }
}
