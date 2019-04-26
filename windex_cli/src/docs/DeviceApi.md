# client.DeviceApi

All URIs are relative to *https://mud.nXXXXXX.router.securehomegateway.ca/api/1.0*

Method | HTTP request | Description
------------- | ------------- | -------------
[**create_device**](DeviceApi.md#create_device) | **POST** /devices | Add a new device to the store
[**get_device**](DeviceApi.md#get_device) | **GET** /devices/{id} | Get a device information
[**list_devices**](DeviceApi.md#list_devices) | **GET** /devices | List devices
[**update_device**](DeviceApi.md#update_device) | **PUT** /devices/{id} | Update an existing device


# **create_device**
> create_device(device_body)

Add a new device to the store

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.DeviceApi()
device_body = client.DeviceBody() # DeviceBody | Device object

try:
    # Add a new device to the store
    api_instance.create_device(device_body)
except ApiException as e:
    print("Exception when calling DeviceApi->create_device: %s\n" % e)
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **device_body** | [**DeviceBody**](DeviceBody.md)| Device object | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_device**
> Device get_device(id)

Get a device information

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.DeviceApi()
id = 56 # int | ID of the device

try:
    # Get a device information
    api_response = api_instance.get_device(id)
    pprint(api_response)
except ApiException as e:
    print("Exception when calling DeviceApi->get_device: %s\n" % e)
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**| ID of the device | 

### Return type

[**Device**](Device.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list_devices**
> InlineResponse200 list_devices()

List devices

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.DeviceApi()

try:
    # List devices
    api_response = api_instance.list_devices()
    pprint(api_response)
except ApiException as e:
    print("Exception when calling DeviceApi->list_devices: %s\n" % e)
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**InlineResponse200**](InlineResponse200.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **update_device**
> update_device(id, device_body)

Update an existing device

### Example

```python
from __future__ import print_function
import time
import client
from client.rest import ApiException
from pprint import pprint

# create an instance of the API class
api_instance = client.DeviceApi()
id = 56 # int | ID of the device
device_body = client.DeviceBody() # DeviceBody | Device object

try:
    # Update an existing device
    api_instance.update_device(id, device_body)
except ApiException as e:
    print("Exception when calling DeviceApi->update_device: %s\n" % e)
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**| ID of the device | 
 **device_body** | [**DeviceBody**](DeviceBody.md)| Device object | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

