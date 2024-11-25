FLYWAY_VERSION="10.21.0"
INSTALL_DIR="$HOME/flyway-$FLYWAY_VERSION" # Install directory in the user's home folder

if flyway --help ; then
  echo "Flyway Installed and Available"
else 
  echo "Flyway Not Installed - Downloading and Configuring Now"
  # Download and extract Flyway
  wget -qO- https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/$FLYWAY_VERSION/flyway-commandline-$FLYWAY_VERSION-linux-x64.tar.gz | tar -xvz

  # Move the Flyway folder to the install directory
  mv "flyway-$FLYWAY_VERSION" "$INSTALL_DIR"
  
  # Overwrite or create symbolic link to the Flyway executable
  sudo ln -sf "$INSTALL_DIR/flyway" /usr/local/bin/flyway

  echo "Flyway version $FLYWAY_VERSION installed and configured."
  echo "Flyway Downloaded - Setting PATH"
  export PATH="/usr/local/bin/flyway-$FLYWAY_VERSION/:$PATH"
  echo "Validation Step - Checking if Flyway can run"
  flyway --version
fi