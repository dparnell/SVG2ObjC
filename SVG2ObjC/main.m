//
//  main.c
//  SVG2ObjC
//
//  Created by Daniel Parnell on 23/09/12.
//  Copyright (c) 2012 Automagic Software Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+SVGPath.h"
#import "NSString+CSSStyle.h"

void render_path(NSXMLElement* e, NSMutableString* result, BOOL shouldStroke, BOOL shouldFill) {
    float x, y, x1, y1, x2, y2;
    int counter, i;
    float numbers[8];
    BOOL needs_draw = NO;
    
    NSString* a = [[e attributeForName: @"d"] stringValue];
    NSArray* path = [a svgPathTokens];
    
    [result appendFormat: @"\t/* %@ */\n", a];
    
    char cmd;
    for (NSObject* o in path) {
        if([o isKindOfClass: [NSString class]]) {
            i = 0;
            cmd = [(NSString*)o characterAtIndex: 0];
            
            if(cmd == 'z' || cmd =='Z') {
                counter = 0;
            } else {
                counter = -1;
            }
        } else {
            if(counter == -1) {                
                switch (cmd) {
                    case 'm':
                    case 'M':
                        counter = 2;
                        break;
                        
                    case 'c':
                    case 'C':
                        counter = 6;
                        break;
                        
                    case 'l':
                    case 'L':
                        counter = 2;
                        break;
                        
                    case 'z':
                    case 'Z':
                        counter = 0;
                        break;
                        
                    default:
                        @throw [NSException exceptionWithName: @"BOOM1" reason: [NSString stringWithFormat: @"Invalid path element: %c", cmd] userInfo: @{ @"path": path } ];
                        break;
                }
            }
            
            if(i<8) {
                numbers[i] = [(NSNumber*)o floatValue];
                i++;
                counter--;
            } else {
                @throw [NSException exceptionWithName: @"BOOM2" reason: @"Invalid path" userInfo: @{ @"path": path } ];
            }
        }
        
        if(counter == 0) {
            counter = -1;
            needs_draw = YES;
            switch (cmd) {
                case 'M':
                    // move absolute
                    x = numbers[0];
                    y = numbers[1];
                    [result appendFormat: @"\tCGContextMoveToPoint(context, %f, %f);\n", x, y];
                    break;
                    
                case 'm':
                    // move relative
                    x += numbers[0];
                    y += numbers[1];
                    [result appendFormat: @"\tCGContextMoveToPoint(context, %f, %f);\n", x, y];
                    break;
                    
                case 'C':
                    // absolute cubic Bézier curveto
                    x1 = numbers[0];
                    y1 = numbers[1];
                    x2 = numbers[2];
                    y2 = numbers[3];
                    x = numbers[4];
                    y = numbers[5];
                    [result appendFormat: @"\tCGContextAddCurveToPoint(context, %f, %f, %f, %f, %f, %f);\n", x1, y1, x2, y2, x, y];
                    break;
                    
                case 'c':
                    // relative cubic Bézier curveto
                    x1 = x + numbers[0];
                    y1 = y + numbers[1];
                    x2 = x + numbers[2];
                    y2 = y + numbers[3];
                    x += numbers[4];
                    y += numbers[5];
                    [result appendFormat: @"\tCGContextAddCurveToPoint(context, %f, %f, %f, %f, %f, %f);\n", x1, y1, x2, y2, x, y];
                    break;
                    
                case 'L':
                    // absolute line
                    x = numbers[0];
                    y = numbers[1];
                    [result appendFormat: @"\tCGContextAddLineToPoint(context, %f, %f);\n", x, y];
                    break;
                    
                case 'l':
                    // relative line
                    x += numbers[0];
                    y += numbers[1];
                    [result appendFormat: @"\tCGContextAddLineToPoint(context, %f, %f);\n", x, y];
                    break;
                    
                case 'z':
                case 'Z':
                    // close path
                    [result appendString: @"\tCGContextClosePath(context);\n"];
                    
                    if(shouldFill) {
                        [result appendString: @"\tCGContextFillPath(context);\n"];
                    }
                    if(shouldStroke) {
                        [result appendString: @"\tCGContextStrokePath(context);\n"];
                    }
                    
                    needs_draw = false;
                    break;
                    
                default:
                    @throw [NSException exceptionWithName: @"BOOM3" reason: @"Invalid path" userInfo: @{ @"path": path } ];
                    break;
            }
        }
    }

    if(needs_draw) {
        if(shouldFill) {
            [result appendString: @"\tCGContextFillPath(context);\n"];
        }
        if(shouldStroke) {
            [result appendString: @"\tCGContextStrokePath(context);\n"];
        }
    }
}

