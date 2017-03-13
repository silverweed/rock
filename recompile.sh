#!/bin/sh

git pull && PATH=$PATH:$HOME $HOME/coffee-script/bin/coffee -c --bare rock.coffee
