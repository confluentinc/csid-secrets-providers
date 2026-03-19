/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.cyberark;

import com.cyberark.conjur.api.Credentials;
import com.cyberark.conjur.api.Endpoints;
import com.cyberark.conjur.api.clients.ResourceClient;
import io.confluent.csid.config.provider.common.SecretRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.util.Collections;
import java.util.Map;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

class CyberArkClientImpl implements CyberArkClient {
  private static final Logger log = LoggerFactory.getLogger(CyberArkClientImpl.class);
  private final ResourceClient resourceClient;

  public CyberArkClientImpl(CyberArkConfigProviderConfig config) {
    log.info("ctor() - creating CyberArk Conjur client for account '{}' at '{}'",
        config.account, config.url);
    String authnUrl = config.url + "/authn";
    Credentials credentials = new Credentials(config.username, config.apiKey, authnUrl);
    String authnUri = authnUrl + "/" + config.account;
    String secretsUri = config.url + "/secrets/" + config.account + "/variable";
    Endpoints endpoints = new Endpoints(authnUri, secretsUri);
    if (!config.sslVerifyEnabled) {
      log.warn("SSL verification is disabled. This should only be used in development/test environments.");
      SSLContext sslContext = createTrustAllSslContext();
      this.resourceClient = new ResourceClient(credentials, endpoints, sslContext);
    } else {
      this.resourceClient = new ResourceClient(credentials, endpoints);
    }
    log.info("ctor() - authentication successful");
  }

  private static SSLContext createTrustAllSslContext() {
    try {
      TrustManager[] trustAllCerts = new TrustManager[]{
          new X509TrustManager() {
            public X509Certificate[] getAcceptedIssuers() {
              return new X509Certificate[0];
            }

            public void checkClientTrusted(X509Certificate[] certs, String authType) {
            }

            public void checkServerTrusted(X509Certificate[] certs, String authType) {
            }
          }
      };
      SSLContext sslContext = SSLContext.getInstance("TLS");
      sslContext.init(null, trustAllCerts, new SecureRandom());
      return sslContext;
    } catch (NoSuchAlgorithmException | KeyManagementException e) {
      throw new RuntimeException("Failed to create trust-all SSL context", e);
    }
  }

  CyberArkClientImpl(ResourceClient resourceClient) {
    this.resourceClient = resourceClient;
  }

  @Override
  public Map<String, String> getSecret(SecretRequest request) throws Exception {
    log.debug("getSecret() - request = '{}'", request);
    String secretValue = this.resourceClient.retrieveSecret(request.path());
    return Collections.singletonMap(request.path(), secretValue);
  }
}
