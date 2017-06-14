param (
	[Parameter(Mandatory = $true)][string]$Path,
	[Parameter(Mandatory = $true)][string]$InputDir,
	[Parameter(Mandatory = $true)][string]$ModuleName
)

$moduleDir = "$InputDir\$ModuleName"
$functionDir = "$moduleDir\Functions"

[System.Text.StringBuilder]$fns = New-Object System.Text.StringBuilder
Get-ChildItem $functionDir |
	foreach {
		gc $_.FullName |
			foreach {$fns.AppendLine($_)} | Out-Null
		$fns.AppendLine() | Out-Null
	}

$scriptName = [System.IO.Path]::GetFileName($Path)
$scriptLines = [string[]]$scriptLines = gc "$moduleDir\$scriptName"
$script = $scriptLines -join "`r`n"
$script.Replace('## <Functions> ##',$fns.ToString()) | Out-File ".\$scriptName"