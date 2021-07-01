package io.confluent.csid.config.provider.common;

import java.util.Map;

/**
 * Interface is used to retrieve secrets from an upstream secret store;
 */
public interface SecretRetriever {
  /**
   * Method is used to retrieve secrets from an upstream secret store.
   * @param path path to the secret
   * @return Map containing all of the values for the secret. Null if secret is not found.
   */
  Map<String, String> retrieveSecret(String path);
}
