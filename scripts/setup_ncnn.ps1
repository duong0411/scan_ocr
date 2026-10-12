# PowerShell Script to setup NCNN Android Vulkan SDK and PaddleOCR models
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  PADDLE OCR & NCNN ENVIRONMENT SETUP   " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$AppDir = Split-Path -Parent $PSScriptRoot
$CppDir = Join-Path $AppDir "android\app\src\main\cpp"
$NcnnTargetDir = Join-Path $CppDir "ncnn-android-vulkan"
$ModelsDir = Join-Path $AppDir "assets\models"

# 1. Create directories
if (-not (Test-Path $CppDir)) { New-Item -ItemType Directory -Path $CppDir -Force }
if (-not (Test-Path $ModelsDir)) { New-Item -ItemType Directory -Path $ModelsDir -Force }

# 2. Download NCNN Android Vulkan SDK if missing
if (-not (Test-Path $NcnnTargetDir)) {
    Write-Host "`n[1/2] Downloading Tencent NCNN Android Vulkan SDK..." -ForegroundColor Yellow
    $NcnnZipUrl = "https://github.com/Tencent/ncnn/releases/download/20240410/ncnn-20240410-android-vulkan.zip"
    $ZipPath = Join-Path $CppDir "ncnn-android.zip"
    
    try {
        Invoke-WebRequest -Uri $NcnnZipUrl -OutFile $ZipPath -UseBasicParsing
        Write-Host "Extracting NCNN SDK..." -ForegroundColor Green
        Expand-Archive -Path $ZipPath -DestinationPath $CppDir -Force
        Remove-Item -Path $ZipPath -Force
        
        # Rename unzipped folder to ncnn-android-vulkan
        $ExtractedFolder = Get-ChildItem -Path $CppDir -Directory | Where-Object { $_.Name -like "ncnn*android*" -and $_.Name -ne "ncnn-android-vulkan" } | Select-Object -First 1
        if ($ExtractedFolder) {
            Rename-Item -Path $ExtractedFolder.FullName -NewName "ncnn-android-vulkan"
        }
        Write-Host "NCNN Android SDK installed successfully!" -ForegroundColor Green
    } catch {
        Write-Warning "Could not download NCNN prebuilt SDK automatically: $_"
        Write-Host "You can manually place the extracted ncnn-android-vulkan into: $CppDir" -ForegroundColor Gray
    }
} else {
    Write-Host "[1/2] NCNN Android SDK already exists at: $NcnnTargetDir" -ForegroundColor Green
}

# 3. Download PaddleOCR v4 NCNN models and dictionary
Write-Host "`n[2/2] Setting up PaddleOCR models..." -ForegroundColor Yellow
$BaseModelUrl = "https://github.com/nihui/ncnn-assets/raw/master/models"
$DictUrl = "https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/release/2.7/ppocr/utils/ppocr_keys_v1.txt"

$Files = @(
    @{ Name = "ch_PP-OCRv4_det_infer.param"; Url = "$BaseModelUrl/ch_PP-OCRv4_det_infer.param" },
    @{ Name = "ch_PP-OCRv4_det_infer.bin"; Url = "$BaseModelUrl/ch_PP-OCRv4_det_infer.bin" },
    @{ Name = "ch_PP-OCRv4_rec_infer.param"; Url = "$BaseModelUrl/ch_PP-OCRv4_rec_infer.param" },
    @{ Name = "ch_PP-OCRv4_rec_infer.bin"; Url = "$BaseModelUrl/ch_PP-OCRv4_rec_infer.bin" },
    @{ Name = "ppocr_keys_v1.txt"; Url = $DictUrl }
)

foreach ($item in $Files) {
    $FilePath = Join-Path $ModelsDir $item.Name
    if (-not (Test-Path $FilePath)) {
        Write-Host "Downloading $($item.Name)..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -Uri $item.Url -OutFile $FilePath -UseBasicParsing
        } catch {
            Write-Warning "Failed to download $($item.Name): $_"
        }
    } else {
        Write-Host "$($item.Name) already exists." -ForegroundColor Gray
    }
}

Write-Host "`nDone! Your PaddleOCR + NCNN mobile environment is configured." -ForegroundColor Green
