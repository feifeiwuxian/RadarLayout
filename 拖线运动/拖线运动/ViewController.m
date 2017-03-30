//
//  ViewController.m
//  拖线运动
//
//  Created by lengchao on 2016/12/9.
//  Copyright © 2016年 chono. All rights reserved.
//

#import "ViewController.h"
#import "PointionModel.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lineLable;
@property (weak, nonatomic) IBOutlet UIButton *centerButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineLable_width;
//@property (weak, nonatomic) IBOutlet UIButton *otherButton;
@property (nonatomic) BOOL isShowLine;
@property (nonatomic, strong) NSMutableArray *positionArr; // 位置数组
@property (nonatomic, strong) NSMutableArray *leiDaSubViewArr; // 按钮的数组
@property (weak, nonatomic) IBOutlet UIView *leiDaView; // 雷达视图
@property (nonatomic) NSInteger pageNum; // 一页数据
// 定义雷达视图的基本变量
@property (nonatomic, strong) NSArray *leiDaLimitNumArr; // 每一圈限制最大个数
@property (nonatomic, strong) NSArray *leiDaWidthArr; // 子视图的大小
@property (nonatomic) CGFloat leiDaMargin; // 最小间距
@property (nonatomic) CGFloat leiDaRadius; // 雷达半径
@property (nonatomic) NSInteger currentSearchCircle; // 当前扫描第几圈
@property (nonatomic) CGFloat leiDaSearchMargin; // 雷达搜索精确度，每次递增
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.lineLable.layer.anchorPoint = CGPointMake(0, 0.5);
    
    self.centerButton.layer.cornerRadius = 40;
    self.centerButton.layer.masksToBounds = YES;
//    self.otherButton.layer.cornerRadius = 30;
//    self.otherButton.layer.masksToBounds = YES;
//    [self.otherButton addTarget:self action:@selector(otherButtonClick:) forControlEvents:UIControlEventTouchUpInside];
//    self.centerButton.userInteractionEnabled = NO;
    UILongPressGestureRecognizer *tapGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [self.centerButton addGestureRecognizer:tapGesture];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.centerButton addGestureRecognizer:pan];
    
    // 初始化雷达设置
    self.leiDaWidthArr = @[@(80), @(75), @(70), @(60),@(50)];
    self.leiDaLimitNumArr = @[@(1), @(2), @(2), @(3), @(5), @(8)];
    self.leiDaMargin = 15; // 布局最小间距
    self.leiDaSearchMargin = 5; // 搜索圈间距
    self.positionArr = [NSMutableArray array];
    self.leiDaSubViewArr = [NSMutableArray array];
    self.currentSearchCircle = 1;
    
    [self refreshLeiDaVeiw];
    
}

// 刷新雷达view
- (void)refreshLeiDaVeiw{
    [self.positionArr removeAllObjects];
    self.currentSearchCircle = 1;
//    self.pageNum = 15;
    self.leiDaRadius = [self.leiDaWidthArr[0] floatValue]/2;
    NSInteger count = 15;
    if (self.leiDaSubViewArr.count > 0) {
        count = self.leiDaSubViewArr.count;
    }
    for (NSInteger i = 0; i < count; i++) {
        PointionModel *model = [self getSuitablePosition];
        if (model != nil) {
            [self.positionArr addObject:model];
        }
    }
    // 重新布局
    if (self.leiDaSubViewArr.count == 0) {
        // 先添加子视图
        [self addSubCell];
    } else {
        for (NSInteger i = 0; i < self.positionArr.count; i++) {
            PointionModel *positionModel = self.positionArr[i];
            UIButton *button = self.leiDaSubViewArr[i];
            if (button != nil) {
                button.bounds = CGRectMake(0, 0, positionModel.radius *2, positionModel.radius *2);
                button.center = positionModel.centerPosition;
                button.layer.cornerRadius = positionModel.radius;
            } else {
                NSLog(@"没找到");
            }
        }
    }

}

