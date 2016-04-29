/*
 
 2 possibilities for the privacy screen. 
 
 1. do not define BLUR, or define it as BLUR=0 to have an opaque screen with the logo centered
    as privacy screen. You can hardcode a background color (code commented out), or by default 
    the top left pixel color of the logo will be used as opaque background color. The alpha
    value is not taken into account.
 2. define BLUR=1 to have a blurred view of the current application content as privacy screen.
 
 Define these in the iOS project Build settings > Preprocessor macros
 
 */



#import "PrivacyScreen.h"
#import "FXBlurView.h"
#import <Cordova/CDVScreenOrientationDelegate.h>
#import "CDVSplashScreen.h"

@interface PrivacyScreen ()

@property (nonatomic, strong) UIView *blurView;

@end

@implementation PrivacyScreen

- (void) enable:(CDVInvokedUrlCommand *) command
{
    NSLog(@"Enabling privacy screen start");
    @try {
        [self removeObservers];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }
    @try {
    [self addObservers];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }
    @try {
    [self blurView];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }
    NSLog(@"Enabling privacy screen end");
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void) pluginInitialize
{
    //[super pluginInitialize];
    [self removeObservers];
    [self addObservers];
    
    [self blurView]; // create the blurview in advance.
}

- (void) onReset
{
    //[super onReset];
    
    [self removeObservers];
    [self addObservers];
}

- (void) addObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(applicationWillResignActive:)
               name:UIApplicationWillResignActiveNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(applicationDidBecomeActive:)
               name:UIApplicationDidBecomeActiveNotification
             object:nil];
}

- (void) removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc removeObserver:self];
}

- (UIWindow *) window
{
    return [[UIApplication sharedApplication].delegate window];
}

- (UIColor*)pixelColorInImage:(UIImage*)image atX:(int)x atY:(int)y {
    
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);
    
    int pixelInfo = ((image.size.width  * y) + x ) * 4; // 4 bytes per pixel
    
    UInt8 red   = data[pixelInfo + 0];
    UInt8 green = data[pixelInfo + 1];
    UInt8 blue  = data[pixelInfo + 2];
    UInt8 alpha = data[pixelInfo + 3];
    CFRelease(pixelData);
    
    return [UIColor colorWithRed:red/255.0f
                           green:green/255.0f
                            blue:blue/255.0f
                           alpha:1];
}

- (NSString*)getImageName:(UIInterfaceOrientation)currentOrientation delegate:(id<CDVScreenOrientationDelegate>)orientationDelegate device:(CDV_iOSDevice)device
{
    // Use UILaunchImageFile if specified in plist.  Otherwise, use Default.
    NSString* imageName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UILaunchImageFile"];
    
    NSUInteger supportedOrientations = [orientationDelegate supportedInterfaceOrientations];
    
    // Checks to see if the developer has locked the orientation to use only one of Portrait or Landscape
    BOOL supportsLandscape = (supportedOrientations & UIInterfaceOrientationMaskLandscape);
    BOOL supportsPortrait = (supportedOrientations & UIInterfaceOrientationMaskPortrait || supportedOrientations & UIInterfaceOrientationMaskPortraitUpsideDown);
    // this means there are no mixed orientations in there
    BOOL isOrientationLocked = !(supportsPortrait && supportsLandscape);
    
    if (imageName)
    {
        imageName = [imageName stringByDeletingPathExtension];
    }
    else
    {
        imageName = @"Default";
    }

    // Add Asset Catalog specific prefixes
    if ([imageName isEqualToString:@"LaunchImage"])
    {
        if (device.iPhone4 || device.iPhone5 || device.iPad) {
            imageName = [imageName stringByAppendingString:@"-700"];
        } else if(device.iPhone6) {
            imageName = [imageName stringByAppendingString:@"-800"];
        } else if(device.iPhone6Plus) {
            imageName = [imageName stringByAppendingString:@"-800"];
            if (currentOrientation == UIInterfaceOrientationPortrait || currentOrientation == UIInterfaceOrientationPortraitUpsideDown)
            {
                imageName = [imageName stringByAppendingString:@"-Portrait"];
            }
        }
    }

    if (device.iPhone5)
    { // does not support landscape
        imageName = [imageName stringByAppendingString:@"-568h"];
    }
    else if (device.iPhone6)
    { // does not support landscape
        imageName = [imageName stringByAppendingString:@"-667h"];
    }
    else if (device.iPhone6Plus)
    { // supports landscape
        if (isOrientationLocked)
        {
            imageName = [imageName stringByAppendingString:(supportsLandscape ? @"-Landscape" : @"")];
        }
        else
        {
            switch (currentOrientation)
            {
                case UIInterfaceOrientationLandscapeLeft:
                case UIInterfaceOrientationLandscapeRight:
                        imageName = [imageName stringByAppendingString:@"-Landscape"];
                    break;
                default:
                    break;
            }
        }
        imageName = [imageName stringByAppendingString:@"-736h"];

    }
    else if (device.iPad)
    {   // supports landscape
        if (isOrientationLocked)
        {
            imageName = [imageName stringByAppendingString:(supportsLandscape ? @"-Landscape" : @"-Portrait")];
        }
        else
        {
            switch (currentOrientation)
            {
                case UIInterfaceOrientationLandscapeLeft:
                case UIInterfaceOrientationLandscapeRight:
                    imageName = [imageName stringByAppendingString:@"-Landscape"];
                    break;
                    
                case UIInterfaceOrientationPortrait:
                case UIInterfaceOrientationPortraitUpsideDown:
                default:
                    imageName = [imageName stringByAppendingString:@"-Portrait"];
                    break;
            }
        }
    }
    
    return imageName;
}

