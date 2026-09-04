// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersAddDsuServerViewController.h"

#import <string>

#import "InputCommon/ControllerInterface/DualShockUDPClient/DualShockUDPClient.h"

#import "ControllersAddDsuServerViewControllerDelegate.h"
#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"

@interface ControllersAddDsuServerViewController () <UITextFieldDelegate>

@end

@implementation ControllersAddDsuServerViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.navigationItem.title = DOLCoreLocalizedString(@"Add New DSU Server");

  self.descriptionField.placeholder = DOLCoreLocalizedString(@"BetterJoy, DS4Windows, etc");
  self.addressField.text = CppToFoundationString(std::string(ciface::DualShockUDPClient::DEFAULT_SERVER_ADDRESS));
  self.portField.text = [NSString stringWithFormat:@"%d", ciface::DualShockUDPClient::DEFAULT_SERVER_PORT];
}

// Mirrors ServerStringValidator: the description and address fields are
// used as fields in a "description:address:port;" serialized entry, so
// ':' and ';' can never be allowed in them.
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
  if (textField != self.descriptionField && textField != self.addressField) {
    return true;
  }

  return [string rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":;"]].location == NSNotFound;
}

- (void)showInvalidInputAlert {
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Error")
                                                                   message:DOLCoreLocalizedString(@"Please enter a valid server address and port.")
                                                            preferredStyle:UIAlertControllerStyleAlert];

  [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];

  [self presentViewController:alert animated:true completion:nil];
}

- (IBAction)addPressed:(id)sender {
  NSString* description = [self.descriptionField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSString* address = [self.addressField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

  if (description.length == 0 || address.length == 0) {
    [self showInvalidInputAlert];
    return;
  }

  NSInteger port = [self.portField.text integerValue];
  if (port <= 0 || port > 0xFFFF) {
    [self showInvalidInputAlert];
    return;
  }

  [self.delegate addDsuServerViewController:self
                didAddServerWithDescription:description
                                     address:address
                                        port:(uint16_t)port];

  [self.navigationController popViewControllerAnimated:true];
}

@end
