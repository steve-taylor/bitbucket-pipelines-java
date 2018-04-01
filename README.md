# Bitbucket Pipelines starter kit for Java/Maven

This is a starting point for using Bitbucket Pipelines in a Java project that
uses Maven. It does the following:

* Automatic tasks:
  * All branches: Build the project (`mvn clean verify`)
  * `master` branch: Deploy the build artifact (`mvn deploy`)
* Manual tasks (can be invoked within the Bitbucket UI):
  * Release major version
  * Release minor version
  * Release patch

The manual release tasks

  * Incrememnt the major, minor, or patch component of the `version` property
    in the project's pom.xml
  * Commit the change to pom.xml to `develop`
  * Tag `develop` with the updated version
  * Merge `develop` into `master`

For this to work, you should follow these rules:

  * Create a new branch for all new features, bugfixes, etc.
  * Merge branches into `develop` only. Don't merge directly into `master`.
  * Don't merge branches with broken builds into `develop`.
  * Only use [semver](https://semver.org/) versions in pom.xml, but stick to
    `MAJOR.MINOR.PATCH` (no suffixes, e.g. `-beta`) otherwise version bumping
    will fail.
  * Don't use snapshot versions.

To set up an Artifactory server and to configure Java projects for deployment
to Artifactory, see
[steve-taylor/artifact-server-config](https://github.com/steve-taylor/artifact-server-config).

## Configuring Bitbucket Pipelines

bitbucket-pipelines.yml by itself isn't quite enough to fully configure your
project for Bitbucket Pipelines. You will need to provide some additional
settings in Bitbucket.

### Environment variables

The following environment variables need to be set withing Bitbucket.
Fortunately, you can set all of these at the team level and they will be
applied to all repositories within the team.

| Name                             | Example                                       | Description                                           |
|----------------------------------|-----------------------------------------------|-------------------------------------------------------|
| `DEPLOYER_NAME`                  | `Deploy Bot`                                  | Deployment script name (appears in git logs)          |
| `DEPLOYER_EMAIL`                 | `deploybot@example.com`                       | Deployment script email address (appears in git logs) |
| `MAVEN_REPO_URL`                 | `https://artifactory.example.com/artifactory` | Maven repository URL                                  |
| `MAVEN_REPO_RELEASES_KEY`        | `libs-release`                                | Public releases cache repo ID                         |
| `MAVEN_SETTINGS_PROFILE`         | `artifactory`                                 | Profile name                                          |
| `MAVEN_REPO_READER_USERNAME`     | `me`                                          | CI/CD Maven read-only username                        |
| `MAVEN_REPO_READER_PASSWORD`     | `swordfish`                                   | CI/CD Maven read-only password                        |
| `MAVEN_REPO_PUBLISHER_USERNAME`  | `cicd`                                        | CI/CD Maven read-write username                       |
| `MAVEN_REPO_PUBLISHER_PASSWORD`  | `super-secret`                                | CI/CD Maven read-write password                       |
| `MAVEN_REPO_RELEASES_LOCAL_KEY`  | `libs-release-local`                          | Private releases repo ID                              |

### ssh

Unfortunately, the ssh keys provided by Bitbucket Pipelines don't allow tasks
to push back to their git repository. You will need to generate a new ssh key
pair that allows Bitbucket Pipelines to push to git.

1. Go to *Settings* / *Security* / *SSH keys* in your Bitbucket team.
2. Click *Add key*
3. Generate an ssh key pair and paste the **public** key into into the *Key*
   field. (The dialog contains links to instructions to generate an ssh key
   pair.)
4. Provide a label and click *Add key* to finish adding the team-level ssh
   key.
5. Navigate to your repo and go to *Settings* / *Pipelines* / *SSH keys*.
6. If there is already a key, delete it.
7. Provide the private and public keys from step 2.

For additional projects, repeat steps 5 to 7.

**Note:** Bitbucket will log warnings each time it pushes using the team-level
ssh key, as it is a deprecated feature and they unfortunately recommend using
an individual account's ssh key instead. You're quite welcome to follow that
recommendation if it makes you sleep better at night.
