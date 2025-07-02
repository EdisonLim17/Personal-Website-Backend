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
        return {
                'statusCode': 500,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,OPTIONS',
                    'Access-Control-Allow-Credentials': 'true'
                },
                'body': json.dumps({'error': 'No visitor count item found.'})
        }
    else:
        try:
            curr_count = response['Item']['num']
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,OPTIONS',
                    'Access-Control-Allow-Credentials': 'true'
                },
                'body': json.dumps({'num_views': curr_count}, cls=DecimalEncoder)
            }
        except Exception as e:
            print(f"Error retrieving visitor count: {str(e)}")
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
