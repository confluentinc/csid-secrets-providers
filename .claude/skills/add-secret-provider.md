---
name: add-secret-provider
description: Generate a complete secret provider integration across csid-secrets-providers and gateway repos. Creates all source files, tests, SPI registration, Docker setup, and gateway integration.
user_invocable: true
arguments:
  - name: provider_name
    description: "The provider display name (e.g., CyberArk, OnePassword, Delinea, Thales)"
    required: true
  - name: provider_key
    description: "The lowercase key used in config/packages (e.g., cyberark, onepassword). Defaults to lowercase of provider_name."
    required: false
  - name: sdk_dependency
    description: "Maven dependency for the vendor SDK in format groupId:artifactId:version (e.g., com.cyberark.conjur:conjur-api:3.1.2)"
    required: true
  - name: config_fields
    description: "Comma-separated list of config fields in format name:type[:required] (e.g., url:STRING:required,account:STRING:required,apiKey:PASSWORD:required,sslVerifyEnabled:BOOLEAN). Types: STRING, PASSWORD, BOOLEAN, INT."
    required: true
  - name: auth_description
    description: "Brief description of how authentication works (e.g., 'API key + username, SDK handles token lifecycle')"
    required: true
  - name: gateway_repo_path
    description: "Path to gateway repo. Defaults to ~/workspace/gateway"
    required: false
---

# Add Secret Provider Skill

## How to Use This Skill

This skill is invoked via Claude Code using the `/add-secret-provider` slash command. It generates a complete secret provider integration across both `csid-secrets-providers` and `gateway` repos.

### Quick Start

From the `csid-secrets-providers` repo directory, run:

```
/add-secret-provider
```

Claude will prompt you for the required arguments interactively.

### Providing Arguments Inline

You can also pass arguments directly:

```
/add-secret-provider provider_name="Delinea" sdk_dependency="com.delinea:sdk:2.0.0" config_fields="url:STRING:required,clientId:STRING:required,clientSecret:PASSWORD:required,tld:STRING" auth_description="OAuth2 client credentials flow"
```

### Argument Reference

| Argument | Required | Description | Example |
|---|---|---|---|
| `provider_name` | Yes | Display name (PascalCase) | `CyberArk`, `OnePassword`, `Delinea` |
| `provider_key` | No | Lowercase key for packages/config. Defaults to lowercase of `provider_name` | `cyberark`, `onepassword` |
| `sdk_dependency` | Yes | Maven GAV in `groupId:artifactId:version` format | `com.cyberark.conjur:conjur-api:3.1.2` |
| `config_fields` | Yes | Comma-separated fields as `name:type[:required]`. Types: `STRING`, `PASSWORD`, `BOOLEAN`, `INT` | `url:STRING:required,apiKey:PASSWORD:required,sslVerifyEnabled:BOOLEAN` |
| `auth_description` | Yes | How auth works (used for documentation annotations) | `API key + username, SDK handles token lifecycle` |
| `gateway_repo_path` | No | Path to gateway repo. Defaults to `~/workspace/gateway` | `/home/user/repos/gateway` |

### What It Does

The skill runs in 4 phases:

1. **Phase 1 — csid module** (~10 files): pom.xml, config, client interface + impl, factory, ConfigProvider, SPI registration, unit tests, module registration in root pom
2. **Phase 2 — Gateway integration** (~15 files): SecretStoreConfig record, ProviderConfig record, SecretStore impl, factory wiring, pom dependencies, unit tests, integration test harness (testcontainers), AuthSwap wiring
3. **Phase 3 — Verification**: Compiles and runs tests in both repos
4. **Phase 4 — Summary**: Checklist of all generated files and next steps

### Important Notes

- Run this from the **csid-secrets-providers** repo root directory
- The gateway repo must exist at the specified path (default: `~/workspace/gateway`)
- The skill will **ask for approval** before modifying shared files (root pom.xml, ProviderConfig.java, SecretStoreFactory.java, gateway pom files)
- The generated `ClientImpl` has a TODO placeholder — you must wire the actual SDK calls
- After generation, you'll need to create a Docker test environment and run E2E tests manually

---

You are an agent that generates a complete secret provider integration. You will create ~21 files across two repos following the exact patterns used by existing providers (Vault, AWS, Azure, CyberArk).

