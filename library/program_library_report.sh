#!/bin/bash
set +o posix
################################################################################
## Program Library Report Script
## 2019.02 created by smlee@sk.com
################################################################################
SCRIPT_VERSION="20220327"
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
HOSTNAME=$(hostname)
PROGRAM_FILE=
FLAG_SAVE=0
FLAG_ALL=0
FLAG_RPM=0
FLAG_TAR=0
FN_INPUT=
FLAG_ANSI=0
while [ "$#" -gt 0 ] ; do
case "$1" in
	-a|--all)
		FLAG_ALL=1
		shift 1
		;;
	-f|--file)
		shift 1
		if [ -f "$1" ] ; then
			FN_INPUT=$1
			FLAG_SAVE=2
			shift 1
		else
			echo "$0 : Unknown option '$1'"
			exit 1
		fi
		;;
	-s|--save)
		FLAG_SAVE=1
		FN_INPUT=
		shift 1
		;;
	-r|--rpm)
		FLAG_RPM=1
		shift 1
		;;
	-t|--tar)
		FLAG_TAR=1
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
		echo "Usage: $0 [-afrstvdh] [filename]"
		echo "      -a, --all     : print all information"
		echo "      -f, --file    : load command execute file"
		echo "      -r, --rpm     : print RPM information (replace digest field)"
		echo "      -s, --save    : save command execute file (do not remove result file)"
		echo "      -t, --tar     : print tar create command"
		echo "      -v, --version : print version ($SCRIPT_VERSION)"
		echo "      -d, --debug   : set debug(-x)"
		echo "      -h, --help    : help"
		exit 0
		;;
	*)
		if [ "$PROGRAM_FILE" != "" ] ; then
			echo "unknown option: $1"
			exit 1
		fi
		PROGRAM_FILE="$1"
		shift 1
		;;
esac
done

if [ "$FLAG_SAVE" == "2" ] ; then
	PROGRAM_FILE=$(head -1 "$FN_INPUT" | awk '{print $NF}')
fi
if [ "$PROGRAM_FILE" == "" ] ; then
	echo "Usage: $0 [-arstvdh] 'program' or '-f file'"
	exit 0
fi
if [ ! -f "$PROGRAM_FILE" ] && [ "$FLAG_SAVE" != "2" ] ; then
	echo "'$PROGRAM_FILE' is not found."
	exit 1
