//
//  PointionModel.h
//  拖线运动
//
//  Created by lengchao on 2016/12/12.
//  Copyright © 2016年 chono. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface PointionModel : NSObject
@property (nonatomic) CGFloat radius; // 半径
@property (nonatomic) CGPoint centerPosition; // 中心位置
@property (nonatomic) NSInteger category; // 1，2， 3， 4  所在分区
@property (nonatomic) NSInteger onCircle; // 1，2， 3， 4,5,6,7,8...  所在圈数
@end
