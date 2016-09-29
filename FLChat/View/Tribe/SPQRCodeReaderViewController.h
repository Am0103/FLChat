//
//  SPQRCodeReaderViewController.h
//  WXOpenIMSampleDev
//
//  Created by Jai Chen on 15/10/26.
//  Copyright © 2015年 taobao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPQRCodeReaderViewController;
@protocol SPQRCodeReaderViewControllerDelegate <NSObject>
- (void)qrcodeReaderViewController:(SPQRCodeReaderViewController *)controller
                      didGetResult:(NSString *)result;
@end

@interface SPQRCodeReaderViewController : UIViewController

+ (BOOL)isAvailable;

- (void)startScanning;
- (void)stopScanning;

@property (nonatomic, weak) id<SPQRCodeReaderViewControllerDelegate> delegate;

@end
