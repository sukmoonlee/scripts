#!/bin/bash
################################################################################
## Program Library Report Script
## 2019.02 created by CoreSolution (smlee@sk.com)
################################################################################
SCRIPT_VERSION="20191211"
LANG=en_US.UTF-8
HOSTNAME=$(hostname)

if [ -f "/bin/readlink" ] ; then PG_readlink="/bin/readlink"
elif [ -f "/usr/bin/readlink" ] ; then PG_readlink="/usr/bin/readlink"
else echo "Error - Command not found 'readlink'"; exit 1; fi

if [ -f "/bin/ldd" ] ; then PG_ldd="/bin/ldd"
elif [ -f "/usr/bin/ldd" ] ; then PG_ldd="/usr/bin/ldd"
else echo "Error - Command not found 'ldd'"; exit 1; fi

if [ -f "/bin/md5sum" ] ; then PG_md5sum="/bin/md5sum"
elif [ -f "/usr/bin/md5sum" ] ; then PG_md5sum="/usr/bin/md5sum"
else echo "Error - Command not found 'md5sum'"; exit 1; fi

if [ -f "/bin/ls" ] ; then PG_ls="/bin/ls"
elif [ -f "/usr/bin/ls" ] ; then PG_ls="/usr/bin/ls"
else echo "Error - Command not found 'ls'"; exit 1; fi
################################################################################
PROGRAM_FILE=""
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
		PROGRAM_FILE="$1"
		shift 1
		;;
esac
done
if [ "$PROGRAM_FILE" == "" ] ; then
	echo "Usage: $0 [filename]"
	exit 0
fi
if [ ! -f "$PROGRAM_FILE" ] ; then
	echo "'$PROGRAM_FILE' is not found."
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
################################################################################
set -e

echo " Program Library Report Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"

LEN_FILE=8
LEN_SIZE=4
LEN_DATE=4
LEN_MD5=6
LEN_LINK=11
while IFS=" " read -r a b c d
do
	#echo "$a , $b , $c , $d"
	if [ "$b" == "=>" ] ; then
		if [ "$c" == "not" ] ; then
			FN_LIB=$(echo "$a"| xargs)
			if [ ${#FN_LIB} -gt "$LEN_FILE" ] ; then LEN_FILE=${#FN_LIB}; fi
			continue;
		fi
		if [ "${c:0:1}" == "(" ] ; then
			#echo "(case 1) $a , $b , $c , $d"
			continue
		else
			#echo "(case 2) $a , $b , $c , $d"
			FN_LIB=$c
		fi
	else
		#echo "(case 3) $a , $b , $c , $d"
		FN_LIB=$(echo "$a"| xargs)
	fi

	#echo "$FN_LIB"
	if [ -L "$FN_LIB" ] ; then
		if [ ${#FN_LIB} -gt $LEN_LINK ] ; then LEN_LINK=${#FN_LIB}; fi
		FN_LIB=$($PG_readlink -f "$FN_LIB")
	fi

	FN_SIZE=$(GetFileSize "$FN_LIB")
	FN_DATE=$(GetFileDate "$FN_LIB")
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	if [ ${#FN_LIB} -gt "$LEN_FILE" ] ; then LEN_FILE=${#FN_LIB}; fi
	if [ ${#FN_SIZE} -gt "$LEN_SIZE" ] ; then LEN_SIZE=${#FN_SIZE}; fi
	if [ ${#FN_DATE} -gt "$LEN_DATE" ] ; then LEN_DATE=${#FN_DATE}; fi
	if [ ${#FN_MD5} -gt "$LEN_MD5" ] ; then LEN_MD5=${#FN_MD5}; fi
done < <($PG_ldd "$PROGRAM_FILE")

FN_LIB="$PROGRAM_FILE"
if [ -L "$FN_LIB" ] ; then
	if [ ${#FN_LIB} -gt "$LEN_LINK" ] ; then LEN_LINK=${#FN_LIB}; fi
	FN_LIB=$($PG_readlink -f "$FN_LIB")
fi

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
line=$line$(StringLine "" "$LEN_LINK")
echo "$line+";
line=$(StringCat "Filename" "$LEN_FILE")
line=$line$(StringCat "Size" "$LEN_SIZE")
line=$line$(StringCat "Date" "$LEN_DATE")
line=$line$(StringCat "Digest" "$LEN_MD5")
line=$line$(StringCat "Link Symbol" "$LEN_LINK")
echo "$line|";
line=$(StringLine "" "$LEN_FILE")
line=$line$(StringLine "" "$LEN_SIZE")
line=$line$(StringLine "" "$LEN_DATE")
line=$line$(StringLine "" "$LEN_MD5")
line=$line$(StringLine "" "$LEN_LINK")
echo "$line+";

FN_LIB=$PROGRAM_FILE
if [ -L "$FN_LIB" ] ; then
	FN_LINK=$FN_LIB
	FN_LIB=$($PG_readlink -f "$FN_LIB")
else
	FN_LINK=""
fi

FN_SIZE=$(GetFileSize "$FN_LIB")
FN_DATE=$(GetFileDate "$FN_LIB")
FN_MD5=$(GetFileMd5 "$FN_LIB")

line=$(StringCat "$FN_LIB (*)" "$LEN_FILE")
line=$line$(StringCat "$FN_SIZE" "$LEN_SIZE" "right")
line=$line$(StringCat "$FN_DATE" "$LEN_DATE")
line=$line$(StringCat "$FN_MD5" "$LEN_MD5")
line=$line$(StringCat "$FN_LINK" "$LEN_LINK")
echo "$line|";

# shellcheck disable=SC2034
while IFS=" " read -r a b c d
do
	if [ "$b" == "=>" ] ; then
		if [ "$c" == "not" ] ; then
			FN_LIB=$(echo "$a"| xargs)
			FN_SIZE="-"
			FN_DATE="-"
			FN_MD5="-"
			FN_LINK="-"

			line=$(StringCat "$FN_LIB" "$LEN_FILE")
			line=$line$(StringCat "$FN_SIZE" "$LEN_SIZE" "right")
			line=$line$(StringCat "$FN_DATE" "$LEN_DATE")
			line=$line$(StringCat "$FN_MD5" "$LEN_MD5")
			line=$line$(StringCat "$FN_LINK" "$LEN_LINK")
			echo "$line|";

			continue;
		fi
		if [ "${c:0:1}" == "(" ] ; then
			continue
		else
			FN_LIB=$c
		fi
	else
		FN_LIB=$(echo "$a"| xargs)
	fi

	if [ -L "$FN_LIB" ] ; then
		FN_LINK=$FN_LIB
		FN_LIB=$($PG_readlink -f "$FN_LIB")
	else
		FN_LINK=""
	fi

	FN_SIZE=$(GetFileSize "$FN_LIB")
	FN_DATE=$(GetFileDate "$FN_LIB")
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	line=$(StringCat "$FN_LIB" "$LEN_FILE")
	line=$line$(StringCat "$FN_SIZE" "$LEN_SIZE" "right")
	line=$line$(StringCat "$FN_DATE" "$LEN_DATE")
	line=$line$(StringCat "$FN_MD5" "$LEN_MD5")
	line=$line$(StringCat "$FN_LINK" "$LEN_LINK")
	echo "$line|";
done < <($PG_ldd "$PROGRAM_FILE"|sort)

line=$(StringLine "" "$LEN_FILE")
line=$line$(StringLine "" "$LEN_SIZE")
line=$line$(StringLine "" "$LEN_DATE")
line=$line$(StringLine "" "$LEN_MD5")
line=$line$(StringLine "" "$LEN_LINK")
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
