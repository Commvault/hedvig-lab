test:
	terraform init
	terraform plan

up: 
	terraform apply -auto-approve

down:
	terraform destroy -auto-approve
	
kill: 
	az group delete -y --no-wait --name rg-hedvig
	
clean: 
	rm terraform.tfstate*