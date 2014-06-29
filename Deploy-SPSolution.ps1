function Deploy-SPSolution
{ 
    <#  
    .SYNOPSIS  
    This function is used to deploy a .wsp solution package to SharePoint Server
    .DESCRIPTION  
    Mandatory parameters:
    SolutionFileName
    WebAppUrl
    FilePath: The path to the program to perform the action on 
    .EXAMPLE 
    Deploy-SPSolution -SolutionFileName "Test.wsp" -WebAppUrl "http:\\testwebapp.com" 
    .EXAMPLE 
    Deploy-SPSolution -SolutionFileName "Test.wsp" -WebAppUrl "http:\\testwebapp.com" -SolutionPath "C:\TestSolutionLocation"
    #>  
    [CmdletBinding()] 
    param( 
		[Parameter(Position=0,Mandatory=$True,
        HelpMessage="Enter the name of the wsp solution file")]
		[string]$SolutionFileName,
		
		[Parameter(Position=1,Mandatory=$True,
        HelpMessage="Enter the web apllication url")]
		[string]$WebAppUrl,

		[Parameter(Position=2,Mandatory=$False,
        HelpMessage="Enter a the path to the wsp solution file")]
		[string]$SolutionPath,
		
		[Parameter(Position=3,Mandatory=$False,
        HelpMessage="Enter a list of web application features that you want to activate")]
		[string]$WebAppFeatures,
		
		[Parameter(Position=4,Mandatory=$False,
        HelpMessage="Enter a the ip address that you want to check")]
		[string]$SiteCollectionRelativeUrl,
		
		[Parameter(Position=5,Mandatory=$False,
        HelpMessage="Enter the site collection url")]
		[string]$SiteCollectionFeatures
    )

    function WaitForSPSolutionJobToComplete([string]$solutionName)
    {
        $solution = Get-SPSolution -Identity $solutionName -ErrorAction SilentlyContinue
 
        if ($solution)
        {
            if ($solution.JobExists)
            {
                Write-Host -NoNewLine "Waiting for timer job to complete for solution '$solutionName'."
            }
         
            while ($solution.JobExists)
            {
                $jobStatus = $solution.JobStatus
             
                if ($jobStatus -eq [Microsoft.SharePoint.Administration.SPRunningJobStatus]::Succeeded)
                {
                    Write-Host "Solution '$solutionName' timer job suceeded"
                    return $true
                }
             
                if ($jobStatus -eq [Microsoft.SharePoint.Administration.SPRunningJobStatus]::Aborted -or
                    $jobStatus -eq [Microsoft.SharePoint.Administration.SPRunningJobStatus]::Failed)
                {
                    Write-Host "Solution '$solutionName' has timer job status '$jobStatus'."
                    return $false

			    }
             
                Write-Host -NoNewLine "."
                Sleep 1
            }
         
            Write-Host
        }
     
        return $true
    }

    $snapin = Get-PSSnapin | Where-Object {$_.Name -eq ‘Microsoft.SharePoint.Powershell’}

    if ($snapin -eq $null)
    {
        Write-Host “Loading SharePoint Powershell”
        Add-PSSnapin “Microsoft.SharePoint.Powershell”
        Write-Host
    }

    try
    {
        if($WebAppFeatures)
        {
	        Foreach($webAppFeature in $WebAppFeatures)
	        {
		        Write-Host "Disabling Feature $webAppFeature ..." -NoNewline
                try
                {
		            Disable-SPFeature –Identity $webAppFeature –url $WebAppUrl -Confirm:$false
                }
                catch
                {
                    Write-Host
                    Write-Host $UnexpectedError -ForegroundColor red
                    Write-Host $_.Exception.Message -ForegroundColor red
                    Write-Host
                }

		        Write-Host "... done"
	        }
        }

        if($SiteCollectionUrl -and $SiteCollectionFeatures)
        {
	        $siteCollectionAbsolutPath = Join-Path -Path $WebAppUrl -ChildPath $SiteCollectionRelativeUrl

	        Foreach($siteCollectionFeature in $SiteCollectionFeatures)
	        {
		        Write-Host "Disabling Feature $siteCollectionFeature ..." -NoNewline
                
                try
                {
		            Disable-SPFeature –Identity $webAppFeature –url $siteCollectionAbsolutPath -Confirm:$false
                }
                catch
                {
                    Write-Host
                    Write-Host $UnexpectedError -ForegroundColor red
                    Write-Host $_.Exception.Message -ForegroundColor red
                    Write-Host
                }

		        Write-Host "... done"
	        }
        }

        Write-Host

        Write-Host "Uninstalling the solution ..." -NoNewline
        Uninstall-SPSolution –Identity $SolutionFileName –WebApplication $WebAppUrl -Confirm:$false
        Write-Host "... done"
        Write-Host

        WaitForSPSolutionJobToComplete $SolutionFileName

        Write-Host "Removing the solution ..." -NoNewline
        Remove-SPSolution –Identity $SolutionFileName -Confirm:$false -Force
        Write-Host "... done"
        Write-Host

        $solutionLiteralPath = $SolutionFileName

        if($SolutionPath)
        {
            $solutionLiteralPath = Join-Path -Path $SolutionPath -ChildPath $SolutionFileName
        }

        if(-Not(Test-Path $solutionLiteralPath))
        {
            Write-Host
            Write-Host "Solution file was not found. Terminating script" -ForegroundColor red
            Write-Host
            #Exit
        }

        Write-Host "Adding the solution ..." -NoNewline
        Add-SPSolution -LiteralPath $solutionLiteralPath
        Write-Host "... done"
        Write-Host

        Write-Host "Installing the solution ..." -NoNewline
        Install-SPSolution -Identity $SolutionFileName –WebApplication $WebAppUrl -GACDeployment -Force
        Write-Host "... done"
        Write-Host

        WaitForSPSolutionJobToComplete $SolutionFileName

        if($WebAppFeatures)
        {
	        Foreach($webAppFeature in $WebAppFeatures)
	        {
		        Write-Host "Enabling Feature $webAppFeature ..." -NoNewline

                try
                {
		            Enable-SPFeature –Identity $webAppFeature –url $WebAppUrl
                }
                catch
                {
                    Write-Host
                    Write-Host $UnexpectedError -ForegroundColor red
                    Write-Host $_.Exception.Message -ForegroundColor red
                    Write-Host
                }

		        Write-Host "... done"
	        }
        }

        if($SiteCollectionUrl -and $SiteCollectionFeatures)
        {
	        $siteCollectionAbsolutPath = Join-Path -Path $WebAppUrl -ChildPath $SiteCollectionRelativeUrl

	        Foreach($siteCollectionFeature in $SiteCollectionFeatures)
	        {
		        Write-Host "Enabling Feature $siteCollectionFeature ..." -NoNewline

                try
                {
		            Enable-SPFeature –Identity $webAppFeature –url $siteCollectionAbsolutPath
                }
                catch
                {
                    Write-Host
                    Write-Host $UnexpectedError -ForegroundColor red
                    Write-Host $_.Exception.Message -ForegroundColor red
                    Write-Host
                }

		        Write-Host "... done"
	        }
        }
    }
    catch
    {
        Write-Host
        Write-Host $UnexpectedError -ForegroundColor red
        Write-Host $_.Exception.Message -ForegroundColor red
        Write-Host
        Exit
    }
}