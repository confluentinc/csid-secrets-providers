/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.common;

import org.apache.kafka.common.config.ConfigChangeCallback;
import org.apache.kafka.common.config.ConfigData;
import org.apache.kafka.common.config.ConfigException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.mockito.stubbing.Answer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

import static io.confluent.csid.config.provider.common.testing.TestUtils.mapOf;
import static io.confluent.csid.config.provider.common.testing.TestUtils.setOf;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

public class AbstractConfigProviderTests {
  private static final Logger log = LoggerFactory.getLogger(AbstractConfigProviderTests.class);
  MockConfigProvider provider;
  Map<String, String> settings = new LinkedHashMap<>();
  ScheduledExecutorService executorService;

  List<ScheduledRunnable> scheduledRunnables;

  @BeforeEach
  public void before() {
    this.provider = mock(MockConfigProvider.class, Mockito.CALLS_REAL_METHODS);
    this.settings = new LinkedHashMap<>();
    this.scheduledRunnables = new ArrayList<>();
    this.executorService = mock(ScheduledExecutorService.class);
    this.provider.executorServiceFactory = mock(ScheduledExecutorServiceFactory.class);
    when(this.provider.executorServiceFactory.create(any())).thenReturn(this.executorService);
    when(this.executorService.submit(any(Callable.class))).thenAnswer(
        invocationOnMock -> {
          Future<Map<String, String>> future = mock(Future.class);
          Callable<Map<String, String>> callable = invocationOnMock.getArgument(0);
          try {
            Map<String, String> result = callable.call();
            when(future.get(anyLong(), any(TimeUnit.class))).thenReturn(result);
          } catch (Exception ex) {
            ExecutionException exception = new ExecutionException("Exception thrown", ex);
            when(future.get(anyLong(), any(TimeUnit.class))).thenThrow(exception);
          }
          return future;
        }
    );
    when(this.executorService.schedule(any(Callable.class), anyLong(), any(TimeUnit.class))).thenAnswer(
        invocationOnMock -> {
          ScheduledFuture<Map<String, String>> future = mock(ScheduledFuture.class);
          Callable<Map<String, String>> callable = invocationOnMock.getArgument(0);
          try {
            Map<String, String> result = callable.call();
            when(future.get(anyLong(), any(TimeUnit.class))).thenReturn(result);
          } catch (Exception ex) {
            ExecutionException exception = new ExecutionException("Exception thrown", ex);
            when(future.get(anyLong(), any(TimeUnit.class))).thenThrow(exception);
          }
          return future;
        }
    );
    when(this.executorService.scheduleAtFixedRate(any(Runnable.class), anyLong(), anyLong(), any(TimeUnit.class))).thenAnswer(
        invocationOnMock -> {
          ScheduledFuture<?> future = mock(ScheduledFuture.class);
          Runnable runnable = invocationOnMock.getArgument(0);
          this.scheduledRunnables.add(
              ImmutableScheduledRunnable.builder()
                  .runnable(runnable)
                  .future(future)
                  .build()
          );

          return future;
        }
    );
    when(this.executorService.submit(any(Runnable.class))).thenAnswer(
        invocationOnMock -> {
          Future<?> future = mock(Future.class);
          Runnable runnable = invocationOnMock.getArgument(0);
          try {
            runnable.run();
          } catch (Exception ex) {
            ExecutionException exception = new ExecutionException("Exception thrown", ex);
            when(future.get(anyLong(), any(TimeUnit.class))).thenThrow(exception);
          }
          return future;
        }
    );

  }

  void runScheduledRunnables() throws Exception {
    for (ScheduledRunnable scheduledRunnable : this.scheduledRunnables) {
      try {
        scheduledRunnable.runnable().run();
        when(scheduledRunnable.future().get(anyLong(), any(TimeUnit.class))).thenReturn(null);
        when(scheduledRunnable.future().get()).thenReturn(null);
      } catch (Exception ex) {
        ExecutionException exception = new ExecutionException("Exception thrown", ex);
        when(scheduledRunnable.future().get(anyLong(), any(TimeUnit.class))).thenThrow(exception);
      }
    }

  }

  @AfterEach
  public void after() throws IOException, InterruptedException {
    this.provider.close();
    verify(this.executorService, times(1)).shutdown();
    verify(this.executorService, times(1)).awaitTermination(anyLong(), any(TimeUnit.class));
  }

