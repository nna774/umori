all:

SAM := sam
REGION := ap-northeast-1
BUCKET := nana-lambda

STACK_NAME := umori

app-for-deploy:
	: sam build --use-container

deploy: app-for-deploy
	$(SAM) deploy --region $(REGION) --s3-bucket $(BUCKET) --capabilities CAPABILITY_IAM --stack-name $(STACK_NAME)
