# Setup ddwrt on Linksys WRT 3200

### 1. Prepare Router <a id="Prepare"/>
- Connect Ethernetcable with PC and Router
- Connect Powercable with Router

### 2. Flash DDWRT <a id="Flash"/>
- Download ddwrt image for wrt3200: <br>
  http://download1.dd-wrt.com/dd-wrtv2/downloads/betas/2017/07-08-2017-r32597/linksys-wrt3200acm/factory-to-ddwrt.bin
- Open Browser and enter Adress 192.168.1.1. You should now see a LinkSys Smart Wifi Setup Screen.
- Accept Lizenz and click on manual Configuration.
image:doc/Flash1.png[Flash1]
  
- Now click on Anmelden and ether the default Passwort: admin
image:doc/Flash2.png[Flash2]

- You should now see the Linksys web admin page:
- Go to Konnektivität, click on Datei auswählen on the manual firmware update setting and select the in step 1 downloaded factory-to-ddwrt.bin
image:doc/Flash3.png[Flash3]
image:doc/Flash5.png[Flash5]

- Press start to start the flash progress <br>
  Accept the upcomming warings and restart the Router once the process is finished
 
### 3. Setup DDWRT <a id="DDWRT"/>
- After the Router restartet got to the Adress 192.168.1.1 by entering it in the Address Bar of you web browser
- Now enter a new username and password <br>
  user: admin
  password: root
- You should now see the ddwrt admin web page
image:doc/ddwrt1.png[ddwrt1]
- Download the ddwrt template config: <br>
  https://github.com/ipa320/setup_cob4/blob/master/ddwrt_backup/linksys_wrt3200_initial_config.bin?raw=true
- Go to Administration -> Backup <br>
  Select the downloaded file under Restore Settings
image:doc/ddwrt2.png[ddwrt1]

### 4. Customize DDWRT Settings <a id="Custom"/>
- 
