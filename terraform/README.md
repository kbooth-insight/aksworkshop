# aksworkshop example terraform

This is an example implementation of aksworkshop.io (as of 02/12/2019) using terraform.

## run
`terraform plan -var 'client_id=<service principal id>' -var 'client_secret=<principal password>'`

check your output

Then run 
`terraform apply -var 'client_id=<service principal id>' -var 'client_secret=<principal password>'`
