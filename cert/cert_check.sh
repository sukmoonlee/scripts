#!/bin/bash
set +o posix
################################################################################
# Certfication Check Script
# 2020.12.26 created by smlee@sk.com
################################################################################
SCRIPT_VERSION="20220327"
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
elif [ -f "/usr/sbin/ss" ] ; then PG_SS="/usr/sbin/ss"
else echo "Error - Command not found 'netstat' or 'ss'"; exit 1; fi
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
FLAG_ANSI=0
while [ "$#" -gt 0 ] ; do
case "$1" in
	-r|--report)
		FLAG_REPORT=1
		shift 1
		;;
	--ansi)
		FLAG_ANSI=1
		shift 1
		;;
	--no-ansi)
		FLAG_ANSI=0
		shift 1
		;;
	-v|--version)
		echo "$0 $SCRIPT_VERSION"
		exit 0
		;;
	-d|--debug)
		set -x
		shift 1
		;;
	-h|--help)
		Usage
		exit 0
		;;
	*)
		if [ "$TARGET_HOST" == "" ] && [[ $1 =~ : ]] ; then
			ARG=( "${1/:/ }" )
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
	local align="$3"

	local len_name=${#name}
	if [ "$FLAG_ANSI" == "1" ] ; then
		_str=$(echo "$name" |sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g"|sed 's/(B//g')
		len_name=${#_str}
	fi
	local cnt_space=$((len-len_name))
	local RST="|$name"

	if [ "$align" == "right" ] ; then RST="|"; fi
	for ((i=0; i<cnt_space; i++))
	do
		RST="$RST "
	done

	if [ "$align" == "right" ] ; then RST="$RST$name"; fi
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
	if [ "$2" == "new" ] ; then
		_STRING_LIST=()
		_STRING_NO=0
		_STRING_LIST[$_STRING_NO]=""
	elif [ "$2" == "newline" ] ; then
		_STRING_NO=$((_STRING_NO+1))
		_STRING_LIST[$_STRING_NO]=""
	fi

	if [ "$3" == "right" ] ; then
		_STRING_LIST[$_STRING_NO]="${_STRING_LIST[$_STRING_NO]}$1~R|"
	else
		_STRING_LIST[$_STRING_NO]="${_STRING_LIST[$_STRING_NO]}$1|"
	fi
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
			local _len=${#_col}
			if [ "$FLAG_ANSI" == "1" ] ; then
				_col=$(echo "${_col}" |sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g"|sed 's/(B//g')
				_len=${#_col}
			fi
			if [ "${_col:$((_len-2)):2}" == "~R" ] ; then
				_len=$((_len-2))
			fi
			if [ "$_len" -gt "${SLEN[$_col_cnt]}" ] ; then
				SLEN[$_col_cnt]=$_len
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
				local _len=${#_col}

				if [ "$FLAG_ANSI" == "1" ] ; then
					_str=$(echo "${_col}" |sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g"|sed 's/(B//g')
					_len=${#_str}
					if [ "${_str:$((_len-2)):2}" == "~R" ] ; then
						_line=$_line$(_stringCat "${_col/~R/}" "${SLEN[$_col_cnt]}" "right")
					else
						_line=$_line$(_stringCat "$_col" "${SLEN[$_col_cnt]}")
					fi
				else
					if [ "${_col:$((_len-2)):2}" == "~R" ] ; then
						_line=$_line$(_stringCat "${_col:0:$((_len-2))}" "${SLEN[$_col_cnt]}" "right")
					else
						_line=$_line$(_stringCat "$_col" "${SLEN[$_col_cnt]}")
					fi
				fi
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
	str=$($PG_TIMEOUT 10 $PG_OPENSSL s_client -connect "$1" -"$2" 2>/dev/null | grep -Ea "Protocol|Cipher|Session-ID:")

	ar=( "$str" )
	if [ "${ar[7]}" == "" ] ; then
		if [ "${ar[1]}" == "" ] || [ "${ar[1]}" == "(NONE)," ] ; then
			str_protocol=" $2 "
		else
			str_protocol=" ${ar[1]:0:-1} "
		fi
	else
		str_protocol=" ${ar[7]} "
	fi

	if [ "${ar[12]}" == "" ] ; then
		if [ "${ar[4]}" != "" ] && [ "${ar[4]}" != "(NONE)" ] ; then
			str_allow="   O"
		else
			str_allow="   X"
		fi
	else
		str_allow="   O"
	fi

	if [ "${ar[10]}" == "" ] ; then
		if [ "${ar[4]}" == "" ] || [ "${ar[4]}" == "(NONE)" ] ; then
			str_cipher=
		else
			str_cipher=" ${ar[4]} "
		fi
	else
		str_cipher=" ${ar[10]} "
	fi

	if [ "$FLAG_ANSI" == "1" ] && [[ $str_allow == *"O" ]] ; then
		makeString "$(tput setaf 4)$str_protocol$(tput sgr0)" "newline"
	else
		makeString "$str_protocol" "newline"
	fi
	makeString "$str_allow"
	makeString "$str_cipher"
}
function GetTlsHostPort
{
	local _addr="$1"

	echo "Check URL - $_addr"
	PrintCertInfo "$_addr"
	echo ""

	echo "Report Protocol"
	makeString "-" "new"; makeString "-"; makeString "-"
	makeString " Protocol " "newline"
	makeString " allow "
	makeString " Cipher "
	makeString "-" "newline"; makeString "-"; makeString "-"

	just=$($PG_OPENSSL s_client -help 2>&1 >/dev/null |grep -ai 'just use'|awk '{print $1}')
	GetProtocolInfo "$_addr" "tls1"
	GetProtocolInfo "$_addr" "tls1_1"
	GetProtocolInfo "$_addr" "tls1_2"
	if [[ $just == *"-tls1_3"* ]] ; then
		GetProtocolInfo "$_addr" "tls1_3"
	fi
	GetProtocolInfo "$_addr" "ssl3"
	if [[ $just == *"-ssl2"* ]] ; then
		GetProtocolInfo "$_addr" "ssl2"
	fi
	if [[ $just == *"-dtls1"* ]] ; then
		GetProtocolInfo "$_addr" "dtls1"
	fi
	if [[ $just == *"-dtls1_2"* ]] ; then
		GetProtocolInfo "$_addr" "dtls1_2"
	fi

	makeString "-" "newline"; makeString "-"; makeString "-"
	printString |tee |sed 's/^/    /'
}
################################################################################
sslversion=$($PG_OPENSSL version)
echo "Certification Check Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION, $sslversion)"
echo ""

if [ "$TARGET_HOST" != "" ] ; then
	GetTlsHostPort "$TARGET_HOST:$TARGET_PORT"
	exit 0
fi

makeString "-" "newline"; makeString "-"; makeString "-"; makeString "-"
makeString " Listen Socket " "newline"
makeString " Test Socket "
makeString " PID/Program "
makeString " Certification Information ($(date +%Z\ %z)) "
makeString "-" "newline"; makeString "-"; makeString "-"; makeString "-"

if [ "$PG_NETSTAT" != "" ] ; then
	pplist=$($PG_NETSTAT -nap 2>/dev/null |grep ^tcp |grep LISTEN|sort -n)
else
	pplist=$($PG_SS -nap 2>/dev/null |grep ^tcp |grep LISTEN|sort -n)
fi
pparray=()
cnt=0
while read -r pp
do
	cnt=$((cnt+1))
	pparray[cnt]=$pp
done <<< "$pplist"

report_array=()
cnt=0
for i in $(seq 1 ${#pparray[@]})
do
	IFS=' ' read -r -a _array <<< "${pparray[$i]}"

	if [ "$PG_NETSTAT" != "" ] ; then
		str_ip=$(echo "${_array[3]}" | awk -F: '{print substr($0,0,length($0)-length($NF)-1)}')
		str_port=$(echo "${_array[3]}" | awk -F: '{print $NF}')
		if [ "${_array[0]}" == "tcp" ] && [ "$str_ip" == "0.0.0.0" ] ; then
			str_addr="127.0.0.1:$str_port"
		elif [ "$str_ip" == "::" ] || [ "$str_ip" == "::1" ] ; then
			str_addr="[::1]:$str_port"
		elif [ "${_array[0]}" == "tcp6" ] ; then
			str_addr="[$str_ip]:$str_port"
		else
			str_addr="$str_ip:$str_port"
		fi
		str_local=${_array[3]}
		str_pid=${_array[6]}
	else
		str_ip=$(echo "${_array[4]}" | awk -F: '{print substr($0,0,length($0)-length($NF)-1)}')
		str_port=$(echo "${_array[4]}" | awk -F: '{print $NF}')
		if [ "$str_ip" == "*" ] ; then
			str_addr="127.0.0.1:$str_port"
		elif [ "$str_ip" == "[::]" ] ; then
			str_addr="[::1]:$str_port"
		else
			str_addr="$str_ip:$str_port"
		fi

		str_local=${_array[4]}
		str_pid=${_array[6]}
		if [[ ${#str_pid} -gt 40 ]] ; then str_pid="${str_pid:0:38}.."; fi
	fi

	str=$($PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "$str_addr" 2>/dev/null | $PG_OPENSSL x509 -dates -noout 2>/dev/null)
	if [ "$str" == "" ] ; then
		if [ "$FLAG_REPORT" == "1" ] ; then continue; fi
		pstr=
	else
		pstr=$(echo "$str" | sed 's/notBefore=//g' | sed 's/notAfter=/ ~ /g' |tr -d '\n')
		pstr1=$(date --date="${pstr:0:24}" +%Y-%m-%d\ %H:%M:%S)
		pstr2=$(date --date="${pstr:27:24}" +%Y-%m-%d\ %H:%M:%S)
		if [ "$FLAG_ANSI" == "1" ] ; then
			pstr="$(tput setaf 1)$pstr1 ~ $pstr2$(tput sgr0)"
		else
			pstr="$pstr1 ~ $pstr2"
		fi
		cnt=$((cnt+1))
		report_array[cnt]=$str_addr
	fi

	#makeString " ${_array[3]} " "newline"
	makeString " $str_local " "newline"
	makeString " $str_addr "
	makeString " $str_pid "
	makeString " $pstr "

	if [ "$pstr" != "" ] ; then
		str=$($PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "$str_addr" 2>/dev/null | $PG_OPENSSL x509 -issuer -noout 2>/dev/null)
		pstr1=${str//issuer=/ }
		if [ "$pstr1" != "" ] ; then
			if [ "$FLAG_ANSI" == "1" ] ; then
				makeString " >>>$(tput setaf 2)$pstr1$(tput sgr0)"
			else
				makeString " >>>$pstr1"
			fi
		fi
	fi
done

makeString "-" "newline"; makeString "-"; makeString "-"; makeString "-"
printString

for i in $(seq 1 ${#report_array[@]})
do
	echo ""
	GetTlsHostPort "${report_array[$i]}"
done

exit 0
