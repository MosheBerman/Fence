//
//  MBPointAnnotationView.h
//  Fence
//
//  Created by Moshe Berman on 9/20/12.
//
//

#import "MBLabelAnnotationView.h"

#import <QuartzCore/QuartzCore.h>

@interface MBPointAnnotationView : MKAnnotationView

@property (nonatomic, assign) NSInteger pointIndex;

@end
