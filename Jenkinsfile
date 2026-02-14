pipeline {
  agent any

  triggers {
    githubPush()
  }

  environment {
    IMAGE_NAME = 'todo-app'
    DOCKERHUB_IMAGE = 'manan2245/to-do-app'
    DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
    PUSH_TO_DOCKERHUB = 'true'
    APP_CONTAINER = 'todo-app-container'
    CANDIDATE_CONTAINER = 'todo-app-candidate'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Image') {
      steps {
        bat 'docker build -t %IMAGE_NAME%:%BUILD_NUMBER% .'
        bat 'docker tag %IMAGE_NAME%:%BUILD_NUMBER% %IMAGE_NAME%:latest'
        bat 'docker tag %IMAGE_NAME%:%BUILD_NUMBER% %DOCKERHUB_IMAGE%:%BUILD_NUMBER%'
        bat 'docker tag %IMAGE_NAME%:%BUILD_NUMBER% %DOCKERHUB_IMAGE%:latest'
      }
    }

    stage('Test') {
      steps {
        bat 'docker run --rm %IMAGE_NAME%:%BUILD_NUMBER% python manage.py test'
      }
    }

    stage('Push To Docker Hub') {
      when {
        environment name: 'PUSH_TO_DOCKERHUB', value: 'true'
      }
      steps {
        withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
          bat '''
            @echo off
            echo %DOCKERHUB_PASSWORD% | docker login -u %DOCKERHUB_USERNAME% --password-stdin
            docker push %DOCKERHUB_IMAGE%:%BUILD_NUMBER%
            docker push %DOCKERHUB_IMAGE%:latest
            docker logout
          '''
        }
      }
    }

    stage('Deploy Container') {
      steps {
        bat '''
          @echo off
          setlocal EnableDelayedExpansion

          set NEW_IMAGE=%IMAGE_NAME%:%BUILD_NUMBER%
          set OLD_IMAGE=
          set CURRENT_PORT=
          set TARGET_PORT=
          set CANDIDATE_PORT=

          rem If current app container exists, preserve its current host port.
          for /f "delims=" %%p in ('powershell -NoProfile -Command "$raw = docker port %APP_CONTAINER% 8000/tcp 2>$null; if($LASTEXITCODE -eq 0 -and $raw){ $line = ($raw | Select-Object -First 1); $m = [regex]::Match($line, ':(\\d+)$'); if($m.Success){$m.Groups[1].Value} }"') do set CURRENT_PORT=%%p

          if defined CURRENT_PORT (
            set TARGET_PORT=!CURRENT_PORT!
            echo Reusing existing app port !TARGET_PORT!
          ) else (
            rem Default target is 8001; if occupied by another service, pick next free up to 8100.
            for /f "delims=" %%p in ('powershell -NoProfile -Command "$port=$null; for($p=8001; $p -le 8100; $p++){ try { $l=[System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any,$p); $l.Start(); $l.Stop(); $port=$p; break } catch {} }; if(-not $port){ exit 1 }; $port"') do set TARGET_PORT=%%p
            if not defined TARGET_PORT (
              echo Could not find free deploy port in range 8001-8100.
              exit /b 1
            )
            echo Selected temporary deploy port !TARGET_PORT!
          )

          rem Candidate runs on a separate free port.
          for /f "delims=" %%p in ('powershell -NoProfile -Command "$port=$null; for($p=9001; $p -le 9100; $p++){ try { $l=[System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any,$p); $l.Start(); $l.Stop(); $port=$p; break } catch {} }; if(-not $port){ exit 1 }; $port"') do set CANDIDATE_PORT=%%p
          if not defined CANDIDATE_PORT (
            echo Could not find free candidate port in range 9001-9100.
            exit /b 1
          )

          echo Preparing candidate container...
          docker rm -f %CANDIDATE_CONTAINER% 2>nul
          docker run -d --name %CANDIDATE_CONTAINER% -p !CANDIDATE_PORT!:8000 %NEW_IMAGE%
          if errorlevel 1 (
            echo Failed to start candidate container.
            exit /b 1
          )

          echo Waiting for candidate response on http://localhost:!CANDIDATE_PORT! ...
          powershell -NoProfile -Command "$ok=$false; $u='http://localhost:' + !CANDIDATE_PORT!; for($i=0;$i -lt 20;$i++){try{ $r=Invoke-WebRequest -UseBasicParsing $u -TimeoutSec 2; if($r.StatusCode -ge 200 -and $r.StatusCode -lt 500){$ok=$true; break}} catch {}; Start-Sleep -Seconds 2}; if(-not $ok){exit 1}"
          if errorlevel 1 (
            echo Candidate health check failed.
            docker logs %CANDIDATE_CONTAINER%
            docker rm -f %CANDIDATE_CONTAINER% 2>nul
            exit /b 1
          )

          for /f "delims=" %%i in ('docker inspect -f "{{.Config.Image}}" %APP_CONTAINER% 2^>nul') do set OLD_IMAGE=%%i

          echo Swapping to new container...
          docker rm -f %APP_CONTAINER% 2>nul
          docker run -d --name %APP_CONTAINER% -p !TARGET_PORT!:8000 %NEW_IMAGE%
          if errorlevel 1 (
            echo Failed to start new primary container. Attempting rollback...
            if defined OLD_IMAGE (
              docker run -d --name %APP_CONTAINER% -p !TARGET_PORT!:8000 !OLD_IMAGE!
            )
            docker rm -f %CANDIDATE_CONTAINER% 2>nul
            exit /b 1
          )

          docker rm -f %CANDIDATE_CONTAINER% 2>nul
          echo Deploy completed on host port !TARGET_PORT!.
        '''
      }
    }

    stage('Verify Running') {
      steps {
        bat 'docker ps'
        bat 'docker port %APP_CONTAINER% 8000'
      }
    }
  }
}
