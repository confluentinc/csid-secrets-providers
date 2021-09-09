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
package io.confluent.csid.config.provider.vault;


import com.bettercloud.vault.EnvironmentLoader;
import com.bettercloud.vault.SslConfig;
import com.bettercloud.vault.VaultConfig;
import com.bettercloud.vault.VaultException;
import io.confluent.csid.config.provider.common.AbstractConfigProviderConfig;
import io.confluent.csid.config.provider.common.config.ConfigKeyBuilder;
import io.confluent.csid.config.provider.common.config.ConfigUtils;
import io.confluent.csid.config.provider.common.config.Validators;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.ConfigException;
import org.apache.kafka.common.config.types.Password;

import java.util.Map;
import java.util.Objects;

import static io.confluent.csid.config.provider.common.config.ConfigUtils.getEnum;
import static io.confluent.csid.config.provider.common.util.Utils.isNullOrEmpty;

class VaultConfigProviderConfig extends AbstractConfigProviderConfig {
  public static final String ADDRESS_CONFIG = "vault.address";
  static final String ADDRESS_DOC = "Sets the address (URL) of the Vault server instance to which API calls should be sent. " +
      "If no address is explicitly set, the object will look to the `VAULT_ADDR` If you do not supply it explicitly AND no " +
      "environment variable value is found, then initialization may fail.";

  public static final String NAMESPACE_CONFIG = "vault.namespace";
  static final String NAMESPACE_DOC = "Sets a global namespace to the Vault server instance, if desired.";
  public static final String TOKEN_CONFIG = "vault.auth.token";
  static final String TOKEN_DOC = "Sets the token used to access Vault. If no token is explicitly set " +
      "then the `VAULT_TOKEN` environment variable will be used. ";

  public static final String AUTH_METHOD_CONFIG = "vault.auth.method";
  static final String AUTH_METHOD_DOC = "The login method to use. " + ConfigUtils.enumDescription(AuthMethod.class);

  public static final String SSL_VERIFY_ENABLED_CONFIG = "vault.ssl.verify.enabled";
  static final String SSL_VERIFY_ENABLED_DOC = "Flag to determine if the configProvider should verify the SSL Certificate " +
      "of the Vault server. Outside of development this should never be enabled.";

  public static final String USERNAME_CONFIG = "vault.auth.username";
  static final String USERNAME_DOC = "The username to authenticate with.";
  public static final String PASSWORD_CONFIG = "vault.auth.password";
  static final String PASSWORD_DOC = "The password to authenticate with.";

  public static final String MOUNT_CONFIG = "vault.auth.mount";
  static final String MOUNT_DOC = "Location of the mount to use for authentication.";

  public static final String ROLE_CONFIG = "vault.auth.role";
  static final String ROLE_DOC = "The role to use for authentication.";
  public static final String SECRET_CONFIG = "vault.auth.secret";
  static final String SECRET_DOC = "The secret to use for authentication.";

  public final boolean sslVerifyEnabled;
  public final AuthMethod authMethod;

  public final String username;
  public final String password;
  public final String mount;

  public final String role;
  public final String secret;

  void checkNotDefault(String item) {
    ConfigDef config = config();
    Object currentValue = get(item);
    ConfigDef.ConfigKey configKey = config.configKeys().get(item);
    if (Objects.equals(configKey.defaultValue, currentValue)) {
      throw new ConfigException(
          item,
          currentValue,
          "Value must be specified"
      );
    }
  }

  public VaultConfigProviderConfig(Map<?, ?> originals) {
    super(config(), originals);
    this.sslVerifyEnabled = getBoolean(SSL_VERIFY_ENABLED_CONFIG);
    this.authMethod = getEnum(AuthMethod.class, this, AUTH_METHOD_CONFIG);
    this.username = getString(USERNAME_CONFIG);
    this.password = getPassword(PASSWORD_CONFIG).value();
    this.mount = getString(MOUNT_CONFIG);
    this.role = getString(ROLE_CONFIG);
    this.secret = getPassword(SECRET_CONFIG).value();

    switch (this.authMethod) {
      case LDAP:
      case UserPass:
        checkNotDefault(USERNAME_CONFIG);
        checkNotDefault(PASSWORD_CONFIG);
        break;
      case AppRole:
        checkNotDefault(ROLE_CONFIG);
        checkNotDefault(SECRET_CONFIG);
        break;
      default:
    }

  }

