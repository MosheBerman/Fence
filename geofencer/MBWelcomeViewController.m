//
//  MBWelcomeViewController.m
//  Fence
//
//  Created by Moshe Berman on 9/20/12.
//
//

#import "MBWelcomeViewController.h"

#import <QuartzCore/QuartzCore.h>

@interface MBWelcomeViewController () <UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *headerImage;
@property (strong, nonatomic) IBOutlet UIScrollView *wrapperScrollView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITextView *instructionsView;

@end

@implementation MBWelcomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //
    //  
    //
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(next)];
    [[self navigationItem] setRightBarButtonItem:buttonItem animated:YES];
    
    [[[self headerImage] layer] setShadowRadius:7];
    [[[self headerImage] layer] setShadowColor:[UIColor blackColor].CGColor];
    [[[self headerImage] layer] setShadowOpacity:1.0];
    
    [self setTitle:NSLocalizedString(@"Welcome", @"The title for the welcome screen")];
    
    CGFloat height = [[self headerImage] frame].size.height + [[self titleLabel] frame].size.height+[[self instructionsView] frame].size.height;
    
    CGSize newContentSize = CGSizeMake([[self wrapperScrollView]frame].size.width, height);
    
    [[self wrapperScrollView] setContentSize:newContentSize];
    [[self wrapperScrollView] setShowsHorizontalScrollIndicator:NO];
    
    [[self instructionsView] setUserInteractionEnabled:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) next{
    [[[self navigationController] presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{

    CGRect headerFrame = [[self headerImage] frame];
    CGPoint contentOffset = [[self wrapperScrollView] contentOffset];
    
    headerFrame.origin.y = MIN(contentOffset.y, contentOffset.y - (contentOffset.y * 0.05));

    [[self headerImage] setFrame:headerFrame];
    
}

- (void)viewDidUnload {
    [self setHeaderImage:nil];
    [self setWrapperScrollView:nil];
    [self setTitleLabel:nil];
    [self setInstructionsView:nil];
    [super viewDidUnload];
}
@end
