
//
//  SPTribeProfileViewController.m
//  WXOpenIMSampleDev
//
//  Created by Jai Chen on 15/10/15.
//  Copyright © 2015年 taobao. All rights reserved.
//

#import "SPTribeProfileViewController.h"
#import "SPTribeInfoEditViewController.h"
#import "SPTribeMemberListViewController.h"
#import "SPKitExample.h"
#import "SPUtil.h"
#import "UIControl+BlockSupport.h"
#import "SPTribeQRCodeViewController.h"

typedef enum : int {
    SPTribeMemberRoleNotKnown,
    SPTribeMemberRoleGuest,
    SPTribeMemberRoleNormal,
    SPTribeMemberRoleManager
} SPTribeMemberRole;

#define kSPTribeProfileActionTitleJoin @"加入群"
#define kSPTribeProfileActionTitleExit @"退出群"
#define kSPTribeProfileActionTitleDisband @"解散群"
#define kSPTribeProfileActionTitleSendMess @"发送消息"

@interface SPTribeProfileViewController ()
<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *tribeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *tribeIDLabel;

@property (weak, nonatomic) IBOutlet UIImageView *converImageView;

@property (assign, nonatomic) NSUInteger countOfMembers;
@property (strong, nonatomic) YWTribeMember *myTribeMember;

@end

@implementation SPTribeProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width * 0.5;
    self.avatarImageView.clipsToBounds = YES;

    self.countOfMembers = [[self ywTribeService] fetchTribeMembers:self.tribe.tribeId].count;
    
    //判断显示 加入群 退出群 解散群
    self.myTribeMember = [[self ywTribeService] fetchTribeMember:[[[self ywIMCore] getLoginService] currentLoginedUser] inTribe:self.tribe.tribeId];
    
    [self reloadData];
    [self addTribeCallbackBlocks];
}

- (void)dealloc {
    [self removeTribeCallbackBlocks];
}

- (void)addTribeCallbackBlocks {
    __weak __typeof(self) weakSelf = self;

    [[self ywTribeService] addMemberDidJoinBlock:^(NSDictionary *userInfo) {
        NSString *tribeID = userInfo[YWTribeServiceKeyTribeId];
        YWPerson *person = userInfo[YWTribeServiceKeyPerson];
        YWPerson *me = [[[weakSelf ywIMCore] getLoginService] currentLoginedUser];
        if ([tribeID isEqualToString:weakSelf.tribe.tribeId] ) {
            if([person isEqualToPerson:me]) {
                weakSelf.myTribeMember = [[weakSelf ywTribeService] fetchTribeMember:[[[weakSelf ywIMCore] getLoginService] currentLoginedUser]
                                                                             inTribe:weakSelf.tribe.tribeId];

                [weakSelf reloadData];
                [weakSelf requestTribeMembers];
            }
            else {
                weakSelf.countOfMembers++;
                [weakSelf reloadData];
            }
        }
    } forKey:self.description ofPriority:YWBlockPriorityDeveloper];

    [[self ywTribeService] addDidExpelFromTribeBlock:^(NSDictionary *userInfo) {
        NSString *tribeID = userInfo[YWTribeServiceKeyTribeId];
        YWPerson *person = userInfo[YWTribeServiceKeyPerson];
        YWPerson *me = [[[weakSelf ywIMCore] getLoginService] currentLoginedUser];
        if ([tribeID isEqualToString:weakSelf.tribe.tribeId] ) {
            if([person isEqualToPerson:me]) {
                [weakSelf.navigationController popToRootViewControllerAnimated:YES];

                weakSelf.myTribeMember = nil;
                [weakSelf.tableView reloadData];
            }
            else {
                weakSelf.countOfMembers--;
                [weakSelf reloadData];
            }
        }
    } forKey:self.description ofPriority:YWBlockPriorityDeveloper];


    [[self ywTribeService] addMemberDidExitBlock:^(NSDictionary *userInfo) {
        NSString *tribeID = userInfo[YWTribeServiceKeyTribeId];
        YWPerson *person = userInfo[YWTribeServiceKeyPerson];
        YWPerson *me = [[[weakSelf ywIMCore] getLoginService] currentLoginedUser];
        if ([tribeID isEqualToString:weakSelf.tribe.tribeId] ) {
            if([person isEqualToPerson:me]) {
                [weakSelf.navigationController popToRootViewControllerAnimated:YES];

                weakSelf.myTribeMember = nil;
                [weakSelf.tableView reloadData];
            }
            else {
                weakSelf.countOfMembers--;
                [weakSelf reloadData];
            }
        }
    } forKey:self.description ofPriority:YWBlockPriorityDeveloper];


    [[self ywTribeService] addTribeDidDisbandBlock:^(NSDictionary *userInfo) {
        NSString *tribeID = userInfo[YWTribeServiceKeyTribeId];
        if ([tribeID isEqualToString:weakSelf.tribe.tribeId]) {
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];

            weakSelf.myTribeMember = nil;
            [weakSelf reloadData];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf dismissViewController:nil];
            });
        }
    } forKey:self.description ofPriority:YWBlockPriorityDeveloper];

    [[self ywTribeService] addTribeInfoDidUpdateBlock:^(NSDictionary *userInfo) {
        NSString *tribeId = userInfo[YWTribeServiceKeyTribeId];
        if ([tribeId isEqualToString:weakSelf.tribe.tribeId]) {
            NSString *tribeName = userInfo[YWTribeServiceKeyTribeName];
            if (tribeName) {
                weakSelf.tribe.tribeName = tribeName;
                [weakSelf reloadData];
            }

            NSString *bulletin = userInfo[YWTribeServiceKeyTribeNotice];
            if (bulletin) {
                weakSelf.tribe.notice = bulletin;
                [weakSelf.tableView reloadData];
            }
        }

    } forKey:self.description ofPriority:YWBlockPriorityDeveloper];
}

