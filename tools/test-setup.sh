#!/bin/bash
# This tool is used to setup the environment for running the tests. Its name
# name and location is based on Zuul CI, which can automatically run it.
set -euo pipefail

# User specific environment
# shellcheck disable=SC2076
for entry in "$HOME/.local/bin"; do
    if ! [[ "$PATH" =~ $entry ]]
    then
        PATH="$entry:$PATH"
    fi
done
export PATH
# save it for further sessions
# shellcheck disable=SC2016
echo 'export PATH="$PATH"' >> ~/.bashrc
set -x

if [ -f "/etc/os-release" ]; then
    sudo apt-get update  # mandatory or other apt-get commands fail
    sudo apt-get remove -y ansible || true
fi

# on WSL we want to avoid using Windows's npm (broken)
if [ "$(which npm)" == '/mnt/c/Program Files/nodejs/npm' ]; then
    sudo apt-get install -y curl
    curl --silent -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    which -a npm
    which -a node
    # Activate nvm for current shell
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
    which -a node
    which -a npm

    nvm install --lts
    which -a node
    node --version
fi

which pre-commit || pipx install pre-commit
uname
if [ -f /etc/hosts ]; then  # if we are not on pure Windows
    # GHA comes with ansible-core preinstalled via pipx, so we will
    # inject the linter into it. MacOS does not have it.
    which ansible || pipx install ansible-core
    pipx inject --include-deps ansible-core --include-binaries ansible-lint yamllint
    ansible --version
    ansible-lint --version
fi

npm config set fund false
npm ci
