<#
.SYNOPSIS
  Obtain current licenses used and maximum available for Microsoft 365 SKU with PRTG.
.DESCRIPTION
  Typically this script is placed in the following location on a PRTG Probe.  Insert how to setup an application ID in Azure Active Directory.  Setup a device and sensors in PRTG with inheritance of Windows credentials.
  Test
.PARAMETER Username
  Application ID
.PARAMETER Password
  Application Secret
.PARAMETER Hostname
  Tenant Hostname
.PARAMETER SKU
  Microsoft 365 SKU
.INPUTS
  <Does the script accept an input>
.OUTPUTS
  A log file in the temp directory of the user running the script
.NOTES
  Version:        0.1
  Author:         Scott Stancil
  Creation Date:  20230303
  Purpose/Change: Initial script development
.EXAMPLE
  Directly from the command line, an example could be manually entered to see the XML result.
  PRTG-CheckM365Licensing.ps1 -Username appid -Password appsecret -Hostname tenantname.onmicrosoft.com -SKU M365EDU_A3_FACULTY
#>

# Accept basic SkuPartNumber you want to check as an argument
param( # Parameter help description 

[Parameter(Mandatory)]
[string]$username,

[Parameter(Mandatory)]
[string]$password,


[Parameter(Mandatory)]
[string]$hostname,

[Parameter(Mandatory)]
[string]$sku

)

#Force TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;


$checkSkuPartNumber = $sku;

# Define AppId, secret and scope, your tenant name and endpoint URL
$AppId = $username
$AppSecret = $password
$Scope = "https://graph.microsoft.com/.default"
$TenantName = $hostname

$Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"

# Add System.Web for urlencode
Add-Type -AssemblyName System.Web

# Create body
$Body = @{
	client_id = $AppId
	client_secret = $AppSecret
	scope = $Scope
	grant_type = 'client_credentials'
}

# Splat the parameters for Invoke-Restmethod for cleaner code
$PostSplat = @{
    ContentType = 'application/x-www-form-urlencoded'
    Method = 'POST'
    # Create string by joining bodylist with '&'
    Body = $Body
    Uri = $Url
}

# Request the token!
$Request = Invoke-RestMethod @PostSplat

# Create Header
$Header = @{ Authorization = "$($Request.token_type) $($Request.access_token)" }

# Setup URI
$uri = "https://graph.microsoft.com/v1.0/subscribedSkus"

# Create licensing request
$licensingRequest = Invoke-RestMethod -Uri $uri -Headers $Header -Method Get -ContentType "application/json"

# Obtain the value from licensing
$allSubscribedLicensesArray = $licensingRequest.value

$licensingValue = $allSubscribedLicensesArray | Where-Object {$_.skuPartNumber -eq $checkSkuPartNumber}

# Setup PRTG Return Format
"<prtg>"

# Setup PRTG Result
 "<result>"
 "<channel>AssignedLicenses</channel>" 
 "<value>"+ $licensingValue.consumedUnits +"</value>"
 "</result>"

 "<result>"
 "<channel>MaxLicenses</channel>" 
 "<value>"+ $licensingValue.prepaidUnits.enabled +"</value>"
 "</result>"

 "<result>"
 "<channel>SuspendedLicenses</channel>" 
 "<value>"+ $licensingValue.prepaidUnits.suspended +"</value>"
 "</result>"

 "<result>"
 "<channel>WarningLicenses</channel>" 
 "<value>"+ $licensingValue.prepaidUnits.warning +"</value>"
 "</result>"

 "<text>No Text</text>"
 "</prtg>"
