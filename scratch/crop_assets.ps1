Add-Type -AssemblyName System.Drawing

function Crop-Image($srcPath, $destPath, $x, $y, $w, $h) {
    $src = [System.Drawing.Image]::FromFile($srcPath)
    $rect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), $rect, [System.Drawing.GraphicsUnit]::Pixel)
    $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    $src.Dispose()
    Write-Host "Saved $destPath ($w x $h)"
}

$src = 'C:/Users/ayber/.gemini/antigravity/brain/4e3092de-b1d4-41bf-898a-c8efa8b70e90/.user_uploaded/media_1794250088963_aaebe1aa.jpg'

Crop-Image $src 'assets/images/logo.png' 20 33 145 42
Crop-Image $src 'assets/images/logo_icon.png' 22 34 40 38
Crop-Image $src 'assets/images/student_ayberk.png' 265 110 68 70
Crop-Image $src 'assets/images/student_ayberk_dark.png' 266 410 68 70
Crop-Image $src 'assets/images/instructor_mustafa.png' 595 105 72 72
Crop-Image $src 'assets/images/instructor_mustafa_dark.png' 595 408 72 72
Crop-Image $src 'assets/images/mascot_robot.png' 858 535 130 135
Crop-Image $src 'assets/images/campus_building.png' 348 240 148 100
Crop-Image $src 'assets/images/campus_students.png' 10 565 160 100

