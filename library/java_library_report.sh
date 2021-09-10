#!/bin/bash
set +o posix
################################################################################
## Java Library Report Script
## 2020.11 created by smlee@sk.com
################################################################################
SCRIPT_VERSION="20210823"
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
HOSTNAME=$(hostname)

TMPDIR="/dev/shm/java-library-report"
if [ -d "$TMPDIR" ] ; then rm -rf "$TMPDIR"; fi # tmp code

ORG_FILE=""
NEW_FILE=""
FLAG_ALL=0
FLAG_CLASS=0
FLAG_JSP=0
FLAG_ANSI=0
while [ "$#" -gt 0 ] ; do
case "$1" in
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
		if [ "$ORG_FILE" == "" ] ; then
			ORG_FILE="$1"
		elif [ "$NEW_FILE" == "" ] ; then
			NEW_FILE="$1"
		else
			echo "unknown option: $1"
			exit 1
		fi
		shift 1
		;;
esac
done

if [ "$ORG_FILE" == "" ] ; then
	echo "Usage: $0 [options]... [file]..."
	exit 0
fi
if [ ! -f "$ORG_FILE" ] ; then
	echo "'$ORG_FILE' is not found."
	exit 1
fi
if [ "$NEW_FILE" != "" ] && [ ! -f "$NEW_FILE" ] ; then
	echo "'$NEW_FILE' is not found."
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

mkdir -p "$TMPDIR/org/"
if [ "$?" != "0" ] ; then echo "fail to make directory($TMPDIR/org/)"; exit 1; fi
if [ "$NEW_FILE" != "" ] ; then
	mkdir -p "$TMPDIR/new/"
	if [ "$?" != "0" ] ; then echo "fail to make directory($TMPDIR/new/)"; exit 1; fi
fi

unzip "$ORG_FILE" -d "$TMPDIR/org/" &> /dev/null
if [ "$?" != "0" ] ; then echo "unzip error $ORG_FILE ($?)"; exit 1; fi
find "$TMPDIR/org/" -type f -name "*.jar" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/org.jar.txt"
find "$TMPDIR/org/" -type f -name "*.class" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/org.class.txt"
find "$TMPDIR/org/" -type f -name "*.jsp" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/org.jsp.txt"
# shellcheck disable=SC2012
if [ "$(ls -1 /dev/shm/java-library-report/org |wc -l)" == "1" ] ; then
	ORG_BASE="$TMPDIR/org/$(ls -1 /dev/shm/java-library-report/org)"
else
	ORG_BASE="$TMPDIR/org"
fi

if [ "$NEW_FILE" != "" ] ; then
	unzip "$NEW_FILE" -d "$TMPDIR/new/" &> /dev/null
	if [ "$?" != "0" ] ; then echo "unzip error $NEW_FILE ($?)"; exit 1; fi
	find "$TMPDIR/new/" -type f -name "*.jar" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/new.jar.txt"
	find "$TMPDIR/new/" -type f -name "*.class" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/new.class.txt"
	find "$TMPDIR/new/" -type f -name "*.jsp" -exec md5sum {} \; |awk '{print $2,$1}' | sort > "$TMPDIR/new.jsp.txt"
	# shellcheck disable=SC2012
	if [ "$(ls -1 /dev/shm/java-library-report/new |wc -l)" == "1" ] ; then
		NEW_BASE="$TMPDIR/new/$(ls -1 /dev/shm/java-library-report/new)"
	else
		NEW_BASE="$TMPDIR/new"
	fi
fi

echo " Java Library Report Script ($HOSTNAME, $SCRIPT_VERSION, $BASH_VERSION)"
echo ""

if [ "$NEW_FILE" != "" ] && [ -f "$NEW_BASE/META-INF/MANIFEST.MF" ] ; then
	echo "# Archive Manifest Information"
	makeString "-" "new"; makeString "-"
	makeString "$ORG_FILE" "newline"
	makeString "$NEW_FILE"
	makeString "-" "newline"; makeString "-"

	lineno=$(wc -l "$NEW_BASE/META-INF/MANIFEST.MF" |awk '{print $1}')
	for ((i=1;i<=lineno;i++)); do
		lastline1=$(sed -n "${i},${i}p" "$ORG_BASE/META-INF/MANIFEST.MF" |sed 's/\r//')
		makeString "$lastline1" "newline"
		lastline2=$(sed -n "${i},${i}p" "$NEW_BASE/META-INF/MANIFEST.MF" |sed 's/\r//')
		makeString "$lastline2"
		if [ "$lastline1" == "" ] && [ "$lastline2" == "" ] ; then continue; fi
	done

	makeString "-" "newline"; makeString "-"
	printString
	echo ""
