/**
 *                     Copyright Confluent
 *                     Confluent Community License Agreement
 *                                 Version 1.0
 *
 * This Confluent Community License Agreement Version 1.0 (the “Agreement”) sets
 * forth the terms on which Confluent, Inc. (“Confluent”) makes available certain
 * software made available by Confluent under this Agreement (the “Software”).  BY
 * INSTALLING, DOWNLOADING, ACCESSING, USING OR DISTRIBUTING ANY OF THE SOFTWARE,
 * YOU AGREE TO THE TERMS AND CONDITIONS OF THIS AGREEMENT. IF YOU DO NOT AGREE TO
 * SUCH TERMS AND CONDITIONS, YOU MUST NOT USE THE SOFTWARE.  IF YOU ARE RECEIVING
 * THE SOFTWARE ON BEHALF OF A LEGAL ENTITY, YOU REPRESENT AND WARRANT THAT YOU
 * HAVE THE ACTUAL AUTHORITY TO AGREE TO THE TERMS AND CONDITIONS OF THIS
 * AGREEMENT ON BEHALF OF SUCH ENTITY.  “Licensee” means you, an individual, or
 * the entity on whose behalf you are receiving the Software.
 *
 *    1. LICENSE GRANT AND CONDITIONS.
 *
 *       1.1 License.  Subject to the terms and conditions of this Agreement,
 *       Confluent hereby grants to Licensee a non-exclusive, royalty-free,
 *       worldwide, non-transferable, non-sublicenseable license during the term
 *       of this Agreement to: (a) use the Software; (b) prepare modifications and
 *       derivative works of the Software; (c) distribute the Software (including
 *       without limitation in source code or object code form); and (d) reproduce
 *       copies of the Software (the “License”).  Licensee is not granted the
 *       right to, and Licensee shall not, exercise the License for an Excluded
 *       Purpose.  For purposes of this Agreement, “Excluded Purpose” means making
 *       available any software-as-a-service, platform-as-a-service,
 *       infrastructure-as-a-service or other similar online service that competes
 *       with Confluent products or services that provide the Software.
 *
 *       1.2 Conditions.  In consideration of the License, Licensee’s distribution
 *       of the Software is subject to the following conditions:
 *
 *          (a) Licensee must cause any Software modified by Licensee to carry
 *          prominent notices stating that Licensee modified the Software.
 *
 *          (b) On each Software copy, Licensee shall reproduce and not remove or
 *          alter all Confluent or third party copyright or other proprietary
 *          notices contained in the Software, and Licensee must provide the
 *          notice below with each copy.
 *
 *             “This software is made available by Confluent, Inc., under the
 *             terms of the Confluent Community License Agreement, Version 1.0
 *             located at http://www.confluent.io/confluent-community-license.  BY
 *             INSTALLING, DOWNLOADING, ACCESSING, USING OR DISTRIBUTING ANY OF
 *             THE SOFTWARE, YOU AGREE TO THE TERMS OF SUCH LICENSE AGREEMENT.”
 *
 *       1.3 Licensee Modifications.  Licensee may add its own copyright notices
 *       to modifications made by Licensee and may provide additional or different
 *       license terms and conditions for use, reproduction, or distribution of
 *       Licensee’s modifications.  While redistributing the Software or
 *       modifications thereof, Licensee may choose to offer, for a fee or free of
 *       charge, support, warranty, indemnity, or other obligations. Licensee, and
 *       not Confluent, will be responsible for any such obligations.
 *
 *       1.4 No Sublicensing.  The License does not include the right to
 *       sublicense the Software, however, each recipient to which Licensee
 *       provides the Software may exercise the Licenses so long as such recipient
 *       agrees to the terms and conditions of this Agreement.
 *
 *    2. TERM AND TERMINATION.  This Agreement will continue unless and until
 *    earlier terminated as set forth herein.  If Licensee breaches any of its
 *    conditions or obligations under this Agreement, this Agreement will
 *    terminate automatically and the License will terminate automatically and
 *    permanently.
 *
 *    3. INTELLECTUAL PROPERTY.  As between the parties, Confluent will retain all
 *    right, title, and interest in the Software, and all intellectual property
 *    rights therein.  Confluent hereby reserves all rights not expressly granted
 *    to Licensee in this Agreement.  Confluent hereby reserves all rights in its
 *    trademarks and service marks, and no licenses therein are granted in this
 *    Agreement.
 *
 *    4. DISCLAIMER.  CONFLUENT HEREBY DISCLAIMS ANY AND ALL WARRANTIES AND
 *    CONDITIONS, EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, AND SPECIFICALLY
 *    DISCLAIMS ANY WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR
 *    PURPOSE, WITH RESPECT TO THE SOFTWARE.
 *
 *    5. LIMITATION OF LIABILITY.  CONFLUENT WILL NOT BE LIABLE FOR ANY DAMAGES OF
 *    ANY KIND, INCLUDING BUT NOT LIMITED TO, LOST PROFITS OR ANY CONSEQUENTIAL,
 *    SPECIAL, INCIDENTAL, INDIRECT, OR DIRECT DAMAGES, HOWEVER CAUSED AND ON ANY
 *    THEORY OF LIABILITY, ARISING OUT OF THIS AGREEMENT.  THE FOREGOING SHALL
 *    APPLY TO THE EXTENT PERMITTED BY APPLICABLE LAW.
 *
 *    6.GENERAL.
 *
 *       6.1 Governing Law. This Agreement will be governed by and interpreted in
 *       accordance with the laws of the state of California, without reference to
 *       its conflict of laws principles.  If Licensee is located within the
 *       United States, all disputes arising out of this Agreement are subject to
 *       the exclusive jurisdiction of courts located in Santa Clara County,
 *       California. USA.  If Licensee is located outside of the United States,
 *       any dispute, controversy or claim arising out of or relating to this
 *       Agreement will be referred to and finally determined by arbitration in
 *       accordance with the JAMS International Arbitration Rules.  The tribunal
 *       will consist of one arbitrator.  The place of arbitration will be Palo
 *       Alto, California. The language to be used in the arbitral proceedings
 *       will be English.  Judgment upon the award rendered by the arbitrator may
 *       be entered in any court having jurisdiction thereof.
 *
 *       6.2 Assignment.  Licensee is not authorized to assign its rights under
 *       this Agreement to any third party. Confluent may freely assign its rights
 *       under this Agreement to any third party.
 *
 *       6.3 Other.  This Agreement is the entire agreement between the parties
 *       regarding the subject matter hereof.  No amendment or modification of
 *       this Agreement will be valid or binding upon the parties unless made in
 *       writing and signed by the duly authorized representatives of both
 *       parties.  In the event that any provision, including without limitation
 *       any condition, of this Agreement is held to be unenforceable, this
 *       Agreement and all licenses and rights granted hereunder will immediately
 *       terminate.  Waiver by Confluent of a breach of any provision of this
 *       Agreement or the failure by Confluent to exercise any right hereunder
 *       will not be construed as a waiver of any subsequent breach of that right
 *       or as a waiver of any other right.
 */
