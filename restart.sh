cd /home/bitnami/orcapods;
sudo service orca stop;
git reset --hard;
git clean -f;
git pull;
sudo service orca start;
