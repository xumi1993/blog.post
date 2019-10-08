#!/bin/bash

# hugo --baseUrl="https://xumi1993.github.io/blog"
cd public

if [ -n "$GITHUB_AUTH_SECRET" ]
then
    touch ~/.git-credentials
    chmod 0600 ~/.git-credentials
    echo $GITHUB_AUTH_SECRET > ~/.git-credentials
    git config credential.helper store
    git config user.email "gomijianxu@gmail.com"
    git config user.name "xumi1993"
fi
git add .
git commit -m `date +"%Y.%m.%dT%H:%M%S"`
git push --force origin HEAD:master
