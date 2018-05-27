alias maket='make target/install V=s'
alias makev='make V=s'
alias makem='make menuconfig'

# error messages
cannot_find_top="error: The OpenWrt TopDir was not found."
cannot_find_prj="error: The project folder was not found."
cannot_find_rootfs="error: The rootfs folder was not found."
cannot_find_pkg="error: The package folder was not found."
cannot_find_src="error: The source code folder was not found."
cannot_find_external_kernel="error: The CONFIG_EXTERNAL_KERNEL_TREE is not exist in .config"
no_pkg_name="no package!!!"
nothing_to_makr="error: nothing to make"
here_is_openwrt_top="error: here is OpenWrt TopDir!!!"
finding="Finding, please wait it..."

# colorful echo
COLOR_END='\e[0m'
GREEN='\e[1;32m';
RED='\e[1;31m';
YELLOW='\e[1;33m';

function sdk-help() {
	echo ""
	echo "For OpenWRT:"
	cat ~/.bashrc-openwrt.sh | grep \#\#\# | sed 's/##//g' | sed 's/ --> /: /g'
	echo ""
	echo "For git:"
	cat ~/.bashrc-openwrt.sh | grep "\#\# git" | sed 's/##/#/g' | sed 's/ --> /: /g'
}

function echo_green() {
	echo -e ${GREEN}$@${COLOR_END}
}

function echo_error() {
	echo -e ${RED}$@${COLOR_END}
}

function echo_info() {
	echo -e ${YELLOW}$@${COLOR_END}
}

function goto_target() {
	echo "last_path: $last_path" && \
	cd $target_path && \
	echo_info "change to: $(pwd)"
	OLDPWD=$last_path
}

### makep OOO --> make package/OOO/prepare V=s
function makep() {
	if [ "$(is_sdk_top)" = "no" -o "$1" = "" ]; then
		echo_error $nothing_to_make
		return
	fi
	make package/$1/prepare V=s
}

### makec OOO --> make package/OOO/prepare V=s
function makec() {
	if [ "$(is_sdk_top)" = "no" -o "$1" = "" ]; then
		echo_error $nothing_to_make
		return
	fi
	make package/$1/compile V=s
}

### makei OOO --> make package/OOO/install V=s
function makei() {
	if [ "$(is_sdk_top)" = "no" -o "$1" = "" ]; then
		echo_error $nothing_to_make
		return
	fi
	make package/$1/install V=s
}

### make_clean OOO --> make package/xxx/clean V=s
function make_clean() {
	if [ "$(is_sdk_top)" = "no" -o "$1" = "" ]; then
		echo_error $nothing_to_make
		return
	fi
	make package/$1/clean V=s
}

### make_kernel --> make target/linux/{clean,compile}
function make_kernel() {
	make target/linux/{clean,compile} V=s
}

# check OpenWRT TopDir
function is_sdk_top() {
	if [ -e rules.mk -a -e package ]; then
		echo "yes"
	else
		echo "no"
	fi
}

function find_top() {
	if [ -e rules.mk -a -e package ]; then
		top_path="."
	else
		top_path=""
		ls_path=""
		level="$(pwd | sed 's/^\///g' | tr '\n' '\0' | tr '/' '\n' | wc -l)"
		for i in $(seq 1 $level)
		do
			ls_path="$ls_path../"
			if [ -e $ls_path/rules.mk -a -e $ls_path/package ]; then
				top_path="$(echo $ls_path | sed 's/\/$//g')"
			fi
		done
	fi
	echo $top_path
}


### cdtop --> To OpenWRT TopDir
function cdtop() {
	last_path="$(pwd)"
	current="${PWD##*/}"
	cd_path=""
	hide="$1"

	if [ "$(ls qsdk 2>/dev/null)" != "" ]; then
		cd_path="qsdk"
	else
		# fix last_path is symlink and this tool cannot change to corrent folder
		cd $(pwd -P)
		cd_path="$(find_top)"
	fi

	if [ "$cd_path" = "." ]; then
		if [ "$hide" != "1" ]; then
			echo_error $here_is_openwrt_top
		fi

	elif [ "$cd_path" != "" ]; then
		if [ "$hide" != "1" ]; then
			target_path=$cd_path
			goto_target
		else
			cd $cd_path
		fi
	else
		if [ "$hide" != "1" ]; then
			echo_error $cannot_find_top
		else
			echo $cannot_find_top
		fi
	fi
}


