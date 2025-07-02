import json
import boto3
from decimal import Decimal

class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return int(o) if o % 1 == 0 else float(o)
        return super(DecimalEncoder, self).default(o)

ddb = boto3.resource('dynamodb', region_name='us-east-1')
tb = ddb.Table('VisitorCount')

def lambda_handler(event, context):
    response = tb.get_item(Key={'id': 'visitor_count'})
    if 'Item' not in response:
        tb.put_item(Item={'id': 'visitor_count', 'num': 1})
        curr_count = 1
    else:
        try:
            response = tb.update_item(
                Key={ 'id': 'visitor_count' },
                UpdateExpression='SET num = if_not_exists(num, :start) + :inc',
                ExpressionAttributeValues={
                    ':inc': 1,
                    ':start': 0
                },
                ReturnValues='UPDATED_NEW'
            )
            curr_count = int(response['Attributes']['num'])
        except Exception as e:
            print(f"Error updating count: {str(e)}")
            return {
                'statusCode': 500,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,OPTIONS',
                    'Access-Control-Allow-Credentials': 'true'
                },
                'body': json.dumps({'error': 'Failed to fetch visitor count.'})
            }

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',  # or '*' for public access
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,OPTIONS',
            'Access-Control-Allow-Credentials': 'true'
        },
        'body': json.dumps({'num_views': curr_count}, cls=DecimalEncoder)
    }