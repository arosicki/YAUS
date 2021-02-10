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
function checkOS {
    Clear-Host
    Write-Output "Checking prerequisities"
    return (Get-ComputerInfo).OsProductType
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
        "function Y-" + $command.Name + "{" + $manual + "param(" + $arguments + $nl + ")" + $nl + $command.code + $nl + "}" >> $file
    }
    Import-Module $file
    Remove-Item $file
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
        $ifUpgrade = Read-Host "Your server is not domain controller do you want to promote it to domain controller(y/n)[Default:y]"$nl
        if ($ifUpgrade -eq "n") {
            return
        }
    }
    runCLI
    $Script:version = "v1.0.0"
    getFiles
    implementCommands
    Y-Test "Test"
}