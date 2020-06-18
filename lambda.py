import json


def lambda_handler(event, context): 
	# Handler function (argumentA, argumentB, operant) => computed result
	# Event consists of request body
	# Context contains metadata about the request

    json_data = json.loads(event["body"]) 
    argumentA = int(json_data["argumentA"])
    argumentB = int(json_data["argumentB"])
    operand   = str(json_data["operand"])

    result = compute(argumentA, argumentB, operand)

    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }

def compute(argumentA, argumentB, operand):
	# Compute method performs arithmetic operation on the arguments based on the operand
	# argumentA, argumentB - any numerical value
	# operand - one of [+, -, *, /] arithmetic operand symbols

    operands = {'+': lambda argumentA, argumentB: argumentA + argumentB, 
                '-': lambda argumentA, argumentB: argumentA - argumentB, 
                '*': lambda argumentA, argumentB: argumentA * argumentB, 
                '/': lambda argumentA, argumentB: argumentA / argumentB
               }
    operation = operands.get(operand)
    return operation(argumentA, argumentB)

