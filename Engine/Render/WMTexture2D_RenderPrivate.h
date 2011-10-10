@interface WMTexture2D () {
	//For subclassers
@protected
	GLuint						_name;
	CGSize						_size;
	NSUInteger					_width,
	_height;
}

@end


@interface WMTexture2D (WMTexture2D_RenderPrivate)

@property (nonatomic, readonly) GLuint name;

@end