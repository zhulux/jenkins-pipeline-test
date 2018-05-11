pipeline {
  agent {
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
