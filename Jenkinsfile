pipeline {
  agent {
      label 'k8s'
      dockerfile true
  }
  stages {
    stage('Example') {
      steps {
        echo 'Hello World! '
        sh 'echo mycustomenv1 = $mycustomenv1'
      }
    }
  }
}
