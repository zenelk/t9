//
//  DBGGenerator.h
//  DBGen
//
//  Created by Hunter Lang on 9/19/16.
//  Copyright © 2016 Zenel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBGGenerator : NSObject

+ (BOOL)generateDatabaseWithInputPath:(NSString *)inputPath
                  frequencySamplePath:(NSString *)frequencySamplePath
                           outputPath:(NSString *)outputPath;

@end
