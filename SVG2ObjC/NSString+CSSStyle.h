//
//  NSString+CSSStyle.h
//  SVG2ObjC
//
//  Created by Daniel Parnell on 30/09/12.
//  Copyright (c) 2012 Automagic Software Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (CSSStyle)

- (NSDictionary*) cssStyles;
- (BOOL) cssColourToRed:(CGFloat*)red green:(CGFloat*)green andBlue:(CGFloat*)blue;

@end
