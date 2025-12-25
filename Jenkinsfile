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
                    sh '''
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
                sh '''
                . venv/bin/activate
                python - <<EOF
from app.main import app
print("FastAPI app import OK")
EOF
                '''
            }
        }
    }
}
