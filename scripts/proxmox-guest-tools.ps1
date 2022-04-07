
msiexec /i E:\guest-agent\qemu-ga-x86_64.msi /log C:\msilog.txt /qn

$s = Get-Service QEMU-GA
Start-Service -InputObject $s