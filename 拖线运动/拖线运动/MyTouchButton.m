//
//  MyTouchButton.m
//  拖线运动
//
//  Created by lengchao on 2016/12/9.
//  Copyright © 2016年 chono. All rights reserved.
//

#import "MyTouchButton.h"

@implementation MyTouchButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // 这里可以做子view自己想做的事，做完后，事件继续上传，就可以让其父类，甚至父viewcontroller获取到这个事件了
    [[self nextResponder] touchesBegan:touches withEvent:event];
//    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self nextResponder]touchesEnded:touches withEvent:event];
//    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self nextResponder] touchesCancelled:touches withEvent:event];
//    [super touchesCancelled:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self nextResponder] touchesMoved:touches withEvent:event];
//    [super touchesMoved:touches withEvent:event];
}

@end
