// This is a generated file - do not edit.
//
// Generated from data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use sharedContactDescriptor instead')
const SharedContact$json = {
  '1': 'SharedContact',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {
      '1': 'public_identity_key',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'publicIdentityKey'
    },
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
  ],
};

/// Descriptor for `SharedContact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sharedContactDescriptor = $convert.base64Decode(
    'Cg1TaGFyZWRDb250YWN0EhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBIuChNwdWJsaWNfaWRlbn'
    'RpdHlfa2V5GAIgASgMUhFwdWJsaWNJZGVudGl0eUtleRIhCgxkaXNwbGF5X25hbWUYAyABKAlS'
    'C2Rpc3BsYXlOYW1l');

@$core.Deprecated('Use additionalMessageDataDescriptor instead')
const AdditionalMessageData$json = {
  '1': 'AdditionalMessageData',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.AdditionalMessageData.Type',
      '10': 'type'
    },
    {'1': 'link', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'link', '17': true},
    {
      '1': 'contacts',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.SharedContact',
      '10': 'contacts'
    },
    {
      '1': 'restored_flame_counter',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'restoredFlameCounter',
      '17': true
    },
    {
      '1': 'ask_about_user_id',
      '3': 5,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'askAboutUserId',
      '17': true
    },
    {
      '1': 'webxdc_app',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.WebxdcApp',
      '9': 3,
      '10': 'webxdcApp',
      '17': true
    },
    {
      '1': 'webxdc_update',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.WebxdcUpdate',
      '9': 4,
      '10': 'webxdcUpdate',
      '17': true
    },
    {
      '1': 'webxdc_origin',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.WebxdcOrigin',
      '9': 5,
      '10': 'webxdcOrigin',
      '17': true
    },
    {
      '1': 'webxdc_sync',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.WebxdcSyncChunk',
      '9': 6,
      '10': 'webxdcSync',
      '17': true
    },
    {
      '1': 'webxdc_sync_request',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.WebxdcSyncRequest',
      '9': 7,
      '10': 'webxdcSyncRequest',
      '17': true
    },
  ],
  '4': [AdditionalMessageData_Type$json],
  '8': [
    {'1': '_link'},
    {'1': '_restored_flame_counter'},
    {'1': '_ask_about_user_id'},
    {'1': '_webxdc_app'},
    {'1': '_webxdc_update'},
    {'1': '_webxdc_origin'},
    {'1': '_webxdc_sync'},
    {'1': '_webxdc_sync_request'},
  ],
};

@$core.Deprecated('Use additionalMessageDataDescriptor instead')
const AdditionalMessageData_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'LINK', '2': 0},
    {'1': 'CONTACTS', '2': 1},
    {'1': 'RESTORED_FLAME_COUNTER', '2': 2},
    {'1': 'ASK_ABOUT_USER', '2': 3},
    {'1': 'WEBXDC_APP', '2': 4},
    {'1': 'WEBXDC_UPDATE', '2': 5},
    {'1': 'WEBXDC_SENT', '2': 6},
    {'1': 'WEBXDC_SYNC', '2': 7},
    {'1': 'WEBXDC_SYNC_REQUEST', '2': 8},
  ],
};

