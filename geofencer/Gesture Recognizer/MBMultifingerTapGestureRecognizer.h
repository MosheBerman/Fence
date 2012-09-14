//
//  MBMultifingerTapGestureRecognizer.h
//  Fence
//
//  Created by Moshe Berman on 8/15/12.
//
//

#import <UIKit/UIKit.h>

typedef void (^TouchesEventBlock)(NSSet * touches, UIEvent * event);

@interface MBMultifingerTapGestureRecognizer : UITapGestureRecognizer

@property (copy) TouchesEventBlock touchesBeganCallback;
@property (copy) TouchesEventBlock touchesMovedCallback;
@end
