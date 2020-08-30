//
//  AVCaptureManager.h
//  TRTCDemo
//
//  Created by kaoji on 2020/6/30.
//  Copyright © 2020 rushanting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

//自定义采集输出代理
@protocol KCaptureDelegate <NSObject>

//视频输出
- (void)kCaptureVideoOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

@optional

//音频输出
- (void)kCaptureAudioOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

//已丢弃的延迟采样缓冲区的通知
- (void)kCaptureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

@end

@interface AVCaptureManager : NSObject
@property(nonatomic,assign)id<KCaptureDelegate>delegate;
@property(nonatomic,assign)BOOL isFontDevice;
@property (nonatomic, assign) int captureWidth;
@property (nonatomic, assign) int captureHeight;
//开关采集
-(void)startCapture;
-(void)stopCapture;

//切换摄像头
-(void)switchCamera:(BOOL)isFront;

@end

NS_ASSUME_NONNULL_END
