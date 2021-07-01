package io.confluent.csid.config.provider.vault;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import org.immutables.value.Value;

import java.util.Map;

@Value.Immutable
@JsonDeserialize(as = ImmutableBody.class)
public interface Body {
  @JsonProperty("data")
  Data data();

  @Value.Immutable
  @JsonDeserialize(as = ImmutableData.class)
  interface Data {
    @JsonProperty("data")
    Map<String, String> data();
  }
}
