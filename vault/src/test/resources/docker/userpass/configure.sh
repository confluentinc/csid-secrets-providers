vault status
vault auth enable userpass
vault policy write vault-read /policy.hcl
vault write auth/userpass/users/user1 password=password policies=vault-read

# vault write auth/ldap/config \
#   url="ldap://ldap" \
#   userattr="cn" \
#   binddn="cn=admin,dc=example,dc=org" \
#   bindpass="admin" \
#   userdn="dc=example,dc=org" \
#   discoverdn=true \
#   insecure_tls=false \
#   groupdn="ou=groups,dc=example,dc=org" \
#   token_max_ttl=30 \
#   starttls=false
#
# vault write auth/ldap/groups/vault policies=vault-read