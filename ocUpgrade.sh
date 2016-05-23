#!/bin/bash
function askYesNo {
  while true; do
    read -p "$1" yn
    case $yn in
        [YySs]* ) return 0; break;;
        [Nn]* ) return 1;;
        * ) echo "Please answer yes or no.";;
    esac
  done
}

function backupFolder {
  if [ -d "owncloud" ]; then
    if [ -d "owncloud.old" ]; then
      if [ -d "owncloud.old1" ]; then
        mv owncloud owncloud.old2
        BACKUPFOLD="owncloud.old2"
      else
        mv owncloud owncloud.old1
        BACKUPFOLD="owncloud.old1"
      fi
    else
      mv owncloud owncloud.old
      BACKUPFOLD="owncloud.old"
    fi
  fi
}

function doExit {
  unprotectData
  exit $1;
}

function protectData {
  DATA=`grep -F "datadirectory" config/config.php`
  CONFIGDIR=(${DATA//\'/ })
  DATADIR="${CONFIGDIR[2]}"
  chmod 000 $DATADIR
}

function unprotectData {
  chmod 770 $DATADIR
}

function checkDependencies {
  echo "Checking dependences..."
  if ! type "wget" > /dev/null; then
    apt-get install --yes wget
  fi
  if ! type "unzip" > /dev/null; then
    apt-get install --yes unzip
  fi
}

function Upgrade80 {
  echo 'Actualizando desde 8.0.x';
  checkDependencies
  protectData
  cd ..
  backupFolder
  wget "https://download.owncloud.org/community/owncloud-8.1.8.zip"
  if [ $? != '0' ]; then
    echo 'Error downloading!'
    doExit 1
  fi
  unzip owncloud-8.1.8.zip
  rm owncloud-8.1.8.zip
  cp $BACKUPFOLD/config/config.php owncloud/config/config.php
  chown www-data:www-data owncloud -R
  chmod +x owncloud/occ
  cd owncloud
  unprotectData
  sudo -u www-data ./occ upgrade
  cd ..
  doExit 0
}

function Upgrade81 {
  echo 'Actualizando desde 8.1.x';
  checkDependencies
  protectData
  cd ..
  backupFolder
  wget "https://download.owncloud.org/community/owncloud-8.2.5.zip"
  if [ $? != '0' ]; then
    echo 'Error downloading!'
    doExit 1
  fi
  unzip owncloud-8.2.5.zip
  rm owncloud-8.2.5.zip
  cp owncloud.old/config/config.php owncloud/config/config.php
  chown www-data:www-data owncloud -R
  chmod +x owncloud/occ
  cd owncloud
  unprotectData
  sudo -u www-data ./occ upgrade
  cd ..
  doExit 0
}

function Upgrade82 {
  echo 'Actualizando desde 8.2.x';
  checkDependencies
  protectData
  cd ..
  backupFolder
  wget "https://download.owncloud.org/community/owncloud-9.0.2.zip"
  if [ $? != '0' ]; then
    echo 'Error downloading!'
    doExit 1
  fi
  unzip owncloud-9.0.2.zip
  rm owncloud-9.0.2.zip
  cp owncloud.old/config/config.php owncloud/config/config.php
  chown www-data:www-data owncloud -R
  echo "La version >9.0.x es compatible con php7.0"
  chmod +x owncloud/occ
  cd owncloud
  unprotectData
  sudo -u www-data ./occ upgrade
  cd ..
  doExit 0
}

if [[ $UID != 0 ]]; then
    echo "Adquiriendo modo root:"
    sudo -i
fi
VERSION=`sed '3q;d' version.php`
VERSION=${VERSION:21:3}
if [ "$VERSION" == "8.0" ];
then
  echo 'Version 8.0.x detectada'
  askYesNo "Quieres actualizar?"
  if [ $? == '0' ]; then
    Upgrade80
  else
    doExit 0
  fi
elif [ "$VERSION" == "8.1" ]; then
  echo 'Version 8.1.x detectada'
  askYesNo "Quieres actualizar?"
  if [ $? == '0' ]; then
    Upgrade81
  else
    doExit 0
  fi
elif [ "$VERSION" == "8.2" ]; then
  echo 'Version 8.2.x detectada'
  askYesNo "Quieres actualizar?"
  if [ $? == '0' ]; then
    Upgrade82
  else
    doExit 0
  fi
elif [ "$VERSION" == "9.0" ]; then
  echo 'Version 9.0.x detectada'
  echo 'Enhorabuena, tienes la ultima versión soportada'
  doExit 0
else
  echo 'Version no reconocida'
  doExit 1
fi
