@echo off
setlocal
if "%~1"=="" (
  echo Usage: restore_database.bat path\to\backup.sql
  exit /b 1
)
set DB_NAME=parking_system

echo Restoring %DB_NAME% from %~1
mysql -uroot -p --default-character-set=utf8mb4 %DB_NAME% < "%~1"
if errorlevel 1 (
  echo Restore failed. Please check MySQL account/password and backup file path.
  exit /b 1
)
echo Restore finished.
endlocal
