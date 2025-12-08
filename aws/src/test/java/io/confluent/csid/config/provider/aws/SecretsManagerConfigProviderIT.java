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
package io.confluent.csid.config.provider.aws;

import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableSet;
import io.confluent.csid.config.provider.common.ImmutablePutSecretRequest;
import io.confluent.csid.config.provider.common.ImmutableSecretRequest;
import io.confluent.csid.config.provider.common.PutSecretRequest;
import io.confluent.csid.config.provider.common.SecretRequest;
import org.apache.kafka.common.config.ConfigData;
import org.apache.kafka.common.config.ConfigException;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.Network;
import org.testcontainers.containers.localstack.LocalStackContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.utility.DockerImageName;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.*;

import java.io.IOException;
import java.nio.charset.Charset;
import java.util.Map;

import static io.confluent.csid.config.provider.aws.SecretsManagerConfigProviderConfig.AWS_ACCESS_KEY_ID_CONFIG;
import static io.confluent.csid.config.provider.aws.SecretsManagerConfigProviderConfig.AWS_SECRET_KEY_CONFIG;
import static io.confluent.csid.config.provider.aws.SecretsManagerConfigProviderConfig.ENDPOINT_OVERRIDE;
import static io.confluent.csid.config.provider.aws.SecretsManagerConfigProviderConfig.PREFIX_CONFIG;
import static io.confluent.csid.config.provider.aws.SecretsManagerConfigProviderConfig.REGION_CONFIG;
import static io.confluent.csid.config.provider.aws.SecretsManagerConfigProviderConfig.USE_JSON_CONFIG;
import static org.junit.Assert.assertThrows;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

public class SecretsManagerConfigProviderIT {

  private static final Network network = Network.newNetwork();

  @Container
  public static LocalStackContainer localstack = new LocalStackContainer(DockerImageName.parse("localstack/localstack:3.2.0"))
          .withNetwork(network)
          .withNetworkAliases("localstack")
          .withServices(LocalStackContainer.Service.SECRETSMANAGER);
  private static SecretsManagerConfigProvider provider;

  @BeforeAll
  public static void setUp() {
    localstack.start();
    provider = new SecretsManagerConfigProvider();
  }

  private static void configureProvider(boolean useJsonConfig) {
    provider.configure(ImmutableMap.of(ENDPOINT_OVERRIDE, localstack.getEndpoint().toString(),
            REGION_CONFIG, localstack.getRegion(),
            AWS_ACCESS_KEY_ID_CONFIG, localstack.getAccessKey(),
            AWS_SECRET_KEY_CONFIG, localstack.getSecretKey(),
            USE_JSON_CONFIG, useJsonConfig));
  }

  @AfterAll
  public static void afterAll() throws IOException {
    provider.close();
  }


