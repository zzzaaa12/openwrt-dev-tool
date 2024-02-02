#alias maket='echo "make rootfs_only"; make rootfs_only'
#alias makev='echo "make bahamas platform=Comtrend CONFIG_CT_CUSCODE=TLN"; make bahamas platform=Comtrend CONFIG_CT_CUSCODE=TLN'
alias mtkmake='make V=s MSDK=1'
alias makem='make menuconfig'
#alias makeu='echo "make user_only"; make user_only'

alias make_lg='make_tn'

function make_tn {
    cmd="make bahamas platform=Comtrend CONFIG_CT_CUSCODE=TLN"
    echo "$cmd" && eval $cmd
}

function make_zg {
    cmd="make bahamas platform=Comtrend CONFIG_CT_CUSCODE=UPN"
    echo "$cmd" && eval $cmd
}

function makeu {
    cmd="make user_only"
    echo "$cmd" && eval $cmd
}

# error messages
cannot_find_top="error: Cannot find OpenWrt TopDir"
cannot_find_prj="error: Cannot find project folder"
cannot_find_rootfs="error: Cannot find rootfs folder"
no_pkg_name="no package!!!"
nothing_to_makr="error: nothing to make"
here_not_opnewrt_root="error: here is NOT OpenWrt TopDir!!!"
here_is_openwrt_root="error: here is OpenWrt TopDir!!!"
finding="Finding, please wait it..."

# colorful echo
COLOR_END='\e[0m'
GREEN='\e[1;32m';
RED='\e[1;31m';
YELLOW='\e[1;33m';


function echo_green() {
	echo -e ${GREEN}$@${COLOR_END}
}


function echo_error() {
	echo -e ${RED}$@${COLOR_END}
}


function echo_info() {
	echo -e ${GREEN}$@${COLOR_END}
}


function goto_target() {
	echo "last_path: $(pwd -P)" && \
	cd $target_path && \
	echo_info "change to: $target_path"
	echo ""
}

# make package/xxx/prepare V=s
function makep() {
	if [ "$(is_sdk_top)" = "no" -o "$1" = "" ]; then
		echo_error $nothing_to_make
		return
	fi
	make package/$1/prepare V=s
}

# make package/xxx/prepare V=s
function makec() {
	if [ "$(is_sdk_top)" = "no" -o "$1" = "" ]; then
		echo_error $nothing_to_make
		return
	fi
	make package/$1/compile V=s
}

# make package/xxx/install V=s
function makei() {
	if [ "$(is_sdk_top)" = "no" -o "$1" = "" ]; then
		echo_error $nothing_to_make
		return
	fi
	make package/$1/install V=s
}

# make package/xxx/clean V=s
function make_clean() {
	if [ "$(is_sdk_top)" = "no" -o "$1" = "" ]; then
		echo_error $nothing_to_make
		return
	fi
	make package/$1/clean V=s
}

# make target/linux/{clean,compile}
function make_kernel() {
	make target/linux/{clean,compile} V=s
}

function is_sdk_top() {
        check_openwrt="$(ls feeds.conf.default 2>/dev/null)"
	celeno1="$(ls vendors 2>/dev/null)"
	celeno2="$(ls user 2>/dev/null)"
        realtek="$(ls users 2>/dev/null)"
	if [ "$check_openwrt" != "" ] || [ "$celeno1" != "" -a "$celeno2" != "" ] || [ "$realtek" != "" ]; then
		echo "yes"
	else
		echo "no"
	fi
}

function find_sdk_top() {
	last_path="$(pwd -P)"
	current="${PWD##*/}"
	cd_path=""
	hide="$1"

	if [ "$(is_sdk_top)" = "yes" -a "$hide" != "1" ]; then
		echo "./"
		return
	fi

	ls_path="$last_path/"
	level="$(pwd -P | sed 's/^\///g' | tr '\n' '\0' | tr '/' '\n'  | wc -l)"
	for i in $(seq 1 $level)
	do
		ls_path="$ls_path../"
                check_openwrt="$(ls $ls_path/feeds.conf.default 2>/dev/null)"
		check1="$(ls $ls_path/user 2>/dev/null)"
		check2="$(ls $ls_path/vendors 2>/dev/null)"
		realtek="$(ls $ls_path/users 2>/dev/null)"
		if [ "$check_openwrt" != "" ] || [ "$check1" != "" -a "$check2" != "" ] || [ "$realtek" != "" ]; then
			echo "$ls_path"
			return
		fi
	done
	return
}


# cd to OpenWRT TopDir
function cdtop() {
	target_path="$(find_sdk_top)"
	if [ "$target_path" != "" -a "$target_path" != "./" ]; then
		goto_target
	fi
}


