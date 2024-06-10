import boto3
import json

s3 = boto3.client('s3')

def lambda_handler(event, context):
    try:
        record = event['Records'][0]
        request = record['cf']['request']
        response = record['cf']['response'] if 'response' in record['cf'] else None

        # Add CORS headers
        response_headers = response['headers'] if response else request['headers']
        cors_headers = [
            {'key': 'access-control-allow-origin', 'value': '*'},
            {'key': 'access-control-allow-methods', 'value': 'GET, POST, HEAD, OPTIONS'},
            {'key': 'access-control-allow-headers', 'value': 'Content-Type'},
        ]
        for header in cors_headers:
            key = header['key'].lower()
            value = header['value']
            if key in response_headers:
                response_headers[key].append({'key': key, 'value': value})
            else:
                response_headers[key] = [{'key': key, 'value': value}]

        # Add security headers
        security_headers = [
            {'key': 'content-security-policy', 'value': (
                "default-src *; "
                "script-src * 'unsafe-inline'; "
                "style-src * 'unsafe-inline'; "
                "img-src * data: *; "
                "font-src *; "
                "connect-src *; "
                "object-src 'none'; "
                "form-action 'self'; "
                "frame-ancestors 'none'; "
                "upgrade-insecure-requests"
            )},
            {'key': 'strict-transport-security', 'value': 'max-age=63072000; includeSubdomains; preload'},
            {'key': 'x-content-type-options', 'value': 'nosniff'},
            {'key': 'x-xss-protection', 'value': '1; mode=block'},
            {'key': 'referrer-policy', 'value': 'strict-origin-when-cross-origin'},
            {'key': 'permissions-policy', 'value': (
                "accelerometer=(), "
                "geolocation=(), "
                "microphone=(), "
                "camera=(), "
                "fullscreen=(self), "
                "payment=(), "
                "interest-cohort=(), "
                "usb=(), "
                "magnetometer=(), "
                "gyroscope=()"
            )},
        ]
        for header in security_headers:
            key = header['key'].lower()
            value = header['value']
            if key in response_headers:
                response_headers[key].append({'key': key, 'value': value})
            else:
                response_headers[key] = [{'key': key, 'value': value}]

        if response:
            return response
        else:
            return request

    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return {
            'status': '500',
            'statusDescription': 'Internal Server Error',
            'body': json.dumps({'message': f"Error in lambda_handler: {str(e)}"}),
            'headers': {
                'content-type': [{'key': 'Content-Type', 'value': 'application/json'}],
            },
        }
