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

import com.bettercloud.vault.Vault;
import com.bettercloud.vault.VaultException;
import com.google.common.collect.ImmutableSet;
import org.apache.kafka.common.config.ConfigData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;


//@Compose(dockerComposePath = "docker-compose.yml", clusterHealthCheck = VaultClusterHealthCheck.class)
public abstract class VaultConfigProviderIT {
  protected VaultConfigProvider configProvider;
  protected Vault vault;

  @AfterEach
  public void after() throws IOException {
    this.configProvider.close();
  }

  @Test
  public void missing() {
    ConfigData configData = this.configProvider.get("secret/missing");
    assertNotNull(configData);
    assertTrue(configData.data().isEmpty());
  }

  @Test
  public void valid() throws VaultException {
    final Map<String, Object> expected = new LinkedHashMap<>();
    expected.put("one", "1");
    expected.put("two", "2");
    expected.put("three", "3");
    expected.put("four", "4");
    expected.put("five", "5");
    final String path = "secret/valid";
    this.vault.logical().write(path, expected);
    ConfigData configData = this.configProvider.get(path);
    assertNotNull(configData);
    assertEquals(expected, configData.data());
  }

  @Test
  public void selected() throws VaultException {
    final Map<String, Object> input = new LinkedHashMap<>();
    input.put("one", "1");
    input.put("two", "2");
    input.put("three", "3");
    input.put("four", "4");
    input.put("five", "5");
    final Set<String> keys = ImmutableSet.of("one", "three", "five");
    final Map<String, Object> expected = input.entrySet()
        .stream()
        .filter(e -> keys.contains(e.getKey()))
        .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
    final String path = "secret/selected";
    this.vault.logical().write(path, input);
    ConfigData configData = this.configProvider.get(path, keys);
    assertNotNull(configData);
    assertEquals(expected, configData.data());
  }


}
