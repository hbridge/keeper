#!/bin/bash

ssh -A ubuntu@prod.keeper.duffyapp.com "cd prod/keeper; git fetch; git rebase origin/master"


echo "Restarting scripts..."
ssh -A ubuntu@prod.keeper.duffyapp.com "sudo restart keeper-celery"
ssh -A ubuntu@prod.keeper.duffyapp.com "sudo restart keeper-node"

