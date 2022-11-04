echo Deleting unauthorized filetypes...

set filetypes=mp3 mov mp4 avi mpg mpeg flac m4a flv ogg gif png jpg jpeg
cd C:\Users
:: %%i = file extension
for %%i in (!filetypes!) do (
    choice /c yn /m "Delete .%%i files? "
    if !ERRORLEVEL! equ 1 (
        echo Deleting .%%i files...
          :: %%a = individual file
        for /f "delims=" %%a in ('dir /s /b *.%%i') do (
            choice /c yno /m "Delete %%a? "
            if !ERRORLEVEL! equ 1 (
                echo Deleting %%a...
                del "%%a"
            ) else (
                if !ERRORLEVEL! equ 2 (
                    echo Skipping %%a...
            ) else (
                    explorer.exe %%a\..
            )
        )
    )
) else (
    echo Skipping .%%i files...
    )
)
