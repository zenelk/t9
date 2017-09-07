//
//  DGGenerator.m
//  DictionaryGenerator
//
//  Created by Hunter Lang on 5/28/16.
//  Copyright © 2016 zenelk. All rights reserved.
//

#import "DGGenerator.h"
#import "DGWordFrequencyList.h"

typedef NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> wordRep_t;

@implementation DGGenerator

+ (int)generateDictionaryWithInputPath:(NSURL *)inputURL outputURL:(NSURL *)outputURL {
    NSError *error;
    NSString *inputString = [NSString stringWithContentsOfURL:inputURL encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Problem reading input file: %@", error.description);
        return 1;
    }
    
    wordRep_t *words = [self chunkIntoWords:inputString];

    NSData *table = [self generateTable:words];
    NSURL *outputURLFile = [outputURL URLByAppendingPathComponent:@"generated_table.txt"];
    BOOL success = [table writeToURL:outputURLFile atomically:YES];
    if (!success) {
        NSLog(@"Problem writing output file!");
        return 2;
    }
    return 0;
}

+ (wordRep_t *)chunkIntoWords:(NSString *)inputString {
    static const size_t WORD_BUFFER_LENGTH = 46;
    const char *bytes = [inputString UTF8String];
    char word[WORD_BUFFER_LENGTH];
    memset(word, 0, WORD_BUFFER_LENGTH);
    int currentWordIndex = 0;
    
    wordRep_t *wordRep = [wordRep_t new];
    for (size_t i = 0; i < [inputString length]; ++i) {
        if ((bytes[i] >= 'A' && bytes[i] <= 'Z')
            || (bytes[i] >= 'a' && bytes[i] <= 'z')
            || bytes[i] == '\''
            || bytes[i] == '-') {
            if (currentWordIndex >= WORD_BUFFER_LENGTH) {
                NSLog(@"Word %s is too long! Ignoring it...", word);
                currentWordIndex = 0;
                ++i;
                while (bytes[i] != ' ' && bytes[i] != '\n') {
                    ++i;
                }
                continue;
            }
            word[currentWordIndex++] = bytes[i];
        }
        else if (bytes[i] == ' ' || bytes[i] == '\n') {
            memset(word + currentWordIndex, 0, WORD_BUFFER_LENGTH - currentWordIndex);
            NSString *wordString = [[NSString stringWithUTF8String:word] lowercaseString];
            NSString *t9Rep = [self getT9RepresentationOfWord:wordString];
            NSMutableArray<NSString *> *wordsForRep = wordRep[t9Rep];
            if (!wordsForRep) {
                wordsForRep = [NSMutableArray new];
                wordRep[t9Rep] = wordsForRep;
            }
            if (![wordsForRep containsObject:wordString]) {
                [wordsForRep addObject:wordString];
            }
            currentWordIndex = 0;
        }
        else {
//            NSLog(@"Unrecognized character: %c", bytes[i]);
        }
    }
    if (currentWordIndex != 0) {
        memset(word + currentWordIndex, 0, WORD_BUFFER_LENGTH - currentWordIndex);
        NSString *wordString = [NSString stringWithUTF8String:word];
        NSString *t9Rep = [self getT9RepresentationOfWord:wordString];
        NSMutableArray<NSString *> *wordsForRep = wordRep[t9Rep];
        if (!wordsForRep) {
            wordsForRep = [NSMutableArray new];
            wordRep[t9Rep] = wordsForRep;
        }
        if (![wordsForRep containsObject:wordString]) {
            [wordsForRep addObject:wordString];
        }

    }
    return wordRep;
}

+ (NSString *)getT9RepresentationOfWord:(NSString *)word {
    NSString *lower = [word lowercaseString];
    NSUInteger len = [lower length];
    unichar buffer[len];
    [lower getCharacters:buffer range:NSMakeRange(0, len)];
    char translated[len + 1];
    for(int i = 0; i < len; ++i) {
        switch (buffer[i]) {
            case 'a':
            case 'b':
            case 'c':
                translated[i] = '2';
                break;
            case 'd':
            case 'e':
            case 'f':
                translated[i] = '3';
                break;
            case 'g':
            case 'h':
            case 'i':
                translated[i] = '4';
                break;
            case 'j':
            case 'k':
            case 'l':
                translated[i] = '5';
                break;
            case 'm':
            case 'n':
            case 'o':
                translated[i] = '6';
                break;
            case 'p':
            case 'q':
            case 'r':
            case 's':
                translated[i] = '7';
                break;
            case 't':
            case 'u':
            case 'v':
                translated[i] = '8';
                break;
            case 'w':
            case 'x':
            case 'y':
            case 'z':
                translated[i] = '9';
                break;
            case '\'':
            case '-':
                translated[i] = '1';
                break;
            default:
                break;
        }
    }
    translated[len] = '\0';
    return [NSString stringWithUTF8String:translated];
}

+ (NSData *)generateTable:(wordRep_t *)words {
    static const char repSeparator = ':';
    static const char wordSeparator = ',';
    static const char lineSeparator = '\n';
    
    NSMutableData *data = [NSMutableData data];
    for (NSString *t9Rep in words.allKeys) {
        [data appendData:[t9Rep dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendBytes:&repSeparator length:1];
        NSArray<NSString *> *wordsForRep = words[t9Rep];
        int consumedWords = 0;
        for (NSString *word in wordsForRep) {
            [data appendData:[word dataUsingEncoding:NSUTF8StringEncoding]];
            if (++consumedWords != [wordsForRep count]) {
                [data appendBytes:&wordSeparator length:1];
            }
        }
        [data appendBytes:&lineSeparator length:1];
    }
    return [data copy];
}

//
//+ (NSString *)generateTable:(NSDictionary<NSString *, DGWordFrequencyList *> *)wordFrequencyMap {
//    NSMutableString *stringBuilder = [NSMutableString new];
//    for (NSString *t9Rep in wordFrequencyMap.allKeys) {
//        DGWordFrequencyList *list = wordFrequencyMap[t9Rep];
//        NSDictionary<NSString *, NSNumber *> *frequencies = [list getWordFrequencies];
//        NSMutableString *innerStringBuilder = [NSMutableString new];
//        for (NSString *word in frequencies) {
//            [innerStringBuilder appendFormat:@"%@=%lu;", word, [frequencies[word] unsignedLongValue]];
//        }
//        [stringBuilder appendFormat:@"%@:%@\n", t9Rep, innerStringBuilder];
//    }
//    return stringBuilder;
//}

@end
