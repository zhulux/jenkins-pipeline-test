#!groovy
import groovy.json.JsonSlurper
import groovy.text.GStringTemplateEngine
import groovy.text.SimpleTemplateEngine
import groovy.text.StreamingTemplateEngine
import groovy.json.JsonSlurper


def lib = library('ci-shared-libs').com.starup
def msgUtils = lib.MessageLego.new()
def bearychatHookUrl = env.BEARYCHAT_HOOK_URL
def bearychatHookGroup = 'testgroup'

//BUILD_IMAGE_HOST = 'docker-build-bj3a'
BUILD_IMAGE_HOST = 'docker-build-bj3a'
def jobfilePath = './testJobLocal.yaml'
def kubeUtils = new lib.KubeUtils()


txt = '''
apiVersion: batch/v1
kind: Job
metadata:
  name: ${podname}
  labels:
    app: ${podname}
spec:
  template:
    spec:
      containers:
      - name: ${podname}
        image: ${image}
#        command: ["perll",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
        command: ${command}
      restartPolicy: Never
  backoffLimit: 1
'''

node(BUILD_IMAGE_HOST) {
  checkout scm
  stage('generate job yaml test') {
    namespace = 'devops'
    jobName = 'db-migrate-' + getCommitHash()
    def targetFilePath = "./migrate-job.yaml"
    def fileContents = readFile file: "${jobfilePath}", encoding: "UTF-8"
    jobContents = kubeUtils.jobGen("${fileContents}", "daocloud.io/zhulux/fluentd-journald-elasticsearch:master-036c813", "sleep15", "test-cronjob")
    writeFile file: "${targetFilePath}", text: jobContents

    // create job
    sh "kubectl create -f ${targetFilePath} -n ${namespace}"

    // check job status
    try {
      kubeWaitForJob("${namespace}", "${jobName}", 40)
    } catch (err) {
      println("timeout, please check logs")
      throw err
    } finally {
      println('End pipeline !')
      if (kubeUtils.jobStatus("${namespace}","${jobName}") == 'failed') {
        msg = kubeUtils.getLog("${namespace}", "${jobName}")
        println "${msg}"
        // todo notify
        currentBuild.result = "FAIlED"
        errorMsg = msgUtils.errorMsg("${msg}")
        bearyNotifySend attachments: "${errorMsg}", channel: "${bearychatHookGroup}", endpoint: "${bearychatHookUrl}"
      }
      sh "kubectl delete -f testjobfile -n ${namespace}"
    }

  }
}



/*
Some function
*/

//
// def kubeWaitForJob(namespace, selector, timeoutSecs = 300) {
// //    def kubeUtils = new KubeUtils()
//     timeout(time: timeoutSecs, unit: 'SECONDS') {
//         waitUntil {
//             return kubeJobStatus(namespace, selector)
//         }
//     }
// }
//
//
// def getErrorLog(namespace, selector) {
//   def getJobPod = $/eval "kubectl get po -l job-name=${selector} -n ${namespace} --show-all -oname | tail -1"/$
//   def podName = sh script: "${getJobPod}", returnStdout: true
//   def errorMessage = sh script: "kubectl logs --tail 20 -n ${namespace} ${podName}", returnStdout: true
//   return errorMessage
// }
//
//
// def kubeJobStatus(namespace, jobName) {
//     def script = "kubectl get job ${jobName} -o json -n ${namespace}"
//     def stdout = sh script: "${script}", returnStdout: true
//     def jsonSlurper = new JsonSlurper()
//     def json = jsonSlurper.parseText(stdout.trim())
//     def isComplete = true
//     try {
//         if (json.status.conditions.type[0] && json.status.conditions.type[0] == 'Complete') {
//            return isComplete
//         } else if (json.status.conditions.type[0] && json.status.conditions.type[0] == 'Failed'){
//             status = "failed"
//             echo "Current job task is Failed, Please check pod logs on kubernetes cluster!"
//             return status
//         } else {
//             return false
//         }
//     } catch (java.lang.NullPointerException e) {
//         return false
//     } catch (err) {
//         return false
//     }
//     return isComplete && json.status.conditions.type[0] == 'Complete'
// }
//
//
// @NonCPS
// def kubeJobGen(jobContents, jobImage, jobCommand, jobName) {
//     jobParameter = [ podname: jobName, image: jobImage, command: jobCommand ]
//     def engine = new groovy.text.StreamingTemplateEngine()
//     def template = engine.createTemplate("${jobContents}").make(jobParameter)
//     def templateString = template.toString()
//     return templateString
// }
