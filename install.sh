#!/bin/bash

if [ -f ~/.bashrc ]; then
	if [ "$(grep 'source ~/.bashrc-openwrt.sh' ~/.bashrc)" = "" ]; then
		echo "append bashrc-openwrt.sh to your bashrc"
		echo "source ~/.bashrc-openwrt.sh" >> ~/.bashrc
	fi

	echo "copy bashrc-openwrt.sh to ~/.bashrc-openwrt.sh"
	echo ""
	cp bashrc-openwrt.sh ~/.bashrc-openwrt.sh

	echo "openwrt-dev-tool has been installed."
	echo "Please login your account again to apply setting!!!"
else
	echo "Error: your bashrc is not exist !!!"
fi

