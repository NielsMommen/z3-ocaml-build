$ErrorActionPreference = "Stop"

<# 
    0 - Turns off script tracing.
    1 - Traces each line of the script as it is executed. 
        Lines in the script that are not executed are not traced. 
        Does not display variable assignments, function calls, or external scripts.
    2 - Traces each line of the script as it is executed. 
        Lines in the script that are not executed are not traced. 
        Displays variable assignments, function calls, and external scripts.
#>
Set-PSDebug -Trace 1

$cygwin_exe = "cygwin-setup-x86_64.exe"
$cygwin_url = "https://cygwin.com/setup-x86_64.exe"
$mirror = "http://ftp.inf.tu-dresden.de/software/windows/cygwin32/"
$script_dir = (Get-Location).ToString()
$cygwin_dir = "$script_dir\cygwin"
$prefix_dir = "$(($script_dir).Replace("\", "/"))/prefix"
$cygwin_dir_unix = ($cygwin_dir).Replace("\", "/")

function Cygpath {
    param(
        [System.IO.FileInfo]$path
    )
    return &"$cygwin_dir\bin\cygpath.exe" """$path"""
}

function MkDir {
    param(
        [System.IO.FileInfo]$path
    )
    If (!(Test-Path -PathType Container $path)) {
        New-Item -ItemType Directory -Path $path
    }
}

function LcBash {
    param(
        [String]$cmd
    )
    &"$cygwin_dir\bin\bash.exe" "-lc" """$cmd"""
    if ($lastexitcode -ne 0) {
        throw ("Error...")
    }
}

$pkgs = [String]::Join(" ", (
        @(
            "coreutils"
            "make"
            "mingw64-x86_64-gcc-g++"
            "mingw64-x86_64-gmp"
            "curl"
            "python"
        ) | ForEach-Object { "-P " + $_ }
    ))



Invoke-WebRequest -Uri "$cygwin_url" -OutFile "$cygwin_exe"

Start-Process -NoNewWindow -FilePath "$cygwin_exe" -ArgumentList "-B -qnNd -R cygwin -l $cygwin_dir_unix/var/cache/setup -s $mirror $pkgs" -Wait -PassThru
"none /cygdrive cygdrive binary,posix=0,user,noacl 0 0" | Out-File -FilePath "$cygwin_dir\etc\fstab" -Encoding "utf8"

MkDir $prefix_dir
LcBash "cd $(Cygpath "$script_dir") && make PREFIX=$prefix_dir"