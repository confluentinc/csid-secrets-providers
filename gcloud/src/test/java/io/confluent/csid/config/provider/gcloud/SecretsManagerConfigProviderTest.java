/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.gcloud;

import com.google.api.core.ApiFuture;
import com.google.api.core.ApiFutures;
import com.google.api.gax.grpc.GrpcStatusCode;
import com.google.api.gax.rpc.ApiCallContext;
import com.google.api.gax.rpc.NotFoundException;
import com.google.api.gax.rpc.StatusCode;
import com.google.api.gax.rpc.UnaryCallable;
import com.google.cloud.secretmanager.v1.AccessSecretVersionRequest;
import com.google.cloud.secretmanager.v1.AccessSecretVersionResponse;
import com.google.cloud.secretmanager.v1.SecretManagerServiceClient;
import com.google.cloud.secretmanager.v1.SecretPayload;
import com.google.cloud.secretmanager.v1.stub.SecretManagerServiceStub;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableSet;
import com.google.protobuf.ByteString;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import org.apache.kafka.common.config.ConfigData;
import org.apache.kafka.common.config.ConfigException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

public class SecretsManagerConfigProviderTest {
  SecretManagerServiceStub serviceStub;
  SecretManagerConfigProvider provider;
  Map<String, String> settings;

  @BeforeEach
  public void beforeEach() {
    this.serviceStub = mock(SecretManagerServiceStub.class);
    this.provider = new SecretManagerConfigProvider();
    this.provider.secretManagerFactory = mock(SecretManagerFactory.class);
    when(this.provider.secretManagerFactory.create(any())).thenAnswer(
        invocationOnMock -> SecretManagerServiceClient.create(serviceStub)
    );
    this.settings = new LinkedHashMap<>();
    this.settings.put(SecretManagerConfigProviderConfig.PROJECT_ID_CONFIG, "1234");
    this.provider.configure(this.settings);
  }

  @AfterEach
  public void afterEach() throws IOException {
    this.provider.close();
  }

//  @Test
//  public void notFound() {
//    Throwable expected = new ResourceNotFoundException("Resource 'not/found' was not found.");
//    when(serviceStub.getSecretValue(any())).thenThrow(expected);
//    ConfigException configException = assertThrows(ConfigException.class, () -> {
//      this.provider.get("not/found");
//    });
//    assertEquals(expected, configException.getCause());
//  }
//
//  @Test
//  public void decryptionFailure() {
//    Throwable expected = new DecryptionFailureException("Could not decrypt resource 'not/found'.");
//    when(serviceStub.getSecretValue(any())).thenThrow(expected);
//    ConfigException configException = assertThrows(ConfigException.class, () -> {
//      this.provider.get("not/found");
//    });
//    assertEquals(expected, configException.getCause());
//  }

  UnaryCallable<AccessSecretVersionRequest, AccessSecretVersionResponse> success(String secretName, String expectedRequestName, String data) {
    return new UnaryCallable<AccessSecretVersionRequest, AccessSecretVersionResponse>() {
      @Override
      public ApiFuture<AccessSecretVersionResponse> futureCall(AccessSecretVersionRequest request, ApiCallContext context) {
        assertEquals(expectedRequestName, request.getName(), "Resource Path does not match.");
        AccessSecretVersionResponse response = AccessSecretVersionResponse.newBuilder()
            .setName(secretName)
            .setPayload(
                SecretPayload.newBuilder()
                    .setData(ByteString.copyFrom(data, StandardCharsets.UTF_8))
                    .build()
            )
            .build();
        return ApiFutures.immediateFuture(response);
      }
    };
  }

  UnaryCallable<AccessSecretVersionRequest, AccessSecretVersionResponse> failure(String expectedRequestName, Throwable ex) {
    return new UnaryCallable<AccessSecretVersionRequest, AccessSecretVersionResponse>() {
      @Override
      public ApiFuture<AccessSecretVersionResponse> futureCall(AccessSecretVersionRequest request, ApiCallContext context) {
        assertEquals(expectedRequestName, request.getName());
        return ApiFutures.immediateFailedFuture(ex);
      }
    };
  }


