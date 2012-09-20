//
//  MBAnnotationView.m
//  Fence
//
//  Created by Moshe Berman on 5/8/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import "MBLabelAnnotationView.h"

@implementation MBLabelAnnotationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        
    }
    return self;
}

- (MKAnnotationViewDragState)dragState{
    return self.dragState;
}

- (void)setDragState:(MKAnnotationViewDragState)newDragState animated:(BOOL)animated{
    if (newDragState == MKAnnotationViewDragStateStarting) {
        self.dragState = MKAnnotationViewDragStateDragging;
    }else if(newDragState == MKAnnotationViewDragStateEnding || newDragState == MKAnnotationViewDragStateCanceling){
        self.dragState = MKAnnotationViewDragStateNone;
    }
}

@end
