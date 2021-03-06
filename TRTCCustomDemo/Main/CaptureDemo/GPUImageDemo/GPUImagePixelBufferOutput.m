//
//  GPUImagePixelBufferOutput.m
//  TRTCCustomDemo
//
//  Created by kaoji on 2020/8/23.
//  Copyright © 2020 kaoji. All rights reserved.
//

#import "GPUImagePixelBufferOutput.h"

@implementation GPUImagePixelBufferOutput
{
   __weak GPUImageVideoCamera *_videoCamera;
}

- (instancetype)initWithVideoCamera:(GPUImageVideoCamera *)camera withImageSize:(CGSize)size {
 
  self = [super initWithImageSize:size resultsInBGRAFormat:YES];
  if (self) {
    _videoCamera = camera;
  }
  return self;
}

#pragma mark - GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];

    [self lockFramebufferForReading];
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    GLubyte *sourceBytes = self.rawBytesForImage;
    NSInteger bytesPerRow = self.bytesPerRowInOutput;

    CVPixelBufferRef pixelBuffer = NULL;
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, sourceBytes, bytesPerRow, nil, nil, nil, &pixelBuffer);
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &videoInfo);
//    CMSampleTimingInfo timingInfo = {0,};
//    timingInfo.duration = kCMTimeInvalid;
//    timingInfo.decodeTimeStamp = kCMTimeInvalid;
//    timingInfo.presentationTimeStamp = frameTime;

    if(self.pixelBufferCallback){
        self.pixelBufferCallback(pixelBuffer);
    }
    
    CFRelease(videoInfo);
    CVPixelBufferRelease(pixelBuffer);
    [self unlockFramebufferAfterReading];
}

//- (NSInteger)nextAvailableTextureIndex;
//{
//    return 0;
//}
//
//- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
//{
//
//}
//
//- (CGSize)maximumOutputSize{
//    return CGSizeZero;
//}
//
//- (void)endProcessing{
//}
//
//- (BOOL)shouldIgnoreUpdatesToThisTarget{
//    return NO;
//}
//
//- (BOOL)enabled{
//    return NO;
//}
//
//- (BOOL)wantsMonochromeInput{
//    return NO;
//}
//
//- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue {
//
//}
//
//
//- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex {
//
//}
//
//
//- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
//
//}
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
}

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer {
 
}

- (BOOL)hasAudioTrack {
  return YES;
}

@end