## Prerequisites Check

Before generating any files, verify:

1. **csid-secrets-providers repo exists** at the current working directory
   - Check: `pom.xml` contains `csid-secrets-providers` as artifactId
   - Check: `common/`, `vault/`, `aws/` directories exist
   - Read root `pom.xml` to get current `<version>` (e.g., `1.0.52-SNAPSHOT`)

2. **Gateway repo exists** at `$gateway_repo_path` (default: `~/workspace/gateway`)
   - Check: `gateway-common/` and `gateway-filters/` directories exist
   - Read `pom.xml` to get `csid.secrets.provider.version`

3. **Module doesn't already exist**
   - Check: `$provider_key/` directory does NOT exist in csid repo
   - Check: `gateway-common/.../secretprovider/$provider_key/` does NOT exist

If any prerequisite fails, stop and report the issue. Do NOT proceed.

## Parse Arguments

```
PROVIDER_NAME = $provider_name          # e.g., "CyberArk"
PROVIDER_KEY = $provider_key || lowercase($provider_name)  # e.g., "cyberark"
SDK_GROUP:SDK_ARTIFACT:SDK_VERSION = split($sdk_dependency, ":")
GATEWAY_PATH = $gateway_repo_path || ~/workspace/gateway
```

Parse `$config_fields` into a list of objects:
```
For each field in split($config_fields, ","):
  name, type, required = split(field, ":")
  configConstant = PROVIDER_KEY + "." + camelToKebab(name)  # e.g., "cyberark.api-key"
```

## Phase 1: csid-secrets-providers — Generate Provider Module

### Step 1.1: Read existing provider for reference

Use subagents to read these files in parallel — they define the exact patterns to follow:
- `cyberark/pom.xml` — for pom structure
- `cyberark/src/main/java/.../CyberArkConfigProviderConfig.java` — for config pattern
- `cyberark/src/main/java/.../CyberArkConfigProvider.java` — for provider pattern
- `cyberark/src/main/java/.../CyberArkClient.java` — for client interface
- `cyberark/src/main/java/.../CyberArkClientImpl.java` — for client implementation
- `cyberark/src/main/java/.../CyberArkClientFactory.java` — for factory interface
- `cyberark/src/main/java/.../CyberArkClientFactoryImpl.java` — for factory impl
- `cyberark/src/test/.../CyberArkConfigProviderTest.java` — for test pattern
- `cyberark/src/test/.../CyberArkConfigProviderConfigTest.java` — for config test pattern

### Step 1.2: Create pom.xml

Create `$provider_key/pom.xml`:
- Copy structure from cyberark/pom.xml
- Replace artifactId with `csid-secrets-provider-$provider_key`
- Replace SDK dependency with `$sdk_dependency`
- Keep `csid-secrets-provider-common`, `csid-secrets-provider-annotations`, `mockito-core`, `junit-jupiter`

### Step 1.3: Create ConfigProviderConfig

Create `$provider_key/src/main/java/io/confluent/csid/config/provider/$provider_key/${PROVIDER_NAME}ConfigProviderConfig.java`:
- Extend `AbstractConfigProviderConfig`
- For each field in `$config_fields`: create a `public static final String` constant and a `public final` field
- Constructor parses from map using `getString()`, `getBoolean()`, `getPassword().value()`, `getInt()`
- Static `config()` method defines all keys using `ConfigKeyBuilder`
- PASSWORD type fields use `ConfigDef.Type.PASSWORD`
- License header: `/** * Copyright Confluent 2021 */`

### Step 1.4: Create Client interface

Create `${PROVIDER_NAME}Client.java`:
```java
interface ${PROVIDER_NAME}Client {
  Map<String, String> getSecret(SecretRequest request) throws Exception;
}
```

### Step 1.5: Create ClientImpl

Create `${PROVIDER_NAME}ClientImpl.java`:
- Package-private class
- Constructor takes `${PROVIDER_NAME}ConfigProviderConfig`
- **CRITICAL: Do NOT use System.setProperty()** — use SDK's lower-level classes directly
- **CRITICAL: SSL trust-all only when `sslVerifyEnabled=false` AND `url.startsWith("https")`**
- Second package-private constructor for testing that accepts the raw SDK client
- `getSecret()` calls SDK, returns `Collections.singletonMap(request.path(), secretValue)`
- Add a `TODO` comment in the constructor body: `// TODO: Replace with actual SDK initialization for $PROVIDER_NAME`

