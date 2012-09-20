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
        [[self layer] setBackgroundColor:[[UIColor redColor] colorWithAlphaComponent:0.7].CGColor];
        [[self layer] setBorderColor:[UIColor redColor].CGColor];
        [[self layer] setBorderWidth:2];
        [[self layer] setCornerRadius:22];
        [self setBounds:CGRectMake(0, 0, 44, 44)];
        [self setDraggable:YES];
    }
    
    return self;
}

- (void)setDragState:(MKAnnotationViewDragState)newDragState animated:(BOOL)animated{
    self.dragState = newDragState;
    if (newDragState == MKAnnotationViewDragStateStarting) {
        self.dragState = MKAnnotationViewDragStateDragging;
    }else if(newDragState == MKAnnotationViewDragStateEnding || newDragState == MKAnnotationViewDragStateCanceling){
        self.dragState = MKAnnotationViewDragStateNone;
    }
}

@end
