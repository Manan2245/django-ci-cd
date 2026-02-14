pipeline {
  agent any

  triggers {
    githubPush()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Image') {
      steps {
        bat 'docker build -t todo-app .'
      }
    }

    stage('Deploy Container') {
      steps {
        bat 'docker rm -f todo-app-container 2>nul || exit /b 0'
        bat 'docker run -d --name todo-app-container -p 8001:8000 todo-app'
      }
    }

    stage('Verify Running') {
      steps {
        bat 'docker ps'
      }
    }
  }
}
