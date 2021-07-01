package io.confluent.csid.config.provider.common.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class UtilsTests {
  @Test
  public void isNullOrEmpty() {
    assertTrue(Utils.isNullOrEmpty(""));
    assertTrue(Utils.isNullOrEmpty(null));
    assertFalse(Utils.isNullOrEmpty("test"));
  }
}
