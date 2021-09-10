#!/bin/bash
################################################################################
## Socket Certfication 추출 스크립트
## 2019.01 created by CoreSolution (khkang@sk.com)
## 2019.02.12 FIX. using 'rm' instead of 'unlink' to DELETE
## 2019.02.13 FIX. don't exit even if CERT has no CN
## 2019.02.13 FIX. netstat on CentOS6 has no tcp6 in proto (address translation combined)
################################################################################
SCRIPT_VERSION="20210825"
LANG=en_US.UTF-8
HOSTNAME=$(hostname)
OS=$(uname -s)

if [ -f "/bin/netstat" ] ; then PG_NETSTAT="/bin/netstat"
elif [ -f "/usr/bin/netstat" ] ; then PG_NETSTAT="/usr/bin/netstat"
else echo "Error - Command not found 'netstat'"; exit 1; fi
if [ -f "/usr/bin/ggrep" ] ; then PG_GREP="/usr/bin/ggrep"
elif [ -f "/usr/sfw/bin/ggrep" ] ; then PG_GREP="/usr/sfw/bin/ggrep"
elif [ -f "/usr/bin/grep" ] ; then PG_GREP="/usr/bin/grep"
elif [ -f "/bin/grep" ] ; then PG_GREP="/bin/grep"
else echo "Error - Command not found 'grep'"; exit 1; fi
if [ -f "/bin/rm" ] ; then PG_DELETE="/bin/rm"
elif [ -f "/usr/bin/rm" ] ; then PG_DELETE="/usr/bin/rm"
else echo "Error - Command not found 'rm'"; exit 1; fi
if [ -f "/usr/bin/openssl" ] ; then PG_OPENSSL="/usr/bin/openssl"
elif [ -f "/usr/local/bin/openssl" ] ; then PG_OPENSSL="/usr/local/bin/openssl"
else echo "Error - Command not found 'openssl'"; exit 1; fi
if [ -f "/bin/timeout" ] ; then PG_TIMEOUT="/bin/timeout"
elif [ -f "/usr/bin/timeout" ] ; then PG_TIMEOUT="/usr/bin/timeout"
elif [ -f "/usr/share/doc/bash-3.2/scripts/timeout" ] ; then PG_TIMEOUT="bash /usr/share/doc/bash-3.2/scripts/timeout"
else echo "Error - Command not found 'timeout'"; exit 1; fi
#else PG_TIMEOUT=; fi
################################################################################
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
		echo "Unknown Option"
		exit 1
		;;
esac
done
################################################################################
echo " Certification Socket Check Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo " "

TCPLISTSOCK=()
TCPDESTADDR=()
if [ "$OS" == "SunOS" ] ; then
	TCPLISTEN=$($PG_NETSTAT -na -P tcp | $PG_GREP -i "LISTEN" | awk '{print $1}')
else
	TCPLISTEN=$($PG_NETSTAT -nlt | $PG_GREP -i "^tcp" | awk '{print $4}')
fi

for TCPDEST in $TCPLISTEN
do
	if [ "$OS" == "SunOS" ] ; then
		PORT=$(echo "$TCPDEST" | awk -F'.' '{print $NF}')
		# shellcheck disable=SC2001
		ADDR=$(echo "$TCPDEST" | sed "s/\.${PORT}$//g")
	else
		PORT=$(echo "$TCPDEST" | awk -F':' '{print $NF}')
		# shellcheck disable=SC2001
		ADDR=$(echo "$TCPDEST" | sed "s/:${PORT}$//g")
	fi
	if [[ $ADDR == *":"* ]]; then
		if [ "$ADDR" == "::" ] ; then
			ADDR="::1"
		fi
		ADDR="[${ADDR}]"
	elif [ "$ADDR" == "0.0.0.0" ] ; then
		ADDR="127.0.0.1"
	elif [ "$ADDR" == "*" ] ; then
		ADDR="127.0.0.1"
	fi
	TCPLISTSOCK+=("${TCPDEST}")
	TCPDESTADDR+=("${ADDR}:${PORT}")
done

TMPFILE="/tmp/$0.txt"
if [ -f "$TMPFILE" ] ; then
	$PG_DELETE -f "$TMPFILE"
	if [ "$?" != "0" ] ; then
		echo "Error - $PG_DELETE '$TMPFILE'"
		exit 1
	fi
fi
touch "$TMPFILE"
if [ ! -f "$TMPFILE" ]; then
	echo "Error - Can not create temporary file ${TMPFILE}"
	exit 1
