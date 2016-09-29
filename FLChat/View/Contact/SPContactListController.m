//
//  SPContactListController.m
//  WXOpenIMSampleDev
//
//  Created by huanglei on 15/4/12.
//  Copyright (c) 2015年 taobao. All rights reserved.
//

#import "SPContactListController.h"

#import <WXOpenIMSDKFMWK/YWFMWK.h>
#import <WXOpenIMSDKFMWK/YWServiceDef.h>
#import <WXOUIModule/YWIndicator.h>

#import "SPKitExample.h"
#import "SPUtil.h"
#import "MJRefresh.h"

#import "AppDelegate.h"
#import "SPContactCell.h"
#import "SPSearchContactViewController.h"
#import "SPContactManager.h"
#import "SPContactRequestListController.h"

#import "SPTribeListViewController.h"
#import "SPSearchTribeViewController.h"
#import "CustomUser.h"
#import "AddFriendViewController.h"

#import "Header_Color.h"

@interface SPContactListController ()
<UITableViewDataSource, UITableViewDelegate>

{
    NSMutableArray *_addArr;
    
    NSMutableArray *_sectionIndexTitles;
    
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) YWFetchedResultsController *fetchedResultsController;

@end

@implementation SPContactListController


#pragma mark - life circle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        // 初始化
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView registerNib:[UINib nibWithNibName:@"SPContactCell" bundle:nil]
         forCellReuseIdentifier:@"ContactCell"];
    self.tableView.separatorColor =[UIColor colorWithWhite:1.f*0xdf/0xff alpha:1.f];
    
    self.tableView.backgroundColor = kBackColor;
    if ([self.tableView respondsToSelector:@selector(setSectionIndexBackgroundColor:)]) {
        self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    }
    

    if (self.mode == SPContactListModeNormal) {
        self.navigationItem.title = @"联系人";
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(searchBarButtonItemPressed:)];
        
        CustomUser *customUser1 = [[CustomUser alloc] initWithName:@"新的朋友" avarUrl:@"" identify:@"add001"];
        CustomUser *customUser2 = [[CustomUser alloc] initWithName:@"群聊" avarUrl:@"" identify:@"add002"];
      
        _addArr = [NSMutableArray array];
        [_addArr insertObject:customUser2 atIndex:0];
        [_addArr insertObject:customUser1 atIndex:0];
        
        _sectionIndexTitles = [NSMutableArray arrayWithArray:[self.fetchedResultsController sectionIndexTitles]];
        
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        //修改搜索框的颜色
        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.backgroundColor = [UIColor clearColor];
        
        NSArray *arr = searchBar.subviews;
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
        UIView *view = [[UIView alloc] initWithFrame:searchBar.frame];
        view.backgroundColor = [UIColor clearColor];
        [searchBar insertSubview:view atIndex:0];

        self.tableView.tableHeaderView = searchBar;
        
        //刷新
        self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            [self.tableView reloadData];
            [self.tableView.mj_header endRefreshing];
        }];
        self.tableView.mj_header.backgroundColor = [UIColor clearColor];
        
    }
    else {
        self.navigationItem.title = @"选择联系人";

        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonItemPressed:)];

        self.navigationItem.rightBarButtonItem = doneButtonItem;
        
        UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonItemPressed:)];

        self.navigationItem.leftBarButtonItem = cancelButtonItem;
        [self.tableView setEditing:YES animated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

//    if (self.presentingViewController) {
//        UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
//                                                                                          target:self
//                                                                                          action:@selector(cancelBarButtonItemPressed:)];
//
//        self.navigationItem.rightBarButtonItem = cancelButtonItem;
//    }

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.mode == SPContactListModeNormal) {
         return self.fetchedResultsController.sections.count+1;
    }
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.mode == SPContactListModeNormal)
    {
        if (section == 0) {
            return _addArr.count;
        }
        else
        {
            id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section-1];
            return [sectionInfo numberOfObjects];
        }
    }
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    SPContactCell *cell= [tableView dequeueReusableCellWithIdentifier:@"ContactCell"
                                                         forIndexPath:indexPath];

    if (self.mode == SPContactListModeNormal)
    {
        if (indexPath.section == 0) {
            CustomUser *customUser = [_addArr objectAtIndex:indexPath.row];
            cell.identifier = customUser.identify;
            UIImage *avatar = [UIImage imageNamed:customUser.avarUrl];
            if (!avatar) {
                avatar = [UIImage imageNamed:@"demo_head_120"];
            }
            
            [cell configureWithAvatar:avatar title:customUser.name subtitle:nil];
            return cell;
        }
    }
    NSIndexPath *custIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section-1];
    
    YWPerson *person = [self.fetchedResultsController objectAtIndexPath:custIndexPath];
    cell.identifier = person.personId;

    __block NSString *displayName = nil;
    __block UIImage *avatar = nil;
    //  SPUtil中包含的功能都是Demo中需要的辅助代码，在你的真实APP中一般都需要替换为你真实的实现。
    [[SPUtil sharedInstance] syncGetCachedProfileIfExists:person completion:^(BOOL aIsSuccess, YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
        displayName = aDisplayName;
        avatar = aAvatarImage;
    }];

    //Am6因为没有图片，所以改了下
