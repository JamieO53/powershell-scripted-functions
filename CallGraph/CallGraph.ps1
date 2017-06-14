param(
	[Parameter(Mandatory = $true)][string]$Path,
	[Parameter(Mandatory = $true)][string[]]$GraphHeads,
	[string[]]$ExternalReferences,
	[string]$Label
)

Function References ([string]$head){
	$function = $functions.GetExecutable($head)
	$function.references |
		where { $_.Name -ne 'Log'} |
		foreach {
			if ( $externals -contains $head) {
				$prefix = '{ node [shape=octagon]; '
				$suffix = ' }'
				"$prefix`"$head`"$suffix"
			}
			else {
				if ( $externals -contains $_.Name) {
					$prefix = '{ node [shape=octagon]; '
					$suffix = ' }'
					"$prefix`"$head`"$suffix"
				}
				else {
					$prefix = ''
					$suffix = ';'
				}
				"`"$head`" -> $prefix`"$($_.Name)`"$suffix"
				if ($_.Name -ne $head) {
					References -head $_.Name
				}
			}
		}
}

$scriptFile=$Path
$scriptName=[System.IO.Path]::GetFileName($Path)

$heads = $GraphHeads
$externals = if( $ExternalReferences -ne $null) { $ExternalReferences } else { @() }

$functions = .\New-Executables.ps1 -Path $scriptFile

"strict digraph `"$scriptName`" {"
'compound=true;'
'rankdir=LR;'
'pencolor=white;'
'node [shape=box fontsize=12];'
$heads |
	foreach {
		$head = $_
		"subgraph `"cluster$head`" {"
		if ( $externals -contains $head) {
			$prefix = '{ node [shape=octagon]; '
			$suffix = ' }'
			"$prefix`"$head`"$suffix"
		}
		else {
			References -head $head
			$prefix = ''
			$suffix = ';'
		}
		'}'
		$functions.GetExecutable($head).referencedBy |
			where { $_.name -eq $scriptName } |
			foreach {
				"`"$($_.Name)`" -> $prefix`"$head`"$suffix"
			}
	}
'fontsize=16'
"label=`"$Label`";"
'}'
