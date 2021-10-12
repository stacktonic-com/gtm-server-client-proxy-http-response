___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "CLIENT",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Proxy HTTP JSON Response",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "Return the JSON response of an external HTTP service (e.g. Google Cloud Function) to the client. This client can be used to serve user recommendations or personalization data for example.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "requestPath",
    "displayName": "Request path",
    "simpleValueType": true,
    "help": "Path to claim the GTM server request. Start with a leading /",
    "defaultValue": "/profile",
    "notSetText": "This field is required"
  },
  {
    "type": "RADIO",
    "name": "requestMethod",
    "displayName": "Request method",
    "radioItems": [
      {
        "value": "GET",
        "displayValue": "GET"
      },
      {
        "value": "POST",
        "displayValue": "POST"
      }
    ],
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "httpEndpoint",
    "displayName": "External HTTP endpoint",
    "simpleValueType": true,
    "help": "HTTP endpoint of external service  (found in the GCP interface"
  },
  {
    "type": "CHECKBOX",
    "name": "passQueryParameters",
    "checkboxText": "Pass query parameters",
    "simpleValueType": true
  },
  {
    "type": "CHECKBOX",
    "name": "passBody",
    "checkboxText": "Pass request body (POST requests)",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "hostnameWhitelist",
    "displayName": "Hostname whitelist",
    "simpleValueType": true,
    "help": "Comma separated list of hostnames"
  },
  {
    "type": "CHECKBOX",
    "name": "runContainer",
    "checkboxText": "Pass response data to an event",
    "simpleValueType": true,
    "help": "Pass response data to an event and run container"
  },
  {
    "type": "TEXT",
    "name": "eventName",
    "displayName": "Event name",
    "simpleValueType": true,
    "help": "Configure event name to push response data to the GTM container",
    "defaultValue": "user_store"
  },
  {
    "type": "TEXT",
    "name": "authSecretQueryParam",
    "displayName": "Secret key query parameter",
    "simpleValueType": true,
    "help": "In which ?query\u003d parameter is the secret key passed. Leave blank when you don\u0027t want to use a secret key."
  },
  {
    "type": "TEXT",
    "name": "authSecret",
    "displayName": "Secret key",
    "simpleValueType": true,
    "help": "Secret key to check within external HTTP service"
  }
]


___SANDBOXED_JS_FOR_SERVER___

const claimRequest = require("claimRequest");
const encodeUriComponent = require("encodeUriComponent");
const getRequestHeader = require("getRequestHeader");
const getRequestPath = require("getRequestPath");
const getRequestQueryParameter = require("getRequestQueryParameter");
const getRequestQueryString = require("getRequestQueryString");
const JSON = require("JSON");
const returnResponse = require("returnResponse");
const runContainer = require("runContainer");
const sendHttpGet = require("sendHttpGet");
const setResponseBody = require("setResponseBody");
const setResponseHeader = require("setResponseHeader");
const setResponseStatus = require("setResponseStatus");
const logToConsole = require('logToConsole');

// Check if hostname is allowed
let originAllowed;

const hostnameList = (data.hostnameWhitelist !== undefined) ? data.hostnameWhitelist.toLowerCase().split(",") : [];
if (hostnameList.length > 0) {
  // Compare whitelist to request origin
  hostnameList.forEach(hostname => {
    if (getRequestHeader("origin") === "https://" + hostname) {
      originAllowed = true;
    }
  });
} else {
  // If no whitelist is specified
  originAllowed = true;
}

// Claim request
if (getRequestPath() === data.requestPath && originAllowed === true) {
  
  claimRequest();
  
  // Set response headers
  setResponseHeader("content-type", "application/json");
  setResponseHeader("access-control-allow-credentials", "true");
  setResponseHeader("access-control-allow-origin", getRequestHeader("origin"));
  
  // Build request URL
  let requestUrl = data.httpEndpoint;
  
  if (data.passQueryParameters === true) {
      const queryString = getRequestQueryString() || "";

      if (data.authSecretQueryParam != '') {
        requestUrl = data.httpEndpoint + "?" + data.authSecretQueryParam + "=" + data.authSecret + "&" + queryString;
      } else {
        requestUrl = data.httpEndpoint + "?" + queryString; 
      }
  } 
  
  // Make request to Google Cloud Function
  sendHttpGet(requestUrl, (statusCode, headers, body) => {

    // Succesfull response
    if (statusCode >= 200 && statusCode < 300) {
      
      const jsonData = JSON.parse(body);
      
      // Parse result into an event object
      const event = {
        event_name: data.eventName,
        data: jsonData
      };
      
      // Return succesfull response headers
      setResponseStatus(200);
      setResponseBody(body);
      
      if (data.runContainer === true) {
        // Run container with eventdata (if enabled)
        runContainer(event, () => returnResponse());
      } else {
        // Only return response without running container
        returnResponse();
      }
    } 
    else {
      // Return invalid reponse and don't run container
      setResponseStatus(400);
      setResponseBody("{}");
      returnResponse();
    }
    
  });
}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "queryParametersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "bodyAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "headersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "pathAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "return_response",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_response",
        "versionId": "1"
      },
      "param": [
        {
          "key": "writeResponseAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "writeHeaderAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "writeStatusAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "writeHeadersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "writeBodyAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "run_container",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Untitled test 1
  code: |-
    const mockData = {
      // Mocked field values
    };

    // Call runCode to run the template's code.
    runCode(mockData);


___NOTES___

Created on 10/12/2021, 6:12:56 PM


