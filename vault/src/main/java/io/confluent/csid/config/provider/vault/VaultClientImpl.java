/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.vault;

import com.bettercloud.vault.Vault;
import com.bettercloud.vault.VaultConfig;
import com.bettercloud.vault.VaultException;
import com.bettercloud.vault.response.LogicalResponse;
import org.apache.kafka.common.config.ConfigException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

class VaultClientImpl implements VaultClient {
  private static final Logger log = LoggerFactory.getLogger(VaultClientImpl.class);
  final AtomicReference<Vault> vaultStore = new AtomicReference<>();
  final AtomicReference<AuthHandler.AuthResult> authResultStore = new AtomicReference<>();
  final VaultConfigProviderConfig config;
  final ScheduledExecutorService executorService;





  public VaultClientImpl(VaultConfigProviderConfig config, ScheduledExecutorService executorService) {
    this.config = config;
    this.executorService = executorService;

    VaultConfig vaultConfig = config.createConfig();
    log.info("ctor() - creating initial vault client");

    AuthHandler authHandler = AuthHandlers.get(config.authMethod);
    Vault initialVault = new Vault(vaultConfig);
    AuthHandler.AuthResult result;
    try {
      result = authHandler.execute(config, initialVault);
    } catch (VaultException exception) {
      log.error("ctor() - exception thrown during initial authentication", exception);
      ConfigException configException = new ConfigException("Exception during initial authentication");
      configException.initCause(exception);
      throw configException;
    }
    log.debug("ctor() - authResult = {}", result);
    result.token().ifPresent(vaultConfig::token);
    this.vaultStore.set(initialVault);

    if (result.ttl().isPresent() && result.ttl().get() > 0) {
      if (result.authRenewable()) {
        this.executorService.schedule(() -> {

            },
            result.ttl().get(),
            TimeUnit.SECONDS
        );
      } else if (result.tokenRenewable()) {

      }
    } else {
      log.debug("ctor() - AuthResult does not have a ttl so not scheduling token refresh.");
    }
  }

  class TokenRenewer implements Runnable {
    @Override
    public void run() {

    }
  }
  static class AuthRokenRenewer implements Runnable {

    @Override
    public void run() {

    }
  }


  @Override
  public LogicalResponse read(String path) throws VaultException {
    log.debug("read() - path = '{}'", path);
    Vault vault = this.vaultStore.get();
    return vault.logical().read(path);
  }


}
