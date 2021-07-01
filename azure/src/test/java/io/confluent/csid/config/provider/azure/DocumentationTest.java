/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.azure;

import io.confluent.csid.config.provider.common.testing.AbstractDocumentationTest;
import org.apache.kafka.common.config.provider.ConfigProvider;

import java.util.Collections;
import java.util.List;

public class DocumentationTest extends AbstractDocumentationTest {
  @Override
  protected List<Class<? extends ConfigProvider>> providers() {
    return Collections.singletonList(KeyVaultConfigProvider.class);
  }
}
