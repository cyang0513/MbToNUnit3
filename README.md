# MbToNUnit3
A powershell script to help converting from MbUnit to NUnit3, i tested on both C# and VB.Net test projects.

I recently did a massive conversion work on 10k+ unit test from obsolete MbUnit to NUnit3. It's painful to do it one by one so i wrote this script to help. It will do roughly 60%-80% work for me. The script will do most conversation, but for exception handling you still need to manually change them. There's no easy way to do it.

It will generate the result as "YOURFILE.nu", and a log file per file.

How to use it:
 .\MbToNUnit.ps1 -folderPath "PATH TO YOUR TEST PROJECT"

