#!/bin/bash

# hugo --baseUrl="https://xumi1993.github.io/blog"
cd public
git add .
git commit -m `date +"%Y.%m.%dT%H:%M%S"`
git push origin master
