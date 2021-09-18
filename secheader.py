import json
import os

DOMAIN_NAME = os.getenv('DOMAIN_NAME')

STATIC_HEADERS_TO_ADD = {
    'x-frame-options': [{
        'key':'X-Frame-Options',
        'value': 'DENY'
        }],
    'content-security-policy': [{
        'key': 'Content-Security-Policy', 
        'value': "default-src https://{DOMAIN_NAME} https://www.{DOMAIN_NAME}; base-uri https://{DOMAIN_NAME} https://www.{DOMAIN_NAME}; img-src * 'self' data: https: 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline' https://{DOMAIN_NAME} https://www.{DOMAIN_NAME} fonts.googleapis.com data:; font-src 'self' 'unsafe-inline' fonts.gstatic.com fonts.googleapis.com ; frame-src youtube.com www.youtube.com; object-src 'none'"
        }],
    'strict-transport-security': [{
        'key': 'Strict-Transport-Security', 
        'value': 'max-age=63072000; includeSubdomains; preload'
        }],
    'x-content-type-options': [{
        'key': 'X-Content-Type-Options', 
        'value': 'nosniff'
        }],
    'x-xss-protection': [{
        'key': 'X-XSS-Protection', 
        'value': '1; mode=block'
        }], 
    'referrer-policy': [{
        'key': 'Referrer-Policy', 
        'value': 'same-origin'
        }], 
}

def lambda_handler(event, context):
   # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html#lambda-event-structure-response-origin
   response = event['Records'][0]['cf']['response']
   response['headers'].update(STATIC_HEADERS_TO_ADD)
   return response;

