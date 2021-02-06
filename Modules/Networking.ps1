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
    Write-Output "Created file $file
Press Enter to continue..."
Read-Host
}
function restartInterface($interface) {
    Restart-NetAdapter -Name $interface.Name
    Clear-Host
            Write-Output "Success
Press Enter to continue..."
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

}
function changeIPAddress($interface) {

}
function changePrefix($interface) {

}





function selectEditAction($ifNr) {
    Clear-Host
    getNetworkingInformation
    $interfaceEdit = $script:networkAdapters | Where-Object -Property ifIndex -eq -Value $ifNr
    $editOptions = @("Restart Interface", "Toggle Interface", "Toggle DHCP")
    Write-Host -NoNewline "You selected interface $ifNr -" $interfaceEdit.InterfaceDescription $nl
    if ($interfaceEdit.DHCP -eq "Disabled") {$editOptions += ("Edit IP Address", "Edit mask prefix")} else {Write-Output "Please note that in order to change prefix or IP Address you have to disable DHCP."}
    displayNetworkingInformation($interfaceEdit)
    $editOptions += "Cancel"
    for ($actionNr = 1; $actionNr -le $editOptions.Count; $actionNr++) {
        $a = $actionNr-1
        Write-Host -NoNewline $actionNr"." $editOptions[$a] $nl
    }
    $choiceNE = Read-Host -Prompt "Select your action"
    $choiceNE = [int]$choiceNE
    switch ($choiceNE) {
        1 { restartInterface($interfaceEdit); break }
        2 { toggleInterface($interfaceEdit);break }
        3 { toggleDHCP($interfaceEdit);break }
        4 { if ($interfaceEdit.DHCP -eq "Enabled"){networkingMenu} else {
            changeIPAddress($interfaceEdit)}break}
        5 { if ($interfaceEdit.DHCP -eq "Disabled"){changePrefix($interfaceEdit)} else {Clear-Host
            Write-Output "Select correct option...
Press Enter to continue..."
            Read-Host
            selectEditAction($ifNR)}break}
        6 { if ($interfaceEdit.DHCP -eq "Disabled"){networkingMenu} else {Clear-Host
            Write-Output "Select correct option...
Press Enter to continue..."
            Read-Host
            selectEditAction($ifNR)}break}
        Default {
            Clear-Host
            Write-Output "Select correct option...
Press Enter to continue..."
            Read-Host
            selectEditAction($ifNR)
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
        Write-Output "Returning to menu...
Press enter to continue..."
        Read-Host
        networkingMenu
    }
}
function exportNetworkInterfaceInformation {
    Clear-Host
    Write-Output "1. As .txt file
2. Exit to main menu"
    $netDChoice = Read-Host -Prompt "How do you want to export data?"
    $netDChoice = [int]$netDChoice
    switch ($netDChoice) {
        1 { generateTxtFile; networkingMenu; break }
        2 { networkingMenu; break }
        Default {
            Clear-Host
    Write-Output "Select correct option...
Press Enter to continue..."
Read-Host
exportNetworkInterfaceInformation
        }
}
}
function networkingMenu {
    Clear-Host
    Write-Output "
 _        _______ _________          _______  _______  _       _________ _        _______ 
( (    /|(  ____ \\__   __/|\     /|(  ___  )(  ____ )| \    /\\__   __/( (    /|(  ____ \
|  \  ( || (    \/   ) (   | )   ( || (   ) || (    )||  \  / /   ) (   |  \  ( || (    \/
|   \ | || (__       | |   | | _ | || |   | || (____)||  (_/ /    | |   |   \ | || |      
| (\ \) ||  __)      | |   | |( )| || |   | ||     __)|   _ (     | |   | (\ \) || | ____ 
| | \   || (         | |   | || || || |   | || (\ (   |  ( \ \    | |   | | \   || | \_  )
| )  \  || (____/\   | |   | () () || (___) || ) \ \__|  /  \ \___) (___| )  \  || (___) |
|/    )_)(_______/   )_(   (_______)(_______)|/   \__/|_/    \/\_______/|/    )_)(_______)                                                                                       
Interfaces:"
   displayNetworkingInformation($script:networkAdapters)
   Write-Output "1. Edit Network Configuration
2. Output Information to external file
3. Exit to YAUS"
    $netChoice = Read-Host -Prompt "What do you want to do?"
    $netChoice = [int]$netChoice
    switch ($netChoice) {
        1 { selectNetworkInterface; break }
        2 { exportNetworkInterfaceInformation; break }
        3 { return }
        Default {
            Clear-Host
            Write-Output "Select correct option...
Press Enter to continue..."
            Read-Host
            networkingMenu
        }
    }
}
function Networking {
    getNetworkingInformation
    networkingMenu
}