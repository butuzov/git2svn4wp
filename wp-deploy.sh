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

# Reading Keyword Arguments
for i in "$@"; do
    case $i in

        -git=*|--git=*)
        GIT_URL="${i#*=}"
        shift
        ;;

        -svn=*|--svn=*)
        SVN_URL="${i#*=}"
        shift
        ;;

        -u=*|--u=*|-user=*|--user=*|-username=*|--username=*)
        SVN_USER="${i#*=}"
        shift
        ;;

        -p=*|--p=*|-pass=*|--pass=*|-password=*|--password=*)
        SVN_PASS="${i#*=}"
        shift
        ;;

        -f|--force)
        FORCE_UPDATE=True
        shift
        ;;

        *)
        # unknown option
        ;;
    esac
done


# ok, Checking what we got from cli.
if [[ -z $GIT_URL ]] || [[ -z $SVN_URL ]] \
    || [[ -z $SVN_USER ]] || [[ -z $SVN_PASS ]]; then

    # Your PLugin Git Repository URL
    if [[ -z $GIT_URL ]]; then
        echo -e "Error: -git= key argument missing... \n(Git URL we using to pull your repository from)"
    fi

    # WordPress Plugins Directory SVN URL
    if [[ -z $SVN_URL ]]; then
        echo -e "Error: -svn= key argument missing... \n(SVN of WP Plugins Direcotry SVN we using to push your changes to)"
    fi

    # This is for SVN Username.
    # Note: Case Sensitive
    if [[ -z $SVN_USER ]]; then
        echo -e "Error: -user= key argument missing...\n(WordPress SVN Username)"
    fi

    # This is for SVN Password.
    # Nothing super specia
    if [[ -z $SVN_PASS ]]; then
        echo -e "Error: -pass= key argument missing...\n(WordPress SVN Password)"
    fi

    exit 1;
fi

# Forming SVN Directory Name
SVN_DIR="$(basename "${SVN_URL}" | awk '{print tolower($0)}').svn"
GIT_DIR=${SVN_DIR/.svn/.git}

# echo $SVN_DIR
# echo $GIT_DIR

if [[ -z $ERROR_LOG ]]; then
  printf "\$ERROR_LOG not set\n"
  exit 1;
fi

if [[ -z $DIRECTORY ]]; then
  printf "\$DIRECTORY not set\n"
  exit 1;
fi

# ------------------------------------------------------------------------------
# Dow we have error now? If so, cehck error.txt if it has size more then 1
# (empty) it has errors.
is_error(){

    if [[ -f $ERROR_LOG ]]; then

        ERROR_LOG_SIZE="$(ls -la $ERROR_LOG | awk '{print $5}')"

        if [[ ERROR_LOG_SIZE -gt 2 ]]; then
            return 1
        else
            return 0
        fi
    else
        return 0
    fi
}

# ------------------------------------------------------------------------------

handle_error(){
  EXIT_CDOE="$1"
  ERROR_MSG="$2"

  if [[ "${EXIT_CDOE}" != 0 ]]; then
    echo "${ERROR_MSG}"
    clean_up_and_exit
  fi
}


###############################################################################
# Show error message and delete error log.
###############################################################################

show_error() {
    if [[ ! -f $ERROR_LOG ]]; then
        exit 0;
    fi

    ERROR=$(cat ${ERROR_LOG} | awk '{print "\t"$0}')
    printf "Error:\t %s\n" "${ERROR}"

    unlink $ERROR_LOG
}


###############################################################################
# Returns stable version found in SVN_DIR/trunk/readme.txt
###############################################################################
get_svn_version() {
  if [[ ! -f "${DIRECTORY}/${SVN_DIR}/trunk/readme.txt" ]]; then
    printf "Error: \tUnanable to locate \"readme.txt\"\n"
    exit 1
  fi

  STABLE_SVN_TAG="$(
    # Output readme.txt and piping to awk
    cat "${DIRECTORY}/${SVN_DIR}/trunk/readme.txt" |
    awk '/Stable tag/{print $NF}'
  )"

  if [[ -z $STABLE_SVN_TAG ]]; then
    printf "Error:\tUnable to retrive  \"Stable Tag\"\n"
    exit 1
  fi

  if [[ "trunk" == "$STABLE_SVN_TAG"  ]]; then
    printf "Error:\t'trunk' isn't valid version.\n"
    exit 1
  fi

  echo $STABLE_SVN_TAG
}


