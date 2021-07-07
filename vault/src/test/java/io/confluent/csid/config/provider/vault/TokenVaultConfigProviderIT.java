/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.vault;

import com.bettercloud.vault.SslConfig;
import com.bettercloud.vault.Vault;
import com.bettercloud.vault.VaultConfig;
import com.bettercloud.vault.VaultException;
import com.github.jcustenborder.docker.junit5.Compose;
import com.github.jcustenborder.docker.junit5.Port;
import com.google.common.collect.ImmutableSet;
import org.apache.kafka.common.config.ConfigData;
import org.apache.kafka.common.config.ConfigException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.net.InetSocketAddress;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

@Compose(dockerComposePath = "src/test/resources/docker/root-token/docker-compose.yml", clusterHealthCheck = VaultClusterHealthCheck.class)
public class TokenVaultConfigProviderIT extends VaultConfigProviderIT {
  @BeforeEach
  public void before(@Port(container = "vault", internalPort = 8200) InetSocketAddress address) throws VaultException {
    Map<String, String> settings = new LinkedHashMap<>();
    final String vaultUrl = String.format("http://%s:%s", address.getHostString(), address.getPort());
    settings.put(VaultConfigProviderConfig.ADDRESS_CONFIG, vaultUrl);
    settings.put(VaultConfigProviderConfig.TOKEN_CONFIG, Constants.TOKEN);

    this.configProvider = new VaultConfigProvider();
    this.configProvider.configure(settings);

    SslConfig config = new SslConfig()
        .verify(false)
        .build();
    VaultConfig vaultConfig = new VaultConfig()
        .address(vaultUrl)
        .token(Constants.TOKEN)
        .sslConfig(config)
        .build();
    this.vault = new Vault(vaultConfig);
  }
}
