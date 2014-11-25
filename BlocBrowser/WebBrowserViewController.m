//
//  WebBrowserViewController.m
//  BlocBrowser
//
//  Created by Marius Horga on 11/23/14.
//  Copyright (c) 2014 Marius Horga. All rights reserved.
//

#import "WebBrowserViewController.h"
#import "AwesomeFloatingToolbar.h"

#define kWebBrowserBackString NSLocalizedString(@"Back", @"Back command")
#define kWebBrowserForwardString NSLocalizedString(@"Forward", @"Forward command")
#define kWebBrowserStopString NSLocalizedString(@"Stop", @"Stop command")
#define kWebBrowserRefreshString NSLocalizedString(@"Refresh", @"Reload command")

@interface WebBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate, AwesomeFloatingToolbarDelegate>

@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) AwesomeFloatingToolbar *awesomeToolbar;
@property (nonatomic, assign) NSUInteger frameCount;

@end

@implementation WebBrowserViewController

#pragma mark - UIViewController

- (void)loadView {
    UIView *mainView = [UIView new];
    self.webview = [[UIWebView alloc] init];
    self.webview.delegate = self;
    
    self.textField = [[UITextField alloc] init];
    self.textField.keyboardType = UIKeyboardTypeURL;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Website URL or text to search for", @"Placeholder text field");
    self.textField.backgroundColor = [UIColor colorWithWhite:220/255.0f alpha:1];
    self.textField.textAlignment = 1;
    self.textField.delegate = self;
    
    self.awesomeToolbar = [[AwesomeFloatingToolbar alloc] initWithFourTitles:@[kWebBrowserBackString, kWebBrowserForwardString, kWebBrowserStopString, kWebBrowserRefreshString]];
    self.awesomeToolbar.delegate = self;
    
    for (UIView *viewToAdd in @[self.webview, self.textField, self.awesomeToolbar]) {
        [mainView addSubview:viewToAdd];
    }
    
    self.view = mainView;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
}

- (void) viewWillLayoutSubviews {
    // First, calculate some dimensions.
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight;
    
    // Now, assign the frames
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webview.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    if (CGRectIsEmpty(self.awesomeToolbar.frame)) {
        self.awesomeToolbar.frame = CGRectMake(20, 100, 200, 60);
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *URLString = textField.text;
    // If the user's text includes a space, assume it's a search query instead of a URL
    if ([URLString containsString:@" "]) {
        NSString *newString = [URLString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        URLString = [@"http://www.google.com/search?q=" stringByAppendingString:newString];
    } 
    
    NSURL *URL = [NSURL URLWithString:URLString];
    if (!URL.scheme) {
        // The user didn't type http: or https:
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", URLString]];
    }
    if (URL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [self.webview loadRequest:request];
    }
    
    return NO;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.frameCount++;
    [self updateButtonsAndTitle];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.frameCount--;
    [self updateButtonsAndTitle];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error.code != -999) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
        [alert show];
    }
    [self updateButtonsAndTitle];
    self.frameCount--;
}

#pragma mark - AwesomeFloatingToolbarDelegate

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    if ([title isEqual:kWebBrowserBackString]) {
        [self.webview goBack];
    } else if ([title isEqual:kWebBrowserForwardString]) {
        [self.webview goForward];
    } else if ([title isEqual:kWebBrowserStopString]) {
        [self.webview stopLoading];
    } else if ([title isEqual:kWebBrowserRefreshString]) {
        [self.webview reload];
    }
}

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToPanWithOffset:(CGPoint)offset {
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x + offset.x, startingPoint.y + offset.y);
    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));
    
    [self modifyViewsFrame:potentialNewFrame];
}

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToPinchWithScale:(CGFloat)scale {
    CGPoint startingPoint = toolbar.frame.origin;
    CGRect potentialNewFrame = CGRectMake(startingPoint.x, startingPoint.y, toolbar.frame.size.width * scale, toolbar.frame.size.height * scale);
    
    [self modifyViewsFrame:potentialNewFrame];
}

-(void) didTryToLongPress:(AwesomeFloatingToolbar *)toolbar {
    
    [toolbar rotateToolbarBackgroundColor];
}

#pragma mark - Miscellaneous

-(void)modifyViewsFrame:(CGRect)potentialNewFrame {
    
    if (CGRectContainsRect(self.view.bounds, potentialNewFrame)) {
        self.awesomeToolbar.frame = potentialNewFrame;
    }
}

- (void) updateButtonsAndTitle {
    NSString *webpageTitle = [self.webview stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    if (webpageTitle) {
        self.title = webpageTitle;
    } else {
        self.title = self.webview.request.URL.absoluteString;
    }
    
    if (self.frameCount > 0) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    
    [self.awesomeToolbar setEnabled:[self.webview canGoBack] forButtonWithTitle:kWebBrowserBackString];
    [self.awesomeToolbar setEnabled:[self.webview canGoForward] forButtonWithTitle:kWebBrowserForwardString];
    [self.awesomeToolbar setEnabled:self.frameCount > 0 forButtonWithTitle:kWebBrowserStopString];
    [self.awesomeToolbar setEnabled:self.webview.request.URL && self.frameCount == 0 forButtonWithTitle:kWebBrowserRefreshString];
}

- (void) resetWebView {
    [self.webview removeFromSuperview];
    
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    self.webview = newWebView;
    self.textField.text = nil;
    [self updateButtonsAndTitle];
}

@end
