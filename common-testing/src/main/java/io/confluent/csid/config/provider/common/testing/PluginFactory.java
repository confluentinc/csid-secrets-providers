/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common.testing;

import io.confluent.csid.config.provider.annotations.DocumentationSections;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.provider.ConfigProvider;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class PluginFactory {
  public static Plugin create(List<Class<? extends ConfigProvider>> providers) throws InstantiationException, IllegalAccessException, NoSuchMethodException, InvocationTargetException {
    Set<Package> packages = providers.stream().map(Class::getPackage)
        .collect(Collectors.toSet());
    if (packages.size() > 1) {
      throw new IllegalStateException("Only one package is supported.");
    }
    Optional<Package> pkg = packages.stream().findFirst();
    if (!pkg.isPresent()) {
      throw new IllegalStateException("No packages found.");
    }
    ImmutablePlugin.Builder pluginBuilder = ImmutablePlugin.builder()
        .getPackage(pkg.get());

    for (Class<? extends ConfigProvider> configProviderClass : providers) {
      ImmutableConfigProvider.Builder configProviderBuilder = ImmutableConfigProvider.builder()
          .configProviderClass(configProviderClass);

      DocumentationSections documentationSections = configProviderClass.getAnnotation(DocumentationSections.class);

      if (null != documentationSections) {
        Stream.of(documentationSections.sections()).map(documentationSection -> {
          ImmutableSection.Builder sectionBuilder = ImmutableSection.builder()
              .section(documentationSection);
          Stream.of(documentationSection.codeblocks()).map(codeBlock -> ImmutableCodeBlock.builder()
              .codeblock(codeBlock)
              .build()).forEach(sectionBuilder::addCodeBlocks);
          return sectionBuilder.build();
        }).forEach(configProviderBuilder::addSections);
      }

      ConfigDef config = getConfigFromProvider(configProviderClass);

      Map<String, List<Plugin.ConfigItem>> configItemsByGroup =
          config.configKeys().values().stream()
              .map(configKey -> ImmutableConfigItem.builder().configKey(configKey).build())
              .collect(Collectors.groupingBy(Plugin.ConfigItem::getGroup));

      ImmutableConfig.Builder configBuilder = ImmutableConfig.builder();
      configItemsByGroup.forEach((name, configItems) -> configBuilder.addSections(
          ImmutableConfigSection.builder()
              .name(name)
              .configItems(configItems.stream().sorted().collect(Collectors.toList()))
              .build()
      ));
      configProviderBuilder.config(configBuilder.build());
      pluginBuilder.addConfigProviders(configProviderBuilder.build());
    }


    return pluginBuilder.build();
  }

  public static ConfigDef getConfigFromProvider(Class<? extends ConfigProvider> configProviderClass) throws InstantiationException, IllegalAccessException, NoSuchMethodException, InvocationTargetException {
    ConfigProvider configProvider = configProviderClass.newInstance();
    Method configMethod = configProviderClass.getMethod("config");
    ConfigDef config = (ConfigDef) configMethod.invoke(configProvider);
    return config;
  }
}
