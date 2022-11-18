#!/bin/bash -f

# loop through file containing login details, VM name, key name, and IP address

while IFS="," read -r username password vmname keyname ipaddr
do
  echo "username = $username"
  echo "password = $password"
  echo "vmname = $vmname"
  echo "keyname = $keyname"
  echo "ipaddr = $ipaddr"

  /usr/bin/expect -f ./mcs_ssh.expect "$username" "$password"
  
done < ../mcs_logins.csv
