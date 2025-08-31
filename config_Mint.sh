#!/usr/bin/env bash 
# TRYING: bash ~/Desktop/onboard_Mint.sh 2>&1 | tee ~/Desktop/onboard_Mint_log.txt

# Should I run onboard_Mint.sh using sudo? Currently the script prompts for password part way in. Would be nice to kick off script and walk away.

# Disclaimer: I am not a coder/scripter, but can sometimes understand enough to modify other people's code. Please use only on a Test computer. Do not run on production computer.

# Goal: This script will test hardware and configure a donated computer after it has a fresh Linux Mint Cinnamon install. 
# Common applications are installed: Chrome web browser and Zoom video conferencing.
# For user ease: desktop shortcuts to Firefox, Chrome, LibreOffice, and Zoom.
# Test and document hardware: camera, microphone, wifi 2.4 GHz and 5 GHz, battery health, etc. For example, if someone is going to use Zoom, they will need a computer with working microphone and webcam.

# Change from 24-hour clock to 12-hour. True/False, just double quotes.
dconf write /org/cinnamon/desktop/interface/clock-use-24h "false"

# Change Start of Week from Sunday 7 to Monday 1. Just double quotes.
dconf write /org/cinnamon/desktop/interface/first-date-of-week "1"

# Change power settings. Double and single quotes.
dconf write /org/cinnamon/settings-daemon/plugins/power/lid-close-ac-action "'nothing'"
dconf write /org/cinnamon/settings-daemon/plugins/power/lid-close-battery-action "'nothing'"

# Change Xed Text Editor from default font size to Monospace 21 pt.
dconf write /org/x/editor/preferences/editor/editor-font "'monospace 21'"
dconf write /org/x/editor/preferences/editor/use-default-font "false"
logger -t Cinn-dconf "Cinnamon dconf changes done"
echo "Cinnamon dconf changes done. Press any key to continue..."
read -n 1 -s

# Create a folder to save documentation about computer.
mkdir ~/Desktop/$(hostname)

# Make a backup copy of Software Sources.
sudo cp /etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list.d/official-package-repositories.list.bak

# Change to California Software Sources. Since URLs are being replaced, using comma instead of slash as delimiter.
sudo sed -i 's,http://packages.linuxmint.com,https://mirror.fcix.net/linuxmint-packages,g' /etc/apt/sources.list.d/official-package-repositories.list

sudo sed -i 's,http://archive.ubuntu.com/ubuntu,http://mirror.math.ucdavis.edu/ubuntu,g' /etc/apt/sources.list.d/official-package-repositories.list


function 2wifi {
# Connect to 2.4 GHz Guest wireless. https://thelinuxcode.com/3-ways-to-connect-to-wifi-from-the-command-line-on-debian/
nmcli device wifi connect WIFI-guest password "WIFI-password"

# Make sure MAC address is on WIFI-guest Allow List.

echo "Connected to wifi? Press y to continue"

while true; do
read -r -s -n 1 choice

case "$choice" in
 y|Y ) echo "yes"
ping 8.8.8.8 -c 1

 return 1
;;

 * ) echo "Okay, you could not press a key next time, and press y when ready.";;
esac

done
}

2wifi
logger -t log-wifi "Wifi 2GHz done"
echo "Function 2wifi done. Press any key to continue..."
read -n 1 -s

function ping_internet {
#  Was ping successful? 

echo "Let's test the internet connection."
while true; do
    ping -c 1 8.8.8.8 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Ping successful!"
        break
    else
while true; do
        read -p "Ping failed. Type 'y' to continue: " user_input
        if [[ "$user_input" == "y" ]]; then
            echo "Continuing..."
            break
        else
            echo "You did not type 'y'. Please type 'y' to continue."
        fi
    done
    fi
done
}

ping_internet
logger -t log-ping "Ping internet done"
echo "Function ping_internet done. Press any key to continue..."
read -n 1 -s

# Before installing or updating any packages, it is important to update the package index. The package index contains information about the available packages in the repositories. https://linuxvox.com/blog/linux-mint-package-manager/. https://linuxize.com/post/how-to-use-apt-command/. 
# I had to duplicate the apt commands a few times. Mint seems to want mint-upgrade-info and mintupdate, updated first, and then can proceed normally.
# Mint also got upset and wanted me to run: sudo dpkg --configure -a

sudo apt update
# TODO: Not prompt for password. Maybe run script as sudo?
logger -t log-apt-update "apt update done."
echo "sudo apt update done. Press any key to continue..."
read -n 1 -s

sudo dpkg --configure -a
logger -t log-dpkg-config "dpkg --configure -a done."
echo "sudo dpkg --configure -a done. Press any key to continue..."
read -n 1 -s

sudo apt install mint-upgrade-info
sudo apt install mintupdate
logger -t log-mint-upgrade "mint-upgrade done"
echo "sudo apt install mint-upgrade-info and mintupdate done. Press any key to continue..."
read -n 1 -s