### Step 1.6: Create Factory interface + impl

Create `${PROVIDER_NAME}ClientFactory.java`:
```java
interface ${PROVIDER_NAME}ClientFactory {
  ${PROVIDER_NAME}Client create(${PROVIDER_NAME}ConfigProviderConfig config);
}
```

Create `${PROVIDER_NAME}ClientFactoryImpl.java`:
```java
class ${PROVIDER_NAME}ClientFactoryImpl implements ${PROVIDER_NAME}ClientFactory {
  @Override
  public ${PROVIDER_NAME}Client create(${PROVIDER_NAME}ConfigProviderConfig config) {
    return new ${PROVIDER_NAME}ClientImpl(config);
  }
}
```

### Step 1.7: Create ConfigProvider

Create `${PROVIDER_NAME}ConfigProvider.java`:
- Extend `AbstractConfigProvider<${PROVIDER_NAME}ConfigProviderConfig>`
- **MUST include these annotations**:
  - `@Description("This config provider is used to retrieve secrets from ${PROVIDER_NAME}.")`
  - `@DocumentationSections` with TWO sections: "Secret Value" and "Secret Retrieval"
  - `@DocumentationTip("Config providers can be used with anything that supports the AbstractConfig base class that is shipped with Apache Kafka.")`
  - `@ConfigProviderKey("$provider_key")`
- Fields: `${PROVIDER_NAME}ClientFactory clientFactory`, `${PROVIDER_NAME}Client client`
- Methods: `config(Map)`, `configure()`, `getSecret(SecretRequest)`, `config()`

### Step 1.8: Create SPI file

Create `$provider_key/src/main/resources/META-INF/services/org.apache.kafka.common.config.provider.ConfigProvider`:
```
io.confluent.csid.config.provider.$provider_key.${PROVIDER_NAME}ConfigProvider
```

### Step 1.9: Create unit tests

**${PROVIDER_NAME}ConfigProviderTest.java** (3 tests):
- `getSecret_returnsCorrectData` — mock factory+client, verify secret retrieval
- `getSecret_notFound_throwsException` — mock client throws, verify exception propagation
- `getSecret_withJsonData` — mock client returns JSON string, verify passthrough

**${PROVIDER_NAME}ConfigProviderConfigTest.java** (4 tests):
- `testConfigParsing` — all fields parsed correctly
- `testDefaultValues` — optional fields have correct defaults
- `testSensitiveFieldType` — PASSWORD fields are masked
- `testConfigDef` — ConfigDef contains all expected keys

### Step 1.10: Register module

Read root `pom.xml`, add `<module>$provider_key</module>` in the `<modules>` section.

**ASK USER FOR APPROVAL** before modifying root pom.xml (shared file).

## Phase 2: Gateway — Generate SecretStore Integration

### Step 2.1: Read existing gateway provider for reference

Use subagents to read in parallel:
- `gateway-common/.../secretprovider/cyberark/CyberArkSecretStoreConfig.java`
- `gateway-common/.../secretprovider/cyberark/CyberArkProviderConfig.java`
- `gateway-filters/.../secretstore/cyberark/CyberArkSecretStore.java`
- `gateway-common/.../secretprovider/ProviderConfig.java`
- `gateway-filters/.../secretstore/SecretStoreFactory.java`
- Existing tests for cyberark

### Step 2.2: Create SecretStoreConfig

Create `$GATEWAY_PATH/gateway-common/src/main/java/io/confluent/gateway/common/secretprovider/$provider_key/${PROVIDER_NAME}SecretStoreConfig.java`:
- Java record implementing `MappableRecord`
- Fields from `$config_fields` + `prefixPath` (required) + `separator` (optional)
- `CONFIG_KEYS` maps record field names → csid config key constants
- `prefixPath` and `separator` are NOT in CONFIG_KEYS (gateway-only fields)

### Step 2.3: Create ProviderConfig

Create `${PROVIDER_NAME}ProviderConfig.java`:
```java
public record ${PROVIDER_NAME}ProviderConfig(
    @JsonProperty(required = true) String type,
    @JsonProperty(required = true) ${PROVIDER_NAME}SecretStoreConfig config
) implements ProviderConfig {}
```

