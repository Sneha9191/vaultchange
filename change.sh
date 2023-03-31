#!/bin/bash
url="http://54.204.152.86:8200"
export VAULT_ADDR=$url
export VAULT_TOKEN=$(grep "Initial Root Token" vault_unseal_token | awk -F":" '{print$2}' | xargs)

# Generate a random password
#new_password=$(openssl rand -base64 16)

# Retrieve a list of all secrets paths in the "prod" path
secret_paths=$(vault kv list -format=json dev | jq -r '.[]')

# Loop over each secrets path in the list
for secrets_path in ${secret_paths[@]}
do
  # Retrieve the database name and username from Hashicorp Vault
  dbname=$(vault kv get -field=dbname "dev/${secrets_path}")
  username=$(vault kv get -field=username "dev/${secrets_path}")
  dbserver=$(vault kv get -field=dbserver "dev/${secrets_path}")
  password=$(vault kv get -field=password "dev/${secrets_path}")
  new_password=$(openssl rand -base64 6)

# to limit versions of secrets

  #vault kv metadata put -max-versions=4 prod/${secrets_path}
  # Connect to the database and change the password
  mysql -u ${username} -p${password} -e "ALTER USER '${username}'@'${dbserver}' IDENTIFIED BY '${new_password}';"

  # Update the password in Hashicorp Vault
  vault kv patch dev/${secrets_path} password=${new_password}

  # Verify the password update
  mysql -u ${username} -p${new_password} -e "SELECT 'Password updated successfully for ${dbname}!';"
done
