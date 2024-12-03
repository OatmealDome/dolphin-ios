// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingRootViewController.h"

#import <map>
#import <string>

#import "Core/HW/GCPad.h"
#import "Core/HW/GCPadEmu.h"
#import "Core/HW/Wiimote.h"
#import "Core/HW/WiimoteEmu/Extension/Classic.h"
#import "Core/HW/WiimoteEmu/Extension/DrawsomeTablet.h"
#import "Core/HW/WiimoteEmu/Extension/Drums.h"
#import "Core/HW/WiimoteEmu/Extension/Guitar.h"
#import "Core/HW/WiimoteEmu/Extension/Nunchuk.h"
#import "Core/HW/WiimoteEmu/Extension/TaTaCon.h"
#import "Core/HW/WiimoteEmu/Extension/Turntable.h"
#import "Core/HW/WiimoteEmu/Extension/UDrawTablet.h"
#import "Core/HW/WiimoteEmu/WiimoteEmu.h"

#import "Common/FileUtil.h"
#import "Common/IniFile.h"

#import "InputCommon/ControllerEmu/ControlGroup/Attachments.h"
#import "InputCommon/ControllerEmu/ControllerEmu.h"
#import "InputCommon/InputConfig.h"

#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"
#import "MappingDeviceViewController.h"
#import "MappingExtensionViewController.h"
#import "MappingGroupEditViewController.h"
#import "MappingLoadProfileViewController.h"
#import "MappingRootDeviceCell.h"
#import "MappingRootExtensionCell.h"
#import "MappingRootGroupCell.h"
#import "MappingUtil.h"

struct Group {
  std::string name;
  ControllerEmu::ControlGroup* controlGroup;
  bool isExtensionsGroup = false;
};

struct Section {
  std::string headerName;
  std::string footerName;
  std::vector<Group> groups;
};

@interface MappingRootViewController ()

@end

@implementation MappingRootViewController {
  InputConfig* _config;
  ControllerEmu::EmulatedController* _controller;
  std::vector<Section> _sections;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  if (self.mappingType == DOLMappingTypePad) {
    _config = Pad::GetConfig();
  } else if (self.mappingType == DOLMappingTypeWiimote) {
    _config = Wiimote::GetConfig();
  }
  
  _controller = _config->GetController(self.mappingPort);
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self populateSections];
}

- (void)profileDidLoad:(MappingLoadProfileViewController*)viewController {
  _config->SaveConfig();
  
  [self populateSections];
}

