# "PCAN-USB Pro FD" update
1. read "requirements"
2. flash Bootloader
3. flash Firmware

More Information:   
http://www.peak-system.com/produktcd/Firmware/PCAN-USB%20Devices/USB-CAN-Interfaces_FirmwareUpdate_deu.pdf

## requirement
- Windows 7 on PC or in VM (Windows 8 or higher isn't supported)
- if VM: USB have to declare as USB 2.0
- http://www.peak-system.com/produktcd/
  - install driver for "PCAN-USB Pro FD"
  - download files for flashing

## Bootloader flash
1. start 'PcanFlash.exe'
2. open: 'Application --> Option'
3. choose from list 'Hardware Profile' your USB-CAN-Interface ('PCAN-USB Pro FD')
4. click '...' by 'File name'
5. choose 'PCAN-USB_Pro_FD__MSD_loader_upgrade.bin'
6. Click 'OK'
7. Click 'PCAN --> Connect'
8. Choose (500 kbit/s) and click 'OK'
9. Click 'PCAN --> Set USB to flash mode'
10. After a few seconds one or more LEDs are blinking on the USB-CAN-Interface in orange
11. Now the USB-CAN-Interface should be mounted es mass storage   
    if yes --> skip to chapter 'Firmware flash'
    if not --> Read http://www.peak-system.com/produktcd/Firmware/PCAN-USB%20Devices/USB-CAN-Interfaces_FirmwareUpdate_deu.pdf

## Firmware flash
The USB-CAM-Interface is detected as mass storage in the windows explorer. Otherwise follow chapter 'Bootloader flash'
1. Open the mass storage on the USB-CAM-Interface
2. Delete 'firmware.bin'
3. Copy the new firmware on the device. Don't rename the new file.
4. Wait a few seconds after copying, then disconnect the interface.
5. After a few seconds connect the interface again. Now the interface should be detect as a 'USB-CAN-Interface' again.
