@echo off
setlocal
set DB_NAME=parking_system
set BACKUP_DIR=%~dp0..\backup
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
set FILE=%BACKUP_DIR%\parking_system_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.sql
set FILE=%FILE: =0%

echo Creating full backup: %FILE%
mysqldump -uroot -p --default-character-set=utf8mb4 --routines --triggers --events %DB_NAME% > "%FILE%"
if errorlevel 1 (
  echo Backup failed. Please check MySQL account/password and mysqldump path.
  exit /b 1
)
echo Backup finished.
endlocal
