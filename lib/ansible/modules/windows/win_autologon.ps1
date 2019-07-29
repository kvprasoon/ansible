#!powershell

# Copyright: (c) 2019, Prasoon Karunan V (@prasoonkarunan) <kvprasoon@Live.in>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
Set-StrictMode -Version 2.0

$ErrorActionPreferrence = 'Stop'
$spec = @{
    options = @{
        domain = @{type = "str"; default = $env:userdomain}
        user = @{type = "str"; required = $true}
        password = @{type = "str"; required = $true}
        state = @{type = "str"; choices = "absent","present"; default = "present"}
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args,$spec)
$domain = $module.params.domain
$user = $module.params.user
$password = $module.params.password
$state = $module.params.state

try {
''>c:\temp\t.log
    #Build ParamHash

    $autoAdminLogon = 1
    $stateMessage = 'added'
    if($state -eq 'absent'){
        $autoadminlogon = 0
        $stateMessage = 'removed'
    }
    $module.Result.Msg     = "Auto logon registry keys are already $stateMessage"
    $autoLogonKeyList   = @{
        DefaultPassword = $password
        DefaultUserName = $user
        DefaultDomain   = $domain
        AutoAdminLogon  = $autoAdminLogon
    }
    $actionTaken = $null
    $autoLogonRegPath   = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\'
    $autoLogonKeyRegList   = Get-ItemProperty -Path $autoLogonRegPath -Name $autoLogonKeyList.GetEnumerator().Name -ErrorAction SilentlyContinue

    Foreach($key in $autoLogonKeyList.GetEnumerator().Name){
        "Checking Key $key" >> c:\temp\t.log
        $currentKeyValue = $autoLogonKeyRegList | Select-Object -ExpandProperty $key -ErrorAction SilentlyContinue
        if (-not [String]::IsNullOrEmpty($currentKeyValue)) {
            $expectedValue = $autoLogonKeyList[$key]
            "Checking currentKey $currentKeyValue" >> c:\temp\t.log
            if(($state -eq 'present') -and ($currentKeyValue -ne $expectedValue)) {
                Set-ItemProperty -Path $autoLogonRegPath -Name $key -Value $autoLogonKeyList[$key] -Force
                $actionTaken = $true
            }
            elseif($state -eq 'absent') {
                $actionTaken = $true
                Remove-ItemProperty -Path $autoLogonRegPath -Name $key -Force
            }
        }
        else {
            "else Checking currentKey $currentKeyValue" >> c:\temp\t.log
            if ($state -eq 'present') {
                $actionTaken = $true
                New-ItemProperty -Path $autoLogonRegPath -Name $key -Value $autoLogonKeyList[$key] -Force | Out-Null
            }
        }
    }
    if($actionTaken){
        $module.Result.Msg     = "Auto logon registry keys are $stateMessage"
        $module.Result.changed = $true
    }
}
catch {
  $module.FailJson($_.Exception.Message)
}

$module.ExitJson()
