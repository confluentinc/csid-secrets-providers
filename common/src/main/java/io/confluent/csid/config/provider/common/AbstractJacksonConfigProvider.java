/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Class is provided to allow Jackson to be an optional dependency for implementations that do not need it.
 */
public abstract class AbstractJacksonConfigProvider<CONFIG extends AbstractConfigProviderConfig> extends AbstractConfigProvider<CONFIG> {
  private static final Logger log = LoggerFactory.getLogger(AbstractJacksonConfigProvider.class);
  protected ObjectMapper mapper;

  @Override
  protected void configure() {
    this.mapper = new ObjectMapper();
    this.mapper.configure(SerializationFeature.INDENT_OUTPUT, true);
  }

  protected Map<String, String> readJsonValue(ByteBuffer content) throws IOException {
    byte[] buffer = new byte[content.remaining()];
    content.get(buffer);
    try (JsonParser parser = this.mapper.createParser(buffer)) {
      return readJsonValue(parser);
    }
  }

  protected Map<String, String> readJsonValue(String content) throws IOException {
    try (JsonParser parser = this.mapper.createParser(content)) {
      return readJsonValue(parser);
    }
  }

  protected Map<String, String> readJsonValue(byte[] content) throws IOException {
    try (JsonParser parser = this.mapper.createParser(content)) {
      return readJsonValue(parser);
    }
  }

  protected Map<String, String> readJsonValue(JsonParser parser) throws IOException {
    JsonNode node = this.mapper.readValue(parser, JsonNode.class);
    if (null == node || !node.isObject()) {
      String exampleText = this.mapper.writeValueAsString(
          this.mapper.createObjectNode()
              .put("username", "username")
              .put("password", "s3cr3t")
              .put("hostname", "db01.example.com")
              .put("port", "54321")
      );

      throw new IllegalStateException(
          String.format(
              "Secret body must be a json object with string values. For example:\n%s",
              exampleText
          )
      );
    }
    Map<String, String> result = new LinkedHashMap<>();
    ObjectNode objectNode = (ObjectNode) node;

    Iterator<String> fieldNames = objectNode.fieldNames();
    while (fieldNames.hasNext()) {
      final String fieldName = fieldNames.next();
      JsonNode fieldNode = objectNode.get(fieldName);

      String fieldValue;

      if (fieldNode.isTextual()) {
        fieldValue = fieldNode.textValue();
      } else if (fieldNode.isNull()) {
        log.trace("readJsonValue() - Dropping field '{}' because value is null.", fieldName);
        continue;
      } else {
        log.warn(
            "readJsonValue() - Converting field '{}' from '{}' with .toString(). Secret values must only be strings.",
            fieldName,
            fieldNode.getNodeType()
        );
        fieldValue = fieldNode.toString();
      }
      result.put(fieldName, fieldValue);
    }


    return result;
  }
}
