pipeline {
  agent {
    kubernetes {
      label 'k8s'
      defaultContainer 'jnlp'
    }
  }
  stages {
    stage('Example') {
      steps {
        echo 'Hello World! '
      }
    }
  }
}