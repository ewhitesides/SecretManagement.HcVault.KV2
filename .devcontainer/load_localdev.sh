#!/bin/bash

#start local dev instance of vault
nohup_file='/tmp/nohup.out'
nohup vault server -dev > $nohup_file &

#get token from nohup.out - wait for vault server to start up
token=''; i=0; max=10
while [ -z "$token" -a $i -lt $max ]; do
    token=$(grep 'Root Token:' $nohup_file | awk '{ print $3 }')
    sleep 5
    let "i+=1"
done

#create localdev source file
#$LOCALDEV var comes from environment (devcontainer.json)
cat << EOF > $LOCALDEV
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='$token'
EOF
