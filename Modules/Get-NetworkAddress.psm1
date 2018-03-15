Function Get-NetworkAddress
{
    param (
        [IpAddress]$ip,
        [IpAddress]$Mask
    )
 
    $IpAddressBytes = $ip.GetAddressBytes()
    $SubnetMaskBytes = $Mask.GetAddressBytes()
 
    if ($IpAddressBytes.Length -ne $SubnetMaskBytes.Length) {
        throw "Lengths of IP address and subnet mask do not match."
        exit 0
    }
 
    $BroadcastAddress = @()
 
    for ($i=0;$i -le 3;$i++) {
        $BroadcastAddress += $ipAddressBytes[$i]-band $subnetMaskBytes[$i]
 
    }
 
    $BroadcastAddressString = $BroadcastAddress -Join "."
    return [IpAddress]$BroadcastAddressString
}
