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
    Write-Output "."
}
function displayNetworkingInformation {
    $script:networkAdapters | Sort-Object -Property ifIndex | Format-Table -Property ifIndex, Name, InterfaceDescription, Status, LinkSpeed, MacAddress, IPAddress, Prefix, AddressFamily, DHCP
}
function generateTxtFile {
    displayNetworkingInformation > ./networking-report.txt
    $file = Get-ChildItem ./networking-report.txt
    $file = $file.FullName
    Write-Output "Created file $file
Press Enter to continue..."
Read-Host
}
function selectEditAction($ifNr) {
    $interface = $script:networkAdapters | Where-Object -Property ifIndex -eq -Value $ifNr
    Write-Host -NoNewline "You selected interface $ifNr -" $interface.InterfaceDescription $nl
     
}
function selectNetworkInterface {
    Clear-Host
    displayNetworkingInformation
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
   displayNetworkingInformation
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
