//
//  QiniuPlayView.h
//  sportdream
//
//  Created by lili on 2017/12/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>


@class RCTEventDispatcher;

@interface QiniuPlayView : UIView

@property (nonatomic, assign) int reconnectCount;


- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;


@end
