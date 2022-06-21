#!/bin/bash -f

# use the AWS EC2 CLI to get the name information of the running instances - this tells us how many we have
names=`aws ec2 describe-instances --filter "Name=instance-state-name,Values=running" --filter "Name=tag:Event,Values=Training" --query "Reservations[*].Instances[*].Tags[?Key=='Name']" --output=text | awk '{print $2}'`

# use these names in a loop to get the IP addresses and make a nicer formatted output (i.e. all on one line)
for n in ${names}; do
    ip=`aws ec2 describe-instances --filter "Name=tag:Name,Values=${n}" --query "Reservations[*].Instances[*].PublicIpAddress[]" --output=text`
    key=`aws ec2 describe-instances --filter "Name=tag:Name,Values=${n}" --query "Reservations[*].Instances[*].KeyName[]" --output=text`
    printf "%s,%s,%s\n" ${n} ${key} ${ip}
done