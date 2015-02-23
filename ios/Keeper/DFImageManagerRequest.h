//
//  DFImageManagerRequest.h
//  Strand
//
//  Created by Henry Bridge on 10/28/14.
//  Copyright (c) 2014 Duffy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFImageManagerRequest : NSObject <NSCopying>

typedef NS_ENUM(NSInteger, DFImageRequestDeliveryMode) {
  DFImageRequestOptionsDeliveryModeOpportunistic = 0, // client may get several callbacks, degraded followed by high-quality
  DFImageRequestOptionsDeliveryModeHighQualityFormat = 1, // client will get one result only and it will be the best quality available for the request
  DFImageRequestOptionsDeliveryModeFastFormat = 2 // client will get one result only and it may be degraded
};

typedef NS_ENUM(NSInteger, DFImageRequestContentMode) {
  DFImageRequestContentModeAspectFit = 0,
  DFImageRequestContentModeAspectFill = 1,
};

@property (readonly, nonatomic, retain) NSString *key;
@property (readonly, nonatomic) CGSize size;
@property (readonly, nonatomic) DFImageRequestContentMode contentMode;
@property (readonly, nonatomic) DFImageRequestDeliveryMode deliveryMode;


- (instancetype)initWithKey:(NSString *)key
                           size:(CGSize)size
                    contentMode:(DFImageRequestContentMode)contentMode
                   deliveryMode:(DFImageRequestDeliveryMode)deliveryMode;


- (instancetype)initWithKey:(NSString *)key
                  imageType:(DFImageType)imageType;

- (DFImageType)imageType;
- (BOOL)isDefaultThumbnail;
- (DFImageManagerRequest *)copyWithKey:(NSString *)key;
- (DFImageManagerRequest *)copyWithDeliveryMode:(DFImageRequestDeliveryMode)deliveryMode;
- (DFImageManagerRequest *)copyWithSize:(CGSize)size;

@end
