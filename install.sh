#!/usr/bin/env bash

# Make sure we are not running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root" 1>&2
   exit 1
fi

BASIL_ROOT=$(cd -P $(dirname "$0") && pwd)

if [[ -z "$BASH_VERSION" ]]; then
		echo "Error: GC SDK install script should be run in bash."
		exit 1
fi

echo $'\033[1;32m-{{{>\033[0m Game Closure SDK'
echo 'Installing...'

function abs_path() {
	echo "$1" | sed "s@^./@$PWD@"
}

function error () {
	echo -e "\033[1;31mError:\033[0m $@"
}

function warn () {
	echo -e "\033[1;33mWarning:\033[0m $@"
}

if ! which git > /dev/null; then
		error "GC SDK requires git to install. (http://git-scm.com)"
		exit 1
fi

if ! which node > /dev/null; then
		error "GC SDK requires node 0.8+ to install. (http://nodejs.org)"
		exit 1
fi

if ! which npm > /dev/null; then
		error "GC SDK requires npm to install. (http://npmjs.org)"
		exit 1
fi

#
# Permission checks
#
#

if [[ ! -d "$HOME/.npm" ]]; then
		mkdir "$HOME/.npm"
fi

if [[ ! -w "$HOME/.npm" ]]; then
		error "GC SDK install requires write permission to $HOME/.npm"
		echo "Try: sudo chown -R $USER $HOME/.npm"
		exit 1
fi

#
# Install
#

BASIL_PATH=$(which basil)

if [[ -L "$BASIL_PATH" ]]  ; then
		echo "Removing old basil symlink."
		rm "$BASIL_PATH"
fi

echo -e "\nInitializing GC SDK libraries ..."

# setup for gc internal repositories
remoteurl=`git config --get remote.origin.url`
PRIV_SUBMODS=false && [[ "$remoteurl" == *devkit-priv* ]] && PRIV_SUBMODS=true
if $PRIV_SUBMODS; then
	echo "Using private submodules..."
	cp .gitmodules-priv .gitmodules
fi

if ! git submodule sync; then
		error "Unable to sync git submodules"
		exit 1
fi

git submodule update --init --recursive

if $PRIV_SUBMODS; then
	git checkout .gitmodules
fi

if ! npm install; then
		error "Linking npm to local"
		echo "Try running: sudo chown -R \$USER /usr/local"
		exit 1
fi

echo

node src/dependencyCheck.js

if [[ "$1" != "--silent" ]]; then
	node src/analytics.js
fi

echo 

if [[ $? != 0 ]]; then
	error 'Could not complete installation'
else
	echo 'Successfully installed. Type "basil" to begin.'
fi
