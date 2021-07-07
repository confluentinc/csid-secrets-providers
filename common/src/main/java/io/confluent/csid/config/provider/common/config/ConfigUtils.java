/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common.config;

import io.confluent.csid.config.provider.common.docs.Description;
import org.apache.kafka.common.config.AbstractConfig;

import java.lang.reflect.Field;
import java.util.Arrays;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.StringJoiner;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class ConfigUtils {
  public static <T extends Enum<T>> T getEnum(Class<T> enumClass, AbstractConfig config, String key) {
    String textValue = config.getString(key);
    return Enum.valueOf(enumClass, textValue);
  }

  public static <T extends Enum<T>> String enumDescription(Class<T> enumClass, T... excludes) {
    Set<T> exclude = new LinkedHashSet<T>(Arrays.asList(excludes));
    T[] constants = enumClass.getEnumConstants();
    Map<T, String> descriptions = Stream.of(constants)
        .filter(e -> !exclude.contains(e))
        .sorted(Comparator.comparing(Enum::name))
        .collect(
            Collectors.toMap(
                Function.identity(),
                enumConstant -> {
                  try {
                    Field enumField = enumClass.getField(enumConstant.name());
                    Description descriptionAttribute = enumField.getAnnotation(Description.class);
                    String description = null != descriptionAttribute ? descriptionAttribute.value() : null;
                    return description;
                  } catch (NoSuchFieldException ex) {
                    throw new IllegalStateException("Could not find field " + enumConstant.name(), ex);
                  }
                }, (u, v) -> {
                  throw new IllegalStateException(String.format("Duplicate key %s", u));
                }, LinkedHashMap::new)
        );

    return enumDescription(descriptions);
  }

  public static <T extends Enum<T>> String enumDescription(Map<T, String> descriptions) {
    StringBuilder builder = new StringBuilder();
    descriptions.forEach((key, value) -> {
      if (builder.length() > 0) {
        builder.append(", ");
      }
      builder.append('`');
      builder.append(key.toString());
      builder.append("` - ");
      builder.append(value);
    });
    return builder.toString();
  }

  public static String enumValues(Class<?> enumClass) {
    StringJoiner joiner = new StringJoiner(", ");
    Stream.of(enumClass.getEnumConstants())
        .map(Object::toString)
        .forEach(joiner::add);
    return joiner.toString();
  }
}