  void assertConfigData(Map<String, String> expectedData, Long expectedTTL, ConfigData actual) {
    assertNotNull(actual, "actual should not be null");
    assertEquals(expectedTTL, actual.ttl(), "ttl should match.");
    assertEquals(expectedData, actual.data(), "data should match expected.");
  }

  @Test
  public void getNoKeysSpecified() throws Exception {
    this.provider.configure(this.settings);
    Map<String, String> expected = mapOf(
        "username", "db123",
        "password", "afg789dfgadf7a",
        "port", "54321"
    );
    final String path = "secret-1234";
    when(this.provider.getSecret(any())).thenReturn(expected);

    ConfigData actual = this.provider.get(path);
    verifyExecutorService(1, 0);
    assertConfigData(expected, null, actual);
  }

  @Test
  public void getThirdTimesACharm() throws Exception {
    log.warn("Because this test is using a mocked ScheduledExecutorService all calls to schedule() immediately.");
    this.provider.configure(this.settings);
    Map<String, String> expected = mapOf(
        "username", "db123",
        "password", "afg789dfgadf7a",
        "port", "54321"
    );
    final String path = "secret-1234";
    when(this.provider.getSecret(any()))
        .thenThrow(new RetriableException("It broke once"))
        .thenThrow(new RetriableException("It broke twice"))
        .thenReturn(expected);
    ConfigData actual = this.provider.get(path);
    assertConfigData(expected, null, actual);
    verifyExecutorService(1, 2);
  }

  void verifyExecutorService(int submitInvocations, int scheduleInvocations) throws Exception {
    verify(this.provider.executorService, times(submitInvocations)).submit(any(Callable.class));
    verify(this.provider.executorService, times(scheduleInvocations)).schedule(any(Callable.class), eq(this.provider.config.retryIntervalSeconds), eq(TimeUnit.SECONDS));
    int getSecretInvocations = submitInvocations + scheduleInvocations;
    verify(this.provider, times(getSecretInvocations)).getSecret(any());
  }

  @Test
  public void getSpecificKeys() throws Exception {
    this.provider.configure(this.settings);
    Map<String, String> input = mapOf(
        "username", "db123",
        "password", "afg789dfgadf7a",
        "port", "54321"
    );
    Map<String, String> expected = mapOf(
        "username", "db123",
        "password", "afg789dfgadf7a"
    );
    final String path = "secret-1234";
    when(this.provider.getSecret(any())).thenReturn(input);
    ConfigData actual = this.provider.get(path, setOf("username", "password"));
    verifyExecutorService(1, 0);
    assertConfigData(expected, null, actual);
  }

  @Test
  public void getNotFound() throws Exception {
    this.provider.configure(this.settings);

    final String path = "secret-1234";
    when(this.provider.getSecret(any())).thenReturn(null);
    assertThrows(ConfigException.class, () -> {
      ConfigData actual = this.provider.get(path);
    });
    verifyExecutorService(1, 0);
  }


  @Test
  public void getException() throws Exception {
    this.provider.configure(this.settings);
    final String path = "secret-1234";
    when(this.provider.getSecret(any())).thenThrow(new IllegalStateException("Something is broke"));
    assertThrows(ConfigException.class, () -> {
      this.provider.get(path);
    });
    verifyExecutorService(1, 0);
  }

  @Test
  public void subscribeDisabled() {
    this.settings.put(AbstractConfigProviderConfig.POLLING_ENABLED_CONFIG, "false");
    this.provider.configure(this.settings);
    final String path = "asdfasd";
    final Set<String> keys = setOf("username", "password");
    final ConfigChangeCallback callback = mock(ConfigChangeCallback.class);
    assertThrows(UnsupportedOperationException.class, () -> {
      this.provider.subscribe(path, keys, callback);
    });
  }