  public static ConfigDef config() {
    return AbstractConfigProviderConfig.config()
        .define(
            ConfigKeyBuilder.of(ADDRESS_CONFIG, ConfigDef.Type.STRING)
                .documentation(ADDRESS_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        )
        .define(
            ConfigKeyBuilder.of(AUTH_METHOD_CONFIG, ConfigDef.Type.STRING)
                .documentation(AUTH_METHOD_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue(AuthMethod.Token.name())
                .validator(Validators.validEnum(AuthMethod.class))
                .build()
        )

        .define(
            ConfigKeyBuilder.of(TOKEN_CONFIG, ConfigDef.Type.PASSWORD)
                .documentation(TOKEN_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        )
        .define(
            ConfigKeyBuilder.of(NAMESPACE_CONFIG, ConfigDef.Type.STRING)
                .documentation(NAMESPACE_DOC)
                .importance(ConfigDef.Importance.LOW)
                .defaultValue("")
                .build()
        )
        .define(
            ConfigKeyBuilder.of(SSL_VERIFY_ENABLED_CONFIG, ConfigDef.Type.BOOLEAN)
                .documentation(SSL_VERIFY_ENABLED_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue(true)
                .build()
        ).define(
            ConfigKeyBuilder.of(USERNAME_CONFIG, ConfigDef.Type.STRING)
                .documentation(USERNAME_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(PASSWORD_CONFIG, ConfigDef.Type.PASSWORD)
                .documentation(PASSWORD_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(MOUNT_CONFIG, ConfigDef.Type.STRING)
                .documentation(MOUNT_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(ROLE_CONFIG, ConfigDef.Type.STRING)
                .documentation(ROLE_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        ).define(
            ConfigKeyBuilder.of(SECRET_CONFIG, ConfigDef.Type.PASSWORD)
                .documentation(SECRET_DOC)
                .importance(ConfigDef.Importance.HIGH)
                .defaultValue("")
                .build()
        );
  }

  public VaultConfig createConfig() {
    return createConfig(null);
  }

  /**
   * Method is used to create a VaultConfig.
   *
   * @param environmentLoader Used for configuration testing. Null most of the time
   * @return
   */
  VaultConfig createConfig(EnvironmentLoader environmentLoader) {
    SslConfig sslConfig = new SslConfig()
        .verify(this.sslVerifyEnabled);

    VaultConfig result = new VaultConfig();
    if (null != environmentLoader) {
      result = result.environmentLoader(environmentLoader);
    }

    try {
      result = result.sslConfig(sslConfig.build());
    } catch (VaultException e) {
      ConfigException configException = new ConfigException("Exception thrown while configuring ssl");
      configException.initCause(e);
      throw configException;
    }

    String address = getString(ADDRESS_CONFIG);
    if (!isNullOrEmpty(address)) {
      result = result.address(address);
    }
    Password token = getPassword(TOKEN_CONFIG);
    if (!isNullOrEmpty(token.value())) {
      result = result.token(token.value());
    }
    String namespace = getString(NAMESPACE_CONFIG);
    if (!isNullOrEmpty(namespace)) {
      try {
        result = result.nameSpace(namespace);
      } catch (VaultException e) {
        ConfigException configException = new ConfigException(NAMESPACE_CONFIG, namespace, "Exception thrown setting namespace");
        configException.initCause(e);
        throw configException;
      }
    }

    try {
      result = result.build();
    } catch (VaultException e) {
      ConfigException configException = new ConfigException("Exception thrown while configuring vault");
      configException.initCause(e);
      throw configException;
    }

    return result;
  }
}
