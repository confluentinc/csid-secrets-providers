/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common;

import org.immutables.value.Value;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * ConfigDataHasher is used to keep track of hashed values for config values. Hashes are stored
 * instead of the actual values.
 */
class ConfigDataHasher {
  Map<String, ConfigDataState> paths = new ConcurrentHashMap<>();

  @Value.Immutable
  interface ConfigDataState {
    /**
     * Map containing the hashcode by each individual field.
     *
     * @return
     */
    Map<String, Integer> hashes();

    /**
     * HashCode of all of the fields in hashes() sorted by the key.
     *
     * @return
     */
    int configHashCode();


    static ConfigDataState build(Map<String, String> data) {
      Map<String, Integer> hashes = new LinkedHashMap<>();
      Object[] values = new Object[data.size()];
      final AtomicInteger i = new AtomicInteger(0);
      data.entrySet()
          .stream()
          .sorted(Map.Entry.comparingByKey())
          .forEach(e -> {
            hashes.put(e.getKey(), Objects.hashCode(e.getValue()));
            values[i.getAndIncrement()] = e.getValue();
          });
      int configHashCode = Objects.hash(values);
      return ImmutableConfigDataState.builder()
          .hashes(hashes)
          .configHashCode(configHashCode)
          .build();
    }
  }

  public Set<String> updateHash(SecretRequest path, Map<String, String> configData) {
    final Set<String> result = new LinkedHashSet<>();
    final ConfigDataState newState = ConfigDataState.build(configData);
    /*
      The following code path is going to compare the new and old to see
      if there are differences.
     */
    this.paths.compute(path.raw(), (s, existing) -> {
      if (null != existing) {
        Set<String> keys = new LinkedHashSet<>();
        keys.addAll(newState.hashes().keySet());
        keys.addAll(existing.hashes().keySet());
        for (String key : keys) {
          Integer a = existing.hashes().get(key);
          Integer b = newState.hashes().get(key);
          if (!Objects.equals(a, b)) {
            result.add(key);
          }
        }
      }
      return newState;
    });

    return result;
  }
}
