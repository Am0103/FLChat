//
//  SPTribeMemberListViewController.m
//  WXOpenIMSampleDev
//
//  Created by Jai Chen on 15/10/15.
//  Copyright © 2015年 taobao. All rights reserved.
//

#import "SPTribeMemberListViewController.h"
#import "SPKitExample.h"
#import "SPUtil.h"
#import "SPTribeMemberCell.h"
#import "SPContactListController.h"

@interface SPTribeMemberListViewController ()<SPContactListControllerDelegate>
@property (nonatomic, strong) NSMutableArray *members;
@property (nonatomic, strong) NSMutableDictionary *memberDisplayNames;
@property (nonatomic, strong) NSMutableDictionary *memberAvatars;

@property (nonatomic, assign) BOOL isManagementMode;
@property (nonatomic, assign) BOOL toRestoredManagementMode;

@property (nonatomic, strong) UIBarButtonItem *managerToolBarItem;
@property (nonatomic, strong) UIBarButtonItem *expelMemberToolBarItem;
@end

@implementation SPTribeMemberListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AddMemberCell"];
    self.tableView.tableFooterView = [[UIView alloc] init];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(requestData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    self.members = [[[self ywTribeService] fetchTribeMembers:self.tribe.tribeId] mutableCopy];
    self.memberDisplayNames = [NSMutableDictionary dictionary];
    self.memberAvatars = [NSMutableDictionary dictionary];

    [self configureToolbar];

    [self requestData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.isManagementMode) {
        self.toRestoredManagementMode = self.isManagementMode;
        [self toggleTableViewEdit:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.isManagementMode != self.toRestoredManagementMode) {
        [self toggleTableViewEdit:nil];
    }
}

- (void)requestData {
    if (!self.tribe) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.ywTribeService requestTribeMembersFromServer:self.tribe.tribeId completion:^(NSArray *members, NSString *tribeId, NSError *error) {
        if( error == nil ) {
            weakSelf.members = [members mutableCopy];
            [weakSelf.tableView reloadData];

            [weakSelf configureToolbar];
        }
        else {
            [[SPUtil sharedInstance] showNotificationInViewController:weakSelf.navigationController
                                                                title:@"更新群成员列表失败"
                                                             subtitle:nil
                                                                 type:SPMessageNotificationTypeError];
        }
        [weakSelf.refreshControl endRefreshing];
    }];
}

- (void)configureToolbar {

    BOOL enableTrimeMemberManagement = NO;
    YWTribeMember *tribeMember = [self myTribeMember];
    if (self.tribe.tribeType == YWTribeTypeMultipleChat || tribeMember.role == YWTribeMemberRoleOwner || tribeMember.role == YWTribeMemberRoleManager) {
        enableTrimeMemberManagement = YES;
    }


    if (enableTrimeMemberManagement) {
        UIBarButtonItem *editBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"管理"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(toggleTableViewEdit:)];
        editBarButtonItem.possibleTitles = [NSSet setWithObjects:@"管理", @"完成", nil];
        self.navigationItem.rightBarButtonItem = editBarButtonItem;



        if ([self canExpelMember:nil]) {
            if (!self.expelMemberToolBarItem) {
                UIBarButtonItem *expelMemberItem = [[UIBarButtonItem alloc] initWithTitle:@"踢出群"
                                                                                    style:UIBarButtonItemStylePlain
                                                                                   target:self
                                                                                   action:@selector(expelMemberToolBarItemPressed:)];
                expelMemberItem.enabled = NO;
                self.expelMemberToolBarItem = expelMemberItem;
            }
        }
        else {
            self.expelMemberToolBarItem = nil;
        }

        if ([self canSetMemberRole:nil]) {
            if (!self.managerToolBarItem) {
                UIBarButtonItem *managerItem = [[UIBarButtonItem alloc] initWithTitle:@"设为管理员"
                                                                                style:UIBarButtonItemStylePlain
                                                                               target:self
                                                                               action:@selector(managerToolBarItemPressed:)];
                managerItem.possibleTitles = [NSSet setWithObjects:@"设置为管理员", @"撤消管理员", nil];
                managerItem.enabled = NO;
                self.managerToolBarItem = managerItem;
            }
        }
        else {
            self.managerToolBarItem = nil;
        }

        if (self.expelMemberToolBarItem && self.managerToolBarItem) {
            self.toolbarItems = @[
                                  self.managerToolBarItem,
                                  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                  self.expelMemberToolBarItem
                                  ];
        }
        else if (self.expelMemberToolBarItem) {
            self.toolbarItems = @[
                                  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                  self.expelMemberToolBarItem,
                                  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        }
        else {
            self.toolbarItems = nil;
        }
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
        if (self.isManagementMode) {
            [self toggleTableViewEdit:nil];
        }
    }
}

