@echo off
title Conseiller de Version Windows selon votre Materiel
color 0B

:SCAN
cls
echo ============================================================================
echo          ANALYSE DU MATERIEL POUR RECOMMANDATION DE VERSION WINDOWS
echo ============================================================================
echo.
echo [INFO] Scan des composants en cours, veuillez patienter quelques secondes...
echo.

:: 1. Recuperation de la RAM en Go (avec decimale pour les vieux PC a 1 ou 2 Go)
for /f %%a in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)"') do set RAM=%%a

:: 2. Recuperation de la RAM en Mo (pour calculs precis)
for /f %%m in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB)"') do set RAM_MB=%%m

:: 3. Recuperation du nom du processeur et du nombre de coeurs
for /f "tokens=*" %%c in ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim()"') do set CPU_NAME=%%c
for /f %%n in ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1).NumberOfCores"') do set CPU_CORES=%%n

:: 4. Verification Architecture 32-bit ou 64-bit
set ARCH=32-bit
for /f "tokens=*" %%x in ('powershell -NoProfile -Command "if ((Get-CimInstance Win32_Processor | Select-Object -First 1).AddressWidth -eq 64) { '64-bit' } else { '32-bit' }"') do set ARCH=%%x

:: 5. Verification SSD ou HDD (compatible vieux Windows via WMI / PowerShell)
set DISK_TYPE=HDD (Disque mecanique)
for /f "tokens=*" %%d in ('powershell -NoProfile -Command "try { if (Get-PhysicalDisk | Where-Object MediaType -eq 'SSD') { 'SSD (Rapide)' } else { 'HDD (Disque mecanique)' } } catch { 'HDD ou Inconnu' }"') do set DISK_TYPE=%%d

:: 6. Verification presence TPM 2.0 (requis pour Windows 11)
set TPM_OK=Non
for /f "tokens=*" %%t in ('powershell -NoProfile -Command "try { $tpm = Get-Tpm; if ($tpm.TpmPresent -and $tpm.TpmReady) { 'Oui' } else { 'Non' } } catch { 'Non' }"') do set TPM_OK=%%t

:: Affichage du rapport materiel
cls
echo ============================================================================
echo                       RAPPORT MATERIEL DE VOTRE PC
echo ============================================================================
echo.
echo  - Processeur    : %CPU_NAME% (%CPU_CORES% coeurs)
echo  - Architecture  : %ARCH%
echo  - Memoire RAM   : %RAM% Go (%RAM_MB% Mo)
echo  - Stockage      : %DISK_TYPE%
echo  - Puce TPM 2.0  : %TPM_OK%
echo.
echo ============================================================================
echo                        VERDICT ET RECOMMANDATION
echo ============================================================================
echo.

:: Logique de recommandation materielle du plus ancien au plus recent

:: CAS 1 : Tres vieux PC (Moins de 1.5 Go de RAM ou processeur 32-bit)
if %RAM_MB% LSS 1500 (
    color 0E
    echo [CONSEIL] : WINDOWS XP SP3 ^(32-bit^) ou WINDOWS 7 STARTER / HOME BASIC ^(32-bit^)
    echo.
    echo [POURQUOI] : Votre PC possede moins de 1,5 Go de RAM ^(%RAM% Go^).
    echo Les versions modernes de Windows vont saturer la memoire immediatement.
    echo  - Si le PC reste hors ligne ^(vieux jeux/logiciels^) : Windows XP SP3.
    echo  - Pour un usage basique fluide : Windows 7 32-bit ^(ou Linux leger^).
    goto FIN
)

if "%ARCH%"=="32-bit" (
    color 0E
    echo [CONSEIL] : WINDOWS 7 PROFESSIONNEL ^(32-bit^) ou WINDOWS 8.1 ^(32-bit^)
    echo.
    echo [POURQUOI] : Votre processeur est uniquement 32-bit.
    echo Windows 11 n'existe pas en 32-bit, et Windows 10 32-bit est trop lourd.
    echo Windows 8.1 32-bit reste le plus rapide et reactif sur cette architecture.
    goto FIN
)

:: CAS 2 : PC Ancien (Entre 1.5 Go et 3.5 Go de RAM)
if %RAM_MB% LSS 3500 (
    color 0E
    echo [CONSEIL] : WINDOWS 8.1 ^(64-bit^) ou WINDOWS 7 ED. FAMILIALE / PRO ^(64-bit^)
    echo.
    echo [POURQUOI] : Avec %RAM% Go de RAM, Windows 10 et 11 seront tres lents.
    echo Windows 8.1 est beaucoup moins gourmand en memoire que Windows 10 tout
    echo en etant plus moderne et rapide au demarrage que Windows 7.
    goto FIN
)

:: CAS 3 : PC Milieu de gamme / Ancien avec 4 Go a 6 Go de RAM OU sans SSD
if %RAM_MB% LSS 6500 (
    color 0A
    echo [CONSEIL] : WINDOWS 10 LTSC ^(2021^) ou WINDOWS 10 FAMILLE ^(64-bit^)
    echo.
    echo [POURQUOI] : Vous avez %RAM% Go de RAM. Windows 11 demande au moins 8 Go
    echo pour etre vraiment fluide. Windows 10 est ideal ici.
    echo Astuce : Privilegiez la version "Windows 10 IoT Enterprise LTSC" qui
    echo n'a aucune application inutile et consomme tres peu de RAM.
    goto FIN
)

if "%DISK_TYPE%"=="HDD (Disque mecanique)" (
    color 0E
    echo [CONSEIL] : WINDOWS 10 ^(64-bit^) ou WINDOWS 8.1 ^(64-bit^)
    echo.
    echo [POURQUOI] : Vous avez %RAM% Go de RAM, mais un disque dur mecanique ^(HDD^).
    echo Windows 11 est extremement lent sans SSD. Restez sur Windows 10 ^(avec
    echo votre script d'optimisation^) ou installez un SSD pour passer a Windows 11.
    goto FIN
)

:: CAS 4 : PC Moderne (8 Go de RAM ou plus + SSD) mais sans TPM 2.0
if "%TPM_OK%"=="Non" (
    color 0A
    echo [CONSEIL] : WINDOWS 10 PRO / FAMILLE ^(64-bit^)
    echo.
    echo [POURQUOI] : Votre PC est puissant ^(%RAM% Go RAM + SSD^), mais la puce
    echo de securite TPM 2.0 est desactivee ou absente.
    echo  - Choix officiel : Windows 10 64-bit ^(tournera a pleine vitesse^).
    echo  - Choix alternatif : Windows 11 en contournant la verification TPM via Rufus.
    goto FIN
)

:: CAS 5 : PC Recent et performant (8 Go+ RAM, SSD, TPM 2.0)
color 0A
echo [CONSEIL] : WINDOWS 11 PRO / FAMILLE ^(64-bit^)
echo.
echo [POURQUOI] : Votre materiel remplit tous les criteres modernes :
echo  - %RAM% Go de RAM ^(%CPU_CORES% coeurs^)
echo  - Disque SSD rapide et puce TPM 2.0 active
echo Windows 11 exploitera pleinement votre processeur et votre SSD.

:FIN
echo.
echo ============================================================================
echo.
set /p retry="Voulez-vous relancer l'analyse ? (O/N) : "
if /i "%retry%"=="O" goto SCAN
exit /b
