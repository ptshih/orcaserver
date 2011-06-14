cd /home/bitnami/orcapods;
cd /home/bitnami/orcapods;
touch lastRestarted.txt;
sudo service orca stop;
git reset --hard;
git clean -f;
git pull;
sudo service orca start;
