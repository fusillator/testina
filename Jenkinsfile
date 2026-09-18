pipeline {
    
  agent any
    
  environment {
    IMAGE_CI="fusillator/ci-tools:2026.09.15"
    IMAGE="fusillator/flask-demo"
    TAG="${env.GIT_COMMIT}-${env.BUILD_NUMBER}"
  }
    
  stages{
    stage('sca'){
      steps{
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
      steps{
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
      steps{
        sh '''
          docker logout
          docker build --target dev -t ${IMAGE}:${TAG} .
        '''
      }
    }
    stage('unit tests') {
      steps{
        sh '''
          docker run --rm --user 1000:1000 --cap-drop=ALL --security-opt=no-new-privileges:true --read-only \
          --network=none \
          --tmpfs /tmp:rw,noexec,nosuid,size=64m,mode=1777 \
          --tmpfs /home/ci/.cache:rw,noexec,nosuid,size=128m,uid=1000,gid=1000,mode=0700 \
          -w /app -e HOME=/home/ci \
          ${IMAGE}:${TAG} \
          pytest -m "not integration" -o cache_dir=/home/ci/.cache/pytest_cache
        '''
      }
    }
  }

  post {
    always { 
      sh 'docker rmi ${IMAGE}:${TAG} || true'
    }
  }
}
