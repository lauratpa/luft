# luft

## Requirements

* AWS CLI already configured with at least PowerUser permission
* [Ruby](https://www.ruby-lang.org/en/documentation/installation/) 2.5 installed
* [Docker installed](https://www.docker.com/community-edition)
* [Ruby Version Manager](http://rvm.io/)

## Setup process

### Match ruby version with docker image
For high fidelity development environment, make sure the local ruby version matches that of the docker image. To do so lets use [Ruby Version Manager](http://rvm.io/)

Setup Ruby Version Manager from [Ruby Version Manager](http://rvm.io/)

Run following commands

```bash
rvm install ruby-2.5.0
rvm use ruby-2.5.0
rvm --default use 2.5.0
```

or
```bash
chruby ruby2.5.0
```

### Installing dependencies

```sam-app``` comes with a Gemfile that defines the requirements and manages installing them.

```bash
gem install bundler
bundle install
bundle install --deployment --path luft/vendor/bundle --without test development
```

* Step 1 installs ```bundler```which provides a consistent environment for Ruby projects by tracking and installing the exact gems and versions that are needed.
* Step 2 creates a Gemfile.lock that locks down the versions and creates the full dependency closure.
* Step 3 installs the gems to ```hello_world/vendor/bundle```.

**NOTE:** As you change your dependencies during development you'll need to make sure these steps are repeated in order to execute your Lambda and/or API Gateway locally.

### Local development

**Invoking function locally through local API Gateway**

```bash
sam local start-api
```

If the previous command ran successfully you should now be able to hit the following local endpoint
(however local dynamodb creation is not yet supported)

```bash
curl --data '{"esp8266id":"4620979", "software_version":"NRZ-2018-121C", "sensordatavalues":[{"value_type":"SDS_P1", "value":"16.17"}, {"valuevalue_type":"temperature", "value":"22.60"}, {"value_type":"humidity", "value":"39.40"}, {"value_type":"samples", "value":"863806"}, {"value_type":"min_micro", "value":"158"}, {"value_type":"max_micro", "value":"27029"}, {"value_type":"signal", "value":"-58"}]}' --header "Content-Type: application/json" -X POST http://127.0.0.1:3000/luft-push
```

**SAM CLI** is used to emulate both Lambda and API Gateway locally and uses our `template.yaml` to understand how to bootstrap this environment (runtime, where the source code is, etc.) - The following excerpt is what the CLI will read in order to initialize an API and its routes:

```yaml
...
Events:
  PushData:
    Type: Api # More info about API Event Source: https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md#api
    Properties:
      Path: /luft-data
      Method: post
```

Specification for the template structure can be found here
[https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md](https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md)
More on which resources are auto generated can be found here
[https://github.com/awslabs/serverless-application-model/blob/master/docs/internals/generated_resources.rst](https://github.com/awslabs/serverless-application-model/blob/master/docs/internals/generated_resources.rst)

## Packaging and deployment

AWS Lambda Ruby runtime requires a flat folder with all dependencies including the application. SAM will use `CodeUri` property to know where to look up for both application and dependencies:

```yaml
...
LuftPushFunction:
  Type: AWS::Serverless::Function
    Properties:
      CodeUri: luft/
      ...
```

Firstly, we need a `S3 bucket` where we can upload our Lambda functions packaged as ZIP before we deploy anything - If you don't have a S3 bucket to store code artifacts then this is a good time to create one:

```bash
aws s3 mb s3://BUCKET_NAME
```

Next, run the following command to package our Lambda function to S3:

```bash
sam package \
    --template-file template.yaml \
    --output-template-file packaged.yaml \
    --s3-bucket REPLACE_THIS_WITH_YOUR_S3_BUCKET_NAME
```

Next, the following command will create a Cloudformation Stack and deploy your SAM resources.

```bash
sam deploy \
    --template-file packaged.yaml \
    --stack-name luft \
    --capabilities CAPABILITY_IAM
```

> **See [Serverless Application Model (SAM) HOWTO Guide](https://github.com/awslabs/serverless-application-model/blob/master/HOWTO.md) for more details in how to get started.**

After deployment is complete you can run the following command to retrieve the API Gateway Endpoint URL:

```bash
aws cloudformation describe-stacks \
    --stack-name luft \
    --query 'Stacks[].Outputs'
``` 

## Testing

```bash
bundle exec rspec
```
# Appendix

## AWS CLI commands

AWS CLI commands to package, deploy and describe outputs defined within the cloudformation stack:

```bash
sam package \
    --template-file template.yaml \
    --output-template-file packaged.yaml \
    --s3-bucket REPLACE_THIS_WITH_YOUR_S3_BUCKET_NAME

sam deploy \
    --template-file packaged.yaml \
    --stack-name sam-app \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides MyParameterSample=MySampleValue

aws cloudformation describe-stacks \
    --stack-name sam-app --query 'Stacks[].Outputs'
```

Next, you can use the following resources to know more about beyond hello world samples and how others structure their Serverless applications:

* [AWS Serverless Application Repository](https://aws.amazon.com/serverless/serverlessrepo/)

