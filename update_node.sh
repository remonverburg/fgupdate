#!/bin/bash
clear

# Set these to change the version of FantasyGold to install
TARBALLURL="https://github.com/FantasyGold/FantasyGold-Core/releases/download/v1.2.5/FantasyGold-1.2.5-Linux-x64.tar.gz"
TARBALLNAME="FantasyGold-1.2.5-Linux-x64.tar.gz"
FGCVERSION="1.2.5"

# Check if we are root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

# Check if we have enough memory
if [[ `free -m | awk '/^Mem:/{print $2}'` -lt 900 ]]; then
  echo "This installation requires at least 1GB of RAM.";
  exit 1
fi

# Check if we have enough disk space
if [[ `df -k --output=avail / | tail -n1` -lt 10485760 ]]; then
  echo "This installation requires at least 10GB of free disk space.";
  exit 1
fi

# Install tools for dig and systemctl
echo "Preparing installation..."
apt-get install git dnsutils systemd -y > /dev/null 2>&1

# Check for systemd
systemctl --version >/dev/null 2>&1 || { echo "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# CHARS is used for the loading animation further down.
CHARS="/-\|"
EXTERNALIP=`dig +short myip.opendns.com @resolver1.opendns.com`
clear

echo "
    ___T_
   | o o |
   |__-__|
   /| []|\\
 ()/|___|\()
    |_|_|
    /_|_\  ------- MASTERNODE INSTALLER v2.1 -------+
 |                                                |
 |You can choose between two installation options:|::
 |             default and advanced.              |::
 |                                                |::
 | The advanced installation will install and run |::
 |  the masternode under a non-root user. If you  |::
 |  don't know what that means, use the default   |::
 |              installation method.              |::
 |                                                |::
 | Otherwise, your masternode will not work, and  |::
 |the FGC Team CANNOT assist you in repairing |::
 |        it. You will have to start over.        |::
 |                                                |::
 |Don't use the advanced option unless you are an |::
 |            experienced Linux user.             |::
 |                                                |::
 +------------------------------------------------+::
   ::::::::::::::::::::::::::::::::::::::::::::::::::
"

sleep 5

read -e -p "Use the Advanced Installation? [N/y] : " ADVANCED

if [[ ("$ADVANCED" == "y" || "$ADVANCED" == "Y") ]]; then

USER=fantasygold

adduser $USER --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password > /dev/null

echo "" && echo 'Added user "fantasygold"' && echo ""
sleep 1

else

USER=root

fi

USERHOME=`eval echo "~$USER"`

read -e -p "Server IP Address: " -i $EXTERNALIP -e IP
read -e -p "Masternode Private Key (e.g. 7edfjLCUzGczZi3JQw8GHp434R9kNY33eFyMGeKRymkB56G4324h # THE KEY YOU GENERATED EARLIER) : " KEY
read -e -p "Install Fail2ban? [Y/n] : " FAIL2BAN
read -e -p "Install UFW and configure ports? [Y/n] : " UFW

clear

# Generate random passwords
RPCUSER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RPCPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# update packages and upgrade Ubuntu
echo "Installing dependencies..."
apt-get -qq update
apt-get -qq upgrade
apt-get -qq autoremove
apt-get -qq install wget htop unzip
apt-get -qq install build-essential && apt-get -qq install libtool autotools-dev autoconf automake && apt-get -qq install libssl-dev && apt-get -qq install libboost-all-dev && apt-get -qq install software-properties-common && add-apt-repository -y ppa:bitcoin/bitcoin && apt update && apt-get -qq install libdb4.8-dev && apt-get -qq install libdb4.8++-dev && apt-get -qq install libminiupnpc-dev && apt-get -qq install libqt4-dev libprotobuf-dev protobuf-compiler && apt-get -qq install libqrencode-dev && apt-get -qq install git && apt-get -qq install pkg-config && apt-get -qq install libzmq3-dev
apt-get -qq install aptitude

# Install Fail2Ban
if [[ ("$FAIL2BAN" == "y" || "$FAIL2BAN" == "Y" || "$FAIL2BAN" == "") ]]; then
  aptitude -y -q install fail2ban
  service fail2ban restart
fi

# Install UFW
if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
  apt-get -qq install ufw
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow ssh
  ufw allow 57810/tcp
  yes | ufw enable
fi

# Install FantasyGold daemon
wget $TARBALLURL
tar -xzvf $TARBALLNAME #&& mv bin fantasygold-$FGCVERSION
rm $TARBALLNAME
cp ./fantasygoldd /usr/local/bin
cp ./fantasygold-cli /usr/local/bin
cp ./fantasygold-tx /usr/local/bin
cp ./fantasygold-qt /usr/local/bin
rm -rf fantasygold-$FGCVERSION

# Create .fantasygold directory
mkdir $USERHOME/.fantasygold

# Install bootstrap file
#if [[ ("$BOOTSTRAP" == "y" || "$BOOTSTRAP" == "Y" || "$BOOTSTRAP" == "") ]]; then
#  echo "Installing bootstrap file..."
#  wget $BOOTSTRAPURL && unzip $BOOTSTRAPARCHIVE -d $USERHOME/.fantasygold/ && rm $BOOTSTRAPARCHIVE
#fi

# Create fantasygold.conf
touch $USERHOME/.fantasygold/fantasygold.conf
cat > $USERHOME/.fantasygold/fantasygold.conf << EOL
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
externalip=${IP}
bind=${IP}:57810
masternodeaddr=${IP}
masternodeprivkey=${KEY}
masternode=1
addnode=18.218.69.84:57810
addnode=18.222.88.20:57810
addnode=18.188.230.37:57810
addnode=45.56.104.241:57810
addnode=172.104.152.61:57810
addnode=80.211.188.25:57810
addnode=45.76.131.138:57810
addnode=159.89.128.75:57810
addnode=209.250.236.200:57810
addnode=199.247.13.241:57810
addnode=108.61.87.124:57810
addnode=45.63.64.205:57810
addnode=138.68.225.190:57810
addnode=8.9.11.67:57810
addnode=104.236.95.172:57810
addnode=149.28.42.218:57810
addnode=159.65.72.255:57810
addnode=18.216.52.206:57810
addnode=89.47.161.171:57810
addnode=80.209.224.171:57810
addnode=144.76.38.145:57810
addnode=18.191.6.184:57810
addnode=173.230.141.205:57810
addnode=217.69.3.8:57810
addnode=45.79.66.44:57810
addnode=198.13.47.101:57810
addnode=104.207.134.81:57810
addnode=173.199.115.226:57810
addnode=178.62.204.40:57810
addnode=45.32.215.41:57810
addnode=207.246.125.20:57810
addnode=165.227.106.45:57810
addnode=8.12.17.243:57810
addnode=188.166.116.194:57810
addnode=63.209.33.1:57810
addnode=140.82.15.110:57810
addnode=45.77.85.29:57810
addnode=207.148.7.121:57810
addnode=188.187.188.194:57810
addnode=35.194.84.154:57810
addnode=35.186.174.191:57810
addnode=35.230.173.242:57810
addnode=35.199.27.31:57810
addnode=104.200.28.221:57810
addnode=23.239.31.167:57810
addnode=66.228.47.113:57810
addnode=139.162.125.201:57810
addnode=176.223.128.203:57810
addnode=217.163.23.44:57810
addnode=146.71.79.203:57810
addnode=212.237.19.177:57810
addnode=95.179.129.17:57810
addnode=80.240.17.186:57810
addnode=206.189.167.173:57810
addnode=81.169.214.103:57810
addnode=85.217.171.181:57810
addnode=104.238.161.88:57810
addnode=213.52.129.183:57810
addnode=138.197.216.71:57810
addnode=198.58.115.246:57810
addnode=172.105.224.65:57810
addnode=172.245.36.202:57810
addnode=45.33.8.12:57810
addnode=144.202.100.185:57810
addnode=184.75.221.43:57810
addnode=85.90.245.195:57810
addnode=178.79.190.143:57810
addnode=95.96.104.94:57810
EOL
chmod 0600 $USERHOME/.fantasygold/fantasygold.conf
chown -R $USER:$USER $USERHOME/.fantasygold

sleep 1

cat > /etc/systemd/system/fantasygoldd.service << EOL
[Unit]
Description=fantasygoldd
After=network.target
[Service]
Type=forking
User=${USER}
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/fantasygoldd -conf=${USERHOME}/.fantasygold/fantasygold.conf -datadir=${USERHOME}/.fantasygold
ExecStop=/usr/local/bin/fantasygold-cli -conf=${USERHOME}/.fantasygold/fantasygold.conf -datadir=${USERHOME}/.fantasygold stop
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl enable fantasygoldd
sudo systemctl start fantasygoldd
sudo systemctl start fantasygoldd.service

#clear

#clear
#echo "Your masternode is syncing. Please wait for this process to finish."

until su -c "fantasygold-cli startmasternode local false 2>/dev/null | grep 'successfully started' > /dev/null" $USER; do
  for (( i=0; i<${#CHARS}; i++ )); do
    sleep 5
    #echo -en "${CHARS:$i:1}" "\r"
    clear
    echo "Service Started. Your masternode is syncing. 
    When Current = Synced then select your MN in the local wallet and start it. 
    Script should auto finish here."
    echo "
    Current Block: "
    su -c "curl https://fantasygold.network/api/getblockcount" $USER
    echo "
    Synced Blocks: "
    su -c "fantasygold-cli getblockcount" $USER
  done
done

#echo "Your masternode is syncing. Please wait for this process to finish."
#echo "CTRL+C to exit the masternode sync once you see the MN ENABLED in your local wallet." && echo ""

#until su -c "fantasygold-cli startmasternode local false 2>/dev/null | grep 'successfully started' > /dev/null" $USER; do
#  for (( i=0; i<${#CHARS}; i++ )); do
#    sleep 2
#    echo -en "${CHARS:$i:1}" "\r"
#  done
#done

sleep 1
su -c "/usr/local/bin/fantasygold-cli startmasternode local false" $USER
sleep 1
clear
su -c "/usr/local/bin/fantasygold-cli masternode status" $USER
sleep 5

echo "" && echo "Masternode setup completed." && echo ""
