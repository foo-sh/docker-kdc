#!/bin/sh

set -eu

umask 022

if [ -z "${LDAP_BASEDN+x}" ]; then
    LDAP_BASEDN="$(echo "$KRB5_REALM" | awk -F. '
      {
        for(i=1; i<=NF; i++) {
          printf "dc=" tolower($i)
          if ($i != $NF) {
            printf ","
          }
        }
      }
      END {
        print ""
      }')"
fi

if [ -z "${LDAP_URI+x}" ]; then
    LDAP_URI="ldaps://ldap$(echo "$LDAP_BASEDN" | sed -e 's/,\?[[:alpha:]]\+=/\./g')"
fi

cat <<EOF > /etc/kdcproxy.conf
[global]

[${KRB5_REALM}]
kerberos = kerberos+tcp://127.0.0.1
EOF

cat <<EOF > /var/kerberos/krb5kdc/kdc.conf
[libdefaults]
  default_realm = ${KRB5_REALM}

[logging]
  kdc = STDERR
  admin_server = STDERR
  default = STDERR

[kdcdefaults]
  kdc_listen = ""
  kdc_tcp_listen = 127.0.0.1:88

[realms]
  ${KRB5_REALM} = {
    database_module = ldap.$(echo "${KRB5_REALM}" | tr '[:upper:]' '[:lower:]')
    key_stash_file = /var/kerberos/krb5kdc/.k5.${KRB5_REALM}
    max_lifetime = 24h 0m 0s
    max_renewable_lifetime = 7d 0h 0m 0s
    master_key_type = aes256-cts-hmac-sha1-96
    supported_enctypes = aes256-cts-hmac-sha1-96:normal
  }

[dbmodules]
  ldap.$(echo "${KRB5_REALM}" | tr '[:upper:]' '[:lower:]') = {
    db_library = kldap
    disable_last_success = true
    disaable_lockout = true
    ldap_kerberos_container_dn = "ou=System,${LDAP_BASEDN}"
    ldap_kdc_dn = "uid=krb5kdc,cn=${KRB5_REALM},ou=System,${LDAP_BASEDN}"
    ldap_kadmind_dn = "uid=krb5kdc,cn=${KRB5_REALM},ou=System,${LDAP_BASEDN}"
    ldap_service_password_file = "/var/kerberos/krb5kdc/.k5.ldap.${KRB5_REALM}"
    ldap_servers = "${LDAP_URI}"
  }
EOF

cat <<EOF | kdb5_ldap_util stashsrvpw "uid=krb5kdc,cn=${KRB5_REALM},ou=System,${LDAP_BASEDN}"
$LDAP_BIND_PW
$LDAP_BIND_PW
EOF
cat <<EOF | kdb5_util stash 
$KRB5_STASH_PW
EOF

unset LDAP_BASEDN LDAP_BIND_PW LDAP_URI KRB5_REALM KRB5_STASH_PW

exec "$@"
