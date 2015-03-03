//
//  NSDictionary+DFJSON.m
//  Duffy
//
//  Created by Henry Bridge on 3/25/14.
//  Copyright (c) 2014 Duffy Productions. All rights reserved.
//

#import "NSDictionary+DFJSON.h"
#import "DFJSONConvertible.h"
#import "NSArray+DFJSON.h"

@implementation NSDictionary (DFJSON)

- (NSString *)JSONString
{
    return [self JSONStringPrettyPrinted:NO];
}

- (NSString *)JSONStringPrettyPrinted:(BOOL)prettyPrinted
{
    
    if (![NSJSONSerialization isValidJSONObject:self]) {
        DDLogWarn(@"Warning: json invalid for dict, enumerating types and removing unsafe types.");
        [self enumerateObjectTypes:@""];
        return [[self dictionaryWithNonJSONRemoved] JSONString];
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:prettyPrinted ? NSJSONWritingPrettyPrinted : 0
                                                         error:&error];
    
    if (!jsonData) {
        DDLogError(@"NSDictionary+DFJSON error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}


- (void)enumerateObjectTypes:(NSString *)path
{
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        DDLogVerbose(@"key: %@.%@, class %@", path, key, [key class]);
        DDLogVerbose(@"value: %@, class %@", obj, [obj class]);
        
        if ([[obj class] isSubclassOfClass:[NSDictionary class]]) {
            NSString *newPath = [NSString stringWithFormat:@"%@.%@", path, (NSString *)key];
            [(NSDictionary*)obj enumerateObjectTypes:newPath];
        }
    }];
}

+ (BOOL)isJSONSafeKey:(id)key
{
    return [[key class] isSubclassOfClass:[NSString class]];
}

+ (BOOL)isJSONSafeValue:(id)value
{
    // NSString, NSNumber, NSArray, NSDictionary, or NSNull.
    return (
        [[value class] isSubclassOfClass:[NSString class]] ||
            [[value class] isSubclassOfClass:[NSNumber class]] ||
            [[value class] isSubclassOfClass:[NSArray class]] ||
            [[value class] isSubclassOfClass:[NSDictionary class]] ||
            [[value class] isSubclassOfClass:[NSNull class]] ||
            [[value class] conformsToProtocol:@protocol(DFJSONConvertible)]
    );
}

- (NSDictionary *)dictionaryWithNonJSONRemoved
{
    NSMutableDictionary *mutableCopy = [self mutableCopy];
    NSMutableArray *keysToRemove = [[NSMutableArray alloc] init];
    [mutableCopy enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![NSDictionary isJSONSafeKey:key] || ![NSDictionary isJSONSafeValue:obj]) {
            [keysToRemove addObject:key];
        }
      
      if ([[obj class] isSubclassOfClass:[NSArray class]]) {
        mutableCopy[key] = [(NSArray *)obj JSONSafeArray];
      } else if ([[obj class] isSubclassOfClass:[NSDictionary class]]) {
            mutableCopy[key] = [(NSDictionary*)obj dictionaryWithNonJSONRemoved];
        } else if ([[obj class] conformsToProtocol:@protocol(DFJSONConvertible)]) {
          NSDictionary *JSONDict = [obj JSONDictionary];
          mutableCopy[key] = JSONDict;
        }
    }];
    
    [mutableCopy removeObjectsForKeys:keysToRemove];
    
    return mutableCopy;
}


+ (NSDictionary *)dictionaryWithJSONString:(NSString *)jsonString
{
  if (jsonString == nil) return nil;
  
  NSError *error;
  NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                       options:0
                                                         error:&error];
  if (error) {
    DDLogWarn(@"Error converting:%@ to JSON object.", jsonString);
    return nil;
  }
  
  return dict;
}

@end
