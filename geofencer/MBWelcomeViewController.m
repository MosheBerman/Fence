//
//  MBWelcomeViewController.m
//  Fence
//
//  Created by Moshe Berman on 9/20/12.
//
//

#import "MBWelcomeViewController.h"

@interface MBWelcomeViewController ()

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
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) next{
    [[[self navigationController] presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}
@end