elif [ -f "$ORG_BASE/META-INF/MANIFEST.MF" ] ; then
	echo "# Archive Manifest Information"
	makeString "-" "new"
	makeString "$ORG_FILE" "newline"
	makeString "-" "newline"

	lineno=$(wc -l "$ORG_BASE/META-INF/MANIFEST.MF" |awk '{print $1}')
	for ((i=1;i<=lineno;i++)); do
		lastline1=$(sed -n "${i},${i}p" "$ORG_BASE/META-INF/MANIFEST.MF" |sed 's/\r//')
		makeString "$lastline1" "newline"
		if [ "$lastline1" == "" ] ; then continue; fi
	done

	makeString "-" "newline"
	printString
	echo ""
fi

echo "# Archive Library Information"
makeString "-" "new"; makeString "-"; makeString "-"
makeString "$ORG_FILE" "newline"
if [ "$NEW_FILE" != "" ] ; then
	makeString "$NEW_FILE"
	makeString " Description "
else
	makeString " Size "
	makeString " Checksum "
fi
makeString "-" "newline"; makeString "-"; makeString "-"

function JavaReportLibrary
{
	fn_org=$1
	fn_new=$2

	while IF=" " read fn chksum
	do
		len=${#ORG_BASE}
		org_filename=${fn:$len}
		new_filename=

		if [ "$NEW_FILE" == "" ] ; then
			fn_size=$(GetFileSize "$fn")

			makeString "$org_filename" "newline"
			makeString "$fn_size" "" "right"
			makeString "$chksum"
			continue
		fi

		_flag=0
		new_chksum=$(grep "$org_filename" "$fn_new"|awk '{print $2}')
		if [ "$chksum" == "$new_chksum" ] ; then
			_flag=1
			_str="SAME(=)"
		else
			chksum_cnt=$(grep -c "$org_filename" "$fn_new")
			if [ "$chksum_cnt" == "1" ] ; then
				_flag=2
				_str="MODIFY(*)"
			fi
		fi

		if [ "$FLAG_ALL" == "0" ] && [ "$_flag" == "1" ] ; then continue; fi
		if [ "$_flag" == "1" ] || [ "$_flag" == "2" ] ; then
			makeString "$org_filename" "newline"
			makeString "$org_filename"
			makeString " $_str"
			continue
		fi

		filename=$(basename "$fn")
		rver=$(echo "$filename" |awk -F- '{print $NF}')
		len=$((${#filename}-${#rver}))
		rname=${filename:0:$len}
		re='^[0-9]+$'
		if [ "$rname" != "" ] && [[ ${rver:0:1} =~ $re ]] ; then
			len=$((${#org_filename}-${#filename}))
			dirname=${org_filename:0:$len}

			lfile=$(grep "$dirname$rname" "$fn_new" |sort |head -1)
			if [ "$lfile" != "" ] ; then
				_flag=3
				len=${#NEW_BASE}
				fnold=$(echo "$lfile" |awk '{print $1}')
				new_filename=${fnold:$len}
			fi
		fi

		_str=
		if [ "$_flag" == "0" ] ; then
			_str="REMOVE(-)"
		elif [ "$_flag" == "3" ] ; then
			_str=$(VerDiff "$org_filename" "$new_filename")
			if [ "$_str" == "upgrade" ] ; then
				_str="UPGRADE(<)"
			else
				if [ "$FLAG_ANSI" == "1" ] ; then
					_str="$(tput setaf 1)DOWNGRADE(>)$(tput sgr0) "
				else
					_str="DOWNGRADE(>) "
				fi
			fi
		fi

		makeString "$org_filename" "newline"
		makeString "$new_filename"
		makeString " $_str"
	done < <(cat "$fn_org")

	if [ "$NEW_FILE" == "" ] ; then return; fi
	while IF=" " read fn chksum
	do
		len=${#NEW_BASE}
		new_filename=${fn:$len}

		chksum_cnt=$(grep -c "$new_filename" "$fn_org")
		if [ "$chksum_cnt" == "1" ] ; then continue; fi

		filename=$(basename "$fn")
		rver=$(echo "$filename" |awk -F- '{print $NF}')
		len=$((${#filename}-${#rver}))
		rname=${filename:0:$len}
		if [ "$rname" != "" ] ; then
			lfile=$(grep "$dirname$rname" "$fn_org" |sort |head -1)
			if [ "$lfile" != "" ] ; then continue; fi
		fi

		makeString "" "newline"
		makeString "$new_filename"
		makeString " NEW(+) "
	done < <(cat "$fn_new")
}

JavaReportLibrary "$TMPDIR/org.jar.txt" "$TMPDIR/new.jar.txt"
if [ "$FLAG_CLASS" == "1" ] ; then JavaReportLibrary "$TMPDIR/org.class.txt" "$TMPDIR/new.class.txt"; fi
if [ "$FLAG_JSP" == "1" ] ; then JavaReportLibrary "$TMPDIR/org.jsp.txt" "$TMPDIR/new.jsp.txt"; fi

makeString "-" "newline"; makeString "-"; makeString "-"
printString
exit 0
