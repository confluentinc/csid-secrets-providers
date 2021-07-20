/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common.testing;

import freemarker.cache.ClassTemplateLoader;
import freemarker.ext.beans.BeansWrapper;
import freemarker.template.Configuration;
import freemarker.template.Template;
import freemarker.template.TemplateException;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.provider.ConfigProvider;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.Writer;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.DynamicTest.dynamicTest;

public abstract class AbstractDocumentationTest {
  private static final Logger log = LoggerFactory.getLogger(AbstractDocumentationTest.class);

  protected abstract List<Class<? extends ConfigProvider>> providers();

  /**
   * Test is used to ensure that the META-INF/services file is properly formatted.
   *
   * @return
   * @throws IOException
   */
  @TestFactory
  public Stream<DynamicTest> metaInfServices() throws IOException {
    Set<String> providers = new LinkedHashSet<>();

    String input = "/META-INF/services/org.apache.kafka.common.config.provider.ConfigProvider";
    try (InputStream inputStream = this.getClass().getResourceAsStream(input)) {
      assertNotNull(inputStream, "could not find " + input);
      try (Reader reader = new InputStreamReader(inputStream)) {
        try (LineNumberReader lineNumberReader = new LineNumberReader(reader)) {
          String line;
          while (null != (line = lineNumberReader.readLine())) {
            providers.add(line);
          }
        }
      }
    }
    return providers().stream()
        .map(c -> dynamicTest(c.getName(), () -> {
          assertTrue(
              providers.contains(c.getName()),
              String.format("%s is missing from %s", c.getName(), input)
          );
        }));
  }

  static Configuration configuration;

  @BeforeAll
  public static void before() {
    ClassTemplateLoader loader = new ClassTemplateLoader(
        AbstractDocumentationTest.class,
        "templates"
    );
    configuration = new Configuration(Configuration.getVersion());
    configuration.setDefaultEncoding("UTF-8");
    configuration.setTemplateLoader(loader);
    configuration.setObjectWrapper(new BeansWrapper(Configuration.getVersion()));
    configuration.setNumberFormat("computer");
//    configuration.setBooleanFormat("computer");
  }

  void process(Writer writer, Template template, Object input) throws IOException, TemplateException {
    Map<String, Object> variables = new LinkedHashMap<>();
    variables.put("input", input);
    template.process(variables, writer);
  }

  private void write(File outputFile, Object input, String templateName) throws IOException, TemplateException {
    Template template = configuration.getTemplate(templateName);
    log.info("Writing {}", outputFile);
    try (OutputStream outputStream = new FileOutputStream(outputFile)) {
      try (Writer writer = new OutputStreamWriter(outputStream)) {
        process(writer, template, input);
      }
    }
  }

  @TestFactory
  public List<DynamicTest> documentationCannotEqualKey() throws InvocationTargetException, InstantiationException, IllegalAccessException, NoSuchMethodException {
    List<DynamicTest> tests = new ArrayList<>();
    for (Class<? extends ConfigProvider> configProviderClass : providers()) {
      ConfigDef configDef = PluginFactory.getConfigFromProvider(configProviderClass);
      for (ConfigDef.ConfigKey key : configDef.configKeys().values()) {
        tests.add(
            dynamicTest(String.format("%s/%s", configProviderClass.getSimpleName(), key.name), () -> {
              assertNotEquals(key.name.trim(), key.documentation.trim(), "name and documentation should not match.");
            })
        );
      }
    }
    return tests;
  }


  @Test
  public void readmeMD() throws Exception {
    Plugin plugin = PluginFactory.create(providers());
    log.info("plugin: {}", plugin);
    File outputFile = new File("target/README.md");
    write(outputFile, plugin, "README.md.ftl");
  }


}
