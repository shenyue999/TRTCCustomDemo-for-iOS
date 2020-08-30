//
//  TRTCRenderVC.m
//  TRTCCustomDemo
//
//  Created by kaoji on 2020/8/22.
//  Copyright © 2020 kaoji. All rights reserved.
//

#import "TRTCCustomRenderVC.h"
#import "GLRenderView.h"
#import "CoreImageFilter.h"

@interface TRTCCustomRenderVC ()<TRTCVideoRenderDelegate>
@property (nonatomic, strong) UISegmentedControl *filterSegment;//是否开启滤镜
@property (nonatomic, strong) GLRenderView *glRenderView;
@property (nonatomic, assign) BOOL isFilter;//是否开启滤镜
@property (nonatomic, strong) CoreImageFilter *filter;//滤镜
@end

@implementation TRTCCustomRenderVC

-(void)viewDidLoad{
    [super viewDidLoad];
    self.isFilter = YES;
    [self startTRTC];
}

-(void)startTRTC{
    
    [self.trtc startLocalPreview:YES view:nil];
    [self.trtc startLocalAudio];
    
    //开启自定义渲染
    [self.trtc setLocalVideoRenderDelegate:self pixelFormat:TRTCVideoPixelFormat_NV12 bufferType:TRTCVideoBufferType_PixelBuffer];
    
    [self.trtc callExperimentalAPI:@"{\"api\":\"setCustomRenderMode\",\"params\" : {\"mode\":1}}"];
    
    //进房
    [self.trtc enterRoom:[self roomParam] appScene:TRTCAppSceneLIVE];
    
    
    //自定义渲染画面
    _glRenderView = [[GLRenderView alloc] initWithFrame:self.view.frame];
    _glRenderView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view insertSubview:_glRenderView atIndex:0];
    
    //滤镜控制
    _filterSegment = [[UISegmentedControl alloc] initWithItems:@[@"原始",@"滤镜"]];
    _filterSegment.selectedSegmentIndex = 1;
    _filterSegment.tintColor = rgba(15, 168, 45, 1.0);
    [_filterSegment setTitleTextAttributes:@{NSForegroundColorAttributeName:rgba(15, 168, 45, 1.0)} forState:UIControlStateNormal];
    _filterSegment.frame = CGRectMake( self.view.frame.size.width/2 - 75, self.view.frame.size.height - (isBangsDevice ?BOTTOM_LAYOUT_GUIDE:10) - 40, 150, 40);
    [_filterSegment addTarget:self action:@selector(onClickFilter:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_filterSegment];
    
    //滤镜
    self.filter = [[CoreImageFilter alloc] init];
    
}

-(void)onClickFilter:(UISegmentedControl *)segment{
    self.isFilter = segment.selectedSegmentIndex;
}

#pragma mark - 父类重写
-(void)onClickBack{
    //页面关闭 退房
    [self.trtc setLocalVideoRenderDelegate:nil pixelFormat:TRTCVideoPixelFormat_NV12 bufferType:TRTCVideoBufferType_PixelBuffer];
    [self.trtc stopLocalPreview];
    [self.trtc stopLocalAudio];
    [self.trtc exitRoom];
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)onClickCamera{
    [self.trtc switchCamera];
}

#pragma mark - TRTCVideoRenderDelegate
-(void)onRenderVideoFrame:(TRTCVideoFrame *)frame userId:(NSString *)userId streamType:(TRTCVideoStreamType)streamType{
    
    if(_isFilter){
        //处理图片
        CIImage *image = [self.filter filterPixelBuffer:frame];
        [_glRenderView.ciContext render:image toCVPixelBuffer:frame.pixelBuffer];
    }
    [_glRenderView renderFrame:frame];
    
    
}

@end
