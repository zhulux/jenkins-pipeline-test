#!groovy

node('docker-build-cn') {
    echo env.BRANCH_NAME
    echo env.CHANGE_ID
    println env.CHANGE_ID
    println env.CHANGE_AUTHOR
    println env.IMAGE_TAG
    println env.JOB_URL
    def app
    def myRepo = checkout scm
    def gitCommit = myRepo.GIT_COMMIT
    def gitBranch = myRepo.GIT_BRANCH
    def shortGitCommit = "${gitCommit[0..10]}"
    def previousGitCommit = sh(script: "git rev-parse ${gitCommit}~", returnStdout: true)
 
    stage('Clone repository'){
        checkout scm 
    }
    stage('Test image'){
        echo 'TODO: add tests'
    }

    stage('Publish Image to Registry'){
        label 'docker-build-cn'
        sh "git rev-parse HEAD > .git/commit-id"
        sh "echo -n `git rev-parse HEAD` | head -c 7 > .git/commit-id"
        if (env.BRANCH_NAME ==~ /v.*/) {
            sh "git describe --tags --abbrev=0 > .git/tag-id"
        }
        
        def commit_id = readFile('.git/commit-id').trim()
        def tag_id = readFile('.git/tag-id').trim()
        def BUILD_ID = commit_id
        println commit_id
        println env.BUILD_ID

        app = docker.build("helloworld")
        docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
        if (env.BRANCH_NAME == 'staging') {
            app.push("${BRANCH_NAME}-${commit_id}")
        }
        else if(env.BRANCH_NAME ==~ /v.*/ ){
            app.push("${tag_id}")
        }
        else {
            input "do do do"
        }
        }
    
    }
}

node('k8s') {
    stage('Staging Deployment'){
        if (env.BRANCH_NAME == 'staging') {
            sh ""
            echo "deploy staging"
            sh "date"
            println env.BUILD_ID
        }
    }
    stage('Go for Production?'){
        if (env.BRANCH_NAME ==~ /v.*/){
            milestone(1)
            timeout(time:5, unit:'MINUTES'){
                input 'Deploy to Production?'
            }
            milestone(2)
            stage('Produciton Deployment'){
                echo "deploy to product"

            }
    
        }

    }

}
