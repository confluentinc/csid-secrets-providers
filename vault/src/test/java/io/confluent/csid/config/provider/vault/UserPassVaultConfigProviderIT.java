/**
 * Copyright Confluent 2021
 */
package io.confluent.csid.config.provider.vault;

import com.bettercloud.vault.SslConfig;
import com.bettercloud.vault.Vault;
import com.bettercloud.vault.VaultConfig;
import com.bettercloud.vault.VaultException;
import com.github.jcustenborder.docker.junit5.Compose;
import com.github.jcustenborder.docker.junit5.DockerContainer;
import com.github.jcustenborder.docker.junit5.Port;
import com.palantir.docker.compose.connection.Container;
import org.junit.jupiter.api.BeforeEach;

import java.net.InetSocketAddress;
import java.util.LinkedHashMap;
import java.util.Map;

@Compose(dockerComposePath = "src/test/resources/docker/userpass/docker-compose.yml", clusterHealthCheck = VaultClusterHealthCheck.class)
public class UserPassVaultConfigProviderIT extends VaultConfigProviderIT {
  @BeforeEach
  public void before(@DockerContainer(container = "vault") Container container,
                     @Port(container = "vault", internalPort = 8200) InetSocketAddress address) throws VaultException {
    Map<String, String> settings = new LinkedHashMap<>();
    final String vaultUrl = String.format("http://%s:%s", address.getHostString(), address.getPort());
    settings.put(VaultConfigProviderConfig.ADDRESS_CONFIG, vaultUrl);
    settings.put(VaultConfigProviderConfig.AUTH_METHOD_CONFIG, AuthMethod.UserPass.name());
    settings.put(VaultConfigProviderConfig.USERNAME_CONFIG, "user1");
    settings.put(VaultConfigProviderConfig.PASSWORD_CONFIG, "password");

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


    /*


     */

  }
}
