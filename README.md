# Git to SVN for  WordPress Plugins or (git2svn4wp-plugins)
## What this for (shortly)?
1. Take your WordPress plugin Git (maybe even GitHub) repository
2. And commit changes to WordPress Plugins Directory SVN repository.

## Example
```bash
# Script Screates and Drop direcotries a lot... so it need to have
# some executions permissions
chmod +x git2svn4wp.sh

# Execution Example Kwywords Description.
#
# -svn=URL Where URL is WP SVN for your Plugin
# -git=URL Where URL is Git Repository URL
# -user=USERNAME Where USERNAME is WP SVN Username (case sensitive)
# -pass=******** WHERE ******** is WP SVN User password.
./git2svn4wp.sh -git=https://github.com/username/plugin-repo \
                -svn=http://plugins.svn.wordpress.org/plugin \
                -user=wp-svn-username \
                -pass=wp-svn-usernames-passoword
```

## A bit longer version of _"What this shell script does"_ ?

1. Ensure that published version is newer then one in svn. ( It wouldn't allow you to publish code to repository that has `trunk` as `Stable Tag` in your `readme.txt` of if your `readme.txt` doesn't have `Stable Tag` at all.

2. Convert your `ReAdMe.markdown` (or `readme.md`) and rest of `*.md` ( or `*.markdown` files) that found in your GitRepo root to `readme.txt` (so your repo *would not contain extra file you need to edit before release*) __[*](#readmetxt)__

3. Update [Plugin Assets](https://developer.wordpress.org/plugins/wordpress-org/plugin-assets/) to correct locations. Shell script will search for your assets in root (`/`), `assets` and `wp-svn-assets` and then copy them all to `/assets` directory of your svn repo. __[*](#assets)__

	__NOTE__: I haven't found a way to make this files or folder as non-exportable and still use it while deploying (deploy script uses a export/archive version of repository).

## Why? Inspiration.
This work is done mostly to automate CI/CD routine and practice some shell scripting skills. Deployer hardly inspired by  [svn2git-tools](https://github.com/ocean90/svn2git-tools/) by legendary @ocean90.

## Features & Todo's

* [x] Plugin Header readme.md -> readme.txt conversion
  * [ ] Need to provide a way to preserve readme.txt in case its required by plugin authors.
* [x] Assets management
  * [ ] Need to find a way to block export of useless assets and still use it for deployment.
* [x] Clean-up Procedure
* [ ] Shell analogue of php's `version_compare`
* [ ] Integration examples (like Travis, Circle-CI etc...).
* [ ] Integration with deployed plugins (so code from deployed repository can interact with deploy proccess like `do_action` always did.)


### Errors you can run into.

```bash
# Something wrong with your `SVN_USER` its not exists in SVN or misspelled.
# WordPress SVN usernames case sensitive btw
svn: E000000: Commit failed (details follow):
svn: E000000: Access to '/!svn/me' forbidden

# You using wrong password `SVN_PASS`.
svn: E000000: Authentication failed and interactive prompting is disabled; see the --force-interactive option
svn: E000000: Commit failed (details follow):
svn: E000000: No more credentials or we tried too many times.
```



###### Footnotes
* <a name="readmetxt"></a> `readme.txt` used only in [WordPress Plugin Directory](https://wordpress.org/plugins/), and keeping them in git repo (on my opinion) is pointless task.
* <a name="assets"></a> [Plugin Assets](https://developer.wordpress.org/plugins/wordpress-org/plugin-assets/) also only used by WordPress Plugin Directory
