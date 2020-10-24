#!/bin/bash
# Forked from https://gist.github.com/migueltarga/9f9ada182c46e8ae0414937d8416aad6
# By trix77
# This script has been tested and works with N1

###############################################################################
# YOU NEED TO EDIT OUTDIR BEFORE YOU RUN THIS SCRIPT                          #
###############################################################################

# Full path to output directory
# Default is OUTDIR="$(cd $(dirname $0) && pwd)/strm"
#OUTDIR="/some/path"
OUTDIR="$(cd $(dirname $0) && pwd)/strm"

# Configuation file wget.cfg for wget
wgethelp() {
	echo
	echo "################################################"
	echo "# Configuation file wget.cfg for wget download #"
	echo "################################################"
	echo
	echo "To download your m3u8-file from your iptv-provider in addition to parsing it to"
	echo "strm-files, you need to create this file in the same directory as this script is"
	echo "running from. In that file you need to put the information that you've got from"
	echo "your iptv-provider. You can get the information from the url that your iptv-"
	echo "provider gave you:"
	echo
	echo "http://ip.tv:1234/get.php?username=ABCD&password=EFGH&type=m3u_plus&output=ts"
	echo "^----------^ ^--^                  ^--^          ^--^"
	echo "   URL^       ^PORT          USERNAME^     PASSWORD^"
	echo
	echo "Example content of wget.cfg:"
	echo # if you read this here, the ' before and after ' each line should not be put in the cfg-file
	echo 'URL="http://ip.tv"'
	echo 'PORT="1234"'
	echo 'USERNAME="ABCD"'
	echo 'PASSWORD="EFGH"'
	echo
}

# Configuration file uwgroups.cfg for not wanted groups
uwghelp() {
	echo
	echo "#########################################################"
	echo "# Configuration file uwgroups.cfg for not wanted groups #"
	echo "#########################################################"
	echo
	echo "This script is written with the mind that you want all GROUPS but what is listed"
	echo "in this file. The main reason for making the script this way is to not miss out"
	echo "on new groups. This way even new groups will be output as strm files without any"
	echo "user intervention."
	echo "Create the file in the same directory as this script and put unwanted groups in"
	echo "it, one group per line."
	echo
	echo "TIP: First run this script with the option -a to create the allgroups.txt and"
	echo "then use the information from that file to put in the uwgroups.cfg file. Or,    "
	echo "simply rename the allgroups.txt to uwgroups.cfg and then remove groups from that"
	echo "file that you want not to be skipped by the script."
	echo
	echo "Example content of uwgroups.cfg:"
	echo # if you read this here, the ' before and after ' each line should not be put in the cfg-file
	echo 'Danish Sports Events'
	echo 'Norwegian Sports Events'
	echo 'VOD: ex-Yu Movies'
	echo
}

# Configuration file uwtitles.cfg for not wanted titles

uwthelp() {
	echo
	echo "#########################################################"
	echo "# Configuration file uwtitles.cfg for not wanted titles #"
	echo "#########################################################"
	echo
	echo "This file is used for keywords that you do not want in a title, one keyword per"
	echo "line."
	echo 
	echo "Example content for uwtitles.cfg:"
	echo # if you read this here, the ' before and after ' each line should not be put in the cfg-file
	echo '[4K]'
	echo 'XXX'
	echo
}

###############################################################################
# DO NOT EDIT BELOW THIS LINE UNLESS YOUR REALLY KNOW WHAT YOU ARE DOING      #
###############################################################################

# Enable or disable logging
# Default is 1
LOGENABLE=1

# Enable or disable debug output
# Default is 0
DBGENABLE=0

# Filter level 0 turns off file name filtering completely, not recommended.
# Filter level 1 will replace or remove many characters that might not work on
# a filesystem, such as  * ? < > / : |.
# Filter level 2 will do even more filtering, correct misspellings etc.
# Not recommended unless you do have N1 as your iptv-provider.
# Default is 1
FLEVEL=1

# Enable or disable creating allgroups.txt with all groups found in the m3u8-
# file during script run. Can be used to create the uwgroups.cfg file.
# Default is 1
ALLGRPENABLE=1

# Enable or disable uwtitles.cfg
# Default is 1
UWTENABLE=1

# NOGROUP fix: subfolder name for titles not belonging to a group.
# This is a fix for when the iptv-provider has screwed up and did not place a 
# title in a group.
# Default is "NOGROUP"
NOGROUP="NOGROUP"

# The NOGROUP fix can be turned off, but be aware that disabling this function
# can lead to script creating strange subdirectories that begins with
# "#EXTINF..." if it encounters a title not belonging to a group.
# Default is 1
NOGRPENABLE=1

# Subfolder names for tvshows and movies to be created under OUTDIR.
# Movie strm-files will be created in a group subdir of the MOVIESDIR according
# to the m3u8-file. tv-shows strm-files however, will be stripped of the group 
# it belongs to, and added to a series group instead. Reasons for this is that 
# Jellyfin and Kodi (and maybe Emby) needs it that way. Movies can be spread
# out in subfolders but tv-shows needs to be located under a series-name
# subfolder for them to be indexed correctly.
# Default is "VOD Series" and VOD Movies"
SERIESDIR="VOD Series"
MOVIESDIR="VOD Movies"

# m3u8-file for the script to parse
# Default is "$1"
M3U8FILE="$1"

