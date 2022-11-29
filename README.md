# :wrench: Git Ops Starter

Git ops starter is addressing ABC, Inc. company's all infrastructure needs. Before diving in, read the story of how this repository was born.

## :v: Why?

We have a mission of creating the most comprehensive git ops starter project to help our fellow DevOps save 1000s hours renaming, figuring out non-obvious docs, and trying to address any company's basic to advanced needs. We believe that with the help of the community, we can extract best practices, test them, and document them for a new git ops paradigm.

## :office: ABC, Inc.

ABC, Inc. is a regular or spectacular SaaS startup. They are developing their platform by utilizing following technologies:
- C#
- .Net Core (deployed in Azure App Services and Azure Functions)
- AKS (external services like Superblocks and some long-running internal jobs
- PostgresSQL database (flexible servers managed by Azure) 
- MongoDB database (managed by Atlas and deployed in Azure)
- Redis (managed service by Azure)
- Azure Service Bus
- Typescript with Next.js and deployed in Vercel
- Cloudflare
- Lets-Encrypt
- Azure DevOps Pipelines
- Datadog

## Story

Bob, co-founder and a guy with experience with Azure, was handling all these—creating AppServices, configuring App_Settings, Connection_Strings, and DNS verification records. All by bare hands. It was fun at first. 

But then, as any startup, ABC, Inc. also went through major 2-3 pivots until we started feeling the 'zen' of any startup - "product-market-fit." In a startup world, pivot means you had an A idea; now, it's a B. But what does it mean for technical savages like Bob? You had the A1 service, referencing the A2 service with A3 Database. You had entity names suited and designed for A; the dependencies like A1 -> A2 made sense for A. Now you have to change everything from A to B. You only have time to rewrite/recreate everything. You already have some components that don't need to be changed - at least logically, so you end up applying changes only in "UI" and make everything somehow work. After a few pivots, you have a lovely "C Idea" UI and "A, B, C, D, E" backend and "A0, A1, B1, b999, 7E, DDD" infrastructure. 

With each day passing, Bob felt more pressure; he slowly released that everything would explode if he didn't do something with this now. The next day, after having a horrible night - Bob took a paper - just an MD file and wrote down all requirements for having a better infra world.

## Requirements

- Should have separate Dev/Prod environment and ability to have more environments like QA/Staging relatively easier
- Adding new AppServices/AzureFunctions and k8s deployments should require minimal steps from the developer
- The prod environment should be fully in v-net and authorized developers should have VPN acess to it
- Configurations, connections strings for all deployments should be configured automatically
- Infrastructure deployments should be defined as a code, so it makes any change fast, easy and trackable

Out of these requirements, Bob decided to use Terraform for managing Azure infrastructure and Fluxcd for managing AKS (k8s).

## Architecture

Let's define the process of how one's code is released in production.
1. Code is committed/merged in the dev branch.
2. Azure DevOps pipeline is triggered, which builds the code, runs unit tests and deploys to the dev environment.
3. After testing and release decision, the dev branch is merged to the main, which triggers Azure DevOps pipelines once more, which deploys code to production.

Not the best release management, but it gets the job done with just a few minutes of downtime. Later Bob is planning on improving this as well. 
We can see from this process that we need the following:

- Dev environment
- Prod environment
- Build pipelines for each component
- k8s manifest applies for not azure managed services

### :interrobang: Separate workspace/branch for each environment?
Prons and conds

Bob decided to have branch for each environment and separate workspace associated with it.

### :interrobang: A separate k8s cluster for each environment?
Pros and cons

Bob decided to have one k8s cluster and different node pools for each environment.

### :interrobang: Automated deployment of Build Pipelines?
Pros and cons

Bob decided to have a separate terraform repo for deploying build pipelines.

***

To sum it up. We will have 4 loosly coupled workspaces. dev, prod, k8s for deploying AKS, devops for creating build pipelines. On top of that we will have separate repo - flux for managing k8s deployments.

## Repository structure

Information on how the repository is structured

## Terraform Environment Variables

### TF Cloud Variable Set : Global Secrets

| Key  | Sensitive | Category | Description
| ----------------------------------- | ----- | ------- | ----------------------------------- |
| ARM_CLIENT_ID | X | env | key description |
| ARM_CLIENT_SECRET | X | env | key description |
| ARM_SUBSCRIPTION_ID | X | env | key description |
| ARM_TENANT_ID | X | env | key description |
| AZDO_GITHUB_SERVICE_CONNECTION_PAT | X | env | key description |
| AZDO_ORG_SERVICE_URL | X | env | key description |
| AZDO_PERSONAL_ACCESS_TOKEN | X | env | key description |
| CLOUDFLARE_API_KEY | X | env | key description |
| CLOUDFLARE_EMAIL | X | env | key description |
| DD_API_KEY | X | env | key description |
| DD_APP_KEY | X | env | key description |
| GITHUB_TOKEN | X | env | key description |
| MONGODB_ATLAS_PRIVATE_KEY | X | env | key description |
| MONGODB_ATLAS_PUBLIC_KEY | X | env | key description |
| VERCEL_API_TOKEN | X | env | key description |

## Call outs

Include links to specific implementations, like VPN gateway, MongoDB atlas private link, and more

## Underwater stones

Information about Terraform cloud agents, azure build agents, link to doc how to build agent on premise, cloudflare module version and more

## What's next?
- Discuss and improve Bob's decisions with the help of the community
- ABC, Inc. is planning to duplicate its infrastructure in AWS and Google Cloud
- Implement near-0 time release management
