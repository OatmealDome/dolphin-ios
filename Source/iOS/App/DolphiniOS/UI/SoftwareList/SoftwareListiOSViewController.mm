// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "SoftwareListiOSViewController.h"

#import "ImportFileManager.h"

@implementation SoftwareListiOSViewController

- (IBAction)addButtonPressed:(id)sender {
  NSArray* types = @[
    @"me.oatmealdome.dolphinios.generic-software",
    @"me.oatmealdome.dolphinios.gamecube-software",
    @"me.oatmealdome.dolphinios.wii-software"
  ];
  
  UIDocumentPickerViewController* pickerController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeOpen];
  pickerController.delegate = self;
  pickerController.modalPresentationStyle = UIModalPresentationPageSheet;
  pickerController.allowsMultipleSelection = false;
  
  [self presentViewController:pickerController animated:true completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
  [[ImportFileManager shared] importFileAtUrl:urls[0]];
}

@end
