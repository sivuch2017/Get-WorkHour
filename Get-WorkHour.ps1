# �ݒ�ǂݍ���
$BaseDir = Split-Path $MyInvocation.MyCommand.path
$EnvFile = Join-Path $BaseDir "env.ps1"
. $EnvFile

# �O���[�o���ϐ�
$script:eigyo = 0
$script:result = @()
$script:shell = New-Object -ComObject Shell.Application

# �又��
Function execMain {
    Param([String]$url, [String]$user, [String]$pass)
    
    $ie = New-Object -ComObject InternetExplorer.Application
    $script:hwnd = $ie.HWND

    $ie.Visible = $true
    $ie.Navigate($url, 4)
    waitBusy([ref]$ie)

    @($ie.Document.getElementsByName("loginId"))[0].value = $user
    @($ie.Document.getElementsByName("passwd"))[0].value = $pass
    $ie.Document.getElementById("login_button").click()
    waitBusy([ref]$ie)

    # �����ȍ~�Abyname�Abyclass�Aattributes ���܂Ƃ��Ɏ擾�ł��Ȃ����ߌ��ߑł��Ŏ擾�B

    @(@($ie.Document.getElementsByTagName("table"))[3].getElementsByTagName("a"))[2].click()
    waitBusy([ref]$ie)

    @($ie.Document.getElementsByTagName("table"))[7].getElementsByTagName("tr") | ForEach-Object {
        $td = $_.getElementsByTagName("td") | %{$_.innerText.ToString()}
        if ($td) {
            if ($td[0] -match ".+\(([^)]+)\)") {
                $td[0] = $Matches[1] + "`t"
            }
            $script:result += $td -join ","
        }
    }

    if ($script:eigyo -eq 0) {
        $a = @(@($ie.Document.getElementsByTagName("table"))[7].getElementsByTagName("a"))[0]
        $a.target = "_self"
        $a.click()
        waitBusy([ref]$ie)

        @($ie.Document.getElementsByTagName("table"))[4].getElementsByTagName("tr") | foreach-object -begin {$c = 0; $p = 0} -process {if ($_.outerHTML -match "workhourtable") {$c++; if ($_.outerHTML -match "pink") {$p++};}} -end {$script:eigyo = $c - $p}
    }
    $ie.Quit()
}

# IE�����҂�
Function waitBusy {
    Param([ref]$ie)
    $ie.value = @($shell.Windows() | ? {$_.HWND -eq $hwnd})[-1]
    while ($ie.value.busy -or $ie.value.readystate -ne 4) {
        Start-Sleep -Milliseconds 100
    }
}

# �又���N���E�o��
foreach ($key in $users.Keys) {
    execMain $topurl $users[$key][0] $users[$key][1]
}
$result = @("�����̉c�Ɠ���`t,${eigyo},��") + $result
$result | Out-File -FilePath $csvfile -Encoding default
