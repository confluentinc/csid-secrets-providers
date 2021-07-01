/**
 * Copyright © 2021 Jeremy Custenborder (jcustenborder@gmail.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
