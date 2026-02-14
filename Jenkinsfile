pipeline {
  agent any

  triggers {
    githubPush()
  }

  environment {
    IMAGE_NAME = 'todo-app'
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
        bat 'docker rm -f todo-app-container 2>nul || exit /b 0'
        bat 'docker run -d --name todo-app-container -p 8001:8000 %IMAGE_NAME%:latest'
      }
    }

    stage('Verify Running') {
      steps {
        bat 'docker ps'
      }
    }
  }
}
