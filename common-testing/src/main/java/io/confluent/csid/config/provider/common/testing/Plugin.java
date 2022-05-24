/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common.testing;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import io.confluent.csid.config.provider.annotations.ConfigProviderKey;
import io.confluent.csid.config.provider.annotations.Description;
import io.confluent.csid.config.provider.annotations.DocumentationSection;
import io.confluent.csid.config.provider.annotations.Introduction;
import io.confluent.csid.config.provider.annotations.PluginName;
import io.confluent.csid.config.provider.annotations.PluginOwner;
import io.confluent.csid.config.provider.annotations.Title;
import org.apache.kafka.common.config.ConfigDef;
import org.immutables.value.Value;

import java.util.List;
import java.util.Map;

@Value.Immutable
public interface Plugin {
  Package getPackage();

  @Value.Derived
  default String getIntroduction() {
    Introduction annotation = getPackage().getAnnotation(Introduction.class);
    return null != annotation ? annotation.value() : null;
  }

  @Value.Derived
  default String getPluginName() {
    PluginName annotation = getPackage().getAnnotation(PluginName.class);
    return null != annotation ? annotation.value() : null;
  }

  @Value.Derived
  default String getPluginOwner() {
    PluginOwner annotation = getPackage().getAnnotation(PluginOwner.class);
    return null != annotation ? annotation.value() : null;
  }

  @Value.Derived
  default String getTitle() {
    Title annotation = getPackage().getAnnotation(Title.class);
    return null != annotation ? annotation.value() : null;
  }

  @Value.Immutable
  interface CodeBlock {
    io.confluent.csid.config.provider.annotations.CodeBlock codeblock();

    @Value.Derived
    default String getTitle() {
      return codeblock().title();
    }

    @Value.Derived
    default String getText() {
      return codeblock().text();
    }

    @Value.Derived
    default String getLanguage() {
      return codeblock().language();
    }
  }

  @Value.Immutable
  interface Section {
    DocumentationSection section();

    List<CodeBlock> getCodeBlocks();

    @Value.Derived
    default String getTitle() {
      return section().title();
    }

    @Value.Derived
    default String getText() {
      return section().text();
    }
  }

  List<ConfigProvider> getConfigProviders();

  @Value.Immutable
  interface ConfigProvider {
    Class<? extends org.apache.kafka.common.config.provider.ConfigProvider> configProviderClass();

    @Value.Derived
    default String getDescription() {
      Description annotation = configProviderClass().getAnnotation(Description.class);
      return null != annotation ? annotation.value() : null;
    }

    @Value.Derived
    default String getSimpleName() {
      return configProviderClass().getSimpleName();
    }

    @Value.Derived
    default String getClassName() {
      return configProviderClass().getName();
    }


    @Value.Derived
    default String getProviderKey() {
      ConfigProviderKey annotation = configProviderClass().getAnnotation(ConfigProviderKey.class);
      return null != annotation ? annotation.value() : null;
    }

    List<Section> getSections();

    Config getConfig();

    List<Example> getExamples();
  }

  @Value.Immutable
  interface Config {
    List<ConfigSection> getSections();
  }

  @Value.Immutable
  interface ConfigSection {
    String getName();

    List<ConfigItem> getConfigItems();
  }

  @Value.Immutable
  @JsonDeserialize(as = ImmutableExample.class)
  interface Example {
    @JsonProperty("title")
    String getTitle();
    @JsonProperty("description")
    String getDescription();
    @JsonProperty("providerConfig")
    Map<String, String> getProviderConfig();
    @JsonProperty("providerExample")
    @Nullable
    String getProviderExample();
  }

  @Value.Immutable
  interface ConfigItem extends Comparable<ConfigItem> {
    ConfigDef.ConfigKey configKey();

    @Value.Derived
    default String getName() {
      return configKey().name;
    }

    @Value.Derived
    default ConfigDef.Type getType() {
      return configKey().type;
    }

    @Value.Derived
    default String getDocumentation() {
      return configKey().documentation;
    }

    @Value.Derived
    default String getDefaultValue() {
      return configKey().defaultValue != null ? configKey().defaultValue.toString() : "";
    }

    @Value.Derived
    default String getValidator() {
      return configKey().validator != null ? configKey().validator.toString() : "";
    }

    @Value.Derived
    default ConfigDef.Importance getImportance() {
      return configKey().importance;
    }

    @Value.Derived
    default String getGroup() {
      return (null == configKey().group || configKey().group.isEmpty()) ? "General" : configKey().group;
    }

    @Value.Derived
    default int getOrderInGroup() {
      return configKey().orderInGroup;
    }

    @Value.Derived
    default ConfigDef.Width getWidth() {
      return configKey().width;
    }

    @Value.Derived
    default String getDisplayName() {
      return configKey().displayName;
    }

    @Value.Derived
    default List<String> getDependents() {
      return configKey().dependents;
    }

    @Value.Derived
    default String getRecommender() {
      return configKey().recommender != null ? configKey().recommender.toString() : "";
    }

    @Value.Derived
    default boolean getInternalConfig() {
      return configKey().internalConfig;
    }

    @Override
    default int compareTo(ConfigItem that) {
      if (null == that) {
        return 1;
      }
      int thisImportance;
      switch (getImportance()) {
        case LOW:
          thisImportance = 1;
          break;
        case MEDIUM:
          thisImportance = 2;
          break;
        case HIGH:
          thisImportance = 3;
          break;
        default:
          thisImportance = -1;
          break;
      }
      int thatImportance;
      switch (that.getImportance()) {
        case LOW:
          thatImportance = 1;
          break;
        case MEDIUM:
          thatImportance = 2;
          break;
        case HIGH:
          thatImportance = 3;
          break;
        default:
          thatImportance = -1;
          break;
      }

      return (Integer.compare(thisImportance, thatImportance) * 10) +
          String.CASE_INSENSITIVE_ORDER.compare(this.getName(), that.getName());
    }
  }
}
