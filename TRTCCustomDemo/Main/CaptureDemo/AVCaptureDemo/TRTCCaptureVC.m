//
//  TRTCCaptureVC.m
//  TRTCCustomDemo
//
//  Created by kaoji on 2020/8/22.
//  Copyright © 2020 kaoji. All rights reserved.
//

#import "TRTCCaptureVC.h"
#import "GLRenderView.h"
#import "AVCaptureManager.h"
#import "CoreImageFilter.h"

@interface TRTCCaptureVC ()<KCaptureDelegate>
@property (nonatomic, strong) UISegmentedControl *filterSegment;//是否开启滤镜
@property (nonatomic, strong) GLRenderView *glRenderView;
@property (nonatomic, assign) BOOL isFilter;//是否开启滤镜
@property (nonatomic, strong) CoreImageFilter *filter;//滤镜
@property (nonatomic, strong) AVCaptureManager *captureManager;
@end

@implementation TRTCCaptureVC

-(CoreImageFilter *)filter{
    if(!_filter){
        _filter = [[CoreImageFilter alloc] init];
    }
    return _filter;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    [self startTRTC];
}

-(void)startTRTC{
    
    //开启麦克风采集
    [self.trtc startLocalAudio];
    
    //进房
    [self.trtc enterRoom:[self roomParam] appScene:TRTCAppSceneLIVE];
    
    //开启视频自定义采集
    [self.trtc enableCustomVideoCapture:YES];
    
    //自定义渲染画面
    _glRenderView = [[GLRenderView alloc] initWithFrame:self.view.frame];
    _glRenderView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view insertSubview:_glRenderView atIndex:0];
    
    //滤镜控制
    _filterSegment = [[UISegmentedControl alloc] initWithItems:@[@"原始",@"滤镜"]];
    _filterSegment.selectedSegmentIndex = 0;
    _filterSegment.tintColor = rgba(15, 168, 45, 1.0);
    [_filterSegment setTitleTextAttributes:@{NSForegroundColorAttributeName:rgba(15, 168, 45, 1.0)} forState:UIControlStateNormal];
    _filterSegment.frame = CGRectMake( self.view.frame.size.width/2 - 75, self.view.frame.size.height - (isBangsDevice ?BOTTOM_LAYOUT_GUIDE:10) - 40, 150, 40);
    [_filterSegment addTarget:self action:@selector(onClickFilter:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_filterSegment];
    
    //开启屏幕采集
    _captureManager = [AVCaptureManager new];
    _captureManager.delegate = self;
    [_captureManager startCapture];
    
}

-(void)onClickFilter:(UISegmentedControl *)segment{
    _isFilter = segment.selectedSegmentIndex;
}

#pragma mark - 父类重写
-(void)onClickBack{
    //页面关闭 退房
    [self.trtc enableCustomVideoCapture:NO];
    [self.captureManager stopCapture];
    [self.trtc stopLocalAudio];
    [self.trtc exitRoom];
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)onClickCamera{
    [self.captureManager switchCamera:!self.captureManager.isFontDevice];
}

#pragma mark - KCaptureDelegate
-(void)kCaptureVideoOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

    //创建TRTCVideoFrame
    TRTCVideoFrame *frame = [[TRTCVideoFrame alloc] init];
    frame.pixelFormat = TRTCVideoPixelFormat_NV12;
    frame.bufferType  = TRTCVideoBufferType_PixelBuffer;
    frame.timestamp   = 0;
    frame.pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //开启滤镜的时候
    if(_isFilter){
        //将buffer 用coreImage添加滤镜得到CIImage
        CIImage *image = [self.filter filterPixelBuffer:frame];
        //将CIImage转回buffer给TRTC
        [_glRenderView.ciContext render:image toCVPixelBuffer:frame.pixelBuffer];
    }
    
    [_glRenderView renderFrame:frame];
   
    //发送给sdk处理
    [[TRTCCloud sharedInstance] sendCustomVideoData:frame];
    
}

@end

