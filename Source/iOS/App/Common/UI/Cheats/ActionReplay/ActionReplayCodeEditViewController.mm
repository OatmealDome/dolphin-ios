// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ActionReplayCodeEditViewController.h"

#import "Common/Event.h"

#import "Core/ARDecrypt.h"
#import "Core/ActionReplay.h"

#import "ActionReplayCodeEditViewControllerDelegate.h"
#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"

typedef NS_ENUM(NSInteger, DOLActionReplayCodeMixedResult) {
  DOLActionReplayCodeMixedResultOK,
  DOLActionReplayCodeMixedResultCancel,
  DOLActionReplayCodeMixedResultAbort
};

@interface ActionReplayCodeEditViewController () <UITextViewDelegate>

@end

@implementation ActionReplayCodeEditViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.nameField.text = CppToFoundationString(self.code->name);
  
  NSMutableArray<NSString*>* codeLinesArray = [[NSMutableArray alloc] init];
  for (const auto& e : self.code->ops) {
    [codeLinesArray addObject:CppToFoundationString(ActionReplay::SerializeLine(e))];
  }
  
  self.codeView.text = [codeLinesArray componentsJoinedByString:@"\n"];
}

- (void)disableViews {
  self.nameField.enabled = false;
  self.codeView.userInteractionEnabled = false;
}

- (void)enableViews {
  self.nameField.enabled = true;
  self.codeView.userInteractionEnabled = true;
}

- (void)textViewDidChange:(UITextView*)textView {
  [self.tableView beginUpdates];
  [self.tableView endUpdates];
}

- (IBAction)savePressed:(id)sender {
  [self disableViews];
  
  __block std::string name = FoundationToCppString(self.nameField.text);
  
  NSArray<NSString*>* codeLines = [self.codeView.text componentsSeparatedByString:@"\n"];
  
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    std::vector<ActionReplay::AREntry> entries;
    std::vector<std::string> encryptedLines;
    
    for (size_t i = 0; i < [codeLines count]; i++) {
      NSString* line = [codeLines objectAtIndex:i];
      
      if ([line length] == 0) {
        continue;
      }
      
      if (i == 0 && [line characterAtIndex:0] == u'$') {
        if (name.empty()) {
          name = FoundationToCppString([line substringFromIndex:1]);
        }
        
        continue;
      }
      
      const auto parseResult = ActionReplay::DeserializeLine(FoundationToCppString(line));
      
      if (std::holds_alternative<ActionReplay::AREntry>(parseResult))
      {
        entries.push_back(std::get<ActionReplay::AREntry>(parseResult));
      }
      else if (std::holds_alternative<ActionReplay::EncryptedLine>(parseResult))
      {
        encryptedLines.emplace_back(std::get<ActionReplay::EncryptedLine>(parseResult));
      }
      else
      {
        __block bool continueParsing;
        
        Common::Event waitEvent;
        Common::Event* waitEventPtr = &waitEvent;
        
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString* alertTextFormat = DOLCoreLocalizedStringWithArgs(@"Unable to parse line %1 of the entered AR code as a valid "
                                                                     "encrypted or decrypted code. Make sure you typed it correctly.\n\n"
                                                                     "Would you like to ignore this line and continue parsing?", @"d");
          NSString* alertText = [NSString stringWithFormat:alertTextFormat, i + 1];
          
          UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Parsing Error") message:alertText preferredStyle:UIAlertControllerStyleAlert];
          
          [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Abort") style:UIAlertActionStyleCancel handler:^(UIAlertAction*) {
            continueParsing = false;
            
            waitEventPtr->Set();
          }]];
          
          [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
            continueParsing = true;
            
            waitEventPtr->Set();
          }]];
          
          [self presentViewController:errorAlert animated:true completion:nil];
        });
        
        waitEvent.Wait();
        
        if (!continueParsing) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self enableViews];
          });
          
          return;
        }
      }
    }
    
    if (!encryptedLines.empty()) {
      if (!entries.empty()) {
        __block DOLActionReplayCodeMixedResult mixedResult;
        
        Common::Event waitEvent;
        Common::Event* waitEventPtr = &waitEvent;
        
        dispatch_async(dispatch_get_main_queue(), ^{
          UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Parsing Error")
                                                                              message:DOLCoreLocalizedString(@"This Action Replay code contains both encrypted and unencrypted lines; "
                                                                                                             "you should check that you have entered it correctly.\n\n"
                                                                                                             "Do you want to discard all unencrypted lines?")
                                                                       preferredStyle:UIAlertControllerStyleAlert];
          
          [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
            mixedResult = DOLActionReplayCodeMixedResultOK;
            
            waitEventPtr->Set();
          }]];
          
          [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
            mixedResult = DOLActionReplayCodeMixedResultCancel;
            
            waitEventPtr->Set();
          }]];
          
          [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Abort") style:UIAlertActionStyleCancel handler:^(UIAlertAction*) {
            mixedResult = DOLActionReplayCodeMixedResultAbort;
            
            waitEventPtr->Set();
          }]];
          
          [self presentViewController:errorAlert animated:true completion:nil];
        });
        
        waitEvent.Wait();
        
        if (mixedResult == DOLActionReplayCodeMixedResultOK) {
          entries.clear();
        } else if (mixedResult == DOLActionReplayCodeMixedResultCancel) {
          encryptedLines.clear();
        } else if (mixedResult == DOLActionReplayCodeMixedResultAbort) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self enableViews];
          });
          
          return;
        }
      }
      
      ActionReplay::DecryptARCode(encryptedLines, &entries);
    }
    
    if (entries.empty()) {
      dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* emptyAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Error") message:DOLCoreLocalizedString(@"The resulting decrypted AR code doesn't contain any lines.") preferredStyle:UIAlertControllerStyleAlert];
        
        [emptyAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
          [self enableViews];
        }]];
        
        [self presentViewController:emptyAlert animated:true completion:nil];
      });
      
      return;
    }
    
    self.code->name = name;
    self.code->ops = std::move(entries);
    self.code->user_defined = true;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate userDidSaveCode:self];
      
      [self.navigationController popViewControllerAnimated:true];
    });
  });
}

@end
