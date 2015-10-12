#import "GPUImageSqueezeFilter.h"

NSString *const kGPUImageSqueezeFilterFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp vec2 center;
 uniform highp float radius;
 uniform highp float scale;
 
 void main()
 {
     highp vec2 textureCoordinateToUse = textureCoordinate;
     highp float dist = distance(center, textureCoordinate);
     highp float mult = 0.75/ pow(dist, 0.4);
     
     textureCoordinateToUse.x = center.x + ((textureCoordinateToUse.x - center.x) * mult);
     textureCoordinateToUse.y = center.y + ((textureCoordinateToUse.y - center.y) * mult);
     
     gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse);
     
 }
 );

@interface GPUImageSqueezeFilter ()

- (void)adjustAspectRatio;

@property (readwrite, nonatomic) CGFloat aspectRatio;

@end

@implementation GPUImageSqueezeFilter

@synthesize aspectRatio = _aspectRatio;
@synthesize center = _center;
@synthesize radius = _radius;
@synthesize scale = _scale;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSqueezeFilterFragmentShaderString]))
    {
        return nil;
    }
    
    aspectRatioUniform = [filterProgram uniformIndex:@"aspectRatio"];
    radiusUniform = [filterProgram uniformIndex:@"radius"];
    scaleUniform = [filterProgram uniformIndex:@"scale"];
    centerUniform = [filterProgram uniformIndex:@"center"];
    
    self.radius = 0.25;
    self.scale = 0.5;
    self.center = CGPointMake(0.5, 0.5);
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)adjustAspectRatio;
{
    if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
    {
        [self setAspectRatio:(inputTextureSize.width / inputTextureSize.height)];
    }
    else
    {
        [self setAspectRatio:(inputTextureSize.height / inputTextureSize.width)];
    }
}

- (void)forceProcessingAtSize:(CGSize)frameSize;
{
    [super forceProcessingAtSize:frameSize];
    [self adjustAspectRatio];
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    CGSize oldInputSize = inputTextureSize;
    [super setInputSize:newSize atIndex:textureIndex];
    
    if ( (!CGSizeEqualToSize(oldInputSize, inputTextureSize)) && (!CGSizeEqualToSize(newSize, CGSizeZero)) )
    {
        [self adjustAspectRatio];
    }
}

- (void)setAspectRatio:(CGFloat)newValue;
{
    _aspectRatio = newValue;
    
    [self setFloat:_aspectRatio forUniform:aspectRatioUniform program:filterProgram];
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    [super setInputRotation:newInputRotation atIndex:textureIndex];
    [self setCenter:self.center];
    [self adjustAspectRatio];
}

- (void)setRadius:(CGFloat)newValue;
{
    _radius = newValue;
    
    [self setFloat:_radius forUniform:radiusUniform program:filterProgram];
}

- (void)setScale:(CGFloat)newValue;
{
    _scale = newValue;
    
    [self setFloat:_scale forUniform:scaleUniform program:filterProgram];
}

- (void)setCenter:(CGPoint)newValue;
{
    _center = newValue;
    
    CGPoint rotatedPoint = [self rotatedPoint:_center forRotation:inputRotation];
    
    [self setPoint:rotatedPoint forUniform:centerUniform program:filterProgram];
}

@end
