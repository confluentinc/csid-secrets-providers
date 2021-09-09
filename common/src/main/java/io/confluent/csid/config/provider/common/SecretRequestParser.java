/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common;

import java.net.URI;
import java.util.AbstractMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

class SecretRequestParser {
  private static Map<String, String> parseParams(URI uri) {
    Map<String, String> results;

    if (null != uri.getQuery()) {
      results = Stream.of(uri.getQuery().split("&"))
          .map(s -> {
            String[] parts = s.split("=");
            return new AbstractMap.SimpleImmutableEntry<>(parts[0], parts.length == 2 ? parts[1] : null);
          })
          .collect(Collectors.toMap(AbstractMap.SimpleImmutableEntry::getKey, AbstractMap.SimpleImmutableEntry::getValue));
    } else {
      results = new LinkedHashMap<>();
    }
    return results;
  }

  public static SecretRequest parse(String input) {
    URI uri = URI.create(input);
    Map<String, String> params = parseParams(uri);
    return ImmutableSecretRequest.builder()
        .raw(input)
        .version(Optional.ofNullable(params.get("version")))
        .path(uri.getPath())
        .build();
  }
}
