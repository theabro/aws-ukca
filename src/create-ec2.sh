#!/bin/bash -f

# script to generate set of UKCA VMs build on pre-made AMI image UMvn11.8
# taken from https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2.html

# take number of VMs (& corresponding key pairs) to make from command line input
num_vms=${1}

### THE FOLLOWING SETTINGS COME FROM CLOUDFRONT ###
# Virtual Private Cloud (VPC) id - set via CloudFront from template
vpc='vpc-XXXXXXXXX'

# security group
# set via CloudFront from template - allow ALL incoming traffic from all IPs on port 22
sgid='sg-XXXXXXXXXXX'

# PUBLIC Subnet ids - set via CloudFront from template
subnet0='subnet-XXXXXXXXXXX'
subnet1='subnet-XXXXXXXXXXX'
# Script will place even-numbered instances in subnet0 and odd-numbered instances in subnet1
### END OF CLOUDFRONT OPTIONS ###

# AMI id:
#   Ubuntu 18.04 with metomi-vms and UMvn13.0 installed.
#   UKCA Tutorial suite, required documentation/output & data.
#   Version 1.0, 2022-11-17.
# This now has a 50GB hard disk to give a bit more space just in case.
ami='ami-XXXXXXXXXXX'
# instance type - training requires a .large (2x vCPU, 8GB memory), but can test with t2.micro as it is free tier
# note that t2 are "burstable" and only allow 60% (36 min per hour) of full usage before throttling back to 30%. Use m5.large instead as this doesn't happen & is very similar cost.
#ins_type='t2.micro'
ins_type='m5.large'

# AWS CLI method - do not use currently
## step 1 - create security group. May not need to do this here and could just do via console
## https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-sg.html
## 1.1 set name of group
#sg='ukca_tr-sg'
## 1.2 only create security group if file containing info about it doesn't exist
#if [[ -f ../keys/${sg}.json ]]; then
#    echo "${sg} already exists"
#else
#    echo "making security group"
#    aws ec2 create-security-group --group-name ${sg} --description "UKCA training security group" --vpc-id ${vpc} > ../keys/${sg}.json
#fi
## 1.3 now save group id to a variable - rather hideous command as jq is not installed on a mac by default and
##     I don't want to install it via homebrew/macports
#sgid=`grep -i groupid ../keys/${sg}.json | awk -F\: '{print $2}' | sed 's/"//g' | awk '{print $1}'` 

# steps 2 & 3 - make a set of key pairs to connect to the VMs and then make the EC2 instances
# 2.1 make a directory to hold the keys if it doesn't already exist (also in .gitignore)
mkdir -p ../keys
# loop for making keys and instances
for i in `seq 1 ${num_vms}`; do
    # 2.2 make the keys themselves and set appropriate permissions
    # https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-keypairs.html
    # name the keypair - pad leading 0s
    keypair=`printf "ukca_key_tr%0*d" 2 ${i}`
    # check if the key already exists - need to delete from here and console to work from scratch
    if [[ -f ../keys/${keypair}.pem ]]; then
        echo "$${keypair}.pem already exists"
    else
        echo "making key pair ${keypair}.pem"
        aws ec2 create-key-pair --key-name ${keypair} --query 'KeyMaterial' --output text > ../keys/${keypair}.pem
        # set permissions
        chmod 400 ../keys/${keypair}.pem
    fi

    # create the instances themselves. Here we want to use a different key for each instance so need
    # to do in the loop rather than have a higher count. Also want to give each a unique name.
    # https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-instances.html
    # 3.1 give a name to the EC2 instance
    name=`printf "ukca_vm_tr%0*d" 2 ${i}`
    # check if we are odd or even to choose the subnet to use for this EC2 instance
    # this will split the instances across the 2 subnets
    if [[ $((i%2)) -eq 0 ]]; then
        subnet=${subnet0}
    else
        subnet=${subnet1}
    fi
    if [[ -f ../keys/${name}.json ]]; then
        echo "EC2 instance ${name} already exists"
    else
        echo "making EC2 instance ${name}"
        # 3.2 create the EC2 instance - check if we've already made one of the same name first
        aws ec2 run-instances --image-id ${ami} --count 1 --instance-type ${ins_type} --key-name ${keypair} --security-group-ids ${sgid} --subnet-id ${subnet} > ../keys/${name}.json
        # get the id to add a name tag to it, again a horrible command as don't have jq
        insid=`grep -i instanceid ../keys/${name}.json | awk -F\: '{print $2}' | sed 's/"//g' | sed 's/,//g' | awk '{print $1}'` 
        # 3.3 name the instance using tags
        aws ec2 create-tags --resources ${insid} --tags Key=Name,Value=${name}
        aws ec2 create-tags --resources ${insid} --tags Key=Event,Value=Training
    fi
done
