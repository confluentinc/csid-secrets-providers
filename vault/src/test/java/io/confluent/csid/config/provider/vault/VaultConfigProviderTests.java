/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.vault;

import com.bettercloud.vault.VaultException;
import com.bettercloud.vault.api.Logical;
import com.bettercloud.vault.response.LogicalResponse;
import com.bettercloud.vault.rest.RestResponse;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.confluent.csid.config.provider.common.AbstractConfigProviderConfig;
import org.apache.kafka.common.config.ConfigData;
import org.apache.kafka.common.config.ConfigException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.stubbing.OngoingStubbing;

import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

public class VaultConfigProviderTests {
  VaultConfigProvider configProvider;
  VaultClient vaultClient;
  Map<String, String> settings;

  @BeforeEach
  public void before() {
    this.configProvider = new VaultConfigProvider();
    this.vaultClient = mock(VaultClient.class);
    this.configProvider.vaultClientFactory = mock(VaultClientFactory.class);
    when(this.configProvider.vaultClientFactory.create(any(), any())).thenReturn(this.vaultClient);
    this.settings = new LinkedHashMap<>();
  }


  @Test
  public void getSecretNotFound() throws VaultException {
    this.configProvider.configure(this.settings);
    addVaultException(when(this.vaultClient.read(any())), 404, "not found");
    assertThrows(ConfigException.class, () -> {
      this.configProvider.get("secret/foo");
    });
  }

  OngoingStubbing<LogicalResponse> addVaultException(OngoingStubbing<LogicalResponse> stub, int statusCode, String message) throws VaultException {
    return stub.thenThrow(new VaultException(message, statusCode));
  }

  OngoingStubbing<LogicalResponse> addLogicalResponse(OngoingStubbing<LogicalResponse> stub, int status, Body body) throws JsonProcessingException, VaultException {
    ObjectMapper objectMapper = new ObjectMapper();
    byte[] payload = objectMapper.writeValueAsBytes(body);
    RestResponse restResponse = new RestResponse(status, "application/json", payload);
    LogicalResponse response = new LogicalResponse(restResponse, 1, Logical.logicalOperations.readV2);
    return stub.thenReturn(response);
  }

  @Test
  public void getSecret() throws Exception {
    this.configProvider.configure(this.settings);
    Body expected = ImmutableBody.builder()
        .data(
            ImmutableData.builder()
                .putData("username", "db01")
                .putData("password", "asdfiasdfasdf")
                .build()
        ).build();

    OngoingStubbing<LogicalResponse> stub = when(this.vaultClient.read(any()));
    stub = addLogicalResponse(stub, 200, expected);


    ConfigData actual = this.configProvider.get("secret/foo");
    assertNotNull(actual);
    assertEquals(expected.data().data(), actual.data());
  }
  @Test
  public void getVersioned() throws Exception {
    this.configProvider.configure(this.settings);
    Body expected = ImmutableBody.builder()
        .data(
            ImmutableData.builder()
                .putData("username", "db01")
                .putData("password", "asdfiasdfasdf")
                .build()
        ).build();

    OngoingStubbing<LogicalResponse> stub = when(this.vaultClient.read(any()));
    stub = addLogicalResponse(stub, 200, expected);


    ConfigData actual = this.configProvider.get("secret/foo?version=1234");
    assertNotNull(actual);
    assertEquals(expected.data().data(), actual.data());
  }

  @Test
  public void getSecretRetries() throws Exception {
    this.settings.put(AbstractConfigProviderConfig.RETRY_INTERVAL_SECONDS_CONFIG, "1");
    this.configProvider.configure(this.settings);
    Body expected = ImmutableBody.builder()
        .data(
            ImmutableData.builder()
                .putData("username", "db01")
                .putData("password", "asdfiasdfasdf")
                .build()
        ).build();

    OngoingStubbing<LogicalResponse> stub = when(this.vaultClient.read(any()));
    stub = addVaultException(stub, 503, "Vault Sealed");
    stub = addVaultException(stub, 503, "Vault Sealed");
    stub = addLogicalResponse(stub, 200, expected);


    ConfigData actual = this.configProvider.get("secret/foo");
    assertNotNull(actual);
    assertEquals(expected.data().data(), actual.data());
  }

//  @Test
//  public void getSecretRetry() throws Exception {
//    this.configProvider.configure(this.settings);
//
//    addVaultException(503, "Vault Sealed.");
//    Body expected = addLogicalResponse(200, ImmutableBody.builder()
//        .data(
//            ImmutableData.builder()
//                .putData("username", "db01")
//                .putData("password", "asdfiasdfasdf")
//                .build()
//        )
//    );
//
//
//    ConfigData actual = this.configProvider.get("secret/foo");
//    assertNotNull(actual);
//    assertEquals(expected.data().data(), actual.data());
//  }


}
