/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.common;

import io.confluent.csid.config.provider.annotations.DocumentationTip;
import org.apache.kafka.common.config.ConfigChangeCallback;
import org.apache.kafka.common.config.ConfigData;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.common.config.ConfigException;
import org.apache.kafka.common.config.provider.ConfigProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import static io.confluent.csid.config.provider.common.SecretRequestParser.parse;
import static io.confluent.csid.config.provider.common.SecretRequestParser.parseModifyRequest;

@DocumentationTip("Config providers can be used with anything that supports the AbstractConfig base class that is shipped with Apache Kafka.")
public abstract class AbstractConfigProvider<CONFIG extends AbstractConfigProviderConfig> implements ConfigProvider, SecretRetriever {
  private static final Logger log = LoggerFactory.getLogger(AbstractConfigProvider.class);
  protected CONFIG config;
  protected ScheduledExecutorService executorService;
  //TODO: Comeback and make sure that a thread factory sets the thread name to make troubleshooting a little easier.
  ScheduledExecutorServiceFactory executorServiceFactory = config -> Executors.newScheduledThreadPool(config.threadCount);
  Map<String, Subscription> subscriptions;
  ConfigDataHasher configDataHasher;
  private SecretModifier secretModifier;

  /**
   * Method is used to load the config.
   *
   * @param settings settings that are supplied to the config provider
   * @return config based on the supplied settings
   */
  protected abstract CONFIG config(Map<String, ?> settings);

  /**
   * Method is called after the AbstractConfigProvider has been configured.
   */
  protected abstract void configure();

  protected void setSecretModifier(SecretModifier secretModifier) {
    this.secretModifier = secretModifier;
  }

  /**
   * Method is used to retrieve all of the entries that are stored in the specified store.
   *
   * @param secretRequest Name of the store to retrieve data for
   * @return Map containing all entries in the specified location. Null if not found.
   * @throws RetriableException Informs the caller that an exception has occurred but the operation can be retried.
   */
  protected abstract Map<String, String> getSecret(SecretRequest secretRequest) throws Exception;

  /**
   * Return a copy of the ConfigDef to help with documentation.
   *
   * @return
   */
  public abstract ConfigDef config();

  @Override
  public Map<String, String> retrieveSecret(SecretRequest secretRequest) {
    Future<Map<String, String>> future;

    Callable<Map<String, String>> callable = () -> {
      log.debug("retrieveSecret() - Calling getSecret('{}')", secretRequest);
      return getSecret(secretRequest);
    };

    Exception lastException = null;
    int attempt = 0;
    while (attempt < this.config.retryCount) {
      attempt++;
      log.trace("retrieveSecret() - attempt {} of {}", attempt, this.config.retryCount);
      if (1 == attempt) {
        log.debug("retrieveSecret() - Submitting first attempt for '{}' to run immediately.", secretRequest);
        future = this.executorService.submit(callable);
      } else {
        log.debug("retrieveSecret() - Submitting attempt {} for '{}' to run in {} seconds", attempt, secretRequest, this.config.retryIntervalSeconds);
        future = this.executorService.schedule(callable, this.config.retryIntervalSeconds, TimeUnit.SECONDS);
      }
      log.trace("retrieveSecret() - {}", this.executorService);

      try {
        return future.get(this.config.timeoutSeconds, TimeUnit.SECONDS);
      } catch (ExecutionException ex) {
        if (ex.getCause() instanceof RetriableException) {
          log.warn("retrieveSecret() - RetriableException thrown. Retrying if attempt(s) are available.", ex.getCause());
          lastException = ex;
        } else {
          log.error("retrieveSecret() - Exception thrown. Not retriable.", ex.getCause());
          throw createConfigException(secretRequest, ex.getCause());
        }
      } catch (TimeoutException ex) {
        log.warn("retrieveSecret() - Timeout calling getSecret('{}'). Retrying if attempt(s) are available.", secretRequest);
        if (!future.isDone()) {
          future.cancel(true);
        }
        lastException = ex;
      } catch (InterruptedException ex) {
        throw createConfigException(secretRequest, ex);
      }
    }

    throw createConfigException(secretRequest, lastException);
  }

