param (
  [string]$SecretName = "demo-secret",
  [string]$Namespace = "default",
  [Parameter(Mandatory)] [string]$Key,
  [Parameter(Mandatory)] [SecureString]$Password
)

# Convert SecureString to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)

# Encode in base64
$Encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($UnsecurePassword))

# Output Kubernetes secret manifest
@"
apiVersion: v1
kind: Secret
metadata:
  name: $SecretName
  namespace: $Namespace
type: Opaque
data:
  $Key: $Encoded
"@ | Set-Content "$SecretName-secret.yaml"

Write-Output "Secret manifest written to $SecretName-secret.yaml with base64-encoded $Key"
