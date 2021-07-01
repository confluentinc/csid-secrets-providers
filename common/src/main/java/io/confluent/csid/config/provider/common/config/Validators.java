/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common.config;

import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.ConfigException;

import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.StringJoiner;

public class Validators {
  public static ConfigDef.Validator validEnum(Class<? extends Enum> enumClass, Enum... excludes) {
    String[] ex = new String[excludes.length];
    for (int i = 0; i < ex.length; i++) {
      ex[i] = excludes[i].toString();
    }
    return ValidEnum.of(enumClass, ex);
  }

  static class ValidEnum implements ConfigDef.Validator {
    final Set<String> validEnums;
    final Class<?> enumClass;

    /**
     * Method is used to create a new INSTANCE of the enum validator.
     *
     * @param enumClass Enum class with the entries to validate for.
     * @param excludes  Enum entries to exclude from the validator.
     * @return ValidEnum
     */
    public static ValidEnum of(Class<?> enumClass, String... excludes) {
      return new ValidEnum(enumClass, excludes);
    }

    private ValidEnum(Class<?> enumClass, String... excludes) {
      Set<String> validEnums = new LinkedHashSet<>();
      for (Object o : enumClass.getEnumConstants()) {
        String key = o.toString();
        validEnums.add(key);
      }
      Arrays.asList(excludes).forEach(validEnums::remove);
      this.validEnums = validEnums;
      this.enumClass = enumClass;
    }

    @Override
    public void ensureValid(String s, Object o) {

      if (o instanceof String) {
        if (!validEnums.contains(o)) {
          throw new ConfigException(
              s,
              String.format(
                  "'%s' is not a valid value for %s. Valid values are %s.",
                  o,
                  enumClass.getSimpleName(),
                  ConfigUtils.enumValues(enumClass)
              )
          );
        }
      } else if (o instanceof List) {
        List list = (List) o;
        for (Object i : list) {
          ensureValid(s, i);
        }
      } else {
        throw new ConfigException(
            s,
            o,
            "Must be a String or List"
        );
      }


    }

    @Override
    public String toString() {
      StringJoiner joiner = new StringJoiner(", ");
      this.validEnums.stream()
          .map(Object::toString)
          .forEach(joiner::add);
      return "Matches: ``" + joiner + "``";
    }
  }
}