/// Descriptor for `AdditionalMessageData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List additionalMessageDataDescriptor = $convert.base64Decode(
    'ChVBZGRpdGlvbmFsTWVzc2FnZURhdGESLwoEdHlwZRgBIAEoDjIbLkFkZGl0aW9uYWxNZXNzYW'
    'dlRGF0YS5UeXBlUgR0eXBlEhcKBGxpbmsYAiABKAlIAFIEbGlua4gBARIqCghjb250YWN0cxgD'
    'IAMoCzIOLlNoYXJlZENvbnRhY3RSCGNvbnRhY3RzEjkKFnJlc3RvcmVkX2ZsYW1lX2NvdW50ZX'
    'IYBCABKANIAVIUcmVzdG9yZWRGbGFtZUNvdW50ZXKIAQESLgoRYXNrX2Fib3V0X3VzZXJfaWQY'
    'BSABKANIAlIOYXNrQWJvdXRVc2VySWSIAQESLgoKd2VieGRjX2FwcBgGIAEoCzIKLldlYnhkY0'
    'FwcEgDUgl3ZWJ4ZGNBcHCIAQESNwoNd2VieGRjX3VwZGF0ZRgHIAEoCzINLldlYnhkY1VwZGF0'
    'ZUgEUgx3ZWJ4ZGNVcGRhdGWIAQESNwoNd2VieGRjX29yaWdpbhgIIAEoCzINLldlYnhkY09yaW'
    'dpbkgFUgx3ZWJ4ZGNPcmlnaW6IAQESNgoLd2VieGRjX3N5bmMYCSABKAsyEC5XZWJ4ZGNTeW5j'
    'Q2h1bmtIBlIKd2VieGRjU3luY4gBARJHChN3ZWJ4ZGNfc3luY19yZXF1ZXN0GAogASgLMhIuV2'
    'VieGRjU3luY1JlcXVlc3RIB1IRd2VieGRjU3luY1JlcXVlc3SIAQEirAEKBFR5cGUSCAoETElO'
    'SxAAEgwKCENPTlRBQ1RTEAESGgoWUkVTVE9SRURfRkxBTUVfQ09VTlRFUhACEhIKDkFTS19BQk'
    '9VVF9VU0VSEAMSDgoKV0VCWERDX0FQUBAEEhEKDVdFQlhEQ19VUERBVEUQBRIPCgtXRUJYRENf'
    'U0VOVBAGEg8KC1dFQlhEQ19TWU5DEAcSFwoTV0VCWERDX1NZTkNfUkVRVUVTVBAIQgcKBV9saW'
    '5rQhkKF19yZXN0b3JlZF9mbGFtZV9jb3VudGVyQhQKEl9hc2tfYWJvdXRfdXNlcl9pZEINCgtf'
    'd2VieGRjX2FwcEIQCg5fd2VieGRjX3VwZGF0ZUIQCg5fd2VieGRjX29yaWdpbkIOCgxfd2VieG'
    'RjX3N5bmNCFgoUX3dlYnhkY19zeW5jX3JlcXVlc3Q=');

@$core.Deprecated('Use webxdcSyncChunkDescriptor instead')
const WebxdcSyncChunk$json = {
  '1': 'WebxdcSyncChunk',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {'1': 'chunk_index', '3': 2, '4': 1, '5': 13, '10': 'chunkIndex'},
    {'1': 'chunk_count', '3': 3, '4': 1, '5': 13, '10': 'chunkCount'},
    {'1': 'payload_sha256', '3': 4, '4': 1, '5': 12, '10': 'payloadSha256'},
    {'1': 'payload', '3': 5, '4': 1, '5': 12, '10': 'payload'},
  ],
};

/// Descriptor for `WebxdcSyncChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webxdcSyncChunkDescriptor = $convert.base64Decode(
    'Cg9XZWJ4ZGNTeW5jQ2h1bmsSHwoLdHJhbnNmZXJfaWQYASABKAlSCnRyYW5zZmVySWQSHwoLY2'
    'h1bmtfaW5kZXgYAiABKA1SCmNodW5rSW5kZXgSHwoLY2h1bmtfY291bnQYAyABKA1SCmNodW5r'
    'Q291bnQSJQoOcGF5bG9hZF9zaGEyNTYYBCABKAxSDXBheWxvYWRTaGEyNTYSGAoHcGF5bG9hZB'
    'gFIAEoDFIHcGF5bG9hZA==');

@$core.Deprecated('Use webxdcSyncRequestDescriptor instead')
const WebxdcSyncRequest$json = {
  '1': 'WebxdcSyncRequest',
};

/// Descriptor for `WebxdcSyncRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webxdcSyncRequestDescriptor =
    $convert.base64Decode('ChFXZWJ4ZGNTeW5jUmVxdWVzdA==');

