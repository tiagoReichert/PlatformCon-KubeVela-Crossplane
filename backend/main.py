from flask import Flask
from flask import request
from flask import Response
import boto3
from flask_cors import CORS
import logging
from decimal import Decimal

client = boto3.client('dynamodb', region_name='us-west-2')
dynamodb = boto3.resource("dynamodb", region_name='us-west-2')
table = dynamodb.Table('my-app-table')
app = Flask(__name__)
app.logger.setLevel(logging.INFO)
CORS(app)


@app.route('/', methods=['GET'])
def hello_world():
    return 'Hello World'


@app.route('/api/items', methods=['GET'])
def get_items():
    try:
        body = table.scan()
        body = body["Items"]
        responseBody = []
        for items in body:
            responseBody.append({'price': float(items['price']), 'id': items['id'], 'name': items['name']})
        return responseBody
    except:
        return Response("Failed to get items!", status=409, mimetype='application/json')


@app.route("/api/item", methods=["PUT"])
def add_item():
    app.logger.info(request.json)

    try:
        table.put_item(
            Item={
                'id': request.json['id'],
                'price': Decimal(str(request.json['price'])),
                'name': request.json['name']
            })
        return Response("Created Item!", status=201, mimetype='application/json')
    except:
        return Response("Failed to create Item!", status=409, mimetype='application/json')


# main driver function
if __name__ == '__main__':
    # run() method of Flask class runs the application
    # on the local development server.
    app.run(host='0.0.0.0', port=8080)
