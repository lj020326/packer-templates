$ProgressPreference="SilentlyContinue"

for ([byte]$c = [char]'A'; $c -le [char]'Z'; $c++)  
{  
	$variablePath = [char]$c + ':\variables.ps1'

	if (test-path $variablePath) {
		. $variablePath
		break
	}
}

## ref: https://devblogs.microsoft.com/scripting/windows-powershell-invalid-certificates-and-automated-downloading/
## ref: https://bhargavs.com/index.php/2014/03/17/ignoring-ssl-trust-in-powershell-using-system-net-webclient/
Function Get-WebPage
{
    Param(
        $url,
        $file,
        [switch]$force
    )
    if($force)
    {
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    }
    $webclient = New-Object system.net.webclient
    $webclient.DownloadFile($url,$file)
} #end function Get-WebPage


# $version = '7.0.2'
$version = '7.1.4'
$msi_file_name = "ultradefrag-portable-$($version).bin.amd64.zip"

if ($httpIp){
	if (!$httpPort){
    	$httpPort = "80"
    }
    $download_url = "http://$($httpIp):$($httpPort)/$msi_file_name"
} else {
#     $download_url = "http://downloads.sourceforge.net/project/ultradefrag/stable-release/$($version)/$($msi_file_name)"
    $download_url = "https://archiva.admin.dettonville.int/repository/internal/org/dettonville/infra/ultradefrag-portable/$($version).bin.amd64/$($msi_file_name)"
}

$download_path = "C:\Windows\Temp\$msi_file_name"
$install_path = "C:\Windows\Temp\ultradefrag"

Get-WebPage -url $download_url -file $download_path –force
&"7z.exe" e -y -o"$install_path" "$download_path" *\udefrag.exe *\*.dll

if ($SkipDefrag){
	Write-Host "Skipping defrag"
	exit 0
}

# &"$install_path\udefrag.exe" --optimize --repeat $($env:SystemDrive)
&"$install_path\udefrag" --optimize --repeat $($env:SystemDrive)