- (void)populateSections {
  _sections.clear();
  
  switch (self.mappingType) {
    case DOLMappingTypePad: {
      _sections.push_back({"General and Options", "", {
        {"Buttons", Pad::GetGroup(self.mappingPort, PadGroup::Buttons)},
        {"D-Pad", Pad::GetGroup(self.mappingPort, PadGroup::DPad)},
        {"Control Stick", Pad::GetGroup(self.mappingPort, PadGroup::MainStick)},
        {"C Stick", Pad::GetGroup(self.mappingPort, PadGroup::CStick)},
        {"Triggers", Pad::GetGroup(self.mappingPort, PadGroup::Triggers)},
        {"Rumble", Pad::GetGroup(self.mappingPort, PadGroup::Rumble)},
        {"Options", Pad::GetGroup(self.mappingPort, PadGroup::Options)}
      }});
      
      break;
    }
    case DOLMappingTypeWiimote: {
      ControllerEmu::ControlGroup* extension_group = Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Attachments);
      
      _sections.push_back({"General and Options", "", {
        {"Buttons", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Buttons)},
        {"D-Pad", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::DPad)},
        {"Hotkeys", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Hotkeys)},
        {"Extension", extension_group, true},
        {"Rumble", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Rumble)},
        {"Options", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Options)}
      }});
      
      _sections.push_back({"Motion Simulation", "", {
        {"Shake", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Shake)},
        {"Point", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Point)},
        {"Tilt", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Tilt)},
        {"Swing", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Swing)}
      }});
      
      std::string wiimoteMotionHelp = "WARNING: The controls under Accelerometer and Gyroscope are designed to "
                                      "interface directly with motion sensor hardware. They are not intended for "
                                      "mapping traditional buttons, triggers or axes. You might need to configure "
                                      "alternate input sources before using these controls.";
      
      _sections.push_back({"Motion Input", wiimoteMotionHelp, {
        {"Point", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::IMUPoint)},
        {"Accelerometer", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::IMUAccelerometer)},
        {"Gyroscope", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::IMUGyroscope)}
      }});
      
      ControllerEmu::Attachments* ce_extension = static_cast<ControllerEmu::Attachments*>(extension_group);
      WiimoteEmu::ExtensionNumber extension = static_cast<WiimoteEmu::ExtensionNumber>(ce_extension->GetSelectionSetting().GetValue());
      
      switch (extension) {
        case WiimoteEmu::ExtensionNumber::NUNCHUK: {
          _sections.push_back({"Nunchuk", "", {
            {"Stick", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::Stick)},
            {"Buttons", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::Buttons)}
          }});
          
          _sections.push_back({"Extension Motion Simulation", "", {
            {"Shake", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::Shake)},
            {"Tilt", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::Tilt)},
            {"Swing", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::Swing)}
          }});
          
          std::string extensionMotionHelp = "WARNING: These controls are designed to interface directly with motion "
                                            "sensor hardware. They are not intended for mapping traditional buttons, triggers or "
                                            "axes. You might need to configure alternate input sources before using these controls.";
          
          _sections.push_back({"Extension Motion Input", extensionMotionHelp, {
            {"Accelerometer", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::IMUAccelerometer)}
          }});
          
          break;
        }
        case WiimoteEmu::ExtensionNumber::CLASSIC:
          _sections.push_back({"Classic Controller", "", {
            {"Buttons", Wiimote::GetClassicGroup(self.mappingPort, WiimoteEmu::ClassicGroup::Buttons)},
            {"D-Pad", Wiimote::GetClassicGroup(self.mappingPort, WiimoteEmu::ClassicGroup::DPad)},
            {"Left Stick", Wiimote::GetClassicGroup(self.mappingPort, WiimoteEmu::ClassicGroup::LeftStick)},
            {"Right Stick", Wiimote::GetClassicGroup(self.mappingPort, WiimoteEmu::ClassicGroup::RightStick)},
            {"Triggers", Wiimote::GetClassicGroup(self.mappingPort, WiimoteEmu::ClassicGroup::Triggers)}
          }});
          break;
        case WiimoteEmu::ExtensionNumber::GUITAR:
          _sections.push_back({"Guitar", "", {
            {"Stick", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::Stick)},
            {"Strum", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::Strum)},
            {"Frets", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::Frets)},
            {"Buttons", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::Buttons)},
            {"Whammy", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::Whammy)},
            {"Slider Bar", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::SliderBar)},
          }});
          break;
        case WiimoteEmu::ExtensionNumber::DRUMS:
          _sections.push_back({"Drum Kit", "", {
            {"Stick", Wiimote::GetDrumsGroup(self.mappingPort, WiimoteEmu::DrumsGroup::Stick)},
            {"Pads", Wiimote::GetDrumsGroup(self.mappingPort, WiimoteEmu::DrumsGroup::Pads)},
            {"Buttons", Wiimote::GetDrumsGroup(self.mappingPort, WiimoteEmu::DrumsGroup::Buttons)}
          }});
          break;
        case WiimoteEmu::ExtensionNumber::TURNTABLE:
          _sections.push_back({"DJ Turntable", "", {
            {"Stick", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::Stick)},
            {"Buttons", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::Buttons)},
            {"Effect", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::EffectDial)},
            {"Left Table", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::LeftTable)},
            {"Right Table", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::RightTable)},
            {"Crossfade", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::Crossfade)}
          }});
          break;
        case WiimoteEmu::ExtensionNumber::UDRAW_TABLET:
          _sections.push_back({"uDraw GameTablet", "", {
            {"Buttons", Wiimote::GetUDrawTabletGroup(self.mappingPort, WiimoteEmu::UDrawTabletGroup::Buttons)},
            {"Stylus", Wiimote::GetUDrawTabletGroup(self.mappingPort, WiimoteEmu::UDrawTabletGroup::Stylus)},
            {"Touch", Wiimote::GetUDrawTabletGroup(self.mappingPort, WiimoteEmu::UDrawTabletGroup::Touch)}
          }});
          break;
        case WiimoteEmu::ExtensionNumber::DRAWSOME_TABLET:
          _sections.push_back({"Drawsome Tablet", "", {
            {"Stylus", Wiimote::GetDrawsomeTabletGroup(self.mappingPort, WiimoteEmu::DrawsomeTabletGroup::Stylus)},
            {"Touch", Wiimote::GetDrawsomeTabletGroup(self.mappingPort, WiimoteEmu::DrawsomeTabletGroup::Touch)}
          }});
          break;
        case WiimoteEmu::ExtensionNumber::TATACON:
          _sections.push_back({"Taiko Drum", "", {
            {"Center", Wiimote::GetTaTaConGroup(self.mappingPort, WiimoteEmu::TaTaConGroup::Center)},
            {"Rim", Wiimote::GetTaTaConGroup(self.mappingPort, WiimoteEmu::TaTaConGroup::Rim)}
          }});
          break;
        default:
          break;
      }
      
      break;
    }
  }
  
  [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  // Device and profiles sections are always present
  return _sections.size() + 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case 0: // Devices
      return 1;
    case 1: // Profiles
      return 2;
    default:
      return _sections[section - 2].groups.size();
  }
}

