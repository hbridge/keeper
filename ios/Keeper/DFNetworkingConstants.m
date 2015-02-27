//
//  DFNetworkingConstants.m
//  Keeper
//
//  Created by Henry Bridge on 2/27/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFNetworkingConstants.h"

AWSRegionType const CognitoRegionType = AWSRegionUSEast1; // e.g. AWSRegionUSEast1
AWSRegionType const DefaultServiceRegionType = AWSRegionUSEast1; // e.g. AWSRegionUSEast1
NSString *const CognitoIdentityPoolId = @"us-east-1:d398535c-7f96-4480-ba71-7d8d4ec07c8a";
NSString *const S3BucketName = @"duffy-keeper";
NSString *const BackgroundSessionUploadIdentifier = @"com.duffyapp.keeper.s3BackgroundTransferObjC.uploadSession";
NSString *const BackgroundSessionDownloadIdentifier = @"com.duffyapp.keeper.s3BackgroundTransferObjC.downloadSession";