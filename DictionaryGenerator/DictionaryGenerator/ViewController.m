//
//  ViewController.m
//  DictionaryGenerator
//
//  Created by Hunter Lang on 5/28/16.
//  Copyright © 2016 zenelk. All rights reserved.
//

#import "ViewController.h"
#import "DGGenerator.h"

@interface ViewController ()

@property (weak) IBOutlet NSTextField *inputPathTextField;
@property (weak) IBOutlet NSTextField *outputPathTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
    _inputPathTextField.stringValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"inputPath"];
    _outputPathTextField.stringValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"outputPath"];
}

- (IBAction)pickInputPath:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    
    NSInteger result = [panel runModal];
    
    if (result == NSFileHandlingPanelOKButton) {
        _inputPathTextField.stringValue = [[panel URLs][0] absoluteString];
        [[NSUserDefaults standardUserDefaults] setObject:_inputPathTextField.stringValue forKey:@"inputPath"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (IBAction)pickOutputPath:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO];
    
    NSInteger result = [panel runModal];
    
    if (result == NSFileHandlingPanelOKButton) {
        _outputPathTextField.stringValue = [[panel URLs][0] absoluteString];
        [[NSUserDefaults standardUserDefaults] setObject:_outputPathTextField.stringValue forKey:@"outputPath"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (IBAction)onGenerateDictionaryClicked:(id)sender {
    NSURL *inputURL = [NSURL URLWithString:_inputPathTextField.stringValue];
    NSURL *outputURL = [NSURL URLWithString:_outputPathTextField.stringValue];
    if (inputURL && outputURL) {
        [DGGenerator generateDictionaryWithInputPath:inputURL outputURL:outputURL];
    }
}

@end