### cdkernel --> To kernel source folder
function cdkernel() {
	last_path="$(pwd)"
	if [ "$(is_sdk_top)" = "no" ]; then
		if [ "$(cdtop 1)" = "$cannot_find_top" ]; then
			echo_error $cannot_find_top
			return
		fi
		cdtop 1
	fi

	kernel_path=$(grep CONFIG_EXTERNAL_KERNEL_TREE .config | sed 's/CONFIG_EXTERNAL_KERNEL_TREE="//g' | sed 's/"//g')
	if [ "$kernel_path" = "" ]; then
		echo_error $cannot_find_external_kernel
		return
	fi

	target_path=$kernel_path
	goto_target
}

### cdrootfs --> To rootfs folder in build_dir
function cdrootfs() {
	echo_green $finding
	echo ""
	last_path="$(pwd)"
	if [ "$(is_sdk_top)" = "no" ]; then
		if [ "$(cdtop 1)" = "$cannot_find_top" ]; then
			echo $cannot_find_top
			return
		fi
		cdtop 1
	fi

	target_name="$(grep CONFIG_TARGET_NAME .config | sed 's/.*="//g' | sed 's/"//g')"
	target_board="$(grep CONFIG_TARGET_BOARD .config | sed 's/.*="//g' | sed 's/"//g')"
	rootfs_path="build_dir/target-$target_name/root-$target_board"

	if [ "$rootfs_path" = "" -o ! -e "$rootfs_path" ]; then
		rootfs_path=$(find build_dir -type d -name root-*)
		if [ "$rootfs_path" = "" ]; then
			echo_red "$cannot_find_rootfs"
			cd $last_path
			return
		fi
	fi

	target_path=$(pwd)/$rootfs_path
	goto_target
}


### cdcode OOO --> To source code folder on package in build_dir
function cdcode() {
	if [ "$1" = "" ]; then
		echo_error $no_pkg_name
		return
	fi

	echo_green $finding
	echo ""
	last_path="$(pwd)"

	if [ "$(is_sdk_top)" = "no" ]; then
		if [ "$(cdtop 1)" = "$cannot_find_top" ]; then
			echo $cannot_find_top
			return
		fi
		cdtop 1
	fi

	target_name="$(grep CONFIG_TARGET_NAME .config | sed 's/.*="//g' | sed 's/"//g')"
	target_board="$(grep CONFIG_TARGET_BOARD .config | sed 's/.*="//g' | sed 's/"//g')"
	build_dir_path="build_dir/target-$target_name"

	if [ "$build_dir_path" != "" -a -e "$build_dir_path" ]; then
		code_path=$(find $build_dir_path -maxdepth 1 -type d -name $1*)
		code_src_count=$(find $build_dir_path -maxdepth 1 -type d -name $1* | wc -l)
		if [ "$code_path" = "" ]; then
			echo_red "$cannot_find_src"
			cd $last_path
			return
		fi

		if [ "$code_src_count" != "1" ]; then
			echo_info "Find $code_src_count results:"
			echo $code_path | tr ' ' '\n'
			echo ""
			echo_red "Please search again!!!"
			cd $last_path
			return
		fi

		target_path=$code_path
	fi

	goto_target
}

# Git alias

## git co --> git checkout
git config --global alias.co checkout

## git br --> git branch
git config --global alias.br branch

## git ci --> git commit
git config --global alias.ci commit

## git st --> git status
git config --global alias.st status

## git lg --> git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cd) %C(bold blue)<%an>%Creset" --abbrev-commit --date=local
git config --global alias.lg 'log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cd) %C(bold blue)<%an>%Creset" --abbrev-commit --date=local'

## git d  --> git diff
git config --global alias.d diff

## git ds --> git diff --staged
git config --global alias.ds 'diff --staged' --replace-all

## git r  --> git remote
git config --global alias.r 'remote'

## git rv  --> git remote -v
git config --global alias.rv 'remote -v'

## git unstage --> git reset HEAD --
git config --global alias.unstage 'reset HEAD --'

## git last --> git log -1 HEAD
git config --global alias.last 'log -1 HEAD'


# Other git setting
git config --global color.ui true
git config --global color.diff true
git config --global core.editor vim
git config --global merge.tool vim
git config --global log.date local
