//
//  SPQRCodeReaderViewController.m
//  WXOpenIMSampleDev
//
//  Created by Jai Chen on 15/10/26.
//  Copyright © 2015年 taobao. All rights reserved.
//

#import "SPQRCodeReaderViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface SPQRCodeReaderViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (weak, nonatomic) IBOutlet UIView *animationContentView;
@property (weak, nonatomic) IBOutlet UIImageView *animationImageView;

@end

@implementation SPQRCodeReaderViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.navigationItem.title = @"扫一扫";

    if (![[self class] isAvailable]) {
        return;
    }

    [self setupAVComponents];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self startScanning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self stopScanning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.captureVideoPreviewLayer.frame = self.view.bounds;
}

- (void)setupAVComponents {

    NSError *error = nil;

    // Input
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!deviceInput) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }

    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session addInput:deviceInput];
    self.captureSession = session;

    // Output
    AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [session addOutput:metadataOutput];

    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("com.openimdemo.qrcode", NULL);
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [metadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];

    // Preview
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [videoPreviewLayer setFrame:self.view.frame];
    [self.view.layer insertSublayer:videoPreviewLayer atIndex:0];
    self.captureVideoPreviewLayer = videoPreviewLayer;
}


- (void)startScanning
{
    if (![self.captureSession isRunning]) {
        [self.captureSession startRunning];
        [self startScanningAnimation];
    }
}

- (void)stopScanning
{
    if ([self.captureSession isRunning]) {
        [self.captureSession stopRunning];
        [self stopScanningAnimation];
    }
}

- (void)startScanningAnimation {
    CGFloat height = CGRectGetHeight(self.animationImageView.frame);
    CABasicAnimation * animation =[CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    animation.duration = 2.0;
    animation.fromValue = [NSNumber numberWithFloat:-height];
    animation.toValue = [NSNumber numberWithFloat:height];
    animation.repeatCount = HUGE_VALF;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.animationImageView.layer addAnimation:animation forKey:@"transform.translation.y"];

    self.animationImageView.hidden = NO;
}

- (void)stopScanningAnimation {
    self.animationImageView.hidden = YES;

    [self.animationImageView.layer removeAllAnimations];
}

- (AVAudioPlayer *)audioPlayer {
    if (!_audioPlayer) {
        NSString *beepFilePath = [[NSBundle mainBundle] pathForResource:@"qrcode_scanner_beep" ofType:@"mp3"];
        NSURL *beepURL = [NSURL URLWithString:beepFilePath];

//        NSError *error = nil;
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:NULL];
        [_audioPlayer prepareToPlay];
    }
    return _audioPlayer;
}

#pragma mark - Checking the Reader Availabilities

+ (BOOL)isAvailable
{
    @autoreleasepool {
        if ([[UIDevice currentDevice].systemVersion compare:@"7.0"] == NSOrderedAscending) {
            return NO;
        }

        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        if (!captureDevice) {
            return NO;
        }

        NSError *error;
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];

        if (!deviceInput || error) {
            return NO;
        }
        
        return YES;
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    for (AVMetadataObject *object in metadataObjects) {
        if ([object isKindOfClass:[AVMetadataMachineReadableCodeObject class]]
            && [object.type isEqualToString:AVMetadataObjectTypeQRCode]) {

            [self stopScanning];

            NSString *resultContent = [(AVMetadataMachineReadableCodeObject *) object stringValue];
            if ([self.delegate respondsToSelector:@selector(qrcodeReaderViewController:didGetResult:)]) {
                __weak __typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate qrcodeReaderViewController:weakSelf
                                                     didGetResult:resultContent];
                });
            }

            [self.audioPlayer play];
            break;
        }
    }
}
@end
