#!/bin/bash

###############################################################################
# This work is done mostly to automate CI/CD routine and practice some shell
# scripting skills. Deployer hardly inspired by svn2git-tools by legendary
# @ocean90.
#
# License           : GPL v2
# Last Modification : 2017-04-19
# Last Author       : Oleg Butuzov
# Url               : https://github.com/butuzov/git2svn4wp
###############################################################################


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

################################################################################
# Defining Function and Common Variables
################################################################################

# Let's begin...
DIR="$(pwd)"

# Lack of of knowledge force me to use file to store `stderr` messages.
ERROR_LOG="$DIR/error.txt"

# is_error
#
# Dow we have error now? If so, cehck error.txt if it has size more then 1
# (empty) it has errors.
is_error(){

    if [[ -f $ERROR_LOG ]]; then

        ERROR_LOG_SIZE="$(ls -la $ERROR_LOG | awk '{print $5}')"

        if [[ ERROR_LOG_SIZE -gt 2 ]]; then
            #echo "fuck"
            return 1
        else
            # file empty -> ok!
            return 0
        fi
    else
        # file not exists -> ok!
        return 0
    fi
}

# Show error and delete error log.
# This message will self-destruct in five seconds.
show_error() {
    if [[ -f $ERROR_LOG ]]; then
        echo "Error:"
        cat $ERROR_LOG | awk '{print "\t"$0}'
        echo ""
        unlink $ERROR_LOG
    fi
}

# If Program Fails - we running Emergency cleanup procedure...
clean_up_and_exit() {

    if [[ ! -z $1 ]]; then
        echo "Running \"Exit\" Clean-Up Procedures..."
    else
        echo "Running \"Emergency Exit\" Clean-Up Procedures..."
    fi


    if [[ -d $DIR/$SVN_DIR ]]; then
        echo -n "Removing SVN Directory with all contents..."
        rm -rf "${DIR:?}/${SVN_DIR:?}"
        echo "Done."
    fi


    if [[ -d $DIR/$GIT_DIR ]]; then
        echo -n "Removing GIT Directory with all contents..."
        rm -rf "${DIR:?}/${GIT_DIR:?}"
        echo "Done."
    fi

    echo 'Exiting Program... Bye-Bye'

    # if we have 0 as exit argument - we exiting with this code.
    # of other code if we going to chagne this in future.
    if [[ ! -z $1 ]]; then
        exit $1
    fi

    exit 1;
}


# Forming SVN Directory Name
SVN_DIR="$(
    # Basename of SVN Repo -> Plugin Name
    basename $SVN_URL |
     # Lowercase (optional)
    awk '{print tolower($0)}'
)-svn"  # Addition assignment of '-svn' to directory name


# GIT_URL=https://github.com/butuzov/Debug-Bar-Rewrite-Rules.git
GIT_DIR=$(echo $SVN_DIR | awk '{gsub("-svn", "-git", $0); print $0 }')
rm -rf "${DIR:?}/${SVN_DIR:?}"

###############################################################################
# Gerring Last Tag from Git Repo
###############################################################################
echo -n "Getting Last Git Tag (version)..."

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
    echo " Fail"
    show_error
    clean_up_and_exit
elif [[ $RecentGitTag == "" ]]; then
    echo " Fail"
    echo -e "Error:"
    echo -e "\tCan't retrive tags inforamtion from repository."
    echo -e "\tCheck if you have any"
    echo ""
    clean_up_and_exit
else
    echo " Done."
    echo "Last Git Release Tag - $RecentGitTag"
    unlink $ERROR_LOG
fi


###############################################################################
# Checking Out SVN Repo
###############################################################################
echo -n "Checking Out SVN Repository into \"$SVN_DIR\"..."
svn checkout --quiet $SVN_URL "${DIR:?}/${SVN_DIR:?}" 2> $ERROR_LOG


is_error
if [[ $? -eq 1 ]]; then
    echo " Fail"
    show_error
    clean_up_and_exit
else
    echo " Done."

    if [[ -f $DIR/$SVN_DIR/trunk/readme.txt ]]; then
        StableTag="$(
            # Output readme.txt and piping to awk
            cat $DIR/$SVN_DIR/trunk/readme.txt |
            # if it is Stable Tag, print the verion to StableTag variable
            awk '/Stable tag/{print $3}'
        )"

        # now we can run into sutuation that
        # a) stable tag missing from readme.txt (but code exists!)
        if [[ -z $StableTag ]]; then
            echo "Error:"
            echo -e -n "\tUnable to retrive \"Stable Tag\""
            echo " informartion from readme.txt."
            echo ""
            clean_up_and_exit
        fi

        # b) tag points to "trunk" what basically means there no verions
        # in this plugin, so let it be.
        if [[ "trunk" == "$StableTag" ]]; then
            echo "Error:"
            echo -e -n "\t\"Stable Tag\" points to trunk, please fix this info "
            echo -e -n " in your readme.txt\n" # line limit 80
            echo -e -n "\tbefore running deploy.sh.\n"
            echo ""
            clean_up_and_exit
        fi

        # c) other cases.
        # @todo - I need to gather stat

    else
        echo "Warning:"
        echo -e "\tUnanable to locate \"readme.txt\" get Stable Tag from it."
        echo -e "\tSetting Stable Tag variable to \"0\"."
        StableTag=0
    fi

    #echo "Last Git Release Tag - $RecentGitTag"
    unlink $ERROR_LOG
