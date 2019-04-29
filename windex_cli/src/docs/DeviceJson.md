# DeviceJson

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **str** | Name of the device if available | [optional] 
**fqdn** | **str** |  | [optional] 
**eui64** | **str** |  | [optional] 
**created_at** | **datetime** | Device creation datetime | [optional] 
**updated_at** | **datetime** | Device last update datetime | [optional] 
**device_type_id** | **int** |  | [optional] 
**manufacturer_id** | **int** |  | [optional] 
**idev_id** | **str** |  | [optional] 
**traffic_counts** | [**DeviceBodyTrafficCounts**](DeviceBodyTrafficCounts.md) |  | [optional] 
**mud_url** | **str** |  | [optional] 
**profile_id** | **int** |  | [optional] 
**current_vlan** | **str** |  | [optional] 
**wan_enabled** | **bool** |  | [optional] 
**lan_enabled** | **bool** |  | [optional] 
**firewall_rules** | **list[object]** |  | [optional] 
**firewall_rule_names** | **list[object]** |  | [optional] 
**deleted** | **bool** |  | [optional] [default to False]
**quaranteed** | **bool** |  | [optional] 
**device_enabled** | **bool** |  | [optional] 
**device_state** | **str** |  | [optional] 
**failure_details** | [**object**](.md) |  | [optional] 
**ipv4** | **str** |  | [optional] 
**ipv6** | **str** |  | [optional] 
**acp_prefix** | **str** |  | [optional] 
**idevid_hash** | **str** |  | [optional] 
**ldevid** | **str** |  | [optional] 
**ldevid_hash** | **str** |  | [optional] 
**wpa_key** | **str** |  | [optional] 
**id** | **int** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


