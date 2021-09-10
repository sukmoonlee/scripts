#!/bin/bash
set +o posix
################################################################################
## Process Library Report Script
## 2019.02 created by smlee@sk.com
################################################################################
SCRIPT_VERSION="20210823"
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
HOSTNAME=$(hostname)
PROGRAM_PID=
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
		echo "Usage: $0 [-afrstvdh] [pid]"
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
		if [ "$PROGRAM_PID" != "" ] ; then
			echo "unknown option: $1"
			exit 1
		fi
		PROGRAM_PID="$1"
		shift 1
		;;
esac
done

if [ "$FLAG_SAVE" == "2" ] ; then
	PROGRAM_PID=$(head -1 "$FN_INPUT" | awk '{print $NF}')
fi
if [ "$PROGRAM_PID" == "" ] ; then
	echo "Usage: $0 [-arstvdh] 'pid' or '-f file'"
	exit 0
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
		IFS=':' read -r -a no <<< "$_line"
		echo "${no[0]}"
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
	if [ "$FLAG_SAVE" != "2" ] && [ -f "$file" ] ; then
		exec_cmd "$PG_ls --full-time $file"
	fi

	_s=$(getStartCmdNo "ls --full-time $file")
	if [ "$_s" == "0" ] ; then echo ""; return; fi
	_e=$(getEndCmdNo "$_s")
	sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" |awk '{print $6,substr($7,0,8)}'
}
function GetFileSize
{
	local file="$1"
	if [ "$file" == "" ] ; then return; fi
	if [ "$FLAG_SAVE" != "2" ] && [ -f "$file" ] ; then
		exec_cmd "$PG_ls -l $file"
	fi

	_s=$(getStartCmdNo "ls -l $file")
	if [ "$_s" == "0" ] ; then echo ""; return; fi
	_e=$(getEndCmdNo "$_s")
	sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" | awk '{print $5}'
}
function GetFileMd5
{
	local file="$1"
	if [ "$file" == "" ] ; then return; fi
	if [ "$FLAG_SAVE" != "2" ] && [ -f "$file" ] ; then
		exec_cmd "$PG_md5sum $file"
		exec_cmd "$PG_rpm -qf $file"
	fi

	if [ "$FLAG_RPM" == "1" ] ; then
		_s=$(getStartCmdNo "rpm -qf $file")
		if [ "$_s" == "0" ] ; then echo ""; return; fi
		_e=$(getEndCmdNo "$_s")
		rpm=$(sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" | awk '{print $1}')
		if [ "$rpm" == "file" ] ; then echo ""; else echo "$rpm"; fi
	else
		_s=$(getStartCmdNo "md5sum $file")
		if [ "$_s" == "0" ] ; then echo ""; return; fi
		_e=$(getEndCmdNo "$_s")
		sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" | awk '{print $1}'
	fi
}
function GetFileCheck
{
	local file="$1"
	if [ "$file" == "" ] ; then return; fi
	if [ "$FLAG_SAVE" != "2" ] && [ -f "$file" ] ; then
		exec_cmd "$PG_file $file"
	fi

	_s=$(getStartCmdNo "file $file")
	if [ "$_s" == "0" ] ; then echo "0"; return; fi
	_e=$(getEndCmdNo "$_s")
	sed -n "$((_s+1)),$((_e-1))p" "$FN_INPUT" | egrep -c "ELF|Zip archive"
}
################################################################################
PG_lsof=$(GetFullPath "lsof")
PG_md5sum=$(GetFullPath "md5sum")
PG_stat=$(GetFullPath "stat")
PG_ls=$(GetFullPath "ls")
PG_date=$(GetFullPath "date")
PG_rpm=$(GetFullPath "rpm")
PG_file=$(GetFullPath "file")
if [ "$PG_lsof" == "" ] ; then echo "Error - Command not found 'lsof'"; exit 1; fi
if [ "$PG_md5sum" == "" ] ; then echo "Error - Command not found 'md5sum'"; exit 1; fi
if [ "$PG_stat" == "" ] ; then echo "Error - Command not found 'stat'"; exit 1; fi

if [ "$FN_INPUT" == "" ] ; then
	FN_OUTPUT="/tmp/$(basename "$0")-$(hostname)-$(date +%Y%m%d-%H%M%S)-$$.txt"

	exec_cmd "$PG_lsof -np $PROGRAM_PID"
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

s=$(getStartCmdNo "lsof -np $PROGRAM_PID")
if [ "$s" == "0" ] ; then
	echo "'$PROGRAM_PID' process is not found."
	echo "Usage: $0 [-arstvdh] 'pid' or '-f file'"
	exit 1
fi
e=$(getEndCmdNo "$s")
PROGRAM_FILE=$(sed -n "$((s+1)),$((e-1))p" "$FN_INPUT" |grep " txt "|awk '{print $9} '|awk -F\; '{print $1}')
if [ "$PROGRAM_FILE" == "" ] ; then
	echo "'$PROGRAM_PID' process is not found."
	sed -n "$((s)),$((e))p" "$FN_INPUT" |sed "s/^/	/"
	echo "Usage: $0 [-arstvdh] 'pid' or '-f file'"
	exit 1
fi

#set -e
echo " Process Library Report Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo ""

makeString "-" "new"; makeString "-"; makeString "-"; makeString "-"
makeString " Filename " "newline"
makeString " Size "
makeString " Date "
if [ "$FLAG_RPM" == "1" ] ; then makeString " RPM "; else makeString " Digest "; fi
makeString "-" "newline"; makeString "-"; makeString "-"; makeString "-"

FN_TAR="$(basename "$PROGRAM_FILE")_$(date +%Y%m%d-%H%M%S).tar.gz"
FN_LIST=$PROGRAM_FILE
FN_LIB=$PROGRAM_FILE

makeString " $FN_LIB (*) " "newline"
makeString " $(GetFileSize "$FN_LIB") " "" "right"
makeString " $(GetFileDate "$FN_LIB") "
makeString " $(GetFileMd5 "$FN_LIB") "

while IFS=" " read -r FN_LIB
do
	FN_TYPE=$(GetFileCheck "$FN_LIB")
	if [ "$FN_TYPE" == "0" ] ; then continue; fi

	FN_LIST="$FN_LIST $FN_LIB"
	makeString " $FN_LIB " "newline"
	makeString " $(GetFileSize "$FN_LIB") " "" "right"
	makeString " $(GetFileDate "$FN_LIB") "
	makeString " $(GetFileMd5 "$FN_LIB") "
done < <(sed -n "$((s+1)),$((e-1))p" "$FN_INPUT" |grep ' mem ' |grep ' REG' |awk '{if (NF==9) print $9}'|awk -F\; '{print $1}'|sort)

while IFS=" " read -r FN_LIB
do
	FN_LIST="$FN_LIST $FN_LIB"
	makeString " $FN_LIB " "newline"
	makeString " $(GetFileSize "$FN_LIB") " "" "right"
	makeString " $(GetFileDate "$FN_LIB") "
	makeString " $(GetFileMd5 "$FN_LIB") "
done < <(sed -n "$((s+1)),$((e-1))p" "$FN_INPUT" |grep ' DEL ' |grep ' REG' |awk '{if (NF==8) print $8}'|awk -F\; '{print $1}'|sort)

makeString "-" "newline"; makeString "-"; makeString "-"; makeString "-"
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
	$PG_rm -f "$FN_OUTPUT"
	if [ "$?" != "0" ] ; then
		echo "[error] command not complete ($PG_rm -f $FN_OUTPUT)"
		exit 1
	fi
fi

exit 0
