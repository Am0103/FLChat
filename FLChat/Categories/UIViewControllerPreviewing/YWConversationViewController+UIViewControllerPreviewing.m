//
//  YWConversationViewController+UIViewControllerPreviewing.m
//  WXOpenIMSampleDev
//
//  Created by Jai Chen on 16/1/25.
//  Copyright © 2016年 taobao. All rights reserved.
//

#import "YWConversationViewController+UIViewControllerPreviewing.h"
#import <WXOUIModule/YWIMKit.h>
#import <WXOpenIMSDKFMWK/YWFMWK.h>
#import <WXOpenIMSDKFMWK/YWConversation.h>

@implementation YWConversationViewController (UIViewControllerPreviewing)

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {

    __weak __typeof(self) weakSelf = self;

    BOOL isMarked = (self.conversation.markedOnTopTime >= 1);
    NSString *titleForMarking = isMarked ? @"取消置顶" : @"置顶";
    UIPreviewAction *actionForMarking = [UIPreviewAction actionWithTitle:titleForMarking style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [weakSelf.conversation markConversationOnTop:!isMarked getError:NULL];
    }];

    UIPreviewAction *actionForDeleting = [UIPreviewAction actionWithTitle:@"删除" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [[weakSelf.kitRef.IMCore getConversationService] removeConversationByConversationId:weakSelf.conversation.conversationId
                                                                                      error:NULL];
    }];

    return @[actionForMarking, actionForDeleting];
}

@end
