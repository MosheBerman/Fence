//
//  MBMultifingerTapGestureRecognizer.m
//  Fence
//
//  Created by Moshe Berman on 8/15/12.
//
//

#import "MBMultifingerTapGestureRecognizer.h"



@interface MBMultifingerTapGestureRecognizer ()

@property (nonatomic) NSInteger touchCount;
@property (nonatomic) BOOL firedAlready;
@end

@implementation MBMultifingerTapGestureRecognizer


-(id) init{
    if (self = [super init])
    {
        self.cancelsTouchesInView = NO;
        _touchCount = 0;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    _touchCount += touches.count;
    
    NSLog(@"Tracking: %i touches", _touchCount );

    if (_touchCount == 3 && _touchesBeganCallback){
        
        NSLog(@"%i touches began.", touches.count);
        _touchesBeganCallback(touches, event);
        [self reset];
    }

    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self reset];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_touchesMovedCallback) {
        _touchesMovedCallback(touches, event);
    }
    
}


- (void)reset
{
    _touchCount = 0;
}

- (void)ignoreTouch:(UITouch *)touch forEvent:(UIEvent *)event
{
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
    return NO;
}

@end
