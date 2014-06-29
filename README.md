Deploy-SPSolution
=================

A PowerShell cmdlet for deploying a .wsp solution package to SharePoint Server.

To initialize the cmdlet in a PowerShell prompt run:

`. .\Deploy-SPSolution.ps1`

Mandatory parameters:
- SolutionFileName
- WebAppUrl

Examples:

`Deploy-SPSolution -SolutionFileName "Test.wsp" -WebAppUrl "http:\\testwebapp.com

Deploy-SPSolution -SolutionFileName "Test.wsp" -WebAppUrl "http:\\testwebapp.com" -SolutionPath "C:\TestSolutionLocation"`