package io.confluent.csid.config.provider.azure;

import com.azure.core.credential.TokenCredential;
import com.azure.core.http.HttpClient;
import com.azure.core.http.okhttp.OkHttpAsyncHttpClientBuilder;
import com.azure.identity.ClientCertificateCredentialBuilder;
import com.azure.identity.ClientSecretCredentialBuilder;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.identity.UsernamePasswordCredentialBuilder;
import io.confluent.csid.config.provider.common.AbstractConfigProviderConfig;
import io.confluent.csid.config.provider.common.config.ConfigKeyBuilder;
import io.confluent.csid.config.provider.common.config.ConfigUtils;
import io.confluent.csid.config.provider.common.config.Recommenders;
import io.confluent.csid.config.provider.common.config.Validators;
import io.confluent.csid.config.provider.annotations.Description;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.ConfigException;
import org.apache.kafka.common.config.types.Password;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;

public class KeyVaultConfigProviderConfig extends AbstractConfigProviderConfig {
  private static final Logger log = LoggerFactory.getLogger(KeyVaultConfigProviderConfig.class);
  public static final String PREFIX_CONFIG = "secret.prefix";
  static final String PREFIX_DOC = "Sets a prefix that will be added to all paths. For example you can use `staging` or `production` " +
      "and all of the calls to Secrets Manager will be prefixed with that path. This allows the same configuration settings to be used across " +
      "multiple environments.";

