/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.file;

import io.confluent.csid.config.provider.common.testing.AbstractDocumentationTest;
import java.util.Collections;
import java.util.List;
import org.apache.kafka.common.config.provider.ConfigProvider;

public class DocumentationTest extends AbstractDocumentationTest {
  @Override
  protected List<Class<? extends ConfigProvider>> providers() {
    return Collections.singletonList(FileProvider.class);
  }
}