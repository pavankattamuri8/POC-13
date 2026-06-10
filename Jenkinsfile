pipeline {
    agent any

    environment {
        CLUSTER_NAME = "poc-cluster"
        AWS_REGION   = "ap-south-1"
        SERVICE_NAME = "html-service"
    }

    triggers {
        githubPush()
    }

    stages {

        stage('Clone Code') {
            steps {
                git branch: 'main', url: 'https://github.com/pavankattamuri8/POC-13.git'
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Configure kubectl') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                    aws eks update-kubeconfig \
                        --region $AWS_REGION \
                        --name $CLUSTER_NAME

                    kubectl get nodes
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                    kubectl apply -f k8s-deploy.yaml
                    '''
                }
            }
        }

        stage('Wait for LoadBalancer') {
            steps {
                sh '''
                echo "Waiting for LoadBalancer URL..."

                for i in {1..30}
                do
                  LB_URL=$(kubectl get svc $SERVICE_NAME -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

                  if [ ! -z "$LB_URL" ]; then
                    echo "✅ LoadBalancer Found!"
                    echo "Application URL: http://$LB_URL"
                    echo "Final URL: http://$LB_URL/index.html"
                    exit 0
                  fi

                  echo "Still creating LoadBalancer... retrying in 10 seconds"
                  sleep 10
                done

                echo "❌ ERROR: LoadBalancer not ready"
                exit 1
                '''
            }
        }
    }
}