  public static final String CREDENTIAL_TYPE_CONFIG = "credential.type";
  public static final String CREDENTIAL_TYPE_DOC = "The type of credentials to use. " + ConfigUtils.enumDescription(CredentialLocation.class);

  public static final String CERTIFICATE_PATH_CONFIG = "client.certificate.path";
  public static final String CERTIFICATE_PATH_DOC = "Location on the local filesystem for the client certificate that will be used to authenticate to Azure.";

  public static final String CERTIFICATE_TYPE_CONFIG = "client.certificate.type";
  public static final String CERTIFICATE_TYPE_DOC = "The type of encoding used on the file specified in `" + CERTIFICATE_PATH_CONFIG + "`. " + ConfigUtils.enumDescription(ClientCertificateType.class);

  public static final String CERTIFICATE_PFX_PASSWORD_CONFIG = "client.certificate.pfx.password";
  public static final String CERTIFICATE_PFX_PASSWORD_DOC = "The password protecting the PFX file.";

  public static final String CERTIFICATE_SEND_CHAIN_CONFIG = "client.certificate.send.certificate.chain.enabled";
  public static final String CERTIFICATE_SEND_CHAIN_DOC = "Flag to indicate if certificate chain should be sent as part of authentication request.";

  public static final String CLIENT_ID_CONFIG = "client.id";
  public static final String CLIENT_ID_DOC = "The client ID of the application.";

  public static final String CLIENT_SECRET_CONFIG = "client.secret";
  public static final String CLIENT_SECRET_DOC = "The client secret for the authentication.";

  public static final String USERNAME_CONF = "username";
  public static final String USERNAME_DOC = "The username to authenticate with.";

  public static final String PASSWORD_CONF = "password";
  public static final String PASSWORD_DOC = "The password to authenticate with.";

  public static final String TENANT_ID_CONFIG = "tenant.id";
  public static final String TENANT_ID_DOC = "The tenant ID of the application.";

  public static final String VAULT_URL_CONFIG = "vault.url";
  public static final String VAULT_URL_DOC = "The vault url to connect to. For example `https://example.vault.azure.net/`";


  public final String prefix;
  public final CredentialLocation credentialLocation;
  public final String clientId;
  public final String tenantId;
  public final String vaultUrl;
  public final HttpClient httpClient;

  public KeyVaultConfigProviderConfig(Map<String, ?> settings) {
    super(config(), settings);
    this.prefix = getString(PREFIX_CONFIG);
    this.credentialLocation = ConfigUtils.getEnum(CredentialLocation.class, this, CREDENTIAL_TYPE_CONFIG);
    this.clientId = getString(CLIENT_ID_CONFIG);
    this.tenantId = getString(TENANT_ID_CONFIG);
    this.vaultUrl = getString(VAULT_URL_CONFIG);
    this.httpClient = new OkHttpAsyncHttpClientBuilder()
        .build();
  }

  static final String GROUP_CLIENT_CERTIFICATE = "Client Certificate";
  static final String GROUP_CLIENT_SECRET = "Client Secret";
  static final String GROUP_CLIENT_USERNAME = "Username and Password";

