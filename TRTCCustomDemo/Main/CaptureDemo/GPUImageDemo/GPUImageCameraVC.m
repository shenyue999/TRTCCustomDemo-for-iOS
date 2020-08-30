//
//  GPUImageCameraVC.m
//  TRTCCustomDemo
//
//  Created by kaoji on 2020/8/23.
//  Copyright © 2020 kaoji. All rights reserved.
//

#import "GPUImageCameraVC.h"
#import "GLRenderView.h"
#import "AVCaptureManager.h"
#import <GPUImage/GPUImageContext.h>
#import "GPUImageBeautifyFilter.h"
#import "GPUImagePixelBufferOutput.h"


@interface GPUImageCameraVC ()
@property (nonatomic, strong) UISegmentedControl *filterSegment;//是否开启滤镜
@property (nonatomic, strong) GLRenderView *glRenderView;//自定义渲染,openGL
@property (nonatomic, assign) BOOL isFilter;//是否开启滤镜
@property GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (atomic,    strong) GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic, strong) GPUImagePixelBufferOutput *cameraOutput;
@end

@implementation GPUImageCameraVC

-(void)viewDidLoad{
    [super viewDidLoad];
    [self startTRTC];
    [self gpuImagePushInit];
    [self filterChange:self.filterSegment];
}

-(void)startTRTC{
    
    //开启麦克风采集
    [self.trtc startLocalAudio];
    
    //进房
    [self.trtc enterRoom:[self roomParam] appScene:TRTCAppSceneLIVE];
    
    //开启视频自定义采集
    [self.trtc enableCustomVideoCapture:YES];
    
    //显示预览画面方案一
//    _glRenderView = [[GLRenderView alloc] initWithFrame:self.view.frame];
//    _glRenderView.contentMode = UIViewContentModeScaleAspectFit;
//    [self.view insertSubview:_glRenderView atIndex:0];
    
    //显示画面方案二
    _filterView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    _filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [self.view insertSubview:_filterView atIndex:0];
    
    //滤镜控制
    _filterSegment = [[UISegmentedControl alloc] initWithItems:@[@"美颜",@"深褐色",@"素描"]];
    _filterSegment.selectedSegmentIndex = 0;
    _filterSegment.tintColor = rgba(15, 168, 45, 1.0);
    [_filterSegment setTitleTextAttributes:@{NSForegroundColorAttributeName:rgba(15, 168, 45, 1.0)} forState:UIControlStateNormal];
    _filterSegment.frame = CGRectMake( self.view.frame.size.width/2 - 100, self.view.frame.size.height - (isBangsDevice ?BOTTOM_LAYOUT_GUIDE:10) - 40, 200, 40);
    [_filterSegment addTarget:self action:@selector(filterChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_filterSegment];
    
}

#pragma mark -初始化输入视频流
-(void)gpuImagePushInit{
    
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.frameRate = 18;
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.videoCamera.horizontallyMirrorRearFacingCamera = NO;
    [self.videoCamera addTarget:_filterView];
    
    //处理输出数据
    _cameraOutput = [[GPUImagePixelBufferOutput alloc] initWithVideoCamera:self.videoCamera withImageSize:CGSizeMake(720, 1280)];
    __weak typeof(self) weakSelf = self;
    _cameraOutput.pixelBufferCallback = ^(CVPixelBufferRef  _Nullable pixelBufferRef) {
        [weakSelf sendCustomDataToTRTC:pixelBufferRef];
    };
    [self.videoCamera startCameraCapture];
}

-(void)sendCustomDataToTRTC:(CVPixelBufferRef)pixelBufferRef{
    
    TRTCVideoFrame *frame = [[TRTCVideoFrame alloc] init];
    frame.pixelFormat = TRTCVideoPixelFormat_32BGRA;
    frame.bufferType  = TRTCVideoBufferType_PixelBuffer;
    frame.pixelBuffer = pixelBufferRef;
    frame.timestamp = 0;
    [[TRTCCloud sharedInstance] sendCustomVideoData:frame];
    
    [_glRenderView renderFrame:frame];
    
}

#pragma mark -滤镜
-(void)refreshFilter{
    
    switch(self.filterType){
        case FILTER_BEAUTY_TYPE:
            self.filter = [[GPUImageBeautifyFilter alloc] init];
            break;
        case FILTER_SEPIA_TYPE:
            self.filter = [[GPUImageSepiaFilter alloc] init];
            break;
        case FILTER_SKETCH_TYPE:
            self.filter = [[GPUImageSketchFilter alloc] init];
            break;
    }
    [self.videoCamera addTarget:self.filter];
    [self.filter addTarget:self.filterView];
    [self.filter addTarget:self.cameraOutput];
    
}

-(void)filterChange:(UISegmentedControl *)segment{
    
    //滤镜切换 这样操作会闪一下 应该有更好的方式
    self.filterType = segment.selectedSegmentIndex;
    [self.filter removeAllTargets];
    [self.videoCamera removeAllTargets];
    [self refreshFilter];
}

#pragma mark - 父类重写
-(void)onClickBack{
    //页面关闭 退房
    [self.filter removeTarget:self.cameraOutput];
    [self.trtc enableCustomVideoCapture:NO];
    
    if([self.videoCamera.captureSession isRunning]){
        [self.videoCamera stopCameraCapture];
        AVCaptureInput* input = [self.videoCamera.captureSession.inputs objectAtIndex:0];
        [self.videoCamera.captureSession removeInput:input];
        
        AVCaptureVideoDataOutput* output = (AVCaptureVideoDataOutput*)[self.videoCamera.captureSession.outputs objectAtIndex:0];
        [self.videoCamera.captureSession removeOutput:output];
        
    }
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    [self.filter removeAllTargets];
    [self.videoCamera removeAllTargets];
    [self.trtc stopLocalAudio];
    [self.trtc exitRoom];
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)onClickCamera{
    [self.videoCamera rotateCamera];
}

@end
