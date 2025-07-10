![alt text](https://github.com/WebFritzi/GUI64/blob/main/GUI64.png)

# GUI64 v1.71
GUI64 is a graphical user interface for the Commodore 64 that allows you to run programs and games, as well as to manage files by cutting, copying, pasting, deleting, and renaming them. It moreover enables you to format and rename disks, browse your folders on your SD2IEC device, and create new disk images and folders.

**Control:**<br>
Mouse in Port #1<br>
Joystick in Port #2

# Binaries
There are currently two options: you either download GUI64.D64 and load GUI64 from disk with LOAD"*",8,1 or you use GUI64.PRG. The latter works great with a Kung Fu Flash cartridge. In this case, GUI64 is at your disposal right after switching on your computer.

# Code
GUI64 was developed in 6502 assembly code (ACME syntax) with _C64 Studio_ which you can download here:<br>
<p align="center">https://www.georg-rottensteiner.de/files/C64StudioRelease.zip</p>
To build GUI64, download the files in the "Code" folder and open C64 Studio. In C64 Studio, go to "File->Open->Solution or Project", choose GUI64.c64, and in the next file browser click on "Cancel". The main file is GUI64.asm.<br><br>

**Memory map of GUI64 v1.71**

$033c - $5f00 : Program code

$5f00 - $6000 : FREEMEM, used, e.g., for copying files

$6000 - $9800 : 14 KB free for one single GUI64 app

$9800 - $9900 : 16 window structs

$9900 - $a000 : 112 control structs

$a000 - $a370 : Buffer for desktop data

$a370 - $a400 : Buffer for taskbar data

$a400 - $a800 : Buffer for color data

$a800 - $bc00 : String list for drive A (255 entries)

$bc00 - $d000 : String list for drive B (255 entries)

Graphics elements in I/O area
$d000 - $d800 : Char set (desktop)

$d800 - $e000 : Sprites (currently - $dbc0)

$e000 - $e400 : Char set (taskbar)

$e400 - $e800 : Screen memory

$e800 - $ff00 : 5.75 KB buffer for file viewer content

$ff00 - $ffff : Jump tables


# Coming in Version 2.0 (Work in Progress)
* File browser: Implementation of the menu entries "Sort by Name", "Sort by Type", "Sort by Size" in the "View" menu
* File browser: Implementation of the menu entry "View" in the "File" menu to look into files in text and hex mode
* File browser: Copying files between disks in the same drive via disk swap., maybe even copying files between SD2IEC directories will be possible as well
* Tool tips (task buttons and drive icons)

# Future Plans
* Cartridge version of GUI64 v2.0
* Retrieve time from Ultimate 64 and SD2IECs with RTC
* Application programming interface: It will be possible to run a single app in GUI64.
