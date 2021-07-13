# aws-ukca
Ansible playbook for running UKCA on an AWS EC2 instance

Based on instructions from [Dave Sugden (April 2020)](https://davelms.medium.com/use-ansible-to-create-and-configure-ec2-instances-on-aws-cfbb0ed019bf) and [Vivek Gite (February 2018)](https://www.cyberciti.biz/faq/how-to-create-aws-ec2-key-using-ansible/)

Tested on macOS 10.13.6. On macOS you may first need to
```
export PATH="/Users/[YOUR USERNAME]/Library/Python/2.7/bin:$PATH"
```
Before you start, install the [AWS CLI](https://aws.amazon.com/cli/) and run the 
```
aws configure
```
to set your IAM's `aws_access_key_id`, `aws_secret_access_key`, and default `region`. These are put in the `~/.aws/credentials` and `~/.aws/config` files.

This is a 2 stage process:

1. Create the EC2 instance.
2. Provision the EC2 instance with the required packages and settings to run FCM, Rose, & Cylc and prepare it for UM-UKCA use. 

## Create the EC2 instance

Change any settings as required to the EC2 variables that are set in `roles/create-ec2-instances/vars/main.yml` file.

Rename the fine `inventory/ec2.example` to `inventory/ec2`. This file will contain a list of EC2 instances when they have been created.

Run the command
```
ansible-playbook create-ec2.yml -i inventory
```
to create the EC2 instance. When this has completed the VM that has been created will be listed in the `inventory/ec2` file.