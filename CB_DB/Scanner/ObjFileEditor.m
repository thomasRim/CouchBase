//
//  ObjFileEditor.m
//  Scanner
//
//  Created by Kamil Budzynski on 10.06.2015.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

#import "ObjFileEditor.h"
#import <GLKit/GLKit.h>

#define maxValue 1500.0
#define minValue -1500.0

@implementation ObjFileEditor

+ (NSData *)translateToAlignCenterObjectWithData:(NSData *)data{
   
    //convert to string
    NSString *string = [[NSString alloc] initWithBytesNoCopy:(void *)data.bytes length:data.length encoding:NSASCIIStringEncoding freeWhenDone:NO];
    NSString *line = nil;
    NSScanner *lineScanner = [NSScanner scannerWithString:string];
    
    GLfloat minFloatX = maxValue;
    GLfloat maxFloatX = minValue;
    GLfloat minFloatY = maxValue;
    GLfloat maxFloatY = minValue;
    GLfloat minFloatZ = maxValue;
    GLfloat maxFloatZ = minValue;
    
    // calculate center point of model and translation
    do
    {
        //get line
        [lineScanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&line];
        NSScanner *scanner = [NSScanner scannerWithString:line];
        
        //get line type
        NSString *type = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&type];
        
        if ([type isEqualToString:@"v"])
        {
            //vertex
            GLfloat coords[3];
            [scanner scanFloat:&coords[0]];
            [scanner scanFloat:&coords[1]];
            [scanner scanFloat:&coords[2]];
            
            if (coords[0] < minFloatX) minFloatX = coords[0];
            
            if (coords[0] > maxFloatX) maxFloatX = coords[0];
            
            if (coords[1] < minFloatY) minFloatY = coords[1];
            
            if (coords[1] > maxFloatY) maxFloatY = coords[1];
            
            if (coords[2] < minFloatZ) minFloatZ = coords[2];
            
            if (coords[2] > maxFloatZ) maxFloatZ = coords[2];
            
        }
    }
    while (![lineScanner isAtEnd]);

    // delta X, Y, Z - translation that must by applied to object to center the object
    GLfloat deltas[3];
    deltas[0] = (maxFloatX + minFloatX) / 2;
    deltas[1] = (maxFloatY + minFloatY) / 2;
    deltas[2] = (maxFloatZ + minFloatZ) / 2;
    
    line = nil;
    lineScanner = [NSScanner scannerWithString:string];
    
    // translated line of .obj file
    NSString *newLine;
    // final .obj data
    NSMutableData *fileData = [[NSMutableData alloc] init];
    
    do
    {
        
        //get line
        [lineScanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&line];
        NSScanner *scanner = [NSScanner scannerWithString:line];
        
        //get line type
        NSString *type = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&type];
        
        if ([type isEqualToString:@"v"])
        {
            //vertex
            GLfloat coords[3];
            
            for(int i = 0; i < 3; i++){
                // read vertice coord
                [scanner scanFloat:&coords[i]];
                // center vertice
                coords[i] = coords[i] - deltas[i];
                
            }
            newLine = [NSString stringWithFormat:@"v %.4f %.4f %.4f\n", coords[0], coords[1], coords[2]];
            
        }
        else newLine = [NSString stringWithFormat:@"%@\n",line];
        
        [fileData appendData:[newLine dataUsingEncoding:NSUTF8StringEncoding]];
    }
    while (![lineScanner isAtEnd]);

    return fileData;
}


@end
