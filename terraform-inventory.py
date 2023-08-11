#!/usr/bin/env python
import subprocess
import json

# Run Terraform output command to get instance IPs and other info
terraform_output = subprocess.check_output(["terraform", "output", "-json", "instance_ips"])
instance_ips = json.loads(terraform_output)

# Prepare inventory structure in aws_ec2.py format
inventory = {
    "_meta": {
        "hostvars": {}
    }
}

# Add EC2 instances to the inventory
for i, ip in enumerate(instance_ips, start=1):
    instance_name = f"ec2-{i}"
    inventory["_meta"]["hostvars"][instance_name] = {
        "ansible_host": ip,
        # Add other hostvars if needed
    }

print(json.dumps(inventory)) 
