from __future__ import print_function

import sys

import argparse
import json
import re
import cv2
import pyzbar.pyzbar as pyzbar
from PIL import Image
from pprint import pprint

import client
from client.configuration import Configuration
from client.rest import ApiException


first_cap_re = re.compile('(.)([A-Z][a-z]+)')
all_cap_re = re.compile('([a-z0-9])([A-Z])')


def up_first(string):
    return string[0].upper() + string[1:]


def cc_to_snake(string):
    s1 = first_cap_re.sub(r'\1_\2', string)
    return all_cap_re.sub(r'\1_\2', s1).lower()


def call_api(coll, method, obj_id=None, obj_body=None, get_params=None):
    response = None
    api_instance = getattr(client, '{}Api'.format(up_first(coll)))(client.ApiClient(configuration))
    if method == 'get':
        if obj_id is not None:
            params = get_params or{}
            response = getattr(api_instance, 'get_{}'.format(cc_to_snake(coll)))(obj_id, **params)
        else:
            response = getattr(api_instance, 'list_{}s'.format(cc_to_snake(coll)))()
    elif method == 'post':
        body = json.loads(obj_body)
        obj = getattr(client, '{}Body'.format(up_first(coll)))(**body)
        response = getattr(api_instance, 'create_{}'.format(cc_to_snake(coll)))(obj)
    elif method == 'put':
        body = json.loads(obj_body)
        obj = getattr(client, '{}Body'.format(up_first(coll)))(**body)
        response = getattr(api_instance, 'update_{}'.format(cc_to_snake(coll)))(obj_id, obj)

    return response


def decode_qr(img):
    qr = None
    decoded = pyzbar.decode(img)
    for d in decoded:
        if d.type == 'QRCODE':
            if qr:
                print("More than one QR code detected")
                sys.exit(1)
            qr = d

    return qr


def read_qr(qr_code_filename=None):
    if not qr_code_filename:
        cap = cv2.VideoCapture(0)
        try:
            while True:
                ret, frame = cap.read()
                if not ret:
                    print("Cannot read your camera device")
                    sys.exit(1)

                qr = decode_qr(frame)
                if qr:
                    break

                cv2.imshow("Frame", frame)
                cv2.waitKey(1)
        except KeyboardInterrupt:
            sys.exit(1)

    else:
        qr = decode_qr(Image.open(args.qr_code))
        if not qr:
            print("No QR Code detected")
            sys.exit(1)

    return qr.data


if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='windex-cli')

    parser.add_argument('--ssl-key', type=str, help='SSL key file', required=True)
    parser.add_argument('--ssl-cert', type=str, help='SSL cert file', required=True)
    parser.add_argument('--host', type=str, help='Server url', required=True)
    subparser = parser.add_subparsers(dest='collection')

    for coll in ['device', 'user']:
        obj_parser = subparser.add_parser(coll, help='{} APIs'.format(up_first(coll)))
        obj_subparser = obj_parser.add_subparsers(dest='method')
        # - Get
        obj_parser_get = obj_subparser.add_parser('get', help='Get {0} or list {0}s'.format(coll))
        obj_parser_get.add_argument('--id', type=int, help='Get the {} with ID'.format(coll))
        # - Post
        obj_parser_post = obj_subparser.add_parser('post', help='Create a {}'.format(coll))
        obj_parser_post.add_argument('--body', type=str, help='{} body'.format(up_first(coll)), required=True)
        # - Put
        obj_parser_put = obj_subparser.add_parser('put', help='Update a {}'.format(coll))
        obj_parser_put.add_argument('--id', type=int, help='ID of the {} to update'.format(coll), required=True)
        obj_parser_put.add_argument('--body', type=str, help='{} body with updates'.format(up_first(coll)),
                                    required=True)

        if coll == 'device':
            # - Scan QR code
            obj_parser_scan = obj_subparser.add_parser('scan', help='Scan a QR code to retrieve the MUD URL of the '
                                                                    'device. If URL option is provided, no QR code is '
                                                                    'scanned. If qr-code option is provided, '
                                                                    'the QR code will be obtained from a file else'
                                                                    'it will open your webcam for you to scan a QR '
                                                                    'code')
            obj_parser_scan.add_argument('--url', type=str, help='The MUD file URL for the device')
            obj_parser_scan.add_argument('--qr-code', type=str, help='A file containing the QR code of the MUD '
                                                                     'URL of the device')
            obj_parser_scan.add_argument('--id', type=str, help='The ID of the device to update', required=True)
            # - Add device
            obj_parser_create = obj_subparser.add_parser('create', help='Create a new device')
            obj_parser_create.add_argument('--name', type=str, help='Name of the new device', required=True)
            # - Get new devices
            obj_subparser.add_parser('new', help='Get the list of new devices')
            # - Authorize device
            obj_parser_enable = obj_subparser.add_parser('enable', help='Enable a device')
            obj_parser_enable.add_argument('--id', type=str, help='The ID of the device to enable', required=True)

    args = parser.parse_args()

    # create an instance of the API class
    if not args.collection:
        print('Please specify a collection')
        sys.exit(1)
    if not args.method:
        print('Please specify a method')
        sys.exit(1)

    configuration = Configuration()
    configuration.verify_ssl = False
    configuration.cert_file = args.ssl_cert
    configuration.key_file = args.ssl_key
    configuration.host = args.host

    # API
    if args.method in ['get', 'post', 'put']:
        obj_id = None
        obj_body = None
        if 'id' in args:
            obj_id = args.id
        if 'body' in args:
            obj_body = args.body
        try:
            api_response = call_api(args.collection, args.method, obj_id=obj_id, obj_body=obj_body)
            pprint(api_response)
        except ApiException as e:
            print("Exception when calling api: %s\n" % e)
            sys.exit(1)
        sys.exit(0)

    if args.collection == 'device':
        if args.method == 'scan':
            if args.url:
                mud_url = args.url
            else:
                mud_url = read_qr(args.qr_code)
            call_api('device', 'put', obj_id=args.id, obj_body=f'{{"mud_url": "{mud_url}"}}')
            print(f'Add MUD URL {mud_url} to device')
        if args.method == 'create':
            device = call_api('device', 'post', obj_body=f'{{"name": "{args.name}"}}')
            # call_api('device', 'post', obj_body={"alias": args.name})
            print(f"New device {device.name} created")
            print(f"WPA KEY: {device.wpa_key}")
        if args.method == 'new':
            devices = call_api('device', 'get').devices
            # devices = call_api('device', 'get', get_params={"deviceStatus": "new"}).devices
            if not devices:
                print('No new device detected')
            else:
                print('List of devices:\n  - {}'.format(
                    '\n  - '.join(f"{d.device.id}: {d.device.name}" for d in sorted(devices, key=lambda x: x.device.id))))
                    # '\n  - '.join(f"{d.device.id}: {d.device.alias}" for d in devices)))
        if args.method == 'enable':
            device = call_api('device', 'get', obj_id=args.id).device
            if not device.mud_url:
                print('Please add a MUD URL to the device with the device scan command')
                sys.exit(1)
            call_api('device', 'put', obj_id=args.id, obj_body='{"device_enabled": true}')
            print(f"Device {device.name} enabled")
            # print(f"Device {device.alias} enabled")
        sys.exit(0)
