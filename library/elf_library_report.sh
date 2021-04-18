#!/bin/bash
################################################################################
## ELF Library Report Script
## 2020.11 created by smlee@sk.com
################################################################################
SCRIPT_VERSION="20201230"
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
HOSTNAME=$(hostname)

PROGRAM_PID=""
FLAG_ALL=0
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
	-a|--all)
		FLAG_ALL=1
		shift 1
		;;
	*)
		if [ "$PROGRAM_PID" != "" ] ; then
			echo "unknown option: $1"
			exit 1
		fi
		PROGRAM_PID="$1"
		shift 1
		;;
esac
done
if [ "$PROGRAM_PID" == "" ] ; then
	echo "Usage: $0 [-v] [-d] [-a] [pid]"
	exit 1
fi
PROGRAM_FILE=$(lsof -np "$PROGRAM_PID" |grep " txt "|awk '{print $9} '|awk -F\; '{print $1}')
if [ "$PROGRAM_FILE" == "" ] ; then
	echo "'$PROGRAM_PID' process is not found."
	echo "Usage: $0 [-v] [-d] [-a] [pid]"
	exit 1
fi
################################################################################
function StringCat
{
	local name="$1"
	local len="$2"
	local align="$3"

	local len_name=${#name}
	local cnt_space=$((len-len_name))
	local RST="| $name"

	if [ "$align" == "right" ] ; then
		RST="|"
	fi

	for ((i=0; i<cnt_space+1; i++))
	do
		RST="$RST "
	done

	if [ "$align" == "right" ] ; then
		RST="$RST$name "
	fi

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
function GetFileDate
{
	local file="$1"
	if [ ! -f "$file" ] ; then
		echo "-"
	else
		local fdate
		# shellcheck disable=SC2012
		fdate=$(ls --full-time "$file" |awk '{print $6,substr($7,0,8)}')
		echo "$fdate"
	fi
}
function GetFileSize
{
	local file="$1"
	if [ ! -f "$file" ] ; then
		echo "-"
	else
		local fsize
		# shellcheck disable=SC2012
		fsize=$(ls --full-time "$file" |awk '{print $5}')
		echo "$fsize"
	fi
}
function GetFileMd5
{
	local file="$1"
	if [ ! -f "$file" ] ; then
		echo "-"
	else
		local fmd5
		fmd5=$(rpm -qf "$file" |awk '{print $1}')
		if [ "$fmd5" == "file" ] ; then
			local fn_date=
			fn_date=$(GetFileDate "$file")
			fmd5=$(md5sum "$file" |awk '{print $1}')
			fmd5="($fn_date) $fmd5"
		else
			local rpmname=
			rpmname=$(rpm -q --qf "%{buildtime}" "$fmd5" |awk '{print strftime("(%Y-%m-%d)",$1)a}')
			fmd5="$rpmname $fmd5"
		fi
		echo "$fmd5"
	fi
}
function GetFileCheck
{
	local file="$1"
	local ftype=
	ftype=$(file "$file" |egrep -c "ELF|Zip archive")
	echo "$ftype"
}
################################################################################
osVer=$(uname -r |awk -F\. '{print $(NF-1)}')
if [ "${osVer:0:2}" != "el" ] ; then osVer=$(uname -r |awk -F\. '{print $NF}'); fi
if [ "${#osVer}" != 3 ] ; then osVer=${osVer:0:3}; fi

echo " ELF Report Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION, $osVer)"
echo ""

LEN_FILE=8
LEN_SIZE=4
LEN_MD5=6
while IFS=" " read -r FN_LIB
do
	FN_TYPE=$(GetFileCheck "$FN_LIB")
	if [ "$FN_TYPE" == "0" ] ; then continue; fi

	FN_SIZE=$(GetFileSize "$FN_LIB")
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	if [ ${#FN_LIB} -gt "$LEN_FILE" ] ; then LEN_FILE=${#FN_LIB}; fi
	if [ ${#FN_SIZE} -gt "$LEN_SIZE" ] ; then LEN_SIZE=${#FN_SIZE}; fi
	if [ ${#FN_MD5} -gt "$LEN_MD5" ] ; then LEN_MD5=${#FN_MD5}; fi
done < <(lsof -np "$PROGRAM_PID" |grep ' mem ' |grep ' REG' |awk '{if (NF==9) print $9}'|awk -F\; '{print $1}')

while IFS=" " read -r FN_LIB
do
	FN_SIZE=$(GetFileSize "$FN_LIB")
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	if [ ${#FN_LIB} -gt "$LEN_FILE" ] ; then LEN_FILE=${#FN_LIB}; fi
	if [ ${#FN_SIZE} -gt "$LEN_SIZE" ] ; then LEN_SIZE=${#FN_SIZE}; fi
	if [ ${#FN_MD5} -gt "$LEN_MD5" ] ; then LEN_MD5=${#FN_MD5}; fi
done < <(lsof -np "$PROGRAM_PID" |egrep ' DEL ' |grep ' REG' |awk '{if (NF==8) print $8}'| awk -F\; '{print $1}')

FN_LIB="$PROGRAM_FILE"
FN_SIZE=$(GetFileSize "$FN_LIB")
FN_MD5=$(GetFileMd5 "$FN_LIB")

if [ $((${#FN_LIB}+4)) -gt "$LEN_FILE" ] ; then LEN_FILE=$((${#FN_LIB}+4)); fi
if [ ${#FN_SIZE} -gt "$LEN_SIZE" ] ; then LEN_SIZE=${#FN_SIZE}; fi
if [ ${#FN_MD5} -gt "$LEN_MD5" ] ; then LEN_MD5=${#FN_MD5}; fi

line=$(StringLine "" "$LEN_FILE")
line=$line$(StringLine "" "$LEN_SIZE")
line=$line$(StringLine "" "$LEN_MD5")
echo "$line+"
line=$(StringCat "Filename" "$LEN_FILE")
line=$line$(StringCat "Size" "$LEN_SIZE")
line=$line$(StringCat "(Date) RPM/Digest(md5)" "$LEN_MD5")
echo "$line|"
line=$(StringLine "" "$LEN_FILE")
line=$line$(StringLine "" "$LEN_SIZE")
line=$line$(StringLine "" "$LEN_MD5")
echo "$line+"

FN_LIB=$PROGRAM_FILE
FN_SIZE=$(GetFileSize "$FN_LIB")
FN_MD5=$(GetFileMd5 "$FN_LIB")

line=$(StringCat "$FN_LIB (*)" "$LEN_FILE")
line=$line$(StringCat "$FN_SIZE" "$LEN_SIZE" "right")
line=$line$(StringCat "$FN_MD5" "$LEN_MD5")
echo "$line|"

while IFS=" " read -r FN_LIB
do
	FN_TYPE=$(GetFileCheck "$FN_LIB")
	if [ "$FN_TYPE" == "0" ] ; then continue; fi

	FN_SIZE=$(GetFileSize "$FN_LIB")
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	line=$(StringCat "$FN_LIB" "$LEN_FILE")
	line=$line$(StringCat "$FN_SIZE" "$LEN_SIZE" "right")
	line=$line$(StringCat "$FN_MD5" "$LEN_MD5")
	echo "$line|"
done < <(lsof -np "$PROGRAM_PID" |grep ' mem ' |grep ' REG' |awk '{if (NF==9) print $9}'|awk -F\; '{print $1}'|sort)

while IFS=" " read -r FN_LIB
do
	FN_SIZE=$(GetFileSize "$FN_LIB")
	if [ "$FN_SIZE" == "-" ] ; then continue; fi
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	line=$(StringCat "$FN_LIB" "$LEN_FILE")
	line=$line$(StringCat "$FN_SIZE" "$LEN_SIZE" "right")
	line=$line$(StringCat "$FN_MD5" "$LEN_MD5")
	echo "$line|"
done < <(lsof -np "$PROGRAM_PID" |grep ' DEL ' |grep " REG" |awk '{if (NF==8) print $8}'|awk -F\; '{print $1}'|sort)

line=$(StringLine "" "$LEN_FILE")
line=$line$(StringLine "" "$LEN_SIZE")
line=$line$(StringLine "" "$LEN_MD5")
echo "$line+"

if [ "$FLAG_ALL" == "1" ] ; then
	echo ""
	echo "# echo \$LD_LIBRARY_PATH"
	echo "$LD_LIBRARY_PATH"
fi
if [ "$FLAG_ALL" == "1" ] && [ -f "/usr/sbin/ldconfig" ] ; then
	echo ""
	echo "# ldconfig -p"
	/usr/sbin/ldconfig -p
fi
if [ "$FLAG_ALL" == "1" ] && [ -f "/usr/bin/readelf" ] ; then
	echo ""
	echo "# readelf -a '$PROGRAM_FILE'"
	/usr/bin/readelf -a "$PROGRAM_FILE"
fi

exit 0
