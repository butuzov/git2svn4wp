#!/usr/bin/env bash

###############################################################################
# This work is done mostly to automate CI/CD routine and practice some shell
# scripting skills. Deployer hardly inspired by svn2git-tools by legendary
# @ocean90.
#
# License           : GPL v2
# Last Modification : 2019-10-23
# Last Author       : Oleg Butuzov
# Url               : https://github.com/butuzov/wp-plugins-deploy
###############################################################################


################################################################################
# Defining Function and Common Variables
################################################################################

DIRECTORY="$(pwd)"
ERROR_LOG="${DIRECTORY=}/error.txt"

source "$(pwd)/wp-deploy-options.sh"

# Forming SVN Directory Name
SVN_DIR="$(basename "${SVN_URL}" | awk '{print tolower($0)}').svn"
GIT_DIR=${SVN_DIR/.svn/.git}

# echo $SVN_DIR
# echo $GIT_DIR

source "$(pwd)/wp-deploy-functions.sh"

# clean start cleanup.
rm -rf "${DIRECTORY:?}/${SVN_DIR:?}"
rm -rf "${DIRECTORY:?}/${GIT_DIR:?}"



svn_checkout
git_checkout

STABLE_SVN_TAG=$(get_svn_version)
handle_error $? "${STABLE_SVN_TAG}"

STABLE_GIT_TAG=$(get_git_version)
handle_error $? "${STABLE_GIT_TAG}"


printf "Stable_Tag @ SVN: %s\n" $STABLE_SVN_TAG
printf "Stable_Tag @ GIT: %s\n" $STABLE_GIT_TAG


# Should We Update Deployment?
RECENT=$(echo -e "$STABLE_SVN_TAG\n$STABLE_GIT_TAG" | sort -nr | head -1)


# Case 1. Most_Recent_Tag is Deployed to SVN (Exit 0).
if [[ "${STABLE_SVN_TAG}" == "${RECENT}" ]] && [[ -z $FORCE_UPDATE ]]; then
  echo "Version ${RECENT} is already deployed."
  clean_up_and_exit;
  exit 0;
fi

# Case 2. Most_Recent_Tag is Deployed to SVN
#         Force is ON -> Updating Most_Recent_Tag in SVN
if [[ "${STABLE_SVN_TAG}" == "${RECENT}" ]] && [[ ! -z $FORCE_UPDATE ]]; then
  echo "Running Re-Deploymet: Version ${RECENT}"
  deploy "${STABLE_GIT_TAG}" "${STABLE_SVN_TAG}"
  clean_up_and_exit;
  exit 0
fi

# Case 3. Most_Recent_Tag is In Git. Createing new Most_Recent_Tag in SVN.
echo "Running Deployment: Version ${STABLE_GIT_TAG}"
deploy "${STABLE_GIT_TAG}" "${STABLE_GIT_TAG}"

clean_up_and_exit;
exit 0
