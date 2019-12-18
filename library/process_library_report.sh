#!/bin/bash
################################################################################
## Process Library Report Script
## 2019.02 created by CoreSolution (smlee@sk.com)
################################################################################
SCRIPT_VERSION="20191211"
LANG=en_US.UTF-8
HOSTNAME=$(hostname)

if [ -f "/sbin/lsof" ] ; then PG_lsof="/sbin/lsof"
elif [ -f "/usr/sbin/lsof" ] ; then PG_lsof="/usr/sbin/lsof"
elif [ -f "/usr/bin/lsof" ] ; then PG_lsof="/usr/bin/lsof"
else echo "Error - Command not found 'lsof'"; exit 1; fi

if [ -f "/bin/md5sum" ] ; then PG_md5sum="/bin/md5sum"
elif [ -f "/usr/bin/md5sum" ] ; then PG_md5sum="/usr/bin/md5sum"
else echo "Error - Command not found 'md5sum'"; exit 1; fi

if [ -f "/bin/ls" ] ; then PG_ls="/bin/ls"
elif [ -f "/usr/bin/ls" ] ; then PG_ls="/usr/bin/ls"
else echo "Error - Command not found 'ls'"; exit 1; fi

if [ -f "/usr/bin/file" ] ; then PG_file="/usr/bin/file"
elif [ -f "/bin/file" ] ; then PG_file="/bin/file"
else echo "Error - Command not found 'file'"; exit 1; fi
################################################################################
PROGRAM_PID=""
FLAG_ALL=0
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
	-a|--all)
		FLAG_ALL=1
		shift 1
		;;
	 *)
		PROGRAM_PID="$1"
		shift 1
		;;
esac
done
if [ "$PROGRAM_PID" == "" ] ; then
	echo "Usage: $0 [pid]"
	exit 0
fi
PROGRAM_FILE=$($PG_lsof -np "$PROGRAM_PID" |grep " txt "|awk '{print $9} '|awk -F\; '{print $1}')
if [ "$PROGRAM_FILE" == "" ] ; then
	echo "'$PROGRAM_PID' process is not found."
	echo "Usage: $0 [pid]"
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
function GetFileDate
{
	local file="$1"
	if [ ! -f "$file" ] ; then
		echo "-";
	else
		local fdate
		fdate=$($PG_ls --full-time "$file" |awk '{print $6,substr($7,0,8)}')
		echo "$fdate"
	fi
}
function GetFileSize
{
	local file="$1"
	if [ ! -f "$file" ] ; then
		echo "-";
	else
		local fsize
		fsize=$($PG_ls --full-time "$file" |awk '{print $5}')
		echo "$fsize"
	fi
}
function GetFileMd5
{
	local file="$1"
	if [ ! -f "$file" ] ; then
		echo "-";
	else
		local fmd5
		fmd5=$($PG_md5sum "$file" |awk '{print $1}')
		echo "$fmd5"
	fi
}
function GetFileCheck
{
	local file="$1"
	local ftype
	ftype=$($PG_file "$file" |egrep -c "ELF|Zip archive")
	echo "$ftype"
}
################################################################################
set -e

echo " Process Library Report Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"

