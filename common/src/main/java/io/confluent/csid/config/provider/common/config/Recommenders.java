/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common.config;

import org.apache.kafka.common.config.ConfigDef;

import java.util.Collections;
import java.util.List;
import java.util.Map;

public class Recommenders {
  public static ConfigDef.Recommender visibleIf(String configKey, Object value) {
    return new VisibleIfRecommender(configKey, value, ValidValuesCallback.EMPTY);
  }

  public interface ValidValuesCallback {
    List<Object> validValues(String configItem, Map<String, Object> settings);

    ValidValuesCallback EMPTY = (configItem, settings) -> Collections.emptyList();
  }

  static class VisibleIfRecommender implements ConfigDef.Recommender {
    final String configKey;
    final Object value;
    final ValidValuesCallback validValuesCallback;

    VisibleIfRecommender(String configKey, Object value, ValidValuesCallback validValuesCallback) {
      this.configKey = configKey;
      this.value = value;
      this.validValuesCallback = validValuesCallback;
    }

    @Override
    public List<Object> validValues(String s, Map<String, Object> map) {
      return this.validValuesCallback.validValues(s, map);
    }

    @Override
    public boolean visible(String key, Map<String, Object> settings) {
      Object v = settings.get(this.configKey);
      return this.value.equals(v);
    }
  }
}
