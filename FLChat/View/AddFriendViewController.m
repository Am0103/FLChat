//
//  AddFriendViewController.m
//  FLChat
//
//  Created by FL on 16/9/22.
//  Copyright © 2016年 zhigeng. All rights reserved.
//
#import "Header_Color.h"
#import "AddFriendViewController.h"
#import "SPSearchContactViewController.h"
#import "SPSearchTribeViewController.h"

@interface AddFriendViewController ()<UISearchBarDelegate>

{
    int _selectIndex;
    UIViewController *_selectedViewController;
}

@property (strong, nonatomic) IBOutlet UIView *leftLine;
@property (strong, nonatomic) IBOutlet UIView *rightLine;

@property (strong, nonatomic) IBOutlet UIButton *AddFriend;
@property (strong, nonatomic) IBOutlet UIButton *AddTrible;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *searchBarConstaint;
@property (strong, nonatomic) IBOutlet UIView *selectView;
@property (strong, nonatomic) IBOutlet UIView *topLine;
@property (strong, nonatomic) IBOutlet UIView *bottomLine;

@end

@implementation AddFriendViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = kBackColor;
    self.navigationItem.title = @"添加";
  
    [self setLeftColor];
    [self setHasCentredPlaceholder:self.searchBar];
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    
    //设置光标颜色
    self.searchBar.tintColor = kGolbalThemeColor;
    //去掉阴影框
    self.searchBar.backgroundImage = [self createImageWithColor:[UIColor whiteColor]];
    self.searchBar.delegate = self;
}
- (UIImage *)createImageWithColor: (UIColor *) color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}
//文字和搜索图标 在左边
- (void)setHasCentredPlaceholder:(UISearchBar *)searchBar
{

    SEL centerSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@", @"setCenter", @"Placeholder:"]);
    if ([self.searchBar respondsToSelector:centerSelector])
    {
        NSMethodSignature *signature = [[UISearchBar class] instanceMethodSignatureForSelector:centerSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self.searchBar];
        [invocation setSelector:centerSelector];
        [invocation setArgument:&searchBar atIndex:2];
        [invocation invoke];
    }
}
#pragma mark -searchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [UIView animateWithDuration:0.25 animations:^{
      
        self.topLine.hidden = YES;
        self.bottomLine.hidden = YES;
        self.selectView.hidden = YES;
        NSLog(@"%@",self.searchBarConstaint);
        
        self.searchBarConstaint.constant = 20;
        [self.searchBar updateConstraints];
        
        [_searchBar setShowsCancelButton:YES];//显示右侧取消按钮
        //改变searchBar样式 中间为白色
        self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
        
        self.view.backgroundColor = [UIColor whiteColor];

        if (_selectedViewController) {
            
            if ([_selectedViewController isKindOfClass:[SPSearchContactViewController class]] && _selectIndex == 0) {
                _selectedViewController.view.hidden = NO;
                [self.navigationController setNavigationBarHidden:YES];
                
                return ;
            }
            
            if ([_selectedViewController isKindOfClass:[SPSearchTribeViewController class]] && _selectIndex == 1) {
                _selectedViewController.view.hidden = NO;
                [self.navigationController setNavigationBarHidden:YES];
                
                return;
            }
            [_selectedViewController.view removeFromSuperview];
        }
        
        if (_selectIndex == 0) {
            UIViewController *searchContact = [[SPSearchContactViewController alloc] initWithNibName:@"SPSearchContactViewController" bundle:nil];
            _selectedViewController = searchContact;
            [self addChildViewController:searchContact];
        }
        else
        {
            UIStoryboard *tribeSb = [UIStoryboard storyboardWithName:@"Tribe" bundle:nil];
            UIViewController *tribe = [tribeSb instantiateViewControllerWithIdentifier:@"SPSearchTribeViewController"];
            _selectedViewController = tribe;
            [self addChildViewController:tribe];
        }
       
        [self.view insertSubview:_selectedViewController.view belowSubview:searchBar];
        [self.navigationController setNavigationBarHidden:YES];
       
    }];
    
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
     if (_selectIndex == 0) {
        SPSearchContactViewController *sv = (SPSearchContactViewController *)_selectedViewController;
        [sv onSearch:searchText];
     }
     else{
         SPSearchTribeViewController *sv = (SPSearchTribeViewController *)_selectedViewController;
         [sv onSearch:searchText];
     }
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [UIView animateWithDuration:0.25 animations:^{
        [self.view endEditing:YES];
        
        self.topLine.hidden = NO;
        self.bottomLine.hidden = NO;
        self.selectView.hidden = NO;
        self.searchBarConstaint.constant = 144;
        self.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.view.backgroundColor = kBackColor;
        [self.searchBar updateConstraints];
        [_searchBar setShowsCancelButton:NO];//显示右侧取消按钮
        [self.navigationController setNavigationBarHidden:NO];
        [_selectedViewController.view removeFromSuperview];
        _selectedViewController = nil;
        self.searchBar.text = @"";
        
    }];
}

- (void)setLeftColor
{
    _selectIndex = 0;
    
    [self.AddTrible setTitleColor:[UIColor blackColor]forState:UIControlStateNormal];
    self.rightLine.hidden = YES;
    
    [self.AddFriend setTitleColor:kGolbalThemeColor forState:UIControlStateNormal];
    self.leftLine.hidden = NO;
}
- (IBAction)AddFriendAction:(id)sender {
    
    [self setLeftColor];
}

- (IBAction)AddTribleAction:(id)sender {
    
     _selectIndex = 1;
    
    [self.AddTrible setTitleColor:kGolbalThemeColor forState:UIControlStateNormal];
    self.rightLine.hidden = NO;
    
    [self.AddFriend setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.leftLine.hidden = YES;
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
