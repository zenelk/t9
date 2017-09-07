//
//  ViewController.m
//  DBGen
//
//  Created by Hunter Lang on 9/19/16.
//  Copyright © 2016 Zenel. All rights reserved.
//

#import "ViewController.h"
#import "DBGGenerator.h"

@interface ViewController ()

@property (nonatomic, strong) IBOutlet NSTextField *textFieldDictionary;
@property (nonatomic, strong) IBOutlet NSTextField *textFieldOutputFile;
@property (nonatomic, strong) IBOutlet NSTextField *textFieldFreqSample;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *textFieldDictionaryValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastDictionaryPath"];
    if (textFieldDictionaryValue) {
        self.textFieldDictionary.stringValue = textFieldDictionaryValue;
    }
    NSString *textFieldOutputFileValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastOutputFilePath"];
    if (textFieldOutputFileValue) {
        self.textFieldOutputFile.stringValue = textFieldOutputFileValue;
    }
    NSString *textFieldFreqSampleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastFreqSamplePath"];
    if (textFieldFreqSampleValue) {
        self.textFieldFreqSample.stringValue = textFieldFreqSampleValue;
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (IBAction)onDictionaryPickClicked:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    
    NSInteger result = [panel runModal];
    
    if (result == NSFileHandlingPanelOKButton) {
        self.textFieldDictionary.stringValue = [[panel URLs][0] path];
        [[NSUserDefaults standardUserDefaults] setObject:self.textFieldDictionary.stringValue forKey:@"lastDictionaryPath"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (IBAction)onFrequencySamplePickClicked:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    
    NSInteger result = [panel runModal];
    
    if (result == NSFileHandlingPanelOKButton) {
        self.textFieldFreqSample.stringValue = [[panel URLs][0] path];
        [[NSUserDefaults standardUserDefaults] setObject:self.textFieldFreqSample.stringValue forKey:@"lastFreqSamplePath"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (IBAction)onOutputFilePickClicked:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    NSInteger result = [panel runModal];
    
    if (result == NSFileHandlingPanelOKButton) {
        self.textFieldOutputFile.stringValue = [[panel URL] path];
        [[NSUserDefaults standardUserDefaults] setObject:self.textFieldOutputFile.stringValue forKey:@"lastOutputFilePath"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (IBAction)onGoClicked:(id)sender {
    [DBGGenerator generateDatabaseWithInputPath:self.textFieldDictionary.stringValue
                            frequencySamplePath:self.textFieldFreqSample.stringValue
                                     outputPath:self.textFieldOutputFile.stringValue];
}

@end
