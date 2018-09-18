# C9_Azure_Discovery.ps1 
#
# Version: 12-29-2017
#
# Updates: 
#              - changed logging messages, added check if user already conneced to azure, fixed passing of parameters - 12/29 KMC
#
# Description: Allows user to run various Cloud 9 discovery scripts with the output 
#              written to Excel spreadsheets. 
#              1. Logs the user into Azure
#              2. User selects one or more Azure subscriptions
#              3. User selects one or more Discovery scripts to run
#              4. For each subscription, the selected discovery scripts are run
#              5. An Excel spreadsheet is created for each subscription withh a different
#                 sheet for each discovery run
#
# Prerequisites: arm-discovery.xml is in the same directory
#                Scripts for all the modules are in the same directory
#                Office is installed on the machine running the script 
#                Listed Azure Modules are installed on the machine running the script
#                    -AzureRM - 4.1.0
#                    -AzureRM.Profile - 3.1.0
#                    -AzureRM.Compute - 3.1.0
#                    -AzureRM.Storage - 3.1.0
#                    -AzureRM.Resources - 4.1.0
#
# Usage: C9_Azure_Discovery.ps1 -OutFile <Excel file name> [ -LogFile < log file name > ]                            
#
# Example: .\C9_Azure_Discovery.ps1  -LogFile abc.txt -OutFile xyz.xlsx
#

[CmdletBinding(DefaultParameterSetName="Default")]
param(
  [string]$LogFile,
  [parameter(Mandatory, ParameterSetName="Default")]
  [string]$OutFile
)

function DisplayMessage ($LogFilePath, $Message) { 
  write-host $Message 
  if ($LogFilePath.Length -gt 0) {Out-File -FilePath $LogFilePath -InputObject $Message -Append}
}

function PreReq($JSONFile, $json) {
  $Pass = $False
  foreach($Module in $json.Modules.Module)  {
    $scriptPath = ""
    $scriptPath = ".\" + $Module.Script 
    if(Test-Path $scriptPath) {
      $Pass = $True
    }
    else {
      $Pass = $False
      return $Pass
    }
  }
  return $Pass
}

function PreReqModules($ModuleversionName, $ModuleVersionMajor) {

  $result = $True

  $a = (Get-Module -Name $ModuleversionName -ListAvailable).Version.Major
  if($a -lt $ModuleVersionMajor){$result = $False }

  return $result
}

function Add-Excel-WorkSheet-Data {
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True)]
        [string[]]$DiscoveryData
    )

    Begin {  # Add Worksheet 
      # Get Count of worksheets 
      $WorkSheetCount = $workbook.Worksheets.Count
      # Create New worksheet 
      $WorkSheet = $workbook.Worksheets.Add()
      $WorkSheet.Name = [string]$SelectedModule.Name
    }

    Process {  # add Row of Data       
      # Add Results to Cells 
      $Cells = $DiscoveryData.Split(',') 
      $i=0
      foreach ($Cell in $Cells) {      
        if ($i -eq 0) { $Row = $Cell }
        else { $WorkSheet.Cells.Item($Row,$i) = $Cell }
        $i++
      }
      
    }

    End {        
    }
}

function ConnectToAzure() {
   if ([string]::IsNullOrEmpty($(Get-AzureRmContext).Account)) {
     $login = Login-AzureRmAccount -ErrorAction SilentlyContinue
     if($login -ne $null) {return $true}
     else {return $false } 
   } 
   else {return $true}
}

function SelectSubscription() {    
    
    #Creating multi-select listbox
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "Subscriptions"
    $objForm.Size = New-Object System.Drawing.Size(500,200) 
    $objForm.StartPosition = "CenterScreen"

    $objForm.KeyPreview = $True

    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        {
            $objForm.Close()
        }
        })

    #Creating Buttons of the listbox.
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(165,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"

    $OKButton.Add_Click(
        {
            $objForm.Close()
            
        })

    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(260,120)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $objForm.CancelButton = $CancelButton
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click(
        {
            
            $objListbox.SelectedItems.Clear()
            $objForm.Close()
            
           
        })
    
    $objForm.Controls.Add($CancelButton)


    #Adding label to multi-select listbox
    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,20) 
    $objLabel.Size = New-Object System.Drawing.Size(480,20) 
    $objLabel.Text = "Please make a selection from the list of subscriptions below:"
    $objForm.Controls.Add($objLabel) 
        
    $objListbox = New-Object System.Windows.Forms.Listbox 
    $objListbox.Location = New-Object System.Drawing.Size(10,40) 
    $objListbox.Size = New-Object System.Drawing.Size(460,40) 

    $objListbox.SelectionMode = "MultiExtended"

    #Getting list of subscriptioins in the logged in Azure RM Account
    $Subscriptions = Get-AzureRMSubscription
    
    if($Subscriptions -eq $null){
        
        $selsubs += "SLF"
    }
    else
    {
        #Adding entries to Multi-select listbox created in the earlier steps
        foreach ($Subscription in $Subscriptions) 
        { 
            [void] $objListBox.Items.Add($Subscription.Name)
  
        }

        $objListbox.Height = 70
        $objForm.Controls.Add($objListbox) 
        $objForm.Topmost = $True

        $objForm.Add_Shown({$objForm.Activate()})
        [void] $objForm.ShowDialog()

        
        $selsubs = $objListbox.SelectedItems
        
    }
      
    return $selsubs
}

