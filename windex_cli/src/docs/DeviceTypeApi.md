# client.DeviceTypeApi

All URIs are relative to *https://mud.nXXXXXX.router.securehomegateway.ca/api/1.0*

Method | HTTP request | Description
------------- | ------------- | -------------
[**create_device_type**](DeviceTypeApi.md#create_device_type) | **POST** /device_types | Add a new device type to the store
[**get_device_type**](DeviceTypeApi.md#get_device_type) | **GET** /device_types/{id} | Get a device type information
[**list_device_types**](DeviceTypeApi.md#list_device_types) | **GET** /device_types | Get device types
[**update_device_type**](DeviceTypeApi.md#update_device_type) | **PUT** /device_types/{id} | Update an existing device type


# **create_device_type**
> DeviceTypeJson create_device_type(device_type_body)

Add a new device type to the store

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.DeviceTypeApi()
device_type_body = client.DeviceTypeBody() # DeviceTypeBody | Device type object

try:
    # Add a new device type to the store
    api_response = api_instance.create_device_type(device_type_body)
    pprint(api_response)
except ApiException as e:
    print("Exception when calling DeviceTypeApi->create_device_type: %s\n" % e)
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **device_type_body** | [**DeviceTypeBody**](DeviceTypeBody.md)| Device type object | 

### Return type

[**DeviceTypeJson**](DeviceTypeJson.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_device_type**
> list[DeviceType] get_device_type(id)

Get a device type information

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.DeviceTypeApi()
id = 56 # int | ID of the device

try:
    # Get a device type information
    api_response = api_instance.get_device_type(id)
    pprint(api_response)
except ApiException as e:
    print("Exception when calling DeviceTypeApi->get_device_type: %s\n" % e)
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**| ID of the device | 

### Return type

[**list[DeviceType]**](DeviceType.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list_device_types**
> InlineResponse2001 list_device_types()

Get device types

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.DeviceTypeApi()

try:
    # Get device types
    api_response = api_instance.list_device_types()
    pprint(api_response)
except ApiException as e:
    print("Exception when calling DeviceTypeApi->list_device_types: %s\n" % e)
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**InlineResponse2001**](InlineResponse2001.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **update_device_type**
> DeviceType update_device_type(id, device_type_body)

Update an existing device type

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.DeviceTypeApi()
id = 56 # int | ID of the device
device_type_body = client.DeviceTypeBody() # DeviceTypeBody | Device type object

try:
    # Update an existing device type
    api_response = api_instance.update_device_type(id, device_type_body)
    pprint(api_response)
except ApiException as e:
    print("Exception when calling DeviceTypeApi->update_device_type: %s\n" % e)
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**| ID of the device | 
 **device_type_body** | [**DeviceTypeBody**](DeviceTypeBody.md)| Device type object | 

### Return type

[**DeviceType**](DeviceType.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

