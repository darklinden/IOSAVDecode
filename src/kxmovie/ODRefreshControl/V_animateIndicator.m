//
//  V_animateIndicator.m
//  test
//
//  Created by DarkLinden on 9/27/12.
//  Copyright (c) 2012 comcsoft. All rights reserved.
//

#import "V_animateIndicator.h"
#import <QuartzCore/QuartzCore.h>

@implementation V_animateIndicator

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void)startAnimating
{
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = [NSNumber numberWithFloat:0.0f];
    animation.toValue = [NSNumber numberWithFloat: 2*M_PI];
    animation.duration = 1.2f;
    animation.repeatCount = HUGE_VAL;
    [self.layer addAnimation:animation forKey:@"MyAnimation"];
}

- (void)stopAnimating
{
    [self.layer removeAllAnimations];
}

- (BOOL)isAnimating
{
    if (self.layer.animationKeys.count > 0) {
        return YES;
    }
    return NO;
}

- (void)drawRect:(CGRect)rect
{
    ((CAShapeLayer *)self.layer).fillColor = [[UIColor whiteColor] CGColor];
    CGPoint topOrigin = CGPointMake(10.f, 10.f);
    CGFloat currentArrowSize = 3;
    CGFloat arrowBigRadius = 8.5;
    CGFloat arrowSmallRadius = 5.5;
    CGMutablePathRef arrowPath = CGPathCreateMutable();
    CGPathAddArc(arrowPath, NULL, topOrigin.x, topOrigin.y, arrowBigRadius, 0, 3 * M_PI_2, NO);
    CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x, topOrigin.y - arrowBigRadius - currentArrowSize);
    CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x + (2 * currentArrowSize), topOrigin.y - arrowBigRadius + (currentArrowSize / 2));
    CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x, topOrigin.y - arrowBigRadius + (2 * currentArrowSize));
    CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x, topOrigin.y - arrowBigRadius + currentArrowSize);
    CGPathAddArc(arrowPath, NULL, topOrigin.x, topOrigin.y, arrowSmallRadius, 3 * M_PI_2, 0, YES);
    CGPathCloseSubpath(arrowPath);
    ((CAShapeLayer *)self.layer).path = arrowPath;
    [((CAShapeLayer *)self.layer) setFillRule:kCAFillRuleEvenOdd];
    CGPathRelease(arrowPath);
}


@end
