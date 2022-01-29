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
set -x
export PATH
# save it for further sessions
# shellcheck disable=SC2016
echo 'export PATH="$PATH"' >> ~/.bashrc

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
    # Activate nvm
    set +exu
    source ~/.bashrc
    set -exu

    nvm install --lts
    which -a node
    which -a npm
    node --version
fi

pipx install pre-commit
uname
if [ -f /etc/hosts ]; then  # if we are not on pure Windows
    # GHA comes with ansible-core preinstalled via pipx, so we will
    # inject the linter into it. MacOS does not have it.
    pipx install ansible-core
    pipx inject --include-apps ansible-core ansible-lint yamllint
    ansible --version
    ansible-lint --version
fi

npm config set fund false
npm ci
