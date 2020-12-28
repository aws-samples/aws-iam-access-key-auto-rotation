## aws-iam-access-key-auto-rotation

This set of CloudFormation templates and Python scripts will set up an auto-rotation function that will automatically rotate your AWS IAM User Access Keys every 90 days. At 100 days it will then disable the old Access Keys. And finally at 110 days it will delete the old Access Keys. It will also set up a secret inside AWS Secrets Manager to store the new Access Keys, with a resource policy that permits only the AWS IAM User access to them. There is also automation to set up an Amazon DynamoDB table to house the email addresses for your accounts, and a SNS Topic that will use these email addresses to alert account owners when rotation occurs. 

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

## Deployment
### One-Time Setup Steps for End User Emailing Tool:
1. Move the Amazon Simple Email Service (SES) service out of sandbox mode<br/>
a.	https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html<br/>
b.	Note: There is about a 24 hour wait for approval
2. While in Amazon Simple Email Service (SES), verify the senders address or the sender domain that you will use as the email source.<br/>
a.	This is the email that will be in the ‘Sender’ section of the email sent to your end users.
3. The AWS resources needed for this tool will deploy with the main CloudFormation template.
4. Once the template is fully deployed, you will need to upload the following CSV files into the new S3 bucket created for importing into DynamoDB. By uploading the file, it will kick off the import script.<br/>
a.	csv-to-s3-account-emails.csv
5. You can validate import was successful by going to:<br/>
a.	https://console.aws.amazon.com/dynamodb/<br/>
b.	‘Tables’ on the left side menu<br/>
c.	Clicking on the table name ‘aws-account-emails’<br/>
d.	Clicking on the ‘Items’ tab
6. Upload email templates
7. To monitor the EmailerTool, you can review the logs in CloudWatch under<br/>
a.	 /aws/lambda/Direct-to-End-User-Emailing-Tool 
8.	All config rules are setup to send SNS notifications to this Lambda for processing and emailing to end users.

### Remedation Setup:
1. Upload all files to an S3 bucket of your choosing. Make sure all files are stored in the prefix specified. The prefix "iam-rotation" was pre-filled for you.
2. Log into the AWS Management Console, and select S3 from the Services menu. 
3. Choose a bucket, and upload the project zip files (Make sure the bucket allows all accounts in your OUs to perform s3:GetObject*.)
4. Still in the console, choose CloudFormation from the Services menu.
5. In the left-hand pane, choose StackSets. (If you’ve never created a CloudFormation stack before, choose Get Started.)
6. Click on Create StackSet.
7. Choose Upload a template file.
8. Click on Choose file and select the file named iam-key-auto-rotation-and-notifier.yaml.
9. Click Next. 
10. Give the StackSet a name. I used SecurityFindingsRemediationStackSet. 
11. Fill in all parameter fields required.
12. Click Next. 
13. For Permissions, select Self services permissions and select the AWS IAM Role AWSCloudFormationStackSetAdministrativeRole. (If you created a different Role for this operation, choose this instead.)
14. Click Next. 
15. Select Deploy stacks in organizational units and enter all OUs in the text field separated by a comma.
16. For regions, choose the same region the S3 bucket lives in that you used to upload the zip files..
17. Leave all other defaults and click Next. 
18. After reviewing the information, click the checkbox next to I acknowledge that AWS CloudFormation might create IAM resources. 
19. Click Submit. 

