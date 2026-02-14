pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    IMAGE_NAME = "django-todo-app"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Test') {
      steps {
        bat '''
          python -m venv .venv
          call .venv\\Scripts\\activate
          python -m pip install --upgrade pip
          pip install django==3.2
          python manage.py test
        '''
      }
    }

    stage('Build Image') {
      steps {
        bat "docker build -t %IMAGE_NAME%:%BUILD_NUMBER% ."
        bat "docker tag %IMAGE_NAME%:%BUILD_NUMBER% %IMAGE_NAME%:latest"
      }
    }

    stage('Deploy') {
      when {
        anyOf {
          branch 'main'
          branch 'master'
        }
      }
      steps {
        bat 'docker compose down || exit /b 0'
        bat 'docker compose up -d --build'
      }
    }
  }

  post {
    always {
      cleanWs()
    }
    success {
      echo "Pipeline completed. Build: ${BUILD_NUMBER}"
    }
    failure {
      echo "Pipeline failed."
    }
  }
}
