// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MsgAlertManager.h"

#import <UIKit/UIKit.h>

#import "Common/MsgHandler.h"

#import "FoundationStringUtil.h"

@interface MsgAlertManager ()

// We need to declare this early so the static function below can see it.
- (bool)handleAlertWithCaption:(const char*)caption text:(const char*)text question:(bool)question style:(Common::MsgType)style;

@end

static bool MsgAlert(const char* caption, const char* text, bool question, Common::MsgType style) {
  return [[MsgAlertManager shared] handleAlertWithCaption:caption text:text question:question style:style];
}

@implementation MsgAlertManager

+ (MsgAlertManager*)shared {
  static MsgAlertManager* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (void)registerHandler {
  Common::RegisterMsgAlertHandler(MsgAlert);
}

- (bool)handleAlertWithCaption:(const char*)caption text:(const char*)text question:(bool)question style:(Common::MsgType)style {
  NSString* foundationCaption = CToFoundationString(caption);
  NSString* foundationText = CToFoundationString(text);
  
  // Log to console as a backup
  NSLog(@"MsgAlert - %@: %@ (question: %d)", foundationCaption, foundationText, question ? 1 : 0);

  NSCondition* condition = [[NSCondition alloc] init];
  
  __block bool confirmed = false;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    UIWindow* window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = [[UIViewController alloc] init];
    window.windowLevel = UIWindowLevelAlert;
    
    UIWindow* topWindow = [UIApplication sharedApplication].windows.lastObject;
    window.windowLevel = topWindow.windowLevel + 1;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:foundationCaption message:foundationText preferredStyle:UIAlertControllerStyleAlert];
    
    void (^finish)() = ^void() {
      [condition lock];
      [condition signal];
      [window setHidden:true];
      [condition unlock];
    };

    if (question) {
      [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction* action) {
        confirmed = false;

        finish();
      }]];

      [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
        confirmed = true;

        finish();
      }]];
    }
    else
    {
      [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction* action) {
        confirmed = true;
        
        finish();
      }]];
    }

    [window makeKeyAndVisible];

    [window.rootViewController presentViewController:alert animated:true completion:nil];
  });

  // Wait for a button press
  [condition lock];
  [condition wait];
  [condition unlock];

  return confirmed;
}

@end
