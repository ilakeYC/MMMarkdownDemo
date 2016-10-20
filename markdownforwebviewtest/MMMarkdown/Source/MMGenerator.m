//
//  MMGenerator.m
//  MMMarkdown
//
//  Copyright (c) 2012 Matt Diephouse.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import <sys/utsname.h>
#import "MMGenerator.h"


#import "MMDocument.h"
#import "MMElement.h"

// This value is used to estimate the length of the HTML output. The length of the markdown document
// is multplied by it to create an NSMutableString with an initial capacity.
static const Float64 kHTMLDocumentLengthMultiplier = 1.25;

static NSString * __HTMLEscapedString(NSString *aString)
{
    NSMutableString *result = [aString mutableCopy];
    
    [result replaceOccurrencesOfString:@"&"
                            withString:@"&amp;"
                               options:NSLiteralSearch
                                 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\""
                            withString:@"&quot;"
                               options:NSLiteralSearch
                                 range:NSMakeRange(0, result.length)];
    
    return result;
}

static NSString *__obfuscatedEmailAddress(NSString *anAddress)
{
    NSMutableString *result = [NSMutableString new];
    
    NSString *(^decimal)(unichar c) = ^(unichar c){ return [NSString stringWithFormat:@"&#%d;", c];  };
    NSString *(^hex)(unichar c)     = ^(unichar c){ return [NSString stringWithFormat:@"&#x%x;", c]; };
    NSString *(^raw)(unichar c)     = ^(unichar c){ return [NSString stringWithCharacters:&c length:1]; };
    NSArray *encoders = @[ decimal, hex, raw ];
    
    for (NSUInteger idx=0; idx<anAddress.length; idx++)
    {
        unichar character = [anAddress characterAtIndex:idx];
        NSString *(^encoder)(unichar c);
        if (character == '@')
        {
            // Make sure that the @ gets encoded
            encoder = [encoders objectAtIndex:arc4random_uniform(2)];
        }
        else
        {
            int r = arc4random_uniform(100);
            encoder = encoders[(r >= 90) ? 2 : (r >= 45) ? 1 : 0];
        }
        [result appendString:encoder(character)];
    }
    
    return result;
}

static double __ScreenWidth(int a)
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
//    if ([deviceModel isEqualToString:@"iPhone1,1"])    return /*@"iPhone 1G"*/;
//    if ([deviceModel isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
//    if ([deviceModel isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
//    if ([deviceModel isEqualToString:@"iPhone3,1"])    return /*@"iPhone 4"*/;
//    if ([deviceModel isEqualToString:@"iPhone3,2"])    return @"Verizon iPhone 4";
//    if ([deviceModel isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([deviceModel isEqualToString:@"iPhone5,1"])    return 320.f/*@"iPhone 5"*/;
    if ([deviceModel isEqualToString:@"iPhone5,2"])    return 320.f/*@"iPhone 5"*/;
    if ([deviceModel isEqualToString:@"iPhone5,3"])    return 320.f/*@"iPhone 5C"*/;
    if ([deviceModel isEqualToString:@"iPhone5,4"])    return 320.f/*@"iPhone 5C"*/;
    if ([deviceModel isEqualToString:@"iPhone6,1"])    return 320.f/*@"iPhone 5S"*/;
    if ([deviceModel isEqualToString:@"iPhone6,2"])    return 320.f/*@"iPhone 5S"*/;
    if ([deviceModel isEqualToString:@"iPhone7,1"])    return 414.f/*@"iPhone 6 Plus"*/;
    if ([deviceModel isEqualToString:@"iPhone7,2"])    return 375.f/*@"iPhone 6"*/;
    if ([deviceModel isEqualToString:@"iPhone8,1"])    return 375.f/*@"iPhone 6s"*/;
    if ([deviceModel isEqualToString:@"iPhone8,2"])    return 414.f/*@"iPhone 6s Plus"*/;
    if ([deviceModel isEqualToString:@"iPhone9,1"])    return 375.f/*@"iPhone 7 (CDMA)"*/;
    if ([deviceModel isEqualToString:@"iPhone9,3"])    return 375.f/*@"iPhone 7 (GSM)"*/;
    if ([deviceModel isEqualToString:@"iPhone9,2"])    return 414.f/*@"iPhone 7 Plus (CDMA)"*/;
    if ([deviceModel isEqualToString:@"iPhone9,4"])    return 414.f/*@"iPhone 7 Plus (GSM)"*/;
    return 320.f;
}

