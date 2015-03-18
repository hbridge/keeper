#!/bin/bash
sudo su ubuntu <<EOF
'EOF'
cd /home/ubuntu/dev/keeper/
git fetch
git rebase origin/master
EOF

echo "Restarting scripts..."
sudo stop keeper-celery
sudo start keeper-celery

initctl list | grep duffy-celery
