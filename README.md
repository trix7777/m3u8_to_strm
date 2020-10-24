# m3u8_to_strm
parse an m3u8-file and output strm files

forked from gist: https://gist.github.com/migueltarga/9f9ada182c46e8ae0414937d8416aad6

Thank you migueltarga for the basics to this idea!


To get you started quickly running this script I've created this quick guide:
1. Create a file named wget.cfg in the same directory as you run this script from with the following content:  
URL="http://ip.tv"  
PORT="1234"
USERNAME="ABCD"  
PASSWORD="EFGH"  

Change the values for URL, PORT, USERNAME and PASSWORD to your own in that file but keep the double quotes.
You will have gotten all that information in the link that you have got from your IPTV-provider.
For example:  
http://ip.tv:1234/get.php?username=ABCD&password=EFGH&type=m3u_plus&output=ts  
^----------^ ^--^                  ^--^          ^--^  
   URL^       ^PORT          USERNAME^     PASSWORD^  
   
2. Save the file.  

3. Download your m3u8-file from your IPTV-provider using the information given in the file wget.cfg with this command:  
$ ./strm.sh -d  

The file will be downloaded and saved as original.m3u8 in the script directory.  

To filter out and only do strm-files of wanted groups, I suggest you do no skip the next step. Else strm-files will be created for EVERYTHING found in the m3u8, including ALL TV-channels from all countries. In my case that is more than 45000 channels to be created as strm-files.  

4. Using the original.m3u8 downloaded in step 5, we now run this command:  
$ ./strm.sh -a /path/to/original.m3u8  

For an average computer and with 45000 channels this command will take approximately 10 minutes to complete. The result will create a file allgroups.txt. This file contains all "groups" found in your original.m3u8.  

5. Make a copy of this allgroups.txt file in the script directory and name the copy uwgroups.cfg.  

6. Now open for edit the uwgroups.cfg, which by now have the same contents as your allgroups.txt file. Each line in this file contains a group-name.  

7. Remove ALL group-name lines that you want the script to KEEP. That can be many lines to remove if you want to keep all relevant VOD and Series. My allgroups.txt has 147 group lines and my uwgroups.cfg has 92. In other words, the file uwgroups.cfg should when you are finished editing it, only contain the groups that you DO NOT WANT. Hence the uw (unwanted) in the file name. The reason for having the script behave this way, I've written in the header of the script.  

8. Save the edited uwgroups.cfg.  

9. Now, in you script directory you should have these files:  
allgroups.txt  
original.m3u8  
strm.sh  
uwgroups.cfg  
wget.cfg  

10. You are now ready for the script to run and create strm files! Run the command again, but this time without any switch, but only the location of your original.m3u8:
$ ./strm.sh /path/to/original.m3u8  

The command will run the full script and output the strm files in a strm-subfolder of the script directory. If you want to change the output location you need to edit the OUTDIR in the strm.sh file. For an average computer to complete this task can take up to 30 minutes or more.  

There are more options and settings that you can change in the strm.sh file, such as:
- enable the uwtitles.cfg - a file that filters out titles by keywords defined.
- enable a higher filter level than the default (only recommended for N1 customers).
- disable the automatic creation of allgroups.txt during script run.
- change the sub directory names for movies and tvshows
- disable logging, enable debugging and more
- even more to come...  

Don't forget: -h gives you some help.  
