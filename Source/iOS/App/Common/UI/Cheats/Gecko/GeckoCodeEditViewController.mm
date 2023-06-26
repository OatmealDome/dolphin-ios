// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GeckoCodeEditViewController.h"

#import "Common/Event.h"
#import "Common/StringUtil.h"

#import "Core/GeckoCode.h"
#import "Core/GeckoCodeConfig.h"

#import "FoundationStringUtil.h"
#import "GeckoCodeEditViewControllerDelegate.h"
#import "LocalizationUtil.h"

@interface GeckoCodeEditViewController () <UITextViewDelegate>

@end

@implementation GeckoCodeEditViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.nameField.text = CppToFoundationString(self.code->name);
  self.creatorField.text = CppToFoundationString(self.code->creator);
  
  NSMutableArray<NSString*>* codeLinesArray = [[NSMutableArray alloc] init];
  for (const auto& c : self.code->codes) {
    [codeLinesArray addObject:CppToFoundationString(c.original_line)];
  }
  
  self.codeView.text = [codeLinesArray componentsJoinedByString:@"\n"];
  
  NSMutableArray<NSString*>* notesLinesArray = [[NSMutableArray alloc] init];
  for (const auto& note : self.code->notes) {
    [notesLinesArray addObject:CppToFoundationString(note)];
  }
  
  self.notesView.text = [notesLinesArray componentsJoinedByString:@"\n"];
}

- (void)disableViews {
  self.nameField.enabled = false;
  self.creatorField.enabled = false;
  self.codeView.userInteractionEnabled = false;
  self.notesView.userInteractionEnabled = false;
}

- (void)enableViews {
  self.nameField.enabled = true;
  self.creatorField.enabled = true;
  self.codeView.userInteractionEnabled = true;
  self.notesView.userInteractionEnabled = true;
}

- (void)textViewDidChange:(UITextView*)textView {
  [self.tableView beginUpdates];
  [self.tableView endUpdates];
}

- (IBAction)savePressed:(id)sender {
  [self disableViews];
  
  __block std::string name = FoundationToCppString(self.nameField.text);
  std::string creator = FoundationToCppString(self.creatorField.text);
  std::vector<std::string> notes = SplitString(FoundationToCppString(self.notesView.text), '\n');
  
  NSArray<NSString*>* codeLines = [self.codeView.text componentsSeparatedByString:@"\n"];
  
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    std::vector<Gecko::GeckoCode::Code> entries;
    
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
      
      if (std::optional<Gecko::GeckoCode::Code> c = Gecko::DeserializeLine(FoundationToCppString(line)))
      {
        entries.push_back(*c);
      }
      else
      {
        __block bool continueParsing;
        
        Common::Event wait_event;
        Common::Event* wait_event_ptr = &wait_event;
        
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString* alertTextFormat = DOLCoreLocalizedStringWithArgs(@"Unable to parse line %1 of the entered Gecko code as a valid "
                                                                     "code. Make sure you typed it correctly.\n\n"
                                                                     "Would you like to ignore this line and continue parsing?", @"d");
          NSString* alertText = [NSString stringWithFormat:alertTextFormat, i + 1];
          
          UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Parsing Error") message:alertText preferredStyle:UIAlertControllerStyleAlert];
          
          [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Abort") style:UIAlertActionStyleCancel handler:^(UIAlertAction*) {
            continueParsing = false;
            
            wait_event_ptr->Set();
          }]];
          
          [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
            continueParsing = true;
            
            wait_event_ptr->Set();
          }]];
          
          [self presentViewController:errorAlert animated:true completion:nil];
        });
        
        wait_event.Wait();
        
        if (!continueParsing) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self enableViews];
          });
          
          return;
        }
      }
    }
    
    if (entries.empty()) {
      dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* emptyAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Error") message:DOLCoreLocalizedString(@"This Gecko code doesn't contain any lines.") preferredStyle:UIAlertControllerStyleAlert];
        
        [emptyAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
          [self enableViews];
        }]];
        
        [self presentViewController:emptyAlert animated:true completion:nil];
      });
      
      return;
    }
    
    self.code->name = name;
    self.code->creator = creator;
    self.code->codes = std::move(entries);
    self.code->notes = std::move(notes);
    self.code->user_defined = true;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate userDidSaveCode:self];
      
      [self.navigationController popViewControllerAnimated:true];
    });
  });
}

@end
