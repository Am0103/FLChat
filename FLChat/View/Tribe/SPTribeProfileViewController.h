//
//  SPTribeProfileViewController.h
//  WXOpenIMSampleDev
//
//  Created by Jai Chen on 15/10/15.
//  Copyright © 2015年 taobao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WXOpenIMSDKFMWK/YWFMWK.h>

@interface SPTribeProfileViewController : UIViewController

@property (nonatomic, strong) YWTribe *tribe;

@property(nonatomic, assign)  BOOL isFromAddFriendVcInSearchTribe;
@end
