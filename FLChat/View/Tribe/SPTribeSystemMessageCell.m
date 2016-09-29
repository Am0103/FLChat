//
//  SPTribeSystemMessageCell.m
//  WXOpenIMSampleDev
//
//  Created by Jai Chen on 15/10/21.
//  Copyright © 2015年 taobao. All rights reserved.
//

#import "SPTribeSystemMessageCell.h"
#import <WXOpenIMSDKFMWK/YWIMCore.h>
#import <WXOpenIMSDKFMWK/IYWMessage.h>
#import <WXOpenIMSDKFMWK/YWPerson.h>
#import <WXOpenIMSDKFMWK/IYWTribeServiceDef.h>
#import "SPUtil.h"

@interface SPTribeSystemMessageCell ()
@property (weak, nonatomic) IBOutlet UIView *contentBackgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *tribeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusInfoLabel;
@property (weak, nonatomic) IBOutlet UIView *operationsContentView;
@property (weak, nonatomic) IBOutlet UIImageView *separator;

@property (weak) id<IYWMessage> message;

@end

@implementation SPTribeSystemMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.contentBackgroundView.layer.cornerRadius = 6.0f;
    self.contentBackgroundView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = CGRectGetWidth(self.avatarImageView.frame) * 0.5;
    self.avatarImageView.clipsToBounds = YES;
}

- (void)configureWithMessage:(id<IYWMessage>)message {

    self.message = message;

    YWMessageBodyTribeSystem *body = (YWMessageBodyTribeSystem *)[message messageBody];

    NSDictionary *userInfo = body.userInfo;
    NSString *tribeName = userInfo[YWTribeServiceKeyTribeName];
    YWMessageBodyTribeSystemStatus status = (YWMessageBodyTribeSystemStatus)[userInfo[YWTribeServiceKeyStatus] unsignedIntegerValue];
//    YWMessageBodyTribeSystemType type = body.tribeSystemType;

    self.tribeNameLabel.text = tribeName ?: @"";
    
    UIImage *avatar = nil;
    if ([userInfo[YWTribeServiceKeyTribeType] integerValue] == YWTribeTypeMultipleChat) {
        avatar = [UIImage imageNamed:@"demo_discussion"];
    }
    else {
        avatar = [UIImage imageNamed:@"demo_group_120"];
    }
    self.avatarImageView.image = avatar;

    if (status == YWMessageBodyTribeSystemStatusWait2BProcess) {
        self.operationsContentView.hidden = NO;
        self.statusInfoLabel.hidden = YES;
        self.separator.hidden = NO;
    }
    else if (status == YWMessageBodyTribeSystemStatusDefault) {
        self.operationsContentView.hidden = YES;
        self.statusInfoLabel.hidden = YES;
        self.separator.hidden = YES;
    }
    else {
        self.operationsContentView.hidden = YES;
        self.statusInfoLabel.hidden = NO;
        self.separator.hidden = NO;

        NSString *statusInfo = nil;
        switch ((YWMessageBodyTribeSystemStatus)status) {
            case YWMessageBodyTribeSystemStatusAccepted:
                statusInfo = @"已同意";
                break;
            case YWMessageBodyTribeSystemStatusRejected:
                statusInfo = @"已拒绝";
                break;
            case YWMessageBodyTribeSystemStatusIgnored:
                statusInfo = @"已忽略";
                break;
            default:
                break;
        }

        self.statusInfoLabel.text = statusInfo;
    }

    NSString *typeDescription = body.contentDescription;
    self.typeDescriptionLabel.text = typeDescription;


    YWPerson *person = [message messageFromPerson];
    if ([typeDescription rangeOfString:person.personId].location != NSNotFound) {
        __block NSString *personDisplayName = nil;
        [[SPUtil sharedInstance] syncGetCachedProfileIfExists:person
                                                   completion:^(BOOL aIsSuccess, YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
                                                       personDisplayName = aDisplayName;
                                                   }];
        if (personDisplayName) {
            NSString *finalDescription = [typeDescription stringByReplacingOccurrencesOfString:person.personId withString:personDisplayName];
            self.typeDescriptionLabel.text = finalDescription;
        }
        else {
            __weak __typeof(self) weakSelf = self;
            NSString *messsageId = [message messageId];

            void(^getProfileHandler)(BOOL aIsSuccess, YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) = ^(BOOL aIsSuccess, YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
                if (aDisplayName && [[weakSelf.message messageId] isEqualToString:messsageId]) {
                    NSString *finalDescription = [typeDescription stringByReplacingOccurrencesOfString:person.personId withString:aDisplayName];
                    weakSelf.typeDescriptionLabel.text = finalDescription;
                }
            };
            [[SPUtil sharedInstance] asyncGetProfileWithPerson:person
                                                      progress:^(YWPerson *aPerson, NSString *aDisplayName, UIImage *aAvatarImage) {
                                                          getProfileHandler(YES, aPerson, aDisplayName, aAvatarImage);
                                                      }
                                                    completion:getProfileHandler];
        }
    }
}

- (IBAction)acceptButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tribeInvitationCellWantsAccept:)]) {
        [self.delegate tribeInvitationCellWantsAccept:self];
    }
}
- (IBAction)ignoreButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tribeInvitationCellWantsIgnore:)]) {
        [self.delegate tribeInvitationCellWantsIgnore:self];
    }
}

@end
