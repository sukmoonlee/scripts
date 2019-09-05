#!/bin/bash
################################################################################
## Certfication Report Script
## 2019.02 created by CoreSolution (smlee@sk.com)
################################################################################
SCRIPT_VERSION="20190307"
LANG=en_US.UTF-8
HOSTNAME=$(hostname)
FLAG_PROGRAM=0
FLAG_SOCKET=1
FLAG_ALL=0
OPT_DIR="/etc"

if [ -f "/usr/bin/readlink" ] ; then
	SCRIPT=$(/usr/bin/readlink -f "$0")
	SCRIPTPATH=$(/usr/bin/dirname "$SCRIPT")
	cd "$SCRIPTPATH"
else
	SCRIPTPATH=$(/usr/bin/dirname "$0")
	cd "$SCRIPTPATH"
fi

if [ "$UID" != "0" ] ; then
	echo "Error - Need a root"
	exit 1
fi
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
	-s|--start)
		shift
		OPT_DIR=$1
		shift
		;;
	--program)
		FLAG_PROGRAM="1"
		shift
		;;
	--all)
		FLAG_ALL="1"
		shift
		;;
	--socket)
		FLAG_SOCKET="1"
		shift
		;;
	 *)
		echo "Unknown Option"
		exit 1
		;;
esac
done
################################################################################
FLAG_ECHO=1
if [ -f "/etc/wrs-release" ] ; then FLAG_ECHO=0; fi
if [ -f "/etc/init.d/functions" ]; then
	. /etc/init.d/functions
	if [ "$BOOTUP" = "serial" ] ; then FLAG_ECHO=0; fi
fi
function skt_echo_success()
{
	local str1=$1
	if [[ ${#str1} -gt 55 ]] ; then str1=${str1:0:55}; fi
	if [ "$FLAG_ECHO" == 1 ] && [ "$(type -t echo_success)" = function  ] ; then echo_success; echo "$str1"; return; fi
	echo -ne "                                                            [  OK  ]\r"
	echo "$str1"
}
function skt_echo_passed()
{
	local str1=$1
	if [[ ${#str1} -gt 55 ]] ; then str1=${str1:0:55}; fi
	if [ "$FLAG_ECHO" == 1 ] && [ "$(type -t echo_passed)" = function  ] ; then set +e; echo_passed; echo "$str1"; set -e; return; fi
	echo -ne "                                                            [PASSED]\r"
	echo "$str1"
}
function skt_echo_failure()
{
	local str1=$1
	if [[ ${#str1} -gt 55 ]] ; then str1=${str1:0:55}; fi
	if [ "$FLAG_ECHO" == 1 ] && [ "$(type -t echo_failure)" = function  ] ; then set +e; echo_failure; echo "$str1"; set -e; return; fi
	echo -ne "                                                            [ FAIL ]\r"
	echo "$str1"
}
function skt_echo_warning()
{
	local str1=$1
	if [[ ${#str1} -gt 55 ]] ; then str1=${str1:0:55}; fi
	if [ "$FLAG_ECHO" == 1 ] && [ "$(type -t echo_warning)" = function  ] ; then set +e; echo_warning; echo "$str1"; set -e; return; fi
	echo -ne "                                                            [WARNING]\r"
	echo "$str1"
}
function skt_echo()
{
	local str1=$1
	local str2=$2

	printf " %-25s %s\n" "$str1" "$str2"
}
################################################################################
echo " Certification Report ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo " "

./cert_socket_chk.sh > socket.txt 2>/dev/null
if [ "$?" != "0" ] ; then
	skt_echo_failure "cert_socket_chk.sh"
	cat socket.txt
	exit 1
fi
skt_echo_success "cert_socket_chk.sh"

./cert_program_chk.sh socket.txt > program.txt 2>/dev/null
if [ "$?" != "0" ] ; then
	skt_echo_failure "cert_program_chk.sh"
	cat program.txt
	exit 1
fi
skt_echo_success "cert_program_chk.sh"

./cert_file_chk.sh -s "$OPT_DIR" > file.txt 2>/dev/null
if [ "$?" != "0" ] ; then
	skt_echo_failure "cert_file_chk.sh"
	cat file.txt
	exit 1
fi
skt_echo_success "cert_file_chk.sh"

echo " "

set +e
if [ "$FLAG_SOCKET" == "1" ] ; then
	perl ./cert_report_socket.pl
	if [ "$?" == "127" ] ; then FLAG_ALL=1; fi
fi
if [ "$FLAG_PROGRAM" == "1" ] ; then
	perl ./cert_report.pl
	if [ "$?" == "127" ] ; then FLAG_ALL=1; fi
fi
set -e

if [ "$FLAG_ALL" == "1" ] ; then
	echo ""
	echo "# cat socket.txt"
	cat socket.txt
	echo ""
	echo "# cat program.txt"
	cat program.txt
	echo ""
	echo "# cat file.txt"
	cat file.txt
fi

if [ -f "/usr/bin/rm" ] ; then /usr/bin/rm -f program.txt socket.txt file.txt;
elif [ -f "/bin/rm" ] ; then /bin/rm -f program.txt socket.txt file.txt; fi

exit 0