static NSString * __HTMLStartTagForElement(MMElement *anElement)
{
    switch (anElement.type)
    {
        case MMElementTypeHeader: {
                return [NSString stringWithFormat:@"<h%u style=\"padding:15px 15px 12px 15px;font-family:'HelveticaNeue-Bold';font-size:%upx;color:#333333;\">", (unsigned int)anElement.level,(unsigned int)(22 - (unsigned int)anElement.level)];
        }
        
        case MMElementTypeParagraph:{
            return [NSString stringWithFormat:@"<p style=\"word-wrap: break-word;width:auto; padding: 0px 20px 0px 20px;font-family:'HelveticaNeue';font-size:15px;color:#333333;\">"];
        }
        
        case MMElementTypeBulletedList:
            return @"<ul>\n";
        
        case MMElementTypeNumberedList:
            return @"<ol>\n";
        
        case MMElementTypeListItem:
            return @"<li style=\"font-family:'HelveticaNeue';font-size:15px;color:#333333;\">";
        
        case MMElementTypeBlockquote:
            return @"<blockquote>\n";
        
        case MMElementTypeCodeBlock:
          return anElement.language ? [NSString stringWithFormat:@"<pre style=\"background-color:#F5F8FA;border-radius: 3px;color:#667785;overflow-x:scroll;padding:4px;\"><code class=\"%@\">", anElement.language] : @"<pre style=\"background-color:#F5F8FA;border-radius: 3px;color:#667785;overflow-x:scroll;padding:4px;\"><code>";
        
        case MMElementTypeLineBreak:
            return @"<br />";
        
        case MMElementTypeHorizontalRule:
            return @"\n<hr style=\"border:0.5px solid #CCD6DD\"; />\n";
        
        case MMElementTypeStrikethrough:
            return @"<del>";
        
        case MMElementTypeStrong:
            return @"<strong style=\"text-decoration:none;color:#333333;font-family:'HelveticaNeue-Medium';font-size:15px;\">";
        
        case MMElementTypeEm:
            return @"<em>";
        
        case MMElementTypeCodeSpan:
            return @"<code style=\"display: inline-block;background-color:#F5F8FA;border-radius: 3px;color:#667785;overflow-x:scroll;padding:2px;margin:2px;\" class=\"%@\">";
        
        case MMElementTypeImage: {
//            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            float imageWidth = __ScreenWidth(0) - 20;
            if (anElement.title != nil)
            {
                return [NSString stringWithFormat:@"<div style=\"text-align:center;\"><img style=\"width: %fpx;height: auto;b;\" src=\"%@\" alt=\"%@\" title=\"%@\" /></div>",
                        imageWidth,
                        __HTMLEscapedString(anElement.href),
                        __HTMLEscapedString(anElement.stringValue),
                        __HTMLEscapedString(anElement.title)];
            }
            return [NSString stringWithFormat:@"<div style=\"text-align:center;\"><img style=\"width: %fpx;height: auto;\" src=\"%@\" alt=\"%@\" /></div>",
                    imageWidth,
                    __HTMLEscapedString(anElement.href),
                    __HTMLEscapedString(anElement.stringValue)];
        
        }
            
        case MMElementTypeLink:
            if (anElement.title != nil)
            {
                return [NSString stringWithFormat:@"<a style=\"text-decoration:none;color:#667785;font-family:'HelveticaNeue';font-size:15px;\" title=\"%@\" href=\"%@\">",
                        __HTMLEscapedString(anElement.title), __HTMLEscapedString(anElement.href)];
            }
            return [NSString stringWithFormat:@"<a style=\"text-decoration:none;color:#667785;font-family:'HelveticaNeue';font-size:15px;\" href=\"%@\">", __HTMLEscapedString(anElement.href)];
        
        case MMElementTypeMailTo:
            return [NSString stringWithFormat:@"<a style=\"text-decoration:none;color:#667785;font-family:'HelveticaNeue';font-size:15px;\" href=\"%@\">%@</a>",
                    __obfuscatedEmailAddress([NSString stringWithFormat:@"mailto:%@", anElement.href]),
                    __obfuscatedEmailAddress(anElement.href)];
        
        case MMElementTypeEntity:
            return anElement.stringValue;
        
        case MMElementTypeTable:
            return @"<table style=\"font-family:'HelveticaNeue';font-size:15px;color:#333333;margin:auto;border-collapse:collapse;border:.5px solid #CCD6DD;\" cellpadding=\"20\">";
        
        case MMElementTypeTableHeader:
            return @"<thead><tr>";
            
        case MMElementTypeTableHeaderCell:
            return anElement.alignment == MMTableCellAlignmentCenter ? @"<th style=\"border:.5px solid #CCD6DD;\" align='center'>"
                 : anElement.alignment == MMTableCellAlignmentLeft   ? @"<th style=\"border:.5px solid #CCD6DD;\" align='left'>"
                 : anElement.alignment == MMTableCellAlignmentRight  ? @"<th style=\"border:.5px solid #CCD6DD;\" align='right'>"
                 : @"<th style=\"border:.5px solid #CCD6DD;\">";
        case MMElementTypeTableRow:
            return @"<tr>";
        case MMElementTypeTableRowCell:
            return anElement.alignment == MMTableCellAlignmentCenter ? @"<td style=\"border:.5px solid #CCD6DD;\" align='center'>"
                 : anElement.alignment == MMTableCellAlignmentLeft   ? @"<td style=\"border:.5px solid #CCD6DD;\" align='left'>"
                 : anElement.alignment == MMTableCellAlignmentRight  ? @"<td style=\"border:.5px solid #CCD6DD;\" align='right'>"
                 : @"<td style=\"border:.5px solid #CCD6DD;\">";
        default:
            return nil;
    }
}