### Step 2.4: Create SecretStore

Create `$GATEWAY_PATH/gateway-filters/src/main/java/io/confluent/gateway/filter/authswap/secretstore/$provider_key/${PROVIDER_NAME}SecretStore.java`:
- Implement `SecretStore<${PROVIDER_NAME}SecretStoreConfig>`
- Constructor creates new `${PROVIDER_NAME}ConfigProvider()`
- `configure()` calls `provider.configure(config.toMap())`
- `exchangeCredential()` uses `configData.data().values().iterator().next()` (NOT `.get("value")` — that's Vault-specific)
- `getJsonSecret()` same pattern
- `getSeparator()` returns config value or DEFAULT_SEPARATOR
- `getKeyPrefix()` returns `config.prefixPath()`

### Step 2.5: Modify ProviderConfig.java

**ASK USER FOR APPROVAL** before modifying (shared file).

Add to `@JsonSubTypes`:
```java
@JsonSubTypes.Type(value = ${PROVIDER_NAME}ProviderConfig.class, name = "${PROVIDER_NAME}")
```

Add import and update Javadoc list.

### Step 2.6: Modify SecretStoreFactory.java

**ASK USER FOR APPROVAL** before modifying (shared file).

Add case to switch + private method.

### Step 2.7: Modify gateway pom files

**ASK USER FOR APPROVAL** before modifying.

**gateway-common/pom.xml** — Add dependency:
```xml
<dependency>
  <groupId>io.confluent.csid</groupId>
  <artifactId>csid-secrets-provider-$provider_key</artifactId>
  <version>${csid.secrets.provider.version}</version>
</dependency>
```

**gateway root pom.xml** — Verify `csid.secrets.provider.version` is set correctly. If there are duplicate `<csid.secrets.provider.version>` properties, remove the older one. The version should point to the csid release that includes the new provider module (or use SNAPSHOT for local development).

### Step 2.8: Create gateway tests

**${PROVIDER_NAME}SecretStoreConfigTest.java** (~6 tests):
- Config key mapping correctness
- toMap() output
- Record accessors
- Null handling for optional fields

**${PROVIDER_NAME}ProviderConfigTest.java** (~3 tests):
- Record construction
- Type value
- Null config handling

**${PROVIDER_NAME}SecretStoreTest.java** (~10 tests):
- configure() passes correct config map
- exchangeCredential() with valid data
- exchangeCredential() with invalid separator data
- getJsonSecret() returns JSON
- getJsonSecret() returns null for empty
- getSeparator() with configured value
- getSeparator() with default
- getType() returns "${PROVIDER_NAME}"
- getKeyPrefix() returns prefixPath

Update **SecretStoreFactoryTest.java** — add 2 tests:
- create${PROVIDER_NAME}SecretStore with valid config
- create${PROVIDER_NAME}SecretStore with invalid config throws

Update **ProviderConfigTest.java** — add 3 tests:
- ${PROVIDER_NAME} config creation
- JSON serialization
- JSON deserialization

### Step 2.9: Create Integration Test Harness

Create a **container harness** for the new provider in `gateway-integration-test-tool/src/test/java/io/confluent/gateway/harness/secretstore/$provider_key/`.

Read these reference files first:
- `gateway-integration-test-tool/.../secretstore/cyberark/ConjurHarness.java` — full harness pattern
- `gateway-integration-test-tool/.../secretstore/SecretStoreHarness.java` — interface to implement
- `gateway-integration-test-tool/.../AbstractContainerHarness.java` — base class to extend

**${PROVIDER_NAME}Harness.java** — extends `AbstractContainerHarness<GenericContainer<?>, Builder>` and implements `SecretStoreHarness`:

Key structure:
```java
public class ${PROVIDER_NAME}Harness
    extends AbstractContainerHarness<GenericContainer<?>, ${PROVIDER_NAME}Harness.Builder>
    implements SecretStoreHarness {

  // Constants: docker image, default port, default account/prefix
  // Builder with fluent API: withSecret(key, value), withAccount(), withPrefixPath()
  // createContainer() — sets up testcontainers with env vars, ports, wait strategy
  // doStart() — start dependencies (e.g., database), then container, then initialize (create account, auth, load secrets)
  // Authentication method — get token via REST API after container starts
  // loadSecretsPolicy() — create variables via REST API
  // setSecretValues() — set values via REST API

  // SecretStoreHarness interface methods:
  // getEndpoint(), getPrimaryCredential(), getSecondaryCredential()
  // getSecretPath(), getSecretStoreType(), removeUserCredential(), getSecret()
  // isRunning(), start(), close()

  // Builder inner class
  public static class Builder extends AbstractContainerHarness.BaseBuilder<Builder> { ... }
}
```

If the provider needs a backing database (like Conjur needs PostgreSQL), start it as a separate container in the same Docker network.

### Step 2.10: Create Manual Inspection Test

Create `gateway-app/src/test/java/io/confluent/gateway/integration/${PROVIDER_NAME}HarnessManualTest.java`:
```java
@DisplayName("${PROVIDER_NAME} Harness Manual Inspection Test")
@Tag(GatewayTestTag.IntegrationTest)
class ${PROVIDER_NAME}HarnessManualTest {

  @Test
  @DisplayName("Start ${PROVIDER_NAME} and verify secrets")
  void startAndVerify() throws Exception {
    try (${PROVIDER_NAME}Harness harness = ${PROVIDER_NAME}Harness.builder()
        .withSecret("user1", "newuser:newpass")
        .withSecret("user2", "admin:admin-secret")
        .build()) {

      harness.start();
      assertThat(harness.isRunning()).isTrue();
      assertThat(harness.getSecret("user1")).isEqualTo("newuser:newpass");
      assertThat(harness.getSecret("user2")).isEqualTo("admin:admin-secret");
    }
  }
}
```

### Step 2.11: Wire into AuthSwap Integration Tests

Read and modify these files (**ASK USER FOR APPROVAL** — shared test infrastructure):

**`gateway-app/.../harness/feature/AuthSwapFeature.java`** — Add an `else if` block in the secret store config builder:
```java
} else if ("$provider_key".equals(storeType)) {
  ${PROVIDER_NAME}Harness harness = (${PROVIDER_NAME}Harness) secretStoreHarness;
  secretStoreConfig.put("name", "test-$provider_key");
  secretStoreConfig.put("url", harness.getEndpoint());
  // ... map all provider-specific fields from harness getters
  secretStoreConfig.put("prefixPath", harness.getPrefixPath());
  data.put("$provider_key", secretStoreConfig);
}
```

**`gateway-app/src/test/resources/gateway-config-template.yaml`** — Add a FreeMarker conditional block for the new provider:
```yaml
<#if authSwap.$provider_key??>
    - name: ${authSwap.$provider_key.name}
      provider:
        type: ${PROVIDER_NAME}
        config:
          url: ${authSwap.$provider_key.url}
          # ... all provider-specific config fields
          prefixPath: ${authSwap.$provider_key.prefixPath}
          sslVerifyEnabled: false
</#if>
```

**`gateway-app/.../integration/GatewayAuthSwapIntegrationTest.java`** — Add the new provider to the existing parameterized test by:
1. Adding an import for the harness
2. Adding a `@Nested` test class or adding the provider to the existing `@EnumSource` / parameterized test that creates the harness and runs auth swap scenarios

Reference the CyberArk wiring in commit `09b2eee` for the exact pattern.

## Phase 3: Verification

After generating all files:

1. **Build csid module**:
   ```bash
   cd <csid-repo> && mvn compile -pl :csid-secrets-provider-$provider_key -am -q
   ```

2. **Run csid tests**:
   ```bash
   mvn test -pl :csid-secrets-provider-$provider_key -q
   ```

3. **Install csid locally**:
   ```bash
   mvn install -pl :csid-secrets-provider-$provider_key -am -DskipTests -q
   ```

4. **Build gateway** (including integration test tool):
   ```bash
   cd $GATEWAY_PATH && mvn compile -pl gateway-common,gateway-filters,gateway-integration-test-tool,gateway-app -q
   ```

5. **Run gateway unit tests**:
   ```bash
   mvn test -pl gateway-common,gateway-filters -Dtest="${PROVIDER_NAME}*" -DfailIfNoTests=false
   ```

6. **Run gateway integration test** (manual harness test):
   ```bash
   mvn test -pl gateway-app -Dtest="${PROVIDER_NAME}HarnessManualTest" -DfailIfNoTests=false
   ```

If any step fails, fix the issue before proceeding.

## Phase 4: Summary Report

After all files are generated and tests pass, output:

```
## Generated Files Summary

### csid-secrets-providers ($provider_key module)
- [ ] $provider_key/pom.xml
- [ ] ${PROVIDER_NAME}ConfigProviderConfig.java (X config keys)
- [ ] ${PROVIDER_NAME}Client.java
- [ ] ${PROVIDER_NAME}ClientImpl.java ⚠️ TODO: Wire actual SDK calls
- [ ] ${PROVIDER_NAME}ClientFactory.java
- [ ] ${PROVIDER_NAME}ClientFactoryImpl.java
- [ ] ${PROVIDER_NAME}ConfigProvider.java
- [ ] META-INF/services/...ConfigProvider (SPI)
- [ ] ${PROVIDER_NAME}ConfigProviderTest.java (3 tests)
- [ ] ${PROVIDER_NAME}ConfigProviderConfigTest.java (4 tests)
- [ ] root pom.xml (added module)

### gateway — source + unit tests
- [ ] ${PROVIDER_NAME}SecretStoreConfig.java (gateway-common)
- [ ] ${PROVIDER_NAME}ProviderConfig.java (gateway-common)
- [ ] ${PROVIDER_NAME}SecretStore.java (gateway-filters)
- [ ] ProviderConfig.java (added @JsonSubTypes entry)
- [ ] SecretStoreFactory.java (added case + method)
- [ ] gateway-common/pom.xml (added dependency)
- [ ] gateway root pom.xml (verify csid.secrets.provider.version)
- [ ] ${PROVIDER_NAME}SecretStoreConfigTest.java (6 tests)
- [ ] ${PROVIDER_NAME}ProviderConfigTest.java (3 tests)
- [ ] ${PROVIDER_NAME}SecretStoreTest.java (10 tests)
- [ ] SecretStoreFactoryTest.java (added 2 tests)
- [ ] ProviderConfigTest.java (added 3 tests)

### gateway — integration tests
- [ ] ${PROVIDER_NAME}Harness.java (gateway-integration-test-tool, testcontainers)
- [ ] ${PROVIDER_NAME}HarnessManualTest.java (gateway-app)
- [ ] AuthSwapFeature.java (added ${PROVIDER_NAME} else-if block)
- [ ] gateway-config-template.yaml (added FreeMarker block)
- [ ] GatewayAuthSwapIntegrationTest.java (wired ${PROVIDER_NAME})

### Next Steps
1. Wire actual SDK calls in ${PROVIDER_NAME}ClientImpl.java
2. Create Docker test environment ($provider_key/docker-compose.yml) in csid repo
3. Create test data seeding script ($provider_key/setup-test-data.sh)
4. Run E2E tests against live server
5. Submit PR to csid-secrets-providers, then gateway after csid release
```

## Critical Rules

1. **NEVER use System.setProperty()** — prevents multiple provider instances in same JVM
2. **SSL trust-all ONLY when sslVerifyEnabled=false AND url starts with https**
3. **Every Java file MUST have license header**: `/** * Copyright Confluent 2021 */` (for csid) or `/* * Copyright 2025 Confluent Inc. */` (for gateway)
4. **@DocumentationSections is REQUIRED** — reviewers will reject without it
5. **Use factory pattern** — even with single implementation, it enables testability
6. **Unit tests only in csid** — e2e testing goes in gateway or separate test project
7. **Use `${csid.secrets.provider.version}`** for dependency version in gateway — never hardcode SNAPSHOT
8. **ASK before modifying shared files** (root pom.xml, ProviderConfig.java, SecretStoreFactory.java, gateway pom.xml)
9. **Read reference files first** — always read CyberArk/Vault implementations before generating, patterns may have evolved
10. **Gateway checkstyle: NoLineWrap on imports** — never line-wrap import statements in gateway code, even if they exceed 100 chars. Checkstyle will reject wrapped imports.
11. **Gateway checkstyle: unused imports** — csid checkstyle also checks unused imports. If the generated `ClientImpl` has placeholder code (throws instead of returning), remove `Collections` import