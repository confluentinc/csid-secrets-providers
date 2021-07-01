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
import com.palantir.docker.compose.connection.Cluster;
import com.palantir.docker.compose.connection.Container;
import com.palantir.docker.compose.connection.DockerPort;
import com.palantir.docker.compose.connection.waiting.ClusterHealthCheck;
import com.palantir.docker.compose.connection.waiting.SuccessOrFailure;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class VaultClusterHealthCheck implements ClusterHealthCheck {
  private static final Logger log = LoggerFactory.getLogger(VaultClusterHealthCheck.class);

  @Override
  public SuccessOrFailure isClusterHealthy(Cluster cluster) throws InterruptedException {
    final Container container = cluster.container("vault");
    final DockerPort dockerPort = container.port(8200);

    return SuccessOrFailure.onResultOf(() -> {

      SslConfig sslConfig = new SslConfig()
          .verify(false);

      VaultConfig config = new VaultConfig()
          .sslConfig(sslConfig)
          .address(String.format("http://%s:%s", dockerPort.getIp(), dockerPort.getExternalPort()))
          .token(Constants.TOKEN);
      Vault vault = new Vault(config);

      try {
        vault.logical().list("secret");
      } catch (Exception ex) {
        log.error("Exception thrown listing secrets", ex);
        return false;
      }

      return true;
    });
  }
}
