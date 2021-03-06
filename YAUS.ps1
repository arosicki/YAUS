################################################
#
# YAUS v1.0.2
# Adrian Rosicki
#
################################################

################################################
#
# To import module put it in Modules folder
# and name it's main function like module file
# (without .ps1 extension)
#
################################################
#Utilities
$Script:YAUSversion = "v1.0.2"

#Prevent execution without administative privileges
#Requires -RunAsAdministrator

#Prevents displaying erron messages
$ErrorActionPreference = 'silentlycontinue'
$WarningPreference = 'SilentlyContinue'

$nl = [Environment]::NewLine
# Module Importing
$files = Get-ChildItem ./Modules/*.ps1

$modules = @()
$files | ForEach-Object {
    . $_
    $filename = $_.Name
    $modules += $filename.Substring(0,$filename.Length-4)
}
#Main Menu
function mainMenu {  
    Clear-Host
    Write-Output "
__   _____  _   _ _____ 
\ \ / / _ \| | | /  ___|TM
 \ V / /_\ \ | | \ `--. 
  \ /|  _  | | | |`--. \
  | || | | | |_| /\__/ /
  \_/\_| |_/\___/\____/ 
                        
                        
Modules:"
if ($modules.Length -eq 0) {
    Write-Output "No modules found chceck if your modules are in Modules folder..." "Exiting..."
    exit
}
For ([int]$i = 1; $i -le [int]$modules.Length; $i++) {
    $a = $i - 1
    Write-Host -NoNewline $i"." $modules[$a] $nl
}
Write-Output $i". exit"
$choice = Read-Host -Prompt "Select Module"
$choice = [int]$choice
if (($choice -gt 0) -and ($choice -lt [int]$i)){
    & $modules[$choice-1]
}
elseif ($choice -eq $i) {
    exit
}
else {
    Clear-Host
    Read-Host -Prompt "Select correct option... $nl Press Enter to continue..."
}
}
while (1){mainMenu}