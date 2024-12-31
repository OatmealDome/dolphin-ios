// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "SoftwareListiOSViewController.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "Common/CommonPaths.h"
#import "Common/FileUtil.h"

#import "Core/CommonTitles.h"
#import "Core/Config/MainSettings.h"
#import "Core/IOS/ES/ES.h"
#import "Core/IOS/IOS.h"

#import "DiscIO/NANDImporter.h"

#import "UICommon/GameFile.h"

#import "EmulationBootParameter.h"
#import "FoundationStringUtil.h"
#import "GameFilePtrWrapper.h"
#import "ImportFileManager.h"
#import "LocalizationUtil.h"

typedef NS_ENUM(NSInteger, DOLSoftwareListDocumentPickerType) {
  DOLSoftwareListDocumentPickerTypeImportSoftware,
  DOLSoftwareListDocumentPickerTypeImportNAND,
  DOLSoftwareListDocumentPickerTypeOpenExternal,
};

@implementation SoftwareListiOSViewController {
  DOLSoftwareListDocumentPickerType _pickerType;
  NSURL* _openedUrl;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveImportFileFinishedNotification) name:DOLImportFileFinishedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:DOLImportFileFinishedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if (_openedUrl != nil) {
    [_openedUrl stopAccessingSecurityScopedResource];
    _openedUrl = nil;
  }
  
  NSArray<UIMenuElement*>* wiiActions;
  
  UIMenuElement* wiiNandElement = [UIMenu menuWithTitle:DOLCoreLocalizedString(@"Manage NAND") children:@[
    [UIAction actionWithTitle:DOLCoreLocalizedString(@"Import BootMii NAND Backup...") image:[UIImage systemImageNamed:@"internaldrive"] identifier:nil handler:^(UIAction*) {
      [self openDocumentPickerWithContentTypes:@[
        [UTType typeWithFilenameExtension:@"bin"]
      ] pickerType:DOLSoftwareListDocumentPickerTypeImportNAND];
    }]
  ]];
  
  // Get the system menu TMD
  IOS::HLE::Kernel ios;
  const auto tmd = ios.GetESCore().FindInstalledTMD(Titles::SYSTEM_MENU);
  
  if (tmd.IsValid()) {
    NSString* loadFormat;
    
    if (tmd.IsvWii()) {
      loadFormat = DOLCoreLocalizedStringWithArgs(@"Load vWii System Menu %1", @"@");
    } else {
      loadFormat = DOLCoreLocalizedStringWithArgs(@"Load Wii System Menu %1", @"@");
    }
    
    std::string version = DiscIO::GetSysMenuVersionString(tmd.GetTitleVersion(), tmd.IsvWii());
    
    wiiActions = @[
      [UIAction actionWithTitle:[NSString stringWithFormat:loadFormat, CppToFoundationString(version)] image:[UIImage systemImageNamed:@"tray.and.arrow.down"] identifier:nil handler:^(UIAction*) {
        self->_bootParameter = [[EmulationBootParameter alloc] init];
        self->_bootParameter.bootType = EmulationBootTypeSystemMenu;
        
        [self performSegueWithIdentifier:@"emulation" sender:nil];
      }],
      wiiNandElement,
      [UIAction actionWithTitle:DOLCoreLocalizedString(@"Perform Online System Update") image:[UIImage systemImageNamed:@"icloud.and.arrow.down"] identifier:nil handler:^(UIAction*) {
        [self performSegueForWiiUpdateWithSource:@"" isOnline:true];
      }]
    ];
  } else {
    wiiActions = @[
      wiiNandElement,
      [UIMenu menuWithTitle:DOLCoreLocalizedString(@"Perform Online System Update") image:[UIImage systemImageNamed:@"icloud.and.arrow.down"] identifier:nil options:0 children:@[
        [UIAction actionWithTitle:DOLCoreLocalizedString(@"Europe") image:nil identifier:nil handler:^(UIAction*) {
          [self performSegueForWiiUpdateWithSource:@"EUR" isOnline:true];
        }],
        [UIAction actionWithTitle:DOLCoreLocalizedString(@"Japan") image:nil identifier:nil handler:^(UIAction*) {
          [self performSegueForWiiUpdateWithSource:@"JPN" isOnline:true];
        }],
        [UIAction actionWithTitle:DOLCoreLocalizedString(@"Korea") image:nil identifier:nil handler:^(UIAction*) {
          [self performSegueForWiiUpdateWithSource:@"KOR" isOnline:true];
        }],
        [UIAction actionWithTitle:DOLCoreLocalizedString(@"United States") image:nil identifier:nil handler:^(UIAction*) {
          [self performSegueForWiiUpdateWithSource:@"USA" isOnline:true];
        }]
      ]
    ]];
  }
  
  NSMutableArray<UIMenuElement*>* iplActions = [[NSMutableArray alloc] init];
  
  void(^addIPLAction)(DiscIO::Region, NSString*, std::string) = ^(DiscIO::Region region, NSString* regionName, std::string regionDir) {
    UIAction* iplAction = [UIAction actionWithTitle:DOLCoreLocalizedString(regionName) image:nil identifier:nil handler:^(UIAction*) {
      [self loadGameCubeIPLForRegion:region];
    }];
    
    if (!File::Exists(Config::GetBootROMPath(regionDir))) {
      [iplAction setAttributes:UIMenuElementAttributesDisabled];
    }
    
    [iplActions addObject:iplAction];
  };
  
  addIPLAction(DiscIO::Region::NTSC_J, @"NTSC-J", JAP_DIR);
  addIPLAction(DiscIO::Region::NTSC_U, @"NTSC-U", USA_DIR);
  addIPLAction(DiscIO::Region::PAL, @"PAL", EUR_DIR);
  
  self.navigationItem.leftBarButtonItem.menu = [UIMenu menuWithChildren:@[
    [UIAction actionWithTitle:DOLCoreLocalizedString(@"Open") image:[UIImage systemImageNamed:@"externaldrive"] identifier:nil handler:^(UIAction*) {
      [self openDocumentPickerWithSoftwareContentTypesAndPickerType:DOLSoftwareListDocumentPickerTypeOpenExternal];
    }],
    [UIMenu menuWithTitle:DOLCoreLocalizedString(@"GameCube") image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
      [UIMenu menuWithTitle:@"Load GameCube Main Menu" children:iplActions]
    ]],
    [UIMenu menuWithTitle:DOLCoreLocalizedString(@"Wii") image:nil identifier:nil options:UIMenuOptionsDisplayInline children:wiiActions]
  ]];
}

