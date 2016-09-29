//
//  SPSearchContactViewController.m
//  WXOpenIMSampleDev
//
//  Created by Jai Chen on 15/10/21.
//  Copyright © 2015年 taobao. All rights reserved.
//

#import "SPSearchContactViewController.h"
#import "SPKitExample.h"
#import "SPUtil.h"
#import "SPContactCell.h"
#import "SPContactManager.h"

@interface SPSearchContactViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *results;
@property (strong, nonatomic) NSMutableDictionary *cachedDisplayNames;
@property (strong, nonatomic) NSMutableDictionary *cachedAvatars;


@end

@implementation SPSearchContactViewController

- (instancetype)init {
    if (self = [super init]) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SPContactCell" bundle:nil]
         forCellReuseIdentifier:@"ContactCell"];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.tableFooterView.backgroundColor = [UIColor clearColor];


    self.cachedAvatars = [NSMutableDictionary dictionary];
    self.cachedDisplayNames = [NSMutableDictionary dictionary];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onSearch:(NSString *)searchText {
    if( [searchText length] == 0 ){
        return;
    }
    YWPerson *person = [[YWPerson alloc] initWithPersonId:searchText];
    __weak __typeof(self) weakSelf = self;
    [[[self ywIMCore] getContactService] asyncGetProfileForPerson:person
                                                         progress:nil
                                                  completionBlock:^(BOOL aIsSuccess, YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
                                                      if (aIsSuccess && aPerson) {
                                                          if (aDisplayName) {
                                                              weakSelf.cachedDisplayNames[aPerson.personId] = aDisplayName;
                                                          }
                                                          if (aAvatarImage) {
                                                              weakSelf.cachedAvatars[aPerson.personId] = aAvatarImage;
                                                          }
                                                          weakSelf.results = @[aPerson];
                                                          [weakSelf.tableView reloadData];
                                                      }
                                                      else {
//                                                          [[SPUtil sharedInstance] showNotificationInViewController:weakSelf.navigationController
//                                                                                                              title:@"未找到该用户，请确认帐号后重试"
//                                                                                                           subtitle:nil
//                                                                                                               type:SPMessageNotificationTypeError];
                                                          self.results = nil;
                                                          [self.tableView reloadData];
                                                      }
                                                  }];
}

#pragma mark - UITableView DataSource and Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.results) {
        return self.results.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YWPerson *person = self.results[indexPath.row];

    NSString *name = nil;
    UIImage *avatar = nil;

    
    // 使用服务端的资料
    name = self.cachedDisplayNames[person.personId];
    if (!name) {
        name = person.personId;
    }
    avatar = self.cachedAvatars[person.personId];
    if (!avatar) {
        avatar = [UIImage imageNamed:@"demo_head_120"];
    }

    SPContactCell *cell= [tableView dequeueReusableCellWithIdentifier:@"ContactCell"
                                                         forIndexPath:indexPath];
    [cell configureWithAvatar:avatar title:name subtitle:nil];

    
    BOOL isMe = [person.personId isEqualToString:[[[self ywIMCore] getLoginService] currentLoginedUserId]];
    BOOL isFriend = [[[self ywIMCore] getContactService] ifPersonIsFriend:person];

    if (isMe || isFriend) {
        for (id sub in cell.contentView.subviews) {
            if ([sub isKindOfClass:[UIButton class]]) {
                UIButton *bu = (UIButton *)sub;
                if ([bu.currentTitle isEqualToString:@"添加好友"]) {
                    bu.hidden = YES;
                    break;
                }
            }
        }
        
        for (id sub in cell.contentView.subviews) {
            if ([sub isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)sub;
                if ([label.text isEqualToString:@"自己"] || [label.text isEqualToString:@"好友"]) {
                    if (isMe) {
                        label.text = @"自己";
                    }
                    else {
                        label.text = @"好友";
                    }
                    label.hidden = NO;
                    return cell;
                }
            }
        }
        
        CGFloat windowWidth = [UIScreen mainScreen].bounds.size.width;
        CGRect accessoryViewFrame = CGRectMake(windowWidth - 60, (cell.frame.size.height - 30)/2, 40, 30);
        UILabel *label = [[UILabel alloc] initWithFrame:accessoryViewFrame];

        label.textColor = [UIColor lightGrayColor];
        label.font = [UIFont fontWithName:@"Arial" size:15.0f];
//        cell.accessoryView = label;
        if (isMe) {
            label.text = @"自己";
        }
        else {
            label.text = @"好友";
        }
     
        [cell.contentView addSubview:label];
//        [label sizeToFit];
    }
    else {
//        cell.accessoryView = nil;
        for (id sub in cell.contentView.subviews) {
            if ([sub isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)sub;
                if ([label.text isEqualToString:@"自己"] || [label.text isEqualToString:@"好友"]) {
                    label.hidden = YES;
                    break;
                }
            }
        }
        
        for (id sub in cell.contentView.subviews) {
            if ([sub isKindOfClass:[UIButton class]]) {
                UIButton *bu = (UIButton *)sub;
                if ([bu.currentTitle isEqualToString:@"添加好友"]) {
                    bu.hidden = NO;
                    return cell;
                }
            }
        }
        
        CGFloat windowWidth = [UIScreen mainScreen].bounds.size.width;
        CGRect accessoryViewFrame = CGRectMake(windowWidth - 100, (cell.frame.size.height - 30)/2, 80, 30);
        UIButton *button = [[UIButton alloc] initWithFrame:accessoryViewFrame];
        [button setTitle:@"添加好友" forState:UIControlStateNormal];
        UIColor *color = [UIColor colorWithRed:0 green:180./255 blue:1.0 alpha:1.0];
        [button setTitleColor:color forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.layer.borderColor = color.CGColor;
        button.layer.borderWidth = 0.5f;
        button.layer.cornerRadius = 4.0f;
        button.backgroundColor = [UIColor clearColor];
        button.clipsToBounds = YES;
        [button addTarget:self
                   action:@selector(addContactButtonTapped:event:)
         forControlEvents:UIControlEventTouchUpInside];
//        cell.accessoryView = button;
        [cell.contentView addSubview:button];;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    YWPerson *person = self.results[indexPath.row];

    [self.navigationController setNavigationBarHidden:NO];
    [[SPKitExample sharedInstance] exampleOpenConversationViewControllerWithPerson:person fromNavigationController:self.navigationController];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    YWPerson *person = self.results[indexPath.row];
    BOOL isMe = [person.personId isEqualToString:[[[self ywIMCore] getLoginService] currentLoginedUserId]];
    return !isMe;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    YWPerson *person = self.results[indexPath.row];
    [[SPContactManager defaultManager] addContact:person];

    [self.tableView reloadData];
}

- (void)addContactButtonTapped:(id)sender event:(id)event {
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    if (indexPath != nil){
        [self tableView: self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
    }
}

#pragma mark - Utility
- (YWIMCore *)ywIMCore {
    return [SPKitExample sharedInstance].ywIMKit.IMCore;
}

@end