void process_node(NSXMLNode* n, NSMutableString* result, BOOL shouldStroke, BOOL shouldFill) {
    BOOL changed_state = NO;
    CGFloat r,g,b;
    
    if([n kind] == NSXMLElementKind) {
        NSXMLElement* e = (NSXMLElement*)n;
        NSString* name = [[e name] lowercaseString];
        NSString* style = [[e attributeForName: @"style"] stringValue];
        NSMutableDictionary* styles = nil;
        
        if(style) {
            [result appendFormat: @"\t// %@\n", style];            
            styles = [[style cssStyles] mutableCopy];
        }

        for (NSXMLNode* attr in [e attributes]) {
            NSString* attrName = [[attr name] lowercaseString];
            
            if([attrName isEqualToString: @"fill"] || [attrName isEqualToString: @"stroke"]) {
                if(styles==nil) {
                    styles = [NSMutableDictionary new];
                }
                
                [styles setObject: [attr stringValue] forKey: attrName];
            }
        }
        
        if([styles count]) {
            changed_state = YES;
            [result appendString: @"\tCGContextSaveGState(context);\n"];
            for (NSString* key in styles) {
                NSString* value = [styles objectForKey: key];
                
                if([key isEqualToString: @"stroke"]) {
                    if([value isCaseInsensitiveLike: @"none"]) {
                        shouldStroke = NO;
                    } else {
                        shouldStroke = YES;
                        
                        // is it a colour?
                        if([value cssColourToRed: &r green: &g andBlue: &b]) {
                            [result appendFormat: @"\tCGContextSetRGBStrokeColor(context, %f, %f, %f, 1.0);\n", r, g, b];
                        }
                    }
                } else if([key isEqualToString: @"fill"]) {
                    if([value isCaseInsensitiveLike: @"none"]) {
                        shouldFill = NO;
                    } else {
                        shouldFill = YES;
                        
                        // is it a colour?
                        if([value cssColourToRed: &r green: &g andBlue: &b]) {
                            [result appendFormat: @"\tCGContextSetRGBFillColor(context, %f, %f, %f, 1.0);\n", r, g, b];
                        }
                    }
                } else if([key isEqualToString: @"stroke-width"]) {
                    float w = [value floatValue];
                    
                    [result appendFormat: @"\tCGContextSetLineWidth(context, %f);\n", w];
                }
            }
        }
        
        if([name isEqualToString: @"path"]) {
            // process a PATH element
            render_path(e, result, shouldStroke, shouldFill);
        }
    }
    
    if([n childCount] > 0) {
        for(NSXMLNode* node in [n children]) {
            process_node(node, result, shouldStroke, shouldFill);
        }
    }
    
    if(changed_state) {
        [result appendString: @"\tCGContextRestoreGState(context);\n"];
    }
    
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        if(argc < 2 || argc > 3) {
            printf("USAGE: %s input.svg output_dir\n", argv[0]);
            return 1;
        }
        
        NSString* infileName = [NSString stringWithCString: argv[1] encoding: NSUTF8StringEncoding];
        NSString* infileBaseName = [[infileName lastPathComponent] stringByDeletingPathExtension];
        NSString* className = [infileBaseName capitalizedString];
        NSURL* inputFile = [[NSURL alloc] initFileURLWithPath: infileName];
        NSString* outputDir;

        if(argc == 2) {
            outputDir = [infileName stringByDeletingLastPathComponent];
        } else {
            outputDir = [NSString stringWithCString: argv[2] encoding: NSUTF8StringEncoding];
        }
        
        NSXMLDocument* doc = [[NSXMLDocument alloc] initWithContentsOfURL: inputFile options: 0 error: nil];

        if(doc) {
            NSMutableString* result = [NSMutableString new];
            process_node(doc, result, YES, NO);
            
            NSString* toWrite = [NSString stringWithFormat: @"/* File generated by SVG2ObjC by Daniel Parnell - me@danielparnell.com */\n\n\
#import \"%@\"\n\n\
@implementation %@\n\
\n\
+(void) draw:(CGContextRef)context {\n\
%@}\n\n\
+(void) draw {\n\
#if TARGET_OS_MAC\n\
  CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];\n\
#else\n\
  CGContextRef context = UIGraphicsGetCurrentContext();\n\
#endif\n\
  [%@ draw: context];\n\
}\n\n@end", [infileBaseName stringByAppendingPathExtension: @"h"], className, result, className];
            NSError* error = nil;
            
            if([toWrite writeToFile: [outputDir stringByAppendingPathComponent: [infileBaseName stringByAppendingPathExtension: @"m"]] atomically: NO encoding: NSUTF8StringEncoding error: &error]) {
                toWrite = [NSString stringWithFormat: @"/* File generated by SVG2ObjC by Daniel Parnell - me@danielparnell.com */\n\
#if TARGET_OS_MAC\n\
#import <Cocoa/Cocoa.h>\n\
#else\n\
#import <ApplicationServerices/ApplicationServices.h>\n\
#endif\n\
\n\
@interface %@ : NSObject\n\n\
+(void) draw:(CGContextRef)context;\n\
+(void) draw;\n\
\n\
@end\n", className];
                if([toWrite writeToFile: [outputDir stringByAppendingPathComponent: [infileBaseName stringByAppendingPathExtension: @"h"]] atomically: NO encoding: NSUTF8StringEncoding error: &error]) {
                    return 0;
                } else {
                    fprintf(stderr, "Could not write header file\n");
                    return 1;
                }
            } else {
                fprintf(stderr, "Could not write output file\n");
                return 1;
            }
        }
    }
    return -1;
}

