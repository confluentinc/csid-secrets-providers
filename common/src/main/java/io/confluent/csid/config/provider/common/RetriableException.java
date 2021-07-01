package io.confluent.csid.config.provider.common;

public class RetriableException extends org.apache.kafka.common.errors.RetriableException {
  public RetriableException(String message, Throwable cause) {
    super(message, cause);
  }

  public RetriableException(String message) {
    super(message);
  }

  public RetriableException(Throwable cause) {
    super(cause);
  }
}
