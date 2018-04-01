#!/bin/bash

#
# Version bump and publish this Git+Maven repo.
#
# Usage: ./version.sh {major|minor|patch}
#
# For example, to bump the version from 1.5.9 to 1.6.0:
#
#     ./version.sh minor

abort_on_failure () {
    if [ $? != 0 ]; then
        echo "${1}. Aborting."
        exit 1
    fi
}

# Configure git
git config user.name "${DEPLOYER_NAME}"
git config user.email "${DEPLOYER_EMAIL}"

# Validate command line
if
    [[ $# -ne 1 ]] || \
    ! [[ $1 =~ ^(major|minor|patch)$ ]];
then
    echo "Usage: $0 {major|minor|patch}"
    exit 1
fi

# Ensure we're on develop
if [ $(git rev-parse --abbrev-ref HEAD) != "develop" ]; then
    echo "This is not the develop branch. Aborting."
    exit 1
fi

# Fetch from remote, converting this to a full repo from a shallow repo if necessary
if [ $(git config --get remote.origin.fetch) != "+refs/heads/*:refs/remotes/origin/*" ]; then
    git fetch --unshallow
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

    git fetch origin
    abort_on_failure "Failed to fetch from origin"
else
    git fetch
    abort_on_failure "Failed to fetch"
fi

# Ensure we're in sync with upstream
if [ $(git rev-parse HEAD) != $(git rev-parse '@{u}') ]; then
    echo "This repository is out of sync with upstream. Aborting."
    exit 1
fi

# Get the current project's version from its pom.xml
current_version=$(mvn -q -Dexec.executable='echo' -Dexec.args='${project.version}' --non-recursive exec:exec)
current_version_semver=( ${current_version//./ } )

# Extract the major, minor, and patch components from the current version
major="${current_version_semver[0]}"
minor="${current_version_semver[1]}"
patch="${current_version_semver[2]}"

# Validate the current version. (We can't bump it if it's not valid semver.)
if
    [[ ${#current_version_semver[@]} -ne 3 ]] || \
    ! [[ ${major} =~ ^[0-9]+$ ]] || \
    ! [[ ${minor} =~ ^[0-9]+$ ]] || \
    ! [[ ${patch} =~ ^[0-9]+$ ]];
then
    echo "Current version (${current_version}) is not valid semver. Aborting."
    exit 1
fi

case "$1" in
    major)
        new_version="$((major+1)).0.0"
        ;;
    minor)
        new_version="${major}.$((minor+1)).0"
        ;;
    patch)
        new_version="${major}.${minor}.$((patch+1))"
        ;;
    *)
        # If this happens, it's a bug
        echo "Well, this is embarrassing. The command line argument should have already been validated."
        exit 1
esac

# Version bump pom.xml
mvn -q versions:set -DnewVersion=${new_version}
mvn -q versions:commit

# Commit and tag the version
git add -A
git commit -m "Version ${new_version}"
git tag -a "v${new_version}" -m "Version ${new_version}"

# Merge new version into master
git checkout master
git reset --hard origin/master
git merge develop

# Push everything and go back to develop
git push origin master
abort_on_failure "Failed to push master"

git push --tags
abort_on_failure "Failed to push tags"

git checkout develop

git push
abort_on_failure "Failed to push develop"

echo "$current_version -> $new_version"