- (void)openDocumentPickerWithSoftwareContentTypesAndPickerType:(DOLSoftwareListDocumentPickerType)pickerType {
  NSArray<UTType*>* types = @[
    [UTType exportedTypeWithIdentifier:@"me.oatmealdome.dolphinios.generic-software"],
    [UTType exportedTypeWithIdentifier:@"me.oatmealdome.dolphinios.gamecube-software"],
    [UTType exportedTypeWithIdentifier:@"me.oatmealdome.dolphinios.wii-software"]
  ];
  
  [self openDocumentPickerWithContentTypes:types pickerType:pickerType];
}

- (void)openDocumentPickerWithContentTypes:(NSArray<UTType*>*)contentTypes pickerType:(DOLSoftwareListDocumentPickerType)pickerType {
  UIDocumentPickerViewController* pickerController = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes];
  pickerController.delegate = self;
  pickerController.modalPresentationStyle = UIModalPresentationPageSheet;
  pickerController.allowsMultipleSelection = false;
  
  _pickerType = pickerType;
  
  [self presentViewController:pickerController animated:true completion:nil];
}

- (IBAction)addButtonPressed:(id)sender {
  [self openDocumentPickerWithSoftwareContentTypesAndPickerType:DOLSoftwareListDocumentPickerTypeImportSoftware];
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
  void (^showError)(NSString*) = ^(NSString* error) {
    UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Error") message:error preferredStyle:UIAlertControllerStyleAlert];
    
    [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault
      handler:nil]];
    
    [self presentViewController:errorAlert animated:true completion:nil];
  };
  
  if (_pickerType == DOLSoftwareListDocumentPickerTypeImportSoftware) {
    [[ImportFileManager shared] importFileAtUrl:urls[0]];
  } else if (_pickerType == DOLSoftwareListDocumentPickerTypeOpenExternal) {
    NSURL* url = urls[0];
    
    if (![url startAccessingSecurityScopedResource]) {
      showError(@"Failed to start accessing security scoped resource.");
      return;
    }
    
    _openedUrl = url;
    
    NSString* sourcePath = [_openedUrl path];
    
    GameFilePtrWrapper* gameFileWrapper = [[GameFilePtrWrapper alloc] init];
    gameFileWrapper.gameFile = std::make_shared<UICommon::GameFile>(FoundationToCppString(sourcePath));
    
    if (!gameFileWrapper.gameFile->IsValid()) {
      [_openedUrl stopAccessingSecurityScopedResource];
      
      showError(@"File is invalid.");
      
      return;
    }
    
    [self loadGameFile:gameFileWrapper];
  } else if (_pickerType == DOLSoftwareListDocumentPickerTypeImportNAND) {
    NSURL* url = urls[0];
    
    if (![url startAccessingSecurityScopedResource]) {
      showError(@"Failed to start accessing security scoped resource.");
      return;
    }
    
    UIAlertController* waitAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Importing NAND backup") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [self presentViewController:waitAlert animated:true completion:^{
      dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        DiscIO::NANDImporter().ImportNANDBin(FoundationToCppString([url path]), [] {
          // Called to update the GUI. We don't need to do this.
        }, [] {
          // Called if we need to find NAND keys. Android doesn't implement this, so let's not do it either.
          PanicAlertFmtT("The decryption keys need to be appended to the NAND backup file.");
          return "";
        });
        
        [url stopAccessingSecurityScopedResource];
        
        dispatch_async(dispatch_get_main_queue(), ^{
          [waitAlert dismissViewControllerAnimated:true completion:nil];
        });
      });
    }];
  }
}

