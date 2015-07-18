# ami-d05e75b8, t2.medium
sudo apt-get update
sudo apt-get install -y emacs git tmux ntp

sudo timedatectl set-timezone America/Chicago

wget -qO- https://get.docker.com/ | sh

sudo adduser --disabled-login --disabled-password --gecos "" mdagost
sudo usermod -aG docker mdagost

sudo su mdagost
docker login

cd /home/mdagost/
git clone https://github.com/mdagost/autoswa.git
cd autoswa
scp localhost:~/secrets.yaml aws:~/

docker pull mdagost/perl_mechanize
docker run -it -v /home/mdagost/autoswa:/app mdagost/perl_mechanize perl /app/perl/scripts/doCheckin.pl CONF FN LN multiple_checkin [1|0] from_email to_email

# example crontab entry
# mm hh day mon * docker run -it -v /home/mdagost/autoswa:/app mdagost/perl_mechanize perl /app/perl/scripts/doCheckin.pl CONF FN LN multiple_checkin [1|0] from_email to_email
