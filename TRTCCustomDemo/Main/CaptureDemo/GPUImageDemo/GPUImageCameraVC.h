//
//  GPUImageCameraVC.h
//  TRTCCustomDemo
//
//  Created by kaoji on 2020/8/23.
//  Copyright © 2020 kaoji. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TRTCBaseVC.h"

typedef NS_ENUM(NSInteger, FILTER_TYPE) {
    FILTER_BEAUTY_TYPE = 0,
    FILTER_SEPIA_TYPE  = 1,
    FILTER_SKETCH_TYPE = 2,
};

NS_ASSUME_NONNULL_BEGIN


@interface GPUImageCameraVC : TRTCBaseVC
@property (nonatomic, assign) FILTER_TYPE filterType;
@end

NS_ASSUME_NONNULL_END
