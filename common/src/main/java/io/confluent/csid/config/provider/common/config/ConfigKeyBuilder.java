/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common.config;

import org.apache.kafka.common.config.ConfigDef;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class ConfigKeyBuilder {
  private final String name;
  private final ConfigDef.Type type;
  private String documentation = "";
  private Object defaultValue = ConfigDef.NO_DEFAULT_VALUE;
  private ConfigDef.Validator validator;
  private ConfigDef.Importance importance;
  private String group = "";
  private int orderInGroup = -1;
  private ConfigDef.Width width = ConfigDef.Width.NONE;
  private String displayName;
  private List<String> dependents = Collections.emptyList();
  private ConfigDef.Recommender recommender;
  private boolean internalConfig = true;

  private ConfigKeyBuilder(String group, String name, ConfigDef.Type type) {
    this(name, type);
    this.group = group;
  }

  private ConfigKeyBuilder(String name, ConfigDef.Type type) {
    this.name = name;
    this.displayName = name;
    this.type = type;
  }

  public static ConfigKeyBuilder of(String group, String name, ConfigDef.Type type) {
    return new ConfigKeyBuilder(group, name, type);
  }

  public static ConfigKeyBuilder of(String name, ConfigDef.Type type) {
    return new ConfigKeyBuilder(name, type);
  }

  public ConfigDef.ConfigKey build() {
    return new ConfigDef.ConfigKey(this.name, this.type, this.defaultValue, this.validator, this.importance, this.documentation, this.group, this.orderInGroup, this.width, this.displayName, this.dependents, this.recommender, this.internalConfig);
  }

  public String name() {
    return this.name;
  }

  public ConfigDef.Type type() {
    return this.type;
  }

  public String documentation() {
    return this.documentation;
  }

  public ConfigKeyBuilder documentation(String documentation) {
    this.documentation = documentation;
    return this;
  }

  public Object defaultValue() {
    return this.defaultValue;
  }

  public ConfigKeyBuilder defaultValue(Object defaultValue) {
    this.defaultValue = defaultValue;
    return this;
  }

  public ConfigDef.Validator validator() {
    return this.validator;
  }

  public ConfigKeyBuilder validator(ConfigDef.Validator validator) {
    this.validator = validator;
    return this;
  }

  public ConfigDef.Importance importance() {
    return this.importance;
  }

  public ConfigKeyBuilder importance(ConfigDef.Importance importance) {
    this.importance = importance;
    return this;
  }

  public String group() {
    return this.group;
  }

  public ConfigKeyBuilder group(String group) {
    this.group = group;
    return this;
  }

  public int orderInGroup() {
    return this.orderInGroup;
  }

  public ConfigKeyBuilder orderInGroup(int orderInGroup) {
    this.orderInGroup = orderInGroup;
    return this;
  }

  public ConfigDef.Width width() {
    return this.width;
  }

  public ConfigKeyBuilder width(ConfigDef.Width width) {
    this.width = width;
    return this;
  }

  public String displayName() {
    return this.displayName;
  }

  public ConfigKeyBuilder displayName(String displayName) {
    this.displayName = displayName;
    return this;
  }

  public List<String> dependents() {
    return this.dependents;
  }

  public ConfigKeyBuilder dependents(List<String> dependents) {
    this.dependents = dependents;
    return this;
  }

  public ConfigKeyBuilder dependents(String... dependents) {
    return dependents(Collections.unmodifiableList(Arrays.asList(dependents)));
  }

  public ConfigDef.Recommender recommender() {
    return this.recommender;
  }

  public ConfigKeyBuilder recommender(ConfigDef.Recommender recommender) {
    this.recommender = recommender;
    return this;
  }

  public boolean isinternalConfig() {
    return this.internalConfig;
  }

  public ConfigKeyBuilder internalConfig(boolean internalConfig) {
    this.internalConfig = internalConfig;
    return this;
  }
}
