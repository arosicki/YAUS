function getNetworkingInformation {
    $interfaces = Get-NetAdapter -Physical

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

    $script:networkAdapters |
    Sort-Object -Property ifIndex | ft -A -Property ifIndex, Name, InterfaceDescription, Status, LinkSpeed, MacAddress, IPAddress, Prefix, AddressFamily, DHCP
}




function Networking {
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
   getNetworkingInformation
   Read-Host -Prompt "Type ifIndex of interface you want to edit"
}
