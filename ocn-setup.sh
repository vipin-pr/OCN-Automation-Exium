#!/bin/bash

if [ $# -eq 0 ]
then
echo "kindly execute the below commands before running the script - Please be cautious "
echo "Change the User-Name to current logged in standard user in fourth command - execute whoami to find username from a non root account"
echo
echo "sudo su"
echo 'sudo echo 'deb [trusted=yes] http://debrepo.exium.net/repos/exium-client/debian/amd64 /' > /etc/apt/sources.list.d/exium.list'
echo "cp /etc/sudoers /root/sudoers.bak"
echo "echo User-Name   ALL = NOPASSWD: /usr/sbin/service exium-client restart, /usr/bin/killall -s SIGKILL exium-cli, /usr/bin/systemctl restart exium-client.service >> /etc/sudoers"
echo "exit"
echo
echo "After running the above commands pls use install parameter to install the dependencies"
echo "./ocn-setup.sh install"
echo
exit
fi

if [ $1 == "install" ]; then
#script for automating installation of OCN-Automation script and its dependencies
echo "[+]This script will configure the dependencies required for OCN-Automation script"
echo "[+]Gathering Username"
username=$(whoami)
echo "[+]$username can restart exium-client without password "
git clone https://github.com/vipin-exium/OCN-Status-Automation.git

chmod +x /home/$username/OCN-Status-Automation/status
chmod +x /home/$username/OCN-Status-Automation/ping.sh
chmod +x /home/$username/OCN-Status-Automation/connect
echo "[+]Changed Permissions of the Script"

ln -s OCN-Status-Automation/ping.sh /home/$username/ping
ln -s OCN-Status-Automation/status /home/$username/status
ln -s OCN-Status-Automation/connect /home/$username/connect

echo "[+]creating shortcuts for scripts"
echo "status       .... done"
echo "ping.sh      .... done"
echo "connect      .... done"


echo "[+]Installing Exium-cli"
#installation of exium-cli
sudo apt-get update -y 
sudo apt-cache policy exium-client
sudo apt-get install exium-client -y
echo "[+]Installing Python3-pip"
#installation of python-3
sudo apt-get install python3-pip -y
echo "[+]Installing Slack for slackbot"
pip install slack
pip install slackclient
pip install slack_sdk
git clone https://github.com/Parveshdhull/slackbot.git
echo "[+]Renaming Slackbot directory to Slack-bot"
mv slackbot slack-bot

echo "[+]Injecting Token to slackbot"
sed -i 's/API_TOKEN_HERE/API-TOKEN/' /home/$username/slack-bot/slackbot
echo "[+]Token injected successfully"
echo "[+]Creating soft link for slackbot"
ln -s /home/$username/slack-bot/slackbot
echo "[+]OCN-Automation is configured successfully"
echo
echo "After the Installation kindly login to the workspace.."
echo "exium-cli login -w workspace-name -u username"
echo
exit

else

echo "./ocn-setup.sh install - to install the OCN-Automation Script and its dependencies..."

fi
