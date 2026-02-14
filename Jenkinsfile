pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    APP_DIR = "django-ci-cd"
    IMAGE_NAME = "django-todo-app"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Check Docker') {
      steps {
        bat 'docker --version'
        bat 'docker compose version'
      }
    }

    stage('Build Image') {
      steps {
        dir("${APP_DIR}") {
          bat "docker build -t %IMAGE_NAME%:%BUILD_NUMBER% ."
          bat "docker tag %IMAGE_NAME%:%BUILD_NUMBER% %IMAGE_NAME%:latest"
        }
      }
    }

    stage('Test') {
      steps {
        bat "docker run --rm %IMAGE_NAME%:%BUILD_NUMBER% python manage.py test"
      }
    }

    stage('Deploy') {
      when {
        branch 'main'
      }
      steps {
        dir("${APP_DIR}") {
          bat 'docker compose down || exit /b 0'
          bat 'docker compose up -d --build'
        }
      }
    }
  }

  post {
    always {
      cleanWs()
    }
    success {
      echo "Build Successful: ${BUILD_NUMBER}"
    }
    failure {
      echo "Pipeline failed."
    }
  }
}
