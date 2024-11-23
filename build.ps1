# TODO: Download directly from massgrave
$imagePath = "install.wim"
$index = 2  # TODO: replace with name
curl.exe "https://akaneko-dev.sasha0552.org/install.wim" --output $imagePath
#####
# Create a temporary directory
$mountDir = New-TemporaryFile | %{ mkdir $_-d }

# Mount the Windows image
Mount-WindowsImage -ImagePath $imagePath -Index $index -Path $mountDir

# Remove capabilities not in the desired list
$desiredCapabilities = "Language.Basic~~~en-US~0.0.1.0", "Windows.Client.ShellComponents~~~~0.0.1.0"
foreach ($capability in $(Get-WindowsCapability -Path $mountDir)) {
  if ($desiredCapabilities -notcontains $capability.Name) { # and $capability.State -eq Installed
    Remove-WindowsCapability -Name $capability.Name -Path $mountDir
  }
}

# Disable and remove features not in the desired list
$desiredFeatures = "MSRDC-Infrastructure"
foreach ($feature in $(Get-WindowsOptionalFeature -Path $mountDir)) {
  if ($desiredFeatures -notcontains $feature.FeatureName) {
    Disable-WindowsOptionalFeature -FeatureName $feature.FeatureName -Path $mountDir -Remove
  }
}

# Reset the base of the Windows image and clean up components
Repair-WindowsImage -Path $mountDir -ResetBase -StartComponentCleanup

# Optimize the Windows image for WIMBoot
Optimize-WindowsImage -Path $mountDir -OptimizationTarget WIMBoot

# Dismount the mounted Windows image and save changes
Dismount-WindowsImage -Path $mountDir -Save

# Export the modified Windows image to a new WIM file
Export-WindowsImage -SourceImagePath $imagePath -SourceIndex $index -DestinationImagePath winthin.wim
