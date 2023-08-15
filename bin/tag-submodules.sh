#!/bin/bash

# tag_submodules takes in one argument - the bumped version to tag. It will iterate through all submodules in the repo
# and tag each submodule with the bumped version, allowing others to import these submodules more easily. In the case that
# the submodule major version differs from the root module's, it will tag the submodule with a modified tag to reflect the
# submodule's major version.
#
# This function does not tag the root module though, leaving it to the other commands in make tag-release to handle it
function tag_submodules() {
  echo "The root module's new version is $1. Tagging all submodules while respecting their major versions..."
  # Look for all subdirectories with `go.mod` - we'll exclude the root module and do this manually
  SUBMODULE_DIRS=$(find * -type f -name "go.mod" | xargs dirname | grep -v "vendor" | grep -v "mk-include" | grep -Fxv "." | sort | uniq)

  # Tag each submodule with its directory name (assume that the package declaration in go.mod = its directory path)
  for submodule_dir in $SUBMODULE_DIRS; do
    echo "Found a submodule at $submodule_dir, tagging it..."
    release_prefix=$submodule_dir
    new_version=$1

    # Extract the version number if present, otherwise set it to an empty string
    major_version=$(echo "$release_prefix" | grep -oE '(^|\/)v([0-9]+)$' | grep -oE '[0-9]+')

    # If we have a submodule path like cc-utils/authz/v2 but the top level module cc-utils wants a new version
    # like v0.80.0, then replace the major version with the submodule's version number, so v2.80.0
    if [ -n "$major_version" ]; then
      new_version="v${major_version}.$(echo "$new_version" | cut -d '.' -f 2,3)"
      # Have to cut the /vX out of the submodule path, see
      # https://github.com/golang/go/wiki/Modules#publishing-a-release, importantly,
      # "If the repository follows the major subdirectory pattern described above, the prefix [for the git tag] does not include the major version suffix"
      release_prefix=$(echo "$submodule_dir" | sed -E 's/(^|\/)v[0-9]+$//')
    fi

    # In the case of a repo like events, where events/v3 has a go.mod file, then by the logic above, we might end up
    # with no release_prefix, meaning we might tag the root module. That's not the intention of this script, so we skip
    # in that case
    if [ -z "$release_prefix" ]; then
      echo "Release prefix is empty, meaning we are not tagging a submodule. Skipping..."
      continue
    fi

    if [[ ! $(git tag -l "$release_prefix/$new_version") ]]; then
      echo "Tagging $release_prefix to version $new_version..."
      git tag $release_prefix/$new_version
    else
      echo "Tag $release_prefix/$new_version already exists. Skipping..."
      continue
    fi
  done

  # Push tags to remote
  git push --tags
  echo "Submodule tagging complete, will tag the root module in another script."
}
export -f tag_submodules

# Tag all submodules - we'll let the main CI take care of tagging the root module
tag_submodules $1
