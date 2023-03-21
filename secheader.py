import json
import os

STATIC_HEADERS_TO_ADD = {
    'x-frame-options': [{
        'key': 'X-Frame-Options',
        'value': 'DENY'
    }],
    'content-security-policy': [{
        'key': 'Content-Security-Policy',
        'value':
        "default-src 'self' data: *.googleapis.com https://www.google-analytics.com;"
        "base-uri 'self';"
        "img-src * 'self' data: https: 'unsafe-inline';"
        "script-src 'self' 'unsafe-inline' 'unsafe-eval' *.googleapis.com https://maps.gstatic.com https://www.youtube.com *.google.com https://*.gstatic.com https://www.googletagmanager.com data: blob: https://www.google-analytics.com;"
        "style-src 'self' 'unsafe-inline' *.googleapis.com https://fonts.googleapis.com data:;"
        "font-src 'self' 'unsafe-inline' *.gstatic.com *.googleapis.com;"
        "frame-src https://youtube.com https://www.youtube.com *.google.com;"
        "connect-src 'self' https://www.google-analytics.com https://maps.googleapis.com;"
        "object-src 'none'"
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
    return response
