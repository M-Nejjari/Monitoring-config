# Usage examples:
#   pwsh -File k8s/encode-secrets.ps1 -Username admin -Password adminpassword -Uri "mongodb://admin:adminpassword@mongodb:27017/mern?authSource=admin" -Namespace travelmemory
#   pwsh -File k8s/encode-secrets.ps1  # will prompt for values

param(
  [string]$Username,
  [SecureString]$Password,
  [string]$Uri,
  [string]$Namespace = "travelmemory",
  [string]$SecretName = "mongo-secrets"
)

if (-not $Username) { $Username = Read-Host "Enter Mongo root username" }
if (-not $Password) { $Password = Read-Host -AsSecureString "Enter Mongo root password" }
if (-not $Uri) { $Uri = Read-Host "Enter Mongo connection URI" }

function ToBase64([string]$s) {
  return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($s))
}

$script:SecureToPlain = {
  param([SecureString]$Secure)
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
  try { [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

$b64User = ToBase64 $Username
$plainPassword = & $script:SecureToPlain $Password
$b64Pass = ToBase64 $plainPassword
$b64Uri  = ToBase64 $Uri

Write-Output "# Paste under data: in your Kubernetes Secret"
Write-Output "apiVersion: v1"
Write-Output "kind: Secret"
Write-Output "metadata:"
Write-Output "  name: $SecretName"
Write-Output "  namespace: $Namespace"
Write-Output "type: Opaque"
Write-Output "data:"
Write-Output "  MONGO_INITDB_ROOT_USERNAME: $b64User"
Write-Output "  MONGO_INITDB_ROOT_PASSWORD: $b64Pass"
Write-Output "  MONGO_URI: $b64Uri"

