# BIOS Update for NUC
(Instructions taken from https://www.intel.com/content/www/us/en/support/articles/000033291/intel-nuc.html)

- Download the *.cap file for the Intel BIOS version (see table below) from https://downloadcenter.intel.com/search?keyword=bios+aptio (choose filter as shown below).

<img src="docs/intel_nuc_download_center.png" width="700">

- Place it at the root folder of an usb stick.

- Plug the usb stick into the NUC and startup the NUC. Press F7 to enter the BIOS updater.

- Select the usb stick in the menu and select the *.cap file.

- Wait for the setup to finish.

## Shipped BIOS Versions of NUC Generations

| NUC Generation    | BIOS Version |
| --------------    | ------------ |
| 11                | TNTGLV57.0056.2021.0513 |
| 10                | FNCML357.0053.2021.0904 |
| 7                 | BNKBL357 |


# BIOS settings for NUC 11 and 10

Startup PC and Press (and hold) **F2** to enter BIOS (press **F10** to enter Boot Menu)

## Main
<img src="docs/NUC_11_1_boot.jpg" width="700">

## Advanced 
Click on `Onboard Devices`

<img src="docs/NUC_11_2_bios_advanced.jpg" width="700">

<img src="docs/NUC_11_2_bios_advanced_1.jpg" width="350"><img src="docs/NUC_11_2_bios_advanced_2.jpg" width="350">

- disable `Onboard Devices` except `LAN` as shown in the pictures

## Cooling 
- select `Cool`

<img src="docs/NUC_11_3_bios_cooling.jpg" width="700">


## Performance 
- **for NUC 11**: nothing to be done
- **for NUC 10**: go to `PROCESSOR` and disable `Intel Turbo Boost Technology`

<img src="docs/NUC_11_4_bios_performance.jpg" width="700">

## Security 
- nothing to be done

<img src="docs/NUC_11_5_bios_security.jpg" width="700">

## Power 
- modify `Secondary Power Settings` as shown

<img src="docs/NUC_11_6_bios_power.jpg" width="700">

<img src="docs/NUC_11_6_bios_power_1.jpg" width="350"><img src="docs/NUC_11_6_bios_power_2.jpg" width="350">

## Boot 
<img src="docs/NUC_11_7_bios_boot.jpg" width="700">

- click on `Boot Priority`
- modify boot priority check boxes according to the images below

<img src="docs/NUC_11_7_bios_boot_1.jpg" width="350"><img src="docs/NUC_11_7_bios_boot_2.jpg" width="350"><img src="docs/NUC_11_7_bios_boot_3.jpg" width="350">

Finally, `Save and Exit` in the upper right corner

# BIOS settings for NUC 7 (old NUC Gen)

Startup PC and Press **F2** to enter BIOS (press **F10** to enter Boot Menu)

<img src="docs/boot.jpg" width="700">

Click on `Advanced`

<img src="docs/bios.jpg" width="700">

## Main
- nothing to be done

<img src="docs/main.jpg" width="700">

## Devices 
- disable `Onboard Devices` except `LAN` (keep `WLAN` for head when using new router only!) 
- disable `Enhanced Consumer IR` and `HDMI CEC Control` in `Legacy Device Config`

<img src="docs/devices.jpg" width="700">

## Cooling 
- select `Cool`

<img src="docs/cooling.jpg" width="700">

## Performance 
- nothing to be done

<img src="docs/performance.jpg" width="700">

## Security 
- nothing to be done

<img src="docs/security.jpg" width="700">

## Power 
- modify `Secondary Power Settings` as shown

<img src="docs/power.jpg" width="700">

## Boot 
- nothing to be done

Finally `Save and Exit` by pressing **F10**
