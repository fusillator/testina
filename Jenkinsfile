pipeline {
    
  agent any
    
  environment {
    IMAGE_CI="fusillator/ci-tools:2026.09.15"
    IMAGE="fusillator/flask-demo"
    TAG="${env.GIT_COMMIT.take(7)}-b${env.BUILD_NUMBER}"
  }
    
  stages {
    stage('sca'){
      when {
        anyOf {
          branch pattern: 'feature/*', comparator: 'GLOB'
          //branch pattern: 'feature/.+', comparator: 'REGEXP'
          changeRequest target: 'main', branch: 'feature/*', comparator: 'GLOB'
          //changeRequest target: 'main', branch: 'feature/.+', comparator: 'REGEXP'
        }
      }
      steps {
        sh '''
          if [ $NODE_NAME = master -o $NODE_NAME = built-in ]; then 
            VOLUME_PATH=$(docker volume inspect jenkins_jenkins_home --format '{{ .Mountpoint }}')
            LOCK_PATH=${VOLUME_PATH}/${WORKSPACE#$JENKINS_HOME/} 
          else
            LOCK_PATH=${WORKSPACE} 
          fi
          docker run --rm --user 1000:1000 --cap-drop=ALL --security-opt=no-new-privileges:true --read-only \
            --tmpfs /tmp:rw,noexec,nosuid,size=64m,mode=1777 \
            --tmpfs /home/ci/.cache:rw,noexec,nosuid,size=128m,uid=1000,gid=1000,mode=0700 \
            -v ${LOCK_PATH}/requirements-lock.txt:/home/ci/requirements-lock.txt:ro \
            -v ${LOCK_PATH}/requirements-lock-dev.txt:/home/ci/requirements-lock-dev.txt:ro \
            -w /home/ci -e HOME=/home/ci \
            ${IMAGE_CI} \
            pip-audit --disable-pip --strict --require-hashes -r requirements-lock.txt -r requirements-lock-dev.txt 
            #--mount type=volume,src=jenkins_jenkins_home,dst=/home/ci/requirements-lock.txt,ro,volume-subpath=${WORKSPACE#$JENKINS_HOME/}/requirements-lock.txt \
            #--mount type=volume,src=jenkins_jenkins_home,dst=/home/ci/requirements-lock-dev.txt,ro,volume-subpath=${WORKSPACE#$JENKINS_HOME/}/requirements-lock-dev.txt \
        '''
      }
    }
    stage('linter'){
      when {
        anyOf {
          branch pattern: 'feature/*', comparator: 'GLOB'
          //branch pattern: 'feature/.+', comparator: 'REGEXP'
          changeRequest target: 'main', branch: 'feature/*', comparator: 'GLOB'
          //changeRequest target: 'main', branch: 'feature/.+', comparator: 'REGEXP'
        }
      }
      steps {
        sh '''
          if [ $NODE_NAME = master -o $NODE_NAME = built-in ]; then 
            VOLUME_PATH=$(docker volume inspect jenkins_jenkins_home --format '{{ .Mountpoint }}')
            LOCK_PATH=${VOLUME_PATH}/${WORKSPACE#$JENKINS_HOME/} 
          else
            LOCK_PATH=${WORKSPACE} 
          fi
          mkdir -p .cache/ruff
          docker run --rm --user 1000:1000 --cap-drop=ALL --security-opt=no-new-privileges:true --read-only \
            --network=none \
            --tmpfs /tmp:rw,noexec,nosuid,size=64m,mode=1777 \
            --tmpfs /home/ci/.cache:rw,noexec,nosuid,size=128m,uid=1000,gid=1000,mode=0700 \
            -v ${LOCK_PATH}:/home/ci:ro \
            -w /home/ci -e HOME=/home/ci -e RUFF_CACHE_DIR=/home/ci/.cache/ruff \
            ${IMAGE_CI} \
            ruff check src tests
            #--mount type=volume,src=jenkins_jenkins_home,dst=/home/ci,ro,volume-subpath=${WORKSPACE#$JENKINS_HOME/} \
          rm -rf .cache/ruff
        '''
      }
    }
    stage('build an ephemeral preview for ci test'){
      when {
        anyOf {
          branch pattern: 'feature/*', comparator: 'GLOB'
          //branch pattern: 'feature/.+', comparator: 'REGEXP'
          changeRequest target: 'main', branch: 'feature/*', comparator: 'GLOB'
          //changeRequest target: 'main', branch: 'feature/.+', comparator: 'REGEXP'
        }
      }
      steps {
        sh '''
          docker logout
          docker build --target prod -t ${IMAGE}:${TAG} .
          docker build --target dev --build-arg BASE_IMAGE=${IMAGE}:${TAG} -t ${IMAGE}:${TAG}-dev .
        '''
      }
    }
    stage('unit tests'){
      when {
        anyOf {
          branch pattern: 'feature/*', comparator: 'GLOB'
          //branch pattern: 'feature/.+', comparator: 'REGEXP'
          changeRequest target: 'main', branch: 'feature/*', comparator: 'GLOB'
          //changeRequest target: 'main', branch: 'feature/.+', comparator: 'REGEXP'
        }
      }
      steps {
        sh '''
          docker run --rm --user 1000:1000 --cap-drop=ALL --security-opt=no-new-privileges:true --read-only \
          --network=none \
          --tmpfs /tmp:rw,noexec,nosuid,size=64m,mode=1777 \
          --tmpfs /home/ci/.cache:rw,noexec,nosuid,size=128m,uid=1000,gid=1000,mode=0700 \
          -w /app -e HOME=/home/ci \
          ${IMAGE}:${TAG}-dev \
          pytest -m "not integration" -o cache_dir=/home/ci/.cache/pytest_cache
        '''
      }
    }
    stage('SAST'){
      when {
        changeRequest target: 'main', branch: 'feature/*', comparator: 'GLOB'
      }
      environment {
        SEMGREP_REPO_URL = "${env.GIT_URL}"
        SEMGREP_REPO_NAME = "${env.JOB_NAME}"
        SEMGREP_BRANCH = "${env.BRANCH_NAME}"
        SEMGREP_COMMIT = "${env.GIT_COMMIT}"
        SEMGREP_PR_ID = "${env.CHANGE_ID}"
      }
      steps {
        withCredentials([string(
          credentialsId: 'semgrep-fusillator-lab-token',
          variable: 'SEMGREP_APP_TOKEN'
        )]){
        sh '''
          if [ $NODE_NAME = master -o $NODE_NAME = built-in ]; then 
            VOLUME_PATH=$(docker volume inspect jenkins_jenkins_home --format '{{ .Mountpoint }}')
            APP_PATH=${VOLUME_PATH}/${WORKSPACE#$JENKINS_HOME/} 
          else
            APP_PATH=${WORKSPACE} 
          fi
          docker run --rm --user 1000:1000 --cap-drop=ALL --security-opt=no-new-privileges:true --read-only \
            --tmpfs /tmp:rw,noexec,nosuid,size=64m,mode=1777 \
            -v ${APP_PATH}/src:/src:ro \
            -v "ci_tools_cache:/home/semgrep/.semgrep:rw" \
            -w /src -e HOME=/home/semgrep \
            -e SEMGREP_APP_TOKEN -e SEMGREP_REPO_URL -e SEMGREP_REPO_NAME -e SEMGREP_BRANCH -e SEMGREP_COMMIT -e SEMGREP_PR_ID \
            -e SEMGREP_VERSION_CACHE_PATH=/home/semgrep/.semgrep -e SEMGREP_LOG_FILE=/tmp/semgrep.log \
            semgrep/semgrep:1.176.1-nonroot@sha256:4f79d592f85f91aa37597c0cfbad94ea5fa35c65571425fb061e406e6724d76e \
            sh -c "semgrep install-semgrep-pro && semgrep ci --pro --code --no-suppress-errors --dry-run"
          '''
        }
      }
    }
    stage('push'){
      when {
        changeRequest target: 'main', branch: 'feature/*', comparator: 'GLOB'
      }
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-token', passwordVariable: 'DOCKERHUB_PWD', usernameVariable: 'DOCKERHUB_USR')]) {
          sh 'echo $DOCKERHUB_PWD | docker login --password-stdin -u $DOCKERHUB_USR'
        }
        sh '''
          docker tag ${IMAGE}:${TAG} ${IMAGE}:pr-${CHANGE_ID}
          docker push ${IMAGE}:pr-${CHANGE_ID}
        '''
      }
    }
    stage('promote'){
      when { branch 'main' }
      steps {
        script {
          def m = (env.GIT_URL =~ /github\.com[:\/]([^\/]+)\/(.+?)(\.git)?$/)
          def owner = m[0][1]
          def repo  = m[0][2]
          withCredentials([usernamePassword(credentialsId: 'github-testina-ro-token', passwordVariable: 'GITHUB_TOKEN', usernameVariable: '')]) {
            def resp = sh(script: """
              curl -s -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${owner}/${repo}/commits/${env.GIT_COMMIT}/pulls
            """, returnStdout: true).trim()
          }
          def prNumber = sh(script: "echo '${resp}' | jq -r '.[0].number'", returnStdout: true).trim()
          sh '''
            docker pull ${IMAGE}:pr-${prNumber}
            docker tag ${IMAGE}:pr-${prNumber} ${IMAGE}:main-${TAG}
            docker tag ${IMAGE}:pr-${prNumber} ${IMAGE}:main-b${BUILD_NUMBER}
            docker push ${IMAGE}:main-${TAG}
            docker push ${IMAGE}:main-b{BUILD_NUMBER}
          '''
        }
      }
    }
  }

  post {
    always { 
      sh 'docker rmi ${IMAGE}:${TAG}-dev ${IMAGE}:${TAG} ${IMAGE}:pr-${CHANGE_ID} ${IMAGE}:main-${TAG} ${IMAGE}:main-b${BUILD_NUMBER} || true'
    }
  }
}
