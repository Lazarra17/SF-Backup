# CI/CD for Org Development Model

This is a sample sfdx project that showcases how to use Github Actions for CI/CD in an org development model (no packages, no scratch orgs).

Check out the `pr-develop-branch.yml` file under `.github/workflows` for a detailed explanation of the operations that are being automated.

# CI/CD Configuration
**1-** Go to Github Repository -> Settings -> Secrets and variables -> Action, then go to 'Secrets' tab 

**2-** Click 'New repository secret' and create the following secret:

**Name:** SFDX_INTEGRATION_URL <br>
**Secret:** (Authorization Url) see https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_url.htm on how to generate Authorization Url<br>

**Name:** SFDX_PRODUCTION_URL<br>
**Secret:** (Authorization Url) see https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_url.htm on how to generate Authorization Url<br>


## High level flow

**1-** We have a master branch that represents the metadata we are tracking.

**2-** At the beginning of a development, we create a develop branch off of main, in the remote repository.  

**3-** Developers clone the repository (which is an sfdx project) to their local computer and authorize the project against their own sandbox (this is a one time step). This is an important and often overlooked feature of sfdx: you can authorize any sfdx project against any org, even if the project was created from a different org. 

**4-** Developers checkout the remote develop branch, and create a feature branch that corresponds to the bug or user story they are working on. 

**5-** Developers push their feature branch to the remote repository, and continue to push commits as they progress through the development process.

**6-** Once ready, the developer opens a pull request from the feature branch against the develop branch.

**7-** The pull request triggers a CI/CD job with Github Actions that will do the following:

Do a check-only deployment of only the new metadata or the existing metadata that has changed. This deployment will be against the integration org. 

**8-** If the CI/CD job completes successfully, then the feature branch can be merged into develop.

**9-** The feature branch is merged into develop, and this triggers an actual deployment of the metadata into the integration org, and again runs the tests specified by the developer in the Pull Request Description Body

**10-** At the end of the development, the feature branch opens a pull request into master, then the pull request triggers a CI/CD job with Github Actions that will do the following:

Do a check-only deployment of only the new metadata or the existing metadata that has changed. This deployment will be against the Production org. 

**11-** If the CI/CD job completes successfully, then the feature branch can be merge to Main branch.   This triggers a deployment to Production org which contains the new metadta or existing metadata that has changed.


## Deploying delta changes

We are `sfdx-git-delta` to only deploy the metadata that has been changed (or created) by the developer. 

If you want to deploy the entire branch, simply use the `deploy` command against the `force-app` directory.

## Specify which tests to run

We allow the developer to specify which tests to run by using a special syntax in the pull request body

`Apex::[Class1,Class2,Class3...]::Apex`

Read `pr-develop-branch.yml` for a detailed description of how this works.

