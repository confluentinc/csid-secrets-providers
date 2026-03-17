/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

import com.cyberark.conjur.api.Conjur;
import io.confluent.csid.config.provider.common.SecretRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Collections;
import java.util.Map;

class CyberArkClientImpl implements CyberArkClient {
  private static final Logger log = LoggerFactory.getLogger(CyberArkClientImpl.class);
  private final Conjur conjur;

  public CyberArkClientImpl(CyberArkConfigProviderConfig config) {
    log.info("ctor() - creating CyberArk Conjur client for account '{}' at '{}'",
        config.account, config.url);
    System.setProperty("CONJUR_ACCOUNT", config.account);
    System.setProperty("CONJUR_APPLIANCE_URL", config.url);
    System.setProperty("CONJUR_AUTHN_LOGIN", config.username);
    System.setProperty("CONJUR_AUTHN_API_KEY", config.apiKey);
    String authnUrl = config.url + "/authn";
    this.conjur = new Conjur(config.username, config.apiKey, authnUrl);
    log.info("ctor() - authentication successful");
  }

  CyberArkClientImpl(Conjur conjur) {
    this.conjur = conjur;
  }

  @Override
  public Map<String, String> getSecret(SecretRequest request) throws Exception {
    log.debug("getSecret() - request = '{}'", request);
    String secretValue = this.conjur.variables().retrieveSecret(request.path());
    return Collections.singletonMap(request.path(), secretValue);
  }
}
