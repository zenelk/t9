//
//  DGWordFrequencyList.h
//  DictionaryGenerator
//
//  Created by Hunter Lang on 5/28/16.
//  Copyright © 2016 zenelk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DGWordFrequencyList : NSObject

- (void)addWord:(NSString *)word;
- (NSDictionary<NSString *, NSNumber *> *)getWordFrequencies;

@end