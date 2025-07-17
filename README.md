# Personal Portfolio Website – Backend

This repository contains the infrastructure-as-code (IaC) and backend logic for my personal portfolio website. It uses **Terraform** to provision all AWS resources and deploys an **AWS Lambda** function that tracks visitor count using **DynamoDB**, invoked via the **API Gateway**. The frontend repo for this website can be found [here](https://github.com/EdisonLim17/Personal-Website-Frontend).

### 🌐 Live Site
[https://edisonlim.ca](https://edisonlim.ca)

---

## Architecture
![Image of architecture](/Personal-Website-Backend-AWS-Architecture.jpeg)

---

## 🚀 Features

- Serverless visitor counter updated using an AWS Lambda function invoked through a RESTful API endpoint via API Gateway
- Secure infrastructure provisioned via Terraform
- Playwright tests ensures endpoint responds correctly and counter stored in DynamoDB is updated accurately
- CI/CD pipeline auto-deploys changes to AWS on push to `main` if all tests pass

---

## 🧰 Tech Stack

- **Terraform** – AWS infrastructure provisioning
- **AWS Lambda** – serverless backend (Python) to get and update visitor count stored in DynamoDB
- **API Gateway** – exposes a REST API for the frontend
- **DynamoDB** – NoSQL database to store visitor count
- **GitHub Actions** – automated CI/CD deployment pipeline
- **Playwright** – end-to-end testing of the deployed API and lambda functions

---

## 🔧 CI/CD Workflow

Whenever changes are pushed to the `main` branch:
1. GitHub Actions deploys the backend infrastructure to AWS using Terraform
2. GitHub Actions runs the end-to-end playwright tests to make sure everything still works properly