// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsTabViewController.h"

#import "LocalizationUtil.h"

@interface GraphicsTabViewController ()

@end

@implementation GraphicsTabViewController

// Utility methods to show help alerts (tooltips in DolphinQt) for graphics settings.

- (void)showHelpWithLocalizable:(NSString*)localizable {
  if (localizable == nil) {
    return;
  }
  
  [self showHelpWithMessage:DOLCoreLocalizedString(localizable)];
}

- (void)showHelpWithMessage:(NSString*)message {
  if (message == nil) {
    return;
  }
  
  message = [message stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
  message = [message stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
  message = [message stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
  
  // Wish there was an easy way to unescape these HTML entities.
  message = [message stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
  message = [message stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
  
  // TODO: Is there a way to make <dolphin_emphasis> parts of the string bold in the UIAlertController without private API usage?
  message = [message stringByReplacingOccurrencesOfString:@"<dolphin_emphasis>" withString:@""];
  message = [message stringByReplacingOccurrencesOfString:@"</dolphin_emphasis>" withString:@""];
  
  UIAlertController* controller = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Help") message:message preferredStyle:UIAlertControllerStyleAlert];
  [controller addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
  
  [self presentViewController:controller animated:true completion:nil];
}

@end