# The directory where the script is located.
# Default is "$(cd $(dirname $0) && pwd)"
SCRIPTDIR="$(cd $(dirname $0) && pwd)"

# Location where the log files will be written.
# Default is "$SCRIPTDIR/log"
LOGDIR="$SCRIPTDIR/log"

# All-groups file
# Default is "$SCRIPTDIR/allgroups.txt"
ALLGROUPS="$SCRIPTDIR/allgroups.txt"

# Configuration file uwgroups.cfg
# Default is "$SCRIPTDIR/uwgroups.cfg"
UWGCFG="$SCRIPTDIR/uwgroups.cfg"

# Configuration file uwtitles.cfg
# Default is "$SCRIPTDIR/uwtitles.cfg"
UWTCFG="$SCRIPTDIR/uwtitles.cfg"

# wget options
WGETCFG="$SCRIPTDIR/wget.cfg"
# Only set the following wget options if the file wget.cfg exists
if [ -e "$WGETCFG" ]; then
	OUTM3U8="$SCRIPTDIR/original.m3u8"
	source $WGETCFG
	# if cfg created with a windows program, it might contain windows linefeed \r
	# we need to remove that here
	USERNAME=${USERNAME//$'\r'}
	PASSWORD=${PASSWORD//$'\r'}
	URL=${URL//$'\r'}
	PORT=${PORT//$'\r'}
	POSTDATA="username=$USERNAME&password=$PASSWORD&type=m3u_plus&output=ts"
	URL="${URL}:${PORT}/get.php"
fi

# Time the script.
# Do not change
SECONDS=0

# Set name of script file
# Do not change
SCRIPTNAME="$(basename $0)"

# Set date/time variable:
# Do not change
TLOG="`date "+%Y%m%d_%H%M"`"

# Set logfiles:
# Do not change
MOVEXIST_LOG="$LOGDIR/$TLOG.movie_exist.log"
MOVNEW_LOG="$LOGDIR/$TLOG.movie_new.log"
MOVSKIP_LOG="$LOGDIR/$TLOG.movie_skip.log"
SEREXIST_LOG="$LOGDIR/$TLOG.series_exist.log"
SERNEW_LOG="$LOGDIR/$TLOG.series_new.log"
SERSKIP_LOG="$LOGDIR/$TLOG.series_skip.log"
SERNG_LOG="$LOGDIR/$TLOG.series_nogroup.log"

# Set nogroup warning
# Do not change
NGRPWARN="*** WARNING *** SOME TITLES ARE NOT IN GROUPS, CHECK $SERNG_LOG"

# Size of m3u8-file
# Do not change
# if M3U8FILE does not start with - (like in -a) and is not null and exists then 
if [[ $M3U8FILE != -* ]] && [ -n "$M3U8FILE" ] && [ -e "$M3U8FILE" ]; then
	M3U8SIZE=$(($(stat -c%s "$M3U8FILE") / 1024)); else M3U8FILE="$2"; fi

# if M3U8FILE is not null and exists then
if [ -n "$M3U8FILE" ] && [ -e "$M3U8FILE" ]; then M3U8SIZE=$(($(stat -c%s "$M3U8FILE") / 1024)); fi

# if M3U8SIZE is not null then add SIZEKB
if [ -n "$M3U8SIZE" ]; then SIZEKB="KB"; M3U8SIZE="${M3U8SIZE} ${SIZEKB}"; fi

###############################################################################
# DO NOT EDIT ANYTHING BELOW THIS LINE                                        #
###############################################################################

# TODO:
# - Check $LINE for errors, such as 'http://someurl/somefile."mkv"' -- replace with 'http://someurl/somefile.mkv'
# - To be able to delete old files, we really need to know what is old. As we do not touch the existing files during script run, all files will soon be "old". One way of doing it could be to also output all created file names to one external file, that we in the end use to compare with the file system and to purge old files that's not in it.
# - Log new groups into a file.
# - Compare:
# Local, F2:
# SMB, F2:
# Local, no filter:
# Local, F1: 21 minutes and 38 seconds
# Local, F1, ALLGRPENABLE=0:
# Local, F1, UWTENABLE=0 and ALLGRPENABLE=0:
# Local, F1, UWTENABLE=0 and ALLGRPENABLE=0 and LOGENABLE=0:
# Turn off TITLENOTALREADYEXIST:

debug() {
    if [ $DBGENABLE == 1 ]
    then
    echo -e "\n$@" | cat -v
    fi
}

pause() {
    if [ $DBGENABLE == 1 ]
    then
    sed -n q </dev/tty
	echo "********************************************************************************"
    fi
}

help() {
	echo -e "\n********************************************************************************"
	echo "m3u8 to strm, parse an m3u8-file and output strm files."
	echo "Usage: ./$SCRIPTNAME [OPTION] [FILE]"
	echo
	echo "*** To get you started right away here's a list to follow:"
	echo "* 1: Create and configure wget.cfg (-w ext. help)"
	echo "* 2: Download your m3u8-file with -d"
	echo "* 3: Create the allgroups.txt with -a"
	echo "* 4: Create and configure uwgroups.cfg with help of allgroups.txt (-g ext. help)"
	echo "* 5: If you have not already set your OUTDIR in the script, do that now!"
	echo "* Extra: Create and configure uwtitles.cfg (-t ext. help)"
	echo
	echo "Options:"
	echo "-a FILE     Create and populate the allgroups.txt file using FILE"
	echo "-d          Download m3u8-file using information provided in wget.cfg file."
	echo "-e          Same as -d and then run the script on the downloaded file."
	echo "-h          Print this help."
	echo "-w          Extended help for the wget.cfg file."
	echo "-g          Extended help for the uwgroups.cfg and allgroups.txt files."
	echo "-t          Extended help for the uwtitles.cfg file."
	echo
	echo "Examples:"
	echo "To run this script on local m3u8-file:    ./$SCRIPTNAME FILE.m3u8"
	echo "To download m3u8-file:                    ./$SCRIPTNAME -d"
	echo "To download file and then run the script: ./$SCRIPTNAME -e"
	echo
	echo "********************************************************************************"
}

wgetdl() {
	if [ -e "$WGETCFG" ]; then
		echo -e "\nDownloading to $OUTM3U8"
		wget -q --show-progress -O $OUTM3U8 --post-data $POSTDATA $URL
	else
		echo -e "\n*** ERROR: '$WGETCFG' can not be found!"
		exit
	fi
}

allgroup() {
	if [ -z "$M3U8FILE" ]; then echo -e "\n*** ERROR: You need to specify FILE! Use -h for help." && exit 1; fi
	
	echo -e "\n*** INFO: `date "+%Y-%m-%d %H:%M:%S"` Creating the file $ALLGROUPS."
	echo -e "\n*** NOTE: Be patient, it could take a while for a very big m3u8-file to be processed. 10000 KB+ can take over 10 minutes to process (your is $M3U8SIZE). There will be no output to the screen during that time."
	
	mkdir -p $LOGDIR
	LNR=0
	IFS=$'\n'
	
	while read LINE; do
		INFO=$(echo "$LINE" | grep '^#EXTINF:')
		if [ "$LNR" -eq 0 ] && [ -n "$INFO" ]; then
			LNR=1
			GROUP=$(echo "$LINE" | sed -E 's/.*group-title="([^"]+).*/\1/')
			if [[ "$GROUP" =~ ^#EXTINF.* ]]; then
				NGRPSET=1
				TITLE=$(echo "$LINE" | sed -E 's/.*tvg-name="([^"]+).*/\1/')
				echo "$TITLE" >> "$SERNG_LOG"
			else
				fgrep -qs -- "$GROUP" "$ALLGROUPS" || echo "$GROUP" >> "$ALLGROUPS"
			fi
		fi
		if [ "$LNR" -eq 1 ] && [ -z "$INFO" ]; then
			LNR=0
		fi
	done < "$M3U8FILE"
	if [[ "$NGRPSET" == 1 ]]; then echo -e "\n*** NOTE: There are titles not in groups, your iptv-provider has screwed up. No big deal but you can check $SERNG_LOG if you want to see what those titles are."; fi
	DURATION=$SECONDS
	echo -e "\n*** INFO: `date "+%Y-%m-%d %H:%M:%S"` Done! ($(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds)"
}

while getopts ":hadegtw" option; do
	case $option in
		h) # display help
			help
			exit
			;;
		a) # create allgroups.txt
			M3U8FILE="$2"
			allgroup
			exit
			;;
		d) # wget download
			wgetdl
			exit
			;;
		e) # wget download then run script on the downloaded m3u8-file
			wgetdl
			M3U8FILE=$OUTM3U8
			;;
		g)	# show help about uwgroups.cfg
			uwghelp
			exit
			;;
		t)	# show help about uwtitles.cfg
			uwthelp
			exit
			;;
		w)	# show help about wget.cfg
			wgethelp
			exit
			;;
		\?) # error: display help
			help
			echo -e "\n*** ERROR: Invalid option. -h for help."
			exit
			;;
	esac