static NSString * __HTMLEndTagForElement(MMElement *anElement)
{
    switch (anElement.type)
    {
        case MMElementTypeHeader:
            return [NSString stringWithFormat:@"</h%u>\n", (unsigned int)anElement.level];
        case MMElementTypeParagraph:
            return @"</p>\n";
        case MMElementTypeBulletedList:
            return @"</ul>\n";
        case MMElementTypeNumberedList:
            return @"</ol>\n";
        case MMElementTypeListItem:
            return @"</li>\n";
        case MMElementTypeBlockquote:
            return @"</blockquote>\n";
        case MMElementTypeCodeBlock:
            return @"</code></pre>\n";
        case MMElementTypeStrikethrough:
            return @"</del>";
        case MMElementTypeStrong:
            return @"</strong>";
        case MMElementTypeEm:
            return @"</em>";
        case MMElementTypeCodeSpan:
            return @"</code>";
        case MMElementTypeLink:
            return @"</a>";
        case MMElementTypeTable:
            return @"</tbody></table>";
        case MMElementTypeTableHeader:
            return @"</tr></thead><tbody>";
        case MMElementTypeTableHeaderCell:
            return @"</th>";
        case MMElementTypeTableRow:
            return @"</tr>";
        case MMElementTypeTableRowCell:
            return @"</td>";
        default:
            return nil;
    }
}

@interface MMGenerator ()
- (void) _generateHTMLForElement:(MMElement *)anElement
                      inDocument:(MMDocument *)aDocument
                            HTML:(NSMutableString *)theHTML
                        location:(NSUInteger *)aLocation;
@end

@implementation MMGenerator

#pragma mark - Public Methods

- (NSString *)generateHTML:(MMDocument *)aDocument
{
    NSString   *markdown = aDocument.markdown;
    NSUInteger  location = 0;
    NSUInteger  length   = markdown.length;
    
    NSMutableString *HTML = [NSMutableString stringWithCapacity:length * kHTMLDocumentLengthMultiplier];
    
    for (MMElement *element in aDocument.elements)
    {
        if (element.type == MMElementTypeHTML)
        {
            [HTML appendString:[aDocument.markdown substringWithRange:element.range]];
        }
        else
        {
            [self _generateHTMLForElement:element
                               inDocument:aDocument
                                 HTML:HTML
                             location:&location];
        }
    }
    
    return HTML;
}


#pragma mark - Private Methods

- (void)_generateHTMLForElement:(MMElement *)anElement
                     inDocument:(MMDocument *)aDocument
                           HTML:(NSMutableString *)theHTML
                       location:(NSUInteger *)aLocation
{
    NSString *startTag = __HTMLStartTagForElement(anElement);
    NSString *endTag   = __HTMLEndTagForElement(anElement);
    
    if (startTag)
        [theHTML appendString:startTag];
    
    for (MMElement *child in anElement.children)
    {
        if (child.type == MMElementTypeNone)
        {
            NSString *markdown = aDocument.markdown;
            if (child.range.length == 0)
            {
                [theHTML appendString:@"\n"];
            }
            else
            {
                [theHTML appendString:[markdown substringWithRange:child.range]];
            }
        }
        else if (child.type == MMElementTypeHTML)
        {
            [theHTML appendString:[aDocument.markdown substringWithRange:child.range]];
        }
        else
        {
            [self _generateHTMLForElement:child
                               inDocument:aDocument
                                     HTML:theHTML
                                 location:aLocation];
        }
    }
    
    if (endTag)
        [theHTML appendString:endTag];
}


@end
