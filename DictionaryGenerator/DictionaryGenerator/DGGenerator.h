//
//  DGGenerator.h
//  DictionaryGenerator
//
//  Created by Hunter Lang on 5/28/16.
//  Copyright © 2016 zenelk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DGGenerator : NSObject

+ (int)generateDictionaryWithInputPath:(NSURL *)inputURL outputURL:(NSURL *)outputURL;

@end
