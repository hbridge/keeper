//
//  NSDictionary+DFJSON.h
//  Duffy
//
//  Created by Henry Bridge on 3/25/14.
//  Copyright (c) 2014 Duffy Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (DFJSON)

- (NSString *)JSONString;
- (NSString *)JSONStringPrettyPrinted:(BOOL)prettyPrinted;
- (NSDictionary *)dictionaryWithNonJSONRemoved;

+ (NSDictionary *)dictionaryWithJSONString:(NSString *)jsonString;


+ (BOOL)isJSONSafeKey:(id)key;
+ (BOOL)isJSONSafeValue:(id)value;


@end
