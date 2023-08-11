pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('Access-key')
        AWS_SECRET_ACCESS_KEY = credentials('Secret-access-key')
    }


    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Provisioning') {
            steps {
                withEnv(["AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}", "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"]) {

                    script {
                        def terraformCommand = 'terraform'
                        

                        // Terraform initialization and apply
                        sh "${terraformCommand} init"
                        sh "${terraformCommand} apply -auto-approve"
                    }
                 }
            }
        }

        stage('Ansible Configuration') {
            steps {
                
                    script {
                        def ansibleCommand = 'ansible-playbook'

                        // Dynamic Inventory Script
                        sh "${ansibleCommand} -i ../terraform_inventory.py playbook.yml"
                    }
                
            }
        }
    }
}