// 添加子视图
- (void)addSubCell{
    for (NSInteger i = 0; i < self.positionArr.count; i++) {
        PointionModel *positionModel = self.positionArr[i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.bounds = CGRectMake(0, 0, positionModel.radius *2, positionModel.radius *2);
        button.center = positionModel.centerPosition;
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = positionModel.radius;
        button.tag = 100+i;
        [button setBackgroundColor:[UIColor grayColor]];
        [button setTitle:[NSString stringWithFormat:@"美女%@", @(i)] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(otherButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.leiDaView addSubview:button];
        [self.leiDaSubViewArr addObject:button];
    }
}

// 给我找出合适的位置
- (PointionModel *)getSuitablePosition{
    // 开始扫描第一圈
    // 判断当前所在圈个数是否最大限制
    NSInteger viewCount = 0;
    for (PointionModel *model in self.positionArr) {
        if (model.onCircle == self.currentSearchCircle) {
            viewCount++;
        }
    }
    // 当前最大限制
    NSInteger maxLimit = [[self.leiDaLimitNumArr lastObject] integerValue];
    if (self.currentSearchCircle < self.leiDaLimitNumArr.count) {
        maxLimit = [self.leiDaLimitNumArr[self.currentSearchCircle] integerValue];
    }
    if (viewCount >= maxLimit) {
        self.currentSearchCircle++;
       return [self getSuitablePosition];
    }
    // 计算出雷达半径
    CGFloat cureentAddRadirs = [[self.leiDaWidthArr lastObject] floatValue]/2.0;
    if (self.currentSearchCircle < self.leiDaWidthArr.count) {
        cureentAddRadirs = [self.leiDaWidthArr[self.currentSearchCircle] floatValue] / 2.0;
    }
    if (self.currentSearchCircle == 1) {
        self.leiDaRadius = [self.leiDaWidthArr[0] floatValue]/2 + self.leiDaMargin + cureentAddRadirs;
    } else {
        self.leiDaRadius = self.leiDaRadius + self.leiDaSearchMargin;
    }
    // 如果当前最大半径大于最大区域，返回Nil
    // 最小的圆到中心的距离
    CGPoint smalPosition = CGPointMake(cureentAddRadirs, cureentAddRadirs);
    CGPoint centerPoint = self.centerButton.center;
    CGFloat a = centerPoint.x - smalPosition.x;
    CGFloat b = centerPoint.y - smalPosition.y;
    CGFloat maxRadius = sqrt(a*a + b*b);
    if (self.leiDaRadius > maxRadius) {
        // 最大扫描范围
        NSLog(@"最大扫描范围");
        return nil;
    }
    // 先确定扫描分区
    NSInteger scanCategory = [self getScanCatogary];

    NSMutableArray *scanArr = [NSMutableArray array];
    for (NSInteger i = 0; i < 90; i++) {
        [scanArr addObject:@(i)];
    }
    NSInteger scanCount = 0; // 扫描计数
    PointionModel *model = nil;
    // 判断是否包含当前的角度
    // 360度扫描
    while (1) {
        // 如果扫描结束
        if (scanCount >= 90) {
            // 中断循环
            break;
        }
        if (model != nil) {
            // 找到了坐标，中断循环
            break;
        }
        // 扫描角度，随机获取
        NSInteger scanIndex = arc4random() % scanArr.count;
        NSNumber *scanCorner = scanArr[scanIndex];
        model = [self getPointWith:scanCategory scanCorner:scanCorner];
        // 最后要移除到数组中的元素
        [scanArr removeObjectAtIndex:scanIndex];
        scanCount++;
    }
    if (model != nil) {
        return model;
    } else {
        // 继续找下一圈
        self.currentSearchCircle++;
       return [self getSuitablePosition];
    }
}

// 给定分区，和角度扫描
- (PointionModel *)getPointWith:(NSInteger)scanCagegory scanCorner:(NSNumber *)scanCorner{
    CGFloat pointX = 0;
    CGFloat pointY = 0;
    CGFloat a = 0;
    CGFloat b = 0;
    CGPoint centerPoint = self.centerButton.center;
    CGFloat radian = M_PI_2 * 90 / [scanCorner integerValue];
    if (scanCagegory == 1) {
        // 1分区扫描
         a = self.leiDaRadius * cos(radian);
         b = self.leiDaRadius * sin(radian);
        pointX = centerPoint.x + a;
        pointY = centerPoint.y + b;

    } else if (scanCagegory == 2){
        // 2分区扫描
        a = self.leiDaRadius * sin(radian);
        b = self.leiDaRadius * cos(radian);
        pointX = centerPoint.x - a;
        pointY = centerPoint.y + b;
    }else if (scanCagegory == 3){
        // 3分区扫描
        a = self.leiDaRadius * cos(radian);
        b = self.leiDaRadius * sin(radian);
        pointX = centerPoint.x - a;
        pointY = centerPoint.y - b;
    }else if (scanCagegory == 4){
        // 4分区扫描
        a = self.leiDaRadius * sin(radian);
        b = self.leiDaRadius * cos(radian);
        pointX = centerPoint.x + a;
        pointY = centerPoint.y - b;
    }
    // 检查当前点是否合适
    CGPoint position = CGPointMake(pointX, pointY);
    BOOL isRightPoitn = [self checkIsRightPoit:position];
    if (isRightPoitn) {
     PointionModel *model = [[PointionModel alloc] init];
        model.category = scanCagegory;
        model.centerPosition = position;
        model.onCircle = self.currentSearchCircle;
        CGFloat cureentAddRadirs = [[self.leiDaWidthArr lastObject] floatValue]/2.0;
        if (self.currentSearchCircle < self.leiDaWidthArr.count) {
            cureentAddRadirs = [self.leiDaWidthArr[self.currentSearchCircle] floatValue] / 2.0;
        }
        model.radius = cureentAddRadirs;
        
        return model;
    }
    return nil;
}

// 判断当前的点是否合适
- (BOOL)checkIsRightPoit:(CGPoint)poit{
    // 先判断当前点是否在允许范围内
    CGFloat cureentAddRadirs = [[self.leiDaWidthArr lastObject] floatValue]/2.0;
    if (self.currentSearchCircle < self.leiDaWidthArr.count) {
        cureentAddRadirs = [self.leiDaWidthArr[self.currentSearchCircle] floatValue] / 2.0;
    }
    CGFloat minX = cureentAddRadirs;
    CGFloat minY = cureentAddRadirs;
    
    CGFloat maxX = self.leiDaView.frame.size.width - cureentAddRadirs;
    CGFloat maxY = self.leiDaView.frame.size.height - cureentAddRadirs;
    
    if (poit.x >= minX  && poit.x <= maxX && poit.y >= minY  && poit.y <= maxY) {
        // 在范围内
        // 判断是否与其它圆重叠
        BOOL isOverlap = NO;
        for (NSInteger i = 0; i < self.positionArr.count; i++) {
            PointionModel *model = self.positionArr[i];
            // 两点间的最小距离
            CGFloat standMinDistance = model.radius + self.leiDaMargin + cureentAddRadirs;
            // 计算两点间的距离
            CGFloat a = poit.x - model.centerPosition.x;
            if (a < 0) {
                a = -a;
            }
            CGFloat b = poit.y - model.centerPosition.y;
            if (b < 0) {
                b = -b;
            }
            CGFloat distance = sqrt(a*a + b*b);
            if (distance < standMinDistance) {
                isOverlap = YES;
                break;
            }
        }
        if (isOverlap == NO) {
            // 没有重叠
            return YES;
        } else {
            return NO;
        }
    }else {
        // 不在范围
        return NO;
    }
    
    return NO;
}

// 检查是否包含角度
- (BOOL)checkIsContain:(NSArray *)totoalArr scanConner:(NSInteger)conner{
    BOOL isConten = NO;
    for (NSInteger i = 0; i < totoalArr.count; i++) {
        NSInteger number = [totoalArr[i] integerValue];
        if (number == conner) {
            isConten = YES;
            break;
        }
    }
    return isConten;
}

- (NSInteger)getScanCatogary{
    NSUInteger scanCatogary = 0;
    if (self.currentSearchCircle == 1) {
        scanCatogary = arc4random()%4 + 1;
    }else {
        // 找出当前最少的区域
        NSInteger catogary1 = 0;
        NSInteger catogary2 = 0;
        NSInteger catogary3 = 0;
        NSInteger catogary4 = 0;
        
        for (PointionModel *model in self.positionArr) {
            if (model.category == 1) {
                catogary1++;
            } else if (model.category == 2) {
                catogary2++;
            } else if (model.category == 3) {
                catogary3++;
            } else if (model.category == 4) {
                catogary4++;
            }
        }
        
        NSInteger minCatogary = 1;
        NSInteger minNumber = catogary1;
        if (catogary2 < minNumber) {
            minCatogary = 2;
            minNumber = catogary2;
            
        } else if (catogary3 < minNumber){
            minCatogary = 3;
            minNumber = catogary3;
        } else if (catogary4 < minNumber){
            minCatogary = 4;
            minNumber = catogary4;
        }
        scanCatogary = minCatogary;
    }
    
    return scanCatogary;
}

- (void)otherButtonClick:(id)sender{
    NSLog(@"tap");

}

- (IBAction)buttonClick:(id)sender {
    NSLog(@"buttonClick");

}
- (IBAction)refreshView:(id)sender {
    self.isShowLine = NO;
    self.lineLable.hidden = YES;
    self.lineLable_width.constant = 0;
    // 先加载数据，加载完成后
    self.centerButton.alpha = 1;
    self.centerButton.transform = CGAffineTransformIdentity;
    for (NSInteger i = 0; i < self.leiDaSubViewArr.count; i++) {
        UIButton *button = self.leiDaSubViewArr[i];
        button.alpha = 1;
        button.transform = CGAffineTransformIdentity;
    }
    // 隐藏动画
    [UIView animateWithDuration:0.5 animations:^{
        self.centerButton.alpha = 0;
        self.centerButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
        for (NSInteger i = 0; i < self.leiDaSubViewArr.count; i++) {
            UIButton *button = self.leiDaSubViewArr[i];
            button.alpha = 0;
            button.transform = CGAffineTransformMakeScale(0.01, 0.01);
        }
        
    } completion:^(BOOL finished) {
         [self refreshLeiDaVeiw];
        [UIView animateWithDuration:0.5 animations:^{
            self.centerButton.alpha = 1;
            self.centerButton.transform = CGAffineTransformIdentity;
            for (NSInteger i = 0; i < self.leiDaSubViewArr.count; i++) {
                UIButton *button = self.leiDaSubViewArr[i];
                button.alpha = 1;
                button.transform = CGAffineTransformIdentity;
            }
        }];
    }];
}

- (IBAction)buttonTouchMoveInside:(UIButton *)sender {
//    self.centerButton.hidden = YES;
//    self.centerButton.hidden = NO;
    self.centerButton.enabled = NO;
    NSLog(@"1111");
}
- (void)longPressAction:(UIGestureRecognizer *)sender{
    if (sender.state == UIGestureRecognizerStateBegan) {
         NSLog(@"longPressAction");
    }
}

- (void)handlePan:(UIGestureRecognizer *)sender{
    if ([sender isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)sender;
        if (panGesture.state == UIGestureRecognizerStateBegan) {
            NSLog(@"bbbbbb");
            CGPoint clickPoint = [panGesture locationInView:self.leiDaView];
            // 判断当前 的点是不是在CenterButton上
            BOOL isContain =  CGRectContainsPoint(self.centerButton.frame, clickPoint);
            if (isContain) {
                self.isShowLine = YES;
                self.lineLable.hidden = NO;
            }
            self.lineLable_width.constant = 0;
        }
        if (panGesture.state == UIGestureRecognizerStateChanged)
        {
            NSLog(@"vvvvv");
            CGPoint centerPoint = self.centerButton.center;
            CGPoint clickPoint = [panGesture locationInView:self.leiDaView];
            //    if (clickPoint.x > centerPoint.x && clickPoint.y > centerPoint.y) {
            CGFloat a = clickPoint.x - centerPoint.x;
            CGFloat b = clickPoint.y - centerPoint.y;
            CGFloat reds = atan(b/a);
            if (clickPoint.x < centerPoint.x) {
                a = -a;
                reds =  M_PI_2 + atan(a/b);
                if (clickPoint.y < centerPoint.y) {
                    b = -b;
                    reds = M_PI + atan(b/a);
                }
            }
            self.lineLable.transform = CGAffineTransformMakeRotation(reds);
            
            // 两点间的距离
            CGFloat width = sqrt(a*a + b*b);
            self.lineLable_width.constant = width;
        }
        
        if (panGesture.state == UIGestureRecognizerStateEnded) {
            self.isShowLine = NO;
            // 判断结束的点是不是在要连线的头像上
            CGPoint clickPoint = [panGesture locationInView:self.leiDaView];
            // 判断当前 的点是不是在CenterButton上
            BOOL isContain =  NO;
            for (NSInteger i = 0 ; i < self.positionArr.count; i++) {
                PointionModel *model = self.positionArr[i];
                CGFloat a = clickPoint.x - model.centerPosition.x;
                CGFloat b = clickPoint.y - model.centerPosition.y;
                CGFloat width = sqrt(a*a + b*b);
                if (width <= model.radius) {
                    isContain = YES;
                    self.isShowLine = YES;
                    break;
                }
            }
            if (self.isShowLine) {
                self.lineLable.hidden = NO;
            } else {
                self.lineLable.hidden = YES;
                self.lineLable_width.constant = 0;
            }
            // 如果还是在当前按钮上
            BOOL isInCurrentCenterButton = CGRectContainsPoint(self.centerButton.frame, clickPoint);
            if (isInCurrentCenterButton) {
                [self buttonClick:nil];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    NSLog(@"bbbbbb");
//    UITouch *touch = [touches anyObject];
//    CGPoint clickPoint = [touch locationInView:self.view];
//    // 判断当前 的点是不是在CenterButton上
//    BOOL isContain =  CGRectContainsPoint(self.centerButton.frame, clickPoint);
//    if (isContain) {
//        self.isShowLine = YES;
//        self.lineLable.hidden = NO;
//    }
//    self.lineLable_width.constant = 0;
//}
//
//- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//     NSLog(@"vvvvv");
//    CGPoint centerPoint = self.centerButton.center;
//    UITouch *touch = [touches anyObject];
//    CGPoint clickPoint = [touch locationInView:self.view];
////    if (clickPoint.x > centerPoint.x && clickPoint.y > centerPoint.y) {
//        CGFloat a = clickPoint.x - centerPoint.x;
//        CGFloat b = clickPoint.y - centerPoint.y;
//        CGFloat reds = atan(b/a);
//    if (clickPoint.x < centerPoint.x) {
//        a = -a;
//        reds =  M_PI_2 + atan(a/b);
//        if (clickPoint.y < centerPoint.y) {
//            b = -b;
//            reds = M_PI + atan(b/a);
//        }
//    }
//        self.lineLable.transform = CGAffineTransformMakeRotation(reds);
//        
//        // 两点间的距离
//        CGFloat width = sqrt(a*a + b*b);
//        self.lineLable_width.constant = width;
////    }
//}
//
//- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    self.isShowLine = NO;
//    // 判断结束的点是不是在要连线的头像上
//    UITouch *touch = [touches anyObject];
//    CGPoint clickPoint = [touch locationInView:self.view];
//    // 判断当前 的点是不是在CenterButton上
//    BOOL isContain =  CGRectContainsPoint(self.otherButton.frame, clickPoint);
//    if (isContain) {
//        // 进一步判断拉的位置圆心
//        // 计算两点间的距离
//        // 两点间的距离
//        CGPoint otherCenter = self.otherButton.center;
//        CGFloat a = clickPoint.x - otherCenter.x;
//        CGFloat b = clickPoint.y - otherCenter.y;
//        CGFloat radius = sqrt(a*a + b*b);
//        CGFloat halfWidth = self.otherButton.frame.size.width/2;
//        if (radius < halfWidth) {
//            self.isShowLine = YES;
//        }
//    }
//    if (self.isShowLine) {
//        self.lineLable.hidden = NO;
//    } else {
//        self.lineLable.hidden = YES;
//        self.lineLable_width.constant = 0;
//    }
//    // 如果还是在当前按钮上
//    BOOL isInCurrentCenterButton = CGRectContainsPoint(self.centerButton.frame, clickPoint);
//    if (isInCurrentCenterButton) {
//        [self buttonClick:nil];
//    }
//}

@end
