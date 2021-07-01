package io.confluent.csid.config.provider.common;

import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.Set;

import static io.confluent.csid.config.provider.common.testing.TestUtils.mapOf;
import static io.confluent.csid.config.provider.common.testing.TestUtils.setOf;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class ConfigDataHasherTests {

  @Test
  public void hash() {
    Map<String, String> input = mapOf(
        "username", "user00",
        "password", "pasdf5tsfgsdfg",
        "host", "db01.example.com",
        "port", "54321"
    );

    ConfigDataHasher.ConfigDataState value0 = ConfigDataHasher.ConfigDataState.build(input);
    ConfigDataHasher.ConfigDataState value1 = ConfigDataHasher.ConfigDataState.build(input);
    assertNotNull(value0);
    assertNotNull(value1);
    assertEquals(value0, value1);
  }


  @Test
  public void updateHash() {
    ConfigDataHasher configDataHasher = new ConfigDataHasher();
    final String path = "test";
    Set<String> value = configDataHasher.updateHash(path, mapOf(
        "username", "user00",
        "password", "pasdf5tsfgsdfg"
    ));
    assertTrue(value.isEmpty());
    value = configDataHasher.updateHash(path, mapOf(
        "username", "user01",
        "password", "pasdf5tsfgsdfg"
    ));
    assertEquals(setOf("username"), value);
    value = configDataHasher.updateHash(path, mapOf(
        "username", "user01",
        "password", "pasdf5tsfgsdfg"
    ));
    assertTrue(value.isEmpty());
    value = configDataHasher.updateHash(path, mapOf(
        "username", "user01"
    ));
    assertEquals(setOf("password"), value);
  }

}
