/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common.testing;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import io.confluent.csid.config.provider.annotations.DocumentationSections;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.provider.ConfigProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.AbstractMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class PluginFactory {
  private static final Logger log = LoggerFactory.getLogger(PluginFactory.class);
  static ObjectMapper mapper = new ObjectMapper(new YAMLFactory());

  public static Plugin create(List<Class<? extends ConfigProvider>> providers) throws InstantiationException, IllegalAccessException, NoSuchMethodException, InvocationTargetException, URISyntaxException, IOException {
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

      Map<Path, Plugin.Example> examples = loadExamples(configProviderClass);
      if (!examples.isEmpty()) {
        configProviderBuilder.addAllExamples(examples.values());
      }
      pluginBuilder.addConfigProviders(configProviderBuilder.build());
    }

    return pluginBuilder.build();
  }

  public static Map<Path, Plugin.Example> loadExamples(Class<? extends ConfigProvider> configProviderClass) throws URISyntaxException, IOException {
    URL uri = configProviderClass.getResource(configProviderClass.getSimpleName());
    Map<Path, Plugin.Example> examples = new LinkedHashMap<>();
    if (null != uri) {
      Path path = Paths.get(uri.toURI());
      if (Files.exists(path)) {
        examples = Files.walk(path).filter(Files::isRegularFile)
            .map(p -> {
              try {
                return new AbstractMap.SimpleEntry<>(
                    p,
                    mapper.readValue(p.toFile(), Plugin.Example.class)
                );
              } catch (IOException e) {
                throw new IllegalStateException(
                    String.format("Exception thrown reading %s", p),
                    e
                );
              }
            }).collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
      }
    }
    return examples;
  }


  public static ConfigDef getConfigFromProvider(Class<? extends ConfigProvider> configProviderClass) throws InstantiationException, IllegalAccessException, NoSuchMethodException, InvocationTargetException {
    ConfigProvider configProvider = configProviderClass.newInstance();
    Method configMethod = configProviderClass.getMethod("config");
    ConfigDef config = (ConfigDef) configMethod.invoke(configProvider);
    return config;
  }
}
