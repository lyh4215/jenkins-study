pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code'
            }
        }

        stage('Setup Python') {
            steps {
                dir('app') {
                    sh '''#!/usr/bin/env bash
                    set -euo pipefail
                    python --version
                    python -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    '''
                }
            }
        }

        stage('FastAPI Import Test') {
            steps {
                sh '''#!/usr/bin/env bash
                set -euo pipefail
                . app/venv/bin/activate
                python - <<'EOF'
from app.main import app
print("FastAPI app import OK")
EOF
                '''
            }
        }

        stage('PR Checks') {
            when {
                expression { env.CHANGE_ID != null }
            }
            steps {
                echo "🔍 Running PR checks for PR #${env.CHANGE_ID}"
                sh '''#!/usr/bin/env bash
set -euo pipefail
. app/venv/bin/activate
pytest
        '''
            }
        }

        stage('Main Branch Tests') {
            when {
                allOf {
                    branch 'main'
                    expression { env.CHANGE_ID == null }
                }
            }
            steps {
                echo "🧪 Running full test suite on main"
                sh '''#!/usr/bin/env bash
set -euo pipefail
. app/venv/bin/activate
pytest --junitxml=reports/junit.xml
        '''
            }
        }



        stage('Test Report') {
            when {
                allOf {
                    branch 'main'
                    expression { env.CHANGE_ID == null }
                }
            }
            steps {
                junit 'reports/junit.xml'
            }
        }

        stage('Deploy (Fake)') {
            when {
                allOf {
                    branch 'main'
                    expression { currentBuild.currentResult == 'SUCCESS' }
                }
            }
            steps {
                echo '🚀 Deploying application to production server (fake)'
                echo '✅ Deployment completed'
            }
        }

    }
}
