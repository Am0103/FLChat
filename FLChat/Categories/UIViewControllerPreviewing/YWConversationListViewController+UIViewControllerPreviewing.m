//
//  YWConversationListViewController+UIViewControllerPreviewing.m
//  WXOpenIMSampleDev
//
//  Created by Jai Chen on 16/1/11.
//  Copyright © 2016年 taobao. All rights reserved.
//

#import "YWConversationListViewController+UIViewControllerPreviewing.h"
#import <WXOUIModule/YWUIFMWK.h>
#import <WXOpenIMSDKFMWK/YWFMWK.h>
#import "SPKitExample.h"


@implementation YWConversationListViewController (UIViewControllerPreviewing)

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {

    UISearchDisplayController *searchDisplayController = self.searchDisplayController;
    if (searchDisplayController.isActive) {
        return nil;
    }

    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    if (!indexPath) {
        return nil;
    }
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (!cell) {
        return nil;
    }

    YWConversation *conversation = [[self.kitRef.IMCore getConversationService] objectAtIndexPath:indexPath];
    if (![conversation isKindOfClass:[YWP2PConversation class]] &&
        ![conversation isKindOfClass:[YWTribeConversation class]]) {
        return nil;
    }

    [previewingContext setSourceRect:cell.frame];

    YWConversationViewController *viewController = [[SPKitExample sharedInstance] exampleMakeConversationViewControllerWithConversation:conversation];
    [viewController setMessageInputViewHidden:YES animated:NO];

    return viewController;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    if ([viewControllerToCommit isKindOfClass:[YWConversationViewController class]]) {
        YWConversationViewController *conversationViewController = (YWConversationViewController *)viewControllerToCommit;
        [conversationViewController setMessageInputViewHidden:NO animated:YES];
    }
    [self showViewController:viewControllerToCommit sender:self];
}

@end