  ConfigException createConfigException(SecretRequest storeName, Throwable causedBy) {
    ConfigException configException = new ConfigException(
            String.format("Exception thrown while retrieving '%s'. See log for previous exceptions", storeName)
    );
    configException.initCause(causedBy);
    return configException;
  }

  public ConfigData get(String path) {
    return get(path, Collections.emptySet());
  }

  public ConfigData get(String path, Set<String> keys) {
    log.debug("get(request = '{}' keys = '{}'", path, keys);
    SecretRequest request = parse(path);

    Map<String, String> data = retrieveSecret(request);
    //TODO: Verify this functionality.
    if (null == data || data.isEmpty()) {
      log.error("get() - Could not find request '{}}'", request);
      throw new ConfigException(
              String.format("Could not find secret for request '%s'", request)
      );
    }
    this.configDataHasher.updateHash(request, data);

    final Map<String, String> result;

    if (null != keys && !keys.isEmpty()) {
      Set<String> misses = new LinkedHashSet<>();

      Map<String, String> r = new LinkedHashMap<>();
      for (String key : keys) {
        if (data.containsKey(key)) {
          String value = data.get(key);
          r.put(key, value);
        } else {
          misses.add(key);
        }
      }
      if (!misses.isEmpty()) {
        throw new ConfigException(
                String.format(
                        "Key(s) '%s' are missing for request '%s'",
                        String.join("', '", misses),
                        request
                )
        );
      }
      result = r;
    } else {
      result = data;
    }

    return new ConfigData(result);
  }

  public void createSecret(String path, String value) {
    if (secretModifier != null) {
      PutSecretRequest request = parseModifyRequest(path, value);
      try {
        secretModifier.createSecret(request);
      } catch (Exception e) {
        throw new ConfigException(String.format("Could not create secret for request '%s'", request), e);
      }
    } else {
      throw new UnsupportedOperationException();

    }
  }

  public void updateSecret(String path, String value) {
    if (secretModifier != null) {
      PutSecretRequest request = parseModifyRequest(path, value);
      try {
        secretModifier.updateSecret(request);
      } catch (Exception e) {
        throw new ConfigException(String.format("Could not update secret for request '%s'", request), e);
      }
    } else {
      throw new UnsupportedOperationException();
    }
  }

  public void deleteSecret(String path) {
    if (secretModifier != null) {
      SecretRequest request = parse(path);
      try {
        secretModifier.deleteSecret(request);
      } catch (Exception e) {
        throw new ConfigException(String.format("Could not delete secret for request '%s'", request), e);
      }
    } else {
      throw new UnsupportedOperationException();

    }
  }


  public void close() throws IOException {
    if (null != this.executorService) {
      log.debug("close() - Shutting down ScheduledExecutorService {}", this.executorService);
      this.executorService.shutdown();
      try {
        final long wait = 3L;
        log.debug("close() - Waiting {} seconds for ScheduledExecutorService to terminate", wait);
        if (this.executorService.awaitTermination(wait, TimeUnit.SECONDS)) {
          log.debug("close() - ScheduledExecutorService terminated");
        } else {
          log.warn("close() - ScheduledExecutorService took longer than {} second(s) to terminate", wait);
        }
      } catch (InterruptedException e) {
        log.warn("awaitTermination of executor service interrupted.", e);
      }
    }
  }


  public void configure(Map<String, ?> settings) {
    this.config = config(settings);
    this.executorService = this.executorServiceFactory.create(this.config);
    this.subscriptions = new ConcurrentHashMap<>();
    this.configDataHasher = new ConfigDataHasher();
    configure();
  }


