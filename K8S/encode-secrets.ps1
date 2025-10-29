# Usage examples:
#   pwsh -File k8s/encode-secrets.ps1 -Username admin -Password adminpassword -Uri "mongodb://admin:adminpassword@mongodb:27017/mern?authSource=admin" -Namespace travelmemory
#   pwsh -File k8s/encode-secrets.ps1  # will prompt for values

param(
  [string]$Username,
  [string]$Password,
  [string]$Uri,
  [string]$Namespace = "travelmemory",
  [string]$SecretName = "mongo-secrets"
)

if (-not $Username) { $Username = Read-Host "Enter Mongo root username" }
if (-not $Password) { $Password = Read-Host -AsSecureString "Enter Mongo root password" | ForEach-Object { [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_)) } }
if (-not $Uri) { $Uri = Read-Host "Enter Mongo connection URI" }

function ToBase64([string]$s) {
  return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($s))
}

$b64User = ToBase64 $Username
$b64Pass = ToBase64 $Password
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

