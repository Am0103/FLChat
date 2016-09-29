//
//  SPTribeSystemMessageCell.h
//  WXOpenIMSampleDev
//
//  Created by Jai Chen on 15/10/21.
//  Copyright © 2015年 taobao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WXOpenIMSDKFMWK/YWMessageBodyTribeSystem.h>

@class SPTribeSystemMessageCell;
@protocol SPTribeSystemMessageCellDelegate <NSObject>
- (void)tribeInvitationCellWantsAccept:(SPTribeSystemMessageCell *)cell;
- (void)tribeInvitationCellWantsIgnore:(SPTribeSystemMessageCell *)cell;
@end

@interface SPTribeSystemMessageCell : UITableViewCell

@property (weak, nonatomic) id<SPTribeSystemMessageCellDelegate> delegate;

- (void)configureWithMessage:(id<IYWMessage>)body;

@end
