#!/usr/bin/env bash

set -e

ROOT=$(realpath $(dirname $0))
DOWNLOADS=$ROOT/.downloads

# JAVA
JAVA_URL="https://cdn.azul.com/zulu/bin/zulu8.74.0.17-ca-jdk8.0.392-macosx_aarch64.tar.gz"
JAVA_HOME=$ROOT/lib/jdk8
JDK_DL_TGZ="openjdk-8.tar.gz"
# BUNDLETOOL
BTOOL_URL="https://github.com/google/bundletool/releases/download/1.15.6/bundletool-all-1.15.6.jar"
BTOOL_HOME=$ROOT/lib
# NODE
NODE_PACKAGES="mjpeg-consumer appium"

# Android (requires Android SDK/Studio)
#APPIUM_DRIVERS="uiautomator2"
# Android & iOS (requires Xcode; remember to install the platform-specific simulator sources as well)
APPIUM_DRIVERS="uiautomator2 xcuitest"


main() {
  install_java
  install_bundletool
  install_node_modules
  install_appium_drivers
  print_info
  exit 0
}

function install_java {
  echo_headline "Installing Java 8"
  mkdir -p ${DOWNLOADS}
  if [ ! -f ${DOWNLOADS}/${JDK_DL_TGZ} ]; then
    echo "Downloading Java 8 tgz file from ${JAVA_URL}..."
    curl -L -o ${DOWNLOADS}/${JDK_DL_TGZ} ${JAVA_URL}
  else
    echo "Java 8 tgz file already downloaded. Skipping download."
  fi
  mkdir -p ${JAVA_HOME}
  tar -xzf ${DOWNLOADS}/${JDK_DL_TGZ} -C ${JAVA_HOME} --strip-components=1
  
  if [ -x "$(which java)" ]; then
    echo -e "OK: \033[32mJava 8 installed successfully.\033[0m"
  else
    echo -e "❌ \033[31mJava 8 installation failed.\033[0m"
    exit 1
  fi
}

function install_bundletool {
  echo_headline "Installing Bundletool"
  if [ ! -f ${DOWNLOADS}/bundletool.jar ]; then
    echo "Downloading Bundletool.jar file from ${BTOOL_URL}..."
    curl -L -o ${DOWNLOADS}/bundletool.jar ${BTOOL_URL}
  else
    echo "Bundletool jar already downloaded. Skipping download."
  fi
  mkdir -p ${BTOOL_HOME}
  cp ${DOWNLOADS}/bundletool.jar $BTOOL_HOME/
  chmod ug+x "$BTOOL_HOME/bundletool.jar"
  #source $ROOT/.env.sh
  if [ -x "$(which bundletool.jar)" ]; then
    echo -e "OK: \033[32mBundletool installed successfully.\033[0m"
  else
    echo -e "❌ \033[31mBundletool installation failed.\033[0m"
    exit 1
  fi
}

function install_node_modules {
  echo_headline "Installing Node modules"
  for package in $NODE_PACKAGES; do
    # check with npm if package is already installed
    if [ "$(npm list -g $package | grep $package)" ]; then
      echo "npm package $package is already installed. Skipping."
      continue
    else
      echo "📦 Installing $package..."
      npm install -g $package
    fi
  done
}

function install_appium_drivers {
  echo_headline "Installing Appium drivers"
  for driver in $APPIUM_DRIVERS; do
    if [ "$(appium driver list 2>&1 | grep $driver)" ]; then
      echo "Appium driver $driver is already installed."
    else
      echo "📦 Installing $driver..."
      appium driver install $driver 2>&1 >/dev/null || true
    fi
    if [ "$(appium_doctor $driver 2>&1 | grep ERR)" ]; then
      echo "❌ $driver doctor test failed:"
      appium_doctor $driver
      exit 1
    else
      echo "OK: Appium driver doctor test passed."
    fi
  done
}

function appium_doctor {
  appium driver doctor $1
}

function print_info {
  echo_headline "INSTALLATION REPORT"
  #source $ROOT/.env.sh
  echo_white "\033[37m🟢 Installation complete.\033[0m\n"
  echo_white "\033[37mPython executable: \033[0m"
  echo_green "\033[32m$PYTHON_EXE\033[0m"
  echo_white "   <-- use this as Python interpreter in VS Code\n"
  echo_white "Python version: $($PYTHON_EXE --version)\n"
  echo_white "\033[37mJava executable: \033[0m"
  echo_green "\033[32m$JAVA_HOME/bin/java\033[0m\n"
  echo_white "Java version: $($JAVA_HOME/bin/java -version 2>&1 | head -n 1)\n"

  echo_dir "Android SDK cmdline tools" "$ANDROID_HOME/cmdline-tools/latest/bin"
  echo_dir "Android SDK emulator" "$ANDROID_HOME/emulator"
  echo_dir "Android SDK platform-tools" "$ANDROID_HOME/platform-tools"
  echo ""
  echo ""

}

function echo_red {
  echo -n -e "\033[31m$1\033[0m"
}
function echo_green {
  echo -n -e "\033[32m$1\033[0m"
}
function echo_white {
  echo -n -e "\033[37m$1\033[0m"
}

function echo_yellow {
  echo -n -e "\033[33m$1\033[0m"
}

function echo_headline {
  echo -n -e "\033[1m=== $1 ===\033[0m\n"
}

function echo_var {
  if [ -z ${!1} ]; then
    echo_red "❌ $1 is not set. Exiting.\n"
    exit 1
  else
    echo_white "Variable "
    echo_yellow "$1 = ${!1}\n"
  fi
}

function echo_dir {
  DIRNAME=$1
  DIR=$2
  if [ -d $DIR ]; then
    echo_white "$DIRNAME dir: "
    echo_yellow "$DIR\n"
  else
    echo_red "❌ $DIRNAME is not set. Exiting.\n"
    exit 1
  fi
}

main
