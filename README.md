## Automated AWS EC2 deployment with Terraform

In this [Deploy-in-Public](https://callie-stoscup-s-school.teachable.com/p/deploy-in-public-challenge) challenge, I deploy two NGINX servers - (1) one in a public subnet with access to the internet that forwards traffic to the (2) second server that will display a custom HTML page.

To do this, I:

    - Created an admin user; then, as that user, provisioned the following AWS resources with Terraform:

        - A VPC
        - 1 public subnet
        - 1 private subnet
        - An Internet gateway
        - A NAT gateway
        - A public route table
        - A private route table
        - A public EC2 instance + security group
        - A private EC2 instance + security group
        - A bastion host + security group

    - Then verified the following:
        - that I could SSH into the public EC2 instance and the bastion host
        - that I could NOT directly SSH into the private EC2 instance
        - that I could SSH into the private EC2 instance through the bastion host
        - that I could  view my custom HTML page when I loaded the public IP address of the private EC2 instance
