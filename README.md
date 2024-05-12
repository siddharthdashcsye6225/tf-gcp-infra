# Setting Up Google Cloud Platform Infrastructure with Terraform

## Infrastructure Architecture

![Architecture Diagram](CSYE6225_architecture_diagram.drawio.svg)

## Introduction

This guide provides comprehensive steps for setting up the infrastructure on Google Cloud Platform using Terraform. The architecture diagram above illustrates the components involved in the infrastructure.

## Prerequisites

Before proceeding, ensure you have the following:

- Google Cloud Platform account
- Google Cloud SDK (gcloud CLI) installed
- Terraform CLI installed

## Configuration Steps



1. Install and set up the gcloud CLI and Terraform on your local machine.

2. Clone the repository containing the Terraform configuration files using the following command:
   `git@github.com:siddharthdashcsye6225/tf-gcp-infra.git`
   

4. Navigate to the cloned repository directory:
   `cd tf-gcp-infra`

5. **Review and update Terraform configuration**:
- Create a new Terraform configuration file (e.g., main.tf) or modify the existing ones to define the required resources such as networks and subnets. Ensure that the values are not hard-coded in your Terraform configuration files. You can use variables to make the configuration dynamic.
- variables are defined in a separate file (e.g., variables.tf) to hold values like project ID, region, VPC CIDR range, etc. This allows you to reuse the same Terraform configuration for multiple VPCs by changing the variable values.

6. Initialize the Terraform configuration by running `terraform init`.

7. Validate the configuration using `terraform validate`.

8. Plan the infrastructure changes with `terraform plan`.

9. Apply the changes to create the VPC and subnets using `terraform apply`.

### Checking State

You can check the state of your infrastructure using the `terraform show` command.

## Continuous Integration (CI) Workflow

The Continuous Integration (CI) workflow for this project is implemented using GitHub Actions. It includes the following steps:

1. When a new pull request or push event occurs, GitHub Actions triggers the workflow.

2. The workflow checks out the repository's code.

3. It installs Terraform and initializes the working directory.

4. The `terraform fmt` command is executed to format the Terraform configuration files.

5. The `terraform validate` command is executed to validate the Terraform configuration syntax.

6. If the validation is successful, the workflow proceeds to the next steps; otherwise, it fails and notifies the user.

7. After successful validation, the workflow continues with additional steps like planning and applying infrastructure changes (if configured).

## Architecture Overview

The architecture of this project encompasses various components necessary for building a robust infrastructure on Google Cloud Platform. Managed SSL certificates, VPC networking setup, VM instances, Cloud SQL database instance, Cloud Functions, Pub/Sub topics, and more are orchestrated using Terraform scripts, ensuring consistency and reproducibility across deployments.

### Managed SSL Certificate

A managed SSL certificate is configured to secure the web application with HTTPS.

### Virtual Private Cloud (VPC)

The Virtual Private Cloud (VPC) is configured with custom networks and subnetworks to isolate and manage network resources efficiently.

### Cloud SQL Database

A Cloud SQL database instance is provisioned to store and manage application data securely.

### Cloud Functions

Cloud Functions are used for serverless execution of code triggered by events such as Pub/Sub messages. They handle tasks like sending verification email.

### Pub/Sub Topics

Pub/Sub topics facilitate asynchronous communication between various components of the application, enabling scalable and decoupled architecture.

### Continuous Integration (CI)

The CI workflow, implemented with GitHub Actions, ensures that changes to the infrastructure are validated and applied seamlessly.

### Cloud VM Instance

A Cloud VM instance is provisioned to host the application and other services. It provides computing resources for running applications and services in the cloud environment.

### Managed Instance Group

A managed instance group is configured to automatically manage and scale a group of identical VM instances. It ensures high availability and load balancing by distributing incoming traffic across multiple instances.

### Load Balancer

A load balancer is deployed to distribute incoming traffic among the instances in the managed instance group. It enhances the availability and scalability of the application by efficiently distributing traffic.

### Cloud DNS

Cloud DNS is utilized for domain name resolution, enabling users to access the application using domain names. It provides scalable and reliable DNS hosting, ensuring optimal performance and availability.

### Instance Template

An instance template is created to define the configuration settings for the VM instances in the managed instance group. It ensures consistency and repeatability in VM provisioning, simplifying management and deployment tasks.

### Key Rings

Key rings are configured to manage cryptographic keys used for encryption and decryption operations. They provide a centralized and secure way to manage keys, enhancing data security.

### Cloud Logging with Ops Agent

Cloud Logging with Ops Agent is configured to collect, view, and analyze logs from various Google Cloud Platform services. It provides insights into the performance, availability, and security of the infrastructure and applications.

---
