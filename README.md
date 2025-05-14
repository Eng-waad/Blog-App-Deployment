## SDA2007-Waad abadil saed alharthi
## Week 11 Assignment
## Infrastructure Bootcamp Assignment
## Scenario: Blog App Deployment with Terraform and Ansible:

Deploy a MERN stack blog application on AWS. Backend will run on a single EC2 instance (Ubuntu 22.04), frontend will be hosted via S3 static website hosting, and MongoDB Atlas will be used as the database. Media uploads will be handled through a separate S3 bucket with proper IAM policies.

### Assignment Tasks:
## 1. Design Architecture:

- System Architecture Diagram
This diagram illustrates the architecture of a web application system that I created using the online tool draw.io
- Components Description:
1. React Frontend (S3 Static Website)  
  This is the client-side part of the application, built using React and hosted as a static website on Amazon S3.
2. Backend EC2 Server (Node.js, Express)  
  The backend server runs on an AWS EC2 instance using Node.js and Express framework. It handles the business logic and API requests.
3. Security Group  
  Defines the allowed inbound ports (22 for SSH, 80 for HTTP, and 5000 for the custom backend service).
4. S3 Media Bucket (Media Uploads)  
  An S3 bucket dedicated to storing media uploads such as images or videos.
5. MongoDB Atlas Cluster  
  A cloud-hosted MongoDB database cluster used to store and manage the application's data.


## 2. Security Configuration:

# 2.1 IAM Policy and User for S3 Media Bucket
Terraform Code
# IAM Policy for Media Bucket Access
resource "aws_iam_policy" "s3_media_access" {
  name        = "s3-media-access-policy"
  description = "Allows read/write access to the media S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
        Resource = "arn:aws:s3:::${var.media_bucket_name}/*"
      }
    ]
  })
}

# IAM User and Access Keys
resource "aws_iam_user" "s3_media_user" {
  name = "s3-media-upload-user"
}

resource "aws_iam_user_policy_attachment" "s3_media_access" {
  user       = aws_iam_user.s3_media_user.name
  policy_arn = aws_iam_policy.s3_media_access.arn
}

resource "aws_iam_access_key" "s3_media_user_key" {
  user = aws_iam_user.s3_media_user.name
}

# Output Keys (for Ansible)
output "s3_access_key" {
  value     = aws_iam_access_key.s3_media_user_key.id
  sensitive = true
}

output "s3_secret_key" {
  value     = aws_iam_access_key.s3_media_user_key.secret
  sensitive = true
}

# 2.2 Security Group for EC2 Instance


