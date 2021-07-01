/**
 * Copyright Confluent
 */
package io.confluent.csid.config.provider.vault;

import com.bettercloud.vault.VaultException;
import com.bettercloud.vault.response.LogicalResponse;
import io.confluent.csid.config.provider.common.SecretRequest;

interface VaultClient {
  LogicalResponse read(SecretRequest request) throws VaultException;
}
