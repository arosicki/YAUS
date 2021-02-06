################################################
#
# YAUS Networking Module v1.0.0
# Adrian Rosicki
#
################################################
function getNetworkingInformation {
    Clear-Host
    Write-Output "Reading neworking information"
    $interfaces = Get-NetAdapter -Physical
    Write-Output "."

    $script:networkAdapters = $interfaces | ForEach-Object {
        $ifNumber = $_.ifIndex
        $NetIPInterface = Get-NetIPInterface -erroraction 'silentlycontinue' -InterfaceIndex $ifNumber -AddressFamily IPv4
        $NetIPAddress = Get-NetIPAddress -erroraction 'silentlycontinue' -AddressFamily IPv4 -InterfaceIndex $ifNumber


        New-Object -TypeName psobject -Property @{
                ifIndex                  = $ifNumber
                Name                     = $_.Name
                InterfaceDescription     = $_.InterfaceDescription
                Status                   = $_.Status
                MacAddress               = $_.MacAddress
                LinkSpeed                = $_.LinkSpeed
                IPAddress                = $NetIPAddress.IPAddress
                Prefix                   = $NetIPAddress.PrefixLength
                AddressFamily            = $NetIPAddress.AddressFamily
                DHCP                     = $NetIPInterface.Dhcp
                }
    }
    Clear-Host
}
function displayNetworkingInformation($interface) {
    $interface | Sort-Object -Property ifIndex | Format-Table -Property ifIndex, Name, InterfaceDescription, Status, LinkSpeed, MacAddress, IPAddress, Prefix, AddressFamily, DHCP
}
function generateTxtFile {
    displayNetworkingInformation($script:networkAdapters) > ./networking-report.txt
    $file = Get-ChildItem ./networking-report.txt
    $file = $file.FullName
    Write-Output "Created file $file" "Press Enter to continue..."
Read-Host
}
function restartInterface($interface) {
    Restart-NetAdapter -Name $interface.Name
    Clear-Host
    Write-Output "Success" "Press Enter to continue..."
    Read-Host
    selectEditAction($interface.ifIndex)
}
function toggleInterface($interface) {
    Clear-Host
    if ($interface.Status -eq "Up") {
        Disable-NetAdapter -Name $interface.Name -Confirm:$false
        Start-Sleep -s 2
        Write-Output "Success"
    }
    elseif($interface.Status -eq "Disabled"){
        Enable-NetAdapter -Name $interface.Name
        Start-Sleep -s 2
        Write-Output "Success"
    }
    else {
        Write-Output "Your interface seems to be disconnected connect it to proceed, if you toggled your interface recently try again in few seconds"
    }
    Write-Output "Press Enter to continue..."
    Read-Host
    selectEditAction($interface.ifIndex)
}
function toggleDHCP($interface) {
    Clear-Host
    if($interfaceEdit.DHCP -eq "Disabled") {
        Set-NetIPInterface -InterfaceIndex $interface.ifIndex -Dhcp Enabled
        Restart-NetAdapter -Name $interface.Name
    }
    else {
        Set-NetIPInterface -InterfaceIndex $interface.ifIndex -Dhcp Disabled
    }
    Write-Output "Success" "Press Enter to continue..."
    Read-Host
    selectEditAction($interface.ifIndex)
}
function changeInterfaceName($interface) {
    Clear-Host
    $nameInput = Read-Host -Prompt "Enter new IP Address(or type C to Cancel)"
    if ($nameInput -eq "C"){
        selectEditAction($interface.ifIndex)
    }
    elseif($nameInput.Length -ge 2 -and $nameInput.Length -le 26) {
        Rename-NetAdapter -Name $interface.Name -NewName $nameInpu
        Clear-Host
        Read-Host -Prompt "Success $nl Press Enter to continue.."
        selectEditAction($interface.ifIndex)
    }
    else {
        Clear-Host
        Read-Host -Prompt "Your name is either too long or too short(network interface name should range between 2 and 26 characters) $nl Press Enter to continue.."
        changeInterfaceName($interface)
    }
    
}
function changeIPAddress($interface) {
    Clear-Host
    $ipInput = Read-Host -Prompt "Enter new IP Address(or type C to Cancel)"
    Clear-Host
    if ($ipInput -ne "C") {
        $isValid = [ipaddress]::TryParse($ipInput,[ref][ipaddress]::Loopback)
        if ($isValid) {
            if ($null -ne $interface.IPAddress) {
                Get-NetAdapter -ifIndex $interface.ifIndex | Get-NetIPAddress -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false
            }
            New-NetIPAddress -InterfaceIndex $interface.ifIndex -IPAddress $ipInput > $null
            Set-NetIPAddress -InterfaceIndex $interface.ifIndex -IPAddress $ipInput -PrefixLength $interface.Prefix > $null
            Read-Host -Prompt "Success $nl Press Enter to continue.."
            selectEditAction($interface.ifIndex)
        }
        else {
            Read-Host -Prompt "IP address is not valid try again... $nl Press Enter to continue.."
            changeIPAddress($interface)
        }
    } 
    else {
        selectEditAction($interface.ifIndex)
    }
    
}
function changePrefix($interface) {
    Clear-Host
    $pxInput = Read-Host -Prompt "Enter new prefix length(or type C to Cancel)"
    Clear-Host
    if ($pxInput -eq "C") {
        selectEditAction($interface.ifIndex)
    }
    elseif($pxInput -ge 0 -and $pxInput -le 32) {
        Set-NetIPAddress -InterfaceIndex $interface.ifIndex -IPAddress $interface.IPAddress -PrefixLength $pxInput
        Read-Host -Prompt "Success $nl Press Enter to continue.."
        selectEditAction($interface.ifIndex)
    }
    else {
        Read-Host -Prompt "Prefix length is not valid try again... $nl Press Enter to continue.."
        changePrefix($interface)
    }
}

