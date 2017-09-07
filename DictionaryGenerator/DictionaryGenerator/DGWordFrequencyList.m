//
//  DGWordFrequencyList.m
//  DictionaryGenerator
//
//  Created by Hunter Lang on 5/28/16.
//  Copyright © 2016 zenelk. All rights reserved.
//

#import "DGWordFrequencyList.h"

@interface DGWordFrequencyList ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *wordFrequencies;

@end

@implementation DGWordFrequencyList

- (instancetype)init {
    if (self = [super init]) {
        _wordFrequencies = [NSMutableDictionary new];
    }
    return self;
}

- (void)addWord:(NSString *)word {
    word = [word lowercaseString];
    if (!_wordFrequencies[word]) {
        _wordFrequencies[word] = 0;
    }
    _wordFrequencies[word] = @([_wordFrequencies[word] unsignedIntegerValue] + 1);
}

- (NSDictionary<NSString *, NSNumber *> *)getWordFrequencies {
    return [_wordFrequencies copy];
}

@end
