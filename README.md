# PsAutomationHelpers
A few PowerShell scripts that make Build process easier

Install windows
```
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest https://raw.githubusercontent.com/pkudrel/PsAutomationHelpers/master/install.ps1 -OutFile install.ps1 ; ./install.ps1 ; Remove-Item ./install.ps1
```


