/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.annotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface CodeBlock {
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

  /**
   * Language for the code block
   * @return
   */
  String language();
}