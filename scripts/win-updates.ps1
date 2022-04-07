Set-ExecutionPolicy RemoteSigned -Force
Install-PackageProvider -Name NuGet -Force
Install-Module -Name PSWindowsUpdate -Force
Get-WindowsUpdate -AcceptAll -Download -Install -MicrosoftUpdate 