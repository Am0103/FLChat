//
//  LoginViewController.m
//  FLChat
//
//  Created by FL on 16/9/9.
//  Copyright © 2016年 zhigeng. All rights reserved.
//

#import "SPLoginViewController.h"
//#import "SPUtil.h"
#import "SPKitExample.h"

#import "SPTabBarViewController.h"
@interface SPLoginViewController ()

@property (nonatomic, weak) UINavigationController *weakDetailNavigationController;

@property (strong, nonatomic) IBOutlet UITextField *textFieldUserID;
@property (strong, nonatomic) IBOutlet UITextField *textFieldPassword;


@end

@implementation SPLoginViewController

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}
- (IBAction)actionLogin:(id)sender{
    
    [self.view endEditing:YES];
    
    [SPLoginViewController setLastUserID:self.textFieldUserID.text];
    [SPLoginViewController setLastPassword:self.textFieldPassword.text];
    
    [self _tryLogin];
}

- (void)_tryLogin
{
    
//    [[SPKitExample sharedInstance] callThisBeforeISVAccountLogout];
    
    //应用登陆成功后，调用SDK
    //23451637  6b174312e826d39da461c4177dffdac3
    // {"userid":"fltest1","password":"123456"}  test1 fltest1 xiaolinzi xiaozhuzhu wangyao
    //ez js vn
    [[SPKitExample sharedInstance] callThisAfterISVAccountLoginSuccessWithYWLoginId:self.textFieldUserID.text passWord:self.textFieldPassword.text preloginedBlock:^{
          // 可以显示会话列表页面
    } successBlock:^{
        //  到这里已经完成SDK接入并登录成功，你可以通过exampleMakeConversationListControllerWithSelectItemBlock获得会话列表
        /// 可以显示会话列表页面
        
//        YWConversationViewController *convController = [[SPKitExample sharedInstance] exampleMakeConversationListControllerWithSelectItemBlock:^(YWConversation *aConversation) {
//            
//        }];
//        [self.navigationController pushViewController:convController animated:YES];
        
        [self pushMainControllerAnimated:YES];
    } failedBlock:^(NSError *aError) {
        if (aError.code == YWLoginErrorCodePasswordError || aError.code == YWLoginErrorCodePasswordInvalid || aError.code == YWLoginErrorCodeUserNotExsit) {
            /// 可以显示错误提示
            [[SPKitExample sharedInstance] callThisBeforeISVAccountLogout];
        }
    }];
    
}

- (void)pushMainControllerAnimated:(BOOL)aAnimated
{
    if ([self.view.window.rootViewController isKindOfClass:[SPTabBarViewController class]]) {
        /// 已经进入主页面
        return;
    }
    
    SPTabBarViewController *tabController = [[SPTabBarViewController alloc] init];
    tabController.view.frame = self.view.window.bounds;
    [UIView transitionWithView:self.view.window
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.view.window.rootViewController = tabController;
                    }
                    completion:nil];
}

