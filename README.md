# transren
 Tanslit Renamer (transren), this program replace russian letters in file and dirs names to latin letters


Tanslit Renamer (transren), this program replace russian letters in file and dirs names to latin letters

v 0.0.1b (L) ChaosSoftware 2022.

Usage: transren.exe <-h>|<-m <mask> or/and <-t>>[-d] [-s]

-h - this help

-m <mask> - file mask for search. Parameter must be!

-t - translit subdirectories names

[-d] <directory> - start directory. If not, use current dir.

[-s] - include subdirs

[-f] - find only (no rename files/dirs)

e.g.:

transren.exe -m *.html - translit *.html in current directory

transren.exe -t - translit subdirs in current directory

transren.exe -m *.html -s  - translit *.html in current directory and subdirs

transren.exe -m *.* -s -t - translit all files in current directory and translit all subdirs

transren.exe -m *.html -d D:\DOC\  - translit *.html files in D:\DOC

If file already exist, program ask for replace it.

If directory already exist, program skip it.

### Screenshots

![01](/screens/01.png)

![02](/screens/02.png)

![03](/screens/03.png)