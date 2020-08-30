//
//  AVCaptureManager.m
//  TRTCDemo
//
//  Created by kaoji on 2020/6/30.
//  Copyright © 2020 rushanting. All rights reserved.
//

#import "AVCaptureManager.h"
#import <UIKit/UIKit.h>

@interface AVCaptureManager ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession           *session;
@property (nonatomic, strong) AVCaptureDeviceInput       *input;//当前
@property (nonatomic, strong) AVCaptureDeviceInput       *frontCameraInput;//前置
@property (nonatomic, strong) AVCaptureDeviceInput       *backCameraInput;//后置
@property (nonatomic, strong) AVCaptureVideoDataOutput   *videoDataOutput;
@property (strong, nonatomic) AVCaptureConnection * captureConnection;

@end

@implementation AVCaptureManager
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}
-(void)setup{
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    //session.usesApplicationAudioSession = true;
    //设置分辨率
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    //添加输入设备 前置输入
    _input = self.frontCameraInput;
    [session addInput:_input];
    
    
    // Conigure and add output
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    //AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [session addOutput:videoDataOutput];
    //[session addOutput:audioDataOutput];
    
    videoDataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    //使用多线程接收视频音频
    dispatch_queue_t videoQueue = dispatch_queue_create("videoQueue", NULL);

    [videoDataOutput setSampleBufferDelegate:self queue:videoQueue];
    
    self.session           = session;
    self.videoDataOutput   = videoDataOutput;
    
    [self setPortrait];
}

#pragma mark - Public
-(void)startCapture{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self setup];
        [self.session startRunning];
    });
   
}

-(void)stopCapture{
    
    if([self.session isRunning]){
        [self.session stopRunning];
        
        AVCaptureInput* input = [self.session.inputs objectAtIndex:0];
        [self.session removeInput:input];
        
        AVCaptureVideoDataOutput* output = (AVCaptureVideoDataOutput*)[self.session.outputs objectAtIndex:0];
        [self.session removeOutput:output];
        
        self.session = nil;
    }
    
}

#pragma mark - AVCaptureDelegate
- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if ([output isKindOfClass:[AVCaptureVideoDataOutput class]] == YES) {
        NSLog(@"Error: Drop video frame");
    }else {
        NSLog(@"Error: Drop audio frame");
    }
    
    if ([self.delegate respondsToSelector:@selector(kCaptureOutput:didDropSampleBuffer:fromConnection:)]) {
        [self.delegate kCaptureOutput:output didDropSampleBuffer:sampleBuffer fromConnection:connection];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog( @"sample buffer is not ready. Skipping sample" );
        return;
    }
    
    if ([output isKindOfClass:[AVCaptureVideoDataOutput class]] == YES) {
        
        CVPixelBufferRef pix  = CMSampleBufferGetImageBuffer(sampleBuffer);
        self.captureWidth  = (int)CVPixelBufferGetWidth(pix);
        self.captureHeight = (int)CVPixelBufferGetHeight(pix);
        
        if ([self.delegate respondsToSelector:@selector(kCaptureVideoOutput:didOutputSampleBuffer:fromConnection:)]) {
            [self.delegate kCaptureVideoOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
        
        
    }else if ([output isKindOfClass:[AVCaptureAudioDataOutput class]] == YES) {
        if ([self.delegate respondsToSelector:@selector(kCaptureAudioOutput:didOutputSampleBuffer:fromConnection:)]) {
            [self.delegate kCaptureAudioOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
    
}

//切换摄像头方向
- (void)switchCamera:(BOOL)isFront {
    if (isFront) {
        [self.session stopRunning];
        [self.session removeInput:self.backCameraInput];
        if ([self.session canAddInput:self.frontCameraInput]) {
            [self.session addInput:self.frontCameraInput];
            [self.session startRunning];
        }
        _input = self.frontCameraInput;

    } else {
        [self.session stopRunning];
        [self.session removeInput:self.frontCameraInput];
        if ([self.session canAddInput:self.backCameraInput]) {
            [self.session addInput:self.backCameraInput];
            [self.session startRunning];
        }
        _input = self.backCameraInput;
    }
    [self setPortrait];
}

-(void)setPortrait{
    //解决输出镜像问题
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in [self.videoDataOutput connections] )
    {
        NSLog(@"%@", connection);
        for ( AVCaptureInputPort *port in [connection inputPorts] )
        {
            NSLog(@"%@", port);
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
            }
        }
        connection.videoMirrored = YES;
    }

    if([videoConnection isVideoOrientationSupported]) // **Here it is, its always false**
    {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
}

//摄像头输入
- (AVCaptureDeviceInput *)backCameraInput {
    if (_backCameraInput == nil) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput  alloc] initWithDevice:[self cameroWithPosition:AVCaptureDevicePositionBack] error:&error];
        if (error) {
            NSLog(@"后置摄像头获取失败");
        }
    }
    self.isFontDevice = NO;
    return _backCameraInput;
}

- (AVCaptureDeviceInput *)frontCameraInput {
    if (_frontCameraInput == nil) {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameroWithPosition:AVCaptureDevicePositionFront] error:&error];
        if (error) {
            NSLog(@"前置摄像头获取失败");
        }
    }
    self.isFontDevice = YES;
    return _frontCameraInput;
}

//获取可用的摄像头
- (AVCaptureDevice *)cameroWithPosition:(AVCaptureDevicePosition)position{

    if (@available(iOS 10.0, *)) {
        AVCaptureDeviceDiscoverySession *dissession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDuoCamera,AVCaptureDeviceTypeBuiltInTelephotoCamera,AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
        for (AVCaptureDevice *device in dissession.devices) {
            if ([device position] == position ) {
                return device;
            }
        }
    } else {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device position] == position) {
                return device;
            }
        }
    }
    return nil;
}

@end