resource "aws_security_group" "backend_sg" {
  name        = "backend-security-group"
  description = "Allow SSH, HTTP, and Backend API access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP in production
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## 3. MongoDB Atlas Setup:
 # 3.1 Create a Free-Tier Cluster
   - Sign Up
   - Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas).
   - Create an account.

 # 3.2 Create a Cluster:
   - Click Build a Cluster.
   - Select M0 Sandbox (Free Tier).
   - Choose a cloud provider (AWS) and region (eu-north-1).
   - Name the cluster (Cluster0).
   - Click Create Cluster.

 # 3.3 Whitelist EC2 Instance IP:
   - Go to Security , Network Access.
   - Click ADD IP ADDRESS.
   -  Add EC2 instance’s public IP (ec2-13-60-40-178.eu-north-1.compute.amazonaws.com).
   - Click Confirm.

 # 3.4 Create a Database User:
   - Go to Security , Database Access.
   - Click Add New Database User.
   - Configure User Permissions:
   - Authentication Method: Password.
   - Username: (waadal4400).
   - Password: secure 
   - Database User Privileges: Select Read and write to any database.
   - Click Add User.


 # 3.5 Get the Connection String
   -Connect to Cluster:
   - Go to Database , Connect , Connect your application.
   -Copy the Connection String
     
 # 3.6: Use the Connection String in Backend
   - Add to .env File:
   ```env
   
PORT=5000
MONGO_URI=mongodb+srv://waadal4400:<db_password>@cluster0.15obx6z.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=eu-north-1
S3_BUCKET_NAME=bucketwaad


## 4. S3 Buckets Configuration:
# 4.1 Set Up the Frontend Bucket
  - Create an S3 Bucket:
  - Log in to the AWS Management Console.
  - Click on Create Bucket.
  - Choose the region (eu-north-1).
  - Go to the "Permissions" settings and ensure that “Enable encryption” is not checked.
  - Enable Static Website Hosting: Go to the "Properties" tab
  - Look for "Static website hosting": enable it.
  - Enter the index document name (index.html) and the error document (eerror.html).
  - Add a Bucket Policy to Allow Public Access: Go to the "Permissions" tab, Click on "Bucket Policy"
  - Enter a policy to allow public access:
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "PublicReadGetObject",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
       "Resource": "arn:aws:s3:::media-bucket-waad/*"
      }
    ]
 }
  

# 4.2 Set Up the Media Bucket
 - Create the Media Bucket: name for the bucket (media-bucket-waad)
 - Allow Programmatic Access: Go to the "Permissions"
  Click on “Bucket Policy” and add a policy to allow programmatic access:
{
   "Version": "2012-10-17",
    "Statement": [
     {
       "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::8030-5615-2450:user/media-upload-user"
        },
        "Action": "s3:*",
        "Resource": [
          "arn:aws:s3:::arn:aws:s3:::media-bucket-waad",
          "arn:aws:s3:::arn:aws:s3:::media-bucket-waad/*"
       ]
      }
    ]
  }
  

 # 4.3 Apply CORS Policy:
 - Go to the "Permissions", Look for CORS configuration settings
 - Add CORS settings:
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST"],
    "MaxAgeSeconds": 3000,
    "AllowedHeaders": ["*"]
  }
]


## 5. Launch Template for Backend:
## Create a launch template (or instance directly via Terraform) Use t3.micro, Ubuntu 22.04
Use your existing key pair to allow SSH connection

# 5.1 Configuration Files:
# 1. main.tf

provider "aws" {
  region = "eu-north-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Allow SSH, HTTP and app port"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port 5000"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "backend_lt" {
  name_prefix   = "backend-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "mykey"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.backend_sg.id]
  }

  user_data = base64encode(file("user-data.sh"))
}


# 5.2 user-data.sh

#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# System updates
apt update -y
apt install -y git curl unzip tar gcc g++ make awscli

# Node.js installation
su - ubuntu -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash'
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm install --lts'

# PM2 setup
su - ubuntu -c 'npm install -g pm2'
su - ubuntu -c 'pm2 startup'

# Application directories
su - ubuntu -c 'mkdir -p ~/logs'


# 5.3 Deployment Steps
# Initialize Terraform
terraform init

# Review execution plan
terraform plan

# Apply configuration
terraform apply -auto-approve


## 6. Backend Server Setup

- Use **Ansible** to automate backend server provisioning

- Create a playbook to:
  - Clone the blog application repository
  - Generate and configure the `.env` file with MongoDB Atlas and S3 credentials
  - Start the backend using PM2
  - Ensure the Ansible playbook is idempotent and uses variables for sensitive data
  - Organize your playbook with a recommended role-based structure:

  ```
  ansible/
  ├── inventory
  ├── backend-playbook.yml
  └── roles/
      └── backend/
          ├── tasks/
          ├── templates/
          └── vars/
  ```

## Configuration Files

# 6.1. Inventory File
Define your target servers and SSH credentials:
```ini
[backend_servers]
13.60.40.178 ansible_user=ec2-user ansible_ssh_private_key_file=C:/Users/waad/Downloads/myKey.pem


# 6.2. Roles/backend/vars/main.yml
Store sensitive credentials:
mongo_uri: "username:<password>@cluster0.15obx6z.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
aws_access_key_id: ""
aws_secret_access_key: ""
s3_bucket_name: "bucketwaad"

# 6.3. roles/backend/templates/.env.j2
Template for environment variables:
ini
MONGO_URI={{ mongo_uri }}
AWS_ACCESS_KEY_ID={{ aws_access_key_id }}
AWS_SECRET_ACCESS_KEY={{ aws_secret_access_key }}
S3_BUCKET={{ s3_bucket_name }}


# 6.4. roles/backend/tasks/main.yml
Deployment tasks:

name: Clone blog application repository 
  git:
    repo: 'https://github.com/Eng-waad/Blog-App-Deployment.git'
    dest: /home/ec2-user/blog-app
    version: main
    force: yes

- name: Generate .env file from template
  template:
    src: .env.j2
    dest: /home/ec2-user/blog-app/.env
    owner: ec2-user
    group: ec2-user
    mode: '0600'

- name: Install PM2 globally
  npm:
    name: pm2
    global: yes
    state: present

- name: Start backend using PM2
  command: pm2 start /home/ec2-user/blog-app/app.js --blog-app
  args:
    chdir: /home/ec2-user/blog-app
  register: pm2_start
  ignore_errors: yes

- name: Save PM2 process list
  command: pm2 save
  when: pm2_start.changed

# 6.5.  backend-playbook.yml
Main playbook configuration
---
- hosts: backend_servers
  become: yes
  vars_files:
    - roles/backend/vars/main.yml
  roles:
    - backend

# 6.6. Running the Playbook
 ## 1 Navigate to the ansible directory:
bash

cd ansible

 ## 2 Execute the playbook:
bash


ansible-playbook -i inventory backend-playbook.yml


### Troubleshooting
Issue: SSH Connection Failed |    Solution:  Verify key permissions and Security Group rules
Issue: PM2 Process Not Found |    Solution:  Check if pm2 start ran successfully in tasks
Issue: Missing .env File     |    Solution:  Confirm template paths in tasks/main.yml


### Cleanup
# Destroy Terraform resources
terraform destroy -auto-approve

# Manual cleanup
- Remove MongoDB Atlas IP whitelist rules
- Delete S3 buckets manually
- Revoke IAM user credentials
