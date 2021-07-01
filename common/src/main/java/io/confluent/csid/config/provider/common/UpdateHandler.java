package io.confluent.csid.config.provider.common;

import org.apache.kafka.common.config.ConfigChangeCallback;
import org.apache.kafka.common.config.ConfigData;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.ScheduledExecutorService;
import java.util.stream.Collectors;

/**
 * The UpdateHandler is used to check the upstream secrets store for changes and schedule execution
 * of the callbacks that are attached.
 */
class UpdateHandler implements Runnable {
  private static final Logger log = LoggerFactory.getLogger(UpdateHandler.class);
  final ConfigDataHasher configDataHasher;
  final Map<String, Subscription> subscriptions;
  final String path;
  final SecretRetriever secretRetriever;
  final ScheduledExecutorService executorService;

  UpdateHandler(ConfigDataHasher configDataHasher, Map<String, Subscription> subscriptions, String path, SecretRetriever secretRetriever, ScheduledExecutorService executorService) {
    this.configDataHasher = configDataHasher;
    this.subscriptions = subscriptions;
    this.path = path;
    this.secretRetriever = secretRetriever;
    this.executorService = executorService;
  }

  @Override
  public void run() {
    final Subscription subscription = this.subscriptions.get(this.path);
    if (null == subscription) {
      log.warn("run() - No subscriptions were found for '{}'", this.path);
      return;
    }
    log.debug("run() - Refreshing data for path '{}'", this.path);
    Map<String, String> data = this.secretRetriever.retrieveSecret(path);
    Set<String> updated = configDataHasher.updateHash(path, data);
    if (updated.isEmpty()) {
      log.debug("run() - no updates detected for '{}'", this.path);
      return;
    }
    log.info("run() - Updates detected for '{}':'{}'", this.path, updated);
    subscription.states().entrySet()
        .stream()
        .filter(e -> e.getKey().keys().stream().anyMatch(updated::contains))
        .forEach(e -> {
          Map<String, String> updates = data.entrySet().stream()
              .filter(i -> e.getKey().keys().contains(i.getKey()))
              .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
          ConfigData configData = new ConfigData(updates);
          for (ConfigChangeCallback callback : e.getValue().callbacks()) {
            log.debug("run() - handing callback to executor for {}", callback);
            this.executorService.submit(() -> {
              callback.onChange(this.path, configData);
            });
          }
        });
  }
}
