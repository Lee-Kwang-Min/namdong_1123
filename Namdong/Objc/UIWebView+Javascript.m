//
//  UIWebView+Javascript.m
//  webview
//
//  Created by Chris Song on 2017. 10. 11..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

#import "UIWebView+Javascript.h"

@implementation UIWebView (Javascript)

- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(id *)frame {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    [alert show];
}
@end
