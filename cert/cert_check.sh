#!/bin/bash
################################################################################
# Certfication Check Script
# 2019.09.17 created by CoreSolution (smlee@sk.com)
################################################################################
SCRIPT_VERSION="20190917"
LANG=en_US.UTF-8
HOSTNAME=$(hostname)

if [ -f "/usr/bin/openssl" ] ; then PG_OPENSSL="/usr/bin/openssl"
elif [ -f "/usr/local/bin/openssl" ] ; then PG_OPENSSL="/usr/local/bin/openssl"
else echo "Error - Command not found 'openssl'"; exit 1; fi
if [ -f "/bin/timeout" ] ; then PG_TIMEOUT="/bin/timeout";
elif [ -f "/usr/bin/timeout" ] ; then PG_TIMEOUT="/usr/bin/timeout";
elif [ -f "/usr/share/doc/bash-3.2/scripts/timeout" ] ; then PG_TIMEOUT="bash /usr/share/doc/bash-3.2/scripts/timeout";
else echo "Error - Command not found 'timeout'"; exit 1; fi
################################################################################
TARGET_HOST=
TARGET_PORT=
while [ "$#" -gt 0 ] ; do
case "$1" in
	-v|--version)
		echo "$0 $SCRIPT_VERSION"
		exit 0
		;;
	-h|--host)
		shift 1
		TARGET_HOST="$1"
		shift 1
		;;
	-p|--port)
		shift 1
		TARGET_PORT="$1"
		shift 1
		;;
	-d|--debug)
		set -x
		shift 1
		;;
	 *)
		if [[ $1 =~ : ]] ; then
			ARG=(${1/:/ })
			TARGET_HOST=${ARG[0]}
			TARGET_PORT=${ARG[1]}
			shift 1
		else
			echo "Unknown Option"
			exit 1
		fi
		;;
esac
done

if [ "$TARGET_HOST" == "" ] || [ "$TARGET_PORT" == "" ] ; then
	echo "Usage: $0 -h {Hostname/IP} -p {Port}"
	exit 1
fi
################################################################################
function StringCat
{
	local name="$1"
	local len="$2"

	local len_name=${#name}
	local cnt_space=$((len-len_name))
	local RST="| $name"

	for ((i=0; i<cnt_space+1; i++))
	do
		RST="$RST "
	done
	echo "$RST";
}
function StringLine
{
	local name="$1"
	local len="$2"
	local RST="+"

	for ((i=0; i<len+2; i++))
	do
		RST="$RST-"
	done
	echo "$RST";
}
function PrintCertInfo
{
	$PG_TIMEOUT 10 $PG_OPENSSL s_client -connect "$1" 2>/dev/null | $PG_OPENSSL x509 -issuer -dates -fingerprint -noout | sed 's/^/    /g'
}
function GetProtocolInfo
{
	str=$($PG_TIMEOUT 10 $PG_OPENSSL s_client -connect "$1" -"$2" 2>/dev/null | egrep "Protocol|Cipher|Session-ID:")
	#echo $str

	ar=($str)
	if [ "${ar[7]}" == "" ] ; then
		line=$(StringCat "$2" "10")
	else
		line=$(StringCat "${ar[7]}" "10")
	fi
	line=$line$(StringCat "${ar[10]}" "32")
	if [ "${ar[12]}" == "" ] ; then
		line=$line$(StringCat "X" "10")
	else
		line=$line$(StringCat "O" "10")
	fi
	echo "    $line|";
}
################################################################################
echo "Certification Check Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo " "

echo "Check URL - $TARGET_HOST:$TARGET_PORT"
PrintCertInfo "$TARGET_HOST:$TARGET_PORT"
echo ""

echo "Report Protocol"

line=$(StringLine "" "10")
line=$line$(StringLine "" "32")
line=$line$(StringLine "" "10")
echo "    $line+";
line=$(StringCat "Protocol" "10")
line=$line$(StringCat "Cipher" "32")
line=$line$(StringCat "Support" "10")
echo "    $line|";
line=$(StringLine "" "10")
line=$line$(StringLine "" "32")
line=$line$(StringLine "" "10")
echo "    $line+";

GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "tls1"
GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "tls1_1"
GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "tls1_2"
GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "ssl3"
#GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "dtls1"

line=$(StringLine "" "10")
line=$line$(StringLine "" "32")
line=$line$(StringLine "" "10")
echo "    $line+";