done

###############################################################################
# SCRIPT START                                                                #
###############################################################################

if [ -z "$M3U8FILE" ]; then echo -e "\n*** ERROR: You need to specify FILE! Use -h for help." && exit 1; fi
if [ -z "$OUTDIR" ]; then help && echo -e "\n*** ERROR: You need to edit OUTDIR in the header of this script." && exit 1; fi
if [ ! -e "$M3U8FILE" ]; then echo -e "\n*** ERROR: '$M3U8FILE' can not be found!" && exit 1; fi

echo -e "\n\n\n\n\n\n\n\n\n\n********************************************************************************"
echo "`date "+%Y-%m-%d %H:%M:%S"` script starting"
echo "*** INFO: SCRIPTNAME:   '$SCRIPTNAME'"
echo "*** INFO: SCRIPTDIR:    '$SCRIPTDIR'"
echo "*** INFO: OUTDIR:       '$OUTDIR'"
echo "*** INFO: M3U8FILE:     '$M3U8FILE' ($M3U8SIZE)"
echo "*** INFO: OUTM3U8:      '$OUTM3U8'"
echo "*** INFO: SERIESDIR:    '$OUTDIR/$SERIESDIR'"
echo "*** INFO: MOVIESDIR:    '$OUTDIR/$MOVIESDIR'"
echo "*** INFO: NOGROUP:      '$OUTDIR/$SERIESDIR/$NOGROUP'"
echo "*** INFO: LOGDIR:       '$LOGDIR'"
echo "*** INFO: ALLGROUPS:    '$ALLGROUPS'"
echo "*** INFO: UWTCFG:       '$UWTCFG'"
echo "*** INFO: UWGCFG:       '$UWGCFG'"
echo "*** INFO: WGETCFG:      '$WGETCFG'"
echo "*** INFO: URL:          '$URL'"
echo "*** INFO: POSTDATA:     '$POSTDATA'"
echo "*** INFO: ALLGRPENABLE:  $ALLGRPENABLE"
echo "*** INFO: DBGENABLE:     $DBGENABLE"
echo "*** INFO: FLEVEL:        $FLEVEL"
echo "*** INFO: LOGENABLE:     $LOGENABLE"
echo "*** INFO: NOGRPENABLE:   $NOGRPENABLE"
echo "*** INFO: UWTENABLE:     $UWTENABLE"