function selectEditAction($ifNr) {
    Clear-Host
    getNetworkingInformation
    $interfaceEdit = $script:networkAdapters | Where-Object -Property ifIndex -eq -Value $ifNr
    $editOptions = @("Toggle Interface", "Change interface name")
    Write-Host -NoNewline "You selected interface $ifNr -" $interfaceEdit.InterfaceDescription $nl
    if ($interfaceEdit.Status -eq "Up") {
        $editOptions += ("Restart Interface", "Toggle DHCP")
        if ($interfaceEdit.DHCP -eq "Disabled") {$editOptions += "Edit IP Address";if($null -ne $interfaceEdit.IPAddress) {$editOptions += "Edit mask prefix"}} 
        else {
            Write-Output "Please note that in order to change prefix or IP Address you have to disable DHCP."
        }
    }
    else {
        Write-Output "Enable interface to edit it's properties."
    }
    displayNetworkingInformation($interfaceEdit)
    $editOptions += ("Refresh", "Cancel")
    for ($actionNr = 1; $actionNr -le $editOptions.Count; $actionNr++) {
        $a = $actionNr-1
        Write-Host -NoNewline $actionNr"." $editOptions[$a] $nl
    }
    $choiceNE = Read-Host -Prompt "Select your action"
    $choiceNE = [int]$choiceNE
    if ($interfaceEdit.Status -eq "Up") {
        if($interfaceEdit.DHCP -eq "Disabled") {
            switch ($choiceNE) {
                1 { toggleInterface($interfaceEdit);break }
                2 { changeInterfaceName($interfaceEdit); break }
                3 { restartInterface($interfaceEdit); break }
                4 { toggleDHCP($interfaceEdit); break }
                5 { changeIPAddress($interfaceEdit); break }
                6 { if($null -ne $interfaceEdit.IPAddress){changePrefix($interfaceEdit)}else{selectEditAction($ifNR)} break }
                7 { if($null -ne $interfaceEdit.IPAddress){selectEditAction($ifNR)}else{networkingMenu} break }
                8 { if($null -ne $interfaceEdit.IPAddress){networkingMenu}else{Clear-Host; Read-Host -Prompt "Select correct option... $nl Press Enter to continue..."; selectEditAction($ifNR)} break }
                Default {
                    Clear-Host
                    Read-Host -Prompt "Select correct option... $nl Press Enter to continue..."
                    selectEditAction($ifNR)
                }
            }
        }
        else {
            switch ($choiceNE) {
                1 { toggleInterface($interfaceEdit);break }
                2 { changeInterfaceName($interfaceEdit); break }
                3 { restartInterface($interfaceEdit); break }
                4 { toggleDHCP($interfaceEdit); break }
                5 { selectEditAction($ifNR); break }
                6 { networkingMenu; break }
                Default {
                    Clear-Host
                    Read-Host -Prompt "Select correct option... $nl Press Enter to continue..."
                selectEditAction($ifNR)
            }
            }
        }
    }
    else {
        switch ($choiceNE) {
            1 { toggleInterface($interfaceEdit);break }
            2 { changeInterfaceName($interfaceEdit); break }
            3 { selectEditAction($ifNR); break }
            4 { networkingMenu; break }
            Default {Clear-Host
                Read-Host -Prompt "Select correct option... $nl Press Enter to continue..."
            selectEditAction($ifNR)
        }
        }
    } 
}
function selectNetworkInterface {
    Clear-Host
    displayNetworkingInformation($script:networkAdapters)
    $netEChoice =  Read-Host -Prompt "Type in ifIndex of interface you want to edit(type anything else to exit to menu)"
    if ( ($script:networkAdapters.ifIndex) -contains $netEChoice ) {
        selectEditAction($netEChoice)
    }
    else {
        Clear-Host
        Write-Output "Returning to menu..." "Press enter to continue..."
        Read-Host
        networkingMenu
    }
}
function exportNetworkInterfaceInformation {
    Clear-Host
    Write-Output "1. As .txt file" "2. Exit to main menu"
    $netDChoice = Read-Host -Prompt "How do you want to export data?"
    $netDChoice = [int]$netDChoice
    switch ($netDChoice) {
        1 { generateTxtFile; networkingMenu; break }
        2 { networkingMenu; break }
        Default {
            Clear-Host
            Write-Output "Select correct option..." "Press Enter to continue..."
            Read-Host
            exportNetworkInterfaceInformation
        }
}
}
function networkingMenu {
    Clear-Host
    Write-Output "
 _ YAUS   _______ _________          _______  _______  _       _________ _        _______ 
( (    /|(  ____ \\__   __/|\     /|(  ___  )(  ____ )| \    /\\__   __/( (    /|(  ____ \ TM
|  \  ( || (    \/   ) (   | )   ( || (   ) || (    )||  \  / /   ) (   |  \  ( || (    \/
|   \ | || (__       | |   | | _ | || |   | || (____)||  (_/ /    | |   |   \ | || |      
| (\ \) ||  __)      | |   | |( )| || |   | ||     __)|   _ (     | |   | (\ \) || | ____ 
| | \   || (         | |   | || || || |   | || (\ (   |  ( \ \    | |   | | \   || | \_  )
| )  \  || (____/\   | |   | () () || (___) || ) \ \__|  /  \ \___) (___| )  \  || (___) |
|/    )_)(_______/   )_(   (_______)(_______)|/   \__/|_/    \/\_______/|/    )_)(_______)                                                                                       
Interfaces:"
   displayNetworkingInformation($script:networkAdapters)
   Write-Output "1. Edit Network Configuration" "2. Output Information to external file" "3. Exit to YAUS"
    $netChoice = Read-Host -Prompt "What do you want to do?"
    $netChoice = [int]$netChoice
    switch ($netChoice) {
        1 { selectNetworkInterface; break }
        2 { exportNetworkInterfaceInformation; break }
        3 { return }
        Default {
            Clear-Host
            Write-Output "Select correct option..." "Press Enter to continue..."
            Read-Host
            networkingMenu
        }
    }
}
function Networking {
    getNetworkingInformation
    networkingMenu
}