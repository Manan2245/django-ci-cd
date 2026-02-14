pipeline {
  agent any

  triggers {
    githubPush()
  }

  environment {
    IMAGE_NAME = 'todo-app'
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
      }
    }

    stage('Test') {
      steps {
        bat 'docker run --rm %IMAGE_NAME%:%BUILD_NUMBER% python manage.py test'
      }
    }

    stage('Deploy Container') {
      steps {
        bat '''
          @echo off
          setlocal EnableDelayedExpansion

          set NEW_IMAGE=%IMAGE_NAME%:%BUILD_NUMBER%
          set OLD_IMAGE=

          echo Preparing candidate container...
          docker rm -f %CANDIDATE_CONTAINER% 2>nul
          docker run -d --name %CANDIDATE_CONTAINER% -p 8002:8000 %NEW_IMAGE%
          if errorlevel 1 (
            echo Failed to start candidate container.
            exit /b 1
          )

          echo Waiting for candidate response on http://localhost:8002 ...
          powershell -NoProfile -Command "$ok=$false; for($i=0;$i -lt 20;$i++){try{ $r=Invoke-WebRequest -UseBasicParsing http://localhost:8002 -TimeoutSec 2; if($r.StatusCode -ge 200 -and $r.StatusCode -lt 500){$ok=$true; break}} catch {}; Start-Sleep -Seconds 2}; if(-not $ok){exit 1}"
          if errorlevel 1 (
            echo Candidate health check failed.
            docker logs %CANDIDATE_CONTAINER%
            docker rm -f %CANDIDATE_CONTAINER% 2>nul
            exit /b 1
          )

          for /f "delims=" %%i in ('docker inspect -f "{{.Config.Image}}" %APP_CONTAINER% 2^>nul') do set OLD_IMAGE=%%i

          echo Swapping to new container...
          docker rm -f %APP_CONTAINER% 2>nul
          docker run -d --name %APP_CONTAINER% -p 8000:8000 %NEW_IMAGE%
          if errorlevel 1 (
            echo Failed to start new primary container. Attempting rollback...
            if defined OLD_IMAGE (
              docker run -d --name %APP_CONTAINER% -p 8000:8000 !OLD_IMAGE!
            )
            docker rm -f %CANDIDATE_CONTAINER% 2>nul
            exit /b 1
          )

          docker rm -f %CANDIDATE_CONTAINER% 2>nul
          echo Deploy completed.
        '''
      }
    }

    stage('Verify Running') {
      steps {
        bat 'docker ps'
      }
    }
  }
}