  @Test
  public void subscribeMultiple() throws Exception {
    this.provider.configure(this.settings);
    Map<String, String> initial = mapOf(
        "username", "db123",
        "password", "afg789dfgadf7a"
    );
    Map<String, String> updated = mapOf(
        "username", "db1234",
        "password", "asdfadsiasdfes"
    );
    final String path = "test";
    final Set<String> keys = setOf("username", "password");
    when(this.provider.getSecret(any()))
        .thenReturn(initial)
        .thenReturn(updated)
        .thenReturn(updated);
    ConfigData initialCall = this.provider.get(path, keys);
    assertConfigData(initial, null, initialCall);
    Answer<Object> assertConfigData = invocationOnMock -> {
      String p = invocationOnMock.getArgument(0);
      assertEquals(path, p);
      ConfigData actual = invocationOnMock.getArgument(1);
      assertConfigData(updated, null, actual);
      return null;
    };
    ConfigChangeCallback callback0 = mock(ConfigChangeCallback.class);
    doAnswer(assertConfigData).when(callback0).onChange(eq(path), any(ConfigData.class));
    this.provider.subscribe(path, keys, callback0);
    this.provider.subscribe(path, keys, callback0);
    ConfigChangeCallback callback1 = mock(ConfigChangeCallback.class);
    doAnswer(assertConfigData).when(callback1).onChange(eq(path), any(ConfigData.class));
    this.provider.subscribe(path, keys, callback1);
    runScheduledRunnables();
    runScheduledRunnables();
    verify(callback0, times(1)).onChange(eq(path), any(ConfigData.class));
    verify(callback1, times(1)).onChange(eq(path), any(ConfigData.class));
  }

  @Test
  public void unsubscribeMultiple() throws Exception {
    this.provider.configure(this.settings);
    Map<String, String> initial = mapOf(
        "username", "db123",
        "password", "afg789dfgadf7a"
    );
    Map<String, String> updated = mapOf(
        "username", "db1234",
        "password", "asdfadsiasdfes"
    );
    final String path = "test";
    final Set<String> keys = setOf("username", "password");
    when(this.provider.getSecret(any()))
        .thenReturn(mapOf(
            "username", "db123",
            "password", "afg789dfgadf7a"
        ))
        .thenReturn(mapOf(
            "username", "db1234",
            "password", "asdfadsiasdfes"
        ))
        .thenReturn(mapOf(
            "username", "db1234",
            "password", "fdasdfasdfas"
        ))
        .thenReturn(mapOf(
            "username", "db1234",
            "password", "asdfadsfasdasdafsd"
        ));
    ConfigData initialCall = this.provider.get(path, keys);
    assertConfigData(initial, null, initialCall);
    ConfigChangeCallback callback0 = mock(ConfigChangeCallback.class);
    this.provider.subscribe(path, keys, callback0);
    this.provider.subscribe(path, keys, callback0);
    ConfigChangeCallback callback1 = mock(ConfigChangeCallback.class);
    this.provider.subscribe(path, keys, callback1);
    runScheduledRunnables();
    runScheduledRunnables();
    this.provider.unsubscribe(path, keys, callback1);
    runScheduledRunnables();
    verify(callback0, times(3)).onChange(eq(path), any(ConfigData.class));
    verify(callback1, times(2)).onChange(eq(path), any(ConfigData.class));
  }

  @Test
  public void unsubscribeDisabled() {
    this.settings.put(AbstractConfigProviderConfig.POLLING_ENABLED_CONFIG, "false");
    this.provider.configure(this.settings);
    final String path = "asdfasd";
    final Set<String> keys = setOf("username", "password");
    final ConfigChangeCallback callback = mock(ConfigChangeCallback.class);
    assertThrows(UnsupportedOperationException.class, () -> {
      this.provider.unsubscribe(path, keys, callback);
    });
  }


  @Test
  public void unsubscribeAll() {
    this.provider.configure(this.settings);
    final String path = "test";
    final Set<String> keys = setOf("username", "password");
    ConfigChangeCallback callback0 = mock(ConfigChangeCallback.class);
    this.provider.subscribe(path, keys, callback0);
    assertEquals(1, this.provider.subscriptions.size());
    this.provider.unsubscribeAll();
    assertTrue(this.provider.subscriptions.isEmpty());
    for (ScheduledRunnable scheduledRunnable : this.scheduledRunnables) {
      verify(scheduledRunnable.future(), times(1)).cancel(anyBoolean());
    }
  }

  @Test
  public void unsubscribeAllDisabled() {
    this.settings.put(AbstractConfigProviderConfig.POLLING_ENABLED_CONFIG, "false");
    this.provider.configure(this.settings);
    assertThrows(UnsupportedOperationException.class, () -> {
      this.provider.unsubscribeAll();
    });
  }
}