- (void)toggleTableViewEdit:(id)sender {
    UIBarButtonItem *item = self.navigationItem.rightBarButtonItem;

    self.isManagementMode = !self.isManagementMode;

    if (self.tableView.isEditing && self.isManagementMode) {
        [self.tableView setEditing:NO animated:NO];
    }

    [self.tableView setEditing:self.isManagementMode animated:YES];



    NSIndexPath *indexPathForInserting = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPathForInserting]
                          withRowAnimation:UITableViewRowAnimationFade];

    if (self.isManagementMode) {
        item.title = @"完成";
        if (self.toolbarItems.count) {
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    }
    else {
        item.title = @"管理";
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return (NSInteger)self.members.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return (self.isManagementMode && [self canInviteMember]) ? 64 : 0;
    }
    else {
        return 64;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddMemberCell"
                                                                forIndexPath:indexPath];

        if (self.isManagementMode) {
            cell.textLabel.text = @"添加群成员";
        }
        else {
            cell.textLabel.text = nil;
        }
        return cell;
    }

    SPTribeMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SPTribeMemberCell"
                                                              forIndexPath:indexPath];
    [self configureTribeMemberCell:cell atIndexPath:indexPath requestProfileIfNotExists:YES];
    return cell;
}

- (void)configureTribeMemberCell:(SPTribeMemberCell *)cell atIndexPath:(NSIndexPath *)indexPath requestProfileIfNotExists:(BOOL)requestProfileIfNotExists {

    if (!cell) {
        return;
    }

    YWTribeMember *tribeMember = [self.members objectAtIndex:(NSUInteger)indexPath.row];

    NSString *displayName = nil;
    UIImage *avatar = nil;

    __block NSString *cachedDisplayName = nil;
    __block UIImage *cachedAvatar = nil;
    [[SPUtil sharedInstance] syncGetCachedProfileIfExists:tribeMember
                                               completion:^(BOOL aIsSuccess, YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
                                                   cachedDisplayName = aDisplayName;
                                                   cachedAvatar = aAvatarImage;
                                               }];
    displayName = cachedDisplayName;
    avatar = cachedAvatar;

    if (tribeMember.nickname.length &&
        ![tribeMember.nickname isEqualToString:tribeMember.personId]) {
        displayName = tribeMember.nickname;
    }

    if ((displayName.length == 0 || !avatar) &&
        requestProfileIfNotExists) {  // 未获取到昵称或者头像需要获取个人 Profile

        __weak __typeof(self) weakSelf = self;
        YWFetchProfileCompletionBlock completionBlock = ^(BOOL aIsSuccess, YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
            if (aIsSuccess) {
                NSUInteger index = [weakSelf.members indexOfObject:aPerson];
                if (index != NSNotFound) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:1];
                    SPTribeMemberCell *targetCell = [weakSelf.tableView cellForRowAtIndexPath:indexPath];
                    [weakSelf configureTribeMemberCell:targetCell atIndexPath:indexPath requestProfileIfNotExists:NO];
                }
            }
        };

        [[SPUtil sharedInstance] asyncGetProfileWithPerson:tribeMember
                                                  progress:^(YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
                                                      completionBlock(YES, aPerson, aDisplayName, aAvatarImage);
                                                  }
                                                completion:^(BOOL aIsSuccess, YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
                                                    completionBlock(aIsSuccess, aPerson, aDisplayName, aAvatarImage);
                                                }];
    }


    if (displayName.length == 0) {
        displayName = tribeMember.personId;
    }
    if (!avatar) {
        avatar = [UIImage imageNamed:@"demo_head_120"];
    }

    [cell configureWithAvatar:avatar name:displayName role:tribeMember.role];
}