- (void)removeTribeCallbackBlocks {
    [[self ywTribeService] removeMemberDidJoinBlockForKey:self.description];
    [[self ywTribeService] removeDidExpelFromTribeBlockForKey:self.description];
    [[self ywTribeService] removeMemberDidExitBlockForKey:self.description];
    [[self ywTribeService] removeTribeDidDisbandBlockForKey:self.description];
    [[self ywTribeService] removeTribeInfoDidUpdateBlockForKey:self.description];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:animated];

    [self requestTribe];
    [self requestTribeMembers];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadData {
    self.tribeIDLabel.text = [NSString stringWithFormat:@"群号 %@", self.tribe.tribeId ?: @""];
    self.tribeNameLabel.text = self.tribe.tribeName;
    UIImage *avatar = [[SPUtil sharedInstance] avatarForTribe:self.tribe];
    self.avatarImageView.image = avatar;

    [self.tableView reloadData];
}

#pragma mark - OpenIM API
- (void)requestTribeMembers {
    if (!self.tribe) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.ywTribeService requestTribeMembersFromServer:self.tribe.tribeId completion:^(NSArray *members, NSString *tribeId, NSError *error) {
        if(!error) {
            weakSelf.countOfMembers = members.count;
            weakSelf.myTribeMember = [[weakSelf ywTribeService] fetchTribeMember:[[[weakSelf ywIMCore] getLoginService] currentLoginedUser]
                                                                 inTribe:weakSelf.tribe.tribeId];
            [weakSelf.tableView reloadData];
        }
    }];
}
- (void)requestTribe {
    if (!self.tribe) {
        return;
    }

    __weak __typeof(self) weakSelf = self;
    [self.ywTribeService requestTribeFromServer:self.tribe.tribeId completion:^(YWTribe *tribe, NSError *error) {
        if(!error) {
            weakSelf.tribe = tribe;
            [weakSelf reloadData];
        }
        else {
            [weakSelf handleRequestError:error name:@"更新群信息"];
        }
    }];
}

- (void)joinToTribe {
    __weak typeof (self) weakSelf = self;
    [[SPUtil sharedInstance] setWaitingIndicatorShown:YES withKey:self.description];
    [[self ywTribeService] joinTribe:self.tribe checkInfo:nil completion:^(NSString *tribeId, NSError *error) {
        [[SPUtil sharedInstance] setWaitingIndicatorShown:NO withKey:weakSelf.description];

        [weakSelf handleRequestError:error name:@"加入群"];
    }];
}

