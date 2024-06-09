"ddb-table": {
    annotations: {}
    attributes: {
        appliesToWorkloads: ["three-tier-app"]
        conflictsWith: []
        podDisruptive:   false
        workloadRefPath: ""
    }
    description: ""
    labels: {}
    type: "trait"
}
template: {
	outputs: "dynamodb-table": {
			apiVersion: "dynamodb.aws.upbound.io/v1beta1"
			kind:       "Table"
			metadata: {
				name:	context.name + "-table"
			}
			spec: forProvider: {
				attribute: parameter.attribute
				billingMode: "PAY_PER_REQUEST"
				hashKey:      parameter.hashKey
				region:       parameter.region
				tags: {
					Name:	context.name + "-table"
				}
			}
		}
		outputs: "role": {
			apiVersion: "iam.aws.upbound.io/v1beta1"
			kind:       "Role"
			metadata: {
				labels: "upbound.io/role-name": context.name + "-role"
				name: context.name + "-role"
			}
			spec: forProvider: {
				assumeRolePolicy: """
					{
					  "Version": "2012-10-17",
					  "Statement": [
					      {
					          "Effect": "Allow",
					          "Principal": {
					              "Federated": "arn:aws:iam::{AWS_ACCOUNT_ID}:oidc-provider/oidc.eks.\(parameter.region).amazonaws.com/id/{OIDC_ID}"
					          },
					          "Action": "sts:AssumeRoleWithWebIdentity",
					          "Condition": {
					              "StringEquals": {
					                  "oidc.eks.\(parameter.region).amazonaws.com/id/{OIDC_ID}:aud": "sts.amazonaws.com",
					                  "oidc.eks.\(parameter.region).amazonaws.com/id/{OIDC_ID}:sub": "system:serviceaccount:\(context.namespace):\(context.name)-sa"
					              }
					          }
					      }
					   ]
					}
					"""
				inlinePolicy: [{
					name: "my_inline_policy"
					policy:"""
						{
						  "Version": "2012-10-17",
						  "Statement": [
						    {
						      "Effect": "Allow",
						      "Resource": "arn:aws:dynamodb:\(parameter.region):{AWS_ACCOUNT_ID}:table/\(context.name)-table",
						      "Action": [
						        "dynamodb:PutItem",
						        "dynamodb:DeleteItem",
						        "dynamodb:GetItem",
						        "dynamodb:Scan"
						      ]
						    }
						  ]
						}
						"""
				}]
			}
		}
	outputs: "ddb-sa": {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				annotations: "eks.amazonaws.com/role-arn": "arn:aws:iam::{AWS_ACCOUNT_ID}:role/" + context.name + "-role"
				name:     context.name + "-sa"
				namespace: context.namespace
			}
		}

    parameter: {
       region: string
       hashKey: string
       attribute: [...{
      					name: string
      					type: string
      				}]
    }
}