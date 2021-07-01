/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.vault;

import com.bettercloud.vault.Vault;
import com.bettercloud.vault.VaultException;
import com.bettercloud.vault.response.AuthResponse;
import com.bettercloud.vault.response.LookupResponse;
import org.immutables.value.Value;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Optional;

import static io.confluent.csid.config.provider.common.util.Utils.isNullOrEmpty;

abstract class AuthHandler {
  private static final Logger log = LoggerFactory.getLogger(AuthHandler.class);

  @Value.Immutable
  interface AuthResult {
    @Value.Redacted
    Optional<String> token();

    Optional<Long> ttl();

    boolean tokenRenewable();

    boolean authRenewable();
  }


  public abstract AuthMethod method();

  public abstract AuthResult execute(VaultConfigProviderConfig config, Vault vault) throws VaultException;

  protected AuthResult result(AuthResponse response) {
    log.debug(
        "result() - username = '{}' authLeaseDuration = {} renewable = {} authRenewable = {}",
        response.getUsername(),
        response.getAuthLeaseDuration(),
        response.getRenewable(),
        response.isAuthRenewable()
    );
    return ImmutableAuthResult.builder()
        .token(response.getAuthClientToken())
        .ttl(response.getAuthLeaseDuration())
        .tokenRenewable(response.getRenewable())
        .authRenewable(response.isAuthRenewable())
        .build();
  }

  protected AuthResult result(LookupResponse response) {
    log.debug(
        "result() - username = '{}' authLeaseDuration = {} renewable = {}",
        response.getUsername(),
        response.getTTL(),
        response.isRenewable()
    );
    return ImmutableAuthResult.builder()
        .token(Optional.empty())
        .ttl(response.getTTL())
        .tokenRenewable(response.isRenewable())
        .authRenewable(false)
        .build();
  }

  static class Token extends AuthHandler {

    @Override
    public AuthMethod method() {
      return AuthMethod.Token;
    }

    @Override
    public AuthResult execute(VaultConfigProviderConfig config, Vault vault) throws VaultException {
      LookupResponse lookupResponse = vault.auth().lookupSelf();
      return result(lookupResponse);
    }
  }

  static class LDAP extends AuthHandler {
    @Override
    public AuthMethod method() {
      return AuthMethod.LDAP;
    }

    @Override
    public AuthResult execute(VaultConfigProviderConfig config, Vault vault) throws VaultException {
      AuthResponse response;

      if (isNullOrEmpty(config.mount)) {
        response = vault.auth().loginByLDAP(config.username, config.password);
      } else {
        response = vault.auth().loginByLDAP(config.username, config.password, config.mount);
      }
      return result(response);
    }
  }

  static class UserPass extends AuthHandler {

    @Override
    public AuthMethod method() {
      return AuthMethod.UserPass;
    }

    @Override
    public AuthResult execute(VaultConfigProviderConfig config, Vault vault) throws VaultException {
      AuthResponse response;

      if (isNullOrEmpty(config.mount)) {
        log.trace("execute() - calling loginByUserPass('{}', '********')", config.username);
        response = vault.auth().loginByUserPass(config.username, config.password);
      } else {
        log.trace("execute() - calling loginByUserPass('{}', '********', '{}')", config.username, config.mount);
        response = vault.auth().loginByUserPass(config.username, config.password, config.mount);
      }

      return result(response);
    }
  }

  static class Certificate extends AuthHandler {

    @Override
    public AuthMethod method() {
      return AuthMethod.Certificate;
    }

    @Override
    public AuthResult execute(VaultConfigProviderConfig config, Vault vault) throws VaultException {
      AuthResponse response;

      if (isNullOrEmpty(config.mount)) {
        log.trace("execute() - calling loginByCert()");
        response = vault.auth().loginByCert();
      } else {
        log.trace("execute() - calling loginByCert('{}')", config.mount);
        response = vault.auth().loginByUserPass(config.username, config.password, config.mount);
      }

      return result(response);
    }
  }

  static class AppRole extends AuthHandler {

    @Override
    public AuthMethod method() {
      return AuthMethod.AppRole;
    }

    @Override
    public AuthResult execute(VaultConfigProviderConfig config, Vault vault) throws VaultException {
      AuthResponse response;

      if (isNullOrEmpty(config.mount)) {
        log.trace("execute() - calling loginByAppRole('{}', '*****')", config.role);
        response = vault.auth().loginByAppRole(config.role, config.secret);
      } else {
        log.trace("execute() - calling loginByUserPass('{}', ****, '{}')", config.username, config.mount);
        response = vault.auth().loginByUserPass(config.username, config.password, config.mount);
      }
      return result(response);
    }
  }
}
