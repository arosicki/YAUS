################################################
#
# YAUS Active Directory Shell v1.0.0
# Adrian Rosicki
#
################################################
################################################
#
# To add commands add them to ModuleXmls
# inside existing file or (recommended)new file 
# following the pattern [*c.xml]
#
################################################
$global:AdshVersion = "v1.0.0"
function checkOS {
    Clear-Host
    Write-Output "Checking prerequisities"
    return (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType
}
function getFiles {
    $count = 0
    [xml]$Script:xmlDB = '<?xml version="1.0" encoding="utf-8"?><Commands></Commands>'
    $ADSHfiles = Get-ChildItem ./ModuleXmls/*c.xml
    $nrOfFiles = $ADSHfiles.Count
    $ADSHfiles | ForEach-Object {
        [xml]$xmlFile = Get-Content -Path $_.FullName
        $count++
        Clear-Host
        Write-Host -NoNewline "Getting commands from XML files $nl $count of $nrOfFiles files $nl"
        ForEach ($XmlNode in $xmlFile.DocumentElement.ChildNodes) {
            $Script:xmlDB.DocumentElement.AppendChild($Script:xmlDB.ImportNode($XmlNode, $true)) > $null
        }
    }
}
function implementCommands {
    Clear-Host
    Write-Host -NoNewline "Implementing" ($Script:xmlDB.Commands.Command.Name).Count "commands $nl"
    $date = Get-Date -Format "yyyymmddHHmm"
    $file = "tmp" + $date + ".psm1"
    "#Temporary YAUS Active Directory Shell File" > $file
    $file = Get-ChildItem -Path .\$file
    ForEach($command in $Script:xmlDB.Commands.Command) {
        $arguments = ""
        $argumentsManual = ""
        $examplesMaual = ""
        
        $count = 1
        foreach ($example in $command.Examples.Example.value) {
            $examplesMaual += $nl + ".EXAMPLE " + $nl + $example
        }

        foreach ($param in $command.Arguments.Argument) {
            if($null -ne $param.default) {
                $default = ' = "' + $param.Default + '"'
                $defaultManual = "(default:" + $param.default + ")"
            }
            else {
                $default = ""
                $defaultManual= ""
            }
            $arguments += "$nl[Parameter(Position=" + $param.Position + ", Mandatory=$" + $param.Mandatory + ")][" + $param.Type + "]" + "$" + $param.Name + $default
            if($count -lt ($command.Arguments.Argument).Count) {$arguments += ","}
            $argumentsManual += $nl + ".PARAMETER " +  $param.Name + $nl
            if($param.Mandatory -eq "True") { $argumentsManual += "[Mandatory]" }
            $argumentsManual += $param.description + $defaultManual
            $count++
        }
        $manual = $nl + "<# " + $nl + ".SYNOPSIS " + $nl + $command.synopsis + $nl + ".DESCRIPTION " + $nl + $command.description + $argumentsManual + $examplesMaual + $nl +"#>" + $nl
        "function ADSH-" + $command.Name + "{" + $manual + "param(" + $arguments + $nl + ")" + $nl + $command.code + $nl + "}" >> $file
    }
    Import-Module $file
    Remove-Item $file
}
function getObjectStructure {
    $global:objects = @()
    $tempObjects = Get-ADObject -Filter '*'
    $tempObjects | ForEach-Object {
        if($_.objectClass -ne "domainDNS"){
            $prevObject = $_.DistinguishedName -replace '^[^,]*,', ""
            $_ | Add-Member -NotePropertyName PreviousObject -NotePropertyValue $prevObject -Force
            $global:objects += $_
        }
        else {
            $global:objects += $_
        }
    }
}
function runCommand($commandInput) {
    if ($commandInput -eq "exit"){return $true}
    if ($commandInput -ne "") {
        $commandInput = "ADSH-" + $commandInput
        Invoke-Expression $commandInput
    }
    return $false
}
function inputCommand {
    $CliPrompt = $env:UserName + "@" + $env:ComputerName + ":~/"
    $outputArray = @()
    if ($global:currentLoc -ne $global:ADSHhome) {
        $global:currentLoc.DistinguishedName.split(",") | Where-Object {$_ -notmatch 'DC=.*'} | ForEach-Object {
        $outputArray += $_.split("=")[1]
    }
    for ($i = $outputArray.count - 1; $i -ge 0; $i--) {
        $CliPrompt += $outputArray[$i] + "/"
    }
    }
    $CliPrompt += ">"
    Write-Host -NoNewline $CliPrompt
    $commandInput = Read-Host
    if(runCommand($commandInput)){return $true}
}
function runCLI {
    Clear-Host
    Write-Output "ADSH $global:Adshversion"
    $global:ADSHhome = $global:objects | Where-Object {$_.objectClass -eq "domainDNS"}
    $global:currentLoc = $global:ADSHhome
    while(1){If (inputCommand){return}}
}
function ADSH {
    $osType = checkOS
    if($osType -eq 1) {
        Clear-Host
        Read-Host "You do not run windows server..."$nl"In order to use ADSH run script in wndows server..."$nl"Exiting to YAUS.."
        return
    }
    elseif ($osType -eq 3) {
        Clear-Host
        $ifUpgrade = Read-Host "Your server is not domain controller do you want to promote it to domain controller. This will require a restart.(y/n)[Default:y]"
        if ($ifUpgrade -eq "n") {
            return
        }
        Write-Output "Checking if AD Feature is installed and installing if needed..."
        Add-WindowsFeature AD-Domain-Services -Confirm
        Write-Output "Enter domain name to promote server to domain controller"
        $domainName = Read-Host -Prompt "Domain Name"
        if (Read-Host -Prompt "Do you want to install extra Active Directory tools?[y/n](default:n)" -eq "y") {
            Add-WindowsFeature *AD*
        }
        Install-ADDSForest -InstallDNS -DomainName $domainName
        Write-Output "Rebooting..."
        Restart-Computer
        exit
    }
    getObjectStructure
    getFiles
    implementCommands
    runCLI
}

