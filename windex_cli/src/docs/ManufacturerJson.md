# ManufacturerJson

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **str** | Name of the manufacturer | [optional] 
**created_at** | **datetime** | Manufacturer creation datetime | [optional] 
**updated_at** | **datetime** | Manufacturer last update datetime | [optional] 
**masa_url** | **str** |  | [optional] 
**issuer_public_key** | **str** |  | [optional] 
**trust** | **str** | unknown: The manufacturer&#39;s status is unknown. firstused: The manufacturer&#39;s has been seen by issuer_dn, but is otherwise unknown. admin: A manufacturer that has been marked by the admin as trusted for pure-EST (no BRSKI) enrollment. brski: A manufacturer that will do BRSKI voucher-request/voucher process. webpki: Probably not useful, not well defined.  | [optional] [default to 'unknown']
**issuer_dn** | **str** |  | [optional] 
**id** | **int** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


