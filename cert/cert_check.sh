#!/bin/bash
################################################################################
# Certfication Check Script
# 2020.12.26 created by smlee@sk.com
################################################################################
SCRIPT_VERSION="20210221"
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
if [ -f "/usr/bin/netstat" ] ; then PG_NETSTAT="/usr/bin/netstat"
elif [ -f "/bin/netstat" ] ; then PG_NETSTAT="/bin/netstat"
else echo "Error - Command not found 'netstat'"; exit 1; fi
################################################################################
function Usage
{
	echo "Usage: $0 [-rdvh] [{hostname/ip}:{port}]"
	echo "      -r, --report  : print only secure socket information"
	echo "      -d, --debug   : set debug(-x)"
	echo "      -v, --version : print version ($SCRIPT_VERSION)"
	echo "      -h, --help    : help"
}
TARGET_HOST=
TARGET_PORT=
FLAG_REPORT=0
while [ "$#" -gt 0 ] ; do
case "$1" in
	-v|--version)
		echo "$0 $SCRIPT_VERSION"
		exit 0
		;;
	-d|--debug)
		set -x
		shift 1
		;;
	-r|--report)
		FLAG_REPORT=1
		shift 1
		;;
	-h|--help)
		Usage
		exit 0
		;;
	*)
		if [ "$TARGET_HOST" == "" ] && [[ $1 =~ : ]] ; then
			ARG=(${1/:/ })
			TARGET_HOST=${ARG[0]}
			TARGET_PORT=${ARG[1]}
			shift 1
		else
			echo "Unknown option: $1"
			echo
			Usage
			exit 1
		fi
		;;
