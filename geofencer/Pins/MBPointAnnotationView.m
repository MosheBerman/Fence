//
//  MBPointAnnotationView.m
//  Fence
//
//  Created by Moshe Berman on 9/20/12.
//
//

#import "MBPointAnnotationView.h"

@implementation MBPointAnnotationView

- (void)drawRect:(CGRect)rect{
    // Drawing code
    
    [[self layer] setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.7].CGColor];
    [[self layer] setBorderColor:[UIColor colorWithWhite:1.0 alpha:1.0].CGColor];
    [[self layer] setBorderWidth:1];
    [[self layer] setCornerRadius:22];
    
    [self setBounds:CGRectMake(0, 0, 44, 44)];
    
}


@end
