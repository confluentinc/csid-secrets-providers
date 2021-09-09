/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.Map;

import static io.confluent.csid.config.provider.common.testing.TestUtils.mapOf;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;

public class AbstractJacksonConfigProviderTests {
  MockAbstractJacksonConfigProvider provider;

  @BeforeEach
  public void before() {
    this.provider = mock(MockAbstractJacksonConfigProvider.class, Mockito.CALLS_REAL_METHODS);
    this.provider.configure();
  }

  @Test
  public void readJsonValueNotObject() throws IOException {
    String content = this.provider.mapper.writeValueAsString(12345);
    IllegalStateException ex = assertThrows(IllegalStateException.class, () -> {
      provider.readJsonValue(content);
    });
  }

  @Test
  public void readJsonValueNull() throws IOException {
    String content = this.provider.mapper.writeValueAsString(null);
    IllegalStateException ex = assertThrows(IllegalStateException.class, () -> {
      provider.readJsonValue(content);
    });
  }

  @Test
  public void readJsonValue() throws IOException {
    Map<String, String> expected = mapOf(
        "username", "user01",
        "password", "password",
        "hostname", "db01.example.com",
        "port", "54321"
    );
    String content = this.provider.mapper.writeValueAsString(expected);
    Map<String, String> actual = this.provider.readJsonValue(content);
    assertEquals(expected, actual);
  }

  @Test
  public void readJsonValueBytes() throws IOException {
    Map<String, String> expected = mapOf(
        "username", "user01",
        "password", "password",
        "hostname", "db01.example.com",
        "port", "54321"
    );
    byte[] content = this.provider.mapper.writeValueAsBytes(expected);
    Map<String, String> actual = this.provider.readJsonValue(content);
    assertEquals(expected, actual);
  }

  @Test
  public void readJsonValueByteBuffer() throws IOException {
    Map<String, String> expected = mapOf(
        "username", "user01",
        "password", "password",
        "hostname", "db01.example.com",
        "port", "54321"
    );
    byte[] content = this.provider.mapper.writeValueAsBytes(expected);
    Map<String, String> actual = this.provider.readJsonValue(ByteBuffer.wrap(content));
    assertEquals(expected, actual);
  }

  @Test
  public void readJsonValueObjectValue() throws IOException {
    Map<String, Object> input = mapOf(
        "credentials", mapOf(
            "username", "user01",
            "password", "password"
        )
    );

    Map<String, String> expected = mapOf(
        "credentials", "{\"username\":\"user01\",\"password\":\"password\"}"
    );

    String content = this.provider.mapper.writeValueAsString(input);
    Map<String, String> actual = this.provider.readJsonValue(content);
    assertEquals(expected, actual);
  }

  @Test
  public void readJsonValueNonStringValue() throws IOException {
    Map<String, Object> input = mapOf(
        "username", "user01",
        "password", "password",
        "hostname", "db01.example.com",
        "port", 54321,
        "a", null
    );
    Map<String, String> expected = mapOf(
        "username", "user01",
        "password", "password",
        "hostname", "db01.example.com",
        "port", "54321"
    );

    String content = this.provider.mapper.writeValueAsString(input);
    Map<String, String> actual = this.provider.readJsonValue(content);
    assertEquals(expected, actual);
  }


}
