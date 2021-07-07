/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.vault;

import com.bettercloud.vault.VaultException;
import com.bettercloud.vault.response.LogicalResponse;
import io.confluent.csid.config.provider.common.AbstractConfigProvider;
import io.confluent.csid.config.provider.common.RetriableException;
import io.confluent.csid.config.provider.common.SecretRequest;
import org.apache.kafka.common.config.ConfigDef;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

public class VaultConfigProvider extends AbstractConfigProvider<VaultConfigProviderConfig> {
  private static final Logger log = LoggerFactory.getLogger(VaultConfigProvider.class);

  VaultClientFactory vaultClientFactory = new VaultClientFactoryImpl();
  VaultClient vaultClient;

  @Override
  protected VaultConfigProviderConfig config(Map<String, ?> settings) {
    return new VaultConfigProviderConfig(settings);
  }

  @Override
  protected void configure() {
    this.vaultClient = this.vaultClientFactory.create(this.config, this.executorService);
  }

  /**
   * Status codes that are retriable
   */
  private static final Set<Integer> RETRIABLE = Collections.unmodifiableSet(
      new LinkedHashSet<>(Arrays.asList(500, 502, 503))
  );

  @Override
  protected Map<String, String> getSecret(SecretRequest request) throws Exception {
    log.info("getSecret() - request = '{}'", request);
    try {
      LogicalResponse response = this.vaultClient.read(request);
      return response.getData();
    } catch (VaultException ex) {
      if (RETRIABLE.contains(ex.getHttpStatusCode())) {
        throw new RetriableException("Exception reading vault", ex);
      } else {
        throw ex;
      }
    }
  }

  @Override
  public ConfigDef config() {
    return VaultConfigProviderConfig.config();
  }
}
