import boto3

ec2_client = boto3.client('ec2')
asg_client = boto3.client('autoscaling')

def lambda_handler(event, context):
    print("Event received:", event)

    # 1. Extract instance ID from event (CloudWatch or EventBridge)
    try:
        instance_id = event['detail']['instance-id']
        print(f"Instance ID to remediate: {instance_id}")
    except KeyError:
        print("No instance ID found in event.")
        return

    # 2. Describe instance to find ASG tag
    try:
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        tags = instance.get('Tags', [])
    except Exception as e:
        print(f"Failed to describe instance: {e}")
        return

    # 3. Check for ASG tag
    asg_name = None
    for tag in tags:
        if tag['Key'] == 'aws:autoscaling:groupName':
            asg_name = tag['Value']
            break

    if not asg_name:
        print("Instance not part of an Auto Scaling Group.")
        return

    # 4. Terminate instance through ASG
    try:
        asg_client.terminate_instance_in_auto_scaling_group(
            InstanceId=instance_id,
            ShouldDecrementDesiredCapacity=False
        )
        print(f"Instance {instance_id} terminated. ASG {asg_name} will replace it.")
    except Exception as e:
        print(f"Failed to terminate instance via ASG: {e}")
