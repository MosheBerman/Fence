//
//  MBPointAnnotationView.m
//  Fence
//
//  Created by Moshe Berman on 9/20/12.
//
//

#import "MBPointAnnotationView.h"

@implementation MBPointAnnotationView

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{

    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [[self layer] setBackgroundColor:[[UIColor redColor] colorWithAlphaComponent:0.3].CGColor];
        [[self layer] setBorderColor:[[UIColor redColor] colorWithAlphaComponent:0.5].CGColor];
        [[self layer] setBorderWidth:2];
        
        [self configureUIForStationary];
        [self setDraggable:YES];
    }
    
    return self;
}

- (void)setDragState:(MKAnnotationViewDragState)newDragState animated:(BOOL)animated{
    self.dragState = newDragState;
    if (newDragState == MKAnnotationViewDragStateStarting) {
        
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                [self configureUIForDragging];
            } completion:^(BOOL finished) {
                self.dragState = MKAnnotationViewDragStateDragging;;
            }];
        }else{
            [self configureUIForDragging];
            self.dragState = MKAnnotationViewDragStateDragging;
        }

    }else if(newDragState == MKAnnotationViewDragStateEnding || newDragState == MKAnnotationViewDragStateCanceling){
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                [self configureUIForStationary];
            } completion:^(BOOL finished) {
                self.dragState = MKAnnotationViewDragStateNone;
            }];
        }else{
            [self configureUIForStationary];
            self.dragState = MKAnnotationViewDragStateNone;
        }
    }
}

- (void) configureUIForDragging{
    
    CGPoint oldCenter = [self center];
    [self setBounds:CGRectMake(0, 0, 66, 66)];
    [[self layer] setCornerRadius:33];
    [self setCenter:oldCenter];
    
    [self setAlpha:0.7];
}

- (void) configureUIForStationary{
    [self setBounds:CGRectMake(0, 0, 44, 44)];
    [[self layer] setCornerRadius:22];
    [self setAlpha:1.0];
}

@end
