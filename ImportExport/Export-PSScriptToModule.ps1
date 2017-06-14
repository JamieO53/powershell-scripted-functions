param (
	[Parameter(Mandatory = $true)][string]$Path,
	[Parameter(Mandatory = $true)][string]$OutputDir,
	[Parameter(Mandatory = $true)][string]$ModuleName
)

$moduleDir = "$OutputDir\$ModuleName"
$functionDir = "$moduleDir\Functions"

if (-not (Test-Path $functionDir)) {
	md -Path $functionDir
}

$functions = .\New-Executables.ps1 -Path $Path
$scriptName = $functions.ScriptName
$functions.ex.Values |
	where {$_.TypeName -eq 'FunctionDefinitionAst' } |
	foreach {
		$outputPath = "$functionDir\$($_.Name).ps1"
		$_.Ast.Extent.Text | Out-File $outputPath -Encoding utf8
	}


$scriptModule = '$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

"$moduleRoot\Functions\*.ps1" |
resolve-path |
where-object { -not ($_.Path.tolower().contains(".tests.")) } |
foreach-object { . $_.Path }
' + (
	$functions.ex[$scriptName].References |
		foreach { "
Export-ModuleMember $($_.Name)"
		}
)
$scriptModule | Out-File "$moduleDir\$ModuleName.psm1" -Encoding utf8

$fnMinOffset=0
$fnMaxOffset=0

$functions.ex.Values |
	where {$_.TypeName -eq 'FunctionDefinitionAst' } |
	foreach { $_.Ast.Extent } |
	Measure-Object -Property 'StartOffset','EndOffset' -min -max |
	foreach {
		if ( $_.Property -eq 'StartOffset' ) {
			$fnMinOffset = $_.Minimum
		}
		elseif ( $_.Property -eq 'EndOffset' ) {
			$fnMaxOffset = $_.Maximum
		}
	}

$script = $functions.ex[$scriptName].Ast.Extent.Text

$script.Substring(0,$fnMinOffset - 1) + '## <Functions> ##' + $script.Substring($fnMaxOffset + 1) |
	Out-File "$moduleDir\$scriptName" -Encoding utf8
