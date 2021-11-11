## AWS IAM Key Rotation
This set of CloudFormation templates and Python scripts will set up an auto-rotation function that will automatically rotate your AWS IAM User Access Keys every 90 days. At 100 days it will then disable the old Access Keys. And finally at 110 days it will delete the old Access Keys. It will also set up a secret inside AWS Secrets Manager to store the new Access Keys, with a resource policy that permits only the AWS IAM User access to them. There is also automation to send emails with a custome email template via SES that will alert account owners when rotation occurs. 

## Security
See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License
This library is licensed under the MIT-0 License. See the LICENSE file.

## Deployment Notes
**AWS IAM Key Rotation Runbook**
- Runbook located under asa-iam-rotation/Docs/ASA IAM Key Rotation Runbook (v2) 

**Simple Email Service (SES) Setup:**
1. Move the Amazon Simple Email Service (SES) service out of sandbox mode<br/>
a.	https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html<br/>
b.	Note: There is about a 24 hour wait for approval
2. While in Amazon Simple Email Service (SES), verify the senders address or the sender domain that you will use as the email source.<br/>
a.	This is the email that will be in the ‘Sender’ section of the email sent to your end users.
3. The AWS resources needed for this tool will deploy with the main CloudFormation template.