fi


# Show Stable Tag from Existing SVN Repository
echo "Last SVN Stable Tag - $StableTag"
MostRecentTag=$(echo -e "$RecentGitTag\n$StableTag" | sort -nr | head -1)
if [[ $MostRecentTag == $RecentGitTag ]] && [[ $StableTag != $RecentGitTag ]];
then
    # MESSAGE!
    echo "Preparing Release Version $RecentGitTag for a Deployment..."

    # We doing Git Clone instead git archive --remote due github doesn't
    # really allow it so to make things easier we will
    # clone, archive, cleanup directory and export files from archive to
    # directory ($GIT_DIR)
    rm -rf "${DIR:?}/${GIT_DIR:?}"
    echo -n "Checking Out Git Repository into \"$GIT_DIR\"...";
    git clone -q $GIT_URL $DIR/$GIT_DIR
    cd "${DIR:?}/${GIT_DIR:?}"
    git archive --prefix=$GIT_DIR/ tags/$RecentGitTag --output=$DIR/archive.tar
    cd $DIR && rm -rf "${DIR:?}/${GIT_DIR:?}"
    tar xf "${DIR:?}/archive.tar" && rm "${DIR:?}/archive.tar"
    echo 'Done'.;

    # in case if there is no assets directory in svn, we going to create one
    if [ ! -d "$DIR/$SVN_DIR/assets" ];then
		mkdir "$DIR/$SVN_DIR/assets";
	fi

    # defining few usefull var to use it.
    # no paticular sence of using it, except a shorter line
    # (without line break)
    root=$DIR/$GIT_DIR

    # arguments to not repeat yourself,
    #  - maxdepth 1 (will look only in asked directory)
    #  - type f (searching for files)
    find_args="-maxdepth 1 -type f"

    ###########################################################################
    # Step 1. - Plugin Assets
    # itterating though the list of assets and replacing it one by one
    ###########################################################################
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

    echo -n "Preparing assets..."
    for mask in $( echo 'screenshot*.*' 'icon*.*' 'banner*.*' ); do
        # clean up for this mask if any files found at assts DIRectory
        if [[ -n "$(find $SVN_DIR/assets $find_args -iname $mask)" ]]; then
            # delete asset from assets DIRectory
             find "$DIR/$SVN_DIR/assets" $find_args -iname $mask | xargs rm
        fi

        # We going to check 3 dictories for our assets, in this way
        # (using if statements) we can avoid deleting files that can
        # fit to mask and still used by plugin

        # We Checking Directories in Next Order.
        # - /
        # - /assets
        # - /wp-svn-assets

        # in order to simplify code we assigning pathes before running
        # if condditions scope

        assets_root=$root/assets
        assets_rwp=$root/wp-svn-assets
        assets_svn=$DIR/$SVN_DIR/assets/

		if [[ -n "$(find $root $find_args -iname $mask)" ]]; then
			find $root $find_args -iname $mask | xargs -I % mv % $assets_svn

        # If It doesn't work - we search in root/assets directory.
        elif [[ -d $assets_root ]] \
            && [[ -n "$(find $assets_root $find_args -iname $mask)" ]]; then

            # Piping found files to mv command sto copy in svn/assets directory
			find $assets_root $find_args f -iname $mask \
                | xargs -I % mv % $assets_svn

            # in case if directory already empty.
            # removing this directory.
            if [[ ! -n "$(find $assets_root $find_args -iname '*.*')" ]]; then
                rmdir $assets_root
            fi

        # If It doesn't work - we search in root/wp-svn-assets directory.
        elif [[ -d $assets_rwp ]] \
            && [[ -n "$(find $assets_rwp $find_args -iname $mask)" ]]; then

            # piping found files to mv command sto copy in svn/assets directory
			find $assets_rwp $find_args -iname $mask \
                | xargs -I % mv % $assets_svn

            # in case if directory already empty.
            # removing this directory.
            if [[ ! -n "$(find $assets_rwp $find_args -iname '*.*')" ]]; then
                rmdir $assets_rwp
            fi
		fi
    done
    echo " Done."

    ###########################################################################
    # Step 2. - Compiling Readme.txt from Readme.md and *.md
    ###########################################################################

    touch $root/readme.txt

	# By *.md and *.markdown I mean
 	# - FAQ.md -> Frequently Asked Questions
 	# - UPGRADE.md -> Upgrade Notice
 	# - CHANGELOG.md -> Changelog
 	# - SCREENSHOTS.md -> Screenshots
 	# - INSTALL.md -> Installation

	for markdown_pattern in $( echo 'readme.md' 'readme.markdown' '*.md' '*.markdown' ); do
		found_markdown_files="$(find $root $find_args  -iname $markdown_pattern)"
		if [[ -n $found_markdown_files ]];
		then
			for file in $found_markdown_files; do
                echo "" >> $root/readme.txt
				cat $file >> $root/readme.txt
				unlink $file
			done
		fi
	done

    # Why to use sed if you can have problems with perl? =)

    echo -n "Preparing readme.txt.."
    # Initial ! at the start of readme.txt
    perl -i -pe 's/^!\n//g'  $root/readme.txt
    # h3 tags ### string in github / = string = in wppd
	perl -i -pe 's/### (.*?)\n/= $1 =\n/g' $root/readme.txt
    # h2 tags ## string in github / == string == in wppd
    perl -i -pe 's/## (.*?)\n/== $1 ==\n/g' $root/readme.txt
    # h1 tags # string in github / === string === in wppd
    perl -i -pe 's/# (.*?)\n/=== $1 ===\n/g' $root/readme.txt
    # screenshots
    perl -i -pe 's/!\[(.*?)\]\(.*?screenshot-(\d{1,})\.(png|gif|jpe?g)\)/$2. $1/g' $root/readme.txt

    ##########################################################################
    # Step 3. - Clean UP Headers in readme.txt
    ##########################################################################
    for header in $( echo 'Contributors Tags Donate_Link Requires_at_least
         Tested_up_to Stable_tag License_URI License'); do
        header=$(echo $header | awk '{gsub("_", " ", $0); print $0 }' )
        perl -i -pe 's/\* ($ENV{header}):(.*?)\n/$1: $2\n/ig' $root/readme.txt
    done

    ##########################################################################
    # Step 4. - Contributors.
    # Ideally nickname is same, in other cases need to pre-change code.
    ##########################################################################
    perl -i -pe 'if (/^Contributors/) { s/@//g }' $root/readme.txt
    echo " Done."

    ##########################################################################
	# Step 5. - Before Deployment
    # I was wandering how is better ot organize travis analogue of
    # `before_install` and i guess its better to just include
	# @todo - Implement.
	##########################################################################

    # MESSAGE!
    echo "Release Version $RecentGitTag Ready for Deployment..."

    ##########################################################################
    # Step n. - Copy tmp directory to trunk  and tags
    ##########################################################################
    echo -n "Copy files to Trunk..."
	rm -rf "${DIR:?}/${SVN_DIR:?}/trunk/*"
	cp -a  $root/. $DIR/$SVN_DIR/trunk
    echo " Done."

    cd "${DIR:?}/${SVN_DIR:?}"

    # Code (almost) direct copy/pasted from
    # https://github.com/ocean90/svn2git-tools/
    echo -n "Adding new files to SVN Repo..."
    svn stat | grep "^?" | awk '{print $2}' | xargs svn add --quiet
    echo " Done."

    echo -n "Removing old files from SVN Repo..."
    svn stat | grep "^\!" | awk '{print $2}' | xargs svn remove --quiet
    echo " Done."

    # Preparign to Commit changes
    echo -n "Committing changes to SVN ..."

    svn commit -q --non-interactive \
        --username=$SVN_USER  \
        --password=$SVN_PASS \
        -m "Version bumped to $MostRecentTag" 2> $ERROR_LOG

    is_error
    if [[ $? -eq 1  ]]; then
        echo " Fail."
        show_error
        clean_up_and_exit
        exit 1
    else
        echo " Done."
        unlink $ERROR_LOG
    fi

    # And Preparign to Copy changes
    echo -n "Tagging and committing new SVN tag..."
    svn copy $SVN_URL/trunk $SVN_URL/tags/$MostRecentTag \
        -q --non-interactive --username=$SVN_USER --password=$SVN_PASS \
        -m "Tagging version $MostRecentTag" 2> $ERROR_LOG

    is_error
    if [[ $? -eq 1  ]]; then
        echo " Fail."

        show_error
        clean_up_and_exit
        exit 1
    else
        echo " Done."
        unlink $ERROR_LOG
    fi

    echo "Tag $RecentGitTag deployed to WordPress Plugin Directory SVN ..."
    clean_up_and_exit 0

else

    echo -n "Tag $RecentGitTag already deployed..."
    clean_up_and_exit

fi