//
//  UIWebView+Javascript.h
//  webview
//
//  Created by Chris Song on 2017. 10. 11..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWebView (WebView)
- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(id *)frame;
@end