@$core.Deprecated('Use webxdcSyncPayloadDescriptor instead')
const WebxdcSyncPayload$json = {
  '1': 'WebxdcSyncPayload',
  '2': [
    {
      '1': 'instances',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.WebxdcSyncInstance',
      '10': 'instances'
    },
  ],
};

/// Descriptor for `WebxdcSyncPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webxdcSyncPayloadDescriptor = $convert.base64Decode(
    'ChFXZWJ4ZGNTeW5jUGF5bG9hZBIxCglpbnN0YW5jZXMYASADKAsyEy5XZWJ4ZGNTeW5jSW5zdG'
    'FuY2VSCWluc3RhbmNlcw==');

@$core.Deprecated('Use webxdcSyncInstanceDescriptor instead')
const WebxdcSyncInstance$json = {
  '1': 'WebxdcSyncInstance',
  '2': [
    {'1': 'instance_id', '3': 1, '4': 1, '5': 9, '10': 'instanceId'},
    {'1': 'app_id', '3': 2, '4': 1, '5': 9, '10': 'appId'},
    {'1': 'version', '3': 3, '4': 1, '5': 3, '10': 'version'},
    {
      '1': 'summary',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'summary',
      '17': true
    },
    {
      '1': 'document',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'document',
      '17': true
    },
    {'1': 'created_at', '3': 6, '4': 1, '5': 3, '10': 'createdAt'},
    {'1': 'last_update_at', '3': 7, '4': 1, '5': 3, '10': 'lastUpdateAt'},
    {
      '1': 'updates',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.WebxdcSyncUpdate',
      '10': 'updates'
    },
  ],
  '8': [
    {'1': '_summary'},
    {'1': '_document'},
  ],
};

/// Descriptor for `WebxdcSyncInstance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webxdcSyncInstanceDescriptor = $convert.base64Decode(
    'ChJXZWJ4ZGNTeW5jSW5zdGFuY2USHwoLaW5zdGFuY2VfaWQYASABKAlSCmluc3RhbmNlSWQSFQ'
    'oGYXBwX2lkGAIgASgJUgVhcHBJZBIYCgd2ZXJzaW9uGAMgASgDUgd2ZXJzaW9uEh0KB3N1bW1h'
    'cnkYBCABKAlIAFIHc3VtbWFyeYgBARIfCghkb2N1bWVudBgFIAEoCUgBUghkb2N1bWVudIgBAR'
    'IdCgpjcmVhdGVkX2F0GAYgASgDUgljcmVhdGVkQXQSJAoObGFzdF91cGRhdGVfYXQYByABKANS'
    'DGxhc3RVcGRhdGVBdBIrCgd1cGRhdGVzGAggAygLMhEuV2VieGRjU3luY1VwZGF0ZVIHdXBkYX'
    'Rlc0IKCghfc3VtbWFyeUILCglfZG9jdW1lbnQ=');

@$core.Deprecated('Use webxdcSyncUpdateDescriptor instead')
const WebxdcSyncUpdate$json = {
  '1': 'WebxdcSyncUpdate',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {
      '1': 'sender_id',
      '3': 2,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'senderId',
      '17': true
    },
    {'1': 'payload', '3': 3, '4': 1, '5': 9, '10': 'payload'},
    {'1': 'info', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'info', '17': true},
    {'1': 'href', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'href', '17': true},
    {'1': 'received_at', '3': 6, '4': 1, '5': 3, '10': 'receivedAt'},
  ],
  '8': [
    {'1': '_sender_id'},
    {'1': '_info'},
    {'1': '_href'},
  ],
};

