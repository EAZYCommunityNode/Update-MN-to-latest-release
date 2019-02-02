#!/bin/bash

CONFIG_FILE='ezy.conf'
CONFIGFOLDER='/root/.ezy'
COIN_DAEMON='/usr/local/bin/ezyd'
COIN_CLI='/usr/local/bin/ezy-cli'
COIN_REPO='https://github.com/EAZYCommunityNode/eazynode/releases/download/v2.2.1/ezy-v2.2.1-linux.tar.gz'
COIN_NAME='ezy'
COIN_PORT=52320

NODEIP=$(curl -s4 icanhazip.com)

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

progressfilt () {
  local flag=false c count cr=$'\r' nl=$'\n'
  while IFS='' read -d '' -rn 1 c
  do
    if $flag
    then
      printf '%c' "$c"
    else
      if [[ $c != $cr && $c != $nl ]]
      then
        count=0
      else
        ((count++))
        if ((count > 1))
        then
          flag=true
        fi
      fi
    fi
  done
}


function systemd_stop() {
  echo -e "Stopping your $COIN_NAME Masternode"
  systemctl stop $COIN_NAME.service >/dev/null 2>&1
}
function systemd_start() {
  clear
  echo -e "Starting the $COIN_NAME Masternode"
  systemctl start $COIN_NAME.service >/dev/null 2>&1
}

function configure_stop() {
  clear
  echo -e "Stopping your $COIN_NAME Masternode"
  /etc/init.d/$COIN_NAME stop >/dev/null 2>&1
}
function configure_start() {
  clear
  echo -e "Starting the $COIN_NAME Masternode"
  /etc/init.d/$COIN_NAME start >/dev/null 2>&1
}

function compile_node() {
  echo -e "Prepare to download the new version of $COIN_NAME Masternode"
  rm -f /usr/local/bin/ezyd >/dev/null 2>&1
  rm -f /usr/local/bin/ezy-cli >/dev/null 2>&1
  TMP_FOLDER=$(mktemp -d)
  cd $TMP_FOLDER
  wget --progress=bar:force $COIN_REPO 2>&1 | progressfilt
  compile_error
  COIN_ZIP=$(echo $COIN_REPO | awk -F'/' '{print $NF}')
  tar xvzf $COIN_ZIP >/dev/null 2>&1

  rm -f $COIN_ZIP >/dev/null 2>&1
  cp ezy* /usr/local/bin
  strip $COIN_DAEMON $COIN_CLI
  cd -
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}

function checks() {
 detect_ubuntu 
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME found, will update now.${NC}"
fi
}

function detect_ubuntu() {
 if [[ $(lsb_release -d) == *18.04* ]]; then
   UBUNTU_VERSION=18
 elif [[ $(lsb_release -d) == *16.04* ]]; then
   UBUNTU_VERSION=16
 elif [[ $(lsb_release -d) == *14.04* ]]; then
   UBUNTU_VERSION=14
else
   echo -e "${RED}You are not running Ubuntu 14.04, 16.04 or 18.04 Installation is cancelled.${NC}"
   exit 1
fi
}

function important_information() {
 echo
 echo -e "================================================================================"
 echo -e "$COIN_NAME Masternode is updated and running listening on port ${RED}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 if (( $UBUNTU_VERSION == 16 || $UBUNTU_VERSION == 18 )); then
   echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
   echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
   echo -e "Status: ${RED}systemctl status $COIN_NAME.service${NC}"
 else
   echo -e "Start: ${RED}/etc/init.d/$COIN_NAME start${NC}"
   echo -e "Stop: ${RED}/etc/init.d/$COIN_NAME stop${NC}"
   echo -e "Status: ${RED}/etc/init.d/$COIN_NAME status${NC}"
 fi
 echo -e "Check if $COIN_NAME is running by using the following command:\n${RED}ps -ef | grep $COIN_DAEMON | grep -v grep${NC}"
 echo -e "================================================================================"
}

function stop_node() {
  
  if (( $UBUNTU_VERSION == 16 || $UBUNTU_VERSION == 18 )); then
    systemd_stop
  else
    configure_stop
  fi  
  clear
    
}
function start_node() {
  
  if (( $UBUNTU_VERSION == 16 || $UBUNTU_VERSION == 18 )); then
    systemd_start
  else
    configure_start
  fi  
  clear
    
}

##### Main #####
clear

checks
stop_node
compile_node
start_node
important_information