- (UIContextMenuConfiguration*)collectionView:(UICollectionView*)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath*)indexPath point:(CGPoint)point {
  return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^(NSArray<UIMenuElement*>*) {
    GameFilePtrWrapper* gameFileWrapper = [self->_gameFiles objectAtIndex:indexPath.row];
    
    NSMutableArray<UIAction*>* actions = [[NSMutableArray alloc] init];
    
    [actions addObject:[UIAction actionWithTitle:DOLCoreLocalizedString(@"Properties") image:[UIImage systemImageNamed:@"square.and.pencil"] identifier:nil handler:^(UIAction*) {
      self->_selectedFile = gameFileWrapper;
      
      [self performSegueWithIdentifier:@"properties" sender:nil];
    }]];
    
    UIAction* deleteAction = [UIAction actionWithTitle:DOLCoreLocalizedString(@"Delete") image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(UIAction*) {
      UIAlertController* confirmAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Confirm") message:DOLCoreLocalizedString(@"Are you sure you want to delete this file?") preferredStyle:UIAlertControllerStyleAlert];
        
      [confirmAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"No") style:UIAlertActionStyleDefault handler:nil]];
      
      [confirmAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Yes") style:UIAlertActionStyleDestructive handler:^(UIAlertAction*) {
        if (File::Delete(gameFileWrapper.gameFile->GetFilePath())) {
          [self reloadGameFiles];
        }
      }]];
      
      [self presentViewController:confirmAlert animated:true completion:nil];
    }];
    
    [deleteAction setAttributes:UIMenuElementAttributesDestructive];
    
    [actions addObject:deleteAction];
    
    NSString* gameName = CppToFoundationString(gameFileWrapper.gameFile->GetName(UICommon::GameFile::Variant::LongAndPossiblyCustom));
    
    return [UIMenu menuWithTitle:gameName children:[actions copy]];
  }];
}

- (void)receiveImportFileFinishedNotification {
  [self reloadGameFiles];
}

@end
