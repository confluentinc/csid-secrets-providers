/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common.docs;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target({ElementType.TYPE, ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
public @interface DocumentationSection {
  /**
   * Title of the section.
   * @return
   */
  String title();

  /**
   * Text that will be part of the section
   * @return
   */
  String text();
}