- (void)reloadTableViewRowForPerson:(YWPerson *)person {
    if (!person.personId) {
        return;
    }
    NSUInteger index = [self.members indexOfObject:person];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:1];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.isManagementMode) {
            [self presentAddTribeMemberViewController];
        }
    }
    else {
        if (self.isManagementMode) {

            // 取消选中之前已选中的 cell
            NSMutableArray *selectedRows = [[tableView indexPathsForSelectedRows] mutableCopy];
            [selectedRows removeObject:indexPath];
            for (NSIndexPath *indexPath in selectedRows) {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
            }

            [self selectedRowsInManagementModeDidChange];
        }
        else {
            YWTribeMember *tribeMember = [self.members objectAtIndex:(NSUInteger)indexPath.row];
            [[SPKitExample sharedInstance] exampleOpenConversationViewControllerWithPerson:tribeMember fromNavigationController:self.navigationController];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return;
    }
    else {
        if (self.isManagementMode) {
            [self selectedRowsInManagementModeDidChange];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isManagementMode) {
        if (indexPath.section == 0) {
            return UITableViewCellEditingStyleInsert;
        }

        if ([self canExpelMember:nil]) {
            return UITableViewCellEditingStyleInsert | UITableViewCellEditingStyleDelete;
        }
        else {
            return UITableViewCellEditingStyleNone;
        }
    }
    else {
        YWTribeMember *member = self.members[indexPath.row];
        if ([self canExpelMember:member]) {
            return UITableViewCellEditingStyleDelete;
        }
        return UITableViewCellEditingStyleNone;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isManagementMode) {
        UITableViewCellEditingStyle style = [self tableView:tableView editingStyleForRowAtIndexPath:indexPath];
        if (style == UITableViewCellEditingStyleNone) {
            return NO;
        }
        return YES;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        [self presentAddTribeMemberViewController];
    }
    else {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSInteger index = indexPath.row;
            YWTribeMember *member = self.members[index];
            [self expelMember:member];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"踢出群";
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return nil;
    }

    YWTribeMember *member = self.members[indexPath.row];

    NSMutableArray *actions = [NSMutableArray array];
    if ([self canExpelMember:member]) {
        __weak __typeof(self) weakSelf = self;
        UITableViewRowAction *expelMemberAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                                     title:@"踢出群"
                                                                                   handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                                                       [weakSelf expelMember:member];
                                                                                   }];
        [actions addObject:expelMemberAction];
    }
    if ([self canSetMemberRole:member]) {
        NSString *title = (member.role == YWTribeMemberRoleNormal) ? @"设置为\n管理员" : @"撤消\n管理员";
        YWTribeMemberRole roleToSet = (member.role == YWTribeMemberRoleNormal) ? YWTribeMemberRoleManager : YWTribeMemberRoleNormal;

        __weak __typeof(self) weakSelf = self;
        UITableViewRowAction *managerAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                                 title:title
                                                                               handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                                                   [weakSelf setMember:member
                                                                                              withRole:roleToSet];

                                                                               }];
        [actions addObject:managerAction];
    }
    return actions;
}

- (void)presentAddTribeMemberViewController {
    SPContactListController *contactListController = [[SPContactListController alloc] initWithNibName:@"SPContactListController" bundle:nil];
    contactListController.mode= SPContactListModeMultipleSelection;
    NSArray *excludedPersonIDs = [self.members valueForKey:@"personId"];
    contactListController.excludedPersonIDs = excludedPersonIDs;
    contactListController.delegate = self;
    
    UINavigationController *naviController = [[UINavigationController alloc] initWithRootViewController:contactListController];

    [self presentViewController:naviController
                       animated:YES
                     completion:NULL];
}

- (YWTribeMember *)selectedTribeMemberInManagementMode {
    if (!self.isManagementMode) {
        return nil;
    }

    YWTribeMember *tribeMember = nil;
    for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
        if (indexPath.section == 1 && indexPath.row < self.members.count) {
            tribeMember = self.members[indexPath.row];
            break;
        }
    }
    return tribeMember;
}

- (void)selectedRowsInManagementModeDidChange {
    YWTribeMember *member = [self selectedTribeMemberInManagementMode];
    if (member) {
        if ([self canSetMemberRole:member]) {
            NSString *title = (member.role == YWTribeMemberRoleNormal) ? @"设置为管理员" : @"撤消管理员";
            self.managerToolBarItem.title = title;
            self.managerToolBarItem.enabled = YES;
        }
        else {
            self.managerToolBarItem.enabled = NO;
        }

        if ([self canExpelMember:member]) {
            self.expelMemberToolBarItem.enabled = YES;
        }
        else {
            self.expelMemberToolBarItem.enabled = NO;
        }
    }
    else {
        self.managerToolBarItem.enabled = NO;
        self.expelMemberToolBarItem.enabled = NO;
    }
}

- (void)managerToolBarItemPressed:(id)sender {
    YWTribeMember *member = [self selectedTribeMemberInManagementMode];
    if (member.role == YWTribeMemberRoleNormal || member.role == YWTribeMemberRoleManager ) {
        YWTribeMemberRole roleToSet = (member.role == YWTribeMemberRoleNormal) ? YWTribeMemberRoleManager : YWTribeMemberRoleNormal;
        [self setMember:member withRole:roleToSet];
    }
}
- (void)expelMemberToolBarItemPressed:(id)sender {
    YWTribeMember *member = [self selectedTribeMemberInManagementMode];
    if (member) {
        [self expelMember:member];
    }
}

