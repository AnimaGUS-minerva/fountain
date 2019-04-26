# client.ManufacturerApi

All URIs are relative to *https://mud.nXXXXXX.router.securehomegateway.ca/api/1.0*

Method | HTTP request | Description
------------- | ------------- | -------------
[**create_manufacturer**](ManufacturerApi.md#create_manufacturer) | **POST** /manufacturers | Add a new manufacturer
[**get_manufacturer**](ManufacturerApi.md#get_manufacturer) | **GET** /manufacturers/{id} | Get a manufacturer information
[**list_manufacturers**](ManufacturerApi.md#list_manufacturers) | **GET** /manufacturers | Get manufacturers
[**update_manufacturer**](ManufacturerApi.md#update_manufacturer) | **PUT** /manufacturers/{id} | Update an existing manufacturer


# **create_manufacturer**
> create_manufacturer(manufacturer_body)

Add a new manufacturer

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.ManufacturerApi()
manufacturer_body = client.ManufacturerBody() # ManufacturerBody | Manufacturer object

try:
    # Add a new manufacturer
    api_instance.create_manufacturer(manufacturer_body)
except ApiException as e:
    print("Exception when calling ManufacturerApi->create_manufacturer: %s\n" % e)
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **manufacturer_body** | [**ManufacturerBody**](ManufacturerBody.md)| Manufacturer object | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_manufacturer**
> Manufacturer get_manufacturer(id)

Get a manufacturer information

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.ManufacturerApi()
id = 56 # int | ID of the device

try:
    # Get a manufacturer information
    api_response = api_instance.get_manufacturer(id)
    pprint(api_response)
except ApiException as e:
    print("Exception when calling ManufacturerApi->get_manufacturer: %s\n" % e)
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**| ID of the device | 

### Return type

[**Manufacturer**](Manufacturer.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list_manufacturers**
> InlineResponse2002 list_manufacturers()

Get manufacturers

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.ManufacturerApi()

try:
    # Get manufacturers
    api_response = api_instance.list_manufacturers()
    pprint(api_response)
except ApiException as e:
    print("Exception when calling ManufacturerApi->list_manufacturers: %s\n" % e)
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**InlineResponse2002**](InlineResponse2002.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **update_manufacturer**
> update_manufacturer(id, manufacturer_body)

Update an existing manufacturer

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.ManufacturerApi()
id = 56 # int | ID of the device
manufacturer_body = client.ManufacturerBody() # ManufacturerBody | Manufacturer object

try:
    # Update an existing manufacturer
    api_instance.update_manufacturer(id, manufacturer_body)
except ApiException as e:
    print("Exception when calling ManufacturerApi->update_manufacturer: %s\n" % e)
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**| ID of the device | 
 **manufacturer_body** | [**ManufacturerBody**](ManufacturerBody.md)| Manufacturer object | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

