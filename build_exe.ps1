# PowerShell script to build the Multi-Agent-CLI executable
# This script downloads the gpt-researcher repository, extracts it,
# and uses PyInstaller to create a standalone executable.

# Set environment variables for API keys
$env:PYTHONIOENCODING = "utf-8"

# Create a temporary directory for the download and extraction
$tempDir = Join-Path $env:TEMP "gpt-researcher-build"
$zipPath = Join-Path $tempDir "gpt-researcher.zip"
$extractPath = Join-Path $tempDir "extract"

# Create the temporary directory if it doesn't exist
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-Host "Created temporary directory: $tempDir"
}

# Clean up any previous extraction
if (Test-Path $extractPath) {
    Remove-Item $extractPath -Recurse -Force
    Write-Host "Cleaned up previous extraction"
}

# Create the extraction directory
New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

# Download the repository ZIP file
Write-Host "Downloading gpt-researcher repository..."
$repoUrl = "https://github.com/assafelovic/gpt-researcher/archive/refs/heads/master.zip"
Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Write-Host "Download complete: $zipPath"

# Extract the ZIP file
Write-Host "Extracting ZIP file..."
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
Write-Host "Extraction complete: $extractPath"

# Find the extracted directory (it will be named gpt-researcher-master)
$repoDir = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
Write-Host "Repository directory: $($repoDir.FullName)"

# Change to the repository directory
Set-Location $repoDir.FullName
Write-Host "Changed directory to: $($repoDir.FullName)"

# Clean up build artifacts
Remove-Item ./dist -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ./build -Recurse -Force -ErrorAction SilentlyContinue

# Remove unnecessary files and folders
Remove-Item ./frontend -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ./docs -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ./evals -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ./tests -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ./mcp-server -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ./CURSOR_RULES.md -Force -ErrorAction SilentlyContinue
Remove-Item ./CODE_OF_CONDUCT.md -Force -ErrorAction SilentlyContinue
Remove-Item ./CONTRIBUTING.md -Force -ErrorAction SilentlyContinue
Remove-Item ./LICENSE -Force -ErrorAction SilentlyContinue
Remove-Item ./Procfile -Force -ErrorAction SilentlyContinue
Remove-Item ./README-ja_JP.md -Force -ErrorAction SilentlyContinue
Remove-Item ./README-ko_KR.md -Force -ErrorAction SilentlyContinue
Remove-Item ./README-zh_CN.md -Force -ErrorAction SilentlyContinue
Remove-Item ./README.md -Force -ErrorAction SilentlyContinue
Remove-Item ./citation.cff -Force -ErrorAction SilentlyContinue

# Download Multi_Agent_CLI.py from GitHub
Write-Host "Downloading Multi_Agent_CLI.py from GitHub..."
$multiAgentCliUrl = "https://raw.githubusercontent.com/morganross/GPT-Researcher-Multi-Agent-CLI/master/Multi_Agent_CLI.py"
Invoke-WebRequest -Uri $multiAgentCliUrl -OutFile "Multi_Agent_CLI.py"
Write-Host "Downloaded Multi_Agent_CLI.py from GitHub"

# Determine if we're running from within the gpt-researcher directory or from a parent directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$scriptName = Split-Path -Leaf $scriptPath

# Check if the script is being run from within the gpt-researcher directory
# The directory structure can have either gpt_researcher or gpt-researcher
$isInGptResearcherDir = (Test-Path (Join-Path $scriptDir "gpt_researcher")) -or (Test-Path (Join-Path $scriptDir "gpt-researcher"))

# Debug output
Write-Host "Script directory: $scriptDir"
Write-Host "Running from within gpt-researcher directory: $isInGptResearcherDir"

# Check if gpt_researcher or gpt-researcher directory exists
$gptResearcherPath = ""
if (Test-Path (Join-Path $scriptDir "gpt_researcher")) {
    $gptResearcherPath = "gpt_researcher"
} elseif (Test-Path (Join-Path $scriptDir "gpt-researcher")) {
    $gptResearcherPath = "gpt-researcher"
}

Write-Host "GPT Researcher path: $gptResearcherPath"

# Get absolute paths for PyInstaller
$currentDir = Get-Location
Write-Host "Current directory: $currentDir"

if ($isInGptResearcherDir) {
    # Running from within gpt-researcher directory
    $retrieversPath = Join-Path $scriptDir "$gptResearcherPath\retrievers"
    Write-Host "Retrievers path: $retrieversPath"
    
    # Use absolute paths for PyInstaller
    python -m PyInstaller --onefile Multi_Agent_CLI.py --add-data "$retrieversPath;gpt_researcher/retrievers" --add-data "$(python -c 'import tiktoken; import os; print(os.path.dirname(tiktoken.__file__))');tiktoken" --hidden-import tiktoken --hidden-import=tiktoken_ext.openai_public --hidden-import=tiktoken_ext
} else {
    # Running from parent directory
    $retrieversPath = Join-Path $currentDir "gpt-researcher\$gptResearcherPath\retrievers"
    Write-Host "Retrievers path: $retrieversPath"
    
    # Use absolute paths for PyInstaller
    python -m PyInstaller --onefile ./gpt-researcher/Multi_Agent_CLI.py --add-data "$retrieversPath;gpt_researcher/retrievers" --add-data "$(python -c 'import tiktoken; import os; print(os.path.dirname(tiktoken.__file__))');tiktoken" --hidden-import tiktoken --hidden-import=tiktoken_ext.openai_public --hidden-import=tiktoken_ext
}

# Note: Keeping the terminal open after the executable runs is controlled by the Python script itself,
# not by this build script. You need to add a pause command (like input() or os.system("pause"))
# to the end of gpt-researcher/multi_agents/main.py to keep the terminal open.

# Copy the executable to the original directory
$exePath = Join-Path (Get-Location) "dist\Multi_Agent_CLI.exe"
$destPath = Join-Path (Split-Path -Parent $PSCommandPath) "Multi_Agent_CLI.exe"

if (Test-Path $exePath) {
    Write-Host "Copying executable to: $destPath"
    Copy-Item $exePath $destPath -Force
    Write-Host "Executable copied successfully!"
} else {
    Write-Host "Error: Executable not found at $exePath"
}

# Clean up temporary files
Write-Host "Cleaning up temporary files..."
Set-Location (Split-Path -Parent $PSCommandPath)
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Cleanup complete"

Write-Host "Build process completed. The executable is available at: $destPath"