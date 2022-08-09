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

#set json file with vault vars
#pester tests will load this into powershell environment
output_file='./Test/.vault.json'
cat << EOF > $output_file
{
    "VAULT_ADDR":  "http://127.0.0.1:8200",
    "VAULT_TOKEN": "$token"
}
EOF
