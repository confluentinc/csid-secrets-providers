package io.confluent.csid.config.provider.vault;

import java.util.Collections;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

class AuthHandlers {
  static final Map<AuthMethod, AuthHandler> HANDLER_MAP;

  static {
    Map<AuthMethod, AuthHandler> handlers = Stream.of(
        new AuthHandler.Token(),
        new AuthHandler.LDAP(),
        new AuthHandler.UserPass(),
        new AuthHandler.Certificate()
    )
        .collect(Collectors.toMap(AuthHandler::method, a -> a));

    HANDLER_MAP = Collections.unmodifiableMap(handlers);
  }

  public static AuthHandler get(AuthMethod method) {
    return HANDLER_MAP.get(method);
  }
}
