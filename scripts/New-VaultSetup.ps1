[CmdletBinding()]
param (
    [Parameter()]
    [string]$VaultAddress = "aci-cm-vault-demo.westeurope.azurecontainer.io:8200"
)

Begin {
    # Set environment variables
    $env:VAULT_ADDR = "http://{0}" -f $VaultAddress
    $env:VAULT_SKIP_VERIFY = $true

    $vaultConfigPath = "./.vault/config"
}

Process {
    # Get vault status
    function Get-VaultStatus {
        # Vault status actually returns an array
        # in order to have a proper hash table I iterate through the array
        # and dismiss the useless values
        $status = @()
        $output = @{}
        $retry = $true
        $retryCount = 0
        while ($retry) {
            $status = vault status
            if ($status -match "Error checking seal status") {
                Write-Verbose -Message "Probably container did not yet initialize"
                Start-Sleep -Seconds 5
                $retryCount++
            }
            else {
                $retry = $false
                continue
            }
            $retry = $retryCount -lt 3
        }
        
        $status = vault status
        foreach ($element in $status) {
            if (($element -match "Key" -and $element -match "Value") -or ($element -match "---")) {
                continue
            }
            else {
                if ($element.Split(" ")[1] -ne "") {
                    $outputKey = $element.Split(" ")[0] + " " + $element.Split(" ")[1]
                }
                else {
                    $outputKey = $element.Split(" ")[0]
                }
                $output += @{$outputKey = $element.Split(" ")[-1]}
            }
        }
        return $output
    }
    $vaultStatus = Get-VaultStatus
    if ($vaultStatus["Initialized"] -match "false") {
        $vaultInit = vault operator init -key-shares=1 -key-threshold=1
        if (-not (Test-Path -Path $vaultConfigPath)) {
            New-Item -Path $vaultConfigPath -Force
        }
        Set-Content -Path $vaultConfigPath -Value $vaultInit
    }

    $config = Get-Content -Path $vaultConfigPath
    $keyShare = $config[0].Split(" ")[-1]

    if ($vaultStatus["Sealed"] -match "true") {
        vault operator unseal $keyShare
    }

    # At this point Vault should be ready to use
    # This is very specific for the init command
    # NOTE: if key-shares parameter in 'init' phase had changed this might not be accurate
    $null = vault login $config[2].Split(" ")[-1]

    $vaultSecretsList = vault secrets list
    if (-not ($vaultSecretsList -match "kv/")) {
        vault secrets enable kv
    }
}