- (void)exitFromTribe {
    __weak __typeof(self) weakSelf = self;
    [[SPUtil sharedInstance] setWaitingIndicatorShown:YES withKey:self.description];
    [[self ywTribeService] exitFromTribe:self.tribe.tribeId completion:^(NSString *tribeId, NSError *error) {
        [[SPUtil sharedInstance] setWaitingIndicatorShown:NO withKey:weakSelf.description];

        [weakSelf handleRequestError:error name:@"退出群"];
    }];
}

- (void)disbandTribe {
    __weak __typeof(self) weakSelf = self;
    [[SPUtil sharedInstance] setWaitingIndicatorShown:YES withKey:self.description];
    [[self ywTribeService] disbandTribe:self.tribe.tribeId completion:^(NSString *tribeId, NSError *error) {
        [[SPUtil sharedInstance] setWaitingIndicatorShown:NO withKey:weakSelf.description];

        [weakSelf handleRequestError:error name:@"解散群"];
    }];

}

- (void)modifyMyNickname:(NSString *)nickName {
    __weak __typeof(self) weakSelf = self;
    [[self ywTribeService] modifyNickname:nickName ofMember:[self myTribeMember] inTribe:self.tribe.tribeId completion:^(YWTribeMember *member, NSString *tribeId, NSError *error) {
        if(!error) {
            [weakSelf myTribeMember].nickname = member.nickname;
            [weakSelf.tableView reloadData];
        }
        [weakSelf handleRequestError:error name:@"修改我的群昵称"];
    }];
}

- (void)handleRequestError:(NSError *)error name:(NSString *)name {
    NSString *title = [name stringByAppendingString:!error ? @"成功" : @"失败"];
    SPMessageNotificationType notificationType = !error ? SPMessageNotificationTypeSuccess : SPMessageNotificationTypeError;

    [[SPUtil sharedInstance] showNotificationInViewController:self.navigationController
                                                        title:title
                                                     subtitle:error.localizedFailureReason
                                                         type:notificationType];
}

#pragma mark - UITableView DataSource & Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger number = 4;
    return number;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger number = 0;
    switch (section) {
        case 0:
            number = 1;
            break;
        case 1:
        {
            YWTribeMember *tribeMember = [self myTribeMember];
            if (tribeMember) {
                if (tribeMember.role == YWTribeMemberRoleOwner || tribeMember.role == YWTribeMemberRoleManager) {
                    number = 2;
                }
                else {
                    number = 1;
                }

                if ([[UIDevice currentDevice].systemVersion compare:@"7.0"] != NSOrderedAscending) {
                    number++;
                }
            }
            else {
                number = 0;
            }

            break;
        }
        case 2:
            number = 2;
            if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
                number ++;
            }

            break;
        case 3:
            number = 1;
            break;
        default:
            break;
    }
    return number;
}


- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 85.0f;
    }
    return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {

        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TribeDescriptionCell"];
        [cell prepareForReuse];

        UILabel *noticeLabel = [cell.contentView viewWithTag:2045];
        noticeLabel.text = self.tribe.notice;

        CGSize fittingSize;
        cell.frame = tableView.frame;
        [cell layoutIfNeeded];
        noticeLabel.preferredMaxLayoutWidth = noticeLabel.frame.size.width;
        fittingSize = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

        if (tableView.separatorStyle != UITableViewCellSeparatorStyleNone) {
            fittingSize.height += 1.0 / [UIScreen mainScreen].scale;
        }
        return fittingSize.height;
    }
    return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell;

    __weak typeof(self) weakSelf = self;
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TribeDescriptionCell"
                                               forIndexPath:indexPath];
        UILabel *noticeLabel = [cell.contentView viewWithTag:2045];
        noticeLabel.text = self.tribe.notice;
        noticeLabel.preferredMaxLayoutWidth = noticeLabel.frame.size.width;
    }
    else if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"
                                               forIndexPath:indexPath];


        NSInteger numberOfRows = [self tableView:tableView numberOfRowsInSection:indexPath.section];
        if (indexPath.row == 0) {
            YWTribeMember *tribeMember = [self myTribeMember];
            if (tribeMember.role == YWTribeMemberRoleOwner || tribeMember.role ==   YWTribeMemberRoleManager) {
                cell.textLabel.text = @"群成员管理";
            }
            else {
                cell.textLabel.text = @"群成员列表";
            }
            NSString *memberCountText = (self.countOfMembers > 0) ? [NSString stringWithFormat:@"%lu人", (unsigned long)self.countOfMembers]: nil;
            cell.detailTextLabel.text = memberCountText;
        }
        else if (indexPath.row == numberOfRows - 1) {
            cell.textLabel.text = @"群二维码";
            cell.detailTextLabel.text = nil;
        }
        else {
            cell.textLabel.text = @"群信息编辑";
            cell.detailTextLabel.text = nil;
        }
    }
    else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"
                                                   forIndexPath:indexPath];

            YWMessageFlag messageFlag = [[[self ywIMCore] getSettingService] getMessageReceiveForTribe:_tribe];
            cell.textLabel.text = @"群消息状态";

            NSString *statusString = nil;
            if (messageFlag == YWMessageFlagNotReceive) {
                statusString = @"屏蔽";
            } else if (messageFlag == YWMessageFlagReceive) {
                statusString = @"接收并推送";
            } else {
                statusString = @"接收不推送";
            }
            cell.detailTextLabel.text = statusString;
        }
        else if (indexPath.row == 1) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"RightSwitchCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RightSwitchCell"];
                UISwitch *theSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.width)];
                cell.accessoryView = theSwitch;
            }

            BOOL receiveAtMessage = [[[self ywIMCore] getSettingService] getAtMessageEnableReceiveForTribe:_tribe];

            UISwitch *theSwitch = (UISwitch *)cell.accessoryView;
            YWMessageFlag messageFlag = [[[self ywIMCore] getSettingService] getMessageReceiveForTribe:_tribe];
            cell.textLabel.text = @"接收@消息";
            cell.detailTextLabel.text = nil;

            if (messageFlag != YWMessageFlagNotReceive) {
                theSwitch.on = YES;
                theSwitch.enabled = NO;
            } else {
                theSwitch.enabled = YES;
                if (receiveAtMessage) {
                    theSwitch.on = YES;
                } else {
                    theSwitch.on = NO;
                }
                
                __weak UISwitch *weakSwitch = theSwitch;
                [theSwitch addblock:^{
                    [[[weakSelf ywIMCore] getSettingService] asyncSetAtMessageReceive:weakSwitch.on ? YWAtMessageFlagReceive : YWAtMessageFlagNotReceive ForTribe:weakSelf.tribe completion:^(NSError *aError, NSDictionary *aResult) {
                        if (aError == nil) {
                            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
                    }];
                } forControlEvents:UIControlEventValueChanged];
            }
        }
        else if (indexPath.row == 2) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"
                                                   forIndexPath:indexPath];
            cell.textLabel.text = @"我的昵称";
            cell.detailTextLabel.text = [self myTribeMember].nickname ?: @"未设置";
        }

    }
    else if (indexPath.section == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell"
                                               forIndexPath:indexPath];

        UILabel *label = (UILabel *)[cell.contentView viewWithTag:2046];

        YWTribeMember *tribeMember = [self myTribeMember];
        
        //如果来自搜索界面
        if(self.isFromAddFriendVcInSearchTribe)
        {
            if (!tribeMember) {
                label.text = kSPTribeProfileActionTitleJoin;
            }
            else
            {
                label.text = kSPTribeProfileActionTitleSendMess;
            }
            return cell;
        }
        
        if (!tribeMember) {
            label.text = kSPTribeProfileActionTitleJoin;
        }
        else if (tribeMember.role == YWTribeMemberRoleOwner
                 && self.tribe.tribeType == YWTribeTypeNormal) {
            label.text = kSPTribeProfileActionTitleDisband;

        }
        else {
            label.text = kSPTribeProfileActionTitleExit;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 1) {
        NSInteger numberOfRows = [self tableView:tableView numberOfRowsInSection:indexPath.section];
        if (indexPath.row == 0) {
            // 群成员列表
            SPTribeMemberListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SPTribeMemberListViewController"];
            controller.tribe = self.tribe;
            [self.navigationController pushViewController:controller animated:YES];
        }
        else if (indexPath.row == numberOfRows - 1) {
            // 群二维码
            SPTribeQRCodeViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SPTribeQRCodeViewController"];
            controller.tribe = self.tribe;
            [self.navigationController pushViewController:controller animated:YES];
        }
        else {
            // 编辑群信息
            SPTribeInfoEditViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SPTribeInfoEditViewController"];
            controller.mode = SPTribeInfoEditModeModify;
            controller.tribe = self.tribe;
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
    else if (indexPath.section == 2 && indexPath.row == 0) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"群消息状态" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"接收",@"接收不推送",@"屏蔽", nil];
        
        [actionSheet showInView:self.view];
    }
    else if (indexPath.section == 2 && indexPath.row == 2) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"修改群昵称"
                                                                            message:@""
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof(self) weakSelf = self;

        __block UITextField *nickTextField = nil;
        [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = [weakSelf myTribeMember].nickname;
            nickTextField = textField;
        }];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];

        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"修改"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               [weakSelf modifyMyNickname:nickTextField.text];
                                                           }];
        [controller addAction:cancelAction];
        [controller addAction:doneAction];

        [self presentViewController:controller animated:YES completion:nil];
    }
    else if (indexPath.section == 3 && indexPath.row == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UILabel *label = (UILabel *)[cell.contentView viewWithTag:2046];
        if ([label.text isEqualToString:kSPTribeProfileActionTitleJoin]) {
            [self joinToTribe];
        }
        else if ([label.text isEqualToString:kSPTribeProfileActionTitleDisband]) {
            [self disbandTribe];
        }
        else if ([label.text isEqualToString:kSPTribeProfileActionTitleExit]) {
            [self exitFromTribe];
        }
        else if ([label.text isEqualToString:kSPTribeProfileActionTitleSendMess]) {
            [self presentConversationViewControllerWithTribe:self.tribe];
        }
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        YWTribeMember *tribeMember = [self myTribeMember];
        if (!tribeMember) {
            return CGFLOAT_MIN;
        }
    }
    return UITableViewAutomaticDimension;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        YWTribeMember *tribeMember = [self myTribeMember];
        if (!tribeMember) {
            return CGFLOAT_MIN;
        }
    }
    return UITableViewAutomaticDimension;
}
#pragma mark 跳转到搜索界面
- (void)presentConversationViewControllerWithTribe:(YWTribe *)tribe {
    if (!tribe) {
        return ;
    }
    
    self.navigationController.navigationBarHidden = NO;
    [[SPKitExample sharedInstance] exampleOpenConversationViewControllerWithTribe:tribe fromNavigationController:self.navigationController];
}
#pragma mark - UISCrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.tableView) {
        return;
    }

    CGFloat coverOriginalHeight = CGRectGetHeight(self.converImageView.superview.frame);

    if (scrollView.contentOffset.y < 0) {
        CGFloat scale = (fabs(scrollView.contentOffset.y) + coverOriginalHeight) / coverOriginalHeight;

        CATransform3D transformScale3D = CATransform3DMakeScale(scale, scale, 1.0);
        CATransform3D transformTranslate3D = CATransform3DMakeTranslation(0, scrollView.contentOffset.y/2, 0);
        self.converImageView.layer.transform = CATransform3DConcat(transformScale3D, transformTranslate3D);

        UIEdgeInsets scrollIndicatorInsets = scrollView.scrollIndicatorInsets;
        scrollIndicatorInsets.top = fabs(scrollView.contentOffset.y) + coverOriginalHeight;
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
    }
    else {
        self.converImageView.layer.transform = CATransform3DIdentity;

        if (scrollView.scrollIndicatorInsets.top != coverOriginalHeight) {
            UIEdgeInsets scrollIndicatorInsets = scrollView.scrollIndicatorInsets;
            scrollIndicatorInsets.top = coverOriginalHeight;
            scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
        }
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < 3) {
        [[[self ywIMCore] getSettingService] asyncSetMessageReceive:2-buttonIndex ForTribe:self.tribe completion:^(NSError *aError, NSDictionary *aResult) {
            [self.tableView reloadData];
        }];
    }
}

#pragma mark - Navigation
- (IBAction)dismissViewController:(id)sender {
    if (self.presentingViewController && self.navigationController.viewControllers.firstObject == self) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Utility
- (YWIMCore *)ywIMCore {
    return [SPKitExample sharedInstance].ywIMKit.IMCore;
}

- (id<IYWTribeService>)ywTribeService {
    return [[self ywIMCore] getTribeService];
}

@end
