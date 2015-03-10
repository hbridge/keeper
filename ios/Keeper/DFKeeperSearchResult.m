//
//  DFKeeperSearchResult.m
//  Keeper
//
//  Created by Henry Bridge on 3/9/15.
//  Copyright (c) 2015 Duffy Inc. All rights reserved.
//

#import "DFKeeperSearchResult.h"

@implementation DFKeeperSearchResult

const NSUInteger MaxFirstTokenLocation = 15;

- (NSAttributedString *)attributedSnippetForSearch:(NSString *)searchString baseFont:(UIFont *)baseFont
{
  NSMutableString *trimmedString = [[NSMutableString alloc] initWithString:self.documentString];
  
  // trim string
  static NSRegularExpression *newLineRegex = nil;
  if (!newLineRegex) {
    NSError *error;
    newLineRegex = [NSRegularExpression regularExpressionWithPattern:@"\\s*[\\n\\t]+\\s*" options:0 error:&error];
    if (error) {
      [NSException raise:@"Bad regex" format:@"Error: %@", error];
    }
  }
  
  NSArray *newlineMatches = [newLineRegex matchesInString:self.documentString options:0 range:[self.documentString fullRange]];
  for (NSTextCheckingResult *result in newlineMatches.reverseObjectEnumerator) {
    [trimmedString replaceCharactersInRange:result.range withString:@" "];
  }
  
  
  // highlight search string
  NSString *baseFontName = [[baseFont.fontName componentsSeparatedByString:@"-"] firstObject];
  UIFont *highlightFont = [UIFont fontWithName:[NSString stringWithFormat:@"%@-Bold", baseFontName]
                                          size:baseFont.pointSize];
  NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:trimmedString];

  NSRange firstTokenFound = (NSRange){NSIntegerMax, 0};
  NSArray *tokens = [searchString componentsSeparatedByString:@" "];
  for (NSString *token in tokens) {
    NSString *searchStringRegexPattern = [NSString stringWithFormat:@"(^%@)|([\\s^]+%@)", token, token];
    NSError *error;
    NSRegularExpression *searchStringRegex = [NSRegularExpression
                                              regularExpressionWithPattern:searchStringRegexPattern
                                              options:NSRegularExpressionCaseInsensitive
                                              error:&error];
    NSArray *matches = [searchStringRegex matchesInString:trimmedString
                                                  options:0 range:[trimmedString fullRange]];
    DDLogVerbose(@"%@ matches for %@", @(matches.count), searchStringRegexPattern);
    for (NSTextCheckingResult *match in matches) {
      if (match.range.location < firstTokenFound.location) firstTokenFound = match.range;
      [result setAttributes:@{
                              NSFontAttributeName : highlightFont,
                              }
                      range:match.range];
    }
    if (error) DDLogError(@"%@ regex error: %@", self.class, error);
  }
  
  // truncate beginning if first token is far in
  if (firstTokenFound.location < NSIntegerMax && firstTokenFound.location > MaxFirstTokenLocation) {
    [result replaceCharactersInRange:(NSRange){0, firstTokenFound.location} withString:@"..."];
  }
  
  return result;
}

@end