if [ ! -e "$UWGCFG" ]; then echo -e "\n*** WARNING: '$UWGCFG' can not be found!\nScript can continue, but be aware that the output can be huge if your m3u8-file is really big! Read more about this in the help section (use -h for help).\n\n*** Continue with ENTER\n\n*** Abort with CTRL+C" && sed -n q </dev/tty; fi
if [ ! -e "$UWTCFG" ]; then echo -e "\n*** INFO: '$UWTCFG' can not be found!\nScript will continue without it.\nRead more about this in the help section (use -h for help)."; fi

echo -e "\n*** INFO: If your m3u8-file is very big (10000 KB+), (see yours size above) and you have a lot of unwanted groups specified, there will be no output to the screen for a very long time (sometimes for more than 30 minutes) depending on your CPU speed and where your OUTDIR is located; a network location for instance, is much slower to write to than a local path. Check the log and output directories for progress."

# create logdir:
if [ "$LOGENABLE" -eq 1 ]; then mkdir -p $LOGDIR; fi

# set LNR to 0
LNR=0

# set UWGROUP to 0
UWGROUP=0

# sets the internal field separator to eol\n
IFS=$'\n'

debug "*** start: begin loop; while read each LINE by LINE from the M3U8FILE do:"
pause
(
while read LINE; do	#while MAINLOOP START

###############################################################################
# SECTION 1 START                                                             #
###############################################################################

	if [ "$UWGROUP" -eq 0 ]; then	#if UWGROUPHUGESKIP START
		debug "*** section 1: read a line from the LINE variable into other variables."
		pause
		
		debug "*** s1_c1: set INFO with data from LINE, only if LINE starts with #EXTINF:" 
		INFO=$(echo "$LINE" | grep '^#EXTINF:')
		
		debug "LINE: '$LINE'"
		debug "LNR: $LNR"
		debug "INFO: '$INFO'"
		pause

		debug "*** s1_c2: if LNR is 0 and INFO is not null then continue. else skip to s1_cA.\n- LNR will be 0 if s1_c3-s1_c9 has not run yet.\n- INFO will not be null if it has been set with s1_c1."
		pause
		if [ "$LNR" -eq 0 ] && [ -n "$INFO" ]; then	#if LNR0_INFONOTNULL START

			debug "*** s1_c3: set GROUP using group-title value to:"
			GROUP=$(echo "$LINE" | sed -E 's/.*group-title="([^"]+).*/\1/')
			debug "'$GROUP'"
			pause
			
			NGRPSET=0
			debug "*** s1_c3.1: if GROUP begins with #EXTINF then do s1_c3.2."
			if [[ "$GROUP" =~ ^#EXTINF.* ]] && [ "$NOGRPENABLE" -eq 1 ]; then	#if GROUPbeginswithEXTINF START
				pause 

				debug "*** s1_c3.2: put title that is erroneously not in a group in $NOGROUP."
				GROUP=$NOGROUP
				NGRPSET=1
				debug "GROUP after processing: $GROUP" 
					
				# We need to get the TITLE earlier here to get the title output for the log (if LOGENABLE=1).
				debug "*** s1_c3.3: set TITLE using tvg-name value to:" 
				TITLE=$(echo "$LINE" | sed -E 's/.*tvg-name="([^"]+).*/\1/')
				debug "'$TITLE'" 
				pause 
					
			else	#if GROUPbeginswithEXTINF ELSE 
				debug "GROUP is already in a group or NOGRPENABLE is 0, skipped s1_c3.2."
				pause
			fi	#if GROUPbeginswithEXTINF END
						
			if [ "$ALLGRPENABLE" -eq 1 ]; then	#if ALLGRPENABLE START
				debug "*** s2_c1: write each group name once to $ALLGROUPS"
				if [ "$NGRPSET" -eq 1 ] && [ "$LOGENABLE" -eq 1 ]; then	#if NGRPSET_LOGENABLE START
					fgrep -qs -- "$NGRPWARN" "$ALLGROUPS" || echo "$NGRPWARN" >> "$ALLGROUPS"
				else	#if NGRPSET_LOGENABLE ELSE
					fgrep -qs -- "$GROUP" "$ALLGROUPS" || echo "$GROUP" >> "$ALLGROUPS"
				fi	#if NGRPSET_LOGENABLE END
				pause
			fi	#if ALLGRPENABLE END

			debug "*** s2_c2: check the $UWGCFG for unwanted groups, and only if not found, continue."
			if ! fgrep -qs "$GROUP" "$UWGCFG"; then	#if UWGROUPnotinGROUP START
				UWGROUP=0
				debug "GROUP was not in UWGCFG, continuing" 
				pause
			
				if [ "$NGRPSET" -ne 1 ]; then	#if NGRPSET START # we don't need to get this a second time here if it's already been set if the title was in a nogroup
				debug "*** s1_c4: set TITLE using tvg-name value to:"
				TITLE=$(echo "$LINE" | sed -E 's/.*tvg-name="([^"]+).*/\1/')
				debug "'$TITLE'" 
				pause 
				fi	#if NGRPSET END
				
				debug "*** s1_c5: set SERIE using tvg-name value (without the SxxExx) to:" 
				SERIE=$(echo "$LINE" | sed -E 's/.*tvg-name="([^"]+)[| ][Ss][0-9].*/\1/')
				debug "'$SERIE'" 
				pause 
				
				debug "*** s1_c6: if SERIE begins with '#EXTINF:' we decide it's a movie, else a series:"
				if [[ "$SERIE" =~ ^#EXTINF:.* ]]; then	#if SERIEhasEXTINF START
					ISM=1
					debug "it is a movie (set ISM to 1)." 
					unset SERIE
					debug "unset SERIE check (should be null now): '$SERIE'"
				else	#if SERIEhasEXTINF ELSE
					ISM=0
					debug "it is a series (set ISM to 0)."
				fi	#if SERIEhasEXTINF END
				pause 

				debug "*** s1_c9: set LNR to 1, telling script we've completed this section." 
				LNR=1
				pause 
			else	#if UWGROUPnotinGROUP ELSE
				UWGROUP=1
				debug "GROUP was in UWGCFG, skipping." 
				pause 
			fi	#if UWGROUPnotinGROUP END
		fi	#if LNR0_INFONOTNULL END

		debug "LNR: $LNR" 
		debug "INFO: '$INFO'"; 
		debug "UWGROUP: $UWGROUP"
		
		debug "*** s1_cA: if LNR is 1 and INFO is null then continue to section 2.\n- LNR will be 1 if s1_c3-s1_c9 has been run (GROUP, TITLE, SERIE is set).\n- INFO is null only when s1_c1 has not set it (i.e. when the line did not start with #EXTINF:)."
		if [ "$LNR" -eq 1 ] && [ -z "$INFO" ] && [ "$UWGROUP" -eq 0 ]; then	#if LNR1andINFONULL START

###############################################################################
# SECTION 2 START                                                             #
###############################################################################

			debug "*** section 2: we now have all information, including url-line."
			debug "LINE: '$LINE'" 
			pause 
			
			debug "*** s2_c4: set shopt options" 
			shopt -s extglob nocasematch nocaseglob
			pause 
			
			UWTITLE=0
			if [ "$UWTENABLE" -eq 1 ]; then	#if UWTENABLE START
				debug "*** s2_c5: check TITLE against $UWTCFG for keywords." 
				IFS=' ' read -ra arr <<<$TITLE
				for keyword in "${arr[@]}"; do	#for TITLEinUWTCFG START
					if fgrep -qsiw "$keyword" "$UWTCFG"; then	#if keywordINUWTCFG START
						if [ "$ISM" -eq 1 ]; then	#if ISMMOVIE1 START
							OUT1=$GROUP/$TITLE
							OUT2=$MOVSKIP_LOG
						else	#if ISMMOVIE1 ELSE
							OUT1=$SERIE/$TITLE
							OUT2=$SERSKIP_LOG
						fi	#if ISMMOVIE1 END
						if [ "$LOGENABLE" -eq 1 ]; then echo "$OUT1" >> "$OUT2"; fi
						debug "unwanted keyword found in UWTCFG: setting UWTITLE to 1 (TITLE is unwanted)." 
						UWTITLE=1
					fi	#if keywordINUWTCFG END
				done	#for TITLEinUWTCFG END
				pause 
			fi	#if UWTENABLE END
			
			debug "*** s2_c6: only continue if TITLE is wanted." 
			if [ "$UWTITLE" -eq 0 ]; then	#if UNWANTEDTITLE0 START
				pause 

###############################################################################
# FILTER LEVER 1 START                                                        #
###############################################################################
			
				if [ "$FLEVEL" -ge 1 ]; then	#if FILTERLEVEL1 START
					debug "*** s2_c6.1: filtering level 1 start with FLEVEL set to: $FLEVEL" 

					# in filter level 1 we want to replace or remove characters that might not work in a Windows environment.
					
					# substring replacement:
					# to replace the first match of $substring with $replacement:
					# ${string/substring/replacement}
					# to replace all matches of $substring with $replacement:
					# ${string//substring/replacement}
					# place multiple substrings inside []
					
					debug "variables before filter 1:" 
					debug "GROUP: $GROUP" 
					debug "TITLE: $TITLE" 
					debug "SERIE: $SERIE" 

					# will be used to replace stuff in filter level 1
					REPCHAR1="-"			# replace with -
					NONAME="NONAME"			# replace with 'NONAME'

					# note that backslash \ will never exist in in this context as it would have been escaped earlier. double quotes " (citation mark) would not have been captured either as the capture by sed would have stopped capturing at the char before that. because of this, neither \ or " will be used here.

					# TODO: "[\x01-\x1F\x7F]"									# special chars
					# "^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)"	# illegal

					# replace stuff:
					
					# carriage return
					GROUP=${GROUP%$'\r'}
					TITLE=${TITLE%$'\r'}
					SERIE=${SERIE%$'\r'}
					
					# leading period
					GROUP=${GROUP##+([.])}
					TITLE=${TITLE##+([.])}
					SERIE=${SERIE##+([.])}
					
					# trailing period
					GROUP=${GROUP%%+([.])}
					TITLE=${TITLE%%+([.])}
					SERIE=${SERIE%%+([.])}
					
					# file named period
					GROUP=${GROUP##/.}
					TITLE=${TITLE##/.}
					SERIE=${SERIE##/.}
					
					# * ? < >
					GROUP=${GROUP//+([\*\?\<\>])}
					TITLE=${TITLE//+([\*\?\<\>])}
					SERIE=${SERIE//+([\*\?\<\>])}
					
					# (no filename) with $NONAME
					GROUP=${GROUP:-"$NONAME"}
					TITLE=${TITLE:-"$NONAME"}
					SERIE=${SERIE:-"$NONAME"}
					
					# all / : | with $REPCHAR1
					GROUP=${GROUP//+([\/:|])/"$REPCHAR1"}
					TITLE=${TITLE//+([\/:|])/"$REPCHAR1"}
					SERIE=${SERIE//+([\/:|])/"$REPCHAR1"}
					
					# leading whitespace
					GROUP=${GROUP##+( )}
					TITLE=${TITLE##+( )}
					SERIE=${SERIE##+( )}
					
					# trailing whitespace
					GROUP=${GROUP%%+( )}
					TITLE=${TITLE%%+( )}
					SERIE=${SERIE%%+( )}
					
					# double whitespaces (must be last)
					GROUP=${GROUP//+( )/ }
					TITLE=${TITLE//+( )/ }
					SERIE=${SERIE//+( )/ }

					debug "variables after filter 1:" 
					debug "GROUP: $GROUP" 
					debug "TITLE: $TITLE" 
					debug "SERIE: $SERIE" 
					
					pause 
				
				fi	#if FILTERLEVEL1 END
				
###############################################################################
# FILTER LEVER 2 START                                                        #
###############################################################################
				
				if [ "$FLEVEL" -ge 2 ]; then	#if FILTERLEVEL2 START
					debug "*** s2_c6.2: filtering level 2 start." 
					# in filter level 2 we want to tidy up even more:
					
					# misspelled stuff:
					PRE="[PRE]"			; _PRE1="[RRE]"
										  _PRE2="[PFE]"
					MUA="[Multi-Audio]"	; _MUA1="[MUTI-AUDIO]"
					NORDIC="[NORDIC]"	; _NORDIC1=" Nordic]"
										  _NORDIC2="[nordic]"
					KIDS="[KIDS]"		; _KIDS1="[KDS]"
					FOURK="[4K]"		; _FOURK1="[4k]"
					
					GROUP=${GROUP//"$_PRE1"/"$PRE"}
					GROUP=${GROUP//"$_PRE2"/"$PRE"}
					TITLE=${TITLE//"$_PRE1"/"$PRE"}
					TITLE=${TITLE//"$_PRE2"/"$PRE"}
					SERIE=${SERIE//"$_PRE1"/"$PRE"}
					SERIE=${SERIE//"$_PRE2"/"$PRE"}
					
					GROUP=${GROUP//"$_MUA1"/"$MUA"}
					TITLE=${TITLE//"$_MUA1"/"$MUA"}
					SERIE=${SERIE//"$_MUA1"/"$MUA"}
					
					GROUP=${GROUP//"$_NORDIC1"/ "$NORDIC"}
					GROUP=${GROUP//"$_NORDIC2"/"$NORDIC"}
					TITLE=${TITLE//"$_NORDIC1"/ "$NORDIC"}
					TITLE=${TITLE//"$_NORDIC2"/"$NORDIC"}
					SERIE=${SERIE//"$_NORDIC1"/ "$NORDIC"}
					SERIE=${SERIE//"$_NORDIC2"/"$NORDIC"}
					
					GROUP=${GROUP//"$_KIDS1"/"$KIDS"}
					TITLE=${TITLE//"$_KIDS1"/"$KIDS"}
					SERIE=${SERIE//"$_KIDS1"/"$KIDS"}
					
					GROUP=${GROUP//"$_FOURK1"/"$FOURK"}
					TITLE=${TITLE//"$_FOURK1"/"$FOURK"}
					SERIE=${SERIE//"$_FOURK1"/"$FOURK"}
					
					# space after (
					GROUP=${GROUP//+(\( )/\(}
					TITLE=${TITLE//+(\( )/\(}
					SERIE=${SERIE//+(\( )/\(}
					
					# space before )
					GROUP=${GROUP//+( \))/\)}
					TITLE=${TITLE//+( \))/\)}
					SERIE=${SERIE//+( \))/\)}
					
					# space after [
					GROUP=${GROUP//+(\[ )/\[}
					TITLE=${TITLE//+(\[ )/\[}
					SERIE=${SERIE//+(\[ )/\[}
					
					# space before ]
					GROUP=${GROUP//+( \])/\]}
					TITLE=${TITLE//+( \])/\]}
					SERIE=${SERIE//+( \])/\]}
					
					# add space after )
					GROUP=${GROUP//+(\))/\) }
					TITLE=${TITLE//+(\))/\) }
					SERIE=${SERIE//+(\))/\) }

					# add space after ]
					GROUP=${GROUP//+(\])/\] }
					TITLE=${TITLE//+(\])/\] }
					SERIE=${SERIE//+(\])/\] }
					
					# special - replace these
					_ONLY4K="[Only On 4K Devices]"
					_VOD="VOD- "
					_COMMA=","				# comma isn't wanted
					
					GROUP=${GROUP//"$_ONLY4K"}
					TITLE=${TITLE//"$_ONLY4K"}
					SERIE=${SERIE//"$_ONLY4K"}
											
					GROUP=${GROUP//$_VOD}	# don't want group to be named VOD-
					
					GROUP=${GROUP//+([$_COMMA])}
					TITLE=${TITLE//+([$_COMMA])}
					SERIE=${SERIE//+([$_COMMA])}
											
					# conform to standard
					MS="[MS]"				# for multi subtitle
					MA="[MA]"				# for multi audio
					MSA="Multi-Subs"
					MSB="Multi-Sub"
					MSC="Multi Subs"
					MAA="Multi-Audio"
					MAB="Multi Audio"
					MAC="Dual-Audio"
					FKA="4K"

					GROUP=${GROUP//"$MSA"/"$MS"}
					GROUP=${GROUP//"$MSB"/"$MS"}
					GROUP=${GROUP//"$MSC"/"$MS"}
					TITLE=${TITLE//"$MSA"/"$MS"}
					TITLE=${TITLE//"$MSB"/"$MS"}
					TITLE=${TITLE//"$MSC"/"$MS"}
					SERIE=${SERIE//"$MSA"/"$MS"}
					SERIE=${SERIE//"$MSB"/"$MS"}
					SERIE=${SERIE//"$MSC"/"$MS"}

					GROUP=${GROUP//"$MAA"/"$MA"}
					GROUP=${GROUP//"$MAB"/"$MA"}
					GROUP=${GROUP//"$MAC"/"$MA"}
					TITLE=${TITLE//"$MAA"/"$MA"}
					TITLE=${TITLE//"$MAB"/"$MA"}
					TITLE=${TITLE//"$MAC"/"$MA"}
					SERIE=${SERIE//"$MAA"/"$MA"}
					SERIE=${SERIE//"$MAB"/"$MA"}
					SERIE=${SERIE//"$MAC"/"$MA"}

					GROUP=${GROUP//"$FKA"/"$FOURK"}
					TITLE=${TITLE//"$FKA"/"$FOURK"}
					SERIE=${SERIE//"$FKA"/"$FOURK"}

					# more than one [
					GROUP=${GROUP//+(\[)/\[}
					TITLE=${TITLE//+(\[)/\[}
					SERIE=${SERIE//+(\[)/\[}
					
					# more than one ]
					GROUP=${GROUP//+(\])/\]}
					TITLE=${TITLE//+(\])/\]}
					SERIE=${SERIE//+(\])/\]}
					
					# more than one (
					GROUP=${GROUP//+(\()/\(}
					TITLE=${TITLE//+(\()/\(}
					SERIE=${SERIE//+(\()/\(}
					
					# more than one )
					GROUP=${GROUP//+(\))/\)}
					TITLE=${TITLE//+(\))/\)}
					SERIE=${SERIE//+(\))/\)}
					
					# replace stuff:
					# warning: this can lead to duplicates, that in the end then will be skipped, caused by the scripts function 'if file exists'.

					# [KIDS]
					GROUP=${GROUP//\[KIDS\]}
					TITLE=${TITLE//\[KIDS\]}
					SERIE=${SERIE//\[KIDS\]}

					# [SE]
					GROUP=${GROUP//\[SE\]}
					TITLE=${TITLE//\[SE\]}
					SERIE=${SERIE//\[SE\]}
					
					# [NORDIC]
					GROUP=${GROUP//\[NORDIC\]}
					TITLE=${TITLE//\[NORDIC\]}
					SERIE=${SERIE//\[NORDIC\]}

					# [IMDB]
					GROUP=${GROUP//\[IMDB\]}
					TITLE=${TITLE//\[IMDB\]}
					SERIE=${SERIE//\[IMDB\]}

					# [PRE]
					GROUP=${GROUP//\[PRE\]}
					TITLE=${TITLE//\[PRE\]}
					SERIE=${SERIE//\[PRE\]}
					
					# $MS
					GROUP=${GROUP//"$MS"}
					TITLE=${TITLE//"$MS"}
					SERIE=${SERIE//"$MS"}
					
					# $MA
					GROUP=${GROUP//"$MA"}
					TITLE=${TITLE//"$MA"}
					SERIE=${SERIE//"$MA"}

					# $FOURK with 4K
					GROUP=${GROUP//"$FOURK"/4K}
					#TITLE=${TITLE//"$FOURK"}
					#SERIE=${SERIE//"$FOURK"}
					
					# $FOURK with nothing
					#GROUP=${GROUP//"$FOURK"}
					#TITLE=${TITLE//"$FOURK"}
					#SERIE=${SERIE//"$FOURK"}

					################################################## end warning.
					
					# ()
					GROUP=${GROUP//()}
					TITLE=${TITLE//()}
					SERIE=${SERIE//()}
					
					# []
					GROUP=${GROUP//[]}
					TITLE=${TITLE//[]}
					SERIE=${SERIE//[]}
					
					# add space before dash (-) only if space already after
					GROUP=${GROUP//+(- )/ - }
					TITLE=${TITLE//+(- )/ - }
					SERIE=${SERIE//+(- )/ - }
					
					# brackets for parentheses -- to be able to differentiate from year
					GROUP=${GROUP//\[/\(}
					GROUP=${GROUP//\]/\)}
					TITLE=${TITLE//\[/\(}
					TITLE=${TITLE//\]/\)}
					SERIE=${SERIE//\[/\(}
					SERIE=${SERIE//\]/\)}

					# re-place brackets on some stuff
					GROUP=${GROUP//\(4K\)/"$FOURK"}
					GROUP=${GROUP//\(MS\)/"$MS"}
					GROUP=${GROUP//\(MA\)/"$MA"}
					TITLE=${TITLE//\(4K\)/"$FOURK"}
					TITLE=${TITLE//\(MS\)/"$MS"}
					TITLE=${TITLE//\(MA\)/"$MA"}
					SERIE=${SERIE//\(4K\)/"$FOURK"}
					SERIE=${SERIE//\(MS\)/"$MS"}
					SERIE=${SERIE//\(MA\)/"$MA"}

					# leading whitespace (again)
					GROUP=${GROUP##+( )}
					TITLE=${TITLE##+( )}
					SERIE=${SERIE##+( )}
					
					# trailing whitespace (again)
					GROUP=${GROUP%%+( )}
					TITLE=${TITLE%%+( )}
					SERIE=${SERIE%%+( )}

					# double whitespaces (again) (must be last)
					GROUP=${GROUP//+( )/ }
					TITLE=${TITLE//+( )/ }
					SERIE=${SERIE//+( )/ }
					
					debug "variables after filter 2:"
					debug "GROUP: $GROUP" 
					debug "TITLE: $TITLE" 
					debug "SERIE: $SERIE" 
					
					pause
					
				fi	#if FILTERLEVEL2 END 
				
###############################################################################
# SECTION 3 START                                                             #
###############################################################################

				debug "TITLE is wanted, continue." 
				if [ "$ISM" -eq 1 ]; then	#if ISAMOVIE1B START
					OUT1=$OUTDIR/$MOVIESDIR/$GROUP
					OUT2=$OUT1/$TITLE.strm
					OUT3=$GROUP/$TITLE
					OUT4=$MOVNEW_LOG
					OUT5=$MOVEXIST_LOG
				else	#if ISAMOVIE1B ELSE
					OUT1=$OUTDIR/$SERIESDIR/$SERIE
					OUT2=$OUT1/$TITLE.strm
					OUT3=$GROUP/$SERIE/$TITLE
					OUT4=$SERNEW_LOG
					OUT5=$SEREXIST_LOG
				fi	#if ISAMOVIE1B END
				pause 
				
				if [ "$UWTITLE" -eq 1 ]; then debug "TITLE is not wanted, skipping."; fi

				debug "*** s2_c7: only continue if the strm-file does not already exist." 
				# if strm-file does not already exist (else the script would add lines to the existing file and Jellyfin would believe it's new file)
				if [ ! -e "$OUT1/$TITLE.strm" ]; then	#if TITLENOTALREADYEXIST START
					pause

					debug "*** s2_c8: create the directory for the strm file." 
					mkdir -p $OUT1
					pause 
				
					debug "*** s2_c9: create the strm-file with the LINE variable printed to it."
					printf "%s" "$LINE" > "$OUT2"
					debug "LINE: '$LINE'" 
					debug "OUT2: '$OUT2'" 
					pause 
		
					if [[ "$GROUP" =~ ^#EXTINF.* ]] || [ "$GROUP" = "$NOGROUP" ] && [ "$LOGENABLE" -eq 1 ]; then echo "$TITLE" >> "$SERNG_LOG"; fi
					if [ "$LOGENABLE" -eq 1 ]; then echo "$OUT3" >> "$OUT4"; fi
				else	#if TITLENOTALREADYEXIST ELSE
					debug "strm-file already exists, skipping." 
					if [ "$LOGENABLE" -eq 1 ]; then echo "$OUT3" >> "$OUT5"; fi
				fi	#if TITLENOTALREADYEXIST END
				debug "*** section 2: complete!" 
				pause 
			fi	#if UNWANTEDTITLE0 END
			LNR=0

		else	#if LNR1andINFONULL ELSE
			debug "LNR: $LNR" 
			debug "INFO: '$INFO'" 
			debug "UWGROUP: $UWGROUP" 
		
			if [ "$LNR" -eq 0 ] && [ -z "$INFO" ] && [ "$UWGROUP" -eq 0 ]; then debug "*** section 1: complete but LINE did not have any useful information, restarting!\nLINE: '$LINE'"; fi 
			if [ "$LNR" -eq 1 ] && [ -n "$INFO" ]; then debug "*** section 1: complete but we need to get the url-line, restarting!"; fi 
			if [ "$UWGROUP" -eq 1 ]; then debug "*** section 1: complete but $GROUP was in UWGCFG, skipping!"; fi 
			pause 
			
		fi	#if LNR1andINFONULL END
	else	#if UWGROUPHUGESKIP ELSE
		UWGROUP=0
		debug "we now do a huge skip because the group was not wanted" 
		pause 
	fi 	#if UWGROUPHUGESKIP END

done < "$M3U8FILE"	#while MAINLOOP END
)

DURATION=$SECONDS
echo -e "\n*** INFO: `date "+%Y-%m-%d %H:%M:%S"` Done! ($(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds)"
echo -e "********************************************************************************\n"
