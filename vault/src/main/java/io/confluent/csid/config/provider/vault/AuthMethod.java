package io.confluent.csid.config.provider.vault;

import io.confluent.csid.config.provider.common.docs.Description;

enum AuthMethod {
  @Description("Authentication via the `token\n" + "<https://www.vaultproject.io/docs/auth/token>`_. endpoint.")
  Token,
  @Description("Authentication via the `ldap\n" + "<https://www.vaultproject.io/docs/auth/token>`_. endpoint.")
  LDAP,
  @Description("Authentication via the `ldap\n" + "<https://www.vaultproject.io/docs/auth/token>`_. endpoint.")
  UserPass,
  @Description("Authentication via the `ldap\n" + "<https://www.vaultproject.io/docs/auth/token>`_. endpoint.")
  Certificate,
  @Description("Authentication via the `ldap\n" + "<https://www.vaultproject.io/docs/auth/token>`_. endpoint.")
  AppRole,

}