LEN_FILE=8
LEN_SIZE=4
LEN_DATE=4
LEN_MD5=6
while IFS=" " read -r FN_LIB
do
	FN_TYPE=$(GetFileCheck "$FN_LIB")
	if [ "$FN_TYPE" == "0" ] ; then continue; fi

	FN_SIZE=$(GetFileSize "$FN_LIB")
	FN_DATE=$(GetFileDate "$FN_LIB")
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	if [ ${#FN_LIB} -gt "$LEN_FILE" ] ; then LEN_FILE=${#FN_LIB}; fi
	if [ ${#FN_SIZE} -gt "$LEN_SIZE" ] ; then LEN_SIZE=${#FN_SIZE}; fi
	if [ ${#FN_DATE} -gt "$LEN_DATE" ] ; then LEN_DATE=${#FN_DATE}; fi
	if [ ${#FN_MD5} -gt "$LEN_MD5" ] ; then LEN_MD5=${#FN_MD5}; fi
done < <($PG_lsof -np "$PROGRAM_PID" |grep ' mem ' |grep ' REG' |awk '{if (NF==9) print $9}'|awk -F\; '{print $1}')

while IFS=" " read -r FN_LIB
do
	#FN_TYPE=$(GetFileCheck "$FN_LIB")
	#if [ "$FN_TYPE" == "0" ] ; then continue; fi

	FN_SIZE=$(GetFileSize "$FN_LIB")
	FN_DATE=$(GetFileDate "$FN_LIB")
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	if [ ${#FN_LIB} -gt "$LEN_FILE" ] ; then LEN_FILE=${#FN_LIB}; fi
	if [ ${#FN_SIZE} -gt "$LEN_SIZE" ] ; then LEN_SIZE=${#FN_SIZE}; fi
	if [ ${#FN_DATE} -gt "$LEN_DATE" ] ; then LEN_DATE=${#FN_DATE}; fi
	if [ ${#FN_MD5} -gt "$LEN_MD5" ] ; then LEN_MD5=${#FN_MD5}; fi
done < <($PG_lsof -np "$PROGRAM_PID" |egrep ' DEL ' |grep ' REG' |awk '{if (NF==8) print $8}'| awk -F\; '{print $1}')

FN_LIB="$PROGRAM_FILE"
FN_SIZE=$(GetFileSize "$FN_LIB")
FN_DATE=$(GetFileDate "$FN_LIB")
FN_MD5=$(GetFileMd5 "$FN_LIB")

if [ $((${#FN_LIB}+4)) -gt "$LEN_FILE" ] ; then LEN_FILE=$((${#FN_LIB}+4)); fi
if [ ${#FN_SIZE} -gt "$LEN_SIZE" ] ; then LEN_SIZE=${#FN_SIZE}; fi
if [ ${#FN_DATE} -gt "$LEN_DATE" ] ; then LEN_DATE=${#FN_DATE}; fi
if [ ${#FN_MD5} -gt "$LEN_MD5" ] ; then LEN_MD5=${#FN_MD5}; fi

line=$(StringLine "" "$LEN_FILE")
line=$line$(StringLine "" "$LEN_SIZE")
line=$line$(StringLine "" "$LEN_DATE")
line=$line$(StringLine "" "$LEN_MD5")
echo "$line+";
line=$(StringCat "Filename" "$LEN_FILE")
line=$line$(StringCat "Size" "$LEN_SIZE")
line=$line$(StringCat "Date" "$LEN_DATE")
line=$line$(StringCat "Digest" "$LEN_MD5")
echo "$line|";
line=$(StringLine "" "$LEN_FILE")
line=$line$(StringLine "" "$LEN_SIZE")
line=$line$(StringLine "" "$LEN_DATE")
line=$line$(StringLine "" "$LEN_MD5")
echo "$line+";

FN_LIB=$PROGRAM_FILE
FN_SIZE=$(GetFileSize "$FN_LIB")
FN_DATE=$(GetFileDate "$FN_LIB")
FN_MD5=$(GetFileMd5 "$FN_LIB")

line=$(StringCat "$FN_LIB (*)" "$LEN_FILE")
line=$line$(StringCat "$FN_SIZE" "$LEN_SIZE" "right")
line=$line$(StringCat "$FN_DATE" "$LEN_DATE")
line=$line$(StringCat "$FN_MD5" "$LEN_MD5")
echo "$line|";

while IFS=" " read -r FN_LIB
do
	FN_TYPE=$(GetFileCheck "$FN_LIB")
	if [ "$FN_TYPE" == "0" ] ; then continue; fi

	FN_SIZE=$(GetFileSize "$FN_LIB")
	FN_DATE=$(GetFileDate "$FN_LIB")
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	line=$(StringCat "$FN_LIB" "$LEN_FILE")
	line=$line$(StringCat "$FN_SIZE" "$LEN_SIZE" "right")
	line=$line$(StringCat "$FN_DATE" "$LEN_DATE")
	line=$line$(StringCat "$FN_MD5" "$LEN_MD5")
	echo "$line|";
done < <($PG_lsof -np "$PROGRAM_PID" |grep ' mem ' |grep ' REG' |awk '{if (NF==9) print $9}'|awk -F\; '{print $1}'|sort)

while IFS=" " read -r FN_LIB
do
	#FN_TYPE=$(GetFileCheck "$FN_LIB")
	#if [ "$FN_TYPE" == "0" ] ; then continue; fi

	FN_SIZE=$(GetFileSize "$FN_LIB")
	FN_DATE=$(GetFileDate "$FN_LIB")
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	line=$(StringCat "$FN_LIB" "$LEN_FILE")
	line=$line$(StringCat "$FN_SIZE" "$LEN_SIZE" "right")
	line=$line$(StringCat "$FN_DATE" "$LEN_DATE")
	line=$line$(StringCat "$FN_MD5" "$LEN_MD5")
	echo "$line|";
done < <($PG_lsof -np "$PROGRAM_PID" |grep ' DEL ' |grep " REG" |awk '{if (NF==8) print $8}'|awk -F\; '{print $1}'|sort)

line=$(StringLine "" "$LEN_FILE")
line=$line$(StringLine "" "$LEN_SIZE")
line=$line$(StringLine "" "$LEN_DATE")
line=$line$(StringLine "" "$LEN_MD5")
echo "$line+";

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

exit 0
