/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common;

import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;

import java.util.Optional;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.DynamicTest.dynamicTest;

public class SecretRequestParserTests {

  @TestFactory
  public Stream<DynamicTest> parse() {
    return Stream.of(
        ImmutableSecretRequest.builder()
            .raw("test-path")
            .path("test-path")
            .build(),
        ImmutableSecretRequest.builder()
            .raw("test-path?version=1234")
            .path("test-path")
            .version(Optional.of("1234"))
            .build(),
        ImmutableSecretRequest.builder()
            .raw("test-path?ignored=1234")
            .path("test-path")
            .build(),
        ImmutableSecretRequest.builder()
            .raw("secret/foo/bar/baz/test-path")
            .path("secret/foo/bar/baz/test-path")
            .build(),
        ImmutableSecretRequest.builder()
            .raw("secret/foo/bar/baz/test-path/")
            .path("secret/foo/bar/baz/test-path/")
            .build(),
        ImmutableSecretRequest.builder()
            .raw("secret/foo/bar/baz/test-path?version=fansdfubausdbfgiasd")
            .path("secret/foo/bar/baz/test-path")
            .version(Optional.of("fansdfubausdbfgiasd"))
            .build()
        ).map(expected -> dynamicTest(expected.toString(), () -> {
      SecretRequest actual = SecretRequestParser.parse(expected.raw());
      assertEquals(expected, actual);
    }));
  }

}
