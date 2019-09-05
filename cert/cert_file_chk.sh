#!/bin/bash
################################################################################
## Certfication 파일 검색 및 확인 스크립트
## 2019.01 created by CoreSolution (smlee@sk.com)
################################################################################
SCRIPT_VERSION="20190321"
LANG=en_US.UTF-8
HOSTNAME=$(hostname)

if [ -f "/usr/bin/openssl" ] ; then PG_OPENSSL="/usr/bin/openssl"
elif [ -f "/usr/local/bin/openssl" ] ; then PG_OPENSSL="/usr/local/bin/openssl"
elif [ -f "/usr/local/ssl/bin/openssl" ] ; then PG_OPENSSL="/usr/local/ssl/bin/openssl"
else echo "Error - Command not found 'openssl'"; exit 1; fi

OPT_FILE=""
OPT_NFS="0"
OPT_DIR="/etc"
################################################################################
while [ "$#" -gt 0 ] ; do
case "$1" in
	-f|--file)
		shift
		OPT_FILE=$1
		shift
		;;
	-n|--nfs)
		OPT_NFS="1"
		shift
		;;
	-s|--start)
		shift
		OPT_DIR=$1
		shift
		;;
	-v|--version)
		echo $SCRIPT_VERSION
		exit 0
		;;
	-d|--debug)
		set -x
		shift 1
		;;
	 *)
		echo "Unknown Option"
		exit 1
		;;
esac
done
################################################################################
function GetDigest
{
	local str=
	if [ "$UID" == "0" ] ; then
		str=$(md5sum "$1" | awk '{print $1}')
	else
		str=$(sudo md5sum "$1" | awk '{print $1}')
	fi
	echo "$str"
}
function GetFileCmd
{
	local str=
	if [ "$UID" == "0" ] ; then
		str=$(file "$1" | awk '{print $2,$3,$4}')
	else
		str=$(sudo file "$1" | awk '{print $2,$3,$4}')
	fi

	if [ "$str" == "ASCII text " ] || [ "$str" == "ascii text " ] ; then
		str=$(sudo head -1 "$1")
		if [ "$str" == "-----BEGIN CERTIFICATE-----" ] ; then
			str="PEM certificate "
		fi
	fi

	echo "$str"
}
function PrintCertInfo
{
	local file=$1
	if [ "$UID" == "0" ] ; then
		$PG_OPENSSL x509 -in "$file" -issuer -dates -fingerprint -noout | sed 's/^/    /g'
	else
		sudo $PG_OPENSSL x509 -in "$file" -issuer -dates -fingerprint -noout | sed 's/^/    /g'
	fi
}
function GetCertDigest
{
	local str=
	if [ "$UID" == "0" ] ; then
		str=$($PG_OPENSSL x509 -text -in "$1" -outform pem |md5sum |awk '{print $1}')
	else
		str=$(sudo $PG_OPENSSL x509 -text -in "$1" -outform pem |md5sum |awk '{print $1}')
	fi
	echo "$str"
}
################################################################################
set -e

echo " Certification File Search Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo " "

if [ "${BASH_VERSION:0:2}" == "4." ] ; then
	declare -A FLIST
fi

if [ "$UID" == "0" ] ; then

	if [ "$OPT_NFS" == "0" ] ; then OPT_FIND2=" ! -fstype nfs"
	else OPT_FIND2=""; fi

	if [ "$OPT_FILE" == "" ] ; then
		OPT_FIND1=" -name *.pem -o -name *.crt -o -name *.csr -o -name *.der -o -name *.rsa "
	else
		OPT_FIND1=" -name *.pem -o -name *.crt -o -name *.csr -o -name *.der -o -name *.rsa -o -name $OPT_FILE "
	fi

	set +e
	file_list=$(eval "sudo find $OPT_DIR $OPT_FIND1 $OPT_FIND2 2>/dev/null")
	set -e
	for file in $file_list
	do
		digest=$(GetDigest "$file")
		desc=$(GetFileCmd "$file")
		if [ "$desc" != "PEM certificate " ] ; then continue; fi

		ssldigest=$(GetCertDigest "$file")
		if [ "${BASH_VERSION:0:2}" == "4." ] ; then
			if [ "${FLIST[$digest]}" != "" ] ; then continue; fi
		fi

		printf "%s md5sum %s\n" "$file" "$ssldigest"
		if [ "${BASH_VERSION:0:2}" == "4." ] ; then
			FLIST[$digest]=$file
		fi

		PrintCertInfo "$file"
	done

else

	if [ "$OPT_FILE" == "" ] ; then
		# shellcheck disable=SC2024
		sudo ls -1R "$OPT_DIR" |sudo egrep "^/|.pem$|.crt$|.csr$|.der$|.rsa$" > "/tmp/$0.txt"
	else
		# shellcheck disable=SC2024
		sudo ls -1R "$OPT_DIR" |sudo egrep "^/|.pem$|.crt$||.csr$|.der$|.rsa$|$OPT_FILE$" > "/tmp/$0.txt"
	fi

	dirname=$OPT_DIR
	file_list=$(cat "/tmp/$0.txt")
	for ffile in $file_list
	do
		if [ "${ffile:0:1}" == "/" ] ; then
			strlen=${#ffile}
			dirname=${ffile:0:$((strlen-1))}
			continue
		fi

		file="$dirname/$ffile"
		digest=$(GetDigest "$file")
		desc=$(GetFileCmd "$file")
		if [ "$desc" != "PEM certificate " ] ; then continue; fi

		ssldigest=$(GetCertDigest "$file")
		if [ "${BASH_VERSION:0:2}" == "4." ] ; then
			if [ "${FLIST[$digest]}" != "" ] ; then continue; fi
		fi

		printf "%s md5sum %s\n" "$file" "$ssldigest"
		if [ "${BASH_VERSION:0:2}" == "4." ] ; then
			FLIST[$digest]=$file
		fi

		PrintCertInfo "$file"
	done
	rm -f "/tmp/$0.txt"

fi

exit 0