fi
################################################################################
function PrintCertInfo
{
	if [ -z "$PG_TIMEOUT" ] ; then
		$PG_OPENSSL s_client -connect "$1" 2>/dev/null | $PG_OPENSSL x509 -issuer -dates -fingerprint -noout | sed 's/^/    /g'
	else
		$PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "$1" 2>/dev/null | $PG_OPENSSL x509 -issuer -dates -fingerprint -noout | sed 's/^/    /g'
	fi
}
function GetCertDigest
{
	if [ -z "$PG_TIMEOUT" ] ; then
		str=$($PG_OPENSSL s_client -connect "$1" 2>/dev/null | $PG_OPENSSL x509 -text -outform pem |md5sum |awk '{print $1}')
	else
		str=$($PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "$1" 2>/dev/null | $PG_OPENSSL x509 -text -outform pem |md5sum |awk '{print $1}')
	fi
	echo "$str"
}
function GetCertPid
{
	local str=

	if [ "$OS" == "SunOS" ] ; then
		str=$(sudo $PG_NETSTAT -nua -P tcp |$PG_GREP LISTEN |$PG_GREP "$1 " | awk '{print $4}'|awk 'BEGIN { FS="/" } {print $1}')
	else
		str=$(sudo $PG_NETSTAT -nap |$PG_GREP LISTEN |$PG_GREP "$1 " | awk '{print $7}'|awk 'BEGIN { FS="/" } {print $1}')
	fi
	echo "$str"
}
################################################################################
NR=${#TCPDESTADDR[*]}
for ((i=0;i<NR;i++))
do
	if [ -z "$PG_TIMEOUT" ] ; then
		$PG_OPENSSL s_client -connect "${TCPDESTADDR[$i]}" -showcerts &> "$TMPFILE" &
		OPENSSLPID=$!
		#ps -ef |grep "$OPENSSLPID"
		sleep  5

		PIDCNT=$(pidof $PG_OPENSSL)
		for pidline in $PIDCNT
		do
			if [ "$pidline" == "$OPENSSLPID" ] ; then
				#echo "kill $OPENSSLPID"
				kill "$OPENSSLPID"
			 fi
		done
	else
		$PG_TIMEOUT 1 $PG_OPENSSL s_client -connect "${TCPDESTADDR[$i]}" -showcerts &> "$TMPFILE"
	fi
	if [ ! -s "$TMPFILE" ]; then continue; fi

	NOLINE=$(wc -l "$TMPFILE"|awk '{print $1}')
	if [ "$NOLINE" -lt 3 ] ; then continue; fi
	# openssl s_client exception : getservbyname failure for :]:443
	BADADDR=$(head -1 "$TMPFILE"| grep -ic 'getservbyname failure')
	if [ "$BADADDR" -gt 0 ] ; then
		if [[ "${TCPDESTADDR[$i]}" == "[::1]:"* ]]; then
			if [ "$(/usr/bin/getent hosts localhost6 | awk '{print $1}')" == "::1" ]; then
				NEWADDR=${TCPDESTADDR[$i]/'[::1]'/'localhost6'}
				#echo "Queue $NEWADDR for next process"
				TCPDESTADDR+=("${NEWADDR}")
				TCPLISTSOCK+=("${TCPLISTSOCK[$i]}")
				NR=$((NR+1))
			fi
		fi
		continue
	fi
	NOSUPP=$($PG_GREP -ic ":ssl handshake failure:" "$TMPFILE")
	if [ "$NOSUPP" -ge 1 ] ; then continue; fi
	NOPROTO=$($PG_GREP -ic "^unknown protocol" "$TMPFILE")
	NOCERT=$($PG_GREP -ic "^no peer certificate available" "$TMPFILE")
	CERTCN=$($PG_GREP -i -A2 "^Server certificate" "$TMPFILE" | $PG_GREP -i "^subject=" | sed "s/\//\n/g" | awk -F'=' '$1 == "CN" {print $2}')
	#SELFSIGN=$($PG_GREP -ic "self signed certificate" "$TMPFILE")
	VERSION=$($PG_GREP -i -A3 "^SSL-Session:" "$TMPFILE" | $PG_GREP "Protocol" | awk -F':' '{print $2}')
	CIPHER=$($PG_GREP -i -A3 "^SSL-Session:" "$TMPFILE" | $PG_GREP "Cipher" | awk -F':' '{print $2}')

	RES="${TCPDESTADDR[$i]} for ${TCPLISTSOCK[$i]}"
	if [ "$NOPROTO" == "0" -a "$NOCERT" == "0" ] ; then
		RES="${RES} has"
		#if [ "$SELFSIGN" == "0" ]; then
		#    RES="${RES} public"
		#else
		#    RES="${RES} private"
		#fi
		if [ "$CERTCN" == "" ]; then
			RES="${RES} certificate"
		else
			RES="${RES} certificate for \"${CERTCN}\""
		fi
		if [ "$VERSION" != "" ]; then
			RES="${RES} $VERSION"
		fi
		if [ "$CIPHER" != "" -a "$CIPHER" != "0000" ]; then
			RES="${RES} $CIPHER"
		fi

		if [ ! -z "$PG_TIMEOUT" ] ; then
			ssl_digest=$(GetCertDigest "${TCPDESTADDR[$i]}")
		else
			ssl_digest=
		fi
		ssl_pid=$(GetCertPid "${TCPLISTSOCK[$i]}")
		echo "port ${TCPLISTSOCK[$i]} pid $ssl_pid md5sum $ssl_digest / $RES"
		if [ ! -z "$PG_TIMEOUT" ] ; then
			PrintCertInfo "${TCPDESTADDR[$i]}"
		fi
	fi
done

if [ -f "$TMPFILE" ] ; then $PG_DELETE -f "$TMPFILE"; fi
exit 0