esac
done
################################################################################
function _stringCat
{
	local name="$1"
	local len="$2"

	local len_name=${#name}
	local cnt_space=$((len-len_name))
	local RST="|$name"

	for ((i=0; i<cnt_space; i++))
	do
		RST="$RST "
	done
	echo "$RST"
}
function _stringLine
{
	local name="$1"
	local len="$2"
	local RST="+"

	for ((i=0; i<len; i++))
	do
		RST="$RST-"
	done
	echo "$RST"
}
_STRING_NO=0
_STRING_LIST=()
function makeString
{
	if [ "$2" == "newline" ] ; then
		_STRING_NO=$((_STRING_NO+1))
		_STRING_LIST[$_STRING_NO]=""
	fi
	_STRING_LIST[$_STRING_NO]="${_STRING_LIST[$_STRING_NO]}$1|"
}
function printString
{
	local SLEN=()
	for _row in "${_STRING_LIST[@]}"; do
		IFS='|' read -r -a _array <<< "$_row"
		local _col_cnt=0
		for _col in "${_array[@]}"; do
			if [ "${SLEN[$_col_cnt]}" == "" ] ; then
				SLEN[$_col_cnt]=0
			fi
			if [ "${#_col}" -gt "${SLEN[$_col_cnt]}" ] ; then
				SLEN[$_col_cnt]=${#_col}
			fi
			_col_cnt=$((_col_cnt+1))
		done
	done

	for _row in "${_STRING_LIST[@]}"; do
		IFS='|' read -r -a _array <<< "$_row"
		local _col_cnt=0
		local _line=
		local _last_flag=0
		for _col in "${_array[@]}"; do
			if [ "$_col" == "-" ] ; then
				_line=$_line$(_stringLine "" "${SLEN[$_col_cnt]}")
				_last_flag=1
			else
				_line=$_line$(_stringCat "$_col" "${SLEN[$_col_cnt]}")
				_last_flag=0
				if [ "${_col:0:4}" == " >>>" ] ; then _last_flag=2; fi
			fi
			_col_cnt=$((_col_cnt+1))
		done
		if [ "$_line" != "" ] ; then
			if [ "$_last_flag" == "0" ] ; then echo "$_line|"
			elif [ "$_last_flag" == "2" ] ; then echo "$_line"
			else echo "$_line+"; fi
		fi
	done
}
function PrintCertInfo
{
	str=$($PG_TIMEOUT 10 $PG_OPENSSL s_client -connect "$1" 2>/dev/null | $PG_OPENSSL x509 -issuer -subject -dates -fingerprint -noout | sed 's/^/    /g')
	if [ "$str" == "" ] ; then
		exit 1
	fi
	echo "$str"
}
function GetProtocolInfo
{
	str=$($PG_TIMEOUT 10 $PG_OPENSSL s_client -connect "$1" -"$2" 2>/dev/null | egrep -a "Protocol|Cipher|Session-ID:")

	ar=($str)
	if [ "${ar[7]}" == "" ] ; then
		if [ "${ar[1]}" == "" ] || [ "${ar[1]}" == "(NONE)," ] ; then
			makeString " $2" "newline"
		else
			makeString " ${ar[1]:0:-1} " "newline"
		fi
	else
		makeString " ${ar[7]} " "newline"
	fi

	if [ "${ar[12]}" == "" ] ; then
		if [ "${ar[4]}" != "" ] && [ "${ar[4]}" != "(NONE)" ] ; then
			makeString "   O"
		else
			makeString "   X"
		fi
	else
		makeString "   O"
	fi

	if [ "${ar[10]}" == "" ] ; then
		if [ "${ar[4]}" == "" ] || [ "${ar[4]}" == "(NONE)" ] ; then
			makeString ""
		else
			makeString " ${ar[4]} "
		fi
	else
		makeString " ${ar[10]} "
	fi
}
################################################################################
echo "Certification Check Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo " "

if [ "$TARGET_HOST" != "" ] ; then
	echo "Check URL - $TARGET_HOST:$TARGET_PORT"
	PrintCertInfo "$TARGET_HOST:$TARGET_PORT"
	echo ""

	echo "Report Protocol"
	makeString "-" "newline"; makeString "-"; makeString "-";
	makeString " Protocol " "newline"
	makeString " allow "
	makeString " Cipher "
	makeString "-" "newline"; makeString "-"; makeString "-";

	just=$($PG_OPENSSL s_client -help 2>&1 >/dev/null |grep -ai 'just use'|awk '{print $1}')
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

	makeString "-" "newline"; makeString "-"; makeString "-";
	printString |tee |sed 's/^/    /'
elif [ "$FLAG_REPORT" == "1" ] ; then
	makeString "-" "newline"; makeString "-"; makeString "-";
	makeString " Test Socket " "newline"
	makeString " PID/Program "
	makeString " Certification Information ($(date +%Z\ %z)) "
	makeString "-" "newline"; makeString "-"; makeString "-";

	pplist=$($PG_NETSTAT -na |grep ^tcp |grep LISTEN |awk '{print $4}' | awk -F: '{print $NF}' |sort -un)
	for pp in $pplist
	do
		str=$($PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "127.0.0.1:$pp" 2>/dev/null | $PG_OPENSSL x509 -dates -noout 2>/dev/null)
		if [ "$str" == "" ] ; then continue; fi
		makeString " 127.0.0.1:$pp " "newline"

		if [ "$UID" == "0" ] ; then
			pg=$($PG_NETSTAT -nap |grep "^tcp" |grep LISTEN |grep ":$pp"|head -1 | awk '{print $7}')
		else
			pg="-"
		fi
		makeString " $pg "

		pstr=$(echo "$str" | sed 's/notBefore=//g' | sed 's/notAfter=/ ~ /g' |tr -d '\n')
		pstr1=$(date --date="${pstr:0:24}" +%Y-%m-%d\ %H:%M:%S)
		pstr2=$(date --date="${pstr:27:24}" +%Y-%m-%d\ %H:%M:%S)
		pstr="$pstr1 ~ $pstr2"
		makeString " $pstr "

		str=$($PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "127.0.0.1:$pp" 2>/dev/null | $PG_OPENSSL x509 -issuer -noout 2>/dev/null)
		pstr1=${str//issuer=/ }
		if [ "$pstr1" != "" ] ; then makeString " >>>$pstr1"; fi
	done

	makeString "-" "newline"; makeString "-"; makeString "-";
	printString
else
	makeString "-" "newline"; makeString "-"; makeString "-"; makeString "-";
	makeString " Listen Socket " "newline"
	makeString " Test Socket "
	makeString " PID/Program "
	makeString " Certification Information ($(date +%Z\ %z)) "
	makeString "-" "newline"; makeString "-"; makeString "-"; makeString "-";

	pplist=$($PG_NETSTAT -nap 2>/dev/null |grep ^tcp |grep LISTEN)
	pparray=()
	cnt=0
	while read pp
	do
		cnt=$((cnt+1))
		pparray[cnt]=$pp
	done <<< "$pplist"

	for i in $(seq 1 ${#pparray[@]})
	do
		IFS=' ' read -r -a _array <<< "${pparray[$i]}"
		makeString " ${_array[3]} " "newline"

		str_ip=$(echo "${_array[3]}" | awk -F: '{print substr($0,0,length($0)-length($NF)-1)}')
		str_port=$(echo "${_array[3]}" | awk -F: '{print $NF}')
		if [ "${_array[0]}" == "tcp" ] && [ "$str_ip" == "0.0.0.0" ] ; then
			str_addr="127.0.0.1:$str_port"
		elif [ "${_array[0]}" == "tcp6" ] && [ "$str_ip" == "::" ] ; then
			str_addr="[::1]:$str_port"
		elif [ "${_array[0]}" == "tcp" ] ; then
			str_addr="$str_ip:$str_port"
		elif [ "${_array[0]}" == "tcp6" ] ; then
			str_addr="[$str_ip]:$str_port"
		fi
		makeString " $str_addr "
		makeString " ${_array[6]} "

		str=$($PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "$str_addr" 2>/dev/null | $PG_OPENSSL x509 -dates -noout 2>/dev/null)
		if [ "$str" == "" ] ; then
			makeString ""
			continue
		fi

		pstr=$(echo "$str" | sed 's/notBefore=//g' | sed 's/notAfter=/ ~ /g' |tr -d '\n')
		pstr1=$(date --date="${pstr:0:24}" +%Y-%m-%d\ %H:%M:%S)
		pstr2=$(date --date="${pstr:27:24}" +%Y-%m-%d\ %H:%M:%S)
		pstr="$pstr1 ~ $pstr2"
		makeString " $pstr "

		str=$($PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "$str_addr" 2>/dev/null | $PG_OPENSSL x509 -issuer -noout 2>/dev/null)
		pstr1=${str//issuer=/ }
		if [ "$pstr1" != "" ] ; then makeString " >>>$pstr1"; fi
	done

	makeString "-" "newline"; makeString "-"; makeString "-"; makeString "-";
	printString
fi

exit 0
