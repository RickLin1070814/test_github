# WiFi_Driver
for WIFI dongle BL-WA1200 with RTL8892BU chipset

Only porting on ALi platform

BL-WA1200 product specification.pdf - Product Spec.

00013955-RTL88x2BU_WiFi_linux_v5.6.1.2_32629.20190321_COEX20180928-6a6a.zip - Reference Driver released

rtl88x2BU_WiFi_linux_v5.6.1.2_32629.20190321_COEX20180928-6a6a - Linux driver folder

==========================================================
To build and test, do the following:
(1)modify board/ali/c3505-demo/.config
#
# Network testing
#
CONFIG_WIRELESS=y
CONFIG_WEXT_CORE=y
CONFIG_WEXT_PROC=y

#
# USB Network Adapters
#
CONFIG_WLAN=y

#
# USB Device Class drivers
#
CONFIG_USB_WDM=y

(2)Rebuild kernel
rm -rf output/build/linux-PDK1.15.0-20181212A/
make all

(3)modify Makefile
a. rtl88x2BU_WiFi_linux_v5.6.1.2_32629.20190321_COEX20180928-6a6a/Makefile
e.g.:
ifeq ($(CONFIG_PLATFORM_I386_PC), y)
EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN
ARCH:=mips
CROSS_COMPILE:= /home/rick/share/1714_test2/ali_M3728_DDK6_9/buildroot-6.9.1.1/output/host/usr/bin/mipsel-linux-
KSRC:= ../output/build/linux-PDK1.15.0-20181212A
endif

b. wpa_supplicant_hostapd-0.8_rtw_r24647.20171025/wpa_supplicant/Makefile
e.g.:
CC=/home/rick/share/1714_test2/ali_M3728_DDK6_9/buildroot-6.9.1.1/output/host/usr/bin/mipsel-linux-gcc

(4)Compile and copy the wifi driver
#cd rtl88x2BU_WiFi_linux_v5.6.1.2_32629.20190321_COEX20180928-6a6a
#make
#cp 88x2bu.ko ../fs/
#cd ../wpa_supplicant_hostapd-0.8_rtw_r24647.20171025/wpa_supplicant
#make
#cp wpa_cli ../../output/target/bin/

(5)Copy files to FS
a. copy WiFi_Driver_RTL88x2BU/release/ALi_DDK_6_9/wpa_supplicant.conf to buildroot-6.9.1.1/output/target/etc/
b. copy WiFi_Driver_RTL88x2BU/release/ALi_DDK_6_9/common.cst.mk to buildroot-6.9.1.1/fs

(6)modify /output/target/etc/sysctl.conf
kernel.modules_disabled = 1 -> #kernel.modules_disabled = 1

(7)Rebuild kernel and images
#make all

(8)Test commands on STB
#cd /etc
#insmod 88x2bu.ko
#ifconfig wlan0 up
#wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
#wpa_cli -i wlan0 remove_network 0
#wpa_cli -i wlan0 add_network 0
#wpa_cli -i wlan0 set_network 0 ssid '"dtvtest"' (wifi ssid)
#wpa_cli -i wlan0 set_network 0 key_mgmt NONE
#wpa_cli -i wlan0 enable_network 0
#wpa_cli -i wlan0 select_network 0
#wpa_cli -i wlan0 status
#udhcpc -i wlan0
#ping 192.168.1.10 -w 5 
