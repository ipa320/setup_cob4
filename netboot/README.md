# Image setup from network

## prerequisites
- will only work in apartment network (10.0.1.X), the to-be-installed-pc must be connected to apartment network
- image is hosted on apartment NAS 10.0.1.2


## update image
mount nfs on you local pc, e.g.
```
mkdir ~/pxe
sudo mount -t nfs 10.0.1.2:/volume1/pxe pxe
```
update image files from `setup_cob4/images_config`, e.g. copy ks-robot-master.cfg and ks-robot-slave.cfg to `~/pxe`


## install new pc with network image
- select network boot in bios
- select image to install (master/slave, with/without cache)
