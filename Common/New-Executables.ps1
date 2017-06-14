param(
	[Parameter(Mandatory = $true)][string]$Path
)
class Executable {
	[string]$Name
	[System.Management.Automation.Language.Ast]$Ast
	[string]$TypeName
	[System.Collections.Generic.List[Executable]]$References
	[System.Collections.Generic.List[Executable]]$ReferencedBy
 	Executable($name,$ast) {
		$this.Name = $name
		$this.Ast = $ast
		$this.TypeName = $ast.GetType().Name
		$this.References = [System.Collections.Generic.List[Executable]]::new()
		$this.ReferencedBy = [System.Collections.Generic.List[Executable]]::new()
	}
	[void]AddReference([Executable]$reference) {
		if(-not ($this.References.Contains($reference))) {
			$this.References.Add($reference)
		}
		if(-not ($Reference.referencedBy.Contains($this))) {
			$Reference.referencedBy.Add($this)
		}
	}
}
class Executables {
	[string]$ScriptName
    [System.Collections.Generic.Dictionary[string,Executable]]$ex
    Executables([string]$Path) {
		$this.ex = [System.Collections.Generic.Dictionary[string,Executable]]::new()
        $this.ScriptName = [System.IO.Path]::GetFileName($path)
		[System.Management.Automation.Language.Token[]]$tokens=$null
		[System.Management.Automation.Language.ParseError[]]$errors=$null
		[System.Management.Automation.Language.ScriptBlockAst]$script=$null
		$script=[System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
		$this.AddExecutable($this.ScriptName, $script)
        $fns = $script.FindAll({ param($ast) ($ast.GetType().Name -eq 'FunctionDefinitionAst')}, $false)
        $fns |
            foreach {
		        if (-not $this.Contains($_.Name)) {
                     $this.AddExecutable($_.Name, $_)
		        } else { Write-Host "$($_.Name) already exists" }
            }
        $this.ex.Values |
            foreach {
                $this.FindExecutableReferences($_)
            }
	}
    [Executable]AddExecutable($name, [System.Management.Automation.Language.Ast]$ast) {
		[Executable]$executable = [Executable]::New($name,$ast)
		$this.ex.Add($name,$executable)
		return $executable
	}
	[void]FindExecutableReferences ([Executable]$executable) {
        switch -Exact -CaseSensitive ($executable.TypeName) {
            'FunctionDefinitionAst' {
                [System.Management.Automation.Language.FunctionDefinitionAst]$fd = $executable.ast
                $this.FindStatementsReferences($executable, $fd.Body.EndBlock.Statements)
                Break
            }
            'ScriptBlockAst' {
                [System.Management.Automation.Language.ScriptBlockAst]$sb = $executable.ast
                $this.FindStatementsReferences($executable, $sb.EndBlock.Statements)
                Break
            }
            'StatementBlockAst' {
                [System.Management.Automation.Language.StatementBlockAst]$smb = $executable.ast
                $this.FindStatementsReferences($executable, $smb.Statements)
                Break
            }
            default {
            }
        }
    }
    [void]FindStatementsReferences([Executable]$executable, [System.Collections.ObjectModel.ReadOnlyCollection[System.Management.Automation.Language.StatementAst]]$statements){
        $statements |
	        where {($_ -ne $null) -and ($_.GetType().Name -ne 'FunctionDefinitionAst') } |
	        foreach {
		        $this.FindStatementReferences($executable, $_)
	        }
    }
    [void]FindStatementReferences ([Executable]$executable, [System.Management.Automation.Language.StatementAst]$statement) {
	    $commands = $statement.FindAll({ param($ast) ($ast.GetType().Name -eq 'CommandAst')}, $true)
        foreach($command in $commands) {
            $this.FindCommandReferences($executable, $command)
        }
    }
    [void]FindCommandReferences ([Executable]$executable, [System.Management.Automation.Language.CommandBaseAst]$command) {
	    [System.Management.Automation.Language.CommandAst]$c = $command
	    if ($c.CommandElements.count -gt 0) {
		    $action = $c.CommandElements[0]
            $actionType = $action.GetType().Name
		    if (@('ExpandableStringExpressionAst', 'StringConstantExpressionAst') -contains $actionType) {
                $a = $action
			    if ($this.Contains($a.Value)) {
				    $ref = $this.GetExecutable($a.Value)
				    if ($executable -ne $null)
				    {
					    $executable.AddReference($ref)
				    }
			    }
		    }
	    }
    }
    [bool]Contains([object]$key)
    {
        return $this.ex.ContainsKey($key);
    }

    [void]Add([object]$key, [object]$value)
    {
        $this.ex.Add($key, $value);
    }

    [void]Clear()
    {
        $this.ex.Clear();
    }

    [System.Collections.IDictionaryEnumerator]GetEnumerator()
    {
        return $this.ex.GetEnumerator();
    }

    [void]Remove([object]$key)
    {
        $this.ex.Remove($key);
    }

    [object]GetExecutable([object]$key)
    {
        return $this.ex[$key];
    }

    [int]Count()
    {
        return $this.ex.Count;
    }
}
[Executables]::new($Path)