# Before installing or updating any packages, it is important to update the package index. The package index contains information about the available packages in the repositories. https://linuxvox.com/blog/linux-mint-package-manager/. https://linuxize.com/post/how-to-use-apt-command/
sudo apt update
echo "sudo apt update done. Press any key to continue..."
read -n 1 -s


# Update installed packages.
sudo apt upgrade
echo "sudo apt upgrade done. Press any key to continue..."
read -n 1 -s

sudo apt install fonts-crosextra-carlito fonts-crosextra-caladea

# Copy Aptos font folder from USB to computer's Downloads folder.
# Info https://easylinuxtipsproject.blogspot.com/p/libre-office.html#ID6.3
cp /media/user/SilverPur_1/Aptos ~/Downloads -r

# Create folder for Aptos fonts, move fonts over, tell system about new fonts.
sudo mkdir -p -v /usr/local/share/fonts/truetype/aptos-fonts
sudo mv -v ~/Downloads/Aptos/Apto*.ttf /usr/local/share/fonts/truetype/aptos-fonts
sudo fc-cache -fv

# Verify Aptos folder is empty, and if it is, delete the Aptos folder.
function delete_Aptos {
     if [ -d "$HOME/Downloads/Aptos" ]; then
        if [ -z "$(ls -A "$HOME/Downloads/Aptos")" ]; then
            rm -rf "$HOME/Downloads/Aptos"
            echo "The Aptos folder was empty and has been deleted."
        else
            echo "The Aptos folder is not empty."
        fi
    else
        echo "The Aptos folder does not exist."
    fi
return
}
delete_Aptos

# TESTING: LibreOffice Font Replacement table. https://easylinuxtipsproject.blogspot.com/p/libre-office.html#ID6.2
# LibreOffice must be opened at least once.
logger -t open_close_libre "Open and close LibreOffice."
libreoffice &
# Give LibreOffice time to open, remember older computers, first launch of LibreOffice.
sleep 5s

# Function to identify and close LibreOffice processes
function close_libreoffice {
    # Identify LibreOffice processes
    processes=$(pgrep -f libreoffice)

    # Check if any LibreOffice processes are found
    if [ -z "$processes" ]; then
        echo "No LibreOffice processes are running."
    else
        echo "Found the following LibreOffice processes:"
        echo "$processes"

        # Close LibreOffice processes
        echo "Closing LibreOffice processes..."
        kill $processes

        # Check if the kill command was successful
        if [ $? -eq 0 ]; then
            echo "LibreOffice has been closed."
        else
            echo "Failed to close LibreOffice processes."
        fi
    fi
}
close_libreoffice

logger -t libre_fonts "libre font replacement table started"
# TESTING: 
function libre_replace_fonts {
# Define the replacement table file path
REPLACEMENT_FILE="$HOME/.config/libreoffice/4/user/registrymodifications.xcu"

# Check if the replacement file exists
if [ ! -f "$REPLACEMENT_FILE" ]; then
    echo "Replacement table file not found. Please ensure LibreOffice is installed and has been run at least once."
    exit 1
fi

# Backup the original file
cp "$REPLACEMENT_FILE" "$REPLACEMENT_FILE.bak"

# Add the replacement for Calibri to Carlito
sed -i '/<item.*name="FontSubstitution"/,/<\/item>/ s|<string>Calibri</string>|<string>Calibri</string>\n    <string>Carlito</string>|' "$REPLACEMENT_FILE"

# Notify the user
echo "Replacement for Calibri with Carlito has been added to the LibreOffice replacement table."
}


# Install packages in Mint's repository (GUI window is titled Software Manager).
sudo apt install -y fswebcam hw-probe

# Download Zoom. Install Zoom. https://linuxize.com/post/wget-command-examples/
wget -P /home/user/Downloads/ https://zoom.us/client/6.5.7.3298/zoom_amd64.deb
sudo apt install -y /home/user/Downloads/zoom_amd64.deb
logger -t log-zoom-app "Zoom done."
echo "Zoom done. Press any key to continue..."
read -n 1 -s

# Download and Import Google’s Signed Key.https://linuxiac.com/how-to-install-google-chrome-on-linux-mint/
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub > linux_signing_key.pub
sudo install -D -o root -g root -m 644 linux_signing_key.pub /etc/apt/keyrings/linux_signing_key.pub

# Add the official Google Chrome repository.
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/linux_signing_key.pub] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'

# Before installing Chrome, update the packages list.
sudo apt update

sudo apt install google-chrome-stable
logger -t log-chrome-app "Chrome done."
echo "Chrome done. Press any key to continue..."
read -n 1 -s

# Update installed packages.
sudo apt update
sudo apt upgrade
echo "sudo apt upgrade done. Press any key to continue..."
read -n 1 -s