  @Test
  public void get() {
    final String expectedRequestName = "projects/1234/secrets/test-secret/versions/latest";
    final String secretName = "test-secret";
    final String payload = "{\n" +
        "  \"username\": \"asdf\",\n" +
        "  \"password\": \"asdf\"\n" +
        "}";
    Map<String, String> expected = ImmutableMap.of(
        "username", "asdf",
        "password", "asdf"
    );

    when(serviceStub.accessSecretVersionCallable()).thenReturn(
        success(secretName, expectedRequestName, payload)
    );
    ConfigData configData = this.provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expected, configData.data());
    assertEquals(this.provider.config.minimumSecretTTL, configData.ttl());
  }

  @Test
  public void getPrefixed() {
    this.settings.put(SecretManagerConfigProviderConfig.PREFIX_CONFIG, "staging-");
    this.provider.configure(this.settings);
    final String expectedRequestName = "projects/1234/secrets/staging-test-secret/versions/latest";
    final String secretName = "test-secret";
    final String responseSecretName = "staging-test-secret";
    final String payload = "{\n" +
        "  \"username\": \"asdf\",\n" +
        "  \"password\": \"asdf\"\n" +
        "}";
    Map<String, String> expected = ImmutableMap.of(
        "username", "asdf",
        "password", "asdf"
    );

    when(serviceStub.accessSecretVersionCallable()).thenReturn(
        success(responseSecretName, expectedRequestName, payload)
    );
    ConfigData configData = this.provider.get(secretName, ImmutableSet.of());
    assertNotNull(configData);
    assertEquals(expected, configData.data());
    assertEquals(this.provider.config.minimumSecretTTL, configData.ttl());
  }

  StatusCode statusCode(Status.Code statusCode) {
    return new GrpcStatusCode() {
      @Override
      public Status.Code getTransportCode() {
        return statusCode;
      }
    };
  }

  @Test
  public void getNotFound() {
    final String expectedRequestName = "projects/1234/secrets/test-secret/versions/latest";
    final String secretName = "test-secret";

    StatusRuntimeException exception = new StatusRuntimeException(Status.NOT_FOUND);
    when(serviceStub.accessSecretVersionCallable()).thenReturn(
        failure(expectedRequestName, new NotFoundException(
                exception,
                statusCode(Status.Code.NOT_FOUND),
                false
            )
        )
    );
    assertThrows(ConfigException.class, () -> {
      ConfigData configData = this.provider.get(secretName, ImmutableSet.of());
    });
  }


//
//  @Test
//  public void getPrefixed() {
//    this.provider.configure(
//        ImmutableMap.of(SecretManagerConfigProviderConfig.PREFIX_CONFIG, "prefixed")
//    );
//    final String secretName = "foo/bar/baz";
//    final String prefixedName = "prefixed/foo/bar/baz";
//    GetSecretValueResult result = new GetSecretValueResult()
//        .withName(prefixedName)
//        .withSecretString("{\n" +
//            "  \"username\": \"asdf\",\n" +
//            "  \"password\": \"asdf\"\n" +
//            "}");
//    Map<String, String> expected = ImmutableMap.of(
//        "username", "asdf",
//        "password", "asdf"
//    );
//    when(serviceStub.getSecretValue(any())).thenAnswer(invocationOnMock -> {
//      GetSecretValueRequest request =  invocationOnMock.getArgument(0);
//      assertEquals(prefixedName, request.getSecretId());
//      return result;
//    });
//    ConfigData configData = this.provider.get(secretName, ImmutableSet.of());
//    assertNotNull(configData);
//    assertEquals(expected, configData.data());
//
//  }


}
