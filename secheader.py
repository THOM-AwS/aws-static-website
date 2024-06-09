def add_cors_headers(headers):
    """Add CORS headers to the response"""
    headers["access-control-allow-origin"] = [
        {"key": "access-control-allow-origin", "value": "*"}
    ]
    headers["access-control-allow-methods"] = [
        {"key": "access-control-allow-methods", "value": "GET, POST, OPTIONS"}
    ]
    headers["access-control-allow-headers"] = [
        {"key": "access-control-allow-headers", "value": "Content-Type, Authorization"}
    ]

STATIC_HEADERS_TO_ADD = {
    "x-frame-options": [{"key": "x-frame-options", "value": "DENY"}],
    "content-security-policy": [
        {
            "key": "content-security-policy",
            "value": (
                "default-src 'self'; "
                "base-uri 'self'; "
                "img-src 'self' data: *.googleapis.com https://www.google-analytics.com https://analytics.google.com https://*.hamer.cloud https://*.datahub.io https://cdnjs.cloudflare.com https://play.google.com; "
                "script-src 'self' 'unsafe-inline' 'unsafe-eval' *.googleapis.com https://maps.gstatic.com https://www.youtube.com *.google.com https://*.gstatic.com https://www.googletagmanager.com https://www.google-analytics.com https://cdn.jsdelivr.net https://github.com https://cdnjs.cloudflare.com; "
                "style-src 'self' 'unsafe-inline' *.googleapis.com https://fonts.googleapis.com https://cdnjs.cloudflare.com; "
                "font-src 'self' data: *.gstatic.com *.googleapis.com https://cdnjs.cloudflare.com; "
                "frame-src https://www.youtube.com *.google.com https://cdn.jsdelivr.net; "
                "connect-src 'self' https://www.google-analytics.com https://maps.googleapis.com https://*.hamer.cloud https://analytics.google.com https://api.openweathermap.org https://datahub.io https://pkgstore.datahub.io https://cdn.jsdelivr.net https://api.github.com; "
                "object-src 'none'; "
                "form-action 'self'; "
                "frame-ancestors 'none'; "
                "block-all-mixed-content; "
                "upgrade-insecure-requests"
            ),
        }
    ],
    "strict-transport-security": [
        {
            "key": "strict-transport-security",
            "value": "max-age=63072000; includeSubdomains; preload",
        }
    ],
    "x-content-type-options": [{"key": "x-content-type-options", "value": "nosniff"}],
    "x-xss-protection": [{"key": "x-xss-protection", "value": "1; mode=block"}],
    "referrer-policy": [{"key": "referrer-policy", "value": "same-origin"}],
}

def lambda_handler(event, context):
    request = event["Records"][0]["cf"]["request"]
    response = event["Records"][0]["cf"]["response"]

    # Add or update security headers
    headers = response.get("headers", {})
    for key, value in STATIC_HEADERS_TO_ADD.items():
        headers[key] = value  # Header names must be in lowercase

    # Add CORS headers
    add_cors_headers(headers)

    # Handle OPTIONS preflight requests
    if request["method"] == "OPTIONS":
        return {
            "status": "204",
            "statusDescription": "No Content",
            "headers": headers,
        }

    # Update response headers with modified headers
    response["headers"] = headers
    return response
