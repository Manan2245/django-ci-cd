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

    stage('Test') {
      steps {
        dir("${APP_DIR}") {
          sh '''
            set -e
            python -m venv .venv
            . .venv/bin/activate
            pip install --upgrade pip
            pip install django==3.2
            python manage.py test
          '''
        }
      }
    }

    stage('Build Image') {
      steps {
        dir("${APP_DIR}") {
          sh 'docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .'
          sh 'docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest'
        }
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
        dir("${APP_DIR}") {
          sh 'docker compose down || true'
          sh 'docker compose up -d --build'
        }
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