###############################################################################
#
###############################################################################
get_git_version() {
  # Defining Current Realease Tag by
  RecentGitTag="$(
      # Getting List of Tags from remote repository
      git ls-remote -q --tags --refs $GIT_URL 2> $ERROR_LOG |
      # Cleaning Tag Value
      awk '{gsub("refs/tags/", "", $2); print $2 }' |
      # Sorting It
      sort -nr -k1.4                                |
      # Finaly print it  (assigning it to Release var)
      awk 'NR==1{print $1}'
  )"

  is_error
  if [[ $? -eq 1 ]]; then
    show_error
    exit 1
  fi

  if [[ $RecentGitTag == "" ]]; then
    echo "No Git Tags Found"
    exit 1;
  fi

  echo $RecentGitTag

}



###############################################################################
# Checking Out SVN Repo
###############################################################################

svn_checkout(){
  printf 'Checkingout SVN Repository into "%s"...' $SVN_DIR
  svn checkout --quiet $SVN_URL "${DIRECTORY:?}/${SVN_DIR:?}" 2> $ERROR_LOG

  is_error
  if [[ $? -eq 1 ]]; then
    printf " Fail\n"
    show_error
    clean_up_and_exit
    exit 1;
  fi
  printf " Done\n"
}

# REMOVE WHEN READY
svn_checkout_fake(){
  mkdir "${SVN_DIR}"
  cp -r FAKE_${SVN_DIR}/*  ${SVN_DIR}
}

git_checkout(){
  git clone -q $GIT_URL "${DIRECTORY:?}/${GIT_DIR:?}" 2> $ERROR_LOG
}




###############################################################################
# Cleaning Up...
###############################################################################

clean_up_and_exit() {


    if [[ ! -z $1 ]]; then
        echo "Shutdown Cleanup Running"
    else
        echo "Cleanup Running"
    fi


    if [[ -d "${DIRECTORY}/${SVN_DIR}" ]]; then
        echo -n "removing svn repository..."
        rm -rf "${DIRECTORY:?}/${SVN_DIR:?}"
        echo "Done."
    fi


    if [[ -d "${DIRECTORY}/${GIT_DIR}" ]]; then
        echo -n "removing dir repository..."
        rm -rf "${DIRECTORY:?}/${GIT_DIR:?}"
        echo "Done."
    fi

   if [[ -d "${DIRECTORY}/deployment/" ]]; then
        echo -n "removing deployment repository..."
        rm -rf "${DIRECTORY}/deployment/"
        echo "Done."
    fi

    echo 'Exiting Program...'

    # if we have 0 as exit argument - we exiting with this code.
    # of other code if we going to chagne this in future.
    if [[ ! -z $1 ]]; then
        exit $1
    fi

    exit 1;
}


find_and_move(){
  WHERE_TO_LOOK="${1}"
  WHAT_TO_LOOK_FOR="${2}"
  WHERE_TO_MOVE="${3}"

  if [[ ! -d $WHERE_TO_LOOK ]] || [[ ! -d $WHERE_TO_MOVE ]]; then
    return 0;
  fi

  find "${WHERE_TO_LOOK}"  -iname "${WHAT_TO_LOOK_FOR}"  \
    -maxdepth 1 -type f   | \
      xargs -I % cp % "${WHERE_TO_MOVE}";
}


deploy(){
  GIT_TAG_SOURCE=$1
  SVN_TAG_TARGET=$2


  cd "${GIT_DIR}"
  # step 1 - export tag as archive and un archive it.
  git archive --format=tar \
              --prefix=deployment/ \
              --output="${DIRECTORY:?}/archive.tar" \
              "tags/${STABLE_GIT_TAG}"

  cd ..

  # cleanup
  tar xf "${DIRECTORY:?}/archive.tar"
  rm "${DIRECTORY:?}/archive.tar"

  ###########################################################################
  # Step 2. - Plugin Assets
  # itterating though the list of assets and replacing it one by one
  ###########################################################################
  if [ ! -d "$DIRECTORY/$SVN_DIR/assets" ]; then
		  mkdir "$DIRECTORY/$SVN_DIR/assets";
	fi

  #
  # Screenshots
	# - screenshot-n.{jpg,jpeg,png}
	# Icons
	# - icon.svg
	# - icon-128x128.{jpg,jpeg,png}
	# - icon-256x256.{jpg,jpeg,png}
	# Banners
	# - banners-128x128.{jpg,jpeg,png}
	# - banners-256x256.{jpg,jpeg,png}
	#
	# Se more info at..
  # https://developer.wordpress.org/plugins/wordpress-org/plugin-assets/
  ##########################################################################


  for mask in $(echo 'screenshot*.*' 'icon*.*' 'banner*.*' ); do

    # Cleanup Files in SVN that fits to provided pattern.
    find "$DIRECTORY/$SVN_DIR/assets" -maxdepth 1 -type f \
                                      -iname $mask -exec rm {} \;

    # We going to check 3 dictories for our assets, in this way
    # (using if statements) we can avoid deleting files that can
    # fit to mask and still used by plugin
    # We Checking Directories in Next Order.
    #   - /
    #   - /assets
    #   - /wp-svn-assets

    # in order to simplify code we assigning pathes before running
    # if condditions scope
    find_and_move "$GIT_DIR" "$mask" "$SVN_DIR/assets/"
    find_and_move "$GIT_DIR/assets" "$mask" "$SVN_DIR/assets/"
    find_and_move "$GIT_DIR/wp-svn-assets" "$mask" "$SVN_DIR/assets/"
  done

  ##############################################################################
  # Step 2. - Compiling Readme.txt from Readme.md and *.md
  ##############################################################################
  README="$DIRECTORY/readme.txt"
  if [[ -f "${README}" ]]; then
    unlink "${README}"
  fi
  touch "${README}"

  # - README.md -> Frequently Asked Questions
  # - FAQ.md -> Frequently Asked Questions
  # - UPGRADE.md -> Upgrade Notice
  # - CHANGELOG.md -> Changelog
  # - SCREENSHOTS.md -> Screenshots
  # - INSTALL.md -> Installation
  FILES=("README" "FAQ" "UPGRADE" "CHANGELOG" "SCREENSHOTS" "INSTALL")
  EXTENSIONS=("md" "markdown")
  for FILE in ${FILES[*]} ; do
    for EXT in ${EXTENSIONS[*]}; do

      find "${GIT_DIR}"  -maxdepth 1 -type f \
                     -iname "${FILE}.${EXT}" -print0 | \
                     xargs -I % cat % >> "$DIRECTORY/readme.txt"

    done
  done

  ##########################################################################
  # Step 3. - Readme
  ##########################################################################
  # Initial ! at the start of readme.txt
  perl -i -pe 's/^!\n//g' "${README}"

  # h3 tags ### string in github / = string = in wppd
  perl -i -pe 's/### (.*?)\n/= $1 =\n/g' "${README}"

  # h2 tags ## string in github / == string == in wppd
  perl -i -pe 's/## (.*?)\n/== $1 ==\n/g' "${README}"

  # h1 tags # string in github / === string === in wppd
  perl -i -pe 's/# (.*?)\n/=== $1 ===\n/g' "${README}"

  # screenshots
  perl -i -pe 's/!\[(.*?)\]\(.*?screenshot-(\d{1,})\.(png|gif|jpe?g)\)/$2. $1/g' "${README}"

  # and badges
  perl -i -pe 's/!\[(.*?)\]\(.*?\)\n//g' "${README}"

  HEADERS_TO_REMOVE=("Contributors" "Tags" "Donate Link" \
    "Requires at least" "Tested up to" "Stable tag" \
    "License URI" "License")

  for header in "${HEADERS_TO_REMOVE[@]}"; do
    perl -i -pe 's/\* ($ENV{header}):(.*?)\n/$1: $2\n/ig' "${README}"
  done

  ##########################################################################
  # Step 4. - Contributors.
  # Ideally nickname is same, in other cases need to pre-change code.
  ##########################################################################
  perl -i -pe 'if (/Contributors/) { s/@//g }' "${README}"

  ##########################################################################
  # Step 5. - Prepare Files to Deploy
  ##########################################################################

  find "${DIRECTORY}/deployment" -maxdepth 1 -type f \
    -iname "readme.md" -exec rm {} \;
  find "${DIRECTORY}/deployment" -maxdepth 1 -type f \
    -iname "readme.markdown" -exec rm {} \;

  cp "${README}" "${DIRECTORY}/deployment"

  move_content "${DIRECTORY}/deployment" \
    "${DIRECTORY}/${SVN_DIR}/tags/${SVN_TAG_TARGET}/"
  move_content "${DIRECTORY}/deployment" \
    "${DIRECTORY}/${SVN_DIR}/trunk/"

  cd "${DIRECTORY}/${SVN_DIR}"

  # new files
  svn stat | grep "^?" | awk '{print $2}' | xargs svn add --quiet
  # old files
  svn stat | grep "^\!" | awk '{print $2}' | xargs svn remove --quiet

  svn commit -q --non-interactive \
        --username=$SVN_USER  \
        --password=$SVN_PASS \
        -m "Version ${STABLE_GIT_TAG}" 2> $ERROR_LOG

  is_error
  if [[ $? -eq 1  ]]; then
    show_error
    clean_up_and_exit
    exit 1
  fi

}

move_content(){
  SRC="${1}"
  DST="${2}"

  rm -rf "${DST}"
  mkdir -p "${DST}"
  cp -r "${SRC}/"* "${DST}"
}

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
