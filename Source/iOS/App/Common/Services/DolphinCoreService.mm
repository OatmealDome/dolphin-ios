// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DolphinCoreService.h"

#import "Core/Config/UISettings.h"

#import "Common/MsgHandler.h"

#import "UICommon/UICommon.h"

#import "DolphiniOS-Swift.h"
#import "FoundationStringUtil.h"

@implementation DolphinCoreService

static bool MsgAlert(const char* caption, const char* text, bool question, Common::MsgType style)
{
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
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:foundationCaption message:foundationText preferredStyle:UIAlertControllerStyleAlert];
    
    void (^finish)() = ^void() {
      [condition signal];
      [window setHidden:true];
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

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  UICommon::SetUserDirectory(FoundationToCppString([UserFolderUtil getUserFolder]));
  UICommon::CreateDirectories();
  UICommon::Init();
  
  Config::SetBase(Config::MAIN_USE_GAME_COVERS, true);
  
  return YES;
}

@end
