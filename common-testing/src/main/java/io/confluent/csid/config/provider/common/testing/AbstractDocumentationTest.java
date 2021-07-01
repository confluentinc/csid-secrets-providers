/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common.testing;

import org.apache.kafka.common.config.provider.ConfigProvider;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.Reader;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.DynamicTest.dynamicTest;

public abstract class AbstractDocumentationTest {

  protected abstract List<Class<? extends ConfigProvider>> providers();

  @TestFactory
  public Stream<DynamicTest> metaInfServices() throws IOException {
    Set<String> providers = new LinkedHashSet<>();

    String input = "/META-INF/services/org.apache.kafka.common.config.provider.ConfigProvider";
    try (InputStream inputStream = this.getClass().getResourceAsStream(input)) {
      assertNotNull(inputStream, "could not find " + input);
      try (Reader reader = new InputStreamReader(inputStream)) {
        try (LineNumberReader lineNumberReader = new LineNumberReader(reader)) {
          String line;
          while (null != (line = lineNumberReader.readLine())) {
            providers.add(line);
          }
        }
      }
    }
    return providers().stream()
        .map(c -> dynamicTest(c.getName(), () -> {
          assertTrue(
              providers.contains(c.getName()),
              String.format("%s is missing from %s", c.getName(), input)
          );
        }));
  }


}
