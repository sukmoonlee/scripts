#!/bin/bash
################################################################################
## Program Certfication 추출 스크립트
## 2019.01 created by CoreSolution (smlee@sk.com)
################################################################################
SCRIPT_VERSION="20210825"
LANG=en_US.UTF-8
HOSTNAME=$(hostname)
OS=$(uname -s)

if [ -f "/bin/readelf" ] ; then PG_READELF="/bin/readelf"
elif [ -f "/usr/bin/readelf" ] ; then PG_READELF="/usr/bin/readelf"
else PG_READELF=; fi

if [ -f "/bin/basename" ] ; then PG_BASENAME="/bin/basename"
elif [ -f "/usr/bin/basename" ] ; then PG_BASENAME="/usr/bin/basename"
else echo "Error - Command not found 'basename'"; exit 1; fi

if [ -f "/sbin/lsof" ] ; then PG_LSOF="/sbin/lsof"
elif [ -f "/usr/sbin/lsof" ] ; then PG_LSOF="/usr/sbin/lsof"
elif [ -f "/usr/bin/lsof" ] ; then PG_LSOF="/usr/bin/lsof"
elif [ -f "/usr/local/bin/lsof" ] ; then PG_LSOF="/usr/local/bin/lsof"
elif [ -f "/opt/csw/bin/amd64/lsof" ] ; then PG_LSOF="/opt/csw/bin/amd64/lsof"
else echo "Error - Command not found 'lsof'"; exit 1; fi
################################################################################
FN_SOCKET=
while [ "$#" -gt 0 ] ; do
case "$1" in
	-v|--version)
		echo $SCRIPT_VERSION
		exit 0
		;;
	-d|--debug)
		set -x
		shift 1
		;;
	 *)
		FN_SOCKET=$1
		shift 1
		;;
esac
done
if [ "$FN_SOCKET" != "" ] && [ ! -f "$FN_SOCKET" ] ; then
	echo "Error - Not found socket file ($FN_SOCKET)"
	exit 1
fi
################################################################################
function GetProgram
{
	local pid=$1
	local name=

	name=$(sudo $PG_LSOF -np "$pid" |head |grep ' txt ' | awk '{print $NF}')
	if [ "${name:0:6}" == "/proc/" ] ; then
		echo ""
	elif [ "$name" == "(deleted)" ] ; then
		name=$(sudo $PG_LSOF -np "$pid" |head |grep ' txt ' | awk '{print $9}' | awk 'BEGIN {FS=";"}{print $1}')
		echo "$name"
	else
		name=$(sudo $PG_LSOF -np "$pid" |head |grep ' txt ' | awk '{print $9}')
		echo "$name"
	fi
}
function GetShortName
{
	local fullname=$1
	local name=

	name==$($PG_BASENAME "$1")
	echo "$name"
}
function CheckLibrary
{
	local pid=$1
	local chk=

	chk=$(sudo $PG_LSOF -np "$pid" |egrep ' mem | DEL ' | egrep "/libssl|/libssl3|/libcrypto|jsse.jar" | head)
	if [ "$chk" != "" ] ; then
		echo "O"
	else
		echo "X"
	fi
}
function CheckFunction
{
	local fullname=$1
	local chk=

	if [ "$PG_READELF" == "" ] ; then
		echo "O"
		return
	fi

	chk=$(sudo $PG_READELF -sW "$fullname" | egrep -i "SSL_use_certificate|SSL_CTX_use_certificate|SSL_use_PrivateKey|gnutls_certificate_set_x509_trust_file|mbedtls_x509_crt_parse" | head)
	if [ "$chk" != "" ] ; then
		echo "O"
	else
		echo "X"
	fi
}
function GetDisplayName
{
	local pid=$1
	local name=

	if [ "$OS" == "SunOS" ] ; then
		name=$(ps -o comm -p "$pid" |tail -1)
	else
		name=$(ps -o cmd --pid "$pid" |tail -1)
	fi
	echo "$name"
}
################################################################################
set -e
if [ "${BASH_VERSION:0:2}" == "4." ] ; then
	declare -A PLIST
fi

echo " Certification Program Library/Functon Check Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo " "

if [ "$FN_SOCKET" == "" ] ; then
	ps_list=$(ps -e -o pid|sed 1,1d)
else
	ps_list=$(grep -v "^ " "$FN_SOCKET" |awk '{print $4}')
fi
for pid in $ps_list
do
	fullname=$(GetProgram "$pid")
	if [ "$fullname" == "" ] ; then continue; fi
	displayname=$(GetDisplayName "$pid")
	if [ "${BASH_VERSION:0:2}" == "4." ] ; then
		if [ "${PLIST[$displayname]}" != "" ] ; then continue; fi
		if [ "${PLIST[$pid]}" != "" ] ; then continue; fi
	fi
	if [ "$OS" == "SunOS" ] ; then
		shortname=$(GetShortName "$displayname")
	else
		shortname=$(GetShortName "$fullname")
	fi
	chk_lib=$(CheckLibrary "$pid")
	chk_fun=$(CheckFunction "$fullname")
	if [ "$chk_lib" == "X" ] && [ "$chk_fun" == "X" ] && [ "$FN_SOCKET" == "" ] ; then continue; fi

	printf "%-20s Lib %s Fun %s PID %s %s\n" "$shortname" "$chk_lib" "$chk_fun" "$pid" "$displayname"
	if [ "${BASH_VERSION:0:2}" == "4." ] ; then
	#	PLIST[$displayname]=$pid
		PLIST[$pid]=$displayname
	fi
done

exit 0
