#!/bin/bash
sudo su ubuntu <<EOF
cd /home/ubuntu/dev/keeper/
git fetch
git rebase origin/master
EOF

echo "Restarting scripts..."
sudo stop keeper-celery
sudo start keeper-celery
sudo stop keeper-node
sudo start keeper-node

initctl list | grep duffy-celery
initctl list | grep duffy-node