# cd to package folder
function cdpkg() {

	if [ "$1" = "" ]; then
		return 1
	fi

	pkg_path=""
	top_path="$(find_sdk_top)"
	if [ "$top_path" == "" ]; then
		return 1
	fi

	echo_green $finding $1
	echo ""

	if [ -e $top_path/user ]; then
		pkg_path=$(find ${top_path}/user -type d -name $1)
	elif [ -e $top_path/users ]; then
		pkg_path=$(find ${top_path}/users -type d -name $1)
	fi

	if [ "$pkg_path" = "" ]; then
		echo_red "$cannot_find_pkg"
		return 1
	fi

	target_path=$(pwd)/$pkg_path
	goto_target
}

function cdroot() {
	if [ "$(is_sdk_top)" = "no" ]; then
		echo "Here is not OpenWRT topdir"
		return
	fi
	o_target=$(grep CONFIG_TARGET_ARCH_PACKAGES= .config | sed 's/"//g' | sed 's/^CONFIG_TARGET_ARCH_PACKAGES=//g')
	o_libc=$(grep CONFIG_LIBC= .config | sed 's/"//g'| sed 's/^CONFIG_LIBC=//g')
	o_board=$(grep CONFIG_TARGET_BOARD= .config | sed 's/"//g' | sed 's/^CONFIG_TARGET_BOARD=//g')
	if [ "$o_target" != "" -a "$o_libc" != "" -a "$o_board" != "" ]; then
		target_path="build_dir/target-${o_target}_${o_libc}/root-${o_board}"
		if [ -e $target_path ]; then
			goto_target
		fi
	fi
}

# RTK only
function cdboa() {

	pkg_path=""
	target_path=""
	last_path="$(pwd)"
	top_path="$(find_sdk_top)"

	if [ "$top_path" == "" ]; then
		return 1
	fi

	target_path="${top_path}users/boa"
	if [ -e $target_path ]; then
		goto_target
	fi
}


# Go to kernel source
function cdkernel() {

	pkg_path=""
	target_path=""
	last_path="$(pwd)"
	top_path="$(find_sdk_top)"

	if [ "$top_path" = "" ]; then
		return 1
	fi

	target_path="${top_path}linux-3.10"
	if [ -e $target_path ]; then # RTK
		goto_target
		return
	fi

	target_path="${top_path}linux-2.6.36.x"
	if [ -e $target_path ]; then # Celeno
		goto_target
	fi
}


# Go to Wi-Fi driver
function cddriver() {
	pkg_path=""
	target_path=""
	last_path="$(pwd)"
	top_path="$(find_sdk_top)"

	if [ "$top_path" == "" ]; then
		return 1
	fi

	target_path="${top_path}linux-3.10/drivers/net/wireless/rtl8192cd"
	if [ -e $target_path ]; then # RTK
		goto_target
	fi
}


# Go to TR069 client folder
function cdtr069() {
	pkg_path=""
	target_path=""
	last_path="$(pwd)"
	top_path="$(find_sdk_top)"

	if [ "$top_path" == "" ]; then
		return 1
	fi

	target_path="${top_path}users/cwmp/agent-5.0"
	if [ -e $target_path ]; then
		goto_target
	fi

	target_path="${top_path}user/cwmp/agent-5.0"
	if [ -e $target_path ]; then
		goto_target
	fi
}


# Go to cwmp folder
function cdcwmp() {
	pkg_path=""
	target_path=""
	last_path="$(pwd)"
	top_path="$(find_sdk_top)"

	if [ "$top_path" == "" ]; then
		return 1
	fi

	target_path="${top_path}users/cwmp"
	if [ -e $target_path ]; then
		goto_target
	fi

	target_path="${top_path}user/cwmp"
	if [ -e $target_path ]; then
		goto_target
	fi
}


# Go to cwmp folder
function ltop() {
	pkg_path=""
	target_path=""
	last_path="$(pwd)"
	top_path="$(find_sdk_top)"

	if [ "$top_path" == "" ]; then
		return 1
	fi

	ls "$top_path" $@
}


function cdimage() {
	pkg_path=""
	target_path=""
	last_path="$(pwd)"
	top_path="$(find_sdk_top)"

	if [ "$top_path" == "" ]; then
		return 1
	fi

	target_path="${top_path}image"
	if [ -e $target_path ]; then # RTK
		goto_target
	fi
}


function cdwatchdog() {
	pkg_path=""
	target_path=""
	last_path="$(pwd)"
	top_path="$(find_sdk_top)"

	if [ "$top_path" == "" ]; then
		return 1
	fi

	target_path="${top_path}users/cwmp/check_watchdog"
	if [ -e $target_path ]; then # RTK
		goto_target
	fi
}
