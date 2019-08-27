![DXC Technology](./images/dxc_wordmark_1c_blk_cmyk.gif)
# OHDSI on AWS by DXC Technology

This repository forks from the [official OHDSIonAWS repository](https://github.com/OHDSI/OHDSIonAWS), and contains updates, fixes and improvements introduced by DXC Technology.

This document summarizes those changes and provides an updated deployment procedure.

# Changes to the Official Version

## Use of Customized Templates

The use of the Official version S3 bucket is replaced by the selection of the bucket and object prefix where the deployment templates are found. 

## Parameter Storage Template

CFN templates do not store the information about the parameters necessary to deploy them under a certain scenario. DXC Technology advocates a Software Defined Infrastructure philosophy, that requires storing the parameter values used to deploy the environment as software artifacts. To implement it on CFN, we introduced a new tamplate `00-main.yaml` that serves the following purposes:

  - Launches the official master CFN stack with the selected parameters, that are thus stored with the template.
  - Creates AWS SM secrets where all passwords and credentials are stored:
    - Initial ATLAS users passwords
    - Databases master password
    - Environment access details. Used by DXC developed scripts, Lambdas and other operation related artifacts.
    
## VPC Independence

The official templates require the creation of a new VPC. DXC Technology, as many organizations, uses its own VPC design that is deployed before the OHDSI environment. The master and vpc templates were modified to accept additional parameters that allow disabling the creation of the VPC resources, replaced by the use of parameter values.

The VPC template remains as the one creating also IAM resources as roles and instance profile, though by DXC Technology standards, those will in the future be migrated to a separate template so their creation can be delegated to privileged users.

### VPC Requirements

If using an existing VPC, it must meet the following requirements:

- Must provide a public subnet in two different AZs
- Must provide a private subnet in two different AZs. Optionally, two separate private subnets can be used for the databases.
- The private subnets must have outbound internet access (Though a NAT gateway of NAT instance)
- If NACLs exist they must not restrict:
    - Inbound TCP/80 - To the applicaiton private subnets, or the public subnets
    - Inbound TCP/443 - To the application private subnets, or the public subnets
    - Inbound TCP/8787 - To the application private subnets
    - Inbound TCP/5432 - To the database private subnets
    - Inbound TCP/5439 - To the database private subnets
    - Inbound TCP/22 - From VPN or whitelisted public IPs to the application private subnets
    - Outbound TCP/80 or TCP/443 to any public Address

## Tagging

Tags are used in AWS for multiple purposes, most importantly for operation automation and cost control. CloudFormation allow specifying tags when creating a stack from a template, that will be associated to each resource that is created (and supports tagging). 

The OHDSI application template includes an EC2 instance that is merely created to run the bootstrapping process. This instance is instructed to stop itself when the process finishes and due its to being set up with termination on stop behavior, terminated.

As this instance no longer exists, but the associated resource is present in the CFN stack, if tags associated to the Stack are modified, the update operation fails as the instance resource cannot be updated.

This has made necessary to modify all templates where tag-supporting resources exist, to define the tags required at resource level instead of at stack level. Ths is also necessary for tags that may need to use different values for different resources.

## ASG Desired Capacity Setting

A parameter was added to set the `DesiredCapacity`setting of the AutoScalingGroup created as part of the ElasticBeanstalk environment. This is not available as an attribute of the CloudFormation resource, and is configured by adding an Auto Scaling Rule that is set to run only once, at the same time stamp when the environment is created.

**NOTICE**: For the Initial Deployment you **MUST** provide a value of at lease `1` to WebAsgMin and WebAsgDesired, or the deployment will fail because the ElasticBeanstalk environment will not deploy any EC2 instance and the application will not be available for the bootstrapping process to perform required actions. The bootstrapping script waits for the EB environment to be available

## Fix to Failure When Using Route53 hosted DNS

When choosing to use a DNS domain hosted in a Route53 zone, the deployment fails because:

  - The bootstrapping script used by the temporary instance uses the R53 domain name to form the URL to invoke WebAPI, that is needed to create the users and to obtain the SQL scripts used to configure the CDM schema to be used from WebAPI.
  - The template that creates those DNS records in Route53 depends on the one that launches the temporary instance. Hence, those do not exist yet when the bootstrapping script runs and so it fails.
  
There is no reason for the Rout53 resources to depend on the application template, and the problem is fixed by removing that dependency.

## Temporary Instance Bootstrapping Process Changes

### Unnecesary Use of the Custom DNS Name

As explained in the previous chapter, the bootstrapping script tries to use the custom DNS name is that option was set for the deployment. However, the scritp can equally use the ElasticBeanstalk assigned endpoint. To avoid the need to synchronize the templates to make sure that that the custom DNS records exist and are operative, the script is modified to always use the ElasticBeanstalk endpoint instead.

### Wait for ElasticBeanstalk Application Availability

At certain point, the script needs to wait until the ElasticBeanstalk application is available, because it will then invoke it as part of the steps requierd to create ATLAS users. This wait was originally implemented with a loop that sleed for 5 seconds until the WebAPI URL responds with an HTTP 200 code. The issue explained in the previous chapter about the existence of the custom DNS Records made this loop fail.

Though replacing the dependency of the Route53 template with the Application template would solve the particular issue, DXC Technoly considered a better approach to use the "Status" and "Health" reported by the ElasticBeanstalk environment as indicators of the availability of the application. Hence the loop was modified to wait until the environment reports to be "Healthy" and in a "Green" status.

### Wait For Database Preparation Completion

An additional WaitCondition was added so the bootstrapping script must signal the successful completion of the database preparation script to consider the CFN stack completed successfully. Originally, errors in the database preparation did not make the deployment fail.
*NOTE: Additional success checks are planed to be introduced in the database preparation script*    

## Temporary Instance Resource Deletion

Having a temporary instance running the bootstrapping process is a handy mechanism, but leads to a drift between the stack definition and the existing resources that, such as described for tag management, leads in turn to operational problems.

DXC Technology intended solution in future versions is to replace this bootstrapping method with a CodePipeline pipeline that will use CodeBuild projects and associated scripts and lambdas. Meanwhile, a new template that removes the temporary instance has been created, to update the stack with it once the deployment is completed.

To create this post-deployment template it has been necessary to remove the dependency between the ElasticBeanstalk environment resource and the Wait Condition used by the temporary instance to signal the moment when the application artifacts are build and the EB environment can be launched. Tihs dependency consists in the obtention of the ElasticBeanstalk environment SolutionStackName, from the WaitCondition data that is in turn fed by the instance's user data script with the value corresponding to the latest available Tomcat solution obtained with an AWS CLI command.

The dependency is replaced with the hard coded value of the latest Tomcat Solution supported by ElasticBeanstalk. In the future bootstrapping process based on CodePipeline the dynamic obtention of this value will be restored.

# Parameters

As described in the `Changes To The Official Version` chapter, a new `00-main-dxc.template` template is used to store in the code repository the values used to create each environment, and store in AWS SecretsManager those values required for operation automation artifacts, and to provide also human operators with access to secret values such as the database master user password, in a secure and access-controlled way.  

Besides the parameters defined by the official OHDSIonAWS templates, wich are described in the [README.md](README.md) document, the changes introduced by DXC Technology imply the following additional parameters:

|Parameter|Description|Values|
|---------|-----------|------|
|S3TemplatesBucket|Bucket where the deployment CFN templates are stored|Bucket Name, accesible to the AWS user deploying them| 
|S3TemplatesPrefix|Object prefix of the CFN templates|Object prefix of the templates| 
|WebAsgDesired|DesiredCapacity of the AutoScalingGroup| >=WebAsgMin and <=WebAsgMax|
|CreateVpc|Create a new VPC or use an existing one. If `false`the VPCId and all SubnetId parameters are required to have valid values|true/false|
|VPCId    |ID of the VPC if CreateVpc is `true`|Valid VPC ID|
|SubnetPublicA|ID of a public subnet in AZ A. If CreateVpc is `true`|Valid Public subnet Id|
|SubnetPublicB|ID of a public subnet in AZ B. If CreateVpc is `true`|Valid Public subnet Id|
|SubnetAppA|ID of a private subnet in AZ A. If CreateVpc is `true`|Valid Private subnet Id|
|SubnetAppB|ID of a private subnet in AZ B. If CreateVpc is `true`|Valid Private subnet Id|
|SubnetDataA|ID of a private subnet in AZ A. If CreateVpc is `true`|Valid Private subnet Id|
|SubnetDataB|ID of a private subnet in AZ B. If CreateVpc is `true`|Valid Private subnet Id|

  