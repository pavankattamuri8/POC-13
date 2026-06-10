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
                git branch: 'main', url: 'https://github.com/Nagendrakumarredd/POC-13.git'
            }
        }

        stage('Terraform Apply') {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'aws-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
            sh '''
            export AWS_DEFAULT_REGION=ap-south-1
 
            aws sts get-caller-identity
 
            terraform init
            terraform apply -auto-approve
            '''
        }
    }
}

        stage('Configure kubectl') {
            steps {
                sh '''
                aws eks update-kubeconfig \
                --region $AWS_REGION \
                --name $CLUSTER_NAME
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
               
                     sh '''
                            export AWS_REGION=us-east-1
                    
                            aws sts get-caller-identity
                    
                            aws eks update-kubeconfig --region $AWS_REGION --name poc-cluster
                    
                            kubectl get nodes
                    
                            kubectl apply -f k8s-deploy.yaml
                            '''


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
                    echo "LoadBalancer Found!"
                    echo "Application URL: http://$LB_URL"
                    echo "Final URL: http://$LB_URL/index.html"
                    exit 0
                  fi

                  echo "Still creating LoadBalancer... retrying in 10 seconds"
                  sleep 10
                done

                echo "ERROR: LoadBalancer not ready"
                exit 1
                '''
            }
        }
    }
}
