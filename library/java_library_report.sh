#!/bin/bash
set +o posix
################################################################################
## Java Library Report Script
## 2020.11 created by smlee@sk.com
################################################################################
SCRIPT_VERSION="20210413"
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
HOSTNAME=$(hostname)

TMPDIR="/dev/shm/java-library-report"
if [ -d "$TMPDIR" ] ; then rm -rf "$TMPDIR"; fi # tmp code

PROGRAM_FILE1=""
PROGRAM_FILE2=""
FLAG_ALL=0
FLAG_CLASS=0
FLAG_JSP=0
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
	-p|--path)
		shift 1
		if [ -d "$1" ] ; then
			TMPDIR=$1
		else
			echo "ERROR: not exist '$1' directory"
			exit 1
		fi
		shift 1
		;;
	-a|--all)
		FLAG_ALL=1
		shift 1
		;;
	-c|--class)
		FLAG_CLASS=1
		shift 1
		;;
	-j|--jsp)
		FLAG_JSP=1
		shift 1
		;;
	*)
		if [ "$PROGRAM_FILE1" == "" ] ; then
			PROGRAM_FILE1="$1"
		elif [ "$PROGRAM_FILE2" == "" ] ; then
			PROGRAM_FILE2="$1"
		else
			echo "unknown option: $1"
			exit 1
		fi
		shift 1
		;;
esac
done

if [ "$PROGRAM_FILE1" == "" ] ; then
	echo "Usage: $0 [options]... [file]..."
	exit 0
fi
if [ ! -f "$PROGRAM_FILE1" ] ; then
	echo "'$PROGRAM_FILE1' is not found."
	exit 1
fi
if [ "$PROGRAM_FILE2" != "" ] && [ ! -f "$PROGRAM_FILE2" ] ; then
	echo "'$PROGRAM_FILE2' is not found."
	exit 1