  @Override
  public synchronized void subscribe(String path, Set<String> keys, ConfigChangeCallback callback) {
    if (!this.config.pollingEnabled) {
      throw new UnsupportedOperationException();
    }
    SecretRequest request = parse(path);
    Subscription.Key key = ImmutableKey.builder()
            .keys(keys)
            .build();
    log.info("subscribe(request = '{}' keys='{}')", request, keys);
    Subscription subscription = this.subscriptions.compute(request.raw(), (s, existing) -> {
      ImmutableSubscription.Builder builder = ImmutableSubscription.builder()
              .path(request.raw());

      ImmutableState.Builder stateBuilder;

      if (null != existing) {
        builder.future(existing.future());
        for (Map.Entry<Subscription.Key, Subscription.State> entry : existing.states().entrySet()) {
          if (key.equals(entry.getKey())) {
            continue;
          }
          builder.putStates(entry);
        }

        Subscription.State existingState = existing.states().get(key);
        if (null != existingState) {
          stateBuilder = ImmutableState.builder()
                  .from(existingState);

          if (existingState.callbacks().contains(callback)) {
            log.warn("subscribe() - callback already exists.");
          } else {
            log.trace("subscribe() - adding callback to existing callback(s).");
            stateBuilder = stateBuilder
                    .addCallbacks(callback);
          }
        } else {
          stateBuilder = ImmutableState.builder()
                  .addCallbacks(callback);
        }
      } else {
        ScheduledFuture<?> future = this.executorService.scheduleAtFixedRate(
                new UpdateHandler(
                        this.configDataHasher,
                        this.subscriptions,
                        request,
                        this,
                        this.executorService
                ),
                0,
                this.config.pollingIntervalSeconds,
                TimeUnit.SECONDS
        );
        builder.future(future);

        stateBuilder = ImmutableState.builder()
                .addCallbacks(callback);
      }

      Subscription.State state = stateBuilder.build();

      builder.putStates(key, state);
      return builder.build();
    });
    log.trace("subscribe() - subscription = '{}'", subscription);
  }

  @Override
  public synchronized void unsubscribe(String path, Set<String> keys, ConfigChangeCallback callback) {
    if (!this.config.pollingEnabled) {
      throw new UnsupportedOperationException();
    }
    SecretRequest request = parse(path);
    Subscription.Key key = ImmutableKey.builder()
            .keys(keys)
            .build();
    log.info("unsubscribe(request = '{}' keys='{}')", request, keys);
    this.subscriptions.compute(request.raw(), (s, existing) -> {
      if (null == existing) {
        return null;
      }
      Subscription.State state = existing.states().get(key);
      if (null == state) {
        log.info("unsubscribe(request = '{}' keys='{}') - subscription for keys does not exist.", request, keys);
        return existing;
      }
      if (!state.callbacks().contains(callback)) {
        log.info("unsubscribe(request = '{}' keys='{}') - callback for keys does not exist.", request, keys);
        return existing;
      }
      ImmutableSubscription.Builder subscriptionBuilder = ImmutableSubscription.builder()
              .future(existing.future())
              .path(existing.path());
      Map<Subscription.Key, Subscription.State> states = new LinkedHashMap<>(existing.states());
      if (state.callbacks().size() > 1) {
        ImmutableState.Builder stateBuilder = ImmutableState.builder();
        state.callbacks()
                .stream()
                .filter(c -> !Objects.equals(c, callback))
                .forEach(stateBuilder::addCallbacks);
        states.put(key, stateBuilder.build());
      } else {
        log.debug("unsubscribe(request = '{}' keys='{}') - removing all callbacks.", request, keys);
        states.remove(key);
      }
      if (states.isEmpty()) {
        log.debug("unsubscribe() - No subscriptions for request '{}'. Removing monitor.", request);
        existing.future().cancel(true);
        return null;
      } else {
        subscriptionBuilder.putAllStates(states);
      }
      return subscriptionBuilder.build();
    });
  }

  @Override
  public synchronized void unsubscribeAll() {
    if (!this.config.pollingEnabled) {
      throw new UnsupportedOperationException();
    }
    for (Map.Entry<String, Subscription> subscriptionEntry : this.subscriptions.entrySet()) {
      log.info("unsubscribeAll() - Canceling UpdateHandler for {}", subscriptionEntry.getKey());
      subscriptionEntry.getValue().future().cancel(true);
    }
    this.subscriptions.clear();
  }
}
