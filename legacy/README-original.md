These two scripts allow for you to install docker, portainer, wireguard (https://github.com/wg-easy/wg-easy), and pi hole without needing to go get all the individual files and guides. 

These scripts require very little adjustments to get them going.

1. Go into the location where the two files are located and make them executable. The chmod +x 'password generator.txt' and chmod +x 'install portainer script.txt' commands should do the trick. 
2. Run the password generator.txt script first. It will install docker and generate the password hash for the other script. It will save at the end of the install portainer script.txt file.
3. Use your favorite editor to go into the install portainer script.txt file.
4. Copy the generated password hash and paste it next to the line where it says PASSWORD_HASH=. It must have the ' at the beginning and end of the password hash for this work properly.
5. Insert your Public IP address where it says WG_HOST=. There are many ways to check for your Public IP address.
6. Erase the PASSWORD_HASH= at the end of the file. The curl -sSL https://install.pi-hole.net | bash should be the last thing in that file.
7. Save the configurations and exit.
8. Run the script and follow any prompts that come up.

If done correctly, all 4 services should be installed and ready to go. 

Note: please make sure appropiate ports are opened from your router. You will need to open 51280 for wireguard. 

Wireguard UI should be accessible from http://your_ip:51821.

Pi-Hole UI should be accessible from http://your_ip/admin.

Portainer UI should be accessible from https://your_ip:9443.
