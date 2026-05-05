pipeline {
  agent {
    docker { image 'ci-agent' }
  }
  parameters {
    string(name: 'XRAY_PROJECT_KEY',   defaultValue: 'QT2',  description: 'Xray Project Key (wajib)')
    string(name: 'XRAY_TESTPLAN_KEY',  defaultValue: '',     description: 'Opsional: Test Plan Key')
  }
  environment {
    XRAY_CLIENT_ID     = credentials('xray-client-id')
    XRAY_CLIENT_SECRET = credentials('xray-client-secret')
  }
  stages {
    stage('Clone') {
      steps {
        checkout scm
      }
    }
    stage('API (Newman)') {
      steps {
        sh '''
          set -e
          mkdir -p reports
          npm i -g newman-reporter-junit || true
          newman run api/*.postman_collection.json \
            -e api/*.postman_environment.json \
            --reporters cli,junit \
            --reporter-junit-export reports/junit-api.xml
        '''
      }
      post {
        always {
          junit 'reports/*.xml'
          archiveArtifacts artifacts: 'reports/**', fingerprint: true
        }
      }
    }
    stage('Publish Results to Xray') {
      steps {
        sh '''
          set -eu
          mkdir -p reports
          # Pastikan file JUnit ada
          [ -s reports/junit-api.xml ] || { echo "ERROR: reports/junit-api.xml not found/empty"; exit 1; }

          # Auth ke Xray
          XRAY_TOKEN=$(
            printf '{"client_id":"%s","client_secret":"%s"}' "$XRAY_CLIENT_ID" "$XRAY_CLIENT_SECRET" |
            curl -fsS -X POST "https://xray.cloud.getxray.app/api/v2/authenticate" \
                 -H "Content-Type: application/json" \
                 --data @- | tr -d '"'
          )
          [ -n "$XRAY_TOKEN" ] || { echo "ERROR: gagal mendapatkan token (cek Client ID/Secret)"; exit 1; }

          # Build query string dinamis
          QS="projectKey=${XRAY_PROJECT_KEY}"
          [ -n "${XRAY_TESTPLAN_KEY:-}" ] && QS="${QS}&testPlanKey=${XRAY_TESTPLAN_KEY}"

          # Import JUnit ke Xray
          HTTP_CODE=$(curl -sS -w "%{http_code}" -o reports/xray-import.json \
            -X POST "https://xray.cloud.getxray.app/api/v2/import/execution/junit?${QS}" \
            -H "Authorization: Bearer ${XRAY_TOKEN}" \
            -H "Content-Type: text/xml" \
            --data-binary @reports/junit-api.xml)

          case "$HTTP_CODE" in
            200|201) : ;;  # OK/Created
            *)  echo "ERROR: Upload failed with HTTP $HTTP_CODE"
                echo "--- Response ---"
                cat reports/xray-import.json || true
                exit 1
                ;;
          esac
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'reports/xray-import.json', fingerprint: true
        }
      }
    }
  }
}