fi
################################################################################
function GetFullPath
{
	local cmd=$1

	if [ "$cmd" == "" ] ; then
		echo ""
		return 1
	fi
	if [ -f '/usr/bin/which' ] ; then
		_fullPath=$(/usr/bin/which "$cmd" 2> /dev/null)
		if [ "$_fullPath" != "" ] ; then
			echo "$_fullPath"
			return
		fi
	fi

	if [ -f '/usr/bin/whereis' ] ; then
		_fullPath=$(/usr/bin/whereis "$cmd" |awk '{print $2}')
		if [ "$_fullPath" != "" ] ; then
			echo "$_fullPath"
			return
		fi
	fi

	echo ""
}
function exec_cmd()
{
	local cmd=$1
	local line_date=
	line_date=$($PG_date +%Y-%m-%d\ %H:%M:%S.%N)
	RST="0"

	set +e
	echo "[$line_date] # $cmd" >> "$FN_OUTPUT"
	eval "$cmd" 1>> "$FN_OUTPUT" 2>&1
	RST=$?
	set -e

	line_date=$($PG_date +%Y-%m-%d\ %H:%M:%S.%N)
	echo "[$line_date] ## exit code: $RST" >> "$FN_OUTPUT"
}
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
function getStartCmdNo
{
	if [ "$1" == "" ] ; then echo "0"; return; fi
	_line=$(grep "] # " "$FN_INPUT" -n |grep "$1")
	if [ "$_line" != "" ] ; then
		IFS=':' read -r -a noa <<< "$_line"
		echo "${noa[0]}"
	else
		echo "0"
	fi
}
function getEndCmdNo
{
	if [ "$1" == "" ] ; then echo "0"; return; fi
	local no=$1

	_line=$(sed -n "${no},\$p" "$FN_INPUT" |grep "## exit code" -n |head -1)
	IFS=':' read -r -a n <<< "$_line"
	local eno=${n[0]}
	echo $(( no + eno - 1 ))
}
function GetFileDate
{
	local file="$1"
	if [ "$file" == "" ] ; then return; fi
	if [ "$FLAG_SAVE" != "2" ] ; then
		exec_cmd "$PG_ls --full-time $file"
	fi

	_s=$(getStartCmdNo "ls --full-time $file")
	_e=$(getEndCmdNo "$_s")
	sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" |awk '{print $6,substr($7,0,8)}'
}
function GetFileSize
{
	local file="$1"
	if [ "$file" == "" ] ; then return; fi
	if [ "$FLAG_SAVE" != "2" ] ; then
		exec_cmd "$PG_ls -l $file"
	fi

	_s=$(getStartCmdNo "ls -l $file")
	_e=$(getEndCmdNo "$_s")
	sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" | awk '{print $5}'
}
function GetFileStat
{
	local file="$1"
	if [ "$file" == "" ] ; then return; fi
	if [ "$FLAG_SAVE" != "2" ] ; then
		exec_cmd "$PG_stat $file"
	fi

	_s=$(getStartCmdNo "stat $file")
	_e=$(getEndCmdNo "$_s")
	sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" | grep "Size:" | awk '{print $8}'
}
function GetFileReadlink
{
	local file="$1"
	if [ "$file" == "" ] ; then return; fi
	if [ "$FLAG_SAVE" != "2" ] ; then
		exec_cmd "$PG_readlink -f $file"
	fi

	_s=$(getStartCmdNo "readlink -f $file")
	_e=$(getEndCmdNo "$_s")
	sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" | awk '{print $1}'
}
function GetFileMd5
{
	local file="$1"
	if [ "$file" == "" ] ; then return; fi
	if [ "$FLAG_SAVE" != "2" ] ; then
		exec_cmd "$PG_md5sum $file"
		exec_cmd "$PG_rpm -qf $file"
	fi

	if [ "$FLAG_RPM" == "1" ] ; then
		_s=$(getStartCmdNo "rpm -qf $file")
		_e=$(getEndCmdNo "$_s")
		rpm=$(sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" | awk '{print $1}')
		if [ "$rpm" == "file" ] ; then echo ""; else echo "$rpm"; fi
	else
		_s=$(getStartCmdNo "md5sum $file")
		_e=$(getEndCmdNo "$_s")
		sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" | awk '{print $1}'
	fi
}
################################################################################
PG_readlink=$(GetFullPath "readlink")
PG_ldd=$(GetFullPath "ldd")
PG_md5sum=$(GetFullPath "md5sum")
PG_stat=$(GetFullPath "stat")
PG_ls=$(GetFullPath "ls")
PG_date=$(GetFullPath "date")
PG_rpm=$(GetFullPath "rpm")
if [ "$PG_readlink" == "" ] ; then echo "Error - Command not found 'readlink'"; exit 1; fi
if [ "$PG_ldd" == "" ] ; then echo "Error - Command not found 'ldd'"; exit 1; fi
if [ "$PG_md5sum" == "" ] ; then echo "Error - Command not found 'md5sum'"; exit 1; fi
if [ "$PG_stat" == "" ] ; then echo "Error - Command not found 'stat'"; exit 1; fi

if [ "$FN_INPUT" == "" ] ; then
	FN_OUTPUT="/tmp/$(basename "$0")-$(hostname)-$(date +%Y%m%d-%H%M%S)-$$.txt"

	exec_cmd "$PG_ldd $PROGRAM_FILE"
	exec_cmd "$PG_ldd -r $PROGRAM_FILE"
	exec_cmd "echo \$LD_LIBRARY_PATH"
	exec_cmd "$(GetFullPath "ldconfig") -p"

	FN_INPUT=$FN_OUTPUT
	set +e
fi
if [ "$FLAG_SAVE" == "1" ] ; then
	echo ">> Created console reporting file ($FN_INPUT)"
	echo ""
elif [ "$FLAG_SAVE" == "2" ] ; then
	echo ">> Loading console reporting file ($FN_INPUT)"
	echo ""
fi

s=$(getStartCmdNo "ldd $PROGRAM_FILE")
if [ "$s" == "0" ] ; then
	echo "'$PROGRAM_FILE' is not found."
	echo "Usage: $0 [-arstvdh] 'program' or '-f file'"
	exit 1
fi
e=$(getEndCmdNo "$s")

set -e
echo " Program Library Report Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo ""

makeString "-" "new"; makeString "-"; makeString "-"; makeString "-"; makeString "-"
makeString " Filename " "newline"
makeString " Size "
makeString " Date "
if [ "$FLAG_RPM" == "1" ] ; then makeString " RPM "; else makeString " Digest "; fi
makeString " Symbolic Link "
makeString "-" "newline"; makeString "-"; makeString "-"; makeString "-"; makeString "-"

FN_TAR="$(basename "$PROGRAM_FILE")_$(date +%Y%m%d-%H%M%S).tar.gz"
FN_LIST=$PROGRAM_FILE
FN_LIB=$PROGRAM_FILE
if [ "$(GetFileStat "$FN_LIB")" == "symbolic" ] ; then
	FN_LINK=$FN_LIB
	FN_LIB=$(GetFileReadlink "$FN_LIB")
else
	FN_LINK=
fi

makeString " $FN_LIB (*) " "newline"
makeString " $(GetFileSize "$FN_LIB") " "" "right"
makeString " $(GetFileDate "$FN_LIB") "
makeString " $(GetFileMd5 "$FN_LIB") "
makeString " $FN_LINK "

while IFS=" " read -r a b c d
do
	if [ "$b" == "=>" ] ; then
		if [ "$c" == "not" ] && [ "$d" != "" ] ; then
			FN_LIB=$(echo "$a"| xargs)
			makeString " $FN_LIB " "newline"
			makeString ""
			makeString ""
			makeString ""
			makeString ""
			continue
		fi
		if [ "${c:0:1}" == "(" ] ; then
			continue
		else
			FN_LIB=$c
			FN_LIST="$FN_LIST $FN_LIB"
		fi
	else
		FN_LIB=$(echo "$a"| xargs)
		FN_LIST="$FN_LIST $FN_LIB"
	fi

	if [ "$(GetFileStat "$FN_LIB")" == "symbolic" ] ; then
		FN_LINK=$FN_LIB
		FN_LIB=$(GetFileReadlink "$FN_LIB")
	else
		FN_LINK=
	fi

	makeString " $FN_LIB " "newline"
	makeString " $(GetFileSize "$FN_LIB") " "" "right"
	makeString " $(GetFileDate "$FN_LIB") "
	makeString " $(GetFileMd5 "$FN_LIB") "
	makeString " $FN_LINK "
done < <(sed -n "$((s+1)),$((e-1))p" "$FN_INPUT"|sort)

makeString "-" "newline"; makeString "-"; makeString "-"; makeString "-"; makeString "-"
printString

if [ "$FLAG_ALL" == "1" ] ; then
	echo ""
	echo "# echo \$LD_LIBRARY_PATH"
	s=$(getStartCmdNo "echo \$LD_LIBRARY_PATH")
	e=$(getEndCmdNo "$s")
	sed -n "$((s+1)),$((e-1))p" "$FN_INPUT"

	echo ""
	echo "# ldconfig -p"
	s=$(getStartCmdNo "ldconfig -p")
	e=$(getEndCmdNo "$s")
	sed -n "$((s+1)),$((e-1))p" "$FN_INPUT"
fi

if [ "$FLAG_TAR" == "1" ] ; then
	echo ""
	echo "# tar create command"
	echo "tar czhf $FN_TAR $FN_LIST"
fi

if [ "$FLAG_SAVE" == "0" ] && [ -f "$FN_OUTPUT" ] ; then
	PG_rm=$(GetFullPath "rm")
	if ! $PG_rm -f "$FN_OUTPUT" ; then
		echo "[error] command not complete ($PG_rm -f $FN_OUTPUT)"
		exit 1
	fi
fi

exit 0
