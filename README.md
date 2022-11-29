# Git Ops Starter

Git ops starter is addressing ABC, Inc. company's all infrastructure needs. Before diving in read the story how this repository was born.

## ABC, Inc.

ABC, Inc. is a regular or spectacular SaaS startup. They are developing their platform mainly utilizing Microsoft technologies, including C#, .Net deployed in Azure App Services and Azure Functions. For some of external services like Superblocks as well as some internal long running jobs they utilize AKS (k8s). Data is mostly stored in a PostgresSQL database (flexiable servers managed by Azure), they cache in Redis (managed service by Azure) and send cross-components messages in Azure Service Bus. Ah and also for one of their data-sensitive components they use MongoDB Atlas. Front-end is written in Typescript and they use Next.js deployed to Vercel. For DNS management they use Cloudflare, for SSL certificates they use lets-encrypt and for logging/monitoring they use DataDog. And for some wired reason they use Azure Devops pipelines instead of GitHub Actions.

## Story

Bob, co-founder and a guy who had experience with Azure, was handling all of these. Creating AppServices, configuring App_Settings, Connection_Strings, DNS verification records. All by bare hands. It was fun at first. But then as any startup, ABC also went through major 2-3 pivots until we started feeling the ‘zen’ of any startup - “product-market-fit.” In a startup world, pivot simply means you had an A idea; now, it's a B. But what does it really mean for technical savages like Bob? You had the A1 service, referencing the A2 service with A3 Database. You had entity names that are suited and designed for A; the dependencies like A1 -> A2 made sense for A. Now you have to change everything from A to B. You don’t have time to rewrite everything. You already have some components that don’t need to be changed - at least logically, so you end up applying changes only in “UI” and make everything somehow work. After a few pivots, you have a lovely “C Idea” UI and “A, B, C, D, E” backend and “A0, A1, B1, b999, 7E, DDD” infrastructure. With each day passing, Bob felt more pressure; he slowly releases that if he don’t do something with this now, everything will simply explode. The next day, after having a horrible night - Bob took a paper - in fact just an MD file and wrote down all requirmenets.

## Requirements

- Should have separate dev/prod environment and ability to have more enviroments like qa/staging relativly easier
- Adding new AppServices/AzureFunctions and k8s deployments should require minimal steps from developer
- Prod environment should be fully in v-net and authorized developers should have vpn acess to it
- Configurations, connections strings for all deployments should be configured automatically
- Infrastructure deployments should be defined as a code, so it makes any change fast, easy and trackable

Out of these requirements Bob decided to use Terraform for managing Azure infrastructure and Fluxcd for managing AKS (k8s).

## Architecture

Let's define the proces how ones code is released in production.
1. Code is commited/merged in dev branch.
2. Azure DevOps pipelines is triggered, which builds the code, runs unit tests and deploys to dev environment.
3. After testing and release decision, dev branch is merged to main which triggers Azure Devops pipeleins once more, which deploys code to production.

Not the best release management, but its get job done, with just few minutes of downtime. Later one Bob is planning on improving this as well. 
We can clearly see from this process that we need:

- Dev environment
- Prod environment
- Build pipelines for each component
- k8s manifest apply for not azure managed services

Let's go one by one. 
Its prettystraight forward that we can have terraform repo with all necassary azure services in dev enviroment. Then we can have branch called dev for dev and main branch for production.

### A separate k8s cluster for each environment?
prons and cons
Bob decided to have on cluster and different node-pools for ench environment

### Automated deployment of Build Pipelines?
prons and cons

Bob decided to have a separate terraform repo for deploying build pipelines

## Underwater stones

Information about Terraform cloud agents, azure build agents, link to doc how to build agent on premise, cloudflare module version and more

## Repository structure

Information on how the repository is structured

## Terraform Environment Variables


## Call outs

Include links to specific implementations, like vpn gateway, mongodb atlas private link and more

## What's next

- Discuss and improve Bob's decisions with help of community
- ABC, Inc. is planning to duplciate their infrastructure in AWS and Google Cloud
