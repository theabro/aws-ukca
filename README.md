# aws-ukca

Ansible playbook for running UKCA on an AWS EC2 instance. This is based on the Vagrant-based [Met Office Virtual Machine](https://github.com/metomi/metomi-vms) and previous work on using Ansible for this VM on the [JASMIN Unmanaged Cloud](https://github.com/theabro/ukca-playbook). 

Based on instructions from [Dave Sugden (April 2020)](https://davelms.medium.com/use-ansible-to-create-and-configure-ec2-instances-on-aws-cfbb0ed019bf) and [Vivek Gite (February 2018)](https://www.cyberciti.biz/faq/how-to-create-aws-ec2-key-using-ansible/), as well as general Googling.

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

## Managing the EC2 instance

You should use the [AWS console](https://aws.amazon.com/) to manage the EC2 instance, specifically the **EC2** Dashboard which can be found under _All services_. 

If the VM becomes unresponsive you many need to force-stop it via the EC2 Dashboard. 

## Create the EC2 instance

Change any settings as required to the EC2 variables that are set in `roles/create-ec2-instances/vars/main.yml` file. The volume size has been set here to 30GB, and the instance type is currently `t2.micro` (the _"free tier"_ size). This can be resized by [following the instructions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-resize.html) for changing the instance using the AWS console.

You should rename the file `inventory/ec2.example` to `inventory/ec2`. This file will contain a list of EC2 instances when they have been created.

Run the command
```
ansible-playbook -v create-ec2.yml -i inventory
```
to create the EC2 instance. When this has completed the VM that has been created will be listed in the `inventory/ec2` file.

## Provision the Met Office VM

Once the EC2 instance has been created, you can provision the Met Office VM on it by running the command
```
ansible-playbook -v provision.yml -i inventory
```
This will take the information of the EC2 instance created from the file `inventory/ec2`. If you terminate this instance or if its IP address changes you will need to update this file.

It will take some time to provision this VM, due to the number of packages that are installed and the other options made. 