//
//- (void)_presentSplitControllerAnimated:(BOOL)aAnimated
//{
//    if ([self.view.window.rootViewController isKindOfClass:[UISplitViewController class]]) {
//        /// 已经进入主页面
//        return;
//    }
//    
//    UISplitViewController *splitController = [[UISplitViewController alloc] init];
//    
//    if ([splitController respondsToSelector:@selector(setPreferredDisplayMode:)]) {
//        [splitController setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
//    }
//    
//    /// 各个页面
//    
//    UINavigationController *masterController = nil, *detailController = nil;
//    
//    {
//        /// 消息列表页面
//        
//        UIViewController *viewController = [[UIViewController alloc] init];
//        [viewController.view setBackgroundColor:[UIColor whiteColor]];
//        UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:viewController];
//        
//        detailController = nvc;
//    }
//    
//    
//    
//    
//    {
//        /// 会话列表页面
//        __weak typeof(self) weakSelf = self;
//        self.weakDetailNavigationController = detailController;
//        
//        YWConversationListViewController *conversationListController = [[SPKitExample sharedInstance] exampleMakeConversationListControllerWithSelectItemBlock:^(YWConversation *aConversation) {
//            
//            if ([weakSelf.weakDetailNavigationController.viewControllers.lastObject isKindOfClass:[YWConversationViewController class]]) {
//                YWConversationViewController *oldConvController = weakSelf.weakDetailNavigationController.viewControllers.lastObject;
//                if ([oldConvController.conversation.conversationId isEqualToString:aConversation.conversationId]) {
//                    return;
//                }
//            }
//            
//            
//            YWConversationViewController *convController = [[SPKitExample sharedInstance] exampleMakeConversationViewControllerWithConversation:aConversation];
//            if (convController) {
//                [weakSelf.weakDetailNavigationController popToRootViewControllerAnimated:NO];
//                [weakSelf.weakDetailNavigationController pushViewController:convController animated:NO];
//                
//                /// 关闭按钮
//                UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(actionCloseiPad:)];
//                [convController.navigationItem setLeftBarButtonItem:closeItem];
//            }
//        }];
//        
//        masterController = [[UINavigationController alloc] initWithRootViewController:conversationListController];
//        
//        /// 注销按钮
//        UIBarButtonItem *logoutItem = [[UIBarButtonItem alloc] initWithTitle:@"注销" style:UIBarButtonItemStylePlain target:self action:@selector(actionLogoutiPad:)];
//        [conversationListController.navigationItem setLeftBarButtonItem:logoutItem];
//    }
//    
//    [splitController setViewControllers:@[masterController, detailController]];
//    
//    splitController.view.frame = self.view.window.bounds;
//    [UIView transitionWithView:self.view.window
//                      duration:0.25
//                       options:UIViewAnimationOptionTransitionCrossDissolve
//                    animations:^{
//                        self.view.window.rootViewController = splitController;
//                    }
//                    completion:nil];
//}
//
//- (void)_pushMainControllerAnimated:(BOOL)aAnimated
//{
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//        [self _presentSplitControllerAnimated:aAnimated];
//    } else {
////        if ([self.view.window.rootViewController isKindOfClass:[SPTabBarViewController class]]) {
////            /// 已经进入主页面
////            return;
////        }
////        
////        SPTabBarViewController *tabController = [[SPTabBarViewController alloc] init];
////        tabController.view.frame = self.view.window.bounds;
////        [UIView transitionWithView:self.view.window
////                          duration:0.25
////                           options:UIViewAnimationOptionTransitionCrossDissolve
////                        animations:^{
////                            self.view.window.rootViewController = tabController;
////                        }
////                        completion:nil];
//    }
//}
//- (void)_tryLogin
//{
//    __weak typeof(self) weakSelf = self;
//    
//    [[SPUtil sharedInstance] setWaitingIndicatorShown:YES withKey:self.description];
//    
//    //这里先进行应用的登录
//    
//    //应用登陆成功后，登录IMSDK
//    [[SPKitExample sharedInstance] callThisAfterISVAccountLoginSuccessWithYWLoginId:self.textFieldUserID.text
//                                                                           passWord:self.textFieldPassword.text
//                                                                    preloginedBlock:^{
//                                                                        [[SPUtil sharedInstance] setWaitingIndicatorShown:NO withKey:weakSelf.description];
//                                                                        [weakSelf _pushMainControllerAnimated:YES];
//                                                                    } successBlock:^{
//                                                                        
//                                                                        //  到这里已经完成SDK接入并登录成功，你可以通过exampleMakeConversationListControllerWithSelectItemBlock获得会话列表
//                                                                        [[SPUtil sharedInstance] setWaitingIndicatorShown:NO withKey:weakSelf.description];
//                                                                        
//                                                                        [weakSelf _pushMainControllerAnimated:YES];
//#if DEBUG
//                                                                        // 自定义轨迹参数均为透传
//                                                                        //                                                                        [YWExtensionServiceFromProtocol(IYWExtensionForCustomerService) updateExtraInfoWithExtraUI:@"透传内容" andExtraParam:@"透传内容"];
//#endif
//                                                                    } failedBlock:^(NSError *aError) {
//                                                                        [[SPUtil sharedInstance] setWaitingIndicatorShown:NO withKey:weakSelf.description];
//                                                                        
//                                                                        if (aError.code == YWLoginErrorCodePasswordError || aError.code == YWLoginErrorCodePasswordInvalid || aError.code == YWLoginErrorCodeUserNotExsit) {
//                                                                            
//                                                                            dispatch_async(dispatch_get_main_queue(), ^{
//                                                                                UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"登录失败, 可以使用游客登录。\n（如在调试，请确认AppKey、帐号、密码是否正确。）" delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"游客登录", nil];
//                                                                                [as showInView:weakSelf.view];
//                                                                            });
//                                                                        }
//                                                                        
//                                                                    }];
//}
//


#pragma mark - properties

+ (NSString *)lastUserID
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUserID"];
}

+ (void)setLastUserID:(NSString *)lastUserID
{
    [[NSUserDefaults standardUserDefaults] setObject:lastUserID forKey:@"lastUserID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)lastPassword
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"lastPassword"];
}

+ (void)setLastPassword:(NSString *)lastPassword
{
    [[NSUserDefaults standardUserDefaults] setObject:lastPassword forKey:@"lastPassword"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([SPKitExample sharedInstance].lastConnectionStatus == YWIMConnectionStatusForceLogout || [SPKitExample sharedInstance].lastConnectionStatus == YWIMConnectionStatusMannualLogout) {
        /// 被踢或者登出后，不要自动登录
       
    }
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
