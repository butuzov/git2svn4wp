

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