//    if (!displayName || avatar == nil ) {
      if (!displayName) {
        displayName = person.personId;

        __weak __typeof(self) weakSelf = self;
        __weak __typeof(cell) weakCell = cell;
        [[SPUtil sharedInstance] asyncGetProfileWithPerson:person
                                                  progress:^(YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
                                                      if (aDisplayName && [weakCell.identifier isEqualToString:aPerson.personId]) {
                                                          NSIndexPath *aIndexPath = [weakSelf.tableView indexPathForCell:weakCell];
                                                          if (!aIndexPath) {
                                                              return ;
                                                          }
                                                          [weakSelf.tableView reloadRowsAtIndexPaths:@[aIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                                                      }
                                                  } completion:^(BOOL aIsSuccess, YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
                                                      if (aDisplayName && [weakCell.identifier isEqualToString:aPerson.personId]) {
                                                          NSIndexPath *aIndexPath = [weakSelf.tableView indexPathForCell:weakCell];
                                                          if (!aIndexPath) {
                                                              return ;
                                                          }
                                                          [weakSelf.tableView reloadRowsAtIndexPaths:@[aIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                                                      }
                                                  }];
    }

    if (!avatar) {
        avatar = [UIImage imageNamed:@"demo_head_120"];
    }
    
    [cell configureWithAvatar:avatar title:displayName subtitle:nil];
    


    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.contentView.backgroundColor = kBackColor;
        header.textLabel.font = [UIFont fontWithName:@"Arial" size:13.0f];
        [header.textLabel setTextColor:[UIColor grayColor]];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.mode == SPContactListModeNormal)
    {
        if (section - 1 >= [[self.fetchedResultsController sectionIndexTitles] count]) {
            return nil;
        }
        return [self.fetchedResultsController sectionIndexTitles][(NSUInteger)section - 1];
    }
    
    if (section >= [[self.fetchedResultsController sectionIndexTitles] count]) {
        return nil;
    }
    return [self.fetchedResultsController sectionIndexTitles][(NSUInteger)section];
   
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return _sectionIndexTitles;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.mode == SPContactListModeNormal)
    {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                
                [self addFriend];
                return;//Am6
            }
            else
            {
                [self gotoTribe];
                return;//Am6
            }
        }
        NSIndexPath *custIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section-1];
        YWPerson *person = [self.fetchedResultsController objectAtIndexPath:custIndexPath];
        
        [[SPKitExample sharedInstance] exampleOpenConversationViewControllerWithPerson:person fromNavigationController:self.navigationController];
    }
    else
    {
        // 取消选中之前已选中的 cell
        NSMutableArray *selectedRows = [[tableView indexPathsForSelectedRows] mutableCopy];
        [selectedRows removeObject:indexPath];
        for (NSIndexPath *indexPath in selectedRows) {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == SPContactListModeMultipleSelection || self.mode == SPContactListModeSingleSelection) {
        return UITableViewCellEditingStyleInsert | UITableViewCellEditingStyleDelete;
    }
    else
    {
        if (indexPath.section == 0) {
            return UITableViewCellEditingStyleNone;
        }
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == SPContactListModeNormal) {
        
        if (indexPath.section == 0) {
            return;
        }
        NSIndexPath *custIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section-1];
        YWPerson *person = [self.fetchedResultsController objectAtIndexPath:custIndexPath];

        __weak typeof(self) weakSelf = self;
        [[[SPKitExample sharedInstance].ywIMKit.IMCore getContactService] removeContact:person withResultBlock:^(NSError *error, NSArray *personArray) {
            if (error == nil) {
                [YWIndicator showTopToastTitle:nil content:@"删除好友成功" userInfo:nil withTimeToDisplay:1.5f andClickBlock:nil];
                [weakSelf.tableView reloadData];
            } else {
                [YWIndicator showTopToastTitle:nil content:@"删除好友失败" userInfo:nil withTimeToDisplay:1.5f andClickBlock:nil];
            }
        }];
    }
}
#pragma mark - Data
- (void)cancelBarButtonItemPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)doneBarButtonItemPressed:(id)sender {
    NSMutableArray *selectedIDs = [NSMutableArray array];
    NSArray *indexPathsForSelectedRows = [self.tableView indexPathsForSelectedRows];
    
    for (NSIndexPath *indexPath in indexPathsForSelectedRows) {
        NSIndexPath *custIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section-1];
        YWPerson *person = [self.fetchedResultsController objectAtIndexPath:custIndexPath];
        NSString *personId = person.personId;
        if (personId) {
            [selectedIDs addObject:personId];
        }
    }

    if ([self.delegate respondsToSelector:@selector(contactListController:didSelectPersonIDs:)]) {
        [self.delegate contactListController:self didSelectPersonIDs:[selectedIDs copy]];
    }

    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)searchBarButtonItemPressed:(id)sender {
    
    AddFriendViewController *controller = [[AddFriendViewController alloc] init];
    [controller setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - 好友操作
- (void)addFriend
{
    SPContactRequestListController *controller = [[SPContactRequestListController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}
#pragma mark - 群聊
- (void)gotoTribe
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Tribe" bundle:nil];
    SPTribeListViewController *trible = [storyboard instantiateViewControllerWithIdentifier:@"SPTribeListViewController"];
    [self.navigationController pushViewController:trible animated:YES];
    
}
#pragma mark - FRC
- (YWFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController == nil) {
        YWIMCore *imcore = [SPKitExample sharedInstance].ywIMKit.IMCore;
        _fetchedResultsController = [[imcore getContactService] fetchedResultsControllerWithListMode:YWContactListModeAlphabetic imCore:imcore];
        
        __weak typeof(self) weakSelf = self;
        [_fetchedResultsController setDidChangeContentBlock:^{
            [weakSelf.tableView reloadData];
        }];
        
        [_fetchedResultsController setDidResetContentBlock:^{
            [weakSelf.tableView reloadData];
        }];
    }
    return _fetchedResultsController;
}

@end
