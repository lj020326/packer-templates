# // first argument is mapped to $url
## https://bernhardelbl.wordpress.com/2013/03/21/download-and-install-a-certificate-to-your-trusted-root-using-powershell/
param($url)

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

[System.Uri] $u = New-Object System.Uri($url)
[Net.ServicePoint] $sp = [Net.ServicePointManager]::FindServicePoint($u);

[System.Guid] $groupName = [System.Guid]::NewGuid()

# // create a request
[Net.HttpWebRequest] $req = [Net.WebRequest]::create($url)
$req.Method = "GET"
$req.Timeout = 600000 # = 10 minutes
$req.ConnectionGroupName = $groupName

# // Set if you need a username/password to access the resource
#$req.Credentials = New-Object Net.NetworkCredential("username", "password");

[Net.HttpWebResponse] $result = $req.GetResponse()

$sp.CloseConnectionGroup($groupName)

$fullPathIncFileName = $MyInvocation.MyCommand.Definition

$currentScriptName = $MyInvocation.MyCommand.Name

$currentExecutingPath = $fullPathIncFileName.Replace($currentScriptName, "")

$outfilename = $currentExecutingPath + "Export.cer"

[System.Byte[]] $data = $sp.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
[System.IO.File]::WriteAllBytes($outfilename, $data)
Write-Host $outfilename

CertUtil -addStore Root $outfilename
