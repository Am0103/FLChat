//
//  TabBarViewController.m
//  FLChat
//
//  Created by FL on 16/9/14.
//  Copyright © 2016年 zhigeng. All rights reserved.
//

#import "SPTabBarViewController.h"

#import "SPKitExample.h"
#import "SPUtil.h"
#import <YWExtensionForCustomerServiceFMWK/YWExtensionForCustomerServiceFMWK.h>

#import "YWConversationListViewController+UIViewControllerPreviewing.h"
#import "SPContactListController.h"
#import "SPSettingController.h"

#import "AddFriendViewController.h"

#define kTabbarItemCount    4

#import "Header_Color.h"

#import "WJPopoverViewController.h"

@interface SPTabBarViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    
    WJPopoverViewController *_popView;
    
    UITableView *_tableView;
    
    NSArray *_MenuArr;
}
@end

@implementation SPTabBarViewController

#pragma mark - private

- (UITabBarItem *)_makeItemWithTitle:(NSString *)aTitle normalName:(NSString *)aNormal selectedName:(NSString *)aSelected tag:(NSInteger)aTag
{
    UITabBarItem *result = nil;
    
    UIImage *nor = [UIImage imageNamed:aNormal];
    UIImage *sel = [UIImage imageNamed:aSelected];
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7.f) {
        result = [[UITabBarItem alloc] initWithTitle:aTitle image:nor selectedImage:sel];
        [result setTag:aTag];
    } else {
        result = [[UITabBarItem alloc] initWithTitle:aTitle image:nor tag:aTag];
    }
    
    return result;
}

#pragma mark - life

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _MenuArr = [NSArray arrayWithObjects:@"发起群聊",@"加好友",@"扫一扫",@"收付款", nil];
    
    self.tabBar.translucent = NO;
    
    NSMutableArray *aryControllers = [NSMutableArray array];
    
    /// 会话列表页面
    {
        
        YWConversationListViewController *conversationListController = [[SPKitExample sharedInstance].ywIMKit makeConversationListViewController];
        
         conversationListController.ywcsTrackTitle = @"会话列表";
        //Am6注释的
//        [[SPKitExample sharedInstance] exampleCustomizeConversationCellWithConversationListController:conversationListController];
        
        __weak __typeof(conversationListController) weakConversationListController = conversationListController;
        conversationListController.didSelectItemBlock = ^(YWConversation *aConversation) {
            
            if ([aConversation isKindOfClass:[YWCustomConversation class]]) {
                YWCustomConversation *customConversation = (YWCustomConversation *)aConversation;
                [customConversation markConversationAsRead];
                
                if ([customConversation.conversationId isEqualToString:SPTribeSystemConversationID]) {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Tribe" bundle:nil];
                    UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"SPTribeSystemConversationViewController"];
                    [weakConversationListController.navigationController pushViewController:controller animated:YES];
                }
            }
            
            else
            {
                [[SPKitExample sharedInstance]exampleOpenConversationViewControllerWithConversation:aConversation fromNavigationController:weakConversationListController.navigationController];
            }
        };
      

        conversationListController.didDeleteItemBlock = ^ (YWConversation *aConversation) {
            if ([aConversation.conversationId isEqualToString:SPTribeSystemConversationID]) {
                [[[SPKitExample sharedInstance].ywIMKit.IMCore getConversationService] removeConversationByConversationId:[SPKitExample sharedInstance].tribeSystemConversation.conversationId error:NULL];
            }
        };
    
        // 会话列表空视图
        if (conversationListController)
        {
            CGRect frame = CGRectMake(0, 0, 100, 100);
            UIView *viewForNoData = [[UIView alloc] initWithFrame:frame];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login_logo"]];
            imageView.center = CGPointMake(viewForNoData.frame.size.width/2, viewForNoData.frame.size.height/2);
            [imageView setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin];
            
            [viewForNoData addSubview:imageView];
            
            conversationListController.viewForNoData = viewForNoData;
        }
        
        {
            __weak typeof(conversationListController) weakController = conversationListController;
            [conversationListController setViewDidLoadBlock:^{
                
                weakController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCustom:forEvent:)];
                
                
                // 加入搜索栏
                weakController.tableView.tableHeaderView = weakController.searchBar;
                
//                CGPoint contentOffset = CGPointMake(0, weakController.searchBar.frame.size.height);
//                [weakController.tableView setContentOffset:contentOffset animated:NO];
                //修改searchBar背景颜色
                weakController.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
                weakController.searchBar.backgroundColor = kBackColor;
                
                NSArray *arr = weakController.searchBar.subviews;
                for (UIView *subView in arr)
                {
                    NSArray *arr2 = subView.subviews;
                    for (UIView *subView2 in arr2)
                    {
                        if ([subView2 isKindOfClass:NSClassFromString(@"UISearchBarBackground")])
                        {
                            [subView2 removeFromSuperview];
                            break;
                        }
                    }
                }
                UIView *view = [[UIView alloc] initWithFrame:weakController.searchBar.frame];
                view.backgroundColor = [UIColor clearColor];
                [weakController.searchBar insertSubview:view atIndex:0];

                
                if ([weakController respondsToSelector:@selector(traitCollection)]) {
                    UITraitCollection *traitCollection = weakController.traitCollection;
                    if ( [traitCollection respondsToSelector:@selector(forceTouchCapability)] ) {
                        if (traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                            [weakController registerForPreviewingWithDelegate:weakController sourceView:weakController.tableView];
                        }
                    }
                }
            }];
        }
        
        
        UINavigationController *naviController = [[UINavigationController alloc] initWithRootViewController:conversationListController];
        
        UITabBarItem *item = [self _makeItemWithTitle:@"消息" normalName:@"news_nor" selectedName:@"news_pre" tag:100];
        [naviController setTabBarItem:item];
        
        [aryControllers addObject:naviController];
        
        __weak typeof(naviController) weakController = naviController;
        [[SPKitExample sharedInstance].ywIMKit setUnreadCountChangedBlock:^(NSInteger aCount) {
            NSString *badgeValue = aCount > 0 ?[ @(aCount) stringValue] : nil;
            weakController.tabBarItem.badgeValue = badgeValue;
        }];
    }
    
    
    
    /// 联系人列表页面
    {
        SPContactListController *contactListController = [[SPContactListController alloc] initWithNibName:@"SPContactListController" bundle:nil];
        
        UINavigationController *naviController = [[UINavigationController alloc] initWithRootViewController:contactListController];
        
        UITabBarItem *item = [self _makeItemWithTitle:@"联系人" normalName:@"contact_nor" selectedName:@"contact_pre" tag:101];
        [naviController setTabBarItem:item];
        
        [aryControllers addObject:naviController];
    }
    
    /// 群页面
    {
        

    }
    
    // 设置页面
    {
        SPSettingController *settingController = [[SPSettingController alloc] initWithNibName:@"SPSettingController" bundle:nil];

        UINavigationController *naviController = [[UINavigationController alloc] initWithRootViewController:settingController];

        UITabBarItem *item = [self _makeItemWithTitle:@"更多" normalName:@"set_nor" selectedName:@"set_pre" tag:103];
        [naviController setTabBarItem:item];

        [aryControllers addObject:naviController];
    }


    self.viewControllers = aryControllers;

}