  @Test
  public void get() {
    configureProvider(true);
    try (SecretsManagerClient secretsManagerClient = SecretsManagerClient.builder()
            .endpointOverride(localstack.getEndpoint())
            .credentialsProvider(StaticCredentialsProvider.create(
                    AwsBasicCredentials.create(localstack.getAccessKey(), localstack.getSecretKey())
            ))
            .region(Region.of(localstack.getRegion()))
            .build()) {
      secretsManagerClient.createSecret(CreateSecretRequest.builder()
              .name("foo/bar/baz")
              .secretString("{\n" +
                      "  \"username\": \"asdf\",\n" +
                      "  \"password\": \"asdf\"\n" +
                      "}")
              .build());
    }


    final String secretName = "foo/bar/baz";
    Map<String, String> expected = ImmutableMap.of(
            "username", "asdf",
            "password", "asdf"
    );
    ConfigData configData = provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expected, configData.data());
  }

  @Test
  public void getPlainSecretValue() {
    configureProvider(false);
    try (SecretsManagerClient secretsManagerClient = SecretsManagerClient.builder()
            .endpointOverride(localstack.getEndpoint())
            .credentialsProvider(StaticCredentialsProvider.create(
                    AwsBasicCredentials.create(localstack.getAccessKey(), localstack.getSecretKey())
            ))
            .region(Region.of(localstack.getRegion()))
            .build()) {
      secretsManagerClient.createSecret(CreateSecretRequest.builder()
              .name("clientId")
              .secretString("mappedClientId/mappedClientSecret")
              .build());
    }


    final String secretName = "clientId";
    Map<String, String> expected = ImmutableMap.of(
            "clientId", "mappedClientId/mappedClientSecret"
    );
    ConfigData configData = provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expected, configData.data());
  }

  @Test
  public void getBinary() {
    configureProvider(true);
    try (SecretsManagerClient secretsManagerClient = SecretsManagerClient.builder()
            .endpointOverride(localstack.getEndpoint())
            .credentialsProvider(StaticCredentialsProvider.create(
              AwsBasicCredentials.create(localstack.getAccessKey(), localstack.getSecretKey())
            ))
            .region(Region.of(localstack.getRegion()))
            .build()) {
      secretsManagerClient.createSecret(CreateSecretRequest.builder()
              .name("foo/bar/binary")
              .secretBinary(SdkBytes.fromString("{\n" +
                      "  \"username\": \"asdf\",\n" +
                      "  \"password\": \"asdf\"\n" +
                      "}", Charset.defaultCharset()))
              .build());
    }

    final String secretName = "foo/bar/binary";
    Map<String, String> expected = ImmutableMap.of(
            "username", "asdf",
            "password", "asdf"
    );
    ConfigData configData = provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expected, configData.data());
  }

  @Test
  public void getWithPrefix() {
    configureProvider(true);
    try (SecretsManagerClient secretsManagerClient = SecretsManagerClient.builder()
            .endpointOverride(localstack.getEndpoint())
            .credentialsProvider(StaticCredentialsProvider.create(
              AwsBasicCredentials.create(localstack.getAccessKey(), localstack.getSecretKey())
            ))
            .region(Region.of(localstack.getRegion()))
            .build()) {
      secretsManagerClient.createSecret(CreateSecretRequest.builder()
              .name("test/prefix/foo/bar/baz")
              .secretString("{\n" +
                      "  \"username\": \"asdf\",\n" +
                      "  \"password\": \"asdf\"\n" +
                      "}")
              .build());
    }

    final String prefix = "test/prefix/";
    provider.configure(ImmutableMap.of(ENDPOINT_OVERRIDE, localstack.getEndpoint().toString(),
            REGION_CONFIG, localstack.getRegion(),
            AWS_ACCESS_KEY_ID_CONFIG, localstack.getAccessKey(),
            AWS_SECRET_KEY_CONFIG, localstack.getSecretKey(),
            PREFIX_CONFIG, prefix));

    final String secretName = "foo/bar/baz";
    Map<String, String> expected = ImmutableMap.of(
            "username", "asdf",
            "password", "asdf"
    );
    ConfigData configData = provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expected, configData.data());
  }

  @Test
  public void createSecretSuccess() {
    configureProvider(true);

    final String secretName = "it-create-test-" + System.currentTimeMillis();
    final String secretJson = "{\n  \"username\": \"created-user\",\n  \"password\": \"created-pass\"\n}";

    PutSecretRequest createRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value(secretJson)
            .path(secretName)
            .raw(secretName)
            .build();

    // Create using provider
    provider.createSecret(createRequest);

    // Verify by reading back
    Map<String, String> expected = ImmutableMap.of(
            "username", "created-user",
            "password", "created-pass"
    );
    ConfigData configData = provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expected, configData.data());

    // Cleanup
    cleanupSecret(secretName);
  }

  @Test
  public void createSecretPlainValue() {
    configureProvider(false);  // use.json = false

    final String secretName = "it-create-plain-" + System.currentTimeMillis();
    final String secretValue = "plain-secret-value-12345";

    PutSecretRequest createRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value(secretValue)
            .path(secretName)
            .raw(secretName)
            .build();

    // Create using provider
    provider.createSecret(createRequest);

    // Verify by reading back
    Map<String, String> expected = ImmutableMap.of(secretName, secretValue);
    ConfigData configData = provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expected, configData.data());

    // Cleanup
    cleanupSecret(secretName);
  }

  @Test
  public void createSecretWithComplexJson() {
    configureProvider(true);

    final String secretName = "it-create-complex-" + System.currentTimeMillis();
    final String secretJson = "{\n" +
            "  \"db_host\": \"localhost\",\n" +
            "  \"db_port\": \"5432\",\n" +
            "  \"db_user\": \"admin\",\n" +
            "  \"db_password\": \"super$ecret!\"\n" +
            "}";

    PutSecretRequest createRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value(secretJson)
            .path(secretName)
            .raw(secretName)
            .build();

    provider.createSecret(createRequest);

    // Verify
    Map<String, String> expected = ImmutableMap.of(
            "db_host", "localhost",
            "db_port", "5432",
            "db_user", "admin",
            "db_password", "super$ecret!"
    );
    ConfigData configData = provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expected, configData.data());

    // Cleanup
    cleanupSecret(secretName);
  }

  @Test
  public void updateSecretSuccess() {
    configureProvider(true);

    final String secretName = "it-update-test-" + System.currentTimeMillis();
    final String originalJson = "{\n  \"username\": \"original-user\",\n  \"password\": \"original-pass\"\n}";
    final String updatedJson = "{\n  \"username\": \"updated-user\",\n  \"password\": \"updated-pass\"\n}";

    // First create the secret
    PutSecretRequest createRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value(originalJson)
            .path(secretName)
            .raw(secretName)
            .build();
    provider.createSecret(createRequest);

    // Verify original value
    Map<String, String> originalExpected = ImmutableMap.of(
            "username", "original-user",
            "password", "original-pass"
    );
    ConfigData originalData = provider.get(secretName, ImmutableSet.of());
    assertEquals(originalExpected, originalData.data());

    // Now update the secret
    PutSecretRequest updateRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value(updatedJson)
            .path(secretName)
            .raw(secretName)
            .build();
    provider.updateSecret(updateRequest);

    // Verify updated value
    Map<String, String> updatedExpected = ImmutableMap.of(
            "username", "updated-user",
            "password", "updated-pass"
    );
    ConfigData updatedData = provider.get(secretName, ImmutableSet.of());
    assertNotNull(updatedData);
    assertEquals(updatedExpected, updatedData.data());

    // Cleanup
    cleanupSecret(secretName);
  }

  @Test
  public void updateSecretMultipleTimes() {
    configureProvider(true);

    final String secretName = "it-multi-update-" + System.currentTimeMillis();

    // Create initial secret
    PutSecretRequest createRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value("{\"version\": \"1\"}")
            .path(secretName)
            .raw(secretName)
            .build();
    provider.createSecret(createRequest);

    // Update multiple times
    for (int i = 2; i <= 5; i++) {
      PutSecretRequest updateRequest = ImmutablePutSecretRequest.builder()
              .key(secretName)
              .value("{\"version\": \"" + i + "\"}")
              .path(secretName)
              .raw(secretName)
              .build();
      provider.updateSecret(updateRequest);
    }

    // Verify final value
    Map<String, String> expected = ImmutableMap.of("version", "5");
    ConfigData configData = provider.get(secretName, ImmutableSet.of());
    assertEquals(expected, configData.data());

    // Cleanup
    cleanupSecret(secretName);
  }

  @Test
  public void updateSecretAddNewFields() {
    configureProvider(true);

    final String secretName = "it-update-fields-" + System.currentTimeMillis();
    final String originalJson = "{\"key1\": \"value1\"}";
    final String updatedJson = "{\"key1\": \"value1\", \"key2\": \"value2\", \"key3\": \"value3\"}";

    // Create
    PutSecretRequest createRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value(originalJson)
            .path(secretName)
            .raw(secretName)
            .build();
    provider.createSecret(createRequest);

    // Update with more fields
    PutSecretRequest updateRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value(updatedJson)
            .path(secretName)
            .raw(secretName)
            .build();
    provider.updateSecret(updateRequest);

    // Verify
    Map<String, String> expected = ImmutableMap.of(
            "key1", "value1",
            "key2", "value2",
            "key3", "value3"
    );
    ConfigData configData = provider.get(secretName, ImmutableSet.of());
    assertEquals(expected, configData.data());

    // Cleanup
    cleanupSecret(secretName);
  }

  @Test
  public void deleteSecretSuccess() {
    configureProvider(true);

    final String secretName = "it-delete-test-" + System.currentTimeMillis();
    final String secretJson = "{\"username\": \"to-be-deleted\"}";

    // Create secret first
    PutSecretRequest createRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value(secretJson)
            .path(secretName)
            .raw(secretName)
            .build();
    provider.createSecret(createRequest);

    // Verify it exists
    ConfigData beforeDelete = provider.get(secretName, ImmutableSet.of());
    assertNotNull(beforeDelete);

    // Delete the secret
    SecretRequest deleteRequest = ImmutableSecretRequest.builder()
            .path(secretName)
            .raw(secretName)
            .build();
    provider.deleteSecret(deleteRequest);

    // Verify it's deleted (should throw exception)
    assertThrows(ConfigException.class, () -> {
      provider.get(secretName, ImmutableSet.of());
    });
  }

  @Test
  public void deleteSecretNotFound() {
    configureProvider(true);

    final String secretName = "it-nonexistent-secret-" + System.currentTimeMillis();

    SecretRequest deleteRequest = ImmutableSecretRequest.builder()
            .path(secretName)
            .raw(secretName)
            .build();

    // Deleting non-existent secret should throw ResourceNotFoundException
    assertThrows(ResourceNotFoundException.class, () -> {
      provider.deleteSecret(deleteRequest);
    });
  }

  @Test
  public void fullSecretLifecycle() {
    configureProvider(true);

    final String secretName = "it-lifecycle-" + System.currentTimeMillis();

    // 1. CREATE
    PutSecretRequest createRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value("{\"step\": \"created\"}")
            .path(secretName)
            .raw(secretName)
            .build();
    provider.createSecret(createRequest);

    ConfigData afterCreate = provider.get(secretName, ImmutableSet.of());
    assertEquals("created", afterCreate.data().get("step"));

    // 2. UPDATE
    PutSecretRequest updateRequest = ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value("{\"step\": \"updated\"}")
            .path(secretName)
            .raw(secretName)
            .build();
    provider.updateSecret(updateRequest);

    ConfigData afterUpdate = provider.get(secretName, ImmutableSet.of());
    assertEquals("updated", afterUpdate.data().get("step"));

    // 3. DELETE
    SecretRequest deleteRequest = ImmutableSecretRequest.builder()
            .path(secretName)
            .raw(secretName)
            .build();
    provider.deleteSecret(deleteRequest);

    // 4. VERIFY DELETED
    assertThrows(ConfigException.class, () -> {
      provider.get(secretName, ImmutableSet.of());
    });
  }

  @Test
  public void createReadUpdateReadDeleteRead() {
    configureProvider(true);

    final String secretName = "it-crud-" + System.currentTimeMillis();

    // CREATE
    provider.createSecret(ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value("{\"username\": \"user1\", \"password\": \"pass1\"}")
            .path(secretName)
            .raw(secretName)
            .build());

    // READ 1
    ConfigData read1 = provider.get(secretName, ImmutableSet.of());
    assertEquals("user1", read1.data().get("username"));
    assertEquals("pass1", read1.data().get("password"));

    // UPDATE
    provider.updateSecret(ImmutablePutSecretRequest.builder()
            .key(secretName)
            .value("{\"username\": \"user2\", \"password\": \"pass2\"}")
            .path(secretName)
            .raw(secretName)
            .build());

    // READ 2
    ConfigData read2 = provider.get(secretName, ImmutableSet.of());
    assertEquals("user2", read2.data().get("username"));
    assertEquals("pass2", read2.data().get("password"));

    // DELETE
    provider.deleteSecret(ImmutableSecretRequest.builder()
            .path(secretName)
            .raw(secretName)
            .build());

    // READ 3 (should fail)
    assertThrows(ConfigException.class, () -> {
      provider.get(secretName, ImmutableSet.of());
    });
  }

  /**
   * Helper method to cleanup secrets after tests.
   * Uses force delete without recovery window.
   */
  private void cleanupSecret(String secretName) {
    try (SecretsManagerClient client = SecretsManagerClient.builder()
            .endpointOverride(localstack.getEndpoint())
            .credentialsProvider(StaticCredentialsProvider.create(
                    AwsBasicCredentials.create(localstack.getAccessKey(), localstack.getSecretKey())
            ))
            .region(Region.of(localstack.getRegion()))
            .build()) {

      client.deleteSecret(DeleteSecretRequest.builder()
              .secretId(secretName)
              .forceDeleteWithoutRecovery(Boolean.TRUE)
              .build());
    } catch (Exception e) {
      // Ignore cleanup errors
    }
  }

  /**
   * Helper to verify a secret exists in AWS directly.
   */
  private GetSecretValueResponse getSecretDirect(String secretName) {
    try (SecretsManagerClient client = SecretsManagerClient.builder()
            .endpointOverride(localstack.getEndpoint())
            .credentialsProvider(StaticCredentialsProvider.create(
                    AwsBasicCredentials.create(localstack.getAccessKey(), localstack.getSecretKey())
            ))
            .region(Region.of(localstack.getRegion()))
            .build()) {

      return client.getSecretValue(GetSecretValueRequest.builder()
              .secretId(secretName)
              .build());
    }
  }
}
