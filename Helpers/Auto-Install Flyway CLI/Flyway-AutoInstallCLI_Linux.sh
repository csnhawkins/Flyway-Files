FLYWAY_VERSION="10.19.0"

if flyway --help ; then
  echo "Flyway Installed and Available"
else 
  echo "Flyway Not Installed - Downloading and Configuring Now"
  wget -qO- https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/$FLYWAY_VERSION/flyway-commandline-$FLYWAY_VERSION-linux-x64.tar.gz | tar -xvz && sudo ln -s `pwd`/flyway-$FLYWAY_VERSION/flyway /usr/local/bin 
  echo "Flyway Downloaded - Setting PATH"
  export PATH="/usr/local/bin/flyway-$FLYWAY_VERSION/:$PATH"
  echo "Validation Step - Checking if Flyway can run"
  flyway --version
fi