- (UIInterfaceOrientation)getCurrentOrientation
{
    UIInterfaceOrientation iOrientation = [UIApplication sharedApplication].statusBarOrientation;
    UIDeviceOrientation dOrientation = [UIDevice currentDevice].orientation;

    bool landscape;

    if (dOrientation == UIDeviceOrientationUnknown || dOrientation == UIDeviceOrientationFaceUp || dOrientation == UIDeviceOrientationFaceDown) {
        // If the device is laying down, use the UIInterfaceOrientation based on the status bar.
        landscape = UIInterfaceOrientationIsLandscape(iOrientation);
    } else {
        // If the device is not laying down, use UIDeviceOrientation.
        landscape = UIDeviceOrientationIsLandscape(dOrientation);

        // There's a bug in iOS!!!! http://openradar.appspot.com/7216046
        // So values needs to be reversed for landscape!
        if (dOrientation == UIDeviceOrientationLandscapeLeft)
        {
            iOrientation = UIInterfaceOrientationLandscapeRight;
        }
        else if (dOrientation == UIDeviceOrientationLandscapeRight)
        {
            iOrientation = UIInterfaceOrientationLandscapeLeft;
        }
        else if (dOrientation == UIDeviceOrientationPortrait)
        {
            iOrientation = UIInterfaceOrientationPortrait;
        }
        else if (dOrientation == UIDeviceOrientationPortraitUpsideDown)
        {
            iOrientation = UIInterfaceOrientationPortraitUpsideDown;
        }
    }

    return iOrientation;
}

- (CDV_iOSDevice) getCurrentDevice
{
    CDV_iOSDevice device;
    
    UIScreen* mainScreen = [UIScreen mainScreen];
    CGFloat mainScreenHeight = mainScreen.bounds.size.height;
    CGFloat mainScreenWidth = mainScreen.bounds.size.width;
    
    int limit = MAX(mainScreenHeight,mainScreenWidth);
    
    device.iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    device.iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    device.retina = ([mainScreen scale] == 2.0);
    device.iPhone4 = (device.iPhone && limit == 480.0);
    device.iPhone5 = (device.iPhone && limit == 568.0);
    // note these below is not a true device detect, for example if you are on an
    // iPhone 6/6+ but the app is scaled it will prob set iPhone5 as true, but
    // this is appropriate for detecting the runtime screen environment
    device.iPhone6 = (device.iPhone && limit == 667.0);
    device.iPhone6Plus = (device.iPhone && limit == 736.0);
    
    return device;
}

- (UIView *)blurView
{
    if( nil == _blurView )
    {
#if BLUR
        FXBlurView *blurView = [[FXBlurView alloc]initWithFrame:self.window.frame];
        blurView.tintColor = [UIColor blackColor];
        blurView.blurRadius = 9;
        blurView.iterations = 3;
#else // OPAQUE
        UIView *blurView = [[UIView alloc]initWithFrame:self.window.frame];
        
        NSString* imageName = [self getImageName:[self getCurrentOrientation] delegate:(id<CDVScreenOrientationDelegate>)self.viewController device:[self getCurrentDevice]];

        UIImage *logo = [UIImage imageNamed:imageName];
        UIImageView *iv = [[UIImageView alloc]initWithImage:logo];
        iv.tag = 4;
        
        // hard coded background color:
        blurView.backgroundColor = [UIColor colorWithRed:34./255. green:129./255. blue:197./255. alpha:1];
        
        // sampled background color:
        //blurView.backgroundColor = [self pixelColorInImage:logo atX:0 atY:0];
        
        [blurView addSubview:iv];
        iv.center = blurView.center;
#endif
        
        _blurView = blurView;
    }
    return _blurView;
}

- (void) showBlurView
{
    self.blurView.alpha = 1;
    UIView *coverView = self.blurView;
    coverView.frame = self.window.frame;
    coverView.transform = CGAffineTransformIdentity;
    coverView.layer.transform = CATransform3DIdentity;
    [coverView viewWithTag:4].center = coverView.center;
    
    [self.window addSubview:coverView];
}

- (void) applicationWillResignActive:(NSNotification *) notification
{
    [self showBlurView];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBlurView) object:nil];
    [self performSelector:@selector(hideBlurView) withObject:nil afterDelay:0.1];
}

- (void) hideBlurView
{
    UIView *blurView = self.blurView;
    
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         blurView.alpha = 0;
                         
                     } completion:^(BOOL finished) {
                         [blurView removeFromSuperview];
                     }];
}

@end