  public static ConfigDef config() {
    return AbstractConfigProviderConfig.config()
        .define(
            ConfigKeyBuilder.of(VAULT_URL_CONFIG, ConfigDef.Type.STRING)
                .documentation(VAULT_URL_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .build()
        )
        .define(
            ConfigKeyBuilder.of(CREDENTIAL_TYPE_CONFIG, ConfigDef.Type.STRING)
                .documentation(CREDENTIAL_TYPE_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue(CredentialLocation.DefaultAzure.name())
                .validator(Validators.validEnum(CredentialLocation.class))
                .build()
        )
        .define(
            ConfigKeyBuilder.of(CLIENT_ID_CONFIG, ConfigDef.Type.STRING)
                .documentation(CLIENT_ID_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        )
        .define(
            ConfigKeyBuilder.of(TENANT_ID_CONFIG, ConfigDef.Type.STRING)
                .documentation(TENANT_ID_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        )


        //Client Certificate
        .define(
            ConfigKeyBuilder.of(CERTIFICATE_PATH_CONFIG, ConfigDef.Type.STRING)
                .documentation(CERTIFICATE_PATH_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .group(GROUP_CLIENT_CERTIFICATE)
                .defaultValue("")
                .recommender(Recommenders.visibleIf(CREDENTIAL_TYPE_CONFIG, CredentialLocation.ClientCertificate.name()))
                .build()
        ).define(
            ConfigKeyBuilder.of(CERTIFICATE_TYPE_CONFIG, ConfigDef.Type.STRING)
                .documentation(CERTIFICATE_TYPE_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .group(GROUP_CLIENT_CERTIFICATE)
                .defaultValue(ClientCertificateType.PEM.name())
                .recommender(Recommenders.visibleIf(CREDENTIAL_TYPE_CONFIG, CredentialLocation.ClientCertificate.name()))
                .validator(Validators.validEnum(ClientCertificateType.class))
                .build()
        ).define(
            ConfigKeyBuilder.of(CERTIFICATE_SEND_CHAIN_CONFIG, ConfigDef.Type.BOOLEAN)
                .documentation(CERTIFICATE_SEND_CHAIN_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .group(GROUP_CLIENT_CERTIFICATE)
                .defaultValue(false)
                .recommender(Recommenders.visibleIf(CREDENTIAL_TYPE_CONFIG, CredentialLocation.ClientCertificate.name()))
                .build()
        ).define(
            ConfigKeyBuilder.of(CERTIFICATE_PFX_PASSWORD_CONFIG, ConfigDef.Type.PASSWORD)
                .documentation(CERTIFICATE_PFX_PASSWORD_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .group(GROUP_CLIENT_CERTIFICATE)
                .defaultValue("")
                .recommender(Recommenders.visibleIf(CREDENTIAL_TYPE_CONFIG, CredentialLocation.ClientCertificate.name()))
                .build()
        )
        //Client Secret
        .define(
            ConfigKeyBuilder.of(CLIENT_SECRET_CONFIG, ConfigDef.Type.PASSWORD)
                .documentation(CLIENT_SECRET_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .group(GROUP_CLIENT_SECRET)
                .defaultValue("")
                .recommender(Recommenders.visibleIf(CREDENTIAL_TYPE_CONFIG, CredentialLocation.ClientSecret.name()))
                .build()
        )
        //Username and password
        .define(
            ConfigKeyBuilder.of(USERNAME_CONF, ConfigDef.Type.STRING)
                .documentation(USERNAME_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .group(GROUP_CLIENT_USERNAME)
                .defaultValue("")
                .recommender(Recommenders.visibleIf(CREDENTIAL_TYPE_CONFIG, CredentialLocation.UsernamePassword.name()))
                .build()
        ).define(
            ConfigKeyBuilder.of(PASSWORD_CONF, ConfigDef.Type.PASSWORD)
                .documentation(PASSWORD_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .group(GROUP_CLIENT_USERNAME)
                .defaultValue("")
                .recommender(Recommenders.visibleIf(CREDENTIAL_TYPE_CONFIG, CredentialLocation.UsernamePassword.name()))
                .build()
        )

        .define(
            ConfigKeyBuilder.of(PREFIX_CONFIG, ConfigDef.Type.STRING)
                .documentation(PREFIX_DOC)
                .importance(ConfigDef.Importance.LOW)
                .defaultValue("")
                .build()
        );
  }

  public enum CredentialLocation {
    @Description("Uses the DefaultAzureCredential.")
    DefaultAzure,
    @Description("Uses the ClientSecretCredential.")
    ClientSecret,
    @Description("Uses the ClientCertificateCredential.")
    ClientCertificate,
    @Description("Uses the UsernamePasswordCredential.")
    UsernamePassword
  }

  public enum ClientCertificateType {
    @Description("Certificate is formatted using PEM encoding.")
    PEM,
    @Description("Certificate is formatted using PFX encoding. `" + CERTIFICATE_PFX_PASSWORD_CONFIG + "` is required.")
    PFX
  }

  String getRequiredString(String name) {
    String result = getString(name);

    if (result == null || result.isEmpty()) {
      throw new ConfigException(name, result, "Cannot be null or blank.");
    }

    return result;
  }


  public TokenCredential buildCredential() {
    TokenCredential result;


    switch (credentialLocation) {
      case DefaultAzure:
        log.info("Building DefaultAzureCredential");
        result = new DefaultAzureCredentialBuilder()
            .httpClient(this.httpClient)
            .build();
        break;
      case ClientSecret:
        Password clientSecretPassword = getPassword(CLIENT_SECRET_CONFIG);
        log.info("Building ClientSecretCredential");
        result = new ClientSecretCredentialBuilder()
            .tenantId(this.tenantId)
            .clientId(this.clientId)
            .clientSecret(clientSecretPassword.value())
            .build();
        break;
      case ClientCertificate:
        ClientCertificateType certificateType = ConfigUtils.getEnum(ClientCertificateType.class, this, CERTIFICATE_TYPE_CONFIG);
        String clientCertificatePath = getRequiredString(CERTIFICATE_PATH_CONFIG);
        log.info("Loading client certificate '{}'", clientCertificatePath);
        ClientCertificateCredentialBuilder clientCertificateCredentialBuilder = new ClientCertificateCredentialBuilder()
            .sendCertificateChain(getBoolean(CERTIFICATE_SEND_CHAIN_CONFIG))
            .tenantId(this.tenantId)
            .clientId(this.clientId);
        switch (certificateType) {
          case PEM:
            log.info("Setting pemCertificate to {}", clientCertificatePath);
            clientCertificateCredentialBuilder.pemCertificate(clientCertificatePath);
            break;
          case PFX:
            log.info("Setting pfxCertificate to {}", clientCertificatePath);
            Password clientCertificatePassword = getPassword(CERTIFICATE_PFX_PASSWORD_CONFIG);
            clientCertificateCredentialBuilder.pfxCertificate(clientCertificatePath, clientCertificatePassword.value());
            break;
          default:
            throw new ConfigException(CERTIFICATE_TYPE_CONFIG, certificateType, "Unsupported ClientCertificateType");
        }
        log.info("Building ClientCertificateCredential");
        result = clientCertificateCredentialBuilder.build();
        break;
      case UsernamePassword:
        String username = getRequiredString(USERNAME_CONF);
        Password password = getPassword(PASSWORD_CONF);
        result = new UsernamePasswordCredentialBuilder()
            .tenantId(this.tenantId)
            .clientId(this.clientId)
            .username(username)
            .password(password.value())
            .build();
        break;
      default:
        throw new ConfigException(CREDENTIAL_TYPE_CONFIG, credentialLocation, "Unsupported ConfigLocation");
    }
    log.info("Credential Type = {}", result.getClass().getName());
    return result;
  }

}
