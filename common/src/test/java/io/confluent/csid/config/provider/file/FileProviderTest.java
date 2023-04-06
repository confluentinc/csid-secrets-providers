/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.file;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.google.common.collect.ImmutableMap;
import java.io.File;
import java.io.IOException;
import java.util.Map;
import org.apache.kafka.common.protocol.types.Field.Str;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class FileProviderTest {

  FileProvider provider;

  File file;

  @BeforeEach
  public void beforeEach() {
    provider = new FileProvider();
    provider.configure(ImmutableMap.of());
    file = new File("src/test/resources/test.txt");
  }

  @AfterEach
  public void afterEach() throws IOException {
    this.provider.close();
  }

  @Test
  public void testGetSecret() throws Exception {
    Map<String,String> expected = ImmutableMap.of(file.getName(), "blah");
    Map<String, String> actual = provider.get(file.getPath()).data();
    assertEquals(expected, actual);
  }

}