@Library('jenkins-scripts@main') _

pipeline {
  agent any
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Run Shared Pipeline') {
      steps {
        script {
          todoPipeline(appDir: '.', imageName: 'django-todo-app')
        }
      }
    }
  }
}
