// CloudFront Function (viewer-request, runtime cloudfront-js-2.0).
// 1. 301 www.<domain> to the apex, keeping path and query string.
// 2. Map clean URLs to the S3 object: "/" and "/dir/" get index.html,
//    "/page" gets "/page.html". Paths that already have an extension pass through.
function handler(event) {
  var request = event.request;
  var host = request.headers.host ? request.headers.host.value : '';
  if (host.indexOf('www.') === 0) {
    var qs = '';
    var keys = Object.keys(request.querystring);
    for (var i = 0; i < keys.length; i++) {
      var k = keys[i];
      var v = request.querystring[k].value;
      qs += (i === 0 ? '?' : '&') + encodeURIComponent(k) + (v === '' ? '' : '=' + encodeURIComponent(v));
    }
    return {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: { location: { value: 'https://' + host.slice(4) + request.uri + qs } }
    };
  }
  var uri = request.uri;
  if (uri.charAt(uri.length - 1) === '/') {
    request.uri = uri + 'index.html';
  } else if (uri.split('/').pop().indexOf('.') === -1) {
    request.uri = uri + '.html';
  }
  return request;
}
