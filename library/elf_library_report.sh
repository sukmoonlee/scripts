#!/bin/bash
################################################################################
## ELF Library Report Script
## 2020.11 created by smlee@sk.com
################################################################################
SCRIPT_VERSION="20210823"
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
HOSTNAME=$(hostname)

PROGRAM_PID=""
FLAG_ALL=0
FLAG_ANSI=0
while [ "$#" -gt 0 ] ; do
case "$1" in
	-a|--all)
		FLAG_ALL=1
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
################################################################################
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

makeString "-" "new"; makeString "-"; makeString "-"
makeString " Filename" "newline"
makeString " Size"
makeString " (Date) RPM/Digest(md5)"
makeString "-" "newline"; makeString "-"; makeString "-"

FN_LIB=$PROGRAM_FILE
FN_SIZE=$(GetFileSize "$FN_LIB")
FN_MD5=$(GetFileMd5 "$FN_LIB")

makeString "$FN_LIB (*)" "newline"
makeString "$FN_SIZE" "" "right"
makeString "$FN_MD5"

while IFS=" " read -r FN_LIB
do
	FN_TYPE=$(GetFileCheck "$FN_LIB")
	if [ "$FN_TYPE" == "0" ] ; then continue; fi
	FN_SIZE=$(GetFileSize "$FN_LIB")
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	makeString "$FN_LIB" "newline"
	makeString "$FN_SIZE" "$" "right"
	makeString "$FN_MD5"
done < <(lsof -np "$PROGRAM_PID" |grep ' mem ' |grep ' REG' |awk '{if (NF==9) print $9}'|awk -F\; '{print $1}'|sort)

while IFS=" " read -r FN_LIB
do
	FN_SIZE=$(GetFileSize "$FN_LIB")
	if [ "$FN_SIZE" == "-" ] ; then continue; fi
	FN_MD5=$(GetFileMd5 "$FN_LIB")

	makeString "$FN_LIB" "newline"
	makeString "$FN_SIZE" "$" "right"
	makeString "$FN_MD5"
done < <(lsof -np "$PROGRAM_PID" |grep ' DEL ' |grep " REG" |awk '{if (NF==8) print $8}'|awk -F\; '{print $1}'|sort)

makeString "-" "newline"; makeString "-"; makeString "-"
printString

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
