#!/bin/bash
################################################################################
# Certfication Check Script
# 2019.09.17 created by CoreSolution (smlee@sk.com)
################################################################################
SCRIPT_VERSION="20200928"
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
HOSTNAME=$(hostname)

if [ -f "/usr/bin/openssl11" ] ; then PG_OPENSSL="/usr/bin/openssl11"
elif [ -f "/usr/bin/openssl" ] ; then PG_OPENSSL="/usr/bin/openssl"
elif [ -f "/usr/local/bin/openssl" ] ; then PG_OPENSSL="/usr/local/bin/openssl"
else echo "Error - Command not found 'openssl'"; exit 1; fi
if [ -f "/bin/timeout" ] ; then PG_TIMEOUT="/bin/timeout"
elif [ -f "/usr/bin/timeout" ] ; then PG_TIMEOUT="/usr/bin/timeout"
elif [ -f "/usr/share/doc/bash-3.2/scripts/timeout" ] ; then PG_TIMEOUT="bash /usr/share/doc/bash-3.2/scripts/timeout"
else echo "Error - Command not found 'timeout'"; exit 1; fi
################################################################################
TARGET_HOST=
TARGET_PORT=
FLAG_ALL=0
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
	-a|--all)
		FLAG_ALL=1
		shift 1
		;;
	--help)
		echo "Usage: $0 -h {Hostname/IP} -p {Port}"
		exit 1
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
	echo "$RST"
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
	echo "$RST"
}
function PrintCertInfo
{
	str=$($PG_TIMEOUT 10 $PG_OPENSSL s_client -connect "$1" 2>/dev/null | $PG_OPENSSL x509 -issuer -dates -fingerprint -noout | sed 's/^/    /g')
	if [ "$str" == "" ] ; then
		exit 1
	fi
	echo "$str"
}
function GetProtocolInfo
{
	str=$($PG_TIMEOUT 10 $PG_OPENSSL s_client -connect "$1" -"$2" 2>/dev/null | egrep "Protocol|Cipher|Session-ID:")
	#echo $str

	ar=($str)
	if [ "${ar[7]}" == "" ] ; then
		if [ "${ar[1]}" == "" ] || [ "${ar[1]}" == "(NONE)," ] ; then
			line=$(StringCat "$2" "10")
		else
			line=$(StringCat "${ar[1]:0:-1}" "10")
		fi
	else
		line=$(StringCat "${ar[7]}" "10")
	fi

	if [ "${ar[10]}" == "" ] ; then
		if [ "${ar[4]}" == "" ] || [ "${ar[4]}" == "(NONE)" ] ; then
			line=$line$(StringCat "" "32")
		else
			line=$line$(StringCat "${ar[4]}" "32")
		fi
	else
		line=$line$(StringCat "${ar[10]}" "32")
	fi

	if [ "${ar[12]}" == "" ] ; then
		if [ "${ar[4]}" != "" ] && [ "${ar[4]}" != "(NONE)" ] ; then
			line=$line$(StringCat "O" "10")
		else
			line=$line$(StringCat "X" "10")
		fi
	else
		line=$line$(StringCat "O" "10")
	fi
	echo "    $line|"
}
################################################################################
echo "Certification Check Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo " "

if [ "$TARGET_HOST" != "" ] ; then
	echo "Check URL - $TARGET_HOST:$TARGET_PORT"
	PrintCertInfo "$TARGET_HOST:$TARGET_PORT"
	echo ""

	echo "Report Protocol"

	line=$(StringLine "" "10")
	line=$line$(StringLine "" "32")
	line=$line$(StringLine "" "10")
	echo "    $line+"
	line=$(StringCat "Protocol" "10")
	line=$line$(StringCat "Cipher" "32")
	line=$line$(StringCat "Support" "10")
	echo "    $line|"
	line=$(StringLine "" "10")
	line=$line$(StringLine "" "32")
	line=$line$(StringLine "" "10")
	echo "    $line+"

	just=$($PG_OPENSSL s_client -help 2>&1 >/dev/null |grep -i 'just use'|awk '{print $1}')
	GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "tls1"
	GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "tls1_1"
	GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "tls1_2"
	if [[ $just == *"-tls1_3"* ]] ; then
		GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "tls1_3"
	fi
	GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "ssl3"
	if [[ $just == *"-ssl2"* ]] ; then
		GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "ssl2"
	fi
	if [[ $just == *"-dtls1"* ]] ; then
		GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "dtls1"
	fi
	if [[ $just == *"-dtls1_2"* ]] ; then
		GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "dtls1_2"
	fi

	#just=$($PG_OPENSSL s_client help 2>&1 >/dev/null |grep 'just use'|awk '{print $1}')
	#echo "$just" | while IFS=' ' read ll
	#do
	#	GetProtocolInfo "$TARGET_HOST:$TARGET_PORT" "$ll"
	#done

	line=$(StringLine "" "10")
	line=$line$(StringLine "" "32")
	line=$line$(StringLine "" "10")
	echo "    $line+"
else
	line=$(StringLine "" "15")
	line=$line$(StringLine "" "16")
	line=$line$(StringLine "" "41")
	echo "$line+"
	line=$(StringCat "Local Address" "15")
	line=$line$(StringCat "PID/Program name" "16")
	str=$(date +%Z\ %z)
	line=$line$(StringCat "Certification Information ($str)" "41")
	echo "$line|"
	line=$(StringLine "" "15")
	line=$line$(StringLine "" "16")
	line=$line$(StringLine "" "41")
	echo "$line+"

	pplist=$(netstat -na |grep ^tcp |grep LISTEN |awk '{print $4}' | awk -F: '{print $NF}' |sort -un)
	for pp in $pplist
	do
		line=$(StringCat "127.0.0.1:$pp" "15")
		if [ "$UID" == "0" ] ; then
			pg=$(netstat -nap |grep "^tcp" |grep LISTEN |grep ":$pp"|head -1 | awk '{print $NF}')
			if [[ $pg != *"/"* ]] ; then	
				pg=$(netstat -nap |grep "^tcp" |grep LISTEN |grep ":$pp"|head -1 | awk '{print $7}')
			fi
		else
			pg="-"
		fi
		line=$line$(StringCat "$pg" "16")

		str=$($PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "127.0.0.1:$pp" 2>/dev/null | $PG_OPENSSL x509 -dates -noout 2>/dev/null)
		if [ "$str" == "" ] ; then
			if [ "$FLAG_ALL" == "1" ] ; then
				line=$line$(StringCat "" "41")
				echo "$line|"
			fi
			continue
		fi

		pstr=$(echo "$str" | sed 's/notBefore=//g' | sed 's/notAfter=/ ~ /g' |tr -d '\n')
		pstr1=$(date --date="${pstr:0:24}" +%Y-%m-%d\ %H:%M:%S)
		pstr2=$(date --date="${pstr:27:24}" +%Y-%m-%d\ %H:%M:%S)
		pstr="$pstr1 ~ $pstr2"

		line=$line$(StringCat "$pstr" "41")

		str=$($PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "127.0.0.1:$pp" 2>/dev/null | $PG_OPENSSL x509 -issuer -noout 2>/dev/null)
		pstr=${str//issuer=/ }
		echo "$line|$pstr"
	done

	line=$(StringLine "" "15")
	line=$line$(StringLine "" "16")
	line=$line$(StringLine "" "41")
	echo "$line+"
fi
