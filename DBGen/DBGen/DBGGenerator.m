//
//  DBGGenerator.m
//  DBGen
//
//  Created by Hunter Lang on 9/19/16.
//  Copyright © 2016 Zenel. All rights reserved.
//

#import "DBGGenerator.h"
#import "sqlite3.h"

@implementation DBGGenerator

+ (BOOL)generateDatabaseWithInputPath:(NSString *)inputPath
                  frequencySamplePath:(NSString *)frequencySamplePath
                           outputPath:(NSString *)outputPath {
    NSMutableDictionary<NSString *, NSNumber *> *frequencyDictionary = [self populateDictionary:inputPath];
    if (!frequencyDictionary) {
        return false;
    }
    NSLog(@"Dictionary populated");
    BOOL success = [self updateFrequenciesWithSample:frequencySamplePath onDictionary:frequencyDictionary];
    if (!success) {
        return false;
    }
    NSLog(@"Frequencies updated");
    sqlite3 *db = [self createDatabaseAtPath:outputPath];
    if (!db) {
        return false;
    }
    NSLog(@"DB created");
    success = [self insertFromDictionary:frequencyDictionary toDatabase:db];
    if (!success) {
        NSLog(@"Failed to insert the words into the dictionary!");
        sqlite3_close_v2(db);
        return false;
    }
    NSLog(@"Inserts completed");
    if (sqlite3_close_v2(db) != SQLITE_OK) {
        NSLog(@"Can't close DB!");
        success = false;
    }
    NSLog(@"Close complete, and done...");
    return success;
}

+ (NSMutableDictionary<NSString *, NSNumber *> *)populateDictionary:(NSString *)dictionaryPath {
    NSMutableDictionary<NSString *, NSNumber *> *result = [NSMutableDictionary new];
    NSError *error;
    NSString *inputString = [NSString stringWithContentsOfFile:dictionaryPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Could not open dictionary for reading: %@", error.localizedDescription);
        return nil;
    }
    for (NSString *line in [inputString componentsSeparatedByString:@"\n"]) {
        if ([line isEqualToString:@""]) {
            continue;
        }
        [result setObject:@(1) forKey:[[line lowercaseString]
                                       stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    }
    return result;
}

+ (BOOL)updateFrequenciesWithSample:(NSString *)frequencySamplePath onDictionary:(NSMutableDictionary<NSString *, NSNumber *> *)dictionary {
    static const size_t WORD_BUFFER_LENGTH = 46;
    NSError *error;
    NSString *inputString = [NSString stringWithContentsOfFile:frequencySamplePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Could not open sample for reading: %@", error.localizedDescription);
        return false;
    }

    const char *bytes = [inputString UTF8String];
    char word[WORD_BUFFER_LENGTH];
    memset(word, 0, WORD_BUFFER_LENGTH);
    int currentWordIndex = 0;
    
    for (int i = 0; i < [inputString length]; ++i) {
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
            if (dictionary[wordString]) {
                dictionary[wordString] = @([dictionary[wordString] intValue] + 1);
            }
            else {
//                NSLog(@"Word is not in dictionary: %@", wordString);
            }
            currentWordIndex = 0;
        }
        else {
            //            NSLog(@"Unrecognized character: %c", bytes[i]);
        }
    }
    if (currentWordIndex != 0) {
        memset(word + currentWordIndex, 0, WORD_BUFFER_LENGTH - currentWordIndex);
        NSString *wordString = [[NSString stringWithUTF8String:word] lowercaseString];
        if (dictionary[wordString]) {
            dictionary[wordString] = @([dictionary[wordString] intValue] + 1);
        }
        else {
            NSLog(@"Word is not in dictionary: %@", wordString);
        }
    }
    return true;
}

+ (sqlite3 *)createDatabaseAtPath:(NSString *)path {
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error) {
            NSLog(@"Error deleting file at path for db: %@", error.localizedDescription);
            return NULL;
        }
    }
    sqlite3 *db;
    if (sqlite3_open([path UTF8String], &db) != SQLITE_OK) {
        NSLog(@"Couldn't open a database at the path");
        return NULL;
    }
    const char *createWords = "CREATE TABLE Words (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT, t9 TEXT, frequency INTEGER)";
    char *errorMessage;
    if (sqlite3_exec(db, createWords, NULL, NULL, &errorMessage) != SQLITE_OK) {
        NSLog(@"Failed to create table: %s", errorMessage);
        if (sqlite3_close_v2(db) != SQLITE_OK) {
            NSLog(@"Can't close DB!");
        }
        return NULL;
    }
    return db;
}

+ (BOOL)insertFromDictionary:(NSMutableDictionary<NSString *, NSNumber *> *)dictionary toDatabase:(sqlite3 *)db {
    static const char *INSERT_FORMAT = "INSERT INTO Words (id, word, t9, frequency) VALUES (NULL, ?, ?, ?)";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(db, INSERT_FORMAT, (int)strlen(INSERT_FORMAT), &statement, NULL) != SQLITE_OK) {
        NSLog(@"Could not prepare statement");
        return false;
    }
    NSUInteger total = [dictionary count];
    NSUInteger i = 0;
    for (NSString *key in dictionary.allKeys) {
        if ((++i % 1000) == 0) {
            NSLog(@"Insert progress: %d of %d", (int)i, (int)total);
        }
        NSString *t9Rep = [self generateT9Rep:key];
        sqlite3_bind_text(statement, 1, [key UTF8String], -1, NULL);
        sqlite3_bind_text(statement, 2, [t9Rep UTF8String], -1, NULL);
        sqlite3_bind_int(statement, 3, [dictionary[key] intValue]);
        if (sqlite3_step(statement) != SQLITE_DONE) {
            NSLog(@"Could not execute statement!");
            sqlite3_finalize(statement);
            return false;
        }
        sqlite3_reset(statement);
    }
    sqlite3_finalize(statement);
    return true;
}

+ (NSString *)generateT9Rep:(NSString *)word {
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

@end
