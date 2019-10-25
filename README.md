# Git to SVN for  WordPress Plugins or (wp-plugins-deploy)

![GitHub All Releases](https://img.shields.io/github/downloads/butuzov/wp-plugins-deploy/total)

## What this for?
1. Develop your plugin using Git
2. Deploy new release to WordPress Plugins Directory (SVN)

## Example

```bash
# Execution Example Kwywords Description.
#
# -svn=URL Where URL is WP SVN for your Plugin
# -git=URL Where URL is Git Repository URL
# -user=USERNAME Where USERNAME is WP SVN Username (case sensitive)
# -pass=******** WHERE ******** is WP SVN User password.
./wp-deploy.sh --git=https://github.com/username/plugin-repo \
               --svn=http://plugins.svn.wordpress.org/plugin \
               --user="${WP_SVN_USER}" --pass="${WP_SVN_PASSWORD}"

# redeploy current git tag
./wp-deploy.sh --git=https://github.com/username/plugin-repo \
               --svn=http://plugins.svn.wordpress.org/plugin \
               --user="${WP_SVN_USER}" -pass="${WP_SVN_PASSWORD}" \
			   --force
```

## Options

* `-git` or `--git`: URL of GIT repository
* `-svn` or `--svn`: URL of SVN repository
* `-u`, `--u`, `-user`, `--user`, `-username` or `--username`: SVN username.
* `-p`, `--p`, `-pass`, `--pass`, `-password` or `--password`: SVN username.
* `-f`, `--force`: Force GIT tag redeployment.

## A bit longer version of _"What this shell script does"_ ?

1. Ensure that published version is newer then one in svn. ( It wouldn't allow you to publish code to repository that has `trunk` as `Stable Tag` in your `readme.txt` of if your `readme.txt` doesn't have `Stable Tag` at all.

2. Convert your `readme.md` (or `readme.md`) and rest of `*.md` ( or `*.markdown` files) that found in your GitRepo root to `readme.txt` (so your repo *would not contains extra file you need to edit before release*) __[*](#readmetxt)__

3. Update [Plugin Assets](https://developer.wordpress.org/plugins/wordpress-org/plugin-assets/) to correct locations. Shell script will search for your assets in root (`/`), `assets` and `wp-svn-assets` and then copy them all to `/assets` directory of your svn repo. __[*](#assets)__

	__NOTE__: I haven't found a way to make this files or folder as non-exportable and still use it while deploying (deploy script uses a export/archive version of repository).

## Why? Inspiration.

This script is done to automate boring CD tasks. Inspired by  [svn2git-tools](https://github.com/ocean90/svn2git-tools/) by @ocean90.

## Features & Todo's

* [x] Generation of `readme.txt`: Allow you to use github style markdown, in order to generate readme.txt
* [x] Separate Usage of assets (no need to deploy assets to final users if only wordpress plugins directory require it)
* [x] Forse update of current release.


### Troubleshooting.

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

### Example Git repository.

This script used for deployments of [Debug Bar Rewrite Rules](https://github.com/butuzov/Debug-Bar-Rewrite-Rules) plugin.

### Footnotes
* <a name="readmetxt"></a> `readme.txt` used only in [WordPress Plugin Directory](https://wordpress.org/plugins/), and keeping them in git repo (on my opinion) is pointless task.
* <a name="assets"></a> [Plugin Assets](https://developer.wordpress.org/plugins/wordpress-org/plugin-assets/) also only used by WordPress Plugin Directory