fi
################################################################################
function _stringCat
{
	local name="$1"
	local len="$2"
	local align="$3"

	local len_name=${#name}
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
				if [ "${_col:$((_len-2)):2}" == "~R" ] ; then
					_line=$_line$(_stringCat "${_col:0:$((_len-2))}" "${SLEN[$_col_cnt]}" "right")
				else
					_line=$_line$(_stringCat "$_col" "${SLEN[$_col_cnt]}")
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
################################################################################
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
function VerDiff
{
	local lfile=
	local rfile=
	lfile=$(basename "$1")
	rfile=$(basename "$2")

	local len=${#lfile}
	for ((i=0; i<len; i++))
	do
		if [ "${lfile:$i:1}" == "${rfile:$i:1}" ] ; then continue; fi
		break
	done
	if [ "$i" == "$len" ] ; then echo "equal"; exit; fi

	local lver=${lfile:$i}
	local rver=${rfile:$i}

	IFS='.' read -r -a llver <<< "$lver"
	IFS='.' read -r -a rrver <<< "$rver"
	re='^[0-9]+$'

	for index in "${!llver[@]}"
	do
		if ! [[ ${llver[$index]} =~ $re ]] ; then continue; fi
		if ! [[ ${rrver[$index]} =~ $re ]] ; then continue; fi

		if [ "${llver[$index]}" -eq "${rrver[$index]}" ] ; then
			continue
		elif [ "${llver[$index]}" -lt "${rrver[$index]}" ] ; then
			echo "upgrade"
			exit
		else
			echo "downgrade"
			exit
		fi
	done

	echo "equal"
}
################################################################################
if [ -d "$TMPDIR" ] ; then
	echo "Check directory($TMPDIR). Must not exist directory."
	exit 1
fi
mkdir -p "$TMPDIR"
if [ "$?" != "0" ] ; then echo "fail to make directory($TMPDIR)"; exit 1; fi

mkdir -p "$TMPDIR/file1/"
if [ "$?" != "0" ] ; then echo "fail to make directory($TMPDIR/file1/)"; exit 1; fi
if [ "$PROGRAM_FILE2" != "" ] ; then
	mkdir -p "$TMPDIR/file2/"
	if [ "$?" != "0" ] ; then echo "fail to make directory($TMPDIR/file2/)"; exit 1; fi
fi

unzip "$PROGRAM_FILE1" -d "$TMPDIR/file1/" &> /dev/null
if [ "$?" != "0" ] ; then echo "unzip error $PROGRAM_FILE1 ($?)"; exit 1; fi
find "$TMPDIR/file1/" -type f -name "*.jar" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/file1.jar.txt"
find "$TMPDIR/file1/" -type f -name "*.class" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/file1.class.txt"
find "$TMPDIR/file1/" -type f -name "*.jsp" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/file1.jsp.txt"

if [ "$PROGRAM_FILE2" != "" ] ; then
	unzip "$PROGRAM_FILE2" -d "$TMPDIR/file2/" &> /dev/null
	if [ "$?" != "0" ] ; then echo "unzip error $PROGRAM_FILE2 ($?)"; exit 1; fi
	find "$TMPDIR/file2/" -type f -name "*.jar" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/file2.jar.txt"
	find "$TMPDIR/file2/" -type f -name "*.class" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/file2.class.txt"
	find "$TMPDIR/file2/" -type f -name "*.jsp" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/file2.jsp.txt"
fi

echo " Java Library Report Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo ""

if [ -f "$TMPDIR/file2/META-INF/MANIFEST.MF" ] ; then
	echo "# Archive Manifest Information"
	makeString "-" "new"; makeString "-"
	makeString "$PROGRAM_FILE1" "newline"
	makeString "$PROGRAM_FILE2"
	makeString "-" "newline"; makeString "-"

	lineno=$(wc -l "$TMPDIR/file2/META-INF/MANIFEST.MF" |awk '{print $1}')
	for ((i=1;i<=lineno;i++)); do
		lastline1=$(sed -n "${i},${i}p" "$TMPDIR/file1/META-INF/MANIFEST.MF" |sed 's/\r//')
		makeString "$lastline1" "newline"
		lastline2=$(sed -n "${i},${i}p" "$TMPDIR/file2/META-INF/MANIFEST.MF" |sed 's/\r//')
		makeString "$lastline2"
		if [ "$lastline1" == "" ] && [ "$lastline2" == "" ] ; then continue; fi
	done

	makeString "-" "newline"; makeString "-"
	printString
	echo ""
elif [ "$PROGRAM_FILE2" == "" ] && [ -f "$TMPDIR/file1/META-INF/MANIFEST.MF" ] ; then
	echo "# Archive Manifest Information"
	makeString "-" "new"
	makeString "$PROGRAM_FILE1" "newline"
	makeString "-" "newline"

	lineno=$(wc -l "$TMPDIR/file1/META-INF/MANIFEST.MF" |awk '{print $1}')
	for ((i=1;i<=lineno;i++)); do
		lastline1=$(sed -n "${i},${i}p" "$TMPDIR/file1/META-INF/MANIFEST.MF" |sed 's/\r//')
		makeString "$lastline1" "newline"
		if [ "$lastline1" == "" ] ; then continue; fi
	done

	makeString "-" "newline"
	printString
	echo ""
fi

echo "# Archive Library Information"
if [ "$PROGRAM_FILE2" != "" ] ; then
	JARFILE="$TMPDIR/file2.jar.txt"
	CLASSFILE="$TMPDIR/file2.class.txt"
	JSPFILE="$TMPDIR/file2.jsp.txt"
else
	JARFILE="$TMPDIR/file1.jar.txt"
	CLASSFILE="$TMPDIR/file1.class.txt"
	JSPFILE="$TMPDIR/file1.jsp.txt"
fi

makeString "-" "new"; makeString "-"; makeString "-"
makeString "$PROGRAM_FILE1" "newline"
if [ "$PROGRAM_FILE2" != "" ] ; then
	makeString "$PROGRAM_FILE2"
	makeString " Description "
else
	makeString " Size "
	makeString " Checksum "
fi
makeString "-" "newline"; makeString "-"; makeString "-"

function JavaReportLibrary
{
	while IF=" " read fn chksum
	do
		fnbase=$(basename "$fn")

		if [ "$PROGRAM_FILE2" == "" ] ; then
			DIR="$TMPDIR/file1/"
			len=${#DIR}
			pfilename1=${fn:$len}
			FN_SIZE=$(GetFileSize "$fn")

			makeString "$pfilename1" "newline"
			makeString "$FN_SIZE" "" "right"
			makeString "$chksum"
			continue
		fi

		FLAG=0
		fnold=
		while IF=" " read a b
		do
			fnbase2=$(basename "$a")
			if [ "$fnbase" == "$fnbase2" ] ; then
				fnold=$a
				if [ "$chksum" == "$b" ] ; then
					FLAG=1
				else
					FLAG=2
				fi
			fi
		done < <(grep "$fnbase" "$2")

		if [ "$FLAG_ALL" == "0" ] && [ "$FLAG" == "1" ] ; then continue; fi

		if [ "$fnold" != "" ] ; then
			DIR="$TMPDIR/file1/"
			len=${#DIR}
			pfilename1=${fnold:$len}
		else
			DIR="$TMPDIR/file2/"
			len=${#DIR}
			pfilename0=${fn:$len}
			rver=$(echo "$pfilename0" |awk -F- '{print $NF}')
			len=$((${#pfilename0}-${#rver}))
			rname=${pfilename0:0:$len}

			lfile=$(grep "$rname" "$2" |sort |head -1)
			if [ "$lfile" != "" ] ; then
				FLAG=3
				DIR="$TMPDIR/file1/"
				len=${#DIR}
				fnold=$(echo "$lfile" |awk '{print $1}')
				pfilename1=${fnold:$len}
			else
				pfilename1=
			fi
		fi
		DIR="$TMPDIR/file2/"
		len=${#DIR}
		pfilename2=${fn:$len}

		STR=
		if [ "$FLAG" == "0" ] ; then
			STR="NEW(+)"
		elif [ "$FLAG" == "1" ] ; then
			STR="SAME(=)"
		elif [ "$FLAG" == "2" ] ; then
			STR="MODIFY(*)"
		elif [ "$FLAG" == "3" ] ; then
			STR=$(VerDiff "$pfilename1" "$pfilename2")
			if [ "$STR" == "upgrade" ] ; then
				STR="REPLACE(>)"
			else
				STR="REPLACE(<)"
			fi
		fi

		makeString "$pfilename1" "newline"
		makeString "$pfilename2"
		makeString "$STR"
	done < <(cat "$1")
}

JavaReportLibrary "$JARFILE" "$TMPDIR/file1.jar.txt"
if [ "$FLAG_CLASS" == "1" ] ; then JavaReportLibrary "$CLASSFILE" "$TMPDIR/file1.class.txt"; fi
if [ "$FLAG_JSP" == "1" ] ; then JavaReportLibrary "$JSPFILE" "$TMPDIR/file1.jsp.txt"; fi

makeString "-" "newline"; makeString "-"; makeString "-"
printString

exit 0
