/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common.testing;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

public class TestUtils {
  public static <T> Set<T> setOf(T... items) {
    Set<T> result = new LinkedHashSet<>();
    Collections.addAll(result, items);
    return result;
  }

  public static <K, V> Map<K, V> mapOf(K key0, V value0) {
    Map<K, V> result = new LinkedHashMap<>();
    result.put(key0, value0);
    return result;
  }

  public static <K, V> Map<K, V> mapOf(K key0, V value0, K key1, V value1) {
    Map<K, V> result = new LinkedHashMap<>();
    result.put(key0, value0);
    result.put(key1, value1);
    return result;
  }

  public static <K, V> Map<K, V> mapOf(K key0, V value0, K key1, V value1, K key2, V value2) {
    Map<K, V> result = new LinkedHashMap<>();
    result.put(key0, value0);
    result.put(key1, value1);
    result.put(key2, value2);
    return result;
  }

  public static <K, V> Map<K, V> mapOf(K key0, V value0, K key1, V value1, K key2, V value2, K key3, V value3) {
    Map<K, V> result = new LinkedHashMap<>();
    result.put(key0, value0);
    result.put(key1, value1);
    result.put(key2, value2);
    result.put(key3, value3);
    return result;
  }

  public static <K, V> Map<K, V> mapOf(K key0, V value0, K key1, V value1, K key2, V value2, K key3, V value3, K key4, V value4) {
    Map<K, V> result = new LinkedHashMap<>();
    result.put(key0, value0);
    result.put(key1, value1);
    result.put(key2, value2);
    result.put(key3, value3);
    result.put(key4, value4);
    return result;
  }

}
