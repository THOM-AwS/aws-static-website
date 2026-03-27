import json


def lambda_handler(event, context):
    try:
        record = event['Records'][0]
        request = record['cf']['request']
        response = record['cf']['response'] if 'response' in record['cf'] else None

        response_headers = response['headers'] if response else request['headers']

        # Security headers (sensible defaults for any static site)
        security_headers = [
            {'key': 'strict-transport-security', 'value': 'max-age=63072000; includeSubdomains; preload'},
            {'key': 'x-content-type-options', 'value': 'nosniff'},
            {'key': 'x-frame-options', 'value': 'SAMEORIGIN'},
            {'key': 'referrer-policy', 'value': 'strict-origin-when-cross-origin'},
            {'key': 'permissions-policy', 'value': (
                "accelerometer=(), "
                "geolocation=(), "
                "microphone=(), "
                "camera=(), "
                "fullscreen=(self), "
                "payment=()"
            )},
            {'key': 'content-security-policy', 'value': (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data:; "
                "font-src 'self'; "
                "frame-ancestors 'self'; "
                "upgrade-insecure-requests"
            )},
        ]
        for header in security_headers:
            key = header['key'].lower()
            value = header['value']
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
            'body': json.dumps({'message': f"Error: {str(e)}"}),
            'headers': {
                'content-type': [{'key': 'content-type', 'value': 'application/json'}],
            },
        }
