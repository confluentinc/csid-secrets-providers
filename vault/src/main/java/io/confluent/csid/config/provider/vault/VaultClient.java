/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.vault;

import com.bettercloud.vault.VaultException;
import com.bettercloud.vault.response.LogicalResponse;

interface VaultClient {
  LogicalResponse read(String secret) throws VaultException;
}