/// Descriptor for `WebxdcSyncUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webxdcSyncUpdateDescriptor = $convert.base64Decode(
    'ChBXZWJ4ZGNTeW5jVXBkYXRlEh0KCm1lc3NhZ2VfaWQYASABKAlSCW1lc3NhZ2VJZBIgCglzZW'
    '5kZXJfaWQYAiABKANIAFIIc2VuZGVySWSIAQESGAoHcGF5bG9hZBgDIAEoCVIHcGF5bG9hZBIX'
    'CgRpbmZvGAQgASgJSAFSBGluZm+IAQESFwoEaHJlZhgFIAEoCUgCUgRocmVmiAEBEh8KC3JlY2'
    'VpdmVkX2F0GAYgASgDUgpyZWNlaXZlZEF0QgwKCl9zZW5kZXJfaWRCBwoFX2luZm9CBwoFX2hy'
    'ZWY=');

@$core.Deprecated('Use webxdcOriginDescriptor instead')
const WebxdcOrigin$json = {
  '1': 'WebxdcOrigin',
  '2': [
    {'1': 'instance_id', '3': 1, '4': 1, '5': 9, '10': 'instanceId'},
    {'1': 'app_id', '3': 2, '4': 1, '5': 9, '10': 'appId'},
    {'1': 'version', '3': 3, '4': 1, '5': 3, '10': 'version'},
  ],
};

/// Descriptor for `WebxdcOrigin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webxdcOriginDescriptor = $convert.base64Decode(
    'CgxXZWJ4ZGNPcmlnaW4SHwoLaW5zdGFuY2VfaWQYASABKAlSCmluc3RhbmNlSWQSFQoGYXBwX2'
    'lkGAIgASgJUgVhcHBJZBIYCgd2ZXJzaW9uGAMgASgDUgd2ZXJzaW9u');

@$core.Deprecated('Use webxdcAppDescriptor instead')
const WebxdcApp$json = {
  '1': 'WebxdcApp',
  '2': [
    {'1': 'app_id', '3': 1, '4': 1, '5': 9, '10': 'appId'},
    {'1': 'version', '3': 2, '4': 1, '5': 3, '10': 'version'},
  ],
};

/// Descriptor for `WebxdcApp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webxdcAppDescriptor = $convert.base64Decode(
    'CglXZWJ4ZGNBcHASFQoGYXBwX2lkGAEgASgJUgVhcHBJZBIYCgd2ZXJzaW9uGAIgASgDUgd2ZX'
    'JzaW9u');

@$core.Deprecated('Use webxdcUpdateDescriptor instead')
const WebxdcUpdate$json = {
  '1': 'WebxdcUpdate',
  '2': [
    {'1': 'instance_id', '3': 1, '4': 1, '5': 9, '10': 'instanceId'},
    {'1': 'payload', '3': 2, '4': 1, '5': 9, '10': 'payload'},
    {'1': 'info', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'info', '17': true},
    {'1': 'href', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'href', '17': true},
    {
      '1': 'summary',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'summary',
      '17': true
    },
    {
      '1': 'document',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'document',
      '17': true
    },
    {'1': 'notify', '3': 7, '4': 1, '5': 9, '9': 4, '10': 'notify', '17': true},
  ],
  '8': [
    {'1': '_info'},
    {'1': '_href'},
    {'1': '_summary'},
    {'1': '_document'},
    {'1': '_notify'},
  ],
};

/// Descriptor for `WebxdcUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webxdcUpdateDescriptor = $convert.base64Decode(
    'CgxXZWJ4ZGNVcGRhdGUSHwoLaW5zdGFuY2VfaWQYASABKAlSCmluc3RhbmNlSWQSGAoHcGF5bG'
    '9hZBgCIAEoCVIHcGF5bG9hZBIXCgRpbmZvGAMgASgJSABSBGluZm+IAQESFwoEaHJlZhgEIAEo'
    'CUgBUgRocmVmiAEBEh0KB3N1bW1hcnkYBSABKAlIAlIHc3VtbWFyeYgBARIfCghkb2N1bWVudB'
    'gGIAEoCUgDUghkb2N1bWVudIgBARIbCgZub3RpZnkYByABKAlIBFIGbm90aWZ5iAEBQgcKBV9p'
    'bmZvQgcKBV9ocmVmQgoKCF9zdW1tYXJ5QgsKCV9kb2N1bWVudEIJCgdfbm90aWZ5');