# Create desktop shortcuts for Firefox, Chrome, Zoom, and LibreOffice.
function desktop_icons {
DESKTOP_DIR="$HOME/Desktop"

cat <<EOL > "$DESKTOP_DIR/firefox.desktop"
[Desktop Entry]
Version=1.0
Name=Firefox
Comment=Browse the web
Exec=firefox
Icon=firefox
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOL

cat <<EOL > "$DESKTOP_DIR/google-chrome.desktop"
[Desktop Entry]
Version=1.0
Name=Google Chrome
Comment=Browse the web
Exec=google-chrome-stable
Icon=google-chrome
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOL

cat <<EOL > "$DESKTOP_DIR/libreoffice.desktop"
[Desktop Entry]
Version=1.0
Name=LibreOffice
Comment=OpenOffice Suite
Exec=libreoffice
Icon=libreoffice
Terminal=false
Type=Application
Categories=Office;WordProcessor;Spreadsheet;Presentation;
EOL

# Create a desktop shortcut for Zoom
cat <<EOL > "$DESKTOP_DIR/zoom.desktop"
[Desktop Entry]
Version=1.0
Name=Zoom
Comment=Video conferencing
Exec=zoom
Icon=Zoom
Terminal=false
Type=Application
Categories=Network;Video;
EOL

# Make the shortcuts executable
chmod +x "$DESKTOP_DIR/firefox.desktop"
chmod +x "$DESKTOP_DIR/google-chrome.desktop"
chmod +x "$DESKTOP_DIR/libreoffice.desktop"
chmod +x "$DESKTOP_DIR/zoom.desktop"

return
}
desktop_icons


# Test camera. 
fswebcam -r 640x480 --jpeg 100 -D 3 -S 13 fswebcam.jpg
xdg-open ~/fswebcam.jpg
logger -t log-camera "Camera test done."
echo "fswebcam.jpg done. Press any key to continue..."
read -n 1 -s
rm ~/fswebcam.jpg

function test_mic {
echo "Ready to test microphone? Press y to continue and speak."

while true; do
read -r -s -n 1 choice

case "$choice" in
 y|Y ) echo "Please speak to test microphone."
echo
arecord --duration=5 test.wav
echo
aplay test.wav
rm test.wav
echo
echo Deleted test.wav.
 return 1
;;

 * ) echo "Okay, you could not press a key next time, and press y when ready.";;
esac

done
}

test_mic
logger -t log-mic "Microphone test done."
echo "Function test_mic done. Press any key to continue..."
read -n 1 -s

# Collect hardware for documentation.
sudo inxi -FZxd > /media/user/SilverPur_1/$(hostname)_inxi.txt

# Collect additional hardware info for documentation, share to https://linux-hardware.org, and capture custom URL that hw-probe outputs. 
# Run hw-probe and capture the output
HWPROBE_OUTPUT=$(sudo -E hw-probe -all -upload)

# Extract the probe URL using grep and awk
HWPROBE_URL=$(echo "$HWPROBE_OUTPUT" | grep "Probe URL:" | awk '{print $NF}')

# Create the filename
FILENAME="$(hostname)_hwprobe_url.txt"

# Save the URL to the file
echo "$HWPROBE_URL" > "$FILENAME"
echo "hw-probe URL saved to $FILENAME"


# TESTING: Change Terminal font size to Monospace 20 pt. 
# Used dconf dump to determine font is saved in a file with the filname starting with a colon and followed by a random GUID, e.g. /org/gnome/terminal/legacy/profiles:/:[GUID?]. I only know how to interact with static file names, not variable. 
# Hooray, it's called a GNOME terminal profile https://www.baeldung.com/linux/gnome-terminal-profile-export. 
dconf load /org/gnome/terminal/legacy/profiles:/:616aa865-4ac8-4681-9858-79a87effbfe0/ < /media/user/SilverPur_1/Mint/gnomeProfile.dconf

# Install fonts for compatability with Microsoft documents. Other users have reported known problems accepting EULA.
wget http://ftp.us.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.8.1_all.deb -P ~/Downloads
sudo apt-get install --no-install-recommends ~/Downloads/ttf-mscorefonts-installer_3.8.1_all.deb
sudo cp -v -r /usr/share/fonts/truetype/msttcorefonts /usr/local/share/fonts/msttcorefonts2
sudo apt-get purge ttf-mscorefonts-installer
sudo dpkg-reconfigure fontconfig

logger -t log-ttf "ttf-mscorefonts-installer done."
echo "ttf-mscorefonts-installer done. Press any key to continue..."
read -n 1 -s

# Disable auto-arrange desktop icons. Requires restart.
# TODO: Figure out how to handle restart; may need to move to end of script. 
sed -i 's/nemo-icon-view-auto-layout=true/nemo-icon-view-auto-layout=false/g' ./.config/nemo/desktop-metadata
