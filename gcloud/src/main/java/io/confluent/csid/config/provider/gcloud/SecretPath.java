/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.gcloud;

import org.apache.kafka.common.config.ConfigException;

import java.net.URI;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.AbstractMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

class SecretPath {
  private final URI uri;
  private final Map<String, String> params;
  private final long ttl;
  private final Path path;

  private SecretPath(URI uri, Map<String, String> params, String prefix, long projectId, Long version, long ttl) {
    this.uri = uri;
    this.params = params;
    this.ttl = ttl;

    this.path = Paths.get(
        "projects",
        Long.toString(projectId),
        "secrets",
        ((null != prefix && !prefix.isEmpty()) ? prefix : "") + uri.getPath(),
        "versions",
        null != version ? version.toString() : "latest"
    );
  }

  public long ttl() {
    return this.ttl;
  }


  public Path path() {
    return this.path;
  }

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

  static Long parseLong(Map<String, String> params, String key, Long defaultValue) {
    Long result;

    if (params.containsKey(key)) {
      String input = params.get(key);
      try {
        result = Long.parseLong(input);
      } catch (NumberFormatException ex) {
        ConfigException configException = new ConfigException(key, input, "Could not parse to long.");
        configException.initCause(ex);
        throw configException;
      }
    } else {
      result = defaultValue;
    }

    return result;
  }

  public static SecretPath parse(SecretManagerConfigProviderConfig config, String input) {
    URI uri = URI.create(input);
    Map<String, String> params = parseParams(uri);
    long ttl = parseLong(params, "ttl", config.minimumSecretTTL);
    Long version = parseLong(params, "version", null);
    long projectId = parseLong(params, "projectid", config.projectId);
    return new SecretPath(uri, params, config.prefix, projectId, version, ttl);
  }
}
