//
//  SPSearchTribeViewController.m
//  WXOpenIMSampleDev
//
//  Created by shili.nzy on 15/4/11.
//  Copyright (c) 2015年 taobao. All rights reserved.
//

#import "SPSearchTribeViewController.h"
#import "SPTribeProfileViewController.h"
#import "SPKitExample.h"
#import "SPUtil.h"
#import "SPQRCodeReaderViewController.h"
#import "SPContactCell.h"
#import "Header_Color.h"
@interface SPSearchTribeViewController ()<UITextFieldDelegate, SPQRCodeReaderViewControllerDelegate,UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *searchTextField;

@property (assign, nonatomic) BOOL shouldAutoBeginSearch;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (copy,nonatomic)NSArray *results;
@end

@implementation SPSearchTribeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.tableFooterView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = kBackColor;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"SPContactCell" bundle:nil]
         forCellReuseIdentifier:@"ContactCell"];
    
    if ([SPQRCodeReaderViewController isAvailable]) {
        UIBarButtonItem *qrCodeReaderItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"qrcode_scan_icon"]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(presentQRCodeReaderViewController:)];
        self.navigationItem.rightBarButtonItem = qrCodeReaderItem;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.shouldAutoBeginSearch) {
        self.shouldAutoBeginSearch = NO;
        [self onSearch:nil];
    }
    else {
        if ([self.searchTextField canBecomeFirstResponder]) {
            [self.searchTextField becomeFirstResponder];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.presentingViewController && self.navigationController.viewControllers.firstObject == self) {
        UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:@"关闭"
                                                                          style:UIBarButtonItemStylePlain target:self action:@selector(dismissViewController:)];
        self.navigationItem.leftBarButtonItem = dismissButton;
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.searchTextField endEditing:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.searchTextField endEditing:YES];
}

#pragma mark - Actions
- (void)onSearch:(NSString *)text {
    if( [text length] == 0 ){
        return;
    }
    _searchText = text;
    __weak typeof (self) weakSelf = self;

    [[SPUtil sharedInstance] setWaitingIndicatorShown:YES withKey:self.description];
    [self.ywTribeService requestTribeFromServer:text completion:^(YWTribe *tribe, NSError *error) {
        [[SPUtil sharedInstance] setWaitingIndicatorShown:NO withKey:weakSelf.description];
        if(!error) {
            if (!tribe) {
                self.results = nil;
                [self.tableView reloadData];
            }
            self.results = @[tribe];
            [self.tableView reloadData];
//
        }
        else {
//            [[SPUtil sharedInstance] showNotificationInViewController:weakSelf.navigationController
//                                                                title:@"未找到该群，请确认群帐号后重试"
//                                                             subtitle:nil
//                                                                type:SPMessageNotificationTypeError];
//            self.results = nil;
//            [self.tableView reloadData];
            
            self.results = nil;
            [self.tableView reloadData];
        }
    }];
}

- (void)presentTribeProfileViewControllerWithTribe:(YWTribe *)tribe {
    if (!tribe) {
        return ;
    }
    SPTribeProfileViewController *controller =[self.storyboard instantiateViewControllerWithIdentifier:@"SPTribeProfileViewController"];
    controller.tribe = tribe;
    controller.isFromAddFriendVcInSearchTribe = YES;
    [self.navigationController pushViewController:controller animated:YES];
//    [self.navigationController setViewControllers:@[controller] animated:YES];
}

- (void)presentQRCodeReaderViewController:(id)sender {
    SPQRCodeReaderViewController *qrCodeReaderViewController = [[SPQRCodeReaderViewController alloc] init];
    qrCodeReaderViewController.delegate = self;
    [self.navigationController pushViewController:qrCodeReaderViewController animated:YES];
}

- (IBAction)dismissViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.searchTextField) {
        [self onSearch:nil];
    }
    return YES;
}

#pragma mark - SPQRCodeReaderViewControllerDelegate
- (void)qrcodeReaderViewController:(SPQRCodeReaderViewController *)controller didGetResult:(NSString *)result {
    NSURL *url = [NSURL URLWithString:result];

    if ([url.scheme isEqualToString:@"openimdemo"]) {
        if ([url.path isEqualToString:@"/searchTribe"]) {
            NSString *query = [url.query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            for (NSString *param in [query componentsSeparatedByString:@"&"]) {
                NSArray *elts = [param componentsSeparatedByString:@"="];
                if([elts count] < 2) continue;
                [params setObject:[elts lastObject] forKey:[elts firstObject]];
            }
            if ([params[@"tribeId"] length]) {
                [self.navigationController popToViewController:self animated:YES];
                self.searchTextField.text = params[@"tribeId"];
                self.shouldAutoBeginSearch = YES;
            }
        }
    }
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
    YWTribe *tribe = self.results[indexPath.row];
    
    NSString *name = nil;
    UIImage *avatar = nil;
    
    // 使用服务端的资料
    name = tribe.tribeName;
    if (!name) {
        name = tribe.tribeId;
    }

    if (!avatar) {
        avatar = [UIImage imageNamed:@"demo_head_120"];
    }
    
    
    SPContactCell *cell= [tableView dequeueReusableCellWithIdentifier:@"ContactCell"
                                                         forIndexPath:indexPath];
    [cell configureWithAvatar:avatar title:name subtitle:nil];
    
    
    if ([self.ywTribeService fetchTribeMember:[[YWPerson alloc] initWithPersonId:[[[self ywIMCore] getLoginService] currentLoginedUserId]] inTribe:tribe.tribeId]) {
        
        for (id sub in cell.contentView.subviews) {
            if ([sub isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)sub;
                if ([label.text isEqualToString:@"已加"]) {
                    cell.hidden = NO;
                    return cell;
                }
            }
        }
    
        CGFloat windowWidth = [UIScreen mainScreen].bounds.size.width;
        CGRect accessoryViewFrame = CGRectMake(windowWidth - 60, (cell.frame.size.height - 30)/2, 40, 30);
        UILabel *label = [[UILabel alloc] initWithFrame:accessoryViewFrame];
        label.textColor = [UIColor lightGrayColor];
//        cell.accessoryView = label;
        label.font = [UIFont fontWithName:@"Arial" size:15.0f];
        label.text = @"已加";

//        [label sizeToFit];
        [cell.contentView addSubview:label];
        
    }
    else {
//        cell.accessoryView = nil;
        
        for (id sub in cell.contentView.subviews) {
            if ([sub isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)sub;
                if ([label.text isEqualToString:@"已加"]) {
                    cell.hidden = YES;
                    break;
                }
            }
        }
      
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    YWTribe *tribe = self.results[indexPath.row];
    
    [self presentTribeProfileViewControllerWithTribe:tribe];
}


#pragma makr - 
- (YWIMCore *)ywIMCore {
    return [SPKitExample sharedInstance].ywIMKit.IMCore;
}

- (id<IYWTribeService>)ywTribeService {
    return [[self ywIMCore] getTribeService];
}
@end
