pipeline {
  agent {
      label 'k8s'
      dockerfile true
  }
  stages {
    stage('Example') {
      steps {
        echo 'Hello World! '
      }
    }
  }
}


pipeline {
    agent { dockerfile true }
    stages {
        stage('Test') {
            steps {
                sh 'node --version'
                sh 'svn --version'
            }
        }
    }
}