function SelectDiscovery() {    
    
    #Creating multi-select listbox
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "Discoveries"
    $objForm.Size = New-Object System.Drawing.Size(700,400) 
    $objForm.StartPosition = "CenterScreen"

    $objForm.KeyPreview = $True

    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        {
            $objForm.Close()
        }
        })

    #Creating Buttons of the listbox.
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(185,320)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"

    $OKButton.Add_Click(
        {
            $objForm.Close()
        })

    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(330,320)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click(
        {
            $objListbox.SelectedItems.Clear()
            
            $objForm.Close()
        
        })

    $objForm.Controls.Add($CancelButton)

    #Adding label to multi-select listbox
    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,20) 
    $objLabel.Size = New-Object System.Drawing.Size(670,20) 
    $objLabel.Text = "Please make a selection from the list of Discoveries below:"
    $objForm.Controls.Add($objLabel) 

    $objListbox = New-Object System.Windows.Forms.Listbox 
    $objListbox.Location = New-Object System.Drawing.Size(10,40) 
    $objListbox.Size = New-Object System.Drawing.Size(640,40) 

    $objListbox.SelectionMode = "MultiExtended"
    
    foreach ($x in $json.Modules.Module.Name ) {
    
    [void] $objListbox.Items.Add($x)

    }

    
    $objListbox.Height = 270
    $objForm.Controls.Add($objListbox) 
    $objForm.Topmost = $True

    $objForm.Add_Shown({$objForm.Activate()})
    [void] $objForm.ShowDialog()

    $seldis = $objListbox.SelectedItems

    return $seldis
    
}

#....................Main...................#

# initialize variables
$JSONFile = ".\arm-discovery.json"
$selsubs = @()
$sedis = @()

# load Module info from json file 
$json = get-content -Path $JSONFile | ConvertFrom-Json


DisplayMessage $LogFile "Script Initiated"

if(PreReq $JSONFile $json) {
  if(PreReqModules "AzureRM" "4" ) { 
    DisplayMessage $LogFIle "Passed prerequisite checks"
    DisplayMessage $LogFile "Connecting to Azure"
    if(ConnectToAzure) {
      DisplayMessage $LogFile "Prompting user to select subscriptions"
      $selsubs = SelectSubscription
      if($selsubs -eq $null) {
        DisplayMessage $LogFile "No subscriptions selected "
      }
      elseif($selsubs -eq "SLF") {DisplayMessage $LogFile "No subscriptions available"}
      else {
        
        $msg = "User selected the following Subscriptions: " 
        foreach ($selsub in $selsubs) { $msg = $msg + '[' + $selsub + '] ' }
        DisplayMessage $LogFile $msg

        DisplayMessage $LogFile "Prompting user to select discoveries"

        $seldis = SelectDiscovery 
        if($seldis -eq $null)  {DisplayMessage $LogFile "No discovery scripts selected"}
        else  {
          
          $msg = "User selected the following Discoveries: " 
          foreach ($s in $seldis) { $msg = $msg + '[' + $s + '] ' }
          DisplayMessage $LogFile $msg
          
          foreach($sub in $selsubs){
            
            # Creating excel
            DisplayMessage $LogFile "Creating an Excel spreadsheet for subscription: $sub"
            $excel = New-Object -ComObject excel.application
            $excel.visible = $True

            # Adding a workbook
            $workbook = $excel.Workbooks.Add()

            # Build Array of selected Modules           
            $SelectedModules = @()
            foreach ($Module in $json.Modules.Module) { 
             if($seldis -contains $Module.Name) { $SelectedModules += $Module }     
            }
             
            # Execute Module Discovery Scripts and add to Excel spreadsheet
            $i=0
            foreach ($SelectedModule in $SelectedModules ) {
              $msg = "Checking prerequisites for module: " + $SelectedModule.Name
              DisplayMessage $LogFile $msg
              $pass = PreReqModules $SelectedModule.ModuleVersion.Name $SelectedModule.ModuleVersion.Version
              if($pass) {
    
                $msg = "Prerequisite check passed for module: " + $SelectedModule.Name
                DisplayMessage $LogFile $msg
                
                # Script 
                $cmd = ".\" + $SelectedModule.Script

                # Parmaters
                $parms = @()

                # subscription parameter
                $parms += '-' + [string]$SelectedModule.SParameter.Name 
                $parms += [char]39 + $sub + [char]39

                # optional parameters 
                foreach ($OParm in $SelectedModule.Oparameter) { 
                  $parms +=  '-' + $OParm.Name 
                  
                  if ($OParm.Value.Contains(' ')) { $parms += [char]39 + $OParm.Value + [char]39 } 
                  else { $parms += $OParm.Value }
                }               
                                
                $msg = "Executing " + $SelectedModule.Name + " module: " + $cmd 
                foreach ($parm in $parms) {$msg = $msg + ' ' + $parm}
                DisplayMessage $LogFile $msg

                invoke-expression "$cmd $parms" | Add-Excel-WorkSheet-Data 
                $i++
              }
              else {
                $msg = "Prerequisite check failed for module: " + $SelectedModule.ModuleVersion.Name
                DisplayMessage $LogFile $msg
              }           
            }

            #Saving Excel file
            DisplayMessage $LogFile "Saving Excel spreadsheet for $sub"
     
            $Path = [io.path]::GetDirectoryName($OutFile)
            $FileName = [io.path]::GetFileNameWithoutExtension($OutFile)
            $OutPutFileName = $Path + '\' + $FileName + "-" + $sub          
            
            $workbook.SaveAs($OutPutFileName)
            $excel.Quit()
          }
        }
      }
    }
    else {DisplayMessage $LogFile "Azure login failed"}
  }
  else {DisplayMessage $LogFile "Failed prerequisite check for PowerShell modules"}
}
else {DisplayMessage $LogFile "Discovery scripts missing"}