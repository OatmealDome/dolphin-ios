// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersDsuClientViewController.h"

#import <string>
#import <vector>

#import <fmt/format.h>

#import "Common/CommonTypes.h"
#import "Common/Config/Config.h"
#import "Common/StringUtil.h"

#import "InputCommon/ControllerInterface/DualShockUDPClient/DualShockUDPClient.h"

#import "ControllersAddDsuServerViewController.h"
#import "ControllersAddDsuServerViewControllerDelegate.h"
#import "DsuServerCell.h"
#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"

namespace
{
struct DsuServerEntry
{
  std::string description;
  std::string address;
  u16 port;
};

// Mirrors ciface::DualShockUDPClient::InputBackend::ConfigChanged and
// DualShockUDPClientWidget::RefreshServerList: entries are stored as
// "description:address:port;" and old single-server settings (kept only
// for backwards compatibility) are folded into the new list on first read.
std::vector<DsuServerEntry> LoadDsuServers()
{
  const auto legacy_address = Config::Get(ciface::DualShockUDPClient::Settings::SERVER_ADDRESS);
  const auto legacy_port = Config::Get(ciface::DualShockUDPClient::Settings::SERVER_PORT);

  if (!legacy_address.empty() && legacy_port != 0)
  {
    const auto& current_setting = Config::Get(ciface::DualShockUDPClient::Settings::SERVERS);
    Config::SetBaseOrCurrent(ciface::DualShockUDPClient::Settings::SERVERS,
                              current_setting + fmt::format("{}:{}:{};", "DS4", legacy_address,
                                                             legacy_port));
    Config::SetBase(ciface::DualShockUDPClient::Settings::SERVER_ADDRESS, "");
    Config::SetBase(ciface::DualShockUDPClient::Settings::SERVER_PORT, 0);
  }

  std::vector<DsuServerEntry> servers;

  const auto& servers_setting = Config::Get(ciface::DualShockUDPClient::Settings::SERVERS);
  for (const auto& entry : SplitString(servers_setting, ';'))
  {
    const auto parts = SplitString(entry, ':');
    if (parts.size() < 3)
    {
      continue;
    }

    const int port = std::atoi(parts[2].c_str());
    if (port < 0 || port > 0xFFFF)
    {
      continue;
    }

    servers.push_back({parts[0], parts[1], static_cast<u16>(port)});
  }

  return servers;
}

void SaveDsuServers(const std::vector<DsuServerEntry>& servers)
{
  std::string new_setting;
  for (const auto& server : servers)
  {
    new_setting += fmt::format("{}:{}:{};", server.description, server.address, server.port);
  }

  Config::SetBaseOrCurrent(ciface::DualShockUDPClient::Settings::SERVERS, new_setting);
}
}  // namespace

@interface ControllersDsuClientViewController () <ControllersAddDsuServerViewControllerDelegate>

@end

@implementation ControllersDsuClientViewController {
  std::vector<DsuServerEntry> _servers;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = DOLCoreLocalizedString(@"DSU Client");

  NSString* htmlDescription = DOLCoreLocalizedString(
      @"DSU protocol enables the use of input and motion data from compatible "
      @"sources, like PlayStation, Nintendo Switch and Steam controllers.<br><br>"
      @"For setup instructions, "
      @"<a href=\"https://wiki.dolphin-emu.org/index.php?title=DSU_Client\">"
      @"refer to this page</a>.");

  NSData* htmlData = [htmlDescription dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary* options = @{
    NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
    NSCharacterEncodingDocumentAttribute : @(NSUTF8StringEncoding)
  };

  NSAttributedString* attributedDescription =
      [[NSAttributedString alloc] initWithData:htmlData options:options
                             documentAttributes:nil error:nil];

  if (attributedDescription != nil) {
    self.descriptionTextView.attributedText = attributedDescription;
  } else {
    // Fall back to plain text if, for whatever reason, the HTML failed to parse.
    self.descriptionTextView.text = htmlDescription;
  }

  self.descriptionTextView.font = [UIFont systemFontOfSize:15];
  self.descriptionTextView.textColor = [UIColor secondaryLabelColor];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  self->_servers = LoadDsuServers();

  self.enabledSwitch.on = Config::Get(ciface::DualShockUDPClient::Settings::SERVERS_ENABLED);

  [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 3;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case 0:  // Enable
      return 1;
    case 1:  // Servers + Add row
      return self->_servers.size() + 1;
    default:  // Description
      return 1;
  }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 0) {
    return [tableView dequeueReusableCellWithIdentifier:@"enableCell" forIndexPath:indexPath];
  }

  if (indexPath.section == 1) {
    if ((NSUInteger)indexPath.row == self->_servers.size()) {
      UITableViewCell* addCell = [tableView dequeueReusableCellWithIdentifier:@"addCell" forIndexPath:indexPath];
      addCell.userInteractionEnabled = self.enabledSwitch.on;
      addCell.textLabel.alpha = self.enabledSwitch.on ? 1.0 : 0.5;
      return addCell;
    }

    DsuServerCell* serverCell = [tableView dequeueReusableCellWithIdentifier:@"serverCell" forIndexPath:indexPath];

    const auto& server = self->_servers[indexPath.row];
    serverCell.nameLabel.text = [NSString stringWithFormat:@"%@:%@ - %@",
                                                             CppToFoundationString(server.address),
                                                             @(server.port),
                                                             CppToFoundationString(server.description)];
    serverCell.nameLabel.alpha = self.enabledSwitch.on ? 1.0 : 0.5;

    return serverCell;
  }

  return [tableView dequeueReusableCellWithIdentifier:@"descriptionCell" forIndexPath:indexPath];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:true];

  if (indexPath.section != 1 || (NSUInteger)indexPath.row != self->_servers.size()) {
    return;
  }

  if (!self.enabledSwitch.on) {
    return;
  }

  [self performSegueWithIdentifier:@"addServer" sender:nil];
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section != 1 || (NSUInteger)indexPath.row == self->_servers.size()) {
    return false;
  }

  return self.enabledSwitch.on;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
  if (editingStyle != UITableViewCellEditingStyleDelete) {
    return;
  }

  self->_servers.erase(self->_servers.begin() + indexPath.row);
  SaveDsuServers(self->_servers);

  [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Actions

- (IBAction)enabledSwitchChanged:(id)sender {
  Config::SetBaseOrCurrent(ciface::DualShockUDPClient::Settings::SERVERS_ENABLED, (bool)self.enabledSwitch.on);

  // Section 1 needs to redraw: the server rows and the "Add..." row both
  // reflect the enabled state (dimmed + non-interactive when disabled).
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"addServer"]) {
    ControllersAddDsuServerViewController* addController = segue.destinationViewController;
    addController.delegate = self;
  }
}

#pragma mark - ControllersAddDsuServerViewControllerDelegate

- (void)addDsuServerViewController:(ControllersAddDsuServerViewController*)viewController
                 didAddServerWithDescription:(NSString*)description
                                      address:(NSString*)address
                                         port:(uint16_t)port {
  self->_servers.push_back({FoundationToCppString(description), FoundationToCppString(address), port});
  SaveDsuServers(self->_servers);

  [self.tableView reloadData];
}

@end