- (NSString *)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
  if (section == 1) {
    return DOLCoreLocalizedString(@"Profile");
  }
  
  NSInteger actualSection = section - 2;
  
  if (actualSection < 0) {
    return @"";
  }
  
  NSString* sectionLocalizable = CppToFoundationString(_sections[actualSection].headerName);
  return DOLCoreLocalizedString(sectionLocalizable);
}

- (NSString *)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section {
  NSInteger actualSection = section - 2;
  
  if (actualSection < 0) {
    return @"";
  }
  
  NSString* sectionLocalizable = CppToFoundationString(_sections[actualSection].footerName);
  return DOLCoreLocalizedString(sectionLocalizable);
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 0) { // Devices
    MappingRootDeviceCell* deviceCell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
    
    const auto deviceString = _controller->GetDefaultDevice().ToString();
    if (!deviceString.empty()) {
      deviceCell.deviceLabel.text = CppToFoundationString(deviceString);
    } else {
      // Show at least *something* to make it clear that no device is selected.
      deviceCell.deviceLabel.text = @"—";
    }
    
    return deviceCell;
  } else if (indexPath.section == 1) { // Profiles
    NSString* profileCellIdentifier = indexPath.row == 1 ? @"ProfileSaveCell" : @"ProfileLoadCell";
    
    return [tableView dequeueReusableCellWithIdentifier:profileCellIdentifier];
  }
  
  NSInteger actualSection = indexPath.section - 2;
  
  const auto& group = _sections[actualSection].groups[indexPath.row];
  
  if (group.isExtensionsGroup) {
    auto attachments = static_cast<ControllerEmu::Attachments*>(group.controlGroup);
    
    MappingRootExtensionCell* extensionCell = [tableView dequeueReusableCellWithIdentifier:@"ExtensionSelectCell" forIndexPath:indexPath];
    extensionCell.extensionLabel.text = [MappingUtil getLocalizedStringForWiimoteExtension:static_cast<WiimoteEmu::ExtensionNumber>(attachments->GetSelectedAttachment())];
    
    return extensionCell;
  }
  
  MappingRootGroupCell* groupCell = [tableView dequeueReusableCellWithIdentifier:@"GroupCell" forIndexPath:indexPath];
  groupCell.nameCell.text = DOLCoreLocalizedString(CppToFoundationString(group.name));
  
  return groupCell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 1 && indexPath.row == 1) { // Profiles -> Save
    // TODO: Localization
    UIAlertController* nameAlert = [UIAlertController alertControllerWithTitle:@"Enter Name" message:@"Please enter a name for this profile." preferredStyle:UIAlertControllerStyleAlert];
    
    [nameAlert addTextFieldWithConfigurationHandler:^(UITextField* textField) {
      textField.placeholder = DOLCoreLocalizedString(@"Name");
    }];
    
    [nameAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Cancel") style:UIAlertActionStyleDefault handler:nil]];
    
    [nameAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Save") style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
      const std::string profileName = FoundationToCppString(nameAlert.textFields[0].text);
      
      if (profileName.empty()) {
        UIAlertController* badNameAlert = [UIAlertController alertControllerWithTitle:@"Invalid Name" message:@"Please enter a profile name." preferredStyle:UIAlertControllerStyleAlert];
        [badNameAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:badNameAlert animated:true completion:nil];
        
        return;
      }
      
      const std::string profilePath = self->_config->GetUserProfileDirectoryPath() + profileName + ".ini";

      File::CreateFullPath(profilePath);

      Common::IniFile ini;

      self->_controller->SaveConfig(ini.GetOrCreateSection("Profile"));
      ini.Save(profilePath);
    }]];
    
    [self presentViewController:nameAlert animated:true completion:nil];
  }
  
  [self.tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"toDevice"]) {
    MappingDeviceViewController* deviceController = segue.destinationViewController;
    
    DOLDeviceFilter filterType;
    if (self.mappingType == DOLMappingTypePad && self.mappingPort == 0) {
      filterType = DOLDeviceFilterTouchscreenExceptPad;
    } else if (self.mappingType == DOLMappingTypeWiimote && self.mappingPort == 0) {
      filterType = DOLDeviceFilterTouchscreenExceptWii;
    } else {
      filterType = DOLDeviceFilterTouchscreenAll;
    }
    
    deviceController.delegate = self;
    deviceController.filterType = filterType;
    deviceController.inputConfig = _config;
    deviceController.emulatedController = _controller;
  } else if ([segue.identifier isEqualToString:@"toExtension"]) {
    ControllerEmu::ControlGroup* extensionGroup = Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Attachments);
    
    MappingExtensionViewController* extensionController = segue.destinationViewController;
    
    extensionController.delegate = self;
    extensionController.attachments = static_cast<ControllerEmu::Attachments*>(extensionGroup);
  } else if ([segue.identifier isEqualToString:@"toGroupEdit"]) {
    MappingGroupEditViewController* editController = segue.destinationViewController;
    
    editController.delegate = self;
    editController.controller = _controller;
    
    NSIndexPath* indexPath = self.tableView.indexPathForSelectedRow;
    editController.controlGroup = _sections[indexPath.section - 2].groups[indexPath.row].controlGroup;
  } else if ([segue.identifier isEqualToString:@"toProfileLoad"]) {
    UINavigationController* loadRootController = segue.destinationViewController;
    MappingLoadProfileViewController* loadController = loadRootController.viewControllers[0];
    
    loadController.delegate = self;
    loadController.inputConfig = _config;
    loadController.emulatedController = _controller;
    loadController.filterTouchscreen = (self.mappingType == DOLMappingTypePad || self.mappingType == DOLMappingTypeWiimote) && self.mappingPort != 0;
  }
}

- (void)deviceDidChange:(MappingDeviceViewController*)viewController {
  _config->SaveConfig();
}

- (void)controlGroupDidChange:(MappingGroupEditViewController*)viewController {
  _config->SaveConfig();
}

- (void)extensionDidChange:(MappingExtensionViewController*)viewController {
  _config->SaveConfig();
}

@end