- (void)addCustom:(UIBarButtonItem *)item forEvent:(UIEvent *)event
{
    //Am6
    //    [[SPKitExample sharedInstance] exampleAddOrUpdateCustomConversation];
    _popView = [[WJPopoverViewController alloc] initWithShowView:[self tableView]];
    _popView.borderWidth = 0;
    [_popView showPopoverWithBarButtonItemTouch:event animation:YES];
}


- (UITableView *)tableView {
    if(_tableView == nil) {
        _tableView = [[UITableView alloc] init];
        _tableView.frame = CGRectMake(0, 0, 150, 199);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 50;
        _tableView.scrollEnabled = NO;
        // ios 7
        if ([_tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [_tableView setSeparatorInset:UIEdgeInsetsZero];
        }
        // ios 8
        if([_tableView respondsToSelector:@selector(setLayoutMargins:)]){
            [_tableView setLayoutMargins:UIEdgeInsetsZero];
        }
        
    }
    return _tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // iso 7
    if ([cell  respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    // ios 8
    if([cell respondsToSelector:@selector(setLayoutMargins:)]){
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.textLabel.font = [UIFont fontWithName:@"Arial" size:14.0f];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
//    UIView *view = [[UIView alloc] init];
//    view.backgroundColor = [UIColor blueColor];
//    cell.selectedBackgroundView = view;
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = [_MenuArr objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%@", indexPath);
    [WJPopoverViewController dissPopoverViewWithAnimation:NO];
   
    switch (indexPath.row) {
        case 1:
        {
            AddFriendViewController *addFriend = [[AddFriendViewController alloc] initWithNibName:@"AddFriendViewController" bundle:nil];
            addFriend.hidesBottomBarWhenPushed = YES;
            [self.selectedViewController pushViewController:addFriend animated:YES];
            break;
        }
            
        default:
            break;
    }
//    if (indexPath.row == 1) {
//        AddFriendViewController *addFriend = [[AddFriendViewController alloc] initWithNibName:@"AddFriendViewController" bundle:nil];
//        addFriend.hidesBottomBarWhenPushed = YES;
//        [self.selectedViewController pushViewController:addFriend animated:YES];
//    }
     _tableView = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
