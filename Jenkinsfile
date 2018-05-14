#pipeline {
#  agent {
#      dockerfile true
#  }
#  stages {
#    stage('Example') {
#      steps {
#        echo 'Hello World! '
#        sh 'echo mycustomenv1 = $mycustomenv1'
#      }
#    }
#  }
#}


node("docker-build") {
    docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
    
        git url: "https://github.com/aliasmee/jenkins-pipeline-test.git"
    
        sh "git rev-parse HEAD > .git/commit-id"
        def commit_id = readFile('.git/commit-id').trim()
        println commit_id
    
        stage "build"
        def app = docker.build "jenkins-pipeline-test"
    
        stage "publish"
        app.push 'master'
        app.push "${commit_id}"
    }
}