#pragma mark -
- (void)expelMember:(YWTribeMember *)member {
    __weak typeof(self) weakSelf = self;
    [self.ywTribeService expelMember:member fromTribe:self.tribe.tribeId completion:^(YWPerson *member, NSString *tribeId, NSError *error) {
        if( error == nil ) {
            NSUInteger index= [weakSelf.members indexOfObject:member];
            if (index != NSNotFound) {
                [weakSelf.members removeObjectAtIndex:index];
                NSIndexPath *indexPathToRemove = [NSIndexPath indexPathForRow:index inSection:1];
                [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPathToRemove]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        } else {
            [[SPUtil sharedInstance] showNotificationInViewController:weakSelf.navigationController
                                                                title:@"移除群成员失败"
                                                             subtitle:[NSString stringWithFormat:@"%@", error]
                                                                 type:SPMessageNotificationTypeError];
        }
    }];
}

- (void)setMember:(YWTribeMember *)member withRole:(YWTribeMemberRole) role{
    __weak __typeof(self) weakSelf = self;
    [[self ywTribeService] setMember:member withRole:role fromTribe:self.tribe.tribeId completion:^(YWPerson *member, YWTribeMemberRole role, NSString *tribeId, NSError *error) {
        if (!error) {
            NSUInteger index = [weakSelf.members indexOfObject:member];
            if (index != NSNotFound) {
                YWTribeMember *member = weakSelf.members[index];
                member.role = role;
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:1];
                [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath]
                                          withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        else {
            [[SPUtil sharedInstance] showNotificationInViewController:weakSelf.navigationController
                                                                title:@"修改管理员权限失败"
                                                             subtitle:[NSString stringWithFormat:@"%@", error]
                                                                 type:SPMessageNotificationTypeError];
        }
    }];
}

- (BOOL)canExpelMember:(YWTribeMember *)member {
    YWTribeMember *myMember = [self myTribeMember];
    if (myMember.role != YWTribeMemberRoleOwner) {
        return NO;
    }
    if ([member isEqualToPerson:myMember]) {
        return NO;
    }
    return YES;
}

- (BOOL)canInviteMember {
    if (self.tribe.tribeType == YWTribeTypeMultipleChat) {
        return YES;
    }
    else {
        YWTribeMember *myMember = [self myTribeMember];
        if (myMember.role == YWTribeMemberRoleOwner || myMember.role == YWTribeMemberRoleManager) {
            return YES;
        }
        return NO;
    }
}

- (BOOL)canSetMemberRole:(YWTribeMember *)member {
    if (self.tribe.tribeType == YWTribeTypeMultipleChat) {
        return NO;
    }
    YWTribeMember *myMember = [self myTribeMember];
    if (myMember.role != YWTribeMemberRoleOwner) {
        return NO;
    }
    if ([member isEqualToPerson:myMember]) {
        return NO;
    }
    return YES;
}

#pragma mark - SPContactListControllerDelegate
- (void)contactListController:(SPContactListController *)controller didSelectPersonIDs:(NSArray *)personIDs {
    if (personIDs.count) {
        NSMutableArray *persons = [NSMutableArray array];
        for (NSString *personID in personIDs) {
            YWPerson *person = [[YWPerson alloc] initWithPersonId:personID];
            if (person) {
                [persons addObject:person];
            }
        }

        __weak __typeof(self) weakSelf = self;
        [[self ywTribeService] inviteMembers:persons
                                     toTribe:self.tribe.tribeId
                                  completion:^(NSArray *members, NSString *tribeId, NSError *error) {
                                      if (!error) {
                                          if (weakSelf.tribe.tribeType == YWTribeTypeMultipleChat) {
                                              // 多聊群中成功邀请后，成员已经直接加入，刷新列表
                                              NSSet *aSet = [NSSet setWithArray:self.members];
                                              NSSet *bSet = [aSet setByAddingObjectsFromArray:members];

                                              weakSelf.members = [[bSet allObjects] mutableCopy];
                                              [weakSelf.tableView reloadData];
                                          }
                                          else if (weakSelf.tribe.tribeType == YWTribeTypeNormal) {
                                              // 普通群中成功邀请后，需要受邀者同意才加入，提示已发出邀请
                                              [[SPUtil sharedInstance] showNotificationInViewController:weakSelf.navigationController
                                                                                                  title:@"群邀请已发出"
                                                                                               subtitle:nil
                                                                                                   type:SPMessageNotificationTypeSuccess];

                                          }
                                      }
                                  }];
    }
}
#pragma mark -

- (YWIMCore *)ywIMCore {
    return [SPKitExample sharedInstance].ywIMKit.IMCore;
}

- (id<IYWTribeService>)ywTribeService {
    return [[self ywIMCore] getTribeService];
}

- (YWTribeMember *)myTribeMember {
    NSString *myPersonID = [[[self ywIMCore] getLoginService] currentLoginedUserId];

    YWTribeMember *myTribeMember = nil;
    for (YWTribeMember *tribeMember in self.members) {
        if ([tribeMember.personId isEqualToString:myPersonID]) {
            myTribeMember = tribeMember;
            break;
        }
    }
    return myTribeMember;
}

@end
